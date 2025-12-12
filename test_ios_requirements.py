#!/usr/bin/env python3
"""
Comprehensive test suite for iOS app requirements
Tests all database tables, views, and relationships needed by the app
"""

import psycopg2
from datetime import date, datetime, timedelta

conn_str = "postgresql://postgres.rpbxeaxlaoyoqkohytlw:rcq!vyd6qtb_HCP5mzt@aws-0-us-west-2.pooler.supabase.com:5432/postgres"

def print_section(title):
    print("\n" + "="*70)
    print(f"  {title}")
    print("="*70 + "\n")

def test_basic_users():
    """Test 1: Basic auth users and database records"""
    print_section("TEST 1: Basic Users")

    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()

    # Check therapist
    cur.execute("SELECT id, first_name, last_name, email FROM therapists WHERE email = 'demo-pt@ptperformance.app';")
    therapist = cur.fetchone()
    if therapist:
        print(f"✅ Therapist: {therapist[1]} {therapist[2]} ({therapist[3]})")
    else:
        print("❌ Demo therapist not found")
        cur.close()
        conn.close()
        return False

    # Check patient
    cur.execute("SELECT id, first_name, last_name, email FROM patients WHERE email = 'demo-athlete@ptperformance.app';")
    patient = cur.fetchone()
    if patient:
        print(f"✅ Patient: {patient[1]} {patient[2]} ({patient[3]})")
        patient_id = patient[0]
    else:
        print("❌ Demo patient not found")
        cur.close()
        conn.close()
        return False

    cur.close()
    conn.close()
    return True, patient_id

def test_program_data(patient_id):
    """Test 2: Program, phases, and sessions exist"""
    print_section("TEST 2: Program Data")

    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()

    # Check for active program
    cur.execute("""
        SELECT id, name, status, start_date, end_date
        FROM programs
        WHERE patient_id = %s
        ORDER BY created_at DESC
        LIMIT 1;
    """, (patient_id,))
    program = cur.fetchone()

    if not program:
        print(f"❌ No program found for patient {patient_id}")
        cur.close()
        conn.close()
        return False

    print(f"✅ Program: {program[1]} (status: {program[2]})")
    program_id = program[0]

    # Check for phases
    cur.execute("""
        SELECT id, name, sequence
        FROM phases
        WHERE program_id = %s
        ORDER BY sequence;
    """, (program_id,))
    phases = cur.fetchall()

    if not phases:
        print(f"❌ No phases found for program {program_id}")
        cur.close()
        conn.close()
        return False

    print(f"✅ Phases: {len(phases)} found")
    for phase in phases:
        print(f"   Phase {phase[2]}: {phase[1]}")

    # Check for sessions
    phase_ids = [str(p[0]) for p in phases]
    cur.execute("""
        SELECT COUNT(*)
        FROM sessions
        WHERE phase_id::text = ANY(%s::text[]);
    """, (phase_ids,))
    session_count = cur.fetchone()[0]

    if session_count == 0:
        print(f"❌ No sessions found for phases")
        cur.close()
        conn.close()
        return False

    print(f"✅ Sessions: {session_count} found")

    cur.close()
    conn.close()
    return True, program_id, phases

def test_todays_session(patient_id):
    """Test 3: Today's session query (what iOS app needs)"""
    print_section("TEST 3: Today's Session Query")

    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()

    # iOS app needs sessions for today
    # The query chain should be: sessions -> phases -> programs -> patient_id

    # First, check if sessions have a date field
    cur.execute("""
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'sessions'
        AND (column_name LIKE '%date%' OR column_name = 'scheduled_at' OR column_name = 'weekday');
    """)
    date_columns = [row[0] for row in cur.fetchall()]
    print(f"Session date-related columns: {date_columns}")

    # Try to find a session for patient via relationship chain
    cur.execute("""
        SELECT s.id, s.name, ph.name as phase_name, pr.name as program_name
        FROM sessions s
        JOIN phases ph ON s.phase_id = ph.id
        JOIN programs pr ON ph.program_id = pr.id
        WHERE pr.patient_id = %s
        LIMIT 5;
    """, (patient_id,))

    sessions = cur.fetchall()
    if not sessions:
        print(f"❌ No sessions found via relationship chain for patient {patient_id}")
        cur.close()
        conn.close()
        return False

    print(f"✅ Found {len(sessions)} sessions via relationship chain:")
    for session in sessions[:3]:
        print(f"   {session[1]} (Phase: {session[2]}, Program: {session[3]})")

    cur.close()
    conn.close()
    return True

