#!/usr/bin/env python3
"""
Test Therapist RLS Policies
============================
Tests if the therapist can actually query patients using the ANON key
(which enforces RLS policies, just like the iOS app).
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"
SUPABASE_SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

print("=" * 80)
print("TESTING THERAPIST RLS POLICIES WITH ANON KEY")
print("=" * 80)

# Step 1: Login as therapist to get auth token
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
    user = auth_data.get('user')
    print(f"   ✅ Login successful!")
    print(f"   User ID: {user['id']}")
    print(f"   Email: {user['email']}")
else:
    print(f"   ❌ Login failed: {response.status_code}")
    print(f"   Response: {response.text}")
    exit(1)

# Step 2: Get therapist record to find therapist ID
print("\n2. Getting therapist record...")
therapist_headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}

therapist_url = f"{SUPABASE_URL}/rest/v1/therapists?email=eq.demo-pt@ptperformance.app&select=*"
response = requests.get(therapist_url, headers=therapist_headers)
if response.status_code == 200:
    therapists = response.json()
    if therapists:
        therapist = therapists[0]
        therapist_id = therapist['id']
        print(f"   ✅ Therapist found!")
        print(f"   ID: {therapist_id}")
        print(f"   Name: {therapist['first_name']} {therapist['last_name']}")
    else:
        print(f"   ❌ No therapist found with this email!")
        exit(1)
else:
    print(f"   ❌ Query failed: {response.status_code}")
    print(f"   Response: {response.text}")
    exit(1)

# Step 3: Query patients with therapist_id filter (this is what the iOS app does)
print("\n3. Querying patients for this therapist (with RLS enforced)...")
print(f"   Query: SELECT * FROM patients WHERE therapist_id = '{therapist_id}'")

patients_url = f"{SUPABASE_URL}/rest/v1/patients?therapist_id=eq.{therapist_id}&select=*"
response = requests.get(patients_url, headers=therapist_headers)

print(f"   Status: {response.status_code}")
if response.status_code == 200:
    patients = response.json()
    print(f"   ✅ Query successful!")
    print(f"   Patients found: {len(patients)}")

    if patients:
        for p in patients:
            print(f"     - {p['first_name']} {p['last_name']} ({p['email']})")
    else:
        print(f"     ⚠️ NO PATIENTS RETURNED!")
        print(f"     This means RLS policies are blocking the query!")
else:
    print(f"   ❌ Query failed!")
    print(f"   Response: {response.text}")

# Step 4: Try querying all patients (no filter) to see if RLS allows any access
print("\n4. Querying ALL patients (to test RLS)...")
all_patients_url = f"{SUPABASE_URL}/rest/v1/patients?select=*"
response = requests.get(all_patients_url, headers=therapist_headers)

print(f"   Status: {response.status_code}")
if response.status_code == 200:
    all_patients = response.json()
    print(f"   Patients returned: {len(all_patients)}")

    if all_patients:
        print(f"   ✅ RLS allows therapist to see {len(all_patients)} patient(s):")
        for p in all_patients:
            print(f"     - {p['first_name']} {p['last_name']} (therapist_id: {p.get('therapist_id', 'NULL')})")
    else:
        print(f"   ❌ RLS is blocking ALL patient queries for this therapist!")
        print(f"   The therapist RLS policy is too restrictive or broken!")
else:
    print(f"   ❌ Query failed: {response.text}")

print("\n" + "=" * 80)
print("DIAGNOSIS:")
print("=" * 80)

if response.status_code == 200:
    all_patients = response.json()
    if len(all_patients) > 0:
        print("✅ RLS policies are working - therapist CAN see patients")
        print("   The iOS app should work correctly.")
    else:
        print("❌ RLS policies are blocking therapist from seeing ANY patients!")
        print("   This is the root cause of the empty patient list in the app.")
        print("\nPossible causes:")
        print("   1. RLS policy uses auth.uid() but therapist.user_id doesn't match")
        print("   2. RLS policy logic is incorrect")
        print("   3. RLS policy references wrong column")
else:
    print("❌ Database query failed - check error message above")

print("=" * 80)
