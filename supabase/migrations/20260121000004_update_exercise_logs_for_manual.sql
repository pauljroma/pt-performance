-- Migration: Update exercise_logs for Manual Workout Entry
-- Created: 2026-01-21
-- Purpose: Allow exercise_logs to reference manual session exercises
-- Part 4 of 4 for Manual Workout Entry feature
--
-- This migration:
--   1. Makes session_exercise_id nullable
--   2. Adds manual_session_exercise_id column
--   3. Adds XOR constraint: exactly one of session_exercise_id OR manual_session_exercise_id must be set
--
-- This enables exercise_logs to track both:
--   - Program-based exercises (via session_exercise_id)
--   - Manual/ad-hoc exercises (via manual_session_exercise_id)

-- ============================================================================
-- 1. MAKE session_exercise_id NULLABLE
-- ============================================================================

-- session_exercise_id needs to be nullable so exercise_logs can reference
-- manual_session_exercises instead of session_exercises for manual workouts
ALTER TABLE exercise_logs
ALTER COLUMN session_exercise_id DROP NOT NULL;

COMMENT ON COLUMN exercise_logs.session_exercise_id IS
'Reference to program session exercise. NULL if this log is for a manual session exercise.
XOR constraint ensures exactly one of session_exercise_id or manual_session_exercise_id is set.';

-- ============================================================================
-- 2. ADD manual_session_exercise_id COLUMN
-- ============================================================================

-- Add the new column for referencing manual session exercises
-- Only add if it doesn't exist (for idempotency)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'exercise_logs'
        AND column_name = 'manual_session_exercise_id'
    ) THEN
        ALTER TABLE exercise_logs
        ADD COLUMN manual_session_exercise_id UUID
        REFERENCES manual_session_exercises(id) ON DELETE CASCADE;
    END IF;
END $$;

COMMENT ON COLUMN exercise_logs.manual_session_exercise_id IS
'Reference to manual session exercise. NULL if this log is for a program session exercise.
XOR constraint ensures exactly one of session_exercise_id or manual_session_exercise_id is set.';

-- ============================================================================
-- 3. ADD XOR CONSTRAINT (exactly one reference)
-- ============================================================================

-- Drop existing constraint if it exists (for idempotency)
ALTER TABLE exercise_logs
DROP CONSTRAINT IF EXISTS exercise_logs_xor_exercise_reference;

-- Add constraint: must have exactly one of session_exercise_id OR manual_session_exercise_id
-- This ensures every exercise log is linked to either:
--   - A program exercise (session_exercise_id IS NOT NULL)
--   - OR a manual exercise (manual_session_exercise_id IS NOT NULL)
-- But never both, and never neither.
ALTER TABLE exercise_logs
ADD CONSTRAINT exercise_logs_xor_exercise_reference
CHECK (
    -- Option 1: Program exercise log
    (session_exercise_id IS NOT NULL AND manual_session_exercise_id IS NULL)
    OR
    -- Option 2: Manual exercise log
    (session_exercise_id IS NULL AND manual_session_exercise_id IS NOT NULL)
);

COMMENT ON CONSTRAINT exercise_logs_xor_exercise_reference ON exercise_logs IS
'XOR constraint ensuring each exercise log is linked to exactly one exercise reference:
- Program session exercise (session_exercise_id IS NOT NULL, manual_session_exercise_id IS NULL)
- OR Manual session exercise (session_exercise_id IS NULL, manual_session_exercise_id IS NOT NULL)
Both cannot be set simultaneously, and at least one must be set.';

-- ============================================================================
-- 4. CREATE INDEX FOR NEW COLUMN
-- ============================================================================

-- Create index for efficient lookups on manual_session_exercise_id
-- Partial index only includes rows where the column is not null
DROP INDEX IF EXISTS idx_exercise_logs_manual_session_exercise;

CREATE INDEX idx_exercise_logs_manual_session_exercise
ON exercise_logs(manual_session_exercise_id)
WHERE manual_session_exercise_id IS NOT NULL;

-- ============================================================================
-- 5. CREATE HELPER VIEW FOR UNIFIED EXERCISE LOG ACCESS
-- ============================================================================

-- This view provides a unified way to query exercise logs regardless of source
-- It joins with both session_exercises (program) and manual_session_exercises (manual)
DROP VIEW IF EXISTS vw_exercise_logs_unified;

