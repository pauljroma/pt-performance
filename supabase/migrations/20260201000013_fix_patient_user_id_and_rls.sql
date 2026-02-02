-- BUILD 366: Fix patient user_id data and then apply RLS
-- The root cause is patients.user_id not matching auth.uid()

-- Step 1: Fix patients.user_id by matching on email
UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE LOWER(p.email) = LOWER(au.email)
AND (p.user_id IS NULL OR p.user_id::text != au.id::text);

-- Step 2: Enable RLS on daily_readiness
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Step 3: Drop all existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Step 4: Create the RLS policy
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

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - Fixed patient user_id data and RLS';
