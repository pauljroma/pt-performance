-- ============================================================================
-- TIGHTEN DEMO RLS MIGRATION
-- Date: 2026-02-22
-- Purpose: Replace overly permissive USING(true) policies on 18 tables
--          with proper auth.uid()-scoped policies.
--
-- PREREQUISITE: The demo-auth edge function must be deployed so that
--   demo users get real Supabase Auth sessions. Without this, demo mode
--   will break because auth.uid() will return NULL.
--
-- This migration reverses the blanket USING(true) policies introduced in:
--   - 20260207410000_fix_all_remaining_rls.sql
--   - 20260207430000_fix_remaining_rls_comprehensive.sql
--
-- It uses the helper functions from 20260222120000_rls_audit_fixes.sql:
--   - is_own_patient(patient_id) -- checks if patient belongs to current user
--   - is_therapist_of_patient(patient_id) -- checks therapist-patient relationship
--   - is_therapist() -- checks if current user is a therapist
--
-- Pattern for tables with direct patient_id:
--   SELECT: is_own_patient(patient_id) OR is_therapist_of_patient(patient_id)
--   INSERT: is_own_patient(patient_id)
--   UPDATE: is_own_patient(patient_id)
--   DELETE: is_own_patient(patient_id)
--   + service_role full access
--
-- Pattern for tables with indirect patient relationship (sessions chain):
--   SELECT: via JOIN to programs.patient_id
--   INSERT/UPDATE: therapists can manage, patients can update own
--   + service_role full access
--
-- Pattern for shared content (system_workout_templates):
--   SELECT: all authenticated
--   INSERT/UPDATE: therapists only
--   + service_role full access
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. streak_records (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'streak_records' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.streak_records', pol.policyname); END LOOP;
END $$;

CREATE POLICY "streak_records_patient_select" ON public.streak_records
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "streak_records_patient_insert" ON public.streak_records
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "streak_records_patient_update" ON public.streak_records
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "streak_records_patient_delete" ON public.streak_records
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "streak_records_service_role" ON public.streak_records
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.streak_records FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.streak_records TO authenticated;
GRANT ALL ON public.streak_records TO service_role;


-- ============================================================================
-- 2. streak_history (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'streak_history' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.streak_history', pol.policyname); END LOOP;
END $$;

CREATE POLICY "streak_history_patient_select" ON public.streak_history
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "streak_history_patient_insert" ON public.streak_history
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "streak_history_patient_update" ON public.streak_history
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "streak_history_patient_delete" ON public.streak_history
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "streak_history_service_role" ON public.streak_history
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.streak_history FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.streak_history TO authenticated;
GRANT ALL ON public.streak_history TO service_role;


-- ============================================================================
-- 3. daily_readiness (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.daily_readiness', pol.policyname); END LOOP;
END $$;

CREATE POLICY "daily_readiness_patient_select" ON public.daily_readiness
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "daily_readiness_patient_insert" ON public.daily_readiness
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "daily_readiness_patient_update" ON public.daily_readiness
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "daily_readiness_patient_delete" ON public.daily_readiness
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "daily_readiness_service_role" ON public.daily_readiness
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.daily_readiness FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.daily_readiness TO authenticated;
GRANT ALL ON public.daily_readiness TO service_role;


-- ============================================================================
-- 4. arm_care_assessments (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'arm_care_assessments' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.arm_care_assessments', pol.policyname); END LOOP;
END $$;

CREATE POLICY "arm_care_assessments_patient_select" ON public.arm_care_assessments
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "arm_care_assessments_patient_insert" ON public.arm_care_assessments
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "arm_care_assessments_patient_update" ON public.arm_care_assessments
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "arm_care_assessments_patient_delete" ON public.arm_care_assessments
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "arm_care_assessments_service_role" ON public.arm_care_assessments
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.arm_care_assessments FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.arm_care_assessments TO authenticated;
GRANT ALL ON public.arm_care_assessments TO service_role;


-- ============================================================================
-- 5. body_comp_measurements (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'body_comp_measurements' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.body_comp_measurements', pol.policyname); END LOOP;
END $$;

CREATE POLICY "body_comp_measurements_patient_select" ON public.body_comp_measurements
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "body_comp_measurements_patient_insert" ON public.body_comp_measurements
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "body_comp_measurements_patient_update" ON public.body_comp_measurements
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "body_comp_measurements_patient_delete" ON public.body_comp_measurements
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "body_comp_measurements_service_role" ON public.body_comp_measurements
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.body_comp_measurements FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.body_comp_measurements TO authenticated;
GRANT ALL ON public.body_comp_measurements TO service_role;


-- ============================================================================
-- 6. manual_sessions (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'manual_sessions' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.manual_sessions', pol.policyname); END LOOP;
END $$;

CREATE POLICY "manual_sessions_patient_select" ON public.manual_sessions
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "manual_sessions_patient_insert" ON public.manual_sessions
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "manual_sessions_patient_update" ON public.manual_sessions
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "manual_sessions_patient_delete" ON public.manual_sessions
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "manual_sessions_service_role" ON public.manual_sessions
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.manual_sessions FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.manual_sessions TO authenticated;
GRANT ALL ON public.manual_sessions TO service_role;


-- ============================================================================
-- 7. patient_goals (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'patient_goals' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.patient_goals', pol.policyname); END LOOP;
END $$;

CREATE POLICY "patient_goals_patient_select" ON public.patient_goals
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "patient_goals_patient_insert" ON public.patient_goals
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "patient_goals_patient_update" ON public.patient_goals
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "patient_goals_patient_delete" ON public.patient_goals
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "patient_goals_service_role" ON public.patient_goals
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.patient_goals FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.patient_goals TO authenticated;
GRANT ALL ON public.patient_goals TO service_role;


-- ============================================================================
-- 8. notification_settings (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'notification_settings' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.notification_settings', pol.policyname); END LOOP;
END $$;

CREATE POLICY "notification_settings_patient_select" ON public.notification_settings
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "notification_settings_patient_insert" ON public.notification_settings
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "notification_settings_patient_update" ON public.notification_settings
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "notification_settings_patient_delete" ON public.notification_settings
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "notification_settings_service_role" ON public.notification_settings
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.notification_settings FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_settings TO authenticated;
GRANT ALL ON public.notification_settings TO service_role;


-- ============================================================================
-- 9. prescription_notification_preferences (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'prescription_notification_preferences' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.prescription_notification_preferences', pol.policyname); END LOOP;
END $$;

CREATE POLICY "rx_notif_prefs_patient_select" ON public.prescription_notification_preferences
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "rx_notif_prefs_patient_insert" ON public.prescription_notification_preferences
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "rx_notif_prefs_patient_update" ON public.prescription_notification_preferences
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "rx_notif_prefs_patient_delete" ON public.prescription_notification_preferences
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "rx_notif_prefs_service_role" ON public.prescription_notification_preferences
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.prescription_notification_preferences FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.prescription_notification_preferences TO authenticated;
GRANT ALL ON public.prescription_notification_preferences TO service_role;


-- ============================================================================
-- 10. workout_modifications (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'workout_modifications' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.workout_modifications', pol.policyname); END LOOP;
END $$;

CREATE POLICY "workout_modifications_patient_select" ON public.workout_modifications
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "workout_modifications_patient_insert" ON public.workout_modifications
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "workout_modifications_patient_update" ON public.workout_modifications
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "workout_modifications_patient_delete" ON public.workout_modifications
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "workout_modifications_service_role" ON public.workout_modifications
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.workout_modifications FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_modifications TO authenticated;
GRANT ALL ON public.workout_modifications TO service_role;


-- ============================================================================
-- 11. patient_favorite_templates (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'patient_favorite_templates' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.patient_favorite_templates', pol.policyname); END LOOP;
END $$;

CREATE POLICY "patient_favorite_templates_patient_select" ON public.patient_favorite_templates
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "patient_favorite_templates_patient_insert" ON public.patient_favorite_templates
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "patient_favorite_templates_patient_update" ON public.patient_favorite_templates
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "patient_favorite_templates_patient_delete" ON public.patient_favorite_templates
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "patient_favorite_templates_service_role" ON public.patient_favorite_templates
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.patient_favorite_templates FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.patient_favorite_templates TO authenticated;
GRANT ALL ON public.patient_favorite_templates TO service_role;


-- ============================================================================
-- 12. workout_prescriptions (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'workout_prescriptions' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.workout_prescriptions', pol.policyname); END LOOP;
END $$;

CREATE POLICY "workout_prescriptions_patient_select" ON public.workout_prescriptions
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "workout_prescriptions_therapist_insert" ON public.workout_prescriptions
    FOR INSERT TO authenticated
    WITH CHECK (is_therapist());

CREATE POLICY "workout_prescriptions_therapist_update" ON public.workout_prescriptions
    FOR UPDATE TO authenticated
    USING (is_therapist_of_patient(patient_id) OR is_own_patient(patient_id));

CREATE POLICY "workout_prescriptions_patient_delete" ON public.workout_prescriptions
    FOR DELETE TO authenticated
    USING (is_therapist_of_patient(patient_id));

CREATE POLICY "workout_prescriptions_service_role" ON public.workout_prescriptions
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.workout_prescriptions FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_prescriptions TO authenticated;
GRANT ALL ON public.workout_prescriptions TO service_role;


-- ============================================================================
-- 13. exercise_logs (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'exercise_logs' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.exercise_logs', pol.policyname); END LOOP;
END $$;

CREATE POLICY "exercise_logs_patient_select" ON public.exercise_logs
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "exercise_logs_patient_insert" ON public.exercise_logs
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "exercise_logs_patient_update" ON public.exercise_logs
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "exercise_logs_patient_delete" ON public.exercise_logs
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "exercise_logs_service_role" ON public.exercise_logs
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.exercise_logs FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.exercise_logs TO authenticated;
GRANT ALL ON public.exercise_logs TO service_role;


-- ============================================================================
-- 14. patient_workout_templates (patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'patient_workout_templates' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.patient_workout_templates', pol.policyname); END LOOP;
END $$;

CREATE POLICY "patient_workout_templates_patient_select" ON public.patient_workout_templates
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id) OR is_therapist_of_patient(patient_id));

CREATE POLICY "patient_workout_templates_patient_insert" ON public.patient_workout_templates
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "patient_workout_templates_patient_update" ON public.patient_workout_templates
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "patient_workout_templates_patient_delete" ON public.patient_workout_templates
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "patient_workout_templates_service_role" ON public.patient_workout_templates
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.patient_workout_templates FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.patient_workout_templates TO authenticated;
GRANT ALL ON public.patient_workout_templates TO service_role;


-- ============================================================================
-- 15. sessions (indirect: phase_id -> phases -> programs -> patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'sessions' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.sessions', pol.policyname); END LOOP;
END $$;

CREATE POLICY "sessions_patient_select" ON public.sessions
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM phases ph
            JOIN programs pr ON ph.program_id = pr.id
            WHERE ph.id = sessions.phase_id
            AND (is_own_patient(pr.patient_id) OR is_therapist_of_patient(pr.patient_id))
        )
    );

CREATE POLICY "sessions_therapist_insert" ON public.sessions
    FOR INSERT TO authenticated
    WITH CHECK (
        is_therapist()
        OR EXISTS (
            SELECT 1 FROM phases ph
            JOIN programs pr ON ph.program_id = pr.id
            WHERE ph.id = sessions.phase_id
            AND is_own_patient(pr.patient_id)
        )
    );

CREATE POLICY "sessions_update" ON public.sessions
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM phases ph
            JOIN programs pr ON ph.program_id = pr.id
            WHERE ph.id = sessions.phase_id
            AND (is_own_patient(pr.patient_id) OR is_therapist_of_patient(pr.patient_id))
        )
    );

CREATE POLICY "sessions_delete" ON public.sessions
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM phases ph
            JOIN programs pr ON ph.program_id = pr.id
            WHERE ph.id = sessions.phase_id
            AND is_therapist_of_patient(pr.patient_id)
        )
    );

CREATE POLICY "sessions_service_role" ON public.sessions
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.sessions FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sessions TO authenticated;
GRANT ALL ON public.sessions TO service_role;


-- ============================================================================
-- 16. session_exercises (indirect: session_id -> sessions -> phases -> programs)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'session_exercises' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.session_exercises', pol.policyname); END LOOP;
END $$;

CREATE POLICY "session_exercises_patient_select" ON public.session_exercises
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sessions s
            JOIN phases ph ON s.phase_id = ph.id
            JOIN programs pr ON ph.program_id = pr.id
            WHERE s.id = session_exercises.session_id
            AND (is_own_patient(pr.patient_id) OR is_therapist_of_patient(pr.patient_id))
        )
    );

CREATE POLICY "session_exercises_insert" ON public.session_exercises
    FOR INSERT TO authenticated
    WITH CHECK (
        is_therapist()
        OR EXISTS (
            SELECT 1 FROM sessions s
            JOIN phases ph ON s.phase_id = ph.id
            JOIN programs pr ON ph.program_id = pr.id
            WHERE s.id = session_exercises.session_id
            AND is_own_patient(pr.patient_id)
        )
    );

CREATE POLICY "session_exercises_update" ON public.session_exercises
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sessions s
            JOIN phases ph ON s.phase_id = ph.id
            JOIN programs pr ON ph.program_id = pr.id
            WHERE s.id = session_exercises.session_id
            AND (is_own_patient(pr.patient_id) OR is_therapist_of_patient(pr.patient_id))
        )
    );

CREATE POLICY "session_exercises_delete" ON public.session_exercises
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sessions s
            JOIN phases ph ON s.phase_id = ph.id
            JOIN programs pr ON ph.program_id = pr.id
            WHERE s.id = session_exercises.session_id
            AND is_therapist_of_patient(pr.patient_id)
        )
    );

CREATE POLICY "session_exercises_service_role" ON public.session_exercises
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.session_exercises FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.session_exercises TO authenticated;
GRANT ALL ON public.session_exercises TO service_role;


-- ============================================================================
-- 17. manual_session_exercises (indirect: manual_session_id -> manual_sessions)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'manual_session_exercises' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.manual_session_exercises', pol.policyname); END LOOP;
END $$;

CREATE POLICY "manual_session_exercises_patient_select" ON public.manual_session_exercises
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM manual_sessions ms
            WHERE ms.id = manual_session_exercises.manual_session_id
            AND (is_own_patient(ms.patient_id) OR is_therapist_of_patient(ms.patient_id))
        )
    );

