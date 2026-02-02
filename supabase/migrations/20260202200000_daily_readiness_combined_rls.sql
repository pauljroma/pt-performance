-- BUILD 385: Combined RLS policy for daily_readiness
-- Single policy that handles all cases to avoid policy conflicts

BEGIN;

-- Drop ALL existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Single combined policy for authenticated users
CREATE POLICY "daily_readiness_access"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (
        -- Demo patient: any authenticated user can access
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        -- Own patient record via user_id
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR
        -- Own patient record via email fallback
        patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
        OR
        -- Therapist viewing their patient
        patient_id IN (
            SELECT p.id FROM patients p
            JOIN therapists t ON p.therapist_id = t.id
            WHERE t.user_id = auth.uid() OR t.email = (auth.jwt() ->> 'email')
        )
    )
    WITH CHECK (
        -- Demo patient: any authenticated user can write
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        -- Own patient record via user_id
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR
        -- Own patient record via email fallback
        patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Ensure RLS is enabled
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON daily_readiness TO authenticated;

COMMIT;
