-- BUILD 366: Fix RLS with proper type casting
-- The issue is likely UUID vs text mismatch between patients.user_id and auth.uid()

-- First enable RLS
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

-- Create policy with explicit type casting to handle UUID/text mismatch
CREATE POLICY "users_manage_own_patient_readiness"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (
        patient_id::text IN (
            SELECT id::text FROM patients WHERE user_id::text = auth.uid()::text
        )
    )
    WITH CHECK (
        patient_id::text IN (
            SELECT id::text FROM patients WHERE user_id::text = auth.uid()::text
        )
    );

GRANT ALL ON daily_readiness TO authenticated;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - RLS with UUID/text casting fix';
