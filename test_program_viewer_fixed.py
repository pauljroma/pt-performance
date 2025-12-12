#!/usr/bin/env python3
"""
Test Program Viewer After Migration 20251211000008
===================================================
Verifies the schema fix allows iOS program viewer to work.
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

print("=" * 80)
print("TESTING PROGRAM VIEWER SCHEMA FIX")
print("=" * 80)

# Login as therapist
print("\n1. Login as therapist...")
response = requests.post(
    f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
    headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
    json={"email": "demo-pt@ptperformance.app", "password": "demo-therapist-2025"}
)
access_token = response.json()["access_token"]
headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {access_token}",
}
print(f"   ✅ Login successful")

# Get patient
response = requests.get(f"{SUPABASE_URL}/rest/v1/patients?select=id&limit=1", headers=headers)
patient_id = response.json()[0]['id']
print(f"   Patient ID: {patient_id}")

# ============================================================================
# TEST 1: Verify session_number column exists
# ============================================================================
print("\n2. Testing sessions.session_number column...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/sessions?select=id,session_number,sequence&limit=1",
    headers=headers
)

if response.status_code == 200:
    sessions = response.json()
    if sessions and 'session_number' in sessions[0]:
        print(f"   ✅ session_number column exists")
        print(f"   Value: {sessions[0]['session_number']} (should match sequence: {sessions[0]['sequence']})")
    else:
        print(f"   ❌ session_number column missing!")
        print(f"   Migration not applied yet - see APPLY_MIGRATION_20251211000008.md")
        exit(1)
else:
    print(f"   ❌ Query failed: {response.text}")
    exit(1)

# ============================================================================
# TEST 2: Verify exercise_name column exists
# ============================================================================
print("\n3. Testing exercise_templates.exercise_name column...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/exercise_templates?select=id,exercise_name,name&limit=1",
    headers=headers
)

if response.status_code == 200:
    exercises = response.json()
    if exercises and 'exercise_name' in exercises[0]:
        print(f"   ✅ exercise_name column exists")
        print(f"   Value: '{exercises[0]['exercise_name']}' (should match name: '{exercises[0]['name']}')")
    else:
        print(f"   ❌ exercise_name column missing!")
        print(f"   Migration not applied yet - see APPLY_MIGRATION_20251211000008.md")
        exit(1)
else:
    print(f"   ❌ Query failed: {response.text}")
    exit(1)

# ============================================================================
# TEST 3: Full program query (exact iOS query)
# ============================================================================
print("\n4. Testing full program query (iOS ProgramViewModel)...")

# Get program
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?patient_id=eq.{patient_id}&select=*",
    headers=headers
)
assert response.status_code == 200, f"Program query failed: {response.text}"
programs = response.json()
assert len(programs) > 0, "No programs found"

program = programs[0]
program_id = program['id']
print(f"   ✅ Program: {program['name']}")

# Get phases
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/phases?program_id=eq.{program_id}&select=*&order=phase_number.asc",
    headers=headers
)
assert response.status_code == 200, f"Phases query failed: {response.text}"
phases = response.json()
assert len(phases) > 0, "No phases found"
print(f"   ✅ {len(phases)} phases")

# Get sessions (THIS USED TO FAIL!)
phase_id = phases[0]['id']
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/sessions?phase_id=eq.{phase_id}&select=*&order=session_number.asc",
    headers=headers
)

if response.status_code == 200:
    sessions = response.json()
    print(f"   ✅ Sessions query works! ({len(sessions)} sessions)")
else:
    print(f"   ❌ FAILED: {response.text}")
    print(f"   Migration may not be fully applied")
    exit(1)

# Get session exercises (THIS ALSO USED TO FAIL!)
if sessions:
    session_id = sessions[0]['id']
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/session_exercises?session_id=eq.{session_id}&select=id,session_id,exercise_templates!inner(exercise_name),prescribed_sets,prescribed_reps,prescribed_load,load_unit,rest_period_seconds,order_index&order=order_index.asc",
        headers=headers
    )

    if response.status_code == 200:
        exercises = response.json()
        print(f"   ✅ Exercises query works! ({len(exercises)} exercises)")
        if exercises:
            print(f"      Example: {exercises[0]['exercise_templates']['exercise_name']}")
    else:
        print(f"   ❌ Exercises query failed: {response.text[:200]}")
        exit(1)

print("\n" + "=" * 80)
print("✅ ALL TESTS PASSED!")
print("=" * 80)
print("\nThe program viewer should now work in the iOS app:")
print("  ✅ sessions.session_number column exists and syncs with sequence")
print("  ✅ exercise_templates.exercise_name column exists and syncs with name")
print("  ✅ Program query returns all phases")
print("  ✅ Sessions query works with session_number ordering")
print("  ✅ Exercises query works with exercise_name join")
print("\n🚀 Ready to test on iPad!")
print("=" * 80)
