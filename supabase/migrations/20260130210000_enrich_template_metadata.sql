-- BUILD 338: Enrich workout template metadata
-- Problem: Many templates missing descriptions, inconsistent difficulty levels, incomplete tags
-- Solution: Add descriptions, normalize difficulty, complete tag coverage

BEGIN;

-- ============================================================================
-- Step 1: Add descriptions to templates missing them
-- ============================================================================

-- Strength templates
UPDATE system_workout_templates
SET description = CASE
    WHEN name ILIKE '%5x5%' THEN 'Classic 5x5 strength program focusing on compound lifts with progressive overload'
    WHEN name ILIKE '%push%pull%' OR name ILIKE '%ppl%' THEN 'Push/Pull/Legs split targeting specific movement patterns for balanced development'
    WHEN name ILIKE '%upper%lower%' THEN 'Upper/Lower split alternating between upper and lower body training days'
    WHEN name ILIKE '%full body%' THEN 'Full body workout hitting all major muscle groups in one session'
    WHEN name ILIKE '%hypertrophy%' THEN 'Hypertrophy-focused training with moderate weight and higher rep ranges'
    WHEN name ILIKE '%power%' THEN 'Power development workout emphasizing explosive movements and strength'
    WHEN name ILIKE '%circuit%' THEN 'Circuit-style training with minimal rest for conditioning and strength endurance'
    ELSE description
END
WHERE category = 'strength'
  AND (description IS NULL OR description = '');

-- Mobility/Yoga templates
UPDATE system_workout_templates
SET description = CASE
    WHEN name ILIKE '%morning%' THEN 'Gentle morning routine to wake up the body and improve mobility'
    WHEN name ILIKE '%evening%' OR name ILIKE '%night%' THEN 'Relaxing evening routine to unwind and prepare for restful sleep'
    WHEN name ILIKE '%hip%' THEN 'Hip-focused mobility work to improve range of motion and reduce tightness'
    WHEN name ILIKE '%shoulder%' THEN 'Shoulder mobility and stability exercises for overhead movement quality'
    WHEN name ILIKE '%spine%' OR name ILIKE '%back%' THEN 'Spinal mobility routine for a healthy, flexible back'
    WHEN name ILIKE '%flow%' THEN 'Flowing movement sequence linking poses with breath'
    WHEN name ILIKE '%stretch%' THEN 'Stretching routine to improve flexibility and reduce muscle tension'
    WHEN name ILIKE '%recovery%' THEN 'Active recovery session to promote healing and reduce soreness'
    ELSE description
END
WHERE category = 'mobility'
  AND (description IS NULL OR description = '');

-- Cardio templates
UPDATE system_workout_templates
SET description = CASE
    WHEN name ILIKE '%hiit%' THEN 'High-intensity interval training for maximum calorie burn and conditioning'
    WHEN name ILIKE '%steady%' OR name ILIKE '%zone 2%' THEN 'Steady-state cardio in the aerobic zone for endurance building'
    WHEN name ILIKE '%sprint%' THEN 'Sprint intervals for explosive power and anaerobic capacity'
    WHEN name ILIKE '%tabata%' THEN 'Tabata protocol: 20 seconds work, 10 seconds rest for 4 minutes'
    WHEN name ILIKE '%emom%' THEN 'Every Minute On the Minute workout for consistent pacing'
    WHEN name ILIKE '%amrap%' THEN 'As Many Rounds As Possible in the given time frame'
    ELSE description
END
WHERE category = 'cardio'
  AND (description IS NULL OR description = '');

-- Hybrid/CrossFit templates
UPDATE system_workout_templates
SET description = CASE
    WHEN name ILIKE '%wod%' THEN 'Workout of the Day combining strength and conditioning elements'
    WHEN name ILIKE '%metcon%' THEN 'Metabolic conditioning workout for improved work capacity'
    WHEN name ILIKE '%benchmark%' THEN 'Benchmark workout to track fitness progress over time'
    WHEN name ILIKE '%hero%' THEN 'Hero workout honoring military and first responders'
    ELSE description
END
WHERE category IN ('hybrid', 'crossfit', 'functional')
  AND (description IS NULL OR description = '');

-- ============================================================================
-- Step 2: Normalize difficulty levels
-- ============================================================================

-- Set default difficulty to 'intermediate' where missing
UPDATE system_workout_templates
SET difficulty = 'intermediate'
WHERE difficulty IS NULL OR difficulty = '';

-- Adjust difficulty based on workout characteristics
UPDATE system_workout_templates
SET difficulty = 'beginner'
WHERE (
    name ILIKE '%beginner%'
    OR name ILIKE '%intro%'
    OR name ILIKE '%starter%'
    OR name ILIKE '%foundation%'
    OR name ILIKE '%basic%'
)
AND difficulty != 'beginner';

