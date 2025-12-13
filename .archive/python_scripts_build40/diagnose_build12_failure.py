#!/usr/bin/env python3
"""
Diagnose Build 12 Failure
==========================
Tests exact queries from iOS app to identify what's failing.
"""

import requests
import json

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

print("=" * 80)
print("DIAGNOSING BUILD 12 FAILURE")
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
    user_id = auth_data['user']['id']
    print(f"   ✅ Login successful!")
    print(f"   User ID: {user_id}")
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
    print(f"   ✅ Patient: {patient['first_name']} {patient['last_name']} ({patient_id})")
else:
    print(f"   ❌ Cannot get patient: {response.status_code} - {response.text}")
    exit(1)

# Step 3: Test each query with DETAILED error reporting
print("\n3. Testing patient detail queries (EXACT iOS app queries)...")
print("=" * 80)

failures = []

# Test 1: Flags query (PatientDetailViewModel line 108-115)
print("\n[1/4] Testing patient_flags query...")
print("   Query: .from('patient_flags').select().eq('patient_id', '{patient_id}').is('resolved_at', null)")
url = f"{SUPABASE_URL}/rest/v1/patient_flags?patient_id=eq.{patient_id}&resolved_at=is.null&select=*"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
print(f"   Response: {response.text[:200]}")
if response.status_code != 200:
    failures.append(("patient_flags", response.status_code, response.text))

# Test 2: Pain trend query (AnalyticsService line 77-83)
print("\n[2/4] Testing vw_pain_trend query...")
print("   Query: .from('vw_pain_trend').select().eq('patient_id', '{patient_id}')")
url = f"{SUPABASE_URL}/rest/v1/vw_pain_trend?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
print(f"   Response: {response.text[:200]}")
if response.status_code != 200:
    failures.append(("vw_pain_trend", response.status_code, response.text))

# Test 3: Adherence query (AnalyticsService line 94-99)
print("\n[3/4] Testing vw_patient_adherence query...")
print("   Query: .from('vw_patient_adherence').select().eq('patient_id', '{patient_id}').single()")
url = f"{SUPABASE_URL}/rest/v1/vw_patient_adherence?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
print(f"   Response: {response.text[:200]}")
if response.status_code != 200:
    failures.append(("vw_patient_adherence", response.status_code, response.text))

# Test 4: Sessions query (AnalyticsService line 107-119) - UPDATED VERSION
print("\n[4/4] Testing vw_patient_sessions query (UPDATED)...")
print("   Query: .from('vw_patient_sessions').select('id,session_number,session_date,completed,exercise_count').eq('patient_id', '{patient_id}')")
url = f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=id,session_number,session_date,completed,exercise_count"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
print(f"   Response: {response.text[:200]}")
if response.status_code != 200:
    failures.append(("vw_patient_sessions", response.status_code, response.text))

# Check if Build 12 actually has the fix
print("\n" + "=" * 80)
print("CHECKING IF BUILD 12 INCLUDES THE FIX")
print("=" * 80)
print("\nThe iOS code should query 'vw_patient_sessions', not 'sessions'.")
print("If Build 12 still queries 'sessions', it means the code change didn't get included.")
print("\nLet me test the OLD query to see if that's what's happening...")

# Test OLD query (what Build 11 and earlier would use)
print("\n[DIAGNOSTIC] Testing OLD sessions query (sessions table)...")
url = f"{SUPABASE_URL}/rest/v1/sessions?patient_id=eq.{patient_id}&select=id,session_number,session_date,completed"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
if response.status_code != 200:
    print(f"   ❌ OLD query fails (expected) - {response.text[:100]}")
    print("\n   This confirms the OLD code path fails.")
    print("   If Build 12 is using this path, it means the code fix wasn't included in the build.")
else:
    print(f"   ⚠️ OLD query works? Unexpected!")

# Summary
print("\n" + "=" * 80)
print("DIAGNOSIS")
print("=" * 80)

if failures:
    print(f"\n❌ {len(failures)} queries failed:")
    for name, status, error in failures:
        print(f"\n   {name}:")
        print(f"   Status: {status}")
        print(f"   Error: {error[:200]}")

    print("\n" + "=" * 80)
    print("POSSIBLE CAUSES:")
    print("=" * 80)
    print("\n1. Build 12 doesn't include the AnalyticsService.swift code change")
    print("   - Check if Build 12 was built AFTER the code was modified")
    print("   - The build timestamp was 05:40:31, code was modified before that")

    print("\n2. Database views have issues")
    print("   - Views were created successfully according to migration")
    print("   - But there might be RLS policy issues")

    print("\n3. iOS app is caching old code or using different code path")
    print("   - Try force-quitting the app and reopening")
    print("   - Check TestFlight shows Build 12, not Build 11")
else:
    print("\n✅ All queries pass!")
    print("\nThis is strange - all backend queries work, but app shows error.")
    print("\nPossible issues:")
    print("1. App is still running Build 11 (check TestFlight build number)")
    print("2. App has different error handling that's not caught by these tests")
    print("3. There's a Swift/SDK issue not visible in HTTP tests")

print("=" * 80)
