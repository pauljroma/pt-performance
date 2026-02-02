-- BUILD 366: Simplest possible RLS - just check user is authenticated

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

-- Simplest policy: just check authenticated
CREATE POLICY "authenticated_access"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

GRANT ALL ON daily_readiness TO authenticated;
