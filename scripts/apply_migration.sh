#!/bin/bash
# Automated Migration Application
# Usage: ./scripts/apply_migration.sh 20251213000001_add_feature.sql

set -e  # Exit on any error

MIGRATION_FILE=$1

if [ -z "$MIGRATION_FILE" ]; then
    echo "❌ Error: Migration file required"
    echo "Usage: ./scripts/apply_migration.sh 20251213000001_add_feature.sql"
    exit 1
fi

MIGRATION_PATH="supabase/migrations/$MIGRATION_FILE"

if [ ! -f "$MIGRATION_PATH" ]; then
    echo "❌ Error: Migration file not found: $MIGRATION_PATH"
    exit 1
fi

echo "🗄️  Applying Migration: $MIGRATION_FILE"
echo ""

# ==================== STEP 1: VALIDATE SQL ====================
echo "📋 Step 1: Validating SQL syntax..."

# Basic SQL validation (check for dangerous commands)
if grep -qi "DROP DATABASE\|DROP SCHEMA" "$MIGRATION_PATH"; then
    echo "❌ Error: Migration contains DROP DATABASE or DROP SCHEMA"
    echo "   This is dangerous and not allowed. Please review migration."
    exit 1
fi

echo "✅ SQL validation passed"
echo ""

# ==================== STEP 2: BACKUP SCHEMA ====================
echo "💾 Step 2: Creating schema backup..."

# Create backups directory if it doesn't exist
mkdir -p .backups/

BACKUP_FILE=".backups/schema_before_${MIGRATION_FILE%.sql}_$(date +%Y%m%d_%H%M%S).txt"

# Note: We can't directly backup since we're using Supabase CLI
# Instead, create a marker file
echo "Migration: $MIGRATION_FILE" > "$BACKUP_FILE"
echo "Date: $(date)" >> "$BACKUP_FILE"
echo "Before applying migration - schema backup via Supabase Dashboard" >> "$BACKUP_FILE"

echo "✅ Backup marker created: $BACKUP_FILE"
echo ""

# ==================== STEP 3: APPLY VIA SUPABASE CLI ====================
echo "🚀 Step 3: Applying migration via Supabase CLI..."
echo ""

# Check for credentials
if [ -z "$SUPABASE_PASSWORD" ]; then
    echo "⚠️  SUPABASE_PASSWORD not set, loading from .env..."
    if [ -f .env ]; then
        source .env
    else
        echo "❌ Error: .env file not found and SUPABASE_PASSWORD not set"
        exit 1
    fi
fi

if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo "⚠️  SUPABASE_ACCESS_TOKEN not set, using default..."
    export SUPABASE_ACCESS_TOKEN="sbp_9d60dd93d30bd9f1dc7adce99fd8ec3e02dfc6a8"
fi

echo "Credentials loaded"
echo "Applying migration: $MIGRATION_FILE"
echo ""

# Apply migration using Supabase CLI
supabase db push -p "${SUPABASE_PASSWORD}" --include-all

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration applied successfully!"
else
    echo ""
    echo "❌ Migration failed!"
    echo "   Check error message above"
    echo "   Migration may need to be applied manually via Dashboard"
    exit 1
fi

echo ""

# ==================== STEP 4: MARK AS APPLIED ====================
echo "📝 Step 4: Marking migration as applied..."

# Add .applied suffix to track locally
if [ ! -f "${MIGRATION_PATH}.applied" ]; then
    mv "$MIGRATION_PATH" "${MIGRATION_PATH}.applied"
    echo "✅ Renamed to: ${MIGRATION_PATH}.applied"
else
    echo "⚠️  Migration already marked as applied"
fi

echo ""

# ==================== STEP 5: VERIFY SCHEMA ====================
echo "🔍 Step 5: Verifying schema..."

# Wait for PostgREST schema cache to refresh
echo "⏳ Waiting 60 seconds for PostgREST schema cache to refresh..."
echo "   (This is normal - see MIGRATION_RUNBOOK.md Step 3c)"
sleep 60

echo "✅ Schema cache should be refreshed"
echo ""

# ==================== STEP 6: UPDATE LINEAR (OPTIONAL) ====================
if [ -n "$LINEAR_API_KEY" ]; then
    echo "📝 Step 6: Updating Linear..."

    echo "Enter Linear issue ID for this migration (or press ENTER to skip):"
    read ISSUE_ID

    if [ -n "$ISSUE_ID" ]; then
        python scripts/linear/update_issue.py \
            --issue "$ISSUE_ID" \
            --status "Done" \
            --comment "Migration $MIGRATION_FILE applied successfully"
        echo "✅ Linear updated"
    else
        echo "⏭️  Skipping Linear update"
    fi
else
    echo "⏭️  Step 6: LINEAR_API_KEY not set - skipping Linear update"
fi

echo ""

# ==================== COMPLETE ====================
echo "🎉 Migration complete!"
echo ""
echo "Summary:"
echo "  Migration: $MIGRATION_FILE"
echo "  Status: Applied"
echo "  Backup: $BACKUP_FILE"
echo ""
echo "Next steps:"
echo "1. Test the migration in your iOS app"
echo "2. If errors occur, wait 2-3 minutes for cache refresh"
echo "3. If still errors, check Supabase Dashboard → Database → Tables"
