#!/usr/bin/env python3
"""
Check Database Schema
=====================
Check the actual schema for pain_flags and sessions tables.
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
}

print("=" * 80)
print("CHECKING DATABASE SCHEMA")
print("=" * 80)

# Check pain_flags table schema
print("\n1. Checking pain_flags table...")
url = f"{SUPABASE_URL}/rest/v1/pain_flags?limit=1&select=*"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    if data:
        print(f"   ✅ Table exists")
        print(f"   Columns: {', '.join(data[0].keys())}")
    else:
        print(f"   ⚠️ Table exists but no data")
else:
    print(f"   ❌ Table doesn't exist or error: {response.text}")

# Check sessions table schema
print("\n2. Checking sessions table...")
url = f"{SUPABASE_URL}/rest/v1/sessions?limit=1&select=*"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    if data:
        print(f"   ✅ Table exists")
        print(f"   Columns: {', '.join(data[0].keys())}")
    else:
        print(f"   ⚠️ Table exists but no data")
else:
    print(f"   ❌ Table doesn't exist or error: {response.text}")

# Check if sessions has data for our patient
print("\n3. Checking sessions for patient John Brebbia...")
patient_id = "00000000-0000-0000-0000-000000000001"
url = f"{SUPABASE_URL}/rest/v1/sessions?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ Found {len(data)} sessions")
    if data:
        print(f"   Sample session columns: {', '.join(data[0].keys())}")
else:
    print(f"   ❌ Error: {response.text}")

print("=" * 80)
