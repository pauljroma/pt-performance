-- ============================================================================
-- BUILD 483: FIX ALL HEALTH HUB TABLES RLS FOR DEMO PATIENT
-- ============================================================================
-- Problem: Multiple Health Hub tables missing demo patient access in RLS
-- Tables affected: recovery_sessions, supplement_logs, patient_supplement_stacks, lab_results
-- Solution: Add proper RLS policies that include demo patient access
-- ============================================================================

-- ============================================================================
-- RECOVERY_SESSIONS TABLE
-- ============================================================================

ALTER TABLE recovery_sessions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'recovery_sessions'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON recovery_sessions', pol.policyname);
    END LOOP;
END $$;

-- SELECT policy
CREATE POLICY "recovery_sessions_select_policy"
    ON recovery_sessions FOR SELECT
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
        OR patient_id IN (
            SELECT id FROM patients
            WHERE therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        )
    );

-- INSERT policy
CREATE POLICY "recovery_sessions_insert_policy"
    ON recovery_sessions FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE policy
CREATE POLICY "recovery_sessions_update_policy"
    ON recovery_sessions FOR UPDATE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    )
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE policy
CREATE POLICY "recovery_sessions_delete_policy"
    ON recovery_sessions FOR DELETE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON recovery_sessions TO authenticated;

-- ============================================================================
-- SUPPLEMENT_LOGS TABLE
-- ============================================================================

ALTER TABLE supplement_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'supplement_logs'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON supplement_logs', pol.policyname);
    END LOOP;
END $$;

-- SELECT policy
CREATE POLICY "supplement_logs_select_policy"
    ON supplement_logs FOR SELECT
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
        OR patient_id IN (
            SELECT id FROM patients
            WHERE therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        )
    );

-- INSERT policy
CREATE POLICY "supplement_logs_insert_policy"
    ON supplement_logs FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE policy
CREATE POLICY "supplement_logs_update_policy"
    ON supplement_logs FOR UPDATE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    )
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE policy
CREATE POLICY "supplement_logs_delete_policy"
    ON supplement_logs FOR DELETE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON supplement_logs TO authenticated;

-- ============================================================================
-- PATIENT_SUPPLEMENT_STACKS TABLE
-- ============================================================================

ALTER TABLE patient_supplement_stacks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'patient_supplement_stacks'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON patient_supplement_stacks', pol.policyname);
    END LOOP;
END $$;

-- SELECT policy
CREATE POLICY "patient_supplement_stacks_select_policy"
    ON patient_supplement_stacks FOR SELECT
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
        OR patient_id IN (
            SELECT id FROM patients
            WHERE therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        )
    );

-- INSERT policy
CREATE POLICY "patient_supplement_stacks_insert_policy"
    ON patient_supplement_stacks FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE policy
CREATE POLICY "patient_supplement_stacks_update_policy"
    ON patient_supplement_stacks FOR UPDATE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    )
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE policy
CREATE POLICY "patient_supplement_stacks_delete_policy"
    ON patient_supplement_stacks FOR DELETE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON patient_supplement_stacks TO authenticated;

-- ============================================================================
-- LAB_RESULTS TABLE
-- ============================================================================

ALTER TABLE lab_results ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'lab_results'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON lab_results', pol.policyname);
    END LOOP;
END $$;

-- SELECT policy
CREATE POLICY "lab_results_select_policy"
    ON lab_results FOR SELECT
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
        OR patient_id IN (
            SELECT id FROM patients
            WHERE therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        )
    );

-- INSERT policy
CREATE POLICY "lab_results_insert_policy"
    ON lab_results FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE policy
CREATE POLICY "lab_results_update_policy"
    ON lab_results FOR UPDATE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    )
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE policy
CREATE POLICY "lab_results_delete_policy"
    ON lab_results FOR DELETE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON lab_results TO authenticated;

-- ============================================================================
-- SUPPLEMENTS (CATALOG) TABLE - READ ONLY FOR ALL
-- ============================================================================

ALTER TABLE supplements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'supplements'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON supplements', pol.policyname);
    END LOOP;
END $$;

-- Everyone can read the supplement catalog
CREATE POLICY "supplements_select_policy"
    ON supplements FOR SELECT
    TO authenticated
    USING (true);

GRANT SELECT ON supplements TO authenticated;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
DECLARE
    table_name TEXT;
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Health Hub Tables RLS Fix Complete - BUILD 483';
    RAISE NOTICE '============================================';

    FOR table_name IN SELECT unnest(ARRAY['fasting_logs', 'recovery_sessions', 'supplement_logs', 'patient_supplement_stacks', 'lab_results', 'supplements'])
    LOOP
        SELECT COUNT(*) INTO policy_count
        FROM pg_policies
        WHERE pg_policies.tablename = table_name;

        RAISE NOTICE 'Table % - % policies', table_name, policy_count;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE 'All tables now allow:';
    RAISE NOTICE '  - Demo patient access (UUID all-zeros)';
    RAISE NOTICE '  - Own data access via patient_id';
    RAISE NOTICE '  - Patient lookup via user_id or email';
    RAISE NOTICE '  - Therapist access to patient data';
    RAISE NOTICE '';
END $$;
