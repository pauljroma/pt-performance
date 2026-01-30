-- BUILD 331: Fix "August 13, 2018" workout template
-- Problem: Strength section shows "1,2,3,4,5" instead of actual exercise names
-- Solution: Replace with properly structured exercise data from original workout plan

UPDATE system_workout_templates
SET
    description = 'Full-body strength workout with press focus, split squats, and conditioning circuit',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
        {
            "id": "a13-2018-block-1",
            "name": "Active Warmup",
            "block_type": "cardio",
            "sequence": 1,
            "exercises": [
                {
                    "id": "a13-2018-ex-1-1",
                    "name": "Jump Rope",
                    "sequence": 1,
                    "prescribed_sets": 3,
                    "prescribed_reps": "1 min",
                    "notes": "Cardio activation - 3 rounds"
                },
                {
                    "id": "a13-2018-ex-1-2",
                    "name": "Air Squat",
                    "sequence": 2,
                    "prescribed_sets": 3,
                    "prescribed_reps": "10",
                    "notes": "Lower body prep - 3 rounds"
                },
                {
                    "id": "a13-2018-ex-1-3",
                    "name": "KB Swing",
                    "sequence": 3,
                    "prescribed_sets": 3,
                    "prescribed_reps": "15",
                    "notes": "Power activation - 3 rounds"
                }
            ]
        },
        {
            "id": "a13-2018-block-2",
            "name": "Dynamic Mobility",
            "block_type": "dynamic_stretch",
            "sequence": 2,
            "exercises": [
                {
                    "id": "a13-2018-ex-2-1",
                    "name": "Side Shuffle w/ Arm Swing",
                    "sequence": 1,
                    "notes": "Lateral movement"
                },
                {
                    "id": "a13-2018-ex-2-2",
                    "name": "Knee Hug to Hip Opener",
                    "sequence": 2,
                    "notes": "Hip mobility"
                },
                {
                    "id": "a13-2018-ex-2-3",
                    "name": "Carioca",
                    "sequence": 3,
                    "notes": "Hip mobility"
                },
                {
                    "id": "a13-2018-ex-2-4",
                    "name": "Push-Ups",
                    "sequence": 4,
                    "prescribed_reps": "10",
                    "notes": "Upper body prep"
                },
                {
                    "id": "a13-2018-ex-2-5",
                    "name": "Toy Soldier",
                    "sequence": 5,
                    "notes": "Hamstring activation"
                },
                {
                    "id": "a13-2018-ex-2-6",
                    "name": "Lateral Lunge",
                    "sequence": 6,
                    "notes": "Adductor mobility"
                }
            ]
        },
        {
            "id": "a13-2018-block-3",
            "name": "Shoulder Prep",
            "block_type": "activation",
            "sequence": 3,
            "exercises": [
                {
                    "id": "a13-2018-ex-3-1",
                    "name": "Abduction to External Rotation",
                    "sequence": 1,
                    "prescribed_reps": "12",
                    "notes": "Rotator cuff activation"
                },
                {
                    "id": "a13-2018-ex-3-2",
                    "name": "Band Press",
                    "sequence": 2,
                    "prescribed_reps": "12",
                    "notes": "Shoulder activation"
                },
                {
                    "id": "a13-2018-ex-3-3",
                    "name": "A/T/Y Raises",
                    "sequence": 3,
                    "prescribed_sets": 6,
                    "notes": "Full shoulder prep - 6 rounds"
                }
            ]
        },
        {
            "id": "a13-2018-block-4",
            "name": "Strength - Main Lifts",
            "block_type": "push",
            "sequence": 4,
            "exercises": [
                {
                    "id": "a13-2018-ex-4-1",
                    "name": "Strict Press to Push Press",
                    "sequence": 1,
                    "prescribed_sets": 3,
                    "prescribed_reps": "8 strict + 8 push",
                    "notes": "Set 1: Light (RPE 5), Set 2: Moderate (RPE 6), Set 3: Moderate (RPE 7). Rest 90 sec. Accessory: Dead Bug (SLOW) x10 between sets"
                },
                {
                    "id": "a13-2018-ex-4-2",
                    "name": "DB Split Squat",
                    "sequence": 2,
                    "prescribed_sets": 3,
                    "prescribed_reps": "8/8",
                    "notes": "Set 1: Moderate (RPE 6), Set 2: Heavy (RPE 7), Set 3: Heavy (RPE 8). Rest 90 sec. Accessory: Standing Staggered Stance Hamstring Stretch x5/5 between sets"
                }
            ]
        },
        {
            "id": "a13-2018-block-5",
            "name": "Conditioning - 4 Rounds",
            "block_type": "functional",
            "sequence": 5,
            "exercises": [
                {
                    "id": "a13-2018-ex-5-1",
                    "name": "KB Swing",
                    "sequence": 1,
                    "prescribed_reps": "25",
                    "notes": "Beginner: 18 light, Advanced: 30 heavy"
                },
                {
                    "id": "a13-2018-ex-5-2",
                    "name": "Sit-Ups",
                    "sequence": 2,
                    "prescribed_reps": "20",
                    "notes": "Beginner: 12, Advanced: 30"
                },
                {
                    "id": "a13-2018-ex-5-3",
                    "name": "Goblet Squat",
                    "sequence": 3,
                    "prescribed_reps": "15",
                    "notes": "Beginner: 10 light, Advanced: 20 heavy"
                },
                {
                    "id": "a13-2018-ex-5-4",
                    "name": "Burpees",
                    "sequence": 4,
                    "prescribed_reps": "10",
                    "notes": "Beginner: 6, Advanced: 15. Rest 60 sec between rounds"
                }
            ]
        },
        {
            "id": "a13-2018-block-6",
            "name": "Finisher",
            "block_type": "recovery",
            "sequence": 6,
            "exercises": [
                {
                    "id": "a13-2018-ex-6-1",
                    "name": "Foam Roll",
                    "sequence": 1,
                    "prescribed_reps": "5-10 min",
                    "notes": "Focus: shoulders, quads, hip flexors"
                }
            ]
        }
    ]'::jsonb,
    tags = '{strength,press,split-squat,kettlebell,conditioning,burpees,goblet-squat,shoulders,full-body,intermediate}'
WHERE id = '0dc0c2da-e20b-477a-a23a-ef4b8f87a555';

-- Verify the update
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM system_workout_templates
    WHERE id = '0dc0c2da-e20b-477a-a23a-ef4b8f87a555'
      AND exercises::text LIKE '%Strict Press to Push Press%';

    IF updated_count = 0 THEN
        RAISE WARNING 'August 13, 2018 workout update may have failed - exercise not found';
    ELSE
        RAISE NOTICE 'Successfully updated August 13, 2018 workout with proper exercise names';
    END IF;
END $$;
