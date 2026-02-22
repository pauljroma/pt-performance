-- ============================================================================
-- RLS AUDIT FIX MIGRATION
-- Date: 2026-02-22
-- Purpose: Comprehensive Row Level Security audit and remediation
--
-- This migration addresses findings from a full RLS audit of all tables
-- in the Modus PT Performance database. It:
--   1. Enables RLS on tables that currently lack it
--   2. Adds proper user-scoped policies where missing
--   3. Documents overly permissive policies (USING(true)) for future tightening
--   4. Leaves LIMS tables (separate system) and system/config tables as-is
--      with appropriate documentation
--
-- IMPORTANT: This migration is safe to run (idempotent). It uses:
--   - ALTER TABLE ... ENABLE ROW LEVEL SECURITY (no-op if already enabled)
--   - DROP POLICY IF EXISTS before CREATE POLICY
--   - DO $$ blocks with IF NOT EXISTS checks
--
-- Categories:
--   CRITICAL: Patient health data exposed without RLS
--   HIGH:     User-identifiable data exposed without RLS
--   MEDIUM:   Overly permissive policies (USING(true)) on patient data
--   LOW:      System/config tables without RLS (acceptable in some cases)
--   INFO:     LIMS tables (separate system, addressed separately)
-- ============================================================================

BEGIN;

-- ============================================================================
-- HELPER: Ensure is_therapist() and is_patient_owner() functions exist
-- ============================================================================

-- is_therapist: checks if current user is a therapist
CREATE OR REPLACE FUNCTION public.is_therapist()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.therapists
        WHERE user_id = auth.uid()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_therapist() TO authenticated;

