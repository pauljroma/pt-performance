#!/usr/bin/env python3
"""
Test Build 13 Failures - Debug what iPad is seeing
"""
import os
import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

# Login as therapist
print("=" * 60)
print("TESTING BUILD 13 - THERAPIST LOGIN")
print("=" * 60)

auth_response = requests.post(
    f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
    headers={
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json"
    },
    json={
        "email": "demo-pt@ptperformance.app",
        "password": "demo-therapist-2025"
    }
)

if auth_response.status_code != 200:
    print(f"❌ Login failed: {auth_response.status_code}")
    print(auth_response.text)
    exit(1)

auth_data = auth_response.json()
access_token = auth_data["access_token"]
user_id = auth_data["user"]["id"]
print(f"✅ Logged in as therapist")
print(f"   User ID: {user_id}")

headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}

# Test 1: Get therapist ID
print("\n" + "=" * 60)
print("TEST 1: GET THERAPIST ID")
print("=" * 60)
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/therapists?user_id=eq.{user_id}&select=id",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    therapists = response.json()
    if therapists:
        therapist_id = therapists[0]["id"]
        print(f"✅ Therapist ID: {therapist_id}")
    else:
        print(f"❌ No therapist found for user_id {user_id}")
        print("Database linkage broken!")
else:
    print(f"❌ Failed: {response.text}")

# Test 2: Get patient list
print("\n" + "=" * 60)
print("TEST 2: GET PATIENT LIST")
print("=" * 60)
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/patients?select=*",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    patients = response.json()
    print(f"✅ {len(patients)} patients")
    if patients:
        patient_id = patients[0]["id"]
        print(f"   First patient: {patients[0].get('first_name')} {patients[0].get('last_name')}")
        print(f"   Patient ID: {patient_id}")
    else:
        print("❌ No patients returned - RLS blocking?")
else:
    print(f"❌ Failed: {response.text}")

if not patients:
    print("\n🚨 CRITICAL: No patients returned - RLS policies broken!")
    exit(1)

# Test 3: Get notes
print("\n" + "=" * 60)
print("TEST 3: GET NOTES FOR PATIENT")
print("=" * 60)
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/session_notes?patient_id=eq.{patient_id}&select=*&order=created_at.desc",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    notes = response.json()
    print(f"✅ {len(notes)} notes")
    for note in notes[:3]:
        print(f"   - {note['note_type']}: {note['note_text'][:50]}...")
else:
    print(f"❌ Failed: {response.text}")

# Test 4: Get current program
print("\n" + "=" * 60)
print("TEST 4: GET CURRENT PROGRAM")
print("=" * 60)
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
        program_id = program["id"]
        program_name = program.get('program_name') or program.get('name') or 'Unknown'
        print(f"   Program: {program_name}")
        print(f"   Program ID: {program_id}")
        print(f"   Available fields: {list(program.keys())}")
    else:
        print("❌ No programs returned - RLS blocking?")
else:
    print(f"❌ Failed: {response.text}")

if not programs:
    print("\n🚨 CRITICAL: No programs returned - RLS policies broken!")
    exit(1)

# Test 5: Get phases (checking for session_number column)
print("\n" + "=" * 60)
print("TEST 5: GET PHASES AND SESSIONS (WITH NEW COLUMNS)")
print("=" * 60)
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/phases?program_id=eq.{program_id}&select=*",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    phases = response.json()
    print(f"✅ {len(phases)} phases")
    if phases:
        phase_id = phases[0]["id"]
        phase_name = phases[0].get('phase_name') or phases[0].get('name') or 'Unknown'
        print(f"   First phase: {phase_name}")
        print(f"   Available fields: {list(phases[0].keys())}")

        # Test sessions with session_number column
        print("\n   Testing sessions.session_number column...")
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/sessions?phase_id=eq.{phase_id}&select=id,name,session_number,sequence&order=session_number.asc",
            headers=headers
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            sessions = response.json()
            print(f"   ✅ {len(sessions)} sessions")
            if sessions:
                print(f"   First session: {sessions[0]}")
                session_id = sessions[0]["id"]
            else:
                print("   ❌ No sessions returned")
        else:
            print(f"   ❌ Failed: {response.text}")
            print("   🚨 session_number column missing or query broken!")
    else:
        print("❌ No phases returned")
else:
    print(f"❌ Failed: {response.text}")

# Test 6: Get exercises (checking for exercise_name and prescribed_* columns)
if 'session_id' in locals():
    print("\n" + "=" * 60)
    print("TEST 6: GET EXERCISES (WITH NEW COLUMNS)")
    print("=" * 60)

    query = f"""session_exercises!inner(
        id,
        prescribed_sets,
        prescribed_reps,
        prescribed_load,
        load_unit,
        rest_period_seconds,
        order_index,
        exercise_templates!inner(
            id,
            exercise_name,
            name
        )
    )"""

    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/sessions?id=eq.{session_id}&select={query}",
        headers=headers
    )
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Query succeeded")
        if data and data[0].get('session_exercises'):
            exercises = data[0]['session_exercises']
            print(f"✅ {len(exercises)} exercises")
            print(f"\nFirst exercise:")
            ex = exercises[0]
            print(f"   exercise_name: {ex.get('exercise_templates', {}).get('exercise_name', 'MISSING')}")
            print(f"   prescribed_sets: {ex.get('prescribed_sets', 'MISSING')}")
            print(f"   prescribed_reps: {ex.get('prescribed_reps', 'MISSING')}")
            print(f"   prescribed_load: {ex.get('prescribed_load', 'MISSING')}")
            print(f"   load_unit: {ex.get('load_unit', 'MISSING')}")
            print(f"   rest_period_seconds: {ex.get('rest_period_seconds', 'MISSING')}")
            print(f"   order_index: {ex.get('order_index', 'MISSING')}")
        else:
            print("❌ No exercises returned")
    else:
        print(f"❌ Failed: {response.text}")
        print("🚨 New columns missing or query broken!")

# Test 7: Get prior session information
print("\n" + "=" * 60)
print("TEST 7: GET PRIOR SESSION INFORMATION")
print("=" * 60)
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=*&order=session_date.desc&limit=5",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    sessions = response.json()
    print(f"✅ {len(sessions)} prior sessions")
    for session in sessions:
        print(f"   - {session.get('session_date')}: {session.get('session_name', 'N/A')}")
else:
    print(f"❌ Failed: {response.text}")
    print("🚨 Prior session view broken!")

# Summary
print("\n" + "=" * 60)
print("SUMMARY")
print("=" * 60)
print("Run this script and send me the output.")
print("This will show exactly what's failing on the backend.")
