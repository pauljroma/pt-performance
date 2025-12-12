#!/usr/bin/env python3
"""Minimal program/phase/session seed for John Brebbia"""

import psycopg2
from datetime import date, timedelta

conn_str = "postgresql://postgres.rpbxeaxlaoyoqkohytlw:rcq!vyd6qtb_HCP5mzt@aws-0-us-west-2.pooler.supabase.com:5432/postgres"

conn = psycopg2.connect(conn_str)
cur = conn.cursor()

print("="*70)
print("  SEEDING MINIMAL PROGRAM DATA")
print("="*70 + "\n")

patient_id = '00000000-0000-0000-0000-000000000001'
program_id = '00000000-0000-0000-0000-000000000200'
phase1_id = '00000000-0000-0000-0000-000000000301'
phase2_id = '00000000-0000-0000-0000-000000000302'

# Calculate dates (start today, run for 4 weeks)
today = date.today()
end_date = today + timedelta(weeks=4)

# 1. Create Program
print("1️⃣  Creating program...")
cur.execute("""
    INSERT INTO programs (id, patient_id, name, description, start_date, end_date, status, created_at)
    VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        status = EXCLUDED.status;
""", (
    program_id,
    patient_id,
    '4-Week Return to Throw',
    'Progressive return-to-throw program for post-tricep strain rehabilitation',
    today,
    end_date,
    'active'
))
print(f"   ✅ Program created: 4-Week Return to Throw")
print(f"      Start: {today}, End: {end_date}")

# 2. Create Phase 1 (Weeks 1-2)
print("\n2️⃣  Creating Phase 1...")
phase1_end = today + timedelta(weeks=2)
cur.execute("""
    INSERT INTO phases (id, program_id, name, sequence, start_date, end_date, notes, created_at)
    VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date;
""", (
    phase1_id,
    program_id,
    'Foundation',
    1,
    today,
    phase1_end,
    'Build base strength and mobility. No throwing yet.'
))
print(f"   ✅ Phase 1: Foundation ({today} to {phase1_end})")

# 3. Create Phase 2 (Weeks 3-4)
print("\n3️⃣  Creating Phase 2...")
phase2_start = phase1_end + timedelta(days=1)
cur.execute("""
    INSERT INTO phases (id, program_id, name, sequence, start_date, end_date, notes, created_at)
    VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date;
""", (
    phase2_id,
    program_id,
    'Light Throwing',
    2,
    phase2_start,
    end_date,
    'Introduce light throwing at 30-50% intensity'
))
print(f"   ✅ Phase 2: Light Throwing ({phase2_start} to {end_date})")

# 4. Create Sessions (3 per week for phase 1 = 6 sessions)
print("\n4️⃣  Creating sessions for Phase 1...")
sessions_created = 0

# Week 1: Mon, Wed, Fri
week1_dates = [
    today,  # Today
    today + timedelta(days=2),  # +2 days
    today + timedelta(days=4),  # +4 days
]

# Week 2: Mon, Wed, Fri
week2_dates = [
    today + timedelta(days=7),   # +7 days
    today + timedelta(days=9),   # +9 days
    today + timedelta(days=11),  # +11 days
]

all_session_dates = week1_dates + week2_dates

for i, session_date in enumerate(all_session_dates, 1):
    session_id = f'00000000-0000-0000-0000-0000000004{i:02d}'
    weekday = session_date.weekday()  # 0=Monday, 6=Sunday

    cur.execute("""
        INSERT INTO sessions (id, phase_id, name, sequence, weekday, created_at)
        VALUES (%s, %s, %s, %s, %s, NOW())
        ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            sequence = EXCLUDED.sequence,
            weekday = EXCLUDED.weekday;
    """, (
        session_id,
        phase1_id,
        f'Session {i}: Foundation Training',
        i,
        weekday
    ))
    sessions_created += 1

    # Show today's session specially
    if session_date == today:
        print(f"   ✅ TODAY's Session: {i} (weekday={weekday})")
    else:
        days_from_now = (session_date - today).days
        print(f"   ✅ Session {i}: +{days_from_now} days (weekday={weekday})")

