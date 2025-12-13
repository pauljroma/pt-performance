#!/usr/bin/env python3
"""
Diagnose Current State - What's Actually Failing?
==================================================
"""

import requests
import json

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"
SUPABASE_SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

print("=" * 80)
print("COMPREHENSIVE DIAGNOSTIC - CURRENT STATE")
print("=" * 80)

# Login as therapist
print("\n[1] Login as therapist...")
response = requests.post(
    f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
    headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
    json={"email": "demo-pt@ptperformance.app", "password": "demo-therapist-2025"}
)

if response.status_code != 200:
    print(f"❌ LOGIN FAILED: {response.text}")
    exit(1)

auth_data = response.json()
access_token = auth_data["access_token"]
user_id = auth_data["user"]["id"]
headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {access_token}",
}
service_headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
}

print(f"✅ Login successful")
print(f"   User ID: {user_id}")

# Get therapist and patient
print("\n[2] Getting therapist and patient IDs...")
response = requests.get(f"{SUPABASE_URL}/rest/v1/therapists?user_id=eq.{user_id}&select=id", headers=headers)
if response.status_code == 200 and response.json():
    therapist_id = response.json()[0]['id']
    print(f"✅ Therapist ID: {therapist_id}")
else:
    print(f"❌ Can't get therapist: {response.text}")

response = requests.get(f"{SUPABASE_URL}/rest/v1/patients?select=id&limit=1", headers=headers)
if response.status_code == 200 and response.json():
    patient_id = response.json()[0]['id']
    print(f"✅ Patient ID: {patient_id}")
else:
    print(f"❌ Can't get patient: {response.text}")
    exit(1)

# ============================================================================
# CHECK SCHEMA STATE
# ============================================================================
print("\n" + "=" * 80)
print("SCHEMA CHECKS")
print("=" * 80)

# Check if migration was applied
print("\n[3] Checking if session_number column exists...")
response = requests.get(f"{SUPABASE_URL}/rest/v1/sessions?select=session_number&limit=1", headers=service_headers)
if response.status_code == 200:
    print("✅ session_number column EXISTS")
    if response.json():
        print(f"   Sample value: {response.json()[0]}")
else:
    print("❌ session_number column MISSING")
    print(f"   Error: {response.text}")
    print("   >>> Migration 20251211000008 NOT applied yet")

print("\n[4] Checking if exercise_name column exists...")
response = requests.get(f"{SUPABASE_URL}/rest/v1/exercise_templates?select=exercise_name&limit=1", headers=service_headers)
if response.status_code == 200:
    print("✅ exercise_name column EXISTS")
    if response.json():
        print(f"   Sample value: {response.json()[0]}")
else:
    print("❌ exercise_name column MISSING")
    print(f"   Error: {response.text}")
    print("   >>> Migration 20251211000008 NOT applied yet")

# ============================================================================
# TEST PATIENT DETAIL SECTIONS
# ============================================================================
print("\n" + "=" * 80)
print("PATIENT DETAIL SECTIONS (as therapist)")
print("=" * 80)

