-- BUILD 326: Fix Workout Library for Demo Mode
-- Purpose: Allow demo users (unauthenticated) to access system workout templates
-- Issue: RLS policy only allowed 'authenticated' role, but demo mode bypasses auth
--
-- This migration:
-- 1. Adds RLS policy for 'anon' role to read system_workout_templates
-- 2. Seeds 10 workout templates with proper structure

-- ============================================================================
-- 1. ADD ANON RLS POLICY
-- ============================================================================

-- Allow anonymous users to read system templates (for demo mode)
DROP POLICY IF EXISTS "system_workout_templates_anon_read" ON system_workout_templates;
CREATE POLICY "system_workout_templates_anon_read"
ON system_workout_templates
FOR SELECT
TO anon
USING (true);

-- Grant SELECT to anon role
GRANT SELECT ON system_workout_templates TO anon;

-- ============================================================================
-- 2. SEED WORKOUT TEMPLATES
-- ============================================================================

-- Clear existing templates to avoid duplicates
DELETE FROM system_workout_templates WHERE source_file = 'build_326_seed.sql';

-- Insert 10 foundational templates
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file
) VALUES
-- 1. Upper Body Strength
(
    'a1b2c3d4-0001-4000-8000-000000000001',
    'Upper Body Strength',
    'Complete upper body workout targeting chest, back, shoulders, and arms.',
    'upper',
    'intermediate',
    45,
    '[
        {"exercise_name": "Bench Press", "block_name": "Push", "sequence": 1, "target_sets": 4, "target_reps": "8-10", "notes": "Control descent, explosive press"},
        {"exercise_name": "Overhead Press", "block_name": "Push", "sequence": 2, "target_sets": 3, "target_reps": "10", "notes": "Keep core tight"},
        {"exercise_name": "Pull-Ups", "block_name": "Pull", "sequence": 3, "target_sets": 4, "target_reps": "8-12", "notes": "Full extension at bottom"},
        {"exercise_name": "Seated Row", "block_name": "Pull", "sequence": 4, "target_sets": 3, "target_reps": "12", "notes": "Squeeze shoulder blades"},
        {"exercise_name": "Face Pulls", "block_name": "Accessory", "sequence": 5, "target_sets": 3, "target_reps": "15", "notes": "External rotation at end"},
        {"exercise_name": "Bicep Curls", "block_name": "Accessory", "sequence": 6, "target_sets": 3, "target_reps": "12", "notes": "Controlled tempo"},
        {"exercise_name": "Tricep Pushdowns", "block_name": "Accessory", "sequence": 7, "target_sets": 3, "target_reps": "12", "notes": "Keep elbows pinned"}
    ]'::jsonb,
    ARRAY['upper_body', 'strength', 'push', 'pull', 'intermediate'],
    'build_326_seed.sql'
),
-- 2. Lower Body Focus
(
    'a1b2c3d4-0002-4000-8000-000000000002',
    'Lower Body Focus',
    'Comprehensive leg workout targeting quads, hamstrings, and glutes.',
    'lower',
    'intermediate',
    50,
    '[
        {"exercise_name": "Barbell Squat", "block_name": "Main", "sequence": 1, "target_sets": 4, "target_reps": "6-8", "notes": "Full depth, drive through heels"},
        {"exercise_name": "Romanian Deadlift", "block_name": "Main", "sequence": 2, "target_sets": 4, "target_reps": "8-10", "notes": "Keep back flat, feel hamstrings"},
        {"exercise_name": "Leg Press", "block_name": "Main", "sequence": 3, "target_sets": 3, "target_reps": "12", "notes": "Controlled descent"},
        {"exercise_name": "Walking Lunges", "block_name": "Accessory", "sequence": 4, "target_sets": 3, "target_reps": "10 each leg", "notes": "Keep torso upright"},
        {"exercise_name": "Leg Curls", "block_name": "Accessory", "sequence": 5, "target_sets": 3, "target_reps": "12", "notes": "Squeeze at top"},
        {"exercise_name": "Calf Raises", "block_name": "Accessory", "sequence": 6, "target_sets": 4, "target_reps": "15", "notes": "Full range of motion"}
    ]'::jsonb,
    ARRAY['lower_body', 'strength', 'legs', 'intermediate'],
    'build_326_seed.sql'
),
-- 3. Full Body Workout
(
    'a1b2c3d4-0003-4000-8000-000000000003',
    'Full Body Workout',
    'Balanced full body session hitting all major muscle groups.',
    'full_body',
    'beginner',
    55,
    '[
        {"exercise_name": "Goblet Squat", "block_name": "Lower", "sequence": 1, "target_sets": 3, "target_reps": "12", "notes": "Keep chest up"},
        {"exercise_name": "Push-Ups", "block_name": "Upper", "sequence": 2, "target_sets": 3, "target_reps": "10-15", "notes": "Full range of motion"},
        {"exercise_name": "Dumbbell Row", "block_name": "Upper", "sequence": 3, "target_sets": 3, "target_reps": "10 each", "notes": "Drive elbow back"},
        {"exercise_name": "Romanian Deadlift", "block_name": "Lower", "sequence": 4, "target_sets": 3, "target_reps": "10", "notes": "Hinge at hips"},
        {"exercise_name": "Shoulder Press", "block_name": "Upper", "sequence": 5, "target_sets": 3, "target_reps": "10", "notes": "Press overhead"},
        {"exercise_name": "Plank", "block_name": "Core", "sequence": 6, "target_sets": 3, "target_reps": "30 seconds", "notes": "Keep neutral spine"}
    ]'::jsonb,
    ARRAY['full_body', 'strength', 'beginner'],
    'build_326_seed.sql'
),
-- 4. Push Day
(
    'a1b2c3d4-0004-4000-8000-000000000004',
    'Push Day',
    'Focus on pushing movements for chest, shoulders, and triceps.',
    'push',
    'intermediate',
    40,
    '[
        {"exercise_name": "Bench Press", "block_name": "Main", "sequence": 1, "target_sets": 4, "target_reps": "6-8", "notes": "Control the weight"},
        {"exercise_name": "Incline Dumbbell Press", "block_name": "Main", "sequence": 2, "target_sets": 3, "target_reps": "10", "notes": "30-degree incline"},
        {"exercise_name": "Overhead Press", "block_name": "Main", "sequence": 3, "target_sets": 3, "target_reps": "8-10", "notes": "Brace core"},
        {"exercise_name": "Lateral Raises", "block_name": "Accessory", "sequence": 4, "target_sets": 3, "target_reps": "15", "notes": "Light weight, control"},
        {"exercise_name": "Tricep Dips", "block_name": "Accessory", "sequence": 5, "target_sets": 3, "target_reps": "10-12", "notes": "Keep elbows close"},
        {"exercise_name": "Cable Flyes", "block_name": "Accessory", "sequence": 6, "target_sets": 3, "target_reps": "12", "notes": "Squeeze at center"}
    ]'::jsonb,
    ARRAY['push', 'chest', 'shoulders', 'triceps', 'intermediate'],
    'build_326_seed.sql'
),
-- 5. Pull Day
(
    'a1b2c3d4-0005-4000-8000-000000000005',
    'Pull Day',
    'Focus on pulling movements for back and biceps.',
    'pull',
    'intermediate',
    40,
    '[
        {"exercise_name": "Deadlift", "block_name": "Main", "sequence": 1, "target_sets": 4, "target_reps": "5", "notes": "Keep back flat"},
        {"exercise_name": "Pull-Ups", "block_name": "Main", "sequence": 2, "target_sets": 4, "target_reps": "8-10", "notes": "Full extension"},
        {"exercise_name": "Barbell Row", "block_name": "Main", "sequence": 3, "target_sets": 3, "target_reps": "8-10", "notes": "Pull to lower chest"},
        {"exercise_name": "Face Pulls", "block_name": "Accessory", "sequence": 4, "target_sets": 3, "target_reps": "15", "notes": "External rotation"},
        {"exercise_name": "Hammer Curls", "block_name": "Accessory", "sequence": 5, "target_sets": 3, "target_reps": "12", "notes": "Neutral grip"},
        {"exercise_name": "Reverse Flyes", "block_name": "Accessory", "sequence": 6, "target_sets": 3, "target_reps": "12", "notes": "Squeeze shoulder blades"}
    ]'::jsonb,
    ARRAY['pull', 'back', 'biceps', 'intermediate'],
    'build_326_seed.sql'
),
-- 6. Mobility & Recovery
(
    'a1b2c3d4-0006-4000-8000-000000000006',
    'Mobility & Recovery',
    'Active recovery session focusing on mobility and flexibility.',
    'mobility',
    'beginner',
    30,
    '[
        {"exercise_name": "Foam Roll Thoracic", "block_name": "Warmup", "sequence": 1, "target_sets": 1, "target_reps": "2 minutes", "notes": "Roll slowly"},
        {"exercise_name": "Cat-Cow Stretch", "block_name": "Mobility", "sequence": 2, "target_sets": 2, "target_reps": "10 each", "notes": "Breathe deeply"},
        {"exercise_name": "World''s Greatest Stretch", "block_name": "Mobility", "sequence": 3, "target_sets": 2, "target_reps": "5 each side", "notes": "Hold each position"},
        {"exercise_name": "Hip 90-90 Stretch", "block_name": "Mobility", "sequence": 4, "target_sets": 2, "target_reps": "60 seconds each", "notes": "Keep back tall"},
        {"exercise_name": "Shoulder CARs", "block_name": "Mobility", "sequence": 5, "target_sets": 2, "target_reps": "5 each direction", "notes": "Full range circles"},
        {"exercise_name": "Deep Squat Hold", "block_name": "Mobility", "sequence": 6, "target_sets": 3, "target_reps": "30 seconds", "notes": "Heels down"}
    ]'::jsonb,
    ARRAY['mobility', 'recovery', 'flexibility', 'beginner'],
    'build_326_seed.sql'
),
-- 7. Core Strength
(
    'a1b2c3d4-0007-4000-8000-000000000007',
    'Core Strength',
    'Dedicated core workout for stability and strength.',
    'functional',
    'beginner',
    25,
    '[
        {"exercise_name": "Dead Bug", "block_name": "Anti-Extension", "sequence": 1, "target_sets": 3, "target_reps": "10 each side", "notes": "Keep back flat"},
        {"exercise_name": "Plank", "block_name": "Anti-Extension", "sequence": 2, "target_sets": 3, "target_reps": "30-45 seconds", "notes": "Squeeze glutes"},
        {"exercise_name": "Side Plank", "block_name": "Anti-Lateral Flexion", "sequence": 3, "target_sets": 2, "target_reps": "30 seconds each", "notes": "Stack shoulders"},
        {"exercise_name": "Pallof Press", "block_name": "Anti-Rotation", "sequence": 4, "target_sets": 3, "target_reps": "10 each side", "notes": "Resist rotation"},
        {"exercise_name": "Bird Dog", "block_name": "Stability", "sequence": 5, "target_sets": 3, "target_reps": "8 each side", "notes": "Opposite arm and leg"},
        {"exercise_name": "Hanging Leg Raise", "block_name": "Flexion", "sequence": 6, "target_sets": 3, "target_reps": "10", "notes": "Control the swing"}
    ]'::jsonb,
    ARRAY['core', 'stability', 'functional', 'beginner'],
    'build_326_seed.sql'
),
-- 8. HIIT Cardio
(
    'a1b2c3d4-0008-4000-8000-000000000008',
    'HIIT Cardio',
    'High intensity interval training for conditioning.',
    'cardio',
    'advanced',
    25,
    '[
        {"exercise_name": "Jump Rope", "block_name": "Warmup", "sequence": 1, "target_sets": 1, "target_reps": "3 minutes", "notes": "Easy pace"},
        {"exercise_name": "Burpees", "block_name": "HIIT", "sequence": 2, "target_sets": 4, "target_reps": "30 seconds on/30 off", "notes": "Max effort"},
        {"exercise_name": "Mountain Climbers", "block_name": "HIIT", "sequence": 3, "target_sets": 4, "target_reps": "30 seconds on/30 off", "notes": "Keep hips low"},
        {"exercise_name": "Box Jumps", "block_name": "HIIT", "sequence": 4, "target_sets": 4, "target_reps": "30 seconds on/30 off", "notes": "Soft landing"},
        {"exercise_name": "Battle Ropes", "block_name": "HIIT", "sequence": 5, "target_sets": 4, "target_reps": "30 seconds on/30 off", "notes": "Alternate waves"},
        {"exercise_name": "Assault Bike", "block_name": "Finisher", "sequence": 6, "target_sets": 1, "target_reps": "3 minutes", "notes": "All out effort"}
    ]'::jsonb,
    ARRAY['cardio', 'hiit', 'conditioning', 'advanced'],
    'build_326_seed.sql'
),
-- 9. Beginner Strength
(
    'a1b2c3d4-0009-4000-8000-000000000009',
    'Beginner Strength',
    'Introduction to strength training with fundamental movements.',
    'strength',
    'beginner',
    40,
    '[
        {"exercise_name": "Goblet Squat", "block_name": "Lower", "sequence": 1, "target_sets": 3, "target_reps": "10", "notes": "Depth over weight"},
        {"exercise_name": "Push-Ups", "block_name": "Upper", "sequence": 2, "target_sets": 3, "target_reps": "8-12", "notes": "Modify if needed"},
        {"exercise_name": "Dumbbell Romanian Deadlift", "block_name": "Lower", "sequence": 3, "target_sets": 3, "target_reps": "10", "notes": "Feel the stretch"},
        {"exercise_name": "Dumbbell Row", "block_name": "Upper", "sequence": 4, "target_sets": 3, "target_reps": "10 each", "notes": "Pull to hip"},
        {"exercise_name": "Glute Bridge", "block_name": "Lower", "sequence": 5, "target_sets": 3, "target_reps": "12", "notes": "Squeeze at top"},
        {"exercise_name": "Plank", "block_name": "Core", "sequence": 6, "target_sets": 3, "target_reps": "20-30 seconds", "notes": "Build duration"}
    ]'::jsonb,
    ARRAY['strength', 'beginner', 'fundamentals'],
    'build_326_seed.sql'
),
-- 10. Athletic Performance
(
    'a1b2c3d4-0010-4000-8000-000000000010',
    'Athletic Performance',
    'Power and explosiveness training for athletes.',
    'functional',
    'advanced',
    50,
    '[
        {"exercise_name": "Box Jumps", "block_name": "Power", "sequence": 1, "target_sets": 4, "target_reps": "5", "notes": "Max height, step down"},
        {"exercise_name": "Medicine Ball Slams", "block_name": "Power", "sequence": 2, "target_sets": 3, "target_reps": "8", "notes": "Explosive movement"},
        {"exercise_name": "Hang Clean", "block_name": "Olympic", "sequence": 3, "target_sets": 4, "target_reps": "5", "notes": "Triple extension"},
        {"exercise_name": "Front Squat", "block_name": "Strength", "sequence": 4, "target_sets": 4, "target_reps": "6", "notes": "Elbows high"},
        {"exercise_name": "Single Leg RDL", "block_name": "Balance", "sequence": 5, "target_sets": 3, "target_reps": "8 each", "notes": "Hip hinge pattern"},
        {"exercise_name": "Sled Push", "block_name": "Conditioning", "sequence": 6, "target_sets": 4, "target_reps": "40 yards", "notes": "Drive through legs"}
    ]'::jsonb,
    ARRAY['athletic', 'power', 'performance', 'advanced'],
    'build_326_seed.sql'
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    difficulty = EXCLUDED.difficulty,
    duration_minutes = EXCLUDED.duration_minutes,
    exercises = EXCLUDED.exercises,
    tags = EXCLUDED.tags,
    source_file = EXCLUDED.source_file;

