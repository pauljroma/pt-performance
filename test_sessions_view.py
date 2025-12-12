#!/usr/bin/env python3
"""
Test vw_patient_sessions View
==============================
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

print("=" * 80)
print("TESTING vw_patient_sessions VIEW")
print("=" * 80)

# Step 1: Login as therapist
print("\n1. Logging in as demo therapist...")
login_url = f"{SUPABASE_URL}/auth/v1/token?grant_type=password"
login_headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Content-Type": "application/json"
}
login_data = {
    "email": "demo-pt@ptperformance.app",
    "password": "demo-therapist-2025"
}

response = requests.post(login_url, headers=login_headers, json=login_data)
if response.status_code == 200:
    auth_data = response.json()
    access_token = auth_data.get('access_token')
    print(f"   ✅ Login successful!")
else:
    print(f"   ❌ Login failed")
    exit(1)

# Step 2: Get patient ID
print("\n2. Getting patient ID...")
headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {access_token}",
}

patients_url = f"{SUPABASE_URL}/rest/v1/patients?select=id,first_name,last_name&limit=1"
response = requests.get(patients_url, headers=headers)
if response.status_code == 200 and response.json():
    patient = response.json()[0]
    patient_id = patient['id']
    print(f"   ✅ Patient ID: {patient_id} ({patient['first_name']} {patient['last_name']})")
else:
    print(f"   ❌ Cannot get patient ID")
    exit(1)

# Step 3: Test vw_patient_sessions
print("\n3. Testing vw_patient_sessions view...")
url = f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=id,session_number,session_date,completed,exercise_count"
response = requests.get(url, headers=headers)

print(f"   Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ SUCCESS - Returned {len(data)} sessions")
    if data:
        for s in data[:3]:  # Show first 3
            print(f"     - Session {s.get('session_number')}: {s.get('name', 'N/A')}")
else:
    print(f"   ❌ FAILED - {response.text}")

print("=" * 80)
