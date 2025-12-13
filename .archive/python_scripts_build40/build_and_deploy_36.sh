#!/bin/bash
set -e

echo "🚀 Building and Archiving PTPerformance Build 36"
echo "=================================================="

cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Clean
echo "🧹 Cleaning..."
/usr/bin/xcodebuild clean \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -configuration Release

# Archive
echo "📦 Archiving..."
/usr/bin/xcodebuild archive \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -configuration Release \
  -archivePath build/PTPerformance.xcarchive

echo "✅ Archive created successfully!"
echo "📍 Archive location: build/PTPerformance.xcarchive"
echo ""
echo "To upload to TestFlight, use Xcode:"
echo "1. Open Xcode → Window → Organizer"
echo "2. Select the archive"
echo "3. Click 'Distribute App'"
echo "4. Select 'App Store Connect'"
echo "5. Upload"
