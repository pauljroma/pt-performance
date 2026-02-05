-- Fix RLS policies for recovery_sessions table
-- The policies were incorrectly checking patient_id = auth.uid()
-- But patient_id is the patient's table ID, not the auth user's ID
-- We need to verify ownership through the patients table
--
-- Example of the mismatch:
--   patient_id in recovery_sessions = '743bbbd4-...' (patients.id)
--   auth.uid() = 'bc867b4a-...' (auth.users.id)
-- These are different UUIDs! We need to join through patients table.

-- Drop existing incorrect policies
DROP POLICY IF EXISTS "Patients view own recovery sessions" ON recovery_sessions;
DROP POLICY IF EXISTS "Patients insert own recovery sessions" ON recovery_sessions;
DROP POLICY IF EXISTS "Patients update own recovery sessions" ON recovery_sessions;
DROP POLICY IF EXISTS "Patients delete own recovery sessions" ON recovery_sessions;

-- Create corrected policies that check ownership through patients table
CREATE POLICY "Patients view own recovery sessions" ON recovery_sessions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = recovery_sessions.patient_id
            AND patients.user_id = auth.uid()
        )
    );

CREATE POLICY "Patients insert own recovery sessions" ON recovery_sessions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = recovery_sessions.patient_id
            AND patients.user_id = auth.uid()
        )
    );

CREATE POLICY "Patients update own recovery sessions" ON recovery_sessions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = recovery_sessions.patient_id
            AND patients.user_id = auth.uid()
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = recovery_sessions.patient_id
            AND patients.user_id = auth.uid()
        )
    );

CREATE POLICY "Patients delete own recovery sessions" ON recovery_sessions
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = recovery_sessions.patient_id
            AND patients.user_id = auth.uid()
        )
    );

-- Verify RLS is enabled
ALTER TABLE recovery_sessions ENABLE ROW LEVEL SECURITY;

-- Add comment documenting the fix
COMMENT ON TABLE recovery_sessions IS 'Build 437+ - Fixed RLS to check patients.user_id = auth.uid()';
