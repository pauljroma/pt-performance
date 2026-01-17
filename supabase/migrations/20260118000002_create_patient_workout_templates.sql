-- Migration: Create Patient Workout Templates Table
-- Purpose: Patient-created workout templates for the Manual Workout Entry feature
-- Part 2 of 4 for Manual Workout Entry feature

-- ============================================================================
-- 1. CREATE PATIENT WORKOUT TEMPLATES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS patient_workout_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Owner relationship
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Basic info
    name TEXT NOT NULL,
    description TEXT,

    -- Classification (simplified - patient's own categorization)
    category TEXT,

    -- Exercise content (same structure as system templates)
    exercises JSONB NOT NULL DEFAULT '[]'::JSONB,

    -- Usage tracking
    usage_count INTEGER NOT NULL DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index on patient_id for filtering by owner
CREATE INDEX IF NOT EXISTS idx_patient_workout_templates_patient_id
ON patient_workout_templates(patient_id);

-- Index on usage_count for sorting by popularity
CREATE INDEX IF NOT EXISTS idx_patient_workout_templates_usage_count
ON patient_workout_templates(usage_count DESC);

-- Index on created_at for sorting by recency
CREATE INDEX IF NOT EXISTS idx_patient_workout_templates_created_at
ON patient_workout_templates(created_at DESC);

-- GIN index on exercises JSONB for searching within exercises
CREATE INDEX IF NOT EXISTS idx_patient_workout_templates_exercises_gin
ON patient_workout_templates USING GIN(exercises);

-- ============================================================================
-- 3. CREATE TRIGGER FOR updated_at
-- ============================================================================

-- Create or replace the function for updating timestamp
CREATE OR REPLACE FUNCTION update_patient_workout_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_patient_workout_templates_updated_at ON patient_workout_templates;
CREATE TRIGGER trigger_patient_workout_templates_updated_at
    BEFORE UPDATE ON patient_workout_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_patient_workout_templates_updated_at();

-- ============================================================================
-- 4. ADD COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE patient_workout_templates IS
'Patient-created workout templates for the Manual Workout Entry feature.
Patients can save their own custom workouts as templates for reuse.';

COMMENT ON COLUMN patient_workout_templates.patient_id IS
'The patient who owns this template. Enforced by RLS.';

COMMENT ON COLUMN patient_workout_templates.exercises IS
'JSONB array of exercise definitions (same structure as system_workout_templates):
[{
  "exercise_template_id": "uuid or null",
  "exercise_name": "Exercise Name",
  "block_name": "Warmup/Main/Cooldown",
  "sequence": 1,
  "target_sets": 3,
  "target_reps": "8-12",
  "target_load": "bodyweight or 135",
  "load_unit": "lbs/kg/bodyweight",
  "rest_period_seconds": 60,
  "notes": "Optional notes"
}]';

COMMENT ON COLUMN patient_workout_templates.usage_count IS
'Number of times this template has been used to create a manual session. Incremented automatically.';

-- ============================================================================
-- 5. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE patient_workout_templates ENABLE ROW LEVEL SECURITY;

-- Patients can only see their own templates
DROP POLICY IF EXISTS "patients_own_workout_templates_select" ON patient_workout_templates;
CREATE POLICY "patients_own_workout_templates_select"
ON patient_workout_templates
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
);

-- Patients can insert their own templates
DROP POLICY IF EXISTS "patients_own_workout_templates_insert" ON patient_workout_templates;
CREATE POLICY "patients_own_workout_templates_insert"
ON patient_workout_templates
FOR INSERT
TO authenticated
WITH CHECK (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
);

-- Patients can update their own templates
DROP POLICY IF EXISTS "patients_own_workout_templates_update" ON patient_workout_templates;
CREATE POLICY "patients_own_workout_templates_update"
ON patient_workout_templates
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

-- Patients can delete their own templates
DROP POLICY IF EXISTS "patients_own_workout_templates_delete" ON patient_workout_templates;
CREATE POLICY "patients_own_workout_templates_delete"
ON patient_workout_templates
FOR DELETE
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
);

-- Therapists can view their patients' templates
DROP POLICY IF EXISTS "therapists_view_patient_templates" ON patient_workout_templates;
CREATE POLICY "therapists_view_patient_templates"
ON patient_workout_templates
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

COMMENT ON POLICY "patients_own_workout_templates_select" ON patient_workout_templates IS
'Patients can only view their own workout templates.';

COMMENT ON POLICY "patients_own_workout_templates_insert" ON patient_workout_templates IS
'Patients can only create workout templates for themselves.';

COMMENT ON POLICY "patients_own_workout_templates_update" ON patient_workout_templates IS
'Patients can only update their own workout templates.';

COMMENT ON POLICY "patients_own_workout_templates_delete" ON patient_workout_templates IS
'Patients can only delete their own workout templates.';

COMMENT ON POLICY "therapists_view_patient_templates" ON patient_workout_templates IS
'Therapists can view workout templates of their assigned patients.';

-- ============================================================================
-- 6. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON patient_workout_templates TO authenticated;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'patient_workout_templates') THEN
        RAISE NOTICE 'SUCCESS: patient_workout_templates table created';
    ELSE
        RAISE EXCEPTION 'FAILED: patient_workout_templates table was not created';
    END IF;
END $$;
