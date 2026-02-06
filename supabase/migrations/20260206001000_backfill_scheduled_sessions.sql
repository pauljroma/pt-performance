-- Backfill scheduled_sessions for all active enrollments
-- Build 441 - Today tab shows workouts for enrolled programs
-- Note: schedule_enrollment_workouts function was already updated in previous migration

-- ============================================================================
-- Re-run backfill with updated function
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
-- Verify results
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
        LIMIT 5
    LOOP
        RAISE NOTICE '  %: % on %', rec.program_title, rec.workout_name, rec.scheduled_date;
    END LOOP;
END $$;
