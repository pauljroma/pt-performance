#!/usr/bin/env python3
"""
Test Patient Detail View RLS Policies
======================================
Tests each of the 4 data sources that PatientDetailViewModel queries:
1. patient_flags
2. vw_pain_trend
3. vw_patient_adherence
4. sessions

Uses ANON KEY (enforces RLS) to simulate iOS app behavior.
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

print("=" * 80)
print("TESTING PATIENT DETAIL VIEW RLS POLICIES")
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
    print(f"   ❌ Login failed: {response.status_code}")
    exit(1)

# Step 2: Get therapist ID and patient ID
print("\n2. Getting therapist and patient IDs...")
headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}

therapist_url = f"{SUPABASE_URL}/rest/v1/therapists?email=eq.demo-pt@ptperformance.app&select=id"
response = requests.get(therapist_url, headers=headers)
if response.status_code == 200 and response.json():
    therapist_id = response.json()[0]['id']
    print(f"   ✅ Therapist ID: {therapist_id}")
else:
    print(f"   ❌ Cannot get therapist ID")
    exit(1)

patients_url = f"{SUPABASE_URL}/rest/v1/patients?therapist_id=eq.{therapist_id}&select=id,first_name,last_name"
response = requests.get(patients_url, headers=headers)
if response.status_code == 200 and response.json():
    patient = response.json()[0]
    patient_id = patient['id']
    patient_name = f"{patient['first_name']} {patient['last_name']}"
    print(f"   ✅ Patient ID: {patient_id} ({patient_name})")
else:
    print(f"   ❌ Cannot get patient ID")
    exit(1)

# Step 3: Test each data source used by PatientDetailViewModel
print("\n3. Testing patient detail view data sources...")
print("=" * 80)

test_results = []

# Test 1: patient_flags
print("\nTest 1: patient_flags table")
url = f"{SUPABASE_URL}/rest/v1/patient_flags?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ SUCCESS - Returned {len(data)} flags")
    test_results.append(("patient_flags", True, len(data)))
else:
    print(f"   ❌ FAILED - {response.text}")
    test_results.append(("patient_flags", False, response.text))

# Test 2: vw_pain_trend view
print("\nTest 2: vw_pain_trend view")
url = f"{SUPABASE_URL}/rest/v1/vw_pain_trend?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ SUCCESS - Returned {len(data)} records")
    test_results.append(("vw_pain_trend", True, len(data)))
else:
    print(f"   ❌ FAILED - {response.text}")
    test_results.append(("vw_pain_trend", False, response.text))

# Test 3: vw_patient_adherence view
print("\nTest 3: vw_patient_adherence view")
url = f"{SUPABASE_URL}/rest/v1/vw_patient_adherence?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ SUCCESS - Returned {len(data)} records")
    test_results.append(("vw_patient_adherence", True, len(data)))
else:
    print(f"   ❌ FAILED - {response.text}")
    test_results.append(("vw_patient_adherence", False, response.text))

# Test 4: sessions table with join
print("\nTest 4: sessions table")
url = f"{SUPABASE_URL}/rest/v1/sessions?patient_id=eq.{patient_id}&select=id,session_number,session_date,completed,exercise_count:session_exercises(count)"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ SUCCESS - Returned {len(data)} sessions")
    test_results.append(("sessions", True, len(data)))
else:
    print(f"   ❌ FAILED - {response.text}")
    test_results.append(("sessions", False, response.text))

# Summary
print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)

passing = [r for r in test_results if r[1]]
failing = [r for r in test_results if not r[1]]

print(f"\n✅ Passing: {len(passing)}/4")
for name, _, count in passing:
    print(f"   - {name} ({count} records)")

print(f"\n❌ Failing: {len(failing)}/4")
for name, _, error in failing:
    print(f"   - {name}")
    print(f"     Error: {error}")

if failing:
    print("\n" + "=" * 80)
    print("ROOT CAUSE:")
    print("=" * 80)
    print(f"\nThe following tables/views need RLS policies for therapist access:")
    for name, _, _ in failing:
        print(f"  - {name}")
    print("\nThese tables/views need policies that allow therapists to query records")
    print("for patients they are assigned to (therapist_id linkage).")
else:
    print("\n✅ All queries work! The issue might be in the app logic or error handling.")

print("=" * 80)
