#!/bin/bash
# Upload to TestFlight - Automated Script
set -e

echo "=================================================="
echo "UPLOAD TO TESTFLIGHT"
echo "=================================================="

# Check archive exists
if [ ! -d "./build/PTPerformance.xcarchive" ]; then
    echo "❌ Error: Archive not found at ./build/PTPerformance.xcarchive"
    echo "Run: xcodebuild -scheme PTPerformance -configuration Release -archivePath ./build/PTPerformance.xcarchive archive"
    exit 1
fi

echo "✅ Archive found"

# Export IPA with proper provisioning
echo "📦 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath ./build/PTPerformance.xcarchive \
    -exportPath ./build \
    -exportOptionsPlist ./ExportOptions.plist \
    -allowProvisioningUpdates

if [ ! -f "./build/PTPerformance.ipa" ]; then
    echo "❌ Export failed - IPA not created"
    echo "Opening Xcode Organizer for manual upload..."
    open -a Xcode ./build/PTPerformance.xcarchive
    exit 1
fi

echo "✅ IPA exported"

# Validate IPA
echo "🔍 Validating IPA..."
xcrun altool --validate-app \
    -f ./build/PTPerformance.ipa \
    -t ios \
    --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
    --apiIssuer "$APP_STORE_CONNECT_API_ISSUER_ID" \
    || {
        echo "⚠️  Validation failed - uploading anyway..."
    }

# Upload IPA
echo "⬆️  Uploading to TestFlight..."
xcrun altool --upload-app \
    -f ./build/PTPerformance.ipa \
    -t ios \
    --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
    --apiIssuer "$APP_STORE_CONNECT_API_ISSUER_ID"

echo ""
echo "=================================================="
echo "✅ UPLOAD COMPLETE!"
echo "=================================================="
echo ""
echo "Build will appear in TestFlight in 5-10 minutes"
echo "Check: https://appstoreconnect.apple.com"
echo ""
