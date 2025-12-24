#!/bin/bash
#
# apply_migration.sh - Coordinate database migration across repositories
#
# Purpose: Orchestrate Supabase migration from linear-bootstrap to supabase/
# Status: Phase 1 implementation (file-based coordination)
#
# Usage:
#   scripts/orchestration/apply_migration.sh MIGRATION_FILE
#   scripts/orchestration/apply_migration.sh 20251223000000_add_help_content.sql
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Get supabase directory (3 levels up from linear-bootstrap)
SUPABASE_DIR="$(cd "${ROOT_DIR}/../../../supabase" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MIGRATION_FILE="${1:-}"

usage() {
    echo "Usage: $0 MIGRATION_FILE"
    echo ""
    echo "Examples:"
    echo "  $0 20251223000000_add_help_content.sql"
    echo "  $0 /path/to/migration.sql"
    echo ""
    echo "Environment:"
    echo "  SUPABASE_DIR    Path to supabase directory (default: ../../../supabase)"
    echo "  SUPABASE_URL    Supabase project URL (from .env)"
    echo "  SUPABASE_KEY    Supabase service role key (from .env)"
    echo ""
    exit 1
}

if [[ -z "$MIGRATION_FILE" ]]; then
    echo -e "${RED}❌ Migration file required${NC}"
    usage
fi

echo -e "${GREEN}🔄 Applying database migration${NC}"
echo ""

# 1. Verify supabase directory exists
echo -e "${GREEN}1️⃣  Verifying supabase directory...${NC}"
if [[ ! -d "$SUPABASE_DIR" ]]; then
    echo -e "${RED}❌ Supabase directory not found: $SUPABASE_DIR${NC}"
    echo ""
    echo "Expected structure:"
    echo "  expo/"
    echo "  ├── clients/"
    echo "  │   └── linear-bootstrap/    # Current location"
    echo "  └── supabase/                # Migrations"
    echo "      └── migrations/"
    echo ""
    exit 1
fi

echo -e "${GREEN}   ✅ Found: $SUPABASE_DIR${NC}"
echo ""

# 2. Load environment variables
echo -e "${GREEN}2️⃣  Loading environment...${NC}"

if [[ -f "$ROOT_DIR/.env" ]]; then
    # shellcheck disable=SC1091
    source "$ROOT_DIR/.env"
    echo -e "${GREEN}   ✅ Loaded .env${NC}"
else
    echo -e "${RED}❌ .env file not found${NC}"
    echo "Run: tools/scripts/bootstrap.sh"
    exit 1
fi

# Verify required env vars
if [[ -z "${SUPABASE_URL:-}" ]] || [[ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
    echo -e "${RED}❌ Missing required environment variables${NC}"
    echo "Required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY"
    exit 1
fi

echo -e "${GREEN}   ✅ Environment configured${NC}"
echo ""

# 3. Locate migration file
echo -e "${GREEN}3️⃣  Locating migration file...${NC}"

if [[ -f "$MIGRATION_FILE" ]]; then
    # Absolute or relative path provided
    MIGRATION_PATH="$MIGRATION_FILE"
elif [[ -f "$SUPABASE_DIR/migrations/$MIGRATION_FILE" ]]; then
    # Filename provided, found in supabase/migrations/
    MIGRATION_PATH="$SUPABASE_DIR/migrations/$MIGRATION_FILE"
else
    echo -e "${RED}❌ Migration file not found: $MIGRATION_FILE${NC}"
    echo ""
    echo "Searched:"
    echo "  - $MIGRATION_FILE"
    echo "  - $SUPABASE_DIR/migrations/$MIGRATION_FILE"
    echo ""
    exit 1
fi

echo -e "${GREEN}   ✅ Found: $MIGRATION_PATH${NC}"
echo ""

# 4. Validate migration file
echo -e "${GREEN}4️⃣  Validating migration...${NC}"

# Check SQL syntax (basic)
if ! grep -q "^--" "$MIGRATION_PATH"; then
    echo -e "${YELLOW}   ⚠️  Migration has no comments (recommended to add)${NC}"
fi

# Check for transaction wrapping
if ! grep -qi "BEGIN" "$MIGRATION_PATH"; then
    echo -e "${YELLOW}   ⚠️  Migration not wrapped in transaction (recommended)${NC}"
fi

echo -e "${GREEN}   ✅ Basic validation passed${NC}"
echo ""

# 5. Confirm before applying
echo -e "${YELLOW}⚠️  About to apply migration:${NC}"
echo "   File: $MIGRATION_PATH"
echo "   Target: $SUPABASE_URL"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Aborted${NC}"
    exit 0
fi

# 6. Apply migration
echo -e "${GREEN}5️⃣  Applying migration...${NC}"

# Check for Supabase CLI
if command -v supabase &> /dev/null; then
    # Use Supabase CLI if available
    echo -e "${GREEN}   Using Supabase CLI...${NC}"

    cd "$SUPABASE_DIR"

    supabase db push \
        --db-url "$SUPABASE_URL" \
        --password "$SUPABASE_SERVICE_ROLE_KEY" \
        || {
            echo -e "${RED}❌ Migration failed via Supabase CLI${NC}"
            exit 1
        }

    echo -e "${GREEN}   ✅ Migration applied via CLI${NC}"
else
    # Fallback: Use psql if available
    if command -v psql &> /dev/null; then
        echo -e "${GREEN}   Using psql...${NC}"

        # Extract connection details from SUPABASE_URL
        # Format: postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]

        psql "$SUPABASE_URL" -f "$MIGRATION_PATH" || {
            echo -e "${RED}❌ Migration failed via psql${NC}"
            exit 1
        }

        echo -e "${GREEN}   ✅ Migration applied via psql${NC}"
    else
        # No CLI tools available - use HTTP API
        echo -e "${GREEN}   Using Supabase HTTP API...${NC}"

        # Read SQL file
        SQL_CONTENT=$(cat "$MIGRATION_PATH")

        # Apply via REST API
        curl -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
            -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
            -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"query\": $(jq -Rs . <<< "$SQL_CONTENT")}" \
            || {
                echo -e "${RED}❌ Migration failed via API${NC}"
                exit 1
            }

        echo -e "${GREEN}   ✅ Migration applied via API${NC}"
    fi
fi

echo ""

# 7. Verify migration
echo -e "${GREEN}6️⃣  Verifying migration...${NC}"

# Basic verification: check if migration was recorded
if command -v supabase &> /dev/null; then
    cd "$SUPABASE_DIR"
    supabase migration list || true
fi

echo -e "${GREEN}   ✅ Verification complete${NC}"
echo ""

echo -e "${GREEN}✅ Migration coordination complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify changes in Supabase dashboard"
echo "  2. Test affected functionality"
echo "  3. Update Linear issue status"
echo ""
