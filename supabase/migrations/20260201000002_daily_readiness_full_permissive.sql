-- BUILD 366: Make daily_readiness fully permissive for debugging
-- This removes ALL restrictions temporarily

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

-- Disable RLS completely for now
ALTER TABLE daily_readiness DISABLE ROW LEVEL SECURITY;

-- Grant full access
GRANT ALL ON daily_readiness TO authenticated;
GRANT ALL ON daily_readiness TO anon;
GRANT ALL ON daily_readiness TO service_role;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - RLS disabled for debugging';
