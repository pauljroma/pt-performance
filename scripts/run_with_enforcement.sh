#!/bin/bash
# Run With Enforcement
# Executes commands with safety checks and validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPO_HOME="${EXPO_HOME:-/Users/expo/Code/expo}"

echo "========================================="
echo "RUN WITH ENFORCEMENT"
echo "========================================="

# Preflight validation
if [[ -f "$SCRIPT_DIR/agent_preflight_validator.py" ]]; then
    echo "Running preflight checks..."
    python3 "$SCRIPT_DIR/agent_preflight_validator.py" || {
        echo "✗ Preflight checks failed"
        exit 1
    }
fi

# Execute command
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <command> [args...]"
    exit 1
fi

echo ""
echo "Executing: $*"
echo ""

# Run the command
"$@"
EXIT_CODE=$?

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✓ Command completed successfully"
else
    echo "✗ Command failed with exit code $EXIT_CODE"
fi

exit $EXIT_CODE
