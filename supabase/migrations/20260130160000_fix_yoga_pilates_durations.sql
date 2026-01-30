-- BUILD 331: Fix yoga/pilates templates to use duration-based metrics
-- Problem: Yoga/Pilates exercises showing "3 sets of 10 reps" instead of duration/breaths
-- Solution: Convert to "5 breaths" format for holds, "30 sec" for timed exercises

-- Update yoga templates with breath-based durations
UPDATE system_workout_templates
SET exercises = (
    SELECT jsonb_agg(
        CASE
            WHEN block_elem->>'block_type' IN ('yoga', 'mobility', 'static_stretch', 'flexibility', 'recovery', 'cooldown')
            THEN jsonb_set(
                jsonb_set(
                    block_elem,
                    '{exercises}',
                    (
                        SELECT jsonb_agg(
                            CASE
                                -- For yoga/mobility exercises with 3 sets of 10, convert to 5 breaths
                                WHEN (ex->>'prescribed_sets')::int = 3
                                     AND (ex->>'prescribed_reps' = '10' OR ex->>'prescribed_reps' = '10 reps')
                                THEN ex - 'prescribed_sets' - 'prescribed_reps' ||
                                     '{"duration": "5 breaths", "notes": "Hold and breathe deeply"}'::jsonb
                                -- For exercises with just reps, convert to breaths
                                WHEN ex->>'prescribed_reps' IS NOT NULL
                                     AND (ex->>'prescribed_reps')::text ~ '^[0-9]+$'
                                     AND (ex->>'prescribed_reps')::int <= 15
                                THEN ex - 'prescribed_sets' - 'prescribed_reps' ||
                                     jsonb_build_object('duration', (ex->>'prescribed_reps')::int || ' breaths')
                                -- Keep exercises that already have duration
                                WHEN ex->>'duration' IS NOT NULL
                                THEN ex
                                -- Default: keep as-is for dynamic movements
                                ELSE ex
                            END
                        )
                        FROM jsonb_array_elements(block_elem->'exercises') AS ex
                    )
                ),
                '{notes}',
                COALESCE(block_elem->'notes', '"Focus on breath and form"'::jsonb)
            )
            ELSE block_elem
        END
    )
    FROM jsonb_array_elements(exercises) AS block_elem
)
WHERE category IN ('mobility', 'yoga', 'flexibility', 'recovery')
  AND exercises::text LIKE '%"prescribed_sets": 3%'
  AND exercises::text LIKE '%"prescribed_reps": "10"%';

-- Update pilates templates similarly
UPDATE system_workout_templates
SET exercises = (
    SELECT jsonb_agg(
        CASE
            WHEN block_elem->>'block_type' IN ('pilates', 'core', 'activation', 'stability')
            THEN jsonb_set(
                block_elem,
                '{exercises}',
                (
                    SELECT jsonb_agg(
                        CASE
                            -- Pilates holds: convert to breaths
                            WHEN (ex->>'prescribed_sets')::int = 3
                                 AND (ex->>'prescribed_reps' = '10' OR ex->>'prescribed_reps' = '10 reps')
                                 AND (ex->>'name' ILIKE '%plank%' OR ex->>'name' ILIKE '%hold%' OR
                                      ex->>'name' ILIKE '%bird%' OR ex->>'name' ILIKE '%bridge%')
                            THEN ex - 'prescribed_sets' - 'prescribed_reps' ||
                                 '{"duration": "30 sec", "notes": "Maintain form throughout"}'::jsonb
                            -- Dynamic pilates: keep sets but adjust reps
                            WHEN (ex->>'prescribed_sets')::int = 3
                                 AND (ex->>'prescribed_reps' = '10' OR ex->>'prescribed_reps' = '10 reps')
                            THEN ex || '{"notes": "Control the movement"}'::jsonb
                            ELSE ex
                        END
                    )
                    FROM jsonb_array_elements(block_elem->'exercises') AS ex
                )
            )
            ELSE block_elem
        END
    )
    FROM jsonb_array_elements(exercises) AS block_elem
)
WHERE category = 'pilates'
  AND exercises::text LIKE '%"prescribed_sets": 3%'
  AND exercises::text LIKE '%"prescribed_reps": "10"%';

-- Verify the update
DO $$
DECLARE
    yoga_count INTEGER;
    pilates_count INTEGER;
BEGIN
    -- Count templates that still have the bad pattern
    SELECT COUNT(*) INTO yoga_count
    FROM system_workout_templates
    WHERE category IN ('mobility', 'yoga', 'flexibility', 'recovery')
      AND exercises::text LIKE '%"prescribed_sets": 3%'
      AND exercises::text LIKE '%"prescribed_reps": "10"%';

    SELECT COUNT(*) INTO pilates_count
    FROM system_workout_templates
    WHERE category = 'pilates'
      AND exercises::text LIKE '%"prescribed_sets": 3%'
      AND exercises::text LIKE '%"prescribed_reps": "10"%';

    IF yoga_count = 0 AND pilates_count = 0 THEN
        RAISE NOTICE 'Successfully updated yoga/pilates templates to use breath-based durations';
    ELSE
        RAISE NOTICE 'Remaining templates with 3x10 pattern: yoga=%, pilates=%', yoga_count, pilates_count;
    END IF;
END $$;
