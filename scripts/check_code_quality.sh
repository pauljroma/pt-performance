#!/bin/bash
#
# Code Quality Check Script
# Scans Swift code for dangerous patterns and anti-patterns
#
# Usage: ./scripts/check_code_quality.sh [options]
#
# Options:
#   --fix         Auto-fix some issues (TODO: not implemented)
#   --verbose     Show all matches, not just counts
#   --strict      Fail on warnings too
#   --report      Generate JSON report
#   --help        Show this help
#
# Checks performed:
#   1. Force unwraps (!) in production code
#   2. Hardcoded API keys and secrets
#   3. TODO/FIXME in critical paths
#   4. print() statements (should use DebugLogger)
#   5. Commented-out code blocks
#   6. Large files (>500 lines)
#   7. Deprecated API usage
#
# Exit Codes:
#   0 - No issues found
#   1 - Issues found (blocking)
#   2 - Warnings only (non-blocking unless --strict)
#

set -o pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_PROJECT_DIR="$PROJECT_ROOT/ios-app/PTPerformance"

# Thresholds
MAX_FORCE_UNWRAPS=5          # Per file
MAX_FILE_LINES=500           # Lines per file
MAX_PRINT_STATEMENTS=0       # Should be 0 in production

# Colors
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# Options
VERBOSE=false
STRICT=false
GENERATE_REPORT=false

# Counters
ERRORS=0
WARNINGS=0

# Parse arguments
for arg in "$@"; do
    case $arg in
        --verbose)
            VERBOSE=true
            ;;
        --strict)
            STRICT=true
            ;;
        --report)
            GENERATE_REPORT=true
            ;;
        --help|-h)
            head -30 "$0" | tail -28
            exit 0
            ;;
    esac
done

# Exclusion patterns
EXCLUDE_PATTERNS=(
    "*/Tests/*"
    "*/PTPerformanceTests/*"
    "*/PTPerformanceUITests/*"
    "*Test*.swift"
    "*Tests.swift"
    "*Mock*.swift"
    "*Preview*.swift"
    "*Previews.swift"
    "*/Previews/*"
    "*_Previews.swift"
    "*/build/*"
    "*/.build/*"
    "*/Pods/*"
    "*/Carthage/*"
)

build_exclude_args() {
    local args=""
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        args="$args ! -path \"$pattern\""
    done
    echo "$args"
}

find_swift_files() {
    local exclude_args=$(build_exclude_args)
    eval "find \"$IOS_PROJECT_DIR\" -name '*.swift' $exclude_args -type f 2>/dev/null"
}

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}======================================${NC}"
    echo -e "${CYAN}${BOLD}      CODE QUALITY CHECKS${NC}"
    echo -e "${CYAN}${BOLD}======================================${NC}"
    echo ""
}

print_check() {
    local status="$1"
    local name="$2"
    local detail="$3"

    case $status in
        PASS)
            echo -e "${GREEN}[PASS]${NC} $name"
            ;;
        FAIL)
            echo -e "${RED}[FAIL]${NC} $name"
            [ -n "$detail" ] && echo -e "       ${RED}$detail${NC}"
            ((ERRORS++))
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $name"
            [ -n "$detail" ] && echo -e "       ${YELLOW}$detail${NC}"
            ((WARNINGS++))
            ;;
    esac
}

# ============================================================
# CHECK 1: Force Unwraps
# ============================================================
check_force_unwraps() {
    echo -e "${BLUE}Checking for force unwraps...${NC}"

    local files_with_issues=0
    local total_issues=0

    while IFS= read -r file; do
        # Count force unwraps (! not followed by =, excluding string literals and comments)
        # Look for patterns like: variable!, try!, as!
        local count=$(grep -E '(\w+!(?!=)|try!|as!)' "$file" 2>/dev/null | \
            grep -v "^[[:space:]]*//\|^[[:space:]]*\*\|\".*!\"|/\*.*!\|!.*\*/" | \
            wc -l | tr -d ' ')

        if [ "$count" -gt "$MAX_FORCE_UNWRAPS" ]; then
            ((files_with_issues++))
            ((total_issues += count))
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${YELLOW}$file: $count force unwraps${NC}"
            fi
        fi
    done < <(find_swift_files)

    if [ "$files_with_issues" -eq 0 ]; then
        print_check "PASS" "Force unwraps"
    elif [ "$total_issues" -gt 50 ]; then
        print_check "FAIL" "Force unwraps" "$files_with_issues files exceed threshold ($total_issues total)"
    else
        print_check "WARN" "Force unwraps" "$files_with_issues files have excessive force unwraps"
    fi
}

