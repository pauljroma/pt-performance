-- 009_fix_rls_policies.sql
-- Fix missing RLS policies for patient data access
-- Critical: Patients cannot view their data without these policies
-- Date: 2025-12-09
-- Issue: Build 8 fails with "data could not be read because it doesn't exist"

-- ============================================================================
-- 1. ADD MISSING user_id COLUMN TO PATIENTS TABLE
-- ============================================================================

ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_patients_user_id
  ON patients(user_id);

COMMENT ON COLUMN patients.user_id IS
  'Links patient record to Supabase auth.users for authentication. Required for RLS policies.';

-- ============================================================================
-- 2. PATIENT READ POLICIES FOR HIERARCHICAL TABLES
-- ============================================================================

-- Phases (child of programs)
CREATE POLICY patients_see_own_phases ON phases
  FOR SELECT USING (
    program_id IN (
      SELECT id FROM programs WHERE patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
      )
    )
  );

-- Sessions (child of phases)
CREATE POLICY patients_see_own_sessions ON sessions
  FOR SELECT USING (
    phase_id IN (
      SELECT id FROM phases WHERE program_id IN (
        SELECT id FROM programs WHERE patient_id IN (
          SELECT id FROM patients WHERE user_id = auth.uid()
        )
      )
    )
  );

-- Session Exercises (child of sessions)
CREATE POLICY patients_see_own_session_exercises ON session_exercises
  FOR SELECT USING (
    session_id IN (
      SELECT id FROM sessions WHERE phase_id IN (
        SELECT id FROM phases WHERE program_id IN (
          SELECT id FROM programs WHERE patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
          )
        )
      )
    )
  );

-- ============================================================================
-- 3. PATIENT READ POLICIES FOR DIRECT patient_id REFERENCES
-- ============================================================================

-- Exercise Logs
CREATE POLICY patients_see_own_exercise_logs ON exercise_logs
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  );

-- Pain Logs
CREATE POLICY patients_see_own_pain_logs ON pain_logs
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  );

-- Bullpen Logs
CREATE POLICY patients_see_own_bullpen_logs ON bullpen_logs
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  );

-- Plyo Logs
CREATE POLICY patients_see_own_plyo_logs ON plyo_logs
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  );

-- Session Notes
CREATE POLICY patients_see_own_session_notes ON session_notes
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  );

-- Body Comp Measurements
CREATE POLICY patients_see_own_body_comp ON body_comp_measurements
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  );

-- Session Status
CREATE POLICY patients_see_own_session_status ON session_status
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  );

-- Pain Flags
CREATE POLICY patients_see_own_pain_flags ON pain_flags
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  );

-- ============================================================================
-- 4. THERAPIST READ POLICIES (MIRROR PATTERN)
-- ============================================================================

-- Phases
CREATE POLICY therapists_see_patient_phases ON phases
  FOR SELECT USING (
    program_id IN (
      SELECT id FROM programs WHERE patient_id IN (
        SELECT id FROM patients WHERE therapist_id IN (
          SELECT id FROM therapists WHERE user_id = auth.uid()
        )
      )
    )
  );

-- Sessions
CREATE POLICY therapists_see_patient_sessions ON sessions
  FOR SELECT USING (
    phase_id IN (
      SELECT id FROM phases WHERE program_id IN (
        SELECT id FROM programs WHERE patient_id IN (
          SELECT id FROM patients WHERE therapist_id IN (
            SELECT id FROM therapists WHERE user_id = auth.uid()
          )
        )
      )
    )
  );

-- Session Exercises
CREATE POLICY therapists_see_patient_session_exercises ON session_exercises
  FOR SELECT USING (
    session_id IN (
      SELECT id FROM sessions WHERE phase_id IN (
        SELECT id FROM phases WHERE program_id IN (
          SELECT id FROM programs WHERE patient_id IN (
            SELECT id FROM patients WHERE therapist_id IN (
              SELECT id FROM therapists WHERE user_id = auth.uid()
            )
          )
        )
      )
    )
  );

-- Exercise Logs
CREATE POLICY therapists_see_patient_exercise_logs ON exercise_logs
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE therapist_id IN (
        SELECT id FROM therapists WHERE user_id = auth.uid()
      )
    )
  );

-- Pain Logs
CREATE POLICY therapists_see_patient_pain_logs ON pain_logs
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE therapist_id IN (
        SELECT id FROM therapists WHERE user_id = auth.uid()
      )
    )
  );

-- Bullpen Logs
CREATE POLICY therapists_see_patient_bullpen_logs ON bullpen_logs
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE therapist_id IN (
        SELECT id FROM therapists WHERE user_id = auth.uid()
      )
    )
  );

-- Plyo Logs
CREATE POLICY therapists_see_patient_plyo_logs ON plyo_logs
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE therapist_id IN (
        SELECT id FROM therapists WHERE user_id = auth.uid()
      )
    )
  );

-- Session Notes
CREATE POLICY therapists_see_patient_session_notes ON session_notes
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE therapist_id IN (
        SELECT id FROM therapists WHERE user_id = auth.uid()
      )
    )
  );

-- Body Comp
CREATE POLICY therapists_see_patient_body_comp ON body_comp_measurements
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE therapist_id IN (
        SELECT id FROM therapists WHERE user_id = auth.uid()
      )
    )
  );

-- Session Status
CREATE POLICY therapists_see_patient_session_status ON session_status
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE therapist_id IN (
        SELECT id FROM therapists WHERE user_id = auth.uid()
      )
    )
  );

-- Pain Flags
CREATE POLICY therapists_see_patient_pain_flags ON pain_flags
  FOR SELECT USING (
    patient_id IN (
      SELECT id FROM patients WHERE therapist_id IN (
        SELECT id FROM therapists WHERE user_id = auth.uid()
      )
    )
  );

-- ============================================================================
-- 5. VERIFICATION
-- ============================================================================

-- Count policies per table
SELECT
  schemaname,
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'patients', 'programs', 'phases', 'sessions', 'session_exercises',
    'exercise_logs', 'pain_logs', 'bullpen_logs', 'plyo_logs',
    'session_notes', 'body_comp_measurements', 'session_status', 'pain_flags'
  )
GROUP BY schemaname, tablename
ORDER BY tablename;

-- Show all patient-facing policies
SELECT
  tablename,
  policyname,
  cmd as operation
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname LIKE 'patients_%'
ORDER BY tablename, policyname;
