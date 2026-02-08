-- Fix RLS for remaining tables that are blocking authenticated users
-- Issues:
--   1. workout_modifications: permission denied
--   2. manual_session_exercises: permission denied
--   3. patient_favorite_templates: permission denied on insert
--   4. workout_prescriptions: needs RLS for patient access

-- ============================================================================
-- WORKOUT_MODIFICATIONS - Open for all authenticated users + demo
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'workout_modifications'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.workout_modifications', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.workout_modifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_modifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workout_modifications_select" ON public.workout_modifications FOR SELECT USING (true);
CREATE POLICY "workout_modifications_insert" ON public.workout_modifications FOR INSERT WITH CHECK (true);
CREATE POLICY "workout_modifications_update" ON public.workout_modifications FOR UPDATE USING (true);
CREATE POLICY "workout_modifications_delete" ON public.workout_modifications FOR DELETE USING (true);

GRANT ALL ON public.workout_modifications TO authenticated;
GRANT ALL ON public.workout_modifications TO anon;

-- ============================================================================
-- MANUAL_SESSION_EXERCISES - Open for all authenticated users + demo
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'manual_session_exercises'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.manual_session_exercises', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.manual_session_exercises DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.manual_session_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "manual_session_exercises_select" ON public.manual_session_exercises FOR SELECT USING (true);
CREATE POLICY "manual_session_exercises_insert" ON public.manual_session_exercises FOR INSERT WITH CHECK (true);
CREATE POLICY "manual_session_exercises_update" ON public.manual_session_exercises FOR UPDATE USING (true);
CREATE POLICY "manual_session_exercises_delete" ON public.manual_session_exercises FOR DELETE USING (true);

GRANT ALL ON public.manual_session_exercises TO authenticated;
GRANT ALL ON public.manual_session_exercises TO anon;

-- ============================================================================
-- PATIENT_FAVORITE_TEMPLATES - Fix for authenticated users
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'patient_favorite_templates'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.patient_favorite_templates', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.patient_favorite_templates DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_favorite_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_favorite_templates_select" ON public.patient_favorite_templates FOR SELECT USING (true);
CREATE POLICY "patient_favorite_templates_insert" ON public.patient_favorite_templates FOR INSERT WITH CHECK (true);
CREATE POLICY "patient_favorite_templates_update" ON public.patient_favorite_templates FOR UPDATE USING (true);
CREATE POLICY "patient_favorite_templates_delete" ON public.patient_favorite_templates FOR DELETE USING (true);

GRANT ALL ON public.patient_favorite_templates TO authenticated;
GRANT ALL ON public.patient_favorite_templates TO anon;

-- ============================================================================
-- WORKOUT_PRESCRIPTIONS - Ensure patients can access their prescriptions
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'workout_prescriptions'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.workout_prescriptions', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.workout_prescriptions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workout_prescriptions_select" ON public.workout_prescriptions FOR SELECT USING (true);
CREATE POLICY "workout_prescriptions_insert" ON public.workout_prescriptions FOR INSERT WITH CHECK (true);
CREATE POLICY "workout_prescriptions_update" ON public.workout_prescriptions FOR UPDATE USING (true);
CREATE POLICY "workout_prescriptions_delete" ON public.workout_prescriptions FOR DELETE USING (true);

GRANT ALL ON public.workout_prescriptions TO authenticated;
GRANT ALL ON public.workout_prescriptions TO anon;

-- ============================================================================
-- SESSIONS - Ensure patients can access their program sessions
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'sessions'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.sessions', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sessions_select" ON public.sessions FOR SELECT USING (true);
CREATE POLICY "sessions_insert" ON public.sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "sessions_update" ON public.sessions FOR UPDATE USING (true);
CREATE POLICY "sessions_delete" ON public.sessions FOR DELETE USING (true);

GRANT ALL ON public.sessions TO authenticated;
GRANT ALL ON public.sessions TO anon;

-- ============================================================================
-- SESSION_EXERCISES - Ensure patients can access exercises in their sessions
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'session_exercises'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.session_exercises', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.session_exercises DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "session_exercises_select" ON public.session_exercises FOR SELECT USING (true);
CREATE POLICY "session_exercises_insert" ON public.session_exercises FOR INSERT WITH CHECK (true);
CREATE POLICY "session_exercises_update" ON public.session_exercises FOR UPDATE USING (true);
CREATE POLICY "session_exercises_delete" ON public.session_exercises FOR DELETE USING (true);

GRANT ALL ON public.session_exercises TO authenticated;
GRANT ALL ON public.session_exercises TO anon;

-- ============================================================================
-- EXERCISE_LOGS - Ensure patients can log their exercises
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'exercise_logs'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.exercise_logs', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.exercise_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "exercise_logs_select" ON public.exercise_logs FOR SELECT USING (true);
CREATE POLICY "exercise_logs_insert" ON public.exercise_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "exercise_logs_update" ON public.exercise_logs FOR UPDATE USING (true);
CREATE POLICY "exercise_logs_delete" ON public.exercise_logs FOR DELETE USING (true);

GRANT ALL ON public.exercise_logs TO authenticated;
GRANT ALL ON public.exercise_logs TO anon;

-- ============================================================================
-- PATIENT_WORKOUT_TEMPLATES - Ensure patients can create templates
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'patient_workout_templates'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.patient_workout_templates', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.patient_workout_templates DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_workout_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_workout_templates_select" ON public.patient_workout_templates FOR SELECT USING (true);
CREATE POLICY "patient_workout_templates_insert" ON public.patient_workout_templates FOR INSERT WITH CHECK (true);
CREATE POLICY "patient_workout_templates_update" ON public.patient_workout_templates FOR UPDATE USING (true);
CREATE POLICY "patient_workout_templates_delete" ON public.patient_workout_templates FOR DELETE USING (true);

GRANT ALL ON public.patient_workout_templates TO authenticated;
GRANT ALL ON public.patient_workout_templates TO anon;

-- ============================================================================
-- SYSTEM_WORKOUT_TEMPLATES - Read access for all
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'system_workout_templates'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.system_workout_templates', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.system_workout_templates DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_workout_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "system_workout_templates_select" ON public.system_workout_templates FOR SELECT USING (true);
CREATE POLICY "system_workout_templates_insert" ON public.system_workout_templates FOR INSERT WITH CHECK (true);
CREATE POLICY "system_workout_templates_update" ON public.system_workout_templates FOR UPDATE USING (true);

GRANT SELECT ON public.system_workout_templates TO authenticated;
GRANT SELECT ON public.system_workout_templates TO anon;
GRANT INSERT, UPDATE ON public.system_workout_templates TO authenticated;

-- ============================================================================
-- Force schema reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Fixed RLS for 9 tables:';
    RAISE NOTICE '  - workout_modifications';
    RAISE NOTICE '  - manual_session_exercises';
    RAISE NOTICE '  - patient_favorite_templates';
    RAISE NOTICE '  - workout_prescriptions';
    RAISE NOTICE '  - sessions';
    RAISE NOTICE '  - session_exercises';
    RAISE NOTICE '  - exercise_logs';
    RAISE NOTICE '  - patient_workout_templates';
    RAISE NOTICE '  - system_workout_templates';
    RAISE NOTICE '============================================';
END $$;
