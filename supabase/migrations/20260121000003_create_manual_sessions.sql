-- Migration: Create Manual Sessions Tables
-- Created: 2026-01-21
-- Purpose: Support for ad-hoc workouts in the Manual Workout Entry feature
-- Part 3 of 4 for Manual Workout Entry feature
--
-- This migration creates:
--   1. manual_sessions - Ad-hoc workout sessions created by patients
--   2. manual_session_exercises - Exercises within a manual session
--
-- Uses SECURITY DEFINER function pattern (like meal_plan_items) to avoid RLS recursion.

-- ============================================================================
-- 1. DROP EXISTING OBJECTS (for clean slate)
-- ============================================================================

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_increment_template_usage ON manual_sessions;
DROP TRIGGER IF EXISTS trigger_manual_sessions_updated ON manual_sessions;

-- Drop functions
DROP FUNCTION IF EXISTS increment_template_usage_count() CASCADE;
DROP FUNCTION IF EXISTS calculate_manual_session_metrics(UUID) CASCADE;
DROP FUNCTION IF EXISTS user_owns_manual_session(UUID) CASCADE;
DROP FUNCTION IF EXISTS user_owns_manual_session_exercise(UUID) CASCADE;

-- Drop policies on manual_session_exercises first
DROP POLICY IF EXISTS "patients_own_manual_exercises_select" ON manual_session_exercises;
DROP POLICY IF EXISTS "patients_own_manual_exercises_insert" ON manual_session_exercises;
DROP POLICY IF EXISTS "patients_own_manual_exercises_update" ON manual_session_exercises;
DROP POLICY IF EXISTS "patients_own_manual_exercises_delete" ON manual_session_exercises;
DROP POLICY IF EXISTS "therapists_view_patient_manual_exercises" ON manual_session_exercises;
DROP POLICY IF EXISTS "manual_session_exercises_select" ON manual_session_exercises;
DROP POLICY IF EXISTS "manual_session_exercises_insert" ON manual_session_exercises;
DROP POLICY IF EXISTS "manual_session_exercises_update" ON manual_session_exercises;
DROP POLICY IF EXISTS "manual_session_exercises_delete" ON manual_session_exercises;

-- Drop policies on manual_sessions
DROP POLICY IF EXISTS "patients_own_manual_sessions_select" ON manual_sessions;
DROP POLICY IF EXISTS "patients_own_manual_sessions_insert" ON manual_sessions;
DROP POLICY IF EXISTS "patients_own_manual_sessions_update" ON manual_sessions;
DROP POLICY IF EXISTS "patients_own_manual_sessions_delete" ON manual_sessions;
DROP POLICY IF EXISTS "therapists_view_patient_manual_sessions" ON manual_sessions;
DROP POLICY IF EXISTS "manual_sessions_select" ON manual_sessions;
DROP POLICY IF EXISTS "manual_sessions_insert" ON manual_sessions;
DROP POLICY IF EXISTS "manual_sessions_update" ON manual_sessions;
DROP POLICY IF EXISTS "manual_sessions_delete" ON manual_sessions;

-- Drop indexes
DROP INDEX IF EXISTS idx_manual_sessions_patient_id;
DROP INDEX IF EXISTS idx_manual_sessions_completed_at;
DROP INDEX IF EXISTS idx_manual_sessions_created_at;
DROP INDEX IF EXISTS idx_manual_sessions_source_template;
DROP INDEX IF EXISTS idx_manual_session_exercises_session_id;
DROP INDEX IF EXISTS idx_manual_session_exercises_exercise_template;

-- Drop tables (manual_session_exercises first due to FK)
DROP TABLE IF EXISTS manual_session_exercises CASCADE;
DROP TABLE IF EXISTS manual_sessions CASCADE;

-- ============================================================================
-- 2. CREATE MANUAL SESSIONS TABLE
-- ============================================================================

