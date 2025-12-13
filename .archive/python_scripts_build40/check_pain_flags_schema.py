#!/usr/bin/env python3
"""
Check pain_flags Table Schema
===============================
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
}

print("Checking pain_flags table schema...")

# Try to get one row to see columns
url = f"{SUPABASE_URL}/rest/v1/pain_flags?limit=1&select=*"
response = requests.get(url, headers=headers)

if response.status_code == 200:
    data = response.json()
    if data:
        print(f"Columns: {list(data[0].keys())}")
    else:
        # Table exists but no data - need to check pg_catalog
        print("Table exists but no data. Checking schema via information_schema...")

        # Use PostgREST rpc if available, or try a different approach
        # For now, let's just try inserting a test row to see what columns are required
        print("\nTrying to understand required columns...")

        # Check if there's a seed data file that shows the structure
        print("Check migration files for table definition")
else:
    print(f"Error: {response.status_code} - {response.text}")
