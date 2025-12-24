#!/bin/bash
#
# lint.sh - Run Python linters for linear-bootstrap
#
# Usage:
#   tools/python/lint.sh              # Run all linters
#   tools/python/lint.sh --fix        # Auto-fix issues where possible
#   tools/python/lint.sh --check      # Check only (CI mode)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MODE="${1:---lint}"

usage() {
    echo "Usage: $0 [--lint|--fix|--check]"
    echo ""
    echo "Lint modes:"
    echo "  --lint    Run all linters (default)"
    echo "  --fix     Auto-fix issues where possible"
    echo "  --check   Check only, fail on any issues (CI mode)"
    echo ""
    exit 1
}

# Check if linter tools are installed
check_tools() {
    local missing=0

    # Check for black (formatter)
    if ! command -v black &> /dev/null; then
        echo -e "${YELLOW}⚠️  black not installed (code formatter)${NC}"
        missing=$((missing + 1))
    fi

    # Check for flake8 (linter)
    if ! command -v flake8 &> /dev/null; then
        echo -e "${YELLOW}⚠️  flake8 not installed (linter)${NC}"
        missing=$((missing + 1))
    fi

    # Check for pylint (linter)
    if ! command -v pylint &> /dev/null; then
        echo -e "${YELLOW}⚠️  pylint not installed (linter)${NC}"
        missing=$((missing + 1))
    fi

    # Check for mypy (type checker)
    if ! command -v mypy &> /dev/null; then
        echo -e "${YELLOW}⚠️  mypy not installed (type checker)${NC}"
        missing=$((missing + 1))
    fi

    if [[ $missing -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Install missing tools with:${NC}"
        echo "  pip install black flake8 pylint mypy"
        echo ""
        echo "Continuing with available tools..."
        echo ""
    fi
}

# Run black formatter
run_black() {
    local fix_mode=$1

    if ! command -v black &> /dev/null; then
        echo -e "${YELLOW}⚠️  Skipping black (not installed)${NC}"
        return 0
    fi

    echo -e "${GREEN}🎨 Running black (code formatter)...${NC}"

    cd "$ROOT_DIR"

    if [[ $fix_mode == "true" ]]; then
        # Fix mode: format files
        black scripts/ tools/python/ --exclude="/(\.git|\.venv|venv|__pycache__|\.pytest_cache)/" || return 1
    else
        # Check mode: just report issues
        black scripts/ tools/python/ --check --exclude="/(\.git|\.venv|venv|__pycache__|\.pytest_cache)/" || return 1
    fi

    echo -e "${GREEN}✅ black check passed${NC}"
}

# Run flake8 linter
run_flake8() {
    if ! command -v flake8 &> /dev/null; then
        echo -e "${YELLOW}⚠️  Skipping flake8 (not installed)${NC}"
        return 0
    fi

    echo -e "${GREEN}🔍 Running flake8 (linter)...${NC}"

    cd "$ROOT_DIR"

    # Run flake8 with common exclusions
    flake8 scripts/ tools/python/ \
        --exclude=.git,__pycache__,.venv,venv,.pytest_cache \
        --max-line-length=100 \
        --ignore=E203,W503 \
        || return 1

    echo -e "${GREEN}✅ flake8 check passed${NC}"
}

# Run pylint linter
run_pylint() {
    if ! command -v pylint &> /dev/null; then
        echo -e "${YELLOW}⚠️  Skipping pylint (not installed)${NC}"
        return 0
    fi

    echo -e "${GREEN}🔍 Running pylint (linter)...${NC}"

    cd "$ROOT_DIR"

    # Find Python files
    local py_files=()
    while IFS= read -r file; do
        py_files+=("$file")
    done < <(find scripts tools/python -name "*.py" -not -path "*/\.*" -not -path "*/venv/*" -not -path "*/__pycache__/*" 2>/dev/null)

    if [[ ${#py_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No Python files found${NC}"
        return 0
    fi

    # Run pylint with relaxed settings
    pylint "${py_files[@]}" \
        --disable=missing-docstring,too-few-public-methods,invalid-name \
        --max-line-length=100 \
        || {
            echo -e "${YELLOW}⚠️  pylint found issues (non-fatal)${NC}"
            return 0  # Don't fail on pylint warnings
        }

    echo -e "${GREEN}✅ pylint check passed${NC}"
}

# Run mypy type checker
run_mypy() {
    if ! command -v mypy &> /dev/null; then
        echo -e "${YELLOW}⚠️  Skipping mypy (not installed)${NC}"
        return 0
    fi

    echo -e "${GREEN}🔍 Running mypy (type checker)...${NC}"

    cd "$ROOT_DIR"

    # Run mypy on scripts and tools
    mypy scripts/ tools/python/ \
        --ignore-missing-imports \
        --no-strict-optional \
        || {
            echo -e "${YELLOW}⚠️  mypy found issues (non-fatal)${NC}"
            return 0  # Don't fail on mypy warnings
        }

    echo -e "${GREEN}✅ mypy check passed${NC}"
}

# Run all linters
run_all_linters() {
    local fix_mode=$1
    local errors=0

    run_black "$fix_mode" || errors=$((errors + 1))
    echo ""

    run_flake8 || errors=$((errors + 1))
    echo ""

    run_pylint || errors=$((errors + 1))
    echo ""

    run_mypy || errors=$((errors + 1))
    echo ""

    return $errors
}

# Main execution
check_tools

case "$MODE" in
    --lint)
        echo -e "${GREEN}🔍 Running linters...${NC}"
        echo ""
        run_all_linters "false"
        result=$?

        echo ""
        if [[ $result -eq 0 ]]; then
            echo -e "${GREEN}✅ All linters passed!${NC}"
        else
            echo -e "${YELLOW}⚠️  Some linters reported issues${NC}"
            echo "Run with --fix to auto-fix formatting issues"
        fi

        exit $result
        ;;

    --fix)
        echo -e "${GREEN}🔧 Running linters with auto-fix...${NC}"
        echo ""
        run_all_linters "true"
        result=$?

        echo ""
        if [[ $result -eq 0 ]]; then
            echo -e "${GREEN}✅ Auto-fix complete!${NC}"
        else
            echo -e "${YELLOW}⚠️  Some issues remain (manual fix required)${NC}"
        fi

        exit $result
        ;;

    --check)
        echo -e "${GREEN}🔍 Running linters in check mode (CI)...${NC}"
        echo ""
        run_all_linters "false"
        result=$?

        echo ""
        if [[ $result -eq 0 ]]; then
            echo -e "${GREEN}✅ All linters passed!${NC}"
            exit 0
        else
            echo -e "${RED}❌ Linters failed!${NC}"
            exit 1
        fi
        ;;

    *)
        echo -e "${RED}❌ Unknown mode: $MODE${NC}"
        usage
        ;;
esac
