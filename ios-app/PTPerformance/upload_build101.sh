#!/bin/bash
set -e

echo "🚀 Building and uploading Build 101 to TestFlight..."
echo ""
echo "📋 Build 101: Comprehensive Debug Logging"
echo "   - Added detailed logging to AI Chat service (every parsing step)"
echo "   - Added logging to all Analytics Service fetch methods"
echo "   - Added logging to History ViewModel data fetching"
echo "   - All logs visible in Debug Logs view on device"
echo "   - Can now diagnose exact failure points without TestFlight delays"
echo "   - Building without whole-module optimization to avoid compiler crash"
echo ""

# Configuration
SCHEME="PTPerformance"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/PTPerformance-Build101.xcarchive"
EXPORT_PATH="./build/export"
IPA_PATH="./build/export/PTPerformance.ipa"

# Clean
echo "🧹 Cleaning..."
rm -rf ./build
mkdir -p ./build

# Archive with optimizations disabled to avoid compiler crash
echo "📦 Archiving (no whole-module optimization)..."
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
    -scheme "$SCHEME" \
    -project ./PTPerformance.xcodeproj \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM=5NNLBL74XR \
    SWIFT_COMPILATION_MODE=singlefile \
    SWIFT_OPTIMIZATION_LEVEL="-Onone" \
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
echo "✅ Build 101 uploaded to TestFlight successfully!"
echo "   Archive: $ARCHIVE_PATH"
echo "   IPA: $IPA_PATH"
echo ""
echo "📋 WHAT'S NEW IN BUILD 101:"
echo "   ✅ Comprehensive debug logging for AI Chat"
echo "   ✅ Comprehensive debug logging for History"
echo "   ✅ All errors now visible in Debug Logs (Settings → Developer Tools)"
echo "   ✅ Can diagnose exact failure points without guessing"
echo "   ✅ Logs persist to file and can be exported"
echo ""
echo "🧪 HOW TO TEST:"
echo "   1. Install BUILD 101 from TestFlight"
echo "   2. Open Settings → Developer Tools → Debug Logs"
echo "   3. Tap 'Clear All' to start fresh"
echo "   4. Navigate to AI Assistant and send a message"
echo "   5. Return to Debug Logs to see exactly what happened"
echo "   6. Repeat for History tab"
echo "   7. Filter by 'Errors' to see only failures"
echo "   8. Export logs and share for analysis"
echo ""
echo "⚠️  NOTE: Built without optimizations to avoid compiler crash"
echo "    Performance may be slightly slower than usual"
