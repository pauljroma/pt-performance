#!/bin/bash
# iOS Deployment Script - Archive, Export, Upload to TestFlight
# Usage: ./deploy_ios.sh [command] [build_number]

set -e

COMMAND="${1:-help}"
BUILD_NUM="${2:-$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Info.plist 2>/dev/null || echo "")}"
PROJECT="PTPerformance.xcodeproj"
SCHEME="PTPerformance"
ARCHIVE_PATH="build/PTPerformance_BUILD${BUILD_NUM}.xcarchive"
IPA_PATH="build/PTPerformance.ipa"

case "$COMMAND" in
    archive)
        echo "========================================="
        echo "BUILD $BUILD_NUM - Archive & Export"
        echo "========================================="

        # Clean
        echo "Step 1/3: Cleaning..."
        xcodebuild clean -project "$PROJECT" -scheme "$SCHEME" -configuration Release

        # Archive
        echo ""
        echo "Step 2/3: Archiving..."
        xcodebuild archive \
          -project "$PROJECT" \
          -scheme "$SCHEME" \
          -configuration Release \
          -archivePath "$ARCHIVE_PATH" \
          -allowProvisioningUpdates \
          | tee "build_${BUILD_NUM}_archive.log"

        # Export
        echo ""
        echo "Step 3/3: Exporting IPA..."
        xcodebuild -exportArchive \
          -archivePath "$ARCHIVE_PATH" \
          -exportPath build/ \
          -exportOptionsPlist ExportOptions.plist \
          -allowProvisioningUpdates \
          | tee "build_${BUILD_NUM}_export.log"

        echo ""
        echo "✅ Archive complete: $IPA_PATH ($(du -h "$IPA_PATH" | cut -f1))"
        ;;

    upload-api)
        echo "========================================="
        echo "BUILD $BUILD_NUM - Upload via API"
        echo "========================================="

        if [ ! -f "$IPA_PATH" ]; then
            echo "❌ IPA not found. Run './deploy_ios.sh archive $BUILD_NUM' first"
            exit 1
        fi

        API_KEY=$(security find-generic-password -a "$USER" -s "APP_STORE_CONNECT_API_KEY" -w 2>/dev/null || echo "")
        API_ISSUER=$(security find-generic-password -a "$USER" -s "APP_STORE_CONNECT_API_ISSUER" -w 2>/dev/null || echo "")

        if [ -z "$API_KEY" ] || [ -z "$API_ISSUER" ]; then
            echo "❌ API credentials not found in keychain"
            echo ""
            echo "Setup instructions:"
            echo "  1. Get API key from https://appstoreconnect.apple.com/access/api"
            echo "  2. Run: security add-generic-password -a \"\$USER\" -s \"APP_STORE_CONNECT_API_KEY\" -w \"YOUR_KEY_ID\""
            echo "  3. Run: security add-generic-password -a \"\$USER\" -s \"APP_STORE_CONNECT_API_ISSUER\" -w \"YOUR_ISSUER_ID\""
            exit 1
        fi

        echo "Uploading to TestFlight..."
        xcrun altool --upload-app \
          --type ios \
          --file "$IPA_PATH" \
          --apiKey "$API_KEY" \
          --apiIssuer "$API_ISSUER" \
          --verbose \
          | tee "build_${BUILD_NUM}_upload.log"

        echo ""
        echo "✅ Upload complete!"
        echo "📱 Check https://appstoreconnect.apple.com in ~15 minutes"
        ;;

    upload-appleid)
        echo "========================================="
        echo "BUILD $BUILD_NUM - Upload via Apple ID"
        echo "========================================="

        if [ ! -f "$IPA_PATH" ]; then
            echo "❌ IPA not found. Run './deploy_ios.sh archive $BUILD_NUM' first"
            exit 1
        fi

        if [ -z "$APPLE_ID" ]; then
            echo "❌ APPLE_ID environment variable not set"
            echo "Run: export APPLE_ID=\"your.email@example.com\""
            exit 1
        fi

        echo "Uploading to TestFlight..."
        xcrun altool --upload-app \
          --type ios \
          --file "$IPA_PATH" \
          --username "$APPLE_ID" \
          --password "@keychain:APP_SPECIFIC_PASSWORD" \
          --verbose \
          | tee "build_${BUILD_NUM}_upload.log"

        echo ""
        echo "✅ Upload complete!"
        echo "📱 Check https://appstoreconnect.apple.com in ~15 minutes"
        ;;

    upload-manual)
        echo "========================================="
        echo "BUILD $BUILD_NUM - Manual Upload"
        echo "========================================="

        if [ ! -f "$IPA_PATH" ]; then
            echo "❌ IPA not found. Run './deploy_ios.sh archive $BUILD_NUM' first"
            exit 1
        fi

        echo "IPA: $IPA_PATH ($(du -h "$IPA_PATH" | cut -f1))"
        echo ""
        echo "Choose upload method:"
        echo "  1) Transporter (drag & drop)"
        echo "  2) Xcode Organizer"
        echo ""
        read -p "Enter choice (1 or 2): " choice

        case $choice in
            1)
                echo "Opening Transporter..."
                open -a "Transporter" "$IPA_PATH" || {
                    echo "❌ Transporter not found. Install from App Store."
                    exit 1
                }
                ;;
            2)
                echo "Opening Xcode Organizer..."
                open "$ARCHIVE_PATH" || {
                    echo "❌ Archive not found at $ARCHIVE_PATH"
                    exit 1
                }
                ;;
            *)
                echo "❌ Invalid choice"
                exit 1
                ;;
        esac

        echo ""
        echo "📱 After upload completes:"
        echo "  - Wait ~15 minutes for TestFlight processing"
        echo "  - Check https://appstoreconnect.apple.com"
        ;;

    full)
        echo "========================================="
        echo "BUILD $BUILD_NUM - Full Deployment"
        echo "========================================="

        # Archive & Export
        "$0" archive "$BUILD_NUM"

        echo ""
        echo "Attempting automatic upload..."

        # Try API upload first, fallback to manual
        if "$0" upload-api "$BUILD_NUM" 2>/dev/null; then
            echo "✅ Full deployment complete!"
        else
            echo "⚠️ Automatic upload failed. Falling back to manual upload..."
            "$0" upload-manual "$BUILD_NUM"
        fi
        ;;

    help|*)
        cat << 'HELP'
