#!/bin/bash
#
# rehydrate.sh - Rehydrate agent context from previous session
#
# Purpose: Restore agent context from completed swarm sessions
# Usage:
#   .swarms/bin/rehydrate.sh SESSION_ID
#   .swarms/bin/rehydrate.sh 20251223_architecture_rollout
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWARMS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${SWARMS_DIR}/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SESSION_ID="${1:-}"

usage() {
    echo "Usage: $0 SESSION_ID"
    echo ""
    echo "Rehydrate agent context from completed swarm session."
    echo ""
    echo "Examples:"
    echo "  $0 20251223_architecture_rollout"
    echo "  $0 latest  # Use most recent session"
    echo ""
    echo "Available sessions:"
    ls -1 "$SWARMS_DIR/sessions/" 2>/dev/null | head -10 || echo "  (none found)"
    echo ""
    exit 1
}

if [[ -z "$SESSION_ID" ]]; then
    usage
fi

# Handle 'latest' shortcut
if [[ "$SESSION_ID" == "latest" ]]; then
    SESSION_ID=$(ls -1t "$SWARMS_DIR/sessions/" | head -1)
    if [[ -z "$SESSION_ID" ]]; then
        echo -e "${RED}❌ No sessions found${NC}"
        exit 1
    fi
    echo -e "${GREEN}Using latest session: $SESSION_ID${NC}"
fi

SESSION_DIR="$SWARMS_DIR/sessions/$SESSION_ID"

echo -e "${GREEN}🔄 Rehydrating context from session: $SESSION_ID${NC}"
echo ""

# 1. Verify session exists
echo -e "${GREEN}1️⃣  Verifying session...${NC}"
if [[ ! -d "$SESSION_DIR" ]]; then
    echo -e "${RED}❌ Session not found: $SESSION_DIR${NC}"
    echo ""
    echo "Available sessions:"
    ls -1 "$SWARMS_DIR/sessions/" 2>/dev/null || echo "  (none found)"
    exit 1
fi

echo -e "${GREEN}   ✅ Found session directory${NC}"
echo ""

# 2. Load session metadata
echo -e "${GREEN}2️⃣  Loading session metadata...${NC}"

if [[ -f "$SESSION_DIR/session.json" ]]; then
    # Extract metadata
    SWARM_NAME=$(jq -r '.name // "Unknown"' "$SESSION_DIR/session.json")
    AGENT_COUNT=$(jq -r '.agents | length // 0' "$SESSION_DIR/session.json")
    STATUS=$(jq -r '.status // "unknown"' "$SESSION_DIR/session.json")

    echo -e "${GREEN}   Swarm: $SWARM_NAME${NC}"
    echo -e "${GREEN}   Agents: $AGENT_COUNT${NC}"
    echo -e "${GREEN}   Status: $STATUS${NC}"
else
    echo -e "${YELLOW}   ⚠️  No session.json found (basic session)${NC}"
    SWARM_NAME="Unknown"
fi

echo ""

# 3. Check for outcomes
echo -e "${GREEN}3️⃣  Checking outcomes...${NC}"

OUTCOME_FILES=$(find "$SESSION_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

if [[ $OUTCOME_FILES -gt 0 ]]; then
    echo -e "${GREEN}   ✅ Found $OUTCOME_FILES outcome files${NC}"

    # List outcome files
    find "$SESSION_DIR" -name "*.md" -type f | while read -r outcome; do
        echo -e "${GREEN}      - $(basename "$outcome")${NC}"
    done
else
    echo -e "${YELLOW}   ⚠️  No outcome files found${NC}"
fi

echo ""

# 4. Generate context summary
echo -e "${GREEN}4️⃣  Generating context summary...${NC}"

CONTEXT_FILE="$ROOT_DIR/.swarms/context/rehydrated_${SESSION_ID}.md"

cat > "$CONTEXT_FILE" << EOF
# Rehydrated Context - $SESSION_ID

**Generated:** $(date +%Y-%m-%d\ %H:%M:%S)
**Source Session:** $SESSION_ID
**Swarm:** $SWARM_NAME

---

## Session Summary

- **Session ID:** $SESSION_ID
- **Swarm Name:** $SWARM_NAME
- **Agent Count:** $AGENT_COUNT
- **Status:** $STATUS

---

## Session Contents

EOF

# Add session files
if [[ -f "$SESSION_DIR/README.md" ]]; then
    echo "### Session README" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
    cat "$SESSION_DIR/README.md" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
fi

# Add outcomes
if [[ $OUTCOME_FILES -gt 0 ]]; then
    echo "### Outcomes" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"

    find "$SESSION_DIR" -name "*.md" -type f | while read -r outcome; do
        echo "#### $(basename "$outcome")" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        cat "$outcome" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
    done
fi

# Add deliverables (if tracked)
if [[ -f "$SESSION_DIR/deliverables.json" ]]; then
    echo "### Deliverables" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
    jq -r '.[] | "- \(.status): \(.path) (\(.description))"' "$SESSION_DIR/deliverables.json" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
fi

echo -e "${GREEN}   ✅ Context file created: $CONTEXT_FILE${NC}"
echo ""

# 5. Create handoff document
echo -e "${GREEN}5️⃣  Creating handoff document...${NC}"

HANDOFF_FILE="$ROOT_DIR/.swarms/handoffs/handoff_${SESSION_ID}_$(date +%Y%m%d_%H%M%S).md"

cat > "$HANDOFF_FILE" << EOF
# Session Handoff - $SESSION_ID

**Date:** $(date +%Y-%m-%d\ %H:%M:%S)
**Session:** $SESSION_ID
**Swarm:** $SWARM_NAME

---

## What Was Accomplished

EOF

# Add high-level summary from outcomes
if [[ $OUTCOME_FILES -gt 0 ]]; then
    find "$SESSION_DIR" -name "*.md" -type f | while read -r outcome; do
        # Extract first heading or summary
        echo "### $(basename "$outcome" .md)" >> "$HANDOFF_FILE"
        head -20 "$outcome" | grep -A 5 "## Summary" | tail -5 >> "$HANDOFF_FILE" || true
        echo "" >> "$HANDOFF_FILE"
    done
fi

cat >> "$HANDOFF_FILE" << EOF

## Files Modified

EOF

# List files from deliverables
if [[ -f "$SESSION_DIR/deliverables.json" ]]; then
    jq -r '.[] | .path' "$SESSION_DIR/deliverables.json" >> "$HANDOFF_FILE"
fi

cat >> "$HANDOFF_FILE" << EOF

## Next Steps

1. Review context file: $CONTEXT_FILE
2. Verify changes are correct
3. Run validation: tools/scripts/validate.sh all
4. Continue with next phase

---

**Rehydration Complete**
EOF

echo -e "${GREEN}   ✅ Handoff created: $HANDOFF_FILE${NC}"
echo ""

# 6. Summary
echo -e "${GREEN}✅ Rehydration complete!${NC}"
echo ""
echo "Context restored from session: $SESSION_ID"
echo ""
echo "Generated files:"
echo "  - Context: $CONTEXT_FILE"
echo "  - Handoff: $HANDOFF_FILE"
echo ""
echo "Next steps:"
echo "  1. Review context file for summary"
echo "  2. Read handoff document for next steps"
echo "  3. Continue work from last checkpoint"
echo ""
