#!/bin/bash
#
# validate.sh - Validate swarm configs and sessions
#
# Purpose: Validate YAML configs, check session integrity
# Usage:
#   .swarms/bin/validate.sh CONFIG_FILE
#   .swarms/bin/validate.sh all
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWARMS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${SWARMS_DIR}/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET="${1:-all}"

usage() {
    echo "Usage: $0 {CONFIG_FILE|all}"
    echo ""
    echo "Validate swarm configurations and sessions."
    echo ""
    echo "Examples:"
    echo "  $0 .swarms/configs/infrastructure/ARCHITECTURE_ROLLOUT.yaml"
    echo "  $0 all  # Validate all configs"
    echo ""
    exit 1
}

validate_yaml_syntax() {
    local file=$1

    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}   ⚠️  Python3 not found, skipping YAML validation${NC}"
        return 0
    fi

    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo -e "${GREEN}   ✅ YAML syntax valid${NC}"
        return 0
    else
        echo -e "${RED}   ❌ YAML syntax error${NC}"
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1 || true
        return 1
    fi
}

validate_config_structure() {
    local file=$1

    echo -e "${GREEN}   Checking required fields...${NC}"

    # Check for required fields
    local has_name=$(grep -c "^name:" "$file" || echo "0")
    local has_agents=$(grep -c "^agents:" "$file" || echo "0")

    if [[ $has_name -eq 0 ]]; then
        echo -e "${RED}   ❌ Missing required field: name${NC}"
        return 1
    fi

    if [[ $has_agents -eq 0 ]]; then
        echo -e "${RED}   ❌ Missing required field: agents${NC}"
        return 1
    fi

    echo -e "${GREEN}   ✅ Required fields present${NC}"

    # Check for agent structure
    if ! grep -q "id:" "$file"; then
        echo -e "${YELLOW}   ⚠️  No agent IDs found${NC}"
    fi

    if ! grep -q "deliverables:" "$file"; then
        echo -e "${YELLOW}   ⚠️  No deliverables defined${NC}"
    fi

    return 0
}

validate_single_config() {
    local config_file=$1

    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}❌ Config file not found: $config_file${NC}"
        return 1
    fi

    echo -e "${GREEN}🔍 Validating: $(basename "$config_file")${NC}"

    # Validate YAML syntax
    validate_yaml_syntax "$config_file" || return 1

    # Validate structure
    validate_config_structure "$config_file" || return 1

    echo -e "${GREEN}✅ Config valid${NC}"
    echo ""

    return 0
}

validate_all_configs() {
    echo -e "${GREEN}🔍 Validating all swarm configs...${NC}"
    echo ""

    local errors=0
    local total=0

    # Find all YAML files in configs/
    while IFS= read -r config; do
        total=$((total + 1))

        if ! validate_single_config "$config"; then
            errors=$((errors + 1))
        fi
    done < <(find "$SWARMS_DIR/configs" -name "*.yaml" -o -name "*.yml")

    echo "=" * 60
    echo -e "${GREEN}VALIDATION SUMMARY${NC}"
    echo "=" * 60

    echo -e "\n📊 Total configs: $total"
    echo -e "✅ Valid: $((total - errors))"

    if [[ $errors -gt 0 ]]; then
        echo -e "${RED}❌ Errors: $errors${NC}"
        return 1
    else
        echo -e "${GREEN}✅ All configs valid!${NC}"
    fi

    echo ""
    return 0
}

validate_session() {
    local session_dir=$1

    echo -e "${GREEN}🔍 Validating session: $(basename "$session_dir")${NC}"

    # Check for session.json
    if [[ -f "$session_dir/session.json" ]]; then
        echo -e "${GREEN}   ✅ session.json found${NC}"

        # Validate JSON syntax
        if command -v jq &> /dev/null; then
            if jq empty "$session_dir/session.json" 2>/dev/null; then
                echo -e "${GREEN}   ✅ session.json valid${NC}"
            else
                echo -e "${RED}   ❌ session.json invalid${NC}"
                return 1
            fi
        fi
    else
        echo -e "${YELLOW}   ⚠️  No session.json (basic session)${NC}"
    fi

    # Check for outcome files
    local outcome_count=$(find "$session_dir" -name "*.md" | wc -l | tr -d ' ')
    echo -e "${GREEN}   📄 Outcome files: $outcome_count${NC}"

    echo -e "${GREEN}✅ Session valid${NC}"
    echo ""

    return 0
}

validate_all_sessions() {
    echo -e "${GREEN}🔍 Validating all sessions...${NC}"
    echo ""

    local errors=0
    local total=0

    if [[ ! -d "$SWARMS_DIR/sessions" ]]; then
        echo -e "${YELLOW}⚠️  No sessions directory${NC}"
        return 0
    fi

    # Find all session directories
    while IFS= read -r session_dir; do
        total=$((total + 1))

        if ! validate_session "$session_dir"; then
            errors=$((errors + 1))
        fi
    done < <(find "$SWARMS_DIR/sessions" -mindepth 1 -maxdepth 1 -type d)

    echo "=" * 60
    echo -e "${GREEN}SESSION VALIDATION SUMMARY${NC}"
    echo "=" * 60

    echo -e "\n📊 Total sessions: $total"
    echo -e "✅ Valid: $((total - errors))"

    if [[ $errors -gt 0 ]]; then
        echo -e "${RED}❌ Errors: $errors${NC}"
        return 1
    else
        echo -e "${GREEN}✅ All sessions valid!${NC}"
    fi

    echo ""
    return 0
}

# Main execution
case "$TARGET" in
    all)
        validate_all_configs
        result_configs=$?

        validate_all_sessions
        result_sessions=$?

        if [[ $result_configs -eq 0 && $result_sessions -eq 0 ]]; then
            echo -e "${GREEN}✅ All validations passed!${NC}"
            exit 0
        else
            echo -e "${RED}❌ Some validations failed${NC}"
            exit 1
        fi
        ;;

    *.yaml|*.yml)
        validate_single_config "$TARGET"
        ;;

    *)
        echo -e "${RED}❌ Unknown target: $TARGET${NC}"
        usage
        ;;
esac