iOS Deployment Script

Usage:
  ./deploy_ios.sh [command] [build_number]

Commands:
  archive              Archive and export IPA
  upload-api           Upload to TestFlight via App Store Connect API
  upload-appleid       Upload to TestFlight via Apple ID
  upload-manual        Open Transporter or Xcode for manual upload
  full                 Archive + Upload (tries API, falls back to manual)
  help                 Show this help

Examples:
  ./deploy_ios.sh archive 112
  ./deploy_ios.sh upload-api 112
  ./deploy_ios.sh full 112

Build Number:
  If not specified, reads from Info.plist CFBundleVersion

Environment Variables:
  APPLE_ID            Your Apple ID email (for upload-appleid)

Keychain Items (for upload-api):
  APP_STORE_CONNECT_API_KEY       API Key ID (10 chars)
  APP_STORE_CONNECT_API_ISSUER    API Issuer ID (UUID)

Keychain Items (for upload-appleid):
  APP_SPECIFIC_PASSWORD           App-specific password

Setup API Credentials:
  1. Visit https://appstoreconnect.apple.com/access/api
  2. Generate API key (Team Keys → + → Admin access)
  3. Download AuthKey_XXXXXXXXXX.p8
  4. Store credentials:
     security add-generic-password -a "$USER" -s "APP_STORE_CONNECT_API_KEY" -w "YOUR_KEY_ID"
     security add-generic-password -a "$USER" -s "APP_STORE_CONNECT_API_ISSUER" -w "YOUR_ISSUER_ID"

Setup Apple ID Credentials:
  1. Visit https://appleid.apple.com → Security → App-Specific Passwords
  2. Generate password
  3. Store in keychain:
     security add-generic-password -a "your.email@example.com" -s "APP_SPECIFIC_PASSWORD" -w "xxxx-xxxx-xxxx-xxxx"
  4. Set environment variable:
     export APPLE_ID="your.email@example.com"
HELP
        ;;
esac
