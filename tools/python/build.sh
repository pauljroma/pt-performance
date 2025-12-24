#!/bin/bash
#
# build.sh - Build/compile Python modules for linear-bootstrap
#
# Usage:
#   tools/python/build.sh              # Build all
#   tools/python/build.sh --check      # Check only (no build)
#   tools/python/build.sh --clean      # Clean build artifacts
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MODE="${1:---build}"

usage() {
    echo "Usage: $0 [--build|--check|--clean]"
    echo ""
    echo "Build modes:"
    echo "  --build    Build/compile Python modules (default)"
    echo "  --check    Check syntax without building"
    echo "  --clean    Remove build artifacts"
    echo ""
    exit 1
}

# Check Python syntax for all Python files
check_syntax() {
    echo -e "${GREEN}🔍 Checking Python syntax...${NC}"

    local errors=0

    # Find all Python files
    while IFS= read -r py_file; do
        if ! python3 -m py_compile "$py_file" 2>/dev/null; then
            echo -e "${RED}❌ Syntax error in: $py_file${NC}"
            errors=$((errors + 1))
        fi
    done < <(find "$ROOT_DIR" -name "*.py" -not -path "*/\.*" -not -path "*/venv/*" -not -path "*/__pycache__/*")

    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}✅ All Python files have valid syntax${NC}"
        return 0
    else
        echo -e "${RED}❌ Found $errors files with syntax errors${NC}"
        return 1
    fi
}

# Clean build artifacts
clean_build() {
    echo -e "${GREEN}🧹 Cleaning build artifacts...${NC}"

    cd "$ROOT_DIR"

    # Remove __pycache__ directories
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

    # Remove .pyc files
    find . -type f -name "*.pyc" -delete 2>/dev/null || true

    # Remove .pyo files
    find . -type f -name "*.pyo" -delete 2>/dev/null || true

    # Remove build directories
    rm -rf build/ dist/ *.egg-info/ 2>/dev/null || true

    echo -e "${GREEN}✅ Build artifacts cleaned${NC}"
}

# Build Python modules
build_modules() {
    echo -e "${GREEN}🔨 Building Python modules...${NC}"

    cd "$ROOT_DIR"

    # Check if setup.py or pyproject.toml exists
    if [[ -f setup.py ]]; then
        echo -e "${GREEN}Building with setup.py...${NC}"
        python3 setup.py build
    elif [[ -f pyproject.toml ]]; then
        echo -e "${GREEN}Building with pyproject.toml...${NC}"
        if command -v pip &> /dev/null; then
            pip install -e .
        else
            echo -e "${YELLOW}⚠️  pip not available, skipping build${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No setup.py or pyproject.toml found${NC}"
        echo -e "${YELLOW}Skipping build (pure Python project)${NC}"
    fi

    # Compile all Python files to bytecode
    echo -e "${GREEN}Compiling Python bytecode...${NC}"
    python3 -m compileall -q "$ROOT_DIR/scripts" 2>/dev/null || true
    python3 -m compileall -q "$ROOT_DIR/tools" 2>/dev/null || true

    echo -e "${GREEN}✅ Build complete${NC}"
}

# Verify build output
verify_build() {
    echo -e "${GREEN}✓ Verifying build...${NC}"

    # Check if key modules are importable
    local errors=0

    # Try importing scripts/content modules
    if [[ -f "$ROOT_DIR/scripts/content/load_articles.py" ]]; then
        if ! python3 -c "import sys; sys.path.insert(0, '$ROOT_DIR'); from scripts.content import load_articles" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  Cannot import scripts.content.load_articles${NC}"
            errors=$((errors + 1))
        fi
    fi

    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}✅ Build verification passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Build verification had $errors warnings${NC}"
    fi
}

# Main execution
case "$MODE" in
    --build)
        check_syntax || exit 1
        clean_build
        build_modules
        verify_build
        echo ""
        echo -e "${GREEN}✅ Build complete!${NC}"
        ;;

    --check)
        check_syntax
        echo ""
        echo -e "${GREEN}✅ Syntax check complete!${NC}"
        ;;

    --clean)
        clean_build
        echo ""
        echo -e "${GREEN}✅ Clean complete!${NC}"
        ;;

    *)
        echo -e "${RED}❌ Unknown mode: $MODE${NC}"
        usage
        ;;
esac
