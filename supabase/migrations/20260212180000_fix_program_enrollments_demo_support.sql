-- ============================================================================
-- FIX PROGRAM_ENROLLMENTS RLS FOR DEMO MODE
-- ============================================================================
-- Problem: Demo patient can't enroll in programs because RLS requires auth.uid()
-- Solution: Add demo patient support to program_enrollments policies
-- Demo Patient ID: 00000000-0000-0000-0000-000000000001
-- ============================================================================

-- ============================================================================
-- STEP 1: Drop existing policies
-- ============================================================================

DROP POLICY IF EXISTS "Patients can view own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can insert own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can update own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can delete own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Allow authenticated users to enroll" ON program_enrollments;

-- Also drop any anon policies if they exist
DROP POLICY IF EXISTS "program_enrollments_anon_select" ON program_enrollments;
DROP POLICY IF EXISTS "program_enrollments_anon_insert" ON program_enrollments;
DROP POLICY IF EXISTS "program_enrollments_anon_update" ON program_enrollments;
DROP POLICY IF EXISTS "program_enrollments_anon_delete" ON program_enrollments;

-- ============================================================================
-- STEP 2: Create ANON policies (for demo mode)
-- Demo mode uses anon key, queries by patient id directly
-- ============================================================================

CREATE POLICY "program_enrollments_anon_select"
    ON program_enrollments FOR SELECT
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "program_enrollments_anon_insert"
    ON program_enrollments FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "program_enrollments_anon_update"
    ON program_enrollments FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "program_enrollments_anon_delete"
    ON program_enrollments FOR DELETE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- ============================================================================
-- STEP 3: Create AUTHENTICATED policies
-- Authenticated users access via user_id/email match OR demo patient
-- ============================================================================

CREATE POLICY "program_enrollments_auth_select"
    ON program_enrollments FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
        OR patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

CREATE POLICY "program_enrollments_auth_insert"
    ON program_enrollments FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
        OR patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

CREATE POLICY "program_enrollments_auth_update"
    ON program_enrollments FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
        OR patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    )
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
        OR patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

CREATE POLICY "program_enrollments_auth_delete"
    ON program_enrollments FOR DELETE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
        OR patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- ============================================================================
-- STEP 4: Grant permissions
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON program_enrollments TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON program_enrollments TO authenticated;

-- ============================================================================
-- STEP 5: Force schema reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    policy_count INT;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'program_enrollments';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'program_enrollments RLS Updated for Demo';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Policies on program_enrollments: %', policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'ANON can access demo patient enrollments';
    RAISE NOTICE 'AUTHENTICATED can access by auth or demo patient';
    RAISE NOTICE '============================================';
END $$;