# ============================================================
# CHECK 2: Hardcoded Secrets
# ============================================================
check_hardcoded_secrets() {
    echo -e "${BLUE}Checking for hardcoded secrets...${NC}"

    local patterns=(
        'sk_live_[a-zA-Z0-9]+'               # Stripe live keys
        'pk_live_[a-zA-Z0-9]+'               # Stripe publishable keys
        'api[_-]?key\s*=\s*"[a-zA-Z0-9]{32,}'  # Generic API keys (32+ chars, assignment only)
        'secret[_-]?key\s*=\s*"[a-zA-Z0-9]{20,}' # Secret keys (20+ chars, assignment only)
        'AWSKEY[A-Z0-9]{16,}'                # AWS keys
        'ghp_[a-zA-Z0-9]{36}'                # GitHub tokens
        'xox[baprs]-[a-zA-Z0-9-]+'           # Slack tokens
    )

    local found=0

    for pattern in "${patterns[@]}"; do
        while IFS= read -r file; do
            local matches=$(grep -lE "$pattern" "$file" 2>/dev/null)
            if [ -n "$matches" ]; then
                ((found++))
                if [ "$VERBOSE" = true ]; then
                    echo -e "  ${RED}$file: potential secret${NC}"
                fi
            fi
        done < <(find_swift_files)
    done

    if [ "$found" -eq 0 ]; then
        print_check "PASS" "Hardcoded secrets"
    else
        print_check "FAIL" "Hardcoded secrets" "Found $found files with potential secrets"
    fi
}

# ============================================================
# CHECK 3: TODO/FIXME in Critical Paths
# ============================================================
check_todos() {
    echo -e "${BLUE}Checking for TODO/FIXME markers...${NC}"

    # Critical paths that shouldn't have TODOs
    local critical_dirs=(
        "Services"
        "ViewModels"
        "Auth"
    )

    local critical_todos=0
    local total_todos=0

    # Count all TODOs first
    total_todos=$(find_swift_files | xargs grep -lE "(TODO|FIXME|XXX|HACK)" 2>/dev/null | wc -l | tr -d ' ')

    # Check critical paths
    for dir in "${critical_dirs[@]}"; do
        local count=$(find "$IOS_PROJECT_DIR" -path "*/$dir/*" -name "*.swift" \
            ! -path "*/Tests/*" \
            -exec grep -lE "(TODO|FIXME|XXX|HACK)" {} \; 2>/dev/null | wc -l | tr -d ' ')
        ((critical_todos += count))
    done

    if [ "$critical_todos" -eq 0 ]; then
        if [ "$total_todos" -gt 20 ]; then
            print_check "WARN" "TODO/FIXME markers" "$total_todos total (consider cleanup)"
        else
            print_check "PASS" "TODO/FIXME markers" "$total_todos total"
        fi
    else
        print_check "WARN" "TODO/FIXME markers" "$critical_todos in critical paths, $total_todos total"
    fi
}

# ============================================================
# CHECK 4: Print Statements
# ============================================================
check_print_statements() {
    echo -e "${BLUE}Checking for print() statements...${NC}"

    local count=0

    while IFS= read -r file; do
        # Count print() statements not in comments
        local file_count=$(grep -E '^\s*print\(' "$file" 2>/dev/null | \
            grep -v "^[[:space:]]*//\|DebugLogger\|Logger" | wc -l | tr -d ' ')
        ((count += file_count))

        if [ "$VERBOSE" = true ] && [ "$file_count" -gt 0 ]; then
            echo -e "  ${YELLOW}$file: $file_count print statements${NC}"
        fi
    done < <(find_swift_files)

    if [ "$count" -eq 0 ]; then
        print_check "PASS" "Print statements"
    else
        # Print statements are a warning, not a blocking error
        # They should be migrated to DebugLogger over time
        print_check "WARN" "Print statements" "$count found (migrate to DebugLogger)"
    fi
}

