#!/bin/bash
# Quality Control Checks - Run before every build
# Usage: ./scripts/run_qc_checks.sh

set -e  # Exit on any error

echo "🔍 Running QC Checks..."
echo ""

FAILED=0

# ==================== CHECK 1: UNIT TESTS ====================
echo "📋 Check 1: Running unit tests..."

cd ios-app/PTPerformance

xcodebuild test \
    -scheme PTPerformance \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -quiet 2>&1 | grep -E "Test Suite|passed|failed|BUILD"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Unit tests: PASSED"
else
    echo "❌ Unit tests: FAILED"
    FAILED=1
fi

cd ../..
echo ""

# ==================== CHECK 2: BUILD COMPILATION ====================
echo "📱 Check 2: Checking Swift compilation..."

cd ios-app/PTPerformance

xcodebuild clean build \
    -scheme PTPerformance \
    -destination 'generic/platform=iOS' \
    -quiet 2>&1 | tail -1

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Build compilation: PASSED"
else
    echo "❌ Build compilation: FAILED"
    echo "   Run 'xcodebuild build -scheme PTPerformance' for details"
    FAILED=1
fi

cd ../..
echo ""

# ==================== CHECK 3: CODE SIGNING ====================
echo "🔑 Check 3: Validating code signing..."

# Check if certificate exists
security find-identity -v -p codesigning | grep -q "Apple Development"
if [ $? -eq 0 ]; then
    echo "✅ Code signing certificate: FOUND"
else
    echo "❌ Code signing certificate: NOT FOUND"
    echo "   Download profiles in Xcode → Preferences → Accounts"
    FAILED=1
fi

echo ""

# ==================== CHECK 4: BUILD NUMBER ====================
echo "🔢 Check 4: Verifying build number..."

# Extract build number from Config.swift
BUILD_NUM=$(grep "buildNumber" ios-app/PTPerformance/Config.swift | grep -o "[0-9]\+" | head -1)

if [ -z "$BUILD_NUM" ]; then
    echo "❌ Build number: NOT FOUND in Config.swift"
    FAILED=1
else
    echo "✅ Build number: $BUILD_NUM (Config.swift)"

    # Check Info.plist (basic check)
    if [ -f "ios-app/PTPerformance/Info.plist" ]; then
        echo "✅ Info.plist: EXISTS"
    else
        echo "⚠️  Info.plist: NOT FOUND (may use generated plist)"
    fi
fi

echo ""

# ==================== CHECK 5: MIGRATIONS ====================
echo "🗄️  Check 5: Checking migrations..."

# Count migration files
TOTAL_MIGRATIONS=$(ls -1 supabase/migrations/*.sql 2>/dev/null | wc -l)
APPLIED_MIGRATIONS=$(ls -1 supabase/migrations/*.applied 2>/dev/null | wc -l)

echo "   Total migrations: $TOTAL_MIGRATIONS"
echo "   Applied migrations: $APPLIED_MIGRATIONS"

# Check if there are unapplied migrations
UNAPPLIED=$((TOTAL_MIGRATIONS))

if [ $UNAPPLIED -eq 0 ]; then
    echo "✅ All migrations applied"
elif [ $UNAPPLIED -gt 0 ]; then
    echo "⚠️  $UNAPPLIED migration(s) pending - may need to apply"
    echo "   Run: ./scripts/apply_migration.sh <migration-file>"
fi

echo ""

# ==================== SUMMARY ====================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAILED -eq 0 ]; then
    echo "✅ All QC checks passed!"
    echo ""
    echo "Ready to build:"
    echo "  cd ios-app/PTPerformance"
    echo "  open PTPerformance.xcodeproj"
    echo "  Product → Archive"
    exit 0
else
    echo "❌ QC checks failed!"
    echo ""
    echo "Fix the errors above before building."
    echo "See .claude/TROUBLESHOOTING_RUNBOOK.md for help."
    exit 1
fi