CREATE VIEW vw_exercise_logs_unified AS
SELECT
    el.id,
    el.patient_id,
    el.session_exercise_id,
    el.manual_session_exercise_id,

    -- Source type indicator
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

    -- Log data
    el.actual_sets,
    el.actual_reps,
    el.actual_load,
    el.load_unit,
    el.rpe,
    el.pain_score,
    el.notes,
    el.logged_at,

    -- Additional context
    CASE
        WHEN el.session_exercise_id IS NOT NULL THEN s.name
        WHEN el.manual_session_exercise_id IS NOT NULL THEN ms.name
    END AS session_name

FROM exercise_logs el
-- Program exercise joins
LEFT JOIN session_exercises se ON el.session_exercise_id = se.id
LEFT JOIN exercise_templates et_program ON se.exercise_template_id = et_program.id
LEFT JOIN sessions s ON se.session_id = s.id
-- Manual exercise joins
LEFT JOIN manual_session_exercises mse ON el.manual_session_exercise_id = mse.id
LEFT JOIN manual_sessions ms ON mse.manual_session_id = ms.id;

COMMENT ON VIEW vw_exercise_logs_unified IS
'Unified view of exercise logs that joins both program-based and manual session exercises.
Use this view to query all exercise logs regardless of source.
The source_type column indicates whether the log is from a "program" or "manual" workout.';

GRANT SELECT ON vw_exercise_logs_unified TO authenticated;

-- ============================================================================
-- 6. CREATE SECURITY DEFINER FUNCTION FOR MANUAL EXERCISE LOG OWNERSHIP
-- ============================================================================

-- Function to check if user owns an exercise log that references a manual session exercise
CREATE OR REPLACE FUNCTION public.user_owns_exercise_log_manual(check_log_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM exercise_logs el
        JOIN manual_session_exercises mse ON el.manual_session_exercise_id = mse.id
        JOIN manual_sessions ms ON mse.manual_session_id = ms.id
        JOIN patients p ON p.id = ms.patient_id
        WHERE el.id = check_log_id
        AND p.email = (auth.jwt() ->> 'email')
    )
$$;

GRANT EXECUTE ON FUNCTION public.user_owns_exercise_log_manual(UUID) TO authenticated;

COMMENT ON FUNCTION user_owns_exercise_log_manual(UUID) IS
'SECURITY DEFINER function to check if user owns an exercise log via manual session.
Used to extend RLS policies for exercise_logs to support manual workout entries.';

-- ============================================================================
-- 7. UPDATE RLS POLICIES FOR EXERCISE LOGS
-- ============================================================================

-- Note: This adds support for manual session exercise logs.
-- Existing policies for program exercise logs should remain functional.
-- We add new policies that OR with existing conditions.

-- Drop existing policies to recreate them with manual session support
DROP POLICY IF EXISTS "patients_own_exercise_logs_select" ON exercise_logs;
DROP POLICY IF EXISTS "patients_own_exercise_logs_insert" ON exercise_logs;
DROP POLICY IF EXISTS "patients_own_exercise_logs_update" ON exercise_logs;
DROP POLICY IF EXISTS "patients_own_exercise_logs_delete" ON exercise_logs;
DROP POLICY IF EXISTS "therapists_view_patient_exercise_logs" ON exercise_logs;
DROP POLICY IF EXISTS "exercise_logs_select" ON exercise_logs;
DROP POLICY IF EXISTS "exercise_logs_insert" ON exercise_logs;
DROP POLICY IF EXISTS "exercise_logs_update" ON exercise_logs;
DROP POLICY IF EXISTS "exercise_logs_delete" ON exercise_logs;

-- SELECT: Patients can view their own exercise logs (both program and manual)
CREATE POLICY "exercise_logs_select"
ON exercise_logs
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
);

-- INSERT: Patients can create exercise logs for exercises they own
CREATE POLICY "exercise_logs_insert"
ON exercise_logs
FOR INSERT
TO authenticated
WITH CHECK (
    -- Must be the patient's own log
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
    AND
    (
        -- Option 1: Program exercise log (session_exercise_id set)
        (
            session_exercise_id IS NOT NULL
            AND manual_session_exercise_id IS NULL
        )
        OR
        -- Option 2: Manual exercise log (manual_session_exercise_id set)
        (
            manual_session_exercise_id IS NOT NULL
            AND session_exercise_id IS NULL
            AND manual_session_exercise_id IN (
                SELECT mse.id
                FROM manual_session_exercises mse
                JOIN manual_sessions ms ON mse.manual_session_id = ms.id
                JOIN patients p ON ms.patient_id = p.id
                WHERE p.email = (auth.jwt() ->> 'email')
            )
        )
    )
);

