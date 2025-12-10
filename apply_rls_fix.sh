#!/bin/bash

# ============================================================================
# RLS Policy Fix - Quick Apply Script
# Date: 2025-12-09
# ============================================================================

set -e  # Exit on error

echo "=================================================="
echo "RLS Policy Fix - Deployment Script"
echo "=================================================="
echo ""

# Check if we're in the correct directory
if [ ! -f "infra/009_fix_rls_policies.sql" ]; then
    echo "❌ Error: Must run from /Users/expo/Code/expo/clients/linear-bootstrap/"
    exit 1
fi

echo "✅ Found migration file: infra/009_fix_rls_policies.sql"
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Error: Supabase CLI not found"
    echo "Install with: brew install supabase/tap/supabase"
    exit 1
fi

echo "✅ Supabase CLI installed"
echo ""

# Check if migration is already copied to supabase/migrations
if [ ! -f "supabase/migrations/20251209000009_fix_rls_policies.sql" ]; then
    echo "📋 Copying migration to supabase/migrations/..."
    cp infra/009_fix_rls_policies.sql supabase/migrations/20251209000009_fix_rls_policies.sql
    echo "✅ Migration copied"
else
    echo "✅ Migration already in supabase/migrations/"
fi
echo ""

# Try to link to Supabase project
echo "🔗 Linking to Supabase project..."
echo ""

# Check if already linked
if supabase status 2>&1 | grep -q "local database is not running"; then
    echo "⚠️  Local database not running (this is OK for remote deployment)"
elif supabase status 2>&1 | grep -q "Access token not provided"; then
    echo "⚠️  Not logged in to Supabase"
    echo ""
    echo "To deploy, you need to login to Supabase:"
    echo ""
    echo "  supabase login"
    echo ""
    echo "Then link to the project:"
    echo ""
    echo "  supabase link --project-ref rpbxeaxlaoyoqkohytlw --password \"rcq!vyd6qtb_HCP5mzt\""
    echo ""
    echo "Then deploy the migration:"
    echo ""
    echo "  supabase db push"
    echo ""
    echo "Or use the Supabase Dashboard to apply the migration manually."
    echo "See RLS_FIX_DEPLOYMENT_GUIDE.md for detailed instructions."
    echo ""
    exit 0
fi

# If we get here, try to push
echo "🚀 Deploying migration to Supabase..."
echo ""

if supabase db push; then
    echo ""
    echo "=================================================="
    echo "✅ MIGRATION DEPLOYED SUCCESSFULLY!"
    echo "=================================================="
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Run verification queries:"
    echo "   Open Supabase SQL Editor and run: test_rls_fix.sql"
    echo ""
    echo "2. Link patients to auth users:"
    echo "   Open Supabase SQL Editor and run: link_patients_to_auth.sql"
    echo ""
    echo "3. Test patient data access from iOS app"
    echo ""
    echo "4. Check RLS_FIX_DEPLOYMENT_GUIDE.md for details"
    echo ""
else
    echo ""
    echo "❌ Deployment failed"
    echo ""
    echo "Try manual deployment via Supabase Dashboard:"
    echo "1. Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw"
    echo "2. Click 'SQL Editor'"
    echo "3. Copy contents of infra/009_fix_rls_policies.sql"
    echo "4. Paste and run"
    echo ""
    echo "See RLS_FIX_DEPLOYMENT_GUIDE.md for detailed instructions."
    echo ""
    exit 1
fi
