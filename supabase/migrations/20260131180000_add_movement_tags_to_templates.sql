-- BUILD 352: Add movement-based tags to workout templates for Quick Pick filtering
--
-- Problem: Quick Pick filter uses 30% exercise name matching threshold, which fails for
-- mixed/full-body workouts. Templates also lack movement-type tags (push, pull, legs, etc.)
--
-- Solution: Add movement-based tags to templates based on their content so they match
-- on the tag filter (step 2) instead of relying on exercise name matching (step 6).
--
-- Categories of tags to add:
-- - push: workouts with pressing movements (bench, overhead, push-ups, dips)
-- - pull: workouts with pulling movements (rows, pull-ups, deadlifts, curls)
-- - legs: workouts with lower body movements (squats, lunges, leg press)
-- - upper_body: workouts focused on upper body
-- - lower_body: workouts focused on lower body
-- - full_body: workouts hitting all major muscle groups

BEGIN;

-- Helper function to add tags without duplicates
CREATE OR REPLACE FUNCTION add_tags_if_not_exists(existing_tags text[], new_tags text[])
RETURNS text[] AS $$
DECLARE
    result text[];
    tag text;
BEGIN
    result := COALESCE(existing_tags, '{}');
    FOREACH tag IN ARRAY new_tags LOOP
        IF NOT result @> ARRAY[tag] THEN
            result := result || ARRAY[tag];
        END IF;
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =======================
-- STRONGLIFTS 5x5 TEMPLATES
-- Full-body programs with squat + push + pull
-- =======================

-- StrongLifts Workout A: Squat, Bench, Row
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'chest', 'back', 'quads'])
WHERE name LIKE 'StrongLifts 5x5 - Workout A%'
   OR id = '5f5a0001-0001-4000-8000-000000000001';

-- StrongLifts Workout B: Squat, OHP, Deadlift
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'shoulders', 'hamstrings', 'quads'])
WHERE name LIKE 'StrongLifts 5x5 - Workout B%'
   OR id = '5f5a0001-0002-4000-8000-000000000002';

-- =======================
-- MADCOW 5x5 TEMPLATES
-- =======================

-- Madcow Monday: Squat, Bench, Row
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'chest', 'back', 'quads'])
WHERE name LIKE 'Madcow 5x5 - Monday%'
   OR id = '5f5a0002-0001-4000-8000-000000000003';

-- Madcow Wednesday: Squat, Incline Bench, Deadlift
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'chest', 'hamstrings', 'quads'])
WHERE name LIKE 'Madcow 5x5 - Wednesday%'
   OR id = '5f5a0002-0002-4000-8000-000000000004';

-- Madcow Friday: Squat, Bench, Row
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'chest', 'back', 'quads'])
WHERE name LIKE 'Madcow 5x5 - Friday%'
   OR id = '5f5a0002-0003-4000-8000-000000000005';

-- =======================
-- STARTING STRENGTH TEMPLATES
-- =======================

-- Starting Strength Day A: Squat, Bench, Deadlift
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'chest', 'hamstrings', 'quads'])
WHERE name LIKE 'Starting Strength - Day A%'
   OR id = '5f5a0005-0001-4000-8000-000000000009';

-- Starting Strength Day B: Squat, OHP, Power Clean
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'shoulders', 'quads'])
WHERE name LIKE 'Starting Strength - Day B%'
   OR id = '5f5a0005-0002-4000-8000-000000000010';

-- =======================
-- ICE CREAM FITNESS TEMPLATES
-- =======================

-- ICF Day A: Squat, Bench, Row + accessories
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'chest', 'back', 'quads', 'triceps', 'biceps', 'core'])
WHERE name LIKE 'Ice Cream Fitness 5x5 - Day A%'
   OR id = '5f5a0004-0001-4000-8000-000000000007';

-- ICF Day B: Squat, OHP, Deadlift + accessories
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'shoulders', 'hamstrings', 'quads', 'triceps', 'biceps', 'core'])
WHERE name LIKE 'Ice Cream Fitness 5x5 - Day B%'
   OR id = '5f5a0004-0002-4000-8000-000000000008';

-- =======================
-- TEXAS METHOD TEMPLATES
-- =======================

-- Texas Method Volume Day
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'chest', 'hamstrings', 'quads'])
WHERE name LIKE 'Texas Method - Volume%'
   OR id = '5f5a000a-0001-4000-8000-000000000020';

-- Texas Method Recovery Day
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'shoulders', 'back', 'quads'])
WHERE name LIKE 'Texas Method - Recovery%'
   OR id = '5f5a000a-0002-4000-8000-000000000021';

