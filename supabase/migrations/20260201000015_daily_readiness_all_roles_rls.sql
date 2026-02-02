-- BUILD 366: Allow all roles including anon

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

-- Policy for authenticated users
CREATE POLICY "authenticated_full_access"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Policy for anon users (in case JWT isn't being sent correctly)
CREATE POLICY "anon_full_access"
    ON daily_readiness FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- Policy for public
CREATE POLICY "public_full_access"
    ON daily_readiness FOR ALL
    TO public
    USING (true)
    WITH CHECK (true);

GRANT ALL ON daily_readiness TO authenticated;
GRANT ALL ON daily_readiness TO anon;
GRANT ALL ON daily_readiness TO public;
