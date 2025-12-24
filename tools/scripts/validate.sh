#!/bin/bash
#
# validate.sh - Canonical validation interface for linear-bootstrap
#
# Usage:
#   tools/scripts/validate.sh articles   # Validate article frontmatter
#   tools/scripts/validate.sh swarms     # Validate swarm YAML configs
#   tools/scripts/validate.sh env        # Validate environment config
#   tools/scripts/validate.sh all        # Run all validations
#

set -euo pipefail

# Get the root directory of linear-bootstrap
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TARGET="${1:-all}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 {articles|swarms|env|all}"
    echo ""
    echo "Validation targets:"
    echo "  articles     Validate article frontmatter and structure"
    echo "  swarms       Validate swarm YAML configurations"
    echo "  env          Validate environment configuration"
    echo "  all          Run all validations"
    echo ""
    echo "Examples:"
    echo "  $0 articles"
    echo "  $0 all"
    exit 1
}

validate_articles() {
    echo -e "${GREEN}📚 Validating articles...${NC}"
    cd "$ROOT_DIR"

    # Check if Python validation script exists
    if [[ -f "tools/python/validate_articles.py" ]]; then
        python3 tools/python/validate_articles.py
    elif [[ -f "scripts/content/validate_frontmatter.py" ]]; then
        python3 scripts/content/validate_frontmatter.py
    else
        echo -e "${YELLOW}⚠️  Validation script not found, running basic checks${NC}"

        # Basic validation: check for .md files and frontmatter
        ARTICLE_DIR="docs/help-articles/baseball"
        ARTICLE_COUNT=$(find "$ARTICLE_DIR" -name "*.md" ! -name "README.md" | wc -l | tr -d ' ')

        echo "Found $ARTICLE_COUNT articles in $ARTICLE_DIR"

        # Check for files without frontmatter
        BAD_FILES=0
        while IFS= read -r file; do
            if ! head -1 "$file" | grep -q "^---$"; then
                echo -e "${RED}❌ Missing frontmatter: $file${NC}"
                ((BAD_FILES++))
            fi
        done < <(find "$ARTICLE_DIR" -name "*.md" ! -name "README.md")

        if [[ $BAD_FILES -eq 0 ]]; then
            echo -e "${GREEN}✅ All articles have frontmatter${NC}"
        else
            echo -e "${RED}❌ $BAD_FILES articles missing frontmatter${NC}"
            return 1
        fi
    fi
}

validate_swarms() {
    echo -e "${GREEN}🤖 Validating swarm configurations...${NC}"
    cd "$ROOT_DIR"

    # Check if swarm validation script exists
    if [[ -f ".swarms/bin/validate.sh" ]]; then
        bash .swarms/bin/validate.sh
    else
        echo -e "${YELLOW}⚠️  Swarm validation script not found, running basic YAML check${NC}"

        SWARM_DIR=".swarms/configs"
        if [[ ! -d "$SWARM_DIR" ]]; then
            echo -e "${YELLOW}⚠️  No swarm configs directory found${NC}"
            return 0
        fi

        SWARM_COUNT=$(find "$SWARM_DIR" -name "*.yaml" -o -name "*.yml" | wc -l | tr -d ' ')
        echo "Found $SWARM_COUNT swarm configs in $SWARM_DIR"

        # Check YAML syntax with Python
        BAD_CONFIGS=0
        while IFS= read -r file; do
            if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
                echo -e "${RED}❌ Invalid YAML: $file${NC}"
                ((BAD_CONFIGS++))
            fi
        done < <(find "$SWARM_DIR" -name "*.yaml" -o -name "*.yml")

        if [[ $BAD_CONFIGS -eq 0 ]]; then
            echo -e "${GREEN}✅ All swarm configs have valid YAML${NC}"
        else
            echo -e "${RED}❌ $BAD_CONFIGS swarm configs have invalid YAML${NC}"
            return 1
        fi
    fi
}

validate_env() {
    echo -e "${GREEN}⚙️  Validating environment configuration...${NC}"
    cd "$ROOT_DIR"

    # Check if .env exists
    if [[ ! -f .env ]]; then
        echo -e "${RED}❌ .env file not found${NC}"
        echo "Run: cp .env.template .env"
        return 1
    fi

    # Check required environment variables
    source .env

    REQUIRED_VARS=(
        "SUPABASE_URL"
        "SUPABASE_KEY"
    )

    MISSING_VARS=0
    for var in "${REQUIRED_VARS[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo -e "${RED}❌ Missing required variable: $var${NC}"
            ((MISSING_VARS++))
        else
            echo -e "${GREEN}✅ $var is set${NC}"
        fi
    done

    # Check optional but recommended variables
    OPTIONAL_VARS=(
        "SUPABASE_SERVICE_ROLE_KEY"
        "LINEAR_API_KEY"
        "LINEAR_TEAM_ID"
    )

    for var in "${OPTIONAL_VARS[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo -e "${YELLOW}⚠️  Optional variable not set: $var${NC}"
        else
            echo -e "${GREEN}✅ $var is set${NC}"
        fi
    done

    if [[ $MISSING_VARS -gt 0 ]]; then
        echo -e "${RED}❌ $MISSING_VARS required variables missing${NC}"
        return 1
    else
        echo -e "${GREEN}✅ All required environment variables are set${NC}"
    fi
}

case "$TARGET" in
    articles)
        validate_articles
        ;;

    swarms)
        validate_swarms
        ;;

    env)
        validate_env
        ;;

    all)
        echo -e "${GREEN}🔍 Running all validations...${NC}"
        echo ""

        FAILED=0

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if ! validate_env; then
            ((FAILED++))
        fi

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if ! validate_articles; then
            ((FAILED++))
        fi

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if ! validate_swarms; then
            ((FAILED++))
        fi

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if [[ $FAILED -eq 0 ]]; then
            echo -e "${GREEN}✅ All validations passed${NC}"
        else
            echo -e "${RED}❌ $FAILED validation(s) failed${NC}"
            exit 1
        fi
        ;;

    *)
        echo -e "${RED}❌ Unknown target: $TARGET${NC}"
        usage
        ;;
esac
