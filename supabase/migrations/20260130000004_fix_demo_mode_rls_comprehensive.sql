-- BUILD 326: Comprehensive Demo Mode RLS Fix
-- Purpose: Allow demo users (unauthenticated/anon) to access all required tables
-- Issue: All RLS policies use auth.uid() which returns NULL in demo mode
--
-- Demo mode bypasses Supabase authentication, so the client makes requests as 'anon'.
-- This migration adds read policies for 'anon' role on all tables needed for demo.

-- ============================================================================
-- CORE TABLES (guaranteed to exist)
-- ============================================================================

-- 1. SESSIONS TABLE
DROP POLICY IF EXISTS "sessions_anon_read" ON sessions;
CREATE POLICY "sessions_anon_read" ON sessions FOR SELECT TO anon USING (true);
GRANT SELECT ON sessions TO anon;

-- 2. SESSION_EXERCISES TABLE
DROP POLICY IF EXISTS "session_exercises_anon_read" ON session_exercises;
CREATE POLICY "session_exercises_anon_read" ON session_exercises FOR SELECT TO anon USING (true);
GRANT SELECT ON session_exercises TO anon;

-- 3. EXERCISE_TEMPLATES TABLE
DROP POLICY IF EXISTS "exercise_templates_anon_read" ON exercise_templates;
CREATE POLICY "exercise_templates_anon_read" ON exercise_templates FOR SELECT TO anon USING (true);
GRANT SELECT ON exercise_templates TO anon;

-- 4. SCHEDULED_SESSIONS TABLE
DROP POLICY IF EXISTS "scheduled_sessions_anon_read" ON scheduled_sessions;
CREATE POLICY "scheduled_sessions_anon_read" ON scheduled_sessions FOR SELECT TO anon USING (true);
GRANT SELECT ON scheduled_sessions TO anon;

-- 5. PROGRAMS TABLE
DROP POLICY IF EXISTS "programs_anon_read" ON programs;
CREATE POLICY "programs_anon_read" ON programs FOR SELECT TO anon USING (true);
GRANT SELECT ON programs TO anon;

-- 6. PHASES TABLE
DROP POLICY IF EXISTS "phases_anon_read" ON phases;
CREATE POLICY "phases_anon_read" ON phases FOR SELECT TO anon USING (true);
GRANT SELECT ON phases TO anon;

-- 7. PATIENTS TABLE
DROP POLICY IF EXISTS "patients_anon_read" ON patients;
CREATE POLICY "patients_anon_read" ON patients FOR SELECT TO anon USING (true);
GRANT SELECT ON patients TO anon;

-- 8. EXERCISE_LOGS TABLE
DROP POLICY IF EXISTS "exercise_logs_anon_read" ON exercise_logs;
CREATE POLICY "exercise_logs_anon_read" ON exercise_logs FOR SELECT TO anon USING (true);
DROP POLICY IF EXISTS "exercise_logs_anon_insert" ON exercise_logs;
CREATE POLICY "exercise_logs_anon_insert" ON exercise_logs FOR INSERT TO anon WITH CHECK (true);
GRANT SELECT, INSERT ON exercise_logs TO anon;

-- 9. MANUAL_SESSIONS TABLE
DROP POLICY IF EXISTS "manual_sessions_anon_read" ON manual_sessions;
CREATE POLICY "manual_sessions_anon_read" ON manual_sessions FOR SELECT TO anon USING (true);
DROP POLICY IF EXISTS "manual_sessions_anon_insert" ON manual_sessions;
CREATE POLICY "manual_sessions_anon_insert" ON manual_sessions FOR INSERT TO anon WITH CHECK (true);
DROP POLICY IF EXISTS "manual_sessions_anon_update" ON manual_sessions;
CREATE POLICY "manual_sessions_anon_update" ON manual_sessions FOR UPDATE TO anon USING (true);
GRANT SELECT, INSERT, UPDATE ON manual_sessions TO anon;

