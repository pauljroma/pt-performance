#!/bin/bash
# Deploy sync-whoop-recovery Edge Function
# Build 138 - WHOOP Integration MVP

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Deploying sync-whoop-recovery Edge Function              ║"
echo "║  Build 138 - WHOOP Integration MVP                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in the right directory
if [ ! -f "index.ts" ]; then
    echo "❌ Error: Must run from supabase/functions/sync-whoop-recovery directory"
    exit 1
fi

# Run tests first
echo "📋 Running tests..."
deno run --allow-read test.ts

if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Aborting deployment."
    exit 1
fi

echo "✅ Tests passed"
echo ""

# Deploy the function
echo "🚀 Deploying function to Supabase..."
cd ../../.. # Go to project root
supabase functions deploy sync-whoop-recovery

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed"
    exit 1
fi

echo "✅ Function deployed successfully"
echo ""

# Check if secrets are set
echo "🔐 Checking secrets..."
SECRETS_NEEDED=("WHOOP_CLIENT_ID" "WHOOP_CLIENT_SECRET")
MISSING_SECRETS=()

for secret in "${SECRETS_NEEDED[@]}"; do
    # Note: This won't work without Supabase CLI access to secrets
    # Just informational
    echo "   - $secret (set manually with: supabase secrets set $secret=...)"
done

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ DEPLOYMENT COMPLETE                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "1. Set WHOOP OAuth secrets:"
echo "   supabase secrets set WHOOP_CLIENT_ID=your_client_id"
echo "   supabase secrets set WHOOP_CLIENT_SECRET=your_client_secret"
echo ""
echo "2. Add whoop_oauth_credentials column to patients table (if not exists):"
echo "   ALTER TABLE patients ADD COLUMN IF NOT EXISTS whoop_oauth_credentials JSONB;"
echo ""
echo "3. Test the function:"
echo "   curl -X POST https://your-project.supabase.co/functions/v1/sync-whoop-recovery \\"
echo "     -H \"Authorization: Bearer YOUR_ANON_KEY\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"patient_id\": \"test-uuid\"}'"
echo ""
