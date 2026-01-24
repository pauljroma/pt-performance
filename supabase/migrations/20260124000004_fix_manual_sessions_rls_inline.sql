-- Migration: Fix manual_sessions RLS with inline EXISTS pattern
-- Created: 2026-01-24
-- Purpose: Use the same inline EXISTS pattern that works for nutrition_goals

-- ============================================================================
-- 1. DROP AND RECREATE INSERT POLICY
-- ============================================================================

-- Drop the existing INSERT policy
DROP POLICY IF EXISTS "manual_sessions_insert" ON manual_sessions;

-- Create INSERT policy with inline EXISTS (same pattern as nutrition_goals)
CREATE POLICY "manual_sessions_insert" ON manual_sessions
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- 2. VERIFY RLS ON PATIENTS TABLE ALLOWS SELECT
-- ============================================================================

-- Ensure patients table allows SELECT for authenticated users
-- This is required for the EXISTS check to work
DO $$
DECLARE
    v_policy_exists BOOLEAN;
BEGIN
    -- Check if there's a SELECT policy on patients for authenticated
    SELECT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'patients'
        AND (policyname LIKE '%select%' OR policyname LIKE '%read%' OR policyname LIKE '%view%')
    ) INTO v_policy_exists;
    
    IF NOT v_policy_exists THEN
        RAISE WARNING 'No SELECT policy found on patients table - this may cause issues';
    END IF;
END $$;

-- ============================================================================
-- 3. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_policy_def TEXT;
BEGIN
    SELECT with_check::text INTO v_policy_def
    FROM pg_policies
    WHERE tablename = 'manual_sessions'
    AND policyname = 'manual_sessions_insert';
    
    RAISE NOTICE 'SUCCESS: Updated manual_sessions_insert policy';
    RAISE NOTICE 'Policy WITH CHECK: %', COALESCE(v_policy_def, 'N/A');
END $$;
