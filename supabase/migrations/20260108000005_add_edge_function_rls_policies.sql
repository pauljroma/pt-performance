-- BUILD 138: Edge Function RLS Policies Enhancement
-- Adds service role policies and missing RLS for Edge Functions
-- Date: 2026-01-08
-- Purpose: Ensure Edge Functions can properly insert/update data while maintaining security

-- ============================================================================
-- 1. Service Role Policies for recommendations table
-- ============================================================================

-- Drop and recreate policies to ensure service role can insert recommendations
DROP POLICY IF EXISTS "Service role can manage recommendations" ON recommendations;

CREATE POLICY "Service role can manage recommendations"
    ON recommendations FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Patients can delete their pending recommendations
DROP POLICY IF EXISTS "Patients can delete own pending recommendations" ON recommendations;

CREATE POLICY "Patients can delete own pending recommendations"
    ON recommendations FOR DELETE
    USING (patient_id = auth.uid() AND status = 'pending');

COMMENT ON POLICY "Service role can manage recommendations" ON recommendations IS
    'Edge Functions use service role to create AI recommendations';

-- ============================================================================
-- 2. Service Role Policies for session_instances table
-- ============================================================================

-- Drop and recreate to ensure service role can insert instances
DROP POLICY IF EXISTS "Service role can manage session instances" ON session_instances;

CREATE POLICY "Service role can manage session instances"
    ON session_instances FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

COMMENT ON POLICY "Service role can manage session instances" ON session_instances IS
    'Edge Functions use service role to create workout instances';

-- ============================================================================
-- 3. Service Role Policies for nutrition_recommendations table
-- ============================================================================

DROP POLICY IF EXISTS "Service role can manage nutrition recommendations" ON nutrition_recommendations;

CREATE POLICY "Service role can manage nutrition recommendations"
    ON nutrition_recommendations FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Allow deletion of old recommendations
DROP POLICY IF EXISTS "Patients can delete own nutrition recommendations" ON nutrition_recommendations;

CREATE POLICY "Patients can delete own nutrition recommendations"
    ON nutrition_recommendations FOR DELETE
    USING (patient_id = auth.uid());

COMMENT ON POLICY "Service role can manage nutrition recommendations" ON nutrition_recommendations IS
    'Edge Functions use service role to create nutrition AI recommendations';

-- ============================================================================
-- 4. Verify daily_readiness service role policy exists (already created in migration 20260105000010)
-- ============================================================================

-- This policy should already exist from 20260105000010_create_daily_readiness.sql
-- Verify it exists, and create if missing

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'daily_readiness'
        AND policyname = 'Service role can manage all readiness data'
    ) THEN
        CREATE POLICY "Service role can manage all readiness data"
            ON daily_readiness FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);

        RAISE NOTICE 'Created missing service role policy for daily_readiness';
    ELSE
        RAISE NOTICE 'Service role policy for daily_readiness already exists';
    END IF;
END $$;

-- ============================================================================
-- 5. nutrition_logs service role policy (for AI meal parser)
-- ============================================================================

-- Check if table exists and add service role policy
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'nutrition_logs'
    ) THEN
        -- Enable RLS if not already enabled
        ALTER TABLE nutrition_logs ENABLE ROW LEVEL SECURITY;

        -- Drop existing policy if exists
        DROP POLICY IF EXISTS "Service role can manage nutrition logs" ON nutrition_logs;

        -- Create service role policy
        CREATE POLICY "Service role can manage nutrition logs"
            ON nutrition_logs FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);

        RAISE NOTICE 'Created service role policy for nutrition_logs';
    ELSE
        RAISE NOTICE 'nutrition_logs table does not exist - skipping';
    END IF;
END $$;

-- ============================================================================
-- 6. patients table - ensure Edge Functions can read patient data
-- ============================================================================

-- Verify patients table has service role policy for WHOOP credentials access
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'patients'
        AND policyname = 'Service role can manage patients'
    ) THEN
        -- Create service role policy
        CREATE POLICY "Service role can manage patients"
            ON patients FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);

        RAISE NOTICE 'Created service role policy for patients';
    ELSE
        RAISE NOTICE 'Service role policy for patients already exists';
    END IF;
END $$;

-- ============================================================================
-- 7. sessions and session_exercises - Edge Functions need read access
-- ============================================================================

