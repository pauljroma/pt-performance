#!/bin/bash

SUPABASE_URL="https://rpbxeaxlaoyoqkohytlw.supabase.co"
SERVICE_KEY="sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

echo "Fetching all auth users..."
echo ""

curl -s "${SUPABASE_URL}/auth/v1/admin/users" \
  -H "apikey: ${SERVICE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_KEY}" \
  | python3 -c "
import sys
import json
data = json.load(sys.stdin)
print(f'Total users: {len(data[\"users\"])}')
print('')
for user in data['users']:
    print(f'ID: {user[\"id\"]}')
    print(f'Email: {user[\"email\"]}')
    print(f'Created: {user[\"created_at\"]}')
    print('---')
"
