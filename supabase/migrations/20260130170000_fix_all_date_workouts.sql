-- BUILD 332: Fix all date-labeled workout templates
-- Generated from original Dropbox workout files
-- Replaces incorrect '1,2,3,4,5' exercise names with actual exercise data


-- Fix "January 2, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180102-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180102-ex-1-1",
                "name": "Push Ups",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Warm-up pace"
            },
            {
                "id": "20180102-ex-1-2",
                "name": "Air Squats",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Full depth"
            },
            {
                "id": "20180102-ex-1-3",
                "name": "Jumping Jacks",
                "sequence": 3,
                "prescribed_reps": "20",
                "notes": "Elevate HR"
            }
        ]
    },
    {
        "id": "20180102-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180102-ex-2-1",
                "name": "PVC Good Mornings",
                "sequence": 1,
                "notes": "Hip hinge activation"
            },
            {
                "id": "20180102-ex-2-2",
                "name": "PVC Passovers",
                "sequence": 2,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180102-ex-2-3",
                "name": "Arm Circles",
                "sequence": 3,
                "notes": "Shoulder warm-up"
            },
            {
                "id": "20180102-ex-2-4",
                "name": "Back Lunge + Twist",
                "sequence": 4,
                "notes": "Hip flexor/t-spine"
            },
            {
                "id": "20180102-ex-2-5",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 2, 2018';


-- Fix "January 4, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180104-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180104-ex-1-1",
                "name": "Bear Crawl 4-way",
                "sequence": 1,
                "notes": "Forward, backward, lateral"
            },
            {
                "id": "20180104-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded or single leg"
            }
        ]
    },
    {
        "id": "20180104-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180104-ex-2-1",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/glute activation"
            },
            {
                "id": "20180104-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180104-ex-2-3",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring mobility"
            },
            {
                "id": "20180104-ex-2-4",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip/groin mobility"
            },
            {
                "id": "20180104-ex-2-5",
                "name": "RRL",
                "sequence": 5,
                "notes": "Hip rotation"
            },
            {
                "id": "20180104-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "20180104-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180104-ex-3-1",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (bar only) (RPE 5). Set 2: Light+ (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            },
            {
                "id": "20180104-ex-3-2",
                "name": "\u00bd Kneel SA Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets (switch sides immediately) Accessory: PVC Passover between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 4, 2018';


-- Fix "January 7, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180107-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180107-ex-1-1",
                "name": "Jumping Jacks",
                "sequence": 1,
                "prescribed_reps": "30",
                "notes": "Elevate HR"
            },
            {
                "id": "20180107-ex-1-2",
                "name": "TRX Rows",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Activation"
            }
        ]
    },
    {
        "id": "20180107-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180107-ex-2-1",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180107-ex-2-2",
                "name": "Rev. Lunge + Reach",
                "sequence": 2,
                "notes": "Hip flexor/t-spine"
            },
            {
                "id": "20180107-ex-2-3",
                "name": "High Knee Pull",
                "sequence": 3,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180107-ex-2-4",
                "name": "PVC Passovers",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180107-ex-2-5",
                "name": "Spidermans",
                "sequence": 5,
                "notes": "Hip/groin mobility"
            },
            {
                "id": "20180107-ex-2-6",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "20180107-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180107-ex-3-1",
                "name": "Walking Lunges",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 5). Set 2: Light DBs (RPE 6). Set 3: Moderate DBs (RPE 7). Set 4: Heavy DBs (RPE 8). Rest: 90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180107-ex-3-2",
                "name": "Bent Over Row (BOR)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180107-block-4",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180107-ex-4-1",
                "name": "KB Swings",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "4 rounds total"
            },
            {
                "id": "20180107-ex-4-2",
                "name": "Russian Twists",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "15e",
                "notes": "4 rounds total"
            },
            {
                "id": "20180107-ex-4-3",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "4 rounds total"
            },
            {
                "id": "20180107-ex-4-4",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "4 rounds total"
            }
        ]
    },
    {
        "id": "20180107-block-5",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180107-ex-5-1",
                "name": "Row",
                "sequence": 1,
                "notes": "500m - moderate pace"
            },
            {
                "id": "20180107-ex-5-2",
                "name": "Ladder Drills",
                "sequence": 2,
                "notes": "2-3 patterns"
            },
            {
                "id": "20180107-ex-5-3",
                "name": "Foam Roll",
                "sequence": 3,
                "notes": "5-10 min"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 7, 2018';


-- Fix "January 9, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180109-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180109-ex-1-1",
                "name": "Bike/Row",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "20180109-ex-1-2",
                "name": "Walkouts",
                "sequence": 2,
                "notes": "Full extension"
            }
        ]
    },
    {
        "id": "20180109-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180109-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180109-ex-2-2",
                "name": "Lunge + Rotation",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180109-ex-2-3",
                "name": "Hamstring Walks",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180109-ex-2-4",
                "name": "PVC Good Mornings",
                "sequence": 4,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180109-ex-2-5",
                "name": "Air Squats",
                "sequence": 5,
                "notes": "10 - Lower body activation"
            },
            {
                "id": "20180109-ex-2-6",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "20180109-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180109-ex-3-1",
                "name": "Single Leg Deadlifts",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: TTP (Toe Touch Progression) between sets"
            },
            {
                "id": "20180109-ex-3-2",
                "name": "Single Arm BOR",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180109-block-4",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180109-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "notes": "300m - cool down pace"
            },
            {
                "id": "20180109-ex-4-2",
                "name": "Foam Roll",
                "sequence": 2,
                "notes": "5-10 min"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 9, 2018';


-- Fix "January 10, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180110-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180110-ex-1-1",
                "name": "Bear Crawl (4-way)",
                "sequence": 1,
                "notes": "Forward, back, lateral"
            },
            {
                "id": "20180110-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded or single leg"
            }
        ]
    },
    {
        "id": "20180110-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180110-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180110-ex-2-2",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180110-ex-2-3",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring mobility"
            },
            {
                "id": "20180110-ex-2-4",
                "name": "Over/Under",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180110-ex-2-5",
                "name": "SL Rotation",
                "sequence": 5,
                "notes": "Core activation"
            },
            {
                "id": "20180110-ex-2-6",
                "name": "RRL",
                "sequence": 6,
                "notes": "Hip rotation"
            }
        ]
    },
    {
        "id": "20180110-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180110-ex-3-1",
                "name": "Overhead Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: PVC/Empty bar (RPE 5). Set 2: Light (RPE 6). Set 3: Light+ (RPE 6). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Pigeon stretch between sets"
            },
            {
                "id": "20180110-ex-3-2",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child pose between sets"
            },
            {
                "id": "20180110-ex-3-3",
                "name": "KB RDL",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: HS Walk between sets"
            },
            {
                "id": "20180110-ex-3-4",
                "name": "Arm Set (Curl, Row, Press)",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "20180110-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180110-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "40 cal"
            },
            {
                "id": "20180110-ex-4-2",
                "name": "Calf Raise",
                "sequence": 2,
                "prescribed_reps": "30"
            },
            {
                "id": "20180110-ex-4-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "20e"
            },
            {
                "id": "20180110-ex-4-4",
                "name": "Farmers Carry",
                "sequence": 4,
                "prescribed_reps": "10 lengths"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 10, 2018';


-- Fix "January 11, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180111-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180111-ex-1-1",
                "name": "Bike/Row",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "20180111-ex-1-2",
                "name": "Monster Walks",
                "sequence": 2,
                "notes": "Band at ankles"
            }
        ]
    },
    {
        "id": "20180111-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180111-ex-2-1",
                "name": "Toy Soldiers",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180111-ex-2-2",
                "name": "PVC Good Morning",
                "sequence": 2,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180111-ex-2-3",
                "name": "Piriformis",
                "sequence": 3,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180111-ex-2-4",
                "name": "Hamstring Walks",
                "sequence": 4,
                "notes": "Hamstring mobility"
            },
            {
                "id": "20180111-ex-2-5",
                "name": "Lunge + Rotation",
                "sequence": 5,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180111-ex-2-6",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            },
            {
                "id": "20180111-ex-2-7",
                "name": "TRX Rows",
                "sequence": 7,
                "notes": "10 - Back activation"
            }
        ]
    },
    {
        "id": "20180111-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180111-ex-3-1",
                "name": "Negative Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1:  (RPE 7). Set 2:  (RPE 7). Set 3:  (RPE 8). Set 4:  (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "20180111-ex-3-2",
                "name": "Deadlifts",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate+ (RPE 7). Set 3: Working (RPE 7). Set 4: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: TTP between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 11, 2018';


-- Fix "January 14, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180114-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180114-ex-1-1",
                "name": "Monster Walks",
                "sequence": 1,
                "prescribed_reps": "2 lengths",
                "notes": "Band at ankles"
            },
            {
                "id": "20180114-ex-1-2",
                "name": "Jumping Jacks",
                "sequence": 2,
                "prescribed_reps": "50",
                "notes": "Elevate HR"
            }
        ]
    },
    {
        "id": "20180114-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180114-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180114-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180114-ex-2-3",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180114-ex-2-4",
                "name": "Side Lunges",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180114-ex-2-5",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180114-ex-2-6",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "20180114-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180114-ex-3-1",
                "name": "Deadlift (Building)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Working (RPE 7-8). Set 5: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: Hamstring Walk between sets"
            },
            {
                "id": "20180114-ex-3-2",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180114-block-4",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180114-ex-4-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "12 cal"
            },
            {
                "id": "20180114-ex-4-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "20180114-ex-4-3",
                "name": "Side Lunges",
                "sequence": 3,
                "prescribed_reps": "12e"
            },
            {
                "id": "20180114-ex-4-4",
                "name": "Burpees",
                "sequence": 4,
                "prescribed_reps": "12"
            },
            {
                "id": "20180114-ex-4-5",
                "name": "KB Clean",
                "sequence": 5,
                "prescribed_reps": "12e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 14, 2018';


-- Fix "January 15, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180115-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180115-ex-1-1",
                "name": "Jumping Jacks",
                "sequence": 1,
                "prescribed_reps": "20",
                "notes": "Elevate HR"
            },
            {
                "id": "20180115-ex-1-2",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_reps": "20",
                "notes": "Core activation"
            },
            {
                "id": "20180115-ex-1-3",
                "name": "Air Squats",
                "sequence": 3,
                "prescribed_reps": "20",
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "20180115-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180115-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20180115-ex-2-2",
                "name": "Hamstring Walks",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180115-ex-2-3",
                "name": "Lunge + Twist",
                "sequence": 3,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180115-ex-2-4",
                "name": "High Knee Pull",
                "sequence": 4,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180115-ex-2-5",
                "name": "Piriformis",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180115-ex-2-6",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Chest activation"
            }
        ]
    },
    {
        "id": "20180115-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180115-ex-3-1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "20180115-ex-3-2",
                "name": "KB Front Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "20180115-block-4",
        "name": "Conditioning - 12 min EMOM",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180115-ex-4-1",
                "name": "TGU",
                "sequence": 1,
                "prescribed_reps": "1e side"
            },
            {
                "id": "20180115-ex-4-2",
                "name": "Slamballs",
                "sequence": 2,
                "prescribed_reps": "15"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 15, 2018';


-- Fix "January 16, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180116-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180116-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20180116-ex-1-2",
                "name": "SL Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180116-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180116-ex-2-1",
                "name": "PVC Passovers",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180116-ex-2-2",
                "name": "PVC Good Mornings",
                "sequence": 2,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180116-ex-2-3",
                "name": "Quad Pulls",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20180116-ex-2-4",
                "name": "Lunge + Reach",
                "sequence": 4,
                "notes": "Hip flexor/t-spine"
            },
            {
                "id": "20180116-ex-2-5",
                "name": "Air Squats",
                "sequence": 5,
                "notes": "10 - Lower body activation"
            },
            {
                "id": "20180116-ex-2-6",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "20180116-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180116-ex-3-1",
                "name": "KB Clean",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: SL Hip Opener between sets"
            },
            {
                "id": "20180116-ex-3-2",
                "name": "Bent Over Row (BOR)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Working (RPE 7-8). Rest: 90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 16, 2018';


-- Fix "January 18, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180118-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180118-ex-1-1",
                "name": "Jumping Jacks",
                "sequence": 1,
                "prescribed_reps": "30",
                "notes": "Elevate HR"
            },
            {
                "id": "20180118-ex-1-2",
                "name": "Glute Bridges",
                "sequence": 2,
                "prescribed_reps": "30",
                "notes": "Glute activation"
            },
            {
                "id": "20180118-ex-1-3",
                "name": "Plank",
                "sequence": 3,
                "prescribed_reps": "30 sec",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180118-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180118-ex-2-1",
                "name": "High Knee Pulls",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180118-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180118-ex-2-3",
                "name": "Piriformis",
                "sequence": 3,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180118-ex-2-4",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180118-ex-2-5",
                "name": "Side Lunges",
                "sequence": 5,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180118-ex-2-6",
                "name": "Walkouts",
                "sequence": 6,
                "notes": "10 - Full body activation"
            }
        ]
    },
    {
        "id": "20180118-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180118-ex-3-1",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Set 5: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "20180118-ex-3-2",
                "name": "Split Squats",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 5). Set 2: Light DBs (RPE 6). Set 3: Moderate DBs (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "20180118-block-4",
        "name": "Conditioning - Circuit Style",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180118-ex-4-1",
                "name": "TRX Rows",
                "sequence": 1,
                "notes": "12-15"
            },
            {
                "id": "20180118-ex-4-2",
                "name": "KB Swings",
                "sequence": 2,
                "notes": "15-20"
            },
            {
                "id": "20180118-ex-4-3",
                "name": "Lunge + Rotate",
                "sequence": 3,
                "notes": "8e"
            },
            {
                "id": "20180118-ex-4-4",
                "name": "Farmers Carry Hold",
                "sequence": 4,
                "notes": "30-45 sec"
            },
            {
                "id": "20180118-ex-4-5",
                "name": "Slurpees",
                "sequence": 5,
                "notes": "8-10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 18, 2018';


-- Fix "January 21, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180121-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180121-ex-1-1",
                "name": "Jump Rope",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20180121-ex-1-2",
                "name": "Monster Walks",
                "sequence": 2,
                "notes": "Band at ankles"
            }
        ]
    },
    {
        "id": "20180121-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180121-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180121-ex-2-2",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180121-ex-2-3",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180121-ex-2-4",
                "name": "Over/Under Fence",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180121-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180121-ex-2-6",
                "name": "Piriformis",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180121-ex-2-7",
                "name": "Spiderman",
                "sequence": 7,
                "notes": "Hip/groin mobility"
            }
        ]
    },
    {
        "id": "20180121-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180121-ex-3-1",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Hamstring Walks between sets"
            },
            {
                "id": "20180121-ex-3-2",
                "name": "Box Jumps or Step Ups",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "25 total",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 6). Rest: 60 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "20180121-block-4",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180121-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "400m",
                "notes": "2 rounds total"
            },
            {
                "id": "20180121-ex-4-2",
                "name": "Shoulder Taps",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "25e",
                "notes": "2 rounds total"
            },
            {
                "id": "20180121-ex-4-3",
                "name": "Air Squats",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "30",
                "notes": "2 rounds total"
            },
            {
                "id": "20180121-ex-4-4",
                "name": "Deadbugs",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "25e",
                "notes": "2 rounds total"
            },
            {
                "id": "20180121-ex-4-5",
                "name": "Row",
                "sequence": 5,
                "prescribed_sets": 2,
                "prescribed_reps": "400m",
                "notes": "2 rounds total"
            },
            {
                "id": "20180121-ex-4-6",
                "name": "KB Push Press",
                "sequence": 6,
                "prescribed_sets": 2,
                "prescribed_reps": "25",
                "notes": "2 rounds total"
            },
            {
                "id": "20180121-ex-4-7",
                "name": "Sit Ups",
                "sequence": 7,
                "prescribed_sets": 2,
                "prescribed_reps": "25",
                "notes": "2 rounds total"
            },
            {
                "id": "20180121-ex-4-8",
                "name": "KB Swings",
                "sequence": 8,
                "prescribed_sets": 2,
                "prescribed_reps": "25",
                "notes": "2 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 21, 2018';


-- Fix "January 22, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180122-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180122-ex-1-1",
                "name": "Jumping Jacks",
                "sequence": 1,
                "prescribed_reps": "50",
                "notes": "Elevate HR"
            },
            {
                "id": "20180122-ex-1-2",
                "name": "SL Bridges",
                "sequence": 2,
                "prescribed_reps": "20e",
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180122-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180122-ex-2-1",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180122-ex-2-2",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180122-ex-2-3",
                "name": "Arm Circles",
                "sequence": 3,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180122-ex-2-4",
                "name": "Walkout + Push Up",
                "sequence": 4,
                "notes": "5 - Full body activation"
            },
            {
                "id": "20180122-ex-2-5",
                "name": "Spidermans",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180122-ex-2-6",
                "name": "Air Squats",
                "sequence": 6,
                "notes": "10 - Lower body activation"
            },
            {
                "id": "20180122-ex-2-7",
                "name": "Good Mornings",
                "sequence": 7,
                "notes": "10 - Hip hinge prep"
            }
        ]
    },
    {
        "id": "20180122-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180122-ex-3-1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7-8). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180122-ex-3-2",
                "name": "DB Bench Press",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Set 5: Moderate+ (RPE 8). Rest: 60-90 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 22, 2018';


-- Fix "January 23, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180123-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180123-ex-1-1",
                "name": "Walkouts + Windmills",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Full ROM"
            }
        ]
    },
    {
        "id": "20180123-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180123-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180123-ex-2-2",
                "name": "Hamstring Walks",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180123-ex-2-3",
                "name": "Bear Crawls/Quad Ped",
                "sequence": 3,
                "notes": "Core/shoulder activation"
            },
            {
                "id": "20180123-ex-2-4",
                "name": "Spidermans",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180123-ex-2-5",
                "name": "Side Lunge + Rotate",
                "sequence": 5,
                "notes": "Adductor/t-spine"
            },
            {
                "id": "20180123-ex-2-6",
                "name": "PVC Passovers",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20180123-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180123-ex-3-1",
                "name": "Deadlifts (Building)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Working (RPE 7-8). Set 5: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: TTP between sets"
            },
            {
                "id": "20180123-ex-3-2",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180123-block-4",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180123-ex-4-1",
                "name": "Wall Sit",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            },
            {
                "id": "20180123-ex-4-2",
                "name": "Side Plank",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "30 sec e",
                "notes": "3 rounds total"
            },
            {
                "id": "20180123-ex-4-3",
                "name": "Jump Rope",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "75",
                "notes": "3 rounds total"
            },
            {
                "id": "20180123-ex-4-4",
                "name": "SL Resisted Bridge",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "3 rounds total"
            }
        ]
    },
    {
        "id": "20180123-block-5",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180123-ex-5-1",
                "name": "Row",
                "sequence": 1,
                "notes": "500m cool down"
            },
            {
                "id": "20180123-ex-5-2",
                "name": "Foam Roll",
                "sequence": 2,
                "notes": "5-10 min"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 23, 2018';


-- Fix "January 25, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180125-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180125-ex-1-1",
                "name": "Bear Crawls",
                "sequence": 1,
                "prescribed_reps": "2 lengths",
                "notes": "Forward and back"
            }
        ]
    },
    {
        "id": "20180125-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180125-ex-2-1",
                "name": "Hip Openers/Closers",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180125-ex-2-2",
                "name": "Arm Circles",
                "sequence": 2,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180125-ex-2-3",
                "name": "High Knee Pulls",
                "sequence": 3,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180125-ex-2-4",
                "name": "High Knee Skips",
                "sequence": 4,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180125-ex-2-5",
                "name": "PVC Figure 8''s",
                "sequence": 5,
                "notes": "T-spine/shoulder"
            },
            {
                "id": "20180125-ex-2-6",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "20180125-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180125-ex-3-1",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8-10 AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20180125-ex-3-2",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "20180125-block-4",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180125-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "300m",
                "notes": "4 rounds total"
            },
            {
                "id": "20180125-ex-4-2",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "4 rounds total"
            },
            {
                "id": "20180125-ex-4-3",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            },
            {
                "id": "20180125-ex-4-4",
                "name": "\u00bd Kneel Chops",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 25, 2018';


-- Fix "January 26, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180126-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180126-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_reps": "3 x 10",
                "notes": "Glute activation"
            },
            {
                "id": "20180126-ex-1-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_reps": "20e",
                "notes": "Core activation"
            },
            {
                "id": "20180126-ex-1-3",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_reps": "20",
                "notes": "Back activation"
            }
        ]
    },
    {
        "id": "20180126-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180126-ex-2-1",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/glute"
            },
            {
                "id": "20180126-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180126-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180126-ex-2-4",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180126-ex-2-5",
                "name": "Pigeon/Piriformis",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180126-ex-2-6",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "20180126-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180126-ex-3-1",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            },
            {
                "id": "20180126-ex-3-2",
                "name": "Strict Press",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate+ (RPE 7). Set 3: Working (RPE 7). Set 4: Working (RPE 8). Set 5: Working (RPE 8). Rest: 2-3 min between sets Accessory: Figure 8 between sets"
            }
        ]
    },
    {
        "id": "20180126-block-4",
        "name": "Conditioning - Core EMOM (12 min)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180126-ex-4-1",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "10"
            },
            {
                "id": "20180126-ex-4-2",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "20180126-ex-4-3",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_reps": "8"
            },
            {
                "id": "20180126-ex-4-4",
                "name": "Dead Bugs",
                "sequence": 4,
                "prescribed_reps": "10e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 26, 2018';


-- Fix "January 28, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180128-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180128-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "10 cal",
                "notes": "Moderate pace"
            },
            {
                "id": "20180128-ex-1-2",
                "name": "Monster Walks",
                "sequence": 2,
                "prescribed_reps": "2 lengths",
                "notes": "Band at ankles"
            },
            {
                "id": "20180128-ex-1-3",
                "name": "Push Ups",
                "sequence": 3,
                "prescribed_reps": "10",
                "notes": "Activation"
            }
        ]
    },
    {
        "id": "20180128-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180128-ex-2-1",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180128-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180128-ex-2-3",
                "name": "Side Lunges",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180128-ex-2-4",
                "name": "Piriformis",
                "sequence": 4,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180128-ex-2-5",
                "name": "Hip Openers",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180128-ex-2-6",
                "name": "PVC Passovers",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20180128-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180128-ex-3-1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180128-ex-3-2",
                "name": "SA DB Bench Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    },
    {
        "id": "20180128-block-4",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180128-ex-4-1",
                "name": "HKTC",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "20180128-ex-4-2",
                "name": "KB Swings",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "20180128-ex-4-3",
                "name": "Goblet Squats",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "20180128-ex-4-4",
                "name": "SA BOR (KB)",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "15e",
                "notes": "3 rounds total"
            },
            {
                "id": "20180128-ex-4-5",
                "name": "Russian Twists",
                "sequence": 5,
                "prescribed_sets": 3,
                "prescribed_reps": "15e",
                "notes": "3 rounds total"
            }
        ]
    },
    {
        "id": "20180128-block-5",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180128-ex-5-1",
                "name": "Battle Ropes",
                "sequence": 1,
                "prescribed_reps": "30 sec"
            },
            {
                "id": "20180128-ex-5-2",
                "name": "Foam Roll",
                "sequence": 2,
                "prescribed_reps": "5-10 min"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 28, 2018';


-- Fix "January 30, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180130-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180130-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "20180130-ex-1-2",
                "name": "SL Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20180130-ex-1-3",
                "name": "TRX Rows",
                "sequence": 3,
                "notes": "Back activation"
            }
        ]
    },
    {
        "id": "20180130-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180130-ex-2-1",
                "name": "Toy Soldiers",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180130-ex-2-2",
                "name": "Lunge + Rotate",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180130-ex-2-3",
                "name": "PVC Figure 8''s",
                "sequence": 3,
                "notes": "Shoulder/t-spine"
            },
            {
                "id": "20180130-ex-2-4",
                "name": "PVC Good Mornings",
                "sequence": 4,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180130-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180130-ex-2-6",
                "name": "Bear Crawls",
                "sequence": 6,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180130-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180130-ex-3-1",
                "name": "BB Slant Bar Twist",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: SL Rotation between sets"
            },
            {
                "id": "20180130-ex-3-2",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 5). Set 2: Light DBs (RPE 6). Set 3: Moderate DBs (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "20180130-block-4",
        "name": "Conditioning - 20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180130-ex-4-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "10 cal"
            },
            {
                "id": "20180130-ex-4-2",
                "name": "Split Squat",
                "sequence": 2,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180130-ex-4-3",
                "name": "TGU",
                "sequence": 3,
                "prescribed_reps": "5e"
            },
            {
                "id": "20180130-ex-4-4",
                "name": "Russian Twists",
                "sequence": 4,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180130-ex-4-5",
                "name": "Burpees",
                "sequence": 5,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 30, 2018';


-- Fix "January 31, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180131-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180131-ex-1-1",
                "name": "Monsters",
                "sequence": 1,
                "prescribed_reps": "2 lengths",
                "notes": "Band at ankles"
            },
            {
                "id": "20180131-ex-1-2",
                "name": "Banded Bridge",
                "sequence": 2,
                "prescribed_reps": "3 x 10",
                "notes": "Glute activation"
            },
            {
                "id": "20180131-ex-1-3",
                "name": "Banded Squat",
                "sequence": 3,
                "prescribed_reps": "3 x 10",
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "20180131-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180131-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180131-ex-2-2",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180131-ex-2-3",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring mobility"
            },
            {
                "id": "20180131-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180131-ex-2-5",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180131-ex-2-6",
                "name": "SL Rotation",
                "sequence": 6,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180131-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180131-ex-3-1",
                "name": "Turkish Get Up (TGU)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: SL Rotation between sets"
            },
            {
                "id": "20180131-ex-3-2",
                "name": "Slant Bar 3 Ext.",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Pigeon stretch between sets"
            },
            {
                "id": "20180131-ex-3-3",
                "name": "Slant Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "20180131-ex-3-4",
                "name": "Arm Set (Curl, Row, Press)",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: PVC Pass between sets"
            }
        ]
    },
    {
        "id": "20180131-block-4",
        "name": "Conditioning",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180131-ex-4-1",
                "name": "Row 500m OR Shuttle 300m",
                "sequence": 1,
                "notes": "Timed effort"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 31, 2018';


-- Fix "February 1, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180201-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180201-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20180201-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded or single leg"
            }
        ]
    },
    {
        "id": "20180201-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180201-ex-2-1",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/glute activation"
            },
            {
                "id": "20180201-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180201-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180201-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180201-ex-2-5",
                "name": "Push Up W/O",
                "sequence": 5,
                "notes": "Upper body activation"
            },
            {
                "id": "20180201-ex-2-6",
                "name": "Pigeon/Piriformis",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "20180201-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180201-ex-3-1",
                "name": "Lunge (3-way)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "12 total",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20180201-ex-3-2",
                "name": "SA Row",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180201-block-4",
        "name": "Core Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180201-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "250m"
            },
            {
                "id": "20180201-ex-4-2",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "20180201-ex-4-3",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_reps": "12"
            },
            {
                "id": "20180201-ex-4-4",
                "name": "Dead Bugs",
                "sequence": 4,
                "prescribed_reps": "15e"
            },
            {
                "id": "20180201-ex-4-5",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "250m"
            },
            {
                "id": "20180201-ex-4-6",
                "name": "Push Press",
                "sequence": 6,
                "prescribed_reps": "10"
            },
            {
                "id": "20180201-ex-4-7",
                "name": "Sit Ups",
                "sequence": 7,
                "prescribed_reps": "12"
            },
            {
                "id": "20180201-ex-4-8",
                "name": "TRX Row",
                "sequence": 8,
                "prescribed_reps": "15"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 1, 2018';


-- Fix "February 4, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180204-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180204-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "20180204-ex-1-2",
                "name": "Push Ups",
                "sequence": 2,
                "notes": "Upper body activation"
            },
            {
                "id": "20180204-ex-1-3",
                "name": "Sit Ups",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180204-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180204-ex-2-1",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180204-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180204-ex-2-3",
                "name": "Piriformis",
                "sequence": 3,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180204-ex-2-4",
                "name": "Rev. Lunge + Reach",
                "sequence": 4,
                "notes": "Hip flexor/t-spine"
            },
            {
                "id": "20180204-ex-2-5",
                "name": "PVC Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180204-ex-2-6",
                "name": "Bear Crawls",
                "sequence": 6,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180204-block-3",
        "name": "Intro - 9 min EMOM",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180204-ex-3-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "10 cal"
            },
            {
                "id": "20180204-ex-3-2",
                "name": "BB Deadlift",
                "sequence": 2,
                "prescribed_reps": "15"
            },
            {
                "id": "20180204-ex-3-3",
                "name": "Bar Over Burpees",
                "sequence": 3,
                "prescribed_reps": "10"
            }
        ]
    },
    {
        "id": "20180204-block-4",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180204-ex-4-1",
                "name": "Deadbugs",
                "sequence": 1,
                "prescribed_reps": "12e"
            },
            {
                "id": "20180204-ex-4-2",
                "name": "Step Ups",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "20180204-ex-4-3",
                "name": "Farmer''s Carry",
                "sequence": 3,
                "prescribed_reps": "3 laps"
            },
            {
                "id": "20180204-ex-4-4",
                "name": "MB Chops",
                "sequence": 4,
                "prescribed_reps": "12e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 4, 2018';


-- Fix "February 5, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180205-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180205-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "20180205-ex-1-2",
                "name": "Jumping Jacks",
                "sequence": 2,
                "notes": "Elevate HR"
            }
        ]
    },
    {
        "id": "20180205-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180205-ex-2-1",
                "name": "Piriformis",
                "sequence": 1,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180205-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180205-ex-2-3",
                "name": "Side Lunges",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180205-ex-2-4",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180205-ex-2-5",
                "name": "High Knee Pull",
                "sequence": 5,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180205-ex-2-6",
                "name": "Over/Under Fence",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "20180205-ex-2-7",
                "name": "Push Ups",
                "sequence": 7,
                "notes": "10 - Chest activation"
            },
            {
                "id": "20180205-ex-2-8",
                "name": "Glute Bridges",
                "sequence": 8,
                "notes": "30 - Glute activation"
            }
        ]
    },
    {
        "id": "20180205-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180205-ex-3-1",
                "name": "DB Bench (Heavy)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "6",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Set 4: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "20180205-ex-3-2",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180205-ex-3-3",
                "name": "Chin Up \"Active Hang\"",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "",
                "notes": "Set 1:  (RPE 7). Set 2:  (RPE 8). Rest: 90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 5, 2018';


-- Fix "February 6, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180206-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180206-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "1 min",
                "notes": "Easy pace"
            },
            {
                "id": "20180206-ex-1-2",
                "name": "Jump Rope",
                "sequence": 2,
                "prescribed_reps": "1 min",
                "notes": "Moderate pace"
            },
            {
                "id": "20180206-ex-1-3",
                "name": "Plank",
                "sequence": 3,
                "prescribed_reps": "1 min",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180206-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180206-ex-2-1",
                "name": "Arm Circles",
                "sequence": 1,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180206-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180206-ex-2-3",
                "name": "Hamstring Walks",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180206-ex-2-4",
                "name": "Lunge + Reach",
                "sequence": 4,
                "notes": "Hip flexor/t-spine"
            },
            {
                "id": "20180206-ex-2-5",
                "name": "Spidermans",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180206-ex-2-6",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            },
            {
                "id": "20180206-ex-2-7",
                "name": "Air Squats",
                "sequence": 7,
                "notes": "20 - Lower body activation"
            }
        ]
    },
    {
        "id": "20180206-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180206-ex-3-1",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20180206-ex-3-2",
                "name": "Deadlifts (Building)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "20180206-block-4",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180206-ex-4-1",
                "name": "Step Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "4 rounds total"
            },
            {
                "id": "20180206-ex-4-2",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            },
            {
                "id": "20180206-ex-4-3",
                "name": "KB Swings",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            },
            {
                "id": "20180206-ex-4-4",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 6, 2018';


-- Fix "February 8, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180208-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180208-ex-1-1",
                "name": "Push Ups",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Chest activation"
            },
            {
                "id": "20180208-ex-1-2",
                "name": "Air Squats",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Lower body activation"
            },
            {
                "id": "20180208-ex-1-3",
                "name": "Jumping Jacks",
                "sequence": 3,
                "prescribed_reps": "30",
                "notes": "Elevate HR"
            }
        ]
    },
    {
        "id": "20180208-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180208-ex-2-1",
                "name": "Lunge + Twist",
                "sequence": 1,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180208-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180208-ex-2-3",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180208-ex-2-4",
                "name": "PVC Passovers",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180208-ex-2-5",
                "name": "PVC Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180208-ex-2-6",
                "name": "High Knee Skip",
                "sequence": 6,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180208-ex-2-7",
                "name": "Pigeon",
                "sequence": 7,
                "notes": "Hip opener"
            }
        ]
    },
    {
        "id": "20180208-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180208-ex-3-1",
                "name": "Single Leg Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Bodyweight/Light (RPE 7). Set 3: Light (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180208-ex-3-2",
                "name": "Negative Push Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1:  (RPE 6). Set 2:  (RPE 7). Set 3:  (RPE 7). Set 4:  (RPE 8). Rest: 60-90 sec between sets Accessory: Foam Angels between sets"
            }
        ]
    },
    {
        "id": "20180208-block-4",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180208-ex-4-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "12 cal",
                "notes": "2 rounds total"
            },
            {
                "id": "20180208-ex-4-2",
                "name": "MB Toe Taps",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "20180208-ex-4-3",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "20180208-ex-4-4",
                "name": "Row/Bike",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "12 cal",
                "notes": "2 rounds total"
            },
            {
                "id": "20180208-ex-4-5",
                "name": "Deadbugs",
                "sequence": 5,
                "prescribed_sets": 2,
                "prescribed_reps": "12e",
                "notes": "2 rounds total"
            },
            {
                "id": "20180208-ex-4-6",
                "name": "KB Swings",
                "sequence": 6,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "20180208-ex-4-7",
                "name": "Row/Bike",
                "sequence": 7,
                "prescribed_sets": 2,
                "prescribed_reps": "12 cal",
                "notes": "2 rounds total"
            },
            {
                "id": "20180208-ex-4-8",
                "name": "Box Jump/Step Up",
                "sequence": 8,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "20180208-ex-4-9",
                "name": "TRX Rows",
                "sequence": 9,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 8, 2018';


-- Fix "February 9, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180209-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180209-ex-1-1",
                "name": "Row/Jump Rope",
                "sequence": 1,
                "notes": "Easy pace warm-up"
            },
            {
                "id": "20180209-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded or SL variation"
            }
        ]
    },
    {
        "id": "20180209-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180209-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180209-ex-2-2",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180209-ex-2-3",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180209-ex-2-4",
                "name": "HS Walk",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180209-ex-2-5",
                "name": "Push Up W/O",
                "sequence": 5,
                "notes": "Upper body activation"
            },
            {
                "id": "20180209-ex-2-6",
                "name": "90s Robot",
                "sequence": 6,
                "notes": "T-spine mobility"
            }
        ]
    },
    {
        "id": "20180209-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180209-ex-3-1",
                "name": "Single Leg Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180209-ex-3-2",
                "name": "Bent Over Row (BOR)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180209-block-4",
        "name": "Conditioning - Chipper",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180209-ex-4-1",
                "name": "Slamballs",
                "sequence": 1,
                "prescribed_reps": "30"
            },
            {
                "id": "20180209-ex-4-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "30e"
            },
            {
                "id": "20180209-ex-4-3",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_reps": "30"
            },
            {
                "id": "20180209-ex-4-4",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_reps": "30"
            },
            {
                "id": "20180209-ex-4-5",
                "name": "TRX Row",
                "sequence": 5,
                "prescribed_reps": "30"
            },
            {
                "id": "20180209-ex-4-6",
                "name": "Push Ups",
                "sequence": 6,
                "prescribed_reps": "30"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 9, 2018';


-- Fix "February 11, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180211-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180211-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "20180211-ex-1-2",
                "name": "Monster Walks",
                "sequence": 2,
                "notes": "Band at ankles"
            }
        ]
    },
    {
        "id": "20180211-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180211-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180211-ex-2-2",
                "name": "SL Hinge Quad Pull",
                "sequence": 2,
                "notes": "Hip hinge/quad prep"
            },
            {
                "id": "20180211-ex-2-3",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180211-ex-2-4",
                "name": "Over/Under Fence",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180211-ex-2-5",
                "name": "Piriformis",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180211-ex-2-6",
                "name": "PVC Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180211-ex-2-7",
                "name": "Rev. Lunge + Reach",
                "sequence": 7,
                "notes": "T-spine mobility"
            }
        ]
    },
    {
        "id": "20180211-block-3",
        "name": "Intro - 9 min EMOM",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180211-ex-3-1",
                "name": "Snow Angels",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180211-ex-3-2",
                "name": "Row/Bike",
                "sequence": 2,
                "notes": "Moderate pace"
            },
            {
                "id": "20180211-ex-3-3",
                "name": "Sit Ups",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180211-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180211-ex-4-1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "20180211-block-5",
        "name": "Conditioning - 12 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180211-ex-5-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m"
            },
            {
                "id": "20180211-ex-5-2",
                "name": "Push Press",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "20180211-ex-5-3",
                "name": "SA KB Swing",
                "sequence": 3,
                "prescribed_reps": "8e"
            },
            {
                "id": "20180211-ex-5-4",
                "name": "V Ups",
                "sequence": 4,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 11, 2018';


-- Fix "February 13, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180213-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180213-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20180213-ex-1-2",
                "name": "Inchworms",
                "sequence": 2,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "20180213-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180213-ex-2-1",
                "name": "Bear Crawls",
                "sequence": 1,
                "notes": "Core/coordination"
            },
            {
                "id": "20180213-ex-2-2",
                "name": "Hamstring Walks",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180213-ex-2-3",
                "name": "SL Hinge Quad Pull",
                "sequence": 3,
                "notes": "Hip hinge/quad prep"
            },
            {
                "id": "20180213-ex-2-4",
                "name": "Spidermans",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180213-ex-2-5",
                "name": "Side Lunges",
                "sequence": 5,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180213-ex-2-6",
                "name": "PVC Figure 8''s",
                "sequence": 6,
                "notes": "T-spine/shoulder"
            },
            {
                "id": "20180213-ex-2-7",
                "name": "Butt Kicks",
                "sequence": 7,
                "notes": "Quad activation"
            },
            {
                "id": "20180213-ex-2-8",
                "name": "Air Squats",
                "sequence": 8,
                "notes": "30 - Lower body prep"
            }
        ]
    },
    {
        "id": "20180213-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180213-ex-3-1",
                "name": "Lateral Step Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180213-ex-3-2",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180213-block-4",
        "name": "Conditioning - Bodyweight Chipper",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180213-ex-4-1",
                "name": "TGU",
                "sequence": 1,
                "prescribed_reps": "5e"
            },
            {
                "id": "20180213-ex-4-2",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_reps": "20"
            },
            {
                "id": "20180213-ex-4-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "20e"
            },
            {
                "id": "20180213-ex-4-4",
                "name": "Air Squats",
                "sequence": 4,
                "prescribed_reps": "100"
            },
            {
                "id": "20180213-ex-4-5",
                "name": "Push Ups",
                "sequence": 5,
                "prescribed_reps": "20"
            },
            {
                "id": "20180213-ex-4-6",
                "name": "Rev. Lunges",
                "sequence": 6,
                "prescribed_reps": "20e"
            },
            {
                "id": "20180213-ex-4-7",
                "name": "Mountain Climbers",
                "sequence": 7,
                "prescribed_reps": "50e"
            },
            {
                "id": "20180213-ex-4-8",
                "name": "SL Bridges",
                "sequence": 8,
                "prescribed_reps": "20e"
            },
            {
                "id": "20180213-ex-4-9",
                "name": "Monkey Bars",
                "sequence": 9,
                "prescribed_reps": "Full length"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 13, 2018';


-- Fix "February 14, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180214-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180214-ex-1-1",
                "name": "Bear Crawls",
                "sequence": 1,
                "notes": "Forward and back"
            },
            {
                "id": "20180214-ex-1-2",
                "name": "Row/Bike",
                "sequence": 2,
                "notes": "Easy pace"
            }
        ]
    },
    {
        "id": "20180214-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180214-ex-2-1",
                "name": "Hip Openers/Closers",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180214-ex-2-2",
                "name": "High Knee Pulls",
                "sequence": 2,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180214-ex-2-3",
                "name": "Quad Pulls",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20180214-ex-2-4",
                "name": "Piriformis",
                "sequence": 4,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180214-ex-2-5",
                "name": "Hamstring Walks",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180214-ex-2-6",
                "name": "Air Squats",
                "sequence": 6,
                "notes": "10 - Lower body prep"
            },
            {
                "id": "20180214-ex-2-7",
                "name": "Push Ups",
                "sequence": 7,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "20180214-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180214-ex-3-1",
                "name": "Slant Bar Twist",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: SL Rotation between sets"
            },
            {
                "id": "20180214-ex-3-2",
                "name": "Slant Bar 3 Ext.",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Pigeon stretch between sets"
            }
        ]
    },
    {
        "id": "20180214-block-4",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180214-ex-4-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "300m/600m",
                "notes": "4 rounds total"
            },
            {
                "id": "20180214-ex-4-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "4 rounds total"
            },
            {
                "id": "20180214-ex-4-3",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            },
            {
                "id": "20180214-ex-4-4",
                "name": "\u00bd Knee Chops",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "4 rounds total"
            }
        ]
    },
    {
        "id": "20180214-block-5",
        "name": "Cash Out",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180214-ex-5-1",
                "name": "Hill Sprints/Cone Drills",
                "sequence": 1,
                "prescribed_reps": "10 min",
                "notes": "High intensity finish"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 14, 2018';


-- Fix "February 15, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180215-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180215-ex-1-1",
                "name": "Clam Shells",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20180215-ex-1-2",
                "name": "Seated Wall Angels",
                "sequence": 2,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20180215-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180215-ex-2-1",
                "name": "Lunge + Reach",
                "sequence": 1,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180215-ex-2-2",
                "name": "Spidermans",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180215-ex-2-3",
                "name": "Quad Pulls",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20180215-ex-2-4",
                "name": "Hip Openers/Closers",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180215-ex-2-5",
                "name": "PVC Passovers",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180215-ex-2-6",
                "name": "PVC Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180215-ex-2-7",
                "name": "Karaoke",
                "sequence": 7,
                "notes": "Hip/coordination"
            }
        ]
    },
    {
        "id": "20180215-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180215-ex-3-1",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20180215-ex-3-2",
                "name": "SA KB Clean",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lateral Plank Walks x 2 between sets"
            }
        ]
    },
    {
        "id": "20180215-block-4",
        "name": "Cash Out",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180215-ex-4-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Steady pace cooldown"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 15, 2018';


-- Fix "February 18, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180218-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180218-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "20180218-ex-1-2",
                "name": "Sit Ups",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "20180218-ex-1-3",
                "name": "Push Ups",
                "sequence": 3,
                "notes": "Upper body activation"
            },
            {
                "id": "20180218-ex-1-4",
                "name": "Air Squats",
                "sequence": 4,
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "20180218-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180218-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180218-ex-2-2",
                "name": "Toy Soldiers",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180218-ex-2-3",
                "name": "SL Hinge Quad Pull",
                "sequence": 3,
                "notes": "Hip hinge/quad prep"
            },
            {
                "id": "20180218-ex-2-4",
                "name": "Over/Under Fence",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180218-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180218-ex-2-6",
                "name": "High Knee Skip",
                "sequence": 6,
                "notes": "Dynamic warm-up"
            }
        ]
    },
    {
        "id": "20180218-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180218-ex-3-1",
                "name": "Single Leg Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180218-ex-3-2",
                "name": "DB Bench Press",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate+ (RPE 7). Set 3: Heavy (RPE 7). Set 4: Heavy+ (RPE 8). Rest: 90 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    },
    {
        "id": "20180218-block-4",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180218-ex-4-1",
                "name": "Goblet Squats",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "20180218-ex-4-2",
                "name": "Push Press",
                "sequence": 2,
                "prescribed_reps": "15"
            },
            {
                "id": "20180218-ex-4-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "15e"
            },
            {
                "id": "20180218-ex-4-4",
                "name": "Pull Ups/TRX Rows",
                "sequence": 4,
                "prescribed_reps": "15"
            },
            {
                "id": "20180218-ex-4-5",
                "name": "Snow Angels",
                "sequence": 5,
                "prescribed_reps": "15"
            },
            {
                "id": "20180218-ex-4-6",
                "name": "Ball Ham Curls",
                "sequence": 6,
                "prescribed_reps": "15"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 18, 2018';


-- Fix "February 20, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180220-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180220-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "20180220-ex-1-2",
                "name": "SL Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180220-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180220-ex-2-1",
                "name": "Hip Openers",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180220-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180220-ex-2-3",
                "name": "Arm Circles",
                "sequence": 3,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180220-ex-2-4",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180220-ex-2-5",
                "name": "High Knee Pulls",
                "sequence": 5,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180220-ex-2-6",
                "name": "Butt Kicks",
                "sequence": 6,
                "notes": "Quad activation"
            },
            {
                "id": "20180220-ex-2-7",
                "name": "Walkout + Windmill",
                "sequence": 7,
                "notes": "5 - Full body activation"
            },
            {
                "id": "20180220-ex-2-8",
                "name": "Lunge + Reach",
                "sequence": 8,
                "notes": "T-spine mobility"
            }
        ]
    },
    {
        "id": "20180220-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180220-ex-3-1",
                "name": "Bench Press",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy+ (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "20180220-ex-3-2",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Moderate (RPE 7). Rest: As needed between sides Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "20180220-block-4",
        "name": "Conditioning - 20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180220-ex-4-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "20 cal"
            },
            {
                "id": "20180220-ex-4-2",
                "name": "MB Toe Taps",
                "sequence": 2,
                "prescribed_reps": "20"
            },
            {
                "id": "20180220-ex-4-3",
                "name": "TRX Rows",
                "sequence": 3,
                "prescribed_reps": "20"
            },
            {
                "id": "20180220-ex-4-4",
                "name": "Walking Lunge",
                "sequence": 4,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180220-ex-4-5",
                "name": "Shoulder Taps",
                "sequence": 5,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180220-ex-4-6",
                "name": "Deadlifts",
                "sequence": 6,
                "prescribed_reps": "20"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 20, 2018';


-- Fix "February 22, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180222-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180222-ex-1-1",
                "name": "Jump Rope",
                "sequence": 1,
                "notes": "OR Row 500m"
            }
        ]
    },
    {
        "id": "20180222-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180222-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180222-ex-2-2",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180222-ex-2-3",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180222-ex-2-4",
                "name": "Push Up W/O",
                "sequence": 4,
                "notes": "Upper body activation"
            },
            {
                "id": "20180222-ex-2-5",
                "name": "RRL",
                "sequence": 5,
                "notes": "Rotational prep"
            },
            {
                "id": "20180222-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "20180222-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180222-ex-3-1",
                "name": "Bridge (Activation)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded or SL (RPE 5). Set 2: Banded or SL (RPE 5). Set 3: Banded or SL (RPE 5)"
            },
            {
                "id": "20180222-ex-3-2",
                "name": "Push Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Figure 8 between sets"
            },
            {
                "id": "20180222-ex-3-3",
                "name": "Good Mornings",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: TTP (Touch the Post) between sets"
            }
        ]
    },
    {
        "id": "20180222-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180222-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "250m"
            },
            {
                "id": "20180222-ex-4-2",
                "name": "Lunges",
                "sequence": 2,
                "prescribed_reps": "8e"
            },
            {
                "id": "20180222-ex-4-3",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_reps": "12"
            },
            {
                "id": "20180222-ex-4-4",
                "name": "\u00bd Knee Chop",
                "sequence": 4,
                "prescribed_reps": "8e"
            },
            {
                "id": "20180222-ex-4-5",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "250m"
            },
            {
                "id": "20180222-ex-4-6",
                "name": "Slamball",
                "sequence": 6,
                "prescribed_reps": "10"
            },
            {
                "id": "20180222-ex-4-7",
                "name": "Russian Twist",
                "sequence": 7,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180222-ex-4-8",
                "name": "Burpees",
                "sequence": 8,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 22, 2018';


-- Fix "February 23, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180223-block-1",
        "name": "Active - x3 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180223-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Glute activation"
            },
            {
                "id": "20180223-ex-1-2",
                "name": "Starfish",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Core activation"
            },
            {
                "id": "20180223-ex-1-3",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "Back activation"
            }
        ]
    },
    {
        "id": "20180223-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180223-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180223-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180223-ex-2-3",
                "name": "Over/Under",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180223-ex-2-4",
                "name": "HS Walk",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180223-ex-2-5",
                "name": "Bear Crawl",
                "sequence": 5,
                "notes": "5 - Core/coordination"
            },
            {
                "id": "20180223-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "20180223-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180223-ex-3-1",
                "name": "Turkish Get Up (TGU)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: SL Rotation between sets"
            },
            {
                "id": "20180223-ex-3-2",
                "name": "Single Leg Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "20180223-block-4",
        "name": "Conditioning - Core Chipper",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180223-ex-4-1",
                "name": "TGU",
                "sequence": 1,
                "prescribed_reps": "5e"
            },
            {
                "id": "20180223-ex-4-2",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_reps": "20"
            },
            {
                "id": "20180223-ex-4-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "15e"
            },
            {
                "id": "20180223-ex-4-4",
                "name": "SL Bridge",
                "sequence": 4,
                "prescribed_reps": "20e"
            },
            {
                "id": "20180223-ex-4-5",
                "name": "Air Squat",
                "sequence": 5,
                "prescribed_reps": "100"
            },
            {
                "id": "20180223-ex-4-6",
                "name": "Shoulder Tap",
                "sequence": 6,
                "prescribed_reps": "20e"
            },
            {
                "id": "20180223-ex-4-7",
                "name": "Back Lunge",
                "sequence": 7,
                "prescribed_reps": "15e"
            },
            {
                "id": "20180223-ex-4-8",
                "name": "Sit Ups",
                "sequence": 8,
                "prescribed_reps": "20"
            },
            {
                "id": "20180223-ex-4-9",
                "name": "Push Ups",
                "sequence": 9,
                "prescribed_reps": "10"
            },
            {
                "id": "20180223-ex-4-10",
                "name": "Wall Sit",
                "sequence": 10,
                "prescribed_reps": "60 sec"
            },
            {
                "id": "20180223-ex-4-11",
                "name": "Plank",
                "sequence": 11,
                "prescribed_reps": "60 sec"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 23, 2018';


-- Fix "February 25, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180225-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180225-ex-1-1",
                "name": "Push Ups",
                "sequence": 1,
                "notes": "Upper body activation"
            },
            {
                "id": "20180225-ex-1-2",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "Lower body prep"
            },
            {
                "id": "20180225-ex-1-3",
                "name": "Side Plank",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180225-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180225-ex-2-1",
                "name": "Lunge + Rotate",
                "sequence": 1,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180225-ex-2-2",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180225-ex-2-3",
                "name": "High Knee Skip",
                "sequence": 3,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180225-ex-2-4",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180225-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180225-ex-2-6",
                "name": "Glute Bridges",
                "sequence": 6,
                "notes": "30 - Glute activation"
            }
        ]
    },
    {
        "id": "20180225-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180225-ex-3-1",
                "name": "KB Front Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180225-ex-3-2",
                "name": "KB SA Bent Over Row (BOR)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 25, 2018';


-- Fix "February 27, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180227-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180227-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20180227-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20180227-ex-1-3",
                "name": "Plank",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180227-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180227-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20180227-ex-2-2",
                "name": "Hi Touch/Lo Touch",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180227-ex-2-3",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180227-ex-2-4",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180227-ex-2-5",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180227-ex-2-6",
                "name": "Pigeon/Piriformis",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "20180227-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180227-ex-3-1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "20180227-ex-3-2",
                "name": "3-Way Lunge",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "20180227-block-4",
        "name": "Conditioning - 20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180227-ex-4-1",
                "name": "Split Squat",
                "sequence": 1,
                "prescribed_reps": "8e"
            },
            {
                "id": "20180227-ex-4-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180227-ex-4-3",
                "name": "Renegade Row",
                "sequence": 3,
                "prescribed_reps": "8e"
            },
            {
                "id": "20180227-ex-4-4",
                "name": "Slamballs",
                "sequence": 4,
                "prescribed_reps": "10"
            },
            {
                "id": "20180227-ex-4-5",
                "name": "Cal Row",
                "sequence": 5,
                "prescribed_reps": "10"
            }
        ]
    },
    {
        "id": "20180227-block-5",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180227-ex-5-1",
                "name": "Battle Ropes",
                "sequence": 1,
                "prescribed_reps": "30 sec on/30 sec off x 3",
                "notes": "Max effort"
            },
            {
                "id": "20180227-ex-5-2",
                "name": "Foam Roll",
                "sequence": 2,
                "prescribed_reps": "5-10 min",
                "notes": "Full body"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 27, 2018';


-- Fix "February 28, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180228-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180228-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20180228-ex-1-2",
                "name": "Jumping Jacks",
                "sequence": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "20180228-ex-1-3",
                "name": "Snow Angels",
                "sequence": 3,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20180228-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180228-ex-2-1",
                "name": "Piriformis",
                "sequence": 1,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180228-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180228-ex-2-3",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180228-ex-2-4",
                "name": "Side Lunges",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180228-ex-2-5",
                "name": "Over/Under Fence",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180228-ex-2-6",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "20180228-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180228-ex-3-1",
                "name": "DB Bench Press (Heavy)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "6",
                "notes": "Set 1: Heavy (RPE 6). Set 2: Heavy (RPE 7). Set 3: Heavy+ (RPE 8). Set 4: Heavy+ (RPE 8). Rest: 2 min between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "20180228-ex-3-2",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 28, 2018';


-- Fix "March 1, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180301-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180301-ex-1-1",
                "name": "Push Ups",
                "sequence": 1,
                "notes": "Upper body activation"
            },
            {
                "id": "20180301-ex-1-2",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "Lower body prep"
            },
            {
                "id": "20180301-ex-1-3",
                "name": "Jumping Jacks",
                "sequence": 3,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180301-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180301-ex-2-1",
                "name": "PVC Passovers",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180301-ex-2-2",
                "name": "PVC Good Mornings",
                "sequence": 2,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180301-ex-2-3",
                "name": "Side Lunges",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180301-ex-2-4",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180301-ex-2-5",
                "name": "High Knee Pulls",
                "sequence": 5,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180301-ex-2-6",
                "name": "Over/Under Fence",
                "sequence": 6,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "20180301-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180301-ex-3-1",
                "name": "MB Clean Progressions",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: T-Spine on Roller between sets"
            },
            {
                "id": "20180301-ex-3-2",
                "name": "Side Plank",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": "Set 1:  (RPE 6). Set 2:  (RPE 6). Set 3:  (RPE 7)"
            }
        ]
    },
    {
        "id": "20180301-block-4",
        "name": "Conditioning - 20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180301-ex-4-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "30 cal"
            },
            {
                "id": "20180301-ex-4-2",
                "name": "HKTC",
                "sequence": 2,
                "prescribed_reps": "30"
            },
            {
                "id": "20180301-ex-4-3",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_reps": "30"
            },
            {
                "id": "20180301-ex-4-4",
                "name": "Bike/Row",
                "sequence": 4,
                "prescribed_reps": "30 cal"
            },
            {
                "id": "20180301-ex-4-5",
                "name": "KB Swings",
                "sequence": 5,
                "prescribed_reps": "30"
            },
            {
                "id": "20180301-ex-4-6",
                "name": "Shoulder Taps",
                "sequence": 6,
                "prescribed_reps": "30e"
            },
            {
                "id": "20180301-ex-4-7",
                "name": "Bike/Row",
                "sequence": 7,
                "prescribed_reps": "30 cal"
            },
            {
                "id": "20180301-ex-4-8",
                "name": "Box Jump/Step Ups",
                "sequence": 8,
                "prescribed_reps": "30"
            },
            {
                "id": "20180301-ex-4-9",
                "name": "TRX Rows",
                "sequence": 9,
                "prescribed_reps": "30"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 1, 2018';


-- Fix "March 5, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 45,
    exercises = '[
    {
        "id": "20180305-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180305-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20180305-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20180305-ex-1-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180305-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180305-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180305-ex-2-2",
                "name": "Lunge + Reach",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180305-ex-2-3",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20180305-ex-2-4",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180305-ex-2-5",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180305-ex-2-6",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "20180305-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180305-ex-3-1",
                "name": "Walking Lunges",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180305-ex-3-2",
                "name": "\u00bd Kneel SA Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    },
    {
        "id": "20180305-block-4",
        "name": "Core Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180305-ex-4-1",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "20180305-ex-4-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "20180305-ex-4-3",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_reps": "10"
            },
            {
                "id": "20180305-ex-4-4",
                "name": "Farmers Carry",
                "sequence": 4,
                "prescribed_reps": "2 lengths"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 5, 2018';


-- Fix "March 6, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180306-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180306-ex-1-1",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Band at ankles"
            },
            {
                "id": "20180306-ex-1-2",
                "name": "Banded Squats",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20180306-ex-1-3",
                "name": "Banded Bridge",
                "sequence": 3,
                "notes": "Glute/hip activation"
            }
        ]
    },
    {
        "id": "20180306-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180306-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20180306-ex-2-2",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180306-ex-2-3",
                "name": "Over/Under",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180306-ex-2-4",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180306-ex-2-5",
                "name": "ATW",
                "sequence": 5,
                "notes": "Around the world - shoulder"
            },
            {
                "id": "20180306-ex-2-6",
                "name": "Bear Crawl",
                "sequence": 6,
                "notes": "5 - Core/coordination"
            }
        ]
    },
    {
        "id": "20180306-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180306-ex-3-1",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20180306-ex-3-2",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "20180306-block-4",
        "name": "Conditioning - Chipper",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180306-ex-4-1",
                "name": "KB Swing",
                "sequence": 1,
                "prescribed_reps": "50"
            },
            {
                "id": "20180306-ex-4-2",
                "name": "Shoulder Tap",
                "sequence": 2,
                "prescribed_reps": "40"
            },
            {
                "id": "20180306-ex-4-3",
                "name": "Goblet Squat",
                "sequence": 3,
                "prescribed_reps": "30"
            },
            {
                "id": "20180306-ex-4-4",
                "name": "Starfish",
                "sequence": 4,
                "prescribed_reps": "20"
            },
            {
                "id": "20180306-ex-4-5",
                "name": "Med Ball Tap",
                "sequence": 5,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 6, 2018';


-- Fix "March 11, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180311-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180311-ex-1-1",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Mobility assessment"
            },
            {
                "id": "20180311-ex-1-2",
                "name": "Jump Rope",
                "sequence": 2,
                "notes": "Cardio warm-up"
            }
        ]
    },
    {
        "id": "20180311-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180311-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180311-ex-2-2",
                "name": "Over/Under Fence",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180311-ex-2-3",
                "name": "Spidermans",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180311-ex-2-4",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180311-ex-2-5",
                "name": "Side Lunges",
                "sequence": 5,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180311-ex-2-6",
                "name": "Quad Pulls",
                "sequence": 6,
                "notes": "Quad stretch"
            },
            {
                "id": "20180311-ex-2-7",
                "name": "Glute Bridges",
                "sequence": 7,
                "notes": "30 - Glute activation"
            }
        ]
    },
    {
        "id": "20180311-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180311-ex-3-1",
                "name": "Single Leg Deadlift (SL DL)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Hamstring Walks between sets"
            },
            {
                "id": "20180311-ex-3-2",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180311-block-4",
        "name": "Cash Out",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180311-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Steady pace cooldown"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 11, 2018';


-- Fix "March 13, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180313-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180313-ex-1-1",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Mobility assessment"
            },
            {
                "id": "20180313-ex-1-2",
                "name": "Push Ups",
                "sequence": 2,
                "notes": "Upper body activation"
            },
            {
                "id": "20180313-ex-1-3",
                "name": "Air Squats",
                "sequence": 3,
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "20180313-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180313-ex-2-1",
                "name": "Back Lunge + Twist",
                "sequence": 1,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180313-ex-2-2",
                "name": "Spidermans",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180313-ex-2-3",
                "name": "Quad Pulls",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20180313-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180313-ex-2-5",
                "name": "PVC Passovers",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180313-ex-2-6",
                "name": "Hamstring Walks",
                "sequence": 6,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180313-ex-2-7",
                "name": "Walkouts",
                "sequence": 7,
                "notes": "5 - Full body prep"
            }
        ]
    },
    {
        "id": "20180313-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180313-ex-3-1",
                "name": "Slant Bar 3 Ext.",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 8). Rest: 60 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180313-ex-3-2",
                "name": "Stability Ball Hamstring Curls",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60 sec between sets"
            }
        ]
    },
    {
        "id": "20180313-block-4",
        "name": "Conditioning - 1 Round for Time",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180313-ex-4-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 1,
                "prescribed_reps": "500m/1000m",
                "notes": "1 rounds total"
            },
            {
                "id": "20180313-ex-4-2",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "50",
                "notes": "1 rounds total"
            },
            {
                "id": "20180313-ex-4-3",
                "name": "Air Squats",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "75",
                "notes": "1 rounds total"
            },
            {
                "id": "20180313-ex-4-4",
                "name": "Dead Bugs",
                "sequence": 4,
                "prescribed_sets": 1,
                "prescribed_reps": "25e",
                "notes": "1 rounds total"
            },
            {
                "id": "20180313-ex-4-5",
                "name": "Row/Bike",
                "sequence": 5,
                "prescribed_sets": 1,
                "prescribed_reps": "500m/1000m",
                "notes": "1 rounds total"
            },
            {
                "id": "20180313-ex-4-6",
                "name": "KB Swings",
                "sequence": 6,
                "prescribed_sets": 1,
                "prescribed_reps": "50",
                "notes": "1 rounds total"
            },
            {
                "id": "20180313-ex-4-7",
                "name": "Mtn Climbers",
                "sequence": 7,
                "prescribed_sets": 1,
                "prescribed_reps": "50e",
                "notes": "1 rounds total"
            },
            {
                "id": "20180313-ex-4-8",
                "name": "MB Toe Taps",
                "sequence": 8,
                "prescribed_sets": 1,
                "prescribed_reps": "25",
                "notes": "1 rounds total"
            },
            {
                "id": "20180313-ex-4-9",
                "name": "Burpees",
                "sequence": 9,
                "prescribed_sets": 1,
                "prescribed_reps": "25",
                "notes": "1 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 13, 2018';


-- Fix "March 14, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180314-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180314-ex-1-1",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Band at ankles"
            },
            {
                "id": "20180314-ex-1-2",
                "name": "Banded Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20180314-ex-1-3",
                "name": "Banded Squat",
                "sequence": 3,
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "20180314-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180314-ex-2-1",
                "name": "High Knee/Quad Pull",
                "sequence": 1,
                "notes": "Hip flexor/quad prep"
            },
            {
                "id": "20180314-ex-2-2",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180314-ex-2-3",
                "name": "Over/Under",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180314-ex-2-4",
                "name": "Lunge + Reach",
                "sequence": 4,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180314-ex-2-5",
                "name": "Bear Crawl",
                "sequence": 5,
                "notes": "5 - Core/coordination"
            },
            {
                "id": "20180314-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "20180314-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180314-ex-3-1",
                "name": "Slant Bar 3 Ext.",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Pigeon stretch between sets"
            },
            {
                "id": "20180314-ex-3-2",
                "name": "Renegade Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Bi/Lat Stretch between sets"
            },
            {
                "id": "20180314-ex-3-3",
                "name": "Slant Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "20180314-ex-3-4",
                "name": "Step Ups",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180314-ex-3-5",
                "name": "Battle Ropes",
                "sequence": 5,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": "Rest: 30-60 sec between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 14, 2018';


-- Fix "March 20, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180320-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180320-ex-1-1",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Mobility assessment"
            },
            {
                "id": "20180320-ex-1-2",
                "name": "Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180320-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180320-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180320-ex-2-2",
                "name": "Lunge + Rotate",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180320-ex-2-3",
                "name": "Hamstring Walks",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180320-ex-2-4",
                "name": "PVC Good Mornings",
                "sequence": 4,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180320-ex-2-5",
                "name": "PVC Figure 8''s",
                "sequence": 5,
                "notes": "T-spine/shoulder"
            },
            {
                "id": "20180320-ex-2-6",
                "name": "Spidermans",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "20180320-ex-2-7",
                "name": "Butt Kicks",
                "sequence": 7,
                "notes": "Quad activation"
            },
            {
                "id": "20180320-ex-2-8",
                "name": "Push Ups",
                "sequence": 8,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "20180320-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180320-ex-3-1",
                "name": "Deadlifts",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90-120 sec between sets Accessory: TTP (Touch the Post) between sets"
            },
            {
                "id": "20180320-ex-3-2",
                "name": "SA Bent Over Row (BOR)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180320-block-4",
        "name": "Conditioning - 20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180320-ex-4-1",
                "name": "MB Slams",
                "sequence": 1,
                "prescribed_reps": "12"
            },
            {
                "id": "20180320-ex-4-2",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "20180320-ex-4-3",
                "name": "V Ups",
                "sequence": 3,
                "prescribed_reps": "12"
            },
            {
                "id": "20180320-ex-4-4",
                "name": "Side Lunges",
                "sequence": 4,
                "prescribed_reps": "6e"
            },
            {
                "id": "20180320-ex-4-5",
                "name": "Row/Bike",
                "sequence": 5,
                "prescribed_reps": "12 cal"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 20, 2018';


-- Fix "March 25, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180325-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180325-ex-1-1",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Mobility assessment"
            },
            {
                "id": "20180325-ex-1-2",
                "name": "Sit Ups",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "20180325-ex-1-3",
                "name": "Air Squats",
                "sequence": 3,
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "20180325-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180325-ex-2-1",
                "name": "High Knee Pulls",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180325-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180325-ex-2-3",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180325-ex-2-4",
                "name": "Side Lunges",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180325-ex-2-5",
                "name": "PVC Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180325-ex-2-6",
                "name": "Piriformis",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180325-ex-2-7",
                "name": "Spidermans",
                "sequence": 7,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "20180325-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180325-ex-3-1",
                "name": "Deadlifts (Building)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Light+ (RPE 5). Set 3: Moderate (RPE 6). Set 4: Moderate+ (RPE 7). Set 5: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: TTP (Touch the Post) between sets"
            },
            {
                "id": "20180325-ex-3-2",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180325-block-4",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180325-ex-4-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "12 cal"
            },
            {
                "id": "20180325-ex-4-2",
                "name": "Russian Twists",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "20180325-ex-4-3",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_reps": "12"
            },
            {
                "id": "20180325-ex-4-4",
                "name": "Push Press",
                "sequence": 4,
                "prescribed_reps": "12"
            },
            {
                "id": "20180325-ex-4-5",
                "name": "MB Slams",
                "sequence": 5,
                "prescribed_reps": "12"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 25, 2018';


-- Fix "March 26, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180326-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180326-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded or SL variation"
            },
            {
                "id": "20180326-ex-1-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180326-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180326-ex-2-1",
                "name": "High Knee Pull + Reach",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "20180326-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180326-ex-2-3",
                "name": "Lunge + Reach",
                "sequence": 3,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180326-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180326-ex-2-5",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180326-ex-2-6",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "10 - Hip hinge prep"
            }
        ]
    },
    {
        "id": "20180326-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180326-ex-3-1",
                "name": "Single Leg Deadlift (SL DL)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walks between sets"
            },
            {
                "id": "20180326-ex-3-2",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180326-block-4",
        "name": "Core - 5 Rounds",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180326-ex-4-1",
                "name": "Front Squat",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10"
            },
            {
                "id": "20180326-ex-4-2",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "10"
            },
            {
                "id": "20180326-ex-4-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180326-ex-4-4",
                "name": "Push Press",
                "sequence": 4,
                "prescribed_sets": 5,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 26, 2018';


-- Fix "March 27, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180327-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180327-ex-1-1",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Mobility assessment"
            },
            {
                "id": "20180327-ex-1-2",
                "name": "Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20180327-ex-1-3",
                "name": "Supermans",
                "sequence": 3,
                "notes": "Back activation"
            }
        ]
    },
    {
        "id": "20180327-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180327-ex-2-1",
                "name": "PVC Passovers",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180327-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180327-ex-2-3",
                "name": "Hamstring Walks",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180327-ex-2-4",
                "name": "Lunge + Twist",
                "sequence": 4,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180327-ex-2-5",
                "name": "Over/Under Fence",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180327-ex-2-6",
                "name": "Karaoke",
                "sequence": 6,
                "notes": "Hip/coordination"
            },
            {
                "id": "20180327-ex-2-7",
                "name": "Air Squats",
                "sequence": 7,
                "notes": "20 - Lower body prep"
            }
        ]
    },
    {
        "id": "20180327-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180327-ex-3-1",
                "name": "MB Clean Progressions",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: T-Spine on Roller between sets"
            },
            {
                "id": "20180327-ex-3-2",
                "name": "Bent Over Row (BOR)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 27, 2018';


-- Fix "March 29, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180329-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180329-ex-1-1",
                "name": "SA Row",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20180329-ex-1-2",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: RRL between sets"
            }
        ]
    },
    {
        "id": "20180329-block-2",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180329-ex-2-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m"
            },
            {
                "id": "20180329-ex-2-2",
                "name": "KB Swing",
                "sequence": 2,
                "prescribed_reps": "15"
            },
            {
                "id": "20180329-ex-2-3",
                "name": "BOSU Mtn Climb",
                "sequence": 3,
                "prescribed_reps": "20e"
            },
            {
                "id": "20180329-ex-2-4",
                "name": "Jump Rope",
                "sequence": 4,
                "prescribed_reps": "60"
            },
            {
                "id": "20180329-ex-2-5",
                "name": "HKTC",
                "sequence": 5,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 29, 2018';


-- Fix "April 1, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180401-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180401-ex-1-1",
                "name": "Bike/Row",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "20180401-ex-1-2",
                "name": "Monsters",
                "sequence": 2,
                "notes": "Band at ankles"
            }
        ]
    },
    {
        "id": "20180401-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180401-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180401-ex-2-2",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180401-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180401-ex-2-4",
                "name": "Piriformis",
                "sequence": 4,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180401-ex-2-5",
                "name": "Push-Up Walkout",
                "sequence": 5,
                "notes": "Full body activation"
            },
            {
                "id": "20180401-ex-2-6",
                "name": "Spiderman",
                "sequence": 6,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "20180401-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180401-ex-3-1",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: TTP (Touch the Post) between sets"
            },
            {
                "id": "20180401-ex-3-2",
                "name": "Step Ups OR Box Jumps",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e / 25",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 1, 2018';


-- Fix "April 2, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180402-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180402-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded or SL variation"
            },
            {
                "id": "20180402-ex-1-2",
                "name": "Wall Sit + Plank",
                "sequence": 2,
                "notes": "Isometric hold"
            }
        ]
    },
    {
        "id": "20180402-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180402-ex-2-1",
                "name": "HS Walk",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180402-ex-2-2",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180402-ex-2-3",
                "name": "Lunge + Reach",
                "sequence": 3,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180402-ex-2-4",
                "name": "Over/Under",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180402-ex-2-5",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180402-ex-2-6",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "20180402-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180402-ex-3-1",
                "name": "KB Front Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180402-ex-3-2",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180402-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180402-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m"
            },
            {
                "id": "20180402-ex-4-2",
                "name": "KB Swing",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "20180402-ex-4-3",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "12e"
            },
            {
                "id": "20180402-ex-4-4",
                "name": "Burpees",
                "sequence": 4,
                "prescribed_reps": "12"
            },
            {
                "id": "20180402-ex-4-5",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "200m"
            },
            {
                "id": "20180402-ex-4-6",
                "name": "Slamballs",
                "sequence": 6,
                "prescribed_reps": "12"
            },
            {
                "id": "20180402-ex-4-7",
                "name": "\u00bd Kneel Chop",
                "sequence": 7,
                "prescribed_reps": "12"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 2, 2018';


-- Fix "April 3, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180403-block-1",
        "name": "Active - 3 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180403-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Glute activation"
            },
            {
                "id": "20180403-ex-1-2",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Core activation"
            },
            {
                "id": "20180403-ex-1-3",
                "name": "Push Ups",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Upper body activation"
            }
        ]
    },
    {
        "id": "20180403-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180403-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180403-ex-2-2",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180403-ex-2-3",
                "name": "Spiderman",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180403-ex-2-4",
                "name": "Quad Pull",
                "sequence": 4,
                "notes": "Quad stretch"
            },
            {
                "id": "20180403-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180403-ex-2-6",
                "name": "Push Up W/O",
                "sequence": 6,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "20180403-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180403-ex-3-1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "20180403-ex-3-2",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "20180403-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180403-ex-4-1",
                "name": "OH Squat",
                "sequence": 1,
                "prescribed_reps": "10"
            },
            {
                "id": "20180403-ex-4-2",
                "name": "Med Ball Tap",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "20180403-ex-4-3",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_reps": "15"
            },
            {
                "id": "20180403-ex-4-4",
                "name": "Farmers Carry",
                "sequence": 4,
                "prescribed_reps": "2 lengths"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 3, 2018';


-- Fix "April 4, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180404-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180404-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20180404-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded or SL variation"
            }
        ]
    },
    {
        "id": "20180404-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180404-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180404-ex-2-2",
                "name": "High Knee Pull",
                "sequence": 2,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180404-ex-2-3",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180404-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180404-ex-2-5",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180404-ex-2-6",
                "name": "Pigeon",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "20180404-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180404-ex-3-1",
                "name": "Slant Bar 3 Ext.",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Pigeon stretch between sets"
            },
            {
                "id": "20180404-ex-3-2",
                "name": "Renegade Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20180404-ex-3-3",
                "name": "Slant Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "20180404-ex-3-4",
                "name": "KB RDL",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: TTP (Touch the Post) between sets"
            }
        ]
    },
    {
        "id": "20180404-block-4",
        "name": "Conditioning - 5 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180404-ex-4-1",
                "name": "TRX Row",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "15",
                "notes": "5 rounds total"
            },
            {
                "id": "20180404-ex-4-2",
                "name": "Squat",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "15",
                "notes": "5 rounds total"
            },
            {
                "id": "20180404-ex-4-3",
                "name": "Push Ups",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "15",
                "notes": "5 rounds total"
            },
            {
                "id": "20180404-ex-4-4",
                "name": "Rower Sprint",
                "sequence": 4,
                "prescribed_sets": 5,
                "prescribed_reps": "90 sec",
                "notes": "5 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 4, 2018';


-- Fix "April 5, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180405-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180405-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded or SL variation"
            },
            {
                "id": "20180405-ex-1-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180405-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180405-ex-2-1",
                "name": "High Knee Pull + Reach",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "20180405-ex-2-2",
                "name": "Push Up W/O",
                "sequence": 2,
                "notes": "Full body activation"
            },
            {
                "id": "20180405-ex-2-3",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180405-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180405-ex-2-5",
                "name": "Lunge + Twist",
                "sequence": 5,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180405-ex-2-6",
                "name": "PVC Passover",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20180405-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180405-ex-3-1",
                "name": "Single Leg Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180405-ex-3-2",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "20180405-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180405-ex-4-1",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "20180405-ex-4-2",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "20180405-ex-4-3",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180405-ex-4-4",
                "name": "TGU",
                "sequence": 4,
                "prescribed_reps": "1e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 5, 2018';


-- Fix "April 6, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 45,
    exercises = '[
    {
        "id": "20180406-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180406-ex-1-1",
                "name": "Jump Rope",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180406-ex-1-2",
                "name": "Row",
                "sequence": 2,
                "notes": "Moderate pace"
            }
        ]
    },
    {
        "id": "20180406-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180406-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20180406-ex-2-2",
                "name": "Spiderman",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180406-ex-2-3",
                "name": "Hi Touch/Lo Touch",
                "sequence": 3,
                "notes": "Dynamic stretch"
            },
            {
                "id": "20180406-ex-2-4",
                "name": "Over/Under",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180406-ex-2-5",
                "name": "Piriformis",
                "sequence": 5,
                "notes": "Glute stretch"
            },
            {
                "id": "20180406-ex-2-6",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "10 - Hip hinge prep"
            }
        ]
    },
    {
        "id": "20180406-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180406-ex-3-1",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded/SL (RPE 5). Set 2: Banded/SL (RPE 6). Set 3: Banded/SL (RPE 6). Rest: 45 sec between sets"
            },
            {
                "id": "20180406-ex-3-2",
                "name": "Split Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20180406-ex-3-3",
                "name": "Good Mornings",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "20180406-block-4",
        "name": "Conditioning - EMOM 12''",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180406-ex-4-1",
                "name": "Push Press",
                "sequence": 1,
                "prescribed_reps": "8e"
            },
            {
                "id": "20180406-ex-4-2",
                "name": "Med Ball Tap",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "20180406-ex-4-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180406-ex-4-4",
                "name": "Front Squat",
                "sequence": 4,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 6, 2018';


-- Fix "April 8, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180408-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180408-ex-1-1",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Movement assessment"
            },
            {
                "id": "20180408-ex-1-2",
                "name": "Hurdle Step",
                "sequence": 2,
                "notes": "Hip mobility test"
            },
            {
                "id": "20180408-ex-1-3",
                "name": "Monster Walks",
                "sequence": 3,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180408-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180408-ex-2-1",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180408-ex-2-2",
                "name": "Piriformis",
                "sequence": 2,
                "notes": "Glute stretch"
            },
            {
                "id": "20180408-ex-2-3",
                "name": "Side Lunges",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180408-ex-2-4",
                "name": "Quad Pulls",
                "sequence": 4,
                "notes": "Quad stretch"
            },
            {
                "id": "20180408-ex-2-5",
                "name": "PVC Passovers",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180408-ex-2-6",
                "name": "Inchworms",
                "sequence": 6,
                "notes": "Full body activation"
            },
            {
                "id": "20180408-ex-2-7",
                "name": "Air Squats",
                "sequence": 7,
                "notes": "10 - Lower body prep"
            },
            {
                "id": "20180408-ex-2-8",
                "name": "Push Ups",
                "sequence": 8,
                "notes": "10 - Upper body prep"
            }
        ]
    },
    {
        "id": "20180408-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180408-ex-3-1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20180408-ex-3-2",
                "name": "SA DB Bench Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Chest Openers between sets"
            }
        ]
    },
    {
        "id": "20180408-block-4",
        "name": "Conditioning - 15-20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180408-ex-4-1",
                "name": "HKTC",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "20180408-ex-4-2",
                "name": "KB Swings",
                "sequence": 2,
                "prescribed_reps": "15"
            },
            {
                "id": "20180408-ex-4-3",
                "name": "Goblet Squats",
                "sequence": 3,
                "prescribed_reps": "15"
            },
            {
                "id": "20180408-ex-4-4",
                "name": "SA BOR (KB)",
                "sequence": 4,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180408-ex-4-5",
                "name": "Russian Twist",
                "sequence": 5,
                "prescribed_reps": "15e"
            },
            {
                "id": "20180408-ex-4-6",
                "name": "Battle Ropes",
                "sequence": 6,
                "prescribed_reps": "30 sec"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 8, 2018';


-- Fix "April 9, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180409-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180409-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20180409-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20180409-ex-1-3",
                "name": "Shoulder Tap",
                "sequence": 3,
                "notes": "Core/shoulder stability"
            }
        ]
    },
    {
        "id": "20180409-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180409-ex-2-1",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "20180409-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180409-ex-2-3",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180409-ex-2-4",
                "name": "Push Up W/O",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "20180409-ex-2-5",
                "name": "Pigeon",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180409-ex-2-6",
                "name": "RRL",
                "sequence": 6,
                "notes": "Rotation mobility"
            }
        ]
    },
    {
        "id": "20180409-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180409-ex-3-1",
                "name": "Walking Lunges",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20180409-ex-3-2",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "Max",
                "notes": "Set 1: Bodyweight (RPE 8). Set 2: T-Push Ups (RPE 7). Rest: 90 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "20180409-block-4",
        "name": "Conditioning - Chipper",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180409-ex-4-1",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "40"
            },
            {
                "id": "20180409-ex-4-2",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_reps": "40"
            },
            {
                "id": "20180409-ex-4-3",
                "name": "KB Swings",
                "sequence": 3,
                "prescribed_reps": "40"
            },
            {
                "id": "20180409-ex-4-4",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_reps": "40"
            },
            {
                "id": "20180409-ex-4-5",
                "name": "Renegade Row",
                "sequence": 5,
                "prescribed_reps": "40"
            },
            {
                "id": "20180409-ex-4-6",
                "name": "Burpees",
                "sequence": 6,
                "prescribed_reps": "40"
            },
            {
                "id": "20180409-ex-4-7",
                "name": "Calf Raise",
                "sequence": 7,
                "prescribed_reps": "40"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 9, 2018';


-- Fix "April 10, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180410-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180410-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20180410-ex-1-2",
                "name": "TRX Row",
                "sequence": 2,
                "notes": "Back activation"
            },
            {
                "id": "20180410-ex-1-3",
                "name": "Plank",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180410-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180410-ex-2-1",
                "name": "Hi Touch/Lo Touch",
                "sequence": 1,
                "notes": "Dynamic stretch"
            },
            {
                "id": "20180410-ex-2-2",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180410-ex-2-3",
                "name": "Spiderman",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180410-ex-2-4",
                "name": "Bear Crawl",
                "sequence": 4,
                "notes": "5 - Full body activation"
            },
            {
                "id": "20180410-ex-2-5",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180410-ex-2-6",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "20180410-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180410-ex-3-1",
                "name": "Chin Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Bi/Lat Stretch between sets"
            },
            {
                "id": "20180410-ex-3-2",
                "name": "KB RDL",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "20180410-block-4",
        "name": "Conditioning - EMOM 10''",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180410-ex-4-1",
                "name": "Goblet Squat",
                "sequence": 1,
                "prescribed_reps": "7"
            },
            {
                "id": "20180410-ex-4-2",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_reps": "7"
            },
            {
                "id": "20180410-ex-4-3",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "7e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 10, 2018';


-- Fix "April 11, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180411-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180411-ex-1-1",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20180411-ex-1-2",
                "name": "Jump Rope",
                "sequence": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "20180411-ex-1-3",
                "name": "Row",
                "sequence": 3,
                "notes": "Moderate pace"
            }
        ]
    },
    {
        "id": "20180411-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180411-ex-2-1",
                "name": "High Knee/Quad Pull",
                "sequence": 1,
                "notes": "Hip flexor/quad prep"
            },
            {
                "id": "20180411-ex-2-2",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180411-ex-2-3",
                "name": "Hip Openers",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180411-ex-2-4",
                "name": "SL Rotation",
                "sequence": 4,
                "notes": "Core/hip mobility"
            },
            {
                "id": "20180411-ex-2-5",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180411-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "20180411-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180411-ex-3-1",
                "name": "Banded Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Band (RPE 5). Set 2: Band (RPE 6). Set 3: Band (RPE 6). Rest: 45 sec between sets Accessory: Pigeon between sets"
            },
            {
                "id": "20180411-ex-3-2",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "20180411-ex-3-3",
                "name": "Med Ball Clean",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Good Mornings between sets"
            },
            {
                "id": "20180411-ex-3-4",
                "name": "Thrusters",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 11, 2018';


-- Fix "April 12, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180412-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180412-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded/SL variation"
            },
            {
                "id": "20180412-ex-1-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "20180412-ex-1-3",
                "name": "Wall Sit",
                "sequence": 3,
                "notes": "Quad isometric"
            }
        ]
    },
    {
        "id": "20180412-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180412-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20180412-ex-2-2",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180412-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180412-ex-2-4",
                "name": "Pigeon/Piriformis",
                "sequence": 4,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180412-ex-2-5",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180412-ex-2-6",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "20180412-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180412-ex-3-1",
                "name": "Turkish Get Up (TGU)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: SL Rotation between sets"
            },
            {
                "id": "20180412-ex-3-2",
                "name": "Good Mornings",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "20180412-block-4",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180412-ex-4-1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 3,
                "notes": "3 rounds total"
            },
            {
                "id": "20180412-ex-4-2",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "notes": "3 rounds total"
            },
            {
                "id": "20180412-ex-4-3",
                "name": "Groundhog",
                "sequence": 3,
                "prescribed_sets": 3,
                "notes": "3 rounds total"
            },
            {
                "id": "20180412-ex-4-4",
                "name": "Push Press",
                "sequence": 4,
                "prescribed_sets": 3,
                "notes": "3 rounds total"
            },
            {
                "id": "20180412-ex-4-5",
                "name": "Plank",
                "sequence": 5,
                "prescribed_sets": 3,
                "notes": "3 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 12, 2018';


-- Fix "April 13, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 45,
    exercises = '[
    {
        "id": "20180413-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180413-ex-1-1",
                "name": "Push Ups",
                "sequence": 1,
                "notes": "Upper body activation"
            },
            {
                "id": "20180413-ex-1-2",
                "name": "Sit Ups",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "20180413-ex-1-3",
                "name": "Air Squat",
                "sequence": 3,
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "20180413-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180413-ex-2-1",
                "name": "HS Walk",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180413-ex-2-2",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Dynamic hamstring"
            },
            {
                "id": "20180413-ex-2-3",
                "name": "Over/Under",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180413-ex-2-4",
                "name": "Quad Pull + Hinge",
                "sequence": 4,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180413-ex-2-5",
                "name": "Push Up W/O",
                "sequence": 5,
                "notes": "Full body activation"
            },
            {
                "id": "20180413-ex-2-6",
                "name": "90s Robot",
                "sequence": 6,
                "notes": "T-spine mobility"
            }
        ]
    },
    {
        "id": "20180413-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180413-ex-3-1",
                "name": "SL Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20180413-ex-3-2",
                "name": "SA DB Bench",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "20180413-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180413-ex-4-1",
                "name": "SA KB Swing",
                "sequence": 1,
                "prescribed_reps": "8e"
            },
            {
                "id": "20180413-ex-4-2",
                "name": "HKTC",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "20180413-ex-4-3",
                "name": "Renegade Row",
                "sequence": 3,
                "prescribed_reps": "8e"
            },
            {
                "id": "20180413-ex-4-4",
                "name": "Sit Ups",
                "sequence": 4,
                "prescribed_reps": "10"
            },
            {
                "id": "20180413-ex-4-5",
                "name": "Bear Crawl Hold",
                "sequence": 5,
                "prescribed_reps": "60\""
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 13, 2018';


-- Fix "April 15, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180415-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180415-ex-1-1",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Movement assessment"
            },
            {
                "id": "20180415-ex-1-2",
                "name": "Bike/Row",
                "sequence": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "20180415-ex-1-3",
                "name": "Push Ups",
                "sequence": 3,
                "notes": "Upper body prep"
            },
            {
                "id": "20180415-ex-1-4",
                "name": "SL Bridge",
                "sequence": 4,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180415-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180415-ex-2-1",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180415-ex-2-2",
                "name": "Piriformis",
                "sequence": 2,
                "notes": "Glute stretch"
            },
            {
                "id": "20180415-ex-2-3",
                "name": "Quad Pulls",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20180415-ex-2-4",
                "name": "Lunge & Rotate",
                "sequence": 4,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180415-ex-2-5",
                "name": "Hip Openers/Closers",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180415-ex-2-6",
                "name": "High Knees (fast)",
                "sequence": 6,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180415-ex-2-7",
                "name": "Butt Kicks",
                "sequence": 7,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180415-ex-2-8",
                "name": "Walkout + Push Up",
                "sequence": 8,
                "notes": "5 - Full body activation"
            }
        ]
    },
    {
        "id": "20180415-block-3",
        "name": "Intro - 9 min EMOM",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180415-ex-3-1",
                "name": "10 cal Bike/Row",
                "sequence": 1
            },
            {
                "id": "20180415-ex-3-2",
                "name": "10 BB DL",
                "sequence": 2
            },
            {
                "id": "20180415-ex-3-3",
                "name": "10 Bar Over Burpees",
                "sequence": 3
            }
        ]
    },
    {
        "id": "20180415-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180415-ex-4-1",
                "name": "3 Way Lunges",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "5e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "20180415-block-5",
        "name": "Conditioning - 12-15 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180415-ex-5-1",
                "name": "Starfish",
                "sequence": 1,
                "prescribed_reps": "12e"
            },
            {
                "id": "20180415-ex-5-2",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "20180415-ex-5-3",
                "name": "Farmer''s Carry",
                "sequence": 3,
                "prescribed_reps": "1 length"
            },
            {
                "id": "20180415-ex-5-4",
                "name": "MB Lifts",
                "sequence": 4,
                "prescribed_reps": "12e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 15, 2018';


-- Fix "April 16, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180416-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180416-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20180416-ex-1-2",
                "name": "Monsters",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20180416-ex-1-3",
                "name": "Shoulder Tap",
                "sequence": 3,
                "notes": "Core/shoulder stability"
            }
        ]
    },
    {
        "id": "20180416-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180416-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180416-ex-2-2",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180416-ex-2-3",
                "name": "Quad Pull + Hinge",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180416-ex-2-4",
                "name": "Hi Touch/Lo Touch",
                "sequence": 4,
                "notes": "Dynamic stretch"
            },
            {
                "id": "20180416-ex-2-5",
                "name": "Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180416-ex-2-6",
                "name": "PVC Passover/Fig. 8",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20180416-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180416-ex-3-1",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20180416-ex-3-2",
                "name": "SL DL",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "20180416-block-4",
        "name": "Conditioning - 5 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180416-ex-4-1",
                "name": "Goblet Squat",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "5 rounds total"
            },
            {
                "id": "20180416-ex-4-2",
                "name": "Groundhog",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "5 rounds total"
            },
            {
                "id": "20180416-ex-4-3",
                "name": "Split Squat",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "8e",
                "notes": "5 rounds total"
            },
            {
                "id": "20180416-ex-4-4",
                "name": "Sit Ups",
                "sequence": 4,
                "prescribed_sets": 5,
                "prescribed_reps": "12",
                "notes": "5 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 16, 2018';


-- Fix "April 17, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180417-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180417-ex-1-1",
                "name": "Bear Crawl",
                "sequence": 1,
                "notes": "Full body activation"
            },
            {
                "id": "20180417-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180417-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180417-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20180417-ex-2-2",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180417-ex-2-3",
                "name": "Arm Circles",
                "sequence": 3,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180417-ex-2-4",
                "name": "Push Up W/O",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "20180417-ex-2-5",
                "name": "Pigeon/Piriformis",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20180417-ex-2-6",
                "name": "Butterfly",
                "sequence": 6,
                "notes": "Adductor stretch"
            }
        ]
    },
    {
        "id": "20180417-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180417-ex-3-1",
                "name": "Slant Bar 3 Ext.",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Pigeon between sets"
            },
            {
                "id": "20180417-ex-3-2",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            }
        ]
    },
    {
        "id": "20180417-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180417-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "250m"
            },
            {
                "id": "20180417-ex-4-2",
                "name": "KB Swing",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "20180417-ex-4-3",
                "name": "Starfish",
                "sequence": 3,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180417-ex-4-4",
                "name": "\u00bd Kneel Chop",
                "sequence": 4,
                "prescribed_reps": "10"
            },
            {
                "id": "20180417-ex-4-5",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "250m"
            },
            {
                "id": "20180417-ex-4-6",
                "name": "Back Lunge",
                "sequence": 6,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180417-ex-4-7",
                "name": "Russian Twist",
                "sequence": 7,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180417-ex-4-8",
                "name": "Burpees",
                "sequence": 8,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 17, 2018';


-- Fix "April 18, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180418-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180418-ex-1-1",
                "name": "Banded Clamshell",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20180418-ex-1-2",
                "name": "Sit Ups",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "20180418-ex-1-3",
                "name": "Push Ups",
                "sequence": 3,
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "20180418-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180418-ex-2-1",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "20180418-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180418-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180418-ex-2-4",
                "name": "Over/Under",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180418-ex-2-5",
                "name": "Side Lunge",
                "sequence": 5,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180418-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "20180418-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180418-ex-3-1",
                "name": "Hip Thrust",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Ham/Glute Stretch between sets"
            },
            {
                "id": "20180418-ex-3-2",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Light-Moderate (RPE 7). Rest: As needed Accessory: SL Rotation between sides"
            },
            {
                "id": "20180418-ex-3-3",
                "name": "Floor Press",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20180418-ex-3-4",
                "name": "Kang Squat",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "20180418-block-4",
        "name": "Conditioning",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180418-ex-4-1",
                "name": "Hollow Hold",
                "sequence": 1
            },
            {
                "id": "20180418-ex-4-2",
                "name": "Row",
                "sequence": 2
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 18, 2018';


-- Fix "April 19, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 45,
    exercises = '[
    {
        "id": "20180419-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180419-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded/SL variation"
            },
            {
                "id": "20180419-ex-1-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180419-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180419-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180419-ex-2-2",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180419-ex-2-3",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180419-ex-2-4",
                "name": "Heel Kiss Walk",
                "sequence": 4,
                "notes": "Ankle mobility"
            },
            {
                "id": "20180419-ex-2-5",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180419-ex-2-6",
                "name": "ATW",
                "sequence": 6,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "20180419-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180419-ex-3-1",
                "name": "SL Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20180419-ex-3-2",
                "name": "SA Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180419-block-4",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180419-ex-4-1",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "20180419-ex-4-2",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 19, 2018';


-- Fix "April 20, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180420-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180420-ex-1-1",
                "name": "Row / Jump Rope",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180420-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded/SL variation"
            }
        ]
    },
    {
        "id": "20180420-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180420-ex-2-1",
                "name": "High Knee Pull + Reach",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "20180420-ex-2-2",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180420-ex-2-3",
                "name": "Quad Pull + Hinge",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180420-ex-2-4",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180420-ex-2-5",
                "name": "Push Up W/O",
                "sequence": 5,
                "notes": "Full body activation"
            },
            {
                "id": "20180420-ex-2-6",
                "name": "SL Rotation",
                "sequence": 6,
                "notes": "Core/hip mobility"
            }
        ]
    },
    {
        "id": "20180420-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180420-ex-3-1",
                "name": "Front Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20180420-ex-3-2",
                "name": "KB RDL / Good Mornings",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Banded Ham Stretch between sets"
            }
        ]
    },
    {
        "id": "20180420-block-4",
        "name": "Conditioning - 12'' EMOM",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180420-ex-4-1",
                "name": "Lunges",
                "sequence": 1,
                "prescribed_reps": "8e"
            },
            {
                "id": "20180420-ex-4-2",
                "name": "Shoulder Tap",
                "sequence": 2,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180420-ex-4-3",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_reps": "8"
            },
            {
                "id": "20180420-ex-4-4",
                "name": "TRX Row",
                "sequence": 4,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 20, 2018';


-- Fix "April 21, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180421-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180421-ex-1-1",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20180421-ex-1-2",
                "name": "Banded Squats",
                "sequence": 2,
                "notes": "Quad activation"
            },
            {
                "id": "20180421-ex-1-3",
                "name": "Banded Bridge",
                "sequence": 3,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180421-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180421-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180421-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180421-ex-2-3",
                "name": "High Touch/Low Touch",
                "sequence": 3,
                "notes": "Dynamic stretch"
            },
            {
                "id": "20180421-ex-2-4",
                "name": "Pushup Walkout",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "20180421-ex-2-5",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180421-ex-2-6",
                "name": "PVC Passover",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180421-ex-2-7",
                "name": "Good Mornings",
                "sequence": 7,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "20180421-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180421-ex-3-1",
                "name": "Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 8). Set 5: Max (RPE 9). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20180421-ex-3-2",
                "name": "SL DL",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "20180421-block-4",
        "name": "Conditioning - 15'' AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180421-ex-4-1",
                "name": "Front Squat",
                "sequence": 1,
                "prescribed_reps": "10"
            },
            {
                "id": "20180421-ex-4-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180421-ex-4-3",
                "name": "Push Press",
                "sequence": 3,
                "prescribed_reps": "10"
            },
            {
                "id": "20180421-ex-4-4",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_reps": "10"
            },
            {
                "id": "20180421-ex-4-5",
                "name": "Burpees",
                "sequence": 5,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 21, 2018';


-- Fix "April 22, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180422-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180422-ex-1-1",
                "name": "Monster Walks",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20180422-ex-1-2",
                "name": "TRX Is, Ys, Ts",
                "sequence": 2,
                "notes": "Shoulder activation"
            }
        ]
    },
    {
        "id": "20180422-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180422-ex-2-1",
                "name": "Spiderman & Rotate",
                "sequence": 1,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20180422-ex-2-2",
                "name": "High Knee Skip",
                "sequence": 2,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180422-ex-2-3",
                "name": "Quad Pull + Hinge",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180422-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180422-ex-2-5",
                "name": "Walkout + Push Up",
                "sequence": 5,
                "notes": "5 - Full body activation"
            },
            {
                "id": "20180422-ex-2-6",
                "name": "Lunge + Reach",
                "sequence": 6,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180422-ex-2-7",
                "name": "Toy Soldiers",
                "sequence": 7,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180422-ex-2-8",
                "name": "PVC Figure 8s",
                "sequence": 8,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180422-ex-2-9",
                "name": "TGU",
                "sequence": 9,
                "notes": "1e - Full body warm-up"
            }
        ]
    },
    {
        "id": "20180422-block-3",
        "name": "Intro - EMOM (40 sec each)",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180422-ex-3-1",
                "name": "Snow Angels",
                "sequence": 1
            },
            {
                "id": "20180422-ex-3-2",
                "name": "Burpees",
                "sequence": 2
            },
            {
                "id": "20180422-ex-3-3",
                "name": "Sit Ups",
                "sequence": 3
            }
        ]
    },
    {
        "id": "20180422-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180422-ex-4-1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Dead Bugs 10e between sets"
            }
        ]
    },
    {
        "id": "20180422-block-5",
        "name": "Conditioning - 12 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180422-ex-5-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m"
            },
            {
                "id": "20180422-ex-5-2",
                "name": "Push Press",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "20180422-ex-5-3",
                "name": "V Ups",
                "sequence": 3,
                "prescribed_reps": "10"
            },
            {
                "id": "20180422-ex-5-4",
                "name": "Goblet Squats",
                "sequence": 4,
                "prescribed_reps": "10"
            }
        ]
    },
    {
        "id": "20180422-block-6",
        "name": "Cashout - 2 Rounds",
        "block_type": "functional",
        "sequence": 6,
        "exercises": [
            {
                "id": "20180422-ex-6-1",
                "name": "Rope Climb",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "1"
            },
            {
                "id": "20180422-ex-6-2",
                "name": "MB Slams",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "8"
            },
            {
                "id": "20180422-ex-6-3",
                "name": "Jump Rope",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "50"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 22, 2018';


-- Fix "April 23, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 45,
    exercises = '[
    {
        "id": "20180423-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180423-ex-1-1",
                "name": "Banded Bridge",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20180423-ex-1-2",
                "name": "Banded Squats",
                "sequence": 2,
                "notes": "Quad activation"
            }
        ]
    },
    {
        "id": "20180423-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180423-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180423-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180423-ex-2-3",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180423-ex-2-4",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180423-ex-2-5",
                "name": "Push Up W/O",
                "sequence": 5,
                "notes": "Full body activation"
            },
            {
                "id": "20180423-ex-2-6",
                "name": "Pigeon",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "20180423-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180423-ex-3-1",
                "name": "Lunge 3-way",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20180423-ex-3-2",
                "name": "SA Row (TRX/DB)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180423-block-4",
        "name": "Conditioning - 12'' AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180423-ex-4-1",
                "name": "Push Ups",
                "sequence": 1,
                "prescribed_reps": "10"
            },
            {
                "id": "20180423-ex-4-2",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "20180423-ex-4-3",
                "name": "Cal Row",
                "sequence": 3,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 23, 2018';


-- Fix "April 24, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180424-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180424-ex-1-1",
                "name": "Sally Up!",
                "sequence": 1,
                "notes": "Push-up challenge"
            }
        ]
    },
    {
        "id": "20180424-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180424-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180424-ex-2-2",
                "name": "Hi Touch/Lo Touch",
                "sequence": 2,
                "notes": "Dynamic stretch"
            },
            {
                "id": "20180424-ex-2-3",
                "name": "Spiderman",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180424-ex-2-4",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180424-ex-2-5",
                "name": "Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180424-ex-2-6",
                "name": "Bear Crawl",
                "sequence": 6,
                "notes": "1 length - Full body activation"
            }
        ]
    },
    {
        "id": "20180424-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180424-ex-3-1",
                "name": "Floor Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: TRX Pec Stretch between sets"
            },
            {
                "id": "20180424-ex-3-2",
                "name": "KB RDL",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "20180424-block-4",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180424-ex-4-1",
                "name": "KB Swing",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "20180424-ex-4-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "15e",
                "notes": "3 rounds total"
            },
            {
                "id": "20180424-ex-4-3",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "20180424-ex-4-4",
                "name": "Med Ball Tap",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "20180424-ex-4-5",
                "name": "Burpees",
                "sequence": 5,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 24, 2018';


-- Fix "April 29, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180429-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180429-ex-1-1",
                "name": "Sit Ups",
                "sequence": 1,
                "notes": "Core activation"
            },
            {
                "id": "20180429-ex-1-2",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "Lower body prep"
            },
            {
                "id": "20180429-ex-1-3",
                "name": "Push Ups",
                "sequence": 3,
                "notes": "Upper body activation"
            }
        ]
    },
    {
        "id": "20180429-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180429-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180429-ex-2-2",
                "name": "Over/Under Fence",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180429-ex-2-3",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180429-ex-2-4",
                "name": "High Knee Skip",
                "sequence": 4,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180429-ex-2-5",
                "name": "Spiderman & Rotate",
                "sequence": 5,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20180429-ex-2-6",
                "name": "PVC Passovers",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180429-ex-2-7",
                "name": "Is, Ys, Ts",
                "sequence": 7,
                "notes": "3e - Shoulder activation"
            },
            {
                "id": "20180429-ex-2-8",
                "name": "Side Plank",
                "sequence": 8,
                "notes": "30 sec e - Core activation"
            }
        ]
    },
    {
        "id": "20180429-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180429-ex-3-1",
                "name": "SL DL",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Dead Bugs 10e (slow) between sets"
            },
            {
                "id": "20180429-ex-3-2",
                "name": "DB Bench Press (Pyramid)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Chest Opener between sets"
            }
        ]
    },
    {
        "id": "20180429-block-4",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180429-ex-4-1",
                "name": "KB Swings",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "20180429-ex-4-2",
                "name": "Push Presses",
                "sequence": 2,
                "prescribed_reps": "15"
            },
            {
                "id": "20180429-ex-4-3",
                "name": "HKTC",
                "sequence": 3,
                "prescribed_reps": "15"
            },
            {
                "id": "20180429-ex-4-4",
                "name": "TRX Rows",
                "sequence": 4,
                "prescribed_reps": "15"
            },
            {
                "id": "20180429-ex-4-5",
                "name": "Shoulder Taps",
                "sequence": 5,
                "prescribed_reps": "15e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 29, 2018';


-- Fix "April 30, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180430-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180430-ex-1-1",
                "name": "Jumping Jacks",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180430-ex-1-2",
                "name": "Monster Walks",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180430-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180430-ex-2-1",
                "name": "Arm Circles",
                "sequence": 1,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180430-ex-2-2",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180430-ex-2-3",
                "name": "Hamstring Walks",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180430-ex-2-4",
                "name": "PVC Passovers",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180430-ex-2-5",
                "name": "Hip Openers",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180430-ex-2-6",
                "name": "Piriformis",
                "sequence": 6,
                "notes": "Glute stretch"
            },
            {
                "id": "20180430-ex-2-7",
                "name": "Quad Pulls",
                "sequence": 7,
                "notes": "Quad stretch"
            }
        ]
    },
    {
        "id": "20180430-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180430-ex-3-1",
                "name": "SL Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 8). Rest: 60-90 sec between sets Accessory: Birddogs 10e between sets"
            },
            {
                "id": "20180430-ex-3-2",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "20180430-block-4",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180430-ex-4-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12 cal",
                "notes": "4 rounds total"
            },
            {
                "id": "20180430-ex-4-2",
                "name": "KB Swings",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "4 rounds total"
            },
            {
                "id": "20180430-ex-4-3",
                "name": "Sit Ups",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "4 rounds total"
            },
            {
                "id": "20180430-ex-4-4",
                "name": "Split Squats",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "4 rounds total"
            },
            {
                "id": "20180430-ex-4-5",
                "name": "Russian Twist",
                "sequence": 5,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "4 rounds total"
            },
            {
                "id": "20180430-ex-4-6",
                "name": "Burpees",
                "sequence": 6,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 30, 2018';


-- Fix "May 1, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180501-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180501-ex-1-1",
                "name": "Snow Angels",
                "sequence": 1,
                "notes": "Shoulder activation"
            },
            {
                "id": "20180501-ex-1-2",
                "name": "Jump Rope",
                "sequence": 2,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180501-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180501-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180501-ex-2-2",
                "name": "Hamstring Walks",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180501-ex-2-3",
                "name": "Spidermans",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180501-ex-2-4",
                "name": "Lunge + Reach",
                "sequence": 4,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180501-ex-2-5",
                "name": "High Knee Pulls",
                "sequence": 5,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180501-ex-2-6",
                "name": "Walkout + Push Up",
                "sequence": 6,
                "notes": "5 - Full body activation"
            },
            {
                "id": "20180501-ex-2-7",
                "name": "PVC Passovers",
                "sequence": 7,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180501-ex-2-8",
                "name": "Lat Stretch",
                "sequence": 8,
                "notes": "Back mobility"
            }
        ]
    },
    {
        "id": "20180501-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180501-ex-3-1",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Shoulder Mobility between sets"
            },
            {
                "id": "20180501-ex-3-2",
                "name": "3 Way Lunges",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Hip Mobility between sets"
            }
        ]
    },
    {
        "id": "20180501-block-4",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180501-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "250m",
                "notes": "2 rounds total"
            },
            {
                "id": "20180501-ex-4-2",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "2 rounds total"
            },
            {
                "id": "20180501-ex-4-3",
                "name": "V Ups",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "2 rounds total"
            },
            {
                "id": "20180501-ex-4-4",
                "name": "Row",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "250m",
                "notes": "2 rounds total"
            },
            {
                "id": "20180501-ex-4-5",
                "name": "Goblet Squats",
                "sequence": 5,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "2 rounds total"
            },
            {
                "id": "20180501-ex-4-6",
                "name": "HKTC",
                "sequence": 6,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "2 rounds total"
            },
            {
                "id": "20180501-ex-4-7",
                "name": "Row",
                "sequence": 7,
                "prescribed_sets": 2,
                "prescribed_reps": "250m",
                "notes": "2 rounds total"
            },
            {
                "id": "20180501-ex-4-8",
                "name": "Box Jump/Step Up",
                "sequence": 8,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "2 rounds total"
            },
            {
                "id": "20180501-ex-4-9",
                "name": "Farmer''s Carry Hold w/ High Knees",
                "sequence": 9,
                "prescribed_sets": 2,
                "prescribed_reps": "45 sec",
                "notes": "2 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 1, 2018';


-- Fix "May 8, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180508-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180508-ex-1-1",
                "name": "Jumping Jacks",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180508-ex-1-2",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "20180508-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180508-ex-2-1",
                "name": "Piriformis",
                "sequence": 1,
                "notes": "Glute stretch"
            },
            {
                "id": "20180508-ex-2-2",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180508-ex-2-3",
                "name": "High Knee Pulls",
                "sequence": 3,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180508-ex-2-4",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180508-ex-2-5",
                "name": "Side Lunges",
                "sequence": 5,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180508-ex-2-6",
                "name": "PVC Passovers",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180508-ex-2-7",
                "name": "Hip Openers/Closers",
                "sequence": 7,
                "notes": "Hip mobility"
            },
            {
                "id": "20180508-ex-2-8",
                "name": "Bear Crawls",
                "sequence": 8,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "20180508-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180508-ex-3-1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "6",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate+ (RPE 7). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Chest Openers between sets"
            },
            {
                "id": "20180508-ex-3-2",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 8, 2018';


-- Fix "May 9, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180509-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180509-ex-1-1",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20180509-ex-1-2",
                "name": "Banded Squat",
                "sequence": 2,
                "notes": "Quad activation"
            },
            {
                "id": "20180509-ex-1-3",
                "name": "Bridges",
                "sequence": 3,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180509-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180509-ex-2-1",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "20180509-ex-2-2",
                "name": "Hi Touch/Lo Touch",
                "sequence": 2,
                "notes": "Dynamic stretch"
            },
            {
                "id": "20180509-ex-2-3",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20180509-ex-2-4",
                "name": "Pushup Walkout",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "20180509-ex-2-5",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180509-ex-2-6",
                "name": "PVC Passover",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180509-ex-2-7",
                "name": "Good Mornings",
                "sequence": 7,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "20180509-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180509-ex-3-1",
                "name": "Slant Bar 3 Ext.",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Pigeon between sets"
            },
            {
                "id": "20180509-ex-3-2",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20180509-ex-3-3",
                "name": "Slant Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "20180509-ex-3-4",
                "name": "Step Ups",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "20180509-block-4",
        "name": "Conditioning",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180509-ex-4-1",
                "name": "Timed 500m Row",
                "sequence": 1,
                "notes": "Max effort"
            },
            {
                "id": "20180509-ex-4-2",
                "name": "Sally Up!",
                "sequence": 2,
                "notes": "Push-up challenge"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 9, 2018';


-- Fix "May 10, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180510-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180510-ex-1-1",
                "name": "Jump Rope",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180510-ex-1-2",
                "name": "Row",
                "sequence": 2,
                "notes": "Moderate pace"
            }
        ]
    },
    {
        "id": "20180510-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180510-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180510-ex-2-2",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180510-ex-2-3",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180510-ex-2-4",
                "name": "W/O Pushup",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "20180510-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180510-ex-2-6",
                "name": "RRL",
                "sequence": 6,
                "notes": "Rotation mobility"
            }
        ]
    },
    {
        "id": "20180510-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180510-ex-3-1",
                "name": "Push Press",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Fig 8''s between sets"
            },
            {
                "id": "20180510-ex-3-2",
                "name": "Good Mornings",
                "sequence": 2,
                "prescribed_sets": 9,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Set 5: Notes. Set 6: -------. Set 7: Alternating waves. Set 8: Footwork drills. Set 9: Front and side. Rest: 60-90 sec between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "20180510-block-4",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180510-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "250m",
                "notes": "2 rounds total"
            },
            {
                "id": "20180510-ex-4-2",
                "name": "Split Squat",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "20180510-ex-4-3",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "20180510-ex-4-4",
                "name": "\u00bd Kneel Chop",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "20180510-ex-4-5",
                "name": "Row",
                "sequence": 5,
                "prescribed_sets": 2,
                "prescribed_reps": "250m",
                "notes": "2 rounds total"
            },
            {
                "id": "20180510-ex-4-6",
                "name": "Slam Balls",
                "sequence": 6,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "20180510-ex-4-7",
                "name": "Russian Twist",
                "sequence": 7,
                "prescribed_sets": 2,
                "prescribed_reps": "12e",
                "notes": "2 rounds total"
            },
            {
                "id": "20180510-ex-4-8",
                "name": "Burpees",
                "sequence": 8,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 10, 2018';


-- Fix "May 14, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180514-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180514-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded/SL variation"
            },
            {
                "id": "20180514-ex-1-2",
                "name": "Sit Ups",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "20180514-ex-1-3",
                "name": "Cossack",
                "sequence": 3,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "20180514-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180514-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180514-ex-2-2",
                "name": "Lunge + Reach",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180514-ex-2-3",
                "name": "Hi Touch/Lo Touch",
                "sequence": 3,
                "notes": "Dynamic stretch"
            },
            {
                "id": "20180514-ex-2-4",
                "name": "HS Walk",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180514-ex-2-5",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180514-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "20180514-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180514-ex-3-1",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20180514-ex-3-2",
                "name": "Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "20180514-block-4",
        "name": "Conditioning - 5 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180514-ex-4-1",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "8",
                "notes": "5 rounds total"
            },
            {
                "id": "20180514-ex-4-2",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "15",
                "notes": "5 rounds total"
            },
            {
                "id": "20180514-ex-4-3",
                "name": "Jump Rope",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "60",
                "notes": "5 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 14, 2018';


-- Fix "May 15, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180515-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180515-ex-1-1",
                "name": "Clamshells",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20180515-ex-1-2",
                "name": "SL Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180515-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180515-ex-2-1",
                "name": "Spidermans",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180515-ex-2-2",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180515-ex-2-3",
                "name": "PVC Passovers",
                "sequence": 3,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180515-ex-2-4",
                "name": "PVC Good Mornings",
                "sequence": 4,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180515-ex-2-5",
                "name": "Hip Openers",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180515-ex-2-6",
                "name": "Walkouts + Push Up",
                "sequence": 6,
                "notes": "5 - Full body activation"
            },
            {
                "id": "20180515-ex-2-7",
                "name": "Shoulder Mob. or Hip Mob.",
                "sequence": 7,
                "notes": "Individual needs"
            }
        ]
    },
    {
        "id": "20180515-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180515-ex-3-1",
                "name": "Bench Press (Building)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Max (RPE 8). Rest: 90-120 sec between sets Accessory: Chest Opener between sets"
            },
            {
                "id": "20180515-ex-3-2",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 15, 2018';


-- Fix "May 17, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180517-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180517-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded/SL variation"
            },
            {
                "id": "20180517-ex-1-2",
                "name": "Plank",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "20180517-ex-1-3",
                "name": "Wall Sit",
                "sequence": 3,
                "notes": "Quad isometric"
            }
        ]
    },
    {
        "id": "20180517-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180517-ex-2-1",
                "name": "Lunge + Twist",
                "sequence": 1,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180517-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180517-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180517-ex-2-4",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180517-ex-2-5",
                "name": "Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180517-ex-2-6",
                "name": "90s Robot",
                "sequence": 6,
                "notes": "T-spine mobility"
            }
        ]
    },
    {
        "id": "20180517-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180517-ex-3-1",
                "name": "Step Ups",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20180517-ex-3-2",
                "name": "SA Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180517-block-4",
        "name": "Conditioning - 5 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180517-ex-4-1",
                "name": "Split Squat",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "8e",
                "notes": "5 rounds total"
            },
            {
                "id": "20180517-ex-4-2",
                "name": "Shoulder Tap",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "12e",
                "notes": "5 rounds total"
            },
            {
                "id": "20180517-ex-4-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "10e",
                "notes": "5 rounds total"
            },
            {
                "id": "20180517-ex-4-4",
                "name": "Lat. Skater",
                "sequence": 4,
                "prescribed_sets": 5,
                "prescribed_reps": "12e",
                "notes": "5 rounds total"
            },
            {
                "id": "20180517-ex-4-5",
                "name": "HKTC",
                "sequence": 5,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "5 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 17, 2018';


-- Fix "May 18, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180518-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180518-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded/SL variation"
            },
            {
                "id": "20180518-ex-1-2",
                "name": "T-Push Ups",
                "sequence": 2,
                "notes": "Upper body/rotation"
            }
        ]
    },
    {
        "id": "20180518-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180518-ex-2-1",
                "name": "High Knee Pull + Reach",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "20180518-ex-2-2",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180518-ex-2-3",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20180518-ex-2-4",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180518-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "20180518-ex-2-6",
                "name": "Push Up W/O",
                "sequence": 6,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "20180518-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180518-ex-3-1",
                "name": "Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Max (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20180518-ex-3-2",
                "name": "KB RDL",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "20180518-block-4",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180518-ex-4-1",
                "name": "Cal Row",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "30",
                "notes": "2 rounds total"
            },
            {
                "id": "20180518-ex-4-2",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "30",
                "notes": "2 rounds total"
            },
            {
                "id": "20180518-ex-4-3",
                "name": "Sit Ups",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "30",
                "notes": "2 rounds total"
            },
            {
                "id": "20180518-ex-4-4",
                "name": "Push Ups",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "30",
                "notes": "2 rounds total"
            },
            {
                "id": "20180518-ex-4-5",
                "name": "Jump Rope",
                "sequence": 5,
                "prescribed_sets": 2,
                "prescribed_reps": "60",
                "notes": "2 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 18, 2018';


-- Fix "May 21, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180521-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180521-ex-1-1",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20180521-ex-1-2",
                "name": "Banded Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20180521-ex-1-3",
                "name": "Banded Squats",
                "sequence": 3,
                "notes": "Quad activation"
            }
        ]
    },
    {
        "id": "20180521-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180521-ex-2-1",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180521-ex-2-2",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180521-ex-2-3",
                "name": "PVC Passover",
                "sequence": 3,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180521-ex-2-4",
                "name": "Push Up W/O",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "20180521-ex-2-5",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180521-ex-2-6",
                "name": "Pigeon",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "20180521-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180521-ex-3-1",
                "name": "Chin Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Bi/Lat Stretch between sets"
            },
            {
                "id": "20180521-ex-3-2",
                "name": "SL DL",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "20180521-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180521-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "250m"
            },
            {
                "id": "20180521-ex-4-2",
                "name": "Split Squat",
                "sequence": 2,
                "prescribed_reps": "8e"
            },
            {
                "id": "20180521-ex-4-3",
                "name": "Sit Ups",
                "sequence": 3,
                "prescribed_reps": "15"
            },
            {
                "id": "20180521-ex-4-4",
                "name": "TRX Row",
                "sequence": 4,
                "prescribed_reps": "12"
            },
            {
                "id": "20180521-ex-4-5",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "250m"
            },
            {
                "id": "20180521-ex-4-6",
                "name": "Thrusters",
                "sequence": 6,
                "prescribed_reps": "15"
            },
            {
                "id": "20180521-ex-4-7",
                "name": "Starfish",
                "sequence": 7,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180521-ex-4-8",
                "name": "Push Ups",
                "sequence": 8,
                "prescribed_reps": "12"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 21, 2018';


-- Fix "May 22, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180522-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180522-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180522-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20180522-ex-1-3",
                "name": "Sit Ups",
                "sequence": 3,
                "notes": "Core activation"
            },
            {
                "id": "20180522-ex-1-4",
                "name": "Push Ups",
                "sequence": 4,
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "20180522-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180522-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180522-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180522-ex-2-3",
                "name": "Hi Touch/Lo Touch",
                "sequence": 3,
                "notes": "Dynamic stretch"
            },
            {
                "id": "20180522-ex-2-4",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180522-ex-2-5",
                "name": "SL Rotation",
                "sequence": 5,
                "notes": "Core/hip mobility"
            },
            {
                "id": "20180522-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "20180522-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180522-ex-3-1",
                "name": "DB Bench",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: Pec Stretch between sets"
            },
            {
                "id": "20180522-ex-3-2",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "20180522-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180522-ex-4-1",
                "name": "KB Swing",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "20180522-ex-4-2",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_reps": "20"
            },
            {
                "id": "20180522-ex-4-3",
                "name": "OH Squat",
                "sequence": 3,
                "prescribed_reps": "10"
            },
            {
                "id": "20180522-ex-4-4",
                "name": "Dead Bugs",
                "sequence": 4,
                "prescribed_reps": "10e"
            },
            {
                "id": "20180522-ex-4-5",
                "name": "Burpees",
                "sequence": 5,
                "prescribed_reps": "10"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 22, 2018';


-- Fix "May 23, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180523-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180523-ex-1-1",
                "name": "Row/Jump Rope",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180523-ex-1-2",
                "name": "Bear Crawl (4-way)",
                "sequence": 2,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "20180523-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180523-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20180523-ex-2-2",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180523-ex-2-3",
                "name": "Lunge + Reach",
                "sequence": 3,
                "notes": "T-spine mobility"
            },
            {
                "id": "20180523-ex-2-4",
                "name": "Quad Pull",
                "sequence": 4,
                "notes": "Quad stretch"
            },
            {
                "id": "20180523-ex-2-5",
                "name": "Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180523-ex-2-6",
                "name": "Fig. 8",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20180523-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180523-ex-3-1",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded/SL (RPE 5). Set 2: Banded/SL (RPE 6). Set 3: Banded/SL (RPE 6)"
            },
            {
                "id": "20180523-ex-3-2",
                "name": "SL Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20180523-ex-3-3",
                "name": "\u00bd Kneel SA Press",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "20180523-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180523-ex-4-1",
                "name": "Goblet Squat",
                "sequence": 1,
                "prescribed_reps": "10-12"
            },
            {
                "id": "20180523-ex-4-2",
                "name": "BOSU Mtn Climb",
                "sequence": 2,
                "prescribed_reps": "10-12e"
            },
            {
                "id": "20180523-ex-4-3",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_reps": "10-12"
            },
            {
                "id": "20180523-ex-4-4",
                "name": "Med Ball Tap",
                "sequence": 4,
                "prescribed_reps": "10-12e"
            },
            {
                "id": "20180523-ex-4-5",
                "name": "Rower Sprint",
                "sequence": 5,
                "prescribed_reps": "30 sec"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 23, 2018';


-- Fix "June 5, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180605-block-1",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180605-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "20180605-ex-1-2",
                "name": "Rear Lunge w/ Reach \u2191",
                "sequence": 2,
                "prescribed_sets": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180605-ex-1-3",
                "name": "Lateral Squat",
                "sequence": 3,
                "prescribed_sets": 2,
                "notes": "Adductor mobility"
            }
        ]
    },
    {
        "id": "20180605-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180605-ex-2-1",
                "name": "Quadruped Trunk Rot.",
                "sequence": 1,
                "notes": "10/10 - T-spine mobility"
            },
            {
                "id": "20180605-ex-2-2",
                "name": "4 Point Bridge w/ Alt. Leg Extension",
                "sequence": 2,
                "notes": "10/10 - Core stability"
            },
            {
                "id": "20180605-ex-2-3",
                "name": "Stick Figure 8",
                "sequence": 3,
                "notes": "5/5 - Shoulder mobility"
            },
            {
                "id": "20180605-ex-2-4",
                "name": "Good Morning w/ Rot. hold",
                "sequence": 4,
                "notes": "5/5 - Hip hinge/rotation"
            },
            {
                "id": "20180605-ex-2-5",
                "name": "Band Face Pulls",
                "sequence": 5,
                "notes": "15 - Rear delt activation"
            },
            {
                "id": "20180605-ex-2-6",
                "name": "SA Band Press",
                "sequence": 6,
                "notes": "10/10 - Shoulder stability"
            },
            {
                "id": "20180605-ex-2-7",
                "name": "Band Straight Arm Lat Pulldown",
                "sequence": 7,
                "notes": "10 - Lat activation"
            }
        ]
    },
    {
        "id": "20180605-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180605-ex-3-1",
                "name": "Flat DB Alt. Press \u2192 Double Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: Wall Sit w/ Wall Angels x 5 between sets"
            },
            {
                "id": "20180605-ex-3-2",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "3/3",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 8). Set 3: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: Lat/Tri Stretch :15/:15 between sets"
            }
        ]
    },
    {
        "id": "20180605-block-4",
        "name": "Conditioning - 4 Rounds / 10 min Cap",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180605-ex-4-1",
                "name": "Pull-ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            },
            {
                "id": "20180605-ex-4-2",
                "name": "Box Jumps or Step-ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "16",
                "notes": "4 rounds total"
            },
            {
                "id": "20180605-ex-4-3",
                "name": "KB SA Swings",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "25",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'June 5, 2018';


-- Fix "June 6, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180606-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180606-ex-1-1",
                "name": "Quick Step Ups",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180606-ex-1-2",
                "name": "Quick Lat. Step Ups",
                "sequence": 2,
                "notes": "Lateral cardio"
            }
        ]
    },
    {
        "id": "20180606-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180606-ex-2-1",
                "name": "Stick Rotations",
                "sequence": 1,
                "notes": "20x - T-spine mobility"
            },
            {
                "id": "20180606-ex-2-2",
                "name": "Stick Good Mornings",
                "sequence": 2,
                "notes": "10x - Hip hinge prep"
            },
            {
                "id": "20180606-ex-2-3",
                "name": "Stick Sumo Back Squat",
                "sequence": 3,
                "notes": "10x - Sumo stance prep"
            },
            {
                "id": "20180606-ex-2-4",
                "name": "Stick OH Squat",
                "sequence": 4,
                "notes": "10x - Shoulder/hip mobility"
            },
            {
                "id": "20180606-ex-2-5",
                "name": "Walking Leg Cradle",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180606-ex-2-6",
                "name": "Walking Side Lunge",
                "sequence": 6,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180606-ex-2-7",
                "name": "Walking Rear Lunge w/ Reach Back",
                "sequence": 7,
                "notes": "T-spine/hip mobility"
            }
        ]
    },
    {
        "id": "20180606-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180606-ex-3-1",
                "name": "Sumo Deadlift (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Set 5: Max (RPE 9). Rest: 2-3 min between sets Accessory: Seated Groin Stretch + SL RDL Balance between sets"
            },
            {
                "id": "20180606-ex-3-2",
                "name": "Chin Ups or TRX Supinated Grip",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 90 sec between sets Accessory: Cat/Cow Stretch 10x between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'June 6, 2018';


-- Fix "June 7, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180607-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180607-ex-1-1",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180607-ex-1-2",
                "name": "Mountain Climbers",
                "sequence": 2,
                "notes": "Core/cardio"
            },
            {
                "id": "20180607-ex-1-3",
                "name": "\u00bd Kneel Band Chop",
                "sequence": 3,
                "notes": "Core rotation"
            }
        ]
    },
    {
        "id": "20180607-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180607-ex-2-1",
                "name": "Toy Soldier",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180607-ex-2-2",
                "name": "High Knee March",
                "sequence": 2,
                "notes": "Hip flexor prep"
            },
            {
                "id": "20180607-ex-2-3",
                "name": "High Knee M-Skip",
                "sequence": 3,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180607-ex-2-4",
                "name": "Slow Backpedal",
                "sequence": 4,
                "notes": "Hip/hamstring"
            },
            {
                "id": "20180607-ex-2-5",
                "name": "Backpedal/Sprint",
                "sequence": 5,
                "notes": "Speed work"
            },
            {
                "id": "20180607-ex-2-6",
                "name": "Crisscross Jumping Jack",
                "sequence": 6,
                "notes": "20x - Cardio"
            },
            {
                "id": "20180607-ex-2-7",
                "name": "Band Angled Pull Apart",
                "sequence": 7,
                "notes": "15/15 - Rear delt"
            },
            {
                "id": "20180607-ex-2-8",
                "name": "Band OH Pull Apart",
                "sequence": 8,
                "notes": "15x - Upper back"
            },
            {
                "id": "20180607-ex-2-9",
                "name": "Band OH Rear Lunge",
                "sequence": 9,
                "notes": "5/5 5\"hold - Stability"
            },
            {
                "id": "20180607-ex-2-10",
                "name": "Band OH Squat",
                "sequence": 10,
                "notes": "10x - Shoulder/hip mobility"
            }
        ]
    },
    {
        "id": "20180607-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180607-ex-3-1",
                "name": "Split Squat DB Curl to Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Hip Flexor to Calf/HS Stretch 5/5 between sets"
            },
            {
                "id": "20180607-ex-3-2",
                "name": "Loaded/Unloaded Push-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8/8-12",
                "notes": "Set 1: Loaded/Unloaded (RPE 6). Set 2: Loaded/Unloaded (RPE 7). Set 3: Loaded/Unloaded (RPE 7). Set 4: Loaded/Unloaded (RPE 7). Accessory: Quadruped Trunk Rotation 8/8 between sets"
            }
        ]
    },
    {
        "id": "20180607-block-4",
        "name": "Conditioning - 12'' EMOM",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180607-ex-4-1",
                "name": "Battle Rope 30\"",
                "sequence": 1
            },
            {
                "id": "20180607-ex-4-2",
                "name": "DL 15x",
                "sequence": 2
            },
            {
                "id": "20180607-ex-4-3",
                "name": "Jump Rope 30\"",
                "sequence": 3
            },
            {
                "id": "20180607-ex-4-4",
                "name": "Burpees 10-15 (30\")",
                "sequence": 4
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'June 7, 2018';


-- Fix "June 14, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180614-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180614-ex-1-1",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180614-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180614-ex-2-1",
                "name": "Side Slide w/ Arm Swing",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "20180614-ex-2-2",
                "name": "Lateral Plank Walk",
                "sequence": 2,
                "notes": "Core/shoulder"
            },
            {
                "id": "20180614-ex-2-3",
                "name": "Lunge w/ Palm to Instep Rot.",
                "sequence": 3,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20180614-ex-2-4",
                "name": "Carioca",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180614-ex-2-5",
                "name": "A-Skip",
                "sequence": 5,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180614-ex-2-6",
                "name": "Lateral A-Skip",
                "sequence": 6,
                "notes": "Lateral movement"
            }
        ]
    },
    {
        "id": "20180614-block-3",
        "name": "Movement Prep (w/ Plates)",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180614-ex-3-1",
                "name": "Neutral Arm Raise w/ 3 sec. Lower",
                "sequence": 1,
                "prescribed_reps": "10x",
                "notes": "Shoulder stability"
            },
            {
                "id": "20180614-ex-3-2",
                "name": "Bent Scap Retraction w/ Forward Arm Raise",
                "sequence": 2,
                "prescribed_reps": "10x",
                "notes": "Upper back"
            },
            {
                "id": "20180614-ex-3-3",
                "name": "External Rotations w/ Press",
                "sequence": 3,
                "prescribed_reps": "10x",
                "notes": "Rotator cuff"
            },
            {
                "id": "20180614-ex-3-4",
                "name": "Rear Delt Fly",
                "sequence": 4,
                "prescribed_reps": "10x",
                "notes": "Posterior shoulder"
            },
            {
                "id": "20180614-ex-3-5",
                "name": "TRX Fallouts",
                "sequence": 5,
                "prescribed_reps": "10x",
                "notes": "Core stability"
            }
        ]
    },
    {
        "id": "20180614-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180614-ex-4-1",
                "name": "Neutral Grip DB Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 7). Rest: 90 sec between sets Accessory: Sidelying Trunk Rotation x 5/5 between sets"
            },
            {
                "id": "20180614-ex-4-2",
                "name": "Strict Pull-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8-12",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Banded Lat Stretch x :20/:20 between sets"
            }
        ]
    },
    {
        "id": "20180614-block-5",
        "name": "Core Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180614-ex-5-1",
                "name": "Palloff Press",
                "sequence": 1,
                "notes": "Anti-rotation"
            },
            {
                "id": "20180614-ex-5-2",
                "name": "Bar Rotations",
                "sequence": 2,
                "notes": "Rotation"
            },
            {
                "id": "20180614-ex-5-3",
                "name": "Starfish",
                "sequence": 3,
                "notes": "Core stability"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'June 14, 2018';


-- Fix "June 19, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180619-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180619-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180619-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180619-ex-2-1",
                "name": "Carioca",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180619-ex-2-2",
                "name": "Lunge w/ Palm to Instep",
                "sequence": 2,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180619-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180619-ex-2-4",
                "name": "Quad Pull + Hinge",
                "sequence": 4,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180619-ex-2-5",
                "name": "A-Skip",
                "sequence": 5,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180619-ex-2-6",
                "name": "Lateral A-Skip",
                "sequence": 6,
                "notes": "Lateral movement"
            },
            {
                "id": "20180619-ex-2-7",
                "name": "Updog \u2192 Downdog Flow",
                "sequence": 7,
                "notes": "Full body mobility"
            },
            {
                "id": "20180619-ex-2-8",
                "name": "Pigeon",
                "sequence": 8,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "20180619-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180619-ex-3-1",
                "name": "Strict Chin-Ups",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Set 5: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch / Forearm Stretch between sets"
            },
            {
                "id": "20180619-ex-3-2",
                "name": "SA DB Bench",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10/10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: TRX Pec Stretch between sets"
            }
        ]
    },
    {
        "id": "20180619-block-4",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180619-ex-4-1",
                "name": "TRX/Ring Row",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "4 rounds total"
            },
            {
                "id": "20180619-ex-4-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "18 total",
                "notes": "4 rounds total"
            },
            {
                "id": "20180619-ex-4-3",
                "name": "KB Swings",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "24",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'June 19, 2018';


-- Fix "June 26, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180626-block-1",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180626-ex-1-1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "20180626-ex-1-2",
                "name": "Rear Lunge Reach Up",
                "sequence": 2,
                "prescribed_sets": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180626-ex-1-3",
                "name": "Push-Ups",
                "sequence": 3,
                "prescribed_sets": 2,
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "20180626-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180626-ex-2-1",
                "name": "Knee Hug",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180626-ex-2-2",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180626-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180626-ex-2-4",
                "name": "Lateral Shuffle",
                "sequence": 4,
                "notes": "Lateral movement"
            },
            {
                "id": "20180626-ex-2-5",
                "name": "Backpedal",
                "sequence": 5,
                "notes": "Hip/hamstring"
            },
            {
                "id": "20180626-ex-2-6",
                "name": "A-Skip",
                "sequence": 6,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180626-ex-2-7",
                "name": "Bushwackers",
                "sequence": 7,
                "notes": "Full body"
            },
            {
                "id": "20180626-ex-2-8",
                "name": "High Bear Crawl",
                "sequence": 8,
                "notes": "Core/shoulder"
            },
            {
                "id": "20180626-ex-2-9",
                "name": "Band Work",
                "sequence": 9,
                "notes": "Activation"
            }
        ]
    },
    {
        "id": "20180626-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180626-ex-3-1",
                "name": "KB/DB Bench Rows",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Banded Lat Stretch between sets"
            },
            {
                "id": "20180626-ex-3-2",
                "name": "Seated DB Curls",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12-15",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 45-60 sec between sets Accessory: Band Tricep Pressdown 15x between sets"
            }
        ]
    },
    {
        "id": "20180626-block-4",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180626-ex-4-1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "50x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180626-ex-4-2",
                "name": "KB Push Press",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180626-ex-4-3",
                "name": "Starfish",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "16x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180626-ex-4-4",
                "name": "KB Swing",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "20x",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'June 26, 2018';


-- Fix "June 27, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180627-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180627-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180627-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180627-ex-2-1",
                "name": "Leg Cradle",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180627-ex-2-2",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180627-ex-2-3",
                "name": "Quad Pull + Reach Up",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180627-ex-2-4",
                "name": "TRX Row",
                "sequence": 4,
                "notes": "15x - Upper back activation"
            },
            {
                "id": "20180627-ex-2-5",
                "name": "Push Up",
                "sequence": 5,
                "notes": "15x - Upper body prep"
            }
        ]
    },
    {
        "id": "20180627-block-3",
        "name": "With Light KB",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180627-ex-3-1",
                "name": "Lunge w/ Twist",
                "sequence": 1,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20180627-ex-3-2",
                "name": "Lateral Lunge",
                "sequence": 2,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180627-ex-3-3",
                "name": "Rear Lunge KB OH",
                "sequence": 3,
                "notes": "Shoulder/hip stability"
            },
            {
                "id": "20180627-ex-3-4",
                "name": "Goblet Squat",
                "sequence": 4,
                "notes": "3 sec pause - Squat prep"
            }
        ]
    },
    {
        "id": "20180627-block-4",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180627-ex-4-1",
                "name": "Good Morning",
                "sequence": 1,
                "prescribed_reps": "10x",
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180627-ex-4-2",
                "name": "Back Squat",
                "sequence": 2,
                "prescribed_reps": "10x",
                "notes": "Movement pattern prep"
            }
        ]
    },
    {
        "id": "20180627-block-5",
        "name": "Strength",
        "block_type": "push",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180627-ex-5-1",
                "name": "Back Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: Foot Elevated Hip Flexor Stretch + Pigeon between sets"
            }
        ]
    },
    {
        "id": "20180627-block-6",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 6,
        "exercises": [
            {
                "id": "20180627-ex-6-1",
                "name": "Push-Ups",
                "sequence": 1,
                "prescribed_reps": "10x"
            },
            {
                "id": "20180627-ex-6-2",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_reps": "15x"
            },
            {
                "id": "20180627-ex-6-3",
                "name": "Stationary Loaded Lunge",
                "sequence": 3,
                "prescribed_reps": "20x"
            },
            {
                "id": "20180627-ex-6-4",
                "name": "Lateral Hops",
                "sequence": 4,
                "prescribed_reps": "25x"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'June 27, 2018';


-- Fix "June 30, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180630-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180630-ex-1-1",
                "name": "Jump Rope",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180630-ex-1-2",
                "name": "SA KB Swing",
                "sequence": 2,
                "notes": "Power activation"
            },
            {
                "id": "20180630-ex-1-3",
                "name": "Goblet Squat",
                "sequence": 3,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "20180630-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180630-ex-2-1",
                "name": "Carioca",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180630-ex-2-2",
                "name": "High Knee March",
                "sequence": 2,
                "notes": "Hip flexor prep"
            },
            {
                "id": "20180630-ex-2-3",
                "name": "Alternating Shuffles",
                "sequence": 3,
                "notes": "Lateral movement"
            },
            {
                "id": "20180630-ex-2-4",
                "name": "Rear Lunge + Reach Up",
                "sequence": 4,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20180630-ex-2-5",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180630-ex-2-6",
                "name": "Rig: Swings, Sumo Squat",
                "sequence": 6,
                "notes": "Hip/shoulder prep"
            }
        ]
    },
    {
        "id": "20180630-block-3",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180630-ex-3-1",
                "name": "RDL",
                "sequence": 1,
                "prescribed_reps": "10x",
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180630-ex-3-2",
                "name": "Bent Row",
                "sequence": 2,
                "prescribed_reps": "10x",
                "notes": "Upper back activation"
            },
            {
                "id": "20180630-ex-3-3",
                "name": "Traditional Deadlift",
                "sequence": 3,
                "prescribed_reps": "10x",
                "notes": "Movement prep"
            }
        ]
    },
    {
        "id": "20180630-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180630-ex-4-1",
                "name": "Traditional Deadlift",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Set 5: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: Supine Hip Rotation between sets"
            },
            {
                "id": "20180630-ex-4-2",
                "name": "Seated DB Shoulder Press",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8-12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Birddog 10x w/ 2 sec pause between sets"
            }
        ]
    },
    {
        "id": "20180630-block-5",
        "name": "Conditioning - Chipper",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180630-ex-5-1",
                "name": "Jump Rope",
                "sequence": 1
            },
            {
                "id": "20180630-ex-5-2",
                "name": "Sit-Ups",
                "sequence": 2
            },
            {
                "id": "20180630-ex-5-3",
                "name": "SA KB Swing",
                "sequence": 3
            },
            {
                "id": "20180630-ex-5-4",
                "name": "Air Bike",
                "sequence": 4
            },
            {
                "id": "20180630-ex-5-5",
                "name": "Wall Ball",
                "sequence": 5
            },
            {
                "id": "20180630-ex-5-6",
                "name": "Mountain Climber",
                "sequence": 6
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'June 30, 2018';


-- Fix "July 3, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180703-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180703-ex-1-1",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180703-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180703-ex-2-1",
                "name": "Knee Hug",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180703-ex-2-2",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180703-ex-2-3",
                "name": "Lateral Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180703-ex-2-4",
                "name": "Bushwackers",
                "sequence": 4,
                "notes": "Full body"
            },
            {
                "id": "20180703-ex-2-5",
                "name": "Side Slide w/ Arm Swing",
                "sequence": 5,
                "notes": "Lateral movement"
            },
            {
                "id": "20180703-ex-2-6",
                "name": "Bear Crawl",
                "sequence": 6,
                "notes": "Core/shoulder"
            }
        ]
    },
    {
        "id": "20180703-block-3",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180703-ex-3-1",
                "name": "Face Pulls",
                "sequence": 1,
                "prescribed_reps": "15x",
                "notes": "Rear delt/rotator cuff"
            },
            {
                "id": "20180703-ex-3-2",
                "name": "SA Press",
                "sequence": 2,
                "prescribed_reps": "15/15x",
                "notes": "Shoulder activation"
            },
            {
                "id": "20180703-ex-3-3",
                "name": "Straight Arm Lat Pulldown",
                "sequence": 3,
                "prescribed_reps": "15x",
                "notes": "Lat activation"
            }
        ]
    },
    {
        "id": "20180703-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180703-ex-4-1",
                "name": "DB Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 7). Rest: 90 sec between sets Accessory: Pec Stretch between sets"
            },
            {
                "id": "20180703-ex-4-2",
                "name": "Bent BB Row (Underhand)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Seated Wall Angel 5x between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 3, 2018';


-- Fix "July 5, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180705-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180705-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180705-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180705-ex-2-1",
                "name": "Alternating Side Shuffle",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "20180705-ex-2-2",
                "name": "Quad Pull + Reach Up",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180705-ex-2-3",
                "name": "Carioca",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180705-ex-2-4",
                "name": "Lunge Palm to Instep",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180705-ex-2-5",
                "name": "High Knee March",
                "sequence": 5,
                "notes": "Hip flexor prep"
            },
            {
                "id": "20180705-ex-2-6",
                "name": "Lateral Lunge",
                "sequence": 6,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180705-ex-2-7",
                "name": "Supine Leg Kick",
                "sequence": 7,
                "notes": "10/10 - Hamstring"
            },
            {
                "id": "20180705-ex-2-8",
                "name": "Supine Leg Swing",
                "sequence": 8,
                "notes": "10/10 - Hip mobility"
            },
            {
                "id": "20180705-ex-2-9",
                "name": "Seated Groin",
                "sequence": 9,
                "notes": "Adductor stretch"
            },
            {
                "id": "20180705-ex-2-10",
                "name": "Seated Forward Bend",
                "sequence": 10,
                "notes": "Hamstring/back"
            }
        ]
    },
    {
        "id": "20180705-block-3",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180705-ex-3-1",
                "name": "RDL",
                "sequence": 1,
                "prescribed_reps": "10x Slow",
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180705-ex-3-2",
                "name": "Bent BB Row Overhand",
                "sequence": 2,
                "prescribed_reps": "10x",
                "notes": "Upper back activation"
            },
            {
                "id": "20180705-ex-3-3",
                "name": "Sumo DL",
                "sequence": 3,
                "prescribed_reps": "10x",
                "notes": "Movement prep"
            }
        ]
    },
    {
        "id": "20180705-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180705-ex-4-1",
                "name": "Sumo Deadlift (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Set 5: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Deep Squat Hold between sets"
            },
            {
                "id": "20180705-ex-4-2",
                "name": "Split Stance DB Curl to Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: 1/2 Kneel Hip Flexor/HS Stretch between sets"
            }
        ]
    },
    {
        "id": "20180705-block-5",
        "name": "Conditioning - 12 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180705-ex-5-1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_reps": "30x"
            },
            {
                "id": "20180705-ex-5-2",
                "name": "Slamball",
                "sequence": 2,
                "prescribed_reps": "20x"
            },
            {
                "id": "20180705-ex-5-3",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_reps": "15x"
            },
            {
                "id": "20180705-ex-5-4",
                "name": "Burpees",
                "sequence": 4,
                "prescribed_reps": "10x"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 5, 2018';


-- Fix "July 11, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180711-block-1",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180711-ex-1-1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "50x",
                "notes": "Cardio activation"
            },
            {
                "id": "20180711-ex-1-2",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "12x",
                "notes": "Upper back activation"
            },
            {
                "id": "20180711-ex-1-3",
                "name": "Push-Ups",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "12x",
                "notes": "Upper body prep"
            },
            {
                "id": "20180711-ex-1-4",
                "name": "Air Squat",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "12x",
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "20180711-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180711-ex-2-1",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "20180711-ex-2-2",
                "name": "High Knee March",
                "sequence": 2,
                "notes": "3 sec balance - Hip flexor prep"
            },
            {
                "id": "20180711-ex-2-3",
                "name": "Butt Kicks",
                "sequence": 3,
                "notes": "Quad activation"
            },
            {
                "id": "20180711-ex-2-4",
                "name": "Rear Lunge w/ Reach Up",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180711-ex-2-5",
                "name": "Leg Cradle",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20180711-ex-2-6",
                "name": "Trunk Rotation",
                "sequence": 6,
                "notes": "20x - T-spine mobility"
            },
            {
                "id": "20180711-ex-2-7",
                "name": "Good Morning",
                "sequence": 7,
                "notes": "12x - Hip hinge prep"
            },
            {
                "id": "20180711-ex-2-8",
                "name": "Split Squat w/ Press",
                "sequence": 8,
                "notes": "6/6x - Full body prep"
            },
            {
                "id": "20180711-ex-2-9",
                "name": "OHS",
                "sequence": 9,
                "notes": "12x - Shoulder/hip mobility"
            }
        ]
    },
    {
        "id": "20180711-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180711-ex-3-1",
                "name": "KB or DB Front Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 7). Rest: 90 sec between sets Accessory: 4 Point Bridge w/ Leg Ext. 10x between sets"
            },
            {
                "id": "20180711-ex-3-2",
                "name": "DB Curls (Beach Season!)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 45-60 sec between sets Accessory: Band Tricep Pressdown 15-20x between sets"
            }
        ]
    },
    {
        "id": "20180711-block-4",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180711-ex-4-1",
                "name": "Jump Rope or DU''s",
                "sequence": 1,
                "prescribed_reps": "35x"
            },
            {
                "id": "20180711-ex-4-2",
                "name": "KB Swings",
                "sequence": 2,
                "prescribed_reps": "25x"
            },
            {
                "id": "20180711-ex-4-3",
                "name": "Pull-Ups or TRX Rows",
                "sequence": 3,
                "prescribed_reps": "15x"
            },
            {
                "id": "20180711-ex-4-4",
                "name": "Burpees",
                "sequence": 4,
                "prescribed_reps": "10x"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 11, 2018';


-- Fix "July 12, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180712-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180712-ex-1-1",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180712-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180712-ex-2-1",
                "name": "Knee to Leg Cradle",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180712-ex-2-2",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180712-ex-2-3",
                "name": "Lunge w/ Palm to Instep",
                "sequence": 3,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180712-ex-2-4",
                "name": "Carioca",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180712-ex-2-5",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180712-ex-2-6",
                "name": "Yoga Flow",
                "sequence": 6,
                "notes": "Pigeon/Updog/Downdog - Full body mobility"
            }
        ]
    },
    {
        "id": "20180712-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180712-ex-3-1",
                "name": "Landmine Thrusters",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Mountain Climbers 20x between sets"
            },
            {
                "id": "20180712-ex-3-2",
                "name": "Landmine Rows",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Child''s Pose/Updog between sets"
            }
        ]
    },
    {
        "id": "20180712-block-4",
        "name": "Conditioning - 5 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180712-ex-4-1",
                "name": "Lateral Box Jumps",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10x",
                "notes": "5 rounds total"
            },
            {
                "id": "20180712-ex-4-2",
                "name": "HKTC/T2B",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "10x",
                "notes": "5 rounds total"
            },
            {
                "id": "20180712-ex-4-3",
                "name": "Wall Balls",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "10x",
                "notes": "5 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 12, 2018';


-- Fix "July 13, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180713-block-1",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180713-ex-1-1",
                "name": "Air Bike",
                "sequence": 1,
                "prescribed_sets": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "20180713-ex-1-2",
                "name": "Jump Rope",
                "sequence": 2,
                "prescribed_sets": 2,
                "notes": "Cardio"
            },
            {
                "id": "20180713-ex-1-3",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_sets": 2,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "20180713-block-2",
        "name": "Strength",
        "block_type": "push",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180713-ex-2-1",
                "name": "BB Strict Press to Push Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "5 strict + 5 push",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Wall Sit Wall Angels 10x between sets"
            },
            {
                "id": "20180713-ex-2-2",
                "name": "Loaded Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Hip Flexor/HS Stretch w/ box between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 13, 2018';


-- Fix "July 17, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180717-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180717-ex-1-1",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180717-ex-1-2",
                "name": "Back Lunge",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180717-ex-1-3",
                "name": "Shoulder Taps",
                "sequence": 3,
                "notes": "Core/shoulder stability"
            }
        ]
    },
    {
        "id": "20180717-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180717-ex-2-1",
                "name": "Knee Hug to Quad Pull",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180717-ex-2-2",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180717-ex-2-3",
                "name": "Hip Openers",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180717-ex-2-4",
                "name": "SL RDL w/ Reach",
                "sequence": 4,
                "notes": "Balance/hamstring"
            }
        ]
    },
    {
        "id": "20180717-block-3",
        "name": "Track Series (with Plates or DB)",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180717-ex-3-1",
                "name": "Rear Lunge w/ Press",
                "sequence": 1,
                "prescribed_reps": "12x",
                "notes": "Full body"
            },
            {
                "id": "20180717-ex-3-2",
                "name": "Squat w/ Front Raise",
                "sequence": 2,
                "prescribed_reps": "12x",
                "notes": "Lower/shoulder"
            },
            {
                "id": "20180717-ex-3-3",
                "name": "Bent Rear Delt Fly",
                "sequence": 3,
                "prescribed_reps": "12x",
                "notes": "Posterior shoulder"
            },
            {
                "id": "20180717-ex-3-4",
                "name": "Lateral Squat w/ Front Rack",
                "sequence": 4,
                "prescribed_reps": "12x",
                "notes": "Adductor/shoulder"
            }
        ]
    },
    {
        "id": "20180717-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180717-ex-4-1",
                "name": "Front Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Posted SL RDL 8/8 between sets"
            },
            {
                "id": "20180717-ex-4-2",
                "name": "Split Stance KB Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "8/8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: 1/2 Kneel Hip Flexor/Hamstring Stretch between sets"
            }
        ]
    },
    {
        "id": "20180717-block-5",
        "name": "Conditioning - 3 Rounds (16 min Cap)",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180717-ex-5-1",
                "name": "Row 300m or Bike 750m",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "-",
                "notes": "3 rounds total"
            },
            {
                "id": "20180717-ex-5-2",
                "name": "KB Swings",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "30x",
                "notes": "3 rounds total"
            },
            {
                "id": "20180717-ex-5-3",
                "name": "Starfish",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "20x",
                "notes": "3 rounds total"
            },
            {
                "id": "20180717-ex-5-4",
                "name": "Pull-Ups or Band Pulldown",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10x",
                "notes": "3 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 17, 2018';


-- Fix "July 18, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180718-block-1",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180718-ex-1-1",
                "name": "Lateral Low Step-Ups",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "50x",
                "notes": "Lateral activation"
            },
            {
                "id": "20180718-ex-1-2",
                "name": "\u00bd Burpee",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "15x",
                "notes": "Cardio activation"
            },
            {
                "id": "20180718-ex-1-3",
                "name": "TRX Rows",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "10x",
                "notes": "Upper back activation"
            }
        ]
    },
    {
        "id": "20180718-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180718-ex-2-1",
                "name": "High Knee March w/ 3 sec hold",
                "sequence": 1,
                "notes": "Hip flexor/balance"
            },
            {
                "id": "20180718-ex-2-2",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180718-ex-2-3",
                "name": "Leg Cradle",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180718-ex-2-4",
                "name": "Lunge w/ Reach Up + Twist",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180718-ex-2-5",
                "name": "Bear Crawl",
                "sequence": 5,
                "notes": "Core/shoulder"
            },
            {
                "id": "20180718-ex-2-6",
                "name": "Air Squat w/ 2 sec pause",
                "sequence": 6,
                "notes": "10x - Squat pattern"
            }
        ]
    },
    {
        "id": "20180718-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180718-ex-3-1",
                "name": "Alternating DB Flat Press to Double DB Flat Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8/8 alt + 8 double",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Standing TRX Chest Stretch between sets"
            },
            {
                "id": "20180718-ex-3-2",
                "name": "Farmers Walk",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Birddog 10x Slow between sets"
            }
        ]
    },
    {
        "id": "20180718-block-4",
        "name": "Conditioning - 3-5 Rounds (10'' Cap)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180718-ex-4-1",
                "name": "Box Jumps",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "9x",
                "notes": "5 rounds total"
            },
            {
                "id": "20180718-ex-4-2",
                "name": "DB Thrusters",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "12x",
                "notes": "5 rounds total"
            },
            {
                "id": "20180718-ex-4-3",
                "name": "TRX Rows",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "15x",
                "notes": "5 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 18, 2018';


-- Fix "July 19, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180719-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180719-ex-1-1",
                "name": "Row or Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180719-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180719-ex-2-1",
                "name": "Lunge w/ Palm to Instep",
                "sequence": 1,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180719-ex-2-2",
                "name": "Slow Backpedal",
                "sequence": 2,
                "notes": "Hip/hamstring"
            },
            {
                "id": "20180719-ex-2-3",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 3,
                "notes": "Lateral movement"
            },
            {
                "id": "20180719-ex-2-4",
                "name": "A-Skip",
                "sequence": 4,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180719-ex-2-5",
                "name": "Butt Kicks",
                "sequence": 5,
                "notes": "Quad activation"
            },
            {
                "id": "20180719-ex-2-6",
                "name": "Lateral A-Skip",
                "sequence": 6,
                "notes": "Lateral movement"
            },
            {
                "id": "20180719-ex-2-7",
                "name": "High Knees",
                "sequence": 7,
                "notes": "Hip flexor prep"
            },
            {
                "id": "20180719-ex-2-8",
                "name": "High Knee Carioca",
                "sequence": 8,
                "notes": "Hip mobility"
            },
            {
                "id": "20180719-ex-2-9",
                "name": "Lateral Plank Walk",
                "sequence": 9,
                "notes": "Core/shoulder"
            }
        ]
    },
    {
        "id": "20180719-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180719-ex-3-1",
                "name": "Back Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Heavy (RPE 7). Rest: 2-3 min between sets Accessory: Quad Stretch + Calf Stretch between sets"
            },
            {
                "id": "20180719-ex-3-2",
                "name": "DB Hammer Curl",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8-12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 60 sec between sets Accessory: Close Grip Push-Ups 10x between sets"
            }
        ]
    },
    {
        "id": "20180719-block-4",
        "name": "Core Cashout - 3-4 Rounds",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180719-ex-4-1",
                "name": "BOSU Mtn Climbers",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "30x"
            },
            {
                "id": "20180719-ex-4-2",
                "name": "SL Glute Bridge",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10"
            },
            {
                "id": "20180719-ex-4-3",
                "name": "Russ. Twist or Partner Throws",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "20x"
            },
            {
                "id": "20180719-ex-4-4",
                "name": "TRX Fallouts",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "10x"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 19, 2018';


-- Fix "July 25, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180725-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180725-ex-1-1",
                "name": "Air Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180725-ex-1-2",
                "name": "Step Up w/ High Knee",
                "sequence": 2,
                "notes": "Lower body activation"
            },
            {
                "id": "20180725-ex-1-3",
                "name": "\u00bd Burpee",
                "sequence": 3,
                "notes": "Cardio"
            },
            {
                "id": "20180725-ex-1-4",
                "name": "Push Ups",
                "sequence": 4,
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "20180725-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180725-ex-2-1",
                "name": "Side Shuffle w/ Swing",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "20180725-ex-2-2",
                "name": "Knee Hug w/ Hip Opener",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180725-ex-2-3",
                "name": "Quad Pull to Leg Cradle",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180725-ex-2-4",
                "name": "Walking Lunge w/ Twist",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180725-ex-2-5",
                "name": "Bear Crawl",
                "sequence": 5,
                "notes": "Core/shoulder"
            }
        ]
    },
    {
        "id": "20180725-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180725-ex-3-1",
                "name": "SA DB Chest Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8/8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Side Lying T-Rotations x5/5 between sets"
            },
            {
                "id": "20180725-ex-3-2",
                "name": "Landmine Rotation",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60 sec between sets Accessory: \u00bd Kneel Lifts 4 x 8/8 between sets"
            }
        ]
    },
    {
        "id": "20180725-block-4",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180725-ex-4-1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_reps": "30x"
            },
            {
                "id": "20180725-ex-4-2",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_reps": "12x"
            },
            {
                "id": "20180725-ex-4-3",
                "name": "Sit Ups",
                "sequence": 3,
                "prescribed_reps": "20x"
            },
            {
                "id": "20180725-ex-4-4",
                "name": "Wall Balls",
                "sequence": 4,
                "prescribed_reps": "15x"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 25, 2018';


-- Fix "July 26, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180726-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180726-ex-1-1",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180726-ex-1-2",
                "name": "Stationary Lunge",
                "sequence": 2,
                "notes": "Hip/leg prep"
            },
            {
                "id": "20180726-ex-1-3",
                "name": "Push-Ups",
                "sequence": 3,
                "notes": "Upper body prep"
            },
            {
                "id": "20180726-ex-1-4",
                "name": "TRX Rows",
                "sequence": 4,
                "notes": "Upper back activation"
            }
        ]
    },
    {
        "id": "20180726-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180726-ex-2-1",
                "name": "Knee Hug to Quad Pull",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180726-ex-2-2",
                "name": "Lateral Lunge",
                "sequence": 2,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180726-ex-2-3",
                "name": "Inchworms",
                "sequence": 3,
                "notes": "10x - Full body"
            },
            {
                "id": "20180726-ex-2-4",
                "name": "Lunge w/ Reach Up + Twist",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180726-ex-2-5",
                "name": "Toy Soldiers",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180726-ex-2-6",
                "name": "Lateral Push-off to Land",
                "sequence": 6,
                "notes": "Power/lateral"
            },
            {
                "id": "20180726-ex-2-7",
                "name": "Mini Band Work",
                "sequence": 7,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20180726-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180726-ex-3-1",
                "name": "Back Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: SA SL RDL 8/8 between sets"
            },
            {
                "id": "20180726-ex-3-2",
                "name": "Strict Pull-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8-10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Seated Wall Angel 5x between sets"
            }
        ]
    },
    {
        "id": "20180726-block-4",
        "name": "Conditioning - 12 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180726-ex-4-1",
                "name": "Air Bike",
                "sequence": 1,
                "prescribed_reps": "15/12 cal"
            },
            {
                "id": "20180726-ex-4-2",
                "name": "Box Jumps",
                "sequence": 2,
                "prescribed_reps": "15x"
            },
            {
                "id": "20180726-ex-4-3",
                "name": "Battle Rope Power Slams",
                "sequence": 3,
                "prescribed_reps": "30x"
            },
            {
                "id": "20180726-ex-4-4",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_reps": "15x"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 26, 2018';


-- Fix "July 30, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180730-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180730-ex-1-1",
                "name": "Run or Row or Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180730-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180730-ex-2-1",
                "name": "Knee Hug w/ Hip Opener",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180730-ex-2-2",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180730-ex-2-3",
                "name": "Leg Cradle",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180730-ex-2-4",
                "name": "Lateral Lunge",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180730-ex-2-5",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180730-ex-2-6",
                "name": "Bear Crawl",
                "sequence": 6,
                "notes": "Core/shoulder"
            },
            {
                "id": "20180730-ex-2-7",
                "name": "Supine Leg Kicks",
                "sequence": 7,
                "notes": "10x ea - Hamstring"
            },
            {
                "id": "20180730-ex-2-8",
                "name": "Supine Trunk Rotation",
                "sequence": 8,
                "notes": "10x - T-spine mobility"
            }
        ]
    },
    {
        "id": "20180730-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180730-ex-3-1",
                "name": "Split Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8/8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Shoulder Taps 10x SLOW between sets"
            },
            {
                "id": "20180730-ex-3-2",
                "name": "Standing DB Curl to Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Chest/Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180730-block-4",
        "name": "Conditioning - 12'' Ascending Ladder (5, 10, 15, 20...)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180730-ex-4-1",
                "name": "Air Squat",
                "sequence": 1
            },
            {
                "id": "20180730-ex-4-2",
                "name": "Push-Up",
                "sequence": 2
            },
            {
                "id": "20180730-ex-4-3",
                "name": "SA Swing",
                "sequence": 3
            },
            {
                "id": "20180730-ex-4-4",
                "name": "Jump Rope",
                "sequence": 4
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'July 30, 2018';


-- Fix "August 1, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180801-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180801-ex-1-1",
                "name": "Quick Step Ups",
                "sequence": 1,
                "prescribed_reps": "50x",
                "notes": "Cardio activation"
            },
            {
                "id": "20180801-ex-1-2",
                "name": "Quick Lateral Step Over",
                "sequence": 2,
                "prescribed_reps": "50x",
                "notes": "Lateral activation"
            }
        ]
    },
    {
        "id": "20180801-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180801-ex-2-1",
                "name": "Quad Pull to Knee Hug",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180801-ex-2-2",
                "name": "Lateral Lunge Opening Foot",
                "sequence": 2,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180801-ex-2-3",
                "name": "Carioca",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180801-ex-2-4",
                "name": "Rear Lunge + Reach Up",
                "sequence": 4,
                "notes": "Hip/T-spine"
            }
        ]
    },
    {
        "id": "20180801-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180801-ex-3-1",
                "name": "Sumo Deadlift (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Groin Stretch + SL RDL Balance between sets"
            },
            {
                "id": "20180801-ex-3-2",
                "name": "Chin-Ups or Band Pulldown",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 90 sec between sets Accessory: Cat/Cow 10x between sets"
            }
        ]
    },
    {
        "id": "20180801-block-4",
        "name": "Conditioning - 3-4 Rounds (10'' Cap)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180801-ex-4-1",
                "name": "Band Lifts",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180801-ex-4-2",
                "name": "Box Jumps",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180801-ex-4-3",
                "name": "Slamballs",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "16x",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 1, 2018';


-- Fix "August 2, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180802-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180802-ex-1-1",
                "name": "Row or Air Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "20180802-ex-1-2",
                "name": "Hollow Body Windshield Wiper",
                "sequence": 2,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180802-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180802-ex-2-1",
                "name": "Bushwackers",
                "sequence": 1,
                "notes": "Full body"
            },
            {
                "id": "20180802-ex-2-2",
                "name": "Bear Crawl",
                "sequence": 2,
                "notes": "Core/shoulder"
            },
            {
                "id": "20180802-ex-2-3",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 3,
                "notes": "Lateral movement"
            },
            {
                "id": "20180802-ex-2-4",
                "name": "Seal Jumping Jacks",
                "sequence": 4,
                "notes": "20x - Shoulder mobility"
            },
            {
                "id": "20180802-ex-2-5",
                "name": "Lateral Plank Walk",
                "sequence": 5,
                "notes": "Core/shoulder"
            },
            {
                "id": "20180802-ex-2-6",
                "name": "Lunge w/ Reach Up + Twist",
                "sequence": 6,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180802-ex-2-7",
                "name": "Inchworm w/ Push-Up",
                "sequence": 7,
                "notes": "10x - Full body prep"
            },
            {
                "id": "20180802-ex-2-8",
                "name": "Scap Warm-Up w/ Plates",
                "sequence": 8,
                "notes": "Shoulder activation"
            }
        ]
    },
    {
        "id": "20180802-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180802-ex-3-1",
                "name": "Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 5). Set 2: Moderate-Heavy (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Quadruped Trunk Rotation between sets"
            },
            {
                "id": "20180802-ex-3-2",
                "name": "DB Lateral Raise",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 45 sec between sets Accessory: DB Front Raise 10x between sets"
            }
        ]
    },
    {
        "id": "20180802-block-4",
        "name": "Conditioning - 3 Rounds (Interval)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180802-ex-4-1",
                "name": "Battle Rope",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            },
            {
                "id": "20180802-ex-4-2",
                "name": "Max Cal Row",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            },
            {
                "id": "20180802-ex-4-3",
                "name": "Plyo Spider Mtn Climbers",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 2, 2018';


-- Fix "August 6, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180806-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180806-ex-1-1",
                "name": "Run or Air Bike or Row",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180806-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180806-ex-2-1",
                "name": "Lunge w/ Reach Up + Twist",
                "sequence": 1,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180806-ex-2-2",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 2,
                "notes": "Lateral movement"
            },
            {
                "id": "20180806-ex-2-3",
                "name": "Bear Crawl",
                "sequence": 3,
                "notes": "Core/shoulder"
            },
            {
                "id": "20180806-ex-2-4",
                "name": "High Knee Carioca",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180806-ex-2-5",
                "name": "Quad Pull Hinge",
                "sequence": 5,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180806-ex-2-6",
                "name": "Knee Hug w/ Hip Opener",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "20180806-ex-2-7",
                "name": "Butt Kicks",
                "sequence": 7,
                "notes": "Quad activation"
            },
            {
                "id": "20180806-ex-2-8",
                "name": "High Knees",
                "sequence": 8,
                "notes": "Hip flexor prep"
            }
        ]
    },
    {
        "id": "20180806-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180806-ex-3-1",
                "name": "BB Strict Press",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Deadbug 10x SLOW between sets"
            },
            {
                "id": "20180806-ex-3-2",
                "name": "KB Front Rack Walking Lunge",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets"
            }
        ]
    },
    {
        "id": "20180806-block-4",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180806-ex-4-1",
                "name": "Run",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "1 Lap",
                "notes": "4 rounds total"
            },
            {
                "id": "20180806-ex-4-2",
                "name": "Goblet Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180806-ex-4-3",
                "name": "Push-Up",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "12x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180806-ex-4-4",
                "name": "TRX Row",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "15x",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 6, 2018';


-- Fix "August 7, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180807-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180807-ex-1-1",
                "name": "Row or Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180807-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180807-ex-2-1",
                "name": "Knee Hug to Quad Pull",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180807-ex-2-2",
                "name": "Rear Lunge w/ Reach Up",
                "sequence": 2,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180807-ex-2-3",
                "name": "Leg Cradle",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180807-ex-2-4",
                "name": "High Knee Carioca",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180807-ex-2-5",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180807-ex-2-6",
                "name": "Power A-Skip",
                "sequence": 6,
                "notes": "Dynamic power"
            },
            {
                "id": "20180807-ex-2-7",
                "name": "Lateral A-Skip",
                "sequence": 7,
                "notes": "Lateral movement"
            }
        ]
    },
    {
        "id": "20180807-block-3",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180807-ex-3-1",
                "name": "Good Morning",
                "sequence": 1,
                "prescribed_reps": "5x w/ pause",
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180807-ex-3-2",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_reps": "5x w/ pause",
                "notes": "Squat pattern"
            },
            {
                "id": "20180807-ex-3-3",
                "name": "Strict Press",
                "sequence": 3,
                "prescribed_reps": "5x",
                "notes": "Shoulder prep"
            },
            {
                "id": "20180807-ex-3-4",
                "name": "Push Press",
                "sequence": 4,
                "prescribed_reps": "5x",
                "notes": "Power prep"
            }
        ]
    },
    {
        "id": "20180807-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180807-ex-4-1",
                "name": "BB or KB Front Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Hip Flexor/Hamstring Stretch between sets"
            }
        ]
    },
    {
        "id": "20180807-block-5",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180807-ex-5-1",
                "name": "Burpee Box Jumps",
                "sequence": 1,
                "prescribed_reps": "10x"
            },
            {
                "id": "20180807-ex-5-2",
                "name": "KB Swing",
                "sequence": 2,
                "prescribed_reps": "15x"
            },
            {
                "id": "20180807-ex-5-3",
                "name": "Starfish",
                "sequence": 3,
                "prescribed_reps": "20x"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 7, 2018';


-- Fix "August 8, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180808-block-1",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180808-ex-1-1",
                "name": "Step Ups",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "30-50x",
                "notes": "Leg activation"
            },
            {
                "id": "20180808-ex-1-2",
                "name": "Push-Ups",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10-15x",
                "notes": "Upper body prep"
            },
            {
                "id": "20180808-ex-1-3",
                "name": "KB Swings",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "25-35x",
                "notes": "Power activation"
            }
        ]
    },
    {
        "id": "20180808-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180808-ex-2-1",
                "name": "High Knee March w/ pause",
                "sequence": 1,
                "notes": "Hip flexor/balance"
            },
            {
                "id": "20180808-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180808-ex-2-3",
                "name": "Leg Cradle",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180808-ex-2-4",
                "name": "Lunge w/ Reach Up + Twist",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180808-ex-2-5",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 5,
                "notes": "Lateral movement"
            },
            {
                "id": "20180808-ex-2-6",
                "name": "Squat w/ 3 sec pause",
                "sequence": 6,
                "notes": "Squat pattern"
            }
        ]
    },
    {
        "id": "20180808-block-3",
        "name": "Band Warm-Up",
        "block_type": "cardio",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180808-ex-3-1",
                "name": "Pull Apart",
                "sequence": 1,
                "prescribed_reps": "12x",
                "notes": "Rear delt/rhomboids"
            },
            {
                "id": "20180808-ex-3-2",
                "name": "Snatch Press",
                "sequence": 2,
                "prescribed_reps": "12x",
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180808-ex-3-3",
                "name": "Good Morning",
                "sequence": 3,
                "prescribed_reps": "12x",
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180808-ex-3-4",
                "name": "OH Squat",
                "sequence": 4,
                "prescribed_reps": "12x",
                "notes": "Shoulder/hip mobility"
            }
        ]
    },
    {
        "id": "20180808-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180808-ex-4-1",
                "name": "Alternating DB Press to Double",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10 alt + 10 double",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: TRX Chest Stretch between sets"
            },
            {
                "id": "20180808-ex-4-2",
                "name": "Suitcase Carry HEAVY",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: PB Glute Bridge 10x between sets"
            }
        ]
    },
    {
        "id": "20180808-block-5",
        "name": "Conditioning - Descending Ladder (20-16-12-8-4)",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180808-ex-5-1",
                "name": "Goblet Stationary Lunge",
                "sequence": 1
            },
            {
                "id": "20180808-ex-5-2",
                "name": "Rotational Slamball",
                "sequence": 2
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 8, 2018';


-- Fix "August 13, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180813-block-1",
        "name": "Active - 3 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180813-ex-1-1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "Cardio activation"
            },
            {
                "id": "20180813-ex-1-2",
                "name": "Air Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10x",
                "notes": "Lower body prep"
            },
            {
                "id": "20180813-ex-1-3",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15x",
                "notes": "Power activation"
            }
        ]
    },
    {
        "id": "20180813-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180813-ex-2-1",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "20180813-ex-2-2",
                "name": "Knee Hug to Hip Opener",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180813-ex-2-3",
                "name": "Carioca",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180813-ex-2-4",
                "name": "Push-Ups",
                "sequence": 4,
                "notes": "Upper body prep"
            },
            {
                "id": "20180813-ex-2-5",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180813-ex-2-6",
                "name": "Lateral Lunge",
                "sequence": 6,
                "notes": "Adductor mobility"
            }
        ]
    },
    {
        "id": "20180813-block-3",
        "name": "Shoulder Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180813-ex-3-1",
                "name": "Abduction to External Rotation",
                "sequence": 1,
                "prescribed_reps": "12x",
                "notes": "Rotator cuff"
            },
            {
                "id": "20180813-ex-3-2",
                "name": "Press",
                "sequence": 2,
                "prescribed_reps": "12x",
                "notes": "Shoulder activation"
            },
            {
                "id": "20180813-ex-3-3",
                "name": "A/T/Y",
                "sequence": 3,
                "prescribed_reps": "6 rounds",
                "notes": "Full shoulder prep"
            }
        ]
    },
    {
        "id": "20180813-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180813-ex-4-1",
                "name": "Strict Press to Push Press",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "8 strict + 8 push",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Dead Bug (SLOW) x 10 between sets"
            },
            {
                "id": "20180813-ex-4-2",
                "name": "DB Split Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "8/8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Standing Staggered Stance Hamstring Stretch x 5/5 between sets"
            }
        ]
    },
    {
        "id": "20180813-block-5",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180813-ex-5-1",
                "name": "KB Swing",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "25x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180813-ex-5-2",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "20x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180813-ex-5-3",
                "name": "Goblet Squat",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "15x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180813-ex-5-4",
                "name": "Burpees",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "10x",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 13, 2018';


-- Fix "August 14, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180814-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180814-ex-1-1",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180814-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180814-ex-2-1",
                "name": "Leg Cradle",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180814-ex-2-2",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180814-ex-2-3",
                "name": "Lateral Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "20180814-ex-2-4",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180814-ex-2-5",
                "name": "Bear Crawl",
                "sequence": 5,
                "notes": "Core/shoulder"
            },
            {
                "id": "20180814-ex-2-6",
                "name": "Hip Heist",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "20180814-ex-2-7",
                "name": "Leg Swings",
                "sequence": 7,
                "notes": "10x ea - Hip mobility"
            },
            {
                "id": "20180814-ex-2-8",
                "name": "Sumo Squat",
                "sequence": 8,
                "notes": "10x - Sumo stance prep"
            }
        ]
    },
    {
        "id": "20180814-block-3",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180814-ex-3-1",
                "name": "RDL",
                "sequence": 1,
                "prescribed_reps": "10x",
                "notes": "Hip hinge pattern"
            },
            {
                "id": "20180814-ex-3-2",
                "name": "Lateral Squat",
                "sequence": 2,
                "prescribed_reps": "10x",
                "notes": "Adductor prep"
            },
            {
                "id": "20180814-ex-3-3",
                "name": "Sumo DL",
                "sequence": 3,
                "prescribed_reps": "10x",
                "notes": "Movement prep"
            }
        ]
    },
    {
        "id": "20180814-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180814-ex-4-1",
                "name": "Sumo Deadlift",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Set 5: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: 4 Point Bridge w/ ext. 10x between sets"
            },
            {
                "id": "20180814-ex-4-2",
                "name": "Split Stance Row",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12/12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Banded Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20180814-block-5",
        "name": "Conditioning - 3 Rounds (Interval)",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180814-ex-5-1",
                "name": "HKTC",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            },
            {
                "id": "20180814-ex-5-2",
                "name": "Box Jumps",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            },
            {
                "id": "20180814-ex-5-3",
                "name": "Max Cal Row",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 14, 2018';


-- Fix "August 16, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180816-block-1",
        "name": "Active - 3 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180816-ex-1-1",
                "name": "Lateral Step Up",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "30x",
                "notes": "Lateral activation"
            },
            {
                "id": "20180816-ex-1-2",
                "name": "Rear Lunge w/ Reach Up",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10x",
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180816-ex-1-3",
                "name": "\u00bd Burpee",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10x",
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180816-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180816-ex-2-1",
                "name": "High Knee Carioca",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20180816-ex-2-2",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 2,
                "notes": "Lateral movement"
            },
            {
                "id": "20180816-ex-2-3",
                "name": "Quad Pull Hinge",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180816-ex-2-4",
                "name": "High Knees",
                "sequence": 4,
                "notes": "Hip flexor prep"
            },
            {
                "id": "20180816-ex-2-5",
                "name": "Backpedal",
                "sequence": 5,
                "notes": "Hip/hamstring"
            },
            {
                "id": "20180816-ex-2-6",
                "name": "Butt Kicks",
                "sequence": 6,
                "notes": "Quad activation"
            },
            {
                "id": "20180816-ex-2-7",
                "name": "A-Skip",
                "sequence": 7,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "20180816-ex-2-8",
                "name": "Lateral A-Skip",
                "sequence": 8,
                "notes": "Lateral movement"
            },
            {
                "id": "20180816-ex-2-9",
                "name": "Bushwackers",
                "sequence": 9,
                "notes": "Full body"
            }
        ]
    },
    {
        "id": "20180816-block-3",
        "name": "Band Work",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180816-ex-3-1",
                "name": "Face Pulls",
                "sequence": 1,
                "prescribed_reps": "15x",
                "notes": "Rear delt/rotator cuff"
            },
            {
                "id": "20180816-ex-3-2",
                "name": "SA Press",
                "sequence": 2,
                "prescribed_reps": "15/15x",
                "notes": "Shoulder activation"
            },
            {
                "id": "20180816-ex-3-3",
                "name": "Lat Pulldown",
                "sequence": 3,
                "prescribed_reps": "15x",
                "notes": "Lat activation"
            },
            {
                "id": "20180816-ex-3-4",
                "name": "Palloff Press w/ Rot.",
                "sequence": 4,
                "prescribed_reps": "15/15x",
                "notes": "Anti-rotation core"
            }
        ]
    },
    {
        "id": "20180816-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180816-ex-4-1",
                "name": "Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Band Pull Apart 10x between sets"
            },
            {
                "id": "20180816-ex-4-2",
                "name": "HEAVY Farmers Carry",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Rot. Plank 10x w/ 2 sec pause between sets"
            }
        ]
    },
    {
        "id": "20180816-block-5",
        "name": "Conditioning (Optional)",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180816-ex-5-1",
                "name": "Air Bike",
                "sequence": 1,
                "prescribed_reps": "50 calories",
                "notes": "Steady state cardio"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 16, 2018';


-- Fix "August 22, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180822-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180822-ex-1-1",
                "name": "Run or Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "20180822-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180822-ex-2-1",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "20180822-ex-2-2",
                "name": "Knee Hug to Hip Opener",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20180822-ex-2-3",
                "name": "Carioca",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20180822-ex-2-4",
                "name": "Quad Pull Hinge",
                "sequence": 4,
                "notes": "Quad/hip prep"
            },
            {
                "id": "20180822-ex-2-5",
                "name": "Butt Kicks",
                "sequence": 5,
                "notes": "Quad activation"
            },
            {
                "id": "20180822-ex-2-6",
                "name": "Knee Hug to Leg Cradle",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "20180822-ex-2-7",
                "name": "Lunge Palm to Instep",
                "sequence": 7,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180822-ex-2-8",
                "name": "Toy Soldier",
                "sequence": 8,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180822-ex-2-9",
                "name": "Hurdles",
                "sequence": 9,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "20180822-block-3",
        "name": "Movement Prep (w/ Small Plates)",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180822-ex-3-1",
                "name": "Abduction w/ ER",
                "sequence": 1,
                "prescribed_reps": "12x",
                "notes": "Rotator cuff"
            },
            {
                "id": "20180822-ex-3-2",
                "name": "Neutral Grip Press",
                "sequence": 2,
                "prescribed_reps": "12x",
                "notes": "Shoulder prep"
            },
            {
                "id": "20180822-ex-3-3",
                "name": "A/T/Y",
                "sequence": 3,
                "prescribed_reps": "6x",
                "notes": "Full shoulder activation"
            }
        ]
    },
    {
        "id": "20180822-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180822-ex-4-1",
                "name": "Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Quadruped Trunk Rot. 5/5 between sets"
            },
            {
                "id": "20180822-ex-4-2",
                "name": "Heavy Suitcase Carry",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Shoulder Taps 20x SLOW between sets"
            }
        ]
    },
    {
        "id": "20180822-block-5",
        "name": "Conditioning - Descending Ladder (20-15-10-5)",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180822-ex-5-1",
                "name": "Burpees",
                "sequence": 1
            },
            {
                "id": "20180822-ex-5-2",
                "name": "Pull-Ups / Band Pulldown",
                "sequence": 2
            },
            {
                "id": "20180822-ex-5-3",
                "name": "SA KB Swings",
                "sequence": 3
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 22, 2018';


-- Fix "August 28, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180828-block-1",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180828-ex-1-1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": ":30",
                "notes": "Cardio activation"
            },
            {
                "id": "20180828-ex-1-2",
                "name": "Rear Lunge Reach Up",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10x",
                "notes": "Hip/T-spine"
            },
            {
                "id": "20180828-ex-1-3",
                "name": "Shoulder Taps SLOW",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "20x",
                "notes": "Core/shoulder stability"
            },
            {
                "id": "20180828-ex-1-4",
                "name": "Squat w/ pause",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "10x",
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "20180828-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180828-ex-2-1",
                "name": "High Knee March",
                "sequence": 1,
                "notes": "Hip flexor prep"
            },
            {
                "id": "20180828-ex-2-2",
                "name": "SL RDL w/ Reach",
                "sequence": 2,
                "notes": "Balance/hamstring"
            },
            {
                "id": "20180828-ex-2-3",
                "name": "Lat. Shuffle w/ Arm Swing",
                "sequence": 3,
                "notes": "Lateral movement"
            },
            {
                "id": "20180828-ex-2-4",
                "name": "Bear Crawl",
                "sequence": 4,
                "notes": "Core/shoulder"
            }
        ]
    },
    {
        "id": "20180828-block-3",
        "name": "Empty Bar Warm-Up",
        "block_type": "cardio",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180828-ex-3-1",
                "name": "RDL",
                "sequence": 1,
                "prescribed_reps": "12x",
                "notes": "Hip hinge prep"
            },
            {
                "id": "20180828-ex-3-2",
                "name": "Curls",
                "sequence": 2,
                "prescribed_reps": "12x",
                "notes": "Bicep activation"
            },
            {
                "id": "20180828-ex-3-3",
                "name": "Bent Row Underhand",
                "sequence": 3,
                "prescribed_reps": "12x",
                "notes": "Back activation"
            }
        ]
    },
    {
        "id": "20180828-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180828-ex-4-1",
                "name": "Bent BB Row (Underhand)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Close Grip Push-Up 10-15x between sets"
            },
            {
                "id": "20180828-ex-4-2",
                "name": "Loaded Glute Bridge",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "8-12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 7). Rest: 60 sec between sets Accessory: Supine Trunk Rot. 10x between sets"
            }
        ]
    },
    {
        "id": "20180828-block-5",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20180828-ex-5-1",
                "name": "Burpees",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180828-ex-5-2",
                "name": "HKTC w/ Rotation",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "15x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180828-ex-5-3",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "25x",
                "notes": "4 rounds total"
            },
            {
                "id": "20180828-ex-5-4",
                "name": "Jump Rope",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "30x",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 28, 2018';


-- Fix "August 30, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180830-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180830-ex-1-1",
                "name": "Monsters",
                "sequence": 1,
                "prescribed_reps": "2x",
                "notes": "Full body activation"
            },
            {
                "id": "20180830-ex-1-2",
                "name": "Banded Bridge",
                "sequence": 2,
                "prescribed_reps": "30x",
                "notes": "Glute activation"
            },
            {
                "id": "20180830-ex-1-3",
                "name": "Banded Squats",
                "sequence": 3,
                "prescribed_reps": "30x",
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "20180830-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180830-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20180830-ex-2-2",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180830-ex-2-3",
                "name": "Push Up W/O",
                "sequence": 3,
                "notes": "Upper body prep"
            },
            {
                "id": "20180830-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180830-ex-2-5",
                "name": "Quad Pull",
                "sequence": 5,
                "notes": "Quad stretch"
            },
            {
                "id": "20180830-ex-2-6",
                "name": "Lunge + Reach",
                "sequence": 6,
                "notes": "Hip/T-spine"
            }
        ]
    },
    {
        "id": "20180830-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180830-ex-3-1",
                "name": "Lunges",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20180830-ex-3-2",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 9). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20180830-ex-3-3",
                "name": "SL Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 45 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "20180830-ex-3-4",
                "name": "SA Row",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 45 sec between sets Accessory: Biceps/Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'August 30, 2018';


-- Fix "September 18, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20180918-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180918-ex-1-1",
                "name": "Sumo Deadlift",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: Pigeon & Child''s Pose between sets"
            },
            {
                "id": "20180918-ex-1-2",
                "name": "Reverse Snow Angel",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10-15",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 6). Set 3: Bodyweight (RPE 7). Rest: 60 sec between sets Accessory: Hollow Rock Hold 30-45 sec between sets"
            }
        ]
    },
    {
        "id": "20180918-block-2",
        "name": "Post Workout",
        "block_type": "functional",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180918-ex-2-1",
                "name": "KB Crosswalk",
                "sequence": 1,
                "prescribed_reps": "4 x 2 D+B",
                "notes": "Heavy carry for grip/core"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'September 18, 2018';


-- Fix "September 19, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180919-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180919-ex-1-1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: SL Trunk Rotation between sets"
            },
            {
                "id": "20180919-ex-1-2",
                "name": "BB RDL to Wide Grip Bent Row",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "8-12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 75 sec between sets Accessory: Kneeling Hip Flexor/Hamstring stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'September 19, 2018';


-- Fix "September 27, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180927-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180927-ex-1-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light effort warmup"
            },
            {
                "id": "20180927-ex-1-2",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "1 min",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20180927-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180927-ex-2-1",
                "name": "Quad Pull/Knee Hug",
                "sequence": 1,
                "notes": "Hip/quad mobility"
            },
            {
                "id": "20180927-ex-2-2",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180927-ex-2-3",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor stretch"
            },
            {
                "id": "20180927-ex-2-4",
                "name": "A-Skip",
                "sequence": 4,
                "notes": "Dynamic warmup"
            },
            {
                "id": "20180927-ex-2-5",
                "name": "Push-Ups",
                "sequence": 5,
                "notes": "10 reps - upper body prep"
            }
        ]
    },
    {
        "id": "20180927-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180927-ex-3-1",
                "name": "Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "20180927-ex-3-2",
                "name": "Heavy Farmers Carry",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "",
                "notes": "Set 1: Heavy (RPE 7). Rest: 5 Burpees between each trip"
            }
        ]
    },
    {
        "id": "20180927-block-4",
        "name": "Cash Out",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20180927-ex-4-1",
                "name": "Ladder",
                "sequence": 1,
                "prescribed_reps": "1 round",
                "notes": "Footwork/agility"
            },
            {
                "id": "20180927-ex-4-2",
                "name": "Wall Sit",
                "sequence": 2,
                "prescribed_reps": "45 sec",
                "notes": "Quad endurance"
            },
            {
                "id": "20180927-ex-4-3",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "15 each",
                "notes": "Core rotation"
            },
            {
                "id": "20180927-ex-4-4",
                "name": "Air Squat",
                "sequence": 4,
                "prescribed_reps": "15",
                "notes": "Lower body flush"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'September 27, 2018';


-- Fix "September 28, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20180928-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180928-ex-1-1",
                "name": "Monster Walk",
                "sequence": 1,
                "prescribed_reps": "2 x 10e",
                "notes": "Glute/hip activation"
            }
        ]
    },
    {
        "id": "20180928-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180928-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor activation"
            },
            {
                "id": "20180928-ex-2-2",
                "name": "Spiderman",
                "sequence": 2,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20180928-ex-2-3",
                "name": "Hamstring Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180928-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20180928-ex-2-5",
                "name": "Lunge & Reach",
                "sequence": 5,
                "notes": "Hip/core prep"
            },
            {
                "id": "20180928-ex-2-6",
                "name": "Burpees",
                "sequence": 6,
                "notes": "10 reps - full body warmup"
            }
        ]
    },
    {
        "id": "20180928-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180928-ex-3-1",
                "name": "Single Leg Deadlift (S.L.D.L)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8 each",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: T.T.P (Toe Touch Progression) between sets"
            },
            {
                "id": "20180928-ex-3-2",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8 each",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'September 28, 2018';


-- Fix "September 29, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20180929-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20180929-ex-1-1",
                "name": "General Movement",
                "sequence": 1,
                "prescribed_reps": "5 min",
                "notes": "Light cardio"
            },
            {
                "id": "20180929-ex-1-2",
                "name": "Jumping Jacks",
                "sequence": 2,
                "prescribed_reps": "2 x 10 sec",
                "notes": "Elevate heart rate"
            }
        ]
    },
    {
        "id": "20180929-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20180929-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor activation"
            },
            {
                "id": "20180929-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20180929-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20180929-ex-2-4",
                "name": "Tin Soldier",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20180929-ex-2-5",
                "name": "Leg Swings",
                "sequence": 5,
                "notes": "Hip mobility (front/back)"
            },
            {
                "id": "20180929-ex-2-6",
                "name": "Hip Circles",
                "sequence": 6,
                "notes": "Hip joint mobility"
            },
            {
                "id": "20180929-ex-2-7",
                "name": "PVC Passover",
                "sequence": 7,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20180929-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20180929-ex-3-1",
                "name": "Single Leg Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "8 each",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 45 sec between sets"
            },
            {
                "id": "20180929-ex-3-2",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 8). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 9). Set 4: Bodyweight (RPE 9). Rest: 60-90 sec between sets"
            },
            {
                "id": "20180929-ex-3-3",
                "name": "Pull Ups",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 8). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 9). Set 4: Bodyweight (RPE 9). Rest: 90-120 sec between sets Accessory: Balance/Foam Roll between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'September 29, 2018';


