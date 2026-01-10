#!/bin/bash
set -e

echo "🚀 Building and uploading Build 99 to TestFlight..."
echo ""
echo "📋 Build 99: ACTUAL fixes for AI Chat + History"
echo "   - Removed faulty guard that prevented message loading"
echo "   - Implemented sessionsWithLogs mapping in HistoryViewModel"
echo ""

# Configuration
SCHEME="PTPerformance"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/PTPerformance-Build99.xcarchive"
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
    DEVELOPMENT_TEAM=5NNLBL74XR \
    archive

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive failed!"
    exit 1
fi

echo "✅ Archive successful!"

# Export
echo "📤 Exporting IPA..."
cat > ./build/ExportOptions.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>5NNLBL74XR</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST

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
echo "✅ Build 99 uploaded to TestFlight successfully!"
echo "   Archive: $ARCHIVE_PATH"
echo "   IPA: $IPA_PATH"
