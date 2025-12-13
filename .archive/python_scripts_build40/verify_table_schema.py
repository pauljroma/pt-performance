#!/usr/bin/env python3
"""Verify exercise_logs table schema via SQL query"""

import requests

headers = {
    'apikey': 'sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3',
    'Authorization': 'Bearer sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3',
    'Content-Type': 'application/json'
}

# Query information_schema to check table structure
sql = """
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'exercise_logs'
ORDER BY ordinal_position;
"""

print("🔍 Checking exercise_logs table schema...")
print()

# Try using the postgres endpoint if available
# This is a workaround - we're using rpc to execute a query
response = requests.post(
    'https://rpbxeaxlaoyoqkohytlw.supabase.co/rest/v1/rpc/exec',
    headers=headers,
    json={'query': sql}
)

if response.status_code == 404:
    print("❌ RPC endpoint not available")
    print()
    print("The exercise_logs table needs to be created via Supabase Dashboard.")
    print()
    print("📋 Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new")
    print()
    print("📝 Run this SQL:")
    print("="*60)
    with open("supabase/migrations/20251212000001_create_exercise_logs_table.sql") as f:
        print(f.read())
    print("="*60)
else:
    print(f"Response: {response.status_code}")
    print(response.text[:1000])
