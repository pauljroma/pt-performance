-- BUILD 366: Correct RLS for daily_readiness
-- The patient_id column references patients.id, NOT auth.uid() directly
-- We need to check that the patient record belongs to the authenticated user

-- Drop existing policies
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Ensure RLS is enabled
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- CREATE HELPER FUNCTION: Check if patient belongs to current user
CREATE OR REPLACE FUNCTION auth_owns_patient(p_patient_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if this patient_id has user_id matching auth.uid()
    RETURN EXISTS (
        SELECT 1 FROM patients 
        WHERE id = p_patient_id 
        AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- INSERT: User can insert for patients they own
CREATE POLICY "users_insert_own_patient_readiness"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (auth_owns_patient(patient_id));

-- SELECT: User can view their patient's data
CREATE POLICY "users_select_own_patient_readiness"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (auth_owns_patient(patient_id));

-- UPDATE: User can update their patient's data
CREATE POLICY "users_update_own_patient_readiness"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (auth_owns_patient(patient_id))
    WITH CHECK (auth_owns_patient(patient_id));

-- DELETE: User can delete their patient's data
CREATE POLICY "users_delete_own_patient_readiness"
    ON daily_readiness FOR DELETE
    TO authenticated
    USING (auth_owns_patient(patient_id));

-- Ensure grants
GRANT SELECT, INSERT, UPDATE, DELETE ON daily_readiness TO authenticated;
GRANT EXECUTE ON FUNCTION auth_owns_patient TO authenticated;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - RLS via auth_owns_patient() function';
