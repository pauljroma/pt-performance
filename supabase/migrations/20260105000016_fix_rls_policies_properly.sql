-- Fix RLS policies properly for daily_readiness - BUILD 116
-- Handle both patient and therapist access patterns correctly

-- Re-enable RLS (was disabled in 20260105000015)
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Authenticated users can insert readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can insert their own readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can insert readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can view their own readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can view all readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can update their own readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can update readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can delete their own readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can delete readiness data" ON daily_readiness;

-- ============================================================
-- INSERT Policies
-- ============================================================

-- Policy 1: Patients can insert their own readiness data
CREATE POLICY "Patients can insert own readiness"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = auth.uid()
    );

-- Policy 2: Therapists can insert readiness data for any patient
CREATE POLICY "Therapists can insert any readiness"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (
        is_therapist()
    );

-- ============================================================
-- SELECT Policies
-- ============================================================

-- Policy 3: Patients can view their own readiness data
CREATE POLICY "Patients can view own readiness"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (
        patient_id = auth.uid()
    );

-- Policy 4: Therapists can view all readiness data
CREATE POLICY "Therapists can view all readiness"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (
        is_therapist()
    );

-- ============================================================
-- UPDATE Policies
-- ============================================================

-- Policy 5: Patients can update their own readiness data
CREATE POLICY "Patients can update own readiness"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Policy 6: Therapists can update any readiness data
CREATE POLICY "Therapists can update any readiness"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (is_therapist())
    WITH CHECK (is_therapist());

-- ============================================================
-- DELETE Policies
-- ============================================================

-- Policy 7: Patients can delete their own readiness data
CREATE POLICY "Patients can delete own readiness"
    ON daily_readiness FOR DELETE
    TO authenticated
    USING (patient_id = auth.uid());

-- Policy 8: Therapists can delete any readiness data
CREATE POLICY "Therapists can delete any readiness"
    ON daily_readiness FOR DELETE
    TO authenticated
    USING (is_therapist());

-- ============================================================
-- Comments
-- ============================================================

COMMENT ON TABLE daily_readiness IS 'BUILD 116 - Daily readiness check-ins with proper RLS policies for patients and therapists';
