#!/bin/bash
#
# deploy_to_testflight.sh - Coordinate TestFlight deployment
#
# Purpose: Orchestrate TestFlight upload from linear-bootstrap coordination
# Status: Phase 1 implementation (fastlane-based)
#
# Usage:
#   scripts/orchestration/deploy_to_testflight.sh BUILD_NUMBER
#   scripts/orchestration/deploy_to_testflight.sh 74
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
    echo "  $0 74              # Deploy build 74 to TestFlight"
    echo ""
    echo "Prerequisites:"
    echo "  - Build already archived (run trigger_ios_build.sh first)"
    echo "  - fastlane installed and configured"
    echo "  - App Store Connect credentials in environment"
    echo ""
    echo "Environment:"
    echo "  IOS_DIR                 Path to iOS app (default: ../../../ios-app/PTPerformance)"
    echo "  FASTLANE_USER          App Store Connect email"
    echo "  FASTLANE_PASSWORD      App Store Connect password"
    echo "  FASTLANE_APP_ID        App ID (com.expo.ptperformance)"
    echo ""
    exit 1
}

if [[ -z "$BUILD_NUMBER" ]]; then
    echo -e "${RED}❌ Build number required${NC}"
    usage
fi

echo -e "${GREEN}🚀 Deploying build $BUILD_NUMBER to TestFlight${NC}"
echo ""

# 1. Verify iOS directory exists
echo -e "${GREEN}1️⃣  Verifying iOS app directory...${NC}"
if [[ ! -d "$IOS_DIR" ]]; then
    echo -e "${RED}❌ iOS directory not found: $IOS_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}   ✅ Found: $IOS_DIR${NC}"
echo ""

# 2. Check prerequisites
echo -e "${GREEN}2️⃣  Checking prerequisites...${NC}"

# Check for fastlane
if ! command -v fastlane &> /dev/null; then
    echo -e "${RED}❌ fastlane not found${NC}"
    echo ""
    echo "Install fastlane:"
    echo "  brew install fastlane"
    echo "  # or"
    echo "  sudo gem install fastlane"
    echo ""
    exit 1
fi
echo -e "${GREEN}   ✅ Fastlane found${NC}"

# Check for archived build
BUILD_DIR="$IOS_DIR/build_${BUILD_NUMBER}"
if [[ ! -d "$BUILD_DIR" ]]; then
    echo -e "${RED}❌ Build directory not found: $BUILD_DIR${NC}"
    echo ""
    echo "Run trigger_ios_build.sh first to create archive"
    exit 1
fi
echo -e "${GREEN}   ✅ Build directory found${NC}"

# Check for IPA file
IPA_FILE="$BUILD_DIR/PTPerformance_${BUILD_NUMBER}.ipa"
if [[ ! -f "$IPA_FILE" ]]; then
    echo -e "${RED}❌ IPA file not found: $IPA_FILE${NC}"
    echo ""
    echo "Expected: $IPA_FILE"
    exit 1
fi
echo -e "${GREEN}   ✅ IPA file found${NC}"

echo ""

# 3. Load credentials
echo -e "${GREEN}3️⃣  Loading credentials...${NC}"

# Load from .env if exists
if [[ -f "$ROOT_DIR/.env" ]]; then
    # shellcheck disable=SC1091
    source "$ROOT_DIR/.env"
fi

# Check required credentials
MISSING_CREDS=false

if [[ -z "${FASTLANE_USER:-}" ]]; then
    echo -e "${YELLOW}   ⚠️  FASTLANE_USER not set${NC}"
    MISSING_CREDS=true
fi

if [[ -z "${FASTLANE_PASSWORD:-}" ]]; then
    echo -e "${YELLOW}   ⚠️  FASTLANE_PASSWORD not set${NC}"
    MISSING_CREDS=true
fi

if [[ "$MISSING_CREDS" == "true" ]]; then
    echo ""
    echo -e "${YELLOW}Add credentials to .env:${NC}"
    echo "  FASTLANE_USER=your-email@example.com"
    echo "  FASTLANE_PASSWORD=your-app-specific-password"
    echo ""

    read -p "Continue anyway? (fastlane will prompt) (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}   ✅ Credentials loaded${NC}"
