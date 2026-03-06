#!/usr/bin/env bash
# promote.sh — Build-once promote-many artifact CLI
# Validates, tags, and promotes release artifacts through environments.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONTRACT="$SCRIPT_DIR/promote-contract.json"
STATE_DIR="$SCRIPT_DIR/.state"
HISTORY_FILE="$STATE_DIR/promote-history.json"

# ── Colors ────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Contract helpers ──────────────────────────────────────────

contract_field() {
  local path="$1"
  python3 -c "
import json
with open('$CONTRACT') as f:
    data = json.load(f)
keys = '$path'.lstrip('.').split('.')
val = data
for k in keys:
    if isinstance(val, dict):
        val = val.get(k)
    else:
        val = None
        break
if isinstance(val, list):
    for item in val:
        print(item)
elif val is not None:
    print(val)
" 2>/dev/null
}

contract_list() {
  contract_field "$1"
}

# ── State helpers ─────────────────────────────────────────────

ensure_state_dir() {
  mkdir -p "$STATE_DIR"
  if [[ ! -f "$HISTORY_FILE" ]]; then
    echo '{"promotions":[]}' > "$HISTORY_FILE"
  fi
}

append_history() {
  local sha="$1" env="$2" action="$3" artifact_path="${4:-}"
  ensure_state_dir
  local now tagger
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tagger="${USER:-ci}"
  local tmp="$HISTORY_FILE.tmp.$$"
  python3 -c "
import json
with open('$HISTORY_FILE') as f:
    data = json.load(f)
data['promotions'].append({
    'sha': '$sha',
    'env': '$env',
    'action': '$action',
    'timestamp': '$now',
    'tagger': '$tagger',
    'artifact_path': '$artifact_path'
})
with open('$tmp', 'w') as f:
    json.dump(data, f, indent=2)
" && mv "$tmp" "$HISTORY_FILE"
}

get_last_tag_env() {
  local sha="$1"
  python3 -c "
import json
with open('$HISTORY_FILE') as f:
    data = json.load(f)
envs = []
for p in data['promotions']:
    if p['sha'] == '$sha' and p['action'] == 'tag':
        envs.append(p['env'])
if envs:
    print(envs[-1])
" 2>/dev/null
}

# ── Commands ──────────────────────────────────────────────────

