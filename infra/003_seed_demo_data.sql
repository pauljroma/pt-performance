-- 003_seed_demo_data.sql
-- Demo data for PT Performance Platform MVP
-- Zone-7 (Data Access), Zone-8 (Data Ingestion)
-- Agent 3 - Phase 1: Data Layer
--
-- Seeds:
-- 1. Demo therapist (Sarah Thompson)
-- 2. Demo patient (John Brebbia - pitcher)
-- 3. 8-Week On-Ramp Program (4 phases, 24 sessions)
-- 4. Sample exercise logs and pain logs
--
-- Run after: 001_init_supabase.sql, 002_epic_enhancements.sql

-- ============================================================================
-- 1. DEMO THERAPIST
-- ============================================================================

INSERT INTO therapists (id, first_name, last_name, email, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000100'::uuid,
  'Sarah',
  'Thompson',
  'demo-pt@ptperformance.app',
  '2025-01-01 08:00:00'::timestamptz
)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- 2. DEMO PATIENT (John Brebbia - Pitcher)
-- ============================================================================

INSERT INTO patients (
  id,
  therapist_id,
  first_name,
  last_name,
  email,
  date_of_birth,
  sport,
  position,
  dominant_hand,
  height_in,
  weight_lb,
  medical_history,
  medications,
  goals,
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
  'Pitcher (Right-handed)',
  'Right',
  73,
  195,
  '{
    "injuries": [
      {
        "year": 2025,
        "body_region": "elbow",
        "diagnosis": "Grade 1 tricep strain",
        "notes": "Minor strain during spring training, conservative rehab protocol"
      }
    ],
    "surgeries": [],
    "chronic_conditions": []
  }'::jsonb,
  '{
    "current": [],
    "allergies": []
  }'::jsonb,
  'Return to full throwing capacity by June 2025. Regain 94-96 mph fastball velocity. Improve shoulder stability and reduce injury risk.',
  '2025-01-01 08:30:00'::timestamptz
)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- 3. 8-WEEK ON-RAMP PROGRAM
-- ============================================================================

INSERT INTO programs (
  id,
  patient_id,
  name,
  description,
  start_date,
  end_date,
  status,
  metadata,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000200'::uuid,
  '00000000-0000-0000-0000-000000000001'::uuid,
  '8-Week On-Ramp',
  'Progressive return-to-throw program for post-tricep strain rehabilitation. Builds strength, mobility, and throwing capacity over 8 weeks.',
  '2025-02-01'::date,
  '2025-03-28'::date,
  'active',
  '{
    "target_level": "Professional",
    "role": "Reliever",
    "return_to_throw_target_date": "2025-03-15",
    "full_intensity_target_date": "2025-04-01"
  }'::jsonb,
  '2025-01-28 10:00:00'::timestamptz
)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. PROGRAM PHASES (4 phases, 2 weeks each)
-- ============================================================================

-- Phase 1: Foundation (Weeks 1-2)
INSERT INTO phases (
  id,
  program_id,
  name,
  sequence,
  start_date,
  end_date,
  duration_weeks,
  goals,
  constraints,
  notes,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000301'::uuid,
  '00000000-0000-0000-0000-000000000200'::uuid,
  'Foundation',
  1,
  '2025-02-01'::date,
  '2025-02-14'::date,
  2,
  'Build base strength, mobility, and tissue capacity. No throwing.',
  '{
    "no_overhead_until_week": 3,
    "max_intensity_pct": 60,
    "restrictions": ["no throwing", "no overhead pressing"]
  }'::jsonb,
  'Focus on movement quality and pain-free range of motion.',
  '2025-01-28 10:05:00'::timestamptz
)
ON CONFLICT DO NOTHING;

-- Phase 2: Build (Weeks 3-4)
INSERT INTO phases (
  id,
  program_id,
  name,
  sequence,
  start_date,
  end_date,
  duration_weeks,
  goals,
  constraints,
  notes,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000302'::uuid,
  '00000000-0000-0000-0000-000000000200'::uuid,
  'Build',
  2,
  '2025-02-15'::date,
  '2025-02-28'::date,
  2,
  'Increase load tolerance. Introduce light plyometric drills.',
  '{
    "max_intensity_pct": 75,
    "restrictions": ["no high-velocity throwing"]
  }'::jsonb,
  'Begin plyo progression with light medicine balls.',
  '2025-01-28 10:06:00'::timestamptz
)
ON CONFLICT DO NOTHING;

