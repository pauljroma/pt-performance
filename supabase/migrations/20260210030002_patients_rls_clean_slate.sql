-- ============================================================================
-- PATIENTS TABLE RLS - CLEAN SLATE
-- ============================================================================
-- Problem: Conflicting RLS policies causing "new row violates" errors
-- Solution: Drop ALL policies and recreate with clean, non-conflicting rules
-- ============================================================================

-- ============================================================================
-- STEP 1: Drop ALL existing policies on patients table
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
        RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- ============================================================================
-- STEP 2: Ensure RLS is enabled
-- ============================================================================

ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 3: Create ANON policies (for demo mode)
-- ============================================================================

-- ANON SELECT: Allow reading any patient (demo mode needs this)
CREATE POLICY "patients_anon_select"
    ON patients FOR SELECT
    TO anon
    USING (true);

-- ANON INSERT: Only allow inserting demo patient
CREATE POLICY "patients_anon_insert"
    ON patients FOR INSERT
    TO anon
    WITH CHECK (id = '00000000-0000-0000-0000-000000000001'::uuid);

-- ANON UPDATE: Allow updating demo patient (any fields)
CREATE POLICY "patients_anon_update"
    ON patients FOR UPDATE
    TO anon
    USING (id = '00000000-0000-0000-0000-000000000001'::uuid);

-- ANON DELETE: Not allowed
-- (no policy = denied)

-- ============================================================================
-- STEP 4: Create AUTHENTICATED policies (for real users)
-- ============================================================================

-- AUTH SELECT: Own record, demo patient, or therapist's patients
CREATE POLICY "patients_auth_select"
    ON patients FOR SELECT
    TO authenticated
    USING (
        id = '00000000-0000-0000-0000-000000000001'::uuid
        OR user_id = auth.uid()
        OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
        OR therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
    );

-- AUTH INSERT: Therapists can insert
CREATE POLICY "patients_auth_insert"
    ON patients FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM therapists WHERE user_id = auth.uid())
        OR id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- AUTH UPDATE: Own record, demo patient, or therapist's patients
CREATE POLICY "patients_auth_update"
    ON patients FOR UPDATE
    TO authenticated
    USING (
        id = '00000000-0000-0000-0000-000000000001'::uuid
        OR user_id = auth.uid()
        OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
        OR therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
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
    policy_names TEXT;
BEGIN
    SELECT COUNT(*), string_agg(policyname, ', ')
    INTO policy_count, policy_names
    FROM pg_policies
    WHERE tablename = 'patients' AND schemaname = 'public';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Patients RLS Clean Slate Complete';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Total policies: %', policy_count;
    RAISE NOTICE 'Policies: %', policy_names;
    RAISE NOTICE '';
    RAISE NOTICE 'ANON role can:';
    RAISE NOTICE '  - SELECT any patient';
    RAISE NOTICE '  - INSERT demo patient only';
    RAISE NOTICE '  - UPDATE demo patient only';
    RAISE NOTICE '';
    RAISE NOTICE 'AUTHENTICATED role can:';
    RAISE NOTICE '  - SELECT own/demo/therapist patients';
    RAISE NOTICE '  - INSERT as therapist or demo';
    RAISE NOTICE '  - UPDATE own/demo/therapist patients';
    RAISE NOTICE '============================================';
END $$;
