-- Migration: Create Patient Workout Templates Table
-- Created: 2026-01-21
-- Purpose: Patient-created workout templates for the Manual Workout Entry feature
-- Part 2 of 4 for Manual Workout Entry feature
--
-- This migration creates the patient_workout_templates table which allows
-- patients to save their own custom workout templates for reuse.
-- Uses SECURITY DEFINER function pattern (like meal_plan_items) to avoid RLS recursion.

-- ============================================================================
-- 1. DROP EXISTING OBJECTS (for clean slate)
-- ============================================================================

-- Drop dependent triggers and functions
DROP TRIGGER IF EXISTS trigger_patient_workout_templates_updated_at ON patient_workout_templates;
DROP FUNCTION IF EXISTS update_patient_workout_templates_updated_at();

-- Drop existing policies
DROP POLICY IF EXISTS "patients_own_workout_templates_select" ON patient_workout_templates;
DROP POLICY IF EXISTS "patients_own_workout_templates_insert" ON patient_workout_templates;
DROP POLICY IF EXISTS "patients_own_workout_templates_update" ON patient_workout_templates;
DROP POLICY IF EXISTS "patients_own_workout_templates_delete" ON patient_workout_templates;
DROP POLICY IF EXISTS "therapists_view_patient_templates" ON patient_workout_templates;
DROP POLICY IF EXISTS "patient_workout_templates_select" ON patient_workout_templates;
DROP POLICY IF EXISTS "patient_workout_templates_insert" ON patient_workout_templates;
DROP POLICY IF EXISTS "patient_workout_templates_update" ON patient_workout_templates;
DROP POLICY IF EXISTS "patient_workout_templates_delete" ON patient_workout_templates;

-- Drop existing indexes
DROP INDEX IF EXISTS idx_patient_workout_templates_patient_id;
DROP INDEX IF EXISTS idx_patient_workout_templates_usage_count;
DROP INDEX IF EXISTS idx_patient_workout_templates_created_at;
DROP INDEX IF EXISTS idx_patient_workout_templates_exercises_gin;

-- Drop the table if it exists (CASCADE will handle any remaining dependencies)
DROP TABLE IF EXISTS patient_workout_templates CASCADE;

-- Drop the helper function if it exists
DROP FUNCTION IF EXISTS user_owns_patient_template(UUID);

-- ============================================================================
-- 2. CREATE PATIENT WORKOUT TEMPLATES TABLE
-- ============================================================================

