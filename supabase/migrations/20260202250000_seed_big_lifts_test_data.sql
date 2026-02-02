-- Migration: Seed Big Lifts Test Data for Demo Patient
-- Date: 2026-02-02
-- Purpose: Add sample workout data to test the Big Lifts Scorecard
-- Patient ID: 00000000-0000-0000-0000-000000000001 (demo patient)

-- Add exercises to existing "Strength Day 4" session (2026-01-23)
-- This session should have the PR weights

DO $$
DECLARE
    v_session_id UUID;
BEGIN
    -- Find the Strength Day 4 session
    SELECT id INTO v_session_id
    FROM manual_sessions
    WHERE patient_id = '00000000-0000-0000-0000-000000000001'
      AND name = 'Strength Day 4'
      AND notes LIKE '%SEED%'
    LIMIT 1;

    IF v_session_id IS NOT NULL THEN
        -- Delete any existing exercises for this session (clean slate)
        DELETE FROM manual_session_exercises WHERE manual_session_id = v_session_id;

        -- Add PR exercises
        INSERT INTO manual_session_exercises (manual_session_id, exercise_name, target_sets, target_reps, target_load, load_unit, notes)
        VALUES
            (v_session_id, 'Bench Press', 3, '5', 180, 'lbs', 'New PR!'),
            (v_session_id, 'Squat', 3, '5', 245, 'lbs', 'New PR!'),
            (v_session_id, 'Deadlift', 3, '3', 305, 'lbs', 'New PR!'),
            (v_session_id, 'Overhead Press', 3, '5', 105, 'lbs', 'New PR!');

        RAISE NOTICE 'Added 4 PR exercises to Strength Day 4 session: %', v_session_id;
    ELSE
        RAISE NOTICE 'Strength Day 4 session not found, creating new session...';

        -- Create the session if it doesn't exist
        INSERT INTO manual_sessions (id, patient_id, name, completed_at, notes, created_at)
        VALUES (
            gen_random_uuid(),
            '00000000-0000-0000-0000-000000000001',
            'Strength Day 4 - PRs',
            CURRENT_DATE - INTERVAL '10 days' + TIME '10:00:00',
            '[SEED] Personal records!',
            NOW()
        )
        RETURNING id INTO v_session_id;

        INSERT INTO manual_session_exercises (manual_session_id, exercise_name, target_sets, target_reps, target_load, load_unit, notes)
        VALUES
            (v_session_id, 'Bench Press', 3, '5', 180, 'lbs', 'New PR!'),
            (v_session_id, 'Squat', 3, '5', 245, 'lbs', 'New PR!'),
            (v_session_id, 'Deadlift', 3, '3', 305, 'lbs', 'New PR!'),
            (v_session_id, 'Overhead Press', 3, '5', 105, 'lbs', 'New PR!');

        RAISE NOTICE 'Created new PR session with 4 exercises: %', v_session_id;
    END IF;
END $$;

-- Verify the data was added
DO $$
DECLARE
    v_bench_max NUMERIC;
    v_squat_max NUMERIC;
    v_deadlift_max NUMERIC;
BEGIN
    SELECT MAX(target_load) INTO v_bench_max
    FROM manual_session_exercises mse
    JOIN manual_sessions ms ON mse.manual_session_id = ms.id
    WHERE ms.patient_id = '00000000-0000-0000-0000-000000000001'
      AND mse.exercise_name = 'Bench Press';

    SELECT MAX(target_load) INTO v_squat_max
    FROM manual_session_exercises mse
    JOIN manual_sessions ms ON mse.manual_session_id = ms.id
    WHERE ms.patient_id = '00000000-0000-0000-0000-000000000001'
      AND mse.exercise_name = 'Squat';

    SELECT MAX(target_load) INTO v_deadlift_max
    FROM manual_session_exercises mse
    JOIN manual_sessions ms ON mse.manual_session_id = ms.id
    WHERE ms.patient_id = '00000000-0000-0000-0000-000000000001'
      AND mse.exercise_name = 'Deadlift';

    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'BIG LIFTS SEED DATA VERIFICATION';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Bench Press Max: % lbs', COALESCE(v_bench_max, 0);
    RAISE NOTICE 'Squat Max: % lbs', COALESCE(v_squat_max, 0);
    RAISE NOTICE 'Deadlift Max: % lbs', COALESCE(v_deadlift_max, 0);
    RAISE NOTICE 'SBD Total: % lbs', COALESCE(v_bench_max, 0) + COALESCE(v_squat_max, 0) + COALESCE(v_deadlift_max, 0);
    RAISE NOTICE '========================================';
END $$;