-- is_own_patient: checks if a patient_id belongs to the current user
CREATE OR REPLACE FUNCTION public.is_own_patient(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.patients
        WHERE id = p_patient_id
        AND (
            user_id = auth.uid()
            OR id = '00000000-0000-0000-0000-000000000001'::uuid  -- demo patient
        )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_own_patient(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_own_patient(UUID) TO anon;

-- is_therapist_of_patient: checks if current user is the therapist for a patient
CREATE OR REPLACE FUNCTION public.is_therapist_of_patient(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.therapist_patients
        WHERE therapist_id = auth.uid()
        AND patient_id = p_patient_id
    ) OR EXISTS (
        SELECT 1 FROM public.patients p
        JOIN public.therapists t ON p.therapist_id = t.id
        WHERE p.id = p_patient_id
        AND t.user_id = auth.uid()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_therapist_of_patient(UUID) TO authenticated;


-- ============================================================================
-- CRITICAL FIX 1: therapists table — NO RLS
-- Contains: first_name, last_name, email, credentials, specialty
-- Risk: Any anonymous/authenticated user can read all therapist PII
-- ============================================================================

ALTER TABLE public.therapists ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "therapists_own_select" ON public.therapists;
DROP POLICY IF EXISTS "therapists_own_update" ON public.therapists;
DROP POLICY IF EXISTS "therapists_authenticated_select" ON public.therapists;
DROP POLICY IF EXISTS "therapists_service_role" ON public.therapists;

-- Therapists can view their own record
CREATE POLICY "therapists_own_select" ON public.therapists
    FOR SELECT
    TO authenticated
    USING (
        user_id = auth.uid()
        OR is_therapist()  -- therapists can see other therapists (for referrals)
    );

-- Therapists can update their own record
CREATE POLICY "therapists_own_update" ON public.therapists
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Patients need to see their therapist's basic info (name, credentials)
CREATE POLICY "therapists_authenticated_select" ON public.therapists
    FOR SELECT
    TO authenticated
    USING (
        id IN (SELECT therapist_id FROM patients WHERE user_id = auth.uid())
    );

-- Service role full access
CREATE POLICY "therapists_service_role" ON public.therapists
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

GRANT SELECT ON public.therapists TO authenticated;
GRANT ALL ON public.therapists TO service_role;


-- ============================================================================
-- CRITICAL FIX 2: pain_logs — NO RLS
-- Contains: patient pain scores, body region, clinical notes
-- Risk: All patient pain data exposed to any user
-- ============================================================================

ALTER TABLE public.pain_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pain_logs_patient_select" ON public.pain_logs;
DROP POLICY IF EXISTS "pain_logs_patient_insert" ON public.pain_logs;
DROP POLICY IF EXISTS "pain_logs_patient_update" ON public.pain_logs;
DROP POLICY IF EXISTS "pain_logs_patient_delete" ON public.pain_logs;
DROP POLICY IF EXISTS "pain_logs_therapist_select" ON public.pain_logs;
DROP POLICY IF EXISTS "pain_logs_anon_select" ON public.pain_logs;
DROP POLICY IF EXISTS "pain_logs_service_role" ON public.pain_logs;

-- Patients can manage their own pain logs
CREATE POLICY "pain_logs_patient_select" ON public.pain_logs
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "pain_logs_patient_insert" ON public.pain_logs
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "pain_logs_patient_update" ON public.pain_logs
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "pain_logs_patient_delete" ON public.pain_logs
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

-- Therapists can view their patients' pain logs
CREATE POLICY "pain_logs_therapist_select" ON public.pain_logs
    FOR SELECT TO authenticated
    USING (is_therapist_of_patient(patient_id));

-- Demo mode: anon can read demo patient's pain logs
CREATE POLICY "pain_logs_anon_select" ON public.pain_logs
    FOR SELECT TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Service role full access
CREATE POLICY "pain_logs_service_role" ON public.pain_logs
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.pain_logs TO authenticated;
GRANT SELECT ON public.pain_logs TO anon;


-- ============================================================================
-- CRITICAL FIX 3: bullpen_logs — NO RLS
-- Contains: pitch counts, velocity, pain scores — athlete health data
-- ============================================================================

ALTER TABLE public.bullpen_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bullpen_logs_patient_select" ON public.bullpen_logs;
DROP POLICY IF EXISTS "bullpen_logs_patient_insert" ON public.bullpen_logs;
DROP POLICY IF EXISTS "bullpen_logs_patient_update" ON public.bullpen_logs;
DROP POLICY IF EXISTS "bullpen_logs_patient_delete" ON public.bullpen_logs;
DROP POLICY IF EXISTS "bullpen_logs_therapist_select" ON public.bullpen_logs;
DROP POLICY IF EXISTS "bullpen_logs_anon_select" ON public.bullpen_logs;
DROP POLICY IF EXISTS "bullpen_logs_service_role" ON public.bullpen_logs;

CREATE POLICY "bullpen_logs_patient_select" ON public.bullpen_logs
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "bullpen_logs_patient_insert" ON public.bullpen_logs
    FOR INSERT TO authenticated
    WITH CHECK (is_own_patient(patient_id));

CREATE POLICY "bullpen_logs_patient_update" ON public.bullpen_logs
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "bullpen_logs_patient_delete" ON public.bullpen_logs
    FOR DELETE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "bullpen_logs_therapist_select" ON public.bullpen_logs
    FOR SELECT TO authenticated
    USING (is_therapist_of_patient(patient_id));

CREATE POLICY "bullpen_logs_anon_select" ON public.bullpen_logs
    FOR SELECT TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "bullpen_logs_service_role" ON public.bullpen_logs
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.bullpen_logs TO authenticated;
GRANT SELECT ON public.bullpen_logs TO anon;


-- ============================================================================
-- CRITICAL FIX 4: session_notes — NO RLS
-- Contains: Clinical documentation, therapist notes — HIPAA-sensitive
-- ============================================================================

ALTER TABLE public.session_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "session_notes_patient_select" ON public.session_notes;
DROP POLICY IF EXISTS "session_notes_therapist_select" ON public.session_notes;
DROP POLICY IF EXISTS "session_notes_therapist_insert" ON public.session_notes;
DROP POLICY IF EXISTS "session_notes_therapist_update" ON public.session_notes;
DROP POLICY IF EXISTS "session_notes_therapist_delete" ON public.session_notes;
DROP POLICY IF EXISTS "session_notes_anon_select" ON public.session_notes;
DROP POLICY IF EXISTS "session_notes_service_role" ON public.session_notes;

-- Patients can view notes about themselves
CREATE POLICY "session_notes_patient_select" ON public.session_notes
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id));

-- Therapists can fully manage notes for their patients
CREATE POLICY "session_notes_therapist_select" ON public.session_notes
    FOR SELECT TO authenticated
    USING (is_therapist_of_patient(patient_id));

CREATE POLICY "session_notes_therapist_insert" ON public.session_notes
    FOR INSERT TO authenticated
    WITH CHECK (is_therapist() AND is_therapist_of_patient(patient_id));

CREATE POLICY "session_notes_therapist_update" ON public.session_notes
    FOR UPDATE TO authenticated
    USING (is_therapist_of_patient(patient_id));

CREATE POLICY "session_notes_therapist_delete" ON public.session_notes
    FOR DELETE TO authenticated
    USING (is_therapist_of_patient(patient_id));

-- Demo mode
CREATE POLICY "session_notes_anon_select" ON public.session_notes
    FOR SELECT TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "session_notes_service_role" ON public.session_notes
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.session_notes TO authenticated;
GRANT SELECT ON public.session_notes TO anon;


-- ============================================================================
-- HIGH FIX 5: programs — NO RLS
-- Contains: patient rehabilitation program data
-- Linked to patients via patient_id
-- ============================================================================

ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "programs_patient_select" ON public.programs;
DROP POLICY IF EXISTS "programs_patient_update" ON public.programs;
DROP POLICY IF EXISTS "programs_therapist_select" ON public.programs;
DROP POLICY IF EXISTS "programs_therapist_insert" ON public.programs;
DROP POLICY IF EXISTS "programs_therapist_update" ON public.programs;
DROP POLICY IF EXISTS "programs_anon_select" ON public.programs;
DROP POLICY IF EXISTS "programs_service_role" ON public.programs;

CREATE POLICY "programs_patient_select" ON public.programs
    FOR SELECT TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "programs_patient_update" ON public.programs
    FOR UPDATE TO authenticated
    USING (is_own_patient(patient_id));

CREATE POLICY "programs_therapist_select" ON public.programs
    FOR SELECT TO authenticated
    USING (is_therapist_of_patient(patient_id));

CREATE POLICY "programs_therapist_insert" ON public.programs
    FOR INSERT TO authenticated
    WITH CHECK (is_therapist());

CREATE POLICY "programs_therapist_update" ON public.programs
    FOR UPDATE TO authenticated
    USING (is_therapist_of_patient(patient_id));

CREATE POLICY "programs_anon_select" ON public.programs
    FOR SELECT TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "programs_service_role" ON public.programs
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.programs TO authenticated;
GRANT SELECT ON public.programs TO anon;


-- ============================================================================
-- HIGH FIX 6: phases — NO RLS
-- Contains: program phase data, linked to programs (which link to patients)
-- ============================================================================

ALTER TABLE public.phases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "phases_authenticated_select" ON public.phases;
DROP POLICY IF EXISTS "phases_therapist_insert" ON public.phases;
DROP POLICY IF EXISTS "phases_therapist_update" ON public.phases;
DROP POLICY IF EXISTS "phases_anon_select" ON public.phases;
DROP POLICY IF EXISTS "phases_service_role" ON public.phases;

-- Authenticated users can view phases for programs they have access to
CREATE POLICY "phases_authenticated_select" ON public.phases
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM programs p
            WHERE p.id = phases.program_id
            AND (
                is_own_patient(p.patient_id)
                OR is_therapist_of_patient(p.patient_id)
            )
        )
    );

