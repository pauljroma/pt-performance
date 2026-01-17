-- Migration: Create Manual Sessions Tables
-- Purpose: Support for ad-hoc workouts in the Manual Workout Entry feature
-- Part 3 of 4 for Manual Workout Entry feature

-- ============================================================================
-- 1. CREATE MANUAL SESSIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS manual_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Owner relationship
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Session info
    name TEXT,
    notes TEXT,

    -- Source template tracking (if created from a template)
    source_template_id UUID,
    source_template_type TEXT CHECK (source_template_type IN ('system', 'patient', NULL)),

    -- Session timing
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    completed BOOLEAN NOT NULL DEFAULT false,

    -- Aggregated metrics (calculated after exercises are logged)
    total_volume NUMERIC,           -- Total volume (sets * reps * load)
    avg_rpe NUMERIC,                -- Average RPE across all exercises
    avg_pain NUMERIC,               -- Average pain score across all exercises
    duration_minutes INTEGER,       -- Actual duration in minutes

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 2. CREATE MANUAL SESSION EXERCISES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS manual_session_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Parent relationship
    manual_session_id UUID NOT NULL REFERENCES manual_sessions(id) ON DELETE CASCADE,

    -- Exercise reference (optional - can be ad-hoc exercise)
    exercise_template_id UUID REFERENCES exercise_templates(id) ON DELETE SET NULL,

    -- Exercise details (stored directly for flexibility)
    exercise_name TEXT NOT NULL,
    block_name TEXT,                -- e.g., "Warmup", "Main", "Cooldown"
    sequence INTEGER NOT NULL DEFAULT 0,

    -- Prescription/targets
    target_sets INTEGER,
    target_reps TEXT,               -- Text to allow "8-12" or "AMRAP"
    target_load NUMERIC,
    load_unit TEXT DEFAULT 'lbs' CHECK (load_unit IN ('lbs', 'kg', 'bodyweight', NULL)),
    rest_period_seconds INTEGER,

    -- Notes
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Manual sessions indexes
CREATE INDEX IF NOT EXISTS idx_manual_sessions_patient_id
ON manual_sessions(patient_id);

CREATE INDEX IF NOT EXISTS idx_manual_sessions_completed_at
ON manual_sessions(completed_at DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_manual_sessions_created_at
ON manual_sessions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_manual_sessions_source_template
ON manual_sessions(source_template_id, source_template_type);

-- Manual session exercises indexes
CREATE INDEX IF NOT EXISTS idx_manual_session_exercises_session_id
ON manual_session_exercises(manual_session_id, sequence);

CREATE INDEX IF NOT EXISTS idx_manual_session_exercises_exercise_template
ON manual_session_exercises(exercise_template_id);

-- ============================================================================
-- 4. CREATE HELPER FUNCTIONS
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_template_usage ON manual_sessions;
CREATE TRIGGER trigger_increment_template_usage
    AFTER INSERT ON manual_sessions
    FOR EACH ROW
    EXECUTE FUNCTION increment_template_usage_count();

-- Function to calculate session metrics
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
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_manual_session_metrics(UUID) IS
'Recalculates aggregated metrics for a manual session based on exercise logs.
Call this function when a session is completed or when exercise logs are updated.';

-- ============================================================================
-- 5. ADD COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE manual_sessions IS
'Ad-hoc workout sessions created by patients outside of their prescribed programs.
These sessions track manual/freestyle workouts for the Manual Workout Entry feature.';

COMMENT ON COLUMN manual_sessions.source_template_id IS
'If created from a template, references the source template ID.';

COMMENT ON COLUMN manual_sessions.source_template_type IS
'Type of source template: "system" for system_workout_templates, "patient" for patient_workout_templates.';

COMMENT ON COLUMN manual_sessions.total_volume IS
'Aggregated total volume (sets * reps * load) across all exercises. Calculated on session completion.';

COMMENT ON TABLE manual_session_exercises IS
'Exercises within a manual session. Similar structure to session_exercises but for ad-hoc workouts.';

COMMENT ON COLUMN manual_session_exercises.target_reps IS
'Target reps as text to support ranges like "8-12" or special values like "AMRAP".';

COMMENT ON COLUMN manual_session_exercises.block_name IS
'Organizational block name like "Warmup", "Main Set", "Cooldown", etc.';

-- ============================================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE manual_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual_session_exercises ENABLE ROW LEVEL SECURITY;

-- MANUAL SESSIONS POLICIES

-- Patients can view their own manual sessions
DROP POLICY IF EXISTS "patients_own_manual_sessions_select" ON manual_sessions;
CREATE POLICY "patients_own_manual_sessions_select"
ON manual_sessions
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
);

