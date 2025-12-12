#!/usr/bin/env python3
"""
Debug As iPad - Test Exactly What iPad App Does
================================================
"""

import requests
import json

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

print("=" * 80)
print("DEBUG AS iPAD - EXACT APP BEHAVIOR")
print("=" * 80)

# Step 1: Login as therapist (what iPad does)
print("\n[1] Login as therapist (demo-pt@ptperformance.app)...")
response = requests.post(
    f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
    headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
    json={"email": "demo-pt@ptperformance.app", "password": "demo-therapist-2025"}
)

if response.status_code != 200:
    print(f"❌ LOGIN FAILED!")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")
    exit(1)

auth_data = response.json()
access_token = auth_data["access_token"]
user_id = auth_data["user"]["id"]
print(f"✅ Login successful")
print(f"   User ID: {user_id}")

headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# Step 2: Get patients (what PatientListViewModel does)
print("\n[2] Loading patient list (PatientListViewModel)...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/patients?select=*",
    headers=headers
)

print(f"Status: {response.status_code}")
if response.status_code == 200:
    patients = response.json()
    print(f"✅ {len(patients)} patients")
    if patients:
        patient_id = patients[0]['id']
        print(f"   First patient: {patients[0].get('first_name')} {patients[0].get('last_name')}")
        print(f"   Patient ID: {patient_id}")
    else:
        print("❌ NO PATIENTS RETURNED!")
        print("   RLS might be blocking access")
        exit(1)
else:
    print(f"❌ FAILED: {response.text}")
    exit(1)

# Step 3: Load patient detail sections
print("\n[3] Loading patient detail sections...")

# 3a: Flags
print("\n   [3a] patient_flags...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/patient_flags?patient_id=eq.{patient_id}&select=*",
    headers=headers
)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    flags = response.json()
    print(f"   ✅ {len(flags)} flags")
else:
    print(f"   ❌ FAILED: {response.text[:200]}")

# 3b: Pain trend
print("\n   [3b] vw_pain_trend...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/vw_pain_trend?patient_id=eq.{patient_id}&select=*",
    headers=headers
)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    pain = response.json()
    print(f"   ✅ {len(pain)} data points")
    if len(pain) == 0:
        print(f"   ⚠️  WARNING: No pain data!")
else:
    print(f"   ❌ FAILED: {response.text[:200]}")

# 3c: Adherence
print("\n   [3c] vw_patient_adherence...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/vw_patient_adherence?patient_id=eq.{patient_id}&select=*",
    headers=headers
)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    adherence = response.json()
    print(f"   ✅ {len(adherence)} records")
    if adherence:
        print(f"      Adherence: {adherence[0].get('adherence_pct')}%")
    else:
        print(f"   ⚠️  WARNING: No adherence data!")
else:
    print(f"   ❌ FAILED: {response.text[:200]}")

# 3d: Sessions
print("\n   [3d] vw_patient_sessions...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=*&limit=5",
    headers=headers
)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    sessions = response.json()
    print(f"   ✅ {len(sessions)} sessions")
    if len(sessions) == 0:
        print(f"   ⚠️  WARNING: No sessions!")
else:
    print(f"   ❌ FAILED: {response.text[:200]}")

# Step 4: Test NOTES (NotesService)
print("\n[4] Testing NOTES (exact NotesService.swift query)...")
print("   Query: .from('session_notes').select().eq('patient_id', patientId).order('created_at', desc)")

response = requests.get(
    f"{SUPABASE_URL}/rest/v1/session_notes?patient_id=eq.{patient_id}&select=*&order=created_at.desc",
    headers=headers
)

print(f"   Status: {response.status_code}")
if response.status_code == 200:
    notes = response.json()
    print(f"   ✅ Query succeeded - {len(notes)} notes")

    if notes:
        note = notes[0]
        print(f"\n   Checking note schema for iOS SessionNote model...")
        required = ["id", "patient_id", "session_id", "note_type", "note_text", "created_by", "created_at"]
        actual = list(note.keys())

        for field in required:
            if field in actual:
                value = note.get(field)
                if value is not None:
                    print(f"      ✅ {field}: {str(value)[:50]}")
                else:
                    print(f"      ⚠️  {field}: NULL")
            else:
                print(f"      ❌ {field}: MISSING")

        # Try to decode as iOS would
        print(f"\n   Testing JSON decoding compatibility...")
        try:
            # Simulate what iOS JSONDecoder would do
            for required_field in required:
                if required_field not in note:
                    print(f"      ❌ iOS decoding will FAIL - missing '{required_field}'")
                    break
            else:
                print(f"      ✅ iOS should be able to decode this note")
        except Exception as e:
            print(f"      ❌ Decoding error: {e}")
    else:
        print(f"   ⚠️  NO NOTES FOUND - but query succeeded")
        print(f"   This means RLS is working but no data exists")
