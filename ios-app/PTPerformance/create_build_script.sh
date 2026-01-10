#!/bin/bash
# Create iOS Build Upload Script
# Usage: ./create_build_script.sh BUILD_NUM "Description"

BUILD_NUM=$1
BUILD_DESC=$2

if [ -z "$BUILD_NUM" ] || [ -z "$BUILD_DESC" ]; then
    cat << 'USAGE'
Usage: ./create_build_script.sh BUILD_NUM "Description"

Examples:
  ./create_build_script.sh 113 "UUID schema fixes"
  ./create_build_script.sh 114 "Performance improvements"

This will create: upload_build113.sh with the proven working method.
USAGE
    exit 1
fi

SCRIPT_NAME="upload_build${BUILD_NUM}.sh"

cat > "$SCRIPT_NAME" << EOF
#!/bin/bash
set -e

echo "🚀 Building and uploading Build ${BUILD_NUM} to TestFlight..."
echo ""
echo "📋 Build ${BUILD_NUM}: ${BUILD_DESC}"
echo ""

# Configuration
SCHEME="PTPerformance"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/PTPerformance-Build${BUILD_NUM}.xcarchive"
EXPORT_PATH="./build/export"
IPA_PATH="./build/export/PTPerformance.ipa"

# Clean
echo "🧹 Cleaning..."
rm -rf ./build
mkdir -p ./build

# Archive
echo "📦 Archiving..."
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \\
    -scheme "\$SCHEME" \\
    -project ./PTPerformance.xcodeproj \\
    -destination 'generic/platform=iOS' \\
    -archivePath "\$ARCHIVE_PATH" \\
    -allowProvisioningUpdates \\
    CODE_SIGN_STYLE=Automatic \\
    DEVELOPMENT_TEAM=V9L3BZN3ZT \\
    PROVISIONING_PROFILE_SPECIFIER="" \\
    CODE_SIGN_IDENTITY="" \\
    archive

if [ ! -d "\$ARCHIVE_PATH" ]; then
    echo "❌ Archive failed!"
    exit 1
fi

echo "✅ Archive successful!"

# Export
echo "📤 Exporting IPA..."
cat > ./build/ExportOptions.plist << 'PLIST'
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

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -exportArchive \\
    -archivePath "\$ARCHIVE_PATH" \\
    -exportPath "\$EXPORT_PATH" \\
    -exportOptionsPlist ./build/ExportOptions.plist \\
    -allowProvisioningUpdates

if [ ! -f "\$IPA_PATH" ]; then
    echo "❌ Export failed!"
    exit 1
fi

echo "✅ Export successful!"

# Upload to TestFlight
echo "📤 Uploading to TestFlight..."
xcrun altool --upload-app --type ios --file "\$IPA_PATH" \\
    --apiKey 9S37GWGW49 \\
    --apiIssuer eebecd15-2a07-4dc3-a74c-aed17ca3887a

echo ""
echo "✅ Build ${BUILD_NUM} uploaded to TestFlight successfully!"
echo "   Archive: \$ARCHIVE_PATH"
echo "   IPA: \$IPA_PATH"
echo ""
echo "📋 WHAT'S IN BUILD ${BUILD_NUM}:"
echo "   ✅ ${BUILD_DESC}"
echo "   TODO: Add detailed change list"
echo ""
echo "🧪 HOW TO TEST:"
echo "   1. Install BUILD ${BUILD_NUM} from TestFlight"
echo "   2. TODO: Add specific test steps"
echo ""
EOF

chmod +x "$SCRIPT_NAME"

echo ""
echo "✅ Created $SCRIPT_NAME"
echo ""
echo "📝 Next steps:"
echo "   1. Edit $SCRIPT_NAME to add detailed change notes"
echo "   2. Increment build number: /usr/libexec/PlistBuddy -c \"Set :CFBundleVersion ${BUILD_NUM}\" Info.plist"
echo "   3. Run: ./$SCRIPT_NAME"
echo ""