UPDATE system_workout_templates
SET difficulty = 'advanced'
WHERE (
    name ILIKE '%advanced%'
    OR name ILIKE '%elite%'
    OR name ILIKE '%pro%'
    OR name ILIKE '%intense%'
    OR name ILIKE '%extreme%'
)
AND difficulty != 'advanced';

-- ============================================================================
-- Step 3: Complete tag coverage based on category and content
-- ============================================================================

-- Add category-based tags
UPDATE system_workout_templates
SET tags = array_cat(
    COALESCE(tags, ARRAY[]::text[]),
    ARRAY['strength']
)
WHERE category = 'strength'
  AND NOT (COALESCE(tags, ARRAY[]::text[]) @> ARRAY['strength']);

UPDATE system_workout_templates
SET tags = array_cat(
    COALESCE(tags, ARRAY[]::text[]),
    ARRAY['mobility']
)
WHERE category = 'mobility'
  AND NOT (COALESCE(tags, ARRAY[]::text[]) @> ARRAY['mobility']);

UPDATE system_workout_templates
SET tags = array_cat(
    COALESCE(tags, ARRAY[]::text[]),
    ARRAY['cardio']
)
WHERE category = 'cardio'
  AND NOT (COALESCE(tags, ARRAY[]::text[]) @> ARRAY['cardio']);

-- Add content-based tags
UPDATE system_workout_templates
SET tags = array_cat(tags, ARRAY['compound'])
WHERE (
    exercises::text ILIKE '%squat%'
    OR exercises::text ILIKE '%deadlift%'
    OR exercises::text ILIKE '%bench press%'
    OR exercises::text ILIKE '%overhead press%'
)
AND NOT (COALESCE(tags, ARRAY[]::text[]) @> ARRAY['compound']);

UPDATE system_workout_templates
SET tags = array_cat(tags, ARRAY['bodyweight'])
WHERE (
    exercises::text ILIKE '%push-up%'
    OR exercises::text ILIKE '%pull-up%'
    OR exercises::text ILIKE '%burpee%'
    OR exercises::text ILIKE '%plank%'
)
AND category != 'mobility'
AND NOT (COALESCE(tags, ARRAY[]::text[]) @> ARRAY['bodyweight']);

UPDATE system_workout_templates
SET tags = array_cat(tags, ARRAY['kettlebell'])
WHERE exercises::text ILIKE '%kettlebell%' OR exercises::text ILIKE '%kb %'
AND NOT (COALESCE(tags, ARRAY[]::text[]) @> ARRAY['kettlebell']);

UPDATE system_workout_templates
SET tags = array_cat(tags, ARRAY['dumbbell'])
WHERE exercises::text ILIKE '%dumbbell%' OR exercises::text ILIKE '%db %'
AND NOT (COALESCE(tags, ARRAY[]::text[]) @> ARRAY['dumbbell']);

UPDATE system_workout_templates
SET tags = array_cat(tags, ARRAY['barbell'])
WHERE exercises::text ILIKE '%barbell%' OR exercises::text ILIKE '%bb %'
AND NOT (COALESCE(tags, ARRAY[]::text[]) @> ARRAY['barbell']);

-- ============================================================================
-- Step 4: Remove duplicate tags and clean up
-- ============================================================================

UPDATE system_workout_templates
SET tags = (
    SELECT ARRAY(SELECT DISTINCT unnest(tags) ORDER BY 1)
)
WHERE tags IS NOT NULL AND array_length(tags, 1) > 0;

-- ============================================================================
-- Step 5: Verification
-- ============================================================================

DO $$
DECLARE
    templates_with_desc INTEGER;
    templates_with_diff INTEGER;
    templates_with_tags INTEGER;
    total_templates INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_templates FROM system_workout_templates;

    SELECT COUNT(*) INTO templates_with_desc
    FROM system_workout_templates
    WHERE description IS NOT NULL AND description != '';

    SELECT COUNT(*) INTO templates_with_diff
    FROM system_workout_templates
    WHERE difficulty IS NOT NULL AND difficulty != '';

    SELECT COUNT(*) INTO templates_with_tags
    FROM system_workout_templates
    WHERE tags IS NOT NULL AND array_length(tags, 1) > 0;

    RAISE NOTICE 'Metadata enrichment complete:';
    RAISE NOTICE '  Total templates: %', total_templates;
    RAISE NOTICE '  With descriptions: % (%.1f%%)', templates_with_desc, (templates_with_desc::float / total_templates * 100);
    RAISE NOTICE '  With difficulty: % (%.1f%%)', templates_with_diff, (templates_with_diff::float / total_templates * 100);
    RAISE NOTICE '  With tags: % (%.1f%%)', templates_with_tags, (templates_with_tags::float / total_templates * 100);
END $$;

COMMIT;
