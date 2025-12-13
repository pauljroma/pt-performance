#!/usr/bin/env python3
"""
Diagnose Remaining Errors
==========================
1. Save note - "therapist-user-id error invalid input type"
2. Front page - "unable to load current session"
3. Load program - "data missing"
"""

import requests
import json

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"
SUPABASE_SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

print("=" * 80)
print("DIAGNOSING REMAINING ERRORS")
print("=" * 80)

# Login as therapist
print("\n1. Logging in as therapist...")
login_url = f"{SUPABASE_URL}/auth/v1/token?grant_type=password"
response = requests.post(login_url,
    headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
    json={"email": "demo-pt@ptperformance.app", "password": "demo-therapist-2025"})

if response.status_code != 200:
    print(f"❌ Login failed")
    exit(1)

auth_data = response.json()
access_token = auth_data["access_token"]
user_id = auth_data["user"]["id"]
headers = {"apikey": SUPABASE_ANON_KEY, "Authorization": f"Bearer {access_token}"}
service_headers = {"apikey": SUPABASE_SERVICE_KEY, "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}"}

print(f"   ✅ Login successful!")
print(f"   User ID: {user_id}")
print(f"   User ID type: {type(user_id)} (should be string UUID)")

# Get patient and therapist IDs
response = requests.get(f"{SUPABASE_URL}/rest/v1/patients?select=id&limit=1", headers=headers)
patient_id = response.json()[0]['id']

response = requests.get(f"{SUPABASE_URL}/rest/v1/therapists?email=eq.demo-pt@ptperformance.app&select=id", headers=headers)
therapist_id = response.json()[0]['id']

print(f"   Patient ID: {patient_id}")
print(f"   Therapist ID: {therapist_id}")

# ============================================================================
# ERROR 1: Save note - "therapist-user-id error invalid input type"
# ============================================================================
print("\n" + "=" * 80)
print("ERROR 1: SAVE NOTE")
print("=" * 80)

# Check session_notes table schema
print("\nChecking session_notes schema...")
response = requests.get(f"{SUPABASE_URL}/rest/v1/session_notes?limit=0", headers=service_headers)
print(f"   Status: {response.status_code}")

# Try to insert a note with the therapist user_id (UUID)
print(f"\nTrying to insert note with created_by = user_id (UUID)...")
note_data = {
    "patient_id": patient_id,
    "session_id": None,
    "note_type": "general",
    "note_text": "Test note",
    "created_by": user_id  # This is a UUID string
}

response = requests.post(
    f"{SUPABASE_URL}/rest/v1/session_notes",
    headers=headers,
    json=note_data
)

print(f"   Status: {response.status_code}")
if response.status_code != 201:
    print(f"   ❌ FAILED: {response.text}")
    print(f"\n   The error suggests created_by column expects different type than UUID")

    # Check what type created_by column actually is
    print(f"\n   Checking column type in database...")
    # We can't easily check this via REST API, but the error will tell us

else:
    print(f"   ✅ Note inserted successfully")

# ============================================================================
# ERROR 2: Front page - "unable to load current session"
# ============================================================================
print("\n" + "=" * 80)
print("ERROR 2: CURRENT SESSION")
print("=" * 80)

print("\nTrying to load current/today's session...")

# The app probably queries session_status or sessions for today's date
# Let me try different queries that might be "current session"

# Query 1: session_status for today
print("\n   Query 1: session_status for today")
url = f"{SUPABASE_URL}/rest/v1/session_status?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"   Records: {len(data)}")
    if data:
        print(f"   Columns: {list(data[0].keys())}")
else:
    print(f"   Error: {response.text[:200]}")

# Query 2: Check if there's a vw_current_session or vw_today_session view
print("\n   Query 2: Checking for today/current session views")
for view_name in ["vw_current_session", "vw_today_session", "vw_patient_today"]:
    url = f"{SUPABASE_URL}/rest/v1/{view_name}?limit=1"
    response = requests.get(url, headers=service_headers)
    if response.status_code == 200:
        print(f"   ✅ Found view: {view_name}")
    else:
        print(f"   ❌ No view: {view_name}")

# ============================================================================
# ERROR 3: Load program - "data missing"
# ============================================================================
print("\n" + "=" * 80)
print("ERROR 3: LOAD PROGRAM")
print("=" * 80)

print("\nTrying to load program with all related data...")

# Get program
print("\n   Query 1: programs for patient")
url = f"{SUPABASE_URL}/rest/v1/programs?patient_id=eq.{patient_id}&select=*"
response = requests.get(url, headers=headers)
print(f"   Status: {response.status_code}")
if response.status_code == 200:
    programs = response.json()
    print(f"   Programs: {len(programs)}")
    if programs:
        program = programs[0]
        program_id = program['id']
        print(f"   Program: {program.get('name')}")
        print(f"   Columns: {list(program.keys())}")

        # Check for missing data
        required_for_display = ['target_level', 'duration_weeks']
        missing = [f for f in required_for_display if not program.get(f)]
        if missing:
            print(f"   ⚠️ Missing data: {missing}")

        # Query 2: phases for this program
        print(f"\n   Query 2: phases for program {program_id}")
        url = f"{SUPABASE_URL}/rest/v1/phases?program_id=eq.{program_id}&select=*"
        response = requests.get(url, headers=headers)
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            phases = response.json()
            print(f"   Phases: {len(phases)}")
            if phases:
                print(f"   Sample phase columns: {list(phases[0].keys())}")
        else:
            print(f"   ❌ Error: {response.text[:200]}")

        # Query 3: sessions for phases
        print(f"\n   Query 3: sessions for program phases")
        url = f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=*&limit=1"
        response = requests.get(url, headers=headers)
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            sessions = response.json()
            print(f"   Sessions available: {len(sessions)}")
            if sessions:
                print(f"   Sample session columns: {list(sessions[0].keys())}")
        else:
            print(f"   ❌ Error: {response.text[:200]}")
    else:
        print(f"   ❌ No programs found for patient!")
else:
    print(f"   ❌ Error: {response.text[:200]}")

print("\n" + "=" * 80)
print("DIAGNOSIS COMPLETE")
print("=" * 80)