-- Phase 3: Intensify (Weeks 5-6)
INSERT INTO phases (
  id,
  program_id,
  name,
  sequence,
  start_date,
  end_date,
  duration_weeks,
  goals,
  constraints,
  notes,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000303'::uuid,
  '00000000-0000-0000-0000-000000000200'::uuid,
  'Intensify',
  3,
  '2025-03-01'::date,
  '2025-03-14'::date,
  2,
  'Progressive throwing volume. Target 70-80% max velocity.',
  '{
    "max_intensity_pct": 85,
    "restrictions": []
  }'::jsonb,
  'Begin structured bullpen sessions with velocity tracking.',
  '2025-01-28 10:07:00'::timestamptz
)
ON CONFLICT DO NOTHING;

-- Phase 4: Return to Performance (Weeks 7-8)
INSERT INTO phases (
  id,
  program_id,
  name,
  sequence,
  start_date,
  end_date,
  duration_weeks,
  goals,
  constraints,
  notes,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000304'::uuid,
  '00000000-0000-0000-0000-000000000200'::uuid,
  'Return to Performance',
  4,
  '2025-03-15'::date,
  '2025-03-28'::date,
  2,
  'Full velocity throwing. Simulate game conditions.',
  '{
    "max_intensity_pct": 100,
    "restrictions": []
  }'::jsonb,
  'Final preparation for return to competition.',
  '2025-01-28 10:08:00'::timestamptz
)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 5. SESSIONS (3 per week = 24 total)
-- ============================================================================

-- Phase 1, Week 1 (Sessions 1-3)
INSERT INTO sessions (id, phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes, created_at) VALUES
  ('00000000-0000-0000-0000-000000000401'::uuid, '00000000-0000-0000-0000-000000000301'::uuid, 'Week 1 - Session 1', 1, 1, 4, false, 'Introduction to program. Movement assessment.', '2025-01-28 10:10:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000402'::uuid, '00000000-0000-0000-0000-000000000301'::uuid, 'Week 1 - Session 2', 2, 3, 5, false, 'Build strength foundation.', '2025-01-28 10:11:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000403'::uuid, '00000000-0000-0000-0000-000000000301'::uuid, 'Week 1 - Session 3', 3, 5, 5, false, 'Mobility and activation work.', '2025-01-28 10:12:00'::timestamptz),

-- Phase 1, Week 2 (Sessions 4-6)
  ('00000000-0000-0000-0000-000000000404'::uuid, '00000000-0000-0000-0000-000000000301'::uuid, 'Week 2 - Session 1', 4, 1, 5, false, 'Increase volume slightly.', '2025-01-28 10:13:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000405'::uuid, '00000000-0000-0000-0000-000000000301'::uuid, 'Week 2 - Session 2', 5, 3, 6, false, 'Progressive overload.', '2025-01-28 10:14:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000406'::uuid, '00000000-0000-0000-0000-000000000301'::uuid, 'Week 2 - Session 3', 6, 5, 5, false, 'Recovery and mobility.', '2025-01-28 10:15:00'::timestamptz),

-- Phase 2, Week 3 (Sessions 7-9)
  ('00000000-0000-0000-0000-000000000407'::uuid, '00000000-0000-0000-0000-000000000302'::uuid, 'Week 3 - Session 1', 7, 1, 6, false, 'Introduce plyo drills.', '2025-01-28 10:16:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000408'::uuid, '00000000-0000-0000-0000-000000000302'::uuid, 'Week 3 - Session 2', 8, 3, 6, false, 'Strength + plyo combo.', '2025-01-28 10:17:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000409'::uuid, '00000000-0000-0000-0000-000000000302'::uuid, 'Week 3 - Session 3', 9, 5, 5, false, 'Active recovery.', '2025-01-28 10:18:00'::timestamptz),