-- 10. MANUAL_SESSION_EXERCISES TABLE
DROP POLICY IF EXISTS "manual_session_exercises_anon_read" ON manual_session_exercises;
CREATE POLICY "manual_session_exercises_anon_read" ON manual_session_exercises FOR SELECT TO anon USING (true);
DROP POLICY IF EXISTS "manual_session_exercises_anon_insert" ON manual_session_exercises;
CREATE POLICY "manual_session_exercises_anon_insert" ON manual_session_exercises FOR INSERT TO anon WITH CHECK (true);
GRANT SELECT, INSERT ON manual_session_exercises TO anon;

-- 11. PATIENT_WORKOUT_TEMPLATES TABLE
DROP POLICY IF EXISTS "patient_workout_templates_anon_read" ON patient_workout_templates;
CREATE POLICY "patient_workout_templates_anon_read" ON patient_workout_templates FOR SELECT TO anon USING (true);
DROP POLICY IF EXISTS "patient_workout_templates_anon_insert" ON patient_workout_templates;
CREATE POLICY "patient_workout_templates_anon_insert" ON patient_workout_templates FOR INSERT TO anon WITH CHECK (true);
GRANT SELECT, INSERT ON patient_workout_templates TO anon;

-- ============================================================================
-- OPTIONAL TABLES (may or may not exist)
-- ============================================================================

