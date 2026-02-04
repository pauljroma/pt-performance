-- BUILD 404: Fix demo patient RLS access
-- Problem: Demo patient (00000000-0000-0000-0000-000000000001) user_id doesn't match auth.uid()
-- Solution: Add explicit demo patient policies to allow any authenticated user access

-- ============================================================================
-- STEP 1: Add demo patient read access to patients table
-- ============================================================================
-- This allows the subquery in daily_readiness RLS to return the demo patient row

DROP POLICY IF EXISTS "demo_patient_read_access" ON patients;

CREATE POLICY "demo_patient_read_access"
    ON patients FOR SELECT
    TO authenticated
    USING (id = '00000000-0000-0000-0000-000000000001'::uuid);

-- ============================================================================
-- STEP 2: Add demo patient access to daily_readiness table
-- ============================================================================

DROP POLICY IF EXISTS "demo_patient_readiness_access" ON daily_readiness;

CREATE POLICY "demo_patient_readiness_access"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- ============================================================================
-- STEP 3: Also add to arm_care_assessments for demo patient
-- ============================================================================

DROP POLICY IF EXISTS "demo_patient_arm_care_access" ON arm_care_assessments;

CREATE POLICY "demo_patient_arm_care_access"
    ON arm_care_assessments FOR ALL
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

COMMENT ON POLICY "demo_patient_read_access" ON patients IS 'BUILD 404: Allow any authenticated user to read demo patient';
COMMENT ON POLICY "demo_patient_readiness_access" ON daily_readiness IS 'BUILD 404: Allow any authenticated user to manage demo patient readiness';
