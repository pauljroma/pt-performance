#!/bin/bash

# Print migration SQL for easy copying
# Usage: ./print_migration_sql.sh

echo "="
echo "RLS Migration SQL - Ready to Copy"
echo "="
echo ""
echo "INSTRUCTIONS:"
echo "1. Select ALL the SQL below (from ALTER TABLE to the last ;)"
echo "2. Copy to clipboard (Cmd+C)"
echo "3. Open Supabase SQL Editor:"
echo "   https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql"
echo "4. Click '+ New Query'"
echo "5. Paste (Cmd+V) and click 'Run'"
echo ""
echo "="
echo "MIGRATION SQL STARTS BELOW THIS LINE"
echo "="
echo ""

cat /Users/expo/Code/expo/clients/linear-bootstrap/infra/009_fix_rls_policies.sql

echo ""
echo "="
echo "MIGRATION SQL ENDS ABOVE THIS LINE"
echo "="
echo ""
echo "NEXT: After migration succeeds, run this to link patients:"
echo ""
echo "UPDATE patients p"
echo "SET user_id = au.id"
echo "FROM auth.users au"
echo "WHERE p.email = au.email AND p.user_id IS NULL;"
echo ""
echo "SELECT COUNT(*) as total, COUNT(user_id) as linked FROM patients;"
echo ""
