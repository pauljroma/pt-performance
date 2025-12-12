#!/bin/bash
# Upload Build 13 to TestFlight - USE THIS SCRIPT
set -e

echo "=================================================="
echo "UPLOADING BUILD 13 TO TESTFLIGHT"
echo "=================================================="

# Credentials (stored for automation)
export APP_STORE_CONNECT_API_KEY_ID="415c860b88184388b6e889bfd87bb440"
export APP_STORE_CONNECT_API_ISSUER_ID="69a6de97-ec29-47e3-e053-5b8c7c11a4d1"
export APP_STORE_CONNECT_API_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8"
export FASTLANE_APPLE_ID="support@quiver.cx"

# Verify archive exists
if [ ! -d "build/PTPerformance.xcarchive" ]; then
    echo "❌ Archive not found!"
    echo "Run: ./build_and_upload.sh 13"
    exit 1
fi

echo "✅ Archive found"
echo ""
echo "Opening Xcode Organizer..."
echo ""
open -a Xcode build/PTPerformance.xcarchive

echo "=================================================="
echo "MANUAL UPLOAD REQUIRED (Takes 30 seconds)"
echo "=================================================="
echo ""
echo "In Xcode Organizer window that just opened:"
echo ""
echo "  1. Click 'Distribute App' button (blue, top right)"
echo "  2. Select 'App Store Connect'"
echo "  3. Click 'Upload'"
echo "  4. Click 'Next' (accept defaults)"
echo "  5. Click 'Upload' (final button)"
echo ""
echo "Build 13 will appear in TestFlight in ~5 minutes"
echo "Check: https://appstoreconnect.apple.com"
echo "=================================================="
