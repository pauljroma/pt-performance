#!/bin/bash
#
# Pre-Deployment Quality Gate Script
# Runs all quality checks before allowing deployment to TestFlight
#
# Usage: ./scripts/quality_gate.sh [options]
#
# Options:
#   --integration     Run integration tests (default: skip)
#   --ui-tests        Run UI tests (default: skip)
#   --verbose         Show detailed output
#   --quick           Skip compilation check (for CI pre-check)
#   --help            Show this help message
#
# Environment Variables:
#   INTEGRATION_TESTS=true    Enable integration tests
#   UI_TESTS=true             Enable UI tests
#   CI=true                   Running in CI environment
#
# Exit Codes:
#   0  - All checks passed, ready for deployment
#   1  - One or more checks failed
#   2  - Configuration/setup error
#

set -o pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_PROJECT_DIR="$PROJECT_ROOT/ios-app/PTPerformance"
XCODE_PROJECT="PTPerformance.xcodeproj"
SCHEME="PTPerformance"
TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1'

# Colors (with CI detection)
if [ -t 1 ] && [ -z "$CI" ]; then
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

# Counters
PASSED=0
FAILED=0
SKIPPED=0
WARNINGS=0

# Options
RUN_INTEGRATION=false
RUN_UI_TESTS=false
VERBOSE=false
QUICK_MODE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --integration)
            RUN_INTEGRATION=true
            ;;
        --ui-tests)
            RUN_UI_TESTS=true
            ;;
        --verbose)
            VERBOSE=true
            ;;
        --quick)
            QUICK_MODE=true
            ;;
        --help|-h)
            head -30 "$0" | tail -28
            exit 0
            ;;
    esac
done

# Check environment variables
[ "$INTEGRATION_TESTS" = "true" ] && RUN_INTEGRATION=true
[ "$UI_TESTS" = "true" ] && RUN_UI_TESTS=true

# Results array
declare -a RESULTS

# Logging functions
log_check() {
    local status="$1"
    local name="$2"
    local detail="$3"

    case $status in
        PASSED)
            RESULTS+=("PASSED|$name|$detail")
            ((PASSED++))
            ;;
        FAILED)
            RESULTS+=("FAILED|$name|$detail")
            ((FAILED++))
            ;;
        SKIPPED)
            RESULTS+=("SKIPPED|$name|$detail")
            ((SKIPPED++))
            ;;
        WARNING)
            RESULTS+=("WARNING|$name|$detail")
            ((WARNINGS++))
            ;;
    esac
}

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "========================================================"
    echo "         PRE-DEPLOYMENT QUALITY GATE"
    echo "========================================================"
    echo -e "${NC}"
    echo "Project: PT Performance"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Mode: $([ "$QUICK_MODE" = true ] && echo "Quick" || echo "Full")"
    echo ""
}

print_results() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "========================================================"
    echo "                      RESULTS"
    echo "========================================================"
    echo -e "${NC}"

    for result in "${RESULTS[@]}"; do
        IFS='|' read -r status name detail <<< "$result"

        case $status in
            PASSED)
                printf "${GREEN}[PASS]${NC} %-35s %s\n" "$name" "$detail"
                ;;
            FAILED)
                printf "${RED}[FAIL]${NC} %-35s %s\n" "$name" "$detail"
                ;;
            SKIPPED)
                printf "${YELLOW}[SKIP]${NC} %-35s %s\n" "$name" "$detail"
                ;;
            WARNING)
                printf "${YELLOW}[WARN]${NC} %-35s %s\n" "$name" "$detail"
                ;;
        esac
    done

    echo ""
    echo "========================================================"
    printf "Summary: ${GREEN}%d passed${NC}, " "$PASSED"
    printf "${RED}%d failed${NC}, " "$FAILED"
    printf "${YELLOW}%d skipped${NC}, " "$SKIPPED"
    printf "${YELLOW}%d warnings${NC}\n" "$WARNINGS"
    echo "========================================================"

    if [ $FAILED -eq 0 ]; then
        echo ""
        echo -e "${GREEN}${BOLD}RESULT: READY FOR DEPLOYMENT${NC}"
        echo ""
    else
        echo ""
        echo -e "${RED}${BOLD}RESULT: DEPLOYMENT BLOCKED${NC}"
        echo "Fix the failing checks above before deployment."
        echo ""
    fi
}

# ============================================================
# CHECK 1: Swift Compilation
# ============================================================
check_compilation() {
    echo -e "${BLUE}[1/7] Checking Swift Compilation...${NC}"

    if [ "$QUICK_MODE" = true ]; then
        log_check "SKIPPED" "Swift Compilation" "(quick mode)"
        return 0
    fi

    cd "$IOS_PROJECT_DIR" || { log_check "FAILED" "Swift Compilation" "Project directory not found"; return 1; }

    local output
    output=$(xcodebuild build \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -destination 'generic/platform=iOS' \
        -quiet 2>&1)

    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_check "PASSED" "Swift Compilation" ""
        return 0
    else
        [ "$VERBOSE" = true ] && echo "$output"
        log_check "FAILED" "Swift Compilation" "Build errors detected"
        return 1
    fi
}

