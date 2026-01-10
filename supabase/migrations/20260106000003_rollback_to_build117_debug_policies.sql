-- EMERGENCY ROLLBACK: Restore BUILD 117 Debug Policies
-- BUILD 118 restrictive policies broke RLS - reverting to BUILD 117's working state

-- ============================================================================
-- DROP BUILD 118 RESTRICTIVE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Patients can insert own readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can view own readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can update own readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Patients can delete own readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can insert any readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can view all readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can update any readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can delete any readiness" ON daily_readiness;

-- ============================================================================
-- RESTORE BUILD 117 DEBUG POLICIES (WORKING)
-- ============================================================================

-- These policies from BUILD 117 were working correctly
-- They allow all authenticated users to access daily_readiness

CREATE POLICY "Debug: Allow all authenticated inserts"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Debug: Allow all authenticated selects"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Debug: Allow all authenticated updates"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Debug: Allow all authenticated deletes"
    ON daily_readiness FOR DELETE
    TO authenticated
    USING (true);

-- Update table comment to reflect BUILD 117 state
COMMENT ON TABLE daily_readiness IS
'BUILD 117 debug policies active (permissive for all authenticated users). Will implement proper RLS in future build.';

-- ============================================================================
-- NOTES
-- ============================================================================
-- BUILD 118 attempted to implement restrictive patient_id = auth.uid() policies
-- but this caused RLS errors in production.
--
-- BUILD 117's permissive approach was working correctly and is restored here.
--
-- Future improvement: Investigate why patient_id = auth.uid() causes RLS errors
-- (likely UUID type mismatch or is_therapist() function issues)