CREATE POLICY "manual_session_exercises_patient_insert" ON public.manual_session_exercises
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM manual_sessions ms
            WHERE ms.id = manual_session_exercises.manual_session_id
            AND is_own_patient(ms.patient_id)
        )
    );

CREATE POLICY "manual_session_exercises_patient_update" ON public.manual_session_exercises
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM manual_sessions ms
            WHERE ms.id = manual_session_exercises.manual_session_id
            AND (is_own_patient(ms.patient_id) OR is_therapist_of_patient(ms.patient_id))
        )
    );

CREATE POLICY "manual_session_exercises_patient_delete" ON public.manual_session_exercises
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM manual_sessions ms
            WHERE ms.id = manual_session_exercises.manual_session_id
            AND is_own_patient(ms.patient_id)
        )
    );

CREATE POLICY "manual_session_exercises_service_role" ON public.manual_session_exercises
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.manual_session_exercises FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.manual_session_exercises TO authenticated;
GRANT ALL ON public.manual_session_exercises TO service_role;


-- ============================================================================
-- 18. system_workout_templates (shared content -- no patient_id)
-- ============================================================================

DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'system_workout_templates' AND schemaname = 'public'
    LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.system_workout_templates', pol.policyname); END LOOP;
END $$;

-- All authenticated users can read system templates
CREATE POLICY "system_workout_templates_authenticated_select" ON public.system_workout_templates
    FOR SELECT TO authenticated
    USING (true);

