#!/bin/bash
#
# deploy.sh - Canonical deployment interface for linear-bootstrap
#
# Usage:
#   tools/scripts/deploy.sh content      # Deploy articles to Supabase
#   tools/scripts/deploy.sh ios          # Trigger iOS build (coordinates with ../../ios-app/)
#   tools/scripts/deploy.sh migration    # Apply Supabase migration (coordinates with ../../supabase/)
#   tools/scripts/deploy.sh testflight   # Deploy to TestFlight (coordinates with ../../ios-app/)
#

set -euo pipefail

# Get the root directory of linear-bootstrap
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TARGET="${1:-}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 {content|ios|migration|testflight}"
    echo ""
    echo "Deployment targets:"
    echo "  content      Deploy articles to Supabase"
    echo "  ios          Trigger iOS build (coordinates with ios-app)"
    echo "  migration    Apply Supabase migration (coordinates with supabase)"
    echo "  testflight   Deploy iOS to TestFlight"
    echo ""
    echo "Examples:"
    echo "  $0 content"
    echo "  $0 testflight"
    exit 1
}

if [[ -z "$TARGET" ]]; then
    usage
fi

case "$TARGET" in
    content)
        echo -e "${GREEN}📚 Deploying content to Supabase...${NC}"
        cd "$ROOT_DIR"

        # Check if .env exists
        if [[ ! -f .env ]]; then
            echo -e "${RED}❌ Error: .env file not found${NC}"
            echo "Run: cp .env.template .env"
            echo "Then edit .env with your Supabase credentials"
            exit 1
        fi

        # Check if Python 3 is available
        if ! command -v python3 &> /dev/null; then
            echo -e "${RED}❌ Error: python3 not found${NC}"
            echo "Install Python 3 to continue"
            exit 1
        fi

        # Run content deployment script
        python3 scripts/content/load_articles.py

        echo ""
        echo -e "${GREEN}✅ Content deployment complete${NC}"
        echo "Manifest: deployment_manifest.json"
        ;;

    ios)
        echo -e "${GREEN}🔨 Triggering iOS build...${NC}"
        cd "$ROOT_DIR"

        IOS_APP_DIR="${ROOT_DIR}/../../ios-app/PTPerformance"

        if [[ ! -d "$IOS_APP_DIR" ]]; then
            echo -e "${RED}❌ Error: iOS app not found at $IOS_APP_DIR${NC}"
            exit 1
        fi

        echo "Coordinating with ios-app at: $IOS_APP_DIR"

        # Check if script exists
        if [[ -f "${ROOT_DIR}/scripts/orchestration/trigger_ios_build.sh" ]]; then
            bash "${ROOT_DIR}/scripts/orchestration/trigger_ios_build.sh"
        else
            echo -e "${YELLOW}⚠️  Orchestration script not found, running directly in ios-app${NC}"
            cd "$IOS_APP_DIR"
            fastlane build
        fi

        echo -e "${GREEN}✅ iOS build complete${NC}"
        ;;

    migration)
        echo -e "${GREEN}🗄️  Applying Supabase migration...${NC}"
        cd "$ROOT_DIR"

        SUPABASE_DIR="${ROOT_DIR}/../../supabase"

        if [[ ! -d "$SUPABASE_DIR" ]]; then
            echo -e "${RED}❌ Error: Supabase directory not found at $SUPABASE_DIR${NC}"
            exit 1
        fi

        echo "Coordinating with supabase at: $SUPABASE_DIR"

        # Check if orchestration script exists
        if [[ -f "${ROOT_DIR}/scripts/orchestration/apply_migration.sh" ]]; then
            bash "${ROOT_DIR}/scripts/orchestration/apply_migration.sh" "$@"
        else
            echo -e "${YELLOW}⚠️  Orchestration script not found, running directly in supabase${NC}"
            cd "$SUPABASE_DIR"

            # Check if SUPABASE_ACCESS_TOKEN is set
            if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
                echo -e "${RED}❌ Error: SUPABASE_ACCESS_TOKEN not set${NC}"
                echo "Export SUPABASE_ACCESS_TOKEN before running migrations"
                exit 1
            fi

            supabase db push
        fi

        echo -e "${GREEN}✅ Migration applied${NC}"
        ;;

    testflight)
        echo -e "${GREEN}✈️  Deploying to TestFlight...${NC}"
        cd "$ROOT_DIR"

        IOS_APP_DIR="${ROOT_DIR}/../../ios-app/PTPerformance"

        if [[ ! -d "$IOS_APP_DIR" ]]; then
            echo -e "${RED}❌ Error: iOS app not found at $IOS_APP_DIR${NC}"
            exit 1
        fi

        echo "Coordinating with ios-app at: $IOS_APP_DIR"
        echo -e "${YELLOW}⚠️  This will deploy to TestFlight. Continue? (y/N)${NC}"
        read -r confirm

        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Cancelled"
            exit 0
        fi

        # Check if orchestration script exists
        if [[ -f "${ROOT_DIR}/scripts/orchestration/deploy_to_testflight.sh" ]]; then
            bash "${ROOT_DIR}/scripts/orchestration/deploy_to_testflight.sh"
        else
            echo -e "${YELLOW}⚠️  Orchestration script not found, running directly in ios-app${NC}"
            cd "$IOS_APP_DIR"

            # Run fastlane testflight deployment
            fastlane deploy_testflight
        fi

        echo -e "${GREEN}✅ TestFlight deployment complete${NC}"
        ;;

    *)
        echo -e "${RED}❌ Unknown target: $TARGET${NC}"
        usage
        ;;
esac
