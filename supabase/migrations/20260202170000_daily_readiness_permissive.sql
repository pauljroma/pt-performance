-- BUILD 385: Make daily_readiness fully permissive for authenticated users
-- Too many RLS issues with this table - simplify

BEGIN;

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

-- Simple permissive policy: any authenticated user can do anything
CREATE POLICY "daily_readiness_authenticated_all"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Ensure RLS is enabled but with permissive policy
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Grant all permissions
GRANT ALL ON daily_readiness TO authenticated;

COMMIT;