-- ============================================================================
-- 3. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    template_count INT;
    anon_policy_exists BOOLEAN;
BEGIN
    -- Count templates
    SELECT COUNT(*) INTO template_count
    FROM system_workout_templates;

    -- Check anon policy exists
    SELECT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'system_workout_templates'
        AND policyname = 'system_workout_templates_anon_read'
    ) INTO anon_policy_exists;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'BUILD 326: Workout Library Fixed for Demo';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Templates in database: %', template_count;
    RAISE NOTICE 'Anon RLS policy exists: %', anon_policy_exists;
    RAISE NOTICE '';
    RAISE NOTICE 'Templates seeded:';
    RAISE NOTICE '  1. Upper Body Strength (intermediate)';
    RAISE NOTICE '  2. Lower Body Focus (intermediate)';
    RAISE NOTICE '  3. Full Body Workout (beginner)';
    RAISE NOTICE '  4. Push Day (intermediate)';
    RAISE NOTICE '  5. Pull Day (intermediate)';
    RAISE NOTICE '  6. Mobility & Recovery (beginner)';
    RAISE NOTICE '  7. Core Strength (beginner)';
    RAISE NOTICE '  8. HIIT Cardio (advanced)';
    RAISE NOTICE '  9. Beginner Strength (beginner)';
    RAISE NOTICE ' 10. Athletic Performance (advanced)';
    RAISE NOTICE '============================================';

    IF template_count < 10 THEN
        RAISE WARNING 'Expected 10+ templates, got %. Some inserts may have failed.', template_count;
    END IF;

    IF NOT anon_policy_exists THEN
        RAISE WARNING 'Anon RLS policy not created. Demo mode may not work.';
    END IF;
END $$;
