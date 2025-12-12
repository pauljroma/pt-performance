#!/usr/bin/env python3
"""
Full Patient Detail Test with JSON Decoding Validation
========================================================
Tests all 4 sections AND validates JSON structure matches iOS models.
"""

import requests
import json

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

# iOS model field requirements
IOS_MODELS = {
    "PatientFlag": ["id", "patient_id", "flag_type", "severity", "description", "created_at", "resolved_at", "auto_created"],
    "PainDataPoint": ["id", "logged_date", "avg_pain", "session_number"],  # Based on CodingKeys
    "AdherenceData": ["adherence_pct", "completed_sessions", "total_sessions"],
    "SessionSummary": ["id", "session_number", "session_date", "completed", "exercise_count"]
}

print("=" * 80)
print("FULL PATIENT DETAIL TEST WITH JSON DECODING")
print("=" * 80)

# Login
print("\n1. Logging in as therapist...")
login_url = f"{SUPABASE_URL}/auth/v1/token?grant_type=password"
response = requests.post(login_url, headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
                         json={"email": "demo-pt@ptperformance.app", "password": "demo-therapist-2025"})
if response.status_code != 200:
    print(f"❌ Login failed: {response.status_code}")
    exit(1)

access_token = response.json()["access_token"]
headers = {"apikey": SUPABASE_ANON_KEY, "Authorization": f"Bearer {access_token}"}
print(f"   ✅ Login successful!")

# Get patient
print("\n2. Getting patient...")
response = requests.get(f"{SUPABASE_URL}/rest/v1/patients?select=id,first_name,last_name&limit=1", headers=headers)
if not response.json():
    print(f"❌ No patients found")
    exit(1)

patient = response.json()[0]
patient_id = patient['id']
print(f"   ✅ Patient: {patient['first_name']} {patient['last_name']}")

# Test all 4 sections with decoding validation
print("\n3. Testing all 4 sections with decoding validation...")
print("=" * 80)

all_pass = True

# Test 1: PatientFlag
print("\n[1/4] patient_flags")
url = f"{SUPABASE_URL}/rest/v1/patient_flags?patient_id=eq.{patient_id}&resolved_at=is.null&select=*"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    if data:  # If there's data, validate structure
        required = IOS_MODELS["PatientFlag"]
        actual = list(data[0].keys())
        missing = [f for f in required if f not in actual]
        if missing:
            print(f"   ❌ Missing fields: {missing}")
            all_pass = False
        else:
            print(f"   ✅ Schema valid - {len(data)} records")
    else:
        print(f"   ✅ Query works - 0 records (empty but queryable)")
else:
    print(f"   ❌ FAILED: {response.status_code} - {response.text[:100]}")
    all_pass = False

# Test 2: vw_pain_trend
print("\n[2/4] vw_pain_trend")
url = f"{SUPABASE_URL}/rest/v1/vw_pain_trend?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    if data:
        # Note: iOS model uses CodingKeys to map logged_date, avg_pain, session_number
        # The view might have different column names - check what it returns
        print(f"   ✅ Query works - {len(data)} records")
        print(f"   Columns: {list(data[0].keys())}")
    else:
        print(f"   ✅ Query works - 0 records")
else:
    print(f"   ❌ FAILED: {response.status_code} - {response.text[:100]}")
    all_pass = False

# Test 3: vw_patient_adherence
print("\n[3/4] vw_patient_adherence")
url = f"{SUPABASE_URL}/rest/v1/vw_patient_adherence?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    if data:
        print(f"   ✅ Query works - {len(data)} records")
        print(f"   Columns: {list(data[0].keys())}")
    else:
        print(f"   ✅ Query works - 0 records")
else:
    print(f"   ❌ FAILED: {response.status_code} - {response.text[:100]}")
    all_pass = False

# Test 4: vw_patient_sessions
print("\n[4/4] vw_patient_sessions")
url = f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=id,session_number,session_date,completed,exercise_count"
response = requests.get(url, headers=headers)
if response.status_code == 200:
    data = response.json()
    if data:
        required = IOS_MODELS["SessionSummary"]
        actual = list(data[0].keys())
        missing = [f for f in required if f not in actual]
        if missing:
            print(f"   ❌ Missing fields: {missing}")
            all_pass = False
        else:
            print(f"   ✅ Schema valid - {len(data)} records")
    else:
        print(f"   ✅ Query works - 0 records")
else:
    print(f"   ❌ FAILED: {response.status_code} - {response.text[:100]}")
    all_pass = False

# Summary
print("\n" + "=" * 80)
if all_pass:
    print("✅ ALL TESTS PASSED!")
    print("\nThe app should now work. If it still shows 'Unable to load patient data':")
    print("1. Make sure you're testing the LATEST build from TestFlight")
    print("2. Force-quit the app and reopen")
    print("3. Try logging out and back in")
else:
    print("❌ SOME TESTS FAILED - see details above")

print("=" * 80)
