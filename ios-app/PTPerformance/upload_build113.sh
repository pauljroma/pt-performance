#!/bin/bash
set -e

echo "🚀 Building and uploading Build 113 to TestFlight..."
echo ""
echo "📋 Build 113: CRITICAL FIX: Restored History tab with pain trends and adherence"
echo ""

# Configuration
SCHEME="PTPerformance"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/PTPerformance-Build113.xcarchive"
EXPORT_PATH="./build/export"
IPA_PATH="./build/export/PTPerformance.ipa"

# Clean
echo "🧹 Cleaning..."
rm -rf ./build
mkdir -p ./build

# Archive
echo "📦 Archiving..."
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
    -scheme "$SCHEME" \
    -project ./PTPerformance.xcodeproj \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=V9L3BZN3ZT \
    PROVISIONING_PROFILE_SPECIFIER="" \
    CODE_SIGN_IDENTITY="" \
    archive

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive failed!"
    exit 1
fi

echo "✅ Archive successful!"

# Export
echo "📤 Exporting IPA..."
cp ./ExportOptions.plist ./build/ExportOptions.plist

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist ./build/ExportOptions.plist \
    -allowProvisioningUpdates

if [ ! -f "$IPA_PATH" ]; then
    echo "❌ Export failed!"
    exit 1
fi

echo "✅ Export successful!"

# Upload to TestFlight
echo "📤 Uploading to TestFlight..."
xcrun altool --upload-app --type ios --file "$IPA_PATH" \
    --apiKey 9S37GWGW49 \
    --apiIssuer eebecd15-2a07-4dc3-a74c-aed17ca3887a

echo ""
echo "✅ Build 113 uploaded to TestFlight successfully!"
echo "   Archive: $ARCHIVE_PATH"
echo "   IPA: $IPA_PATH"
echo ""
echo "📋 WHAT'S IN BUILD 113:"
echo "   ✅ CRITICAL FIX: Restored History tab and Daily Readiness features"
echo "   TODO: Add detailed change list"
echo ""
echo "🧪 HOW TO TEST:"
echo "   1. Install BUILD 113 from TestFlight"
echo "   2. TODO: Add specific test steps"
echo ""