print(f"\n   Total: {sessions_created} sessions created")

# 5. Create some basic exercise templates
print("\n5️⃣  Creating exercise templates...")
exercises = [
    ('00000000-0000-0000-0000-000000000501', 'Band Pull-Apart', 'Upper Body', 'Shoulder', 'Resistance Band', 'Bodyweight', None),
    ('00000000-0000-0000-0000-000000000502', 'Scapular Wall Slides', 'Upper Body', 'Shoulder', 'None', 'Bodyweight', None),
    ('00000000-0000-0000-0000-000000000503', 'Prone Y Raises', 'Upper Body', 'Shoulder', 'None', 'Bodyweight', None),
    ('00000000-0000-0000-0000-000000000504', 'External Rotation', 'Upper Body', 'Rotator Cuff', 'Dumbbell', 'Weight', '10RM'),
    ('00000000-0000-0000-0000-000000000505', 'Plank', 'Core', 'Core', 'None', 'Time', None),
]

for ex_id, name, category, body_region, equipment, load_type, rm_method in exercises:
    cur.execute("""
        INSERT INTO exercise_templates (id, name, category, body_region, equipment, load_type, rm_method, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())
        ON CONFLICT (id) DO NOTHING;
    """, (ex_id, name, category, body_region, equipment, load_type, rm_method))

print(f"   ✅ {len(exercises)} exercise templates created")

# 6. Link exercises to today's session
print("\n6️⃣  Linking exercises to today's session...")
session_today_id = '00000000-0000-0000-0000-000000000401'

session_exercises = [
    (session_today_id, '00000000-0000-0000-0000-000000000501', 1, 3, 15, 'Focus on squeezing shoulder blades'),
    (session_today_id, '00000000-0000-0000-0000-000000000502', 2, 3, 10, 'Maintain wall contact'),
    (session_today_id, '00000000-0000-0000-0000-000000000503', 3, 3, 12, 'Keep core engaged'),
    (session_today_id, '00000000-0000-0000-0000-000000000504', 4, 3, 10, '5lb dumbbells'),
    (session_today_id, '00000000-0000-0000-0000-000000000505', 5, 3, 30, '30 seconds per set'),
]

for session_id, template_id, order, sets, reps, notes in session_exercises:
    cur.execute("""
        INSERT INTO session_exercises (id, session_id, exercise_template_id, sequence, target_sets, target_reps, notes, created_at)
        VALUES (gen_random_uuid(), %s, %s, %s, %s, %s, %s, NOW())
        ON CONFLICT DO NOTHING;
    """, (session_id, template_id, order, sets, reps, notes))

print(f"   ✅ {len(session_exercises)} exercises linked to today's session")

conn.commit()

# Verify
print("\n" + "="*70)
print("  VERIFICATION")
print("="*70)

cur.execute("SELECT id, name, status FROM programs WHERE patient_id = %s;", (patient_id,))
programs = cur.fetchall()
print(f"\n✅ Programs: {len(programs)}")
for p in programs:
    print(f"   {p[1]} (status: {p[2]})")

cur.execute("SELECT COUNT(*) FROM phases WHERE program_id = %s;", (program_id,))
phase_count = cur.fetchone()[0]
print(f"\n✅ Phases: {phase_count}")

cur.execute("""
    SELECT COUNT(*)
    FROM sessions s
    JOIN phases ph ON s.phase_id = ph.id
    WHERE ph.program_id = %s;
""", (program_id,))
session_count = cur.fetchone()[0]
print(f"✅ Sessions: {session_count}")

cur.execute("SELECT COUNT(*) FROM exercise_templates;")
template_count = cur.fetchone()[0]
print(f"✅ Exercise Templates: {template_count}")

cur.execute("SELECT COUNT(*) FROM session_exercises WHERE session_id = %s;", (session_today_id,))
ex_count = cur.fetchone()[0]
print(f"✅ Today's Session Exercises: {ex_count}")

print("\n" + "="*70)
print("✅ MINIMAL SEED DATA COMPLETE")
print("="*70 + "\n")

cur.close()
conn.close()