-- Phase 2, Week 4 (Sessions 10-12)
  ('00000000-0000-0000-0000-000000000410'::uuid, '00000000-0000-0000-0000-000000000302'::uuid, 'Week 4 - Session 1', 10, 1, 7, false, 'Increase plyo intensity.', '2025-01-28 10:19:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000411'::uuid, '00000000-0000-0000-0000-000000000302'::uuid, 'Week 4 - Session 2', 11, 3, 7, false, 'Peak volume for phase 2.', '2025-01-28 10:20:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000412'::uuid, '00000000-0000-0000-0000-000000000302'::uuid, 'Week 4 - Session 3', 12, 5, 5, false, 'Deload week prep.', '2025-01-28 10:21:00'::timestamptz),

-- Phase 3, Week 5 (Sessions 13-15)
  ('00000000-0000-0000-0000-000000000413'::uuid, '00000000-0000-0000-0000-000000000303'::uuid, 'Week 5 - Session 1', 13, 1, 6, true, 'First structured throwing session.', '2025-01-28 10:22:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000414'::uuid, '00000000-0000-0000-0000-000000000303'::uuid, 'Week 5 - Session 2', 14, 3, 7, true, 'Throwing + strength.', '2025-01-28 10:23:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000415'::uuid, '00000000-0000-0000-0000-000000000303'::uuid, 'Week 5 - Session 3', 15, 5, 6, false, 'Recovery day.', '2025-01-28 10:24:00'::timestamptz),

-- Phase 3, Week 6 (Sessions 16-18)
  ('00000000-0000-0000-0000-000000000416'::uuid, '00000000-0000-0000-0000-000000000303'::uuid, 'Week 6 - Session 1', 16, 1, 7, true, 'Increase throwing volume.', '2025-01-28 10:25:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000417'::uuid, '00000000-0000-0000-0000-000000000303'::uuid, 'Week 6 - Session 2', 17, 3, 8, true, 'Peak throwing intensity.', '2025-01-28 10:26:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000418'::uuid, '00000000-0000-0000-0000-000000000303'::uuid, 'Week 6 - Session 3', 18, 5, 5, false, 'Light recovery.', '2025-01-28 10:27:00'::timestamptz),

-- Phase 4, Week 7 (Sessions 19-21)
  ('00000000-0000-0000-0000-000000000419'::uuid, '00000000-0000-0000-0000-000000000304'::uuid, 'Week 7 - Session 1', 19, 1, 8, true, 'Full velocity throwing.', '2025-01-28 10:28:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000420'::uuid, '00000000-0000-0000-0000-000000000304'::uuid, 'Week 7 - Session 2', 20, 3, 9, true, 'Simulated game conditions.', '2025-01-28 10:29:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000421'::uuid, '00000000-0000-0000-0000-000000000304'::uuid, 'Week 7 - Session 3', 21, 5, 6, false, 'Maintenance work.', '2025-01-28 10:30:00'::timestamptz),

-- Phase 4, Week 8 (Sessions 22-24)
  ('00000000-0000-0000-0000-000000000422'::uuid, '00000000-0000-0000-0000-000000000304'::uuid, 'Week 8 - Session 1', 22, 1, 8, true, 'Competition preparation.', '2025-01-28 10:31:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000423'::uuid, '00000000-0000-0000-0000-000000000304'::uuid, 'Week 8 - Session 2', 23, 3, 9, true, 'Final assessment bullpen.', '2025-01-28 10:32:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000424'::uuid, '00000000-0000-0000-0000-000000000304'::uuid, 'Week 8 - Session 3', 24, 5, 5, false, 'Program completion review.', '2025-01-28 10:33:00'::timestamptz)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. SAMPLE EXERCISE LOGS (for Week 1, Session 1)
-- ============================================================================

-- Note: session_exercise_id references will be added after exercise library is seeded
-- This section will be populated in a follow-up script after exercises are created

-- ============================================================================
-- 7. SAMPLE PAIN LOGS
-- ============================================================================