CREATE POLICY "phases_therapist_insert" ON public.phases
    FOR INSERT TO authenticated
    WITH CHECK (is_therapist());

CREATE POLICY "phases_therapist_update" ON public.phases
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM programs p
            WHERE p.id = phases.program_id
            AND is_therapist_of_patient(p.patient_id)
        )
        OR is_therapist()
    );

CREATE POLICY "phases_anon_select" ON public.phases
    FOR SELECT TO anon
    USING (
        EXISTS (
            SELECT 1 FROM programs p
            WHERE p.id = phases.program_id
            AND p.patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        )
    );

CREATE POLICY "phases_service_role" ON public.phases
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.phases TO authenticated;
GRANT SELECT ON public.phases TO anon;


-- ============================================================================
-- HIGH FIX 7: exercise_templates — NO RLS
-- Contains: Shared exercise library (names, descriptions, videos)
-- This is shared content — all authenticated users should read.
-- Only therapists/service_role should write.
-- ============================================================================

ALTER TABLE public.exercise_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "exercise_templates_read" ON public.exercise_templates;
DROP POLICY IF EXISTS "exercise_templates_anon_read" ON public.exercise_templates;
DROP POLICY IF EXISTS "exercise_templates_therapist_write" ON public.exercise_templates;
DROP POLICY IF EXISTS "exercise_templates_service_role" ON public.exercise_templates;