cmd_validate() {
  local artifact_dir="${1:-}"
  [[ -z "$artifact_dir" ]] && { echo "Usage: promote.sh validate <artifact-dir>"; exit 1; }
  [[ ! -d "$artifact_dir" ]] && { echo -e "${RED}ERROR${NC} Directory not found: $artifact_dir"; exit 1; }

  echo -e "${BOLD}Validating artifacts in $artifact_dir...${NC}"
  local errors=0

  # Check required files
  local required_files
  required_files=$(contract_list ".required_files")
  for req in $required_files; do
    if [[ -f "$artifact_dir/$req" ]]; then
      echo -e "  ${GREEN}✓${NC} $req"
    else
      echo -e "  ${RED}✗${NC} $req — missing"
      errors=$((errors + 1))
    fi
  done

  # Validate build-metadata.json contents
  if [[ -f "$artifact_dir/build-metadata.json" ]]; then
    local require_sha require_provenance
    require_sha=$(contract_field ".validation_rules.require_git_sha")
    require_provenance=$(contract_field ".validation_rules.require_provenance")

    local meta_errors
    meta_errors=$(python3 -c "
import json, sys
with open('$artifact_dir/build-metadata.json') as f:
    meta = json.load(f)
errors = []
required = ['repo', 'sha', 'ref', 'run_id', 'timestamp']
for field in required:
    if field not in meta or not meta[field]:
        errors.append(f'build-metadata.json: missing required field \"{field}\"')
if '$require_sha' == 'true' and 'sha' in meta:
    sha = meta['sha']
    if not sha or len(sha) < 7:
        errors.append(f'build-metadata.json: sha appears invalid ({sha})')
for e in errors:
    print(e)
" 2>/dev/null)

    if [[ -n "$meta_errors" ]]; then
      echo "$meta_errors" | while read -r err; do
        echo -e "  ${RED}✗${NC} $err"
        errors=$((errors + 1))
      done
    else
      echo -e "  ${GREEN}✓${NC} build-metadata.json contents valid"
    fi

    # Check artifact age
    local max_age
    max_age=$(contract_field ".validation_rules.max_artifact_age_hours")
    if [[ -n "$max_age" ]]; then
      local age_ok
      age_ok=$(python3 -c "
import json
from datetime import datetime, timezone, timedelta
with open('$artifact_dir/build-metadata.json') as f:
    meta = json.load(f)
ts = meta.get('timestamp', '')
if ts:
    try:
        built = datetime.fromisoformat(ts.replace('Z', '+00:00'))
        age_h = (datetime.now(timezone.utc) - built).total_seconds() / 3600
        if age_h > $max_age:
            print(f'STALE ({age_h:.0f}h old, max {$max_age}h)')
        else:
            print('OK')
    except:
        print('PARSE_ERROR')
else:
    print('NO_TIMESTAMP')
" 2>/dev/null)

      if [[ "$age_ok" == "OK" ]]; then
        echo -e "  ${GREEN}✓${NC} artifact age within ${max_age}h limit"
      else
        echo -e "  ${RED}✗${NC} artifact age: $age_ok"
        errors=$((errors + 1))
      fi
    fi
  fi

  # Verify SHA256SUMS
  local require_sums
  require_sums=$(contract_field ".validation_rules.require_sha256sums")
  if [[ "$require_sums" == "true" && -f "$artifact_dir/SHA256SUMS" ]]; then
    if (cd "$artifact_dir" && shasum -a 256 -c SHA256SUMS >/dev/null 2>&1); then
      echo -e "  ${GREEN}✓${NC} SHA256SUMS verified"
    else
      echo -e "  ${RED}✗${NC} SHA256SUMS verification failed"
      errors=$((errors + 1))
    fi
  fi

  echo ""
  if [[ $errors -eq 0 ]]; then
    echo -e "${GREEN}Validation passed.${NC}"
    return 0
  else
    echo -e "${RED}Validation failed ($errors errors).${NC}"
    return 1
  fi
}

cmd_tag() {
  local artifact_dir="${1:-}" env="${2:-}"
  [[ -z "$artifact_dir" || -z "$env" ]] && { echo "Usage: promote.sh tag <artifact-dir> <env>"; exit 1; }

  # Validate environment
  local valid_envs
  valid_envs=$(contract_list ".environments")
  if ! echo "$valid_envs" | grep -qx "$env"; then
    echo -e "${RED}ERROR${NC} Invalid environment '$env'. Valid: $(echo "$valid_envs" | tr '\n' ', ' | sed 's/,$//')"
    exit 1
  fi

  # Validate artifacts first
  cmd_validate "$artifact_dir" || exit 1

  # Enforce promotion order
  ensure_state_dir
  local sha
  sha=$(python3 -c "
import json
with open('$artifact_dir/build-metadata.json') as f:
    print(json.load(f).get('sha', 'unknown'))
" 2>/dev/null)

  local promo_order
  promo_order=$(contract_list ".promotion_order")
  local prev_env=""
  for order_env in $promo_order; do
    if [[ "$order_env" == "$env" ]]; then
      break
    fi
    prev_env="$order_env"
  done

  if [[ -n "$prev_env" ]]; then
    local last_tagged
    last_tagged=$(get_last_tag_env "$sha")
    local prev_found=false
    for order_env in $promo_order; do
      if [[ "$order_env" == "$prev_env" || "$order_env" == "$env" ]]; then
        prev_found=true
      fi
    done

    # Check that previous env was tagged
    local has_prev
    has_prev=$(python3 -c "
import json
with open('$HISTORY_FILE') as f:
    data = json.load(f)
for p in data['promotions']:
    if p['sha'] == '$sha' and p['env'] == '$prev_env' and p['action'] == 'tag':
        print('yes')
        break
else:
    print('no')
" 2>/dev/null)

    if [[ "$has_prev" != "yes" && "${OPT_FORCE:-}" != "1" ]]; then
      echo -e "${RED}ERROR${NC} Cannot tag for '$env' — artifact $sha not yet tagged for '$prev_env'"
      echo "  Promotion order: $(echo "$promo_order" | tr '\n' ' → ' | sed 's/ → $//')"
      echo "  Use --force to override."
      exit 1
    fi
  fi

  # Write promotion tag into artifact dir
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  python3 -c "
import json
tag = {
    'env': '$env',
    'sha': '$sha',
    'tagged_at': '$now',
    'tagger': '${USER:-ci}'
}
with open('$artifact_dir/promotion-tag.json', 'w') as f:
    json.dump(tag, f, indent=2)
" 2>/dev/null

  append_history "$sha" "$env" "tag" ""
  echo -e "${GREEN}Tagged${NC} $sha for ${BOLD}$env${NC}"
}

cmd_push() {
  local artifact_dir="${1:-}" env="${2:-}"
  [[ -z "$artifact_dir" || -z "$env" ]] && { echo "Usage: promote.sh push <artifact-dir> <env>"; exit 1; }

  # Validate first
  cmd_validate "$artifact_dir" || exit 1

  local sha
  sha=$(python3 -c "
import json
with open('$artifact_dir/build-metadata.json') as f:
    print(json.load(f).get('sha', 'unknown'))
" 2>/dev/null)

  local repo_name
  repo_name=$(python3 -c "
import json
with open('$artifact_dir/build-metadata.json') as f:
    print(json.load(f).get('repo', 'unknown'))
" 2>/dev/null)

  # Resolve store config (expand env vars)
  local store_type bucket prefix
  store_type="${ARTIFACT_STORE_TYPE:-s3}"
  bucket="${ARTIFACT_BUCKET:-artifacts}"
  prefix="${ARTIFACT_PREFIX:-}"

  local dest_path
  if [[ -n "$prefix" ]]; then
    dest_path="$prefix/$repo_name/$sha/$env"
  else
    dest_path="$repo_name/$sha/$env"
  fi

  echo -e "${BOLD}Pushing artifacts to $env...${NC}"

  case "$store_type" in
    s3)
      local s3_path="s3://$bucket/$dest_path/"
      echo "  Target: $s3_path"
      if [[ "${OPT_DRY_RUN:-}" == "1" ]]; then
        echo -e "  ${CYAN}DRY RUN${NC} — would upload to $s3_path"
      else
        if command -v aws >/dev/null 2>&1; then
          aws s3 cp --recursive "$artifact_dir/" "$s3_path"
          echo -e "  ${GREEN}Uploaded${NC} to $s3_path"
        else
          echo -e "  ${RED}ERROR${NC} aws CLI not found. Install awscli or use ARTIFACT_STORE_TYPE=local"
          exit 1
        fi
      fi
      append_history "$sha" "$env" "push" "$s3_path"
      ;;
    local)
      local local_path="${ARTIFACT_LOCAL_DIR:-$REPO_ROOT/dist/promoted}/$dest_path"
      echo "  Target: $local_path"
      if [[ "${OPT_DRY_RUN:-}" == "1" ]]; then
        echo -e "  ${CYAN}DRY RUN${NC} — would copy to $local_path"
      else
        mkdir -p "$local_path"
        cp -r "$artifact_dir/"* "$local_path/"
        echo -e "  ${GREEN}Copied${NC} to $local_path"
      fi
      append_history "$sha" "$env" "push" "$local_path"
      ;;
    *)
      echo -e "${RED}ERROR${NC} Unknown store type: $store_type"
      exit 1
      ;;
  esac
}

cmd_status() {
  ensure_state_dir
  local filter_env="${OPT_ENV:-}"

  echo -e "${BOLD}Promotion Status${NC}"
  printf "${BOLD}%-8s %-12s %-22s %-22s %-10s${NC}\n" "ENV" "SHA" "TAGGED" "PUSHED" "TAGGER"
  printf "%-8s %-12s %-22s %-22s %-10s\n" "---" "---" "---" "---" "---"

  python3 -c "
import json
with open('$HISTORY_FILE') as f:
    data = json.load(f)
envs = {}
for p in data['promotions']:
    env = p['env']
    if '$filter_env' and env != '$filter_env':
        continue
    key = env
    if key not in envs:
        envs[key] = {'tag': None, 'push': None}
    if p['action'] == 'tag':
        envs[key]['tag'] = p
    elif p['action'] == 'push':
        envs[key]['push'] = p
for env in ['dev', 'staging', 'prod']:
    if env not in envs:
        continue
    e = envs[env]
    tag = e['tag'] or {}
    push = e['push'] or {}
    sha = tag.get('sha', push.get('sha', '-'))
    tagged = tag.get('timestamp', '-')[:19] if tag else '-'
    pushed = push.get('timestamp', '-')[:19] if push else '-'
    tagger = tag.get('tagger', push.get('tagger', '-'))
    print(f'{env:<8} {sha:<12} {tagged:<22} {pushed:<22} {tagger:<10}')
" 2>/dev/null
}

cmd_audit() {
  ensure_state_dir
  local limit="${OPT_LIMIT:-50}"

  echo -e "${BOLD}Promotion Audit Log${NC} (last $limit entries)"
  printf "${BOLD}%-22s %-8s %-8s %-12s %-10s %-40s${NC}\n" "TIMESTAMP" "ACTION" "ENV" "SHA" "TAGGER" "PATH"
  printf "%-22s %-8s %-8s %-12s %-10s %-40s\n" "---" "---" "---" "---" "---" "---"

  python3 -c "
import json
with open('$HISTORY_FILE') as f:
    data = json.load(f)
entries = data['promotions'][-$limit:]
for p in reversed(entries):
    ts = p.get('timestamp', '-')[:19]
    action = p.get('action', '-')
    env = p.get('env', '-')
    sha = p.get('sha', '-')
    tagger = p.get('tagger', '-')
    path = p.get('artifact_path', '-')
    print(f'{ts:<22} {action:<8} {env:<8} {sha:<12} {tagger:<10} {path:.40}')
" 2>/dev/null
}

# ── Argument parsing ──────────────────────────────────────────

OPT_DRY_RUN=""
OPT_FORCE=""
OPT_ENV=""
OPT_LIMIT=""

usage() {
  cat <<'USAGE'
promote.sh — Build-once promote-many artifact CLI

Usage: promote.sh <command> [options] [args]

Commands:
  validate <dir>       Validate artifact directory (metadata, checksums, age)
  tag <dir> <env>      Tag artifacts for an environment (dev/staging/prod)
  push <dir> <env>     Upload artifacts to store (S3/local)
  status               Show latest promoted artifact per environment
  audit                Show full promotion history

Environments: dev → staging → prod (enforced promotion order)

Options:
  --dry-run            Show what would happen without doing it
  --force              Skip promotion order enforcement
  --env ENV            Filter status to one environment
  --limit N            Limit audit entries (default: 50)
  -h, --help           Show this help

Environment variables:
  ARTIFACT_STORE_TYPE  Store type: s3 (default) or local
  ARTIFACT_BUCKET      S3 bucket name (default: artifacts)
  ARTIFACT_PREFIX      Path prefix in bucket
  ARTIFACT_LOCAL_DIR   Local store directory (for type=local)
USAGE
}

main() {
  local cmd="${1:-}"
  [[ -z "$cmd" ]] && { usage; exit 0; }
  shift

  # Parse options
  local positional=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)   OPT_DRY_RUN=1; shift ;;
      --force)     OPT_FORCE=1; shift ;;
      --env)       OPT_ENV="$2"; shift 2 ;;
      --limit)     OPT_LIMIT="$2"; shift 2 ;;
      -h|--help)   usage; exit 0 ;;
      *)           positional+=("$1"); shift ;;
    esac
  done

  case "$cmd" in
    validate)  cmd_validate "${positional[@]:-}" ;;
    tag)       cmd_tag "${positional[@]:-}" ;;
    push)      cmd_push "${positional[@]:-}" ;;
    status)    cmd_status ;;
    audit)     cmd_audit ;;
    -h|--help) usage ;;
    *)         echo "Unknown command: $cmd"; usage; exit 1 ;;
  esac
}

main "$@"
