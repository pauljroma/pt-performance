#!/bin/bash
# Quality Control Checks - Run before every build
# Usage: ./scripts/run_qc_checks.sh
#
# This script MUST fail (exit 1) when any check fails.
# Do not suppress xcodebuild exit codes or label failures as PASS.

set -euo pipefail

echo "Running QC Checks..."
echo ""

FAILED=0

# ==================== CHECK 1: UNIT TESTS ====================
echo "Check 1: Running unit tests..."

cd ios-app/PTPerformance

TEST_EXIT=0
xcodebuild test \
    -scheme PTPerformance \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -quiet 2>&1 | tail -20 || TEST_EXIT=${PIPESTATUS[0]:-$?}

# Capture the real xcodebuild exit code
if [ $TEST_EXIT -ne 0 ]; then
    echo "FAILED: Unit tests did not pass (exit code $TEST_EXIT)"
    FAILED=1
else
    echo "PASSED: Unit tests"
fi

cd ../..
echo ""

# ==================== CHECK 2: BUILD COMPILATION ====================
echo "Check 2: Checking Swift compilation..."

cd ios-app/PTPerformance

BUILD_EXIT=0
xcodebuild build \
    -scheme PTPerformance \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -quiet 2>&1 | tail -5 || BUILD_EXIT=${PIPESTATUS[0]:-$?}

if [ $BUILD_EXIT -ne 0 ]; then
    echo "FAILED: Build compilation (exit code $BUILD_EXIT)"
    echo "   Run 'xcodebuild build -scheme PTPerformance' for details"
    FAILED=1
else
    echo "PASSED: Build compilation"
fi

cd ../..
echo ""

# ==================== CHECK 3: CODE SIGNING ====================
echo "Check 3: Validating code signing..."

if security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Development\|Apple Distribution"; then
    echo "PASSED: Code signing certificate found"
else
    echo "FAILED: No code signing certificate found"
    echo "   Download profiles in Xcode -> Preferences -> Accounts"
    FAILED=1
fi

echo ""

# ==================== CHECK 4: BUILD NUMBER ====================
echo "Check 4: Verifying build number..."

BUILD_NUM=$(grep "CURRENT_PROJECT_VERSION" ios-app/PTPerformance/PTPerformance.xcodeproj/project.pbxproj | head -1 | grep -o "[0-9]\+" || true)

if [ -z "$BUILD_NUM" ]; then
    echo "FAILED: Build number not found in project.pbxproj"
    FAILED=1
else
    echo "PASSED: Build number $BUILD_NUM"
fi

echo ""

# ==================== CHECK 5: SWIFTLINT ====================
echo "Check 5: Running SwiftLint..."

cd ios-app/PTPerformance

LINT_EXIT=0
swiftlint lint --config .swiftlint.yml --quiet 2>&1 || LINT_EXIT=$?

if [ $LINT_EXIT -ne 0 ]; then
    echo "FAILED: SwiftLint found violations"
    FAILED=1
else
    echo "PASSED: SwiftLint"
fi

cd ../..
echo ""

# ==================== CHECK 6: NO TRACKED SECRETS ====================
echo "Check 6: Checking for tracked secrets..."

SECRETS_FOUND=0
if git ls-files | grep -qE '\.p8$|\.p12$|\.pem$|private_keys/'; then
    echo "FAILED: Signing keys are tracked in git"
    git ls-files | grep -E '\.p8$|\.p12$|\.pem$|private_keys/'
    SECRETS_FOUND=1
    FAILED=1
else
    echo "PASSED: No signing keys tracked in git"
fi

echo ""

# ==================== SUMMARY ====================
echo "=============================================="

if [ $FAILED -eq 0 ]; then
    echo "ALL QC CHECKS PASSED"
    echo ""
    echo "Ready to build. Next steps:"
    echo "  cd ios-app/PTPerformance"
    echo "  xcodebuild archive -scheme PTPerformance ..."
    exit 0
else
    echo "QC CHECKS FAILED"
    echo ""
    echo "Fix the errors above before building."
    exit 1
fi
