-- Migration: Create System Workout Templates Table
-- Purpose: Pre-loaded library of workout templates for the Manual Workout Entry feature
-- Part 1 of 4 for Manual Workout Entry feature

-- ============================================================================
-- 1. CREATE SYSTEM WORKOUT TEMPLATES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS system_workout_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Basic info
    name TEXT NOT NULL,
    description TEXT,

    -- Classification
    category TEXT NOT NULL CHECK (category IN (
        'strength', 'mobility', 'cardio', 'hybrid',
        'full_body', 'upper', 'lower', 'push', 'pull', 'legs'
    )),
    difficulty TEXT NOT NULL CHECK (difficulty IN (
        'beginner', 'intermediate', 'advanced'
    )),

    -- Duration and content
    duration_minutes INTEGER,
    exercises JSONB NOT NULL DEFAULT '[]'::JSONB,

    -- Searchable tags
    tags TEXT[] DEFAULT '{}',

    -- Source tracking (for importing from files/external sources)
    source_file TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index on category for filtering
CREATE INDEX IF NOT EXISTS idx_system_workout_templates_category
ON system_workout_templates(category);

-- Index on difficulty for filtering
CREATE INDEX IF NOT EXISTS idx_system_workout_templates_difficulty
ON system_workout_templates(difficulty);

-- GIN index on tags for array contains queries
CREATE INDEX IF NOT EXISTS idx_system_workout_templates_tags_gin
ON system_workout_templates USING GIN(tags);

-- GIN index on exercises JSONB for searching within exercises
CREATE INDEX IF NOT EXISTS idx_system_workout_templates_exercises_gin
ON system_workout_templates USING GIN(exercises);

-- ============================================================================
-- 3. ADD COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE system_workout_templates IS
'Pre-loaded library of system workout templates for the Manual Workout Entry feature.
These templates are read-only for patients and can be used as starting points for manual sessions.';

COMMENT ON COLUMN system_workout_templates.exercises IS
'JSONB array of exercise definitions:
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

COMMENT ON COLUMN system_workout_templates.tags IS
'Array of searchable tags like: upper_body, compound, dumbbell, beginner_friendly, quick, etc.';

COMMENT ON COLUMN system_workout_templates.source_file IS
'Reference to source file if imported from external source (e.g., "workouts/strength/push_day.json")';

-- ============================================================================
-- 4. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE system_workout_templates ENABLE ROW LEVEL SECURITY;

-- System templates are read-only for all authenticated users
DROP POLICY IF EXISTS "system_workout_templates_read_all" ON system_workout_templates;
CREATE POLICY "system_workout_templates_read_all"
ON system_workout_templates
FOR SELECT
TO authenticated
USING (true);

COMMENT ON POLICY "system_workout_templates_read_all" ON system_workout_templates IS
'All authenticated users can read system workout templates. These are public/shared templates.';

-- ============================================================================
-- 5. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT ON system_workout_templates TO authenticated;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'system_workout_templates') THEN
        RAISE NOTICE 'SUCCESS: system_workout_templates table created';
    ELSE
        RAISE EXCEPTION 'FAILED: system_workout_templates table was not created';
    END IF;
END $$;
