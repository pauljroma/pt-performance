#!/bin/bash

# Open Supabase SQL Editor in browser
# This is where you'll apply the RLS migration

PROJECT_REF="rpbxeaxlaoyoqkohytlw"
SQL_EDITOR_URL="https://supabase.com/dashboard/project/${PROJECT_REF}/sql"

echo "="
echo "Opening Supabase SQL Editor..."
echo "="
echo ""
echo "📋 Next steps:"
echo "  1. Click '+ New Query' in the editor"
echo "  2. Copy migration SQL from: infra/009_fix_rls_policies.sql"
echo "  3. Paste and click 'Run'"
echo ""
echo "See APPLY_NOW_QUICK.md for complete instructions"
echo ""

# Open in default browser
open "$SQL_EDITOR_URL"

echo "✅ Browser opened to: $SQL_EDITOR_URL"
echo ""
