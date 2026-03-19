#!/bin/bash
set -e

echo "🚀 Build 617: Fix crash + lab upload (Sentry.framework re-signed)"
echo ""

SCHEME="PTPerformance"
ARCHIVE_PATH="./build/PTPerformance-Build617.xcarchive"
EXPORT_PATH="./build/export617"
IPA_PATH="./build/export617/PTPerformance.ipa"
API_KEY="9S37GWGW49"
API_ISSUER="eebecd15-2a07-4dc3-a74c-aed17ca3887a"
API_KEY_PATH="$HOME/private_keys/AuthKey_${API_KEY}.p8"

# Unlock keychain so codesign can access the distribution cert
echo "🔐 Enter your macOS login password to unlock the keychain for signing:"
read -s KEYCHAIN_PASSWORD
echo ""
security unlock-keychain -p "$KEYCHAIN_PASSWORD" ~/Library/Keychains/login.keychain-db
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" ~/Library/Keychains/login.keychain-db 2>/dev/null || true
echo "✅ Keychain unlocked"

# Clean
echo "🧹 Cleaning build folder..."
rm -rf ./build/PTPerformance-Build617.xcarchive ./build/export617
mkdir -p ./build

# Archive
echo "📦 Archiving Build 617..."
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -scheme "$SCHEME" \
  -project PTPerformance.xcodeproj \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=5NNLBL74XR \
  archive 2>&1 | grep -E "error:|warning:|ARCHIVE|BUILD"

echo "✅ Archive complete"

# Export
echo "📤 Exporting IPA..."
cp ExportOptions.plist ./build/ExportOptions.plist
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist ./build/ExportOptions.plist \
  -allowProvisioningUpdates \
  2>&1 | grep -E "error:|EXPORT|Exported"

if [ ! -f "$IPA_PATH" ]; then
  echo "❌ Export failed — IPA not found"
  exit 1
fi
echo "✅ Export complete: $IPA_PATH"

# Upload to TestFlight
echo "📡 Uploading to TestFlight..."
xcrun altool --upload-app --type ios --file "$IPA_PATH" \
  --apiKey "$API_KEY" \
  --apiIssuer "$API_ISSUER" \
  --verbose 2>&1 | tail -20

echo ""
echo "✅ Build 617 submitted to TestFlight!"
echo "   Fixes:"
echo "   - iOS 26 beta crash in BiomarkerDashboardView (Dictionary grouping trap)"
echo "   - Lab upload 401 error (Anthropic API key updated in Supabase)"
echo ""
echo "   Processing takes 5-15 min. Check App Store Connect to distribute."
