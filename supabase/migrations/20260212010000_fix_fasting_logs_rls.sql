-- ============================================================================
-- BUILD 483: FIX FASTING_LOGS RLS FOR DEMO PATIENT
-- ============================================================================
-- Problem: "permission denied for table fasting_logs" (code 42501)
-- Root cause: RLS policies don't allow demo patient (UUID all-zeros) to insert
-- Solution: Add proper policies that include demo patient access
-- ============================================================================

-- ============================================================================
-- STEP 1: Ensure RLS is enabled
-- ============================================================================
ALTER TABLE fasting_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 2: Drop potentially conflicting policies
-- ============================================================================
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'fasting_logs'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON fasting_logs', pol.policyname);
    END LOOP;
END $$;

-- ============================================================================
-- STEP 3: Create comprehensive SELECT policy
-- ============================================================================
-- Allow authenticated users to SELECT fasting logs where:
-- 1. It's for the demo patient (for demo mode)
-- 2. The patient_id matches auth.uid() (for users who are patients)
-- 3. The patient_id belongs to a patient record the user owns

CREATE POLICY "fasting_logs_select_policy"
    ON fasting_logs FOR SELECT
    TO authenticated
    USING (
        -- Case 1: Demo patient data (any authenticated user can read)
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        -- Case 2: Own fasting log via patient_id = auth.uid()
        patient_id = auth.uid()
        OR
        -- Case 3: Own fasting log via patient record lookup
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
            OR email = (auth.jwt() ->> 'email')
        )
        OR
        -- Case 4: Therapist can see their patients' fasting logs
        patient_id IN (
            SELECT id FROM patients
            WHERE therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        )
    );

-- ============================================================================
-- STEP 4: Create INSERT policy
-- ============================================================================
CREATE POLICY "fasting_logs_insert_policy"
    ON fasting_logs FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Case 1: Demo patient (any authenticated user can insert for demo)
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        -- Case 2: Own fasting log
        patient_id = auth.uid()
        OR
        -- Case 3: Own fasting log via patient record
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
            OR email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- STEP 5: Create UPDATE policy
-- ============================================================================
CREATE POLICY "fasting_logs_update_policy"
    ON fasting_logs FOR UPDATE
    TO authenticated
    USING (
        -- Same conditions as SELECT
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        patient_id = auth.uid()
        OR
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
            OR email = (auth.jwt() ->> 'email')
        )
    )
    WITH CHECK (
        -- Same conditions for new row values
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        patient_id = auth.uid()
        OR
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
            OR email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- STEP 6: Create DELETE policy
-- ============================================================================
CREATE POLICY "fasting_logs_delete_policy"
    ON fasting_logs FOR DELETE
    TO authenticated
    USING (
        -- Same conditions as SELECT
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        patient_id = auth.uid()
        OR
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
            OR email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- STEP 7: Grant permissions
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON fasting_logs TO authenticated;

-- ============================================================================
-- STEP 8: Verification
-- ============================================================================
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'fasting_logs';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Fasting Logs RLS Fix Complete - BUILD 483';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Total policies on fasting_logs table: %', policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Policies now allow:';
    RAISE NOTICE '  - Demo patient access for any authenticated user';
    RAISE NOTICE '  - Own fasting log access via patient_id';
    RAISE NOTICE '  - Own fasting log access via patient record lookup';
    RAISE NOTICE '  - Therapist access to patient fasting logs';
    RAISE NOTICE '';
END $$;
