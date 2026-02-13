-- ============================================================================
-- PATIENTS TABLE - FULL ANON ACCESS FOR DEMO
-- ============================================================================
-- Temporarily allow full access for anon to debug RLS issues
-- ============================================================================

-- Drop existing anon policies
DROP POLICY IF EXISTS "patients_anon_select" ON patients;
DROP POLICY IF EXISTS "patients_anon_insert" ON patients;
DROP POLICY IF EXISTS "patients_anon_update" ON patients;

-- Create fully permissive anon policies
CREATE POLICY "patients_anon_all"
    ON patients
    TO anon
    USING (true)
    WITH CHECK (true);

-- Ensure grants
GRANT ALL ON patients TO anon;

-- Force reload
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- Verify
DO $$
BEGIN
    RAISE NOTICE 'Created fully permissive anon policy on patients';
    RAISE NOTICE 'ANON can now SELECT, INSERT, UPDATE, DELETE any row';
END $$;
