-- Seed system_workout_templates with sample workouts
-- Build 241: Manual Workout Entry - Sample Templates

INSERT INTO system_workout_templates (name, description, category, difficulty, duration_minutes, exercises, tags)
VALUES
-- Full Body Workouts
(
    'Full Body Strength A',
    'Comprehensive full body workout targeting all major muscle groups with compound movements.',
    'strength',
    'intermediate',
    60,
    '[
        {"exercise_name": "Row Machine Warmup", "block_name": "Cardio", "sequence": 1, "target_sets": 1, "target_reps": "5 min", "notes": "Easy pace warmup"},
        {"exercise_name": "World''s Greatest Stretch", "block_name": "Dynamic Stretch", "sequence": 2, "target_sets": 2, "target_reps": "5 each"},
        {"exercise_name": "Leg Swings", "block_name": "Dynamic Stretch", "sequence": 3, "target_sets": 2, "target_reps": "10 each"},
        {"exercise_name": "Barbell Bench Press", "block_name": "Push", "sequence": 4, "target_sets": 4, "target_reps": "8-10", "notes": "RPE 8"},
        {"exercise_name": "Incline Dumbbell Press", "block_name": "Push", "sequence": 5, "target_sets": 3, "target_reps": "10-12"},
        {"exercise_name": "Barbell Rows", "block_name": "Pull", "sequence": 6, "target_sets": 4, "target_reps": "8-10", "notes": "RPE 8"},
        {"exercise_name": "Lat Pulldowns", "block_name": "Pull", "sequence": 7, "target_sets": 3, "target_reps": "10-12"},
        {"exercise_name": "Goblet Squats", "block_name": "Legs", "sequence": 8, "target_sets": 3, "target_reps": "12"},
        {"exercise_name": "Walking Lunges", "block_name": "Legs", "sequence": 9, "target_sets": 3, "target_reps": "10 each"},
        {"exercise_name": "Foam Roll", "block_name": "Recovery", "sequence": 10, "target_sets": 1, "target_reps": "5 min"},
        {"exercise_name": "Static Stretching", "block_name": "Recovery", "sequence": 11, "target_sets": 1, "target_reps": "5 min"}
    ]'::jsonb,
    ARRAY['full-body', 'strength', 'compound']
),

(
    'Full Body Strength B',
    'Alternative full body workout focusing on different movement patterns.',
    'strength',
    'intermediate',
    55,
    '[
        {"exercise_name": "Jump Rope", "block_name": "Cardio", "sequence": 1, "target_sets": 1, "target_reps": "5 min"},
        {"exercise_name": "Hip Circles", "block_name": "Dynamic Stretch", "sequence": 2, "target_sets": 2, "target_reps": "10 each"},
        {"exercise_name": "Inchworms", "block_name": "Dynamic Stretch", "sequence": 3, "target_sets": 2, "target_reps": "8"},
        {"exercise_name": "Overhead Press", "block_name": "Push", "sequence": 4, "target_sets": 4, "target_reps": "8-10", "notes": "RPE 8"},
        {"exercise_name": "Dumbbell Flyes", "block_name": "Push", "sequence": 5, "target_sets": 3, "target_reps": "12"},
        {"exercise_name": "Romanian Deadlift", "block_name": "Hinge", "sequence": 6, "target_sets": 4, "target_reps": "10-12"},
        {"exercise_name": "Good Mornings", "block_name": "Hinge", "sequence": 7, "target_sets": 3, "target_reps": "12"},
        {"exercise_name": "Bulgarian Split Squats", "block_name": "Legs", "sequence": 8, "target_sets": 3, "target_reps": "10 each"},
        {"exercise_name": "Step Ups", "block_name": "Legs", "sequence": 9, "target_sets": 3, "target_reps": "10 each"},
        {"exercise_name": "Pigeon Stretch", "block_name": "Recovery", "sequence": 10, "target_sets": 1, "target_reps": "2 min each"}
    ]'::jsonb,
    ARRAY['full-body', 'strength', 'alternative']
),

