-- Migration: Tighten permissive USING(true) RLS policies for 1.0 launch
--
-- Context: Migrations 20260207410000 and 20260207430000 relaxed RLS to USING(true)
-- to work around demo mode auth issues. This migration replaces those blanket-open
-- policies with proper patient-scoped policies on HIPAA-sensitive and medium-risk tables.
--
-- Demo mode: The is_own_patient() function (SECURITY DEFINER) already handles
-- demo user lookups, so demo mode continues to work without USING(true).
--
-- Tables addressed (18 from RLS_AUDIT_REPORT.md):
--   HIGH risk: arm_care_assessments, body_comp_measurements, workout_prescriptions
--   MEDIUM risk: streak_records, streak_history, daily_readiness, manual_sessions,
--                patient_goals, exercise_logs, sessions, session_exercises,
--                workout_modifications, manual_session_exercises
--   LOW risk: notification_settings, prescription_notification_preferences,
--             patient_favorite_templates, patient_workout_templates, system_workout_templates

BEGIN;

-- ============================================================
-- Helper: Drop all existing policies on a table
-- ============================================================

-- We drop and recreate to ensure no leftover USING(true) policies remain.

-- ============================================================
-- 1. streak_records (patient_id column)
-- ============================================================
DO $$ BEGIN
    -- Drop existing permissive policies
    DROP POLICY IF EXISTS "streak_records_select" ON public.streak_records;
    DROP POLICY IF EXISTS "streak_records_insert" ON public.streak_records;
    DROP POLICY IF EXISTS "streak_records_update" ON public.streak_records;
    DROP POLICY IF EXISTS "streak_records_delete" ON public.streak_records;
    DROP POLICY IF EXISTS "streak_records_all" ON public.streak_records;
    DROP POLICY IF EXISTS "Allow all access to streak_records" ON public.streak_records;
    DROP POLICY IF EXISTS "streak_records_anon_select" ON public.streak_records;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.streak_records ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "streak_records_patient_select" ON public.streak_records
        FOR SELECT TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "streak_records_patient_insert" ON public.streak_records
        FOR INSERT TO authenticated WITH CHECK (is_own_patient(patient_id));
    CREATE POLICY "streak_records_patient_update" ON public.streak_records
        FOR UPDATE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "streak_records_patient_delete" ON public.streak_records
        FOR DELETE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "streak_records_therapist_select" ON public.streak_records
        FOR SELECT TO authenticated USING (is_therapist_of_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 2. streak_history (patient_id column)
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "streak_history_select" ON public.streak_history;
    DROP POLICY IF EXISTS "streak_history_insert" ON public.streak_history;
    DROP POLICY IF EXISTS "streak_history_update" ON public.streak_history;
    DROP POLICY IF EXISTS "streak_history_delete" ON public.streak_history;
    DROP POLICY IF EXISTS "streak_history_all" ON public.streak_history;
    DROP POLICY IF EXISTS "Allow all access to streak_history" ON public.streak_history;
    DROP POLICY IF EXISTS "streak_history_anon_select" ON public.streak_history;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.streak_history ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "streak_history_patient_select" ON public.streak_history
        FOR SELECT TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "streak_history_patient_insert" ON public.streak_history
        FOR INSERT TO authenticated WITH CHECK (is_own_patient(patient_id));
    CREATE POLICY "streak_history_patient_update" ON public.streak_history
        FOR UPDATE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "streak_history_therapist_select" ON public.streak_history
        FOR SELECT TO authenticated USING (is_therapist_of_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 3. daily_readiness (patient_id column)
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "daily_readiness_select" ON public.daily_readiness;
    DROP POLICY IF EXISTS "daily_readiness_insert" ON public.daily_readiness;
    DROP POLICY IF EXISTS "daily_readiness_update" ON public.daily_readiness;
    DROP POLICY IF EXISTS "daily_readiness_delete" ON public.daily_readiness;
    DROP POLICY IF EXISTS "daily_readiness_all" ON public.daily_readiness;
    DROP POLICY IF EXISTS "Allow all access to daily_readiness" ON public.daily_readiness;
    DROP POLICY IF EXISTS "daily_readiness_anon_select" ON public.daily_readiness;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.daily_readiness ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "daily_readiness_patient_select" ON public.daily_readiness
        FOR SELECT TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "daily_readiness_patient_insert" ON public.daily_readiness
        FOR INSERT TO authenticated WITH CHECK (is_own_patient(patient_id));
    CREATE POLICY "daily_readiness_patient_update" ON public.daily_readiness
        FOR UPDATE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "daily_readiness_therapist_select" ON public.daily_readiness
        FOR SELECT TO authenticated USING (is_therapist_of_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 4. arm_care_assessments (patient_id column) — HIGH risk
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "arm_care_assessments_select" ON public.arm_care_assessments;
    DROP POLICY IF EXISTS "arm_care_assessments_insert" ON public.arm_care_assessments;
    DROP POLICY IF EXISTS "arm_care_assessments_update" ON public.arm_care_assessments;
    DROP POLICY IF EXISTS "arm_care_assessments_delete" ON public.arm_care_assessments;
    DROP POLICY IF EXISTS "arm_care_assessments_all" ON public.arm_care_assessments;
    DROP POLICY IF EXISTS "Allow all access to arm_care_assessments" ON public.arm_care_assessments;
    DROP POLICY IF EXISTS "arm_care_assessments_anon_select" ON public.arm_care_assessments;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.arm_care_assessments ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "arm_care_assessments_patient_select" ON public.arm_care_assessments
        FOR SELECT TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "arm_care_assessments_patient_insert" ON public.arm_care_assessments
        FOR INSERT TO authenticated WITH CHECK (is_own_patient(patient_id));
    CREATE POLICY "arm_care_assessments_patient_update" ON public.arm_care_assessments
        FOR UPDATE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "arm_care_assessments_therapist_select" ON public.arm_care_assessments
        FOR SELECT TO authenticated USING (is_therapist_of_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 5. body_comp_measurements (patient_id column) — HIGH risk
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "body_comp_measurements_select" ON public.body_comp_measurements;
    DROP POLICY IF EXISTS "body_comp_measurements_insert" ON public.body_comp_measurements;
    DROP POLICY IF EXISTS "body_comp_measurements_update" ON public.body_comp_measurements;
    DROP POLICY IF EXISTS "body_comp_measurements_delete" ON public.body_comp_measurements;
    DROP POLICY IF EXISTS "body_comp_measurements_all" ON public.body_comp_measurements;
    DROP POLICY IF EXISTS "Allow all access to body_comp_measurements" ON public.body_comp_measurements;
    DROP POLICY IF EXISTS "body_comp_measurements_anon_select" ON public.body_comp_measurements;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.body_comp_measurements ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "body_comp_patient_select" ON public.body_comp_measurements
        FOR SELECT TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "body_comp_patient_insert" ON public.body_comp_measurements
        FOR INSERT TO authenticated WITH CHECK (is_own_patient(patient_id));
    CREATE POLICY "body_comp_patient_update" ON public.body_comp_measurements
        FOR UPDATE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "body_comp_therapist_select" ON public.body_comp_measurements
        FOR SELECT TO authenticated USING (is_therapist_of_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 6. workout_prescriptions (patient_id column) — HIGH risk
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "workout_prescriptions_select" ON public.workout_prescriptions;
    DROP POLICY IF EXISTS "workout_prescriptions_insert" ON public.workout_prescriptions;
    DROP POLICY IF EXISTS "workout_prescriptions_update" ON public.workout_prescriptions;
    DROP POLICY IF EXISTS "workout_prescriptions_delete" ON public.workout_prescriptions;
    DROP POLICY IF EXISTS "workout_prescriptions_all" ON public.workout_prescriptions;
    DROP POLICY IF EXISTS "Allow all access to workout_prescriptions" ON public.workout_prescriptions;
    DROP POLICY IF EXISTS "workout_prescriptions_anon_select" ON public.workout_prescriptions;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.workout_prescriptions ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "workout_prescriptions_patient_select" ON public.workout_prescriptions
        FOR SELECT TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "workout_prescriptions_patient_insert" ON public.workout_prescriptions
        FOR INSERT TO authenticated WITH CHECK (is_own_patient(patient_id));
    CREATE POLICY "workout_prescriptions_patient_update" ON public.workout_prescriptions
        FOR UPDATE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "workout_prescriptions_therapist_select" ON public.workout_prescriptions
        FOR SELECT TO authenticated USING (is_therapist_of_patient(patient_id));
    CREATE POLICY "workout_prescriptions_therapist_manage" ON public.workout_prescriptions
        FOR ALL TO authenticated USING (is_therapist_of_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 7. manual_sessions (patient_id column)
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "manual_sessions_select" ON public.manual_sessions;
    DROP POLICY IF EXISTS "manual_sessions_insert" ON public.manual_sessions;
    DROP POLICY IF EXISTS "manual_sessions_update" ON public.manual_sessions;
    DROP POLICY IF EXISTS "manual_sessions_delete" ON public.manual_sessions;
    DROP POLICY IF EXISTS "manual_sessions_all" ON public.manual_sessions;
    DROP POLICY IF EXISTS "Allow all access to manual_sessions" ON public.manual_sessions;
    DROP POLICY IF EXISTS "manual_sessions_anon_select" ON public.manual_sessions;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.manual_sessions ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "manual_sessions_patient_select" ON public.manual_sessions
        FOR SELECT TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "manual_sessions_patient_insert" ON public.manual_sessions
        FOR INSERT TO authenticated WITH CHECK (is_own_patient(patient_id));
    CREATE POLICY "manual_sessions_patient_update" ON public.manual_sessions
        FOR UPDATE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "manual_sessions_patient_delete" ON public.manual_sessions
        FOR DELETE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "manual_sessions_therapist_select" ON public.manual_sessions
        FOR SELECT TO authenticated USING (is_therapist_of_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 8. patient_goals (patient_id column)
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "patient_goals_select" ON public.patient_goals;
    DROP POLICY IF EXISTS "patient_goals_insert" ON public.patient_goals;
    DROP POLICY IF EXISTS "patient_goals_update" ON public.patient_goals;
    DROP POLICY IF EXISTS "patient_goals_delete" ON public.patient_goals;
    DROP POLICY IF EXISTS "patient_goals_all" ON public.patient_goals;
    DROP POLICY IF EXISTS "Allow all access to patient_goals" ON public.patient_goals;
    DROP POLICY IF EXISTS "patient_goals_anon_select" ON public.patient_goals;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.patient_goals ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "patient_goals_patient_select" ON public.patient_goals
        FOR SELECT TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "patient_goals_patient_insert" ON public.patient_goals
        FOR INSERT TO authenticated WITH CHECK (is_own_patient(patient_id));
    CREATE POLICY "patient_goals_patient_update" ON public.patient_goals
        FOR UPDATE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "patient_goals_patient_delete" ON public.patient_goals
        FOR DELETE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "patient_goals_therapist_select" ON public.patient_goals
        FOR SELECT TO authenticated USING (is_therapist_of_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 9. exercise_logs (patient_id column)
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "exercise_logs_select" ON public.exercise_logs;
    DROP POLICY IF EXISTS "exercise_logs_insert" ON public.exercise_logs;
    DROP POLICY IF EXISTS "exercise_logs_update" ON public.exercise_logs;
    DROP POLICY IF EXISTS "exercise_logs_delete" ON public.exercise_logs;
    DROP POLICY IF EXISTS "exercise_logs_all" ON public.exercise_logs;
    DROP POLICY IF EXISTS "Allow all access to exercise_logs" ON public.exercise_logs;
    DROP POLICY IF EXISTS "exercise_logs_anon_select" ON public.exercise_logs;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.exercise_logs ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "exercise_logs_patient_select" ON public.exercise_logs
        FOR SELECT TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "exercise_logs_patient_insert" ON public.exercise_logs
        FOR INSERT TO authenticated WITH CHECK (is_own_patient(patient_id));
    CREATE POLICY "exercise_logs_patient_update" ON public.exercise_logs
        FOR UPDATE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "exercise_logs_patient_delete" ON public.exercise_logs
        FOR DELETE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "exercise_logs_therapist_select" ON public.exercise_logs
        FOR SELECT TO authenticated USING (is_therapist_of_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 10. workout_modifications (patient_id column)
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "workout_modifications_select" ON public.workout_modifications;
    DROP POLICY IF EXISTS "workout_modifications_insert" ON public.workout_modifications;
    DROP POLICY IF EXISTS "workout_modifications_update" ON public.workout_modifications;
    DROP POLICY IF EXISTS "workout_modifications_delete" ON public.workout_modifications;
    DROP POLICY IF EXISTS "workout_modifications_all" ON public.workout_modifications;
    DROP POLICY IF EXISTS "Allow all access to workout_modifications" ON public.workout_modifications;
    DROP POLICY IF EXISTS "workout_modifications_anon_select" ON public.workout_modifications;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.workout_modifications ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "workout_modifications_patient_select" ON public.workout_modifications
        FOR SELECT TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "workout_modifications_patient_insert" ON public.workout_modifications
        FOR INSERT TO authenticated WITH CHECK (is_own_patient(patient_id));
    CREATE POLICY "workout_modifications_patient_update" ON public.workout_modifications
        FOR UPDATE TO authenticated USING (is_own_patient(patient_id));
    CREATE POLICY "workout_modifications_therapist_select" ON public.workout_modifications
        FOR SELECT TO authenticated USING (is_therapist_of_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 11. notification_settings (patient_id column) — LOW risk
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "notification_settings_select" ON public.notification_settings;
    DROP POLICY IF EXISTS "notification_settings_insert" ON public.notification_settings;
    DROP POLICY IF EXISTS "notification_settings_update" ON public.notification_settings;
    DROP POLICY IF EXISTS "notification_settings_all" ON public.notification_settings;
    DROP POLICY IF EXISTS "Allow all access to notification_settings" ON public.notification_settings;
    DROP POLICY IF EXISTS "notification_settings_anon_select" ON public.notification_settings;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "notification_settings_patient_all" ON public.notification_settings
        FOR ALL TO authenticated USING (is_own_patient(patient_id)) WITH CHECK (is_own_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 12. prescription_notification_preferences (patient_id column) — LOW risk
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "prescription_notification_preferences_select" ON public.prescription_notification_preferences;
    DROP POLICY IF EXISTS "prescription_notification_preferences_insert" ON public.prescription_notification_preferences;
    DROP POLICY IF EXISTS "prescription_notification_preferences_update" ON public.prescription_notification_preferences;
    DROP POLICY IF EXISTS "prescription_notification_preferences_all" ON public.prescription_notification_preferences;
    DROP POLICY IF EXISTS "Allow all access to prescription_notification_preferences" ON public.prescription_notification_preferences;
    DROP POLICY IF EXISTS "prescription_notification_preferences_anon_select" ON public.prescription_notification_preferences;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.prescription_notification_preferences ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "prescription_notif_prefs_patient_all" ON public.prescription_notification_preferences
        FOR ALL TO authenticated USING (is_own_patient(patient_id)) WITH CHECK (is_own_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 13. patient_favorite_templates (patient_id column) — LOW risk
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "patient_favorite_templates_select" ON public.patient_favorite_templates;
    DROP POLICY IF EXISTS "patient_favorite_templates_insert" ON public.patient_favorite_templates;
    DROP POLICY IF EXISTS "patient_favorite_templates_update" ON public.patient_favorite_templates;
    DROP POLICY IF EXISTS "patient_favorite_templates_delete" ON public.patient_favorite_templates;
    DROP POLICY IF EXISTS "patient_favorite_templates_all" ON public.patient_favorite_templates;
    DROP POLICY IF EXISTS "Allow all access to patient_favorite_templates" ON public.patient_favorite_templates;
    DROP POLICY IF EXISTS "patient_favorite_templates_anon_select" ON public.patient_favorite_templates;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.patient_favorite_templates ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "patient_favorite_templates_patient_all" ON public.patient_favorite_templates
        FOR ALL TO authenticated USING (is_own_patient(patient_id)) WITH CHECK (is_own_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 14. patient_workout_templates (patient_id column) — LOW risk
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "patient_workout_templates_select" ON public.patient_workout_templates;
    DROP POLICY IF EXISTS "patient_workout_templates_insert" ON public.patient_workout_templates;
    DROP POLICY IF EXISTS "patient_workout_templates_update" ON public.patient_workout_templates;
    DROP POLICY IF EXISTS "patient_workout_templates_delete" ON public.patient_workout_templates;
    DROP POLICY IF EXISTS "patient_workout_templates_all" ON public.patient_workout_templates;
    DROP POLICY IF EXISTS "Allow all access to patient_workout_templates" ON public.patient_workout_templates;
    DROP POLICY IF EXISTS "patient_workout_templates_anon_select" ON public.patient_workout_templates;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.patient_workout_templates ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "patient_workout_templates_patient_all" ON public.patient_workout_templates
        FOR ALL TO authenticated USING (is_own_patient(patient_id)) WITH CHECK (is_own_patient(patient_id));
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 15. system_workout_templates (no patient_id — shared content)
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "system_workout_templates_select" ON public.system_workout_templates;
    DROP POLICY IF EXISTS "system_workout_templates_insert" ON public.system_workout_templates;
    DROP POLICY IF EXISTS "system_workout_templates_update" ON public.system_workout_templates;
    DROP POLICY IF EXISTS "system_workout_templates_all" ON public.system_workout_templates;
    DROP POLICY IF EXISTS "Allow all access to system_workout_templates" ON public.system_workout_templates;
    DROP POLICY IF EXISTS "system_workout_templates_anon_select" ON public.system_workout_templates;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.system_workout_templates ENABLE ROW LEVEL SECURITY;
    -- Shared content: anyone can read, only service role can write
    CREATE POLICY "system_workout_templates_read" ON public.system_workout_templates
        FOR SELECT TO authenticated, anon USING (true);
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 16. sessions (no direct patient_id — scoped via phase -> program -> patient)
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "sessions_select" ON public.sessions;
    DROP POLICY IF EXISTS "sessions_insert" ON public.sessions;
    DROP POLICY IF EXISTS "sessions_update" ON public.sessions;
    DROP POLICY IF EXISTS "sessions_delete" ON public.sessions;
    DROP POLICY IF EXISTS "sessions_all" ON public.sessions;
    DROP POLICY IF EXISTS "Allow all access to sessions" ON public.sessions;
    DROP POLICY IF EXISTS "sessions_anon_select" ON public.sessions;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
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
    CREATE POLICY "sessions_patient_update" ON public.sessions
        FOR UPDATE TO authenticated
        USING (
            EXISTS (
                SELECT 1 FROM phases ph
                JOIN programs pr ON ph.program_id = pr.id
                WHERE ph.id = sessions.phase_id
                AND (is_own_patient(pr.patient_id) OR is_therapist_of_patient(pr.patient_id))
            )
        );
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 17. session_exercises (no direct patient_id — scoped via session -> phase -> program)
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "session_exercises_select" ON public.session_exercises;
    DROP POLICY IF EXISTS "session_exercises_insert" ON public.session_exercises;
    DROP POLICY IF EXISTS "session_exercises_update" ON public.session_exercises;
    DROP POLICY IF EXISTS "session_exercises_delete" ON public.session_exercises;
    DROP POLICY IF EXISTS "session_exercises_all" ON public.session_exercises;
    DROP POLICY IF EXISTS "Allow all access to session_exercises" ON public.session_exercises;
    DROP POLICY IF EXISTS "session_exercises_anon_select" ON public.session_exercises;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.session_exercises ENABLE ROW LEVEL SECURITY;
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
    CREATE POLICY "session_exercises_patient_update" ON public.session_exercises
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
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================
-- 18. manual_session_exercises (no direct patient_id — scoped via manual_session)
-- ============================================================
DO $$ BEGIN
    DROP POLICY IF EXISTS "manual_session_exercises_select" ON public.manual_session_exercises;
    DROP POLICY IF EXISTS "manual_session_exercises_insert" ON public.manual_session_exercises;
    DROP POLICY IF EXISTS "manual_session_exercises_update" ON public.manual_session_exercises;
    DROP POLICY IF EXISTS "manual_session_exercises_delete" ON public.manual_session_exercises;
    DROP POLICY IF EXISTS "manual_session_exercises_all" ON public.manual_session_exercises;
    DROP POLICY IF EXISTS "Allow all access to manual_session_exercises" ON public.manual_session_exercises;
    DROP POLICY IF EXISTS "manual_session_exercises_anon_select" ON public.manual_session_exercises;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.manual_session_exercises ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "manual_session_exercises_patient_select" ON public.manual_session_exercises
        FOR SELECT TO authenticated
        USING (
            EXISTS (
                SELECT 1 FROM manual_sessions ms
                WHERE ms.id = manual_session_exercises.manual_session_id
                AND is_own_patient(ms.patient_id)
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
                AND is_own_patient(ms.patient_id)
            )
        );
    CREATE POLICY "manual_session_exercises_therapist_select" ON public.manual_session_exercises
        FOR SELECT TO authenticated
        USING (
            EXISTS (
                SELECT 1 FROM manual_sessions ms
                WHERE ms.id = manual_session_exercises.manual_session_id
                AND is_therapist_of_patient(ms.patient_id)
            )
        );
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

COMMIT;
