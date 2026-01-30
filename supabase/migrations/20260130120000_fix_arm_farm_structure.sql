-- BUILD 326: Fix Arm Farm Program JSON Structure
-- Purpose: Update exercise JSON to match Swift model expectations
-- Issue: Used "block_name" and "exercise_name" instead of "name"

-- Update the standard Arm Farm
UPDATE system_workout_templates
SET exercises = '[
    {
        "name": "Warm-Up",
        "block_type": "warmup",
        "sequence": 0,
        "exercises": [
            {"name": "Light DB Curls", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "20", "notes": "Easy weight, get blood flowing"},
            {"name": "DB Kickbacks or Band Pushdowns", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "20", "notes": "Light resistance, activate triceps"},
            {"name": "Arm Circles + Elbow Openers", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 seconds", "notes": "Dynamic mobility for elbows and shoulders"}
        ]
    },
    {
        "name": "Block 1: Heavy Mechanical Tension",
        "block_type": "strength",
        "sequence": 1,
        "exercises": [
            {"name": "Standing DB Curl", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "8-10", "notes": "3-second lower, full supination at top. Focus on stretch at bottom."},
            {"name": "Overhead DB Triceps Extension", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "10-12", "notes": "Deep stretch at bottom, slow 3-sec eccentric. Keep elbows pointed up."}
        ]
    },
    {
        "name": "Block 2: Volume + Pump",
        "block_type": "hypertrophy",
        "sequence": 2,
        "exercises": [
            {"name": "Incline DB Curl", "sequence": 1, "prescribed_sets": 2, "prescribed_reps": "12", "notes": "Bench at 45-60 degrees. Let arms hang straight down for max stretch."},
            {"name": "Close-Grip Push-Ups", "sequence": 2, "prescribed_sets": 2, "prescribed_reps": "to near failure", "notes": "Hands shoulder-width or narrower. Stop 1-2 reps before failure."},
            {"name": "Hammer Curl", "sequence": 3, "prescribed_sets": 2, "prescribed_reps": "12-15", "notes": "Neutral grip targets brachialis for arm thickness. Controlled tempo."}
        ]
    },
    {
        "name": "Block 3: Finisher (Burn + Stretch)",
        "block_type": "metabolic",
        "sequence": 3,
        "exercises": [
            {"name": "Alternating DB Curls", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "30 seconds continuous", "notes": "Non-stop alternating curls. Keep constant tension."},
            {"name": "Bench Dips or Cable Pushdowns", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "30 seconds", "notes": "Continuous movement until the 30 seconds is up. Chase the burn."}
        ]
    }
]'::jsonb
WHERE id = 'a1b2c3d4-a000-fa00-0001-000000000001';

-- Update the Travel Edition
UPDATE system_workout_templates
SET exercises = '[
    {
        "name": "Warm-Up",
        "block_type": "warmup",
        "sequence": 0,
        "exercises": [
            {"name": "Arm Circles", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "20 each direction", "notes": "Start small, gradually increase size"},
            {"name": "Wall Push-Ups", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "15", "notes": "Easy pace, warm up pushing muscles"},
            {"name": "Wrist Circles + Elbow Flexion", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 seconds", "notes": "Loosen up joints"}
        ]
    },
    {
        "name": "Block 1: Isometric Tension",
        "block_type": "strength",
        "sequence": 1,
        "exercises": [
            {"name": "Towel Curl Isometric Hold", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "20-30 sec hold", "notes": "Step on towel, curl up to 90 degrees, hold with max tension"},
            {"name": "Diamond Push-Ups", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "8-12", "notes": "Hands form diamond shape. Slow eccentric."}
        ]
    },
    {
        "name": "Block 2: Bodyweight Volume",
        "block_type": "hypertrophy",
        "sequence": 2,
        "exercises": [
            {"name": "Chin-Ups (or Doorframe Rows)", "sequence": 1, "prescribed_sets": 2, "prescribed_reps": "max reps", "notes": "Supinated grip for bicep emphasis"},
            {"name": "Bench/Chair Dips", "sequence": 2, "prescribed_sets": 2, "prescribed_reps": "15-20", "notes": "Feet on floor, hands on chair behind you"},
            {"name": "Towel Hammer Curl", "sequence": 3, "prescribed_sets": 2, "prescribed_reps": "12-15", "notes": "Curl towel against your foot resistance"}
        ]
    },
    {
        "name": "Block 3: Burnout",
        "block_type": "metabolic",
        "sequence": 3,
        "exercises": [
            {"name": "Push-Up Negatives", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "30 sec slow negatives", "notes": "5-second lowering phase, reset at top"},
            {"name": "Bicep Flexing Hold", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "30 sec hold", "notes": "Flex biceps hard, hold peak contraction"}
        ]
    }
]'::jsonb
WHERE id = 'a1b2c3d4-a000-fa00-0002-000000000002';

