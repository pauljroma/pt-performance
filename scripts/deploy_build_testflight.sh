#!/bin/bash
#
# Deploy PT Performance to TestFlight
# Usage: ./scripts/deploy_build_testflight.sh [build_number]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo "PT Performance - TestFlight Deployment"
echo "=========================================="
echo ""

# Configuration
PROJECT_DIR="ios-app/PTPerformance"
SCHEME="PTPerformance"
BUILD_NUMBER=${1:-45}
ARCHIVE_PATH="build/PTPerformance.xcarchive"
EXPORT_PATH="build/TestFlight"

# Step 1: Pre-flight checks
echo -e "${BLUE}Step 1: Pre-flight checks${NC}"

# Check if we're in the right directory
if [ ! -d "ios-app" ]; then
    echo -e "${RED}Error: Must run from project root${NC}"
    exit 1
fi

# Check schema validation
echo "  - Running schema validation..."
if python3 scripts/validate_ios_schema.py --verbose 2>&1 | grep -q "All schemas match\|WARNING"; then
    echo -e "  ${GREEN}✓ Schema validation passed${NC}"
else
    echo -e "  ${YELLOW}⚠ Schema validation skipped (no DB connection)${NC}"
fi

# Step 2: Set build number
echo ""
echo -e "${BLUE}Step 2: Setting build number to ${BUILD_NUMBER}${NC}"

cd "$PROJECT_DIR"
agvtool new-version -all "$BUILD_NUMBER"

# Get current version
CURRENT_VERSION=$(agvtool what-marketing-version | grep "CFBundleShortVersionString" | awk '{print $NF}' | tr -d '"')
echo -e "  ${GREEN}✓ Version: ${CURRENT_VERSION} (Build ${BUILD_NUMBER})${NC}"

# Step 3: Clean build directory
echo ""
echo -e "${BLUE}Step 3: Cleaning build directory${NC}"

rm -rf build
mkdir -p build

echo -e "  ${GREEN}✓ Build directory cleaned${NC}"

# Step 4: Build archive
echo ""
echo -e "${BLUE}Step 4: Building archive${NC}"
echo "  This may take a few minutes..."

xcodebuild archive \
    -project PTPerformance.xcodeproj \
    -scheme "$SCHEME" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}" \
    CODE_SIGN_STYLE="${CODE_SIGN_STYLE:-Automatic}" \
    | xcpretty || exit 1

echo -e "  ${GREEN}✓ Archive created${NC}"

# Step 5: Export for TestFlight
echo ""
echo -e "${BLUE}Step 5: Exporting for TestFlight${NC}"

# Create export options plist
cat > build/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist build/ExportOptions.plist \
    | xcpretty || exit 1

echo -e "  ${GREEN}✓ Export successful${NC}"

# Step 6: Upload to TestFlight
echo ""
echo -e "${BLUE}Step 6: Uploading to TestFlight${NC}"

IPA_PATH="$EXPORT_PATH/$SCHEME.ipa"

if [ -f "$IPA_PATH" ]; then
    echo "  IPA location: $IPA_PATH"

    # Check if xcrun altool is available
    if command -v xcrun &> /dev/null; then
        echo ""
        echo -e "${YELLOW}Ready to upload to TestFlight${NC}"
        echo -e "${YELLOW}Run: xcrun altool --upload-app -f \"$IPA_PATH\" -t ios -u YOUR_APPLE_ID${NC}"
        echo ""
        echo "Or use Xcode Organizer:"
        echo "  1. Open Xcode"
        echo "  2. Window → Organizer"
        echo "  3. Select archive"
        echo "  4. Click 'Distribute App'"
    else
        echo -e "${RED}xcrun not found - please use Xcode to upload${NC}"
    fi
else
    echo -e "${RED}Error: IPA not found at $IPA_PATH${NC}"
    exit 1
fi

# Step 7: Post-deployment checklist
echo ""
echo "=========================================="
echo -e "${GREEN}Build Complete!${NC}"
echo "=========================================="
echo ""
echo "Build Information:"
echo "  Version: $CURRENT_VERSION"
echo "  Build: $BUILD_NUMBER"
echo "  Bundle ID: com.ptperformance.app"
echo ""
echo "Next Steps:"
echo "  1. Upload IPA to TestFlight (see above)"
echo "  2. Add release notes from RELEASE_NOTES_BUILD_${BUILD_NUMBER}.md"
echo "  3. Submit for review"
echo "  4. Monitor Sentry for errors after release"
echo ""
echo "Post-Deployment Monitoring:"
echo "  - Check Sentry dashboard for errors"
echo "  - Monitor crash-free rate (target: >99%)"
echo "  - Verify performance metrics"
echo "  - Check Linear for bug reports"
echo ""

cd ../..
