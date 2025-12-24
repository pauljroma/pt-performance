#!/bin/bash
#
# test.sh - Run Python tests for linear-bootstrap
#
# Usage:
#   tools/python/test.sh              # Run all tests
#   tools/python/test.sh --unit       # Unit tests only
#   tools/python/test.sh --integration # Integration tests only
#   tools/python/test.sh --coverage   # Run with coverage report
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MODE="${1:---all}"

usage() {
    echo "Usage: $0 [--all|--unit|--integration|--coverage]"
    echo ""
    echo "Test modes:"
    echo "  --all          Run all tests (default)"
    echo "  --unit         Run unit tests only"
    echo "  --integration  Run integration tests only"
    echo "  --coverage     Run with coverage report"
    echo ""
    exit 1
}

# Check if pytest is available
check_pytest() {
    if ! command -v pytest &> /dev/null; then
        echo -e "${YELLOW}⚠️  pytest not installed${NC}"
        echo ""
        echo "Install with:"
        echo "  pip install pytest pytest-cov"
        echo ""
        exit 1
    fi
}

# Run unit tests
run_unit_tests() {
    echo -e "${GREEN}🧪 Running unit tests...${NC}"

    cd "$ROOT_DIR"

    if [[ -d tests/unit ]]; then
        pytest tests/unit/ -v
    else
        echo -e "${YELLOW}⚠️  No unit tests found (tests/unit/ doesn't exist)${NC}"
        return 0
    fi
}

# Run integration tests
run_integration_tests() {
    echo -e "${GREEN}🧪 Running integration tests...${NC}"

    cd "$ROOT_DIR"

    if [[ -d tests/integration ]]; then
        pytest tests/integration/ -v
    else
        echo -e "${YELLOW}⚠️  No integration tests found (tests/integration/ doesn't exist)${NC}"
        return 0
    fi
}

# Run all tests
run_all_tests() {
    echo -e "${GREEN}🧪 Running all tests...${NC}"

    cd "$ROOT_DIR"

    if [[ -d tests ]]; then
        pytest tests/ -v
    else
        echo -e "${YELLOW}⚠️  No tests directory found${NC}"
        echo "Creating test structure..."
        mkdir -p tests/unit tests/integration tests/fixtures
        echo -e "${GREEN}✅ Test directories created${NC}"
        echo ""
        echo "Add test files to tests/unit/ and tests/integration/"
        return 0
    fi
}

# Run tests with coverage
run_with_coverage() {
    echo -e "${GREEN}🧪 Running tests with coverage...${NC}"

    cd "$ROOT_DIR"

    if ! command -v pytest-cov &> /dev/null; then
        echo -e "${YELLOW}⚠️  pytest-cov not installed${NC}"
        echo "Install with: pip install pytest-cov"
        echo ""
        echo "Running without coverage..."
        run_all_tests
        return
    fi

    if [[ -d tests ]]; then
        pytest tests/ -v \
            --cov=scripts \
            --cov=tools/python \
            --cov-report=term-missing \
            --cov-report=html

        echo ""
        echo -e "${GREEN}📊 Coverage report generated: htmlcov/index.html${NC}"
    else
        echo -e "${YELLOW}⚠️  No tests directory found${NC}"
        return 0
    fi
}

# Run validation tests (article validation, etc.)
run_validation_tests() {
    echo -e "${GREEN}✓ Running validation tests...${NC}"

    # Validate articles if they exist
    if [[ -d "$ROOT_DIR/docs/help-articles" ]]; then
        echo -e "${GREEN}Validating articles...${NC}"
        python3 "$ROOT_DIR/tools/python/validate_articles.py" "$ROOT_DIR/docs/help-articles"
    fi

    # TODO: Add more validation tests here
}

# Main execution
check_pytest

case "$MODE" in
    --all)
        run_all_tests
        echo ""
        echo -e "${GREEN}✅ All tests complete!${NC}"
        ;;

    --unit)
        run_unit_tests
        echo ""
        echo -e "${GREEN}✅ Unit tests complete!${NC}"
        ;;

    --integration)
        run_integration_tests
        echo ""
        echo -e "${GREEN}✅ Integration tests complete!${NC}"
        ;;

    --coverage)
        run_with_coverage
        echo ""
        echo -e "${GREEN}✅ Tests with coverage complete!${NC}"
        ;;

    --validate)
        run_validation_tests
        echo ""
        echo -e "${GREEN}✅ Validation tests complete!${NC}"
        ;;

    *)
        echo -e "${RED}❌ Unknown mode: $MODE${NC}"
        usage
        ;;
esac