-- Update the Cable Pump Edition
UPDATE system_workout_templates
SET exercises = '[
    {
        "name": "Warm-Up",
        "block_type": "warmup",
        "sequence": 0,
        "exercises": [
            {"name": "Cable Curl (Light)", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "20", "notes": "Very light weight, focus on contraction"},
            {"name": "Cable Pushdown (Light)", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "20", "notes": "Light weight, full range of motion"},
            {"name": "Band Pull-Aparts", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "15", "notes": "Rear delt and shoulder prep"}
        ]
    },
    {
        "name": "Block 1: Stretch-Focused",
        "block_type": "strength",
        "sequence": 1,
        "exercises": [
            {"name": "Incline Cable Curl", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "10-12", "notes": "Set bench at 45 degrees behind low cable. Max stretch at bottom."},
            {"name": "Overhead Cable Triceps Extension", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "12-15", "notes": "Face away from cable, arms overhead. Deep stretch on long head."}
        ]
    },
    {
        "name": "Block 2: Constant Tension",
        "block_type": "hypertrophy",
        "sequence": 2,
        "exercises": [
            {"name": "Cable Preacher Curl", "sequence": 1, "prescribed_sets": 2, "prescribed_reps": "12", "notes": "Use preacher bench with low cable. Constant tension throughout."},
            {"name": "Cable Triceps Kickback", "sequence": 2, "prescribed_sets": 2, "prescribed_reps": "12 each arm", "notes": "Bend over, single arm. Squeeze hard at lockout."},
            {"name": "Cable Hammer Curl (Rope)", "sequence": 3, "prescribed_sets": 2, "prescribed_reps": "15", "notes": "Use rope attachment, neutral grip"}
        ]
    },
    {
        "name": "Block 3: Drop Set Finisher",
        "block_type": "metabolic",
        "sequence": 3,
        "exercises": [
            {"name": "Cable Curl Drop Set", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10-10-10-10 (drop)", "notes": "Start at 10RM, drop 20% each set, no rest between drops"},
            {"name": "Cable Pushdown Drop Set", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10-10-10-10 (drop)", "notes": "Same protocol. Chase the pump."}
        ]
    }
]'::jsonb
WHERE id = 'a1b2c3d4-a000-fa00-0003-000000000003';

-- Verification
DO $$
DECLARE
    template_rec RECORD;
    block_count INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'BUILD 326: Arm Farm JSON Structure Fixed';
    RAISE NOTICE '============================================';

    FOR template_rec IN
        SELECT name, exercises
        FROM system_workout_templates
        WHERE name LIKE '%Arm Farm%'
    LOOP
        SELECT jsonb_array_length(template_rec.exercises) INTO block_count;
        RAISE NOTICE 'Template: % - % blocks', template_rec.name, block_count;
    END LOOP;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'Fixed field names:';
    RAISE NOTICE '  - block_name -> name';
    RAISE NOTICE '  - exercise_name -> name';
    RAISE NOTICE '  - target_sets -> prescribed_sets';
    RAISE NOTICE '  - target_reps -> prescribed_reps';
    RAISE NOTICE '  - Added sequence to blocks';
    RAISE NOTICE '============================================';
END $$;
