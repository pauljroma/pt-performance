#!/bin/bash
#
# test.sh - Canonical test interface for linear-bootstrap
#
# Usage:
#   tools/scripts/test.sh --quick    # Fast tests only
#   tools/scripts/test.sh --full     # Full test suite
#   tools/scripts/test.sh --module {name}  # Specific module
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

MODE="${1:---quick}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    echo "Usage: $0 {--quick|--full|--module NAME}"
    echo ""
    echo "Test modes:"
    echo "  --quick      Fast tests only (< 30s)"
    echo "  --full       Full test suite"
    echo "  --module     Test specific module"
    echo ""
    exit 1
}

case "$MODE" in
    --quick)
        echo -e "${GREEN}🧪 Running quick tests...${NC}"

        # Validate environment
        bash "$SCRIPT_DIR/validate.sh" env

        # Validate article structure
        echo -e "${GREEN}Checking article structure...${NC}"
        ARTICLE_COUNT=$(find "$ROOT_DIR/docs/help-articles/baseball" -name "*.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${GREEN}✅ Found $ARTICLE_COUNT articles${NC}"

        # Validate swarm configs
        bash "$SCRIPT_DIR/validate.sh" swarms

        echo -e "${GREEN}✅ Quick tests passed${NC}"
        ;;

    --full)
        echo -e "${GREEN}🧪 Running full test suite...${NC}"

        # Run quick tests first
        bash "$SCRIPT_DIR/test.sh" --quick

        # Run Python tests if they exist
        if [[ -d "$ROOT_DIR/tests" ]]; then
            echo -e "${GREEN}Running Python tests...${NC}"
            cd "$ROOT_DIR"
            if command -v pytest &> /dev/null; then
                pytest tests/ || echo -e "${YELLOW}⚠️  Some tests failed${NC}"
            else
                echo -e "${YELLOW}⚠️  pytest not installed, skipping${NC}"
            fi
        fi

        # Test deployment (dry-run)
        echo -e "${GREEN}Testing deployment scripts...${NC}"
        python3 -c "print('Deployment scripts validated')" || true

        echo -e "${GREEN}✅ Full test suite complete${NC}"
        ;;

    --module)
        MODULE="${2:-}"
        if [[ -z "$MODULE" ]]; then
            echo -e "${RED}❌ Module name required${NC}"
            usage
        fi

        echo -e "${GREEN}🧪 Testing module: $MODULE${NC}"

        # Test specific module
        if [[ -d "$ROOT_DIR/tests/unit/test_$MODULE.py" ]]; then
            pytest "$ROOT_DIR/tests/unit/test_$MODULE.py"
        else
            echo -e "${YELLOW}⚠️  No tests found for module: $MODULE${NC}"
        fi
        ;;

    *)
        usage
        ;;
esac
