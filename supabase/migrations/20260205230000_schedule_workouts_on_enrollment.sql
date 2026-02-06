-- Schedule workouts when a user enrolls in a program
-- Build 441+ - Fix: Today tab shows scheduled workouts from enrolled programs
--
-- Problem: Enrolling in a program doesn't create scheduled_sessions, so the
-- Today view shows nothing even after enrollment.
-- Solution: Create scheduled_sessions from program_workout_assignments on enrollment.

-- ============================================================================
-- Function: Schedule workouts for an enrollment
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
    v_assignment RECORD;
    v_workout_date DATE;
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
        -- This is a catalog-only program without workout assignments
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

    -- Create scheduled sessions from program_workout_assignments
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
        -- week_number 1 starts on p_start_date's week
        -- day_of_week: 1=Monday, 7=Sunday
        v_workout_date := p_start_date
            + ((v_assignment.week_number - 1) * 7)  -- Add weeks
            + (v_assignment.day_of_week - EXTRACT(DOW FROM p_start_date)::INT);  -- Adjust for day of week

        -- If the calculated date is before start_date, move to next week
        IF v_workout_date < p_start_date THEN
            v_workout_date := v_workout_date + 7;
        END IF;

        -- Insert scheduled session
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

    RAISE NOTICE 'Scheduled % workouts for enrollment %', v_scheduled_count, p_enrollment_id;
    RETURN v_scheduled_count;
END;
$$;

-- ============================================================================
-- Add enrollment_id and workout columns to scheduled_sessions if missing
-- ============================================================================

ALTER TABLE scheduled_sessions
    ADD COLUMN IF NOT EXISTS enrollment_id UUID REFERENCES program_enrollments(id) ON DELETE CASCADE;

ALTER TABLE scheduled_sessions
    ADD COLUMN IF NOT EXISTS workout_template_id UUID REFERENCES system_workout_templates(id) ON DELETE SET NULL;

ALTER TABLE scheduled_sessions
    ADD COLUMN IF NOT EXISTS workout_name TEXT;

-- Index for enrollment lookups
CREATE INDEX IF NOT EXISTS idx_scheduled_sessions_enrollment
    ON scheduled_sessions(enrollment_id) WHERE enrollment_id IS NOT NULL;

-- ============================================================================
-- Trigger: Auto-schedule workouts on new enrollment
-- ============================================================================

CREATE OR REPLACE FUNCTION trigger_schedule_enrollment_workouts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INT;
BEGIN
    -- Only schedule for new active enrollments
    IF NEW.status = 'active' THEN
        SELECT schedule_enrollment_workouts(NEW.id, COALESCE(NEW.started_at::DATE, CURRENT_DATE))
        INTO v_count;

        RAISE NOTICE 'Auto-scheduled % workouts for new enrollment %', v_count, NEW.id;
    END IF;

    RETURN NEW;
END;
$$;

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS enrollment_schedule_workouts ON program_enrollments;

-- Create trigger for new enrollments
CREATE TRIGGER enrollment_schedule_workouts
    AFTER INSERT ON program_enrollments
    FOR EACH ROW
    EXECUTE FUNCTION trigger_schedule_enrollment_workouts();

-- ============================================================================
-- RPC to manually schedule workouts (for existing enrollments)
-- ============================================================================

CREATE OR REPLACE FUNCTION schedule_my_enrollment_workouts(p_enrollment_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_patient_id UUID;
    v_count INT;
BEGIN
    -- Verify the enrollment belongs to the current user
    SELECT patient_id INTO v_patient_id
    FROM program_enrollments
    WHERE id = p_enrollment_id;

    -- Check ownership via patients table
    IF NOT EXISTS (
        SELECT 1 FROM patients
        WHERE id = v_patient_id
        AND (user_id = auth.uid() OR email = (auth.jwt() ->> 'email'))
    ) THEN
        RAISE EXCEPTION 'Not authorized to schedule this enrollment';
    END IF;

    -- Schedule the workouts
    SELECT schedule_enrollment_workouts(p_enrollment_id) INTO v_count;

    RETURN v_count;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION schedule_my_enrollment_workouts(UUID) TO authenticated;

-- ============================================================================
-- Schedule workouts for existing enrollments
-- ============================================================================

DO $$
DECLARE
    v_enrollment RECORD;
    v_count INT;
    v_total INT := 0;
BEGIN
    FOR v_enrollment IN
        SELECT pe.id, pe.patient_id, pe.started_at, pl.program_id
        FROM program_enrollments pe
        JOIN program_library pl ON pl.id = pe.program_library_id
        WHERE pe.status = 'active'
          AND pl.program_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM scheduled_sessions ss
              WHERE ss.enrollment_id = pe.id
          )
    LOOP
        SELECT schedule_enrollment_workouts(
            v_enrollment.id,
            COALESCE(v_enrollment.started_at::DATE, CURRENT_DATE)
        ) INTO v_count;

        v_total := v_total + v_count;
    END LOOP;

    RAISE NOTICE 'Backfilled % total scheduled sessions for existing enrollments', v_total;
END $$;

-- ============================================================================
-- Summary
-- ============================================================================

DO $$
DECLARE
    v_scheduled_count INT;
BEGIN
    SELECT COUNT(*) INTO v_scheduled_count
    FROM scheduled_sessions
    WHERE enrollment_id IS NOT NULL;

    RAISE NOTICE 'Total scheduled sessions from enrollments: %', v_scheduled_count;
END $$;