-- All authenticated users can read exercise templates
CREATE POLICY "exercise_templates_read" ON public.exercise_templates
    FOR SELECT TO authenticated
    USING (true);

-- Demo/anon can also read
CREATE POLICY "exercise_templates_anon_read" ON public.exercise_templates
    FOR SELECT TO anon
    USING (true);

-- Therapists can insert/update exercise templates
CREATE POLICY "exercise_templates_therapist_write" ON public.exercise_templates
    FOR ALL TO authenticated
    USING (is_therapist())
    WITH CHECK (is_therapist());

CREATE POLICY "exercise_templates_service_role" ON public.exercise_templates
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

GRANT SELECT ON public.exercise_templates TO authenticated;
GRANT SELECT ON public.exercise_templates TO anon;
GRANT ALL ON public.exercise_templates TO service_role;


-- ============================================================================
-- LOW FIX 8: video_categories — NO RLS
-- Contains: Category metadata for exercise videos (shared content)
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'video_categories') THEN
        ALTER TABLE public.video_categories ENABLE ROW LEVEL SECURITY;

        -- Drop existing policies
        EXECUTE 'DROP POLICY IF EXISTS "video_categories_read" ON public.video_categories';
        EXECUTE 'DROP POLICY IF EXISTS "video_categories_anon_read" ON public.video_categories';
        EXECUTE 'DROP POLICY IF EXISTS "video_categories_service_role" ON public.video_categories';

        -- Everyone can read video categories
        EXECUTE 'CREATE POLICY "video_categories_read" ON public.video_categories
            FOR SELECT TO authenticated USING (true)';
        EXECUTE 'CREATE POLICY "video_categories_anon_read" ON public.video_categories
            FOR SELECT TO anon USING (true)';
        EXECUTE 'CREATE POLICY "video_categories_service_role" ON public.video_categories
            FOR ALL TO service_role USING (true) WITH CHECK (true)';

        GRANT SELECT ON public.video_categories TO authenticated;
        GRANT SELECT ON public.video_categories TO anon;
    END IF;
END $$;


-- ============================================================================
-- LOW FIX 9: exercise_video_categories — NO RLS (join table)
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'exercise_video_categories') THEN
        ALTER TABLE public.exercise_video_categories ENABLE ROW LEVEL SECURITY;

        EXECUTE 'DROP POLICY IF EXISTS "exercise_video_categories_read" ON public.exercise_video_categories';
        EXECUTE 'DROP POLICY IF EXISTS "exercise_video_categories_anon_read" ON public.exercise_video_categories';
        EXECUTE 'DROP POLICY IF EXISTS "exercise_video_categories_service_role" ON public.exercise_video_categories';

        EXECUTE 'CREATE POLICY "exercise_video_categories_read" ON public.exercise_video_categories
            FOR SELECT TO authenticated USING (true)';
        EXECUTE 'CREATE POLICY "exercise_video_categories_anon_read" ON public.exercise_video_categories
            FOR SELECT TO anon USING (true)';
        EXECUTE 'CREATE POLICY "exercise_video_categories_service_role" ON public.exercise_video_categories
            FOR ALL TO service_role USING (true) WITH CHECK (true)';

        GRANT SELECT ON public.exercise_video_categories TO authenticated;
        GRANT SELECT ON public.exercise_video_categories TO anon;
    END IF;