-- Fix "October 2, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20181002-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181002-ex-1-1",
                "name": "BB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: 3 Way Lat Stretch between sets"
            },
            {
                "id": "20181002-ex-1-2",
                "name": "Bent BB Row (Overhand)",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Cat/Cow 5x between sets"
            }
        ]
    },
    {
        "id": "20181002-block-2",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181002-ex-2-1",
                "name": "Wall Ball",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15x",
                "notes": "4 rounds total"
            },
            {
                "id": "20181002-ex-2-2",
                "name": "Pull-Up or Pulldown",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12x",
                "notes": "4 rounds total"
            },
            {
                "id": "20181002-ex-2-3",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "9x",
                "notes": "4 rounds total"
            }
        ]
    },
    {
        "id": "20181002-block-3",
        "name": "Core Auxiliary - 3 Rounds",
        "block_type": "core",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181002-ex-3-1",
                "name": "Bosu Mountain Climber",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "20x"
            },
            {
                "id": "20181002-ex-3-2",
                "name": "Russian Twists",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "20x"
            },
            {
                "id": "20181002-ex-3-3",
                "name": "Plank Walk-Up",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10x"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 2, 2018';


-- Fix "October 3, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181003-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181003-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Cardio warmup"
            },
            {
                "id": "20181003-ex-1-2",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "1 min",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20181003-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181003-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20181003-ex-2-2",
                "name": "Arm Circles",
                "sequence": 2,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181003-ex-2-3",
                "name": "Lunge & Twist",
                "sequence": 3,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20181003-ex-2-4",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181003-ex-2-5",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warmup"
            },
            {
                "id": "20181003-ex-2-6",
                "name": "Burpees",
                "sequence": 6,
                "notes": "10x full body activation"
            }
        ]
    },
    {
        "id": "20181003-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181003-ex-3-1",
                "name": "Slant Bar Triple Extension",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Rest: 60-90 sec between sets Accessory: Hinge Quad Pull between sets"
            },
            {
                "id": "20181003-ex-3-2",
                "name": "TGU (Turkish Get-Up)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5 each side",
                "notes": "Set 1: Moderate (RPE 7). Rest: As needed between sides Accessory: PVC Passover between sets"
            },
            {
                "id": "20181003-ex-3-3",
                "name": "1/2 Kneel Press",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: 5 Push-Ups between each set"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 3, 2018';


-- Fix "October 4, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181004-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181004-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Cardio warmup"
            },
            {
                "id": "20181004-ex-1-2",
                "name": "Monster Walk",
                "sequence": 2,
                "prescribed_reps": "Full",
                "notes": "Hip activation"
            }
        ]
    },
    {
        "id": "20181004-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181004-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181004-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20181004-ex-2-3",
                "name": "Hamstring Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181004-ex-2-4",
                "name": "Spidermans",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20181004-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181004-ex-2-6",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x upper body activation"
            }
        ]
    },
    {
        "id": "20181004-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181004-ex-3-1",
                "name": "D.B. Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "20181004-ex-3-2",
                "name": "S.L.D.L. (Stiff Leg Deadlift)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8 each side",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: T.T.P. (Toe Touch Progression) between sets"
            }
        ]
    },
    {
        "id": "20181004-block-4",
        "name": "Core Cash Out",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181004-ex-4-1",
                "name": "Russian Twist",
                "sequence": 1,
                "prescribed_reps": "12 each side"
            },
            {
                "id": "20181004-ex-4-2",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "1 min"
            },
            {
                "id": "20181004-ex-4-3",
                "name": "Med Ball Toe Taps",
                "sequence": 3,
                "prescribed_reps": "12"
            },
            {
                "id": "20181004-ex-4-4",
                "name": "Push-Ups",
                "sequence": 4,
                "prescribed_reps": "12"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 4, 2018';


-- Fix "October 5, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20181005-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181005-ex-1-1",
                "name": "Clams",
                "sequence": 1,
                "prescribed_reps": "20x each",
                "notes": "Hip activation"
            },
            {
                "id": "20181005-ex-1-2",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_reps": "20x",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20181005-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181005-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181005-ex-2-2",
                "name": "Lunge & Reach",
                "sequence": 2,
                "notes": "Hip/T-spine"
            },
            {
                "id": "20181005-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181005-ex-2-4",
                "name": "Bear Crawl",
                "sequence": 4,
                "notes": "Full body warmup (meters)"
            },
            {
                "id": "20181005-ex-2-5",
                "name": "Push-Up Walkout",
                "sequence": 5,
                "notes": "Upper body/core"
            },
            {
                "id": "20181005-ex-2-6",
                "name": "Quad Pull",
                "sequence": 6,
                "notes": "Quad stretch"
            }
        ]
    },
    {
        "id": "20181005-block-3",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181005-ex-3-1",
                "name": "KB Swings",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "50x",
                "notes": "2 rounds total"
            },
            {
                "id": "20181005-ex-3-2",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "40x",
                "notes": "2 rounds total"
            },
            {
                "id": "20181005-ex-3-3",
                "name": "Goblet Squat",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "30x",
                "notes": "2 rounds total"
            },
            {
                "id": "20181005-ex-3-4",
                "name": "SA Press",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "20x each",
                "notes": "2 rounds total"
            },
            {
                "id": "20181005-ex-3-5",
                "name": "TGU",
                "sequence": 5,
                "prescribed_sets": 2,
                "prescribed_reps": "10x (5 each)",
                "notes": "2 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 5, 2018';


-- Fix "October 8, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181008-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181008-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Cardio warmup"
            },
            {
                "id": "20181008-ex-1-2",
                "name": "SL Bridge",
                "sequence": 2,
                "prescribed_reps": "20x each",
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20181008-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181008-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181008-ex-2-2",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad stretch with hip hinge"
            },
            {
                "id": "20181008-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181008-ex-2-4",
                "name": "Over Under",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20181008-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181008-ex-2-6",
                "name": "Piriformis",
                "sequence": 6,
                "notes": "Hip external rotation"
            },
            {
                "id": "20181008-ex-2-7",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x upper body activation"
            }
        ]
    },
    {
        "id": "20181008-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181008-ex-3-1",
                "name": "Bar Thrusters",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181008-ex-3-2",
                "name": "Renegade Row",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10 each",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20181008-block-4",
        "name": "Conditioning - EMOM 5 min (Repeat 2-3x)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181008-ex-4-1",
                "name": "Plank",
                "sequence": 1
            },
            {
                "id": "20181008-ex-4-2",
                "name": "Goblet Squat",
                "sequence": 2
            },
            {
                "id": "20181008-ex-4-3",
                "name": "Jump Rope",
                "sequence": 3
            },
            {
                "id": "20181008-ex-4-4",
                "name": "Dead Bugs",
                "sequence": 4
            },
            {
                "id": "20181008-ex-4-5",
                "name": "Push Press",
                "sequence": 5
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 8, 2018';


-- Fix "October 9, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181009-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181009-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "3 min",
                "notes": "Extended cardio warmup"
            }
        ]
    },
    {
        "id": "20181009-block-2",
        "name": "Intro - 12 min EMOM",
        "block_type": "functional",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181009-ex-2-1",
                "name": "Shoulder Taps",
                "sequence": 1,
                "prescribed_reps": "20"
            },
            {
                "id": "20181009-ex-2-2",
                "name": "Bike/Row",
                "sequence": 2,
                "prescribed_reps": "10 cal"
            },
            {
                "id": "20181009-ex-2-3",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "12 each side"
            },
            {
                "id": "20181009-ex-2-4",
                "name": "Slamballs",
                "sequence": 4,
                "prescribed_reps": "15"
            }
        ]
    },
    {
        "id": "20181009-block-3",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181009-ex-3-1",
                "name": "PVC Passover",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181009-ex-3-2",
                "name": "Push-Ups",
                "sequence": 2,
                "notes": "10x upper body activation"
            },
            {
                "id": "20181009-ex-3-3",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20181009-ex-3-4",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181009-ex-3-5",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20181009-ex-3-6",
                "name": "High Knee Skip",
                "sequence": 6,
                "notes": "Dynamic warmup"
            }
        ]
    },
    {
        "id": "20181009-block-4",
        "name": "Conditioning - 8 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181009-ex-4-1",
                "name": "Air Squats",
                "sequence": 1,
                "prescribed_reps": "20"
            },
            {
                "id": "20181009-ex-4-2",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "20181009-ex-4-3",
                "name": "TRX Rows / Pull-Ups",
                "sequence": 3,
                "prescribed_reps": "10"
            },
            {
                "id": "20181009-ex-4-4",
                "name": "Push-Ups",
                "sequence": 4,
                "prescribed_reps": "5"
            }
        ]
    },
    {
        "id": "20181009-block-5",
        "name": "Finisher - 2 Rounds",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "20181009-ex-5-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 2
            },
            {
                "id": "20181009-ex-5-2",
                "name": "Plank",
                "sequence": 2,
                "prescribed_sets": 2
            },
            {
                "id": "20181009-ex-5-3",
                "name": "Farmer Carry",
                "sequence": 3,
                "prescribed_sets": 2
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 9, 2018';


-- Fix "October 10, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181010-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181010-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181010-ex-1-2",
                "name": "Monster Walks",
                "sequence": 2,
                "prescribed_reps": "2x",
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20181010-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181010-ex-2-1",
                "name": "Arm Circles",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181010-ex-2-2",
                "name": "High Knee Pull",
                "sequence": 2,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181010-ex-2-3",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20181010-ex-2-4",
                "name": "Bear Crawl (s)",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "20181010-ex-2-5",
                "name": "Hamstring Walk",
                "sequence": 5,
                "notes": "Hamstring prep"
            },
            {
                "id": "20181010-ex-2-6",
                "name": "Over & Unders",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "20181010-ex-2-7",
                "name": "Burpees",
                "sequence": 7,
                "notes": "10x - Full body warmup"
            }
        ]
    },
    {
        "id": "20181010-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181010-ex-3-1",
                "name": "Sumo Deadlift",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: T.T.P (Touch Toes, Pulse) between sets"
            },
            {
                "id": "20181010-ex-3-2",
                "name": "Turkish Get-Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Light-Moderate (RPE 7). Rest: As needed between sides Accessory: PVC Passover between sets"
            },
            {
                "id": "20181010-ex-3-3",
                "name": "Single Leg Bridges",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "20 total",
                "notes": "Set 1: Bodyweight (RPE 6)"
            }
        ]
    },
    {
        "id": "20181010-block-4",
        "name": "Conditioning - Chipper (1 Round)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181010-ex-4-1",
                "name": "Sit-Ups",
                "sequence": 1,
                "prescribed_sets": 1,
                "prescribed_reps": "40",
                "notes": "1 rounds total"
            },
            {
                "id": "20181010-ex-4-2",
                "name": "Wall Sit",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "90\"",
                "notes": "1 rounds total"
            },
            {
                "id": "20181010-ex-4-3",
                "name": "Jump Rope",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "150 s/u",
                "notes": "1 rounds total"
            },
            {
                "id": "20181010-ex-4-4",
                "name": "SA KB Swing",
                "sequence": 4,
                "prescribed_sets": 1,
                "prescribed_reps": "20e",
                "notes": "1 rounds total"
            },
            {
                "id": "20181010-ex-4-5",
                "name": "Burpees",
                "sequence": 5,
                "prescribed_sets": 1,
                "prescribed_reps": "20",
                "notes": "1 rounds total"
            },
            {
                "id": "20181010-ex-4-6",
                "name": "Dead Bugs",
                "sequence": 6,
                "prescribed_sets": 1,
                "prescribed_reps": "20e",
                "notes": "1 rounds total"
            },
            {
                "id": "20181010-ex-4-7",
                "name": "Row/Bike",
                "sequence": 7,
                "prescribed_sets": 1,
                "prescribed_reps": "20 cal",
                "notes": "1 rounds total"
            },
            {
                "id": "20181010-ex-4-8",
                "name": "Push-Ups",
                "sequence": 8,
                "prescribed_sets": 1,
                "prescribed_reps": "20",
                "notes": "1 rounds total"
            },
            {
                "id": "20181010-ex-4-9",
                "name": "TGU",
                "sequence": 9,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "1 rounds total"
            },
            {
                "id": "20181010-ex-4-10",
                "name": "Mtn Climbers",
                "sequence": 10,
                "prescribed_sets": 1,
                "prescribed_reps": "20e",
                "notes": "1 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 10, 2018';


-- Fix "October 11, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181011-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181011-ex-1-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181011-ex-1-2",
                "name": "SL Bridges",
                "sequence": 2,
                "prescribed_reps": "20x",
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20181011-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181011-ex-2-1",
                "name": "Lunge + Reach",
                "sequence": 1,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20181011-ex-2-2",
                "name": "Big Arm Circles",
                "sequence": 2,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181011-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring/hip flexor"
            },
            {
                "id": "20181011-ex-2-4",
                "name": "Hip Opener",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20181011-ex-2-5",
                "name": "Quad Pull",
                "sequence": 5,
                "notes": "Quad stretch"
            },
            {
                "id": "20181011-ex-2-6",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body prep"
            },
            {
                "id": "20181011-ex-2-7",
                "name": "High Knee Skip",
                "sequence": 7,
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "20181011-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181011-ex-3-1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181011-ex-3-2",
                "name": "Single Leg Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Bodyweight/Light (RPE 7). Set 3: Bodyweight/Light (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181011-ex-3-3",
                "name": "Circuit (x2 Rounds)",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": ""
            },
            {
                "id": "20181011-ex-3-4",
                "name": "Slant Bar Twist",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 45 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "20181011-block-4",
        "name": "Conditioning - 9 min EMOM",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181011-ex-4-1",
                "name": "Thruster",
                "sequence": 1,
                "prescribed_reps": "30\""
            },
            {
                "id": "20181011-ex-4-2",
                "name": "Pull-Up/Dead Hang",
                "sequence": 2,
                "prescribed_reps": "30\""
            },
            {
                "id": "20181011-ex-4-3",
                "name": "Row/Bike",
                "sequence": 3,
                "prescribed_reps": "30\""
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 11, 2018';


-- Fix "October 15, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20181015-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181015-ex-1-1",
                "name": "Bear Crawl 4-Way",
                "sequence": 1,
                "prescribed_reps": "2x",
                "notes": "Full body activation"
            },
            {
                "id": "20181015-ex-1-2",
                "name": "Row/Bike",
                "sequence": 2,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            }
        ]
    },
    {
        "id": "20181015-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181015-ex-2-1",
                "name": "Arm Circles",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181015-ex-2-2",
                "name": "Hip Openers",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20181015-ex-2-3",
                "name": "Push-Up Walkout",
                "sequence": 3,
                "notes": "Upper body/core prep"
            },
            {
                "id": "20181015-ex-2-4",
                "name": "High Knee Skip",
                "sequence": 4,
                "notes": "Lower body activation"
            },
            {
                "id": "20181015-ex-2-5",
                "name": "High Knee Pull",
                "sequence": 5,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181015-ex-2-6",
                "name": "PVC Figure 8",
                "sequence": 6,
                "notes": "Shoulder/T-spine mobility"
            }
        ]
    },
    {
        "id": "20181015-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181015-ex-3-1",
                "name": "Pull-Ups / Low TRX Rows",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8-10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20181015-ex-3-2",
                "name": "Slant Bar 3-Way Extension",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Pigeon stretch between sets"
            }
        ]
    },
    {
        "id": "20181015-block-4",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181015-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m"
            },
            {
                "id": "20181015-ex-4-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "20181015-ex-4-3",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_reps": "10x"
            },
            {
                "id": "20181015-ex-4-4",
                "name": "1/2 Kneeling Chop",
                "sequence": 4,
                "prescribed_reps": "6e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 15, 2018';


-- Fix "October 16, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181016-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181016-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181016-ex-1-2",
                "name": "Monster Walk",
                "sequence": 2,
                "prescribed_reps": "2x",
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20181016-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181016-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20181016-ex-2-2",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring/hip flexor"
            },
            {
                "id": "20181016-ex-2-3",
                "name": "PVC Passover",
                "sequence": 3,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181016-ex-2-4",
                "name": "PVC Good Morning",
                "sequence": 4,
                "notes": "10x - Hip hinge prep"
            },
            {
                "id": "20181016-ex-2-5",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20181016-ex-2-6",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "20181016-block-3",
        "name": "Intro - 9 min EMOM",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181016-ex-3-1",
                "name": "Plank",
                "sequence": 1,
                "prescribed_reps": "40\""
            },
            {
                "id": "20181016-ex-3-2",
                "name": "Bike/Row",
                "sequence": 2,
                "prescribed_reps": "40\""
            },
            {
                "id": "20181016-ex-3-3",
                "name": "Sit-Up",
                "sequence": 3,
                "prescribed_reps": "40\""
            }
        ]
    },
    {
        "id": "20181016-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181016-ex-4-1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "20181016-block-5",
        "name": "Conditioning - 12 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20181016-ex-5-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "12 cal"
            },
            {
                "id": "20181016-ex-5-2",
                "name": "KB Push Press",
                "sequence": 2,
                "prescribed_reps": "10x"
            },
            {
                "id": "20181016-ex-5-3",
                "name": "Squats",
                "sequence": 3,
                "prescribed_reps": "10x"
            },
            {
                "id": "20181016-ex-5-4",
                "name": "V-Ups",
                "sequence": 4,
                "prescribed_reps": "10x"
            }
        ]
    },
    {
        "id": "20181016-block-6",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 6,
        "exercises": [
            {
                "id": "20181016-ex-6-1",
                "name": "Rope Climb",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "1x",
                "notes": "2 rounds total"
            },
            {
                "id": "20181016-ex-6-2",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10x",
                "notes": "2 rounds total"
            },
            {
                "id": "20181016-ex-6-3",
                "name": "Jump Rope",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "50x",
                "notes": "2 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 16, 2018';


-- Fix "October 17, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181017-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181017-ex-1-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            }
        ]
    },
    {
        "id": "20181017-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181017-ex-2-1",
                "name": "Arm Circles",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181017-ex-2-2",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20181017-ex-2-3",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181017-ex-2-4",
                "name": "Push-Up Walkout",
                "sequence": 4,
                "notes": "Upper body/core prep"
            },
            {
                "id": "20181017-ex-2-5",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181017-ex-2-6",
                "name": "Spiderman",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "20181017-ex-2-7",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "20181017-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181017-ex-3-1",
                "name": "Single Leg Deadlift (SL DL)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 7). Rest: 60-90 sec between sets Accessory: TTP (Touch Toes, Pulse) between sets"
            },
            {
                "id": "20181017-ex-3-2",
                "name": "Renegade Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20181017-ex-3-3",
                "name": "Box Jumps / Step-Ups",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "25 total",
                "notes": "Set 1: Bodyweight (RPE 7)"
            }
        ]
    },
    {
        "id": "20181017-block-4",
        "name": "Conditioning - EMOM 10 min",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181017-ex-4-1",
                "name": "Burpees",
                "sequence": 1,
                "prescribed_reps": "10x"
            },
            {
                "id": "20181017-ex-4-2",
                "name": "TGU",
                "sequence": 2,
                "prescribed_reps": "1e"
            }
        ]
    },
    {
        "id": "20181017-block-5",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20181017-ex-5-1",
                "name": "KB Swings",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10x",
                "notes": "4 rounds total"
            },
            {
                "id": "20181017-ex-5-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "4 rounds total"
            },
            {
                "id": "20181017-ex-5-3",
                "name": "Slamball",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10x",
                "notes": "4 rounds total"
            },
            {
                "id": "20181017-ex-5-4",
                "name": "Broad Jump",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "10x",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 17, 2018';


-- Fix "October 19, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20181019-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181019-ex-1-1",
                "name": "Clams",
                "sequence": 1,
                "prescribed_reps": "20e",
                "notes": "Glute activation"
            },
            {
                "id": "20181019-ex-1-2",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_reps": "20x",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20181019-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181019-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181019-ex-2-2",
                "name": "Lunge & Reach",
                "sequence": 2,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20181019-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181019-ex-2-4",
                "name": "Bear Crawl (m)",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "20181019-ex-2-5",
                "name": "Push-Up Walkout",
                "sequence": 5,
                "notes": "Upper body/core prep"
            },
            {
                "id": "20181019-ex-2-6",
                "name": "Quad Pull",
                "sequence": 6,
                "notes": "Quad stretch"
            },
            {
                "id": "20181019-ex-2-7",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "20181019-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181019-ex-3-1",
                "name": "KB Front Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181019-ex-3-2",
                "name": "Cardio Finisher",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "30 cal",
                "notes": ""
            }
        ]
    },
    {
        "id": "20181019-block-4",
        "name": "Conditioning - Circuit 1",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181019-ex-4-1",
                "name": "Bosu Mtn Climbers",
                "sequence": 1,
                "prescribed_reps": "30\""
            },
            {
                "id": "20181019-ex-4-2",
                "name": "OH PVC Squat",
                "sequence": 2,
                "prescribed_reps": "10x"
            },
            {
                "id": "20181019-ex-4-3",
                "name": "Sit-Ups",
                "sequence": 3,
                "prescribed_reps": "15x"
            },
            {
                "id": "20181019-ex-4-4",
                "name": "Dec. Shoulder Taps",
                "sequence": 4,
                "prescribed_reps": "10e"
            },
            {
                "id": "20181019-ex-4-5",
                "name": "SA Press",
                "sequence": 5,
                "prescribed_reps": "10e"
            }
        ]
    },
    {
        "id": "20181019-block-5",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20181019-ex-5-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "250m",
                "notes": "3 rounds total"
            },
            {
                "id": "20181019-ex-5-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12e",
                "notes": "3 rounds total"
            },
            {
                "id": "20181019-ex-5-3",
                "name": "Box Jumps",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "12x",
                "notes": "3 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 19, 2018';


-- Fix "October 22, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 45,
    exercises = '[
    {
        "id": "20181022-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181022-ex-1-1",
                "name": "Chin-Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 9). Rest: 90-120 sec between sets Accessory: Bicep/Lat stretch between sets"
            },
            {
                "id": "20181022-ex-1-2",
                "name": "Single-Leg Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10 each",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 22, 2018';


-- Fix "October 23, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181023-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181023-ex-1-1",
                "name": "Bar Thrusters",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 23, 2018';


-- Fix "October 24, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181024-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181024-ex-1-1",
                "name": "Bench Press (BB or DB)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Moderate-Heavy (RPE 7). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 8). Set 4: Heavy (RPE 8). Set 5: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181024-ex-1-2",
                "name": "Conditioning Block A",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "35 cals",
                "notes": ""
            },
            {
                "id": "20181024-ex-1-3",
                "name": "Bent-Over-Rows",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "8 each",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20181024-ex-1-4",
                "name": "Conditioning Block B - 25-20-15",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": ""
            },
            {
                "id": "20181024-ex-1-5",
                "name": "OH Split Squat",
                "sequence": 5,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light-Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 24, 2018';


-- Fix "October 26, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20181026-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181026-ex-1-1",
                "name": "Half-Kneel Single-Arm Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8 each",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181026-ex-1-2",
                "name": "Tricep Extension",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 26, 2018';


-- Fix "October 29, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20181029-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181029-ex-1-1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light-Moderate (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181029-ex-1-2",
                "name": "Single-Leg RDL",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8 each",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60-90 sec between sets Accessory: TTP (Toes To Post) stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 29, 2018';


-- Fix "October 30, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181030-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181030-ex-1-1",
                "name": "KB Front Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Moderate (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'October 30, 2018';


-- Fix "November 1, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181101-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181101-ex-1-1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_reps": "1 min",
                "notes": "Light cardio warmup"
            },
            {
                "id": "20181101-ex-1-2",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "1 min",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20181101-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181101-ex-2-1",
                "name": "Hip Opener",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20181101-ex-2-2",
                "name": "Spiderman",
                "sequence": 2,
                "notes": "Hip flexor/groin"
            },
            {
                "id": "20181101-ex-2-3",
                "name": "High Knee Pull",
                "sequence": 3,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181101-ex-2-4",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Adductor stretch"
            },
            {
                "id": "20181101-ex-2-5",
                "name": "Quad Pull",
                "sequence": 5,
                "notes": "Quad stretch"
            },
            {
                "id": "20181101-ex-2-6",
                "name": "PVC Passover",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181101-ex-2-7",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x - Upper body activation"
            }
        ]
    },
    {
        "id": "20181101-block-3",
        "name": "EMOM 9 min",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181101-ex-3-1",
                "name": "Slamballs",
                "sequence": 1,
                "prescribed_reps": "15",
                "notes": "Full extension"
            },
            {
                "id": "20181101-ex-3-2",
                "name": "Farmer Carry Hold",
                "sequence": 2,
                "prescribed_reps": "45\"",
                "notes": "Heavy KBs"
            },
            {
                "id": "20181101-ex-3-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "15e",
                "notes": "Controlled"
            }
        ]
    },
    {
        "id": "20181101-block-4",
        "name": "Cash Out",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181101-ex-4-1",
                "name": "Russian Twist",
                "sequence": 1,
                "prescribed_reps": "20e",
                "notes": "Weighted if possible"
            },
            {
                "id": "20181101-ex-4-2",
                "name": "Monkey Bar",
                "sequence": 2,
                "prescribed_reps": "1x",
                "notes": "Full traverse"
            },
            {
                "id": "20181101-ex-4-3",
                "name": "Bear Crawl",
                "sequence": 3,
                "prescribed_reps": "5 lengths",
                "notes": "Controlled"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 1, 2018';


-- Fix "November 2, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20181102-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181102-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m",
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181102-ex-1-2",
                "name": "Air Squat",
                "sequence": 2,
                "prescribed_reps": "30x",
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "20181102-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181102-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20181102-ex-2-2",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181102-ex-2-3",
                "name": "High Knee Skip",
                "sequence": 3,
                "notes": "Hip flexor activation"
            },
            {
                "id": "20181102-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181102-ex-2-5",
                "name": "Hip Openers",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "20181102-ex-2-6",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body activation"
            }
        ]
    },
    {
        "id": "20181102-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181102-ex-3-1",
                "name": "Half-Kneel Single-Arm Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181102-ex-3-2",
                "name": "Turkish Get-Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Moderate (RPE 7). Rest: As needed between sides Accessory: Single-Leg Rotation between sets"
            }
        ]
    },
    {
        "id": "20181102-block-4",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181102-ex-4-1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "50",
                "notes": "Single-unders. 4 rounds total"
            },
            {
                "id": "20181102-ex-4-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Weighted. 4 rounds total"
            },
            {
                "id": "20181102-ex-4-3",
                "name": "Half-Kneel Chop",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "Cable or band. 4 rounds total"
            },
            {
                "id": "20181102-ex-4-4",
                "name": "Lateral Skater",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "15e",
                "notes": "Explosive. 4 rounds total"
            },
            {
                "id": "20181102-ex-4-5",
                "name": "Burpees",
                "sequence": 5,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Full extension. 4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 2, 2018';


-- Fix "November 6, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181106-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181106-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181106-ex-1-2",
                "name": "Air Squats",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Lower body activation"
            },
            {
                "id": "20181106-ex-1-3",
                "name": "Push-Ups",
                "sequence": 3,
                "prescribed_reps": "10",
                "notes": "Upper body activation"
            }
        ]
    },
    {
        "id": "20181106-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181106-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181106-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20181106-ex-2-3",
                "name": "Spiderman",
                "sequence": 3,
                "notes": "Hip flexor/groin"
            },
            {
                "id": "20181106-ex-2-4",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181106-ex-2-5",
                "name": "Lunge & Twist",
                "sequence": 5,
                "notes": "Hip/thoracic mobility"
            },
            {
                "id": "20181106-ex-2-6",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body activation"
            }
        ]
    },
    {
        "id": "20181106-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181106-ex-3-1",
                "name": "EMOM 12 min",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": ""
            },
            {
                "id": "20181106-ex-3-2",
                "name": "Single-Leg Deadlift",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Handstand Walk practice between sets"
            }
        ]
    },
    {
        "id": "20181106-block-4",
        "name": "Conditioning - 6 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181106-ex-4-1",
                "name": "Hanging Knee Raises",
                "sequence": 1,
                "prescribed_sets": 6,
                "prescribed_reps": "8",
                "notes": "Controlled. 6 rounds total"
            },
            {
                "id": "20181106-ex-4-2",
                "name": "Thrusters",
                "sequence": 2,
                "prescribed_sets": 6,
                "prescribed_reps": "8",
                "notes": "Light-moderate. 6 rounds total"
            },
            {
                "id": "20181106-ex-4-3",
                "name": "Row/Bike",
                "sequence": 3,
                "prescribed_sets": 6,
                "prescribed_reps": "8 cal",
                "notes": "Fast pace. 6 rounds total"
            },
            {
                "id": "20181106-ex-4-4",
                "name": "KB Swing",
                "sequence": 4,
                "prescribed_sets": 6,
                "prescribed_reps": "8",
                "notes": "Hip drive. 6 rounds total"
            },
            {
                "id": "20181106-ex-4-5",
                "name": "Bike/Row Sprint",
                "sequence": 5,
                "prescribed_sets": 6,
                "prescribed_reps": "30\"",
                "notes": "Max effort. 6 rounds total"
            },
            {
                "id": "20181106-ex-4-6",
                "name": "Weighted Sit-Ups",
                "sequence": 6,
                "prescribed_sets": 6,
                "prescribed_reps": "30",
                "notes": "Per round. 6 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 6, 2018';


-- Fix "November 7, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181107-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181107-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181107-ex-1-2",
                "name": "Monster Walk",
                "sequence": 2,
                "prescribed_reps": "2x",
                "notes": "Glute activation with band"
            }
        ]
    },
    {
        "id": "20181107-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181107-ex-2-1",
                "name": "PVC Passover",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181107-ex-2-2",
                "name": "Side Lunge",
                "sequence": 2,
                "notes": "Adductor stretch"
            },
            {
                "id": "20181107-ex-2-3",
                "name": "Hamstring Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181107-ex-2-4",
                "name": "High Knee Pull",
                "sequence": 4,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181107-ex-2-5",
                "name": "Quad Pull",
                "sequence": 5,
                "notes": "Quad stretch"
            },
            {
                "id": "20181107-ex-2-6",
                "name": "High Knee Skip",
                "sequence": 6,
                "notes": "Hip flexor activation"
            },
            {
                "id": "20181107-ex-2-7",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x - Upper body activation"
            }
        ]
    },
    {
        "id": "20181107-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181107-ex-3-1",
                "name": "Hand-Release Push-Ups",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181107-ex-3-2",
                "name": "Single-Leg Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "Set 1: Bodyweight/assisted (RPE 6). Set 2: Bodyweight/assisted (RPE 7). Set 3: Bodyweight/assisted (RPE 7). Set 4: Bodyweight/assisted (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181107-ex-3-3",
                "name": "KB Strict Press",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "20181107-block-4",
        "name": "Conditioning - Stations (12 min AMRAP)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181107-ex-4-1",
                "name": "Step-Up/Box Jump",
                "sequence": 1,
                "notes": "Choose based on ability"
            },
            {
                "id": "20181107-ex-4-2",
                "name": "Plank",
                "sequence": 2,
                "notes": "Hold steady"
            },
            {
                "id": "20181107-ex-4-3",
                "name": "Devils Press",
                "sequence": 3,
                "notes": "Light DBs"
            },
            {
                "id": "20181107-ex-4-4",
                "name": "Russian Twist",
                "sequence": 4,
                "notes": "Weighted"
            }
        ]
    },
    {
        "id": "20181107-block-5",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "20181107-ex-5-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "40 cal",
                "notes": "Steady pace"
            },
            {
                "id": "20181107-ex-5-2",
                "name": "Med Ball Toe Tap",
                "sequence": 2,
                "prescribed_reps": "40",
                "notes": "Fast feet"
            },
            {
                "id": "20181107-ex-5-3",
                "name": "Foam Roll",
                "sequence": 3,
                "prescribed_reps": "5-10 min",
                "notes": "Focus on quads, chest, shoulders"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 7, 2018';


-- Fix "November 10, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181110-block-1",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181110-ex-1-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20181110-ex-1-2",
                "name": "Handstand Walk",
                "sequence": 2,
                "notes": "Shoulder/core activation"
            },
            {
                "id": "20181110-ex-1-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181110-ex-1-4",
                "name": "Bear Crawl (medium)",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "20181110-ex-1-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181110-ex-1-6",
                "name": "Single-Leg Rotation",
                "sequence": 6,
                "notes": "Hip/core mobility"
            }
        ]
    },
    {
        "id": "20181110-block-2",
        "name": "Strength",
        "block_type": "push",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181110-ex-2-1",
                "name": "Single-Leg Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight/assisted (RPE 7). Set 2: Bodyweight/assisted (RPE 7). Set 3: Bodyweight/assisted (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181110-ex-2-2",
                "name": "Pull-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 8). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 9). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "20181110-block-3",
        "name": "Core Challenge - Chipper",
        "block_type": "core",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181110-ex-3-1",
                "name": "KB Swing",
                "sequence": 1,
                "prescribed_reps": "50"
            },
            {
                "id": "20181110-ex-3-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "40"
            },
            {
                "id": "20181110-ex-3-3",
                "name": "Overhead Squat",
                "sequence": 3,
                "prescribed_reps": "30"
            },
            {
                "id": "20181110-ex-3-4",
                "name": "Burpees",
                "sequence": 4,
                "prescribed_reps": "20"
            },
            {
                "id": "20181110-ex-3-5",
                "name": "TGU",
                "sequence": 5,
                "prescribed_reps": "10"
            },
            {
                "id": "20181110-ex-3-6",
                "name": "Sit-Ups/Dead Bugs",
                "sequence": 6,
                "prescribed_reps": "10e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 10, 2018';


-- Fix "November 12, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181112-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181112-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181112-ex-1-2",
                "name": "Air Squats",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Lower body activation"
            },
            {
                "id": "20181112-ex-1-3",
                "name": "Push-Ups",
                "sequence": 3,
                "prescribed_reps": "10",
                "notes": "Upper body activation"
            },
            {
                "id": "20181112-ex-1-4",
                "name": "Sit-Ups",
                "sequence": 4,
                "prescribed_reps": "10",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20181112-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181112-ex-2-1",
                "name": "Piriformis Stretch",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "20181112-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20181112-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181112-ex-2-4",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip flexor/groin"
            },
            {
                "id": "20181112-ex-2-5",
                "name": "Lunge & Twist",
                "sequence": 5,
                "notes": "Hip/thoracic mobility"
            },
            {
                "id": "20181112-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181112-ex-2-7",
                "name": "High Knee Skip",
                "sequence": 7,
                "notes": "Hip flexor activation"
            },
            {
                "id": "20181112-ex-2-8",
                "name": "Push-Ups",
                "sequence": 8,
                "notes": "10x - Upper body activation"
            }
        ]
    },
    {
        "id": "20181112-block-3",
        "name": "Core Intro - 3 Rounds",
        "block_type": "core",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181112-ex-3-1",
                "name": "Hanging Knee to Chest",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Controlled"
            },
            {
                "id": "20181112-ex-3-2",
                "name": "Bosu Mountain Climber",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "20e",
                "notes": "Fast pace"
            },
            {
                "id": "20181112-ex-3-3",
                "name": "Plank",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "30 sec",
                "notes": "Hold steady"
            }
        ]
    },
    {
        "id": "20181112-block-4",
        "name": "Cool Down - 2 Rounds",
        "block_type": "recovery",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181112-ex-4-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "1 min",
                "notes": "Easy pace"
            },
            {
                "id": "20181112-ex-4-2",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "Controlled"
            },
            {
                "id": "20181112-ex-4-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "10e",
                "notes": "Slow and controlled"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 12, 2018';


-- Fix "November 13, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20181113-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181113-ex-1-1",
                "name": "KB Strict Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181113-ex-1-2",
                "name": "Slant Bar Triple Extension",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Pigeon stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 13, 2018';


-- Fix "November 14, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181114-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181114-ex-1-1",
                "name": "Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181114-ex-1-2",
                "name": "Single-Leg Deadlift",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Hamstring Walk between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 14, 2018';


-- Fix "November 16, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181116-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181116-ex-1-1",
                "name": "Pull-Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 16, 2018';


-- Fix "November 20, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181120-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181120-ex-1-1",
                "name": "Single-Leg Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Bodyweight/Light (RPE 7). Set 3: Bodyweight/Light (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181120-ex-1-2",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 20, 2018';


-- Fix "November 27, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181127-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181127-ex-1-1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181127-ex-1-2",
                "name": "Split Squats",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 27, 2018';


-- Fix "November 28, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181128-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181128-ex-1-1",
                "name": "Renegade Rows",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20181128-ex-1-2",
                "name": "Single-Leg Deadlift",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: TTP (Toe Touch Progression) between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 28, 2018';


-- Fix "November 29, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181129-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181129-ex-1-1",
                "name": "Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181129-ex-1-2",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'November 29, 2018';


-- Fix "December 3, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 50,
    exercises = '[
    {
        "id": "20181203-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181203-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light pace"
            },
            {
                "id": "20181203-ex-1-2",
                "name": "Monster Walk",
                "sequence": 2,
                "prescribed_reps": "2x",
                "notes": "Hip activation"
            }
        ]
    },
    {
        "id": "20181203-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181203-ex-2-1",
                "name": "Air Squats",
                "sequence": 1,
                "notes": "10x - Lower body prep"
            },
            {
                "id": "20181203-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "20181203-ex-2-3",
                "name": "Arm Circles",
                "sequence": 3,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181203-ex-2-4",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20181203-ex-2-5",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warmup"
            },
            {
                "id": "20181203-ex-2-6",
                "name": "Toy Soldier",
                "sequence": 6,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181203-ex-2-7",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "20181203-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181203-ex-3-1",
                "name": "Goblet Squats",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 6). Set 4: Moderate (RPE 7). Set 5: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181203-ex-3-2",
                "name": "Hand-Release Push-Ups",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "20181203-block-4",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181203-ex-4-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15 cal",
                "notes": "4 rounds total"
            },
            {
                "id": "20181203-ex-4-2",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "4 rounds total"
            },
            {
                "id": "20181203-ex-4-3",
                "name": "Slamballs",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "4 rounds total"
            },
            {
                "id": "20181203-ex-4-4",
                "name": "Plank",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "30 sec",
                "notes": "4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 3, 2018';


-- Fix "December 5, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181205-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181205-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light pace"
            },
            {
                "id": "20181205-ex-1-2",
                "name": "Monster Walk",
                "sequence": 2,
                "prescribed_reps": "2x",
                "notes": "Hip activation"
            }
        ]
    },
    {
        "id": "20181205-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181205-ex-2-1",
                "name": "Push-Ups",
                "sequence": 1,
                "notes": "10x - Upper body prep"
            },
            {
                "id": "20181205-ex-2-2",
                "name": "Side Lunges",
                "sequence": 2,
                "notes": "Hip adductor mobility"
            },
            {
                "id": "20181205-ex-2-3",
                "name": "High Knee Pull",
                "sequence": 3,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181205-ex-2-4",
                "name": "Quad Pull",
                "sequence": 4,
                "notes": "Quad stretch"
            },
            {
                "id": "20181205-ex-2-5",
                "name": "Hamstring Walk",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181205-ex-2-6",
                "name": "PVC Passovers",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181205-ex-2-7",
                "name": "High Knee Skip",
                "sequence": 7,
                "notes": "Dynamic warmup"
            }
        ]
    },
    {
        "id": "20181205-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181205-ex-3-1",
                "name": "D.B. Bench Press \"Heavy\"",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "6",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181205-ex-3-2",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Bodyweight/Light (RPE 6). Rest: 60 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "20181205-block-4",
        "name": "Conditioning - The Eight Crazy Nights of Hanukkah! (20 min)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181205-ex-4-1",
                "name": "Front Squats",
                "sequence": 1,
                "prescribed_reps": "8"
            },
            {
                "id": "20181205-ex-4-2",
                "name": "Hanging Knees to Chest",
                "sequence": 2,
                "prescribed_reps": "8"
            },
            {
                "id": "20181205-ex-4-3",
                "name": "KB Push Press",
                "sequence": 3,
                "prescribed_reps": "8"
            },
            {
                "id": "20181205-ex-4-4",
                "name": "Row/Bike",
                "sequence": 4,
                "prescribed_reps": "8 cal"
            },
            {
                "id": "20181205-ex-4-5",
                "name": "V-Ups",
                "sequence": 5,
                "prescribed_reps": "8"
            },
            {
                "id": "20181205-ex-4-6",
                "name": "Box Jump/Step-Ups",
                "sequence": 6,
                "prescribed_reps": "8"
            },
            {
                "id": "20181205-ex-4-7",
                "name": "Dead Bugs",
                "sequence": 7,
                "prescribed_reps": "8e"
            },
            {
                "id": "20181205-ex-4-8",
                "name": "Burpees",
                "sequence": 8,
                "prescribed_reps": "8"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 5, 2018';


-- Fix "December 6, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181206-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181206-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light pace"
            },
            {
                "id": "20181206-ex-1-2",
                "name": "SL Bridges",
                "sequence": 2,
                "prescribed_reps": "20x",
                "notes": "Glute activation"
            },
            {
                "id": "20181206-ex-1-3",
                "name": "Push-Ups",
                "sequence": 3,
                "prescribed_reps": "10x",
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "20181206-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181206-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181206-ex-2-2",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "20181206-ex-2-3",
                "name": "Spiderman",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20181206-ex-2-4",
                "name": "Quad Pull",
                "sequence": 4,
                "notes": "Quad stretch"
            },
            {
                "id": "20181206-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181206-ex-2-6",
                "name": "Air Squats",
                "sequence": 6,
                "notes": "10x - Lower body prep"
            }
        ]
    },
    {
        "id": "20181206-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181206-ex-3-1",
                "name": "Slant Bar 3 Extensions",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 6). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 7). Rest: 60 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181206-ex-3-2",
                "name": "Turkish Get-Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Light-Moderate (RPE 6). Rest: As needed between sides Accessory: SL Rotation between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 6, 2018';


