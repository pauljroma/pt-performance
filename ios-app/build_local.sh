#!/bin/bash
set -e

# Resolve the project directory relative to this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/PTPerformance"

echo "🔨 Building PTPerformance (Debug Build)"
echo "========================================"
echo "📁 Project: $PROJECT_DIR"

cd "$PROJECT_DIR"

# Find scheme
SCHEME=$(xcodebuild -list -project PTPerformance.xcodeproj 2>/dev/null | grep -A 1 "Schemes:" | tail -1 | xargs)
echo "📋 Using scheme: $SCHEME"

# Parse flags
CLEAN=false
INSTALL=false
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=true ;;
    --install) INSTALL=true ;;
    --help)
      echo "Usage: $0 [--clean] [--install]"
      echo "  --clean    Clean build folder before building"
      echo "  --install  Install and launch in booted simulator after build"
      exit 0
      ;;
  esac
done

# Clean if requested
if [ "$CLEAN" = true ]; then
  echo ""
  echo "🧹 Cleaning build folder..."
  xcodebuild clean \
    -project PTPerformance.xcodeproj \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -configuration Debug \
    -derivedDataPath build/DerivedData \
    -quiet 2>/dev/null || true
  rm -rf build/DerivedData/Build/Products 2>/dev/null || true
  echo "✅ Clean complete"
fi

# Build for simulator (no code signing needed)
echo ""
echo "🔨 Building for iOS Simulator..."
xcodebuild build \
  -project PTPerformance.xcodeproj \
  -scheme "$SCHEME" \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | xcpretty 2>/dev/null || \
xcodebuild build \
  -project PTPerformance.xcodeproj \
  -scheme "$SCHEME" \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO

APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/PTPerformance.app"

echo ""
echo "✅ Build succeeded!"
echo "📱 App: $APP_PATH"

# Install if requested
if [ "$INSTALL" = true ]; then
  echo ""
  echo "📲 Installing to simulator..."
  # Boot simulator if not already running
  xcrun simctl boot 'iPhone 16 Pro' 2>/dev/null || true
  # Install and launch
  xcrun simctl install booted "$APP_PATH"
  xcrun simctl launch booted com.ptperformance.app
  echo "✅ Launched in simulator"
else
  echo ""
  echo "To run in simulator:"
  echo "  xcrun simctl boot 'iPhone 16 Pro'"
  echo "  xcrun simctl install booted $APP_PATH"
  echo "  xcrun simctl launch booted com.ptperformance.app"
fi
