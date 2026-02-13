-- ============================================================================
-- BUILD 484: FIX HEALTH HUB ANON ACCESS FOR DEMO PATIENT
-- ============================================================================
-- Problem: Demo users aren't authenticated (using anon role), but RLS policies
--          only grant access to authenticated users
-- Root cause: When user logs in as demo without real auth, Supabase uses anon role
-- Solution: Add anon role access for demo patient UUID specifically
-- ============================================================================

-- ============================================================================
-- FASTING_LOGS - Add anon access for demo patient ONLY
-- ============================================================================

-- SELECT for anon (demo patient only)
CREATE POLICY "fasting_logs_anon_select_demo"
    ON fasting_logs FOR SELECT
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- INSERT for anon (demo patient only)
CREATE POLICY "fasting_logs_anon_insert_demo"
    ON fasting_logs FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- UPDATE for anon (demo patient only)
CREATE POLICY "fasting_logs_anon_update_demo"
    ON fasting_logs FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- DELETE for anon (demo patient only)
CREATE POLICY "fasting_logs_anon_delete_demo"
    ON fasting_logs FOR DELETE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON fasting_logs TO anon;

-- ============================================================================
-- RECOVERY_SESSIONS - Add anon access for demo patient ONLY
-- ============================================================================

CREATE POLICY "recovery_sessions_anon_select_demo"
    ON recovery_sessions FOR SELECT
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "recovery_sessions_anon_insert_demo"
    ON recovery_sessions FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "recovery_sessions_anon_update_demo"
    ON recovery_sessions FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "recovery_sessions_anon_delete_demo"
    ON recovery_sessions FOR DELETE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON recovery_sessions TO anon;

-- ============================================================================
-- SUPPLEMENT_LOGS - Add anon access for demo patient ONLY
-- ============================================================================

CREATE POLICY "supplement_logs_anon_select_demo"
    ON supplement_logs FOR SELECT
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "supplement_logs_anon_insert_demo"
    ON supplement_logs FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "supplement_logs_anon_update_demo"
    ON supplement_logs FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "supplement_logs_anon_delete_demo"
    ON supplement_logs FOR DELETE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON supplement_logs TO anon;

-- ============================================================================
-- PATIENT_SUPPLEMENT_STACKS - Add anon access for demo patient ONLY
-- ============================================================================

CREATE POLICY "patient_supplement_stacks_anon_select_demo"
    ON patient_supplement_stacks FOR SELECT
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "patient_supplement_stacks_anon_insert_demo"
    ON patient_supplement_stacks FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "patient_supplement_stacks_anon_update_demo"
    ON patient_supplement_stacks FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "patient_supplement_stacks_anon_delete_demo"
    ON patient_supplement_stacks FOR DELETE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON patient_supplement_stacks TO anon;

-- ============================================================================
-- LAB_RESULTS - Add anon access for demo patient ONLY
-- ============================================================================

CREATE POLICY "lab_results_anon_select_demo"
    ON lab_results FOR SELECT
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "lab_results_anon_insert_demo"
    ON lab_results FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "lab_results_anon_update_demo"
    ON lab_results FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "lab_results_anon_delete_demo"
    ON lab_results FOR DELETE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON lab_results TO anon;

-- ============================================================================
-- SUPPLEMENTS (CATALOG) - Anon can read catalog
-- ============================================================================

CREATE POLICY "supplements_anon_select"
    ON supplements FOR SELECT
    TO anon
    USING (true);

GRANT SELECT ON supplements TO anon;

-- ============================================================================
-- WORKOUT_MODIFICATIONS - Add anon access for demo patient ONLY
-- (Fixes the adaptive workout loop issue for demo users)
-- ============================================================================

ALTER TABLE workout_modifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'workout_modifications'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON workout_modifications', pol.policyname);
    END LOOP;
END $$;

-- Authenticated policies
CREATE POLICY "workout_modifications_select_policy"
    ON workout_modifications FOR SELECT
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

CREATE POLICY "workout_modifications_insert_policy"
    ON workout_modifications FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

CREATE POLICY "workout_modifications_update_policy"
    ON workout_modifications FOR UPDATE
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

CREATE POLICY "workout_modifications_delete_policy"
    ON workout_modifications FOR DELETE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id = auth.uid()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid() OR email = (auth.jwt() ->> 'email')
        )
    );

-- Anon policies (demo patient only)
CREATE POLICY "workout_modifications_anon_select_demo"
    ON workout_modifications FOR SELECT
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "workout_modifications_anon_insert_demo"
    ON workout_modifications FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "workout_modifications_anon_update_demo"
    ON workout_modifications FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "workout_modifications_anon_delete_demo"
    ON workout_modifications FOR DELETE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON workout_modifications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON workout_modifications TO anon;

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
    RAISE NOTICE 'Health Hub ANON Access Fix - BUILD 484';
    RAISE NOTICE '============================================';

    FOR table_name IN SELECT unnest(ARRAY[
        'fasting_logs', 'recovery_sessions', 'supplement_logs',
        'patient_supplement_stacks', 'lab_results', 'supplements',
        'workout_modifications'
    ])
    LOOP
        SELECT COUNT(*) INTO policy_count
        FROM pg_policies
        WHERE pg_policies.tablename = table_name;

        RAISE NOTICE 'Table % - % policies', table_name, policy_count;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE 'Demo patient (anon role) now has access to all Health Hub tables';
    RAISE NOTICE '';
END $$;
