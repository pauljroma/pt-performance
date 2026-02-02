-- BUILD 366: Proper RLS for daily_readiness
-- Patients can manage their own data, therapists can view patients they're linked to

-- Re-enable RLS
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- INSERT: Patients can insert their own readiness (patient_id must match auth.uid())
CREATE POLICY "patients_insert_own_readiness"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (patient_id = auth.uid());

-- SELECT: Patients can view their own data
CREATE POLICY "patients_select_own_readiness"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (patient_id = auth.uid());

-- UPDATE: Patients can update their own data
CREATE POLICY "patients_update_own_readiness"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- DELETE: Patients can delete their own data
CREATE POLICY "patients_delete_own_readiness"
    ON daily_readiness FOR DELETE
    TO authenticated
    USING (patient_id = auth.uid());

-- Ensure grants are in place
GRANT SELECT, INSERT, UPDATE, DELETE ON daily_readiness TO authenticated;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - Proper RLS: patient_id = auth.uid()';
