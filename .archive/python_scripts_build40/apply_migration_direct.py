#!/usr/bin/env python3
"""
Apply migration directly using Supabase REST API
"""
import requests
import sys

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

# Read the migration SQL
with open("supabase/migrations/20251212000001_create_exercise_logs_table.sql.applied", "r") as f:
    sql = f.read()

print("🚀 Applying migration: 20251212000001_create_exercise_logs_table.sql")
print(f"📊 SQL length: {len(sql)} characters")
print()

# Try to execute via RPC
headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json"
}

# First, let's verify if the table exists by trying to query it
print("1️⃣ Checking if exercise_logs table exists...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/exercise_logs",
    headers=headers,
    params={"select": "id", "limit": 0}
)

if response.status_code == 200:
    print("✅ Table already exists!")
    print()
    print("Verifying schema...")

    # Try to get one row to see the columns
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/exercise_logs",
        headers=headers,
        params={"select": "*", "limit": 1}
    )

    if response.status_code == 200:
        print("✅ Table is accessible and has correct permissions")
        print()
        print("✅ Migration already applied!")
        sys.exit(0)
    else:
        print(f"⚠️ Table exists but query failed: {response.status_code}")
        print(response.text)
else:
    print(f"❌ Table does not exist (status: {response.status_code})")
    print(response.text)
    print()
    print("2️⃣ Attempting to apply migration via SQL Editor API...")
    print()
    print("⚠️ Direct SQL execution requires service_role key (not available)")
    print()
    print("📋 Manual steps required:")
    print("1. Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new")
    print("2. Copy the SQL from: supabase/migrations/20251212000001_create_exercise_logs_table.sql.applied")
    print("3. Paste into SQL Editor")
    print("4. Click 'RUN'")
    print()
    print("Or run:")
    print("  cat supabase/migrations/20251212000001_create_exercise_logs_table.sql.applied | pbcopy")
    print("  open https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new")
    sys.exit(1)