print("\n[5] Testing patient_flags...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/patient_flags?patient_id=eq.{patient_id}&select=*",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    flags = response.json()
    print(f"✅ {len(flags)} flags")
else:
    print(f"❌ FAILED: {response.text[:200]}")

print("\n[6] Testing vw_pain_trend...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/vw_pain_trend?patient_id=eq.{patient_id}&select=*",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    pain = response.json()
    print(f"✅ {len(pain)} data points")
    if pain:
        print(f"   Columns: {list(pain[0].keys())}")
else:
    print(f"❌ FAILED: {response.text[:200]}")

print("\n[7] Testing vw_patient_adherence...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/vw_patient_adherence?patient_id=eq.{patient_id}&select=*",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    adherence = response.json()
    print(f"✅ {len(adherence)} records")
    if adherence:
        print(f"   Data: {adherence[0]}")
else:
    print(f"❌ FAILED: {response.text[:200]}")

print("\n[8] Testing vw_patient_sessions...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=*&limit=5",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    sessions = response.json()
    print(f"✅ {len(sessions)} sessions")
    if sessions:
        print(f"   Columns: {list(sessions[0].keys())}")
else:
    print(f"❌ FAILED: {response.text[:200]}")

# ============================================================================
# TEST NOTES
# ============================================================================
print("\n" + "=" * 80)
print("NOTES FUNCTIONALITY")
print("=" * 80)

print("\n[9] Testing notes query...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/session_notes?patient_id=eq.{patient_id}&select=*&order=created_at.desc",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    notes = response.json()
    print(f"✅ {len(notes)} notes returned")
    if notes:
        note = notes[0]
        print(f"   Columns: {list(note.keys())}")
        print(f"   Sample: '{note.get('note_text', note.get('content', 'NO TEXT'))}'")

        # Check required fields
        required = ["id", "patient_id", "note_type", "note_text", "created_by", "created_at"]
        missing = [f for f in required if f not in note]
        if missing:
            print(f"   ⚠️  Missing iOS required fields: {missing}")
else:
    print(f"❌ FAILED: {response.text[:200]}")

# ============================================================================
# TEST PROGRAM LOADING
# ============================================================================
print("\n" + "=" * 80)
print("PROGRAM LOADING (exact iOS queries)")
print("=" * 80)

print("\n[10] Testing programs query...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?patient_id=eq.{patient_id}&select=*",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    programs = response.json()
    print(f"✅ {len(programs)} programs")
    if programs:
        program = programs[0]
        print(f"   Program: {program.get('name')}")
        print(f"   Columns: {list(program.keys())}")

        # Check required fields
        required = ["id", "patient_id", "name", "target_level", "duration_weeks"]
        missing = [f for f in required if f not in program or not program.get(f)]
        if missing:
            print(f"   ❌ Missing iOS required fields: {missing}")
        else:
            print(f"   ✅ All required fields present")

        program_id = program['id']

        print(f"\n[11] Testing phases query...")
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/phases?program_id=eq.{program_id}&select=*&order=phase_number.asc",
            headers=headers
        )
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            phases = response.json()
            print(f"✅ {len(phases)} phases")
            if phases:
                phase = phases[0]
                print(f"   Columns: {list(phase.keys())}")

                print(f"\n[12] Testing sessions query (WITH session_number)...")
                response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/sessions?phase_id=eq.{phase['id']}&select=*&order=session_number.asc",
                    headers=headers
                )
                print(f"Status: {response.status_code}")
                if response.status_code == 200:
                    sessions = response.json()
                    print(f"✅ {len(sessions)} sessions (using session_number)")

                    if sessions:
                        session = sessions[0]
                        print(f"   Columns: {list(session.keys())}")

                        print(f"\n[13] Testing session_exercises query (WITH exercise_name)...")
                        response = requests.get(
                            f"{SUPABASE_URL}/rest/v1/session_exercises?session_id=eq.{session['id']}&select=id,session_id,exercise_templates!inner(exercise_name),prescribed_sets&order=order_index.asc",
                            headers=headers
                        )
                        print(f"Status: {response.status_code}")
                        if response.status_code == 200:
                            exercises = response.json()
                            print(f"✅ {len(exercises)} exercises (using exercise_name)")
                            if exercises:
                                print(f"   Sample: {exercises[0]}")
                        else:
                            print(f"❌ FAILED: {response.text[:300]}")
                else:
                    print(f"❌ FAILED: {response.text[:300]}")
                    print("\n   >>> THIS IS THE PROBLEM - session_number column missing")
                    print("   >>> Apply migration 20251211000008")
        else:
            print(f"❌ FAILED: {response.text[:200]}")
else:
    print(f"❌ FAILED: {response.text[:200]}")

print("\n" + "=" * 80)
print("DIAGNOSIS SUMMARY")
print("=" * 80)
