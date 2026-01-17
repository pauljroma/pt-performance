-- Migration: Update exercise_logs for Manual Workout Entry
-- Purpose: Allow exercise_logs to reference manual session exercises
-- Part 4 of 4 for Manual Workout Entry feature

-- ============================================================================
-- 1. MAKE session_exercise_id NULLABLE
-- ============================================================================

-- session_exercise_id needs to be nullable so exercise_logs can reference
-- manual_session_exercises instead of session_exercises
ALTER TABLE exercise_logs
ALTER COLUMN session_exercise_id DROP NOT NULL;

-- ============================================================================
-- 2. ADD manual_session_exercise_id COLUMN
-- ============================================================================

-- Add the new column for referencing manual session exercises
ALTER TABLE exercise_logs
ADD COLUMN IF NOT EXISTS manual_session_exercise_id UUID
REFERENCES manual_session_exercises(id) ON DELETE CASCADE;

-- ============================================================================
-- 3. ADD XOR CONSTRAINT (exactly one reference)
-- ============================================================================

-- Drop existing constraint if it exists (for idempotency)
ALTER TABLE exercise_logs
DROP CONSTRAINT IF EXISTS exercise_logs_xor_exercise_reference;

-- Add constraint: must have exactly one of session_exercise_id OR manual_session_exercise_id
-- This ensures every exercise log is linked to either a program exercise or a manual exercise
ALTER TABLE exercise_logs
ADD CONSTRAINT exercise_logs_xor_exercise_reference
CHECK (
    (session_exercise_id IS NOT NULL AND manual_session_exercise_id IS NULL)
    OR
    (session_exercise_id IS NULL AND manual_session_exercise_id IS NOT NULL)
);

-- ============================================================================
-- 4. CREATE INDEX FOR NEW COLUMN
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_exercise_logs_manual_session_exercise
ON exercise_logs(manual_session_exercise_id)
WHERE manual_session_exercise_id IS NOT NULL;

-- ============================================================================
-- 5. UPDATE RLS POLICIES
-- ============================================================================

-- Update the patient select policy to include manual session exercises
DROP POLICY IF EXISTS "patients_own_exercise_logs_select" ON exercise_logs;
CREATE POLICY "patients_own_exercise_logs_select"
ON exercise_logs
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
);

-- Update the patient insert policy
DROP POLICY IF EXISTS "patients_own_exercise_logs_insert" ON exercise_logs;
CREATE POLICY "patients_own_exercise_logs_insert"
ON exercise_logs
FOR INSERT
TO authenticated
WITH CHECK (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
    AND (
        -- Either logging to a program session exercise
        (session_exercise_id IS NOT NULL AND manual_session_exercise_id IS NULL)
        OR
        -- Or logging to a manual session exercise they own
        (
            manual_session_exercise_id IS NOT NULL
            AND session_exercise_id IS NULL
            AND manual_session_exercise_id IN (
                SELECT mse.id
                FROM manual_session_exercises mse
                JOIN manual_sessions ms ON mse.manual_session_id = ms.id
                WHERE ms.patient_id IN (
                    SELECT id FROM patients WHERE user_id = auth.uid()
                )
            )
        )
    )
);

-- Update the patient update policy
DROP POLICY IF EXISTS "patients_own_exercise_logs_update" ON exercise_logs;
CREATE POLICY "patients_own_exercise_logs_update"
ON exercise_logs
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

-- Update the patient delete policy
DROP POLICY IF EXISTS "patients_own_exercise_logs_delete" ON exercise_logs;
CREATE POLICY "patients_own_exercise_logs_delete"
ON exercise_logs
FOR DELETE
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    )
);

-- Therapists can view their patients' exercise logs
DROP POLICY IF EXISTS "therapists_view_patient_exercise_logs" ON exercise_logs;
CREATE POLICY "therapists_view_patient_exercise_logs"
ON exercise_logs
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

-- ============================================================================
-- 6. ADD COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON COLUMN exercise_logs.session_exercise_id IS
'Reference to program session exercise. NULL if this log is for a manual session exercise.
XOR constraint ensures exactly one of session_exercise_id or manual_session_exercise_id is set.';

COMMENT ON COLUMN exercise_logs.manual_session_exercise_id IS
'Reference to manual session exercise. NULL if this log is for a program session exercise.
XOR constraint ensures exactly one of session_exercise_id or manual_session_exercise_id is set.';

COMMENT ON CONSTRAINT exercise_logs_xor_exercise_reference ON exercise_logs IS
'Ensures each exercise log is linked to exactly one exercise reference:
either a program session exercise (session_exercise_id) or a manual session exercise (manual_session_exercise_id).
Both cannot be set, and at least one must be set.';

-- ============================================================================
-- 7. CREATE HELPER VIEW FOR UNIFIED EXERCISE LOG ACCESS
-- ============================================================================

CREATE OR REPLACE VIEW vw_exercise_logs_unified AS
SELECT
    el.id,
    el.patient_id,
    el.session_exercise_id,
    el.manual_session_exercise_id,

    -- Source type
    CASE
        WHEN el.session_exercise_id IS NOT NULL THEN 'program'
        WHEN el.manual_session_exercise_id IS NOT NULL THEN 'manual'
    END AS source_type,

    -- Exercise name (from either source)
    COALESCE(
        et_program.name,
        mse.exercise_name
    ) AS exercise_name,

    -- Session identifiers
    se.session_id AS program_session_id,
    mse.manual_session_id,

    -- Log data (using actual column names from exercise_logs table)
    el.actual_sets,
    el.actual_reps,
    el.actual_load,
    el.load_unit,
    el.rpe,
    el.pain_score,
    el.notes,
    el.logged_at

FROM exercise_logs el
LEFT JOIN session_exercises se ON el.session_exercise_id = se.id
LEFT JOIN exercise_templates et_program ON se.exercise_template_id = et_program.id
LEFT JOIN manual_session_exercises mse ON el.manual_session_exercise_id = mse.id;

COMMENT ON VIEW vw_exercise_logs_unified IS
'Unified view of exercise logs that joins both program-based and manual session exercises.
Use this view to query all exercise logs regardless of source.';

GRANT SELECT ON vw_exercise_logs_unified TO authenticated;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_has_constraint BOOLEAN;
    v_has_column BOOLEAN;
BEGIN
    -- Check if manual_session_exercise_id column exists
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'exercise_logs'
        AND column_name = 'manual_session_exercise_id'
    ) INTO v_has_column;

    IF v_has_column THEN
        RAISE NOTICE 'SUCCESS: manual_session_exercise_id column exists';
    ELSE
        RAISE EXCEPTION 'FAILED: manual_session_exercise_id column was not created';
    END IF;

    -- Check if XOR constraint exists
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE table_name = 'exercise_logs'
        AND constraint_name = 'exercise_logs_xor_exercise_reference'
    ) INTO v_has_constraint;

    IF v_has_constraint THEN
        RAISE NOTICE 'SUCCESS: XOR constraint exists on exercise_logs';
    ELSE
        RAISE EXCEPTION 'FAILED: XOR constraint was not created';
    END IF;
END $$;