-- Patients can create their own manual sessions
DROP POLICY IF EXISTS "patients_own_manual_sessions_insert" ON manual_sessions;
CREATE POLICY "patients_own_manual_sessions_insert"
ON manual_sessions
FOR INSERT
TO authenticated
WITH CHECK (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
);

-- Patients can update their own manual sessions
DROP POLICY IF EXISTS "patients_own_manual_sessions_update" ON manual_sessions;
CREATE POLICY "patients_own_manual_sessions_update"
ON manual_sessions
FOR UPDATE
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
);

-- Patients can delete their own manual sessions
DROP POLICY IF EXISTS "patients_own_manual_sessions_delete" ON manual_sessions;
CREATE POLICY "patients_own_manual_sessions_delete"
ON manual_sessions
FOR DELETE
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
);

-- Therapists can view their patients' manual sessions
DROP POLICY IF EXISTS "therapists_view_patient_manual_sessions" ON manual_sessions;
CREATE POLICY "therapists_view_patient_manual_sessions"
ON manual_sessions
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM patients
        WHERE therapist_id IN (
            SELECT id FROM therapists WHERE user_id = auth.uid()
        )
    )
);

-- MANUAL SESSION EXERCISES POLICIES

-- Patients can view exercises in their own manual sessions
DROP POLICY IF EXISTS "patients_own_manual_exercises_select" ON manual_session_exercises;
CREATE POLICY "patients_own_manual_exercises_select"
ON manual_session_exercises
FOR SELECT
TO authenticated
USING (
    manual_session_id IN (
        SELECT id FROM manual_sessions
        WHERE patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    )
);

-- Patients can create exercises in their own manual sessions
DROP POLICY IF EXISTS "patients_own_manual_exercises_insert" ON manual_session_exercises;
CREATE POLICY "patients_own_manual_exercises_insert"
ON manual_session_exercises
FOR INSERT
TO authenticated
WITH CHECK (
    manual_session_id IN (
        SELECT id FROM manual_sessions
        WHERE patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    )
);

-- Patients can update exercises in their own manual sessions
DROP POLICY IF EXISTS "patients_own_manual_exercises_update" ON manual_session_exercises;
CREATE POLICY "patients_own_manual_exercises_update"
ON manual_session_exercises
FOR UPDATE
TO authenticated
USING (
    manual_session_id IN (
        SELECT id FROM manual_sessions
        WHERE patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    )
)
WITH CHECK (
    manual_session_id IN (
        SELECT id FROM manual_sessions
        WHERE patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    )
);

-- Patients can delete exercises in their own manual sessions
DROP POLICY IF EXISTS "patients_own_manual_exercises_delete" ON manual_session_exercises;
CREATE POLICY "patients_own_manual_exercises_delete"
ON manual_session_exercises
FOR DELETE
TO authenticated
USING (
    manual_session_id IN (
        SELECT id FROM manual_sessions
        WHERE patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    )
);

-- Therapists can view exercises in their patients' manual sessions
DROP POLICY IF EXISTS "therapists_view_patient_manual_exercises" ON manual_session_exercises;
CREATE POLICY "therapists_view_patient_manual_exercises"
ON manual_session_exercises
FOR SELECT
TO authenticated
USING (
    manual_session_id IN (
        SELECT id FROM manual_sessions
        WHERE patient_id IN (
            SELECT id FROM patients
            WHERE therapist_id IN (
                SELECT id FROM therapists WHERE user_id = auth.uid()
            )
        )
    )
);

-- ============================================================================
-- 7. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON manual_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON manual_session_exercises TO authenticated;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'manual_sessions') THEN
        RAISE NOTICE 'SUCCESS: manual_sessions table created';
    ELSE
        RAISE EXCEPTION 'FAILED: manual_sessions table was not created';
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'manual_session_exercises') THEN
        RAISE NOTICE 'SUCCESS: manual_session_exercises table created';
    ELSE
        RAISE EXCEPTION 'FAILED: manual_session_exercises table was not created';
    END IF;
END $$;