else:
    print(f"   ❌ FAILED!")
    print(f"   Error: {response.text}")
    error = response.json()
    if 'code' in error:
        if error['code'] == '42501':
            print(f"   >>> RLS POLICY BLOCKING ACCESS!")
        elif error['code'] == '42703':
            print(f"   >>> COLUMN DOESN'T EXIST!")

# Step 5: Test ADD NOTE
print("\n[5] Testing ADD NOTE (exact iOS behavior)...")
from datetime import datetime
note_data = {
    "patient_id": patient_id,
    "session_id": None,
    "note_type": "general",
    "note_text": f"iPad test note at {datetime.now().isoformat()}"
    # created_by should be auto-filled by default function
}

print(f"   Sending: {json.dumps(note_data, indent=2)}")

response = requests.post(
    f"{SUPABASE_URL}/rest/v1/session_notes",
    headers=headers,
    json=note_data
)

print(f"   Status: {response.status_code}")
if response.status_code == 201:
    print(f"   ✅ Note created!")
    created_note = response.json()
    if created_note:
        print(f"   Note ID: {created_note[0]['id']}")
else:
    print(f"   ❌ FAILED!")
    print(f"   Error: {response.text}")
    error_data = response.json() if response.text else {}
    if 'code' in error_data:
        if error_data['code'] == '42501':
            print(f"   >>> RLS POLICY BLOCKING INSERT!")
        elif error_data['code'] == '23502':
            print(f"   >>> NULL VALUE VIOLATION!")
            print(f"   >>> Check which column is required but not provided")

# Step 6: Test PROGRAM loading (ProgramViewModel)
print("\n[6] Testing PROGRAM loading (exact ProgramViewModel.swift)...")

print("\n   [6a] Get program...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?patient_id=eq.{patient_id}&select=*",
    headers=headers
)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    programs = response.json()
    if programs:
        program = programs[0]
        print(f"   ✅ Program: {program.get('name')}")

        # Check required fields
        required = ["id", "patient_id", "name", "target_level", "duration_weeks", "created_at"]
        missing = [f for f in required if f not in program or program.get(f) is None]
        if missing:
            print(f"   ❌ Missing required fields: {missing}")
            print(f"   >>> iOS will fail with 'data missing' error")
        else:
            print(f"   ✅ All required fields present")

        program_id = program['id']

        print("\n   [6b] Get phases...")
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/phases?program_id=eq.{program_id}&select=*&order=phase_number.asc",
            headers=headers
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            phases = response.json()
            print(f"   ✅ {len(phases)} phases")

            if phases:
                phase_id = phases[0]['id']

                print("\n   [6c] Get sessions...")
                response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/sessions?phase_id=eq.{phase_id}&select=*&order=session_number.asc",
                    headers=headers
                )
                print(f"   Status: {response.status_code}")
                if response.status_code == 200:
                    sessions = response.json()
                    print(f"   ✅ {len(sessions)} sessions")

                    if sessions:
                        session_id = sessions[0]['id']

                        print("\n   [6d] Get exercises...")
                        response = requests.get(
                            f"{SUPABASE_URL}/rest/v1/session_exercises?session_id=eq.{session_id}&select=id,session_id,exercise_templates!inner(exercise_name),prescribed_sets,prescribed_reps,prescribed_load,load_unit,rest_period_seconds,order_index&order=order_index.asc",
                            headers=headers
                        )
                        print(f"   Status: {response.status_code}")
                        if response.status_code == 200:
                            exercises = response.json()
                            print(f"   ✅ {len(exercises)} exercises")
                        else:
                            print(f"   ❌ FAILED: {response.text[:300]}")
                else:
                    print(f"   ❌ FAILED: {response.text[:300]}")
        else:
            print(f"   ❌ FAILED: {response.text[:300]}")
    else:
        print(f"   ⚠️  NO PROGRAMS FOUND!")
else:
    print(f"   ❌ FAILED: {response.text[:300]}")

print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)
print("\nIf you see failures above, those are what's breaking the iPad app.")
print("=" * 80)
