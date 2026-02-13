-- ============================================================================
-- RE-ENABLE RLS WITH DEMO PATIENT SUPPORT
-- ============================================================================
-- Re-enable RLS and create policies that work with demo mode
-- Demo patient's user_id is NULL (can't set due to FK constraint)
-- Policies must allow access by id for demo patient
-- ============================================================================

-- ============================================================================
-- STEP 1: Re-enable RLS on patients
-- ============================================================================

ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 2: Clean up all existing policies
-- ============================================================================

DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'patients' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON patients', policy_record.policyname);
    END LOOP;
END $$;

-- ============================================================================
-- STEP 3: Create ANON policies (for demo mode)
-- Demo mode uses anon key, queries by patient id directly
-- ============================================================================

CREATE POLICY "patients_anon_select"
    ON patients FOR SELECT
    TO anon
    USING (id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "patients_anon_update"
    ON patients FOR UPDATE
    TO anon
    USING (id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "patients_anon_insert"
    ON patients FOR INSERT
    TO anon
    WITH CHECK (id = '00000000-0000-0000-0000-000000000001'::uuid);

-- ============================================================================
-- STEP 4: Create AUTHENTICATED policies
-- Authenticated users access via user_id or demo patient
-- ============================================================================

CREATE POLICY "patients_auth_select"
    ON patients FOR SELECT
    TO authenticated
    USING (
        user_id = auth.uid()
        OR id = '00000000-0000-0000-0000-000000000001'::uuid
    );

CREATE POLICY "patients_auth_update"
    ON patients FOR UPDATE
    TO authenticated
    USING (
        user_id = auth.uid()
        OR id = '00000000-0000-0000-0000-000000000001'::uuid
    )
    WITH CHECK (
        user_id = auth.uid()
        OR id = '00000000-0000-0000-0000-000000000001'::uuid
    );

CREATE POLICY "patients_auth_insert"
    ON patients FOR INSERT
    TO authenticated
    WITH CHECK (
        user_id = auth.uid()
        OR id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- ============================================================================
-- STEP 5: Grant permissions
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON patients TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON patients TO authenticated;

-- ============================================================================
-- STEP 6: Force schema reload
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
    WHERE tablename = 'patients';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'RLS Re-enabled with Demo Support';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Policies on patients: %', policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'ANON can access demo patient by id';
    RAISE NOTICE 'AUTHENTICATED can access by user_id or demo patient';
    RAISE NOTICE '============================================';
END $$;
