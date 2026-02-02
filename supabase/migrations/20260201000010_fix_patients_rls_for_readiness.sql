-- BUILD 366: Ensure patients table RLS allows the ownership check
-- The daily_readiness RLS function needs to read from patients table

-- First, check and fix patients table RLS
-- Allow authenticated users to read their own patient record

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "patients_read_own" ON patients;
DROP POLICY IF EXISTS "users_read_own_patient" ON patients;
DROP POLICY IF EXISTS "authenticated_read_own_patient" ON patients;

-- Ensure RLS is enabled on patients
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- Create policy allowing users to read their own patient record
-- This is essential for the daily_readiness RLS check to work
CREATE POLICY "users_read_own_patient"
    ON patients FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Also ensure users can update their own patient record
DROP POLICY IF EXISTS "users_update_own_patient" ON patients;
CREATE POLICY "users_update_own_patient"
    ON patients FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Grant necessary permissions
GRANT SELECT, UPDATE ON patients TO authenticated;

-- Now recreate the daily_readiness RLS with a simpler approach
-- that doesn't need SECURITY DEFINER (since patients RLS now allows the read)

-- Drop ALL existing policies on daily_readiness
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Drop the helper functions (no longer needed)
DROP FUNCTION IF EXISTS check_patient_ownership(UUID);
DROP FUNCTION IF EXISTS auth_owns_patient(UUID);

-- Enable RLS on daily_readiness
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Create simple policy using direct subquery
-- Now that patients table allows reading own record, this should work
CREATE POLICY "users_manage_own_patient_readiness"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Ensure grants
GRANT SELECT, INSERT, UPDATE, DELETE ON daily_readiness TO authenticated;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - RLS with patients table access fixed';
