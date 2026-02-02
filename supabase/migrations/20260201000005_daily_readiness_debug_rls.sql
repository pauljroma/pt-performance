-- BUILD 366: Debug RLS - super permissive for authenticated
-- Just check that user is logged in, nothing else

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

-- SIMPLE: Just check auth.uid() is not null
CREATE POLICY "authenticated_full_access"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);

GRANT ALL ON daily_readiness TO authenticated;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - Debug RLS: auth.uid() IS NOT NULL';