def test_exercise_data():
    """Test 4: Exercise templates and session exercises"""
    print_section("TEST 4: Exercise Data")

    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()

    # Check exercise templates
    cur.execute("SELECT COUNT(*) FROM exercise_templates;")
    template_count = cur.fetchone()[0]

    if template_count == 0:
        print("❌ No exercise templates found")
        cur.close()
        conn.close()
        return False

    print(f"✅ Exercise templates: {template_count} found")

    # Check session exercises
    cur.execute("SELECT COUNT(*) FROM session_exercises;")
    session_ex_count = cur.fetchone()[0]

    if session_ex_count == 0:
        print("⚠️  No session exercises found (sessions not linked to exercises)")
        cur.close()
        conn.close()
        return False

    print(f"✅ Session exercises: {session_ex_count} found")

    cur.close()
    conn.close()
    return True

def test_ios_query_simulation(patient_id):
    """Test 5: Simulate exact iOS app query"""
    print_section("TEST 5: iOS App Query Simulation")

    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()

    # The iOS app query from TodaySessionViewModel.swift line 73-83:
    # This is the BROKEN query - it tries to join sessions directly to programs
    print("Testing BROKEN iOS query (sessions -> programs directly):")
    try:
        cur.execute("""
            SELECT s.id, s.name
            FROM sessions s
            JOIN programs pr ON pr.id = s.phase_id  -- WRONG! should be phases.program_id
            WHERE pr.patient_id = %s
            LIMIT 1;
        """, (patient_id,))
        result = cur.fetchone()
        if result:
            print(f"❌ Query succeeded but shouldn't (foreign key mismatch)")
        else:
            print(f"❌ Query returned no results")
    except Exception as e:
        print(f"❌ Query failed as expected: {str(e)[:100]}")

    print("\nTesting CORRECT query (sessions -> phases -> programs):")
    try:
        cur.execute("""
            SELECT s.id, s.name, ph.name as phase_name, pr.name as program_name
            FROM sessions s
            JOIN phases ph ON ph.id = s.phase_id
            JOIN programs pr ON pr.id = ph.program_id
            WHERE pr.patient_id = %s
            LIMIT 1;
        """, (patient_id,))
        result = cur.fetchone()
        if result:
            print(f"✅ Query succeeded: {result[1]} (Phase: {result[2]}, Program: {result[3]})")
            return True
        else:
            print(f"❌ Query returned no results")
            return False
    except Exception as e:
        print(f"❌ Query failed: {str(e)}")
        return False

    cur.close()
    conn.close()

def main():
    print("\n" + "="*70)
    print("  PT PERFORMANCE iOS APP - DATABASE REQUIREMENTS TEST")
    print("="*70)

    results = []

    # Test 1: Basic users
    result = test_basic_users()
    if not result:
        print("\n❌ CRITICAL: Basic users test failed")
        return
    results.append(("Basic Users", True))
    _, patient_id = result

    # Test 2: Program data
    result = test_program_data(patient_id)
    results.append(("Program Data", result is not False))
    if not result:
        print("\n❌ CRITICAL: Program data test failed - need to seed data")
        print("\nNext action: Create minimal seed data for programs/phases/sessions")
        print_summary(results)
        return

    # Test 3: Today's session
    result = test_todays_session(patient_id)
    results.append(("Today's Session", result))

    # Test 4: Exercise data
    result = test_exercise_data()
    results.append(("Exercise Data", result))

    # Test 5: iOS query simulation
    result = test_ios_query_simulation(patient_id)
    results.append(("iOS Query Simulation", result))

    print_summary(results)

def print_summary(results):
    print("\n" + "="*70)
    print("  TEST SUMMARY")
    print("="*70 + "\n")

    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status}  {test_name}")

    all_passed = all(result for _, result in results)
    print("\n" + "="*70)
    if all_passed:
        print("✅ ALL TESTS PASSED - Ready for iOS Build")
    else:
        print("❌ SOME TESTS FAILED - DO NOT BUILD YET")
    print("="*70 + "\n")

if __name__ == '__main__':
    main()
