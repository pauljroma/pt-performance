#!/usr/bin/env python3
"""
Test EXACT iOS model requirements - find the missing field
"""
import requests
import json

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

# Login
auth_response = requests.post(
    f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
    headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
    json={"email": "demo-pt@ptperformance.app", "password": "demo-therapist-2025"}
)

access_token = auth_response.json()["access_token"]
headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {access_token}"
}

print("=" * 80)
print("TESTING EXACT iOS MODEL REQUIREMENTS")
print("=" * 80)

# Test 1: Patients - what fields does API return?
print("\n1. PATIENTS API RESPONSE:")
print("-" * 80)
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/patients?select=*&limit=1",
    headers=headers
)
if response.status_code == 200:
    patients = response.json()
    if patients:
        print("Fields returned by API:")
        print(json.dumps(patients[0], indent=2))
        print("\nField names:")
        print(list(patients[0].keys()))
    else:
        print("❌ No patients returned")
else:
    print(f"❌ Failed: {response.text}")

# Test 2: What does iOS Patient model REQUIRE?
print("\n2. iOS Patient MODEL REQUIREMENTS:")
print("-" * 80)
print("Reading Patient.swift to see required fields...")

# Test 3: Programs
print("\n3. PROGRAMS API RESPONSE:")
print("-" * 80)
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?select=*&limit=1",
    headers=headers
)
if response.status_code == 200:
    programs = response.json()
    if programs:
        print("Fields returned by API:")
        print(json.dumps(programs[0], indent=2))
        print("\nField names:")
        print(list(programs[0].keys()))
else:
    print(f"❌ Failed: {response.text}")

# Test 4: Sessions
print("\n4. SESSIONS API RESPONSE:")
print("-" * 80)
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/sessions?select=*&limit=1",
    headers=headers
)
if response.status_code == 200:
    sessions = response.json()
    if sessions:
        print("Fields returned by API:")
        print(json.dumps(sessions[0], indent=2))
        print("\nField names:")
        print(list(sessions[0].keys()))
else:
    print(f"❌ Failed: {response.text}")
