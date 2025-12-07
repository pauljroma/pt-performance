#!/bin/bash
# Simple script to upload existing IPA to TestFlight
# This uploads the ALREADY COMPILED build - no signing, no building

set -e

IPA_PATH="PTPerformance/PTPerformance.ipa"
APPLE_ID="paul@romatechv100.com"

echo "=== TestFlight Upload Script ==="
echo "IPA: $IPA_PATH"
echo "Apple ID: $APPLE_ID"
echo ""

# Check IPA exists
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ ERROR: IPA not found at $IPA_PATH"
    exit 1
fi

echo "✅ IPA found ($(ls -lh $IPA_PATH | awk '{print $5}'))"
echo ""

# Get app-specific password from user
echo "Enter your App-Specific Password:"
echo "(Get it from: https://appleid.apple.com/account/manage -> Sign-In and Security -> App-Specific Passwords)"
read -s APP_PASSWORD

echo ""
echo "Uploading to TestFlight..."
echo ""

# Upload using xcrun altool
xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --username "$APPLE_ID" \
    --password "$APP_PASSWORD" \
    --verbose

echo ""
echo "✅ Upload complete!"
echo ""
echo "Next steps:"
echo "1. Wait ~5 minutes for Apple to process the build"
echo "2. Check TestFlight: https://appstoreconnect.apple.com/apps"
echo "3. Add testers and distribute"