-- Fix "December 7, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181207-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181207-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light pace"
            },
            {
                "id": "20181207-ex-1-2",
                "name": "Shoulder Taps",
                "sequence": 2,
                "prescribed_reps": "15e",
                "notes": "Core/shoulder activation"
            }
        ]
    },
    {
        "id": "20181207-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181207-ex-2-1",
                "name": "Push-Ups",
                "sequence": 1,
                "notes": "10x - Upper body prep"
            },
            {
                "id": "20181207-ex-2-2",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181207-ex-2-3",
                "name": "High Knee/Quad Pull",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20181207-ex-2-4",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Hip adductor mobility"
            },
            {
                "id": "20181207-ex-2-5",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181207-ex-2-6",
                "name": "Good Morning",
                "sequence": 6,
                "notes": "Posterior chain activation"
            }
        ]
    },
    {
        "id": "20181207-block-3",
        "name": "Conditioning - Chipper",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181207-ex-3-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "50 cal"
            },
            {
                "id": "20181207-ex-3-2",
                "name": "Med Ball Tap",
                "sequence": 2,
                "prescribed_reps": "30x"
            },
            {
                "id": "20181207-ex-3-3",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_reps": "30x"
            },
            {
                "id": "20181207-ex-3-4",
                "name": "Thrusters",
                "sequence": 4,
                "prescribed_reps": "30x"
            },
            {
                "id": "20181207-ex-3-5",
                "name": "Row/Bike",
                "sequence": 5,
                "prescribed_reps": "50 cal"
            },
            {
                "id": "20181207-ex-3-6",
                "name": "Burpees",
                "sequence": 6,
                "prescribed_reps": "30x"
            },
            {
                "id": "20181207-ex-3-7",
                "name": "Sit-Ups",
                "sequence": 7,
                "prescribed_reps": "30x"
            },
            {
                "id": "20181207-ex-3-8",
                "name": "Plank",
                "sequence": 8,
                "prescribed_reps": "1 min each"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 7, 2018';


-- Fix "December 8, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181208-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181208-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "500m",
                "notes": "Light pace"
            },
            {
                "id": "20181208-ex-1-2",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "60 sec / 30 sec each side",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20181208-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181208-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181208-ex-2-2",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181208-ex-2-3",
                "name": "Quad Pull & Hinge",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20181208-ex-2-4",
                "name": "Push Up W/O",
                "sequence": 4,
                "notes": "Upper body prep"
            },
            {
                "id": "20181208-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181208-ex-2-6",
                "name": "SL Rotation",
                "sequence": 6,
                "notes": "Hip/spine mobility"
            }
        ]
    },
    {
        "id": "20181208-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181208-ex-3-1",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded/SL (RPE 5). Set 2: Banded/SL (RPE 6). Set 3: Banded/SL (RPE 6). Rest: 45 sec between sets Accessory: Hip flexor stretch between sets"
            },
            {
                "id": "20181208-ex-3-2",
                "name": "Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181208-ex-3-3",
                "name": "Bench Press",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Warm-up (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8+). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "20181208-block-4",
        "name": "Core Circuit - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181208-ex-4-1",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "20181208-ex-4-2",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "20181208-ex-4-3",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "10e"
            },
            {
                "id": "20181208-ex-4-4",
                "name": "TGU",
                "sequence": 4,
                "prescribed_reps": "1e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 8, 2018';


-- Fix "December 10, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181210-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181210-ex-1-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light pace"
            },
            {
                "id": "20181210-ex-1-2",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_reps": "20x",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20181210-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181210-ex-2-1",
                "name": "Toy Soldier",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181210-ex-2-2",
                "name": "Leg Cradle",
                "sequence": 2,
                "notes": "Hip opener"
            },
            {
                "id": "20181210-ex-2-3",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20181210-ex-2-4",
                "name": "Push-Up Walkout",
                "sequence": 4,
                "notes": "Full body warmup"
            },
            {
                "id": "20181210-ex-2-5",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181210-ex-2-6",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Posterior chain activation"
            },
            {
                "id": "20181210-ex-2-7",
                "name": "OH Squat",
                "sequence": 7,
                "notes": "Full body mobility"
            }
        ]
    },
    {
        "id": "20181210-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181210-ex-3-1",
                "name": "Single Leg Deadlift (SLDL)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            },
            {
                "id": "20181210-ex-3-2",
                "name": "Half-Kneel Single Arm Shoulder Press",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 10, 2018';


-- Fix "December 11, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181211-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181211-ex-1-1",
                "name": "TRX Row",
                "sequence": 1,
                "notes": "Shoulder activation"
            },
            {
                "id": "20181211-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20181211-ex-1-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20181211-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181211-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181211-ex-2-2",
                "name": "Lunge & Reach",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20181211-ex-2-3",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20181211-ex-2-4",
                "name": "HS Walk",
                "sequence": 4,
                "notes": "Hamstring stretch"
            },
            {
                "id": "20181211-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181211-ex-2-6",
                "name": "Push Up W/o",
                "sequence": 6,
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "20181211-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181211-ex-3-1",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 8). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20181211-ex-3-2",
                "name": "Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "20181211-block-4",
        "name": "Conditioning - 12 min EMOM",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181211-ex-4-1",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "10"
            },
            {
                "id": "20181211-ex-4-2",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "20181211-ex-4-3",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_reps": "8"
            },
            {
                "id": "20181211-ex-4-4",
                "name": "Russian Twist",
                "sequence": 4,
                "prescribed_reps": "10e"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 11, 2018';


-- Fix "December 12, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181212-block-1",
        "name": "Active (Warmup)",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181212-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181212-ex-1-2",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "Lower body activation"
            },
            {
                "id": "20181212-ex-1-3",
                "name": "Push-Ups",
                "sequence": 3,
                "notes": "Upper body activation"
            },
            {
                "id": "20181212-ex-1-4",
                "name": "Jumping Jacks",
                "sequence": 4,
                "notes": "Full body warmup"
            }
        ]
    },
    {
        "id": "20181212-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181212-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20181212-ex-2-2",
                "name": "Arm Circles",
                "sequence": 2,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181212-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181212-ex-2-4",
                "name": "Lunge + Twist",
                "sequence": 4,
                "notes": "Hip mobility/rotation"
            },
            {
                "id": "20181212-ex-2-5",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warmup"
            }
        ]
    },
    {
        "id": "20181212-block-3",
        "name": "Intro - EMOM 3 Rounds",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181212-ex-3-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10 cal"
            },
            {
                "id": "20181212-ex-3-2",
                "name": "Med Ball Taps",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "15"
            },
            {
                "id": "20181212-ex-3-3",
                "name": "KB Push Press",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15"
            }
        ]
    },
    {
        "id": "20181212-block-4",
        "name": "Conditioning - 10 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181212-ex-4-1",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Light-moderate load"
            },
            {
                "id": "20181212-ex-4-2",
                "name": "Hanging Knees",
                "sequence": 2,
                "prescribed_reps": "15",
                "notes": "Core engagement"
            },
            {
                "id": "20181212-ex-4-3",
                "name": "TGU",
                "sequence": 3,
                "prescribed_reps": "1e",
                "notes": "Full movement each side"
            }
        ]
    },
    {
        "id": "20181212-block-5",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "20181212-ex-5-1",
                "name": "Sprint Bike",
                "sequence": 1,
                "notes": "Max effort"
            },
            {
                "id": "20181212-ex-5-2",
                "name": "Foam Roll",
                "sequence": 2,
                "notes": "Focus on chest, shoulders, quads"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 12, 2018';


-- Fix "December 14, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181214-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181214-ex-1-1",
                "name": "Jump Rope/Row",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181214-ex-1-2",
                "name": "Bear Crawl (4-way)",
                "sequence": 2,
                "notes": "Full body activation"
            },
            {
                "id": "20181214-ex-1-3",
                "name": "Monsters",
                "sequence": 3,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20181214-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181214-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20181214-ex-2-2",
                "name": "Lunge & Twist",
                "sequence": 2,
                "notes": "Hip mobility/rotation"
            },
            {
                "id": "20181214-ex-2-3",
                "name": "Over/Under",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20181214-ex-2-4",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181214-ex-2-5",
                "name": "Push Up W/o",
                "sequence": 5,
                "notes": "Upper body prep"
            },
            {
                "id": "20181214-ex-2-6",
                "name": "Around the World",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20181214-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181214-ex-3-1",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded/SL (RPE 6). Set 2: Banded/SL (RPE 6). Set 3: Banded/SL (RPE 6). Rest: 45-60 sec between sets"
            },
            {
                "id": "20181214-ex-3-2",
                "name": "Single Arm Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20181214-ex-3-3",
                "name": "Single Leg Squat",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "20181214-block-4",
        "name": "Core - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181214-ex-4-1",
                "name": "Front Squat",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Moderate load"
            },
            {
                "id": "20181214-ex-4-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "10e",
                "notes": "Core rotation"
            },
            {
                "id": "20181214-ex-4-3",
                "name": "Push Press",
                "sequence": 3,
                "prescribed_reps": "10",
                "notes": "Explosive"
            },
            {
                "id": "20181214-ex-4-4",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_reps": "10",
                "notes": "Hip mobility"
            },
            {
                "id": "20181214-ex-4-5",
                "name": "Burpees",
                "sequence": 5,
                "prescribed_reps": "10",
                "notes": "Full body finisher"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 14, 2018';


-- Fix "December 15, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 65,
    exercises = '[
    {
        "id": "20181215-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181215-ex-1-1",
                "name": "Banded Bridge",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "20181215-ex-1-2",
                "name": "Banded Squats",
                "sequence": 2,
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "20181215-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181215-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181215-ex-2-2",
                "name": "Hi Touch/Lo Touch",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "20181215-ex-2-3",
                "name": "Quad Pull & Hinge",
                "sequence": 3,
                "notes": "Quad/hip stretch"
            },
            {
                "id": "20181215-ex-2-4",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "20181215-ex-2-5",
                "name": "Pigeon",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20181215-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20181215-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181215-ex-3-1",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Hamstring Stretch between sets"
            },
            {
                "id": "20181215-ex-3-2",
                "name": "Half Kneel Single Arm Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "20181215-block-4",
        "name": "Core - Chipper",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181215-ex-4-1",
                "name": "TGU",
                "sequence": 1,
                "prescribed_reps": "5e",
                "notes": "Full movement"
            },
            {
                "id": "20181215-ex-4-2",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_reps": "20",
                "notes": "Full body"
            },
            {
                "id": "20181215-ex-4-3",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "15e",
                "notes": "Core anti-extension"
            },
            {
                "id": "20181215-ex-4-4",
                "name": "SL Bridge",
                "sequence": 4,
                "prescribed_reps": "20e",
                "notes": "Glute isolation"
            },
            {
                "id": "20181215-ex-4-5",
                "name": "Air Squat",
                "sequence": 5,
                "prescribed_reps": "100",
                "notes": "Endurance"
            },
            {
                "id": "20181215-ex-4-6",
                "name": "Shoulder Tap",
                "sequence": 6,
                "prescribed_reps": "20e",
                "notes": "Core stability"
            },
            {
                "id": "20181215-ex-4-7",
                "name": "Back Lunge",
                "sequence": 7,
                "prescribed_reps": "15e",
                "notes": "Lower body"
            },
            {
                "id": "20181215-ex-4-8",
                "name": "Sit Ups",
                "sequence": 8,
                "prescribed_reps": "20",
                "notes": "Core flexion"
            },
            {
                "id": "20181215-ex-4-9",
                "name": "Push Ups",
                "sequence": 9,
                "prescribed_reps": "10",
                "notes": "Upper body"
            },
            {
                "id": "20181215-ex-4-10",
                "name": "Wall Sit/Plank",
                "sequence": 10,
                "prescribed_reps": "60\"",
                "notes": "Isometric hold"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 15, 2018';


-- Fix "December 17, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181217-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181217-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181217-ex-1-2",
                "name": "Broad Jumps",
                "sequence": 2,
                "notes": "Power activation"
            }
        ]
    },
    {
        "id": "20181217-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181217-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181217-ex-2-2",
                "name": "Pigeon Stretch",
                "sequence": 2,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20181217-ex-2-3",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20181217-ex-2-4",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181217-ex-2-5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181217-ex-2-6",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "20181217-block-3",
        "name": "Intro - 3 Rounds",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181217-ex-3-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "12 cal",
                "notes": "Moderate pace"
            },
            {
                "id": "20181217-ex-3-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12e",
                "notes": "Core activation"
            },
            {
                "id": "20181217-ex-3-3",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Hip hinge pattern"
            }
        ]
    },
    {
        "id": "20181217-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181217-ex-4-1",
                "name": "Standing Shoulder Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181217-ex-4-2",
                "name": "Split Squats",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "20181217-block-5",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20181217-ex-5-1",
                "name": "Bosu Mtn Climber",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Core stability. 4 rounds total"
            },
            {
                "id": "20181217-ex-5-2",
                "name": "Goblet Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Lower body. 4 rounds total"
            },
            {
                "id": "20181217-ex-5-3",
                "name": "TRX Rows",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Upper back. 4 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 17, 2018';


-- Fix "December 18, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181218-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181218-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181218-ex-1-2",
                "name": "SL Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20181218-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181218-ex-2-1",
                "name": "Hamstring Walk",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181218-ex-2-2",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "10x - Lower body prep"
            },
            {
                "id": "20181218-ex-2-3",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "20181218-ex-2-4",
                "name": "Leg Cradle",
                "sequence": 4,
                "notes": "Hip opener"
            },
            {
                "id": "20181218-ex-2-5",
                "name": "High Knee Pull",
                "sequence": 5,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181218-ex-2-6",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "20181218-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181218-ex-3-1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Set 5: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181218-ex-3-2",
                "name": "Weighted Step-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "20181218-block-4",
        "name": "Conditioning - 12 min Ladder",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181218-ex-4-1",
                "name": "KB Front Squat",
                "sequence": 1,
                "notes": "Lower body"
            },
            {
                "id": "20181218-ex-4-2",
                "name": "Burpees",
                "sequence": 2,
                "notes": "Full body"
            },
            {
                "id": "20181218-ex-4-3",
                "name": "Sit-Ups",
                "sequence": 3,
                "notes": "Core"
            }
        ]
    },
    {
        "id": "20181218-block-5",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "20181218-ex-5-1",
                "name": "Row Sprint",
                "sequence": 1,
                "notes": "Max effort"
            },
            {
                "id": "20181218-ex-5-2",
                "name": "Foam Roll",
                "sequence": 2,
                "notes": "Focus on chest, quads, glutes"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 18, 2018';


-- Fix "December 20, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20181220-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181220-ex-1-1",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181220-ex-1-2",
                "name": "Monster Walk",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20181220-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181220-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20181220-ex-2-2",
                "name": "High Knee Pull",
                "sequence": 2,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181220-ex-2-3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181220-ex-2-4",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Hip adductor mobility"
            },
            {
                "id": "20181220-ex-2-5",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181220-ex-2-6",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "20181220-block-3",
        "name": "Intro - 9 min EMOM",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181220-ex-3-1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "10-12 cal",
                "notes": "Moderate effort"
            },
            {
                "id": "20181220-ex-3-2",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "30\"",
                "notes": "Core stability"
            },
            {
                "id": "20181220-ex-3-3",
                "name": "Bicep Curls",
                "sequence": 3,
                "prescribed_reps": "15",
                "notes": "Arm activation"
            }
        ]
    },
    {
        "id": "20181220-block-4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181220-ex-4-1",
                "name": "Half Kneel Single Arm Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181220-ex-4-2",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181220-ex-4-3",
                "name": "Turkish Get-Up (TGU)",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Moderate (RPE 7). Accessory: Single Leg Rotation between sides"
            }
        ]
    },
    {
        "id": "20181220-block-5",
        "name": "Conditioning - 1 Round",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "20181220-ex-5-1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_sets": 1,
                "prescribed_reps": "25 cal",
                "notes": "Steady pace. 1 rounds total"
            },
            {
                "id": "20181220-ex-5-2",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "25e",
                "notes": "Core rotation. 1 rounds total"
            },
            {
                "id": "20181220-ex-5-3",
                "name": "Light KB Swings",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "25",
                "notes": "Hip hinge. 1 rounds total"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 20, 2018';


-- Fix "December 27, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 70,
    exercises = '[
    {
        "id": "20181227-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181227-ex-1-1",
                "name": "Row/Jump Rope",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181227-ex-1-2",
                "name": "Monsters",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "20181227-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181227-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181227-ex-2-2",
                "name": "Quad Pull & Hinge",
                "sequence": 2,
                "notes": "Quad/hip stretch"
            },
            {
                "id": "20181227-ex-2-3",
                "name": "Lunge & Reach",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20181227-ex-2-4",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181227-ex-2-5",
                "name": "Good Mornings",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "20181227-ex-2-6",
                "name": "Spiderman",
                "sequence": 6,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "20181227-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181227-ex-3-1",
                "name": "Banded or Single Leg Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded/SL (RPE 6). Set 2: Banded/SL (RPE 6). Set 3: Banded/SL (RPE 6). Rest: 45-60 sec between sets Accessory: Hamstring Stretch between sets"
            },
            {
                "id": "20181227-ex-3-2",
                "name": "Good Mornings",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Touch Toes, Pulse (TTP) between sets"
            }
        ]
    },
    {
        "id": "20181227-block-4",
        "name": "Core - 12 Days Style",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181227-ex-4-1",
                "name": "TGU",
                "sequence": 1,
                "prescribed_reps": "1e",
                "notes": "Full movement"
            },
            {
                "id": "20181227-ex-4-2",
                "name": "Box Jump/Step Up",
                "sequence": 2,
                "prescribed_reps": "2",
                "notes": "Power"
            },
            {
                "id": "20181227-ex-4-3",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "3e",
                "notes": "Core rotation"
            },
            {
                "id": "20181227-ex-4-4",
                "name": "TRX Row",
                "sequence": 4,
                "prescribed_reps": "4",
                "notes": "Upper back"
            },
            {
                "id": "20181227-ex-4-5",
                "name": "Push Up",
                "sequence": 5,
                "prescribed_reps": "5",
                "notes": "Upper body"
            },
            {
                "id": "20181227-ex-4-6",
                "name": "Back Lunge",
                "sequence": 6,
                "prescribed_reps": "6e",
                "notes": "Lower body"
            },
            {
                "id": "20181227-ex-4-7",
                "name": "Mtn Climber",
                "sequence": 7,
                "prescribed_reps": "7e",
                "notes": "Core/cardio"
            },
            {
                "id": "20181227-ex-4-8",
                "name": "Goblet Squat",
                "sequence": 8,
                "prescribed_reps": "8",
                "notes": "Lower body"
            },
            {
                "id": "20181227-ex-4-9",
                "name": "Sit Ups",
                "sequence": 9,
                "prescribed_reps": "9",
                "notes": "Core flexion"
            },
            {
                "id": "20181227-ex-4-10",
                "name": "KB Swing",
                "sequence": 10,
                "prescribed_reps": "10",
                "notes": "Hip hinge"
            },
            {
                "id": "20181227-ex-4-11",
                "name": "Thrusters",
                "sequence": 11,
                "prescribed_reps": "11",
                "notes": "Full body"
            },
            {
                "id": "20181227-ex-4-12",
                "name": "Burpees",
                "sequence": 12,
                "prescribed_reps": "12",
                "notes": "Full body finisher"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 27, 2018';


-- Fix "December 28, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181228-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181228-ex-1-1",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded or Single Leg"
            },
            {
                "id": "20181228-ex-1-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20181228-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181228-ex-2-1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "20181228-ex-2-2",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "20181228-ex-2-3",
                "name": "Hi Touch/Lo Touch",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "20181228-ex-2-4",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Hip adductor mobility"
            },
            {
                "id": "20181228-ex-2-5",
                "name": "Pigeon/Piriformis",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "20181228-ex-2-6",
                "name": "SL Rotation",
                "sequence": 6,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "20181228-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181228-ex-3-1",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "Max Rep Test",
                "notes": "Set 1: Bodyweight (RPE 9). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 7). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "20181228-ex-3-2",
                "name": "Slant Bar 3-Way Extension",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 6). Set 2: Light (RPE 6). Set 3: Light (RPE 6). Rest: 45-60 sec between sets Accessory: Pigeon Stretch between sets"
            },
            {
                "id": "20181228-ex-3-3",
                "name": "Slant Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 6). Set 3: Bodyweight (RPE 6). Rest: 45-60 sec between sets Accessory: Cobra/Child Pose between sets"
            },
            {
                "id": "20181228-ex-3-4",
                "name": "Single Leg Squat",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "20181228-ex-3-5",
                "name": "Arm Set",
                "sequence": 5,
                "prescribed_sets": 3,
                "prescribed_reps": "10-12",
                "notes": ""
            }
        ]
    },
    {
        "id": "20181228-block-4",
        "name": "Core Cash Out",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181228-ex-4-1",
                "name": "Heel Raise",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Calf work"
            },
            {
                "id": "20181228-ex-4-2",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_reps": "10e",
                "notes": "Core anti-extension"
            },
            {
                "id": "20181228-ex-4-3",
                "name": "Sit Ups",
                "sequence": 3,
                "prescribed_reps": "12",
                "notes": "Core flexion"
            },
            {
                "id": "20181228-ex-4-4",
                "name": "Wall Sit",
                "sequence": 4,
                "prescribed_reps": "60\"",
                "notes": "Isometric hold"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 28, 2018';


-- Fix "December 29, 2018" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20181229-block-1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20181229-ex-1-1",
                "name": "Row",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "20181229-ex-1-2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "20181229-ex-1-3",
                "name": "Plank",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "20181229-block-2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "20181229-ex-2-1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "20181229-ex-2-2",
                "name": "Lunge & Twist",
                "sequence": 2,
                "notes": "Hip mobility/rotation"
            },
            {
                "id": "20181229-ex-2-3",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring stretch"
            },
            {
                "id": "20181229-ex-2-4",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "20181229-ex-2-5",
                "name": "Push Up W/o",
                "sequence": 5,
                "notes": "Upper body prep"
            },
            {
                "id": "20181229-ex-2-6",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "20181229-block-3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "20181229-ex-3-1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "20181229-ex-3-2",
                "name": "Single Leg Deadlift (SLDL)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "20181229-block-4",
        "name": "Core - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "20181229-ex-4-1",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "250m",
                "notes": "Moderate pace"
            },
            {
                "id": "20181229-ex-4-2",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Lower body"
            },
            {
                "id": "20181229-ex-4-3",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_reps": "12",
                "notes": "Full body"
            },
            {
                "id": "20181229-ex-4-4",
                "name": "Dead Bugs",
                "sequence": 4,
                "prescribed_reps": "15e",
                "notes": "Core anti-extension"
            },
            {
                "id": "20181229-ex-4-5",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "250m",
                "notes": "Moderate pace"
            },
            {
                "id": "20181229-ex-4-6",
                "name": "Push Press",
                "sequence": 6,
                "prescribed_reps": "10",
                "notes": "Explosive"
            },
            {
                "id": "20181229-ex-4-7",
                "name": "Sit Ups",
                "sequence": 7,
                "prescribed_reps": "12",
                "notes": "Core flexion"
            },
            {
                "id": "20181229-ex-4-8",
                "name": "TRX Row",
                "sequence": 8,
                "prescribed_reps": "15",
                "notes": "Upper back"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'December 29, 2018';


-- Fix "January 2, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190102-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190102-ex-1-1",
                "name": "Slant Bar (3 Extensions)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Set 5: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 2, 2019';


-- Fix "January 7, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190107-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190107-ex-1-1",
                "name": "Walking Lunges (Building)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20190107-ex-1-2",
                "name": "Bent Over Row (Building)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 7, 2019';


-- Fix "January 14, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190114-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190114-ex-1-1",
                "name": "Deadlift (Building)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: Hamstring Walk between sets"
            },
            {
                "id": "20190114-ex-1-2",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 14, 2019';


-- Fix "January 21, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190121-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190121-ex-1-1",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Hamstring Walks between sets"
            },
            {
                "id": "20190121-ex-1-2",
                "name": "Box Jumps or Step Ups",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e (or 25 total)",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 21, 2019';


-- Fix "January 28, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190128-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190128-ex-1-1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20190128-ex-1-2",
                "name": "SA DB Bench Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'January 28, 2019';


-- Fix "February 4, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190204-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190204-ex-1-1",
                "name": "Turkish Get Up (TGU) - Weighted",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "3e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 4, 2019';


-- Fix "February 11, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20190211-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190211-ex-1-1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 11, 2019';


-- Fix "February 18, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20190218-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190218-ex-1-1",
                "name": "Single Leg Squat (SL Squat)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Light (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20190218-ex-1-2",
                "name": "DB Bench Press (Building)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 18, 2019';


-- Fix "February 25, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20190225-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190225-ex-1-1",
                "name": "KB Front Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20190225-ex-1-2",
                "name": "KB SA Bent Over Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'February 25, 2019';


-- Fix "March 5, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190305-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190305-ex-1-1",
                "name": "Split Squats (Building)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20190305-ex-1-2",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "6",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Rest: 90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 5, 2019';


-- Fix "March 11, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190311-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190311-ex-1-1",
                "name": "Single Leg Deadlift (SL DL)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Hamstring Walks between sets"
            },
            {
                "id": "20190311-ex-1-2",
                "name": "Pull Ups (AMRAP)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMRAP",
                "notes": "Set 1: Bodyweight (RPE 8). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 9). Rest: 90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 11, 2019';


-- Fix "March 20, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 60,
    exercises = '[
    {
        "id": "20190320-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190320-ex-1-1",
                "name": "Deadlifts",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: T.T.P. (Touch Toes Progression) between sets"
            },
            {
                "id": "20190320-ex-1-2",
                "name": "SA Bent Over Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 20, 2019';


-- Fix "March 25, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190325-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190325-ex-1-1",
                "name": "Deadlifts (Building)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: T.T.P. (Touch Toes Progression) between sets"
            },
            {
                "id": "20190325-ex-1-2",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'March 25, 2019';


-- Fix "April 8, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190408-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190408-ex-1-1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20190408-ex-1-2",
                "name": "SA DB Bench Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Rest: 60-90 sec between sets Accessory: Chest Openers between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 8, 2019';


-- Fix "April 15, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190415-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190415-ex-1-1",
                "name": "3 Way Lunges",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "5e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Light (RPE 7). Rest: 60 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 15, 2019';


-- Fix "April 22, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190422-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190422-ex-1-1",
                "name": "Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: Snow Angels (10 reps) between sets"
            },
            {
                "id": "20190422-ex-1-2",
                "name": "Single Leg Deadlift (SL DL)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: SL Bridge (10e) between sets"
            },
            {
                "id": "20190422-ex-1-3",
                "name": "Active Chin Up Hang",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "",
                "notes": "Set 1: Bodyweight (RPE 8-9)"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'April 22, 2019';


-- Fix "May 6, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190506-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190506-ex-1-1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Deadbugs (10e) between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 6, 2019';


-- Fix "May 13, 2019" workout
UPDATE system_workout_templates
SET
    description = 'Comprehensive training session',
    difficulty = 'intermediate',
    duration_minutes = 55,
    exercises = '[
    {
        "id": "20190513-block-1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "20190513-ex-1-1",
                "name": "Slant Bar (3 Extensions)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "20190513-ex-1-2",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    }
]'::jsonb,
    tags = '{strength,full-body,foundation}'
WHERE name = 'May 13, 2019';


-- Verify updates
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM system_workout_templates
    WHERE name ~ '^[A-Z][a-z]+ [0-9]+, 20[0-9]{2}$'
      AND exercises::text NOT LIKE '%"name": "1"%';

    RAISE NOTICE 'Updated % date-labeled workout templates with proper exercise data', updated_count;
END $$;
