#!/bin/bash
#
# Run All Tests Script
# Runs all test suites and generates a comprehensive report
#
# Usage: ./scripts/run_all_tests.sh [options]
#
# Options:
#   --unit              Run only unit tests
#   --integration       Run only integration tests
#   --ui                Run only UI tests
#   --parallel          Run test suites in parallel (experimental)
#   --report            Generate JUnit XML report
#   --coverage          Generate code coverage report
#   --verbose           Show detailed test output
#   --destination STR   Override test destination
#   --help              Show this help
#
# Environment Variables:
#   TEST_DESTINATION    Override default simulator
#   SKIP_UNIT=true      Skip unit tests
#   SKIP_INTEGRATION=true Skip integration tests
#   SKIP_UI=true        Skip UI tests
#   CI=true             Running in CI mode
#
# Exit Codes:
#   0 - All tests passed
#   1 - One or more tests failed
#   2 - Configuration error
#

set -o pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_PROJECT_DIR="$PROJECT_ROOT/ios-app/PTPerformance"
XCODE_PROJECT="PTPerformance.xcodeproj"
SCHEME="PTPerformance"
DEFAULT_DESTINATION='platform=iOS Simulator,name=iPhone 15 Pro,OS=17.2'

# Output
REPORT_DIR="$PROJECT_ROOT/test-reports"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Colors
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

# Options
RUN_UNIT=true
RUN_INTEGRATION=true
RUN_UI=true
PARALLEL=false
GENERATE_REPORT=false
GENERATE_COVERAGE=false
VERBOSE=false
DESTINATION="${TEST_DESTINATION:-$DEFAULT_DESTINATION}"

# Check environment overrides
[ "$SKIP_UNIT" = "true" ] && RUN_UNIT=false
[ "$SKIP_INTEGRATION" = "true" ] && RUN_INTEGRATION=false
[ "$SKIP_UI" = "true" ] && RUN_UI=false

# Results
UNIT_RESULT=""
UNIT_COUNT=0
UNIT_FAILED=0
INTEGRATION_RESULT=""
INTEGRATION_COUNT=0
INTEGRATION_FAILED=0
UI_RESULT=""
UI_COUNT=0
UI_FAILED=0
START_TIME=$(date +%s)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit)
            RUN_UNIT=true
            RUN_INTEGRATION=false
            RUN_UI=false
            shift
            ;;
        --integration)
            RUN_UNIT=false
            RUN_INTEGRATION=true
            RUN_UI=false
            shift
            ;;
        --ui)
            RUN_UNIT=false
            RUN_INTEGRATION=false
            RUN_UI=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --report)
            GENERATE_REPORT=true
            shift
            ;;
        --coverage)
            GENERATE_COVERAGE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --destination)
            DESTINATION="$2"
            shift 2
            ;;
        --help|-h)
            head -35 "$0" | tail -33
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 2
            ;;
    esac
done

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "========================================================"
    echo "              PT PERFORMANCE TEST SUITE"
    echo "========================================================"
    echo -e "${NC}"
    echo "Project: $XCODE_PROJECT"
    echo "Scheme: $SCHEME"
    echo "Destination: $DESTINATION"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

extract_test_counts() {
    local output="$1"
    local executed=$(echo "$output" | grep -oE "Executed [0-9]+ test" | grep -oE "[0-9]+" | tail -1)
    local failures=$(echo "$output" | grep -oE "[0-9]+ failure" | grep -oE "[0-9]+" | head -1)

    echo "${executed:-0} ${failures:-0}"
}

