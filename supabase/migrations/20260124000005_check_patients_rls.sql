-- Migration: Ensure patients table allows SELECT for RLS checks
-- Created: 2026-01-24
-- Purpose: The manual_sessions INSERT policy needs to SELECT from patients

-- Check and report current RLS status
DO $$
DECLARE
    v_rls_enabled BOOLEAN;
    v_policy_count INTEGER;
    v_policies TEXT;
BEGIN
    -- Check if RLS is enabled on patients
    SELECT relrowsecurity INTO v_rls_enabled
    FROM pg_class
    WHERE relname = 'patients';
    
    -- Count policies
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE tablename = 'patients';
    
    -- Get policy names
    SELECT string_agg(policyname, ', ') INTO v_policies
    FROM pg_policies
    WHERE tablename = 'patients';
    
    RAISE NOTICE 'Patients table RLS status:';
    RAISE NOTICE '  - RLS enabled: %', v_rls_enabled;
    RAISE NOTICE '  - Policy count: %', v_policy_count;
    RAISE NOTICE '  - Policies: %', COALESCE(v_policies, 'NONE');
    
    -- If RLS is enabled but no policies allow cross-table SELECT, we need to add one
    IF v_rls_enabled AND v_policy_count = 0 THEN
        RAISE WARNING 'Patients table has RLS enabled but no policies - adding permissive SELECT';
    END IF;
END $$;

-- Add a policy that allows authenticated users to SELECT their own patient record
-- This is needed for RLS policies on other tables that reference patients
DROP POLICY IF EXISTS "patients_self_select" ON patients;
CREATE POLICY "patients_self_select" ON patients
    FOR SELECT
    TO authenticated
    USING (email = (auth.jwt() ->> 'email'));

COMMENT ON POLICY "patients_self_select" ON patients IS
'Allows authenticated users to read their own patient record.
Required for RLS policies on related tables (manual_sessions, nutrition_goals, etc.)
that need to verify ownership through patients.email.';

-- Verification
DO $$
DECLARE
    v_policy_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'patients'
        AND policyname = 'patients_self_select'
    ) INTO v_policy_exists;
    
    IF v_policy_exists THEN
        RAISE NOTICE 'SUCCESS: patients_self_select policy created';
    ELSE
        RAISE WARNING 'FAILED: patients_self_select policy not created';
    END IF;
END $$;