CREATE TABLE manual_sessions (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Owner relationship
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Session information
    name TEXT,
    notes TEXT,

    -- Source template tracking (if created from a template)
    -- NULL if created from scratch
    source_template_id UUID,
    source_template_type TEXT CHECK (source_template_type IN ('system', 'patient') OR source_template_type IS NULL),

    -- Session timing
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    completed BOOLEAN NOT NULL DEFAULT false,

    -- Aggregated metrics (calculated after exercises are logged)
    total_volume NUMERIC,       -- Total volume = SUM(sets * reps * load)
    avg_rpe NUMERIC,            -- Average RPE across all exercises
    avg_pain NUMERIC,           -- Average pain score across all exercises
    duration_minutes INTEGER,   -- Actual duration (completed_at - started_at)

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraint: source_template_type requires source_template_id
    CONSTRAINT manual_sessions_template_consistency
    CHECK (
        (source_template_id IS NULL AND source_template_type IS NULL)
        OR
        (source_template_id IS NOT NULL AND source_template_type IS NOT NULL)
    )
);

-- ============================================================================
-- 3. CREATE MANUAL SESSION EXERCISES TABLE
-- ============================================================================

CREATE TABLE manual_session_exercises (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Parent relationship
    manual_session_id UUID NOT NULL REFERENCES manual_sessions(id) ON DELETE CASCADE,

    -- Exercise reference (optional - allows ad-hoc exercises not in template library)
    exercise_template_id UUID REFERENCES exercise_templates(id) ON DELETE SET NULL,

    -- Exercise details (stored directly for flexibility and historical record)
    exercise_name TEXT NOT NULL,
    block_name TEXT,            -- e.g., "Warmup", "Main", "Cooldown"
    sequence INTEGER NOT NULL DEFAULT 0,

    -- Prescription/targets
    target_sets INTEGER,
    target_reps TEXT,           -- Text to allow "8-12" or "AMRAP"
    target_load NUMERIC,
    load_unit TEXT DEFAULT 'lbs' CHECK (load_unit IN ('lbs', 'kg', 'bodyweight') OR load_unit IS NULL),
    rest_period_seconds INTEGER,

    -- Notes
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 4. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Manual sessions indexes
CREATE INDEX idx_manual_sessions_patient_id
ON manual_sessions(patient_id);

CREATE INDEX idx_manual_sessions_completed_at
ON manual_sessions(completed_at DESC NULLS LAST);

CREATE INDEX idx_manual_sessions_created_at
ON manual_sessions(created_at DESC);

CREATE INDEX idx_manual_sessions_source_template
ON manual_sessions(source_template_id, source_template_type)
WHERE source_template_id IS NOT NULL;

-- Composite index for patient history queries
CREATE INDEX idx_manual_sessions_patient_completed
ON manual_sessions(patient_id, completed_at DESC NULLS LAST);

-- Manual session exercises indexes
CREATE INDEX idx_manual_session_exercises_session_id
ON manual_session_exercises(manual_session_id, sequence);

CREATE INDEX idx_manual_session_exercises_exercise_template
ON manual_session_exercises(exercise_template_id)
WHERE exercise_template_id IS NOT NULL;

-- ============================================================================
-- 5. CREATE SECURITY DEFINER FUNCTIONS FOR RLS
-- ============================================================================

-- Function to check if user owns a manual session
-- Pattern: Same as user_owns_meal_plan() in meal_plan_items
CREATE OR REPLACE FUNCTION public.user_owns_manual_session(check_session_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM manual_sessions ms
        JOIN patients p ON p.id = ms.patient_id
        WHERE ms.id = check_session_id
        AND p.email = (auth.jwt() ->> 'email')
    )
$$;

GRANT EXECUTE ON FUNCTION public.user_owns_manual_session(UUID) TO authenticated;

COMMENT ON FUNCTION user_owns_manual_session(UUID) IS
'SECURITY DEFINER function to check manual session ownership without RLS recursion.
Returns TRUE if the authenticated user (identified by JWT email) owns the session.
Used by RLS policies on manual_sessions.';

-- Function to check if user owns a manual session exercise
-- Checks ownership through the parent manual_session
CREATE OR REPLACE FUNCTION public.user_owns_manual_session_exercise(check_exercise_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM manual_session_exercises mse
        JOIN manual_sessions ms ON ms.id = mse.manual_session_id
        JOIN patients p ON p.id = ms.patient_id
        WHERE mse.id = check_exercise_id
        AND p.email = (auth.jwt() ->> 'email')
    )
$$;

GRANT EXECUTE ON FUNCTION public.user_owns_manual_session_exercise(UUID) TO authenticated;

COMMENT ON FUNCTION user_owns_manual_session_exercise(UUID) IS
'SECURITY DEFINER function to check manual session exercise ownership without RLS recursion.
Checks ownership through parent manual_session -> patient -> email chain.
Used by RLS policies on manual_session_exercises.';

-- Additional helper function for INSERT policies (checks by manual_session_id)
CREATE OR REPLACE FUNCTION public.user_owns_manual_session_by_id(check_session_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM manual_sessions ms
        JOIN patients p ON p.id = ms.patient_id
        WHERE ms.id = check_session_id
        AND p.email = (auth.jwt() ->> 'email')
    )
$$;

GRANT EXECUTE ON FUNCTION public.user_owns_manual_session_by_id(UUID) TO authenticated;

-- ============================================================================
-- 6. CREATE HELPER FUNCTIONS
-- ============================================================================

-- Function to increment template usage count when manual session is created from template
CREATE OR REPLACE FUNCTION increment_template_usage_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.source_template_type = 'patient' AND NEW.source_template_id IS NOT NULL THEN
        UPDATE patient_workout_templates
        SET usage_count = usage_count + 1
        WHERE id = NEW.source_template_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_increment_template_usage
    AFTER INSERT ON manual_sessions
    FOR EACH ROW
    EXECUTE FUNCTION increment_template_usage_count();

-- Function to calculate session metrics from exercise logs
CREATE OR REPLACE FUNCTION calculate_manual_session_metrics(p_session_id UUID)
RETURNS void AS $$
DECLARE
    v_total_volume NUMERIC;
    v_avg_rpe NUMERIC;
    v_avg_pain NUMERIC;
    v_duration_minutes INTEGER;
BEGIN
    -- Calculate metrics from exercise_logs linked to this manual session
    SELECT
        COALESCE(SUM(el.load_value * el.reps_completed * COALESCE(el.sets_completed, 1)), 0),
        AVG(el.rpe),
        AVG(el.pain_score)
    INTO v_total_volume, v_avg_rpe, v_avg_pain
    FROM exercise_logs el
    JOIN manual_session_exercises mse ON el.manual_session_exercise_id = mse.id
    WHERE mse.manual_session_id = p_session_id;

    -- Calculate duration from started_at to completed_at
    SELECT
        EXTRACT(EPOCH FROM (completed_at - started_at)) / 60
    INTO v_duration_minutes
    FROM manual_sessions
    WHERE id = p_session_id
    AND started_at IS NOT NULL
    AND completed_at IS NOT NULL;

    -- Update the session with calculated metrics
    UPDATE manual_sessions
    SET
        total_volume = v_total_volume,
        avg_rpe = v_avg_rpe,
        avg_pain = v_avg_pain,
        duration_minutes = v_duration_minutes
    WHERE id = p_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION calculate_manual_session_metrics(UUID) TO authenticated;

COMMENT ON FUNCTION calculate_manual_session_metrics(UUID) IS
'Recalculates aggregated metrics for a manual session based on exercise logs.
Call this function when a session is completed or when exercise logs are updated.';

-- ============================================================================
-- 7. ADD COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE manual_sessions IS
'Ad-hoc workout sessions created by patients outside of their prescribed programs.
These sessions track manual/freestyle workouts for the Manual Workout Entry feature.
Protected by RLS using SECURITY DEFINER functions to avoid recursion.';

COMMENT ON COLUMN manual_sessions.patient_id IS
'The patient who owns this session. Enforced by RLS.';

COMMENT ON COLUMN manual_sessions.source_template_id IS
'If created from a template, references the source template ID (UUID).
NULL if workout was created from scratch.';

COMMENT ON COLUMN manual_sessions.source_template_type IS
'Type of source template: "system" for system_workout_templates, "patient" for patient_workout_templates.
NULL if workout was created from scratch.';

COMMENT ON COLUMN manual_sessions.total_volume IS
'Aggregated total volume (sets * reps * load) across all exercises.
Calculated by calculate_manual_session_metrics() on session completion.';

COMMENT ON TABLE manual_session_exercises IS
'Exercises within a manual session. Similar structure to session_exercises but for ad-hoc workouts.
Protected by RLS through parent manual_session ownership.';

COMMENT ON COLUMN manual_session_exercises.target_reps IS
'Target reps as text to support ranges like "8-12" or special values like "AMRAP".';

COMMENT ON COLUMN manual_session_exercises.block_name IS
'Organizational block name like "Warmup", "Main Set", "Cooldown", etc.';

-- ============================================================================
-- 8. ROW LEVEL SECURITY - MANUAL SESSIONS
-- ============================================================================

ALTER TABLE manual_sessions ENABLE ROW LEVEL SECURITY;

-- SELECT: Patients can view their own manual sessions
CREATE POLICY "manual_sessions_select"
ON manual_sessions
FOR SELECT
TO authenticated
USING (user_owns_manual_session(id));

-- INSERT: Patients can create their own manual sessions
CREATE POLICY "manual_sessions_insert"
ON manual_sessions
FOR INSERT
TO authenticated
WITH CHECK (
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
);

-- UPDATE: Patients can update their own manual sessions
CREATE POLICY "manual_sessions_update"
ON manual_sessions
FOR UPDATE
TO authenticated
USING (user_owns_manual_session(id));

-- DELETE: Patients can delete their own manual sessions
CREATE POLICY "manual_sessions_delete"
ON manual_sessions
FOR DELETE
TO authenticated
USING (user_owns_manual_session(id));

-- Policy comments
COMMENT ON POLICY "manual_sessions_select" ON manual_sessions IS
'Patients can view their own manual sessions.
Uses SECURITY DEFINER function to avoid RLS recursion with patients table.';

COMMENT ON POLICY "manual_sessions_insert" ON manual_sessions IS
'Patients can create manual sessions for themselves.
Validates ownership through patient email matching JWT.';

COMMENT ON POLICY "manual_sessions_update" ON manual_sessions IS
'Patients can update their own manual sessions.
Uses SECURITY DEFINER function for ownership check.';

COMMENT ON POLICY "manual_sessions_delete" ON manual_sessions IS
'Patients can delete their own manual sessions.
Uses SECURITY DEFINER function for ownership check.';

-- ============================================================================
-- 9. ROW LEVEL SECURITY - MANUAL SESSION EXERCISES
-- ============================================================================

ALTER TABLE manual_session_exercises ENABLE ROW LEVEL SECURITY;

-- SELECT: Patients can view exercises in their own manual sessions
CREATE POLICY "manual_session_exercises_select"
ON manual_session_exercises
FOR SELECT
TO authenticated
USING (user_owns_manual_session_exercise(id));

-- INSERT: Patients can add exercises to their own manual sessions
CREATE POLICY "manual_session_exercises_insert"
ON manual_session_exercises
FOR INSERT
TO authenticated
WITH CHECK (user_owns_manual_session_by_id(manual_session_id));

-- UPDATE: Patients can update exercises in their own manual sessions
CREATE POLICY "manual_session_exercises_update"
ON manual_session_exercises
FOR UPDATE
TO authenticated
USING (user_owns_manual_session_exercise(id));

-- DELETE: Patients can delete exercises from their own manual sessions
CREATE POLICY "manual_session_exercises_delete"
ON manual_session_exercises
FOR DELETE
TO authenticated
USING (user_owns_manual_session_exercise(id));

-- Policy comments
COMMENT ON POLICY "manual_session_exercises_select" ON manual_session_exercises IS
'Patients can view exercises in their own manual sessions.
Uses SECURITY DEFINER function checking ownership through parent session.';

COMMENT ON POLICY "manual_session_exercises_insert" ON manual_session_exercises IS
'Patients can add exercises to their own manual sessions.
Validates ownership through parent session -> patient -> email chain.';

COMMENT ON POLICY "manual_session_exercises_update" ON manual_session_exercises IS
'Patients can update exercises in their own manual sessions.
Uses SECURITY DEFINER function for ownership check.';

COMMENT ON POLICY "manual_session_exercises_delete" ON manual_session_exercises IS
'Patients can delete exercises from their own manual sessions.
Uses SECURITY DEFINER function for ownership check.';

-- ============================================================================
-- 10. GRANT PERMISSIONS
-- ============================================================================

-- Authenticated users can perform all operations (controlled by RLS)
GRANT SELECT, INSERT, UPDATE, DELETE ON manual_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON manual_session_exercises TO authenticated;

-- Service role has full access for admin operations
GRANT ALL ON manual_sessions TO service_role;
GRANT ALL ON manual_session_exercises TO service_role;

-- ============================================================================
-- 11. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_ms_exists BOOLEAN;
    v_mse_exists BOOLEAN;
    v_ms_rls BOOLEAN;
    v_mse_rls BOOLEAN;
    v_func1_exists BOOLEAN;
    v_func2_exists BOOLEAN;
    v_ms_policy_count INTEGER;
    v_mse_policy_count INTEGER;
BEGIN
    -- Check tables exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'manual_sessions'
    ) INTO v_ms_exists;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'manual_session_exercises'
    ) INTO v_mse_exists;

    IF NOT v_ms_exists THEN
        RAISE EXCEPTION 'FAILED: manual_sessions table was not created';
    END IF;

    IF NOT v_mse_exists THEN
        RAISE EXCEPTION 'FAILED: manual_session_exercises table was not created';
    END IF;

    -- Check RLS is enabled
    SELECT relrowsecurity FROM pg_class WHERE relname = 'manual_sessions' INTO v_ms_rls;
    SELECT relrowsecurity FROM pg_class WHERE relname = 'manual_session_exercises' INTO v_mse_rls;

    IF NOT v_ms_rls THEN
        RAISE EXCEPTION 'FAILED: RLS is not enabled on manual_sessions';
    END IF;

    IF NOT v_mse_rls THEN
        RAISE EXCEPTION 'FAILED: RLS is not enabled on manual_session_exercises';
    END IF;

    -- Check SECURITY DEFINER functions exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_schema = 'public' AND routine_name = 'user_owns_manual_session'
    ) INTO v_func1_exists;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_schema = 'public' AND routine_name = 'user_owns_manual_session_exercise'
    ) INTO v_func2_exists;

    IF NOT v_func1_exists THEN
        RAISE EXCEPTION 'FAILED: user_owns_manual_session function was not created';
    END IF;

    IF NOT v_func2_exists THEN
        RAISE EXCEPTION 'FAILED: user_owns_manual_session_exercise function was not created';
    END IF;

    -- Count policies
    SELECT COUNT(*) FROM pg_policies WHERE tablename = 'manual_sessions' INTO v_ms_policy_count;
    SELECT COUNT(*) FROM pg_policies WHERE tablename = 'manual_session_exercises' INTO v_mse_policy_count;

    IF v_ms_policy_count < 4 THEN
        RAISE EXCEPTION 'FAILED: Expected 4 RLS policies on manual_sessions, found %', v_ms_policy_count;
    END IF;

    IF v_mse_policy_count < 4 THEN
        RAISE EXCEPTION 'FAILED: Expected 4 RLS policies on manual_session_exercises, found %', v_mse_policy_count;
    END IF;

    RAISE NOTICE 'SUCCESS: Manual sessions tables created with RLS enabled';
    RAISE NOTICE '  - manual_sessions: table=%, rls=%, policies=%', v_ms_exists, v_ms_rls, v_ms_policy_count;
    RAISE NOTICE '  - manual_session_exercises: table=%, rls=%, policies=%', v_mse_exists, v_mse_rls, v_mse_policy_count;
    RAISE NOTICE '  - SECURITY DEFINER functions: user_owns_manual_session=%, user_owns_manual_session_exercise=%', v_func1_exists, v_func2_exists;
END $$;