-- Texas Method Intensity Day
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'chest', 'quads'])
WHERE name LIKE 'Texas Method - Intensity%'
   OR id = '5f5a000a-0003-4000-8000-000000000022';

-- =======================
-- BILL STARR ORIGINAL
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body', 'chest', 'quads', 'triceps', 'biceps'])
WHERE name LIKE 'Bill Starr 5x5%'
   OR id = '5f5a0003-0001-4000-8000-000000000006';

-- =======================
-- 5x5 FULL BODY TEMPLATES
-- =======================

-- 5x5 Full Body A, B, C
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'legs', 'upper_body', 'lower_body'])
WHERE name LIKE '5x5 Full Body%'
   OR id IN (
       '5f5a0008-0001-4000-8000-000000000016',
       '5f5a0008-0002-4000-8000-000000000017',
       '5f5a0008-0003-4000-8000-000000000018'
   );

-- =======================
-- 5x5 SPLIT TEMPLATES (Push/Pull/Legs/Upper/Lower)
-- These should already have good tags but ensure consistency
-- =======================

-- 5x5 Upper Body
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'upper_body', 'chest', 'back', 'shoulders', 'triceps'])
WHERE name LIKE '5x5 Upper Body%'
   OR id = '5f5a0007-0001-4000-8000-000000000014';

-- 5x5 Lower Body
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['legs', 'lower_body', 'quads', 'hamstrings', 'glutes'])
WHERE name LIKE '5x5 Lower Body%'
   OR id = '5f5a0007-0002-4000-8000-000000000015';

-- =======================
-- POWERLIFTING TEMPLATES
-- =======================

-- Powerlifting Squat Focus
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['legs', 'lower_body', 'quads', 'glutes', 'core'])
WHERE name LIKE 'Powerlifting 5x5 - Squat%'
   OR id = '5f5a000b-0001-4000-8000-000000000023';

-- Powerlifting Bench Focus
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'upper_body', 'chest', 'triceps', 'shoulders'])
WHERE name LIKE 'Powerlifting 5x5 - Bench%'
   OR id = '5f5a000b-0002-4000-8000-000000000024';

-- Powerlifting Deadlift Focus
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['pull', 'legs', 'lower_body', 'hamstrings', 'back', 'glutes'])
WHERE name LIKE 'Powerlifting 5x5 - Deadlift%'
   OR id = '5f5a000b-0003-4000-8000-000000000025';

-- =======================
-- CROSSFIT/BENCHMARK TEMPLATES
-- Add movement tags based on typical WOD content
-- =======================

-- CrossFit benchmarks often include varied movements
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['cardio', 'conditioning', 'functional'])
WHERE category = 'crossfit' OR name LIKE '%CrossFit%' OR name LIKE '%WOD%';

-- =======================
-- HIIT/CARDIO TEMPLATES
-- Ensure cardio tag is present
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['cardio', 'conditioning', 'hiit', 'endurance'])
WHERE category IN ('cardio', 'hiit', 'conditioning')
   OR name ILIKE '%hiit%'
   OR name ILIKE '%cardio%'
   OR name ILIKE '%conditioning%';

-- =======================
-- BOOTCAMP/FUNCTIONAL TEMPLATES
-- Add core and functional tags
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['functional', 'core', 'cardio', 'conditioning'])
WHERE category = 'bootcamp'
   OR name ILIKE '%bootcamp%'
   OR name ILIKE '%circuit%';

-- =======================
-- BODYBUILDING TEMPLATES
-- Split-specific tags
-- =======================

-- Chest/Push focused bodybuilding
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'upper_body', 'chest', 'triceps'])
WHERE category = 'bodybuilding'
  AND (name ILIKE '%chest%' OR name ILIKE '%push%');

-- Back/Pull focused bodybuilding
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['pull', 'upper_body', 'back', 'biceps'])
WHERE category = 'bodybuilding'
  AND (name ILIKE '%back%' OR name ILIKE '%pull%');

-- Leg focused bodybuilding
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['legs', 'lower_body', 'quads', 'hamstrings', 'glutes'])
WHERE category = 'bodybuilding'
  AND (name ILIKE '%leg%' OR name ILIKE '%lower%');

-- Arm focused bodybuilding
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['upper_body', 'biceps', 'triceps'])
WHERE category = 'bodybuilding'
  AND (name ILIKE '%arm%' OR name ILIKE '%bicep%' OR name ILIKE '%tricep%');

-- =======================
-- MOBILITY/YOGA/PILATES TEMPLATES
-- These should match mobility filter
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['mobility', 'flexibility', 'recovery', 'stretching'])
WHERE category IN ('mobility', 'yoga', 'pilates', 'flexibility', 'recovery')
   OR name ILIKE '%mobility%'
   OR name ILIKE '%stretch%'
   OR name ILIKE '%yoga%'
   OR name ILIKE '%pilates%';

