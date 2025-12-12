#!/usr/bin/env python3
"""
Comprehensive Build 14 Testing - Check ALL errors
"""
import requests
import json

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

print("=" * 80)
print("BUILD 14 COMPREHENSIVE ERROR CHECK")
print("=" * 80)

# Login as therapist
print("\n1. TESTING LOGIN...")
auth_response = requests.post(
    f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
    headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
    json={"email": "demo-pt@ptperformance.app", "password": "demo-therapist-2025"}
)

if auth_response.status_code != 200:
    print(f"❌ LOGIN FAILED: {auth_response.status_code}")
    print(auth_response.text)
    exit(1)

auth_data = auth_response.json()
access_token = auth_data["access_token"]
user_id = auth_data["user"]["id"]
print(f"✅ Login successful - User ID: {user_id}")

headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}

# Test 2: Get therapist ID
print("\n2. TESTING THERAPIST LOOKUP...")
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
        print(f"❌ NO THERAPIST FOUND - RLS blocking or linkage broken!")
        print(f"Response: {response.text}")
else:
    print(f"❌ Query failed: {response.text}")

# Test 3: Get patients (this is what iPad sees)
print("\n3. TESTING PATIENT LIST (what iPad sees)...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/patients?select=*",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    patients = response.json()
    print(f"Result: {len(patients)} patients")
    if len(patients) == 0:
        print("❌ NO PATIENTS - RLS IS BLOCKING ACCESS!")
        print("This is why patient list is empty on iPad")
    else:
        patient_id = patients[0]["id"]
        print(f"✅ Patient: {patients[0].get('first_name')} {patients[0].get('last_name')}")
else:
    print(f"❌ Failed: {response.text}")
    exit(1)

if len(patients) == 0:
    print("\n🚨 CRITICAL: Cannot continue - no patients visible due to RLS")
    exit(1)

# Test 4: Create note (exact iOS request)
print("\n4. TESTING NOTE CREATION (exact iOS request)...")
note_data = {
    "patient_id": patient_id,
    "session_id": None,
    "note_type": "general",
    "note_text": f"Test note from Build 14 check",
    "created_by": None  # iOS sends null, should use database default
}
response = requests.post(
    f"{SUPABASE_URL}/rest/v1/session_notes",
    headers=headers,
    json=note_data
)
print(f"Status: {response.status_code}")
if response.status_code in [200, 201]:
    print(f"✅ Note created successfully")
else:
    print(f"❌ Note creation FAILED: {response.text}")
    print("This is why notes fail on iPad")

# Test 5: Get programs
print("\n5. TESTING PROGRAM LOAD...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?patient_id=eq.{patient_id}&select=*",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    programs = response.json()
    print(f"Result: {len(programs)} programs")
    if len(programs) == 0:
        print("❌ NO PROGRAMS - RLS blocking or no data")
    else:
        program_id = programs[0]["id"]
        print(f"✅ Program: {programs[0].get('name')}")
else:
    print(f"❌ Failed: {response.text}")

if len(programs) == 0:
    print("\n🚨 NO PROGRAMS - Cannot test phases/sessions/exercises")
    exit(1)

# Test 6: Get phases
print("\n6. TESTING PHASES...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/phases?program_id=eq.{program_id}&select=*&order=phase_number.asc",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    phases = response.json()
    print(f"Result: {len(phases)} phases")
    if len(phases) == 0:
        print("❌ NO PHASES - RLS blocking or no data")
    else:
        phase_id = phases[0]["id"]
        print(f"✅ Phase: {phases[0].get('name')}")
else:
    print(f"❌ Failed: {response.text}")

if len(phases) == 0:
    print("\n🚨 NO PHASES - Cannot test sessions")
    exit(1)

# Test 7: Get sessions (with session_number column)
print("\n7. TESTING SESSIONS (with session_number column)...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/sessions?phase_id=eq.{phase_id}&select=id,name,session_number&order=session_number.asc",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    sessions = response.json()
    print(f"Result: {len(sessions)} sessions")
    if len(sessions) == 0:
        print("❌ NO SESSIONS")
    else:
        session_id = sessions[0]["id"]
        print(f"✅ Session: {sessions[0].get('name')}")
        print(f"   session_number: {sessions[0].get('session_number')}")
else:
    print(f"❌ Failed: {response.text}")
    if "session_number" in response.text:
        print("🚨 session_number column MISSING or query broken!")

if len(sessions) == 0:
    exit(1)

# Test 8: Get exercises (EXACT iOS query)
print("\n8. TESTING EXERCISES (exact iOS query from ProgramViewModel)...")
query = """id,session_id,exercise_templates!inner(exercise_name),prescribed_sets,prescribed_reps,prescribed_load,load_unit,rest_period_seconds,order_index"""
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/session_exercises?session_id=eq.{session_id}&select={query}&order=order_index.asc",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    exercises = response.json()
    print(f"Result: {len(exercises)} exercises")
    if len(exercises) == 0:
        print("❌ NO EXERCISES")
    else:
        print(f"✅ First exercise structure:")
        print(json.dumps(exercises[0], indent=2))
else:
    print(f"❌ FAILED: {response.text}")
    print("This is why program viewer shows 'data missing'")

# Test 9: Get prior sessions
print("\n9. TESTING PRIOR SESSION INFO...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=*&order=session_date.desc&limit=5",
    headers=headers
)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    prior_sessions = response.json()
    print(f"Result: {len(prior_sessions)} sessions")
    if len(prior_sessions) == 0:
        print("❌ NO PRIOR SESSIONS")
    else:
        print(f"✅ Sessions found")
        for i, s in enumerate(prior_sessions[:3]):
            print(f"   {i+1}. Date: {s.get('session_date', 'NULL')} | Name: {s.get('session_name', 'NULL')}")
else:
    print(f"❌ Failed: {response.text}")

print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)
print("Check errors above to see what's blocking Build 14")
