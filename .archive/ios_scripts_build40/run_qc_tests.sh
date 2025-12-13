#!/bin/bash
# iOS Quality Control Test Runner
# Executes all unit, integration, and UI tests before deployment
# BLOCKS deployment if any critical tests fail

set -e
set -o pipefail

cd "$(dirname "$0")"

echo "=================================================="
echo "🧪 iOS Quality Control Test Suite"
echo "=================================================="
echo ""
echo "Build CANNOT be deployed if any test fails!"
echo ""

# Setup rbenv
export PATH="$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init - bash 2>/dev/null)" || true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
UNIT_TESTS_PASSED=0
INTEGRATION_TESTS_PASSED=0
UI_TESTS_PASSED=0
TOTAL_FAILURES=0

echo "=================================================="
echo "📋 Phase 1: Unit Tests"
echo "=================================================="
echo ""
echo "Testing ViewModels, Config, and Helpers..."
echo ""

# Run unit tests
set +e  # Don't exit on error, we want to check exit code manually
xcodebuild test \
    -scheme PTPerformance \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:PTPerformanceTests/TodaySessionViewModelTests \
    -only-testing:PTPerformanceTests/PatientListViewModelTests \
    -only-testing:PTPerformanceTests/ConfigTests \
    2>&1 | tee /tmp/unit_test_output.log | xcpretty --color
UNIT_TEST_EXIT_CODE=${PIPESTATUS[0]}
set -e

if [ $UNIT_TEST_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Unit Tests PASSED${NC}"
    UNIT_TESTS_PASSED=1
else
    echo ""
    echo -e "${RED}❌ Unit Tests FAILED${NC}"
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi

echo ""
echo "=================================================="
echo "🔗 Phase 2: Integration Tests"
echo "=================================================="
echo ""
echo "Testing Supabase client and database queries..."
echo ""
echo "⚠️  WARNING: These tests require network connectivity"
echo "⚠️  WARNING: These tests require valid Supabase credentials"
echo ""

# Run integration tests
set +e  # Don't exit on error, we want to check exit code manually
xcodebuild test \
    -scheme PTPerformance \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:PTPerformanceTests/SupabaseIntegrationTests \
    2>&1 | tee /tmp/integration_test_output.log | xcpretty --color
INTEGRATION_TEST_EXIT_CODE=${PIPESTATUS[0]}
set -e

if [ $INTEGRATION_TEST_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Integration Tests PASSED${NC}"
    INTEGRATION_TESTS_PASSED=1
else
    echo ""
    echo -e "${RED}❌ Integration Tests FAILED${NC}"
    echo ""
    echo "Common causes:"
    echo "  1. No internet connection"
    echo "  2. Supabase credentials invalid"
    echo "  3. Demo user doesn't exist in database"
    echo "  4. Database schema mismatch"
    echo "  5. RLS policies blocking access"
    echo ""
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi

echo ""
echo "=================================================="
echo "🎨 Phase 3: UI Tests"
echo "=================================================="
echo ""
echo "Testing patient and therapist user flows..."
echo ""

# Run UI tests
set +e  # Don't exit on error, we want to check exit code manually
xcodebuild test \
    -scheme PTPerformance \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:PTPerformanceUITests/PatientFlowUITests \
    2>&1 | tee /tmp/ui_test_output.log | xcpretty --color
UI_TEST_EXIT_CODE=${PIPESTATUS[0]}
set -e

if [ $UI_TEST_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ UI Tests PASSED${NC}"
    UI_TESTS_PASSED=1
else
    echo ""
    echo -e "${RED}❌ UI Tests FAILED${NC}"
    echo ""
    echo "Common causes:"
    echo "  1. Data loading failure (Build 8 bug)"
    echo "  2. UI layout broken"
    echo "  3. Navigation flow broken"
    echo "  4. Login credentials rejected"
    echo ""
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi

echo ""
echo "=================================================="
echo "📊 Quality Control Summary"
echo "=================================================="
echo ""

# Print results
if [ $UNIT_TESTS_PASSED -eq 1 ]; then
    echo -e "Unit Tests:        ${GREEN}✅ PASS${NC}"
else
    echo -e "Unit Tests:        ${RED}❌ FAIL${NC}"
fi

if [ $INTEGRATION_TESTS_PASSED -eq 1 ]; then
    echo -e "Integration Tests: ${GREEN}✅ PASS${NC}"
else
    echo -e "Integration Tests: ${RED}❌ FAIL${NC}"
fi

if [ $UI_TESTS_PASSED -eq 1 ]; then
    echo -e "UI Tests:          ${GREEN}✅ PASS${NC}"
else
    echo -e "UI Tests:          ${RED}❌ FAIL${NC}"
fi

echo ""

# Determine overall result
if [ $TOTAL_FAILURES -eq 0 ]; then
    echo "=================================================="
    echo -e "${GREEN}✅ ALL TESTS PASSED - BUILD APPROVED FOR DEPLOYMENT${NC}"
    echo "=================================================="
    echo ""
    echo "Next steps:"
    echo "  1. Run ./run_local_build.sh to build and upload to TestFlight"
    echo "  2. Wait for Apple processing (~5-10 minutes)"
    echo "  3. Test on physical iPad via TestFlight"
    echo ""
    exit 0
else
    echo "=================================================="
    echo -e "${RED}❌ $TOTAL_FAILURES TEST SUITE(S) FAILED - BUILD BLOCKED${NC}"
    echo "=================================================="
    echo ""
    echo "🚨 DEPLOYMENT BLOCKED 🚨"
    echo ""
    echo "This build CANNOT be deployed to TestFlight until all tests pass."
    echo ""
    echo "Actions required:"
    echo "  1. Review test failures above"
    echo "  2. Fix the failing code"
    echo "  3. Re-run ./run_qc_tests.sh"
    echo "  4. Only deploy when ALL tests pass"
    echo ""
    echo "This QC gate prevents bugs like Build 8 (deployed broken code)."
    echo ""
    exit 1
fi