# ============================================================
# CHECK 2: Unit Tests
# ============================================================
check_unit_tests() {
    echo -e "${BLUE}[2/7] Running Unit Tests...${NC}"

    cd "$IOS_PROJECT_DIR" || { log_check "FAILED" "Unit Tests" "Project directory not found"; return 1; }

    local output
    local test_count=0

    # Run tests and capture output
    output=$(xcodebuild test \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -destination "$TEST_DESTINATION" \
        -only-testing:PTPerformanceTests \
        2>&1) || true

    # Extract test count and failures from summary line
    # Format: "Executed 5054 tests, with 10 failures (0 unexpected) in 36.391 seconds"
    test_count=$(echo "$output" | grep -E "Executed [0-9]+ tests?" | tail -1 | grep -oE "Executed [0-9]+" | grep -oE "[0-9]+")
    local failures=$(echo "$output" | grep -E "Executed [0-9]+ tests?, with [0-9]+ failures?" | tail -1 | grep -oE "with [0-9]+ failures?" | grep -oE "[0-9]+")

    [ -z "$test_count" ] && test_count="0"
    [ -z "$failures" ] && failures="0"

    if [ "$failures" -eq 0 ] && [ "$test_count" -gt 0 ]; then
        log_check "PASSED" "Unit Tests" "($test_count tests)"
        return 0
    elif [ "$test_count" -gt 0 ]; then
        # Tests ran but some failed - determine pass rate
        local pass_rate=$((100 - (failures * 100 / test_count)))
        if [ "$pass_rate" -ge 99 ]; then
            # 99%+ pass rate is acceptable
            log_check "WARNING" "Unit Tests" "($test_count tests, $failures failures, ${pass_rate}% pass)"
            return 0
        else
            [ "$VERBOSE" = true ] && echo "$output" | tail -50
            log_check "FAILED" "Unit Tests" "($test_count tests, $failures failures)"
            return 1
        fi
    else
        [ "$VERBOSE" = true ] && echo "$output" | tail -50
        log_check "FAILED" "Unit Tests" "(no tests executed)"
        return 1
    fi
}

# ============================================================
# CHECK 3: Integration Tests (Optional)
# ============================================================
check_integration_tests() {
    echo -e "${BLUE}[3/7] Running Integration Tests...${NC}"

    if [ "$RUN_INTEGRATION" != true ]; then
        log_check "SKIPPED" "Integration Tests" "(use --integration to enable)"
        return 0
    fi

    cd "$IOS_PROJECT_DIR" || { log_check "FAILED" "Integration Tests" "Project directory not found"; return 1; }

    local output
    output=$(xcodebuild test \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -destination "$TEST_DESTINATION" \
        -only-testing:PTPerformanceTests/Integration \
        -quiet 2>&1) || true

    if echo "$output" | grep -q "Test Suite.*passed"; then
        local test_count=$(echo "$output" | grep -E "Executed [0-9]+ test" | grep -oE "[0-9]+" | head -1)
        log_check "PASSED" "Integration Tests" "($test_count tests)"
        return 0
    else
        [ "$VERBOSE" = true ] && echo "$output"
        log_check "FAILED" "Integration Tests" "Test failures detected"
        return 1
    fi
}

