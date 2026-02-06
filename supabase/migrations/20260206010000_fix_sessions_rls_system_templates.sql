-- Fix: Allow access to system template sessions via enrolled programs
-- Build 442 - Users can view sessions from programs they're enrolled in
--
-- Problem: sessions table RLS blocks access to system template sessions (patient_id = NULL)
-- Solution: Add policy allowing access to sessions via enrollment

-- ============================================================================
-- Drop existing restrictive policies
-- ============================================================================

-- Keep existing policies but add new ones for enrollment-based access

-- ============================================================================
-- Add policy for enrolled program sessions
-- ============================================================================

-- Users can view sessions from programs they're enrolled in
CREATE POLICY "Patients can view enrolled program sessions"
    ON sessions FOR SELECT
    USING (
        -- Session belongs to a program the user is enrolled in
        EXISTS (
            SELECT 1
            FROM phases p
            JOIN programs prog ON prog.id = p.program_id
            JOIN program_library pl ON pl.program_id = prog.id
            JOIN program_enrollments pe ON pe.program_library_id = pl.id
            JOIN patients pat ON pat.id = pe.patient_id
            WHERE p.id = sessions.phase_id
              AND pe.status = 'active'
              AND (pat.user_id = auth.uid() OR pat.email = (auth.jwt() ->> 'email'))
        )
        OR
        -- Session directly belongs to user's program (existing behavior)
        EXISTS (
            SELECT 1
            FROM phases p
            JOIN programs prog ON prog.id = p.program_id
            JOIN patients pat ON pat.id = prog.patient_id
            WHERE p.id = sessions.phase_id
              AND (pat.user_id = auth.uid() OR pat.email = (auth.jwt() ->> 'email'))
        )
    );

-- ============================================================================
-- Also update exercise_logs RLS to work with enrolled programs
-- ============================================================================

-- Drop existing exercise_logs policy if too restrictive
DROP POLICY IF EXISTS "Patients can view exercise logs for enrolled sessions" ON exercise_logs;

-- Users can view exercise logs from sessions they have access to
CREATE POLICY "Patients can view exercise logs for enrolled sessions"
    ON exercise_logs FOR SELECT
    USING (
        -- Direct ownership
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
        OR
        -- Via session they can access
        EXISTS (
            SELECT 1
            FROM sessions s
            JOIN phases p ON p.id = s.phase_id
            JOIN programs prog ON prog.id = p.program_id
            JOIN program_library pl ON pl.program_id = prog.id
            JOIN program_enrollments pe ON pe.program_library_id = pl.id
            JOIN patients pat ON pat.id = pe.patient_id
            WHERE s.id = exercise_logs.session_id
              AND pe.status = 'active'
              AND (pat.user_id = auth.uid() OR pat.email = (auth.jwt() ->> 'email'))
        )
    );

-- ============================================================================
-- Fix scheduled_sessions RLS for enrolled programs
-- ============================================================================

DROP POLICY IF EXISTS "Patients can view enrolled scheduled sessions" ON scheduled_sessions;

CREATE POLICY "Patients can view enrolled scheduled sessions"
    ON scheduled_sessions FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- Verify the fix
-- ============================================================================

DO $$
DECLARE
    v_policy_count INT;
BEGIN
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE tablename = 'sessions'
      AND policyname LIKE '%enrolled%';

    RAISE NOTICE 'Sessions policies for enrolled access: %', v_policy_count;

    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE tablename = 'scheduled_sessions';

    RAISE NOTICE 'Total scheduled_sessions policies: %', v_policy_count;
END $$;
