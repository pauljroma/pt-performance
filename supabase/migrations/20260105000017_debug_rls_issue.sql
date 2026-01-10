-- Debug RLS issues - BUILD 116
-- Temporarily make policies very permissive to understand auth context

-- Drop all existing policies
DROP POLICY IF EXISTS "Patients can insert own readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can insert any readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can view own readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can view all readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can update own readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can update any readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can delete own readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can delete any readiness" ON daily_readiness;

-- Create super permissive INSERT policy for debugging
-- This will allow any authenticated user to insert any data
CREATE POLICY "Debug: Allow all authenticated inserts"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Just check that user is authenticated (auth.uid() is not null)
        auth.uid() IS NOT NULL
    );

-- Allow authenticated users to view all data (for debugging)
CREATE POLICY "Debug: Allow all authenticated selects"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (
        auth.uid() IS NOT NULL
    );

-- Allow authenticated users to update all data (for debugging)
CREATE POLICY "Debug: Allow all authenticated updates"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);

-- Allow authenticated users to delete all data (for debugging)
CREATE POLICY "Debug: Allow all authenticated deletes"
    ON daily_readiness FOR DELETE
    TO authenticated
    USING (auth.uid() IS NOT NULL);

COMMENT ON TABLE daily_readiness IS 'BUILD 116 - Debug policies active. All authenticated users can access all data. Replace with proper policies after auth debugging.';
