-- ============================================================================
-- Fix supplement RLS: stops cross-user data leakage and fixes save failures
--
-- Problems fixed:
-- 1. SELECT policy included `patient_id = '00000000-0000-0000-0000-000000000001'`
--    allowing ALL authenticated users to see old demo patient's supplement data.
-- 2. INSERT/UPDATE WITH CHECK subquery `SELECT id FROM patients WHERE user_id = auth.uid()`
--    could fail or return nothing due to RLS on the patients table, causing new
--    supplement saves to silently fail.
--
-- Fix:
-- 1. Create a SECURITY DEFINER helper function that bypasses RLS to look up
--    the patient record for the current auth user.
-- 2. Rewrite policies to use this function.
-- 3. Remove the open demo-UUID bypass from authenticated SELECT policies.
-- ============================================================================

-- Helper: returns the patient UUID for the current auth user (bypasses RLS)
CREATE OR REPLACE FUNCTION get_patient_id_for_current_user()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT id
    FROM patients
    WHERE user_id = auth.uid()
    LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION get_patient_id_for_current_user() TO authenticated;

-- ============================================================================
-- PATIENT_SUPPLEMENT_STACKS
-- ============================================================================

ALTER TABLE patient_supplement_stacks ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'patient_supplement_stacks'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON patient_supplement_stacks', pol.policyname);
    END LOOP;
END $$;

-- SELECT: user sees only their own data + therapist can see their patients' data
CREATE POLICY "patient_supplement_stacks_select_policy"
    ON patient_supplement_stacks FOR SELECT
    TO authenticated
    USING (
        patient_id = get_patient_id_for_current_user()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        )
    );

-- INSERT: user can only insert rows for themselves
CREATE POLICY "patient_supplement_stacks_insert_policy"
    ON patient_supplement_stacks FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = get_patient_id_for_current_user()
    );

-- UPDATE: user can only update their own rows
CREATE POLICY "patient_supplement_stacks_update_policy"
    ON patient_supplement_stacks FOR UPDATE
    TO authenticated
    USING (patient_id = get_patient_id_for_current_user())
    WITH CHECK (patient_id = get_patient_id_for_current_user());

-- DELETE: user can only delete their own rows
CREATE POLICY "patient_supplement_stacks_delete_policy"
    ON patient_supplement_stacks FOR DELETE
    TO authenticated
    USING (patient_id = get_patient_id_for_current_user());

-- ============================================================================
-- SUPPLEMENT_LOGS
-- ============================================================================

ALTER TABLE supplement_logs ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'supplement_logs'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON supplement_logs', pol.policyname);
    END LOOP;
END $$;

-- SELECT: user sees only their own logs + therapist can see their patients' logs
CREATE POLICY "supplement_logs_select_policy"
    ON supplement_logs FOR SELECT
    TO authenticated
    USING (
        patient_id = get_patient_id_for_current_user()
        OR patient_id IN (
            SELECT id FROM patients
            WHERE therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        )
    );

-- INSERT: user can only log for themselves
CREATE POLICY "supplement_logs_insert_policy"
    ON supplement_logs FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = get_patient_id_for_current_user()
    );

-- UPDATE: user can only update their own logs
CREATE POLICY "supplement_logs_update_policy"
    ON supplement_logs FOR UPDATE
    TO authenticated
    USING (patient_id = get_patient_id_for_current_user())
    WITH CHECK (patient_id = get_patient_id_for_current_user());

-- DELETE: user can only delete their own logs
CREATE POLICY "supplement_logs_delete_policy"
    ON supplement_logs FOR DELETE
    TO authenticated
    USING (patient_id = get_patient_id_for_current_user());
