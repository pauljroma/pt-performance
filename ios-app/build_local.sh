#!/bin/bash
set -e

echo "🔨 Building PTPerformance (Debug Build)"
echo "========================================"

cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Find scheme
SCHEME=$(xcodebuild -list -project PTPerformance.xcodeproj 2>/dev/null | grep -A 1 "Schemes:" | tail -1 | xargs)
echo "Using scheme: $SCHEME"

# Build for simulator (no code signing needed)
echo ""
echo "Building for iOS Simulator..."
xcodebuild build \
  -project PTPerformance.xcodeproj \
  -scheme "$SCHEME" \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build/simulator \
  | xcpretty || xcodebuild build \
    -project PTPerformance.xcodeproj \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -configuration Debug \
    -derivedDataPath build/simulator

echo ""
echo "✅ Build succeeded!"
echo "📱 App location: build/simulator/Build/Products/Debug-iphonesimulator/PTPerformance.app"
echo ""
echo "To run in simulator:"
echo "  xcrun simctl boot 'iPhone 15 Pro'"
echo "  xcrun simctl install booted build/simulator/Build/Products/Debug-iphonesimulator/PTPerformance.app"
echo "  xcrun simctl launch booted com.ptperformance.app"
