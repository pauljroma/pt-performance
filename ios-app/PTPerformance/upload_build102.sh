#!/bin/bash
set -e

echo "🚀 Building and uploading Build 102 to TestFlight..."
echo ""
echo "📋 Build 102: AI Chat Integration + History Fix"
echo "   - ✅ AI Chat tab integrated into PatientTabView"
echo "   - ✅ Database views for analytics (vw_pain_trend, etc.)"
echo "   - ✅ AIChatService.swift fix (response.data extraction)"
echo "   - ✅ Full AI Assistant functionality in 3rd tab"
echo ""

# Configuration
SCHEME="PTPerformance"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/PTPerformance-Build102.xcarchive"
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
echo "✅ Build 102 uploaded to TestFlight successfully!"
echo "   Archive: $ARCHIVE_PATH"
echo "   IPA: $IPA_PATH"
echo ""
echo "📋 WHAT'S IN BUILD 102:"
echo "   ✅ AI Chat tab visible in Patient view (3rd tab)"
echo "   ✅ Brain icon for AI Assistant"
echo "   ✅ Send messages and receive AI responses"
echo "   ✅ History tab with pain trends and analytics"
echo "   ✅ All database views properly configured"
echo ""
echo "🧪 HOW TO TEST:"
echo "   1. Install BUILD 102 from TestFlight"
echo "   2. Login as a patient"
echo "   3. Verify 4 tabs: Today | History | AI Assistant | Settings"
echo "   4. Tap AI Assistant tab (brain icon)"
echo "   5. Send message: 'What exercises should I do?'"
echo "   6. Verify response appears"
echo "   7. Check History tab loads without errors"
echo ""