# ============================================================
# Run Unit Tests
# ============================================================
run_unit_tests() {
    echo -e "${BLUE}${BOLD}Running Unit Tests...${NC}"
    echo ""

    local xcode_args=(
        -project "$XCODE_PROJECT"
        -scheme "$SCHEME"
        -destination "$DESTINATION"
        -only-testing:PTPerformanceTests
    )

    if [ "$GENERATE_COVERAGE" = true ]; then
        xcode_args+=(-enableCodeCoverage YES)
    fi

    local output
    local exit_code

    if [ "$VERBOSE" = true ]; then
        output=$(xcodebuild test "${xcode_args[@]}" 2>&1 | tee /dev/tty)
        exit_code=${PIPESTATUS[0]}
    else
        output=$(xcodebuild test "${xcode_args[@]}" -quiet 2>&1)
        exit_code=$?
    fi

    # Parse results
    read UNIT_COUNT UNIT_FAILED <<< $(extract_test_counts "$output")

    if [ $exit_code -eq 0 ]; then
        UNIT_RESULT="PASSED"
        echo -e "${GREEN}Unit tests passed ($UNIT_COUNT tests)${NC}"
    else
        UNIT_RESULT="FAILED"
        echo -e "${RED}Unit tests failed ($UNIT_FAILED failures out of $UNIT_COUNT tests)${NC}"

        if [ "$VERBOSE" != true ]; then
            echo ""
            echo "Failed tests:"
            echo "$output" | grep -E "^[[:space:]]*(.*)(FAILED|failed)" | head -20
        fi
    fi

    echo ""
    return $exit_code
}

# ============================================================
# Run Integration Tests
# ============================================================
run_integration_tests() {
    echo -e "${BLUE}${BOLD}Running Integration Tests...${NC}"
    echo ""

    # Check if integration tests exist
    if ! find "$IOS_PROJECT_DIR" -path "*/Tests/Integration/*" -name "*.swift" | grep -q .; then
        echo -e "${YELLOW}No integration tests found${NC}"
        INTEGRATION_RESULT="SKIPPED"
        echo ""
        return 0
    fi

    local xcode_args=(
        -project "$XCODE_PROJECT"
        -scheme "$SCHEME"
        -destination "$DESTINATION"
    )

    # Try to run integration-specific target or filter
    local test_target="PTPerformanceTests"
    local only_testing=""

    # Check for integration test directories
    if [ -d "$IOS_PROJECT_DIR/Tests/Integration" ]; then
        only_testing="-only-testing:PTPerformanceTests/Integration"
    fi

    local output
    local exit_code

    if [ "$VERBOSE" = true ]; then
        output=$(xcodebuild test "${xcode_args[@]}" $only_testing 2>&1 | tee /dev/tty)
        exit_code=${PIPESTATUS[0]}
    else
        output=$(xcodebuild test "${xcode_args[@]}" $only_testing -quiet 2>&1)
        exit_code=$?
    fi

    read INTEGRATION_COUNT INTEGRATION_FAILED <<< $(extract_test_counts "$output")

    if [ $exit_code -eq 0 ]; then
        INTEGRATION_RESULT="PASSED"
        echo -e "${GREEN}Integration tests passed ($INTEGRATION_COUNT tests)${NC}"
    else
        INTEGRATION_RESULT="FAILED"
        echo -e "${RED}Integration tests failed ($INTEGRATION_FAILED failures)${NC}"
    fi

    echo ""
    return $exit_code
}

# ============================================================
# Run UI Tests
# ============================================================
run_ui_tests() {
    echo -e "${BLUE}${BOLD}Running UI Tests...${NC}"
    echo ""

    local xcode_args=(
        -project "$XCODE_PROJECT"
        -scheme "$SCHEME"
        -destination "$DESTINATION"
        -only-testing:PTPerformanceUITests
    )

    local output
    local exit_code

    if [ "$VERBOSE" = true ]; then
        output=$(xcodebuild test "${xcode_args[@]}" 2>&1 | tee /dev/tty)
        exit_code=${PIPESTATUS[0]}
    else
        output=$(xcodebuild test "${xcode_args[@]}" -quiet 2>&1)
        exit_code=$?
    fi

    read UI_COUNT UI_FAILED <<< $(extract_test_counts "$output")

    if [ $exit_code -eq 0 ]; then
        UI_RESULT="PASSED"
        echo -e "${GREEN}UI tests passed ($UI_COUNT tests)${NC}"
    else
        UI_RESULT="FAILED"
        echo -e "${RED}UI tests failed ($UI_FAILED failures)${NC}"
    fi

    echo ""
    return $exit_code
}

