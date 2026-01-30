-- BUILD 326: Seed Arm Farm Program
-- Purpose: Add the "15-Minute Arm Farm" workout template
-- A high-efficiency biceps + triceps workout designed for busy schedules
-- Uses supersets and tri-sets for maximum time efficiency

INSERT INTO system_workout_templates (
    id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file
) VALUES (
    'a1b2c3d4-a000-fa00-0001-000000000001',
    '15-Minute Arm Farm',
    'High-efficiency biceps + triceps workout. Perfect for busy days or as a finisher after your main lift. Uses supersets and tri-sets for maximum pump in minimal time. Goal: High tension + metabolic stress with zero CNS drain.',
    'upper',
    'intermediate',
    15,
    '[
        {
            "block_name": "Warm-Up",
            "block_type": "warmup",
            "block_notes": "Blood flow and joint prep - zero fatigue",
            "exercises": [
                {"exercise_name": "Light DB Curls", "sequence": 1, "target_sets": 1, "target_reps": "20", "notes": "Easy weight, get blood flowing"},
                {"exercise_name": "DB Kickbacks or Band Pushdowns", "sequence": 2, "target_sets": 1, "target_reps": "20", "notes": "Light resistance, activate triceps"},
                {"exercise_name": "Arm Circles + Elbow Openers", "sequence": 3, "target_sets": 1, "target_reps": "30 seconds", "notes": "Dynamic mobility for elbows and shoulders"}
            ]
        },
        {
            "block_name": "Block 1: Heavy Mechanical Tension",
            "block_type": "strength",
            "block_notes": "Superset A - 3 rounds, 30 sec rest between rounds. Long-length loading + eccentric control = fastest hypertrophy signal.",
            "exercises": [
                {"exercise_name": "Standing DB Curl", "sequence": 4, "target_sets": 3, "target_reps": "8-10", "notes": "3-second lower, full supination at top. Focus on stretch at bottom."},
                {"exercise_name": "Overhead DB Triceps Extension", "sequence": 5, "target_sets": 3, "target_reps": "10-12", "notes": "Deep stretch at bottom, slow 3-sec eccentric. Keep elbows pointed up."}
            ]
        },
        {
            "block_name": "Block 2: Volume + Pump",
            "block_type": "hypertrophy",
            "block_notes": "Tri-Set B - 2 rounds, 45 sec rest between rounds. Hits biceps long head, brachialis, and medial triceps.",
            "exercises": [
                {"exercise_name": "Incline DB Curl", "sequence": 6, "target_sets": 2, "target_reps": "12", "notes": "Bench at 45-60 degrees. Let arms hang straight down for max stretch."},
                {"exercise_name": "Close-Grip Push-Ups", "sequence": 7, "target_sets": 2, "target_reps": "to near failure", "notes": "Hands shoulder-width or narrower. Stop 1-2 reps before failure."},
                {"exercise_name": "Hammer Curl", "sequence": 8, "target_sets": 2, "target_reps": "12-15", "notes": "Neutral grip targets brachialis for arm thickness. Controlled tempo."}
            ]
        },
        {
            "block_name": "Block 3: Finisher (Burn + Stretch)",
            "block_type": "metabolic",
            "block_notes": "EMOM x 3 minutes. Work 30 sec, rest 30 sec. If you finish early, hold the stretch position.",
            "exercises": [
                {"exercise_name": "Alternating DB Curls", "sequence": 9, "target_sets": 3, "target_reps": "30 seconds continuous", "notes": "Non-stop alternating curls. Keep constant tension."},
                {"exercise_name": "Bench Dips or Cable Pushdowns", "sequence": 10, "target_sets": 3, "target_reps": "30 seconds", "notes": "Continuous movement until the 30 seconds is up. Chase the burn."}
            ]
        }
    ]'::jsonb,
    ARRAY['arms', 'biceps', 'triceps', 'pump', 'quick', '15min', 'superset', 'hypertrophy', 'intermediate', 'finisher'],
    'build_326_arm_farm.sql'
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    exercises = EXCLUDED.exercises,
    tags = EXCLUDED.tags;

-- Also add variations for different contexts

