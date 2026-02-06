-- Fix: Handle both baseball programs (sessions table) and BASE programs (workout_assignments)
-- Build 441 - Today tab shows workouts for ALL enrolled programs
--
-- Problem: Baseball programs have sessions directly, not via program_workout_assignments
-- Solution: Check sessions table first, fall back to workout_assignments

-- ============================================================================
-- Recreate the scheduling function to handle both program types
-- ============================================================================

CREATE OR REPLACE FUNCTION schedule_enrollment_workouts(
    p_enrollment_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_patient_id UUID;
    v_program_library_id UUID;
    v_program_id UUID;
    v_scheduled_count INT := 0;
    v_session RECORD;
    v_assignment RECORD;
    v_workout_date DATE;
    v_has_sessions BOOLEAN := FALSE;
    v_has_assignments BOOLEAN := FALSE;
    v_week_offset INT;
    v_day_offset INT;
BEGIN
    -- Get enrollment details
    SELECT patient_id, program_library_id
    INTO v_patient_id, v_program_library_id
    FROM program_enrollments
    WHERE id = p_enrollment_id;

    IF v_patient_id IS NULL THEN
        RAISE EXCEPTION 'Enrollment not found: %', p_enrollment_id;
    END IF;

    -- Get the program_id from program_library
    SELECT program_id
    INTO v_program_id
    FROM program_library
    WHERE id = v_program_library_id;

    IF v_program_id IS NULL THEN
        RAISE NOTICE 'Program library % has no linked program', v_program_library_id;
        RETURN 0;
    END IF;

    -- Update enrollment with start date
    UPDATE program_enrollments
    SET started_at = p_start_date
    WHERE id = p_enrollment_id
      AND started_at IS NULL;

    -- Delete any existing scheduled sessions for this enrollment (fresh start)
    DELETE FROM scheduled_sessions
    WHERE patient_id = v_patient_id
      AND enrollment_id = p_enrollment_id;

    -- ========================================================================
    -- METHOD 1: Check for sessions in the sessions table (baseball programs)
    -- Baseball programs have sessions directly linked to phases
    -- ========================================================================

    SELECT EXISTS (
        SELECT 1
        FROM sessions s
        JOIN phases p ON p.id = s.phase_id
        WHERE p.program_id = v_program_id
        LIMIT 1
    ) INTO v_has_sessions;

    IF v_has_sessions THEN
        RAISE NOTICE 'Program % has sessions in sessions table (baseball program style)', v_program_id;

        FOR v_session IN
            SELECT
                s.id as session_id,
                s.name as session_name,
                p.sequence as phase_sequence,
                p.name as phase_name,
                ROW_NUMBER() OVER (ORDER BY p.sequence, s.created_at) as session_number
            FROM sessions s
            JOIN phases p ON p.id = s.phase_id
            WHERE p.program_id = v_program_id
            ORDER BY p.sequence, s.created_at
        LOOP
            -- Calculate workout date based on session number
            -- Schedule 3 sessions per week (Mon, Wed, Fri)
            -- session_number 1 -> day 0 (Mon), 2 -> day 2 (Wed), 3 -> day 4 (Fri)
            -- session_number 4 -> day 7 (next Mon), etc.
            v_week_offset := ((v_session.session_number::INT - 1) / 3) * 7;
            v_day_offset := CASE ((v_session.session_number::INT - 1) % 3)
                WHEN 0 THEN 0  -- Monday
                WHEN 1 THEN 2  -- Wednesday
                WHEN 2 THEN 4  -- Friday
            END;

            v_workout_date := p_start_date + v_week_offset + v_day_offset;

            INSERT INTO scheduled_sessions (
                patient_id,
                session_id,
                scheduled_date,
                status,
                notes,
                enrollment_id,
                workout_template_id,
                workout_name
            ) VALUES (
                v_patient_id,
                v_session.session_id,
                v_workout_date,
                'scheduled',
                v_session.phase_name || ' - ' || v_session.session_name,
                p_enrollment_id,
                NULL,  -- No template, using session directly
                v_session.session_name
            )
            ON CONFLICT DO NOTHING;

            v_scheduled_count := v_scheduled_count + 1;
        END LOOP;

        RAISE NOTICE 'Scheduled % sessions from sessions table', v_scheduled_count;
        RETURN v_scheduled_count;
    END IF;

    -- ========================================================================
    -- METHOD 2: Check program_workout_assignments (BASE programs)
    -- BASE programs use templates assigned to weeks/days
    -- ========================================================================

    SELECT EXISTS (
        SELECT 1
        FROM program_workout_assignments pwa
        WHERE pwa.program_id = v_program_id
        LIMIT 1
    ) INTO v_has_assignments;

    IF v_has_assignments THEN
        RAISE NOTICE 'Program % has workout assignments (BASE program style)', v_program_id;

        FOR v_assignment IN
            SELECT
                pwa.id as assignment_id,
                pwa.template_id,
                pwa.week_number,
                pwa.day_of_week,
                pwa.sequence,
                pwa.phase_id,
                swt.name as workout_name,
                swt.duration_minutes,
                swt.exercises
            FROM program_workout_assignments pwa
            JOIN system_workout_templates swt ON swt.id = pwa.template_id
            WHERE pwa.program_id = v_program_id
            ORDER BY pwa.week_number, pwa.day_of_week
        LOOP
            -- Calculate the actual date for this workout
            v_workout_date := p_start_date
                + ((v_assignment.week_number - 1) * 7)
                + (v_assignment.day_of_week - EXTRACT(DOW FROM p_start_date)::INT);

            -- If the calculated date is before start_date, move to next week
            IF v_workout_date < p_start_date THEN
                v_workout_date := v_workout_date + 7;
            END IF;

            INSERT INTO scheduled_sessions (
                patient_id,
                session_id,
                scheduled_date,
                status,
                notes,
                enrollment_id,
                workout_template_id,
                workout_name
            ) VALUES (
                v_patient_id,
                NULL,  -- No session_id for template-based workouts
                v_workout_date,
                'scheduled',
                'Week ' || v_assignment.week_number || ' - ' || v_assignment.workout_name,
                p_enrollment_id,
                v_assignment.template_id,
                v_assignment.workout_name
            )
            ON CONFLICT DO NOTHING;

            v_scheduled_count := v_scheduled_count + 1;
        END LOOP;

        RAISE NOTICE 'Scheduled % workouts from program_workout_assignments', v_scheduled_count;
        RETURN v_scheduled_count;
    END IF;

    RAISE NOTICE 'Program % has neither sessions nor workout assignments', v_program_id;
    RETURN 0;
END;
$$;
