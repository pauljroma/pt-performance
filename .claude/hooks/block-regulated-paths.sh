#!/usr/bin/env bash
# block-regulated-paths.sh
# Purpose:  Block writes to regulated/sensitive paths (migrations, clinical rules, secrets)
# Trigger:  PreToolUse
# Matcher:  Edit|Write|Bash
# Env vars: REGULATED_PATHS (colon-separated, default includes common sensitive dirs)
set -euo pipefail

INPUT="${HOOK_INPUT:-}"
if [[ -z "$INPUT" ]]; then
  exit 0
fi

TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")

# Determine the path being modified
FILE_PATH=""
case "$TOOL_NAME" in
  Edit|Write)
    FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
inp = d.get('tool_input', {})
print(inp.get('file_path', inp.get('path', '')))
" 2>/dev/null || echo "")
    ;;
  Bash)
    # Extract file paths from command string (best-effort)
    COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null || echo "")
    FILE_PATH="$COMMAND"
    ;;
  *)
    exit 0
    ;;
esac

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Default regulated path patterns
DEFAULT_REGULATED="migrations/:clinical-rules/:.env:secrets/:audit_log/:infra/prod/:certs/"
REGULATED="${REGULATED_PATHS:-$DEFAULT_REGULATED}"

IFS=':' read -ra PATTERNS <<< "$REGULATED"
for pattern in "${PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "BLOCKED — regulated path: $FILE_PATH (matches: $pattern)" >&2
    echo "To allow this edit, set REGULATED_PATHS excluding '$pattern' or get approval." >&2
    exit 1
  fi
done

exit 0
