-- Migration: Fix manual_sessions INSERT RLS policy
-- Created: 2026-01-24
-- Purpose: Use SECURITY DEFINER function to avoid RLS recursion on patients table

-- ============================================================================
-- 1. CREATE SECURITY DEFINER FUNCTION FOR INSERT
-- ============================================================================

-- Function to get patient_id from authenticated user's email
-- This avoids RLS recursion when checking INSERT permission
CREATE OR REPLACE FUNCTION public.get_patient_id_for_auth_user()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT p.id
    FROM patients p
    WHERE p.email = (auth.jwt() ->> 'email')
    LIMIT 1
$$;

GRANT EXECUTE ON FUNCTION public.get_patient_id_for_auth_user() TO authenticated;

COMMENT ON FUNCTION get_patient_id_for_auth_user() IS
'SECURITY DEFINER function to get the patient_id for the authenticated user.
Avoids RLS recursion when checking INSERT permissions on manual_sessions.
Returns NULL if user is not a patient.';

-- ============================================================================
-- 2. UPDATE INSERT POLICY ON MANUAL_SESSIONS
-- ============================================================================

-- Drop the existing INSERT policy
DROP POLICY IF EXISTS "manual_sessions_insert" ON manual_sessions;

-- Create new INSERT policy using SECURITY DEFINER function
CREATE POLICY "manual_sessions_insert"
ON manual_sessions
FOR INSERT
TO authenticated
WITH CHECK (patient_id = get_patient_id_for_auth_user());

COMMENT ON POLICY "manual_sessions_insert" ON manual_sessions IS
'Patients can create manual sessions for themselves.
Uses SECURITY DEFINER function to avoid RLS recursion on patients table.';

-- ============================================================================
-- 3. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_func_exists BOOLEAN;
    v_policy_exists BOOLEAN;
BEGIN
    -- Check function exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_schema = 'public' AND routine_name = 'get_patient_id_for_auth_user'
    ) INTO v_func_exists;

    IF NOT v_func_exists THEN
        RAISE EXCEPTION 'FAILED: get_patient_id_for_auth_user function was not created';
    END IF;

    -- Check policy exists
    SELECT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'manual_sessions'
        AND policyname = 'manual_sessions_insert'
    ) INTO v_policy_exists;

    IF NOT v_policy_exists THEN
        RAISE EXCEPTION 'FAILED: manual_sessions_insert policy was not created';
    END IF;

    RAISE NOTICE 'SUCCESS: Fixed manual_sessions INSERT RLS policy';
    RAISE NOTICE '  - get_patient_id_for_auth_user function: %', v_func_exists;
    RAISE NOTICE '  - manual_sessions_insert policy: %', v_policy_exists;
END $$;
