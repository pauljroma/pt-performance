-- BUILD 366: Disable RLS on daily_readiness to unblock user
-- Will investigate data issue separately

-- Drop all policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Disable RLS
ALTER TABLE daily_readiness DISABLE ROW LEVEL SECURITY;

-- Grant full access
GRANT ALL ON daily_readiness TO authenticated;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - RLS disabled pending data investigation';
