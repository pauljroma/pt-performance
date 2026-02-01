-- BUILD 367: Proper RLS now that iOS app sends authenticated requests
-- Check that patient_id belongs to a patient owned by current user

-- Enable RLS
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Create proper policy: user can only access readiness for their own patients
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

GRANT ALL ON daily_readiness TO authenticated;

COMMENT ON TABLE daily_readiness IS 'BUILD 367 - Proper RLS with patient ownership check';
