#!/usr/bin/env bash
# compose-hooks.sh
# Purpose:  Generate .claude/settings.json from selected hook catalog entries
# Usage:    ./hooks/compose-hooks.sh [hook-name...] [> .claude/settings.json]
# Example:  ./hooks/compose-hooks.sh lint-on-save block-regulated-paths block-dangerous-commands
#
# Available hooks:
#   lint-on-save              PostToolUse → Edit|Write — linter after file edits
#   block-regulated-paths     PreToolUse  → Edit|Write|Bash — block sensitive paths
#   block-dangerous-commands  PreToolUse  → Bash — block rm -rf, force push, DROP TABLE
#   cost-check                PreToolUse  → Bash — spend-gate check before dispatch
#   audit-log                 PostToolUse → Edit|Write|Bash|Agent — compliance trail
#   gate-check                PreToolUse  → Agent|Write — W0 gate + trust tier
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -eq 0 ]]; then
  cat >&2 <<'USAGE'
compose-hooks.sh — Generate .claude/settings.json from hook catalog

Usage:
  ./hooks/compose-hooks.sh <hook1> [hook2...] > .claude/settings.json

Available hooks:
  lint-on-save              PostToolUse  Edit|Write
  block-regulated-paths     PreToolUse   Edit|Write|Bash
  block-dangerous-commands  PreToolUse   Bash
  cost-check                PreToolUse   Bash
  audit-log                 PostToolUse  Edit|Write|Bash|Agent
  gate-check                PreToolUse   Agent|Write

Example:
  ./hooks/compose-hooks.sh lint-on-save block-dangerous-commands block-regulated-paths > .claude/settings.json
USAGE
  exit 1
fi

# Hook metadata: name:trigger:matcher
declare -A HOOK_TRIGGER
HOOK_TRIGGER["lint-on-save"]="PostToolUse:Edit|Write"
HOOK_TRIGGER["block-regulated-paths"]="PreToolUse:Edit|Write|Bash"
HOOK_TRIGGER["block-dangerous-commands"]="PreToolUse:Bash"
HOOK_TRIGGER["cost-check"]="PreToolUse:Bash"
HOOK_TRIGGER["audit-log"]="PostToolUse:Edit|Write|Bash|Agent"
HOOK_TRIGGER["gate-check"]="PreToolUse:Agent|Write"

SELECTED_HOOKS=("$@")

# Validate all hooks before generating output
for hook_name in "${SELECTED_HOOKS[@]}"; do
  if [[ -z "${HOOK_TRIGGER[$hook_name]:-}" ]]; then
    echo "ERROR: unknown hook '$hook_name'" >&2
    echo "Available: ${!HOOK_TRIGGER[*]}" >&2
    exit 1
  fi
  script_path="$HOOKS_DIR/${hook_name}.sh"
  if [[ ! -f "$script_path" ]]; then
    echo "ERROR: hook script not found: $script_path" >&2
    exit 1
  fi
done

# Generate JSON via Python (cleaner than bash string manipulation)
python3 - "$HOOKS_DIR" "${SELECTED_HOOKS[@]}" <<'PYEOF'
import sys, json

hooks_dir = sys.argv[1]
selected = sys.argv[2:]

hook_meta = {
    "lint-on-save":              ("PostToolUse", "Edit|Write"),
    "block-regulated-paths":     ("PreToolUse",  "Edit|Write|Bash"),
    "block-dangerous-commands":  ("PreToolUse",  "Bash"),
    "cost-check":                ("PreToolUse",  "Bash"),
    "audit-log":                 ("PostToolUse", "Edit|Write|Bash|Agent"),
    "gate-check":                ("PreToolUse",  "Agent|Write"),
}

pre_hooks = []
post_hooks = []

for name in selected:
    trigger, matcher = hook_meta[name]
    script = f"{hooks_dir}/{name}.sh"
    entry = {
        "matcher": matcher,
        "hooks": [{"type": "command", "command": f"HOOK_INPUT=$(cat) {script}"}],
    }
    if trigger == "PreToolUse":
        pre_hooks.append(entry)
    else:
        post_hooks.append(entry)

settings = {}
hooks = {}
if pre_hooks:
    hooks["PreToolUse"] = pre_hooks
if post_hooks:
    hooks["PostToolUse"] = post_hooks
if hooks:
    settings["hooks"] = hooks

print(json.dumps(settings, indent=2))
PYEOF
