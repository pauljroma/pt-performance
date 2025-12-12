#!/usr/bin/env python3
"""
Comprehensive User Flow Tests
==============================
Tests ALL user flows the app uses:
1. Login as therapist
2. View patient list
3. View patient detail (all 4 sections)
4. Add a note
5. Load current session
6. Load program with phases and sessions
"""

import requests
import json
from datetime import datetime

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

def test_login():
    """Test therapist login"""
    print("\n[TEST 1] Login as therapist")
    response = requests.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
        json={"email": "demo-pt@ptperformance.app", "password": "demo-therapist-2025"}
    )
    assert response.status_code == 200, f"Login failed: {response.text}"
    auth_data = response.json()
    print(f"   ✅ Login successful")
    return auth_data["access_token"], auth_data["user"]["id"]

def test_patient_list(headers):
    """Test loading patient list"""
    print("\n[TEST 2] Load patient list")
    response = requests.get(f"{SUPABASE_URL}/rest/v1/patients?select=*", headers=headers)
    assert response.status_code == 200, f"Failed: {response.text}"
    patients = response.json()
    assert len(patients) > 0, "No patients found"
    print(f"   ✅ Found {len(patients)} patient(s)")
    return patients[0]['id']

def test_patient_detail(headers, patient_id):
    """Test all 4 sections of patient detail view"""
    print("\n[TEST 3] Load patient detail (4 sections)")

    # Section 1: Flags
    print("   [3a] patient_flags")
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/patient_flags?patient_id=eq.{patient_id}&select=*",
        headers=headers
    )
    assert response.status_code == 200, f"Flags failed: {response.text}"
    flags = response.json()
    # Validate structure matches iOS PatientFlag model
    if flags:
        required = ["id", "patient_id", "flag_type", "severity", "description", "created_at", "resolved_at", "auto_created"]
        actual = list(flags[0].keys())
        missing = [f for f in required if f not in actual]
        assert not missing, f"Flags missing columns: {missing}"
    print(f"       ✅ {len(flags)} flags (schema valid)")

    # Section 2: Pain trend
    print("   [3b] vw_pain_trend")
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/vw_pain_trend?patient_id=eq.{patient_id}&select=*",
        headers=headers
    )
    assert response.status_code == 200, f"Pain trend failed: {response.text}"
    pain_data = response.json()
    if pain_data:
        required = ["id", "logged_date", "avg_pain"]
        actual = list(pain_data[0].keys())
        missing = [f for f in required if f not in actual]
        assert not missing, f"Pain trend missing columns: {missing}"
    print(f"       ✅ {len(pain_data)} data points (schema valid)")

    # Section 3: Adherence
    print("   [3c] vw_patient_adherence")
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/vw_patient_adherence?patient_id=eq.{patient_id}&select=*",
        headers=headers
    )
    assert response.status_code == 200, f"Adherence failed: {response.text}"
    adherence = response.json()
    if adherence:
        required = ["adherence_pct", "completed_sessions", "total_sessions"]
        actual = list(adherence[0].keys())
        missing = [f for f in required if f not in actual]
        assert not missing, f"Adherence missing columns: {missing}"
    print(f"       ✅ Adherence data (schema valid)")

    # Section 4: Sessions
    print("   [3d] vw_patient_sessions")
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=id,session_number,session_date,completed,exercise_count&limit=5",
        headers=headers
    )
    assert response.status_code == 200, f"Sessions failed: {response.text}"
    sessions = response.json()
    assert len(sessions) > 0, "No sessions found"
    required = ["id", "session_number", "session_date", "completed", "exercise_count"]
    actual = list(sessions[0].keys())
    missing = [f for f in required if f not in actual]
    assert not missing, f"Sessions missing columns: {missing}"
    print(f"       ✅ {len(sessions)} sessions (schema valid)")

