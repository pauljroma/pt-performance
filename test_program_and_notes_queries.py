#!/usr/bin/env python3
"""
Test Program and Notes Queries (Exact iOS Queries)
===================================================
Tests the EXACT queries from ProgramViewModel and NotesService.
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

print("=" * 80)
print("TESTING PROGRAM AND NOTES QUERIES")
print("=" * 80)

# Login
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
# TEST NOTES QUERY (Line 14-19 of NotesService.swift)
# ============================================================================
print("\n2. Testing notes query...")
print("   Query: .from('session_notes').select().eq('patient_id', '{patient_id}').order('created_at', desc)")

response = requests.get(
    f"{SUPABASE_URL}/rest/v1/session_notes?patient_id=eq.{patient_id}&select=*&order=created_at.desc",
    headers=headers
)

print(f"   Status: {response.status_code}")
if response.status_code == 200:
    notes = response.json()
    print(f"   ✅ Query works - {len(notes)} notes")

    # Try to decode as SessionNote model
    if notes:
        required = ["id", "patient_id", "session_id", "note_type", "note_text", "created_by", "created_at"]
        actual = list(notes[0].keys())
        missing = [f for f in required if f not in actual]
        if missing:
            print(f"   ❌ Missing fields for SessionNote model: {missing}")
            print(f"   Available: {actual}")
        else:
            print(f"   ✅ Schema matches SessionNote model")
else:
    print(f"   ❌ FAILED: {response.text}")

# ============================================================================
# TEST PROGRAM QUERY (Line 29-39 of ProgramViewModel.swift)
# ============================================================================
print("\n3. Testing program query...")
print("   Query: .from('programs').select().eq('patient_id', '{patient_id}').single()")

response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?patient_id=eq.{patient_id}&select=*",
    headers={**headers, "Accept": "application/vnd.pgrst.object+json"}  # single() uses this header
)

print(f"   Status: {response.status_code}")
if response.status_code == 200:
    program = response.json() if isinstance(response.json(), dict) else response.json()[0]
    program_id = program['id']
    print(f"   ✅ Program: {program.get('name')}")

    # Validate required fields
    required = ["id", "patient_id", "name", "target_level", "duration_weeks", "created_at"]
    actual = list(program.keys())
    missing = [f for f in required if f not in actual or not program.get(f)]
    if missing:
        print(f"   ❌ Missing required fields: {missing}")
        print(f"      This causes 'data missing' error!")
    else:
        print(f"   ✅ All required fields present")

    # ============================================================================
    # TEST PHASES QUERY (Line 46-53)
    # ============================================================================
    print("\n4. Testing phases query...")
    print("   Query: .from('phases').select().eq('program_id', '{program_id}').order('phase_number', asc)")

    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/phases?program_id=eq.{program_id}&select=*&order=phase_number.asc",
        headers=headers
    )

    print(f"   Status: {response.status_code}")
    if response.status_code == 200:
        phases = response.json()
        print(f"   ✅ {len(phases)} phases found")

        if phases:
            phase = phases[0]

            # ============================================================================
            # TEST SESSIONS QUERY (Line 57-62) - THIS IS WHERE IT FAILS!
            # ============================================================================
            print("\n5. Testing sessions query...")
            print("   Query: .from('sessions').select().eq('phase_id', '{phase_id}').order('session_number', asc)")
            print("   ⚠️  NOTE: 'session_number' column doesn't exist in sessions table!")

            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/sessions?phase_id=eq.{phase['id']}&select=*&order=session_number.asc",
                headers=headers
            )

            print(f"   Status: {response.status_code}")
            if response.status_code == 200:
                sessions = response.json()
                print(f"   ✅ {len(sessions)} sessions")
            else:
                print(f"   ❌ FAILED: {response.text}")
                print(f"   ROOT CAUSE: sessions table has 'sequence', not 'session_number'!")

                # Try with correct column
                print("\n   Trying with 'sequence' instead...")
                response2 = requests.get(
                    f"{SUPABASE_URL}/rest/v1/sessions?phase_id=eq.{phase['id']}&select=*&order=sequence.asc",
                    headers=headers
                )
                if response2.status_code == 200:
                    sessions = response2.json()
                    print(f"   ✅ Works with 'sequence': {len(sessions)} sessions")

                    if sessions:
                        # Test session_exercises query
                        session = sessions[0]
                        print("\n6. Testing session_exercises query...")
                        print(f"   Query: .from('session_exercises').select(...with join...).eq('session_id', '{session['id']}')")

                        response3 = requests.get(
                            f"{SUPABASE_URL}/rest/v1/session_exercises?session_id=eq.{session['id']}&select=id,session_id,exercise_templates!inner(exercise_name),prescribed_sets,prescribed_reps,prescribed_load,load_unit,rest_period_seconds,order_index&order=order_index.asc",
                            headers=headers
                        )

                        print(f"   Status: {response3.status_code}")
                        if response3.status_code == 200:
                            exercises = response3.json()
                            print(f"   ✅ {len(exercises)} exercises")
                        else:
                            print(f"   ❌ FAILED: {response3.text[:200]}")
    else:
        print(f"   ❌ FAILED: {response.text}")
else:
    print(f"   ❌ FAILED: {response.text}")

print("\n" + "=" * 80)
print("DIAGNOSIS")
print("=" * 80)
print("\nThe iOS app queries 'session_number' but sessions table has 'sequence'.")
print("This causes the program viewer to fail!")
print("=" * 80)