-- Week 1 - Low pain, good adaptation
INSERT INTO pain_logs (patient_id, session_id, logged_at, pain_rest, pain_during, pain_after, notes)
VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000401'::uuid, '2025-02-03 15:00:00'::timestamptz, 1, 2, 2, 'Slight soreness, normal for day 1'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000402'::uuid, '2025-02-05 15:30:00'::timestamptz, 1, 2, 3, 'Good session, manageable DOMS'),
  ('00000000-0000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000403'::uuid, '2025-02-07 15:15:00'::timestamptz, 2, 2, 2, 'Feeling stronger')
ON CONFLICT DO NOTHING;

-- Week 2 - Continued adaptation
INSERT INTO pain_logs (patient_id, session_id, logged_at, pain_rest, pain_during, pain_after, notes)
VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000404'::uuid, '2025-02-10 15:00:00'::timestamptz, 1, 2, 2, 'Body adapting well'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000405'::uuid, '2025-02-12 15:30:00'::timestamptz, 1, 3, 3, 'Higher volume, slight fatigue'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000406'::uuid, '2025-02-14 15:15:00'::timestamptz, 1, 1, 1, 'Recovery session, feeling good')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 8. SAMPLE BODY COMPOSITION DATA
-- ============================================================================

INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-02-01'::date, 195.0, 12.5, 'Baseline measurement'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-02-15'::date, 196.5, 12.3, 'Gaining lean mass'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-01'::date, 197.0, 12.0, 'Continued progress')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 9. SESSION STATUS TRACKING
-- ============================================================================

-- Mark first 6 sessions as completed (Week 1-2)
INSERT INTO session_status (patient_id, session_id, scheduled_date, status, completed_at, notes)
VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000401'::uuid, '2025-02-03'::date, 'completed', '2025-02-03 15:30:00'::timestamptz, 'Great start'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000402'::uuid, '2025-02-05'::date, 'completed', '2025-02-05 16:00:00'::timestamptz, 'Solid work'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000403'::uuid, '2025-02-07'::date, 'completed', '2025-02-07 15:45:00'::timestamptz, 'Excellent mobility'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000404'::uuid, '2025-02-10'::date, 'completed', '2025-02-10 15:30:00'::timestamptz, 'Strong session'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000405'::uuid, '2025-02-12'::date, 'completed', '2025-02-12 16:00:00'::timestamptz, 'High volume tolerated well'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000406'::uuid, '2025-02-14'::date, 'completed', '2025-02-14 15:30:00'::timestamptz, 'Good recovery')
ON CONFLICT DO NOTHING;

-- Schedule remaining sessions
INSERT INTO session_status (patient_id, session_id, scheduled_date, status)
SELECT
  '00000000-0000-0000-0000-000000000001'::uuid,
  s.id,
  '2025-02-15'::date + (s.sequence - 7) * interval '2 days',
  'scheduled'
FROM sessions s
WHERE s.sequence > 6
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 10. THERAPIST NOTES
-- ============================================================================

INSERT INTO session_notes (patient_id, session_id, author_type, content, created_at)
VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000401'::uuid, 'therapist', 'John showed excellent movement quality. ROM is good. No pain during assessment. Ready to progress.', '2025-02-03 15:35:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000403'::uuid, 'therapist', 'Mobility is improving. Scapular control looking better. Patient is motivated and compliant.', '2025-02-07 15:50:00'::timestamptz),
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000405'::uuid, 'therapist', 'Increased volume well-tolerated. Some fatigue expected. Recommend extra recovery work at home.', '2025-02-12 16:05:00'::timestamptz)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VALIDATION QUERIES (for testing)
-- ============================================================================

-- Count check
-- SELECT 'Therapists' as entity, count(*) from therapists
-- UNION ALL
-- SELECT 'Patients', count(*) from patients
-- UNION ALL
-- SELECT 'Programs', count(*) from programs
-- UNION ALL
-- SELECT 'Phases', count(*) from phases
-- UNION ALL
-- SELECT 'Sessions', count(*) from sessions
-- UNION ALL
-- SELECT 'Pain Logs', count(*) from pain_logs
-- UNION ALL
-- SELECT 'Body Comp', count(*) from body_comp_measurements
-- UNION ALL
-- SELECT 'Session Status', count(*) from session_status
-- UNION ALL
-- SELECT 'Session Notes', count(*) from session_notes;
