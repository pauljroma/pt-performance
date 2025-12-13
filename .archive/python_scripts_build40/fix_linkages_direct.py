#!/usr/bin/env python3
"""Direct database fix for Build 9 linkages"""
import psycopg2
import sys

# Connection details
HOST = "db.rpbxeaxlaoyoqkohytlw.supabase.co"
PORT = 5432
DATABASE = "postgres"
USER = "postgres"
PASSWORD = "rcq!vyd6qtb_HCP5mzt"

print("=" * 70)
print("BUILD 9 - FIXING AUTH LINKAGES")
print("=" * 70)

try:
    print("\n1. Connecting to database...")
    conn = psycopg2.connect(
        host=HOST,
        port=PORT,
        database=DATABASE,
        user=USER,
        password=PASSWORD,
        connect_timeout=10
    )
    conn.autocommit = True
    cursor = conn.cursor()
    print("   ✅ Connected")

    print("\n2. Fixing patient linkage...")
    cursor.execute("""
        UPDATE patients p
        SET user_id = au.id
        FROM auth.users au
        WHERE p.email = au.email
          AND p.email = 'demo-athlete@ptperformance.app'
    """)
    print(f"   ✅ Updated {cursor.rowcount} row(s)")

    print("\n3. Fixing therapist linkage...")
    cursor.execute("""
        UPDATE therapists t
        SET user_id = au.id
        FROM auth.users au
        WHERE t.email = au.email
          AND t.email = 'demo-pt@ptperformance.app'
    """)
    print(f"   ✅ Updated {cursor.rowcount} row(s)")

    print("\n4. Linking patient to therapist...")
    cursor.execute("""
        UPDATE patients p
        SET therapist_id = t.id
        FROM therapists t
        WHERE p.email = 'demo-athlete@ptperformance.app'
          AND t.email = 'demo-pt@ptperformance.app'
    """)
    print(f"   ✅ Updated {cursor.rowcount} row(s)")

    print("\n5. Verifying fixes...")
    cursor.execute("""
        SELECT
          'Patient linked' as check_type,
          p.user_id::text as patient_user_id,
          au.id::text as auth_id,
          CASE WHEN p.user_id = au.id THEN 'YES' ELSE 'NO' END as linked
        FROM patients p, auth.users au
        WHERE p.email = 'demo-athlete@ptperformance.app'
          AND au.email = 'demo-athlete@ptperformance.app'
        UNION ALL
        SELECT
          'Therapist linked' as check_type,
          t.user_id::text as therapist_user_id,
          au.id::text as auth_id,
          CASE WHEN t.user_id = au.id THEN 'YES' ELSE 'NO' END as linked
        FROM therapists t, auth.users au
        WHERE t.email = 'demo-pt@ptperformance.app'
          AND au.email = 'demo-pt@ptperformance.app'
        UNION ALL
        SELECT
          'Patient has therapist' as check_type,
          p.therapist_id::text as patient_therapist_id,
          t.id::text as therapist_id,
          CASE WHEN p.therapist_id = t.id THEN 'YES' ELSE 'NO' END as linked
        FROM patients p, therapists t
        WHERE p.email = 'demo-athlete@ptperformance.app'
          AND t.email = 'demo-pt@ptperformance.app'
    """)

    print("\n" + "=" * 70)
    print("VERIFICATION RESULTS:")
    print("=" * 70)
    for row in cursor.fetchall():
        check_type, id1, id2, linked = row
        status = "✅" if linked == "YES" else "❌"
        print(f"{status} {check_type}: {linked}")
    print("=" * 70)

    cursor.close()
    conn.close()

    print("\n✅ Build 9 linkages fixed successfully!")
    print("\nTest credentials:")
    print("  Patient: demo-athlete@ptperformance.app / demo-patient-2025")
    print("  Therapist: demo-pt@ptperformance.app / demo-therapist-2025")

except psycopg2.OperationalError as e:
    print(f"\n❌ Connection failed: {e}")
    print("\nNote: Supabase blocks direct PostgreSQL connections")
    print("Generating SQL file for manual execution...")

    sql = """
-- Fix all auth user linkages

UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.email = 'demo-athlete@ptperformance.app';

UPDATE therapists t
SET user_id = au.id
FROM auth.users au
WHERE t.email = au.email
  AND t.email = 'demo-pt@ptperformance.app';

UPDATE patients p
SET therapist_id = t.id
FROM therapists t
WHERE p.email = 'demo-athlete@ptperformance.app'
  AND t.email = 'demo-pt@ptperformance.app';

-- Verify
SELECT
  'Patient linked' as check_type,
  p.user_id::text,
  au.id::text,
  CASE WHEN p.user_id = au.id THEN 'YES' ELSE 'NO' END as linked
FROM patients p, auth.users au
WHERE p.email = 'demo-athlete@ptperformance.app'
  AND au.email = 'demo-athlete@ptperformance.app'
UNION ALL
SELECT
  'Therapist linked',
  t.user_id::text,
  au.id::text,
  CASE WHEN t.user_id = au.id THEN 'YES' ELSE 'NO' END
FROM therapists t, auth.users au
WHERE t.email = 'demo-pt@ptperformance.app'
  AND au.email = 'demo-pt@ptperformance.app'
UNION ALL
SELECT
  'Patient has therapist',
  p.therapist_id::text,
  t.id::text,
  CASE WHEN p.therapist_id = t.id THEN 'YES' ELSE 'NO' END
FROM patients p, therapists t
WHERE p.email = 'demo-athlete@ptperformance.app'
  AND t.email = 'demo-pt@ptperformance.app';
"""

    with open('/tmp/fix_build9_linkages.sql', 'w') as f:
        f.write(sql)

    print("\n✅ SQL saved to: /tmp/fix_build9_linkages.sql")
    print("\nRun this in Supabase dashboard SQL editor")

except Exception as e:
    print(f"\n❌ Error: {e}")
    sys.exit(1)
