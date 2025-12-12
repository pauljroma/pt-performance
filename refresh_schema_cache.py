#!/usr/bin/env python3
"""
Refresh Supabase PostgREST schema cache
"""
import requests
import time

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

print("🔄 Refreshing PostgREST schema cache...")
print()

# Method 1: Send a request to a known table to trigger cache refresh
print("1️⃣ Triggering cache refresh via OPTIONS request...")
response = requests.options(
    f"{SUPABASE_URL}/rest/v1/",
    headers=headers
)
print(f"   Status: {response.status_code}")

# Wait a moment
time.sleep(2)

# Method 2: Try to access the new table again
print()
print("2️⃣ Testing exercise_logs table access...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/exercise_logs",
    headers={**headers, "Accept": "application/json"},
    params={"select": "*", "limit": 1}
)
print(f"   GET Status: {response.status_code}")

# Now try an insert with a dummy UUID that will fail FK constraint
print()
print("3️⃣ Testing insert (will fail on FK, but validates schema cache)...")
test_data = {
    "session_exercise_id": "00000000-0000-0000-0000-000000000001",
    "patient_id": "00000000-0000-0000-0000-000000000001",
    "actual_sets": 3,
    "actual_reps": [10, 10, 10],
    "actual_load": 135.0,
    "load_unit": "lbs",
    "rpe": 8,
    "pain_score": 5,
    "notes": "Schema cache test",
    "completed": True
}

response = requests.post(
    f"{SUPABASE_URL}/rest/v1/exercise_logs",
    headers=headers,
    json=test_data
)

print(f"   POST Status: {response.status_code}")
print(f"   Response: {response.text[:200]}")

if "Could not find" in response.text and "schema cache" in response.text:
    print()
    print("❌ Schema cache still not refreshed")
    print()
    print("📋 The schema cache refresh typically takes 30-60 seconds.")
    print("   Options:")
    print("   1. Wait 60 seconds and run this script again")
    print("   2. Go to Supabase Dashboard → Database → Restart PostgREST")
    print("   3. Go to SQL Editor and run: NOTIFY pgrst, 'reload schema';")
elif "violates foreign key" in response.text or response.status_code == 409:
    print()
    print("✅ Schema cache refreshed! Table is ready for use!")
    print("   (Foreign key error is expected - means schema is working)")
elif response.status_code == 201:
    print()
    print("⚠️ Test record was actually inserted (unexpected)")
    print("   You may need to delete it")
else:
    print()
    print(f"❓ Unexpected response: {response.status_code}")
    print(response.text)
