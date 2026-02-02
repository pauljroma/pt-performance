-- BUILD 366: Fix RLS using SECURITY DEFINER function
-- The subquery to patients table may be blocked by RLS
-- Use SECURITY DEFINER to bypass RLS when checking ownership

-- Step 1: Drop ALL existing policies on daily_readiness
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Step 2: Create SECURITY DEFINER function to check patient ownership
-- This function runs with elevated privileges to bypass RLS on patients table
CREATE OR REPLACE FUNCTION check_patient_ownership(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM patients
        WHERE id = p_patient_id
        AND user_id = auth.uid()
    );
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION check_patient_ownership(UUID) TO authenticated;

-- Step 3: Enable RLS
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Step 4: Create single policy using the SECURITY DEFINER function
CREATE POLICY "users_manage_own_patient_readiness"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (check_patient_ownership(patient_id))
    WITH CHECK (check_patient_ownership(patient_id));

-- Step 5: Ensure grants
GRANT SELECT, INSERT, UPDATE, DELETE ON daily_readiness TO authenticated;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - RLS via SECURITY DEFINER check_patient_ownership()';
