#!/usr/bin/env bash
# block-dangerous-commands.sh
# Purpose:  Block dangerous shell commands (rm -rf, force push, DROP TABLE, etc.)
# Trigger:  PreToolUse
# Matcher:  Bash
# Env vars: ALLOW_FORCE_PUSH=1 (to permit git push --force on non-main branches)
set -euo pipefail

INPUT="${HOOK_INPUT:-}"
if [[ -z "$INPUT" ]]; then
  exit 0
fi

TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")

if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null || echo "")

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

block() {
  local reason="$1"
  echo "BLOCKED — dangerous command: $reason" >&2
  echo "Command: $COMMAND" >&2
  exit 1
}

# Destructive filesystem
if echo "$COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f|rm\s+--recursive.*--force'; then
  block "rm -rf detected"
fi

# Git destructive operations on protected branches
if echo "$COMMAND" | grep -qE 'git\s+(push\s+.*--force|push\s+.*-f)\s.*(main|master|production)'; then
  block "force push to protected branch"
fi

if [[ "${ALLOW_FORCE_PUSH:-0}" != "1" ]]; then
  if echo "$COMMAND" | grep -qE 'git\s+(push\s+.*--force|push\s+.*-f)'; then
    block "force push (set ALLOW_FORCE_PUSH=1 to permit on non-main branches)"
  fi
fi

if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard\s+HEAD~[2-9]|git\s+reset\s+--hard\s+HEAD~[0-9]{2}'; then
  block "git reset --hard (multi-commit rewind)"
fi

# Database destructive operations
if echo "$COMMAND" | grep -qiE 'DROP\s+(TABLE|DATABASE|SCHEMA)\s+(?!IF\s+EXISTS)'; then
  block "DROP TABLE/DATABASE/SCHEMA without IF EXISTS"
fi

if echo "$COMMAND" | grep -qiE 'TRUNCATE\s+TABLE'; then
  block "TRUNCATE TABLE"
fi

# Credential exposure
if echo "$COMMAND" | grep -qE 'cat\s+.*\.env|echo\s+.*PASSWORD|printenv.*KEY|printenv.*SECRET|printenv.*TOKEN'; then
  block "potential credential exposure"
fi

# System-level danger
if echo "$COMMAND" | grep -qE 'mkfs\.|dd\s+if=.*of=/dev/'; then
  block "disk format/overwrite command"
fi

exit 0
