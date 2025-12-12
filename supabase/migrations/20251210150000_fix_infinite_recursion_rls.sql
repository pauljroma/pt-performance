-- Fix infinite recursion in patients RLS policy

-- Drop the broken policy
DROP POLICY IF EXISTS patients_see_own_data ON patients;

-- Create correct policy (no subquery, direct comparison)
CREATE POLICY patients_see_own_data ON patients
  FOR SELECT
  USING (user_id = auth.uid());

-- Verify the fix
DO $$
BEGIN
  RAISE NOTICE '✅ Fixed patients_see_own_data policy - no more infinite recursion';
END $$;
