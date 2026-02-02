-- BUILD 366: Disable RLS completely to debug

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

-- DISABLE RLS
ALTER TABLE daily_readiness DISABLE ROW LEVEL SECURITY;

-- Force disable
ALTER TABLE daily_readiness FORCE ROW LEVEL SECURITY;
ALTER TABLE daily_readiness NO FORCE ROW LEVEL SECURITY;

GRANT ALL ON daily_readiness TO authenticated;
GRANT ALL ON daily_readiness TO anon;
GRANT ALL ON daily_readiness TO public;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - RLS DISABLED for debugging';