# ============================================================
# CHECK 5: Commented-Out Code
# ============================================================
check_commented_code() {
    echo -e "${BLUE}Checking for commented-out code...${NC}"

    local files_with_commented_code=0

    while IFS= read -r file; do
        # Look for patterns like //func, //class, //var, //let, //if, //for
        local count=$(grep -E '^[[:space:]]*//[[:space:]]*(func|class|struct|enum|var|let|if|for|while|switch|guard|return)[[:space:]]' "$file" 2>/dev/null | wc -l | tr -d ' ')

        if [ "$count" -gt 5 ]; then
            ((files_with_commented_code++))
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${YELLOW}$file: $count lines of commented code${NC}"
            fi
        fi
    done < <(find_swift_files)

    if [ "$files_with_commented_code" -eq 0 ]; then
        print_check "PASS" "Commented-out code"
    else
        print_check "WARN" "Commented-out code" "$files_with_commented_code files with significant commented code"
    fi
}

# ============================================================
# CHECK 6: Large Files
# ============================================================
check_file_sizes() {
    echo -e "${BLUE}Checking for large files...${NC}"

    local large_files=0

    while IFS= read -r file; do
        local lines=$(wc -l < "$file" | tr -d ' ')

        if [ "$lines" -gt "$MAX_FILE_LINES" ]; then
            ((large_files++))
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${YELLOW}$file: $lines lines${NC}"
            fi
        fi
    done < <(find_swift_files)

    if [ "$large_files" -eq 0 ]; then
        print_check "PASS" "File sizes"
    else
        print_check "WARN" "File sizes" "$large_files files exceed $MAX_FILE_LINES lines"
    fi
}

# ============================================================
# CHECK 7: Deprecated API Usage
# ============================================================
check_deprecated_apis() {
    echo -e "${BLUE}Checking for deprecated API usage...${NC}"

    local deprecated_patterns=(
        'UIApplication.shared.keyWindow'         # Deprecated in iOS 15
        'topViewController'                      # Often deprecated
        'UIAlertView'                           # Use UIAlertController
        'UIActionSheet'                         # Use UIAlertController
        '@IBAction'                             # SwiftUI migration check
        'UITableViewCell'                       # SwiftUI migration check
    )

    local found=0

    for pattern in "${deprecated_patterns[@]}"; do
        local count=$(find_swift_files | xargs grep -l "$pattern" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            ((found += count))
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${YELLOW}$pattern: $count files${NC}"
            fi
        fi
    done

    if [ "$found" -eq 0 ]; then
        print_check "PASS" "Deprecated APIs"
    else
        print_check "WARN" "Deprecated APIs" "$found potential deprecated usages"
    fi
}

# ============================================================
# Summary
# ============================================================
print_summary() {
    echo ""
    echo -e "${CYAN}${BOLD}======================================${NC}"
    echo -e "${CYAN}${BOLD}           SUMMARY${NC}"
    echo -e "${CYAN}${BOLD}======================================${NC}"
    echo ""

    if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}All checks passed!${NC}"
        echo ""
        return 0
    elif [ "$ERRORS" -eq 0 ]; then
        echo -e "${YELLOW}Checks passed with $WARNINGS warning(s)${NC}"
        echo ""
        if [ "$STRICT" = true ]; then
            echo -e "${RED}Strict mode: treating warnings as errors${NC}"
            return 1
        fi
        return 0
    else
        echo -e "${RED}${BOLD}$ERRORS error(s) and $WARNINGS warning(s) found${NC}"
        echo ""
        echo "Please fix the issues above before deployment."
        echo ""
        return 1
    fi
}

# ============================================================
# Main
# ============================================================
main() {
    print_header

    if [ ! -d "$IOS_PROJECT_DIR" ]; then
        echo -e "${RED}Error: Project directory not found: $IOS_PROJECT_DIR${NC}"
        exit 2
    fi

    check_force_unwraps
    check_hardcoded_secrets
    check_todos
    check_print_statements
    check_commented_code
    check_file_sizes
    check_deprecated_apis

    print_summary
    exit $?
}

main "$@"