fi

echo ""

# 4. Verify archive
echo -e "${GREEN}4️⃣  Verifying archive...${NC}"

# Check IPA size
IPA_SIZE=$(du -h "$IPA_FILE" | cut -f1)
echo -e "${GREEN}   IPA size: $IPA_SIZE${NC}"

# Basic validation
if command -v zipinfo &> /dev/null; then
    echo -e "${GREEN}   Checking IPA contents...${NC}"
    if zipinfo -1 "$IPA_FILE" | grep -q "Payload/PTPerformance.app"; then
        echo -e "${GREEN}   ✅ IPA structure valid${NC}"
    else
        echo -e "${RED}❌ Invalid IPA structure${NC}"
        exit 1
    fi
fi

echo ""

# 5. Confirm deployment
echo -e "${YELLOW}⚠️  About to deploy to TestFlight:${NC}"
echo "   Build: $BUILD_NUMBER"
echo "   IPA: $IPA_FILE"
echo "   Size: $IPA_SIZE"
echo ""

read -p "Continue with TestFlight upload? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Aborted${NC}"
    exit 0
fi

# 6. Upload to TestFlight
echo -e "${GREEN}5️⃣  Uploading to TestFlight...${NC}"
echo ""

cd "$IOS_DIR"

# Use fastlane pilot for upload
fastlane pilot upload \
    --ipa "$IPA_FILE" \
    --skip_waiting_for_build_processing \
    --changelog "Build $BUILD_NUMBER - Automated deployment via linear-bootstrap" \
    || {
        echo ""
        echo -e "${RED}❌ TestFlight upload failed${NC}"
        echo ""
        echo "Common issues:"
        echo "  1. Check App Store Connect credentials"
        echo "  2. Verify app identifier matches"
        echo "  3. Check provisioning profile"
        echo "  4. Review fastlane logs above"
        echo ""
        exit 1
    }

echo ""
echo -e "${GREEN}   ✅ Upload complete${NC}"
echo ""

# 7. Post-upload steps
echo -e "${GREEN}6️⃣  Post-upload checklist${NC}"
echo ""
echo "Next steps:"
echo "  1. Wait for App Store Connect processing (~10-15 minutes)"
echo "  2. Add testing notes in App Store Connect"
echo "  3. Distribute to testers"
echo "  4. Update Linear issue status"
echo ""
echo "Monitor processing:"
echo "  https://appstoreconnect.apple.com/apps"
echo ""

# Optional: Create deployment record
DEPLOYMENT_RECORD="$ROOT_DIR/.outcomes/2025-12/TESTFLIGHT_BUILD_${BUILD_NUMBER}_$(date +%Y%m%d_%H%M%S).md"

mkdir -p "$(dirname "$DEPLOYMENT_RECORD")"

cat > "$DEPLOYMENT_RECORD" << EOF
# TestFlight Deployment - Build $BUILD_NUMBER

**Date:** $(date +%Y-%m-%d)
**Time:** $(date +%H:%M:%S)
**Status:** Uploaded

---

## Build Details

- **Build Number:** $BUILD_NUMBER
- **IPA File:** $IPA_FILE
- **IPA Size:** $IPA_SIZE
- **Deployed By:** $(whoami)@$(hostname)

## Deployment Method

- **Tool:** fastlane pilot
- **Upload Time:** $(date)

## Next Steps

1. ⏳ Wait for App Store Connect processing (10-15 min)
2. 📝 Add testing notes in App Store Connect
3. 👥 Distribute to testers
4. 📊 Update Linear issue status

## Links

- [App Store Connect](https://appstoreconnect.apple.com/apps)
- [TestFlight](https://appstoreconnect.apple.com/apps/testflight)

---

**Deployment Record:** Auto-generated by linear-bootstrap orchestration
EOF

echo -e "${GREEN}   ✅ Deployment record created: $DEPLOYMENT_RECORD${NC}"
echo ""

echo -e "${GREEN}✅ TestFlight deployment coordination complete!${NC}"