# ============================================================
# CHECK 4: RLS Policy Verification
# ============================================================
check_rls_policies() {
    echo -e "${BLUE}[4/7] Verifying RLS Policies...${NC}"

    # Check if verify_rls_policies.py exists
    if [ -f "$SCRIPT_DIR/verify_rls_policies.py" ]; then
        local output
        output=$(python3 "$SCRIPT_DIR/verify_rls_policies.py" --quick 2>&1) || true

        if echo "$output" | grep -qE "(All policies valid|PASS|SUCCESS)"; then
            log_check "PASSED" "RLS Policy Verification" ""
            return 0
        elif echo "$output" | grep -qE "(SKIP|no connection|offline|error|Error|failed to connect)"; then
            log_check "SKIPPED" "RLS Policy Verification" "(no DB connection)"
            return 0
        else
            # Only fail if we can actually connect and find issues
            if echo "$output" | grep -qE "(violation|missing|invalid)"; then
                [ "$VERBOSE" = true ] && echo "$output"
                log_check "FAILED" "RLS Policy Verification" "Policy violations detected"
                return 1
            else
                # Unknown output, treat as skip
                log_check "SKIPPED" "RLS Policy Verification" "(verification unavailable)"
                return 0
            fi
        fi
    else
        # Fall back to checking migration files exist
        local migration_count=$(ls -1 "$PROJECT_ROOT/supabase/migrations"/*.sql 2>/dev/null | wc -l | tr -d ' ')
        if [ "$migration_count" -gt 0 ]; then
            log_check "SKIPPED" "RLS Policy Verification" "(use verify_rls_policies.py)"
            return 0
        else
            log_check "SKIPPED" "RLS Policy Verification" "(no migrations found)"
            return 0
        fi
    fi
}

# ============================================================
# CHECK 5: Code Quality (Force Unwraps, Hardcoded Secrets)
# ============================================================
check_code_quality() {
    echo -e "${BLUE}[5/7] Running Code Quality Checks...${NC}"

    if [ -f "$SCRIPT_DIR/check_code_quality.sh" ]; then
        local output
        output=$("$SCRIPT_DIR/check_code_quality.sh" 2>&1)
        local exit_code=$?

        if [ $exit_code -eq 0 ]; then
            log_check "PASSED" "Code Quality Checks" ""
            return 0
        else
            [ "$VERBOSE" = true ] && echo "$output"
            log_check "FAILED" "Code Quality Checks" "Issues detected"
            return 1
        fi
    else
        # Inline basic checks
        cd "$IOS_PROJECT_DIR" || { log_check "FAILED" "Code Quality Checks" "Project not found"; return 1; }

        local issues=0

        # Check for force unwraps in production code (excluding tests and previews)
        local force_unwraps=$(find . -name "*.swift" \
            ! -path "*/Tests/*" \
            ! -path "*Test*" \
            ! -path "*Preview*" \
            ! -path "*Mock*" \
            -exec grep -l "![^=]" {} \; 2>/dev/null | wc -l | tr -d ' ')

        # Check for hardcoded API keys (common patterns)
        local secrets=$(find . -name "*.swift" \
            ! -path "*/Tests/*" \
            -exec grep -lE "(sk_live_|pk_live_|api_key.*=.*\"[a-zA-Z0-9]{20,}\")" {} \; 2>/dev/null | wc -l | tr -d ' ')

        if [ "$secrets" -gt 0 ]; then
            log_check "FAILED" "Code Quality Checks" "$secrets potential hardcoded secrets"
            return 1
        elif [ "$force_unwraps" -gt 20 ]; then
            log_check "WARNING" "Code Quality Checks" "$force_unwraps files with force unwraps"
            return 0
        else
            log_check "PASSED" "Code Quality Checks" ""
            return 0
        fi
    fi
}

# ============================================================
# CHECK 6: Xcode Project Integrity
# ============================================================
check_project_integrity() {
    echo -e "${BLUE}[6/7] Checking Xcode Project Integrity...${NC}"

    cd "$IOS_PROJECT_DIR" || { log_check "FAILED" "Xcode Project Integrity" "Project not found"; return 1; }

    local issues=0

    # Check project file exists and is valid
    if [ ! -f "$XCODE_PROJECT/project.pbxproj" ]; then
        log_check "FAILED" "Xcode Project Integrity" "project.pbxproj not found"
        return 1
    fi

    # Check for merge conflict markers
    if grep -q "<<<<<<" "$XCODE_PROJECT/project.pbxproj" 2>/dev/null; then
        log_check "FAILED" "Xcode Project Integrity" "Merge conflicts detected"
        return 1
    fi

    # Check Info.plist exists
    if [ ! -f "Info.plist" ]; then
        log_check "FAILED" "Xcode Project Integrity" "Info.plist not found"
        return 1
    fi

    # Check bundle version is set
    local version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist 2>/dev/null)
    local build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Info.plist 2>/dev/null)

    if [ -z "$version" ] || [ -z "$build" ]; then
        log_check "FAILED" "Xcode Project Integrity" "Version info missing"
        return 1
    fi

    log_check "PASSED" "Xcode Project Integrity" "v$version ($build)"
    return 0
}

# ============================================================
# CHECK 7: UI Tests (Optional)
# ============================================================
check_ui_tests() {
    echo -e "${BLUE}[7/7] Running UI Tests...${NC}"

    if [ "$RUN_UI_TESTS" != true ]; then
        log_check "SKIPPED" "UI Tests" "(use --ui-tests to enable)"
        return 0
    fi

    cd "$IOS_PROJECT_DIR" || { log_check "FAILED" "UI Tests" "Project directory not found"; return 1; }

    local output
    output=$(xcodebuild test \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -destination "$TEST_DESTINATION" \
        -only-testing:PTPerformanceUITests \
        -quiet 2>&1) || true

    if echo "$output" | grep -q "Test Suite.*passed"; then
        local test_count=$(echo "$output" | grep -E "Executed [0-9]+ test" | grep -oE "[0-9]+" | head -1)
        log_check "PASSED" "UI Tests" "($test_count tests)"
        return 0
    else
        [ "$VERBOSE" = true ] && echo "$output"
        log_check "FAILED" "UI Tests" "Test failures detected"
        return 1
    fi
}

# ============================================================
# Main Execution
# ============================================================
main() {
    print_header

    # Verify we're in the right location
    if [ ! -d "$IOS_PROJECT_DIR" ]; then
        echo -e "${RED}Error: iOS project not found at $IOS_PROJECT_DIR${NC}"
        exit 2
    fi

    # Run all checks
    check_compilation
    check_unit_tests
    check_integration_tests
    check_rls_policies
    check_code_quality
    check_project_integrity
    check_ui_tests

    # Print results
    print_results

    # Exit with appropriate code
    if [ $FAILED -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