DO $$
BEGIN
    -- INTERVAL_TIMERS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'interval_timers' AND table_schema = 'public') THEN
        EXECUTE 'DROP POLICY IF EXISTS "interval_timers_anon_read" ON interval_timers';
        EXECUTE 'CREATE POLICY "interval_timers_anon_read" ON interval_timers FOR SELECT TO anon USING (true)';
        EXECUTE 'DROP POLICY IF EXISTS "interval_timers_anon_insert" ON interval_timers';
        EXECUTE 'CREATE POLICY "interval_timers_anon_insert" ON interval_timers FOR INSERT TO anon WITH CHECK (true)';
        EXECUTE 'DROP POLICY IF EXISTS "interval_timers_anon_update" ON interval_timers';
        EXECUTE 'CREATE POLICY "interval_timers_anon_update" ON interval_timers FOR UPDATE TO anon USING (true)';
        EXECUTE 'DROP POLICY IF EXISTS "interval_timers_anon_delete" ON interval_timers';
        EXECUTE 'CREATE POLICY "interval_timers_anon_delete" ON interval_timers FOR DELETE TO anon USING (true)';
        EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON interval_timers TO anon';
        RAISE NOTICE 'Added anon policies to interval_timers';
    END IF;

    -- NUTRITION_LOGS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_logs' AND table_schema = 'public') THEN
        EXECUTE 'DROP POLICY IF EXISTS "nutrition_logs_anon_read" ON nutrition_logs';
        EXECUTE 'CREATE POLICY "nutrition_logs_anon_read" ON nutrition_logs FOR SELECT TO anon USING (true)';
        EXECUTE 'DROP POLICY IF EXISTS "nutrition_logs_anon_insert" ON nutrition_logs';
        EXECUTE 'CREATE POLICY "nutrition_logs_anon_insert" ON nutrition_logs FOR INSERT TO anon WITH CHECK (true)';
        EXECUTE 'DROP POLICY IF EXISTS "nutrition_logs_anon_delete" ON nutrition_logs';
        EXECUTE 'CREATE POLICY "nutrition_logs_anon_delete" ON nutrition_logs FOR DELETE TO anon USING (true)';
        EXECUTE 'GRANT SELECT, INSERT, DELETE ON nutrition_logs TO anon';
        RAISE NOTICE 'Added anon policies to nutrition_logs';
    END IF;

    -- FOOD_ITEMS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'food_items' AND table_schema = 'public') THEN
        EXECUTE 'DROP POLICY IF EXISTS "food_items_anon_read" ON food_items';
        EXECUTE 'CREATE POLICY "food_items_anon_read" ON food_items FOR SELECT TO anon USING (true)';
        EXECUTE 'GRANT SELECT ON food_items TO anon';
        RAISE NOTICE 'Added anon policies to food_items';
    END IF;

    -- NUTRITION_GOALS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_goals' AND table_schema = 'public') THEN
        EXECUTE 'DROP POLICY IF EXISTS "nutrition_goals_anon_read" ON nutrition_goals';
        EXECUTE 'CREATE POLICY "nutrition_goals_anon_read" ON nutrition_goals FOR SELECT TO anon USING (true)';
        EXECUTE 'DROP POLICY IF EXISTS "nutrition_goals_anon_insert" ON nutrition_goals';
        EXECUTE 'CREATE POLICY "nutrition_goals_anon_insert" ON nutrition_goals FOR INSERT TO anon WITH CHECK (true)';
        EXECUTE 'GRANT SELECT, INSERT ON nutrition_goals TO anon';
        RAISE NOTICE 'Added anon policies to nutrition_goals';
    END IF;

    -- HELP_ARTICLES
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'help_articles' AND table_schema = 'public') THEN
        EXECUTE 'DROP POLICY IF EXISTS "help_articles_anon_read" ON help_articles';
        EXECUTE 'CREATE POLICY "help_articles_anon_read" ON help_articles FOR SELECT TO anon USING (true)';
        EXECUTE 'GRANT SELECT ON help_articles TO anon';
        RAISE NOTICE 'Added anon policies to help_articles';
    END IF;

    -- BODY_COMPOSITIONS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'body_compositions' AND table_schema = 'public') THEN
        EXECUTE 'DROP POLICY IF EXISTS "body_compositions_anon_read" ON body_compositions';
        EXECUTE 'CREATE POLICY "body_compositions_anon_read" ON body_compositions FOR SELECT TO anon USING (true)';
        EXECUTE 'DROP POLICY IF EXISTS "body_compositions_anon_insert" ON body_compositions';
        EXECUTE 'CREATE POLICY "body_compositions_anon_insert" ON body_compositions FOR INSERT TO anon WITH CHECK (true)';
        EXECUTE 'GRANT SELECT, INSERT ON body_compositions TO anon';
        RAISE NOTICE 'Added anon policies to body_compositions';
    END IF;

    -- PATIENT_GOALS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'patient_goals' AND table_schema = 'public') THEN
        EXECUTE 'DROP POLICY IF EXISTS "patient_goals_anon_read" ON patient_goals';
        EXECUTE 'CREATE POLICY "patient_goals_anon_read" ON patient_goals FOR SELECT TO anon USING (true)';
        EXECUTE 'DROP POLICY IF EXISTS "patient_goals_anon_insert" ON patient_goals';
        EXECUTE 'CREATE POLICY "patient_goals_anon_insert" ON patient_goals FOR INSERT TO anon WITH CHECK (true)';
        EXECUTE 'GRANT SELECT, INSERT ON patient_goals TO anon';
        RAISE NOTICE 'Added anon policies to patient_goals';
    END IF;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    policy_count INT;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE policyname LIKE '%_anon_%';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'BUILD 326: Demo Mode RLS Fix Complete';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Total anon policies: %', policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Core tables with anon access:';
    RAISE NOTICE '  - sessions';
    RAISE NOTICE '  - session_exercises';
    RAISE NOTICE '  - exercise_templates';
    RAISE NOTICE '  - scheduled_sessions';
    RAISE NOTICE '  - programs';
    RAISE NOTICE '  - phases';
    RAISE NOTICE '  - patients';
    RAISE NOTICE '  - exercise_logs';
    RAISE NOTICE '  - manual_sessions';
    RAISE NOTICE '  - manual_session_exercises';
    RAISE NOTICE '  - patient_workout_templates';
    RAISE NOTICE '============================================';
END $$;