-- UPDATE: Patients can update their own exercise logs
CREATE POLICY "exercise_logs_update"
ON exercise_logs
FOR UPDATE
TO authenticated
USING (
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
)
WITH CHECK (
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
);

-- DELETE: Patients can delete their own exercise logs
CREATE POLICY "exercise_logs_delete"
ON exercise_logs
FOR DELETE
TO authenticated
USING (
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
);

-- Policy comments
COMMENT ON POLICY "exercise_logs_select" ON exercise_logs IS
'Patients can view their own exercise logs (both program and manual).
Uses patient email from JWT for ownership check.';

COMMENT ON POLICY "exercise_logs_insert" ON exercise_logs IS
'Patients can create exercise logs for:
1. Program exercises (session_exercise_id) they are assigned
2. Manual session exercises (manual_session_exercise_id) they own
XOR constraint is enforced at DB level.';

COMMENT ON POLICY "exercise_logs_update" ON exercise_logs IS
'Patients can update their own exercise logs.
Uses patient email from JWT for ownership check.';

COMMENT ON POLICY "exercise_logs_delete" ON exercise_logs IS
'Patients can delete their own exercise logs.
Uses patient email from JWT for ownership check.';

-- ============================================================================
-- 8. ADD DOCUMENTATION
-- ============================================================================

-- Update table comment to reflect dual-source capability
COMMENT ON TABLE exercise_logs IS
'Exercise logs tracking actual performance for both program-based and manual workouts.
Each log is linked to exactly one exercise reference:
- session_exercise_id: For exercises from prescribed programs
- manual_session_exercise_id: For exercises from manual/ad-hoc workouts
The XOR constraint (exercise_logs_xor_exercise_reference) ensures data integrity.';

-- ============================================================================
-- 9. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_has_column BOOLEAN;
    v_has_constraint BOOLEAN;
    v_has_index BOOLEAN;
    v_has_view BOOLEAN;
    v_policy_count INTEGER;
BEGIN
    -- Check if manual_session_exercise_id column exists
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'exercise_logs'
        AND column_name = 'manual_session_exercise_id'
    ) INTO v_has_column;

    IF NOT v_has_column THEN
        RAISE EXCEPTION 'FAILED: manual_session_exercise_id column was not created';
    END IF;

    -- Check if XOR constraint exists
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE table_schema = 'public'
        AND table_name = 'exercise_logs'
        AND constraint_name = 'exercise_logs_xor_exercise_reference'
    ) INTO v_has_constraint;

    IF NOT v_has_constraint THEN
        RAISE EXCEPTION 'FAILED: XOR constraint was not created';
    END IF;

    -- Check if index exists
    SELECT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'public'
        AND tablename = 'exercise_logs'
        AND indexname = 'idx_exercise_logs_manual_session_exercise'
    ) INTO v_has_index;

    IF NOT v_has_index THEN
        RAISE EXCEPTION 'FAILED: Index on manual_session_exercise_id was not created';
    END IF;

    -- Check if unified view exists
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.views
        WHERE table_schema = 'public'
        AND table_name = 'vw_exercise_logs_unified'
    ) INTO v_has_view;

    IF NOT v_has_view THEN
        RAISE EXCEPTION 'FAILED: vw_exercise_logs_unified view was not created';
    END IF;

    -- Count RLS policies
    SELECT COUNT(*)
    FROM pg_policies
    WHERE tablename = 'exercise_logs'
    INTO v_policy_count;

    RAISE NOTICE 'SUCCESS: exercise_logs updated for manual workout support';
    RAISE NOTICE '  - manual_session_exercise_id column: %', v_has_column;
    RAISE NOTICE '  - XOR constraint: %', v_has_constraint;
    RAISE NOTICE '  - Index created: %', v_has_index;
    RAISE NOTICE '  - Unified view: %', v_has_view;
    RAISE NOTICE '  - RLS policy count: %', v_policy_count;
END $$;
