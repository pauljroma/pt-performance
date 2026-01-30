-- Migration: Fix Yoga/Pilates Templates Duration Format
-- Date: 2026-01-30
-- Build: 332
--
-- Problem: Some yoga and pilates templates incorrectly show "3 sets of 10 reps"
-- instead of duration-based metrics like "30 sec hold" or "5 breaths".
--
-- Solution: Update JSONB exercises to use duration format for static poses:
-- - For holds/poses: "duration": "30 sec" or "duration": "5 breaths"
-- - For flows: "duration": "1 min"
-- - Remove inappropriate prescribed_sets and prescribed_reps for static poses
--
-- Note: The valid categories in system_workout_templates are:
-- strength, mobility, cardio, hybrid, full_body, upper, lower, push, pull, legs, crossfit, functional
-- Yoga and Pilates templates use 'mobility' category and have 'yoga'/'pilates' in tags

BEGIN;

-- ============================================================================
-- Step 1: Identify affected templates (for logging/verification)
-- ============================================================================
DO $$
DECLARE
    affected_count INTEGER;
BEGIN
    -- Count templates with the problematic pattern
    SELECT COUNT(*) INTO affected_count
    FROM system_workout_templates
    WHERE (
        -- Templates categorized as mobility
        category = 'mobility'
        -- OR templates tagged with yoga/pilates
        OR 'yoga' = ANY(tags)
        OR 'pilates' = ANY(tags)
    )
    AND exercises::text LIKE '%"prescribed_sets": 3%'
    AND exercises::text LIKE '%"prescribed_reps": "10"%';

    RAISE NOTICE 'Found % templates with problematic 3x10 pattern in yoga/pilates/mobility category', affected_count;
END $$;

-- ============================================================================
-- Step 2: Fix templates that use "blocks" structure (newer format)
-- Structure: {"blocks": [{"name": "...", "exercises": [...]}]}
-- ============================================================================
UPDATE system_workout_templates
SET exercises = jsonb_build_object(
    'blocks',
    (
        SELECT jsonb_agg(
            CASE
                -- For blocks that contain yoga/mobility exercises
                WHEN block_elem->>'name' ILIKE '%yoga%'
                    OR block_elem->>'name' ILIKE '%stretch%'
                    OR block_elem->>'name' ILIKE '%mobility%'
                    OR block_elem->>'name' ILIKE '%recovery%'
                    OR block_elem->>'name' ILIKE '%cool%down%'
                    OR block_elem->>'name' ILIKE '%relaxation%'
                    OR block_elem->>'name' ILIKE '%pilates%'
                    OR block_elem->>'name' ILIKE '%core%'
                    OR block_elem->>'name' ILIKE '%balance%'
                THEN jsonb_set(
                    block_elem,
                    '{exercises}',
                    (
                        SELECT COALESCE(jsonb_agg(
                            CASE
                                -- Static poses/holds with 3 sets of 10: convert to duration
                                WHEN (ex->>'prescribed_sets')::int = 3
                                     AND (ex->>'prescribed_reps' = '10' OR ex->>'prescribed_reps' = '10 reps')
                                     AND (
                                         ex->>'name' ILIKE '%pose%'
                                         OR ex->>'name' ILIKE '%hold%'
                                         OR ex->>'name' ILIKE '%stretch%'
                                         OR ex->>'name' ILIKE '%asana%'
                                         OR ex->>'name' ILIKE '%plank%'
                                         OR ex->>'name' ILIKE '%bridge%'
                                         OR ex->>'name' ILIKE '%dog%'
                                         OR ex->>'name' ILIKE '%warrior%'
                                         OR ex->>'name' ILIKE '%triangle%'
                                         OR ex->>'name' ILIKE '%pigeon%'
                                         OR ex->>'name' ILIKE '%fold%'
                                         OR ex->>'name' ILIKE '%twist%'
                                         OR ex->>'name' ILIKE '%savasana%'
                                         OR ex->>'name' ILIKE '%child%'
                                     )
                                THEN (ex - 'prescribed_sets' - 'prescribed_reps') ||
                                     '{"duration": "5 breaths", "notes": "Hold and breathe deeply"}'::jsonb
                                -- Other exercises with 3 sets of 10 in mobility context: convert to 30 sec
                                WHEN (ex->>'prescribed_sets')::int = 3
                                     AND (ex->>'prescribed_reps' = '10' OR ex->>'prescribed_reps' = '10 reps')
                                THEN (ex - 'prescribed_sets' - 'prescribed_reps') ||
                                     '{"duration": "30 sec"}'::jsonb
                                -- Keep exercises that already have duration
                                WHEN ex->>'duration' IS NOT NULL
                                THEN ex
                                -- Keep other exercises as-is
                                ELSE ex
                            END
                        ), '[]'::jsonb)
                        FROM jsonb_array_elements(block_elem->'exercises') AS ex
                    )
                )
                ELSE block_elem
            END
        )
        FROM jsonb_array_elements(exercises->'blocks') AS block_elem
    )
)
WHERE exercises ? 'blocks'
  AND (
      category = 'mobility'
      OR 'yoga' = ANY(tags)
      OR 'pilates' = ANY(tags)
  )
  AND exercises::text LIKE '%"prescribed_sets": 3%'
  AND exercises::text LIKE '%"prescribed_reps": "10"%';