-- Upper Body Focus
(
    'Upper Body Push',
    'Chest, shoulders, and triceps focused workout.',
    'push',
    'intermediate',
    45,
    '[
        {"exercise_name": "Band Pull Aparts", "block_name": "Warmup", "sequence": 1, "target_sets": 2, "target_reps": "15"},
        {"exercise_name": "Arm Circles", "block_name": "Warmup", "sequence": 2, "target_sets": 2, "target_reps": "10 each"},
        {"exercise_name": "Flat Bench Press", "block_name": "Push", "sequence": 3, "target_sets": 4, "target_reps": "6-8", "notes": "RPE 8"},
        {"exercise_name": "Incline Dumbbell Press", "block_name": "Push", "sequence": 4, "target_sets": 3, "target_reps": "10-12"},
        {"exercise_name": "Cable Flyes", "block_name": "Push", "sequence": 5, "target_sets": 3, "target_reps": "12-15"},
        {"exercise_name": "Overhead Press", "block_name": "Push", "sequence": 6, "target_sets": 4, "target_reps": "8-10"},
        {"exercise_name": "Lateral Raises", "block_name": "Push", "sequence": 7, "target_sets": 3, "target_reps": "15"},
        {"exercise_name": "Tricep Pushdowns", "block_name": "Push", "sequence": 8, "target_sets": 3, "target_reps": "12-15"},
        {"exercise_name": "Overhead Tricep Extension", "block_name": "Push", "sequence": 9, "target_sets": 3, "target_reps": "12"},
        {"exercise_name": "Chest Stretch", "block_name": "Recovery", "sequence": 10, "target_sets": 1, "target_reps": "1 min each"}
    ]'::jsonb,
    ARRAY['upper-body', 'push', 'chest', 'shoulders', 'triceps']
),

(
    'Upper Body Pull',
    'Back and biceps focused workout.',
    'pull',
    'intermediate',
    45,
    '[
        {"exercise_name": "Face Pulls", "block_name": "Warmup", "sequence": 1, "target_sets": 2, "target_reps": "15"},
        {"exercise_name": "Scapular Retractions", "block_name": "Warmup", "sequence": 2, "target_sets": 2, "target_reps": "10"},
        {"exercise_name": "Pull-ups", "block_name": "Pull", "sequence": 3, "target_sets": 4, "target_reps": "6-10"},
        {"exercise_name": "Barbell Rows", "block_name": "Pull", "sequence": 4, "target_sets": 4, "target_reps": "8-10", "notes": "RPE 8"},
        {"exercise_name": "Lat Pulldowns", "block_name": "Pull", "sequence": 5, "target_sets": 3, "target_reps": "10-12"},
        {"exercise_name": "Seated Cable Rows", "block_name": "Pull", "sequence": 6, "target_sets": 3, "target_reps": "12"},
        {"exercise_name": "Face Pulls", "block_name": "Pull", "sequence": 7, "target_sets": 3, "target_reps": "15"},
        {"exercise_name": "Barbell Curls", "block_name": "Pull", "sequence": 8, "target_sets": 3, "target_reps": "10-12"},
        {"exercise_name": "Hammer Curls", "block_name": "Pull", "sequence": 9, "target_sets": 3, "target_reps": "12"},
        {"exercise_name": "Lat Stretch", "block_name": "Recovery", "sequence": 10, "target_sets": 1, "target_reps": "1 min each"}
    ]'::jsonb,
    ARRAY['upper-body', 'pull', 'back', 'biceps']
),

-- Lower Body Focus
(
    'Lower Body Power',
    'Quad and glute focused lower body workout.',
    'lower',
    'intermediate',
    50,
    '[
        {"exercise_name": "Bike Warmup", "block_name": "Cardio", "sequence": 1, "target_sets": 1, "target_reps": "5 min"},
        {"exercise_name": "Hip Circles", "block_name": "Mobility", "sequence": 2, "target_sets": 2, "target_reps": "10 each"},
        {"exercise_name": "Leg Swings", "block_name": "Mobility", "sequence": 3, "target_sets": 2, "target_reps": "10 each"},
        {"exercise_name": "Bodyweight Squats", "block_name": "Mobility", "sequence": 4, "target_sets": 2, "target_reps": "10"},
        {"exercise_name": "Back Squats", "block_name": "Legs", "sequence": 5, "target_sets": 4, "target_reps": "6-8", "notes": "RPE 8"},
        {"exercise_name": "Leg Press", "block_name": "Legs", "sequence": 6, "target_sets": 3, "target_reps": "10-12"},
        {"exercise_name": "Walking Lunges", "block_name": "Legs", "sequence": 7, "target_sets": 3, "target_reps": "10 each"},
        {"exercise_name": "Leg Extensions", "block_name": "Legs", "sequence": 8, "target_sets": 3, "target_reps": "12-15"},
        {"exercise_name": "Calf Raises", "block_name": "Legs", "sequence": 9, "target_sets": 4, "target_reps": "15"},
        {"exercise_name": "Quad Stretch", "block_name": "Recovery", "sequence": 10, "target_sets": 1, "target_reps": "1 min each"},
        {"exercise_name": "Pigeon Pose", "block_name": "Recovery", "sequence": 11, "target_sets": 1, "target_reps": "2 min each"}
    ]'::jsonb,
    ARRAY['lower-body', 'quads', 'glutes', 'squats']
),

