-- ============================================================================
-- FIX BUILD 11: Add Missing Therapist RLS Policy
-- ============================================================================
-- The therapists table has RLS enabled but NO policies defined!
-- This blocks ALL queries, preventing therapists from seeing their own record
-- and subsequently their patients.
--
-- Date: 2025-12-11
-- Issue: Therapist can login but sees no patients
-- Root Cause: No RLS policy allows therapists to see their own record
-- ============================================================================

-- Add policy to allow therapists to see their own record
CREATE POLICY therapists_see_own_record ON therapists
  FOR SELECT
  USING (user_id = auth.uid());

-- Add policy to allow therapists to see their assigned patients
CREATE POLICY therapists_see_assigned_patients ON patients
  FOR SELECT
  USING (
    therapist_id IN (
      SELECT id FROM therapists WHERE user_id = auth.uid()
    )
  );

-- Verification
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'THERAPIST RLS POLICIES ADDED';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Created policies:';
  RAISE NOTICE '  1. therapists_see_own_record - Allows therapists to query their own record';
  RAISE NOTICE '  2. therapists_see_assigned_patients - Allows therapists to see their patients';
  RAISE NOTICE '';
  RAISE NOTICE 'These policies use user_id = auth.uid() to match the authenticated user.';
  RAISE NOTICE '';
  RAISE NOTICE 'Test with therapist login:';
  RAISE NOTICE '  Email: demo-pt@ptperformance.app';
  RAISE NOTICE '  Password: demo-therapist-2025';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Therapist should now see their record and assigned patients!';
  RAISE NOTICE '========================================================================';
END $$;
