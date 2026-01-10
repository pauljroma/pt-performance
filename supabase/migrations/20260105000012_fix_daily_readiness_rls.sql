-- Fix RLS policies for daily_readiness - BUILD 116
-- Remove auth.users dependency and use simpler role checking

-- Drop existing therapist policy that queries auth.users
DROP POLICY IF EXISTS "Therapists can view all readiness data" ON daily_readiness;

-- Recreate therapist policy using a function that has proper permissions
CREATE OR REPLACE FUNCTION is_therapist()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'therapist'
  );
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION is_therapist() TO authenticated;

-- Recreate therapist policy using the function
CREATE POLICY "Therapists can view all readiness data"
    ON daily_readiness FOR SELECT
    USING (is_therapist());

-- Also create a simpler policy for patients to ensure it works
DROP POLICY IF EXISTS "Patients can view their own readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can insert their own readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can update their own readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can delete their own readiness data" ON daily_readiness;

CREATE POLICY "Patients can view their own readiness data"
    ON daily_readiness FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can insert their own readiness data"
    ON daily_readiness FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update their own readiness data"
    ON daily_readiness FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can delete their own readiness data"
    ON daily_readiness FOR DELETE
    USING (patient_id = auth.uid());
