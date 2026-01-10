-- Temporarily disable RLS on daily_readiness - BUILD 116
-- This allows the iOS app to work while we debug authentication

-- Disable RLS
ALTER TABLE daily_readiness DISABLE ROW LEVEL SECURITY;

-- Add comment explaining this is temporary
COMMENT ON TABLE daily_readiness IS 'BUILD 116 - RLS temporarily disabled for testing. Re-enable after auth debugging.';
