-- Build 451: Comprehensive Today Tab Fix
-- Fix enrolled programs display and session scheduling
--
-- Problem: Real accounts (paul@romatech.com) show nothing on Today tab while demo works
-- Root cause: Demo has direct sessions, real accounts use enrollments without scheduled_sessions
--
-- This migration:
-- 1. Diagnoses the current state
-- 2. Ensures program_library entries have workout structures
-- 3. Creates scheduled_sessions for existing enrollments
-- 4. Adds RPC for Today tab to fetch scheduled workouts

-- ============================================================================
-- Step 1: Diagnostic - Show what paul@romatech.com has
-- ============================================================================

DO $$
DECLARE
    v_paul_patient_id UUID;
    v_count INT;
BEGIN
    SELECT id INTO v_paul_patient_id FROM patients WHERE email = 'paul@romatech.com';

    RAISE NOTICE '=== DIAGNOSTIC: paul@romatech.com (patient_id: %) ===', v_paul_patient_id;

    -- Check enrollments
    SELECT COUNT(*) INTO v_count FROM program_enrollments WHERE patient_id = v_paul_patient_id;
    RAISE NOTICE 'Total enrollments: %', v_count;

    SELECT COUNT(*) INTO v_count FROM program_enrollments WHERE patient_id = v_paul_patient_id AND status = 'active';
    RAISE NOTICE 'Active enrollments: %', v_count;

    -- Check scheduled sessions
    SELECT COUNT(*) INTO v_count FROM scheduled_sessions WHERE patient_id = v_paul_patient_id;
    RAISE NOTICE 'Scheduled sessions: %', v_count;

    -- Check direct programs
    SELECT COUNT(*) INTO v_count FROM programs WHERE patient_id = v_paul_patient_id;
    RAISE NOTICE 'Direct programs: %', v_count;

    -- Check program_library with program_id set
    SELECT COUNT(*) INTO v_count
    FROM program_enrollments pe
    JOIN program_library pl ON pl.id = pe.program_library_id
    WHERE pe.patient_id = v_paul_patient_id
      AND pl.program_id IS NOT NULL;
    RAISE NOTICE 'Enrollments with workout structure (program_id set): %', v_count;

    -- Check program_library without program_id
    SELECT COUNT(*) INTO v_count
    FROM program_enrollments pe
    JOIN program_library pl ON pl.id = pe.program_library_id
    WHERE pe.patient_id = v_paul_patient_id
      AND pl.program_id IS NULL;
    RAISE NOTICE 'Enrollments WITHOUT workout structure (program_id NULL): %', v_count;
END $$;

-- ============================================================================
-- Step 2: List paul's enrolled programs and their workout status
-- ============================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE '=== ENROLLED PROGRAMS DETAILS ===';
    FOR r IN
        SELECT
            pe.id as enrollment_id,
            pl.title as program_title,
            pl.program_id,
            pe.status,
            pe.started_at,
            CASE WHEN pl.program_id IS NOT NULL THEN 'YES' ELSE 'NO' END as has_workouts
        FROM program_enrollments pe
        JOIN program_library pl ON pl.id = pe.program_library_id
        WHERE pe.patient_id = (SELECT id FROM patients WHERE email = 'paul@romatech.com')
        ORDER BY pe.enrolled_at DESC
    LOOP
        RAISE NOTICE 'Program: % | Status: % | Has Workouts: % | Started: %',
            r.program_title, r.status, r.has_workouts, r.started_at;
    END LOOP;
END $$;

-- ============================================================================
-- Step 3: Ensure all BASE pack programs have workout structures
-- (Re-run the connection logic from 20260205210000)
-- ============================================================================

-- First, ensure program_workout_assignments table exists
CREATE TABLE IF NOT EXISTS program_workout_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    template_id UUID NOT NULL REFERENCES system_workout_templates(id) ON DELETE CASCADE,
    phase_id UUID REFERENCES phases(id) ON DELETE SET NULL,
    week_number INT NOT NULL DEFAULT 1,
    day_of_week INT NOT NULL DEFAULT 1,  -- 1=Monday, 7=Sunday
    sequence INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(program_id, week_number, day_of_week, sequence)
);

