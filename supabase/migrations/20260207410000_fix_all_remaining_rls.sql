-- Fix RLS for all tables that demo patient needs to access
-- These tables have policies that check auth.uid() which returns NULL for demo mode

-- ============================================================================
-- STREAK RECORDS
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'streak_records'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.streak_records', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.streak_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.streak_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "streak_records_select" ON public.streak_records FOR SELECT USING (true);
CREATE POLICY "streak_records_insert" ON public.streak_records FOR INSERT WITH CHECK (true);
CREATE POLICY "streak_records_update" ON public.streak_records FOR UPDATE USING (true);
CREATE POLICY "streak_records_delete" ON public.streak_records FOR DELETE USING (true);

GRANT ALL ON public.streak_records TO authenticated;
GRANT ALL ON public.streak_records TO anon;

-- ============================================================================
-- STREAK HISTORY
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'streak_history'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.streak_history', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.streak_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.streak_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "streak_history_select" ON public.streak_history FOR SELECT USING (true);
CREATE POLICY "streak_history_insert" ON public.streak_history FOR INSERT WITH CHECK (true);
CREATE POLICY "streak_history_update" ON public.streak_history FOR UPDATE USING (true);
CREATE POLICY "streak_history_delete" ON public.streak_history FOR DELETE USING (true);

GRANT ALL ON public.streak_history TO authenticated;
GRANT ALL ON public.streak_history TO anon;

-- ============================================================================
-- DAILY READINESS
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.daily_readiness', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.daily_readiness DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_readiness ENABLE ROW LEVEL SECURITY;

CREATE POLICY "daily_readiness_select" ON public.daily_readiness FOR SELECT USING (true);
CREATE POLICY "daily_readiness_insert" ON public.daily_readiness FOR INSERT WITH CHECK (true);
CREATE POLICY "daily_readiness_update" ON public.daily_readiness FOR UPDATE USING (true);
CREATE POLICY "daily_readiness_delete" ON public.daily_readiness FOR DELETE USING (true);

GRANT ALL ON public.daily_readiness TO authenticated;
GRANT ALL ON public.daily_readiness TO anon;

-- ============================================================================
-- ARM CARE ASSESSMENTS
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'arm_care_assessments'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.arm_care_assessments', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.arm_care_assessments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.arm_care_assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "arm_care_assessments_select" ON public.arm_care_assessments FOR SELECT USING (true);
CREATE POLICY "arm_care_assessments_insert" ON public.arm_care_assessments FOR INSERT WITH CHECK (true);
CREATE POLICY "arm_care_assessments_update" ON public.arm_care_assessments FOR UPDATE USING (true);
CREATE POLICY "arm_care_assessments_delete" ON public.arm_care_assessments FOR DELETE USING (true);

GRANT ALL ON public.arm_care_assessments TO authenticated;
GRANT ALL ON public.arm_care_assessments TO anon;

-- ============================================================================
-- BODY COMP MEASUREMENTS
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'body_comp_measurements'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.body_comp_measurements', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.body_comp_measurements DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_comp_measurements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "body_comp_measurements_select" ON public.body_comp_measurements FOR SELECT USING (true);
CREATE POLICY "body_comp_measurements_insert" ON public.body_comp_measurements FOR INSERT WITH CHECK (true);
CREATE POLICY "body_comp_measurements_update" ON public.body_comp_measurements FOR UPDATE USING (true);
CREATE POLICY "body_comp_measurements_delete" ON public.body_comp_measurements FOR DELETE USING (true);

GRANT ALL ON public.body_comp_measurements TO authenticated;
GRANT ALL ON public.body_comp_measurements TO anon;

-- ============================================================================
-- MANUAL SESSIONS
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'manual_sessions'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.manual_sessions', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.manual_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.manual_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "manual_sessions_select" ON public.manual_sessions FOR SELECT USING (true);
CREATE POLICY "manual_sessions_insert" ON public.manual_sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "manual_sessions_update" ON public.manual_sessions FOR UPDATE USING (true);
CREATE POLICY "manual_sessions_delete" ON public.manual_sessions FOR DELETE USING (true);

GRANT ALL ON public.manual_sessions TO authenticated;
GRANT ALL ON public.manual_sessions TO anon;

-- ============================================================================
-- PATIENT GOALS
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'patient_goals'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.patient_goals', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.patient_goals DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_goals_select" ON public.patient_goals FOR SELECT USING (true);
CREATE POLICY "patient_goals_insert" ON public.patient_goals FOR INSERT WITH CHECK (true);
CREATE POLICY "patient_goals_update" ON public.patient_goals FOR UPDATE USING (true);
CREATE POLICY "patient_goals_delete" ON public.patient_goals FOR DELETE USING (true);

GRANT ALL ON public.patient_goals TO authenticated;
GRANT ALL ON public.patient_goals TO anon;

-- ============================================================================
-- NOTIFICATION SETTINGS
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'notification_settings'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.notification_settings', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.notification_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notification_settings_select" ON public.notification_settings FOR SELECT USING (true);
CREATE POLICY "notification_settings_insert" ON public.notification_settings FOR INSERT WITH CHECK (true);
CREATE POLICY "notification_settings_update" ON public.notification_settings FOR UPDATE USING (true);
CREATE POLICY "notification_settings_delete" ON public.notification_settings FOR DELETE USING (true);

GRANT ALL ON public.notification_settings TO authenticated;
GRANT ALL ON public.notification_settings TO anon;

-- ============================================================================
-- PRESCRIPTION NOTIFICATION PREFERENCES
-- ============================================================================

DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'prescription_notification_preferences'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.prescription_notification_preferences', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.prescription_notification_preferences DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescription_notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "prescription_notification_preferences_select" ON public.prescription_notification_preferences FOR SELECT USING (true);
CREATE POLICY "prescription_notification_preferences_insert" ON public.prescription_notification_preferences FOR INSERT WITH CHECK (true);
CREATE POLICY "prescription_notification_preferences_update" ON public.prescription_notification_preferences FOR UPDATE USING (true);
CREATE POLICY "prescription_notification_preferences_delete" ON public.prescription_notification_preferences FOR DELETE USING (true);

GRANT ALL ON public.prescription_notification_preferences TO authenticated;
GRANT ALL ON public.prescription_notification_preferences TO anon;

-- ============================================================================
-- Force schema reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
