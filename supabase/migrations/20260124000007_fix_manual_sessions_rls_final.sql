-- Migration: Fix manual_sessions RLS using email pattern (same as nutrition_logs)
-- Created: 2026-01-24
-- Purpose: Restore RLS policies after failed migration

-- ============================================================================
-- 1. ENSURE POLICIES ARE DROPPED (in case some exist)
-- ============================================================================

DROP POLICY IF EXISTS "manual_sessions_select" ON manual_sessions;
DROP POLICY IF EXISTS "manual_sessions_insert" ON manual_sessions;
DROP POLICY IF EXISTS "manual_sessions_update" ON manual_sessions;
DROP POLICY IF EXISTS "manual_sessions_delete" ON manual_sessions;

-- ============================================================================
-- 2. CREATE POLICIES USING EMAIL PATTERN (SAME AS NUTRITION_LOGS)
-- ============================================================================

-- SELECT policy
CREATE POLICY "manual_sessions_select" ON manual_sessions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = manual_sessions.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- INSERT policy
CREATE POLICY "manual_sessions_insert" ON manual_sessions
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE policy
CREATE POLICY "manual_sessions_update" ON manual_sessions
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = manual_sessions.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE policy
CREATE POLICY "manual_sessions_delete" ON manual_sessions
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = manual_sessions.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- 3. ALSO FIX MANUAL_SESSION_EXERCISES POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "manual_session_exercises_select" ON manual_session_exercises;
DROP POLICY IF EXISTS "manual_session_exercises_insert" ON manual_session_exercises;
DROP POLICY IF EXISTS "manual_session_exercises_update" ON manual_session_exercises;
DROP POLICY IF EXISTS "manual_session_exercises_delete" ON manual_session_exercises;

-- SELECT policy for exercises
CREATE POLICY "manual_session_exercises_select" ON manual_session_exercises
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM manual_sessions ms
            JOIN patients p ON p.id = ms.patient_id
            WHERE ms.id = manual_session_exercises.manual_session_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- INSERT policy for exercises
CREATE POLICY "manual_session_exercises_insert" ON manual_session_exercises
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM manual_sessions ms
            JOIN patients p ON p.id = ms.patient_id
            WHERE ms.id = manual_session_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE policy for exercises
CREATE POLICY "manual_session_exercises_update" ON manual_session_exercises
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM manual_sessions ms
            JOIN patients p ON p.id = ms.patient_id
            WHERE ms.id = manual_session_exercises.manual_session_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE policy for exercises
CREATE POLICY "manual_session_exercises_delete" ON manual_session_exercises
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM manual_sessions ms
            JOIN patients p ON p.id = ms.patient_id
            WHERE ms.id = manual_session_exercises.manual_session_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- 4. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON manual_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON manual_session_exercises TO authenticated;

-- Reload schema cache
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- 5. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_ms_count INTEGER;
    v_mse_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_ms_count
    FROM pg_policies WHERE tablename = 'manual_sessions';
    
    SELECT COUNT(*) INTO v_mse_count
    FROM pg_policies WHERE tablename = 'manual_session_exercises';
    
    RAISE NOTICE 'SUCCESS: RLS policies restored using email pattern';
    RAISE NOTICE '  - manual_sessions policies: %', v_ms_count;
    RAISE NOTICE '  - manual_session_exercises policies: %', v_mse_count;
END $$;