-- Travel/Hotel Version (bodyweight focused)
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file
) VALUES (
    'a1b2c3d4-a000-fa00-0002-000000000002',
    'Arm Farm - Travel Edition',
    'Hotel/travel-friendly arm workout with minimal equipment. Uses towels, bodyweight, and isometric holds. Same 15-minute structure, zero excuses.',
    'upper',
    'beginner',
    15,
    '[
        {
            "block_name": "Warm-Up",
            "block_type": "warmup",
            "block_notes": "Activate and prep with zero equipment",
            "exercises": [
                {"exercise_name": "Arm Circles", "sequence": 1, "target_sets": 1, "target_reps": "20 each direction", "notes": "Start small, gradually increase size"},
                {"exercise_name": "Wall Push-Ups", "sequence": 2, "target_sets": 1, "target_reps": "15", "notes": "Easy pace, warm up pushing muscles"},
                {"exercise_name": "Wrist Circles + Elbow Flexion", "sequence": 3, "target_sets": 1, "target_reps": "30 seconds", "notes": "Loosen up joints"}
            ]
        },
        {
            "block_name": "Block 1: Isometric Tension",
            "block_type": "strength",
            "block_notes": "3 rounds. Use a towel or doorframe for resistance.",
            "exercises": [
                {"exercise_name": "Towel Curl Isometric Hold", "sequence": 4, "target_sets": 3, "target_reps": "20-30 sec hold", "notes": "Step on towel, curl up to 90 degrees, hold with max tension"},
                {"exercise_name": "Diamond Push-Ups", "sequence": 5, "target_sets": 3, "target_reps": "8-12", "notes": "Hands form diamond shape. Slow eccentric."}
            ]
        },
        {
            "block_name": "Block 2: Bodyweight Volume",
            "block_type": "hypertrophy",
            "block_notes": "2 rounds of this tri-set",
            "exercises": [
                {"exercise_name": "Chin-Ups (or Doorframe Rows)", "sequence": 6, "target_sets": 2, "target_reps": "max reps", "notes": "Supinated grip for bicep emphasis"},
                {"exercise_name": "Bench/Chair Dips", "sequence": 7, "target_sets": 2, "target_reps": "15-20", "notes": "Feet on floor, hands on chair behind you"},
                {"exercise_name": "Towel Hammer Curl", "sequence": 8, "target_sets": 2, "target_reps": "12-15", "notes": "Curl towel against your foot resistance"}
            ]
        },
        {
            "block_name": "Block 3: Burnout",
            "block_type": "metabolic",
            "block_notes": "3-minute EMOM finisher",
            "exercises": [
                {"exercise_name": "Push-Up Negatives", "sequence": 9, "target_sets": 3, "target_reps": "30 sec slow negatives", "notes": "5-second lowering phase, reset at top"},
                {"exercise_name": "Bicep Flexing Hold", "sequence": 10, "target_sets": 3, "target_reps": "30 sec hold", "notes": "Flex biceps hard, hold peak contraction"}
            ]
        }
    ]'::jsonb,
    ARRAY['arms', 'biceps', 'triceps', 'travel', 'hotel', 'bodyweight', 'no-equipment', '15min', 'beginner'],
    'build_326_arm_farm.sql'
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    exercises = EXCLUDED.exercises,
    tags = EXCLUDED.tags;

-- Cable-Focused Gym Version (maximum pump)
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file
) VALUES (
    'a1b2c3d4-a000-fa00-0003-000000000003',
    'Arm Farm - Cable Pump Edition',
    'Gym-focused arm workout using cables for constant tension. Maximum pump and time under tension. Great for arm specialization phases.',
    'upper',
    'intermediate',
    15,
    '[
        {
            "block_name": "Warm-Up",
            "block_type": "warmup",
            "block_notes": "Light cable work to prime muscles",
            "exercises": [
                {"exercise_name": "Cable Curl (Light)", "sequence": 1, "target_sets": 1, "target_reps": "20", "notes": "Very light weight, focus on contraction"},
                {"exercise_name": "Cable Pushdown (Light)", "sequence": 2, "target_sets": 1, "target_reps": "20", "notes": "Light weight, full range of motion"},
                {"exercise_name": "Band Pull-Aparts", "sequence": 3, "target_sets": 1, "target_reps": "15", "notes": "Rear delt and shoulder prep"}
            ]
        },
        {
            "block_name": "Block 1: Stretch-Focused",
            "block_type": "strength",
            "block_notes": "3 rounds. Emphasize the stretched position.",
            "exercises": [
                {"exercise_name": "Incline Cable Curl", "sequence": 4, "target_sets": 3, "target_reps": "10-12", "notes": "Set bench at 45 degrees behind low cable. Max stretch at bottom."},
                {"exercise_name": "Overhead Cable Triceps Extension", "sequence": 5, "target_sets": 3, "target_reps": "12-15", "notes": "Face away from cable, arms overhead. Deep stretch on long head."}
            ]
        },
        {
            "block_name": "Block 2: Constant Tension",
            "block_type": "hypertrophy",
            "block_notes": "2 rounds. Never let tension off the muscle.",
            "exercises": [
                {"exercise_name": "Cable Preacher Curl", "sequence": 6, "target_sets": 2, "target_reps": "12", "notes": "Use preacher bench with low cable. Constant tension throughout."},
                {"exercise_name": "Cable Triceps Kickback", "sequence": 7, "target_sets": 2, "target_reps": "12 each arm", "notes": "Bend over, single arm. Squeeze hard at lockout."},
                {"exercise_name": "Cable Hammer Curl (Rope)", "sequence": 8, "target_sets": 2, "target_reps": "15", "notes": "Use rope attachment, neutral grip"}
            ]
        },
        {
            "block_name": "Block 3: Drop Set Finisher",
            "block_type": "metabolic",
            "block_notes": "One giant drop set each. Start heavy, drop weight 3 times.",
            "exercises": [
                {"exercise_name": "Cable Curl Drop Set", "sequence": 9, "target_sets": 1, "target_reps": "10-10-10-10 (drop)", "notes": "Start at 10RM, drop 20% each set, no rest between drops"},
                {"exercise_name": "Cable Pushdown Drop Set", "sequence": 10, "target_sets": 1, "target_reps": "10-10-10-10 (drop)", "notes": "Same protocol. Chase the pump."}
            ]
        }
    ]'::jsonb,
    ARRAY['arms', 'biceps', 'triceps', 'cables', 'pump', 'gym', '15min', 'intermediate', 'specialization'],
    'build_326_arm_farm.sql'
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    exercises = EXCLUDED.exercises,
    tags = EXCLUDED.tags;

-- Verification
DO $$
DECLARE
    arm_farm_count INT;
BEGIN
    SELECT COUNT(*) INTO arm_farm_count
    FROM system_workout_templates
    WHERE name LIKE '%Arm Farm%';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'BUILD 326: Arm Farm Programs Added';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Arm Farm templates created: %', arm_farm_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Templates:';
    RAISE NOTICE '  1. 15-Minute Arm Farm (standard)';
    RAISE NOTICE '  2. Arm Farm - Travel Edition (bodyweight)';
    RAISE NOTICE '  3. Arm Farm - Cable Pump Edition (gym)';
    RAISE NOTICE '============================================';
END $$;
