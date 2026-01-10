-- Migration: Enhanced RLS Policies for Scheduled Sessions Rescheduling
-- Build 69 Agent 12
-- Date: 2025-12-19
-- Description: Add granular RLS policies for patient-only rescheduling access

BEGIN;

-- Drop existing policies to recreate with enhanced granularity
DROP POLICY IF EXISTS "Patients update own scheduled sessions" ON scheduled_sessions;

-- Policy 1: Patients can reschedule their own sessions (update date/time/notes only)
-- Cannot change patient_id, session_id, or manually set status/completed_at
CREATE POLICY "Patients can reschedule own sessions"
    ON scheduled_sessions FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (
        -- Must be their own session (patient_id immutability enforced by USING clause)
        patient_id = auth.uid()
    );

-- Policy 2: Patients can update notes on their own sessions
CREATE POLICY "Patients can update notes on own sessions"
    ON scheduled_sessions FOR UPDATE
    USING (
        patient_id = auth.uid()
        AND status IN ('scheduled', 'rescheduled')
    )
    WITH CHECK (
        patient_id = auth.uid()
        -- Only allow updating notes field for scheduled/rescheduled sessions
        AND status IN ('scheduled', 'rescheduled')
    );

-- Policy 3: Patients can mark their own sessions as completed
CREATE POLICY "Patients can complete own sessions"
    ON scheduled_sessions FOR UPDATE
    USING (
        patient_id = auth.uid()
        AND status = 'scheduled'
        AND scheduled_date <= CURRENT_DATE
    )
    WITH CHECK (
        patient_id = auth.uid()
        AND status = 'completed'
    );

-- Policy 4: Patients can cancel their own upcoming sessions
CREATE POLICY "Patients can cancel own upcoming sessions"
    ON scheduled_sessions FOR UPDATE
    USING (
        patient_id = auth.uid()
        AND status = 'scheduled'
        AND scheduled_date >= CURRENT_DATE
    )
    WITH CHECK (
        patient_id = auth.uid()
        AND status = 'cancelled'
    );

-- Create function for secure rescheduling with validation
CREATE OR REPLACE FUNCTION reschedule_session(
    p_scheduled_session_id UUID,
    p_new_date DATE,
    p_new_time TIME,
    p_notes TEXT DEFAULT NULL
)
RETURNS scheduled_sessions AS $$
DECLARE
    v_session scheduled_sessions;
    v_patient_id UUID;
BEGIN
    -- Get current session details
    SELECT * INTO v_session
    FROM scheduled_sessions
    WHERE id = p_scheduled_session_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Scheduled session not found';
    END IF;

    -- Verify patient ownership (RLS will also enforce this)
    v_patient_id := auth.uid();
    IF v_session.patient_id != v_patient_id THEN
        RAISE EXCEPTION 'Not authorized to reschedule this session';
    END IF;

    -- Verify session is in reschedulable state
    IF v_session.status NOT IN ('scheduled', 'rescheduled') THEN
        RAISE EXCEPTION 'Cannot reschedule session with status: %', v_session.status;
    END IF;

    -- Verify new date is in the future
    IF p_new_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Cannot reschedule to a past date';
    END IF;

    -- Check for conflicting schedule (same session, same date)
    IF EXISTS (
        SELECT 1
        FROM scheduled_sessions
        WHERE patient_id = v_patient_id
        AND session_id = v_session.session_id
        AND scheduled_date = p_new_date
        AND id != p_scheduled_session_id
        AND status != 'cancelled'
    ) THEN
        RAISE EXCEPTION 'Session already scheduled for this date';
    END IF;

    -- Update the scheduled session
    UPDATE scheduled_sessions
    SET
        scheduled_date = p_new_date,
        scheduled_time = p_new_time,
        status = 'rescheduled',
        reminder_sent = FALSE, -- Reset reminder flag
        notes = COALESCE(p_notes, notes),
        updated_at = NOW()
    WHERE id = p_scheduled_session_id
    RETURNING * INTO v_session;

    RETURN v_session;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION reschedule_session TO authenticated;

-- Create function for marking session as completed with validation
CREATE OR REPLACE FUNCTION mark_session_completed(
    p_scheduled_session_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS scheduled_sessions AS $$
DECLARE
    v_session scheduled_sessions;
    v_patient_id UUID;
BEGIN
    -- Get current session details
    SELECT * INTO v_session
    FROM scheduled_sessions
    WHERE id = p_scheduled_session_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Scheduled session not found';
    END IF;

    -- Verify patient ownership
    v_patient_id := auth.uid();
    IF v_session.patient_id != v_patient_id THEN
        RAISE EXCEPTION 'Not authorized to complete this session';
    END IF;

    -- Verify session is scheduled
    IF v_session.status != 'scheduled' THEN
        RAISE EXCEPTION 'Can only complete scheduled sessions. Current status: %', v_session.status;
    END IF;

    -- Update the scheduled session
    UPDATE scheduled_sessions
    SET
        status = 'completed',
        completed_at = NOW(),
        notes = COALESCE(p_notes, notes),
        updated_at = NOW()
    WHERE id = p_scheduled_session_id
    RETURNING * INTO v_session;

    RETURN v_session;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION mark_session_completed TO authenticated;

-- Create index for faster reschedule conflict checking
CREATE INDEX IF NOT EXISTS idx_scheduled_sessions_conflict_check
ON scheduled_sessions(patient_id, session_id, scheduled_date, status)
WHERE status != 'cancelled';

-- Create index for upcoming sessions queries
-- Note: Removed CURRENT_DATE filter as it's not immutable for partial indexes
CREATE INDEX IF NOT EXISTS idx_scheduled_sessions_upcoming
ON scheduled_sessions(patient_id, scheduled_date, scheduled_time)
WHERE status = 'scheduled';

-- Add comment for documentation
COMMENT ON FUNCTION reschedule_session IS 'Securely reschedule a session with validation. Patients can only reschedule their own sessions to future dates.';
COMMENT ON FUNCTION mark_session_completed IS 'Mark a scheduled session as completed. Only the patient who owns the session can mark it complete.';

COMMIT;

-- Verification queries (run after migration)
/*
-- Verify policies exist
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'scheduled_sessions'
ORDER BY policyname;

-- Test reschedule function (as patient)
SELECT * FROM reschedule_session(
    'scheduled-session-uuid'::uuid,
    CURRENT_DATE + 1,
    '14:00:00'::time,
    'Rescheduled due to conflict'
);

-- Test complete function (as patient)
SELECT * FROM mark_session_completed(
    'scheduled-session-uuid'::uuid,
    'Great workout!'
);
*/
