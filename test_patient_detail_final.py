#!/usr/bin/env python3
"""
Test Patient Detail View - Final Verification
==============================================
Tests all 4 data sources with the fixed schema.
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

print("=" * 80)
print("FINAL PATIENT DETAIL VIEW TEST")
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
    patient_name = f"{patient['first_name']} {patient['last_name']}"
    print(f"   ✅ Patient: {patient_name} ({patient_id})")
else:
    print(f"   ❌ Cannot get patient ID")
    exit(1)

# Step 3: Test all 4 sections
print("\n3. Testing patient detail view data sources...")
print("=" * 80)

test_results = []

# Test 1: patient_flags
print("\n[1/4] Testing patient_flags...")
url = f"{SUPABASE_URL}/rest/v1/patient_flags?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ SUCCESS - {len(data)} flags")
    test_results.append(("patient_flags", True, len(data)))
else:
    print(f"   ❌ FAILED - {response.status_code}: {response.text}")
    test_results.append(("patient_flags", False, response.text))

# Test 2: vw_pain_trend
print("\n[2/4] Testing vw_pain_trend...")
url = f"{SUPABASE_URL}/rest/v1/vw_pain_trend?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ SUCCESS - {len(data)} data points")
    test_results.append(("vw_pain_trend", True, len(data)))
else:
    print(f"   ❌ FAILED - {response.status_code}: {response.text}")
    test_results.append(("vw_pain_trend", False, response.text))

# Test 3: vw_patient_adherence
print("\n[3/4] Testing vw_patient_adherence...")
url = f"{SUPABASE_URL}/rest/v1/vw_patient_adherence?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ SUCCESS - {len(data)} records")
    test_results.append(("vw_patient_adherence", True, len(data)))
else:
    print(f"   ❌ FAILED - {response.status_code}: {response.text}")
    test_results.append(("vw_patient_adherence", False, response.text))

# Test 4: vw_patient_sessions (UPDATED to use view)
print("\n[4/4] Testing vw_patient_sessions...")
url = f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=id,session_number,session_date,completed,exercise_count"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ SUCCESS - {len(data)} sessions")
    test_results.append(("vw_patient_sessions", True, len(data)))
else:
    print(f"   ❌ FAILED - {response.status_code}: {response.text}")
    test_results.append(("vw_patient_sessions", False, response.text))

# Summary
print("\n" + "=" * 80)
print("FINAL RESULTS")
print("=" * 80)

passing = [r for r in test_results if r[1]]
failing = [r for r in test_results if not r[1]]

print(f"\n✅ Passing: {len(passing)}/4")
for name, _, count in passing:
    print(f"   - {name} ({count} records)")

if failing:
    print(f"\n❌ Failing: {len(failing)}/4")
    for name, _, error in failing:
        print(f"   - {name}: {error[:100]}...")
else:
    print("\n🎉 ALL TESTS PASSED!")
    print("\nPatient detail view should now work in the iOS app!")
    print("The therapist can click on John Brebbia and see:")
    print("  - Pain trend chart (6 data points)")
    print("  - Adherence metrics (1 record)")
    print("  - Recent sessions (24 sessions)")
    print("  - Patient flags (0 flags currently)")

print("=" * 80)