(
    'Lower Body Posterior',
    'Hamstring and glute focused workout with hip hinge movements.',
    'lower',
    'intermediate',
    50,
    '[
        {"exercise_name": "Treadmill Walk", "block_name": "Cardio", "sequence": 1, "target_sets": 1, "target_reps": "5 min"},
        {"exercise_name": "Glute Bridges", "block_name": "Activation", "sequence": 2, "target_sets": 2, "target_reps": "15"},
        {"exercise_name": "Bird Dogs", "block_name": "Activation", "sequence": 3, "target_sets": 2, "target_reps": "10 each"},
        {"exercise_name": "Deadlifts", "block_name": "Hinge", "sequence": 4, "target_sets": 4, "target_reps": "5", "notes": "RPE 8"},
        {"exercise_name": "Romanian Deadlifts", "block_name": "Hinge", "sequence": 5, "target_sets": 3, "target_reps": "10-12"},
        {"exercise_name": "Hip Thrusts", "block_name": "Hinge", "sequence": 6, "target_sets": 3, "target_reps": "12"},
        {"exercise_name": "Lying Leg Curls", "block_name": "Hinge", "sequence": 7, "target_sets": 3, "target_reps": "12-15"},
        {"exercise_name": "Back Extensions", "block_name": "Hinge", "sequence": 8, "target_sets": 3, "target_reps": "15"},
        {"exercise_name": "Hamstring Stretch", "block_name": "Recovery", "sequence": 9, "target_sets": 1, "target_reps": "2 min each"},
        {"exercise_name": "Hip Flexor Stretch", "block_name": "Recovery", "sequence": 10, "target_sets": 1, "target_reps": "1 min each"}
    ]'::jsonb,
    ARRAY['lower-body', 'posterior', 'hamstrings', 'glutes', 'deadlift']
),

-- Mobility/Rehab
(
    'Full Body Mobility',
    'Comprehensive mobility routine for recovery and flexibility.',
    'mobility',
    'beginner',
    30,
    '[
        {"exercise_name": "Cat-Cow", "block_name": "Upper Body Mobility", "sequence": 1, "target_sets": 2, "target_reps": "10"},
        {"exercise_name": "Thread the Needle", "block_name": "Upper Body Mobility", "sequence": 2, "target_sets": 2, "target_reps": "8 each"},
        {"exercise_name": "Shoulder CARs", "block_name": "Upper Body Mobility", "sequence": 3, "target_sets": 2, "target_reps": "5 each"},
        {"exercise_name": "Wall Angels", "block_name": "Upper Body Mobility", "sequence": 4, "target_sets": 2, "target_reps": "10"},
        {"exercise_name": "Hip CARs", "block_name": "Lower Body Mobility", "sequence": 5, "target_sets": 2, "target_reps": "5 each"},
        {"exercise_name": "90/90 Stretch", "block_name": "Lower Body Mobility", "sequence": 6, "target_sets": 1, "target_reps": "2 min each"},
        {"exercise_name": "Frog Stretch", "block_name": "Lower Body Mobility", "sequence": 7, "target_sets": 1, "target_reps": "2 min"},
        {"exercise_name": "Ankle CARs", "block_name": "Lower Body Mobility", "sequence": 8, "target_sets": 2, "target_reps": "5 each"},
        {"exercise_name": "Child''s Pose", "block_name": "Recovery", "sequence": 9, "target_sets": 1, "target_reps": "2 min"},
        {"exercise_name": "Supine Twist", "block_name": "Recovery", "sequence": 10, "target_sets": 1, "target_reps": "1 min each"}
    ]'::jsonb,
    ARRAY['mobility', 'flexibility', 'recovery', 'stretching']
),

