#!/usr/bin/env python3
"""Test patient login and data access exactly as iOS app does"""
import requests
import json
import sys

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

print("=" * 70)
print("TESTING PATIENT LOGIN AND DATA ACCESS")
print("=" * 70)

# Step 1: Login as patient
print("\n1. Logging in as patient...")
auth_response = requests.post(
    f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
    headers={
        "apikey": ANON_KEY,
        "Content-Type": "application/json"
    },
    json={
        "email": "demo-athlete@ptperformance.app",
        "password": "demo-patient-2025"
    }
)

if auth_response.status_code != 200:
    print(f"❌ Login failed: {auth_response.status_code}")
    print(auth_response.text)
    sys.exit(1)

auth_data = auth_response.json()
access_token = auth_data.get("access_token")
user_id = auth_data.get("user", {}).get("id")

print(f"✅ Login successful!")
print(f"   User ID: {user_id}")
print(f"   Token: {access_token[:20]}...")

# Step 2: Get patient record
print("\n2. Fetching patient record...")
patient_response = requests.get(
    f"{SUPABASE_URL}/rest/v1/patients?user_id=eq.{user_id}",
    headers={
        "apikey": ANON_KEY,
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
)

if patient_response.status_code != 200:
    print(f"❌ Failed to get patient: {patient_response.status_code}")
    print(patient_response.text)
    sys.exit(1)

patients = patient_response.json()
if not patients:
    print("❌ No patient record found!")
    print("   This means user_id is not linked to patients table")
    sys.exit(1)

patient = patients[0]
patient_id = patient["id"]
print(f"✅ Patient record found!")
print(f"   Patient ID: {patient_id}")
print(f"   Name: {patient.get('first_name')} {patient.get('last_name')}")

# Step 3: Get active program
print("\n3. Fetching active program...")
program_response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?patient_id=eq.{patient_id}&status=eq.active",
    headers={
        "apikey": ANON_KEY,
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
)

if program_response.status_code != 200:
    print(f"❌ Failed to get program: {program_response.status_code}")
    print(program_response.text)
    sys.exit(1)

programs = program_response.json()
if not programs:
    print("❌ No active program found!")
    sys.exit(1)

program = programs[0]
program_id = program["id"]
print(f"✅ Active program found!")
print(f"   Program ID: {program_id}")
print(f"   Program: {program.get('name')}")

# Step 4: Get phases
print("\n4. Fetching program phases...")
phases_response = requests.get(
    f"{SUPABASE_URL}/rest/v1/phases?program_id=eq.{program_id}&order=sequence.asc",
    headers={
        "apikey": ANON_KEY,
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
)

if phases_response.status_code != 200:
    print(f"❌ Failed to get phases: {phases_response.status_code}")
    print(phases_response.text)
else:
    phases = phases_response.json()
    print(f"✅ Found {len(phases)} phases")
    for phase in phases:
        print(f"   - {phase.get('name')} (sequence {phase.get('sequence')})")

# Step 5: Get sessions for first phase
if phases:
    phase_id = phases[0]["id"]
    print(f"\n5. Fetching sessions for phase '{phases[0].get('name')}'...")
    sessions_response = requests.get(
        f"{SUPABASE_URL}/rest/v1/sessions?phase_id=eq.{phase_id}",
        headers={
            "apikey": ANON_KEY,
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
    )

    if sessions_response.status_code != 200:
        print(f"❌ Failed to get sessions: {sessions_response.status_code}")
        print(sessions_response.text)
    else:
        sessions = sessions_response.json()
        print(f"✅ Found {len(sessions)} sessions")

        # Get exercises for first session
        if sessions:
            session_id = sessions[0]["id"]
            print(f"\n6. Fetching exercises for session '{sessions[0].get('name')}'...")
            exercises_response = requests.get(
                f"{SUPABASE_URL}/rest/v1/session_exercises?session_id=eq.{session_id}&select=*,exercise_templates(*)",
                headers={
                    "apikey": ANON_KEY,
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json"
                }
            )

            if exercises_response.status_code != 200:
                print(f"❌ Failed to get exercises: {exercises_response.status_code}")
                print(exercises_response.text)
            else:
                exercises = exercises_response.json()
                print(f"✅ Found {len(exercises)} exercises")
                for ex in exercises[:3]:
                    print(f"   - {ex.get('exercise_templates', {}).get('name', 'Unknown')}")

print("\n" + "=" * 70)
print("TEST COMPLETE")
print("=" * 70)
print("\nIf all steps passed ✅, the iOS app should work!")
print("If any failed ❌, that's where the problem is.")
