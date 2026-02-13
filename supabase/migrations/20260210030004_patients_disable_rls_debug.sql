-- ============================================================================
-- TEMPORARILY DISABLE RLS ON PATIENTS FOR DEBUGGING
-- ============================================================================

-- Disable RLS entirely
ALTER TABLE patients DISABLE ROW LEVEL SECURITY;

-- Ensure full grants
GRANT ALL ON patients TO anon;
GRANT ALL ON patients TO authenticated;

-- Force reload
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

DO $$
BEGIN
    RAISE NOTICE 'RLS DISABLED on patients table';
    RAISE NOTICE 'If error persists, issue is NOT RLS - check triggers/constraints';
END $$;