(
    'Hip & Core Rehab',
    'Targeted exercises for hip stability and core strength.',
    'functional',
    'beginner',
    25,
    '[
        {"exercise_name": "Clamshells", "block_name": "Prehab", "sequence": 1, "target_sets": 3, "target_reps": "15 each"},
        {"exercise_name": "Side-lying Hip Abduction", "block_name": "Prehab", "sequence": 2, "target_sets": 3, "target_reps": "12 each"},
        {"exercise_name": "Glute Bridges", "block_name": "Prehab", "sequence": 3, "target_sets": 3, "target_reps": "15"},
        {"exercise_name": "Dead Bugs", "block_name": "Prehab", "sequence": 4, "target_sets": 3, "target_reps": "10 each"},
        {"exercise_name": "Bird Dogs", "block_name": "Prehab", "sequence": 5, "target_sets": 3, "target_reps": "10 each"},
        {"exercise_name": "Pallof Press", "block_name": "Prehab", "sequence": 6, "target_sets": 3, "target_reps": "12 each"},
        {"exercise_name": "Hip Flexor Stretch", "block_name": "Recovery", "sequence": 7, "target_sets": 1, "target_reps": "1 min each"},
        {"exercise_name": "Piriformis Stretch", "block_name": "Recovery", "sequence": 8, "target_sets": 1, "target_reps": "1 min each"}
    ]'::jsonb,
    ARRAY['rehab', 'hip', 'core', 'stability', 'injury-prevention']
),

-- Cardio/HIIT
(
    'HIIT Conditioning',
    'High intensity interval training for cardiovascular fitness.',
    'cardio',
    'intermediate',
    30,
    '[
        {"exercise_name": "Light Jog", "block_name": "Warmup", "sequence": 1, "target_sets": 1, "target_reps": "3 min"},
        {"exercise_name": "Dynamic Stretches", "block_name": "Warmup", "sequence": 2, "target_sets": 1, "target_reps": "2 min"},
        {"exercise_name": "Burpees", "block_name": "HIIT Circuit", "sequence": 3, "target_sets": 4, "target_reps": "30 sec"},
        {"exercise_name": "Mountain Climbers", "block_name": "HIIT Circuit", "sequence": 4, "target_sets": 4, "target_reps": "30 sec"},
        {"exercise_name": "Jump Squats", "block_name": "HIIT Circuit", "sequence": 5, "target_sets": 4, "target_reps": "30 sec"},
        {"exercise_name": "High Knees", "block_name": "HIIT Circuit", "sequence": 6, "target_sets": 4, "target_reps": "30 sec"},
        {"exercise_name": "Rest Between Rounds", "block_name": "HIIT Circuit", "sequence": 7, "target_sets": 4, "target_reps": "60 sec"},
        {"exercise_name": "Walking", "block_name": "Cool Down", "sequence": 8, "target_sets": 1, "target_reps": "3 min"},
        {"exercise_name": "Light Stretching", "block_name": "Cool Down", "sequence": 9, "target_sets": 1, "target_reps": "5 min"}
    ]'::jsonb,
    ARRAY['cardio', 'hiit', 'conditioning', 'fat-loss']
),

(
    'Quick Tabata Blast',
    'Quick but intense Tabata-style workout.',
    'cardio',
    'advanced',
    20,
    '[
        {"exercise_name": "Jumping Jacks", "block_name": "Warmup", "sequence": 1, "target_sets": 1, "target_reps": "2 min"},
        {"exercise_name": "Arm Swings", "block_name": "Warmup", "sequence": 2, "target_sets": 1, "target_reps": "1 min"},
        {"exercise_name": "Burpees", "block_name": "Tabata Round 1", "sequence": 3, "target_sets": 1, "target_reps": "20/10 x8", "notes": "20 sec on, 10 sec off, 8 rounds"},
        {"exercise_name": "Rest", "block_name": "Tabata Round 1", "sequence": 4, "target_sets": 1, "target_reps": "1 min"},
        {"exercise_name": "Jump Squats", "block_name": "Tabata Round 2", "sequence": 5, "target_sets": 1, "target_reps": "20/10 x8", "notes": "20 sec on, 10 sec off, 8 rounds"},
        {"exercise_name": "Rest", "block_name": "Tabata Round 2", "sequence": 6, "target_sets": 1, "target_reps": "1 min"},
        {"exercise_name": "Mountain Climbers", "block_name": "Tabata Round 3", "sequence": 7, "target_sets": 1, "target_reps": "20/10 x8", "notes": "20 sec on, 10 sec off, 8 rounds"},
        {"exercise_name": "Walking", "block_name": "Cool Down", "sequence": 8, "target_sets": 1, "target_reps": "2 min"},
        {"exercise_name": "Deep Breathing", "block_name": "Cool Down", "sequence": 9, "target_sets": 1, "target_reps": "2 min"}
    ]'::jsonb,
    ARRAY['cardio', 'tabata', 'hiit', 'quick', 'intense']
),

