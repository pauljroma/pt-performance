-- Migration: Create System Workout Templates Table
-- Created: 2026-01-21
-- Purpose: Pre-loaded library of workout templates for the Manual Workout Entry feature
-- Part 1 of 4 for Manual Workout Entry feature
--
-- This migration creates the system_workout_templates table which stores
-- pre-defined workout templates that all users can browse and use as
-- starting points for manual workout sessions.

-- ============================================================================
-- 1. DROP EXISTING TABLE IF EXISTS (for clean slate)
-- ============================================================================

-- Drop dependent objects first
DROP INDEX IF EXISTS idx_system_workout_templates_category;
DROP INDEX IF EXISTS idx_system_workout_templates_difficulty;
DROP INDEX IF EXISTS idx_system_workout_templates_tags_gin;
DROP INDEX IF EXISTS idx_system_workout_templates_exercises_gin;

-- Drop the table if it exists (will cascade policies)
DROP TABLE IF EXISTS system_workout_templates CASCADE;

-- ============================================================================
-- 2. CREATE SYSTEM WORKOUT TEMPLATES TABLE
-- ============================================================================

CREATE TABLE system_workout_templates (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Basic information
    name TEXT NOT NULL,
    description TEXT,

    -- Classification
    category TEXT NOT NULL CHECK (category IN (
        'strength',      -- Traditional strength training
        'mobility',      -- Mobility and flexibility work
        'cardio',        -- Cardiovascular focused
        'hybrid',        -- Mix of modalities
        'full_body',     -- Full body workout
        'upper',         -- Upper body focused
        'lower',         -- Lower body focused
        'push',          -- Push movement pattern
        'pull',          -- Pull movement pattern
        'legs',          -- Leg focused
        'crossfit',      -- CrossFit style workouts
        'functional'     -- Functional fitness
    )),

    -- Difficulty level
    difficulty TEXT NOT NULL CHECK (difficulty IN (
        'beginner',
        'intermediate',
        'advanced'
    )),

    -- Duration estimate
    duration_minutes INTEGER CHECK (duration_minutes > 0),

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

    -- Searchable tags for filtering
    tags TEXT[] DEFAULT '{}',

    -- Source tracking for imports
    source_file TEXT,

    -- Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index on category for filtering workouts by type
CREATE INDEX idx_system_workout_templates_category
ON system_workout_templates(category);

-- Index on difficulty for filtering by skill level
CREATE INDEX idx_system_workout_templates_difficulty
ON system_workout_templates(difficulty);

-- GIN index on tags for efficient array contains queries
-- Supports queries like: WHERE 'upper_body' = ANY(tags)
CREATE INDEX idx_system_workout_templates_tags_gin
ON system_workout_templates USING GIN(tags);

-- GIN index on exercises JSONB for searching within exercise content
CREATE INDEX idx_system_workout_templates_exercises_gin
ON system_workout_templates USING GIN(exercises);

-- Composite index for common filter combinations
CREATE INDEX idx_system_workout_templates_category_difficulty
ON system_workout_templates(category, difficulty);

-- ============================================================================
-- 4. ADD COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE system_workout_templates IS
'Pre-loaded library of system workout templates for the Manual Workout Entry feature.
These templates are read-only for all users and serve as starting points for manual sessions.
Managed by administrators/system only.';

COMMENT ON COLUMN system_workout_templates.id IS
'Unique identifier for the template.';

COMMENT ON COLUMN system_workout_templates.name IS
'Display name of the workout template (e.g., "Push Day A", "Full Body Strength").';

COMMENT ON COLUMN system_workout_templates.description IS
'Optional detailed description of the workout, goals, and instructions.';

COMMENT ON COLUMN system_workout_templates.category IS
'Primary classification: strength, mobility, cardio, hybrid, full_body, upper, lower, push, pull, legs, crossfit, functional.';

COMMENT ON COLUMN system_workout_templates.difficulty IS
'Target skill level: beginner, intermediate, or advanced.';

COMMENT ON COLUMN system_workout_templates.duration_minutes IS
'Estimated duration of the workout in minutes.';

COMMENT ON COLUMN system_workout_templates.exercises IS
'JSONB array containing exercise definitions with sets, reps, load targets, and notes.';

COMMENT ON COLUMN system_workout_templates.tags IS
'Array of searchable tags (e.g., upper_body, compound, dumbbell, beginner_friendly, quick).';

COMMENT ON COLUMN system_workout_templates.source_file IS
'Reference to source file if imported (e.g., "workouts/strength/push_day.json").';

-- ============================================================================
-- 5. ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS
ALTER TABLE system_workout_templates ENABLE ROW LEVEL SECURITY;

-- System templates are PUBLIC - everyone can SELECT
-- No SECURITY DEFINER function needed since this is a simple public read
DROP POLICY IF EXISTS "system_workout_templates_public_read" ON system_workout_templates;
CREATE POLICY "system_workout_templates_public_read"
ON system_workout_templates
FOR SELECT
TO authenticated
USING (true);

-- Note: No INSERT/UPDATE/DELETE policies for authenticated users
-- System templates are managed by administrators via direct database access
-- or service role connections only

COMMENT ON POLICY "system_workout_templates_public_read" ON system_workout_templates IS
'All authenticated users can read system workout templates.
These are public/shared templates available to everyone.';

-- ============================================================================
-- 6. GRANT PERMISSIONS
-- ============================================================================

-- Authenticated users can only SELECT
GRANT SELECT ON system_workout_templates TO authenticated;

-- Service role has full access for admin operations
GRANT ALL ON system_workout_templates TO service_role;

-- ============================================================================
-- 7. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_table_exists BOOLEAN;
    v_rls_enabled BOOLEAN;
    v_policy_exists BOOLEAN;
BEGIN
    -- Check table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'system_workout_templates'
    ) INTO v_table_exists;

    IF NOT v_table_exists THEN
        RAISE EXCEPTION 'FAILED: system_workout_templates table was not created';
    END IF;

    -- Check RLS is enabled
    SELECT relrowsecurity
    FROM pg_class
    WHERE relname = 'system_workout_templates'
    INTO v_rls_enabled;

    IF NOT v_rls_enabled THEN
        RAISE EXCEPTION 'FAILED: RLS is not enabled on system_workout_templates';
    END IF;

    -- Check policy exists
    SELECT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'system_workout_templates'
        AND policyname = 'system_workout_templates_public_read'
    ) INTO v_policy_exists;

    IF NOT v_policy_exists THEN
        RAISE EXCEPTION 'FAILED: RLS policy was not created';
    END IF;

    RAISE NOTICE 'SUCCESS: system_workout_templates table created with RLS enabled';
    RAISE NOTICE '  - Table exists: %', v_table_exists;
    RAISE NOTICE '  - RLS enabled: %', v_rls_enabled;
    RAISE NOTICE '  - Policy exists: %', v_policy_exists;
END $$;
