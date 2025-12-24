#!/bin/bash
#
# trigger_ios_build.sh - Coordinate iOS build across repositories
#
# Purpose: Orchestrate iOS build from linear-bootstrap to ios-app
# Status: Phase 1 implementation (signal-based coordination)
#
# Usage:
#   scripts/orchestration/trigger_ios_build.sh [BUILD_NUMBER]
#   scripts/orchestration/trigger_ios_build.sh 74
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Get iOS app directory (3 levels up from linear-bootstrap)
IOS_DIR="$(cd "${ROOT_DIR}/../../../ios-app/PTPerformance" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BUILD_NUMBER="${1:-}"

usage() {
    echo "Usage: $0 BUILD_NUMBER"
    echo ""
    echo "Examples:"
    echo "  $0 74              # Trigger build 74"
    echo ""
    echo "Environment:"
    echo "  IOS_DIR         Path to iOS app (default: ../../../ios-app/PTPerformance)"
    echo ""
    exit 1
}

if [[ -z "$BUILD_NUMBER" ]]; then
    echo -e "${RED}❌ Build number required${NC}"
    usage
fi

echo -e "${GREEN}🚀 Triggering iOS build $BUILD_NUMBER${NC}"
echo ""

# 1. Verify iOS directory exists
echo -e "${GREEN}1️⃣  Verifying iOS app directory...${NC}"
if [[ ! -d "$IOS_DIR" ]]; then
    echo -e "${RED}❌ iOS directory not found: $IOS_DIR${NC}"
    echo ""
    echo "Expected structure:"
    echo "  expo/"
    echo "  ├── clients/"
    echo "  │   └── linear-bootstrap/    # Current location"
    echo "  └── ios-app/"
    echo "      └── PTPerformance/        # iOS app"
    echo ""
    exit 1
fi

echo -e "${GREEN}   ✅ Found: $IOS_DIR${NC}"
echo ""

# 2. Check iOS build prerequisites
echo -e "${GREEN}2️⃣  Checking iOS build prerequisites...${NC}"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ xcodebuild not found (Xcode required)${NC}"
    exit 1
fi
echo -e "${GREEN}   ✅ Xcode found${NC}"

# Check for fastlane (optional but recommended)
if command -v fastlane &> /dev/null; then
    echo -e "${GREEN}   ✅ Fastlane found${NC}"
    HAS_FASTLANE=true
else
    echo -e "${YELLOW}   ⚠️  Fastlane not found (manual build required)${NC}"
    HAS_FASTLANE=false
fi

echo ""

# 3. Sync latest content (optional)
echo -e "${GREEN}3️⃣  Content sync check...${NC}"
read -p "Sync latest content before build? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}   Deploying content...${NC}"
    bash "${ROOT_DIR}/tools/scripts/deploy.sh" content || {
        echo -e "${YELLOW}   ⚠️  Content deployment failed (continuing anyway)${NC}"
    }
else
    echo -e "${YELLOW}   Skipped content sync${NC}"
fi
echo ""

# 4. Trigger iOS build
echo -e "${GREEN}4️⃣  Triggering iOS build...${NC}"

cd "$IOS_DIR"

if [[ "$HAS_FASTLANE" == "true" && -f "fastlane/Fastfile" ]]; then
    # Use fastlane if available
    echo -e "${GREEN}   Using fastlane for build...${NC}"

    # Archive and export
    fastlane gym \
        --scheme PTPerformance \
        --export_method app-store \
        --output_directory "./build_${BUILD_NUMBER}" \
        --output_name "PTPerformance_${BUILD_NUMBER}.ipa" \
        || {
            echo -e "${RED}❌ Fastlane build failed${NC}"
            exit 1
        }

    echo -e "${GREEN}   ✅ Build archived: build_${BUILD_NUMBER}/PTPerformance_${BUILD_NUMBER}.ipa${NC}"
else
    # Manual xcodebuild
    echo -e "${GREEN}   Using xcodebuild (manual)...${NC}"
    echo ""
    echo -e "${YELLOW}   Manual build steps:${NC}"
    echo "   1. Open Xcode: open PTPerformance.xcodeproj"
    echo "   2. Select Product > Archive"
    echo "   3. Select archive and click 'Distribute App'"
    echo "   4. Choose App Store Connect"
    echo ""

    # Open Xcode
    if [[ -f "PTPerformance.xcodeproj/project.pbxproj" ]]; then
        open "PTPerformance.xcodeproj"
        echo -e "${GREEN}   ✅ Opened Xcode project${NC}"
    else
        echo -e "${RED}❌ Xcode project not found${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}✅ iOS build coordination complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Wait for build to complete"
echo "  2. Run: scripts/orchestration/deploy_to_testflight.sh $BUILD_NUMBER"
echo ""
