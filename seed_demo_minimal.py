#!/usr/bin/env python3
"""Minimal seed data for demo users"""

import psycopg2

conn_str = "postgresql://postgres.rpbxeaxlaoyoqkohytlw:rcq!vyd6qtb_HCP5mzt@aws-0-us-west-2.pooler.supabase.com:5432/postgres"

conn = psycopg2.connect(conn_str)
cur = conn.cursor()

print("🌱 Seeding minimal demo data...\n")

# 1. Demo Therapist
print("1️⃣  Creating demo therapist...")
cur.execute("""
    INSERT INTO therapists (id, first_name, last_name, email, created_at)
    VALUES (
        '00000000-0000-0000-0000-000000000100'::uuid,
        'Sarah',
        'Thompson',
        'demo-pt@ptperformance.app',
        NOW()
    )
    ON CONFLICT (email) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name;
""")
print("   ✅ Sarah Thompson created")

# 2. Demo Patient
print("2️⃣  Creating demo patient...")
cur.execute("""
    INSERT INTO patients (
        id,
        therapist_id,
        first_name,
        last_name,
        email,
        date_of_birth,
        sport,
        position,
        created_at
    )
    VALUES (
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        'John',
        'Brebbia',
        'demo-athlete@ptperformance.app',
        '1990-05-27'::date,
        'Baseball',
        'Pitcher',
        NOW()
    )
    ON CONFLICT (email) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        therapist_id = EXCLUDED.therapist_id;
""")
print("   ✅ John Brebbia created")

conn.commit()

# Verify
print("\n📊 Verification:")
cur.execute("SELECT first_name, last_name, email FROM therapists;")
for row in cur.fetchall():
    print(f"   Therapist: {row[0]} {row[1]} ({row[2]})")

cur.execute("SELECT first_name, last_name, email FROM patients;")
for row in cur.fetchall():
    print(f"   Patient: {row[0]} {row[1]} ({row[2]})")

print("\n✅ Minimal seed data complete!")

cur.close()
conn.close()
