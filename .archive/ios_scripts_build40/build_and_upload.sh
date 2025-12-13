#!/bin/bash
# Complete Build and Upload to TestFlight
# Usage: ./build_and_upload.sh [build_number]

set -e

BUILD_NUMBER=${1:-$(( $(agvtool what-version | tail -1 | xargs) + 1 ))}

echo "=================================================="
echo "BUILD & UPLOAD TO TESTFLIGHT"
echo "Build Number: $BUILD_NUMBER"
echo "=================================================="

# Step 1: Set build number
echo ""
echo "[1/5] Setting build number to $BUILD_NUMBER..."
agvtool new-version $BUILD_NUMBER
echo "✅ Build number set"

# Step 2: Clean
echo ""
echo "[2/5] Cleaning build folder..."
rm -rf build/
echo "✅ Cleaned"

# Step 3: Build archive
echo ""
echo "[3/5] Building archive (this takes 2-3 minutes)..."
xcodebuild \
    -scheme PTPerformance \
    -configuration Release \
    -archivePath ./build/PTPerformance.xcarchive \
    archive \
    | xcpretty || xcodebuild \
    -scheme PTPerformance \
    -configuration Release \
    -archivePath ./build/PTPerformance.xcarchive \
    archive

if [ ! -d "./build/PTPerformance.xcarchive" ]; then
    echo "❌ Build failed - check errors above"
    exit 1
fi
echo "✅ Archive built"

# Step 4: Open Xcode Organizer
echo ""
echo "[4/5] Opening Xcode Organizer..."
open -a Xcode ./build/PTPerformance.xcarchive
echo "✅ Xcode Organizer opened"

echo ""
echo "=================================================="
echo "BUILD COMPLETE - Ready for Upload"
echo "=================================================="
echo ""
echo "In Xcode Organizer:"
echo "  1. Click 'Distribute App'"
echo "  2. Select 'App Store Connect' → Next"
echo "  3. Select 'Upload' → Next"
echo "  4. Click 'Upload'"
echo ""
echo "Build: version 1.0 ($BUILD_NUMBER)"
echo "=================================================="
