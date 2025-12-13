#!/bin/bash
set -e

echo "🚀 Deploying Build 36 to TestFlight (No DB Changes)"
echo "====================================================="
echo ""
echo "Build 36 changes: iOS code only (no database migrations needed)"
echo "- Create Program button"
echo "- Patient filtering security fix"
echo "- Backend API fix"
echo "- Analytics views (already in database)"
echo ""

cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

BUILD_NUMBER=36

# Clean
echo "🧹 Cleaning build directories..."
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/PTPerformance-*
echo "✅ Cleaned"
echo ""

# Archive
echo "📦 Creating archive..."
xcodebuild archive \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -configuration Release \
  -archivePath build/PTPerformance.xcarchive \
  -allowProvisioningUpdates \
  | xcbeautify || cat

if [ ! -d "build/PTPerformance.xcarchive" ]; then
    echo "❌ Archive failed!"
    exit 1
fi

echo "✅ Archive created successfully!"
echo ""

# Export IPA
echo "📤 Exporting IPA for App Store..."
xcodebuild -exportArchive \
  -archivePath build/PTPerformance.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/ \
  -allowProvisioningUpdating \
  | xcbeautify || cat

if [ ! -f "build/PTPerformance.ipa" ]; then
    echo "❌ Export failed!"
    exit 1
fi

IPA_SIZE=$(du -h build/PTPerformance.ipa | cut -f1)
echo "✅ IPA exported successfully! (Size: $IPA_SIZE)"
echo ""

# Upload to TestFlight
echo "🚀 Uploading to TestFlight..."
xcrun altool --upload-app \
  --type ios \
  --file build/PTPerformance.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_API_ISSUER \
  | xcbeautify || cat

echo ""
echo "====================================================="
echo "✅ Build 36 deployed to TestFlight successfully!"
echo "====================================================="
echo ""
echo "Next steps:"
echo "1. Check App Store Connect for processing status"
echo "2. Test on physical device once processing completes"
echo "3. Submit for TestFlight external testing (if needed)"
