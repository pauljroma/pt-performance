#!/bin/bash
set -e

echo "🚀 Building and uploading Build 103 to TestFlight..."
echo ""
echo "📋 Build 103: History View Pain Trend Fix"
echo "   - Fixed vw_pain_trend database view type mismatches"
echo "   - UUID → TEXT (MD5 hash) for Swift String compatibility"
echo "   - DATE → TIMESTAMP for ISO8601 decoding"
echo "   - Fixed GROUP BY for proper daily pain score aggregation"
echo "   - Resolves 'data couldn't be read' error in History view"
echo ""

# Configuration
SCHEME="PTPerformance"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/PTPerformance-Build103.xcarchive"
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
cat > ./build/ExportOptions.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>V9L3BZN3ZT</string>
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
echo "✅ Build 103 uploaded to TestFlight successfully!"
echo "   Archive: $ARCHIVE_PATH"
echo "   IPA: $IPA_PATH"
echo ""
echo "📋 WHAT'S FIXED IN BUILD 103:"
echo "   ✅ History view pain trend chart now loads correctly"
echo "   ✅ Database view returns Swift-compatible types"
echo "   ✅ No more 'data couldn't be read because it isn't in the correct format' errors"
echo "   ✅ Pain trend displays with proper daily aggregation"
echo ""
echo "🧪 HOW TO TEST:"
echo "   1. Install BUILD 103 from TestFlight"
echo "   2. Navigate to Patient History tab"
echo "   3. Verify pain trend chart loads without errors"
echo "   4. Check adherence and session data also load"
echo "   5. Confirm no decoding errors in Debug Logs"
echo ""