-- Ensure service role can read sessions and session_exercises
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sessions') THEN
        DROP POLICY IF EXISTS "Service role can read sessions" ON sessions;

        CREATE POLICY "Service role can read sessions"
            ON sessions FOR SELECT
            TO service_role
            USING (true);

        RAISE NOTICE 'Created service role read policy for sessions';
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'session_exercises') THEN
        DROP POLICY IF EXISTS "Service role can read session_exercises" ON session_exercises;

        CREATE POLICY "Service role can read session_exercises"
            ON session_exercises FOR SELECT
            TO service_role
            USING (true);

        RAISE NOTICE 'Created service role read policy for session_exercises';
    END IF;
END $$;

-- ============================================================================
-- 8. exercise_templates - Edge Functions need read access
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'exercise_templates') THEN
        DROP POLICY IF EXISTS "Service role can read exercise templates" ON exercise_templates;

        CREATE POLICY "Service role can read exercise templates"
            ON exercise_templates FOR SELECT
            TO service_role
            USING (true);

        RAISE NOTICE 'Created service role read policy for exercise_templates';
    END IF;
END $$;

-- ============================================================================
-- 9. scheduled_sessions - Edge Functions need read access for nutrition recommendations
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'scheduled_sessions') THEN
        DROP POLICY IF EXISTS "Service role can read scheduled sessions" ON scheduled_sessions;

        CREATE POLICY "Service role can read scheduled sessions"
            ON scheduled_sessions FOR SELECT
            TO service_role
            USING (true);

        RAISE NOTICE 'Created service role read policy for scheduled_sessions';
    END IF;
END $$;

-- ============================================================================
-- 10. nutrition_goals - Edge Functions need read access
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_goals') THEN
        ALTER TABLE nutrition_goals ENABLE ROW LEVEL SECURITY;

        DROP POLICY IF EXISTS "Service role can read nutrition goals" ON nutrition_goals;

        CREATE POLICY "Service role can read nutrition goals"
            ON nutrition_goals FOR SELECT
            TO service_role
            USING (true);

        RAISE NOTICE 'Created service role read policy for nutrition_goals';
    END IF;
END $$;

-- ============================================================================
-- 11. therapists table - Edge Functions need read access for apply-substitution
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'therapists') THEN
        DROP POLICY IF EXISTS "Service role can read therapists" ON therapists;

        CREATE POLICY "Service role can read therapists"
            ON therapists FOR SELECT
            TO service_role
            USING (true);

        RAISE NOTICE 'Created service role read policy for therapists';
    END IF;
END $$;

-- ============================================================================
-- Verification Summary
-- ============================================================================

DO $$
DECLARE
    v_recommendations_policies integer;
    v_session_instances_policies integer;
    v_nutrition_recs_policies integer;
    v_daily_readiness_policies integer;
BEGIN
    SELECT COUNT(*) INTO v_recommendations_policies
    FROM pg_policies WHERE tablename = 'recommendations';

    SELECT COUNT(*) INTO v_session_instances_policies
    FROM pg_policies WHERE tablename = 'session_instances';

    SELECT COUNT(*) INTO v_nutrition_recs_policies
    FROM pg_policies WHERE tablename = 'nutrition_recommendations';

    SELECT COUNT(*) INTO v_daily_readiness_policies
    FROM pg_policies WHERE tablename = 'daily_readiness';

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'EDGE FUNCTION RLS POLICIES - BUILD 138';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Service Role Policies Created:';
    RAISE NOTICE '   - recommendations (% total policies)', v_recommendations_policies;
    RAISE NOTICE '   - session_instances (% total policies)', v_session_instances_policies;
    RAISE NOTICE '   - nutrition_recommendations (% total policies)', v_nutrition_recs_policies;
    RAISE NOTICE '   - daily_readiness (% total policies)', v_daily_readiness_policies;
    RAISE NOTICE '';
    RAISE NOTICE '✅ Edge Functions can now:';
    RAISE NOTICE '   - generate-equipment-substitution: Create recommendations';
    RAISE NOTICE '   - apply-substitution: Create session instances';
    RAISE NOTICE '   - sync-whoop-recovery: Update daily_readiness';
    RAISE NOTICE '   - ai-nutrition-recommendation: Create nutrition recommendations';
    RAISE NOTICE '   - ai-meal-parser: Create nutrition logs';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Security:';
    RAISE NOTICE '   - Service role policies use USING (true) - bypasses RLS';
    RAISE NOTICE '   - Patient policies remain strict - patient_id = auth.uid()';
    RAISE NOTICE '   - Therapist policies use EXISTS checks for access control';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'EDGE FUNCTION RLS POLICIES READY';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
END $$;
