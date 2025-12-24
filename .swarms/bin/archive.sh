#!/bin/bash
#
# archive.sh - Archive completed swarm sessions
#
# Purpose: Move completed sessions to archive, maintain session history
# Usage:
#   .swarms/bin/archive.sh SESSION_ID
#   .swarms/bin/archive.sh all  # Archive all completed
#   .swarms/bin/archive.sh --older-than 30  # Archive sessions older than 30 days
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWARMS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${SWARMS_DIR}/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET="${1:-}"
OPTION="${2:-}"

usage() {
    echo "Usage: $0 {SESSION_ID|all|--older-than DAYS}"
    echo ""
    echo "Archive completed swarm sessions."
    echo ""
    echo "Examples:"
    echo "  $0 20251223_architecture_rollout"
    echo "  $0 all  # Archive all completed sessions"
    echo "  $0 --older-than 30  # Archive sessions older than 30 days"
    echo ""
    exit 1
}

if [[ -z "$TARGET" ]]; then
    usage
fi

# Create archive directory
ARCHIVE_DIR="$SWARMS_DIR/archive/$(date +%Y-%m)"
mkdir -p "$ARCHIVE_DIR"

archive_session() {
    local session_id=$1
    local session_dir="$SWARMS_DIR/sessions/$session_id"

    if [[ ! -d "$session_dir" ]]; then
        echo -e "${RED}❌ Session not found: $session_id${NC}"
        return 1
    fi

    echo -e "${GREEN}📦 Archiving session: $session_id${NC}"

    # Check if already archived
    if [[ -d "$ARCHIVE_DIR/$session_id" ]]; then
        echo -e "${YELLOW}   ⚠️  Already archived${NC}"
        return 0
    fi

    # Create archive metadata
    cat > "$session_dir/ARCHIVED.txt" << EOF
Archived: $(date +%Y-%m-%d\ %H:%M:%S)
Archive Location: $ARCHIVE_DIR/$session_id
Original Location: $session_dir
EOF

    # Move to archive
    mv "$session_dir" "$ARCHIVE_DIR/$session_id"

    echo -e "${GREEN}   ✅ Archived to: $ARCHIVE_DIR/$session_id${NC}"

    return 0
}

archive_all_completed() {
    echo -e "${GREEN}📦 Archiving all completed sessions...${NC}"
    echo ""

    local archived=0
    local skipped=0

    if [[ ! -d "$SWARMS_DIR/sessions" ]]; then
        echo -e "${YELLOW}⚠️  No sessions directory${NC}"
        return 0
    fi

    # Find all session directories
    while IFS= read -r session_dir; do
        local session_id=$(basename "$session_dir")

        # Check if completed (has session.json with status=completed)
        if [[ -f "$session_dir/session.json" ]]; then
            if command -v jq &> /dev/null; then
                local status=$(jq -r '.status // "unknown"' "$session_dir/session.json")

                if [[ "$status" == "completed" || "$status" == "done" ]]; then
                    archive_session "$session_id"
                    archived=$((archived + 1))
                else
                    echo -e "${YELLOW}   Skipping $session_id (status: $status)${NC}"
                    skipped=$((skipped + 1))
                fi
            else
                # No jq, archive all
                archive_session "$session_id"
                archived=$((archived + 1))
            fi
        else
            # No session.json, consider it completed
            archive_session "$session_id"
            archived=$((archived + 1))
        fi
    done < <(find "$SWARMS_DIR/sessions" -mindepth 1 -maxdepth 1 -type d)

    echo ""
    echo "=" * 60
    echo -e "${GREEN}ARCHIVE SUMMARY${NC}"
    echo "=" * 60
    echo -e "\n📊 Archived: $archived"
    echo -e "⏭️  Skipped: $skipped"
    echo -e "\n📁 Archive location: $ARCHIVE_DIR"
    echo ""
}

archive_older_than() {
    local days=$1

    echo -e "${GREEN}📦 Archiving sessions older than $days days...${NC}"
    echo ""

    local archived=0
    local cutoff_date=$(date -v-${days}d +%s 2>/dev/null || date -d "$days days ago" +%s)

    if [[ ! -d "$SWARMS_DIR/sessions" ]]; then
        echo -e "${YELLOW}⚠️  No sessions directory${NC}"
        return 0
    fi

    # Find all session directories
    while IFS= read -r session_dir; do
        local session_id=$(basename "$session_dir")

        # Get modification time
        local mod_time=$(stat -f %m "$session_dir" 2>/dev/null || stat -c %Y "$session_dir")

        if [[ $mod_time -lt $cutoff_date ]]; then
            archive_session "$session_id"
            archived=$((archived + 1))
        else
            echo -e "${YELLOW}   Skipping $session_id (too recent)${NC}"
        fi
    done < <(find "$SWARMS_DIR/sessions" -mindepth 1 -maxdepth 1 -type d)

    echo ""
    echo "=" * 60
    echo -e "${GREEN}ARCHIVE SUMMARY${NC}"
    echo "=" * 60
    echo -e "\n📊 Archived: $archived"
    echo -e "📁 Archive location: $ARCHIVE_DIR"
    echo ""
}

list_archives() {
    echo -e "${GREEN}📁 Archived sessions:${NC}"
    echo ""

    if [[ ! -d "$SWARMS_DIR/archive" ]]; then
        echo -e "${YELLOW}⚠️  No archive directory${NC}"
        return 0
    fi

    # List all archived sessions by month
    while IFS= read -r month_dir; do
        local month=$(basename "$month_dir")
        echo -e "${GREEN}$month${NC}"

        while IFS= read -r session_dir; do
            local session_id=$(basename "$session_dir")
            echo "  - $session_id"
        done < <(find "$month_dir" -mindepth 1 -maxdepth 1 -type d)

        echo ""
    done < <(find "$SWARMS_DIR/archive" -mindepth 1 -maxdepth 1 -type d | sort)
}

# Main execution
case "$TARGET" in
    all)
        archive_all_completed
        ;;

    --older-than)
        if [[ -z "$OPTION" ]]; then
            echo -e "${RED}❌ Days parameter required${NC}"
            usage
        fi
        archive_older_than "$OPTION"
        ;;

    --list)
        list_archives
        ;;

    *)
        # Assume it's a session ID
        archive_session "$TARGET"
        ;;
esac

echo -e "${GREEN}✅ Archive operation complete!${NC}"