-- ============================================================================
-- Step 3: Fix templates that use flat array structure (older format)
-- Structure: [{"name": "...", "block_type": "...", "exercises": [...]}]
-- ============================================================================
UPDATE system_workout_templates
SET exercises = (
    SELECT COALESCE(jsonb_agg(
        CASE
            -- For blocks with yoga/mobility/recovery block types
            WHEN block_elem->>'block_type' IN ('yoga', 'mobility', 'static_stretch', 'flexibility',
                                                'recovery', 'cooldown', 'dynamic_stretch', 'prehab')
                OR block_elem->>'name' ILIKE '%yoga%'
                OR block_elem->>'name' ILIKE '%stretch%'
                OR block_elem->>'name' ILIKE '%mobility%'
                OR block_elem->>'name' ILIKE '%recovery%'
                OR block_elem->>'name' ILIKE '%cool%down%'
                OR block_elem->>'name' ILIKE '%dynamic%'
            THEN jsonb_set(
                block_elem,
                '{exercises}',
                (
                    SELECT COALESCE(jsonb_agg(
                        CASE
                            -- Yoga/stretch poses with 3 sets of 10: convert to duration
                            WHEN (ex->>'prescribed_sets')::int = 3
                                 AND (ex->>'prescribed_reps' = '10' OR ex->>'prescribed_reps' = '10 reps')
                                 AND (
                                     ex->>'name' ILIKE '%yoga%'
                                     OR ex->>'name' ILIKE '%pose%'
                                     OR ex->>'name' ILIKE '%hold%'
                                     OR ex->>'name' ILIKE '%stretch%'
                                     OR ex->>'name' ILIKE '%flow%'
                                     OR ex->>'name' ILIKE '%pigeon%'
                                     OR ex->>'name' ILIKE '%dog%'
                                     OR ex->>'name' ILIKE '%lunge%'
                                 )
                            THEN (ex - 'prescribed_sets' - 'prescribed_reps') ||
                                 '{"duration": "30 sec", "notes": "Focus on breath and form"}'::jsonb
                            -- Keep exercises that already have duration
                            WHEN ex->>'duration' IS NOT NULL
                            THEN ex
                            -- Keep other exercises as-is
                            ELSE ex
                        END
                    ), '[]'::jsonb)
                    FROM jsonb_array_elements(block_elem->'exercises') AS ex
                )
            )
            ELSE block_elem
        END
    ), '[]'::jsonb)
    FROM jsonb_array_elements(exercises) AS block_elem
)
WHERE NOT (exercises ? 'blocks')  -- Only flat array structures
  AND jsonb_typeof(exercises) = 'array'
  AND (
      category = 'mobility'
      OR 'yoga' = ANY(tags)
      OR 'pilates' = ANY(tags)
  )
  AND exercises::text LIKE '%"prescribed_sets": 3%'
  AND exercises::text LIKE '%"prescribed_reps": "10"%';

-- ============================================================================
-- Step 4: Verification
-- ============================================================================
DO $$
DECLARE
    remaining_count INTEGER;
    updated_yoga INTEGER;
    updated_pilates INTEGER;
BEGIN
    -- Count remaining templates with problematic pattern
    SELECT COUNT(*) INTO remaining_count
    FROM system_workout_templates
    WHERE (
        category = 'mobility'
        OR 'yoga' = ANY(tags)
        OR 'pilates' = ANY(tags)
    )
    AND exercises::text LIKE '%"prescribed_sets": 3%'
    AND exercises::text LIKE '%"prescribed_reps": "10"%';

    -- Count templates now using duration format
    SELECT COUNT(*) INTO updated_yoga
    FROM system_workout_templates
    WHERE ('yoga' = ANY(tags) OR category = 'mobility')
    AND exercises::text LIKE '%"duration":%';

    SELECT COUNT(*) INTO updated_pilates
    FROM system_workout_templates
    WHERE 'pilates' = ANY(tags)
    AND exercises::text LIKE '%"duration":%';

    IF remaining_count = 0 THEN
        RAISE NOTICE 'SUCCESS: All yoga/pilates templates now use duration-based metrics';
        RAISE NOTICE '  - Yoga/mobility templates with duration: %', updated_yoga;
        RAISE NOTICE '  - Pilates templates with duration: %', updated_pilates;
    ELSE
        RAISE WARNING 'ATTENTION: % templates still have 3x10 pattern - may require manual review', remaining_count;
    END IF;
END $$;

COMMIT;
