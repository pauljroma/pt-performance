-- ============================================================================
-- FIX BUILD 11: Create Views for Patient Detail Data
-- ============================================================================
-- The iOS app expects tables/columns that don't match the actual schema:
-- 1. App queries "patient_flags" but DB has "pain_flags"
-- 2. App queries "sessions.patient_id" but sessions only has "phase_id"
-- 3. App expects "sessions.session_number" but that column doesn't exist
--
-- Solution: Create views that match what the iOS app expects
-- Date: 2025-12-11
-- ============================================================================

-- ============================================================================
-- 1. CREATE VIEW: patient_flags (alias for pain_flags)
-- ============================================================================
-- iOS app queries "patient_flags" but our table is called "pain_flags"
-- Create a view to bridge the naming gap

CREATE OR REPLACE VIEW patient_flags AS
SELECT
    id,
    patient_id,
    flag_type,
    severity,
    notes AS description,
    triggered_at AS created_at,
    resolved_at,
    false AS auto_created
FROM pain_flags;

-- Add RLS policy for therapists to see patient flags
ALTER VIEW patient_flags SET (security_invoker = true);

COMMENT ON VIEW patient_flags IS 'View that aliases pain_flags for iOS app compatibility';

-- ============================================================================
-- 2. CREATE VIEW: vw_patient_sessions
-- ============================================================================
-- iOS app queries sessions with patient_id, but sessions table has phase_id
-- Need to join through: patient → programs → phases → sessions
-- Also add session_number as the sequence within the phase

CREATE OR REPLACE VIEW vw_patient_sessions AS
SELECT
    s.id,
    s.name,
    s.sequence AS session_number,  -- Map sequence to session_number
    prog.patient_id,                -- Add patient_id from program
    s.phase_id,
    ph.program_id,
    s.weekday,
    s.notes,
    s.created_at,
    s.intensity_rating,
    s.is_throwing_day,
    -- Calculated fields
    NULL::date AS session_date,     -- Will be calculated based on program start + phase sequence
    false AS completed,             -- TODO: Link to session_logs when that table is created
    0 AS exercise_count            -- TODO: Count from session_exercises
FROM sessions s
INNER JOIN phases ph ON s.phase_id = ph.id
INNER JOIN programs prog ON ph.program_id = prog.id;

-- Add RLS policy for therapists to see sessions for their patients
ALTER VIEW vw_patient_sessions SET (security_invoker = true);

COMMENT ON VIEW vw_patient_sessions IS 'Sessions joined with patient_id for iOS app compatibility';

-- ============================================================================
-- 3. ADD RLS POLICIES FOR THERAPIST ACCESS
-- ============================================================================

-- Policy: Therapists can see flags for their assigned patients
CREATE POLICY therapists_see_patient_flags ON pain_flags
  FOR SELECT
  USING (
    patient_id IN (
      SELECT id FROM patients WHERE therapist_id IN (
        SELECT id FROM therapists WHERE user_id = auth.uid()
      )
    )
  );

-- Note: RLS on views works through security_invoker = true setting above
-- The view inherits the RLS policies from the underlying tables

-- ============================================================================
-- 4. ADD RLS POLICIES FOR SESSIONS ACCESS
-- ============================================================================

-- Policy: Therapists can see sessions for their assigned patients
CREATE POLICY therapists_see_sessions ON sessions
  FOR SELECT
  USING (
    phase_id IN (
      SELECT ph.id FROM phases ph
      INNER JOIN programs prog ON ph.program_id = prog.id
      WHERE prog.patient_id IN (
        SELECT id FROM patients WHERE therapist_id IN (
          SELECT id FROM therapists WHERE user_id = auth.uid()
        )
      )
    )
  );

-- Policy: Therapists can see phases for their patients' programs
CREATE POLICY therapists_see_phases ON phases
  FOR SELECT
  USING (
    program_id IN (
      SELECT id FROM programs WHERE patient_id IN (
        SELECT id FROM patients WHERE therapist_id IN (
          SELECT id FROM therapists WHERE user_id = auth.uid()
        )
      )
    )
  );

-- Policy: Therapists can see programs for their assigned patients
CREATE POLICY therapists_see_programs ON programs
  FOR SELECT
  USING (
    patient_id IN (
      SELECT id FROM patients WHERE therapist_id IN (
        SELECT id FROM therapists WHERE user_id = auth.uid()
      )
    )
  );

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'PATIENT DETAIL SCHEMA FIXES APPLIED';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Created views:';
  RAISE NOTICE '  1. patient_flags - Aliases pain_flags for iOS compatibility';
  RAISE NOTICE '  2. vw_patient_sessions - Sessions with patient_id join';
  RAISE NOTICE '';
  RAISE NOTICE 'Created RLS policies:';
  RAISE NOTICE '  1. therapists_see_patient_flags - Access to patient flags';
  RAISE NOTICE '  2. therapists_see_sessions - Access to sessions';
  RAISE NOTICE '  3. therapists_see_phases - Access to phases';
  RAISE NOTICE '  4. therapists_see_programs - Access to programs';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Patient detail view should now work in iOS app!';
  RAISE NOTICE '========================================================================';
END $$;