CREATE TABLE patient_workout_templates (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Owner relationship
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Basic information
    name TEXT NOT NULL,
    description TEXT,

    -- Category (patient's own categorization - free form)
    category TEXT,

    -- Exercise content as JSONB array
    -- Structure: [{
    --   "exercise_template_id": "uuid or null",
    --   "exercise_name": "Exercise Name",
    --   "block_name": "Warmup/Main/Cooldown",
    --   "sequence": 1,
    --   "target_sets": 3,
    --   "target_reps": "8-12",
    --   "target_load": "bodyweight or 135",
    --   "load_unit": "lbs/kg/bodyweight",
    --   "rest_period_seconds": 60,
    --   "notes": "Optional notes"
    -- }]
    exercises JSONB NOT NULL DEFAULT '[]'::JSONB,

    -- Usage tracking
    usage_count INTEGER NOT NULL DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index on patient_id for filtering by owner
CREATE INDEX idx_patient_workout_templates_patient_id
ON patient_workout_templates(patient_id);

-- Index on usage_count for sorting by popularity
CREATE INDEX idx_patient_workout_templates_usage_count
ON patient_workout_templates(usage_count DESC);

-- Index on created_at for sorting by recency
CREATE INDEX idx_patient_workout_templates_created_at
ON patient_workout_templates(created_at DESC);

-- GIN index on exercises JSONB for searching within exercise content
CREATE INDEX idx_patient_workout_templates_exercises_gin
ON patient_workout_templates USING GIN(exercises);

-- Composite index for patient + recency queries
CREATE INDEX idx_patient_workout_templates_patient_created
ON patient_workout_templates(patient_id, created_at DESC);

-- ============================================================================
-- 4. CREATE TRIGGER FOR updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_patient_workout_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_patient_workout_templates_updated_at
    BEFORE UPDATE ON patient_workout_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_patient_workout_templates_updated_at();

-- ============================================================================
-- 5. CREATE SECURITY DEFINER FUNCTION FOR RLS
-- ============================================================================

-- This function checks if the current user owns a patient template.
-- Using SECURITY DEFINER avoids RLS recursion when the policy queries
-- the patients table (which also has RLS enabled).
--
-- Pattern: Same as user_owns_meal_plan() in meal_plan_items

CREATE OR REPLACE FUNCTION public.user_owns_patient_template(check_template_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM patient_workout_templates pwt
        JOIN patients p ON p.id = pwt.patient_id
        WHERE pwt.id = check_template_id
        AND p.email = (auth.jwt() ->> 'email')
    )
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.user_owns_patient_template(UUID) TO authenticated;

COMMENT ON FUNCTION user_owns_patient_template(UUID) IS
'SECURITY DEFINER function to check template ownership without RLS recursion.
Returns TRUE if the authenticated user (identified by JWT email) owns the template.
Used by RLS policies on patient_workout_templates.';

-- ============================================================================
-- 6. ADD COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE patient_workout_templates IS
'Patient-created workout templates for the Manual Workout Entry feature.
Patients can save their own custom workouts as templates for reuse.
Each template is owned by a single patient and protected by RLS.';

COMMENT ON COLUMN patient_workout_templates.id IS
'Unique identifier for the template.';

COMMENT ON COLUMN patient_workout_templates.patient_id IS
'The patient who owns this template. Enforced by RLS.';

COMMENT ON COLUMN patient_workout_templates.name IS
'Display name of the template chosen by the patient.';

COMMENT ON COLUMN patient_workout_templates.description IS
'Optional description of the workout template.';

COMMENT ON COLUMN patient_workout_templates.category IS
'Patient-defined category (free form, not constrained).';

COMMENT ON COLUMN patient_workout_templates.exercises IS
'JSONB array containing exercise definitions (same structure as system_workout_templates).';

COMMENT ON COLUMN patient_workout_templates.usage_count IS
'Number of times this template has been used to create a manual session.
Incremented automatically by trigger on manual_sessions.';

-- ============================================================================
-- 7. ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS
ALTER TABLE patient_workout_templates ENABLE ROW LEVEL SECURITY;

-- SELECT: Patients can view their own templates
-- Uses SECURITY DEFINER function to avoid RLS recursion
CREATE POLICY "patient_workout_templates_select"
ON patient_workout_templates
FOR SELECT
TO authenticated
USING (user_owns_patient_template(id));

-- INSERT: Patients can create templates for themselves
-- Validates ownership via the patient_id -> patients -> email chain
CREATE POLICY "patient_workout_templates_insert"
ON patient_workout_templates
FOR INSERT
TO authenticated
WITH CHECK (
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
);

-- UPDATE: Patients can update their own templates
-- Uses SECURITY DEFINER function for USING clause
CREATE POLICY "patient_workout_templates_update"
ON patient_workout_templates
FOR UPDATE
TO authenticated
USING (user_owns_patient_template(id));

-- DELETE: Patients can delete their own templates
-- Uses SECURITY DEFINER function
CREATE POLICY "patient_workout_templates_delete"
ON patient_workout_templates
FOR DELETE
TO authenticated
USING (user_owns_patient_template(id));

-- Add policy comments
COMMENT ON POLICY "patient_workout_templates_select" ON patient_workout_templates IS
'Patients can only view their own workout templates.
Uses SECURITY DEFINER function to avoid RLS recursion with patients table.';

COMMENT ON POLICY "patient_workout_templates_insert" ON patient_workout_templates IS
'Patients can only create workout templates for themselves.
Validates ownership through patient email matching JWT.';

COMMENT ON POLICY "patient_workout_templates_update" ON patient_workout_templates IS
'Patients can only update their own workout templates.
Uses SECURITY DEFINER function for ownership check.';

COMMENT ON POLICY "patient_workout_templates_delete" ON patient_workout_templates IS
'Patients can only delete their own workout templates.
Uses SECURITY DEFINER function for ownership check.';

-- ============================================================================
-- 8. GRANT PERMISSIONS
-- ============================================================================

-- Authenticated users can perform all operations (controlled by RLS)
GRANT SELECT, INSERT, UPDATE, DELETE ON patient_workout_templates TO authenticated;

-- Service role has full access for admin operations
GRANT ALL ON patient_workout_templates TO service_role;

-- ============================================================================
-- 9. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_table_exists BOOLEAN;
    v_rls_enabled BOOLEAN;
    v_function_exists BOOLEAN;
    v_policy_count INTEGER;
BEGIN
    -- Check table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'patient_workout_templates'
    ) INTO v_table_exists;

    IF NOT v_table_exists THEN
        RAISE EXCEPTION 'FAILED: patient_workout_templates table was not created';
    END IF;

    -- Check RLS is enabled
    SELECT relrowsecurity
    FROM pg_class
    WHERE relname = 'patient_workout_templates'
    INTO v_rls_enabled;

    IF NOT v_rls_enabled THEN
        RAISE EXCEPTION 'FAILED: RLS is not enabled on patient_workout_templates';
    END IF;

    -- Check SECURITY DEFINER function exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_schema = 'public'
        AND routine_name = 'user_owns_patient_template'
    ) INTO v_function_exists;

    IF NOT v_function_exists THEN
        RAISE EXCEPTION 'FAILED: user_owns_patient_template function was not created';
    END IF;

    -- Count policies
    SELECT COUNT(*)
    FROM pg_policies
    WHERE tablename = 'patient_workout_templates'
    INTO v_policy_count;

    IF v_policy_count < 4 THEN
        RAISE EXCEPTION 'FAILED: Expected 4 RLS policies, found %', v_policy_count;
    END IF;

    RAISE NOTICE 'SUCCESS: patient_workout_templates table created with RLS enabled';
    RAISE NOTICE '  - Table exists: %', v_table_exists;
    RAISE NOTICE '  - RLS enabled: %', v_rls_enabled;
    RAISE NOTICE '  - SECURITY DEFINER function exists: %', v_function_exists;
    RAISE NOTICE '  - Policy count: %', v_policy_count;
END $$;