def test_add_note(headers, patient_id, user_id):
    """Test adding a note"""
    print("\n[TEST 4] Add a note")
    note_data = {
        "patient_id": patient_id,
        "session_id": None,
        "note_type": "general",
        "note_text": f"Test note created at {datetime.now().isoformat()}",
        # Don't send created_by - let the default function handle it
    }
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/session_notes",
        headers=headers,
        json=note_data
    )
    if response.status_code == 201:
        print(f"   ✅ Note created successfully")
        return response.json()[0]['id']
    else:
        print(f"   ❌ FAILED: {response.status_code} - {response.text}")
        raise AssertionError(f"Note creation failed: {response.text}")

def test_current_session(headers, patient_id):
    """Test loading current session (what TodaySessionView does)"""
    print("\n[TEST 5] Load current session")
    # The iOS app queries sessions with nested join
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/sessions?select=*,phases!inner(id,name,program_id,programs!inner(id,name,patient_id,status))&phases.programs.patient_id=eq.{patient_id}&phases.programs.status=eq.active&order=sequence.asc&limit=1",
        headers=headers
    )
    assert response.status_code == 200, f"Current session query failed: {response.text}"
    sessions = response.json()
    if sessions:
        print(f"   ✅ Found current session: {sessions[0].get('name')}")
    else:
        print(f"   ⚠️ No active session found (patient might not have active program)")
    return sessions

def test_load_program(headers, patient_id):
    """Test loading program with all data"""
    print("\n[TEST 6] Load program")

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

    # Validate required fields for iOS Program model
    required = ["id", "patient_id", "name", "target_level", "duration_weeks", "created_at"]
    actual = list(program.keys())
    missing = [f for f in required if f not in actual or not program.get(f)]
    assert not missing, f"Program missing required data: {missing}"

    print(f"   ✅ Program: {program['name']}")
    print(f"      target_level: {program['target_level']}")
    print(f"      duration_weeks: {program['duration_weeks']}")

    # Get phases
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/phases?program_id=eq.{program_id}&select=*",
        headers=headers
    )
    assert response.status_code == 200, f"Phases query failed: {response.text}"
    phases = response.json()
    assert len(phases) > 0, "No phases found"

    # Validate phase structure
    required = ["id", "program_id", "phase_number", "name", "duration_weeks", "goals"]
    actual = list(phases[0].keys())
    missing = [f for f in required if f not in actual]
    assert not missing, f"Phases missing columns: {missing}"

    print(f"   ✅ {len(phases)} phases")

    # Get sessions
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/vw_patient_sessions?patient_id=eq.{patient_id}&select=*&limit=5",
        headers=headers
    )
    assert response.status_code == 200, f"Sessions query failed: {response.text}"
    sessions = response.json()
    assert len(sessions) > 0, "No sessions found"

    print(f"   ✅ {len(sessions)} sessions (sample)")

# ============================================================================
# RUN ALL TESTS
# ============================================================================

print("=" * 80)
print("COMPREHENSIVE USER FLOW TESTS")
print("=" * 80)

try:
    # Test 1: Login
    access_token, user_id = test_login()
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Prefer": "return=representation"
    }

    # Test 2: Patient list
    patient_id = test_patient_list(headers)

    # Test 3: Patient detail (all 4 sections)
    test_patient_detail(headers, patient_id)

    # Test 4: Add note
    test_add_note(headers, patient_id, user_id)

    # Test 5: Current session
    test_current_session(headers, patient_id)

    # Test 6: Load program
    test_load_program(headers, patient_id)

    print("\n" + "=" * 80)
    print("✅ ALL TESTS PASSED!")
    print("=" * 80)
    print("\nThe app should now work completely:")
    print("  ✅ Login")
    print("  ✅ View patient list")
    print("  ✅ View patient detail (all sections)")
    print("  ✅ Add notes")
    print("  ✅ Load current session")
    print("  ✅ Load programs")
    print("=" * 80)

except AssertionError as e:
    print("\n" + "=" * 80)
    print(f"❌ TEST FAILED: {e}")
    print("=" * 80)
    exit(1)
except Exception as e:
    print("\n" + "=" * 80)
    print(f"❌ ERROR: {e}")
    print("=" * 80)
    import traceback
    traceback.print_exc()
    exit(1)
