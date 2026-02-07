-- Comprehensive Demo Patient Seed Data for E2E Testing
-- Patient ID: 00000000-0000-0000-0000-000000000001

-- ============================================================================
-- 1. STREAK RECORDS (7-day active streak)
-- ============================================================================

INSERT INTO streak_records (id, patient_id, streak_type, current_streak, longest_streak, last_activity_date, created_at)
VALUES
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, 'workout', 7, 14, CURRENT_DATE, NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, 'arm_care', 5, 10, CURRENT_DATE, NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, 'combined', 7, 14, CURRENT_DATE, NOW())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 1b. STREAK HISTORY (daily activity for last 7 days)
-- ============================================================================

INSERT INTO streak_history (id, patient_id, activity_date, workout_completed, arm_care_completed, notes, created_at)
VALUES
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '6 days', true, true, 'Full training day', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '5 days', true, false, 'Leg day - no throwing', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '4 days', true, true, 'Upper body + arm care', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '3 days', false, true, 'Recovery - arm care only', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '2 days', true, true, 'Back to full training', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '1 day', true, true, 'Great session', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, true, false, 'Today - morning workout done', NOW())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 2. RECENT READINESS CHECK-INS (last 7 days)
-- ============================================================================

INSERT INTO daily_readiness (id, patient_id, date, sleep_hours, soreness_level, energy_level, stress_level, readiness_score, notes, created_at)
VALUES
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '6 days', 7.5, 3, 7, 4, 78.5, 'Feeling good after rest day', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '5 days', 6.5, 5, 6, 5, 65.0, 'Legs sore from squats', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '4 days', 8.0, 4, 8, 3, 82.0, 'Great sleep, ready to train', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '3 days', 7.0, 4, 7, 4, 75.0, 'Normal day', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '2 days', 6.0, 6, 5, 6, 58.0, 'Rough night, taking it easy', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '1 day', 7.5, 3, 8, 3, 80.0, 'Back on track', NOW())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 3. ARM CARE ASSESSMENTS (last 5 days for pitcher)
-- Scores are 0-10, higher is better. Trigger computes shoulder_score, elbow_score, overall_score, and traffic_light
-- ============================================================================

INSERT INTO arm_care_assessments (
    id, patient_id, date,
    shoulder_pain_score, shoulder_stiffness_score, shoulder_strength_score,
    elbow_pain_score, elbow_tightness_score, valgus_stress_score,
    shoulder_score, elbow_score, overall_score, traffic_light,
    notes, created_at
)
VALUES
    -- 4 days ago: Great day (all 9s, green)
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '4 days',
     9, 8, 9, 9, 8, 9,
     8.67, 8.67, 8.67, 'green',
     'Full ROM, no issues', NOW()),
    -- 3 days ago: Slight tightness (6-7 range, yellow)
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '3 days',
     7, 6, 7, 7, 6, 7,
     6.67, 6.67, 6.67, 'yellow',
     'Slight tightness in posterior shoulder', NOW()),
    -- 2 days ago: Recovered (8s, green)
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '2 days',
     8, 8, 9, 9, 8, 8,
     8.33, 8.33, 8.33, 'green',
     'Recovered well', NOW()),
    -- Yesterday: Feeling great (9-10, green)
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '1 day',
     10, 9, 9, 10, 9, 9,
     9.33, 9.33, 9.33, 'green',
     'Feeling great', NOW())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. BODY COMPOSITION MEASUREMENTS (monthly for last 3 months)
-- Note: Demo patient already has Brebbia data. Adding more recent measurements.
-- ============================================================================

INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, lean_mass_lb)
VALUES
    ('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '60 days', 220.0, 16.2, 107.0),
    ('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '30 days', 218.5, 15.5, 107.5),
    ('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE - INTERVAL '7 days', 217.0, 14.8, 108.0)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 5. MANUAL SESSIONS (completed workouts for history)
-- ============================================================================

-- Insert manual sessions for the last 7 days
INSERT INTO manual_sessions (id, patient_id, name, started_at, completed_at, completed, duration_minutes, notes, created_at)
VALUES
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, 'Morning Arm Care',
     (CURRENT_DATE - INTERVAL '6 days' + TIME '08:00:00')::timestamptz,
     (CURRENT_DATE - INTERVAL '6 days' + TIME '08:25:00')::timestamptz,
     true, 25, 'Pre-throwing routine', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, 'Lower Body Strength',
     (CURRENT_DATE - INTERVAL '5 days' + TIME '10:00:00')::timestamptz,
     (CURRENT_DATE - INTERVAL '5 days' + TIME '11:15:00')::timestamptz,
     true, 75, 'Heavy squat day', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, 'Upper Body Push',
     (CURRENT_DATE - INTERVAL '4 days' + TIME '09:30:00')::timestamptz,
     (CURRENT_DATE - INTERVAL '4 days' + TIME '10:30:00')::timestamptz,
     true, 60, 'Bench and shoulders', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, 'Recovery Session',
     (CURRENT_DATE - INTERVAL '3 days' + TIME '16:00:00')::timestamptz,
     (CURRENT_DATE - INTERVAL '3 days' + TIME '16:45:00')::timestamptz,
     true, 45, 'Mobility and stretching', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, 'Upper Body Pull',
     (CURRENT_DATE - INTERVAL '2 days' + TIME '10:00:00')::timestamptz,
     (CURRENT_DATE - INTERVAL '2 days' + TIME '11:00:00')::timestamptz,
     true, 60, 'Rows and pullups', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, 'Conditioning',
     (CURRENT_DATE - INTERVAL '1 day' + TIME '07:00:00')::timestamptz,
     (CURRENT_DATE - INTERVAL '1 day' + TIME '07:30:00')::timestamptz,
     true, 30, 'Sprint intervals', NOW())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. PATIENT GOALS
-- ============================================================================

INSERT INTO patient_goals (id, patient_id, title, description, category, target_value, current_value, unit, target_date, status, created_at)
VALUES
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid,
     'Return to Mound',
     'Complete full bullpen sessions without pain or compensation',
     'rehabilitation', 100, 65, 'percent',
     CURRENT_DATE + INTERVAL '60 days',
     'active', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid,
     'Hit 300lb Squat',
     'Work up to 300lb back squat for 5 reps',
     'strength', 300, 245, 'lbs',
     CURRENT_DATE + INTERVAL '90 days',
     'active', NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid,
     'Improve Shoulder Mobility',
     'Achieve 100 degrees external rotation consistently',
     'mobility', 100, 96, 'degrees',
     CURRENT_DATE + INTERVAL '30 days',
     'active', NOW())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 7. NOTIFICATION SETTINGS (ensure demo patient has good defaults)
-- ============================================================================

INSERT INTO notification_settings (id, patient_id, smart_timing_enabled, fallback_reminder_time, reminder_minutes_before, streak_alerts_enabled, weekly_summary_enabled, quiet_hours_start, quiet_hours_end)
VALUES
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001'::uuid, true, '08:00', 30, true, true, '22:00', '07:00')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 8. Force schema reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
