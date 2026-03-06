#!/usr/bin/env bash
# lint-on-save.sh
# Purpose:  Run linter after file edits to catch style issues before commit
# Trigger:  PostToolUse
# Matcher:  Edit|Write
# Env vars: LINT_CMD (default: npx eslint --fix), LINT_PATHS (default: src/)
set -euo pipefail

INPUT="${HOOK_INPUT:-}"
if [[ -z "$INPUT" ]]; then
  exit 0
fi

# Extract tool name and file path from hook input JSON
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")

if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
inp = d.get('tool_input', {})
print(inp.get('file_path', inp.get('path', '')))
" 2>/dev/null || echo "")

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only lint supported file types
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) : ;;
  *) exit 0 ;;
esac

LINT_CMD="${LINT_CMD:-npx eslint --fix}"

if $LINT_CMD "$FILE_PATH" >/dev/null 2>&1; then
  echo "lint-on-save: OK ($FILE_PATH)"
else
  # Non-blocking: lint failures are warnings only
  echo "lint-on-save: WARN — lint issues in $FILE_PATH (non-blocking)" >&2
fi

exit 0
