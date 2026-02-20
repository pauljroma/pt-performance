-- ============================================================================
-- SEED E2E EXPANSION DATA
-- ============================================================================
-- Date: 2026-02-21
-- Purpose: Add test data for expanded E2E test coverage:
--   1. Lightweight workout session for Jordan Williams (testFinishWorkoutShowsSummary)
--   2. Today's sessions for Tyler, Olivia, Alyssa, Deshawn
--   3. SOAP note records for therapist tests (Sarah Thompson)
--   4. Workout history for Jordan Williams (strength dashboard)
--   5. Today's nutrition for Marcus Rivera
--   6. Pain logs for Marcus Rivera (recovery trend)
--
-- ALL inserts use ON CONFLICT DO NOTHING for idempotency (CLAUDE.md requirement).
-- Uses CURRENT_DATE so sessions are always "today" regardless of when migration runs.
-- ============================================================================


-- ============================================================================
-- SECTION 1: LIGHTWEIGHT WORKOUT SESSION FOR JORDAN WILLIAMS
-- ============================================================================
-- Creates a new session with only 2 exercises x 2 sets each.
-- This fixes testFinishWorkoutShowsSummary by keeping the workout short.
-- Session ID: dddddddd-0000-0000-0501-000000000099

-- Disable audit triggers to allow bulk inserts without user_id issues
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_sessions_trigger') THEN
        ALTER TABLE sessions DISABLE TRIGGER USER;
    END IF;
END $$;

-- Lightweight session under Jordan's Phase 1 (Rebuild)
INSERT INTO sessions (id, phase_id, name, sequence, notes)
VALUES (
    'dddddddd-0000-0000-0501-000000000099'::uuid,
    'cccccccc-0000-0000-0005-000000000001'::uuid,  -- Jordan Phase 1: Rebuild
    'Quick Strength Check',
    99,
    'Lightweight session: 2 exercises x 2 sets for fast completion (E2E test)'
)
ON CONFLICT (id) DO NOTHING;

-- Add 2 exercises to the lightweight session (looked up by name)
DO $$
DECLARE
    v_goblet_id uuid;
    v_plank_id uuid;
BEGIN
    SELECT id INTO v_goblet_id FROM exercise_templates WHERE name = 'Goblet Squat' LIMIT 1;
    SELECT id INTO v_plank_id FROM exercise_templates WHERE name = 'Plank' LIMIT 1;
    IF v_plank_id IS NULL THEN
        SELECT id INTO v_plank_id FROM exercise_templates WHERE name = 'Front Plank' LIMIT 1;
    END IF;

    -- Exercise 1: Goblet Squat (2 sets x 8 reps)
    IF v_goblet_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0501-000000000099'::uuid, v_goblet_id, 1, 2, '8', 30, 'lbs', 60, 'Light goblet squat for quick completion')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Exercise 2: Plank (2 sets x 20 seconds)
    IF v_plank_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0501-000000000099'::uuid, v_plank_id, 2, 2, '20 seconds', 0, 'lbs', 30, 'Core hold for quick completion')
        ON CONFLICT DO NOTHING;
    END IF;

    RAISE NOTICE 'Lightweight session exercises seeded for Jordan Williams';
END $$;

-- Schedule the lightweight session for Jordan today
-- First clean up any stale non-scheduled rows for today
DELETE FROM scheduled_sessions
WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid
  AND session_id = 'dddddddd-0000-0000-0501-000000000099'::uuid
  AND scheduled_date = CURRENT_DATE
  AND status != 'scheduled';

