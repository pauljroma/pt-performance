#!/usr/bin/env python3
"""
Check Database Views
====================
Check what views exist for patient data access.
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
}

patient_id = "00000000-0000-0000-0000-000000000001"

print("=" * 80)
print("CHECKING DATABASE VIEWS")
print("=" * 80)

# Check if there's a vw_patient_sessions view
views_to_check = [
    "vw_patient_sessions",
    "vw_sessions",
    "patient_sessions",
]

for view_name in views_to_check:
    print(f"\nChecking {view_name}...")
    url = f"{SUPABASE_URL}/rest/v1/{view_name}?patient_id=eq.{patient_id}&limit=1&select=*"
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        data = response.json()
        if data:
            print(f"   ✅ View exists with columns: {', '.join(data[0].keys())}")
        else:
            print(f"   ✅ View exists but no data")
    else:
        print(f"   ❌ Not found")

print("\n" + "=" * 80)
