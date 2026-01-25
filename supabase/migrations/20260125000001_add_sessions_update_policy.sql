-- ============================================================================
-- ADD UPDATE POLICY FOR PATIENTS ON SESSIONS TABLE
-- ============================================================================
-- BUILD 277: Fix prescribed session completion
--
-- Issue: Patients cannot mark prescribed sessions as completed because
-- the sessions table only has SELECT policies, not UPDATE policies.
--
-- This migration adds an UPDATE policy so patients can:
-- - Mark their sessions as completed
-- - Update completion metrics (volume, RPE, pain, duration)
-- ============================================================================

-- Drop existing UPDATE policy if any
DROP POLICY IF EXISTS patients_update_own_sessions ON sessions;

-- Allow patients to UPDATE sessions in their programs
-- Uses same pattern as patients_see_own_sessions SELECT policy
CREATE POLICY patients_update_own_sessions ON sessions
  FOR UPDATE
  USING (
    phase_id IN (
      SELECT ph.id FROM phases ph
      INNER JOIN programs pr ON ph.program_id = pr.id
      WHERE pr.patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    phase_id IN (
      SELECT ph.id FROM phases ph
      INNER JOIN programs pr ON ph.program_id = pr.id
      WHERE pr.patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
      )
    )
  );

COMMENT ON POLICY patients_update_own_sessions ON sessions IS
  'Allows patients to update sessions (mark complete, add metrics) for their own programs';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'BUILD 277: SESSIONS UPDATE POLICY ADDED';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'ADDED POLICY:';
  RAISE NOTICE '  patients_update_own_sessions ON sessions FOR UPDATE';
  RAISE NOTICE '';
  RAISE NOTICE 'ALLOWS:';
  RAISE NOTICE '  - Patients can mark sessions as completed';
  RAISE NOTICE '  - Patients can update completion metrics';
  RAISE NOTICE '  - Only for sessions in their own programs';
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
END $$;
