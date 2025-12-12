#!/usr/bin/env python3
"""Apply migration using Supabase REST API"""

import os
import requests
from pathlib import Path

# Read migration
migration_file = Path("supabase/migrations/20251212000001_create_exercise_logs_table.sql")
with open(migration_file) as f:
    sql = f.read()

# Supabase config
SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

print(f"🚀 Applying migration: {migration_file.name}")

# Try PostgREST RPC endpoint
headers = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# Execute SQL via REST API using the postgrest endpoint
# We'll execute each statement separately
statements = [s.strip() for s in sql.split(';') if s.strip() and not s.strip().startswith('--')]

print(f"📝 Executing {len(statements)} SQL statements...")

for i, stmt in enumerate(statements, 1):
    if not stmt or len(stmt) < 5:
        continue

    print(f"\n[{i}/{len(statements)}] Executing statement...")

    # Use the REST API query endpoint
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec",
            headers=headers,
            json={"query": stmt}
        )

        if response.status_code in [200, 201, 204]:
            print(f"  ✅ Success")
        else:
            print(f"  ⚠️  Status {response.status_code}: {response.text[:200]}")
    except Exception as e:
        print(f"  ⚠️  Error: {e}")

print("\n" + "="*60)
print("✅ Migration execution attempted")
print("📊 Verifying table creation...")

# Verify table exists via REST API
verify_response = requests.get(
    f"{SUPABASE_URL}/rest/v1/exercise_logs?limit=1",
    headers=headers
)

if verify_response.status_code == 200:
    print("✅ SUCCESS! exercise_logs table exists and is accessible")
    print("\n🎉 Build 32 migration complete!")
    print("📱 Exercise logging feature is now fully functional")
elif verify_response.status_code == 404 or "does not exist" in verify_response.text:
    print("❌ Table not created - using Supabase Dashboard fallback")
    print("\n📋 Copy this SQL to Supabase Dashboard:")
    print("https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new")
    print("\n" + "="*60)
    print(sql)
    print("="*60)
else:
    print(f"⚠️  Unexpected response: {verify_response.status_code}")
    print(verify_response.text[:500])