# ============================================================
# Generate Report
# ============================================================
generate_report() {
    mkdir -p "$REPORT_DIR"

    local report_file="$REPORT_DIR/test_report_$TIMESTAMP.txt"

    {
        echo "PT Performance Test Report"
        echo "=========================="
        echo ""
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Duration: $(($(date +%s) - START_TIME)) seconds"
        echo ""
        echo "Results"
        echo "-------"
        echo ""
        echo "Unit Tests:        $UNIT_RESULT ($UNIT_COUNT tests, $UNIT_FAILED failures)"
        echo "Integration Tests: $INTEGRATION_RESULT ($INTEGRATION_COUNT tests, $INTEGRATION_FAILED failures)"
        echo "UI Tests:          $UI_RESULT ($UI_COUNT tests, $UI_FAILED failures)"
        echo ""
        echo "Total: $((UNIT_COUNT + INTEGRATION_COUNT + UI_COUNT)) tests"
        echo "Failed: $((UNIT_FAILED + INTEGRATION_FAILED + UI_FAILED))"
    } > "$report_file"

    echo -e "${GREEN}Report saved to: $report_file${NC}"
}

# ============================================================
# Print Summary
# ============================================================
print_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))

    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "========================================================"
    echo "                    TEST SUMMARY"
    echo "========================================================"
    echo -e "${NC}"

    local total_tests=$((UNIT_COUNT + INTEGRATION_COUNT + UI_COUNT))
    local total_failed=$((UNIT_FAILED + INTEGRATION_FAILED + UI_FAILED))

    # Unit Tests
    if [ "$RUN_UNIT" = true ]; then
        case $UNIT_RESULT in
            PASSED) echo -e "${GREEN}[PASS]${NC} Unit Tests         $UNIT_COUNT tests" ;;
            FAILED) echo -e "${RED}[FAIL]${NC} Unit Tests         $UNIT_FAILED/$UNIT_COUNT failed" ;;
            *)      echo -e "${YELLOW}[SKIP]${NC} Unit Tests" ;;
        esac
    fi

    # Integration Tests
    if [ "$RUN_INTEGRATION" = true ]; then
        case $INTEGRATION_RESULT in
            PASSED)  echo -e "${GREEN}[PASS]${NC} Integration Tests  $INTEGRATION_COUNT tests" ;;
            FAILED)  echo -e "${RED}[FAIL]${NC} Integration Tests  $INTEGRATION_FAILED/$INTEGRATION_COUNT failed" ;;
            SKIPPED) echo -e "${YELLOW}[SKIP]${NC} Integration Tests  (no tests found)" ;;
            *)       echo -e "${YELLOW}[SKIP]${NC} Integration Tests" ;;
        esac
    fi

    # UI Tests
    if [ "$RUN_UI" = true ]; then
        case $UI_RESULT in
            PASSED) echo -e "${GREEN}[PASS]${NC} UI Tests           $UI_COUNT tests" ;;
            FAILED) echo -e "${RED}[FAIL]${NC} UI Tests           $UI_FAILED/$UI_COUNT failed" ;;
            *)      echo -e "${YELLOW}[SKIP]${NC} UI Tests" ;;
        esac
    fi

    echo ""
    echo "========================================================"
    echo "Total: $total_tests tests | Failed: $total_failed | Duration: ${duration}s"
    echo "========================================================"

    if [ $total_failed -eq 0 ]; then
        echo ""
        echo -e "${GREEN}${BOLD}ALL TESTS PASSED${NC}"
        echo ""
        return 0
    else
        echo ""
        echo -e "${RED}${BOLD}TESTS FAILED${NC}"
        echo ""
        return 1
    fi
}

# ============================================================
# Main
# ============================================================
main() {
    print_header

    # Change to project directory
    cd "$IOS_PROJECT_DIR" || {
        echo -e "${RED}Error: Cannot find project directory: $IOS_PROJECT_DIR${NC}"
        exit 2
    }

    # Boot simulator if needed
    echo -e "${BLUE}Preparing simulator...${NC}"
    xcrun simctl boot "iPhone 15 Pro" 2>/dev/null || true
    echo ""

    local failed=false

    # Run tests
    if [ "$RUN_UNIT" = true ]; then
        run_unit_tests || failed=true
    fi

    if [ "$RUN_INTEGRATION" = true ]; then
        run_integration_tests || failed=true
    fi

    if [ "$RUN_UI" = true ]; then
        run_ui_tests || failed=true
    fi

    # Generate report if requested
    if [ "$GENERATE_REPORT" = true ]; then
        generate_report
    fi

    # Print summary
    print_summary

    if [ "$failed" = true ]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
