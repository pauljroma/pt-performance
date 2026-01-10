-- BUILD 118: Restore Proper RLS Policies
-- Replace debug policies with production-ready patient/therapist separation

-- ============================================================================
-- DROP DEBUG POLICIES (from BUILD 117)
-- ============================================================================

DROP POLICY IF EXISTS "Debug: Allow all authenticated inserts" ON daily_readiness;
DROP POLICY IF EXISTS "Debug: Allow all authenticated selects" ON daily_readiness;
DROP POLICY IF EXISTS "Debug: Allow all authenticated updates" ON daily_readiness;
DROP POLICY IF EXISTS "Debug: Allow all authenticated deletes" ON daily_readiness;

-- ============================================================================
-- PATIENT POLICIES - Own Data Only
-- ============================================================================

-- Patients can insert their own readiness data
CREATE POLICY "Patients can insert own readiness"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (patient_id = auth.uid());

-- Patients can view their own readiness data
CREATE POLICY "Patients can view own readiness"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (patient_id = auth.uid());

-- Patients can update their own readiness data
CREATE POLICY "Patients can update own readiness"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Patients can delete their own readiness data
CREATE POLICY "Patients can delete own readiness"
    ON daily_readiness FOR DELETE
    TO authenticated
    USING (patient_id = auth.uid());

-- ============================================================================
-- THERAPIST POLICIES - All Patient Data Access
-- ============================================================================

-- Therapists can insert readiness data for any patient
CREATE POLICY "Therapists can insert any readiness"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (is_therapist());

-- Therapists can view all patient readiness data
CREATE POLICY "Therapists can view all readiness"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (is_therapist());

-- Therapists can update any patient readiness data
CREATE POLICY "Therapists can update any readiness"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (is_therapist())
    WITH CHECK (is_therapist());

-- Therapists can delete any patient readiness data
CREATE POLICY "Therapists can delete any readiness"
    ON daily_readiness FOR DELETE
    TO authenticated
    USING (is_therapist());

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Ensure is_therapist() function exists (created in migration 20260105000012)
DO $check$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'is_therapist'
    ) THEN
        RAISE EXCEPTION 'is_therapist() function not found. Run migration 20260105000012 first.';
    END IF;
END $check$;

-- Add helpful comment
COMMENT ON TABLE daily_readiness IS
'BUILD 118 - Production RLS policies active. Patients: own data only. Therapists: all patient data.';

-- ============================================================================
-- ROLLBACK PLAN
-- ============================================================================

-- To rollback to debug mode (if needed), run:
-- DROP POLICY "Patients can insert own readiness" ON daily_readiness;
-- DROP POLICY "Patients can view own readiness" ON daily_readiness;
-- DROP POLICY "Patients can update own readiness" ON daily_readiness;
-- DROP POLICY "Patients can delete own readiness" ON daily_readiness;
-- DROP POLICY "Therapists can insert any readiness" ON daily_readiness;
-- DROP POLICY "Therapists can view all readiness" ON daily_readiness;
-- DROP POLICY "Therapists can update any readiness" ON daily_readiness;
-- DROP POLICY "Therapists can delete any readiness" ON daily_readiness;
--
-- Then re-run migration 20260105000017_debug_rls_issue.sql