END $$;


-- ============================================================================
-- LOW FIX 10: System/infrastructure tables — Enable RLS with service_role only
-- These tables should not be accessible to regular users.
-- Tables: slow_query_log, query_performance_log, cache_config, workload_flags_job_log
-- ============================================================================

DO $$
BEGIN
    -- slow_query_log
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'slow_query_log') THEN
        ALTER TABLE public.slow_query_log ENABLE ROW LEVEL SECURITY;
        EXECUTE 'DROP POLICY IF EXISTS "slow_query_log_service_role" ON public.slow_query_log';
        EXECUTE 'CREATE POLICY "slow_query_log_service_role" ON public.slow_query_log
            FOR ALL TO service_role USING (true) WITH CHECK (true)';
    END IF;

    -- query_performance_log
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'query_performance_log') THEN
        ALTER TABLE public.query_performance_log ENABLE ROW LEVEL SECURITY;
        EXECUTE 'DROP POLICY IF EXISTS "query_performance_log_service_role" ON public.query_performance_log';
        EXECUTE 'CREATE POLICY "query_performance_log_service_role" ON public.query_performance_log
            FOR ALL TO service_role USING (true) WITH CHECK (true)';
    END IF;

    -- cache_config
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'cache_config') THEN
        ALTER TABLE public.cache_config ENABLE ROW LEVEL SECURITY;
        EXECUTE 'DROP POLICY IF EXISTS "cache_config_read" ON public.cache_config';
        EXECUTE 'DROP POLICY IF EXISTS "cache_config_service_role" ON public.cache_config';
        -- Allow reads (cache config is not sensitive)
        EXECUTE 'CREATE POLICY "cache_config_read" ON public.cache_config
            FOR SELECT TO authenticated USING (true)';
        EXECUTE 'CREATE POLICY "cache_config_service_role" ON public.cache_config
            FOR ALL TO service_role USING (true) WITH CHECK (true)';
    END IF;

    -- workload_flags_job_log
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'workload_flags_job_log') THEN
        ALTER TABLE public.workload_flags_job_log ENABLE ROW LEVEL SECURITY;
        EXECUTE 'DROP POLICY IF EXISTS "workload_flags_job_log_service_role" ON public.workload_flags_job_log';
        EXECUTE 'CREATE POLICY "workload_flags_job_log_service_role" ON public.workload_flags_job_log
            FOR ALL TO service_role USING (true) WITH CHECK (true)';
    END IF;
END $$;