-- =======================
-- CORE-FOCUSED TEMPLATES
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['core', 'abs', 'stability', 'functional'])
WHERE category = 'core'
   OR name ILIKE '%core%'
   OR name ILIKE '%abs%'
   OR name ILIKE '%ab %';

-- =======================
-- KETTLEBELL TEMPLATES (StrongFirst, etc.)
-- Often full-body functional movements
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['functional', 'conditioning'])
WHERE name ILIKE '%kettlebell%'
   OR name ILIKE '%kb %'
   OR name ILIKE '%strongfirst%';

-- Swings are primarily hinge/pull pattern
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['pull', 'hamstrings', 'glutes', 'cardio'])
WHERE name ILIKE '%swing%'
   OR exercises::text ILIKE '%swing%';

-- Get-ups are full body
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'pull', 'core', 'shoulders'])
WHERE name ILIKE '%get%up%'
   OR name ILIKE '%getup%';

-- =======================
-- ATG/KNEES OVER TOES TEMPLATES
-- Primarily leg/mobility focused
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['legs', 'lower_body', 'mobility', 'flexibility', 'quads', 'knees'])
WHERE name ILIKE '%atg%'
   OR name ILIKE '%knees over toes%'
   OR name ILIKE '%tibialis%'
   OR name ILIKE '%nordic%';

-- =======================
-- REHAB/SENIOR TEMPLATES
-- Add appropriate tags
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['mobility', 'recovery', 'flexibility', 'low-impact'])
WHERE category IN ('rehab', 'senior', 'rehabilitation')
   OR name ILIKE '%rehab%'
   OR name ILIKE '%senior%'
   OR name ILIKE '%gentle%';

-- =======================
-- TRX/SUSPENSION TEMPLATES
-- Often full-body functional
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['functional', 'core', 'stability'])
WHERE name ILIKE '%trx%'
   OR name ILIKE '%suspension%';

-- =======================
-- CALISTHENICS TEMPLATES
-- Bodyweight movements
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['bodyweight', 'functional'])
WHERE category = 'calisthenics'
   OR name ILIKE '%calisthenics%'
   OR name ILIKE '%bodyweight%';

-- Push calisthenics (push-ups, dips, handstands)
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['push', 'upper_body', 'chest', 'triceps', 'shoulders'])
WHERE category = 'calisthenics'
  AND (exercises::text ILIKE '%push%up%'
       OR exercises::text ILIKE '%dip%'
       OR exercises::text ILIKE '%handstand%');

-- Pull calisthenics (pull-ups, rows)
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['pull', 'upper_body', 'back', 'biceps'])
WHERE category = 'calisthenics'
  AND (exercises::text ILIKE '%pull%up%'
       OR exercises::text ILIKE '%chin%up%'
       OR exercises::text ILIKE '%row%');

-- Leg calisthenics (squats, lunges, pistols)
UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['legs', 'lower_body', 'quads'])
WHERE category = 'calisthenics'
  AND (exercises::text ILIKE '%squat%'
       OR exercises::text ILIKE '%lunge%'
       OR exercises::text ILIKE '%pistol%');

-- =======================
-- DELOAD/RECOVERY TEMPLATES
-- =======================

UPDATE system_workout_templates
SET tags = add_tags_if_not_exists(tags, ARRAY['recovery', 'deload', 'light'])
WHERE name ILIKE '%deload%'
   OR name ILIKE '%recovery%'
   OR name ILIKE '%light day%';

-- Cleanup: remove helper function
DROP FUNCTION IF EXISTS add_tags_if_not_exists(text[], text[]);

COMMIT;

-- Verify: Count templates that now have push/pull/legs tags
SELECT
    'Templates with push tag' as metric,
    COUNT(*) as count
FROM system_workout_templates
WHERE tags @> ARRAY['push']
UNION ALL
SELECT
    'Templates with pull tag',
    COUNT(*)
FROM system_workout_templates
WHERE tags @> ARRAY['pull']
UNION ALL
SELECT
    'Templates with legs tag',
    COUNT(*)
FROM system_workout_templates
WHERE tags @> ARRAY['legs']
UNION ALL
SELECT
    'Templates with cardio tag',
    COUNT(*)
FROM system_workout_templates
WHERE tags @> ARRAY['cardio']
UNION ALL
SELECT
    'Templates with mobility tag',
    COUNT(*)
FROM system_workout_templates
WHERE tags @> ARRAY['mobility']
UNION ALL
SELECT
    'Templates with core tag',
    COUNT(*)
FROM system_workout_templates
WHERE tags @> ARRAY['core'];