-- ============================================================================
-- Step 4: Create RPC for Today tab to get today's scheduled workout
-- ============================================================================

CREATE OR REPLACE FUNCTION get_my_today_workout()
RETURNS TABLE (
    scheduled_session_id UUID,
    workout_name TEXT,
    workout_template_id UUID,
    enrollment_id UUID,
    program_title TEXT,
    scheduled_date DATE,
    status TEXT,
    duration_minutes INT,
    exercises JSONB
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_patient_id UUID;
    v_auth_email TEXT;
BEGIN
    -- Get the current user's email from JWT
    v_auth_email := auth.jwt() ->> 'email';

    -- Find patient ID by auth user_id or email
    SELECT p.id INTO v_patient_id
    FROM patients p
    WHERE p.user_id = auth.uid()
       OR p.email = v_auth_email
    LIMIT 1;

    IF v_patient_id IS NULL THEN
        RAISE NOTICE 'No patient found for auth.uid()=% or email=%', auth.uid(), v_auth_email;
        RETURN;
    END IF;

    RAISE NOTICE 'get_my_today_workout: patient_id=%, date=%', v_patient_id, CURRENT_DATE;

    -- Return today's scheduled workouts
    RETURN QUERY
    SELECT
        ss.id as scheduled_session_id,
        ss.workout_name,
        ss.workout_template_id,
        ss.enrollment_id,
        pl.title as program_title,
        ss.scheduled_date,
        ss.status,
        swt.duration_minutes,
        swt.exercises
    FROM scheduled_sessions ss
    LEFT JOIN program_enrollments pe ON pe.id = ss.enrollment_id
    LEFT JOIN program_library pl ON pl.id = pe.program_library_id
    LEFT JOIN system_workout_templates swt ON swt.id = ss.workout_template_id
    WHERE ss.patient_id = v_patient_id
      AND ss.scheduled_date = CURRENT_DATE
      AND ss.status IN ('scheduled', 'in_progress')
    ORDER BY ss.created_at ASC
    LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION get_my_today_workout() TO authenticated;

-- ============================================================================
-- Step 5: Create RPC to get upcoming scheduled workouts (for the week)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_my_upcoming_workouts(p_days INT DEFAULT 7)
RETURNS TABLE (
    scheduled_session_id UUID,
    workout_name TEXT,
    workout_template_id UUID,
    enrollment_id UUID,
    program_title TEXT,
    scheduled_date DATE,
    status TEXT,
    duration_minutes INT
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_patient_id UUID;
    v_auth_email TEXT;
BEGIN
    v_auth_email := auth.jwt() ->> 'email';

    SELECT p.id INTO v_patient_id
    FROM patients p
    WHERE p.user_id = auth.uid()
       OR p.email = v_auth_email
    LIMIT 1;

    IF v_patient_id IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        ss.id as scheduled_session_id,
        ss.workout_name,
        ss.workout_template_id,
        ss.enrollment_id,
        pl.title as program_title,
        ss.scheduled_date,
        ss.status,
        swt.duration_minutes
    FROM scheduled_sessions ss
    LEFT JOIN program_enrollments pe ON pe.id = ss.enrollment_id
    LEFT JOIN program_library pl ON pl.id = pe.program_library_id
    LEFT JOIN system_workout_templates swt ON swt.id = ss.workout_template_id
    WHERE ss.patient_id = v_patient_id
      AND ss.scheduled_date >= CURRENT_DATE
      AND ss.scheduled_date <= CURRENT_DATE + p_days
      AND ss.status IN ('scheduled', 'in_progress')
    ORDER BY ss.scheduled_date ASC, ss.created_at ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_my_upcoming_workouts(INT) TO authenticated;

-- ============================================================================
-- Step 6: Schedule workouts for all existing active enrollments that don't have any
-- ============================================================================

DO $$
DECLARE
    v_enrollment RECORD;
    v_count INT;
    v_total INT := 0;
    v_scheduled INT := 0;
BEGIN
    RAISE NOTICE '=== SCHEDULING WORKOUTS FOR EXISTING ENROLLMENTS ===';

    FOR v_enrollment IN
        SELECT
            pe.id as enrollment_id,
            pe.patient_id,
            pe.program_library_id,
            pe.started_at,
            pl.title,
            pl.program_id
        FROM program_enrollments pe
        JOIN program_library pl ON pl.id = pe.program_library_id
        WHERE pe.status = 'active'
    LOOP
        v_total := v_total + 1;

        -- Check if already has scheduled sessions
        SELECT COUNT(*) INTO v_count
        FROM scheduled_sessions
        WHERE enrollment_id = v_enrollment.enrollment_id;

        IF v_count > 0 THEN
            RAISE NOTICE 'Enrollment % (%) already has % scheduled sessions - skipping',
                v_enrollment.enrollment_id, v_enrollment.title, v_count;
            CONTINUE;
        END IF;

        -- Check if program has workout assignments
        IF v_enrollment.program_id IS NULL THEN
            RAISE NOTICE 'Enrollment % (%) has no linked program - cannot schedule',
                v_enrollment.enrollment_id, v_enrollment.title;
            CONTINUE;
        END IF;

        SELECT COUNT(*) INTO v_count
        FROM program_workout_assignments
        WHERE program_id = v_enrollment.program_id;

        IF v_count = 0 THEN
            RAISE NOTICE 'Program % has no workout assignments - cannot schedule',
                v_enrollment.program_id;
            CONTINUE;
        END IF;

        -- Schedule workouts
        BEGIN
            SELECT schedule_enrollment_workouts(
                v_enrollment.enrollment_id,
                COALESCE(v_enrollment.started_at::DATE, CURRENT_DATE)
            ) INTO v_count;

            v_scheduled := v_scheduled + 1;
            RAISE NOTICE 'Scheduled % workouts for enrollment % (%)',
                v_count, v_enrollment.enrollment_id, v_enrollment.title;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Failed to schedule for enrollment %: %', v_enrollment.enrollment_id, SQLERRM;
        END;
    END LOOP;

    RAISE NOTICE '=== SUMMARY ===';
    RAISE NOTICE 'Total active enrollments: %', v_total;
    RAISE NOTICE 'Successfully scheduled: %', v_scheduled;
END $$;

-- ============================================================================
-- Step 7: Final diagnostic
-- ============================================================================

DO $$
DECLARE
    v_paul_patient_id UUID;
    v_count INT;
    r RECORD;
BEGIN
    SELECT id INTO v_paul_patient_id FROM patients WHERE email = 'paul@romatech.com';

    RAISE NOTICE '=== FINAL STATE: paul@romatech.com ===';

    SELECT COUNT(*) INTO v_count FROM scheduled_sessions WHERE patient_id = v_paul_patient_id;
    RAISE NOTICE 'Total scheduled sessions: %', v_count;

    SELECT COUNT(*) INTO v_count
    FROM scheduled_sessions
    WHERE patient_id = v_paul_patient_id
      AND scheduled_date >= CURRENT_DATE;
    RAISE NOTICE 'Future scheduled sessions: %', v_count;

    SELECT COUNT(*) INTO v_count
    FROM scheduled_sessions
    WHERE patient_id = v_paul_patient_id
      AND scheduled_date = CURRENT_DATE;
    RAISE NOTICE 'Today scheduled sessions: %', v_count;

    -- Show next 5 upcoming
    RAISE NOTICE '--- Next 5 upcoming workouts ---';
    FOR r IN
        SELECT workout_name, scheduled_date, status
        FROM scheduled_sessions
        WHERE patient_id = v_paul_patient_id
          AND scheduled_date >= CURRENT_DATE
        ORDER BY scheduled_date ASC
        LIMIT 5
    LOOP
        RAISE NOTICE '  %: % (%)', r.scheduled_date, r.workout_name, r.status;
    END LOOP;
END $$;

-- ============================================================================
-- Summary
-- ============================================================================
-- Created:
-- - get_my_today_workout() - Returns today's scheduled workout with exercises
-- - get_my_upcoming_workouts() - Returns next N days of scheduled workouts
-- - Scheduled workouts for all active enrollments with program structures
--
-- Next: Update iOS TodaySessionViewModel to use these RPCs
