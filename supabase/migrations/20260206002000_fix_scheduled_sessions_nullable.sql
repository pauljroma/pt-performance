-- Fix: Make session_id and scheduled_time nullable for enrollment-based workouts
-- Build 441 - Enrollment workouts don't have session_id upfront
--
-- Problem: scheduled_sessions requires session_id and scheduled_time NOT NULL
-- Solution: Make these nullable for enrollment-based workouts

-- ============================================================================
-- Step 1: Make session_id nullable (enrollment workouts don't have sessions)
-- ============================================================================

ALTER TABLE scheduled_sessions
    ALTER COLUMN session_id DROP NOT NULL;

-- ============================================================================
-- Step 2: Make scheduled_time nullable (use default time)
-- ============================================================================

ALTER TABLE scheduled_sessions
    ALTER COLUMN scheduled_time DROP NOT NULL;

-- ============================================================================
-- Step 3: Drop the unique constraint that includes session_id
-- ============================================================================

-- Drop old constraint if it exists
ALTER TABLE scheduled_sessions
    DROP CONSTRAINT IF EXISTS scheduled_sessions_patient_id_session_id_scheduled_date_key;

-- Create new constraint that allows enrollment-based workouts
-- (patient_id, enrollment_id, scheduled_date) for enrollment workouts
-- (patient_id, session_id, scheduled_date) for regular workouts
CREATE UNIQUE INDEX IF NOT EXISTS idx_scheduled_sessions_unique_enrollment
    ON scheduled_sessions(patient_id, enrollment_id, scheduled_date)
    WHERE enrollment_id IS NOT NULL;

-- ============================================================================
-- Step 4: Re-run backfill
-- ============================================================================

DO $$
DECLARE
    v_enrollment RECORD;
    v_count INT;
    v_total INT := 0;
BEGIN
    -- Clear existing enrollment scheduled sessions
    DELETE FROM scheduled_sessions WHERE enrollment_id IS NOT NULL;
    RAISE NOTICE 'Cleared existing enrollment scheduled sessions';

    -- Backfill all active enrollments
    FOR v_enrollment IN
        SELECT pe.id, pe.patient_id, pe.started_at, pl.program_id, pl.title
        FROM program_enrollments pe
        JOIN program_library pl ON pl.id = pe.program_library_id
        WHERE pe.status = 'active'
          AND pl.program_id IS NOT NULL
    LOOP
        RAISE NOTICE 'Scheduling workouts for enrollment % (program: %)', v_enrollment.id, v_enrollment.title;

        BEGIN
            SELECT schedule_enrollment_workouts(
                v_enrollment.id,
                COALESCE(v_enrollment.started_at::DATE, CURRENT_DATE)
            ) INTO v_count;

            RAISE NOTICE '  -> Scheduled % workouts', v_count;
            v_total := v_total + COALESCE(v_count, 0);
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  -> Error scheduling: %', SQLERRM;
        END;
    END LOOP;

    RAISE NOTICE '======================================';
    RAISE NOTICE 'Total scheduled sessions created: %', v_total;
    RAISE NOTICE '======================================';
END $$;

-- ============================================================================
-- Step 5: Verify results
-- ============================================================================

DO $$
DECLARE
    v_count INT;
    rec RECORD;
BEGIN
    SELECT COUNT(*) INTO v_count FROM scheduled_sessions WHERE enrollment_id IS NOT NULL;
    RAISE NOTICE 'Total scheduled sessions from enrollments: %', v_count;

    -- Show sample of scheduled workouts
    RAISE NOTICE 'Sample scheduled workouts:';
    FOR rec IN
        SELECT ss.workout_name, ss.scheduled_date, pl.title as program_title
        FROM scheduled_sessions ss
        JOIN program_enrollments pe ON pe.id = ss.enrollment_id
        JOIN program_library pl ON pl.id = pe.program_library_id
        ORDER BY ss.scheduled_date
        LIMIT 10
    LOOP
        RAISE NOTICE '  %: % on %', rec.program_title, rec.workout_name, rec.scheduled_date;
    END LOOP;
END $$;
