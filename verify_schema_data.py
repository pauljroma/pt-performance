#!/usr/bin/env python3
"""Verify schema fixes and check data"""

import psycopg2
from psycopg2.extras import RealDictCursor

CONN_STR = "postgresql://postgres.rpbxeaxlaoyoqkohytlw:rcq!vyd6qtb_HCP5mzt@aws-0-us-west-2.pooler.supabase.com:5432/postgres"

def verify_workload_flags():
    """Check workload_flags table and data"""
    print("\n" + "="*70)
    print("  WORKLOAD FLAGS VERIFICATION")
    print("="*70 + "\n")

    conn = psycopg2.connect(CONN_STR)
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # Check schema
    cur.execute("""
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name = 'workload_flags'
        ORDER BY ordinal_position;
    """)

    print("📋 Schema:")
    for row in cur.fetchall():
        nullable = "NULL" if row['is_nullable'] == 'YES' else "NOT NULL"
        default = f" DEFAULT {row['column_default']}" if row['column_default'] else ""
        print(f"  • {row['column_name']}: {row['data_type']} {nullable}{default}")

    # Check data
    cur.execute("""
        SELECT * FROM workload_flags
        ORDER BY created_at DESC
        LIMIT 10;
    """)

    flags = cur.fetchall()
    print(f"\n📊 Data (found {len(flags)} rows):")
    for flag in flags:
        print(f"  • ID: {flag['id']}")
        print(f"    Patient: {flag['patient_id']}")
        print(f"    Type: {flag['flag_type']}")
        print(f"    Severity: {flag.get('severity', 'NULL')}")
        print(f"    Active: {flag['is_active']}")
        print()

    if len(flags) == 0:
        print("  ⚠️  No workload flags found in database!")

    cur.close()
    conn.close()

def verify_programs():
    """Check programs for Nic Roma"""
    print("\n" + "="*70)
    print("  PROGRAMS VERIFICATION")
    print("="*70 + "\n")

    conn = psycopg2.connect(CONN_STR)
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # Check for Nic Roma's program
    nic_roma_id = "00000000-0000-0000-0000-000000000002"

    cur.execute("""
        SELECT id, name, patient_id, target_level, status, phase_number
        FROM programs
        WHERE patient_id = %s;
    """, (nic_roma_id,))

    programs = cur.fetchall()
    print(f"📊 Programs for Nic Roma (patient_id: {nic_roma_id}):")
    print(f"   Found {len(programs)} programs\n")

    for prog in programs:
        print(f"  • Program: {prog['name']}")
        print(f"    ID: {prog['id']}")
        print(f"    Target Level: {prog['target_level']}")
        print(f"    Status: {prog['status']}")
        print(f"    Phase Number: {prog.get('phase_number', 'NULL')}")

        # Check phases
        cur.execute("""
            SELECT id, name, sequence, phase_number, status
            FROM phases
            WHERE program_id = %s
            ORDER BY sequence;
        """, (prog['id'],))

        phases = cur.fetchall()
        print(f"    Phases: {len(phases)}")
        for phase in phases:
            print(f"      - {phase['name']} (seq: {phase['sequence']}, phase_num: {phase['phase_number']}, status: {phase['status']})")
        print()

    if len(programs) == 0:
        print("  ⚠️  No programs found for Nic Roma!")

        # Check all programs
        cur.execute("SELECT id, name, patient_id, target_level FROM programs;")
        all_programs = cur.fetchall()
        print(f"\n  All programs in database ({len(all_programs)}):")
        for p in all_programs:
            print(f"    • {p['name']} (patient: {p['patient_id']}, target: {p['target_level']})")

    cur.close()
    conn.close()

def verify_phases():
    """Check phases table for null values"""
    print("\n" + "="*70)
    print("  PHASES NULL CHECK")
    print("="*70 + "\n")

    conn = psycopg2.connect(CONN_STR)
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # Check for null phase_number
    cur.execute("""
        SELECT COUNT(*) as total,
               COUNT(phase_number) as with_phase_number,
               COUNT(*) - COUNT(phase_number) as null_phase_number
        FROM phases;
    """)

    result = cur.fetchone()
    print(f"📊 Phase Numbers:")
    print(f"  • Total phases: {result['total']}")
    print(f"  • With phase_number: {result['with_phase_number']}")
    print(f"  • NULL phase_number: {result['null_phase_number']}")

    if result['null_phase_number'] > 0:
        print("\n  ⚠️  Found phases with NULL phase_number!")
        cur.execute("""
            SELECT id, name, program_id, sequence, phase_number
            FROM phases
            WHERE phase_number IS NULL
            LIMIT 5;
        """)
        null_phases = cur.fetchall()
        for phase in null_phases:
            print(f"    • {phase['name']} (seq: {phase['sequence']}, phase_num: NULL)")

    cur.close()
    conn.close()

if __name__ == "__main__":
    try:
        verify_workload_flags()
        verify_programs()
        verify_phases()

        print("\n" + "="*70)
        print("  ✅ VERIFICATION COMPLETE")
        print("="*70)

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