INSERT INTO scheduled_sessions (
    id, patient_id, session_id, scheduled_date, scheduled_time,
    status, notes, created_at, updated_at
) VALUES (
    'eeeeeeee-0000-0000-0000-000000000099'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid,
    'dddddddd-0000-0000-0501-000000000099'::uuid,
    CURRENT_DATE,
    '10:00:00'::time,
    'scheduled',
    'Lightweight session for E2E testFinishWorkoutShowsSummary',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Ensure the lightweight session is NOT marked as completed
UPDATE sessions
SET completed = false,
    completed_at = NULL,
    started_at = NULL,
    total_volume = NULL,
    avg_rpe = NULL,
    avg_pain = NULL,
    duration_minutes = NULL
WHERE id = 'dddddddd-0000-0000-0501-000000000099'::uuid
  AND completed = true;

-- Remove any daily readiness entry for Jordan today so check-in prompt shows
DELETE FROM daily_readiness
WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid
  AND date = CURRENT_DATE;


-- ============================================================================
-- SECTION 2: TODAY'S SESSIONS FOR TYLER, OLIVIA, ALYSSA, DESHAWN
-- ============================================================================
-- Each patient gets one session with 3 exercises, scheduled for CURRENT_DATE.
-- References existing sessions from the comprehensive seed.

-- Clean up stale non-scheduled rows for these patients today
DELETE FROM scheduled_sessions
WHERE patient_id IN (
    'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,  -- Tyler Brooks
    'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid,  -- Olivia Martinez
    'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,  -- Alyssa Chen
    'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid   -- Deshawn Patterson
)
AND scheduled_date = CURRENT_DATE
AND status != 'scheduled';

-- Tyler Brooks - Lower Strength A (Phase 1, Session 1)
-- Already has exercises: Squat, RDL, Lunges
INSERT INTO scheduled_sessions (
    id, patient_id, session_id, scheduled_date, scheduled_time,
    status, notes, created_at, updated_at
) VALUES (
    'eeeeeeee-0000-0000-0000-000000000003'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,
    'dddddddd-0000-0000-0301-000000000001'::uuid,
    CURRENT_DATE,
    '14:00:00'::time,
    'scheduled',
    'Daily performance session - Lower Strength A (E2E test seed)',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Olivia Martinez - Movement 101 A (Phase 1, Session 1)
-- Already has exercises: Goblet Squat, RDL, Front Plank
INSERT INTO scheduled_sessions (
    id, patient_id, session_id, scheduled_date, scheduled_time,
    status, notes, created_at, updated_at
) VALUES (
    'eeeeeeee-0000-0000-0000-000000000008'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid,
    'dddddddd-0000-0000-0801-000000000001'::uuid,
    CURRENT_DATE,
    '15:00:00'::time,
    'scheduled',
    'Daily strength session - Movement 101 A (E2E test seed)',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Alyssa Chen - Knee Rehab A (Phase 1, Session 1)
-- Already has exercises: Goblet Squat, RDL, Front Plank
INSERT INTO scheduled_sessions (
    id, patient_id, session_id, scheduled_date, scheduled_time,
    status, notes, created_at, updated_at
) VALUES (
    'eeeeeeee-0000-0000-0000-000000000002'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,
    'dddddddd-0000-0000-0201-000000000001'::uuid,
    CURRENT_DATE,
    '11:00:00'::time,
    'scheduled',
    'Daily rehab session - Knee Rehab A (E2E test seed)',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Deshawn Patterson - Rehab Session A (Phase 1, Session 1)
-- Already has exercises: Goblet Squat, Front Plank, Band Pull-Apart
INSERT INTO scheduled_sessions (
    id, patient_id, session_id, scheduled_date, scheduled_time,
    status, notes, created_at, updated_at
) VALUES (
    'eeeeeeee-0000-0000-0000-000000000007'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid,
    'dddddddd-0000-0000-0701-000000000001'::uuid,
    CURRENT_DATE,
    '08:00:00'::time,
    'scheduled',
    'Daily performance session - Rehab Session A (E2E test seed)',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Ensure these sessions are NOT marked completed (reset if previous test run)
UPDATE sessions
SET completed = false,
    completed_at = NULL,
    started_at = NULL,
    total_volume = NULL,
    avg_rpe = NULL,
    avg_pain = NULL,
    duration_minutes = NULL
WHERE id IN (
    'dddddddd-0000-0000-0301-000000000001'::uuid,  -- Tyler: Lower Strength A
    'dddddddd-0000-0000-0801-000000000001'::uuid,  -- Olivia: Movement 101 A
    'dddddddd-0000-0000-0201-000000000001'::uuid,  -- Alyssa: Knee Rehab A
    'dddddddd-0000-0000-0701-000000000001'::uuid   -- Deshawn: Rehab Session A
)
AND completed = true;

-- Remove daily readiness for these patients today so check-in prompt shows
DELETE FROM daily_readiness
WHERE patient_id IN (
    'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid
)
AND date = CURRENT_DATE;


-- ============================================================================
-- SECTION 3: SOAP NOTE RECORDS FOR THERAPIST TESTS
-- ============================================================================
-- Sarah Thompson (therapist_id: 00000000-0000-0000-0000-000000000100) writes
-- notes for Marcus, Alyssa, and Tyler.

-- SOAP Note 1: Marcus Rivera - Labrum rehab progress
INSERT INTO soap_notes (
    id, patient_id, therapist_id, session_id, note_date,
    subjective, objective, assessment, plan,
    pain_level, functional_status, time_spent_minutes, cpt_codes,
    status, signed_at, created_at, updated_at
) VALUES (
    'ffff0000-0000-0000-0000-000000000001'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'dddddddd-0000-0000-0101-000000000001'::uuid,  -- Shoulder Mobility A
    CURRENT_DATE - 3,
    'Patient reports decreased shoulder pain at rest (1/10). Still feels mild pulling sensation at end-range external rotation. Sleeping better - only wakes once at night from shoulder discomfort. Able to perform daily activities with minimal limitations. Throwing light catch at 50% effort with no sharp pain.',
    'Active shoulder flexion 165 degrees (was 150 two weeks ago). External rotation 78 degrees (was 65). Internal rotation 55 degrees. Scapular stability improved - able to hold Y-raise for 20 seconds. Rotator cuff strength 4/5 on manual muscle testing. No clicking or catching during ROM testing. Mild tenderness over posterior capsule on palpation.',
    'Marcus is progressing well through Phase 1 of labrum rehab. ROM gains are on track with expected timeline. Scapular stabilizer strength is improving but still below baseline. Pain levels are consistently decreasing, which is encouraging. The ability to tolerate light throwing is a positive sign for return-to-sport progression.',
    'Continue Phase 2 strengthening program 3x/week. Progress external rotation exercises to 3 lb weight. Add light plyometric ball tosses at 60% effort. Begin integration of overhead patterns with band resistance. Reassess ROM and strength in 2 weeks. Target: full clearance for throwing program by week 10.',
    1,
    'improving',
    45,
    '["97110", "97530", "97140"]'::jsonb,
    'signed',
    (CURRENT_DATE - 3)::timestamptz + INTERVAL '16 hours',
    (CURRENT_DATE - 3)::timestamptz + INTERVAL '15 hours',
    (CURRENT_DATE - 3)::timestamptz + INTERVAL '16 hours'
)
ON CONFLICT (id) DO NOTHING;

-- SOAP Note 2: Alyssa Chen - ACL return to sport progress
INSERT INTO soap_notes (
    id, patient_id, therapist_id, session_id, note_date,
    subjective, objective, assessment, plan,
    pain_level, functional_status, time_spent_minutes, cpt_codes,
    status, signed_at, created_at, updated_at
) VALUES (
    'ffff0000-0000-0000-0000-000000000002'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'dddddddd-0000-0000-0201-000000000001'::uuid,  -- Knee Rehab A
    CURRENT_DATE - 5,
    'Patient reports feeling strong and confident with straight-line activities. Notices mild swelling after high-volume quad work that resolves within 24 hours. No episodes of instability or giving way. Eager to begin lateral movement drills. Has been compliant with home exercise program and ice protocol.',
    'Knee ROM: 0 to 138 degrees (symmetrical with contralateral). Quad circumference 0.5 cm less than uninvolved side (was 1.5 cm at initial eval). Single leg press: 85% of uninvolved side. Y-balance test anterior reach 92% of contralateral. KT-1000 laxity test: 2mm side-to-side difference (within normal). No effusion noted. VMO activation strong with palpation during quad sets.',
    'Alyssa is progressing ahead of typical ACL rehab timeline, consistent with her elite athletic background and exceptional compliance. Quad strength deficit is narrowing rapidly. Balance and proprioception are approaching symmetry. She is psychologically ready for sport-specific progressions, which is important for successful return to basketball.',
    'Advance to Phase 2: Sport-Specific. Begin lateral shuffles and crossover steps at controlled speeds. Introduce jump-landing mechanics with emphasis on knee valgus prevention. Continue progressive quad strengthening with loaded single-leg work. Add basketball-specific footwork drills without contact. Reassess with hop testing battery in 3 weeks.',
    1,
    'improving',
    50,
    '["97110", "97530", "97542"]'::jsonb,
    'signed',
    (CURRENT_DATE - 5)::timestamptz + INTERVAL '14 hours',
    (CURRENT_DATE - 5)::timestamptz + INTERVAL '13 hours',
    (CURRENT_DATE - 5)::timestamptz + INTERVAL '14 hours'
)
ON CONFLICT (id) DO NOTHING;

-- SOAP Note 3: Tyler Brooks - Performance training check-in
INSERT INTO soap_notes (
    id, patient_id, therapist_id, session_id, note_date,
    subjective, objective, assessment, plan,
    pain_level, functional_status, time_spent_minutes, cpt_codes,
    status, created_at, updated_at
) VALUES (
    'ffff0000-0000-0000-0000-000000000003'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'dddddddd-0000-0000-0301-000000000001'::uuid,  -- Lower Strength A
    CURRENT_DATE - 1,
    'Patient reports feeling strong in the weight room. Left hamstring occasionally feels tight during max-effort sprints but no pain. Sleep has been inconsistent (5-6 hours on school nights). Energy levels fluctuate but high on training days. Motivated by upcoming combine timing.',
    'Squat 1RM estimated at 285 lbs based on 3-rep max of 265 lbs. Vertical jump 31 inches (up from 29 at baseline). Pro agility shuttle 4.35 seconds. Hamstring flexibility: straight leg raise 75 degrees bilaterally. Hip flexor tightness noted on Thomas test (L > R). No pain with resisted knee flexion. Body weight 207 lbs, body fat estimated 14.8%.',
    'Tyler is making solid strength and power gains in his off-season program. The hamstring tightness warrants monitoring but does not appear to be pathological. Sleep hygiene is a concern that may limit recovery and performance gains. His combine metrics are trending in the right direction for his position goals.',
    'Continue Phase 1 strength base with progressive overload on squat and deadlift. Add Nordic hamstring curls 2x/week as prehab. Discuss sleep optimization strategies - target 7+ hours. Progress to Phase 2 power and speed work next week if strength benchmarks are met. Schedule 40-yard dash test in 10 days.',
    0,
    'improving',
    40,
    '["97530", "97110"]'::jsonb,
    'draft',
    (CURRENT_DATE - 1)::timestamptz + INTERVAL '16 hours',
    (CURRENT_DATE - 1)::timestamptz + INTERVAL '16 hours'
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- SECTION 4: WORKOUT HISTORY FOR JORDAN WILLIAMS (STRENGTH DASHBOARD)
-- ============================================================================
-- 4 weeks of exercise_logs with progressive weights for Squat, Bench, Deadlift.
-- Uses existing sessions and session_exercises from the comprehensive seed.

DO $$
DECLARE
    v_squat_id uuid;
    v_bench_id uuid;
    v_deadlift_id uuid;
    v_jordan_id uuid := 'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid;
    -- Session IDs from comprehensive seed (Jordan's sessions)
    v_session_501_1 uuid := 'dddddddd-0000-0000-0501-000000000001'::uuid;  -- Lower Body A
    v_session_502_1 uuid := 'dddddddd-0000-0000-0502-000000000001'::uuid;  -- Strength Day A
    v_session_501_2 uuid := 'dddddddd-0000-0000-0501-000000000002'::uuid;  -- Upper Body Modified
    v_session_502_2 uuid := 'dddddddd-0000-0000-0502-000000000002'::uuid;  -- Strength Day B
    -- Session exercise IDs (we need to find these dynamically)
    v_se_squat uuid;
    v_se_bench uuid;
    v_se_deadlift uuid;
    v_week int;
    v_set_num int;
    v_squat_weight numeric;
    v_bench_weight numeric;
    v_deadlift_weight numeric;
    v_workout_date date;
    v_performed_at timestamptz;
BEGIN
    -- Look up exercise template IDs
    SELECT id INTO v_squat_id FROM exercise_templates WHERE name = 'Barbell Squat' LIMIT 1;
    SELECT id INTO v_bench_id FROM exercise_templates WHERE name = 'Bench Press' LIMIT 1;
    IF v_bench_id IS NULL THEN
        SELECT id INTO v_bench_id FROM exercise_templates WHERE name = 'Barbell Bench Press' LIMIT 1;
    END IF;
    SELECT id INTO v_deadlift_id FROM exercise_templates WHERE name = 'Deadlift' LIMIT 1;

    -- For exercise logs we need a valid session_exercise_id.
    -- Jordan's Lower Body A already has goblet_squat and deadlift as session_exercises.
    -- We'll look up the deadlift session_exercise from the comprehensive seed.
    SELECT id INTO v_se_deadlift
    FROM session_exercises
    WHERE session_id = v_session_501_1 AND exercise_template_id = v_deadlift_id
    LIMIT 1;

    -- For squat and bench, we may need to add session_exercises to other sessions.
    -- First check if squat exists on any of Jordan's sessions.
    SELECT id INTO v_se_squat
    FROM session_exercises
    WHERE session_id IN (v_session_501_1, v_session_502_1, v_session_501_2, v_session_502_2)
      AND exercise_template_id = v_squat_id
    LIMIT 1;

    -- If no squat session_exercise exists, add one to Strength Day A
    IF v_se_squat IS NULL AND v_squat_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, target_rpe, rest_period_seconds, notes)
        VALUES (v_session_502_1, v_squat_id, 1, 4, '5', 225, 'lbs', 8, 180, 'Barbell squat for progressive overload')
        ON CONFLICT DO NOTHING;

        SELECT id INTO v_se_squat
        FROM session_exercises
        WHERE session_id = v_session_502_1 AND exercise_template_id = v_squat_id
        LIMIT 1;
    END IF;

    -- Check for bench session_exercise
    SELECT id INTO v_se_bench
    FROM session_exercises
    WHERE session_id IN (v_session_501_1, v_session_502_1, v_session_501_2, v_session_502_2)
      AND exercise_template_id = v_bench_id
    LIMIT 1;

    -- If no bench session_exercise exists, add one to Strength Day B
    IF v_se_bench IS NULL AND v_bench_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, target_rpe, rest_period_seconds, notes)
        VALUES (v_session_502_2, v_bench_id, 1, 4, '5', 155, 'lbs', 7, 120, 'Bench press for progressive overload')
        ON CONFLICT DO NOTHING;

        SELECT id INTO v_se_bench
        FROM session_exercises
        WHERE session_id = v_session_502_2 AND exercise_template_id = v_bench_id
        LIMIT 1;
    END IF;

    -- Generate 4 weeks of progressive workout history
    -- Week 1: Squat 225, Bench 155, Deadlift 275
    -- Week 2: Squat 235, Bench 160, Deadlift 285
    -- Week 3: Squat 245, Bench 165, Deadlift 295
    -- Week 4: Squat 255, Bench 170, Deadlift 305
    FOR v_week IN 1..4 LOOP
        v_workout_date := CURRENT_DATE - ((4 - v_week) * 7 + 2);  -- Spread over past 28 days
        v_squat_weight := 215 + (v_week * 10);     -- 225, 235, 245, 255
        v_bench_weight := 150 + (v_week * 5);       -- 155, 160, 165, 170
        v_deadlift_weight := 265 + (v_week * 10);   -- 275, 285, 295, 305

        -- Squat sets (3 working sets per week)
        IF v_se_squat IS NOT NULL THEN
            FOR v_set_num IN 1..3 LOOP
                v_performed_at := v_workout_date::timestamptz + INTERVAL '14 hours' + (v_set_num * INTERVAL '4 minutes');
                INSERT INTO exercise_logs (
                    patient_id, session_id, session_exercise_id,
                    performed_at, set_number, actual_sets, actual_reps, actual_load,
                    load_unit, rpe, is_pr, notes
                ) VALUES (
                    v_jordan_id,
                    v_session_502_1,
                    v_se_squat,
                    v_performed_at,
                    v_set_num,
                    3,
                    ARRAY[5],
                    v_squat_weight,
                    'lbs',
                    CASE WHEN v_week = 4 AND v_set_num = 3 THEN 9.0 ELSE 7.0 + (v_week * 0.3) END,
                    (v_week = 4 AND v_set_num = 1),
                    CASE WHEN v_week = 4 THEN 'New PR! Felt strong.' ELSE NULL END
                )
                ON CONFLICT DO NOTHING;
            END LOOP;
        END IF;

        -- Bench Press sets (3 working sets per week)
        IF v_se_bench IS NOT NULL THEN
            FOR v_set_num IN 1..3 LOOP
                v_performed_at := (v_workout_date + 1)::timestamptz + INTERVAL '14 hours' + (v_set_num * INTERVAL '3 minutes');
                INSERT INTO exercise_logs (
                    patient_id, session_id, session_exercise_id,
                    performed_at, set_number, actual_sets, actual_reps, actual_load,
                    load_unit, rpe, is_pr, notes
                ) VALUES (
                    v_jordan_id,
                    v_session_502_2,
                    v_se_bench,
                    v_performed_at,
                    v_set_num,
                    3,
                    ARRAY[5],
                    v_bench_weight,
                    'lbs',
                    7.0 + (v_week * 0.3),
                    false,
                    NULL
                )
                ON CONFLICT DO NOTHING;
            END LOOP;
        END IF;

        -- Deadlift sets (3 working sets per week)
        IF v_se_deadlift IS NOT NULL THEN
            FOR v_set_num IN 1..3 LOOP
                v_performed_at := (v_workout_date + 2)::timestamptz + INTERVAL '14 hours' + (v_set_num * INTERVAL '5 minutes');
                INSERT INTO exercise_logs (
                    patient_id, session_id, session_exercise_id,
                    performed_at, set_number, actual_sets, actual_reps, actual_load,
                    load_unit, rpe, is_pr, notes
                ) VALUES (
                    v_jordan_id,
                    v_session_501_1,
                    v_se_deadlift,
                    v_performed_at,
                    v_set_num,
                    3,
                    ARRAY[5],
                    v_deadlift_weight,
                    'lbs',
                    CASE WHEN v_week >= 3 THEN 8.0 + (v_week * 0.2) ELSE 7.5 END,
                    (v_week = 4 AND v_set_num = 1),
                    CASE WHEN v_week = 4 THEN 'Deadlift PR - 305 x 5' ELSE NULL END
                )
                ON CONFLICT DO NOTHING;
            END LOOP;
        END IF;
    END LOOP;

    RAISE NOTICE 'Jordan Williams workout history seeded: 4 weeks x 3 exercises x 3 sets';
END $$;

-- Re-enable audit triggers
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_sessions_trigger') THEN
        ALTER TABLE sessions ENABLE TRIGGER USER;
    END IF;
END $$;


-- ============================================================================
-- SECTION 5: TODAY'S NUTRITION FOR MARCUS RIVERA
-- ============================================================================
-- 3 meal entries (breakfast, lunch, snack) for CURRENT_DATE
-- Marcus has a 2800 cal daily target (labrum recovery nutrition)

INSERT INTO nutrition_logs (patient_id, log_date, logged_at, meal_type, description, calories, protein_grams, carbs_grams, fats_grams, notes)
VALUES
    -- Breakfast: Protein oatmeal with banana and almonds (~700 cal, 25% of daily)
    (
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        CURRENT_DATE,
        CURRENT_DATE::timestamptz + INTERVAL '7 hours 15 minutes',
        'breakfast',
        'Protein oatmeal with banana, almonds, and honey',
        720,
        42.0,
        88.0,
        22.0,
        'Pre-rehab breakfast. Added extra protein scoop for tissue repair.'
    ),
    -- Lunch: Grilled chicken rice bowl (~840 cal, 30% of daily)
    (
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        CURRENT_DATE,
        CURRENT_DATE::timestamptz + INTERVAL '12 hours 30 minutes',
        'lunch',
        'Grilled chicken rice bowl with black beans and avocado',
        840,
        55.0,
        95.0,
        26.0,
        'Post-session lunch. Hit protein target for meal.'
    ),
    -- Snack: Greek yogurt with berries and granola (~320 cal, ~11% of daily)
    (
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        CURRENT_DATE,
        CURRENT_DATE::timestamptz + INTERVAL '15 hours 45 minutes',
        'snack',
        'Greek yogurt parfait with mixed berries and granola',
        320,
        28.0,
        38.0,
        8.0,
        'Afternoon recovery snack. Good casein protein source.'
    )
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SECTION 6: PAIN LOGS FOR MARCUS RIVERA (RECOVERY TREND)
-- ============================================================================
-- 5 pain entries over past 2 weeks showing decreasing pain (recovery).
-- Locations: left_shoulder (labrum repair area), neck, lower_back
-- Uses the existing pain_logs schema: patient_id, session_id, logged_at,
-- pain_rest, pain_during, pain_after, notes

INSERT INTO pain_logs (patient_id, session_id, logged_at, pain_rest, pain_during, pain_after, notes)
VALUES
    -- Entry 1: 14 days ago - left shoulder flare after overhead work
    (
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        NULL,
        NOW() - INTERVAL '14 days',
        3, 5, 6,
        'Location: left_shoulder. Flare-up after overhead band work. Sharp pain at end-range external rotation. Ice applied post-session.'
    ),
    -- Entry 2: 10 days ago - neck tension from compensatory patterns
    (
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        NULL,
        NOW() - INTERVAL '10 days',
        2, 4, 4,
        'Location: neck. Upper trap tension from compensating during shoulder exercises. Stretching helped. Left shoulder improving - pain during exercise down to 4/10.'
    ),
    -- Entry 3: 7 days ago - lower back tightness, shoulder better
    (
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        NULL,
        NOW() - INTERVAL '7 days',
        2, 3, 3,
        'Location: lower_back. Mild lower back tightness after deadlift session. Left shoulder continues to improve - only 3/10 during activity. No pain at rest in shoulder.'
    ),
    -- Entry 4: 4 days ago - continued improvement across all areas
    (
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        NULL,
        NOW() - INTERVAL '4 days',
        1, 2, 3,
        'Location: left_shoulder. Significant improvement. Tolerated full rehab session with minimal discomfort. Neck tension resolved. Lower back feels normal.'
    ),
    -- Entry 5: 1 day ago - near pain-free
    (
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        NULL,
        NOW() - INTERVAL '1 day',
        1, 2, 2,
        'Location: left_shoulder. Near pain-free at rest. Mild pulling sensation only at extreme external rotation. Recovery trajectory is excellent. Ready for progressive loading.'
    )
ON CONFLICT DO NOTHING;


-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_jordan_lightweight_ex int;
    v_jordan_lightweight_sched int;
    v_tyler_sched int;
    v_olivia_sched int;
    v_alyssa_sched int;
    v_deshawn_sched int;
    v_soap_count int;
    v_jordan_logs int;
    v_marcus_nutrition int;
    v_marcus_pain int;
BEGIN
    -- Section 1: Jordan lightweight session
    SELECT COUNT(*) INTO v_jordan_lightweight_ex
    FROM session_exercises
    WHERE session_id = 'dddddddd-0000-0000-0501-000000000099'::uuid;

    SELECT COUNT(*) INTO v_jordan_lightweight_sched
    FROM scheduled_sessions
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid
      AND session_id = 'dddddddd-0000-0000-0501-000000000099'::uuid
      AND scheduled_date = CURRENT_DATE
      AND status = 'scheduled';

    -- Section 2: Today's sessions
    SELECT COUNT(*) INTO v_tyler_sched FROM scheduled_sessions
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid AND scheduled_date = CURRENT_DATE AND status = 'scheduled';

    SELECT COUNT(*) INTO v_olivia_sched FROM scheduled_sessions
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid AND scheduled_date = CURRENT_DATE AND status = 'scheduled';

    SELECT COUNT(*) INTO v_alyssa_sched FROM scheduled_sessions
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid AND scheduled_date = CURRENT_DATE AND status = 'scheduled';

    SELECT COUNT(*) INTO v_deshawn_sched FROM scheduled_sessions
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid AND scheduled_date = CURRENT_DATE AND status = 'scheduled';

    -- Section 3: SOAP notes
    SELECT COUNT(*) INTO v_soap_count FROM soap_notes
    WHERE therapist_id = '00000000-0000-0000-0000-000000000100'::uuid
      AND id IN (
          'ffff0000-0000-0000-0000-000000000001'::uuid,
          'ffff0000-0000-0000-0000-000000000002'::uuid,
          'ffff0000-0000-0000-0000-000000000003'::uuid
      );

    -- Section 4: Jordan exercise logs
    SELECT COUNT(*) INTO v_jordan_logs FROM exercise_logs
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid
      AND performed_at >= (CURRENT_DATE - 30)::timestamptz;

    -- Section 5: Marcus nutrition today
    SELECT COUNT(*) INTO v_marcus_nutrition FROM nutrition_logs
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid
      AND log_date = CURRENT_DATE;

    -- Section 6: Marcus pain logs (last 14 days)
    SELECT COUNT(*) INTO v_marcus_pain FROM pain_logs
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid
      AND logged_at >= NOW() - INTERVAL '15 days';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'E2E EXPANSION DATA SEED VERIFICATION';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE '1. Jordan Lightweight Session:';
    RAISE NOTICE '   Exercises in session:    % (expected: 2)', v_jordan_lightweight_ex;
    RAISE NOTICE '   Scheduled for today:     % (expected: 1)', v_jordan_lightweight_sched;
    RAISE NOTICE '';
    RAISE NOTICE '2. Today''s Sessions:';
    RAISE NOTICE '   Tyler scheduled today:   % (expected: >= 1)', v_tyler_sched;
    RAISE NOTICE '   Olivia scheduled today:  % (expected: >= 1)', v_olivia_sched;
    RAISE NOTICE '   Alyssa scheduled today:  % (expected: >= 1)', v_alyssa_sched;
    RAISE NOTICE '   Deshawn scheduled today: % (expected: >= 1)', v_deshawn_sched;
    RAISE NOTICE '';
    RAISE NOTICE '3. SOAP Notes:';
    RAISE NOTICE '   Notes by Sarah Thompson: % (expected: 3)', v_soap_count;
    RAISE NOTICE '';
    RAISE NOTICE '4. Jordan Workout History:';
    RAISE NOTICE '   Exercise logs (30 days): % (expected: >= 36)', v_jordan_logs;
    RAISE NOTICE '';
    RAISE NOTICE '5. Marcus Nutrition Today:';
    RAISE NOTICE '   Meals logged today:      % (expected: 3)', v_marcus_nutrition;
    RAISE NOTICE '';
    RAISE NOTICE '6. Marcus Pain Logs:';
    RAISE NOTICE '   Pain entries (14 days):  % (expected: >= 5)', v_marcus_pain;
    RAISE NOTICE '============================================';

    -- Warnings for critical items
    IF v_jordan_lightweight_ex < 2 THEN
        RAISE WARNING 'Jordan lightweight session has < 2 exercises - testFinishWorkoutShowsSummary may fail!';
    END IF;
    IF v_jordan_lightweight_sched < 1 THEN
        RAISE WARNING 'Jordan lightweight session not scheduled for today!';
    END IF;
    IF v_soap_count < 3 THEN
        RAISE WARNING 'SOAP notes count is < 3 - therapist tests may fail!';
    END IF;
END $$;

-- Force PostgREST schema reload
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
