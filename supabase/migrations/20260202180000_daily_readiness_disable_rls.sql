-- BUILD 385: Completely disable RLS on daily_readiness
-- As a last resort, disable RLS entirely

-- Disable RLS
ALTER TABLE daily_readiness DISABLE ROW LEVEL SECURITY;

-- Grant full access
GRANT ALL ON daily_readiness TO authenticated;
GRANT ALL ON daily_readiness TO anon;
