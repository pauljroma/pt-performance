-- ============================================================================
-- COMPREHENSIVE PATIENTS RLS FIX
-- ============================================================================
-- Problem: "permission denied for patient table" during demo mode setup
-- Root cause: RLS policies are too restrictive for patient lookup queries
-- Solution: Add proper policies for authenticated users to query patients
-- ============================================================================

-- ============================================================================
-- STEP 1: Ensure RLS is enabled
-- ============================================================================
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 2: Drop potentially conflicting policies
-- ============================================================================
-- We'll recreate them with proper logic

DROP POLICY IF EXISTS "demo_patient_read_access" ON patients;
DROP POLICY IF EXISTS "patients_demo_patient_access" ON patients;
DROP POLICY IF EXISTS "Patients can read own data" ON patients;
DROP POLICY IF EXISTS "Users can read own patient record" ON patients;
DROP POLICY IF EXISTS "Authenticated users can query patients" ON patients;

-- ============================================================================
-- STEP 3: Create comprehensive SELECT policy
-- ============================================================================
-- Allow authenticated users to SELECT patients where:
-- 1. It's the demo patient (for demo mode)
-- 2. The patient's user_id matches auth.uid() (for normal users)
-- 3. The patient's email matches the auth user's email (legacy lookup)
-- 4. The patient is assigned to the user as a therapist

CREATE POLICY "patients_select_policy"
    ON patients FOR SELECT
    TO authenticated
    USING (
        -- Case 1: Demo patient (any authenticated user can read)
        id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        -- Case 2: Own patient record via user_id
        user_id = auth.uid()
        OR
        -- Case 3: Own patient record via email (legacy)
        email = (auth.jwt() ->> 'email')
        OR
        -- Case 4: Therapist can see their assigned patients
        therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        OR
        therapist_id::text = auth.uid()::text
    );

-- ============================================================================
-- STEP 4: Create UPDATE policy for patients
-- ============================================================================
DROP POLICY IF EXISTS "patients_update_policy" ON patients;
DROP POLICY IF EXISTS "Patients can update own data" ON patients;

CREATE POLICY "patients_update_policy"
    ON patients FOR UPDATE
    TO authenticated
    USING (
        -- Demo patient (any authenticated user can update for demo purposes)
        id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        -- Own patient record
        user_id = auth.uid()
        OR
        -- Own patient record via email (legacy)
        email = (auth.jwt() ->> 'email')
        OR
        -- Therapist can update their patients
        therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        OR
        therapist_id::text = auth.uid()::text
    )
    WITH CHECK (
        -- Same conditions for the new row values
        id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        user_id = auth.uid()
        OR
        email = (auth.jwt() ->> 'email')
        OR
        therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        OR
        therapist_id::text = auth.uid()::text
    );

-- ============================================================================
-- STEP 5: Ensure INSERT policy exists for therapists
-- ============================================================================
-- Keep existing therapist insert policy (don't drop if exists)
-- Just ensure it exists

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'patients'
        AND policyname = 'Therapists can insert patients'
    ) THEN
        CREATE POLICY "Therapists can insert patients"
            ON patients FOR INSERT
            TO authenticated
            WITH CHECK (
                -- Must be a therapist
                EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role_name = 'therapist')
                OR EXISTS (SELECT 1 FROM therapists WHERE user_id = auth.uid())
            );
    END IF;
END $$;

-- ============================================================================
-- STEP 6: Grant permissions
-- ============================================================================
GRANT SELECT, INSERT, UPDATE ON patients TO authenticated;

-- ============================================================================
-- STEP 7: Verification
-- ============================================================================
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'patients';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Comprehensive Patients RLS Fix Complete';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Total policies on patients table: %', policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Policies now allow:';
    RAISE NOTICE '  - Demo patient access for any authenticated user';
    RAISE NOTICE '  - Own patient record via user_id or email';
    RAISE NOTICE '  - Therapist access to assigned patients';
    RAISE NOTICE '';
END $$;