-- Beginner Workouts
(
    'Beginner Full Body',
    'Perfect introduction to strength training with basic movements.',
    'full_body',
    'beginner',
    40,
    '[
        {"exercise_name": "Walking", "block_name": "Warmup", "sequence": 1, "target_sets": 1, "target_reps": "5 min"},
        {"exercise_name": "Arm Circles", "block_name": "Warmup", "sequence": 2, "target_sets": 1, "target_reps": "10 each"},
        {"exercise_name": "Push-ups (or Knee Push-ups)", "block_name": "Upper Body", "sequence": 3, "target_sets": 3, "target_reps": "8-10"},
        {"exercise_name": "Dumbbell Rows", "block_name": "Upper Body", "sequence": 4, "target_sets": 3, "target_reps": "10 each"},
        {"exercise_name": "Bodyweight Squats", "block_name": "Lower Body", "sequence": 5, "target_sets": 3, "target_reps": "12"},
        {"exercise_name": "Glute Bridges", "block_name": "Lower Body", "sequence": 6, "target_sets": 3, "target_reps": "12"},
        {"exercise_name": "Step Ups", "block_name": "Lower Body", "sequence": 7, "target_sets": 2, "target_reps": "10 each"},
        {"exercise_name": "Plank", "block_name": "Core", "sequence": 8, "target_sets": 1, "target_reps": "30 sec"},
        {"exercise_name": "Dead Bugs", "block_name": "Core", "sequence": 9, "target_sets": 2, "target_reps": "8 each"},
        {"exercise_name": "Full Body Stretch", "block_name": "Cool Down", "sequence": 10, "target_sets": 1, "target_reps": "5 min"}
    ]'::jsonb,
    ARRAY['beginner', 'full-body', 'introduction', 'basics']
),

(
    'Home Workout - No Equipment',
    'Bodyweight workout that can be done anywhere.',
    'full_body',
    'beginner',
    35,
    '[
        {"exercise_name": "Jumping Jacks", "block_name": "Warmup", "sequence": 1, "target_sets": 1, "target_reps": "2 min"},
        {"exercise_name": "High Knees", "block_name": "Warmup", "sequence": 2, "target_sets": 1, "target_reps": "1 min"},
        {"exercise_name": "Arm Circles", "block_name": "Warmup", "sequence": 3, "target_sets": 1, "target_reps": "1 min"},
        {"exercise_name": "Push-ups", "block_name": "Upper Body", "sequence": 4, "target_sets": 3, "target_reps": "10-15"},
        {"exercise_name": "Diamond Push-ups", "block_name": "Upper Body", "sequence": 5, "target_sets": 2, "target_reps": "8"},
        {"exercise_name": "Pike Push-ups", "block_name": "Upper Body", "sequence": 6, "target_sets": 2, "target_reps": "8"},
        {"exercise_name": "Bodyweight Squats", "block_name": "Lower Body", "sequence": 7, "target_sets": 3, "target_reps": "15"},
        {"exercise_name": "Reverse Lunges", "block_name": "Lower Body", "sequence": 8, "target_sets": 3, "target_reps": "10 each"},
        {"exercise_name": "Single Leg Glute Bridges", "block_name": "Lower Body", "sequence": 9, "target_sets": 2, "target_reps": "10 each"},
        {"exercise_name": "Plank", "block_name": "Core", "sequence": 10, "target_sets": 1, "target_reps": "45 sec"},
        {"exercise_name": "Bicycle Crunches", "block_name": "Core", "sequence": 11, "target_sets": 2, "target_reps": "15 each"},
        {"exercise_name": "Superman", "block_name": "Core", "sequence": 12, "target_sets": 2, "target_reps": "12"},
        {"exercise_name": "Standing Forward Fold", "block_name": "Cool Down", "sequence": 13, "target_sets": 1, "target_reps": "1 min"},
        {"exercise_name": "Child''s Pose", "block_name": "Cool Down", "sequence": 14, "target_sets": 1, "target_reps": "1 min"},
        {"exercise_name": "Pigeon Pose", "block_name": "Cool Down", "sequence": 15, "target_sets": 1, "target_reps": "1 min each"}
    ]'::jsonb,
    ARRAY['home', 'no-equipment', 'bodyweight', 'beginner']
);