-- ============================================================================
-- INFO: LIMS tables — Enable RLS with service_role only
-- These are 17+ tables from a separate laboratory system.
-- They should be locked down to service_role only.
-- ============================================================================

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'lims_materials', 'lims_batches', 'lims_aliquots', 'lims_containers',
        'lims_wells', 'lims_samples', 'lims_protocols', 'lims_runs',
        'lims_run_containers', 'lims_instruments', 'lims_instrument_maintenance',
        'lims_observations', 'lims_feature_definitions', 'lims_features',
        'lims_compute_recipes', 'lims_compute_runs', 'lims_datasets',
        'lims_dataset_lineage', 'lims_custody_log', 'lims_schema_version'
    ]
    LOOP
        IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = tbl) THEN
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
            EXECUTE format('DROP POLICY IF EXISTS "%s_service_role" ON public.%I', tbl, tbl);
            EXECUTE format('CREATE POLICY "%s_service_role" ON public.%I
                FOR ALL TO service_role USING (true) WITH CHECK (true)', tbl, tbl);
            -- Also allow authenticated read for lab staff
            EXECUTE format('DROP POLICY IF EXISTS "%s_authenticated_read" ON public.%I', tbl, tbl);
            EXECUTE format('CREATE POLICY "%s_authenticated_read" ON public.%I
                FOR SELECT TO authenticated USING (is_therapist())', tbl, tbl);
        END IF;
    END LOOP;

    RAISE NOTICE 'LIMS tables: RLS enabled with service_role + therapist-read policies';
END $$;


-- ============================================================================
-- DOCUMENT: Tables with overly permissive USING(true) policies
-- ============================================================================
-- The following tables currently have USING(true) for ALL operations
-- (SELECT, INSERT, UPDATE, DELETE) to all roles including anon.
-- This was done in migrations 20260207410000 and 20260207430000 to fix
-- demo mode issues, but represents a security risk in production.
--
-- These should be tightened to proper user-scoped policies once
-- demo mode authentication is properly handled (e.g., demo user gets
-- a real auth token scoped to the demo patient).
--
-- MEDIUM RISK - Tables with USING(true) on all operations:
--   1. streak_records (patient_id) — patient engagement data
--   2. streak_history (patient_id) — patient engagement data
--   3. daily_readiness (patient_id) — patient health data
--   4. arm_care_assessments (patient_id) — clinical assessment data
--   5. body_comp_measurements (patient_id) — body composition (PII-adjacent)
--   6. manual_sessions (patient_id) — workout session data
--   7. patient_goals (patient_id) — patient goals
--   8. notification_settings (patient_id) — user preferences
--   9. prescription_notification_preferences (patient_id) — user preferences
--  10. workout_modifications (patient_id) — workout data
--  11. manual_session_exercises — exercise data
--  12. patient_favorite_templates (patient_id) — user preferences
--  13. workout_prescriptions (patient_id) — clinical prescriptions
--  14. sessions — workout sessions (via phase->program->patient chain)
--  15. session_exercises — exercises within sessions
--  16. exercise_logs (patient_id) — exercise logging data
--  17. patient_workout_templates (patient_id) — user templates
--  18. system_workout_templates — shared templates (OK for read)
--
-- NOTE: We are NOT changing these in this migration to avoid breaking
-- the currently working demo mode. These should be addressed in a
-- follow-up migration once demo authentication is fixed.
-- See RLS_AUDIT_REPORT.md for the recommended policy patterns.
-- ============================================================================


-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    tbl TEXT;
    rls_enabled BOOLEAN;
    policy_count INT;
    tables_without_rls TEXT[] := '{}';
    tables_fixed TEXT[] := '{}';
BEGIN
    -- Check critical tables
    FOREACH tbl IN ARRAY ARRAY[
        'therapists', 'patients', 'programs', 'phases', 'sessions',
        'exercise_templates', 'session_exercises', 'exercise_logs',
        'pain_logs', 'bullpen_logs', 'body_comp_measurements', 'session_notes',
        'daily_readiness', 'streak_records', 'manual_sessions', 'patient_goals'
    ]
    LOOP
        SELECT relrowsecurity INTO rls_enabled
        FROM pg_class
        WHERE relname = tbl AND relnamespace = 'public'::regnamespace;

        SELECT COUNT(*) INTO policy_count
        FROM pg_policies
        WHERE tablename = tbl AND schemaname = 'public';

        IF rls_enabled THEN
            tables_fixed := array_append(tables_fixed, format('%s (%s policies)', tbl, policy_count));
        ELSE
            tables_without_rls := array_append(tables_without_rls, tbl);
        END IF;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'RLS AUDIT MIGRATION COMPLETE — 2026-02-22';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables with RLS enabled:';
    FOREACH tbl IN ARRAY tables_fixed
    LOOP
        RAISE NOTICE '  OK  %', tbl;
    END LOOP;

    IF array_length(tables_without_rls, 1) > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE 'WARNING — Tables still without RLS:';
        FOREACH tbl IN ARRAY tables_without_rls
        LOOP
            RAISE NOTICE '  FAIL  %', tbl;
        END LOOP;
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE 'All critical tables have RLS enabled.';
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
