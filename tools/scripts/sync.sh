#!/bin/bash
#
# sync.sh - Canonical sync interface for linear-bootstrap
#
# Usage:
#   tools/scripts/sync.sh linear     # Sync with Linear
#   tools/scripts/sync.sh manifest   # Update deployment manifest
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TARGET="${1:-}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    echo "Usage: $0 {linear|manifest}"
    echo ""
    echo "Sync targets:"
    echo "  linear      Sync with Linear API"
    echo "  manifest    Update deployment manifest"
    echo ""
    exit 1
}

if [[ -z "$TARGET" ]]; then
    usage
fi

case "$TARGET" in
    linear)
        echo -e "${GREEN}🔄 Syncing with Linear...${NC}"
        cd "$ROOT_DIR"

        # Check if Linear script exists
        if [[ -f "scripts/linear/sync_issues.py" ]]; then
            python3 scripts/linear/sync_issues.py
        else
            echo -e "${YELLOW}⚠️  Linear sync script not found${NC}"
            echo "Expected: scripts/linear/sync_issues.py"
            exit 1
        fi

        echo -e "${GREEN}✅ Linear sync complete${NC}"
        ;;

    manifest)
        echo -e "${GREEN}📝 Updating deployment manifest...${NC}"
        cd "$ROOT_DIR"

        # Regenerate manifest from current state
        if [[ -f "scripts/content/generate_manifest.py" ]]; then
            python3 scripts/content/generate_manifest.py
        else
            echo -e "${YELLOW}⚠️  Manifest generator not found${NC}"
            echo "Manifest will be updated on next deployment"
        fi

        echo -e "${GREEN}✅ Manifest updated${NC}"
        ;;

    *)
        echo -e "${RED}❌ Unknown target: $TARGET${NC}"
        usage
        ;;
esac