-- Therapists can create/update system templates
CREATE POLICY "system_workout_templates_therapist_insert" ON public.system_workout_templates
    FOR INSERT TO authenticated
    WITH CHECK (is_therapist());

CREATE POLICY "system_workout_templates_therapist_update" ON public.system_workout_templates
    FOR UPDATE TO authenticated
    USING (is_therapist());

CREATE POLICY "system_workout_templates_service_role" ON public.system_workout_templates
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

REVOKE ALL ON public.system_workout_templates FROM anon;
GRANT SELECT ON public.system_workout_templates TO authenticated;
GRANT INSERT, UPDATE ON public.system_workout_templates TO authenticated;
GRANT ALL ON public.system_workout_templates TO service_role;


-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    tbl TEXT;
    policy_count INT;
    has_using_true BOOLEAN;
    tightened TEXT[] := '{}';
    still_open TEXT[] := '{}';
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'streak_records', 'streak_history', 'daily_readiness',
        'arm_care_assessments', 'body_comp_measurements', 'manual_sessions',
        'patient_goals', 'notification_settings', 'prescription_notification_preferences',
        'workout_modifications', 'patient_favorite_templates', 'workout_prescriptions',
        'exercise_logs', 'patient_workout_templates', 'sessions',
        'session_exercises', 'manual_session_exercises', 'system_workout_templates'
    ]
    LOOP
        SELECT COUNT(*) INTO policy_count
        FROM pg_policies
        WHERE tablename = tbl AND schemaname = 'public';

        -- Check if any non-service_role policy still uses USING(true)
        SELECT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE tablename = tbl AND schemaname = 'public'
            AND policyname NOT LIKE '%service_role%'
            AND policyname NOT LIKE '%authenticated_select%'  -- system templates OK
            AND qual = 'true'
        ) INTO has_using_true;

        IF has_using_true THEN
            still_open := array_append(still_open, format('%s (%s policies)', tbl, policy_count));
        ELSE
            tightened := array_append(tightened, format('%s (%s policies)', tbl, policy_count));
        END IF;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'RLS TIGHTENING MIGRATION COMPLETE -- 2026-02-22';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables tightened (USING(true) removed):';
    FOREACH tbl IN ARRAY tightened
    LOOP
        RAISE NOTICE '  OK  %', tbl;
    END LOOP;

    IF array_length(still_open, 1) > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE 'WARNING -- Tables that may still have open policies:';
        FOREACH tbl IN ARRAY still_open
        LOOP
            RAISE NOTICE '  WARN  %', tbl;
        END LOOP;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
END $$;


-- ============================================================================
-- Force PostgREST schema cache reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

COMMIT;
