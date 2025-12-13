#!/bin/bash
set -e

cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

echo "🚀 Archiving Build 36..."
echo ""

/usr/bin/xcodebuild archive \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -configuration Release \
  -archivePath build/PTPerformance.xcarchive \
  -allowProvisioningUpdates

echo ""
echo "✅ Archive complete!"
ls -lh build/PTPerformance.xcarchive
