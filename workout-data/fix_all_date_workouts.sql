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
        "id": "104fda4b-a474-4321-9fae-a65b4d54bb17",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "e355c3d7-8ea8-4099-b245-a8de7fee546f",
                "name": "Push Ups",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Warm-up pace"
            },
            {
                "id": "f922a3cb-fa3c-474f-aa45-b454a1554f3f",
                "name": "Air Squats",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Full depth"
            },
            {
                "id": "440f00cb-4d97-4ee0-bdca-8e4830944844",
                "name": "Jumping Jacks",
                "sequence": 3,
                "prescribed_reps": "20",
                "notes": "Elevate HR"
            }
        ]
    },
    {
        "id": "f3e68da6-5235-4172-bb26-28c601777584",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "ac6db558-7e91-407b-8444-9b1327d14afe",
                "name": "PVC Good Mornings",
                "sequence": 1,
                "notes": "Hip hinge activation"
            },
            {
                "id": "77114bca-34a0-4c33-8ecd-f5c65738e175",
                "name": "PVC Passovers",
                "sequence": 2,
                "notes": "Shoulder mobility"
            },
            {
                "id": "19faa5ee-6948-4e7c-aaec-a3329e3ff270",
                "name": "Arm Circles",
                "sequence": 3,
                "notes": "Shoulder warm-up"
            },
            {
                "id": "2f3941a8-008a-4d4b-9ecf-0ae2a458524f",
                "name": "Back Lunge + Twist",
                "sequence": 4,
                "notes": "Hip flexor/t-spine"
            },
            {
                "id": "e1e575c7-fa64-4ff2-ae2e-8a71f14078fc",
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
        "id": "fb204a29-3a82-44fb-9adf-fc5a3ffe4f85",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "b2b0ee2c-d828-4af7-97a1-6b0ed640a47c",
                "name": "Bear Crawl 4-way",
                "sequence": 1,
                "notes": "Forward, backward, lateral"
            },
            {
                "id": "3906ff79-fbc0-4921-9a8c-bd22bb793bce",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded or single leg"
            }
        ]
    },
    {
        "id": "1af1c34e-3557-4da6-a4f6-83419de55947",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "0e3b722e-2db5-4662-8374-aab0642e262c",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/glute activation"
            },
            {
                "id": "d2f55694-d08f-4184-b87a-00af23a91883",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "238615b3-34b2-4f0a-a543-34574ebaf0d8",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring mobility"
            },
            {
                "id": "06af9ad1-ffb3-4d3b-9f3f-8153386bd174",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip/groin mobility"
            },
            {
                "id": "232b9570-7a62-48d9-9a18-0301f67f3af0",
                "name": "RRL",
                "sequence": 5,
                "notes": "Hip rotation"
            },
            {
                "id": "0907e2d0-dca6-402e-b145-d4f65206abd5",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "77dc4cd9-9367-4bd7-9751-5056bd6523b7",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "ffa2b017-828d-4847-994c-e6d7b8ecff80",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (bar only) (RPE 5). Set 2: Light+ (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            },
            {
                "id": "94d87ef2-46ef-4d38-a303-3dc512f3f73d",
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
        "id": "9454d29a-51d3-4832-80cf-05daa1a17c9f",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "49543cb1-fde5-4eae-b794-6f4dbfc1e83b",
                "name": "Jumping Jacks",
                "sequence": 1,
                "prescribed_reps": "30",
                "notes": "Elevate HR"
            },
            {
                "id": "2d766166-9597-449d-a80c-cf13a9bcb385",
                "name": "TRX Rows",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Activation"
            }
        ]
    },
    {
        "id": "054040a6-fd12-40cc-919d-b2f53c05f54b",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "c7262416-aae6-4af4-a90f-6b207ce7ad6e",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "0457349a-e6e3-4d65-8afa-844d6e44e09c",
                "name": "Rev. Lunge + Reach",
                "sequence": 2,
                "notes": "Hip flexor/t-spine"
            },
            {
                "id": "7718ea46-a520-417d-845c-a2ff473b7a26",
                "name": "High Knee Pull",
                "sequence": 3,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "d57c70fd-9969-4bad-b0cd-5bdbe609dc97",
                "name": "PVC Passovers",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "be93430a-4b97-421d-aa2f-0b758a027841",
                "name": "Spidermans",
                "sequence": 5,
                "notes": "Hip/groin mobility"
            },
            {
                "id": "e81063a7-a121-42b9-844e-7025669d9d96",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "ee726328-3fd5-4b48-bda6-2455fafcd7b2",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "6b4bc59a-3cb5-48da-81cf-a7f6bcd37931",
                "name": "Walking Lunges",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 5). Set 2: Light DBs (RPE 6). Set 3: Moderate DBs (RPE 7). Set 4: Heavy DBs (RPE 8). Rest: 90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "443e4722-01b2-43a2-b084-0ca1facb7453",
                "name": "Bent Over Row (BOR)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "5145967d-307d-496e-97dc-a088f5d51a3f",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "2a93fed3-84fd-4a33-bf2f-08fb31cdffbe",
                "name": "KB Swings",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "4 rounds total"
            },
            {
                "id": "3c6f6bfa-ba1d-4ee7-b2d8-0d936fba1af8",
                "name": "Russian Twists",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "15e",
                "notes": "4 rounds total"
            },
            {
                "id": "57425164-a896-490a-bde4-724b483bad4e",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "4 rounds total"
            },
            {
                "id": "89d9a3e3-a0c2-409d-b07a-4a98a625d563",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "4 rounds total"
            }
        ]
    },
    {
        "id": "2ad7e0b8-8faf-4cea-8d8b-e1fd205b3607",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "423d4f8a-7714-4ac6-8c2c-2788ae3b8517",
                "name": "Row",
                "sequence": 1,
                "notes": "500m - moderate pace"
            },
            {
                "id": "0f435d4a-2b40-44db-9cba-eaa098b4a0fb",
                "name": "Ladder Drills",
                "sequence": 2,
                "notes": "2-3 patterns"
            },
            {
                "id": "a2e2c3f3-90bc-41eb-87bd-a837c5be366a",
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
        "id": "c61e6313-426c-4801-821b-5e205031be38",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "f33d9376-ddf5-4546-8b1f-1e4e03e50712",
                "name": "Bike/Row",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "883dc957-e477-4b41-a6e5-ce39b047b870",
                "name": "Walkouts",
                "sequence": 2,
                "notes": "Full extension"
            }
        ]
    },
    {
        "id": "6969ce0b-8eef-4722-9dce-581734f65566",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "18210007-414d-4b9f-b1f3-bd7c94baefd5",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Hip hinge prep"
            },
            {
                "id": "49583b20-457a-4f27-a1b1-9bcbf9363cb5",
                "name": "Lunge + Rotation",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "76aa25f4-a91b-40e3-b966-f591588ba894",
                "name": "Hamstring Walks",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "37cc1762-c8a9-4081-9fd3-97707825a086",
                "name": "PVC Good Mornings",
                "sequence": 4,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "417210ea-4ee9-49e4-9ed8-0ba88d805f9d",
                "name": "Air Squats",
                "sequence": 5,
                "notes": "10 - Lower body activation"
            },
            {
                "id": "5388f2dc-6834-47b2-a22a-612e7b5cc44d",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "7b2787b3-c94d-4a6d-b8e9-d7118808942f",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "51118a52-ec34-4aa1-8f2e-2aab5e551a7e",
                "name": "Single Leg Deadlifts",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: TTP (Toe Touch Progression) between sets"
            },
            {
                "id": "f3daad57-2c2d-4548-a6e9-cbb80caeeb04",
                "name": "Single Arm BOR",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "87980f52-f472-4ff6-8e62-6018a36dc7fd",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 4,
        "exercises": [
            {
                "id": "331cb4eb-0bcf-4fc6-97ba-f6f886b3a756",
                "name": "Row",
                "sequence": 1,
                "notes": "300m - cool down pace"
            },
            {
                "id": "72e56617-8a0a-4dff-9d66-5b9eea5d3a1f",
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
        "id": "c8b523cc-efea-4356-81b8-aab66793f538",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "b11217a3-2748-43b4-a4d8-784309c6dfdb",
                "name": "Bear Crawl (4-way)",
                "sequence": 1,
                "notes": "Forward, back, lateral"
            },
            {
                "id": "aeb0684c-d04b-463f-a275-5898a7466b59",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded or single leg"
            }
        ]
    },
    {
        "id": "50fa6eae-01a1-4b69-9238-9ccb388bed7b",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "2afe5738-b34a-425c-a60b-e5da48eeda2a",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "4615ed17-e67b-4d43-be05-49faaf3e4946",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Hip hinge prep"
            },
            {
                "id": "bd778193-3cba-490b-9d2c-488260f19941",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring mobility"
            },
            {
                "id": "c66daff9-57d6-4d1b-822c-c6354285c5f6",
                "name": "Over/Under",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "92b00652-2c43-456c-909a-b93c2bd79148",
                "name": "SL Rotation",
                "sequence": 5,
                "notes": "Core activation"
            },
            {
                "id": "320698d3-0ee1-4726-b0a5-634f567939b6",
                "name": "RRL",
                "sequence": 6,
                "notes": "Hip rotation"
            }
        ]
    },
    {
        "id": "017b19f3-9825-4146-b0e8-67572d067434",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "7ba2826a-f25a-4157-9561-dec8df41861f",
                "name": "Overhead Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: PVC/Empty bar (RPE 5). Set 2: Light (RPE 6). Set 3: Light+ (RPE 6). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Pigeon stretch between sets"
            },
            {
                "id": "2a9c49be-7336-400d-9392-9c8330a23961",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child pose between sets"
            },
            {
                "id": "e0a7151e-694e-4f33-bc8a-60de97c41561",
                "name": "KB RDL",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: HS Walk between sets"
            },
            {
                "id": "34da0e98-63bf-41dc-b53d-f490e7286509",
                "name": "Arm Set (Curl, Row, Press)",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "6b8aa149-30a8-41c3-9c67-5b9fdea6df0e",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "67d782ce-ac11-4898-8784-bb1a16ef31e7",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "40 cal"
            },
            {
                "id": "ae4f4942-b883-4d81-aa8d-0bdc523a2f45",
                "name": "Calf Raise",
                "sequence": 2,
                "prescribed_reps": "30"
            },
            {
                "id": "bc35abde-8de4-40c9-843d-ebb5e51244f8",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "20e"
            },
            {
                "id": "5a414b89-f024-41af-8bbb-b7eb8d1b3da4",
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
        "id": "8c1b8bdb-0c7f-46d4-98a2-b6e552717e1f",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "c658adbb-d9d8-4c56-b551-7b85c3a0c8b0",
                "name": "Bike/Row",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "1a978082-614a-47e8-81d9-b40dc02b7084",
                "name": "Monster Walks",
                "sequence": 2,
                "notes": "Band at ankles"
            }
        ]
    },
    {
        "id": "77b638ea-fff8-4a8f-ae25-5452f0d5d0c6",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "d5797399-4848-4124-b4d3-5d88bdc9a125",
                "name": "Toy Soldiers",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "ae63cdca-0852-49ea-b29d-d3069c0905e5",
                "name": "PVC Good Morning",
                "sequence": 2,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "d4f8dd50-639c-4079-8851-d85541a3140f",
                "name": "Piriformis",
                "sequence": 3,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "98d746d7-d7ee-429c-a940-b118d6f5187d",
                "name": "Hamstring Walks",
                "sequence": 4,
                "notes": "Hamstring mobility"
            },
            {
                "id": "3f5ec046-d4f6-4c90-befb-e62d1dd35b78",
                "name": "Lunge + Rotation",
                "sequence": 5,
                "notes": "T-spine mobility"
            },
            {
                "id": "e83a5cf9-3a04-4867-8f70-839dda44c16d",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            },
            {
                "id": "cd0785f4-8eb0-4ae9-a6f5-b7f5dff3926d",
                "name": "TRX Rows",
                "sequence": 7,
                "notes": "10 - Back activation"
            }
        ]
    },
    {
        "id": "a8b11a5c-45fc-4e30-94e1-9b121583095b",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "04129a21-ccdb-4caa-8b5e-d046da5b94be",
                "name": "Negative Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1:  (RPE 7). Set 2:  (RPE 7). Set 3:  (RPE 8). Set 4:  (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "87689231-db06-46c8-8ac8-84fdcb5a9187",
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
        "id": "3ca2a6c2-4e83-4369-9744-4fb785e8b675",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "da8a8e87-6bdd-46a2-bd84-69ba367478e9",
                "name": "Monster Walks",
                "sequence": 1,
                "prescribed_reps": "2 lengths",
                "notes": "Band at ankles"
            },
            {
                "id": "ce517281-8a59-474a-9e42-300665988daa",
                "name": "Jumping Jacks",
                "sequence": 2,
                "prescribed_reps": "50",
                "notes": "Elevate HR"
            }
        ]
    },
    {
        "id": "53aca96d-3a22-43f4-80c9-31adff89f570",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "a1f771df-90bd-44ee-9494-5c70bc22f9ed",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "f02acd87-b2f3-4e80-b454-851e4584bd77",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "ca22b6f2-9f2c-4ffe-bc11-a1e2d7ba3bf5",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "4c15298e-ae2e-40a6-84b4-f9c06d85e696",
                "name": "Side Lunges",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "ea7f0211-9018-41ef-85d1-fe5e27c79bb5",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "16cb23b3-2b58-481c-825f-4faac100a282",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "f669c287-69ac-45b1-a7b5-0ab7ea24236e",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "b9eb89a6-a601-42bc-9ed3-5cde237378d3",
                "name": "Deadlift (Building)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Working (RPE 7-8). Set 5: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: Hamstring Walk between sets"
            },
            {
                "id": "21b09843-22b4-4652-9bf4-baebaa3d7c38",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "ed46508f-afa2-4883-8819-5922b349231a",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "544859d1-3831-4630-acb2-0ea80904a3b8",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "12 cal"
            },
            {
                "id": "8243aa3f-3c4f-4e7f-959a-97490ff578ce",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "e883cd89-2f17-4d6d-b9fd-0f09d45ab640",
                "name": "Side Lunges",
                "sequence": 3,
                "prescribed_reps": "12e"
            },
            {
                "id": "c4fd772d-b453-4772-83d8-4030f06b61ba",
                "name": "Burpees",
                "sequence": 4,
                "prescribed_reps": "12"
            },
            {
                "id": "56e658ef-794a-4e32-946d-9fd2bee646b4",
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
        "id": "f53396ca-fd60-482b-adf4-b65473861775",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "97404c90-184d-4f03-93ef-7f301ae247af",
                "name": "Jumping Jacks",
                "sequence": 1,
                "prescribed_reps": "20",
                "notes": "Elevate HR"
            },
            {
                "id": "dc292068-f5da-4d6a-be69-95e6dafe71b9",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_reps": "20",
                "notes": "Core activation"
            },
            {
                "id": "f9c34b77-43aa-40c7-8ac3-591039099b0b",
                "name": "Air Squats",
                "sequence": 3,
                "prescribed_reps": "20",
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "2e33297d-3743-4e9e-a69d-fba4d200d6dd",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "9eacb960-bc1e-428e-93fd-60ded9fcade6",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "75ea2b46-80ef-47e6-88ed-5d4595f808c1",
                "name": "Hamstring Walks",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "78443379-08a1-40d4-abb5-441f57895b0b",
                "name": "Lunge + Twist",
                "sequence": 3,
                "notes": "T-spine mobility"
            },
            {
                "id": "480cb478-a210-469e-8326-eba1e4915c3a",
                "name": "High Knee Pull",
                "sequence": 4,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "2a12b015-3cd2-4856-abab-72f2e1c2f905",
                "name": "Piriformis",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "e3c4b2f9-ad30-40b9-b90f-9d9ab3e76400",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Chest activation"
            }
        ]
    },
    {
        "id": "42112c88-2ec6-4923-a089-3ee5b392f951",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "36ff7c41-e52e-4327-b1ed-7f501bc50a73",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "a760ce8f-f02d-4e80-bc29-09d9e402f7db",
                "name": "KB Front Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "25569c09-b3f3-453a-bc3b-d8a8213da48f",
        "name": "Conditioning - 12 min EMOM",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "b9796ad5-2f80-4885-8ff2-6629aab62576",
                "name": "TGU",
                "sequence": 1,
                "prescribed_reps": "1e side"
            },
            {
                "id": "af8e5b72-5269-46f8-8084-0dd4bcfa0b61",
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
        "id": "acf604c5-9784-481a-8b5a-be2107047cce",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "6e6196b6-7606-4aee-9f61-51a79b2cb853",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "82305e7c-3902-48e2-9318-bb012ee0ea65",
                "name": "SL Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "fbab82df-1361-4333-bf9b-bc1adc3e4570",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "bfcc42bc-1326-4760-bc05-51b4c4516759",
                "name": "PVC Passovers",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "80a1ded3-ac23-4dbd-996d-9f9f4a9a8bc8",
                "name": "PVC Good Mornings",
                "sequence": 2,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "890158ba-1a98-4a84-a03d-abc39b5e07d9",
                "name": "Quad Pulls",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "188b30f8-7910-429e-b53d-a1b78e976517",
                "name": "Lunge + Reach",
                "sequence": 4,
                "notes": "Hip flexor/t-spine"
            },
            {
                "id": "48f9cc41-51d6-46de-92dd-c4b8e8239332",
                "name": "Air Squats",
                "sequence": 5,
                "notes": "10 - Lower body activation"
            },
            {
                "id": "b35b89c8-a48e-4072-9d6d-1db8ae0584c5",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "2e6535ff-17ba-45c2-9203-bed601382ab8",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "b6fad301-749a-4e9c-911c-9cdbd4e71087",
                "name": "KB Clean",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: SL Hip Opener between sets"
            },
            {
                "id": "ad406769-9b77-406c-ab31-f6f9c8b50ee8",
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
        "id": "556ec05c-ae46-41c1-991c-659d9c46a292",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "a1f7d07f-e1a5-47a2-ae4d-d87a8a790bbf",
                "name": "Jumping Jacks",
                "sequence": 1,
                "prescribed_reps": "30",
                "notes": "Elevate HR"
            },
            {
                "id": "70d91897-66a9-40a9-85b0-07307ecfe13c",
                "name": "Glute Bridges",
                "sequence": 2,
                "prescribed_reps": "30",
                "notes": "Glute activation"
            },
            {
                "id": "c13cab62-354d-4cac-a5cc-0aa8e8541c86",
                "name": "Plank",
                "sequence": 3,
                "prescribed_reps": "30 sec",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "34a2db51-9fab-4198-a0d9-7260a9b2cc09",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "4d554282-8204-43a3-978f-0e3d3d265265",
                "name": "High Knee Pulls",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "90db5603-a58f-444c-ae4b-fedc94167a7f",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "41eac500-2ca4-4b6f-bc12-79f3d37911c3",
                "name": "Piriformis",
                "sequence": 3,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "2585eb38-cfdb-49e8-9ac8-a155a146de29",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "684b1395-0ea6-402a-a450-dd880f2cdc27",
                "name": "Side Lunges",
                "sequence": 5,
                "notes": "Adductor mobility"
            },
            {
                "id": "1ca7f385-69c7-4af2-bae8-5bb734a68302",
                "name": "Walkouts",
                "sequence": 6,
                "notes": "10 - Full body activation"
            }
        ]
    },
    {
        "id": "2c3a4fb0-90c3-43f0-962a-78b50bdecc59",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "5f5e9bc0-e27c-4dcc-8924-07fd202ce855",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Set 5: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "a079b63a-f6c5-42a6-a291-9dfabbcda414",
                "name": "Split Squats",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 5). Set 2: Light DBs (RPE 6). Set 3: Moderate DBs (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "db167983-f22b-427f-998b-c0a729e04fec",
        "name": "Conditioning - Circuit Style",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "a3c314d7-4b83-49fe-90f3-7571be16621b",
                "name": "TRX Rows",
                "sequence": 1,
                "notes": "12-15"
            },
            {
                "id": "5df6499c-d6e0-4634-93c9-c4a292b377be",
                "name": "KB Swings",
                "sequence": 2,
                "notes": "15-20"
            },
            {
                "id": "e1b0a91c-4c8b-4720-8471-7612574675d9",
                "name": "Lunge + Rotate",
                "sequence": 3,
                "notes": "8e"
            },
            {
                "id": "502c51b5-f25a-4fb4-b1b7-6e2ab6025c6e",
                "name": "Farmers Carry Hold",
                "sequence": 4,
                "notes": "30-45 sec"
            },
            {
                "id": "2c81667e-d4ff-4a5e-928c-81004986ac9c",
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
        "id": "a89684e7-6eed-4260-8641-c5b20d228164",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "0f603a1d-5d3a-4771-9b23-8ffda0091022",
                "name": "Jump Rope",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "a8d317c9-72d0-4602-b68f-d451dbc218fb",
                "name": "Monster Walks",
                "sequence": 2,
                "notes": "Band at ankles"
            }
        ]
    },
    {
        "id": "67a25d25-bdf2-49ab-a1ff-9d00c440d924",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "a821ab5b-3f32-406c-908f-e9b9dce3b906",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "dacea58e-09f8-4d25-a114-9bf8b05224a8",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Hip hinge prep"
            },
            {
                "id": "e3a4ec32-a449-415f-92e9-ee8ff88a5861",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "fc7581e6-7011-4dbc-80b5-8e9607431422",
                "name": "Over/Under Fence",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "848ab940-cb4b-4c4f-a172-02cc10a5eb4b",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "b5362959-f2e2-4b6b-908a-65f68ac64485",
                "name": "Piriformis",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "40f70aed-af1d-4824-9aeb-64dfdea46b43",
                "name": "Spiderman",
                "sequence": 7,
                "notes": "Hip/groin mobility"
            }
        ]
    },
    {
        "id": "84bcfe7b-362c-4255-857c-3564578e4c74",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "01e67019-f51c-449b-a52f-2436e7a12e77",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Hamstring Walks between sets"
            },
            {
                "id": "ac08ae09-0e08-4428-a0fb-bfd01a3c2a65",
                "name": "Box Jumps or Step Ups",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "25 total",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 6). Rest: 60 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "ac63b33d-f97d-4cdf-8d7a-b3c9827be55d",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "19569ea5-2605-4169-b297-f6694b90c2dd",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "400m",
                "notes": "2 rounds total"
            },
            {
                "id": "afbba6d0-f5e9-4519-9665-a80d5c3161e6",
                "name": "Shoulder Taps",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "25e",
                "notes": "2 rounds total"
            },
            {
                "id": "559d9587-8cae-4844-9cc9-94c85869cc74",
                "name": "Air Squats",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "30",
                "notes": "2 rounds total"
            },
            {
                "id": "f5ca8fb4-4449-4c1d-87f5-d5b5decaa6d8",
                "name": "Deadbugs",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "25e",
                "notes": "2 rounds total"
            },
            {
                "id": "555f8b54-0485-400e-aab7-619ea2121cfb",
                "name": "Row",
                "sequence": 5,
                "prescribed_sets": 2,
                "prescribed_reps": "400m",
                "notes": "2 rounds total"
            },
            {
                "id": "5f3646af-b21b-4f39-8bef-aff6008d854a",
                "name": "KB Push Press",
                "sequence": 6,
                "prescribed_sets": 2,
                "prescribed_reps": "25",
                "notes": "2 rounds total"
            },
            {
                "id": "ea77888a-d1df-4f7d-aa2a-a6807fb9cdda",
                "name": "Sit Ups",
                "sequence": 7,
                "prescribed_sets": 2,
                "prescribed_reps": "25",
                "notes": "2 rounds total"
            },
            {
                "id": "feba97b2-ad92-4f93-adba-b7803b8d9564",
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
        "id": "29c7915f-fa43-4045-b0b3-f99381843ecf",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "3d58a9b7-4e47-45cf-93b2-6c084313f1d8",
                "name": "Jumping Jacks",
                "sequence": 1,
                "prescribed_reps": "50",
                "notes": "Elevate HR"
            },
            {
                "id": "5d761e1b-db89-4c9c-a421-9ee7991184b5",
                "name": "SL Bridges",
                "sequence": 2,
                "prescribed_reps": "20e",
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "e1e8a3dd-4e62-4cfa-a464-2a807f939fca",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "4cb160c5-8a48-4236-af8f-07b6598b5e45",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "ea897ac7-ee6f-4249-8336-b8e92cc9fcc1",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "a3d5ef99-902e-4140-92bd-76a320676acb",
                "name": "Arm Circles",
                "sequence": 3,
                "notes": "Shoulder prep"
            },
            {
                "id": "69408425-08fa-475a-8b26-c3bfa17ede98",
                "name": "Walkout + Push Up",
                "sequence": 4,
                "notes": "5 - Full body activation"
            },
            {
                "id": "748aefbd-5896-4e8b-88be-4e707ecc3039",
                "name": "Spidermans",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "5fbc5fde-1187-4246-92b7-e4ba8e9b43fc",
                "name": "Air Squats",
                "sequence": 6,
                "notes": "10 - Lower body activation"
            },
            {
                "id": "35ab683b-f73a-4563-9d8a-2339e8ff54f9",
                "name": "Good Mornings",
                "sequence": 7,
                "notes": "10 - Hip hinge prep"
            }
        ]
    },
    {
        "id": "a0ffa01f-11b8-4c79-8f6e-1fa058ef069e",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "bc5bd37b-3b12-4573-907d-97ac26713971",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7-8). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "c6c80453-81d1-4f8b-8fa7-d1b59a76a76d",
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
        "id": "6f85c8ca-9a4e-4c1c-9cf2-2fa8539021aa",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "824e14f2-3303-4c95-844e-41ae4034680b",
                "name": "Walkouts + Windmills",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Full ROM"
            }
        ]
    },
    {
        "id": "a039a537-7f45-4c30-b694-fd5865cd3791",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "57443409-0d3f-45b3-a7a0-d518810a4fe5",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Hip hinge prep"
            },
            {
                "id": "0bc3fa48-5a30-4b09-a5c4-61d0f63cbe44",
                "name": "Hamstring Walks",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "8456d16e-d0dc-40e8-a07a-d481f0e2fc2e",
                "name": "Bear Crawls/Quad Ped",
                "sequence": 3,
                "notes": "Core/shoulder activation"
            },
            {
                "id": "14c46bda-60e8-4e1d-9a64-25ad632fa611",
                "name": "Spidermans",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "f4f102ae-8c37-4ee3-b937-f6647baf4ee9",
                "name": "Side Lunge + Rotate",
                "sequence": 5,
                "notes": "Adductor/t-spine"
            },
            {
                "id": "43695a6a-03b3-442f-832b-0c0554a3bd45",
                "name": "PVC Passovers",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "8e52491e-0d06-4fb4-b333-b0ca882d78e0",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "bcb04681-004b-4926-a292-00d5a9865f24",
                "name": "Deadlifts (Building)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Working (RPE 7-8). Set 5: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: TTP between sets"
            },
            {
                "id": "4b93ad97-3246-44e3-97b8-08196320f5e3",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "1430ea39-beda-46f4-bc27-a7e6f9b82ac1",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "f47c7b93-c86d-4e2c-8c24-563f0eecbec7",
                "name": "Wall Sit",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            },
            {
                "id": "725a62bb-a63b-444a-aab4-f258380f3174",
                "name": "Side Plank",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "30 sec e",
                "notes": "3 rounds total"
            },
            {
                "id": "6b2a8252-7b75-4a28-8dfb-1536e7dbad8e",
                "name": "Jump Rope",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "75",
                "notes": "3 rounds total"
            },
            {
                "id": "90c33413-5341-4900-bbf8-9e439b542188",
                "name": "SL Resisted Bridge",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "3 rounds total"
            }
        ]
    },
    {
        "id": "00d3a9b6-e48a-48a8-8aae-a705cd5ad460",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "5d3aa9d9-7f30-4e01-a1b1-f8a02a97c8fd",
                "name": "Row",
                "sequence": 1,
                "notes": "500m cool down"
            },
            {
                "id": "eddc5422-c397-4d25-943b-f8d2f36cdab6",
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
        "id": "5c95284a-8dba-4dd3-b647-dfe23d5f7a64",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "ac50fba7-6b11-4dcd-8dca-7f111fc55953",
                "name": "Bear Crawls",
                "sequence": 1,
                "prescribed_reps": "2 lengths",
                "notes": "Forward and back"
            }
        ]
    },
    {
        "id": "431b7599-9281-437b-a3f1-98f87eeb542f",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "adaf58a4-4521-47c0-8b31-d9f5b34a1198",
                "name": "Hip Openers/Closers",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "c936d00d-fb31-4bc8-a784-a9f99ee0831d",
                "name": "Arm Circles",
                "sequence": 2,
                "notes": "Shoulder prep"
            },
            {
                "id": "b843f9a7-57c0-4297-abbc-ef3dd0e5fc26",
                "name": "High Knee Pulls",
                "sequence": 3,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "ccfc7050-94fb-4e66-a03b-7e0f053cad0b",
                "name": "High Knee Skips",
                "sequence": 4,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "1a7ee1e2-c7ae-41db-94a0-dc4eeaa88570",
                "name": "PVC Figure 8''s",
                "sequence": 5,
                "notes": "T-spine/shoulder"
            },
            {
                "id": "71d28b43-1d09-4f32-a11a-1017757330b9",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "f3eff59c-26c9-4280-8966-ddcc562f2fb3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "e1a512f9-bb32-4efd-b1d0-1793f1be62ec",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8-10 AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "03da492b-553c-44c4-9ec4-a79313fc957b",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "079e6521-0ea1-4b1f-ab5d-ef91575aea48",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "4c64445d-7c99-4ffd-beec-e2096388e8cf",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "300m",
                "notes": "4 rounds total"
            },
            {
                "id": "034f2f72-58ab-437d-b89d-30e808cad270",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "4 rounds total"
            },
            {
                "id": "9839f136-f8cc-4138-acd3-08aaf208aade",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            },
            {
                "id": "48b4b65c-9648-4fd1-9e15-b2e1e27f1a5e",
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
        "id": "b1c71868-7ff5-4398-8536-298a0a1b8cdf",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "effcaa2e-4662-4c0a-a9ff-5966b3572e1c",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_reps": "3 x 10",
                "notes": "Glute activation"
            },
            {
                "id": "eb78cff3-1859-4bc6-a7b6-f4c50c440c90",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_reps": "20e",
                "notes": "Core activation"
            },
            {
                "id": "fea2285e-2a3f-4840-831d-75c665cf18cd",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_reps": "20",
                "notes": "Back activation"
            }
        ]
    },
    {
        "id": "e01b0dad-16c5-4db7-85db-e8c3b29997fd",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "98d491ca-28ea-40dc-9bb7-3e06218fe73c",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/glute"
            },
            {
                "id": "4e11fbbf-75ba-4d16-ad12-e54bc055c9d9",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "1e1c5af4-7467-4026-b8bd-248a55279ccf",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "455cbf23-1e64-4bcb-9d50-d37fe5bde464",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "e95e2a36-85c7-407c-979f-5dffd288f145",
                "name": "Pigeon/Piriformis",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "7033afd3-98ef-4146-809f-a272f03ea785",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "53d49225-953a-48df-994b-81b477ef4017",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "e60c1a8a-a1d8-481f-9180-18321d9fc322",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            },
            {
                "id": "321665c5-5753-4fea-acc6-c25405353092",
                "name": "Strict Press",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate+ (RPE 7). Set 3: Working (RPE 7). Set 4: Working (RPE 8). Set 5: Working (RPE 8). Rest: 2-3 min between sets Accessory: Figure 8 between sets"
            }
        ]
    },
    {
        "id": "2f85953a-a6e0-4c22-8a6e-d49a4685f1a4",
        "name": "Conditioning - Core EMOM (12 min)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "c8211d74-c4da-4f05-9fa9-4150f999e584",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "10"
            },
            {
                "id": "2936595a-b4a1-4d36-9cf8-0c2873a839d2",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "f3a9e6b8-31cd-4347-955b-3faab1feb8a6",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_reps": "8"
            },
            {
                "id": "b2275874-e476-496a-923c-5ab982f210fc",
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
        "id": "d5daefe7-d5b3-499f-9324-f7d8a2dd00d9",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "cf7efffd-94e1-44d1-9554-44969c4ade80",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "10 cal",
                "notes": "Moderate pace"
            },
            {
                "id": "39dd46ac-cbaf-4a2d-bcd3-4cb097f3b61d",
                "name": "Monster Walks",
                "sequence": 2,
                "prescribed_reps": "2 lengths",
                "notes": "Band at ankles"
            },
            {
                "id": "4b895edc-6267-4c3b-ad93-84a7dfa24fca",
                "name": "Push Ups",
                "sequence": 3,
                "prescribed_reps": "10",
                "notes": "Activation"
            }
        ]
    },
    {
        "id": "e0013407-bb53-4446-9f2c-3d264db40b7a",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "84ba1523-dddd-439d-b351-110c30b3cd49",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "5085a0fb-7652-43ad-b3c7-4f81b227a2f9",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "8e89819d-6b25-455f-b3e1-507ebf121912",
                "name": "Side Lunges",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "aff4fbea-8e2c-499c-bdcb-3dcfa5fa9f85",
                "name": "Piriformis",
                "sequence": 4,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "f56c5913-e244-4498-a712-27eda2502f36",
                "name": "Hip Openers",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "ea69c65d-c10c-4bc0-83a2-538b111a25cd",
                "name": "PVC Passovers",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "532d74af-d4ee-4655-8711-5b4e1a604464",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "c31f95f3-0f07-47a3-a790-9ebc4c2fb247",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "d069bfbf-45f5-4920-9aba-5f2519494cda",
                "name": "SA DB Bench Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    },
    {
        "id": "70ecaccd-e0d7-408f-90a0-f08d1edada12",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "7a267612-c34a-41ec-b748-18f8cdda9521",
                "name": "HKTC",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "13cd82e9-428a-48ba-a1af-8d9b2a22a629",
                "name": "KB Swings",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "db729900-4659-45f7-b2ac-cd0c30ac5e09",
                "name": "Goblet Squats",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "842cec99-ef94-4df3-9ab8-954056aa729e",
                "name": "SA BOR (KB)",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "15e",
                "notes": "3 rounds total"
            },
            {
                "id": "dfa45ac0-fea3-44ee-8d25-502d606ca2ec",
                "name": "Russian Twists",
                "sequence": 5,
                "prescribed_sets": 3,
                "prescribed_reps": "15e",
                "notes": "3 rounds total"
            }
        ]
    },
    {
        "id": "ca266b94-6c69-4a16-bc10-f8753a9fde1d",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "f00566aa-faa8-4b36-a8bf-16a81eaa116a",
                "name": "Battle Ropes",
                "sequence": 1,
                "prescribed_reps": "30 sec"
            },
            {
                "id": "27ba0da6-0c90-4bef-8236-4f32ef437d2f",
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
        "id": "6ed7a23e-b017-4a37-ae8c-0d51049508a2",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "e484cd46-736a-4fe8-a492-ab0843a496df",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "560a99b7-d63d-4464-93e8-5c92539ae35b",
                "name": "SL Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "77196926-15d0-4ef3-937f-dd14a46f56e3",
                "name": "TRX Rows",
                "sequence": 3,
                "notes": "Back activation"
            }
        ]
    },
    {
        "id": "a41a83d2-e14d-45be-ae4f-0bd893f58df4",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "adcbfd02-127b-491d-93ae-3713f189155d",
                "name": "Toy Soldiers",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "48782c69-675d-4671-8e36-3be63a515e1f",
                "name": "Lunge + Rotate",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "5bf35102-93c5-43ec-a0c2-fce5c4e30eea",
                "name": "PVC Figure 8''s",
                "sequence": 3,
                "notes": "Shoulder/t-spine"
            },
            {
                "id": "9bc96de5-b71a-4db5-aa2f-5f52844c8df7",
                "name": "PVC Good Mornings",
                "sequence": 4,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "ecb32ba1-86c5-4528-9f97-560ba9616e51",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "fee8b4d2-8be2-436d-a8cd-f0fb8be336a6",
                "name": "Bear Crawls",
                "sequence": 6,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "6a8d7cd6-eb5b-4f25-b902-a6438a2af2c3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "4b34b8c9-9875-48e0-bad9-c87c8641690f",
                "name": "BB Slant Bar Twist",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: SL Rotation between sets"
            },
            {
                "id": "6ad0dab0-c85d-4156-89d2-a141148cc552",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 5). Set 2: Light DBs (RPE 6). Set 3: Moderate DBs (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "9d57c155-1454-43be-9488-caa6d31bf036",
        "name": "Conditioning - 20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "55858a57-5b65-4ce4-ae65-515df907421a",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "10 cal"
            },
            {
                "id": "7274a02c-b114-40f3-9be4-96efea0e35d1",
                "name": "Split Squat",
                "sequence": 2,
                "prescribed_reps": "10e"
            },
            {
                "id": "ad0ba197-9c0f-48f0-910d-81b632f180e2",
                "name": "TGU",
                "sequence": 3,
                "prescribed_reps": "5e"
            },
            {
                "id": "a8e8dbe0-c970-484c-9c0b-988f42ababa3",
                "name": "Russian Twists",
                "sequence": 4,
                "prescribed_reps": "10e"
            },
            {
                "id": "90f91ebc-f4ec-4e85-956b-63f91d821f6e",
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
        "id": "ec01a459-b174-4b80-b7f2-93e69818e4b7",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "262af2f3-7ace-476b-bbf2-a1bdfd4ca2d6",
                "name": "Monsters",
                "sequence": 1,
                "prescribed_reps": "2 lengths",
                "notes": "Band at ankles"
            },
            {
                "id": "875714c1-cf24-4497-9330-b7f1434e2b57",
                "name": "Banded Bridge",
                "sequence": 2,
                "prescribed_reps": "3 x 10",
                "notes": "Glute activation"
            },
            {
                "id": "d4b1f0fe-46a7-4a23-9ceb-a21afe74359a",
                "name": "Banded Squat",
                "sequence": 3,
                "prescribed_reps": "3 x 10",
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "41395a92-bbf4-4efb-a5c9-d148b9fbb734",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "13debcf8-8fdc-455d-9fdd-99576067c192",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "e491921b-364a-4c24-a91d-72a4d76377ac",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Hip hinge prep"
            },
            {
                "id": "59e59ab1-4150-4053-bfca-ccc863eeee54",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring mobility"
            },
            {
                "id": "5280b231-c928-45f6-a336-73814a27a056",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "eabcb284-6604-49a6-b351-7ca6d51b8c31",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "0a864637-4edb-440c-af6f-fc6ec267efd2",
                "name": "SL Rotation",
                "sequence": 6,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "2d673b41-485a-43e8-b10b-3b2c419b3844",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "38e0585f-da21-43ce-95ef-d6bf144dd57e",
                "name": "Turkish Get Up (TGU)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: SL Rotation between sets"
            },
            {
                "id": "0dcbf874-df4b-493a-bf4d-6f38ad6f2224",
                "name": "Slant Bar 3 Ext.",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Pigeon stretch between sets"
            },
            {
                "id": "061fbef4-727f-45ef-b374-f04f46b48ad4",
                "name": "Slant Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "36656ed0-9654-4b07-a540-25b8449e90b3",
                "name": "Arm Set (Curl, Row, Press)",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: PVC Pass between sets"
            }
        ]
    },
    {
        "id": "947287f6-2cf5-4d50-b7ea-2d71cbe0a860",
        "name": "Conditioning",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "63e70aea-f093-46bc-a8e3-1c8ab471c895",
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
        "id": "15ad47fd-59cb-4188-b232-bbe3de5cb56b",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "80429e65-903d-4d3f-99aa-26ad304731cd",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "313d1557-1bfd-43b0-8112-c64bc70bb3a4",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded or single leg"
            }
        ]
    },
    {
        "id": "610b66dc-1048-4515-acea-2f0bd3c81ea6",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "11c80fcc-bab9-4c02-8320-fb0b0285fb05",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/glute activation"
            },
            {
                "id": "d208e9fb-0d48-44c8-a273-c1f652593093",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "d25f79ea-3bfd-4aca-8269-b3792335a6de",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "d50b493f-2d09-48bf-a456-d97045ca70c7",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "daf60d3d-bd06-4e18-a422-59e4b01be060",
                "name": "Push Up W/O",
                "sequence": 5,
                "notes": "Upper body activation"
            },
            {
                "id": "81367286-0791-47cf-aaa8-9a5a267e9127",
                "name": "Pigeon/Piriformis",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "dd59f4f1-3b90-43af-a3fc-bf451551eed8",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "56cb9f15-9127-489d-862d-ca10390985b0",
                "name": "Lunge (3-way)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "12 total",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "213cad9c-8336-4c50-b57c-f6b49cd99d83",
                "name": "SA Row",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "aa171290-d8b0-4d2a-9bb3-a9128d64be92",
        "name": "Core Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "eb96db0b-c98a-4bc0-b496-16e7c7b489d7",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "250m"
            },
            {
                "id": "55956c87-fb9f-47c4-bf0e-dbf22cd34675",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "c6a3292d-eeae-4e59-90b3-f192b476ac62",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_reps": "12"
            },
            {
                "id": "56ab57d9-5bc3-4fea-ad2f-c3b23fe08ed8",
                "name": "Dead Bugs",
                "sequence": 4,
                "prescribed_reps": "15e"
            },
            {
                "id": "e1704bbc-f53d-4d29-b4a7-0e5ca2dc105f",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "250m"
            },
            {
                "id": "580c6620-1795-4125-9f8c-1568d5149db9",
                "name": "Push Press",
                "sequence": 6,
                "prescribed_reps": "10"
            },
            {
                "id": "3b0206f6-ea4a-4e32-be3c-dd75bdf5df2c",
                "name": "Sit Ups",
                "sequence": 7,
                "prescribed_reps": "12"
            },
            {
                "id": "afe92615-58dd-44cd-8da7-142fb33e9613",
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
        "id": "39006d85-dd0b-4504-9153-9f4b333613e5",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "dd1a35e9-cd7e-4b3c-b373-494961254bd5",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "3adc3d2f-2137-4677-894f-a57d7eac984f",
                "name": "Push Ups",
                "sequence": 2,
                "notes": "Upper body activation"
            },
            {
                "id": "0764e976-ff73-47b5-bf9c-6d109797eed7",
                "name": "Sit Ups",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "4bb160de-27e6-424e-858f-558628ec987a",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "bb42399f-2daa-4028-845f-acaa7bb4abb4",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "5a050d60-ef26-4228-9e08-ddd22ed42914",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "eb3cbc7c-2032-497b-bcea-dab1534670e9",
                "name": "Piriformis",
                "sequence": 3,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "135c91db-557d-42d1-a777-b837e5a3bca0",
                "name": "Rev. Lunge + Reach",
                "sequence": 4,
                "notes": "Hip flexor/t-spine"
            },
            {
                "id": "1d8e4302-1c90-40ed-b660-1e166099b745",
                "name": "PVC Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "c275e517-70d9-4d28-9fa8-249c9a3c4547",
                "name": "Bear Crawls",
                "sequence": 6,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "e61d74cf-407d-4755-bf67-459c25cce249",
        "name": "Intro - 9 min EMOM",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "ad8bfb95-2dcc-4fee-b1ae-79bda7936e32",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "10 cal"
            },
            {
                "id": "4c15d8c7-0b60-408f-8c6d-9e2a2c05c2e8",
                "name": "BB Deadlift",
                "sequence": 2,
                "prescribed_reps": "15"
            },
            {
                "id": "7c22d852-8849-43ec-82e7-60c87cfe40c5",
                "name": "Bar Over Burpees",
                "sequence": 3,
                "prescribed_reps": "10"
            }
        ]
    },
    {
        "id": "bfa3a21e-8291-47e5-a061-ac17d98ad99c",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "0e7edf4f-f4ef-44be-a3f9-795cf088d3da",
                "name": "Deadbugs",
                "sequence": 1,
                "prescribed_reps": "12e"
            },
            {
                "id": "8d6681ca-72ee-4eba-b42b-e743e932bbad",
                "name": "Step Ups",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "0268d56b-bbcd-414d-a710-6469f004ac0a",
                "name": "Farmer''s Carry",
                "sequence": 3,
                "prescribed_reps": "3 laps"
            },
            {
                "id": "adc3138e-218e-4cd5-9255-3940597fba64",
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
        "id": "964a1bd8-32fe-46a5-a2fc-8035244b02a8",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "1b6d8a9d-8ca6-4344-994a-8be23437ccf4",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "5d50c177-18b6-4e89-9768-85abe68b891c",
                "name": "Jumping Jacks",
                "sequence": 2,
                "notes": "Elevate HR"
            }
        ]
    },
    {
        "id": "f30463a5-7377-4490-b44a-64a60266306d",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "10060344-415f-4b81-bedb-16ff1c65dad2",
                "name": "Piriformis",
                "sequence": 1,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "e44e4f63-3118-4c24-86ab-8cbde226bc29",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "8445a7df-7af8-4f54-8c56-1a351711e8db",
                "name": "Side Lunges",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "a7eaaee3-7f2a-4976-85a2-bfb7ebf24818",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "874f9f2e-8c1c-456a-b5ef-1eebc38a845d",
                "name": "High Knee Pull",
                "sequence": 5,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "db2a3a58-5aa0-448f-8b46-1abcfd4dd708",
                "name": "Over/Under Fence",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "801e6632-2e1c-428e-ba59-8ed4b6011762",
                "name": "Push Ups",
                "sequence": 7,
                "notes": "10 - Chest activation"
            },
            {
                "id": "24c2b553-8826-4a31-8ed7-bfbad70d81b8",
                "name": "Glute Bridges",
                "sequence": 8,
                "notes": "30 - Glute activation"
            }
        ]
    },
    {
        "id": "3419b8bf-b28a-4f96-ab13-67cc8bb89e5b",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "48f021b4-bf80-494f-9430-6236951113fe",
                "name": "DB Bench (Heavy)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "6",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Set 4: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "e5595146-e9c3-4a20-b3ca-88136ede69f8",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "ba309291-7f02-4ef2-bf70-56c943cbfbb9",
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
        "id": "42964068-af45-443d-952d-1d1b26e6e8ea",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "29cb156f-3ac5-4185-b284-5a95efe7facf",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "1 min",
                "notes": "Easy pace"
            },
            {
                "id": "1187b8aa-7a64-4fe0-90a1-cdc41ad67eca",
                "name": "Jump Rope",
                "sequence": 2,
                "prescribed_reps": "1 min",
                "notes": "Moderate pace"
            },
            {
                "id": "abbc7467-6e25-4bbd-8310-10124d2d9987",
                "name": "Plank",
                "sequence": 3,
                "prescribed_reps": "1 min",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "800f5cd1-9d7d-4338-a2db-ab96524f1fa4",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "04935b04-2311-43b1-bca8-3e3ec2135149",
                "name": "Arm Circles",
                "sequence": 1,
                "notes": "Shoulder prep"
            },
            {
                "id": "34ff8232-f0bf-446b-a442-28baa2f6c2ba",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "08eb9afc-01ac-4cbb-805c-0cfb25f0910b",
                "name": "Hamstring Walks",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "efa689aa-98b0-47b1-8432-563523fd0964",
                "name": "Lunge + Reach",
                "sequence": 4,
                "notes": "Hip flexor/t-spine"
            },
            {
                "id": "cade5858-dd5a-4c69-80d7-fab1ee60a93d",
                "name": "Spidermans",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "97d66c3e-a2d8-4bed-9b57-a26169013ae3",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            },
            {
                "id": "8e8cd2b4-f5ac-47ed-9884-ed9a42eb9b65",
                "name": "Air Squats",
                "sequence": 7,
                "notes": "20 - Lower body activation"
            }
        ]
    },
    {
        "id": "6f7f5b2c-f1fd-4d25-81d4-2f8c87b4fcc0",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "b4f7f671-422f-4662-b7c3-10ddd01d4e60",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "9efb809b-da33-4c35-ab38-f98bedac39d0",
                "name": "Deadlifts (Building)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "8fecab3e-edaa-478c-8419-1e937d601e39",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "42489a4b-41b1-4784-94fd-7636730cf590",
                "name": "Step Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "4 rounds total"
            },
            {
                "id": "a13ee68d-b4d8-4b3d-804f-23bfc79c1816",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            },
            {
                "id": "f7a65a6c-bd6d-4167-a003-08b5fa9b2988",
                "name": "KB Swings",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            },
            {
                "id": "4b635a71-5c0d-40f4-8a9e-58c4766f1484",
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
        "id": "c5dd8fa8-2817-408a-b69f-c352315f8c82",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "51701b3f-cb30-43c9-ab01-cbbc0d702982",
                "name": "Push Ups",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Chest activation"
            },
            {
                "id": "ad3db5e9-222d-46ba-9a55-725bb9b92e04",
                "name": "Air Squats",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Lower body activation"
            },
            {
                "id": "2dc9504b-c387-4855-a103-e416ec3a4fd8",
                "name": "Jumping Jacks",
                "sequence": 3,
                "prescribed_reps": "30",
                "notes": "Elevate HR"
            }
        ]
    },
    {
        "id": "66bd76e8-40b2-42d4-8561-352ba67efbd3",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "457cec61-17fd-4d13-96c7-f40ee3532dd3",
                "name": "Lunge + Twist",
                "sequence": 1,
                "notes": "T-spine mobility"
            },
            {
                "id": "5953867f-f888-4f69-a457-4c6b0389047b",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "cfcb5977-f6fc-4d8d-8bf4-c77a9e228fc9",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "026db2bc-71c9-4d8b-bc5f-6bf0e3e69551",
                "name": "PVC Passovers",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "e57dafa0-63a1-43d1-9182-3b8c4c0e47a8",
                "name": "PVC Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "ebcf277b-9c8f-4671-b5d1-fd7385425b50",
                "name": "High Knee Skip",
                "sequence": 6,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "021d93c7-1345-4e58-9769-e71aa268b75c",
                "name": "Pigeon",
                "sequence": 7,
                "notes": "Hip opener"
            }
        ]
    },
    {
        "id": "e204ef41-2ecc-4888-9afc-b086c6291061",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "4c219647-4144-4c36-8c6c-5fd3b3a673bc",
                "name": "Single Leg Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Bodyweight/Light (RPE 7). Set 3: Light (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "b72fe3dc-4dd6-445c-a40d-638d4d78f4a0",
                "name": "Negative Push Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1:  (RPE 6). Set 2:  (RPE 7). Set 3:  (RPE 7). Set 4:  (RPE 8). Rest: 60-90 sec between sets Accessory: Foam Angels between sets"
            }
        ]
    },
    {
        "id": "d369a2ea-9236-4635-8f49-c486b738aefb",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "540814c4-5d63-48ea-a427-eed50b6c261b",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "12 cal",
                "notes": "2 rounds total"
            },
            {
                "id": "523b2706-5a10-40d4-89a3-48857137f299",
                "name": "MB Toe Taps",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "7b57647f-fe08-4f3d-a1d8-85b260eea4a8",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "a7da1c01-77cc-451d-adf5-529bf78eb4a3",
                "name": "Row/Bike",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "12 cal",
                "notes": "2 rounds total"
            },
            {
                "id": "656880b1-e526-49b0-bdd5-8a85d2626d47",
                "name": "Deadbugs",
                "sequence": 5,
                "prescribed_sets": 2,
                "prescribed_reps": "12e",
                "notes": "2 rounds total"
            },
            {
                "id": "d9582912-f6c4-4f08-8d50-9df89f0afeac",
                "name": "KB Swings",
                "sequence": 6,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "8ba83728-e889-4828-9d97-a7e0e5d5b9b0",
                "name": "Row/Bike",
                "sequence": 7,
                "prescribed_sets": 2,
                "prescribed_reps": "12 cal",
                "notes": "2 rounds total"
            },
            {
                "id": "b706b081-7098-40b9-8c30-c2e71a29b3c6",
                "name": "Box Jump/Step Up",
                "sequence": 8,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "1e22b467-cc49-41c6-be5b-43639f00ab99",
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
        "id": "0020cd57-cea8-43bc-963b-743c276d3972",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "a37a64cc-beb9-4cff-9ebe-5ed42f26505a",
                "name": "Row/Jump Rope",
                "sequence": 1,
                "notes": "Easy pace warm-up"
            },
            {
                "id": "46b203a2-a55c-41ee-944b-b3b1b5f2a42d",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded or SL variation"
            }
        ]
    },
    {
        "id": "b399e015-6a89-480f-a707-e41e79449db7",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "8dbd312a-452d-4fdf-ada3-f9c191e168aa",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "b5179e30-e9e9-416f-96ea-3faebdc31aaa",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "5d6d3560-dc16-494d-a07a-b710d1e92671",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "94542aad-fd8e-4687-9584-f4973232ba41",
                "name": "HS Walk",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "ae2f558f-2e30-4c35-ae55-14a7a7f805d9",
                "name": "Push Up W/O",
                "sequence": 5,
                "notes": "Upper body activation"
            },
            {
                "id": "3586d200-003b-485c-82f5-f74b982725c4",
                "name": "90s Robot",
                "sequence": 6,
                "notes": "T-spine mobility"
            }
        ]
    },
    {
        "id": "b0b45e4d-861f-4081-bf54-a21988a24a7d",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "0727bdb5-3bdd-4d39-82ac-b8c6148ae70b",
                "name": "Single Leg Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "129082b8-a09b-4fd8-9fd4-57ecb7df67bd",
                "name": "Bent Over Row (BOR)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "ef472084-d598-4acf-85db-4956a05a309d",
        "name": "Conditioning - Chipper",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "db8f53d5-178f-4d21-a30e-ccb120725a16",
                "name": "Slamballs",
                "sequence": 1,
                "prescribed_reps": "30"
            },
            {
                "id": "2dda5a22-187a-4807-9885-6989953ea3f1",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "30e"
            },
            {
                "id": "e4698a12-0622-47db-92c0-25cd81d2ed53",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_reps": "30"
            },
            {
                "id": "9debaff2-b77c-4311-beda-5c9c26aa648a",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_reps": "30"
            },
            {
                "id": "ce44dd97-1f74-4755-b0d4-5a61e9da602c",
                "name": "TRX Row",
                "sequence": 5,
                "prescribed_reps": "30"
            },
            {
                "id": "3a18e88b-5515-4bcd-bac9-14e810d1a602",
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
        "id": "a5724e2a-1280-4572-b19e-343e9904aaaf",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "8634ab8d-748e-4dbb-90c8-e6c31145f654",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "e93e4abb-78ff-4af5-906f-53f609cff67c",
                "name": "Monster Walks",
                "sequence": 2,
                "notes": "Band at ankles"
            }
        ]
    },
    {
        "id": "dc4ed84e-9817-4bbd-b944-0e9c1282be66",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "2d22ea96-1bbd-44d9-af62-de28c56c9b52",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "de6f8a6b-c7bf-4d8a-ae96-c9e65314eae2",
                "name": "SL Hinge Quad Pull",
                "sequence": 2,
                "notes": "Hip hinge/quad prep"
            },
            {
                "id": "c4611e34-d26b-4fbd-bf97-943a4223068a",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "ac39fe7b-db5a-4983-93aa-468e3cd3695f",
                "name": "Over/Under Fence",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "932bbe90-aaf1-43b6-94ca-944963740744",
                "name": "Piriformis",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "4f65d48f-27f4-4648-8579-220b972db137",
                "name": "PVC Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge pattern"
            },
            {
                "id": "fe7ede63-55b4-4917-b052-4333997d40b3",
                "name": "Rev. Lunge + Reach",
                "sequence": 7,
                "notes": "T-spine mobility"
            }
        ]
    },
    {
        "id": "9947568e-46bf-4428-8b93-165d33c54765",
        "name": "Intro - 9 min EMOM",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "d689d640-c89a-4e2a-8e2e-7f6c9f775ec0",
                "name": "Snow Angels",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "133b9c46-f57d-489c-ba48-25eb2f1a2d13",
                "name": "Row/Bike",
                "sequence": 2,
                "notes": "Moderate pace"
            },
            {
                "id": "85b22199-9f0e-4c5c-a0aa-85b5644667fc",
                "name": "Sit Ups",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "92c1e149-e96c-44f6-8b22-197f5a2947fd",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "251ea0cc-e80d-4f87-8fd6-229f461d67d7",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "89344dfc-c02e-48b8-9cce-c328dc1aec3d",
        "name": "Conditioning - 12 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "e456f036-ac27-4924-9c3e-c22017ad5cd6",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m"
            },
            {
                "id": "03a1ee8f-263b-4fac-a07a-d7e1eb7994db",
                "name": "Push Press",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "e2bc1ae5-f29e-4531-92a0-af886c2cbf3a",
                "name": "SA KB Swing",
                "sequence": 3,
                "prescribed_reps": "8e"
            },
            {
                "id": "1c95b7c3-83c8-4a1c-9822-6da38892ad27",
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
        "id": "8774c20c-ffb2-4e26-a122-9a92f0321d4c",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "f5712aed-471c-48f0-b447-b03f690b4083",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "5eebe064-ada8-43d1-841c-adc9c9beff1e",
                "name": "Inchworms",
                "sequence": 2,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "baf12270-a378-4286-9ca7-e1fc008fb686",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "35b9eb7f-6ce4-44b8-839e-7efa0a602b40",
                "name": "Bear Crawls",
                "sequence": 1,
                "notes": "Core/coordination"
            },
            {
                "id": "1e45a722-9d44-4cd2-ab4b-aa8ee009a3fe",
                "name": "Hamstring Walks",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "5652808c-23e7-4036-9d40-a4d15842af41",
                "name": "SL Hinge Quad Pull",
                "sequence": 3,
                "notes": "Hip hinge/quad prep"
            },
            {
                "id": "4bf97999-ad21-46c8-8637-896f56393dda",
                "name": "Spidermans",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "67a2c20a-4a73-4a74-9960-5d82b6787d61",
                "name": "Side Lunges",
                "sequence": 5,
                "notes": "Adductor mobility"
            },
            {
                "id": "1e2acd3f-c87e-44a8-b3c0-4634bc96a6fa",
                "name": "PVC Figure 8''s",
                "sequence": 6,
                "notes": "T-spine/shoulder"
            },
            {
                "id": "12b8f573-a97e-4054-be11-d7e4d3de3772",
                "name": "Butt Kicks",
                "sequence": 7,
                "notes": "Quad activation"
            },
            {
                "id": "e1b1f128-bbca-45d9-a428-002e67940e73",
                "name": "Air Squats",
                "sequence": 8,
                "notes": "30 - Lower body prep"
            }
        ]
    },
    {
        "id": "d39077fb-6a1d-46e5-9878-1349cb38f448",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "32b93216-03d3-4da7-9044-ef7a165f549c",
                "name": "Lateral Step Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "05ebdfe2-7518-4081-9155-70a358c2640f",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "6e962572-ef8a-48dd-8212-c417fdc04611",
        "name": "Conditioning - Bodyweight Chipper",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "a3355700-3248-4e7a-a403-3c36d209a086",
                "name": "TGU",
                "sequence": 1,
                "prescribed_reps": "5e"
            },
            {
                "id": "9cddaebb-3258-46ac-94da-7e233321fa4a",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_reps": "20"
            },
            {
                "id": "19b1f66f-7066-4be6-b587-6b3e3952fd95",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "20e"
            },
            {
                "id": "edfe0bc1-7be9-4e2c-a527-9a8edeb86f4e",
                "name": "Air Squats",
                "sequence": 4,
                "prescribed_reps": "100"
            },
            {
                "id": "190b72be-d999-473e-aa15-0f280c07abab",
                "name": "Push Ups",
                "sequence": 5,
                "prescribed_reps": "20"
            },
            {
                "id": "fac14db8-0369-4ab8-a352-764a14ba6a60",
                "name": "Rev. Lunges",
                "sequence": 6,
                "prescribed_reps": "20e"
            },
            {
                "id": "c64669cd-5f21-43f3-b887-bb19c666af9e",
                "name": "Mountain Climbers",
                "sequence": 7,
                "prescribed_reps": "50e"
            },
            {
                "id": "d5e1856a-3ab8-42f0-b047-79f7faacb731",
                "name": "SL Bridges",
                "sequence": 8,
                "prescribed_reps": "20e"
            },
            {
                "id": "41f31656-0cd6-4cd2-90f4-dcdba0bdd819",
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
        "id": "68e01c42-cf68-4318-8ea1-7f720ea04d28",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "5bfb4d36-76a4-489b-b3cc-1947037b0e15",
                "name": "Bear Crawls",
                "sequence": 1,
                "notes": "Forward and back"
            },
            {
                "id": "58d4ab77-18eb-460c-92ae-8bf8c7c7a07d",
                "name": "Row/Bike",
                "sequence": 2,
                "notes": "Easy pace"
            }
        ]
    },
    {
        "id": "68bb3f42-98e2-474c-aede-2856e37cab0e",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "51476459-429c-487d-ad2d-cc957a53d4f9",
                "name": "Hip Openers/Closers",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "b79d88b3-9f38-4b8f-a2da-e43656aebbb4",
                "name": "High Knee Pulls",
                "sequence": 2,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "95d58c45-bb2d-404b-9bb1-5569067d0586",
                "name": "Quad Pulls",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "c02cf357-7a8c-471f-b698-7489904c97f4",
                "name": "Piriformis",
                "sequence": 4,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "f46e39d0-eb73-4ff3-b7a0-40a4376a48c3",
                "name": "Hamstring Walks",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "1610f133-23db-4e2a-9ec9-95c040260c24",
                "name": "Air Squats",
                "sequence": 6,
                "notes": "10 - Lower body prep"
            },
            {
                "id": "822949eb-5e68-4122-a2fd-39ec1fa43f6a",
                "name": "Push Ups",
                "sequence": 7,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "d89a81f5-6c81-4a2b-aec0-8d6316aa559e",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "25f4ddbd-1df5-4a6e-ab59-4abd7bab0d41",
                "name": "Slant Bar Twist",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: SL Rotation between sets"
            },
            {
                "id": "d47bd799-898e-4478-b26b-6957ea57f357",
                "name": "Slant Bar 3 Ext.",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Pigeon stretch between sets"
            }
        ]
    },
    {
        "id": "265742cb-6257-4f3f-88b1-08ba37b4f3f5",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "f92de541-3cf1-4c7b-a423-cade94f73c65",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "300m/600m",
                "notes": "4 rounds total"
            },
            {
                "id": "364d2810-c094-46ef-ab32-eb38a63cdd9b",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "4 rounds total"
            },
            {
                "id": "49f4cb6a-9863-488b-b65d-d51952c454a0",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            },
            {
                "id": "ba0a22c1-664d-436d-9b82-e6665f0c1d13",
                "name": "\u00bd Knee Chops",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "4 rounds total"
            }
        ]
    },
    {
        "id": "6c8ea4a8-b4a5-4203-abe3-010a86b8eb7f",
        "name": "Cash Out",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "7b8cf7dd-38b8-4320-9ff9-762e55cbea6f",
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
        "id": "51da3fbd-fc98-4191-85a5-1d8510a3717a",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "6f5c3c37-983d-4ba2-974f-10a1ed8a036a",
                "name": "Clam Shells",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "8e6be619-2fbd-430a-b091-3c0412f5d578",
                "name": "Seated Wall Angels",
                "sequence": 2,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "1a0f08ef-dc5a-4a69-9e1e-775aede9c957",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "cfebca4e-a606-42b3-a76d-49228de67947",
                "name": "Lunge + Reach",
                "sequence": 1,
                "notes": "T-spine mobility"
            },
            {
                "id": "d867fa6b-3856-4d9c-bf8a-7fbbdf70a8c9",
                "name": "Spidermans",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "eb6d200f-5c74-47bc-a5d3-7322f64725a0",
                "name": "Quad Pulls",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "26e33669-beab-4d1d-b5fa-38728a27539d",
                "name": "Hip Openers/Closers",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "e0186221-1113-48a4-ac9f-53018041ca87",
                "name": "PVC Passovers",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "ead858f7-0bbf-4959-82f4-e0ec089c9fe2",
                "name": "PVC Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            },
            {
                "id": "e938b396-4533-4d97-8e2c-527d07caf43b",
                "name": "Karaoke",
                "sequence": 7,
                "notes": "Hip/coordination"
            }
        ]
    },
    {
        "id": "2917b228-de68-4b13-9e5e-8f34eebe572f",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "a263e4e3-49b6-45ac-8c7a-3eceef8ebb30",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "5e7cdd4d-e18f-42e7-87ae-4ab44f865842",
                "name": "SA KB Clean",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lateral Plank Walks x 2 between sets"
            }
        ]
    },
    {
        "id": "4e4ac503-0d4c-476e-9829-7f62937b2ed7",
        "name": "Cash Out",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "596b5299-d6f9-48f7-8d27-cfa9a21e433e",
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
        "id": "3a22af3c-11e0-48b0-a230-b5bce3d1c6af",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "f90af68e-4379-4d8f-93af-66d595fa9df4",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "2042153b-24ce-4aca-af93-c42127596527",
                "name": "Sit Ups",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "30b7328f-99cb-4eff-a022-c0d5ba6e5af1",
                "name": "Push Ups",
                "sequence": 3,
                "notes": "Upper body activation"
            },
            {
                "id": "6c53a3c7-ea77-4fb1-a70c-aa17d12b271a",
                "name": "Air Squats",
                "sequence": 4,
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "7f958560-771b-4967-bc41-13860bad6251",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "e6bf04ae-a4c8-442f-a91f-c26439c5ec1b",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "2f3e8c26-42b8-4fe7-9314-edaaa64fa985",
                "name": "Toy Soldiers",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "b9efb83b-e606-480d-8923-65004f85ae28",
                "name": "SL Hinge Quad Pull",
                "sequence": 3,
                "notes": "Hip hinge/quad prep"
            },
            {
                "id": "72c860d9-8d93-4335-b2b1-64a761fd2d47",
                "name": "Over/Under Fence",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "7ada16fe-18ed-4f47-9cef-1d4d0a669977",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "be86ce24-bb61-4f88-ac13-d2e534a2afc5",
                "name": "High Knee Skip",
                "sequence": 6,
                "notes": "Dynamic warm-up"
            }
        ]
    },
    {
        "id": "85226fb1-3e87-402d-b57e-ed6187858cc9",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "9b5d21e0-bba2-419e-91ff-72798a219082",
                "name": "Single Leg Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "eb6f53e5-199f-4e2e-a821-6cef819a1c29",
                "name": "DB Bench Press",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate+ (RPE 7). Set 3: Heavy (RPE 7). Set 4: Heavy+ (RPE 8). Rest: 90 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    },
    {
        "id": "ab110b91-1994-4d70-ae26-921d8dfb2bab",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "7084c794-cf3f-4cde-a9ff-9b8a8afd6f06",
                "name": "Goblet Squats",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "fb642565-05e1-45a7-858d-9889da34c5cf",
                "name": "Push Press",
                "sequence": 2,
                "prescribed_reps": "15"
            },
            {
                "id": "d2619d8a-bfb8-4b8e-b76d-39e2cb408273",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "15e"
            },
            {
                "id": "f4527738-f692-44b8-be2e-ea90d6c5822b",
                "name": "Pull Ups/TRX Rows",
                "sequence": 4,
                "prescribed_reps": "15"
            },
            {
                "id": "712e6ea3-fbd3-47d9-be7a-58b9fe32b779",
                "name": "Snow Angels",
                "sequence": 5,
                "prescribed_reps": "15"
            },
            {
                "id": "813f04ec-051f-4ed7-8fc6-21236aa1a97c",
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
        "id": "ae6e8932-877a-4843-a14f-1c3680cebad9",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "71b75162-d969-4393-8582-5803526f72e2",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "77ad56c7-3129-4920-bf44-baf5fc5b4193",
                "name": "SL Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "34e0ba69-ca0d-4a30-9e1c-66383f5c5400",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "2eb2f175-b15b-4040-aed6-16fad38fad48",
                "name": "Hip Openers",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "89410b90-fadc-48c7-9edd-96efabcaa950",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "515c711b-0d23-411d-a921-c25b5d30e836",
                "name": "Arm Circles",
                "sequence": 3,
                "notes": "Shoulder prep"
            },
            {
                "id": "5fa985bd-f0e5-471d-bfec-04595a2352b5",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "4aa1ff2c-5948-4204-a680-157550d450db",
                "name": "High Knee Pulls",
                "sequence": 5,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "932743bf-40c6-47f2-a8f7-f3719ab0e7c3",
                "name": "Butt Kicks",
                "sequence": 6,
                "notes": "Quad activation"
            },
            {
                "id": "febabefd-94c2-41f6-b646-d89cd6f3a141",
                "name": "Walkout + Windmill",
                "sequence": 7,
                "notes": "5 - Full body activation"
            },
            {
                "id": "4a2cc746-2e09-444f-aa47-f08d92c6e4ad",
                "name": "Lunge + Reach",
                "sequence": 8,
                "notes": "T-spine mobility"
            }
        ]
    },
    {
        "id": "deacd155-52ec-460a-b157-b050243b0560",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "79e43eed-eeac-4921-b1d3-47cd45f22781",
                "name": "Bench Press",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy+ (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "29c52f84-66ed-48fb-818b-b5b849106038",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Moderate (RPE 7). Rest: As needed between sides Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "0579975c-8e38-46a3-b8be-108f1e8e640c",
        "name": "Conditioning - 20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "80046e16-b9f9-43fa-999f-43b37438a568",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "20 cal"
            },
            {
                "id": "d734cfcb-e7a7-4de5-8266-6da3fd2786e1",
                "name": "MB Toe Taps",
                "sequence": 2,
                "prescribed_reps": "20"
            },
            {
                "id": "b61348a0-4f1f-439c-8a85-103a47aac374",
                "name": "TRX Rows",
                "sequence": 3,
                "prescribed_reps": "20"
            },
            {
                "id": "ad6a0dc1-2767-4b17-b4e1-57771ce6b176",
                "name": "Walking Lunge",
                "sequence": 4,
                "prescribed_reps": "10e"
            },
            {
                "id": "6c6abf63-3af1-4d96-b799-22bf381f619a",
                "name": "Shoulder Taps",
                "sequence": 5,
                "prescribed_reps": "10e"
            },
            {
                "id": "bd7ca9d8-c66f-497c-8fb5-f643b0fa7745",
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
        "id": "21e8662d-afad-42f6-9fff-8dc1273c1a2c",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "2820673b-7fdb-4841-ad94-664b8630bee1",
                "name": "Jump Rope",
                "sequence": 1,
                "notes": "OR Row 500m"
            }
        ]
    },
    {
        "id": "0680a925-e4da-4845-aa09-d033d8829216",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "f97e5ef2-2710-482f-96d6-333b3ac2d1c3",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "723ec1f3-387b-4a79-bd8c-468a702ef2b9",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "bede8345-9de0-4c54-8380-0389a25c9724",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "0200c19d-0a34-40ac-93e4-f16ad4ffbf8e",
                "name": "Push Up W/O",
                "sequence": 4,
                "notes": "Upper body activation"
            },
            {
                "id": "138fb7fd-4391-4084-b820-e6c69bb34fcf",
                "name": "RRL",
                "sequence": 5,
                "notes": "Rotational prep"
            },
            {
                "id": "a37b2df9-9a7b-42bb-ac83-717eb4ee1558",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "b2c8a34b-a8a7-4706-a10c-cf24d598b9e5",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "402ba900-0787-49c1-ab24-5d80ffc7e169",
                "name": "Bridge (Activation)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded or SL (RPE 5). Set 2: Banded or SL (RPE 5). Set 3: Banded or SL (RPE 5)"
            },
            {
                "id": "1f4c38cb-fc9f-43e7-a0e1-59ab44e17dfb",
                "name": "Push Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Figure 8 between sets"
            },
            {
                "id": "5e3e73c6-b77a-4d3c-889b-94cc58bc072d",
                "name": "Good Mornings",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: TTP (Touch the Post) between sets"
            }
        ]
    },
    {
        "id": "1b3faaeb-0ea4-47f7-8367-6155c5f824bd",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "a92fb386-4b11-4794-a3e9-5114081a18ff",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "250m"
            },
            {
                "id": "62250851-faf8-4032-91a1-cbcd93b5f25f",
                "name": "Lunges",
                "sequence": 2,
                "prescribed_reps": "8e"
            },
            {
                "id": "defce179-8038-4c60-808d-66b78f7f9d93",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_reps": "12"
            },
            {
                "id": "8b6d4b99-6199-4c0c-8fb4-a5b60a76dd95",
                "name": "\u00bd Knee Chop",
                "sequence": 4,
                "prescribed_reps": "8e"
            },
            {
                "id": "bea28e59-9b8e-4b0b-83b0-753f9a476df5",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "250m"
            },
            {
                "id": "8ceb4674-d903-4561-adc0-7aa5a912fe25",
                "name": "Slamball",
                "sequence": 6,
                "prescribed_reps": "10"
            },
            {
                "id": "cca14160-ffc6-43a6-8c01-bb6ba315adc7",
                "name": "Russian Twist",
                "sequence": 7,
                "prescribed_reps": "10e"
            },
            {
                "id": "8f4dd3ee-c309-41ac-ad48-e8468025dbbe",
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
        "id": "20c08b1a-a4a3-4858-881b-f86c9ff99d03",
        "name": "Active - x3 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "995ae777-aae1-4d35-8c7e-b5b744f89740",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Glute activation"
            },
            {
                "id": "eb32bdb6-75e9-4592-9859-ce0f58363e76",
                "name": "Starfish",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Core activation"
            },
            {
                "id": "1df92aa5-8ae5-4f51-a0ad-a8b66af34f00",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "Back activation"
            }
        ]
    },
    {
        "id": "8d9212d8-3f0c-4435-8a32-0dea28c49d22",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "8281bf3b-f7aa-4e3c-92b4-2b4cabd64ca8",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "362caa3b-27a6-4f42-bea2-d281d7f24b2a",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "25e8297b-6437-4429-a2a8-6a9f92826f21",
                "name": "Over/Under",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "0188ecd0-f1b3-4a54-bc5a-257940b50be3",
                "name": "HS Walk",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "80ce22d6-9411-4348-958c-de63209a510e",
                "name": "Bear Crawl",
                "sequence": 5,
                "notes": "5 - Core/coordination"
            },
            {
                "id": "4b58d31f-b88a-41ef-8220-284a2bcd8cfb",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "04e83216-5c9f-4b07-bcd1-de84a0523a90",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "8ddce332-61ce-4bbb-a85e-625a77ad351f",
                "name": "Turkish Get Up (TGU)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: SL Rotation between sets"
            },
            {
                "id": "39337e64-4c4c-44d4-939c-20847440ea17",
                "name": "Single Leg Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "78b8452c-05cb-4d4e-bb52-8d01166ed6f1",
        "name": "Conditioning - Core Chipper",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "4908848e-f011-404a-ae3b-53064b314374",
                "name": "TGU",
                "sequence": 1,
                "prescribed_reps": "5e"
            },
            {
                "id": "98efcc31-86de-4794-a756-ffce90a5df75",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_reps": "20"
            },
            {
                "id": "68aeb189-b2cc-4fd2-a8e4-aaf84b96cdf5",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "15e"
            },
            {
                "id": "64652e5d-2577-467a-ab32-6ea43dae5d44",
                "name": "SL Bridge",
                "sequence": 4,
                "prescribed_reps": "20e"
            },
            {
                "id": "60600c8e-0ee4-4a98-969d-131148290367",
                "name": "Air Squat",
                "sequence": 5,
                "prescribed_reps": "100"
            },
            {
                "id": "5fb2a5e7-b8e5-4529-b5aa-bf1e04c548b6",
                "name": "Shoulder Tap",
                "sequence": 6,
                "prescribed_reps": "20e"
            },
            {
                "id": "69b72e5d-67fd-4468-9d42-a4d3ffe774af",
                "name": "Back Lunge",
                "sequence": 7,
                "prescribed_reps": "15e"
            },
            {
                "id": "c6b4e173-747c-447f-842d-62e49bcc9ee8",
                "name": "Sit Ups",
                "sequence": 8,
                "prescribed_reps": "20"
            },
            {
                "id": "06be13f9-d27a-427f-bd7f-9c326d7641ae",
                "name": "Push Ups",
                "sequence": 9,
                "prescribed_reps": "10"
            },
            {
                "id": "4efc5277-b91f-4501-ae82-23cd9d32a1c2",
                "name": "Wall Sit",
                "sequence": 10,
                "prescribed_reps": "60 sec"
            },
            {
                "id": "71b57194-fee4-4a36-b224-f088f8142639",
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
        "id": "237216de-4667-4d29-b83d-cfeccbc92e63",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "a5711b29-e20d-444b-ba2c-df26aec3aad4",
                "name": "Push Ups",
                "sequence": 1,
                "notes": "Upper body activation"
            },
            {
                "id": "10d61054-df44-4f23-93d0-70ea66573b80",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "Lower body prep"
            },
            {
                "id": "7c3ee227-db99-43d0-ae38-5e5540a06d38",
                "name": "Side Plank",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "dd84866b-1aa2-4214-8696-b364a604e106",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "263fbe3f-8867-45a9-ad4f-38a5fb9b4ef0",
                "name": "Lunge + Rotate",
                "sequence": 1,
                "notes": "T-spine mobility"
            },
            {
                "id": "b52fcd59-6287-4efb-aba2-91efdc018d61",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "4f6cb1d7-804c-4a66-9871-76e7a9b17e47",
                "name": "High Knee Skip",
                "sequence": 3,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "ba074291-4efb-4466-a0a7-e058105df8f2",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "47d80b69-801b-485e-8376-aefd293d5ca0",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "0ede317f-e386-4586-9bc2-01f5623b0a75",
                "name": "Glute Bridges",
                "sequence": 6,
                "notes": "30 - Glute activation"
            }
        ]
    },
    {
        "id": "b0d6107e-08bb-4acb-b61e-3f2e365feda0",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "3ceb59f0-ee05-450b-9fcf-d1febab8a25b",
                "name": "KB Front Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "1781822c-87fb-4138-a2b1-e2e462480a9d",
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
        "id": "65968710-edc8-4d16-99a4-25400ce57e82",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "0c505d70-165a-440d-94a6-6eb8c24c1420",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "638d9ef5-60f3-45e1-9d81-f775e1cf1690",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "29e9a8c3-86d9-4325-9ace-7897a5755b11",
                "name": "Plank",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "ef8e73d3-3277-4515-b5c9-9f84f3e17797",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "bdaf9b71-23ff-492d-b2bb-5d558cc3e793",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "56c03b0b-3d01-475c-97b1-fd1ce941bb10",
                "name": "Hi Touch/Lo Touch",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "3fe16650-0aa0-4950-84dc-6f2ce41fdb70",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "c233aa0b-9a03-49a1-bab1-bf1897c3e4cd",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "6f852c05-cd7c-4ed7-adf8-1b2a8c15487f",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "ce4db06a-8a96-4c7f-904e-46d86d4fb0f3",
                "name": "Pigeon/Piriformis",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "f976759a-8da5-4ea1-98e4-857479da15c2",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "60527508-e7fc-4b9d-8d71-aff97e93f355",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "ea49c8c9-b60a-4330-807b-486faf6e2413",
                "name": "3-Way Lunge",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "003e5423-2371-4cee-b92f-ca1c4cacecdd",
        "name": "Conditioning - 20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "05152226-cd0a-4c38-a68c-b37f17b2a471",
                "name": "Split Squat",
                "sequence": 1,
                "prescribed_reps": "8e"
            },
            {
                "id": "29b5e75b-07b2-44e0-8361-f1dcda1b467b",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "10e"
            },
            {
                "id": "f23f8446-11dc-4f84-9299-e1df23d552fe",
                "name": "Renegade Row",
                "sequence": 3,
                "prescribed_reps": "8e"
            },
            {
                "id": "3512f77c-0643-435b-90db-69b3bbfa06e9",
                "name": "Slamballs",
                "sequence": 4,
                "prescribed_reps": "10"
            },
            {
                "id": "4774a779-be56-4b17-b373-2bf15093323f",
                "name": "Cal Row",
                "sequence": 5,
                "prescribed_reps": "10"
            }
        ]
    },
    {
        "id": "1957a320-83e8-4951-b7ff-414c65aa9007",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "c5c8156d-b239-43f6-9781-21556d0623ce",
                "name": "Battle Ropes",
                "sequence": 1,
                "prescribed_reps": "30 sec on/30 sec off x 3",
                "notes": "Max effort"
            },
            {
                "id": "53ab5ff3-315a-4ca2-9c35-79254b811624",
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
        "id": "64639a45-f440-47ce-b2bf-c676330bfc2e",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "da87f4ce-5fc1-4eea-a0eb-edc97379a816",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "20a8b726-2e61-4581-bc59-4b242d439342",
                "name": "Jumping Jacks",
                "sequence": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "bcfa898c-ff58-4769-82dc-c3d1d26563d9",
                "name": "Snow Angels",
                "sequence": 3,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "52f59c11-e1cb-4657-b2a7-dfa6b089b1b4",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "c1768a46-db55-4ae3-96f3-a70c02e4539a",
                "name": "Piriformis",
                "sequence": 1,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "7e7284ff-44a7-4032-97b4-b3d14cb54e7f",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "79dfbfe8-66bd-41b1-ad67-a103daabfe14",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "0929214a-d7e8-4a45-a0ac-4f40a1e5990d",
                "name": "Side Lunges",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "6d15773a-c7ed-4fc2-a9d3-87691edf9057",
                "name": "Over/Under Fence",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "f8b14d4b-cba7-4213-8abb-d4517acd5d32",
                "name": "Push Ups",
                "sequence": 6,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "94017722-bd19-4b1d-951a-462554871597",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "6e9ceaba-5702-4a25-b561-51f6300426fa",
                "name": "DB Bench Press (Heavy)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "6",
                "notes": "Set 1: Heavy (RPE 6). Set 2: Heavy (RPE 7). Set 3: Heavy+ (RPE 8). Set 4: Heavy+ (RPE 8). Rest: 2 min between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "4e91f1ea-e765-4aee-a443-2a6c641ec91d",
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
        "id": "7ebc579d-1322-4c64-9ce7-f4da7958a801",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "6af8449a-ca19-4826-ae2e-e440302b65c9",
                "name": "Push Ups",
                "sequence": 1,
                "notes": "Upper body activation"
            },
            {
                "id": "d9e4d8f8-3e47-40f8-811e-d5f9d7e21931",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "Lower body prep"
            },
            {
                "id": "79554907-8519-4710-a2e9-1fc8643f8bae",
                "name": "Jumping Jacks",
                "sequence": 3,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "9689d3bb-e65e-4576-85f8-7febc5220cec",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "1ae85c2a-f1a8-4ef3-8213-6948db77cf04",
                "name": "PVC Passovers",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "5a23ad68-30d0-4228-b5d9-6630730f0d69",
                "name": "PVC Good Mornings",
                "sequence": 2,
                "notes": "Hip hinge prep"
            },
            {
                "id": "db89238f-70a9-4a74-b3d0-d475767f22ef",
                "name": "Side Lunges",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "8309aa3b-57bb-47af-b957-d045465cbde7",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "209a37d2-c769-4a6f-9545-e9940fc64c6b",
                "name": "High Knee Pulls",
                "sequence": 5,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "5e3d3973-287a-4de9-bb62-7881bdf29e8b",
                "name": "Over/Under Fence",
                "sequence": 6,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "92744f49-03c2-4532-a1c6-b1247ec561d8",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "ca5a8a71-0765-48c9-ae4f-f1ab4056e390",
                "name": "MB Clean Progressions",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: T-Spine on Roller between sets"
            },
            {
                "id": "63cbc28c-9974-4a1b-bdb1-cd1760afc2dc",
                "name": "Side Plank",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": "Set 1:  (RPE 6). Set 2:  (RPE 6). Set 3:  (RPE 7)"
            }
        ]
    },
    {
        "id": "9ea4fabf-f4a9-412d-b009-8c7a93bfab22",
        "name": "Conditioning - 20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "df4b5d08-76be-465f-a468-73de87478e21",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "30 cal"
            },
            {
                "id": "eef2961b-bade-4e85-8c9f-5b493d2470e1",
                "name": "HKTC",
                "sequence": 2,
                "prescribed_reps": "30"
            },
            {
                "id": "ad99cd25-bc3d-4857-9632-ef1bf1cb08f3",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_reps": "30"
            },
            {
                "id": "cf879d3f-9c9f-4e42-9ea8-4cfce6358d22",
                "name": "Bike/Row",
                "sequence": 4,
                "prescribed_reps": "30 cal"
            },
            {
                "id": "c5475cd6-b81e-4c3d-bf3f-36559d58464b",
                "name": "KB Swings",
                "sequence": 5,
                "prescribed_reps": "30"
            },
            {
                "id": "1133e2fd-bf90-480f-928b-3811afbea825",
                "name": "Shoulder Taps",
                "sequence": 6,
                "prescribed_reps": "30e"
            },
            {
                "id": "192db5b4-10fa-4448-aeff-1fa6bce60c7f",
                "name": "Bike/Row",
                "sequence": 7,
                "prescribed_reps": "30 cal"
            },
            {
                "id": "682f6b76-b55e-4bc3-bee0-b59dc4b81e74",
                "name": "Box Jump/Step Ups",
                "sequence": 8,
                "prescribed_reps": "30"
            },
            {
                "id": "7e0fea4b-a1e2-43c6-8487-5b26dbc15673",
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
        "id": "d86a4ce7-62ea-444b-8ac0-16987c3dbece",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "a9e8c237-cad5-41a1-8889-6ef776940fa9",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "12570a00-74aa-4744-bbe1-6684134afd5a",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "f649b90e-1bd6-406a-a3f7-caf34d4a3dda",
                "name": "Dead Bugs",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "fd69f1a1-5f2d-4a94-baae-55d7000dcaac",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "47c27d3c-54b2-4d5f-b57f-c3cb803db41f",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "f0666c64-436f-4fc7-ad57-27807945f14e",
                "name": "Lunge + Reach",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "b91901be-615c-4dd3-9931-71c1eb0aefdb",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "b531ee4d-dd66-4339-88a4-7151e5f48bab",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "ef52dff7-fcd4-4e3d-b988-f4adbbbf2339",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "24e668f5-489e-45fb-ad47-fb0d40a8b343",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "881fa728-5918-42d3-a78e-dc928a519d72",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "d4787e6e-0e93-450b-83f8-179db978f6dc",
                "name": "Walking Lunges",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "ed76bbf5-5ebb-4651-8b41-f6bd7ec4e2f3",
                "name": "\u00bd Kneel SA Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: PVC Passovers between sets"
            }
        ]
    },
    {
        "id": "e5ca11c0-7da7-4460-9470-c98fe321b4a7",
        "name": "Core Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "775cc244-53a6-4de2-96c3-90d0e4139b40",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "230aa374-0321-4563-bb47-6dabce707c12",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "506e7e3e-b430-4137-be97-d1e72188cd1f",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_reps": "10"
            },
            {
                "id": "5185f669-c84a-4b04-816e-f260a744cae3",
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
        "id": "bdf72e85-5a35-4207-a42d-588a6b9636ab",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "db461631-86f7-4c05-ad9d-a39951a2a7db",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Band at ankles"
            },
            {
                "id": "c874bfca-1a1f-45a6-8604-0f2ece8c756f",
                "name": "Banded Squats",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "85d17f2e-cbca-460d-9672-09611c98c4eb",
                "name": "Banded Bridge",
                "sequence": 3,
                "notes": "Glute/hip activation"
            }
        ]
    },
    {
        "id": "e7e20c21-3c33-4af0-ace1-2406bce1e89d",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "34755cce-1b41-4e42-b2ef-9305dbc16eda",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "1f3ee16b-5075-477f-b850-d33296c72dce",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "71dd8cd1-bceb-4282-a421-ea623b457652",
                "name": "Over/Under",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "0808a6a8-9261-4b73-ab55-1ae948b8b21a",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "2e141b1b-76f2-4cd0-98d9-5615d1caa9ec",
                "name": "ATW",
                "sequence": 5,
                "notes": "Around the world - shoulder"
            },
            {
                "id": "a3d8f007-5136-4414-b84d-8165b021a19b",
                "name": "Bear Crawl",
                "sequence": 6,
                "notes": "5 - Core/coordination"
            }
        ]
    },
    {
        "id": "5ebdaece-560a-4a11-9308-fd14b45b80a3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "513c6d5b-944e-4b6e-8e12-598d9fb2dc62",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "1c4ab0bc-e90c-498a-90ed-4040d8bfb035",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "1de5c31c-ae25-4d02-b5e4-17ff7bfa7367",
        "name": "Conditioning - Chipper",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "c4f320ad-0d60-4194-aad8-2e2344102c23",
                "name": "KB Swing",
                "sequence": 1,
                "prescribed_reps": "50"
            },
            {
                "id": "2ef93db9-84fe-473e-aa5a-70e9ec4eab11",
                "name": "Shoulder Tap",
                "sequence": 2,
                "prescribed_reps": "40"
            },
            {
                "id": "4058899d-3f81-417e-8fcb-b1b749650722",
                "name": "Goblet Squat",
                "sequence": 3,
                "prescribed_reps": "30"
            },
            {
                "id": "eaaeffe4-40e1-4cf2-9f23-7537cb83b72e",
                "name": "Starfish",
                "sequence": 4,
                "prescribed_reps": "20"
            },
            {
                "id": "ab4f173c-217b-4274-8b58-3dd12502c204",
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
        "id": "337a5dd7-b7a1-4642-b68e-7807d68ae04c",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "ba69d74f-7c37-4536-9dae-991e6a441de2",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Mobility assessment"
            },
            {
                "id": "383b2b63-e51c-4602-8fc0-710e59cca379",
                "name": "Jump Rope",
                "sequence": 2,
                "notes": "Cardio warm-up"
            }
        ]
    },
    {
        "id": "5fa44ecc-1b9a-40f5-9767-b4d82254ddae",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "8e4c2612-f64f-4347-9af9-c3bbc9ccc097",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "0fa3935c-fd5b-4730-9903-e53168a4873a",
                "name": "Over/Under Fence",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "c90f4c5a-3adf-436b-8ce8-3f04da98a51c",
                "name": "Spidermans",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "9d3c00f0-e886-4332-bd57-276e6898d003",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "c458753b-737d-4170-bf8d-bfa71d7deb28",
                "name": "Side Lunges",
                "sequence": 5,
                "notes": "Adductor mobility"
            },
            {
                "id": "298d2b5b-ccef-4053-b870-f11acb0d77fe",
                "name": "Quad Pulls",
                "sequence": 6,
                "notes": "Quad stretch"
            },
            {
                "id": "e29daa89-ae6b-4916-a019-4021cdc1a9c4",
                "name": "Glute Bridges",
                "sequence": 7,
                "notes": "30 - Glute activation"
            }
        ]
    },
    {
        "id": "d0fad28d-8b9b-4601-b9e1-ca8db08c0696",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "bcf4df17-c633-465c-b043-971a5f0034e1",
                "name": "Single Leg Deadlift (SL DL)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Hamstring Walks between sets"
            },
            {
                "id": "ef334ec4-2e45-4395-ba53-d73014f35d6f",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "d914abcc-aa68-4915-b225-cdb7cff97977",
        "name": "Cash Out",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "d543b58d-0aa6-4931-835d-e0df02d40925",
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
        "id": "8cf53137-274d-4cf6-932e-3935a5c490ec",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "032d34f2-991a-444f-b880-7b4278a0e10e",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Mobility assessment"
            },
            {
                "id": "b107b7c0-c74f-4df6-948e-ef9126934a36",
                "name": "Push Ups",
                "sequence": 2,
                "notes": "Upper body activation"
            },
            {
                "id": "01721caa-66ea-43f1-9cee-725baf35a8b1",
                "name": "Air Squats",
                "sequence": 3,
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "e582d2e0-9246-482f-846f-9ed1c558ecea",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "f909769f-977d-4ef0-b188-46f95e15c03c",
                "name": "Back Lunge + Twist",
                "sequence": 1,
                "notes": "T-spine mobility"
            },
            {
                "id": "0a872151-0b2f-4b99-86fc-69657bc7a499",
                "name": "Spidermans",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "7568468c-5434-40da-857a-6d6463c318cd",
                "name": "Quad Pulls",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "36ea4f84-bc92-48ec-8a5f-72114cf643c6",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "48f27d72-6b7a-486a-851b-fecba6997109",
                "name": "PVC Passovers",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "6ba5b691-08a8-4ad3-89e5-b74d082ec4d6",
                "name": "Hamstring Walks",
                "sequence": 6,
                "notes": "Hamstring activation"
            },
            {
                "id": "a1eae4e4-977b-46ff-bc2a-cc86c86b2c12",
                "name": "Walkouts",
                "sequence": 7,
                "notes": "5 - Full body prep"
            }
        ]
    },
    {
        "id": "e57aa589-53d9-4c5c-afb7-5752ae04c3cd",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "35765ed9-bd50-451c-a736-7f6a343954bb",
                "name": "Slant Bar 3 Ext.",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 8). Rest: 60 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "6ae4419f-0aa0-4008-8611-94ee9c381fa6",
                "name": "Stability Ball Hamstring Curls",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60 sec between sets"
            }
        ]
    },
    {
        "id": "3ad405b0-9efa-46da-8264-495a14459b53",
        "name": "Conditioning - 1 Round for Time",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "c62ccd2d-c465-4ffa-8c34-28cd855f6a77",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 1,
                "prescribed_reps": "500m/1000m",
                "notes": "1 rounds total"
            },
            {
                "id": "f513e129-5219-41d1-8013-f42797b6b91a",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "50",
                "notes": "1 rounds total"
            },
            {
                "id": "4be30aa1-9318-435c-bd39-20fe15f60faa",
                "name": "Air Squats",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "75",
                "notes": "1 rounds total"
            },
            {
                "id": "554e5e1f-5f00-4447-8d49-7a9442a8fb1f",
                "name": "Dead Bugs",
                "sequence": 4,
                "prescribed_sets": 1,
                "prescribed_reps": "25e",
                "notes": "1 rounds total"
            },
            {
                "id": "dde571a1-3547-4a6b-9cdc-169f0732277e",
                "name": "Row/Bike",
                "sequence": 5,
                "prescribed_sets": 1,
                "prescribed_reps": "500m/1000m",
                "notes": "1 rounds total"
            },
            {
                "id": "c53dcd00-d371-4a43-9887-9e3907745c1a",
                "name": "KB Swings",
                "sequence": 6,
                "prescribed_sets": 1,
                "prescribed_reps": "50",
                "notes": "1 rounds total"
            },
            {
                "id": "d7a0522c-fa66-492d-a1d3-ab5c6dbe8137",
                "name": "Mtn Climbers",
                "sequence": 7,
                "prescribed_sets": 1,
                "prescribed_reps": "50e",
                "notes": "1 rounds total"
            },
            {
                "id": "f94b4f5d-4277-4134-ab2f-94c43b86bf69",
                "name": "MB Toe Taps",
                "sequence": 8,
                "prescribed_sets": 1,
                "prescribed_reps": "25",
                "notes": "1 rounds total"
            },
            {
                "id": "75b4d867-5ff6-4e6f-88ea-3ceda5d05868",
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
        "id": "272bee31-feb5-4079-8573-ba9ff0a83937",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "94449d0d-1edd-4b31-9314-74f6d6eec556",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Band at ankles"
            },
            {
                "id": "eef9dbc1-8249-4b00-bc54-e1df7c527064",
                "name": "Banded Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "aec9b2a8-44e1-4675-abb7-c50f73f99fdf",
                "name": "Banded Squat",
                "sequence": 3,
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "4e1a2ac7-d8b3-4a26-b629-49a991507d3d",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "65917cf2-542c-468b-a4d2-9e36223b57aa",
                "name": "High Knee/Quad Pull",
                "sequence": 1,
                "notes": "Hip flexor/quad prep"
            },
            {
                "id": "4891d908-cee1-4382-ae06-ad4e62bc9d37",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "7b1e762b-9a55-4bad-82a8-25b6e9333ba0",
                "name": "Over/Under",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "a554634c-4df4-4651-aa58-bed2c1d2dd03",
                "name": "Lunge + Reach",
                "sequence": 4,
                "notes": "T-spine mobility"
            },
            {
                "id": "d52e03c3-4abb-4cca-9c1f-708c81b3067b",
                "name": "Bear Crawl",
                "sequence": 5,
                "notes": "5 - Core/coordination"
            },
            {
                "id": "3c92bb5a-ba35-493c-b982-7285bdc088c3",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "ded8ecf7-d7b4-456f-9e75-8a469cafe21c",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "5116c916-7ebf-4816-ad84-17598cadd886",
                "name": "Slant Bar 3 Ext.",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Pigeon stretch between sets"
            },
            {
                "id": "ac598b79-f1df-4663-a991-00097c2a18ca",
                "name": "Renegade Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Bi/Lat Stretch between sets"
            },
            {
                "id": "e1730bb8-820c-4ef0-9871-f87f3a608942",
                "name": "Slant Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "067c051a-c0ad-46eb-8c5a-650283dec328",
                "name": "Step Ups",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "60514913-aad6-47e2-b5bf-dca41b1de670",
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
        "id": "6fc38419-18b9-4ca1-b3fc-4186e7db0af1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "0327cff9-e9e7-4e25-b5da-c9c2e0813a54",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Mobility assessment"
            },
            {
                "id": "f48f801c-eb49-4a11-be3a-4a1c346674ed",
                "name": "Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "150cb374-57cd-4213-81e8-b7fb4db0c3fa",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "e1c2799f-d3f6-4b83-8856-9a94110be6fe",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "78f9b447-3cc0-4400-a593-82702b02c60a",
                "name": "Lunge + Rotate",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "f7ec10f8-4815-43eb-acf9-3b9b9750a323",
                "name": "Hamstring Walks",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "c3df4c45-26d3-4859-a20f-941296e3ee88",
                "name": "PVC Good Mornings",
                "sequence": 4,
                "notes": "Hip hinge prep"
            },
            {
                "id": "5bf1eb6c-c84c-4a4b-aaa1-a8831f235d9d",
                "name": "PVC Figure 8''s",
                "sequence": 5,
                "notes": "T-spine/shoulder"
            },
            {
                "id": "b0fef7de-6923-46f9-be51-d3de03ed2f1c",
                "name": "Spidermans",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "d62888fd-1644-440d-ada9-91575b180db4",
                "name": "Butt Kicks",
                "sequence": 7,
                "notes": "Quad activation"
            },
            {
                "id": "0cbeee48-b910-4701-a5b5-291f69a3852f",
                "name": "Push Ups",
                "sequence": 8,
                "notes": "10 - Upper body activation"
            }
        ]
    },
    {
        "id": "b28a37cb-ba7a-418e-bf28-82eab37525cd",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "e30de738-f9f0-49ba-a4e4-1c06de997313",
                "name": "Deadlifts",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90-120 sec between sets Accessory: TTP (Touch the Post) between sets"
            },
            {
                "id": "1b7faf54-87ed-4f4c-b248-b6117d3129ef",
                "name": "SA Bent Over Row (BOR)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "e31ca5cd-f21f-4940-ac5a-734ee57e14de",
        "name": "Conditioning - 20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "c5edc926-b045-4f66-a605-366fecbcdf31",
                "name": "MB Slams",
                "sequence": 1,
                "prescribed_reps": "12"
            },
            {
                "id": "fbbe59d0-bdfb-401b-b4f3-18566354475e",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "10295303-446c-4dc7-896f-d1383cdcfbde",
                "name": "V Ups",
                "sequence": 3,
                "prescribed_reps": "12"
            },
            {
                "id": "b942547a-d0e1-4f68-9301-fc9b380c8427",
                "name": "Side Lunges",
                "sequence": 4,
                "prescribed_reps": "6e"
            },
            {
                "id": "ddd600c7-14b3-4e53-b908-ea8cac2c78dc",
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
        "id": "0d431193-bd97-49ae-87c5-90edfeaf1c42",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "6d191c94-c18d-4a0e-ae22-40e083d54ce2",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Mobility assessment"
            },
            {
                "id": "59354438-199b-48e6-bfa2-5b6de572254a",
                "name": "Sit Ups",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "cdcc83b2-ee73-49bb-91d3-831f472758d9",
                "name": "Air Squats",
                "sequence": 3,
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "7e2818ae-7233-405d-a2c0-a1df406bb2e6",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "a56eebb7-1b5a-4ce9-bced-15fe3e678327",
                "name": "High Knee Pulls",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "0e502d31-c1d1-4103-8337-a74eac1e2e00",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "a0882091-18f8-4005-ba2c-4fec1b4cc48c",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "877aa3d8-52f9-474d-89a7-48a84768f940",
                "name": "Side Lunges",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "aaad0999-8083-451b-a9f2-25b83c36b1a7",
                "name": "PVC Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge prep"
            },
            {
                "id": "99fb80f8-93b3-4d12-9c5e-f581f619d10b",
                "name": "Piriformis",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "4569ea7d-8f01-4bc7-ab9a-01507299d2fe",
                "name": "Spidermans",
                "sequence": 7,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "faccf5f6-c159-4aee-8839-5b8a53eef882",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "af6414d7-b2a6-4f2a-b252-169aa48897d6",
                "name": "Deadlifts (Building)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Light+ (RPE 5). Set 3: Moderate (RPE 6). Set 4: Moderate+ (RPE 7). Set 5: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: TTP (Touch the Post) between sets"
            },
            {
                "id": "42fc5c50-0754-40b7-8f54-010aa81744f0",
                "name": "Renegade Rows",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "5b0f4e91-a9d6-4147-a077-cb5bd5c82264",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "7784973a-2e29-468f-a718-535bbdefcec1",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "12 cal"
            },
            {
                "id": "23d45b8c-37be-4aff-8324-9b3983f3c174",
                "name": "Russian Twists",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "92d12931-156a-4c6b-bc8e-2c67d80f559d",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_reps": "12"
            },
            {
                "id": "ec9af89d-f5ac-451b-b432-7ae3ba238d01",
                "name": "Push Press",
                "sequence": 4,
                "prescribed_reps": "12"
            },
            {
                "id": "20e0ae8e-0d71-4ed7-b8ea-98eddd6b7969",
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
        "id": "eeb6f70b-1713-4981-af66-da3c7f2b551c",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "e36b65d5-2ada-443b-8b34-3b9256fdd012",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded or SL variation"
            },
            {
                "id": "910a2466-b517-4cb4-804f-c7959ead3d02",
                "name": "Dead Bugs",
                "sequence": 2,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "e985c1ae-c2b8-43de-83b0-37f323e75098",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "76cd5391-e470-4d3d-bebe-0847489a73e0",
                "name": "High Knee Pull + Reach",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "67cdc5cd-8f6f-4d35-85b4-5c3abf3b97b6",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "bcadba7c-ed52-4ead-88a1-4c371bcd74b9",
                "name": "Lunge + Reach",
                "sequence": 3,
                "notes": "T-spine mobility"
            },
            {
                "id": "c0d0566a-c62d-466f-b0f3-dc6e51dc2ab7",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "de0d1618-84a8-4e18-8a86-61e8cc96de2b",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "d9beb6aa-b216-43ee-a08c-aae516ecf6c1",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "10 - Hip hinge prep"
            }
        ]
    },
    {
        "id": "9e547ced-4d73-4b29-a5fb-095cd824883d",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "33f87a9f-1280-40ea-bc8d-655a10da8c20",
                "name": "Single Leg Deadlift (SL DL)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walks between sets"
            },
            {
                "id": "b610f810-9cb0-44c6-a535-00bc19ef30b1",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "a11f8b0d-e9b1-4fe5-9448-dac6aee04a47",
        "name": "Core - 5 Rounds",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "ec280bbd-96c3-4af3-b444-1280c752008d",
                "name": "Front Squat",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10"
            },
            {
                "id": "5bf4c20e-5e5a-42bf-a250-14bc5706d32f",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "10"
            },
            {
                "id": "c1e07f5c-3758-4702-8dca-1eb5a534101b",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "10e"
            },
            {
                "id": "28dd7a37-b128-4e77-8c65-27231ce8cb0b",
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
        "id": "6722e917-9eed-4312-83bd-7f0938b2eebe",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "dfa725f3-e07f-4153-b5b1-5ffaf91e3a42",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Mobility assessment"
            },
            {
                "id": "e0187855-a6e7-4810-be25-34726eeb453b",
                "name": "Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "aa9cea72-4ff7-4e44-a053-542e07dc0d30",
                "name": "Supermans",
                "sequence": 3,
                "notes": "Back activation"
            }
        ]
    },
    {
        "id": "9cc57fd3-59cc-4ad2-a11a-4724da662e19",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "bbf9cf40-5c4b-4322-82ac-2dedb4df9238",
                "name": "PVC Passovers",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "6a383d83-fff7-47a6-b6f1-de8db6e10149",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "f64d8831-b36b-4448-be19-729d0774d167",
                "name": "Hamstring Walks",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "d66875b9-ea07-4f10-826b-202ad9711dec",
                "name": "Lunge + Twist",
                "sequence": 4,
                "notes": "T-spine mobility"
            },
            {
                "id": "3c683e5a-6d22-448b-a586-6fac2519af71",
                "name": "Over/Under Fence",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "6058c027-4fd9-40e1-91f0-6e74c83fcd18",
                "name": "Karaoke",
                "sequence": 6,
                "notes": "Hip/coordination"
            },
            {
                "id": "40dad6b4-4de4-4bff-b9ea-caba386cf912",
                "name": "Air Squats",
                "sequence": 7,
                "notes": "20 - Lower body prep"
            }
        ]
    },
    {
        "id": "b002487a-f898-4611-96cd-cb899cf294c3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "1a800732-42f2-4448-b94b-a4ae79f42782",
                "name": "MB Clean Progressions",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: T-Spine on Roller between sets"
            },
            {
                "id": "5321df96-658d-4b74-909a-bf55248cbd10",
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
        "id": "acc43c32-aef4-492a-8cd8-cf0913fe2c31",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "003d689c-6a6c-461a-9a47-da72d67f61a7",
                "name": "SA Row",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "955969c7-1493-44c2-ad90-8ac98901a8d0",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: RRL between sets"
            }
        ]
    },
    {
        "id": "c3de70c4-5028-4713-89fb-ea067e43ec7c",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 2,
        "exercises": [
            {
                "id": "86072706-7182-4204-94a0-32d407d8444c",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m"
            },
            {
                "id": "3d0f205d-e88d-4a7e-923f-8642515b9b46",
                "name": "KB Swing",
                "sequence": 2,
                "prescribed_reps": "15"
            },
            {
                "id": "10a70f7b-d538-4c60-931a-b294c3904135",
                "name": "BOSU Mtn Climb",
                "sequence": 3,
                "prescribed_reps": "20e"
            },
            {
                "id": "037635ba-ff07-4a50-a3d1-05017cf678ca",
                "name": "Jump Rope",
                "sequence": 4,
                "prescribed_reps": "60"
            },
            {
                "id": "a19b9b1c-093c-4819-8e5d-fab137ef69a1",
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
        "id": "cb81564f-b93b-4d97-a348-ef265f49ce80",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "cf62bb7a-c968-4cd5-bca6-f07b1649a5df",
                "name": "Bike/Row",
                "sequence": 1,
                "notes": "Easy pace"
            },
            {
                "id": "35f6b242-7b62-4551-942d-24f3ee14eca4",
                "name": "Monsters",
                "sequence": 2,
                "notes": "Band at ankles"
            }
        ]
    },
    {
        "id": "aa61d3c4-6e78-4145-b493-1e43e1ca00c9",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "3b48c570-8291-4ec2-9d41-61be6d24e047",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "d2cd57af-8649-4f38-ba6a-4a51d3f14643",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "c25e38de-1571-42ec-8ec3-1ab9f2015195",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "f4d419ec-651f-4781-9f55-10a038e951d2",
                "name": "Piriformis",
                "sequence": 4,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "e235db95-9ed3-4db6-ab9a-853ac5510311",
                "name": "Push-Up Walkout",
                "sequence": 5,
                "notes": "Full body activation"
            },
            {
                "id": "786d6acc-a51d-4e49-b954-4009cfe8a7c1",
                "name": "Spiderman",
                "sequence": 6,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "e24c4a94-903c-4e96-8e2d-0526077fa064",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "9896375d-1f88-43f5-808b-ed9033613de7",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: TTP (Touch the Post) between sets"
            },
            {
                "id": "21d4a3e9-9bd9-4aaf-90fd-559686126671",
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
        "id": "e4102b67-6ac9-49e4-a289-5e2c89e462eb",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "4a8501e1-211f-4c35-98ba-b391af9f57ee",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded or SL variation"
            },
            {
                "id": "fcd8af88-24e1-4f43-a2b4-ba163f31d05d",
                "name": "Wall Sit + Plank",
                "sequence": 2,
                "notes": "Isometric hold"
            }
        ]
    },
    {
        "id": "b7cf417e-45e4-460d-95ea-4c6521703cc3",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "eba3cc11-ca11-4354-b136-f223bb5778c9",
                "name": "HS Walk",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "346f9fc5-5008-4bf7-86f3-72bbec552fb6",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "d8d58e9c-8c96-453b-b828-1d25471fdb1d",
                "name": "Lunge + Reach",
                "sequence": 3,
                "notes": "T-spine mobility"
            },
            {
                "id": "19d6a70a-37cc-4e11-987b-8fca9560969a",
                "name": "Over/Under",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "89da76b5-2e2e-47d5-83a6-04cda2271a78",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "bd7cd53d-ad96-4e68-b2d3-d8f6a392d58a",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "2d652313-1da7-4fe7-9bb5-272541995c97",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "15037c44-d105-4d93-86d2-292bdf59eaa1",
                "name": "KB Front Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "f24472b3-8b0e-497c-92de-1690b82f8252",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "cce4a806-b653-4277-a302-78db721e2eba",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "56fa15f3-378a-4514-b846-1012606fa16b",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m"
            },
            {
                "id": "1e7c77ed-8b00-4e99-81f2-7b2f349e3da9",
                "name": "KB Swing",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "ae527b2a-529c-46f7-b400-b4aa66e1e983",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "12e"
            },
            {
                "id": "5d3576b7-361e-452e-b0ad-cb01cb1edab7",
                "name": "Burpees",
                "sequence": 4,
                "prescribed_reps": "12"
            },
            {
                "id": "bc88a384-2327-48c5-abf0-80f030bacf22",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "200m"
            },
            {
                "id": "2f474f73-c94e-455f-b687-84bd2bb1cffa",
                "name": "Slamballs",
                "sequence": 6,
                "prescribed_reps": "12"
            },
            {
                "id": "e8c5e540-d4e6-4a14-a2ee-6a4bcc940a5e",
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
        "id": "94dff54d-4ccb-4480-8041-2b9f2573b70b",
        "name": "Active - 3 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "9a16b51f-25c3-4a88-b929-ab13ecbec8de",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Glute activation"
            },
            {
                "id": "cd5dfce4-105a-491f-9129-462a3b396bb1",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Core activation"
            },
            {
                "id": "4211461f-3e63-4648-a2a5-8e243b4f0746",
                "name": "Push Ups",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Upper body activation"
            }
        ]
    },
    {
        "id": "e31a24a8-572b-41ca-99a2-f8d2aff9f1f1",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "5e3e7994-3496-4f4f-8719-af27d2a8482f",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "f0ea5ba7-8824-43c3-be3f-88ce9cae8e1f",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "1523435d-b006-4a8c-84b3-6966e6fefb51",
                "name": "Spiderman",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "200f991f-33a3-401e-b2ee-0cca7aa903c2",
                "name": "Quad Pull",
                "sequence": 4,
                "notes": "Quad stretch"
            },
            {
                "id": "e8b8fe70-2c62-420c-a9c7-38ba3c15ec22",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "89873e7a-cd3e-4ae2-8090-b563a5d82299",
                "name": "Push Up W/O",
                "sequence": 6,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "11dccce8-c045-48a8-9d9f-7e8754e74b03",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "fadeee0e-c185-4a2b-94ed-7fc7aec4ce35",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "df9b91c2-e9b8-48ea-ada2-ac1cd82b5c1e",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            }
        ]
    },
    {
        "id": "4fffff34-2a8d-4cda-b85b-6e69c3154445",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "a58f8ad8-adbf-4558-99db-151d9a05cbc1",
                "name": "OH Squat",
                "sequence": 1,
                "prescribed_reps": "10"
            },
            {
                "id": "1d221410-8fd6-42cf-8e8b-6000c2d12176",
                "name": "Med Ball Tap",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "8728c00a-482b-45ef-bc5d-93dd5d074220",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_reps": "15"
            },
            {
                "id": "34df8da0-9002-4847-a8a0-bc01ca2c15e1",
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
        "id": "977b9f4e-0c8e-4205-93bc-183b8a8f8774",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "c4290478-bfc9-4e7e-b24a-adc50202eefa",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "2546cc75-4297-4e90-9d3c-639d11db4af0",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded or SL variation"
            }
        ]
    },
    {
        "id": "647ca795-2f42-4815-9090-ff95f6f4e0ad",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "72aff1a0-2bbf-4ae5-9168-b936d55d8a87",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "79297755-87d3-4451-a37c-b4a1bf46095e",
                "name": "High Knee Pull",
                "sequence": 2,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "863bd292-1d40-4a66-ac9a-c57f74bd8fa8",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "8fe0192c-0515-4eb0-9b86-13508832117b",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "a582e861-f646-45fc-9626-e5cf6751fda3",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "e97cbd31-d727-40c7-abaf-a12a98860f39",
                "name": "Pigeon",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "ff85a5da-478c-4c68-bdcd-03ed543925f6",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "5a6475f6-c801-4bed-a0e7-e92208217104",
                "name": "Slant Bar 3 Ext.",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Pigeon stretch between sets"
            },
            {
                "id": "796239de-9652-4af6-a979-483a100d8174",
                "name": "Renegade Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "644093ca-9df5-450b-bb51-e36dc572dde5",
                "name": "Slant Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "1f6b2b3c-996b-4056-b902-5f8fba0c3cdf",
                "name": "KB RDL",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: TTP (Touch the Post) between sets"
            }
        ]
    },
    {
        "id": "d52464aa-6831-416f-92b2-fa14164a01b6",
        "name": "Conditioning - 5 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "a790c7ec-83ab-4bc0-8c2f-c952f743610e",
                "name": "TRX Row",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "15",
                "notes": "5 rounds total"
            },
            {
                "id": "34bb8ecb-0be7-429d-837d-a03cdd89388e",
                "name": "Squat",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "15",
                "notes": "5 rounds total"
            },
            {
                "id": "ecb8ef9f-cb64-437a-b3d1-d5fcfe8941e2",
                "name": "Push Ups",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "15",
                "notes": "5 rounds total"
            },
            {
                "id": "72e64ec4-fc55-4e62-9310-3ac01de764e5",
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
        "id": "744743b8-67ef-40ac-a327-3796461a2dcb",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "e2d74afb-fc99-41da-89d4-0c1f499e7ee0",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded or SL variation"
            },
            {
                "id": "1791bffa-5a41-4653-b50e-e419b0a81eba",
                "name": "Dead Bugs",
                "sequence": 2,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "9d2aacaf-fe85-405f-bebb-b6912c157c1a",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "e10103dc-46bc-4c0d-a38c-c8ceef4b3dd6",
                "name": "High Knee Pull + Reach",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "53bff937-aab0-463b-be01-db8994a71d9d",
                "name": "Push Up W/O",
                "sequence": 2,
                "notes": "Full body activation"
            },
            {
                "id": "d32eb1b0-4ecb-4f32-908c-f7424d5606fc",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "b1ac625a-1670-4e94-822b-783a2679efc6",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "09cf89f7-95f0-4ecc-8680-df68933574e3",
                "name": "Lunge + Twist",
                "sequence": 5,
                "notes": "T-spine mobility"
            },
            {
                "id": "a1c39ecb-ac3e-4c8e-aa8c-14640a947a9e",
                "name": "PVC Passover",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "dd8fece2-af8b-4a12-83e0-cee0728f1c53",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "56d38c43-069b-46dd-bf2e-73183de83536",
                "name": "Single Leg Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "d3b2a04e-8217-4116-94e2-762a7efd48ab",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "d62413be-0d3b-4f86-87a3-19451ee7cc5d",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "4ee8943f-59a9-4cc8-96e2-76981e2c8411",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "4cecabc6-4772-484d-9d7b-786eb62e40ce",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "19688e0d-2343-4342-822d-9301108a274c",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "10e"
            },
            {
                "id": "4a643ae3-a3d6-437a-920a-28a1bb937050",
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
        "id": "89ce4d16-f0b9-4824-b4e8-6354d9eaee73",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "cecfa818-a6c4-4dd3-bb75-9c0bea548c6b",
                "name": "Jump Rope",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "87f6df92-bffe-415c-8122-f067d470cb9a",
                "name": "Row",
                "sequence": 2,
                "notes": "Moderate pace"
            }
        ]
    },
    {
        "id": "6f71dd9f-18cc-489c-9e8a-41c308f4a6d1",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "55ccb541-6d59-4010-ba2d-f393676a51dd",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "152b261d-91f0-499e-a32a-4f878fcedb1e",
                "name": "Spiderman",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "e3e55741-fa31-464e-be35-f9ef4847cdde",
                "name": "Hi Touch/Lo Touch",
                "sequence": 3,
                "notes": "Dynamic stretch"
            },
            {
                "id": "6341e314-613e-4797-8718-9c7cbb34e3d8",
                "name": "Over/Under",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "3f3a617e-4179-4d2f-9c14-7f8ad7f6fb9c",
                "name": "Piriformis",
                "sequence": 5,
                "notes": "Glute stretch"
            },
            {
                "id": "e90d4c6a-2ee1-49a6-809e-15111a7d89cf",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "10 - Hip hinge prep"
            }
        ]
    },
    {
        "id": "c8ec6110-7738-46c8-b002-0e01bc46ad2b",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "7fcdb6cc-8636-45da-8c21-a501e5a63857",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded/SL (RPE 5). Set 2: Banded/SL (RPE 6). Set 3: Banded/SL (RPE 6). Rest: 45 sec between sets"
            },
            {
                "id": "f50ea719-2a41-4951-8e43-67c25a163a71",
                "name": "Split Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "837e7fa0-7a41-48ec-a5ae-db98ac2687f9",
                "name": "Good Mornings",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "259631f2-a9b8-454b-856c-ab1fb92cb40c",
        "name": "Conditioning - EMOM 12''",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "3fc929a2-42da-49f7-ac39-327a94ac6678",
                "name": "Push Press",
                "sequence": 1,
                "prescribed_reps": "8e"
            },
            {
                "id": "e21c8f4f-b341-42f7-96ab-3311323d9cd9",
                "name": "Med Ball Tap",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "f4418798-66c8-4751-91e1-603779f313fe",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "10e"
            },
            {
                "id": "bcadf8b7-96cc-468c-bdcb-bfadadebed16",
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
        "id": "49044131-fd25-4acf-b440-9010fc919fd5",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "ec489a18-87ef-464f-9878-bb73d3437794",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Movement assessment"
            },
            {
                "id": "b5718e6d-9edf-48cc-9a03-815fc184e194",
                "name": "Hurdle Step",
                "sequence": 2,
                "notes": "Hip mobility test"
            },
            {
                "id": "1869fc07-fa17-4c7f-9ce8-93f3215e9926",
                "name": "Monster Walks",
                "sequence": 3,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "61be604b-cf4f-4a9c-b07e-bab7b412f2f6",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "d2da123d-ff3c-4799-a3f3-b51b1126a162",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "0d126a50-4fb0-488d-9bc5-f8370159943c",
                "name": "Piriformis",
                "sequence": 2,
                "notes": "Glute stretch"
            },
            {
                "id": "073831ae-7025-4d87-8474-b4d27c1b00fa",
                "name": "Side Lunges",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "e2cf6a29-db03-42c7-880a-0041803a2ce3",
                "name": "Quad Pulls",
                "sequence": 4,
                "notes": "Quad stretch"
            },
            {
                "id": "936a37ff-04fb-469c-aeeb-705a0d516ad4",
                "name": "PVC Passovers",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "f1fae448-e848-40a7-b299-3f2ffdbba9f3",
                "name": "Inchworms",
                "sequence": 6,
                "notes": "Full body activation"
            },
            {
                "id": "5e94c416-2065-4185-b8d0-4395b672cac6",
                "name": "Air Squats",
                "sequence": 7,
                "notes": "10 - Lower body prep"
            },
            {
                "id": "8f4ebb63-5e52-4859-ae45-eeded65f86b2",
                "name": "Push Ups",
                "sequence": 8,
                "notes": "10 - Upper body prep"
            }
        ]
    },
    {
        "id": "38545436-b96c-47a3-8767-7076ce075592",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "32435c5f-fa67-446b-97ad-bd620b76dcc1",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "06efa6f9-2fac-47ee-bde0-8929c56c9562",
                "name": "SA DB Bench Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Chest Openers between sets"
            }
        ]
    },
    {
        "id": "c4f9f9ab-ff93-4eb3-8e31-b32a3bee7ad1",
        "name": "Conditioning - 15-20 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "8101c3f9-1b3e-47d3-a8bb-39f978750c94",
                "name": "HKTC",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "03d518c1-e592-4e36-9490-48a5f3d95e9c",
                "name": "KB Swings",
                "sequence": 2,
                "prescribed_reps": "15"
            },
            {
                "id": "65371320-0c50-4bb0-9aca-f4d1b89def2b",
                "name": "Goblet Squats",
                "sequence": 3,
                "prescribed_reps": "15"
            },
            {
                "id": "3fedd466-f6d7-4e0f-bd52-d0c8669869ca",
                "name": "SA BOR (KB)",
                "sequence": 4,
                "prescribed_reps": "10e"
            },
            {
                "id": "52c25daa-79a7-4874-afb7-07a10abdc496",
                "name": "Russian Twist",
                "sequence": 5,
                "prescribed_reps": "15e"
            },
            {
                "id": "8f121a59-afde-4685-8ac6-0002f6b657f2",
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
        "id": "e3888958-a569-49fa-8986-16b68324896e",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "ca3077c1-0db6-4be5-ab06-a428371591d2",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "0af81537-9c2a-4b48-86a8-c88fe0facef2",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "1511f02b-fcd2-4d4f-baf3-630767ef4093",
                "name": "Shoulder Tap",
                "sequence": 3,
                "notes": "Core/shoulder stability"
            }
        ]
    },
    {
        "id": "40659716-fd1f-484d-8e52-3649f61e6096",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "3136be77-ae2a-4967-97b6-30b98aa7682a",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "331c80da-087e-44cd-ae82-65e02ed5ec5c",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "cb54b151-946c-4c8c-b1d6-eeb8b66cbce6",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "9fa782d3-3121-41fc-b250-b513bfbe9594",
                "name": "Push Up W/O",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "05c30f8a-655e-407d-9205-e7c21f6e6923",
                "name": "Pigeon",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "c4b78392-059a-4327-a4bd-ed455b57d459",
                "name": "RRL",
                "sequence": 6,
                "notes": "Rotation mobility"
            }
        ]
    },
    {
        "id": "0630fd98-4e9f-4202-8275-60c2d579c934",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "8b9e3f58-5056-46e6-b361-a1f1aa0f59ec",
                "name": "Walking Lunges",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "c365e896-6fac-404b-b9c1-1d3cad94cdd0",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "Max",
                "notes": "Set 1: Bodyweight (RPE 8). Set 2: T-Push Ups (RPE 7). Rest: 90 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "079d8795-4280-4526-adf5-de55e812b1d2",
        "name": "Conditioning - Chipper",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "1662a844-21bf-4ed6-a23f-01ad9ab4ea26",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "40"
            },
            {
                "id": "0494f33e-0504-4e0a-9cc3-8b51fee8a6e9",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_reps": "40"
            },
            {
                "id": "bfd3b1ce-0756-4e7b-b4ab-e1fb262aed48",
                "name": "KB Swings",
                "sequence": 3,
                "prescribed_reps": "40"
            },
            {
                "id": "ff803963-8881-44f3-bef0-2787fa43d829",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_reps": "40"
            },
            {
                "id": "4e894879-6165-4a94-979b-e3a9c8f65212",
                "name": "Renegade Row",
                "sequence": 5,
                "prescribed_reps": "40"
            },
            {
                "id": "c5282077-3882-46b3-92eb-136d4d6571ad",
                "name": "Burpees",
                "sequence": 6,
                "prescribed_reps": "40"
            },
            {
                "id": "d2275db4-f110-40ae-bfc4-bbe23ccdbca4",
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
        "id": "a457633c-a21c-4409-bf57-d5747d30e5ba",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "b3d93b3d-9ba8-4721-849e-b90ab1bf63e2",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "04f70945-8cde-424a-bc36-9a639f7bb16c",
                "name": "TRX Row",
                "sequence": 2,
                "notes": "Back activation"
            },
            {
                "id": "ee0e55c8-5757-4956-add7-098687d7fc74",
                "name": "Plank",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "d6c3abff-f0c3-4636-aa13-ecb1cfa409e1",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "486128f7-8296-48d7-baa5-4a330c193c8f",
                "name": "Hi Touch/Lo Touch",
                "sequence": 1,
                "notes": "Dynamic stretch"
            },
            {
                "id": "00d4fccc-2834-46a3-9084-60b32c941db8",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "5b544e3d-9d15-4b95-9845-e2f379be0d49",
                "name": "Spiderman",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "3fea58f8-4560-47bd-b13e-64495a1b25c1",
                "name": "Bear Crawl",
                "sequence": 4,
                "notes": "5 - Full body activation"
            },
            {
                "id": "7c87f237-6131-4967-a2b8-da095992896b",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "2860c99b-62dc-42fd-87b7-013ac2fcf561",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "479ab23f-24b3-48db-bee5-aaf2aa26b19f",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "448a9347-8f9d-422d-9523-a9eb4ac0a4b0",
                "name": "Chin Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Bi/Lat Stretch between sets"
            },
            {
                "id": "be6ccf29-6d48-44d6-b6cb-007e0c22d40e",
                "name": "KB RDL",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "bcb71f84-d90d-4a0e-bfd6-b2c553598c28",
        "name": "Conditioning - EMOM 10''",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "763a0191-1afb-4e6c-afd0-5ab08c893982",
                "name": "Goblet Squat",
                "sequence": 1,
                "prescribed_reps": "7"
            },
            {
                "id": "e132b62e-f92f-436d-b559-37ab53a7116d",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_reps": "7"
            },
            {
                "id": "b480952f-688c-45f2-858c-3e7dc64da5a9",
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
        "id": "fae86a7b-e075-405d-9d99-b8b52787fe74",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "320e68ad-da72-4bc4-b21d-0dc342f4e2a0",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "5d306661-1b06-4389-81ac-aeb9c263a99e",
                "name": "Jump Rope",
                "sequence": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "693d853a-1bf2-4c7c-b556-4b741e037695",
                "name": "Row",
                "sequence": 3,
                "notes": "Moderate pace"
            }
        ]
    },
    {
        "id": "65a2b527-afd4-445a-a93c-de82d76f8270",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "efa8c471-4d58-4f8b-a97c-4f76aa052fdb",
                "name": "High Knee/Quad Pull",
                "sequence": 1,
                "notes": "Hip flexor/quad prep"
            },
            {
                "id": "fcc5e4ed-cc66-4e97-bd83-95957ff5f8e4",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "09adbb2b-f09d-4ce1-8dc1-c9fb1a77d649",
                "name": "Hip Openers",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "c89bb361-458c-4f15-8c4d-d8525957d1fd",
                "name": "SL Rotation",
                "sequence": 4,
                "notes": "Core/hip mobility"
            },
            {
                "id": "3fbd58eb-b827-4feb-bb40-68e8023658eb",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "8063df29-f1b5-4bd4-b43e-e7dce342f9fb",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "99c64f9b-53dd-498c-8692-cf1127091623",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "b4003a46-ee7a-4ea5-8cd9-bb13fbfd2dc3",
                "name": "Banded Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Band (RPE 5). Set 2: Band (RPE 6). Set 3: Band (RPE 6). Rest: 45 sec between sets Accessory: Pigeon between sets"
            },
            {
                "id": "aa6167e7-d70a-4c86-a980-19fecdf59c04",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "a7753930-21c9-4e48-8a2b-dfbdd1fb14d4",
                "name": "Med Ball Clean",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Good Mornings between sets"
            },
            {
                "id": "faf90433-785f-40e9-a35c-45a7939c604d",
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
        "id": "ce473422-f3a2-486b-9e0c-26510573f28f",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "0b072bee-1983-4df9-bb15-5b1cae6ad48a",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded/SL variation"
            },
            {
                "id": "d623095e-f6fc-495d-9660-fa4e5e4de2dd",
                "name": "Dead Bugs",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "3f93eaa8-c230-4e19-a601-c4d33d3a8e0a",
                "name": "Wall Sit",
                "sequence": 3,
                "notes": "Quad isometric"
            }
        ]
    },
    {
        "id": "dbc32ce9-e6bf-44d5-8fc5-1a30f4f19097",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "d81d8ea9-fd50-462c-84db-ce89a4c7690b",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "92bd7324-5434-4fd7-9ae9-dfbd980710a1",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "dcecd744-8458-4372-86dc-d60f6510ceb3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "15666aab-295d-49cb-badb-7d69445b484b",
                "name": "Pigeon/Piriformis",
                "sequence": 4,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "f22b2678-891f-402e-af2a-4e4d7b169365",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "c9f4538b-e545-4cc3-9641-156bdfe63b2f",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "7dff7e46-7d8f-4d0b-807f-9c4c4d2f7156",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "488df7aa-dc9a-4c55-b554-1a7e5a27e2b5",
                "name": "Turkish Get Up (TGU)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: SL Rotation between sets"
            },
            {
                "id": "c1b7b0df-b578-4534-a66c-72922b73cf71",
                "name": "Good Mornings",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "55726dd7-aaba-4653-a43e-dd8926b732c2",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "7fde8682-bc51-4d78-ada4-d6c79d161eb5",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 3,
                "notes": "3 rounds total"
            },
            {
                "id": "8e764a62-dc9c-4fe1-8e9f-6d67c698cc9e",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "notes": "3 rounds total"
            },
            {
                "id": "91ede8b6-d7b9-46b2-887f-277818c048cd",
                "name": "Groundhog",
                "sequence": 3,
                "prescribed_sets": 3,
                "notes": "3 rounds total"
            },
            {
                "id": "bf71e9ac-2ba6-4f47-8175-75e78d07638c",
                "name": "Push Press",
                "sequence": 4,
                "prescribed_sets": 3,
                "notes": "3 rounds total"
            },
            {
                "id": "6fd2b4d5-a9e5-4bbf-81c9-e69c2017cec2",
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
        "id": "a7b20e35-5edd-4c98-86d2-7cfa602358ea",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "d791d61e-1714-40a5-9e72-fc5846c1b340",
                "name": "Push Ups",
                "sequence": 1,
                "notes": "Upper body activation"
            },
            {
                "id": "be87cd44-ee04-46e3-a10c-9c6f27f259bb",
                "name": "Sit Ups",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "9969312e-3764-48d8-92e3-5f0eb19903b7",
                "name": "Air Squat",
                "sequence": 3,
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "41781f47-0b6c-45f2-849f-102694cd1ebc",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "ee9cc8e2-2970-4a86-a54a-3a84ab29dda3",
                "name": "HS Walk",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "ec983e4e-9361-4fe8-9b5d-a5ce1ae02f10",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Dynamic hamstring"
            },
            {
                "id": "89cc13d7-dd1c-4f71-8d22-daf58ddddd09",
                "name": "Over/Under",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "f560e4b8-a489-4aba-9057-9c02a7e2d793",
                "name": "Quad Pull + Hinge",
                "sequence": 4,
                "notes": "Quad/hip prep"
            },
            {
                "id": "94c8f70c-0f8b-4f9b-a7d8-5e2fc5258cf6",
                "name": "Push Up W/O",
                "sequence": 5,
                "notes": "Full body activation"
            },
            {
                "id": "a5a1eded-4778-47d1-b774-2023b4d656fa",
                "name": "90s Robot",
                "sequence": 6,
                "notes": "T-spine mobility"
            }
        ]
    },
    {
        "id": "a2df749c-332e-40fa-b18b-09f2b1887990",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "5baa9bca-c779-4836-97c5-f074821918d1",
                "name": "SL Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "4ba3d085-acae-46e4-9a0c-b07c1901203e",
                "name": "SA DB Bench",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "4d8b9b90-4b46-4e30-9ae8-aca1e8e68e4f",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "07e17402-a2c9-424c-9378-58c8f911a86d",
                "name": "SA KB Swing",
                "sequence": 1,
                "prescribed_reps": "8e"
            },
            {
                "id": "7fe39139-356c-4b05-b7b6-f05fd891da8e",
                "name": "HKTC",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "9c49d62c-a10b-400c-acb3-169447d4a914",
                "name": "Renegade Row",
                "sequence": 3,
                "prescribed_reps": "8e"
            },
            {
                "id": "6a718a95-ceff-4cb3-8de5-51dda6739c29",
                "name": "Sit Ups",
                "sequence": 4,
                "prescribed_reps": "10"
            },
            {
                "id": "bcef1cd8-d8a3-491f-803c-5c46c636fbd6",
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
        "id": "f375356e-68bb-4db7-8792-be7b261a0d4a",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "65532eda-eee4-4ac9-bccd-ba58c796bd9e",
                "name": "FMS Retest",
                "sequence": 1,
                "notes": "Movement assessment"
            },
            {
                "id": "cea71087-de60-4602-bf73-076c896eb7cf",
                "name": "Bike/Row",
                "sequence": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "8df1ddcd-63ae-452a-b488-8e4c3a3f05fa",
                "name": "Push Ups",
                "sequence": 3,
                "notes": "Upper body prep"
            },
            {
                "id": "03ad0f64-fc56-44e4-ad94-78903a90d3a5",
                "name": "SL Bridge",
                "sequence": 4,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "5e567754-b46f-4820-b820-4ca1438ddd46",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "e7d1495b-98c5-42a1-8668-c264d0529940",
                "name": "Hamstring Walks",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "c7fe8710-edd1-48ae-93ce-d10b96afa3a2",
                "name": "Piriformis",
                "sequence": 2,
                "notes": "Glute stretch"
            },
            {
                "id": "416441b2-7141-4b4d-ab75-0c82946b8fbf",
                "name": "Quad Pulls",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "46587d36-5a39-4527-b71e-8f00ccc6f61f",
                "name": "Lunge & Rotate",
                "sequence": 4,
                "notes": "T-spine mobility"
            },
            {
                "id": "78eccaee-d176-45ac-baa2-40337b2cb136",
                "name": "Hip Openers/Closers",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "cf11fbaa-5878-49c8-859a-a7f014dcb753",
                "name": "High Knees (fast)",
                "sequence": 6,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "d6eafe3d-08b6-4be0-bde7-8d2da79cfed3",
                "name": "Butt Kicks",
                "sequence": 7,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "746f3f08-00d6-48f0-b80f-fd17858fa2d6",
                "name": "Walkout + Push Up",
                "sequence": 8,
                "notes": "5 - Full body activation"
            }
        ]
    },
    {
        "id": "8eeb2004-0a5d-4f39-b9ad-2b1bf4ebd3a8",
        "name": "Intro - 9 min EMOM",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "631335a2-4e6a-443f-aaf4-0005c74c6250",
                "name": "10 cal Bike/Row",
                "sequence": 1
            },
            {
                "id": "6ae3a18a-02a2-412d-88b4-9e31d04bb02b",
                "name": "10 BB DL",
                "sequence": 2
            },
            {
                "id": "66a544de-953a-4550-9cb0-eaf3d7334570",
                "name": "10 Bar Over Burpees",
                "sequence": 3
            }
        ]
    },
    {
        "id": "0d896768-788a-467a-9e48-87d4baa19ea9",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "1dce2ec5-a171-4835-a5be-3445c26a5112",
                "name": "3 Way Lunges",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "5e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "3f6b2d3c-8644-4fb9-b7c1-ad9a518e6996",
        "name": "Conditioning - 12-15 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "87decea5-e940-4a5a-9506-7e31b69d0b59",
                "name": "Starfish",
                "sequence": 1,
                "prescribed_reps": "12e"
            },
            {
                "id": "be9f242c-3a92-4f28-b3d3-f2d7c0bed58b",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "e18c2200-e3ca-4283-8885-37758bc2ffd1",
                "name": "Farmer''s Carry",
                "sequence": 3,
                "prescribed_reps": "1 length"
            },
            {
                "id": "4e8197d6-6f7e-4d90-a4a0-bd938e6e5e17",
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
        "id": "e5118a72-0fec-4a48-9ad5-40ca689a1339",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "f990413c-eee4-4900-bcdc-ff759b4af1ba",
                "name": "Row",
                "sequence": 1,
                "notes": "Moderate pace"
            },
            {
                "id": "08f87cff-3088-4925-80d7-508b59140605",
                "name": "Monsters",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "22c973e8-37da-4dd7-a68b-c44d37f56846",
                "name": "Shoulder Tap",
                "sequence": 3,
                "notes": "Core/shoulder stability"
            }
        ]
    },
    {
        "id": "55afccf6-b2b4-4027-ab12-8d66fad08e47",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "01c2a217-ae7a-4259-8e84-4dc3b15bad01",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "9c9d8fc7-1608-46b4-a8de-e0e8e541e115",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "af48353d-3141-4858-8687-474cc07502cd",
                "name": "Quad Pull + Hinge",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "674e08d8-df0f-4e17-a36d-f561ce5c17ac",
                "name": "Hi Touch/Lo Touch",
                "sequence": 4,
                "notes": "Dynamic stretch"
            },
            {
                "id": "3da091cd-56cb-42ec-a4a9-43112314a724",
                "name": "Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge prep"
            },
            {
                "id": "b26db3f5-e594-4eba-ab2a-bf965db0c3f9",
                "name": "PVC Passover/Fig. 8",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "d9c0dac9-d8f8-44ce-a45d-65cb3f089996",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "14093814-53e4-4a61-b8f5-da9b4a671dd9",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "7d0be24e-389c-43ff-a35c-004cff58b0dc",
                "name": "SL DL",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "2ef7e8c4-9ded-4215-a1ab-e915ebfdffc5",
        "name": "Conditioning - 5 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "c39431b1-782d-4344-adac-a56f05c5a245",
                "name": "Goblet Squat",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "5 rounds total"
            },
            {
                "id": "0027b4c0-0244-457a-ab86-ba6c4bb4a1f7",
                "name": "Groundhog",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "5 rounds total"
            },
            {
                "id": "09a972f2-e9cb-4bcb-9d90-d56331a0d6c6",
                "name": "Split Squat",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "8e",
                "notes": "5 rounds total"
            },
            {
                "id": "b9cf61a0-bfc5-48a0-990e-051d500cbfdf",
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
        "id": "b72ad36d-ecc5-46a3-826b-eb4132312bb6",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "a934cd22-7087-437e-a1ea-46d8099f43ec",
                "name": "Bear Crawl",
                "sequence": 1,
                "notes": "Full body activation"
            },
            {
                "id": "2345cc44-9cb9-4919-9136-4d2f8f345982",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "6cb18e00-433c-4fc8-85dd-73de4641c264",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "702c3304-7859-4d90-b8fc-132815216fea",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "e59a643d-c57f-40d0-bc9f-4c4e27eb0e3b",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "bbb2bfde-a133-4f12-a5a7-35a662ec0c3e",
                "name": "Arm Circles",
                "sequence": 3,
                "notes": "Shoulder prep"
            },
            {
                "id": "a7422786-2010-467d-b4c3-e447b476df9e",
                "name": "Push Up W/O",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "45a63324-947a-42ba-96aa-e26b4e7b0ac3",
                "name": "Pigeon/Piriformis",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "45fe0061-22db-4170-b03b-f72f9087aa69",
                "name": "Butterfly",
                "sequence": 6,
                "notes": "Adductor stretch"
            }
        ]
    },
    {
        "id": "d40371c7-7e52-4f48-b8ed-bf62e6481fde",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "05c467e1-182a-4699-bdcc-63b13b97d3a7",
                "name": "Slant Bar 3 Ext.",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Pigeon between sets"
            },
            {
                "id": "ab00d0ec-623b-47cb-b591-640d2ad1739a",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            }
        ]
    },
    {
        "id": "67615836-3ec5-43ce-b88a-fdc5d9290f86",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "8c9dd0cc-b1e0-4bea-a144-67b16d2224f6",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "250m"
            },
            {
                "id": "c3513ca5-a3b7-41ad-82a2-7cd8493e364d",
                "name": "KB Swing",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "dd0aee9b-050f-46db-a4e4-f9e5a3cb10e2",
                "name": "Starfish",
                "sequence": 3,
                "prescribed_reps": "10e"
            },
            {
                "id": "347eceb6-6dd1-41a0-b6da-724e146fa629",
                "name": "\u00bd Kneel Chop",
                "sequence": 4,
                "prescribed_reps": "10"
            },
            {
                "id": "f14ae547-6aff-4e5e-86fa-025ff3e4dde4",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "250m"
            },
            {
                "id": "f4f05905-8d45-4a5a-91f3-927eff7aca64",
                "name": "Back Lunge",
                "sequence": 6,
                "prescribed_reps": "10e"
            },
            {
                "id": "4b118c0b-a83f-4928-b34b-074ac72e7836",
                "name": "Russian Twist",
                "sequence": 7,
                "prescribed_reps": "10e"
            },
            {
                "id": "b1814d8e-0f95-403a-92d4-2382702e3a7e",
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
        "id": "3c2e9b84-4c79-4b5b-bc8a-f224e4fc8032",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "27612d11-e154-4a53-b35d-0d5fe5a4b1e8",
                "name": "Banded Clamshell",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "dc630a04-ac01-427a-a672-78b19724ca52",
                "name": "Sit Ups",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "3c647a68-2064-4dba-86cb-42a89606d5f6",
                "name": "Push Ups",
                "sequence": 3,
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "1eadbe91-7a02-4f94-ae2c-291563f2b145",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "f8daa0ba-b36b-4873-ae8b-8bbc7b65154a",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "08e372b6-8ce0-4be5-848a-eb9c7a084442",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "21db9373-3b98-4eb2-bd8d-23177683d840",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "66c5ad12-5aae-4108-8e82-9c7139d6c196",
                "name": "Over/Under",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "3103fb35-d4ab-49b2-80ca-41ff29f932f8",
                "name": "Side Lunge",
                "sequence": 5,
                "notes": "Adductor mobility"
            },
            {
                "id": "9a723450-a53c-4081-b6a9-451de85e3d73",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "5413a755-4da0-43f0-a9c0-08cc5d6504d6",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "d6c2afae-193f-4fca-8d44-bc078063ed67",
                "name": "Hip Thrust",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Ham/Glute Stretch between sets"
            },
            {
                "id": "f604207c-bf1c-4c95-b6e2-d416c991d3e9",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Light-Moderate (RPE 7). Rest: As needed Accessory: SL Rotation between sides"
            },
            {
                "id": "6c395f62-620b-4f0c-bfd1-c12e9ec5509f",
                "name": "Floor Press",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "f66b2bfc-d33d-4597-afb9-a03f6c7cf00a",
                "name": "Kang Squat",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "f57bf353-c84b-4cb3-bba3-6c0715f1db50",
        "name": "Conditioning",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "9ff2e5d4-61d6-4339-84d0-2eefd01b0c08",
                "name": "Hollow Hold",
                "sequence": 1
            },
            {
                "id": "122802d6-c6e4-431c-8bec-44c310469931",
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
        "id": "fd26a16c-e255-4ed5-a17e-4c899f3aa3e8",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "84242c16-879d-41cb-b2cb-1c06af7bbeac",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded/SL variation"
            },
            {
                "id": "9693537e-889b-4a63-8018-d6e7cb9a2990",
                "name": "Dead Bugs",
                "sequence": 2,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "d19bb9fb-45d0-4d27-af8e-32d7da6477b1",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "5706d36d-372e-4617-b568-b94faf199420",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "9810a913-fad8-4d75-9734-cbeac242e6f2",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "6d53c014-e18a-487d-b9eb-f10341f1b081",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "e4bf335e-5c79-472e-adbe-f00df0f21e1f",
                "name": "Heel Kiss Walk",
                "sequence": 4,
                "notes": "Ankle mobility"
            },
            {
                "id": "802c9f04-d4d8-4250-a933-5e22d5b6c386",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "156598fb-b0e6-4c60-8ebe-3a5297f526f8",
                "name": "ATW",
                "sequence": 6,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "1c044b7e-dd9f-4937-8d20-b0a33a7e94ac",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "4f979833-a9d0-4e70-9e43-1045df2dfa54",
                "name": "SL Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "2ed82914-4c53-4cfe-8458-6a8bc295ac3a",
                "name": "SA Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "542ef151-4cf6-432a-beba-c0ab2de51a6c",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "bdcb8cc8-9e73-4eb3-9fdd-2c0061a3bbe8",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "73a2b7a9-31ce-4f8a-9522-7a3e18918ecf",
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
        "id": "a210aee9-25ea-48a9-8647-101cb2f08a59",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "6e3f7005-32d3-4d42-b19b-fc1075e5da6f",
                "name": "Row / Jump Rope",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "64a37398-acad-443f-8e36-605c2f1bf123",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Banded/SL variation"
            }
        ]
    },
    {
        "id": "35b41276-ded9-43cd-9f45-3943c46f42f1",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "43b0db95-2cd6-43ae-9fee-08b4a18326c5",
                "name": "High Knee Pull + Reach",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "ea4ac06d-c932-44ab-9e26-734ca882075b",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "236f8bf7-4f9f-4f5d-9129-9d9402cc06fe",
                "name": "Quad Pull + Hinge",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "3ffc6273-b4f9-491b-a55c-8d2fa978ab70",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "1278118c-c602-47e0-8760-6d41cc2c848c",
                "name": "Push Up W/O",
                "sequence": 5,
                "notes": "Full body activation"
            },
            {
                "id": "fec0c2cd-101c-4756-a3ae-d19a6d7cc637",
                "name": "SL Rotation",
                "sequence": 6,
                "notes": "Core/hip mobility"
            }
        ]
    },
    {
        "id": "d0309ab5-2016-45df-a20d-a6881d7034d5",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "ca018fb7-beb8-4633-bd7a-3ac856388add",
                "name": "Front Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "48697362-1cbd-4845-81aa-2b086386e317",
                "name": "KB RDL / Good Mornings",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Banded Ham Stretch between sets"
            }
        ]
    },
    {
        "id": "5cd4b84d-f45c-45e3-b2b1-43ca3598322c",
        "name": "Conditioning - 12'' EMOM",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "7f2461b4-a3ce-4a58-b073-0f49ac124a18",
                "name": "Lunges",
                "sequence": 1,
                "prescribed_reps": "8e"
            },
            {
                "id": "e8e5cf36-6b46-40c9-82f6-8a2c3ab9be35",
                "name": "Shoulder Tap",
                "sequence": 2,
                "prescribed_reps": "10e"
            },
            {
                "id": "7b7c13e5-d119-4caf-8068-c6952ddeff81",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_reps": "8"
            },
            {
                "id": "71394483-8097-4c30-8233-c9bf98678a1b",
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
        "id": "27ff1261-9bb6-48fa-8a9f-f84635afe1c2",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "7f8fc519-f843-44cc-ad2b-9ca03387d857",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "57c26800-9a73-4501-83a7-2e0fe6b4a88c",
                "name": "Banded Squats",
                "sequence": 2,
                "notes": "Quad activation"
            },
            {
                "id": "0c90c73d-36f2-4c6f-a279-b42e62ca81d8",
                "name": "Banded Bridge",
                "sequence": 3,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "a53247f8-78fd-46ab-9b6e-05efe6c94132",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "8708c703-67bc-47f8-8699-61e053d74350",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "804b46e0-ce93-46fd-b074-00801cb807ea",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "f5e796bf-1545-4a92-bd9d-62e230561d6e",
                "name": "High Touch/Low Touch",
                "sequence": 3,
                "notes": "Dynamic stretch"
            },
            {
                "id": "122f1c81-72af-4651-a6fb-57e116964003",
                "name": "Pushup Walkout",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "a5a79229-52d3-4511-908f-ca3bc548fc46",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "89beb295-911f-4195-93ba-46b9ebfcc091",
                "name": "PVC Passover",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "7983e81d-09c0-4ae2-bfbe-2132e51d53f5",
                "name": "Good Mornings",
                "sequence": 7,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "622a20a7-5f61-493b-8313-d3d22160698f",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "9d9f0877-f1d8-485c-965e-baf7e5a4039b",
                "name": "Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 8). Set 5: Max (RPE 9). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "9d297942-0314-4f77-a924-fd9c64a5b02e",
                "name": "SL DL",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "40475a57-61ac-4f70-b220-29b20687dc01",
        "name": "Conditioning - 15'' AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "1082f4ac-e378-4060-97cf-90de065d0ac8",
                "name": "Front Squat",
                "sequence": 1,
                "prescribed_reps": "10"
            },
            {
                "id": "3fcea532-3e5c-44fc-afe6-82969f031192",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "10e"
            },
            {
                "id": "d9345837-f396-4631-89d4-7ab1bc1ad2d5",
                "name": "Push Press",
                "sequence": 3,
                "prescribed_reps": "10"
            },
            {
                "id": "2b7f4f47-6bc0-4e82-a39b-9552bf0644d8",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_reps": "10"
            },
            {
                "id": "bec518bf-e602-443f-ada9-42cb50c8f9a8",
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
        "id": "cb641243-7928-4bd7-9710-66c30f4ca88d",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "6c78479f-c9a4-457a-b944-71ad25207b93",
                "name": "Monster Walks",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "326c5da1-4c47-4406-bb0f-4378a3d11a1a",
                "name": "TRX Is, Ys, Ts",
                "sequence": 2,
                "notes": "Shoulder activation"
            }
        ]
    },
    {
        "id": "f68e16f4-5828-4745-b1cb-068029d0e962",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "5b8b1634-bd95-47ca-b9be-a0326cecaee6",
                "name": "Spiderman & Rotate",
                "sequence": 1,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "2b2d27ac-34dd-46f4-8681-98f493234f1a",
                "name": "High Knee Skip",
                "sequence": 2,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "2324d847-406b-4ef7-b47c-f0b3fa501690",
                "name": "Quad Pull + Hinge",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "6142d807-e8f3-4db2-b739-1bbade3749b6",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder prep"
            },
            {
                "id": "4fdfe36a-74e2-4bf8-b7cd-f59cf559d36d",
                "name": "Walkout + Push Up",
                "sequence": 5,
                "notes": "5 - Full body activation"
            },
            {
                "id": "e45567fc-baaf-4620-9b6b-fe358df191d6",
                "name": "Lunge + Reach",
                "sequence": 6,
                "notes": "T-spine mobility"
            },
            {
                "id": "809f8346-b963-42ee-9cdd-31a1bca35a8f",
                "name": "Toy Soldiers",
                "sequence": 7,
                "notes": "Hamstring activation"
            },
            {
                "id": "c2825fd9-14c2-41f5-a1e4-191f82cc666b",
                "name": "PVC Figure 8s",
                "sequence": 8,
                "notes": "Shoulder mobility"
            },
            {
                "id": "04403ca5-d7e6-4267-81cb-6d38530d19fe",
                "name": "TGU",
                "sequence": 9,
                "notes": "1e - Full body warm-up"
            }
        ]
    },
    {
        "id": "fd2c86d1-06d8-4f7d-9797-52f204ba9225",
        "name": "Intro - EMOM (40 sec each)",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "8373ab69-81e0-4430-aba5-a5a93f8ec81d",
                "name": "Snow Angels",
                "sequence": 1
            },
            {
                "id": "3da84fcb-1f57-49d9-8b2c-1340034ecb6d",
                "name": "Burpees",
                "sequence": 2
            },
            {
                "id": "6a9b8bf9-4b1e-4630-bb27-4beb74fb4d24",
                "name": "Sit Ups",
                "sequence": 3
            }
        ]
    },
    {
        "id": "d5c220b1-3606-40b6-a843-033cb0071cb8",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "84b0bf62-dab9-46f3-9476-e6eae17dc053",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Dead Bugs 10e between sets"
            }
        ]
    },
    {
        "id": "fc505089-8f30-41f3-b084-4fcbc841ba21",
        "name": "Conditioning - 12 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "22c620c4-ad1b-4770-99f8-750def2016d8",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m"
            },
            {
                "id": "edc54a92-3d6b-44c7-a148-a8ea7da183ac",
                "name": "Push Press",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "860a8468-401c-46cc-98a2-69c32a196b76",
                "name": "V Ups",
                "sequence": 3,
                "prescribed_reps": "10"
            },
            {
                "id": "59b0376b-bc99-41e3-8f84-bcfe660922d5",
                "name": "Goblet Squats",
                "sequence": 4,
                "prescribed_reps": "10"
            }
        ]
    },
    {
        "id": "d8cd0ac2-2e60-4fe8-8a17-e7e80a15806e",
        "name": "Cashout - 2 Rounds",
        "block_type": "functional",
        "sequence": 6,
        "exercises": [
            {
                "id": "e9fb7eee-b6d9-4339-aae5-1e456b19c0f2",
                "name": "Rope Climb",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "1"
            },
            {
                "id": "b175623f-2296-41f2-b458-7326b106bd74",
                "name": "MB Slams",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "8"
            },
            {
                "id": "bab349c3-52eb-4178-b837-cec7549d0a0b",
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
        "id": "16aad16d-6e71-4b1c-b880-5a24b7ec493a",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "5c01d730-489c-4b5f-b1cd-9db963f7ebcf",
                "name": "Banded Bridge",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "ee8a2f9e-e803-4e45-8629-221864fc3ad7",
                "name": "Banded Squats",
                "sequence": 2,
                "notes": "Quad activation"
            }
        ]
    },
    {
        "id": "42386298-a69e-48cb-a3ed-cb1ab2f25975",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "2c741a82-719c-4aac-897b-c3e9ea1195d2",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "047c8e02-07ff-4ec9-98e0-9b9d247f3af0",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "9b1012a4-c3ff-4c0d-8c83-eac6fb570ddc",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "3b632648-109a-47d0-ad55-c57329c4c6ee",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "0aeb6b36-8426-4d74-8eb8-1179bdb5738d",
                "name": "Push Up W/O",
                "sequence": 5,
                "notes": "Full body activation"
            },
            {
                "id": "03a87101-9b2f-4a6e-b3f0-0179178c915c",
                "name": "Pigeon",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "c88b4795-8e6a-4655-a614-39c0c3e63ecd",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "cdfe66b7-0daa-4d4c-967a-5ef512d8639d",
                "name": "Lunge 3-way",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "a2b48c98-0930-4eca-9797-cb5f65063423",
                "name": "SA Row (TRX/DB)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "3af39c79-25dc-4027-8b09-104efe3ccc2c",
        "name": "Conditioning - 12'' AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "b3cfe678-1004-44da-84e8-2ff1e2031572",
                "name": "Push Ups",
                "sequence": 1,
                "prescribed_reps": "10"
            },
            {
                "id": "ebb57914-293a-49c8-9004-4b185367c0c2",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "3bec285a-c56f-4751-bc33-21fdada955f7",
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
        "id": "c4391899-dba8-4af6-b78f-10a3eb479d52",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "ca01ac70-1825-44f6-873c-1776183eaba3",
                "name": "Sally Up!",
                "sequence": 1,
                "notes": "Push-up challenge"
            }
        ]
    },
    {
        "id": "b3fd312c-8eb7-49fd-884e-0a0c4807dde5",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "21d983ab-d2aa-4c39-a6b7-a8dafdcc1695",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "7a1067aa-850a-4c4f-9064-29ffcaf43387",
                "name": "Hi Touch/Lo Touch",
                "sequence": 2,
                "notes": "Dynamic stretch"
            },
            {
                "id": "64bd5b05-b8c8-4697-91a7-b9b42a1d0433",
                "name": "Spiderman",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "fcc1326a-ed23-4bbc-a842-8720192f766a",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "e5c47d57-22f3-42f1-80ec-38734ac5234d",
                "name": "Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge prep"
            },
            {
                "id": "8563efbe-d4a1-4e8c-a28a-f549940d2b22",
                "name": "Bear Crawl",
                "sequence": 6,
                "notes": "1 length - Full body activation"
            }
        ]
    },
    {
        "id": "d2c176f3-347a-45c3-9649-5583f0ed05e6",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "3e44771e-d686-4aa2-b17e-54eabc52e206",
                "name": "Floor Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: TRX Pec Stretch between sets"
            },
            {
                "id": "b8a5045d-0d68-4424-aa9a-9ea78138ab51",
                "name": "KB RDL",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "b6dd0e95-5b14-473e-8001-274550e6db0f",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "2b65eee0-df19-4dda-9f5b-2bc8be232591",
                "name": "KB Swing",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "ef4c5fbe-5f97-4c1c-8994-bf7f2070d237",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "15e",
                "notes": "3 rounds total"
            },
            {
                "id": "179d9597-32b0-48ea-a775-f9850deeea20",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "77458438-3bd0-434d-8c8b-e19f593473c3",
                "name": "Med Ball Tap",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": "3 rounds total"
            },
            {
                "id": "a1e60f83-74bb-446e-bdf7-c485e7efa6e8",
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
        "id": "c53cf42c-53ad-45b7-94b9-c270671cdd4e",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "7baad170-8681-4610-b2a8-7a21462afa56",
                "name": "Sit Ups",
                "sequence": 1,
                "notes": "Core activation"
            },
            {
                "id": "fc02831d-6e64-4d23-a037-62e589a1a7df",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "Lower body prep"
            },
            {
                "id": "cab98e01-8c2b-4b23-8f04-11870e20b7d8",
                "name": "Push Ups",
                "sequence": 3,
                "notes": "Upper body activation"
            }
        ]
    },
    {
        "id": "102049f9-63a6-4b05-9edd-ed256781277d",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "1dc814b5-9544-4c48-afe9-fd30694c94c2",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "773c3021-dee9-43c8-907d-b9d86c3e5ba2",
                "name": "Over/Under Fence",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "236e43c0-9fe0-4739-81ef-936732bfe75c",
                "name": "Toy Soldiers",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "77eef821-cbb6-464b-9d8f-5d9c1c763a10",
                "name": "High Knee Skip",
                "sequence": 4,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "edfc1c64-e63a-469c-92bd-58cc610da886",
                "name": "Spiderman & Rotate",
                "sequence": 5,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "b82e51cb-8846-4546-bd8a-a3fec1a9a739",
                "name": "PVC Passovers",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "4ef21d62-cd65-4884-b21a-80aea05c23d4",
                "name": "Is, Ys, Ts",
                "sequence": 7,
                "notes": "3e - Shoulder activation"
            },
            {
                "id": "105222d5-ce23-4b7b-93cb-846086f27dbb",
                "name": "Side Plank",
                "sequence": 8,
                "notes": "30 sec e - Core activation"
            }
        ]
    },
    {
        "id": "6ea63115-f951-447f-8fb7-c54ad6141a3a",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "e8bcb52d-0db8-4993-b59c-176a9dabe075",
                "name": "SL DL",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Dead Bugs 10e (slow) between sets"
            },
            {
                "id": "fb713b36-9087-4731-bfb0-7d1e044861fe",
                "name": "DB Bench Press (Pyramid)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate+ (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Chest Opener between sets"
            }
        ]
    },
    {
        "id": "755ff342-6037-467f-ba96-6a3ba7e21be3",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "f23f3b20-7c4b-4bb4-82df-f65f0e89a57f",
                "name": "KB Swings",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "17e7f3d8-79a4-4dfa-87fe-010adcb4f8b5",
                "name": "Push Presses",
                "sequence": 2,
                "prescribed_reps": "15"
            },
            {
                "id": "c5744299-0053-4d94-8bd8-d2112f21b4b8",
                "name": "HKTC",
                "sequence": 3,
                "prescribed_reps": "15"
            },
            {
                "id": "ecc7c3be-0a5f-4020-9155-bd24357b65a8",
                "name": "TRX Rows",
                "sequence": 4,
                "prescribed_reps": "15"
            },
            {
                "id": "de321a4e-3361-4950-8ca2-7087f103284b",
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
        "id": "73d606b2-23da-432d-9efd-fca8b2c6c009",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "e1b70426-ec86-45ef-b594-61a7e8d1d31a",
                "name": "Jumping Jacks",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "e0b58ef0-c5f0-49bd-b1a6-5b1971b2e092",
                "name": "Monster Walks",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "ee2516db-9626-465e-b2aa-35d4c10df361",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "6546d138-f0f3-4c19-ae08-f914da1eceaa",
                "name": "Arm Circles",
                "sequence": 1,
                "notes": "Shoulder prep"
            },
            {
                "id": "d040a929-fa2d-49fd-9c17-b3d748480a18",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "03e7ee37-970e-4c87-a729-c86523c97840",
                "name": "Hamstring Walks",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "0d09fdbd-8bb8-4ea8-874e-a8d5daf984ea",
                "name": "PVC Passovers",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "64ed508d-4b97-4188-94bf-5ad17d6ea4bb",
                "name": "Hip Openers",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "01c062ef-a7f4-446a-b92d-908c60a89b83",
                "name": "Piriformis",
                "sequence": 6,
                "notes": "Glute stretch"
            },
            {
                "id": "d3d941bb-c353-4f77-a891-3c61453323ff",
                "name": "Quad Pulls",
                "sequence": 7,
                "notes": "Quad stretch"
            }
        ]
    },
    {
        "id": "60bdff59-d1cb-48b5-8335-754fe3eeaad2",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "483f5aeb-2279-4694-b74c-e9bca856fdbf",
                "name": "SL Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 8). Rest: 60-90 sec between sets Accessory: Birddogs 10e between sets"
            },
            {
                "id": "4342ce68-976a-4e9d-880f-b7028a577877",
                "name": "Slant Bar Twist",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "a554c6a0-6502-4336-8f0e-c9d69aff48b3",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "85dd74a2-4d77-4f5b-88fb-d121a33590e2",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12 cal",
                "notes": "4 rounds total"
            },
            {
                "id": "8eeb4805-51dd-46aa-9586-afd27f23b369",
                "name": "KB Swings",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "4 rounds total"
            },
            {
                "id": "ba5f0386-adc3-4e4c-a9cc-dd3d76587ebc",
                "name": "Sit Ups",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "4 rounds total"
            },
            {
                "id": "46f2dc32-b5c8-42cd-b22f-7c1a26dbbca0",
                "name": "Split Squats",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "4 rounds total"
            },
            {
                "id": "032928ce-e9a1-4bfb-af72-dbb9ed544394",
                "name": "Russian Twist",
                "sequence": 5,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "4 rounds total"
            },
            {
                "id": "8ca34001-786a-4193-ad5a-4828895b6e5d",
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
        "id": "127e29ef-ee1d-4863-ab62-3f4651f980ef",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "c2b3ca45-6b74-433f-91db-36224f1195b7",
                "name": "Snow Angels",
                "sequence": 1,
                "notes": "Shoulder activation"
            },
            {
                "id": "b23248bb-59bd-4bc8-9d1a-b588396129dd",
                "name": "Jump Rope",
                "sequence": 2,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "e9d4d100-0851-419e-84a8-2b57f97f9983",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "e52cd321-019c-4a35-b1bc-559416ac63d6",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "f4346bad-c62b-40ef-bca6-5067f3e9c732",
                "name": "Hamstring Walks",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "06236ea9-76ba-424c-a824-8c74083b0bc3",
                "name": "Spidermans",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "e5727b05-4b88-4bda-8e57-5d03db295984",
                "name": "Lunge + Reach",
                "sequence": 4,
                "notes": "T-spine mobility"
            },
            {
                "id": "ff80b1cc-7743-4449-9633-da8c9a793b55",
                "name": "High Knee Pulls",
                "sequence": 5,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "db21e124-cc33-4f72-9844-83ec7e98fc0e",
                "name": "Walkout + Push Up",
                "sequence": 6,
                "notes": "5 - Full body activation"
            },
            {
                "id": "91aae4cc-9219-4640-875f-27796aa050ae",
                "name": "PVC Passovers",
                "sequence": 7,
                "notes": "Shoulder mobility"
            },
            {
                "id": "bafcf5dc-20dc-41d1-b329-ec89c01fd93a",
                "name": "Lat Stretch",
                "sequence": 8,
                "notes": "Back mobility"
            }
        ]
    },
    {
        "id": "8ce18d03-7d4b-4ff3-9ef8-aa901531301b",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "64fb8c2f-a5ab-4c77-bfa1-19e8580e47e8",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Shoulder Mobility between sets"
            },
            {
                "id": "2dafaeb5-a708-4eea-a62a-75ef3b6e9a03",
                "name": "3 Way Lunges",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "3e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Hip Mobility between sets"
            }
        ]
    },
    {
        "id": "91d62e36-ee74-4d0d-b42e-22917d2d19ae",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "84ed3520-8457-4825-bab8-bde2714ce1de",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "250m",
                "notes": "2 rounds total"
            },
            {
                "id": "6362fdc9-c603-4cd5-9813-e83955f2247c",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "2 rounds total"
            },
            {
                "id": "501f0e58-de5c-439a-a63e-a3f972f352f0",
                "name": "V Ups",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "2 rounds total"
            },
            {
                "id": "8b762458-98ba-49fd-b43a-237cdb72a5de",
                "name": "Row",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "250m",
                "notes": "2 rounds total"
            },
            {
                "id": "4d9c85cc-6136-420b-8d70-f84ad27a0cf7",
                "name": "Goblet Squats",
                "sequence": 5,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "2 rounds total"
            },
            {
                "id": "c3c91c38-2853-4429-a368-dd8c82c4a4af",
                "name": "HKTC",
                "sequence": 6,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "2 rounds total"
            },
            {
                "id": "bee7bfd5-7850-4f7b-8a6a-3a88b5b5f9dd",
                "name": "Row",
                "sequence": 7,
                "prescribed_sets": 2,
                "prescribed_reps": "250m",
                "notes": "2 rounds total"
            },
            {
                "id": "dd41fdb3-b753-4269-a18f-04b90d315ef4",
                "name": "Box Jump/Step Up",
                "sequence": 8,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "2 rounds total"
            },
            {
                "id": "6f24af2d-4909-42f8-90c5-1a135d574406",
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
        "id": "f75a2dd9-5ff7-45ff-a0c1-f362fbb636d4",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "1395c30d-03e0-44cd-b84a-7fc86d03da9a",
                "name": "Jumping Jacks",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "6ef8eb85-24b0-45bd-8de5-f7c33d3ff975",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "516d5a86-43dd-416a-af48-6fe491dbcf5c",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "00d19756-3722-4842-9d5c-f1587ef9c4cb",
                "name": "Piriformis",
                "sequence": 1,
                "notes": "Glute stretch"
            },
            {
                "id": "82471935-7013-4851-9b50-f7ba169081fe",
                "name": "Quad Pulls",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "77193e25-af71-440d-9c40-9aab542553bc",
                "name": "High Knee Pulls",
                "sequence": 3,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "b332826d-0cbf-4604-9ba7-ede0afe28150",
                "name": "Toy Soldiers",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "bf8e0f37-fed2-4b3e-a322-b5355df9d6ff",
                "name": "Side Lunges",
                "sequence": 5,
                "notes": "Adductor mobility"
            },
            {
                "id": "313694fa-5c5d-4550-8f18-03242a34b463",
                "name": "PVC Passovers",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "c2fe833e-be50-4d39-8100-daa50ce1dab9",
                "name": "Hip Openers/Closers",
                "sequence": 7,
                "notes": "Hip mobility"
            },
            {
                "id": "439c8d9f-b95d-438b-8bf9-cd7ed15d972d",
                "name": "Bear Crawls",
                "sequence": 8,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "fd0d7e62-72b5-44ec-bb8a-1b9eb698ae7d",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "d30a32ae-96a1-424e-a4eb-858f7d10952d",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "6",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate+ (RPE 7). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Chest Openers between sets"
            },
            {
                "id": "95f4f76e-dd8a-479c-8290-24b6e7052821",
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
        "id": "919dad6a-ca14-47f8-bc7f-33b29fcc35be",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "3edec8fd-15f9-4861-aa88-dae46f30c852",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "0b0d2e22-c74c-4c60-9217-ef1c8111534c",
                "name": "Banded Squat",
                "sequence": 2,
                "notes": "Quad activation"
            },
            {
                "id": "0b4874db-f23f-403b-9d34-b63adc6c97fa",
                "name": "Bridges",
                "sequence": 3,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "8f4529c7-3694-4e38-89a8-a25d639ce40b",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "ef22831c-5195-4b61-8c8d-93c99ef9ef58",
                "name": "High Knee Pull + Lunge",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "ada2b0b4-0067-4630-8879-69aee60c7a91",
                "name": "Hi Touch/Lo Touch",
                "sequence": 2,
                "notes": "Dynamic stretch"
            },
            {
                "id": "696e4889-f6b3-4d6a-9cec-53a9b30f646e",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "0b2eb4f9-afed-44ec-b331-71848614b8a8",
                "name": "Pushup Walkout",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "a0b4b89e-65d8-4264-9615-33d26e3e7fdc",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "5881e739-782d-4b00-9eeb-0316a3e17685",
                "name": "PVC Passover",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "a6f7ef9b-8724-4e73-b07b-a1fc258397d4",
                "name": "Good Mornings",
                "sequence": 7,
                "notes": "Hip hinge prep"
            }
        ]
    },
    {
        "id": "40cdcbf8-ad97-4092-b8b4-aabf4b21a6ff",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "a6a55e49-4b15-454d-a1be-9dc13b617a09",
                "name": "Slant Bar 3 Ext.",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Pigeon between sets"
            },
            {
                "id": "f54e188b-f9f7-4174-a85e-6692ba2db72d",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "6824790a-9f6b-4e20-9f45-1867122d979b",
                "name": "Slant Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "c8d793a2-c208-4f5f-a37e-59d0269e9282",
                "name": "Step Ups",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "1b45a4a0-7764-49ab-917f-e37e1d9ebabc",
        "name": "Conditioning",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "c305a592-83c4-49ce-be0a-db016d5b8311",
                "name": "Timed 500m Row",
                "sequence": 1,
                "notes": "Max effort"
            },
            {
                "id": "7066a225-6129-4309-b266-5fb778bba72a",
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
        "id": "118c2eaa-0169-493c-aae7-942bf22e410e",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "d0aee00e-75e5-4ed7-bc12-a989c1d882c0",
                "name": "Jump Rope",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "a04d380b-8332-4eb2-aa71-f3511525862c",
                "name": "Row",
                "sequence": 2,
                "notes": "Moderate pace"
            }
        ]
    },
    {
        "id": "19157bbb-7e9e-412e-8ef3-e7cafa03696a",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "bc445a0d-4deb-4572-8cd9-7130ac203517",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "7fa051d8-a40a-45b5-b75f-f3614c32ff43",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "f5d03bfd-359e-4c15-a924-20fd5f3ca81c",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "7259277a-ff16-44f7-8bca-19aeeb74b8c7",
                "name": "W/O Pushup",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "494ca04d-704e-43fd-936b-b592783286f8",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "f1529e9d-6136-4047-8abe-b15953de4b05",
                "name": "RRL",
                "sequence": 6,
                "notes": "Rotation mobility"
            }
        ]
    },
    {
        "id": "f9f59ff7-5bf7-40f8-aedb-d6226923d5be",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "28808d12-6b5e-432b-87ff-513bc9d48dc2",
                "name": "Push Press",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Fig 8''s between sets"
            },
            {
                "id": "661277df-4251-4034-90b7-4b854e146ddb",
                "name": "Good Mornings",
                "sequence": 2,
                "prescribed_sets": 9,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Set 5: Notes. Set 6: -------. Set 7: Alternating waves. Set 8: Footwork drills. Set 9: Front and side. Rest: 60-90 sec between sets Accessory: TTP between sets"
            }
        ]
    },
    {
        "id": "3cf34706-a205-442f-9d75-8d4987706dbf",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "6df6cd74-cd9f-4c47-b09f-1372ae0672e1",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "250m",
                "notes": "2 rounds total"
            },
            {
                "id": "03feb72f-b4d7-4eda-ba9e-fda0181431b9",
                "name": "Split Squat",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "4787b964-3fc6-413c-9ac4-a8944eec2cd2",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "75b8f7d0-74da-4591-99d6-8cda83cb4969",
                "name": "\u00bd Kneel Chop",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "3e3f2ba1-e1f0-461f-b70c-382cc270f3a1",
                "name": "Row",
                "sequence": 5,
                "prescribed_sets": 2,
                "prescribed_reps": "250m",
                "notes": "2 rounds total"
            },
            {
                "id": "1faecc50-79ba-4da3-a251-7c3e066eef6e",
                "name": "Slam Balls",
                "sequence": 6,
                "prescribed_sets": 2,
                "prescribed_reps": "12",
                "notes": "2 rounds total"
            },
            {
                "id": "294ab911-edd3-4809-b164-24bfbe4f7f22",
                "name": "Russian Twist",
                "sequence": 7,
                "prescribed_sets": 2,
                "prescribed_reps": "12e",
                "notes": "2 rounds total"
            },
            {
                "id": "58fed846-bcde-4aa8-99a3-e51051d74fed",
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
        "id": "fa18c056-4cde-49ba-b3a0-c63bdf43eb84",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "4cd0b4d3-183f-4251-99bb-5ed207ba1adf",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded/SL variation"
            },
            {
                "id": "432e7fee-d788-43b4-b7c9-39e9bb59328d",
                "name": "Sit Ups",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "a459ad30-a2ef-4d41-9a71-af58a938a8f3",
                "name": "Cossack",
                "sequence": 3,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "276ed20e-e230-4a61-8e98-f99aabbc0352",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "787c3359-4298-4c3c-8e69-71946aecb0fd",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "4a4e3af8-a77b-43d6-89a1-e52baf6c8e3a",
                "name": "Lunge + Reach",
                "sequence": 2,
                "notes": "T-spine mobility"
            },
            {
                "id": "ea50e083-b28a-4fb7-87c0-ab8657a37dc0",
                "name": "Hi Touch/Lo Touch",
                "sequence": 3,
                "notes": "Dynamic stretch"
            },
            {
                "id": "fe533f40-0c16-42cc-b766-17f2c7ddabba",
                "name": "HS Walk",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "3ae3c25f-c4df-4eea-a74a-e60fa825844a",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "80989d4f-50b2-4d24-ad23-42b827726740",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "91575b15-d942-4c33-a1c7-9a75dcc7671b",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "d1bd7331-a882-494b-9851-082764e62cef",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "0eb99009-674b-4164-baa5-9a1381f63d95",
                "name": "Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "63af5e4b-d242-4e97-95c5-48bca84a136b",
        "name": "Conditioning - 5 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "7bdb3834-025e-4316-817b-eeab4192a720",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "8",
                "notes": "5 rounds total"
            },
            {
                "id": "145a0404-b13e-4a45-a6d8-489cbacf3759",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "15",
                "notes": "5 rounds total"
            },
            {
                "id": "80d2a449-ff6f-4314-bbf8-ef50b43c8cde",
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
        "id": "10ae4e1a-a92c-4895-b2ef-069253000420",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "12df36c2-fbbf-4d57-ac78-bcdc78e22dd7",
                "name": "Clamshells",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "8f803330-aa76-4827-be3f-8287d4cb9d81",
                "name": "SL Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "fe2e0ae7-327b-42ab-8b61-0abfe106efb2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "63860d72-bc91-4a60-a717-e911d4ab7626",
                "name": "Spidermans",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "b3a74de2-01ab-4a7e-a768-693cbf734d86",
                "name": "Quad Pull + Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "f227cfb5-b53a-479a-b3e4-b180a0436680",
                "name": "PVC Passovers",
                "sequence": 3,
                "notes": "Shoulder mobility"
            },
            {
                "id": "33f5027f-9a42-43b7-aa8b-5fe5cb36be95",
                "name": "PVC Good Mornings",
                "sequence": 4,
                "notes": "Hip hinge prep"
            },
            {
                "id": "cefa5b56-ed7e-4a22-a98b-7562ca340bb0",
                "name": "Hip Openers",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "f824dac8-1983-4fde-b7d2-637740a86ddc",
                "name": "Walkouts + Push Up",
                "sequence": 6,
                "notes": "5 - Full body activation"
            },
            {
                "id": "3892b89b-9481-4a93-bd3f-a4a0f47d6713",
                "name": "Shoulder Mob. or Hip Mob.",
                "sequence": 7,
                "notes": "Individual needs"
            }
        ]
    },
    {
        "id": "ead5e61d-91f2-4b7a-aea1-4cfab93fc4f7",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "c52dc4de-ebfe-4160-80ff-9c13564e5197",
                "name": "Bench Press (Building)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Max (RPE 8). Rest: 90-120 sec between sets Accessory: Chest Opener between sets"
            },
            {
                "id": "df730f08-2e4e-441e-bd34-a685a08f7c3e",
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
        "id": "aaedffd5-d88e-45ae-b57e-877182a5cc60",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "58df6da7-c8db-4a31-ba2e-a48206bbfb72",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded/SL variation"
            },
            {
                "id": "3a82c98d-e0c0-44ec-a2db-7379b9d2e52f",
                "name": "Plank",
                "sequence": 2,
                "notes": "Core activation"
            },
            {
                "id": "bd1ba9d2-a98f-4804-8527-1fe245910d69",
                "name": "Wall Sit",
                "sequence": 3,
                "notes": "Quad isometric"
            }
        ]
    },
    {
        "id": "cbfe6361-943c-4f46-908d-de876968e363",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "55727ab2-5b52-4e53-9ef1-017236d80747",
                "name": "Lunge + Twist",
                "sequence": 1,
                "notes": "T-spine mobility"
            },
            {
                "id": "2f632c75-2b48-4dd9-aaab-fe8ef8e806e9",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "a6c9b3f2-8a13-4805-b970-00362ffaaab4",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "63f77e24-12b5-4047-810c-5c1e1205a2ce",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "48775ee8-e704-464f-b00d-c5b981433e4a",
                "name": "Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge prep"
            },
            {
                "id": "6b3fb3e2-6c65-47c2-b5ac-c8a03d3f0204",
                "name": "90s Robot",
                "sequence": 6,
                "notes": "T-spine mobility"
            }
        ]
    },
    {
        "id": "8d6f2207-5b9a-4050-a5f7-aa42237a0f8e",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "65548b3d-8e87-41ed-8b11-309738a4d4c3",
                "name": "Step Ups",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "3c9edb62-c30c-4bdd-b3e4-bd99cf92909c",
                "name": "SA Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "e011638f-26a7-4ff8-8095-3cff8d0e40bf",
        "name": "Conditioning - 5 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "e3f5a563-48e7-4502-9746-525ddf0419b6",
                "name": "Split Squat",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "8e",
                "notes": "5 rounds total"
            },
            {
                "id": "03b2d9b6-1704-4ae0-a860-57e797e7471d",
                "name": "Shoulder Tap",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "12e",
                "notes": "5 rounds total"
            },
            {
                "id": "15e97bf0-1d23-47a8-a224-bf9c00e38bc6",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_sets": 5,
                "prescribed_reps": "10e",
                "notes": "5 rounds total"
            },
            {
                "id": "02c56caa-e01e-473f-8d61-d92a701b3e85",
                "name": "Lat. Skater",
                "sequence": 4,
                "prescribed_sets": 5,
                "prescribed_reps": "12e",
                "notes": "5 rounds total"
            },
            {
                "id": "5689769c-ca02-4fae-a9c8-c5b52e816c5f",
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
        "id": "3a16ee5e-4a8f-4d17-b0d1-bb7303f4195a",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "2d7123b0-5182-4b27-8681-1e0b87899319",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded/SL variation"
            },
            {
                "id": "2b76aba9-5064-4b95-b16e-859f293028e9",
                "name": "T-Push Ups",
                "sequence": 2,
                "notes": "Upper body/rotation"
            }
        ]
    },
    {
        "id": "d7bb79d9-6b2a-47b3-9c5f-485855827506",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "30185793-833c-4bf1-9ed4-a66b79fdd9c3",
                "name": "High Knee Pull + Reach",
                "sequence": 1,
                "notes": "Hip flexor/T-spine"
            },
            {
                "id": "5a9eef3f-6024-45f5-9012-679d86980be8",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "d353d7f2-f603-4b00-b4ad-a0cdc75ef0b6",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "38f06e7c-abf5-40ff-8eb2-d4eef8e37643",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "f7977c7e-e7e2-4f93-9165-a7197f766291",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder prep"
            },
            {
                "id": "96779782-c46e-4363-b63d-3391efb20a39",
                "name": "Push Up W/O",
                "sequence": 6,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "e1f404bc-fc45-430f-990a-c79c145a2b5e",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "6a9b3ea3-2e01-4942-b075-dc8e5e868095",
                "name": "Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Max (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "5cbeae0f-35fc-4f07-9475-b95861cbf0d5",
                "name": "KB RDL",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "6c028a4f-b878-4b58-839a-f5e4431c01c1",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "fb0dc510-2319-4046-9f93-6af758a47d23",
                "name": "Cal Row",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "30",
                "notes": "2 rounds total"
            },
            {
                "id": "60d82c14-e19e-4c81-ad3f-47068a9f629c",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "30",
                "notes": "2 rounds total"
            },
            {
                "id": "a5a4622e-e10b-457a-aff0-1269169b6cae",
                "name": "Sit Ups",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "30",
                "notes": "2 rounds total"
            },
            {
                "id": "b25172d6-264d-4201-970f-9638326e781c",
                "name": "Push Ups",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "30",
                "notes": "2 rounds total"
            },
            {
                "id": "7ca1422e-f5e5-45a6-b01f-b36c5f0fd730",
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
        "id": "9a1bfc03-dd81-45c4-a114-8ee273558ffb",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "74c25cd3-0296-42d9-9d21-4aeed77233b1",
                "name": "Monsters",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "b541688b-8a35-4d9b-b32c-90a942caee48",
                "name": "Banded Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "72a4c90d-dc0a-4e1a-9acb-53490fa87e18",
                "name": "Banded Squats",
                "sequence": 3,
                "notes": "Quad activation"
            }
        ]
    },
    {
        "id": "8fadf710-ef65-4a31-ac7a-286532ae1903",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "daf4b323-40da-432d-9a71-54add02010b4",
                "name": "Quad Pull + Hinge",
                "sequence": 1,
                "notes": "Quad/hip prep"
            },
            {
                "id": "bd7028d1-5ba7-4f70-913d-a9cedb264b27",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "ab025b39-752b-4b30-897e-67e91b829dbe",
                "name": "PVC Passover",
                "sequence": 3,
                "notes": "Shoulder mobility"
            },
            {
                "id": "30b8a4f6-dccd-4a3b-9b0b-15c30fdfccb7",
                "name": "Push Up W/O",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "464d1a64-4448-4798-a55a-ae45602be62b",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "d86caf5b-50b1-42dd-9794-7cf7f40245ec",
                "name": "Pigeon",
                "sequence": 6,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "29ea01ed-0e31-493c-b0c9-21356f6f6246",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "21940aad-b7a7-4283-b41c-2e62e0a2d80b",
                "name": "Chin Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Bi/Lat Stretch between sets"
            },
            {
                "id": "5b5d5aa2-1d01-4fbe-8a4d-d0a333864cea",
                "name": "SL DL",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "15baac15-e207-4f82-ad68-8c4e526764e0",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "9daa7803-02e3-47fd-82f9-c4c5be19d4ef",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "250m"
            },
            {
                "id": "d2f6a6c9-b0df-4e7a-b1a4-a7bd985ecbc3",
                "name": "Split Squat",
                "sequence": 2,
                "prescribed_reps": "8e"
            },
            {
                "id": "8491d7de-a5de-4347-96d9-495f5fbd9b0b",
                "name": "Sit Ups",
                "sequence": 3,
                "prescribed_reps": "15"
            },
            {
                "id": "daa67d07-0697-4dc7-a121-7c17d76fe83f",
                "name": "TRX Row",
                "sequence": 4,
                "prescribed_reps": "12"
            },
            {
                "id": "c0da8f3d-3b1a-4df8-9349-e5a7b811bcd7",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "250m"
            },
            {
                "id": "6fe504bc-3e56-4a43-8416-e4ad6919b03f",
                "name": "Thrusters",
                "sequence": 6,
                "prescribed_reps": "15"
            },
            {
                "id": "4cd39211-b6e7-4be2-9efd-939e62522c36",
                "name": "Starfish",
                "sequence": 7,
                "prescribed_reps": "10e"
            },
            {
                "id": "f2bcbc17-a61a-4675-8000-5fe4f6863dc6",
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
        "id": "5d9c223a-373c-4b19-8651-1b8ede054739",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "c03e5fbf-7e33-48f0-b91a-fcfc2e66ba21",
                "name": "Row",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "3ae79eeb-e069-4ead-8639-2a1c5c5b3292",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "64e218d9-523a-4894-9019-374108d4f89a",
                "name": "Sit Ups",
                "sequence": 3,
                "notes": "Core activation"
            },
            {
                "id": "b4d52f29-539e-47ac-a49e-ff13326c28c4",
                "name": "Push Ups",
                "sequence": 4,
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "18c3c816-1154-4290-9090-d7e3ec34fcf5",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "9197fe1c-54c5-40ad-b286-d1fae521b2d1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "ad2e3a6f-121f-41d4-b3f9-28a5eca5684a",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "eea268e6-366a-405a-b673-2bea6a3ea0d9",
                "name": "Hi Touch/Lo Touch",
                "sequence": 3,
                "notes": "Dynamic stretch"
            },
            {
                "id": "47b269fa-9a16-436d-897f-d9fab0a8af5a",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "35bbc97c-31ca-41c6-85ea-49c7af542037",
                "name": "SL Rotation",
                "sequence": 5,
                "notes": "Core/hip mobility"
            },
            {
                "id": "8f756571-2e41-49c9-bd18-16f59815ae8b",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder prep"
            }
        ]
    },
    {
        "id": "775c6175-128f-485a-b5cb-0ff880bd856e",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "7ab7580d-03ff-49c0-a6dc-79149dbd8ddf",
                "name": "DB Bench",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: Pec Stretch between sets"
            },
            {
                "id": "4284256d-62bd-44ea-bfa8-44e46fcb5548",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "7c176da4-4d41-4520-a780-0e21c456f829",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "4f975051-7cb9-4058-8e52-606ac1bd7a67",
                "name": "KB Swing",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "e8fe0ea4-6d6a-45ed-a223-725bd023588c",
                "name": "Sit Ups",
                "sequence": 2,
                "prescribed_reps": "20"
            },
            {
                "id": "5af2fa84-7659-4a82-a1d9-ee7c9b5a51d0",
                "name": "OH Squat",
                "sequence": 3,
                "prescribed_reps": "10"
            },
            {
                "id": "f6839ee0-77c1-4435-a6f1-e86116399883",
                "name": "Dead Bugs",
                "sequence": 4,
                "prescribed_reps": "10e"
            },
            {
                "id": "04ff3541-d5ea-4b53-a7f7-7b9fe3d59828",
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
        "id": "380f47f9-a105-47b4-8406-ce042732e5de",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "e8056e30-edb3-4ca2-be3f-a165023ffb90",
                "name": "Row/Jump Rope",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "a4a28dec-ef00-4540-be99-4ec7acc0d18a",
                "name": "Bear Crawl (4-way)",
                "sequence": 2,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "190bfd94-ff45-4b0d-9e60-972eabe7a819",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "122d050b-f349-41d7-bf66-89fcb18b88cf",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "543234bc-8137-4bd8-bbeb-b45e1012ba8b",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "d039c70a-a18b-4be9-a2ea-c34b59c4b73b",
                "name": "Lunge + Reach",
                "sequence": 3,
                "notes": "T-spine mobility"
            },
            {
                "id": "6c69de50-5d1b-4c7d-969e-9e1798d84b76",
                "name": "Quad Pull",
                "sequence": 4,
                "notes": "Quad stretch"
            },
            {
                "id": "ac6d4e7e-385c-4b9d-86b1-4a072264381f",
                "name": "Good Mornings",
                "sequence": 5,
                "notes": "Hip hinge prep"
            },
            {
                "id": "ecd05f22-9fef-4fe6-9e39-60899a06f599",
                "name": "Fig. 8",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "da7caa32-3c9a-4246-8bca-52a1832b7537",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "b315d4aa-97b1-4020-9aa4-2fd5b2912577",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded/SL (RPE 5). Set 2: Banded/SL (RPE 6). Set 3: Banded/SL (RPE 6)"
            },
            {
                "id": "54f958f8-520e-433e-8966-41fca57c6cd9",
                "name": "SL Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "23a192ac-ecac-40e2-8255-2a9eb3437fbf",
                "name": "\u00bd Kneel SA Press",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "76011d44-8eb2-470a-9116-20fd3533447c",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "020a2d16-569b-4cee-818c-f299255c01f9",
                "name": "Goblet Squat",
                "sequence": 1,
                "prescribed_reps": "10-12"
            },
            {
                "id": "d48687e5-06c1-4faa-a6a8-9aa1fd78b685",
                "name": "BOSU Mtn Climb",
                "sequence": 2,
                "prescribed_reps": "10-12e"
            },
            {
                "id": "e6bf0acd-be3c-4da2-a463-5909a8982f9d",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_reps": "10-12"
            },
            {
                "id": "329a6e21-872d-4520-93a3-93b6af2b28c8",
                "name": "Med Ball Tap",
                "sequence": 4,
                "prescribed_reps": "10-12e"
            },
            {
                "id": "3b619956-e591-45de-976b-53e7503f1dd8",
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
        "id": "249f97c0-d3b9-4f45-82cd-5e01b0cc009d",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "b838117c-3d0e-4a77-89be-ebd2d36f29db",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "df714e76-4d51-48b6-b168-5e4bede00783",
                "name": "Rear Lunge w/ Reach \u2191",
                "sequence": 2,
                "prescribed_sets": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "0ce08463-e18b-450e-9012-58907870ced5",
                "name": "Lateral Squat",
                "sequence": 3,
                "prescribed_sets": 2,
                "notes": "Adductor mobility"
            }
        ]
    },
    {
        "id": "3040fa72-5a2a-478f-9675-a4a2cb8f800c",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "5bb55265-953b-4478-a452-f29840ac1ee2",
                "name": "Quadruped Trunk Rot.",
                "sequence": 1,
                "notes": "10/10 - T-spine mobility"
            },
            {
                "id": "d69456b3-4085-45b6-a563-a2d87a843a94",
                "name": "4 Point Bridge w/ Alt. Leg Extension",
                "sequence": 2,
                "notes": "10/10 - Core stability"
            },
            {
                "id": "d0bc7186-7a2d-4c92-8315-317c234dc851",
                "name": "Stick Figure 8",
                "sequence": 3,
                "notes": "5/5 - Shoulder mobility"
            },
            {
                "id": "0e3f3128-8305-446d-bffb-10c91a87c2c7",
                "name": "Good Morning w/ Rot. hold",
                "sequence": 4,
                "notes": "5/5 - Hip hinge/rotation"
            },
            {
                "id": "8d47e51a-ead2-44f1-8395-2bb6833e8028",
                "name": "Band Face Pulls",
                "sequence": 5,
                "notes": "15 - Rear delt activation"
            },
            {
                "id": "f35de216-44df-4863-9dbf-d3598ba11c46",
                "name": "SA Band Press",
                "sequence": 6,
                "notes": "10/10 - Shoulder stability"
            },
            {
                "id": "6dda0351-58bc-463d-ab2b-4291c428b6a4",
                "name": "Band Straight Arm Lat Pulldown",
                "sequence": 7,
                "notes": "10 - Lat activation"
            }
        ]
    },
    {
        "id": "7ecb5bc9-d709-47c6-a65a-964e7ee20393",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "e9d2cca3-b55b-4c3b-b75f-b9cab21414e7",
                "name": "Flat DB Alt. Press \u2192 Double Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 90 sec between sets Accessory: Wall Sit w/ Wall Angels x 5 between sets"
            },
            {
                "id": "c911109f-f72d-4cbf-bc40-9f18964355dd",
                "name": "Turkish Get Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "3/3",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 8). Set 3: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: Lat/Tri Stretch :15/:15 between sets"
            }
        ]
    },
    {
        "id": "0caba6d2-df44-492e-ab4c-3746f843527e",
        "name": "Conditioning - 4 Rounds / 10 min Cap",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "7a73d2d0-af26-43c5-ad60-bb6eeb94f0f8",
                "name": "Pull-ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "4 rounds total"
            },
            {
                "id": "6cba745c-206d-401b-bc72-51adb82c652c",
                "name": "Box Jumps or Step-ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "16",
                "notes": "4 rounds total"
            },
            {
                "id": "c758f621-15fa-4af4-82ee-a6a93cd89038",
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
        "id": "16f14ddc-4ff8-4678-b72e-5a168d40d70d",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "276072b9-1f0a-4c68-8c9a-3d356eb679f2",
                "name": "Quick Step Ups",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "bf1bda4d-2e3d-414c-9361-b3f2dd3743ee",
                "name": "Quick Lat. Step Ups",
                "sequence": 2,
                "notes": "Lateral cardio"
            }
        ]
    },
    {
        "id": "32ea27f2-7a5f-45be-976e-9a0733b0b5c4",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "bf8d8413-aebf-4d49-b5b2-e7355a505e81",
                "name": "Stick Rotations",
                "sequence": 1,
                "notes": "20x - T-spine mobility"
            },
            {
                "id": "95e08f9a-2e09-4922-8d0b-a6563f021c65",
                "name": "Stick Good Mornings",
                "sequence": 2,
                "notes": "10x - Hip hinge prep"
            },
            {
                "id": "281f3d4e-f407-47f9-a9f1-55d9761609e5",
                "name": "Stick Sumo Back Squat",
                "sequence": 3,
                "notes": "10x - Sumo stance prep"
            },
            {
                "id": "b895a849-9ae1-421e-b071-aa08d0bad337",
                "name": "Stick OH Squat",
                "sequence": 4,
                "notes": "10x - Shoulder/hip mobility"
            },
            {
                "id": "dae78179-df92-4352-be05-3ea7319bd346",
                "name": "Walking Leg Cradle",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "817f424c-3ccf-4385-9cdd-22b6e6c2fa42",
                "name": "Walking Side Lunge",
                "sequence": 6,
                "notes": "Adductor mobility"
            },
            {
                "id": "83f58c0a-1997-4fd3-b607-f84c881dcee7",
                "name": "Walking Rear Lunge w/ Reach Back",
                "sequence": 7,
                "notes": "T-spine/hip mobility"
            }
        ]
    },
    {
        "id": "d8e61d27-b10d-41f2-8f49-c1c8f8b5af09",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "5aa362d1-0750-4146-8eca-5cd22821f90c",
                "name": "Sumo Deadlift (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Set 5: Max (RPE 9). Rest: 2-3 min between sets Accessory: Seated Groin Stretch + SL RDL Balance between sets"
            },
            {
                "id": "39181740-3856-4e2b-9a4f-18f879dba0f2",
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
        "id": "563c825c-16dd-4af2-bb9b-a0a815879cd5",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "62394d3a-b329-459e-8281-f49c38c07f88",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "3313ceb1-9224-420c-b296-de9b51d9e954",
                "name": "Mountain Climbers",
                "sequence": 2,
                "notes": "Core/cardio"
            },
            {
                "id": "5b1de421-ca2b-4020-9e19-ad9a6b3111a0",
                "name": "\u00bd Kneel Band Chop",
                "sequence": 3,
                "notes": "Core rotation"
            }
        ]
    },
    {
        "id": "4be93676-187a-4bfa-9762-c83605822441",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "999652da-e924-46f5-af4d-9a42f99bb49f",
                "name": "Toy Soldier",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "9c15ddcd-712a-4b7d-a45c-717128194710",
                "name": "High Knee March",
                "sequence": 2,
                "notes": "Hip flexor prep"
            },
            {
                "id": "fe751b9e-0e3d-4f02-b8f4-a3388c72ec45",
                "name": "High Knee M-Skip",
                "sequence": 3,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "24ed8f29-1e8f-4abd-9b52-fc138152d589",
                "name": "Slow Backpedal",
                "sequence": 4,
                "notes": "Hip/hamstring"
            },
            {
                "id": "60689fc5-db47-4150-bd0b-64a6cc7fb0d8",
                "name": "Backpedal/Sprint",
                "sequence": 5,
                "notes": "Speed work"
            },
            {
                "id": "50319070-c8e0-4d71-a5c8-575d47c6eaf8",
                "name": "Crisscross Jumping Jack",
                "sequence": 6,
                "notes": "20x - Cardio"
            },
            {
                "id": "c2e3ddbf-f12b-4e8c-a85b-ab80459897a9",
                "name": "Band Angled Pull Apart",
                "sequence": 7,
                "notes": "15/15 - Rear delt"
            },
            {
                "id": "bce5580c-eca9-4bd7-8dbf-c4be8d410469",
                "name": "Band OH Pull Apart",
                "sequence": 8,
                "notes": "15x - Upper back"
            },
            {
                "id": "1b4dfee3-40d3-44bd-96e8-2fad8326234f",
                "name": "Band OH Rear Lunge",
                "sequence": 9,
                "notes": "5/5 5\"hold - Stability"
            },
            {
                "id": "2d6ac43f-6402-4485-b21c-753b4aeee539",
                "name": "Band OH Squat",
                "sequence": 10,
                "notes": "10x - Shoulder/hip mobility"
            }
        ]
    },
    {
        "id": "6d7f8c26-dc30-4b03-b000-17d41b6e341b",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "a658e80d-7a60-4660-ad31-a6381a1d93e2",
                "name": "Split Squat DB Curl to Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Hip Flexor to Calf/HS Stretch 5/5 between sets"
            },
            {
                "id": "ea483afe-ce04-45a8-94b6-28b165c5c77c",
                "name": "Loaded/Unloaded Push-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8/8-12",
                "notes": "Set 1: Loaded/Unloaded (RPE 6). Set 2: Loaded/Unloaded (RPE 7). Set 3: Loaded/Unloaded (RPE 7). Set 4: Loaded/Unloaded (RPE 7). Accessory: Quadruped Trunk Rotation 8/8 between sets"
            }
        ]
    },
    {
        "id": "f8572514-ba98-4506-ae2c-004f11ec6ef1",
        "name": "Conditioning - 12'' EMOM",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "c7129af2-b15e-4a1a-a623-a998825f05cf",
                "name": "Battle Rope 30\"",
                "sequence": 1
            },
            {
                "id": "a2111550-2f2b-446a-a808-d01861d9ad7a",
                "name": "DL 15x",
                "sequence": 2
            },
            {
                "id": "c1aaf09f-0c85-429d-92e7-83216d9669c5",
                "name": "Jump Rope 30\"",
                "sequence": 3
            },
            {
                "id": "b6984b89-956f-46e0-abbd-26fb98a27fbe",
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
        "id": "7c9337d9-e36e-45e3-854a-b4f576cb26bf",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "a5cfecc5-182e-4917-9661-4728ed41670c",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "c1390d68-c7de-44b5-8ed1-d54474d4d86d",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "9c0364c6-d4ad-403f-af98-0e3d71d6c503",
                "name": "Side Slide w/ Arm Swing",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "1a8b5452-4f26-45da-8883-290568cec8b7",
                "name": "Lateral Plank Walk",
                "sequence": 2,
                "notes": "Core/shoulder"
            },
            {
                "id": "0bfcc514-2da3-4d55-b6fa-37b14e7b3632",
                "name": "Lunge w/ Palm to Instep Rot.",
                "sequence": 3,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "33619221-04d3-42f5-8614-050ca4739cc9",
                "name": "Carioca",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "a3181b4a-6710-433a-84d8-be10376b7ef4",
                "name": "A-Skip",
                "sequence": 5,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "c8982e26-f3e0-4d4b-8bfb-5e0ce19a3e6b",
                "name": "Lateral A-Skip",
                "sequence": 6,
                "notes": "Lateral movement"
            }
        ]
    },
    {
        "id": "d6085d94-1af7-457c-ada3-7028f1e7408f",
        "name": "Movement Prep (w/ Plates)",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "e3a0c569-3a22-4685-b2de-af6624ed3d6a",
                "name": "Neutral Arm Raise w/ 3 sec. Lower",
                "sequence": 1,
                "prescribed_reps": "10x",
                "notes": "Shoulder stability"
            },
            {
                "id": "cabe6d5a-d129-40b7-be96-bea4098ee98a",
                "name": "Bent Scap Retraction w/ Forward Arm Raise",
                "sequence": 2,
                "prescribed_reps": "10x",
                "notes": "Upper back"
            },
            {
                "id": "92c64d36-372f-46d5-9413-680ba93c312a",
                "name": "External Rotations w/ Press",
                "sequence": 3,
                "prescribed_reps": "10x",
                "notes": "Rotator cuff"
            },
            {
                "id": "7ee76493-7c62-48de-bd23-11072c42ab67",
                "name": "Rear Delt Fly",
                "sequence": 4,
                "prescribed_reps": "10x",
                "notes": "Posterior shoulder"
            },
            {
                "id": "e1fa7b89-02a2-4aed-84d6-e1cbf6652732",
                "name": "TRX Fallouts",
                "sequence": 5,
                "prescribed_reps": "10x",
                "notes": "Core stability"
            }
        ]
    },
    {
        "id": "ff3e0743-4853-4593-9ca0-21f80437e82c",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "3266d325-4655-41ad-8d99-557577ff417d",
                "name": "Neutral Grip DB Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 7). Rest: 90 sec between sets Accessory: Sidelying Trunk Rotation x 5/5 between sets"
            },
            {
                "id": "6febac76-c101-4ce7-b189-88ad68e90fc9",
                "name": "Strict Pull-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8-12",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Banded Lat Stretch x :20/:20 between sets"
            }
        ]
    },
    {
        "id": "d490c8bd-5430-401e-a21f-45b86f23b39d",
        "name": "Core Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "0e64a6fa-a793-42b0-8d3c-cf622254b3a2",
                "name": "Palloff Press",
                "sequence": 1,
                "notes": "Anti-rotation"
            },
            {
                "id": "e4e91c7c-1626-403b-9621-caf659db7577",
                "name": "Bar Rotations",
                "sequence": 2,
                "notes": "Rotation"
            },
            {
                "id": "c2c53a9b-49c6-4518-a286-8a65de5e741f",
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
        "id": "f7d7249e-f0f1-4ab6-95f6-3c8afc3d55fb",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "56611f88-ffaf-408c-9c2d-3ce6b8a70d0e",
                "name": "Row",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "cd5f8400-4096-4346-a339-1d6097cb6a59",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "7659efee-966e-4ffd-8381-5ae3b0927504",
                "name": "Carioca",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "3cdb340b-d76a-4553-841d-3b164a3fc486",
                "name": "Lunge w/ Palm to Instep",
                "sequence": 2,
                "notes": "Hip/T-spine"
            },
            {
                "id": "9550f8b1-0134-45e2-b291-2a205b8ebb3c",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "7232e551-8e64-48c9-acae-5433cf7c869f",
                "name": "Quad Pull + Hinge",
                "sequence": 4,
                "notes": "Quad/hip prep"
            },
            {
                "id": "4661f47a-6fb3-41c6-a8b2-9536069e4591",
                "name": "A-Skip",
                "sequence": 5,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "29140d4e-8f90-437a-be92-fdac13292308",
                "name": "Lateral A-Skip",
                "sequence": 6,
                "notes": "Lateral movement"
            },
            {
                "id": "881c2571-6a25-476e-bce7-31453e3ba917",
                "name": "Updog \u2192 Downdog Flow",
                "sequence": 7,
                "notes": "Full body mobility"
            },
            {
                "id": "120c908a-083d-4af2-aa29-3a85d3cf16b3",
                "name": "Pigeon",
                "sequence": 8,
                "notes": "Glute/hip stretch"
            }
        ]
    },
    {
        "id": "3d7f61e7-980d-4e32-ad65-434d4c1c6226",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "7ac5a698-b3e8-409a-a67e-e2c41d2d5ac1",
                "name": "Strict Chin-Ups",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Set 5: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch / Forearm Stretch between sets"
            },
            {
                "id": "8d31560d-d311-447e-86fa-f8de05872195",
                "name": "SA DB Bench",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10/10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: TRX Pec Stretch between sets"
            }
        ]
    },
    {
        "id": "fa10a4dd-4fec-4379-b0e6-3eb0217bd9f7",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "f0e59693-9c93-43b0-bfbd-5fa857cb8f87",
                "name": "TRX/Ring Row",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "4 rounds total"
            },
            {
                "id": "b538d8ef-edae-4ace-9cc8-68e5fbc2c408",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "18 total",
                "notes": "4 rounds total"
            },
            {
                "id": "1e4a1b6f-1499-42fe-9678-439be56c56f6",
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
        "id": "171d5ac0-869b-4475-8c37-64531974f977",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "ac8998f0-7479-47f8-9d7a-c19ee848a14b",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "bfb567d1-0998-4c7e-98f9-f25be80299c6",
                "name": "Rear Lunge Reach Up",
                "sequence": 2,
                "prescribed_sets": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "f5828b57-951b-4cd2-ac78-bf15acc72783",
                "name": "Push-Ups",
                "sequence": 3,
                "prescribed_sets": 2,
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "2623f559-1881-4650-b7dc-d4f6a09ab1e2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "e6e44ae8-270b-4635-8e6d-a1d53e0f0ecc",
                "name": "Knee Hug",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "71e78369-ffa1-4a95-8b6d-b8b0fd252fbc",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "1651fbc3-f927-48ce-9abb-8a6ecf875819",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "57472453-dc60-427b-bca1-4fb4a3993bf5",
                "name": "Lateral Shuffle",
                "sequence": 4,
                "notes": "Lateral movement"
            },
            {
                "id": "71b90fba-07ef-4c61-911f-173ddf006226",
                "name": "Backpedal",
                "sequence": 5,
                "notes": "Hip/hamstring"
            },
            {
                "id": "5721950c-b229-486b-b226-6e9f63616a17",
                "name": "A-Skip",
                "sequence": 6,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "cca44fc5-5e8c-4180-902b-7bb722e9687d",
                "name": "Bushwackers",
                "sequence": 7,
                "notes": "Full body"
            },
            {
                "id": "a6bc2820-aa3a-4868-8460-9c8eea2f3204",
                "name": "High Bear Crawl",
                "sequence": 8,
                "notes": "Core/shoulder"
            },
            {
                "id": "4fc9fad0-63c4-462f-ad05-602c1fb349b3",
                "name": "Band Work",
                "sequence": 9,
                "notes": "Activation"
            }
        ]
    },
    {
        "id": "db7229f4-a6db-4e48-9621-388140778bef",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "e32b6a9a-121d-4d33-85f4-2d755cd51206",
                "name": "KB/DB Bench Rows",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate+ (RPE 7). Rest: 60-90 sec between sets Accessory: Banded Lat Stretch between sets"
            },
            {
                "id": "7ed88129-cd92-4657-8d40-246dcf887dcb",
                "name": "Seated DB Curls",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12-15",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 45-60 sec between sets Accessory: Band Tricep Pressdown 15x between sets"
            }
        ]
    },
    {
        "id": "027c2eb7-d2d4-4213-bba5-a3067e9fb0f8",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "401e608d-79f6-4d6c-8009-e35f37f2144e",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "50x",
                "notes": "4 rounds total"
            },
            {
                "id": "c13bf7a7-03d5-4e33-914c-32fe60b72b94",
                "name": "KB Push Press",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12x",
                "notes": "4 rounds total"
            },
            {
                "id": "f4dc26c8-a043-4cd6-8a57-ee728ac6d560",
                "name": "Starfish",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "16x",
                "notes": "4 rounds total"
            },
            {
                "id": "c51648bd-a98d-4ff5-a4c9-afd746edaf05",
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
        "id": "7c7dddd8-4228-4395-9722-f280858b774a",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "5b92eaf0-85a5-4037-803a-80261366301d",
                "name": "Row",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "ad203019-ed21-4741-8a55-e8764eed5b20",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "a7cef367-4282-46c8-b7a2-e75032d15926",
                "name": "Leg Cradle",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "0cb50584-9547-46e1-bbd9-95de14eabfc9",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "78b62e60-496b-4cbf-87cb-3dce929573b6",
                "name": "Quad Pull + Reach Up",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "9173f7d9-e1ff-40bc-b170-04c4951d7f47",
                "name": "TRX Row",
                "sequence": 4,
                "notes": "15x - Upper back activation"
            },
            {
                "id": "f7191f44-83f4-443d-bd5f-25adc728e13a",
                "name": "Push Up",
                "sequence": 5,
                "notes": "15x - Upper body prep"
            }
        ]
    },
    {
        "id": "23d967b7-b4f2-4f40-a48b-ef71eae1908d",
        "name": "With Light KB",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "8f598f5f-af34-458f-8089-2bddcdfe705a",
                "name": "Lunge w/ Twist",
                "sequence": 1,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "0fb07bef-7c91-45e5-9129-7d40ca1b5ec6",
                "name": "Lateral Lunge",
                "sequence": 2,
                "notes": "Adductor mobility"
            },
            {
                "id": "0eadecd9-dfcd-4f28-9838-df5fa376ead7",
                "name": "Rear Lunge KB OH",
                "sequence": 3,
                "notes": "Shoulder/hip stability"
            },
            {
                "id": "3d101529-2c5a-43b2-a705-1ee64c8f2e8d",
                "name": "Goblet Squat",
                "sequence": 4,
                "notes": "3 sec pause - Squat prep"
            }
        ]
    },
    {
        "id": "7079995f-7c02-4b70-87d9-f389a70a98e2",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 4,
        "exercises": [
            {
                "id": "eee59c9f-76f3-4ae9-99c1-86d332cc6a5c",
                "name": "Good Morning",
                "sequence": 1,
                "prescribed_reps": "10x",
                "notes": "Hip hinge prep"
            },
            {
                "id": "a862f68a-21ce-4f57-9291-197ad93ef18d",
                "name": "Back Squat",
                "sequence": 2,
                "prescribed_reps": "10x",
                "notes": "Movement pattern prep"
            }
        ]
    },
    {
        "id": "b6f61ede-2c16-4042-93c3-c1e8ea268853",
        "name": "Strength",
        "block_type": "push",
        "sequence": 5,
        "exercises": [
            {
                "id": "c3ceae86-ee8f-44ae-bc78-173959aeacff",
                "name": "Back Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: Foot Elevated Hip Flexor Stretch + Pigeon between sets"
            }
        ]
    },
    {
        "id": "17f2cc21-e660-4a76-82cb-207c180d8360",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 6,
        "exercises": [
            {
                "id": "6fc25b10-20ec-4331-8ff6-8d26a0afc63f",
                "name": "Push-Ups",
                "sequence": 1,
                "prescribed_reps": "10x"
            },
            {
                "id": "20472d64-8861-426b-963d-d38b9efd5c2e",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_reps": "15x"
            },
            {
                "id": "021be8d0-a568-4f7d-8459-adf82067939c",
                "name": "Stationary Loaded Lunge",
                "sequence": 3,
                "prescribed_reps": "20x"
            },
            {
                "id": "490bc2ca-9d69-44ec-8078-2a31ae3bf15c",
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
        "id": "d07c62a1-8fae-4514-8e1d-7f9101308ea1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "c65e9acd-07a9-445b-8dbb-3f4daeee353a",
                "name": "Jump Rope",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "29b805f5-f941-4182-b9cf-7293e6294ee4",
                "name": "SA KB Swing",
                "sequence": 2,
                "notes": "Power activation"
            },
            {
                "id": "6943342c-5a3b-480d-afd2-5e2bd64443a4",
                "name": "Goblet Squat",
                "sequence": 3,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "3e2cdaca-2940-4fb5-8968-d2997655b4be",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "b9fb589b-2156-4599-b789-28d812a5c458",
                "name": "Carioca",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "3e8019d0-f00f-4577-9cec-065711070f72",
                "name": "High Knee March",
                "sequence": 2,
                "notes": "Hip flexor prep"
            },
            {
                "id": "2179c2e7-428a-425a-9122-0b4dd8d004cb",
                "name": "Alternating Shuffles",
                "sequence": 3,
                "notes": "Lateral movement"
            },
            {
                "id": "dd07a23b-aa74-4966-a224-04d318a4996c",
                "name": "Rear Lunge + Reach Up",
                "sequence": 4,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "8f95c9ae-53d0-4b3b-a09e-228fa829291f",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "c24b49da-e418-4d32-96df-77883fc0378d",
                "name": "Rig: Swings, Sumo Squat",
                "sequence": 6,
                "notes": "Hip/shoulder prep"
            }
        ]
    },
    {
        "id": "422b9873-de25-4524-97c3-3748617ffd9e",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "7851ab4e-d37f-471e-9043-d8fc4bbf5cde",
                "name": "RDL",
                "sequence": 1,
                "prescribed_reps": "10x",
                "notes": "Hip hinge pattern"
            },
            {
                "id": "0d1a7e88-943c-4faa-8eca-3bba32dbcb17",
                "name": "Bent Row",
                "sequence": 2,
                "prescribed_reps": "10x",
                "notes": "Upper back activation"
            },
            {
                "id": "0f417563-69bd-4456-88f4-af243c851d33",
                "name": "Traditional Deadlift",
                "sequence": 3,
                "prescribed_reps": "10x",
                "notes": "Movement prep"
            }
        ]
    },
    {
        "id": "c8f74322-4385-4f6a-aade-2b9cc8550282",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "ecd3c102-145e-44dd-8a89-b1170fa9a275",
                "name": "Traditional Deadlift",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Set 5: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: Supine Hip Rotation between sets"
            },
            {
                "id": "7dc01cf2-3844-489c-936e-e1c4db461686",
                "name": "Seated DB Shoulder Press",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8-12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Birddog 10x w/ 2 sec pause between sets"
            }
        ]
    },
    {
        "id": "a71be6fc-7056-4dd4-be5d-1c15d379e4f3",
        "name": "Conditioning - Chipper",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "ecfb21bb-e4f7-4dca-8b70-c99c1d997c5c",
                "name": "Jump Rope",
                "sequence": 1
            },
            {
                "id": "55957b20-e82a-4e01-a738-efe77098c012",
                "name": "Sit-Ups",
                "sequence": 2
            },
            {
                "id": "2aeb745b-6c2e-4610-a1d6-f5dc42b8a910",
                "name": "SA KB Swing",
                "sequence": 3
            },
            {
                "id": "98692cff-9c12-4b99-9911-6fc90309e464",
                "name": "Air Bike",
                "sequence": 4
            },
            {
                "id": "632308cf-8d07-4e82-ae39-9f14220cd8cd",
                "name": "Wall Ball",
                "sequence": 5
            },
            {
                "id": "a6532e49-5599-4617-92b1-fb4e8318acac",
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
        "id": "02740945-3b21-47d5-a38e-ecc7728124f4",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "fdee86b3-33e1-410f-8449-48be2eb6fc0e",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "2cc427c7-bc1c-4d00-b5cb-0d3a40d15d26",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "1a487135-dab8-48aa-a4b1-88d79856a427",
                "name": "Knee Hug",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "b92e58ef-e3ea-41af-9ae3-13a4b9be8ab1",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "3e42dee2-c308-400e-8ec6-7eaa71676b75",
                "name": "Lateral Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "fb2a34e3-5ba6-43de-8a43-fd1445fc9b5f",
                "name": "Bushwackers",
                "sequence": 4,
                "notes": "Full body"
            },
            {
                "id": "869de459-af34-42a8-8713-5e2a37301175",
                "name": "Side Slide w/ Arm Swing",
                "sequence": 5,
                "notes": "Lateral movement"
            },
            {
                "id": "eac6b816-b4b8-4e75-97dd-5e745d7cb954",
                "name": "Bear Crawl",
                "sequence": 6,
                "notes": "Core/shoulder"
            }
        ]
    },
    {
        "id": "1773b715-4a4b-4966-8f0b-9346defd82cf",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "b385f61b-5866-4397-80e0-39492da6300a",
                "name": "Face Pulls",
                "sequence": 1,
                "prescribed_reps": "15x",
                "notes": "Rear delt/rotator cuff"
            },
            {
                "id": "8afce145-b26c-4570-9fc9-f484e8b3a6bd",
                "name": "SA Press",
                "sequence": 2,
                "prescribed_reps": "15/15x",
                "notes": "Shoulder activation"
            },
            {
                "id": "85a2173b-59c9-4f1d-804a-e57886b1e5a3",
                "name": "Straight Arm Lat Pulldown",
                "sequence": 3,
                "prescribed_reps": "15x",
                "notes": "Lat activation"
            }
        ]
    },
    {
        "id": "8a424151-ecdb-4341-845e-08f5e925aeea",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "8321fd67-870f-4c78-a3de-b85e2f3dd0fc",
                "name": "DB Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 7). Rest: 90 sec between sets Accessory: Pec Stretch between sets"
            },
            {
                "id": "6ad84012-9a34-41f8-b287-1c5813ba9727",
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
        "id": "ea285520-3cbe-4df0-a8da-891db0b01314",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "1126b20d-4db0-4c15-bad3-4f67ddac0179",
                "name": "Row",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "a61e3d3d-5662-4487-bf7c-df7990d4bb9a",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "29a74e94-e809-4c7c-a3db-3b7f5947c14f",
                "name": "Alternating Side Shuffle",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "fdd0efdd-de04-4d4f-be97-729da3bd88db",
                "name": "Quad Pull + Reach Up",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "e9bf9afd-a0bb-42b7-a984-a8dbdcfaed9b",
                "name": "Carioca",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "f6199924-6b61-4f83-8617-d98996be04da",
                "name": "Lunge Palm to Instep",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "c7ca2dd8-5dd1-4a3b-8ec1-3a67209615d4",
                "name": "High Knee March",
                "sequence": 5,
                "notes": "Hip flexor prep"
            },
            {
                "id": "ae359c2c-8e77-414f-a9a4-05f336c490c4",
                "name": "Lateral Lunge",
                "sequence": 6,
                "notes": "Adductor mobility"
            },
            {
                "id": "117cfda3-a796-4dd4-9691-f771353c2613",
                "name": "Supine Leg Kick",
                "sequence": 7,
                "notes": "10/10 - Hamstring"
            },
            {
                "id": "3d53bc5b-a327-4592-8cee-f2bedc38f1d4",
                "name": "Supine Leg Swing",
                "sequence": 8,
                "notes": "10/10 - Hip mobility"
            },
            {
                "id": "faf15373-1bbb-4387-8e62-c34ff75b31b0",
                "name": "Seated Groin",
                "sequence": 9,
                "notes": "Adductor stretch"
            },
            {
                "id": "c1cc5f43-d37b-4e2c-ab35-e8d518d94fd8",
                "name": "Seated Forward Bend",
                "sequence": 10,
                "notes": "Hamstring/back"
            }
        ]
    },
    {
        "id": "6aeeb8aa-a9da-42ce-ad72-2077d4dc8f7c",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "7ba0f78d-1c75-4025-b190-7962943056a2",
                "name": "RDL",
                "sequence": 1,
                "prescribed_reps": "10x Slow",
                "notes": "Hip hinge pattern"
            },
            {
                "id": "65aab89f-854c-4513-aa5f-88bd4830a786",
                "name": "Bent BB Row Overhand",
                "sequence": 2,
                "prescribed_reps": "10x",
                "notes": "Upper back activation"
            },
            {
                "id": "f89694d8-e926-4ab0-96b7-9cd601c945b0",
                "name": "Sumo DL",
                "sequence": 3,
                "prescribed_reps": "10x",
                "notes": "Movement prep"
            }
        ]
    },
    {
        "id": "65a79f48-3735-4dee-b932-0b12ed7a50bb",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "5a0a0461-a57e-445c-aca2-a2185b120399",
                "name": "Sumo Deadlift (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Set 5: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Deep Squat Hold between sets"
            },
            {
                "id": "5ce6bec8-dd57-4318-ac25-6281e76c4595",
                "name": "Split Stance DB Curl to Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: 1/2 Kneel Hip Flexor/HS Stretch between sets"
            }
        ]
    },
    {
        "id": "ce81baf0-d00f-46ca-9de3-f2fd0e0492cc",
        "name": "Conditioning - 12 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "79b5ed00-9b76-4e97-8cc3-744937076903",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_reps": "30x"
            },
            {
                "id": "68aa05da-282a-4357-ba6d-1c2d1bdd8e81",
                "name": "Slamball",
                "sequence": 2,
                "prescribed_reps": "20x"
            },
            {
                "id": "28c29ffd-8635-4bf5-aa57-4f012530bb4c",
                "name": "TRX Row",
                "sequence": 3,
                "prescribed_reps": "15x"
            },
            {
                "id": "44b7f1b8-8cdd-4452-80e4-cc1e80dd190d",
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
        "id": "3325ed93-2c0e-417e-96f2-be6d19d8152e",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "2081f8de-ddd6-48bb-9360-323483f0cc25",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "50x",
                "notes": "Cardio activation"
            },
            {
                "id": "6001205b-a107-4f51-a21a-29912ff5379d",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "12x",
                "notes": "Upper back activation"
            },
            {
                "id": "019b3945-519d-4cd9-aab6-8143d6fdb511",
                "name": "Push-Ups",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "12x",
                "notes": "Upper body prep"
            },
            {
                "id": "c72d8a09-c3f6-4308-9295-2bb2f77394be",
                "name": "Air Squat",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "12x",
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "c84df907-c931-4d74-892b-af076600dee8",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "0596bba5-8252-4056-99d0-ce1f048099e4",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "b603cdac-fac7-47ba-a81a-ff7d152d88f7",
                "name": "High Knee March",
                "sequence": 2,
                "notes": "3 sec balance - Hip flexor prep"
            },
            {
                "id": "a0ecfcf3-a171-4cfe-9562-efabc7876b50",
                "name": "Butt Kicks",
                "sequence": 3,
                "notes": "Quad activation"
            },
            {
                "id": "5856f3fc-7a05-4d85-bb52-9ca7af89952a",
                "name": "Rear Lunge w/ Reach Up",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "3073051d-9b2d-4919-b47b-0e8d54ddf4ed",
                "name": "Leg Cradle",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "760ed8c2-f1b5-46cd-a1a8-23e087a260b0",
                "name": "Trunk Rotation",
                "sequence": 6,
                "notes": "20x - T-spine mobility"
            },
            {
                "id": "dd7840b9-e4aa-4439-b410-59c43e6be981",
                "name": "Good Morning",
                "sequence": 7,
                "notes": "12x - Hip hinge prep"
            },
            {
                "id": "a12eefa8-51ac-469a-b525-ad49688fae3b",
                "name": "Split Squat w/ Press",
                "sequence": 8,
                "notes": "6/6x - Full body prep"
            },
            {
                "id": "5c58f23f-5cb5-4a57-bdad-35af9f6ed3a9",
                "name": "OHS",
                "sequence": 9,
                "notes": "12x - Shoulder/hip mobility"
            }
        ]
    },
    {
        "id": "1b152ced-8876-42d2-b40a-fcc77e791cdd",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "541a2d8e-d479-470a-9775-9c782cf239b8",
                "name": "KB or DB Front Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 7). Rest: 90 sec between sets Accessory: 4 Point Bridge w/ Leg Ext. 10x between sets"
            },
            {
                "id": "cd9e6bcf-4ad2-410b-a57c-48c38490b8bb",
                "name": "DB Curls (Beach Season!)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 45-60 sec between sets Accessory: Band Tricep Pressdown 15-20x between sets"
            }
        ]
    },
    {
        "id": "42ba9d13-87e7-4067-83a8-62866f9eb970",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "190bd3ed-932b-426b-aef4-6adf899733ee",
                "name": "Jump Rope or DU''s",
                "sequence": 1,
                "prescribed_reps": "35x"
            },
            {
                "id": "f09487d6-b2b0-46b1-b26d-2b1ee61c59ae",
                "name": "KB Swings",
                "sequence": 2,
                "prescribed_reps": "25x"
            },
            {
                "id": "3ed99492-0fa2-47df-8a3b-e420dc764f7d",
                "name": "Pull-Ups or TRX Rows",
                "sequence": 3,
                "prescribed_reps": "15x"
            },
            {
                "id": "98f29f01-2c62-475a-90f4-39eb164167b8",
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
        "id": "64ece29f-2895-4ed0-a96b-eb14208e703e",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "f0a7c375-1c18-458f-b1dd-5668fd346f24",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "fbbe26ef-0f0c-4866-915a-812fe1cb541b",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "f1ff6502-a803-4569-8856-56307f628443",
                "name": "Knee to Leg Cradle",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "887db2ad-0dd9-4ede-8d95-6920d02d7e68",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "9348eff5-c1be-4859-9859-017df06878f9",
                "name": "Lunge w/ Palm to Instep",
                "sequence": 3,
                "notes": "Hip/T-spine"
            },
            {
                "id": "fbea07ea-adfb-4394-beb5-d0858b494b26",
                "name": "Carioca",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "f13dbac4-239c-4b7a-b668-6c9df277a3fa",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "9b06a724-59bb-4def-bebe-5a6edff9ce9f",
                "name": "Yoga Flow",
                "sequence": 6,
                "notes": "Pigeon/Updog/Downdog - Full body mobility"
            }
        ]
    },
    {
        "id": "d7909b19-a801-42ce-915c-e16eaf143311",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "47a85ddb-7f31-4b6f-84ff-d5f4333710dd",
                "name": "Landmine Thrusters",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Mountain Climbers 20x between sets"
            },
            {
                "id": "361e9efb-acb3-4ed9-889d-8db96fe3fad8",
                "name": "Landmine Rows",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Child''s Pose/Updog between sets"
            }
        ]
    },
    {
        "id": "cba141a0-27d4-44de-b6b6-de514bd5e25a",
        "name": "Conditioning - 5 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "58489b60-fc44-4d90-96cb-154d7569984c",
                "name": "Lateral Box Jumps",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10x",
                "notes": "5 rounds total"
            },
            {
                "id": "db1b9bd2-d3fe-4ea3-a0e0-129954e25bb9",
                "name": "HKTC/T2B",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "10x",
                "notes": "5 rounds total"
            },
            {
                "id": "5d1c54be-9893-4614-b204-2a595cfaa7b1",
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
        "id": "1a1fb172-0ddc-4880-82dd-4bb955285788",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "942fd197-b7ae-47dc-a5cf-eaad9e461d62",
                "name": "Air Bike",
                "sequence": 1,
                "prescribed_sets": 2,
                "notes": "Cardio activation"
            },
            {
                "id": "4c4e159d-7ce2-4013-848b-44211b6f7063",
                "name": "Jump Rope",
                "sequence": 2,
                "prescribed_sets": 2,
                "notes": "Cardio"
            },
            {
                "id": "330a1100-493a-4717-82cb-71b9a676cf60",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_sets": 2,
                "notes": "Full body activation"
            }
        ]
    },
    {
        "id": "af5ad2a4-f771-483d-8731-7bea5f2d03a5",
        "name": "Strength",
        "block_type": "push",
        "sequence": 2,
        "exercises": [
            {
                "id": "35bf53b4-7c45-4767-9c80-658cbbadc1ac",
                "name": "BB Strict Press to Push Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "5 strict + 5 push",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Wall Sit Wall Angels 10x between sets"
            },
            {
                "id": "f2aa13ca-d240-41e2-8038-245939e22757",
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
        "id": "a23f4d20-ea8f-4a96-9797-7b4cdb5a096e",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "51d9661a-5482-4b51-b922-03e105d7b0b2",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "e1ef839f-0a95-4448-b2ea-19bbde63cf4d",
                "name": "Back Lunge",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "17314d75-0d70-4f94-bfeb-7f735157b773",
                "name": "Shoulder Taps",
                "sequence": 3,
                "notes": "Core/shoulder stability"
            }
        ]
    },
    {
        "id": "19722d18-63ee-4751-bda0-987877f602d3",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "d01e669b-1105-41dd-be0a-b91765954690",
                "name": "Knee Hug to Quad Pull",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "f8a760e7-eeb4-4132-8d52-dc106aecaf5d",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "6f642468-f955-4951-b4be-edaa8400ea5e",
                "name": "Hip Openers",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "08b7a219-1de9-4e10-beac-5391cfd5d42a",
                "name": "SL RDL w/ Reach",
                "sequence": 4,
                "notes": "Balance/hamstring"
            }
        ]
    },
    {
        "id": "69bf5e66-f5fc-410e-9669-202b702eb51a",
        "name": "Track Series (with Plates or DB)",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "56db11b6-b518-4217-8942-46550e060cc0",
                "name": "Rear Lunge w/ Press",
                "sequence": 1,
                "prescribed_reps": "12x",
                "notes": "Full body"
            },
            {
                "id": "b6a9a846-ac00-4362-b919-82baff8f40da",
                "name": "Squat w/ Front Raise",
                "sequence": 2,
                "prescribed_reps": "12x",
                "notes": "Lower/shoulder"
            },
            {
                "id": "d6769b6b-b1c3-454c-a021-861a636ad38d",
                "name": "Bent Rear Delt Fly",
                "sequence": 3,
                "prescribed_reps": "12x",
                "notes": "Posterior shoulder"
            },
            {
                "id": "3e51c227-3271-40fd-b1ab-2bb0257f1856",
                "name": "Lateral Squat w/ Front Rack",
                "sequence": 4,
                "prescribed_reps": "12x",
                "notes": "Adductor/shoulder"
            }
        ]
    },
    {
        "id": "86cd4de2-9b9b-4db1-9621-edf609973ce2",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "8c2e7ecc-791c-48ba-9777-b62c8b87dfb4",
                "name": "Front Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Posted SL RDL 8/8 between sets"
            },
            {
                "id": "b4d7c908-c9cb-4470-ba8b-90ea71486e3e",
                "name": "Split Stance KB Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "8/8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: 1/2 Kneel Hip Flexor/Hamstring Stretch between sets"
            }
        ]
    },
    {
        "id": "8d9a978b-5625-49bd-b742-0da4f600149a",
        "name": "Conditioning - 3 Rounds (16 min Cap)",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "b6c4f59e-b822-4e2e-b189-f4ed2a618e75",
                "name": "Row 300m or Bike 750m",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "-",
                "notes": "3 rounds total"
            },
            {
                "id": "a62c2629-1261-45a0-9cfb-731c34d8e0bf",
                "name": "KB Swings",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "30x",
                "notes": "3 rounds total"
            },
            {
                "id": "4280d488-d18f-4160-b6df-ef8d9f0e0b23",
                "name": "Starfish",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "20x",
                "notes": "3 rounds total"
            },
            {
                "id": "979e18bc-6134-40eb-8951-7dec82d932fd",
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
        "id": "ece6a669-d9e5-45d1-b4e7-630fae2a7163",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "2c4c3a85-19fa-483c-84da-f01725ea0726",
                "name": "Lateral Low Step-Ups",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "50x",
                "notes": "Lateral activation"
            },
            {
                "id": "580c7d5e-699a-4d28-9c62-c5a18784713c",
                "name": "\u00bd Burpee",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "15x",
                "notes": "Cardio activation"
            },
            {
                "id": "702f7219-0a42-4d82-87d6-d57360120c9d",
                "name": "TRX Rows",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "10x",
                "notes": "Upper back activation"
            }
        ]
    },
    {
        "id": "c1f5e3b7-7be6-4070-a07e-0e0fb0a9375f",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "df07558a-8382-4b60-9e96-50fe43aad47a",
                "name": "High Knee March w/ 3 sec hold",
                "sequence": 1,
                "notes": "Hip flexor/balance"
            },
            {
                "id": "d4867304-a2f6-4bd6-b294-e5bd718ecd9c",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "a64c1130-0d73-44a4-a9c2-b0734a7b8975",
                "name": "Leg Cradle",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "d9aab015-8a56-4058-b71c-17c7e5493231",
                "name": "Lunge w/ Reach Up + Twist",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "b3819183-46a5-472a-a840-5bb9d970d981",
                "name": "Bear Crawl",
                "sequence": 5,
                "notes": "Core/shoulder"
            },
            {
                "id": "f38e3f2c-9c4d-4dfb-ae33-5ec611cc4558",
                "name": "Air Squat w/ 2 sec pause",
                "sequence": 6,
                "notes": "10x - Squat pattern"
            }
        ]
    },
    {
        "id": "20c1b028-72fa-4f2a-964b-3df982125231",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "f994d5b0-c834-47bc-8315-3fc1ff3a7d5c",
                "name": "Alternating DB Flat Press to Double DB Flat Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8/8 alt + 8 double",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Standing TRX Chest Stretch between sets"
            },
            {
                "id": "d5ee1d34-7c8b-4a25-803d-d5fe43211fe6",
                "name": "Farmers Walk",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Birddog 10x Slow between sets"
            }
        ]
    },
    {
        "id": "337cb834-55bc-4a06-8a28-cdcde43d04a4",
        "name": "Conditioning - 3-5 Rounds (10'' Cap)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "eb9c4121-97ce-444c-af40-8311bdb74691",
                "name": "Box Jumps",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "9x",
                "notes": "5 rounds total"
            },
            {
                "id": "347a4d4a-0390-4149-8f1d-35f999324c26",
                "name": "DB Thrusters",
                "sequence": 2,
                "prescribed_sets": 5,
                "prescribed_reps": "12x",
                "notes": "5 rounds total"
            },
            {
                "id": "6b72f461-e9a4-45f4-a67b-f9bb4da76c3c",
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
        "id": "28d14cc4-bf11-4c19-a97c-099842c551a5",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "77f6d4ec-5702-43d5-912e-56247583ad26",
                "name": "Row or Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "e90a40d6-c71e-4d69-8799-8eceb5d6bf57",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "c60f2c35-ca42-453d-aed6-88d0c825d7bb",
                "name": "Lunge w/ Palm to Instep",
                "sequence": 1,
                "notes": "Hip/T-spine"
            },
            {
                "id": "4ed96d58-a188-44a1-aed5-fa66407524ee",
                "name": "Slow Backpedal",
                "sequence": 2,
                "notes": "Hip/hamstring"
            },
            {
                "id": "d42f29db-d7d0-4fa3-bebd-95f70917c09c",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 3,
                "notes": "Lateral movement"
            },
            {
                "id": "40173da9-2840-4611-9c2c-d9baa606cc19",
                "name": "A-Skip",
                "sequence": 4,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "82351ef3-7d6c-4085-a551-4a57a29bf148",
                "name": "Butt Kicks",
                "sequence": 5,
                "notes": "Quad activation"
            },
            {
                "id": "4dc6890d-e85f-47f3-8854-5d0bbc1ebb73",
                "name": "Lateral A-Skip",
                "sequence": 6,
                "notes": "Lateral movement"
            },
            {
                "id": "06f3efba-9b4a-47f1-886b-988b1597d36c",
                "name": "High Knees",
                "sequence": 7,
                "notes": "Hip flexor prep"
            },
            {
                "id": "0875f2f7-dcd1-43f1-9ba5-88ebaadf13e2",
                "name": "High Knee Carioca",
                "sequence": 8,
                "notes": "Hip mobility"
            },
            {
                "id": "4cddf258-9632-4961-830a-c82c6cdb0659",
                "name": "Lateral Plank Walk",
                "sequence": 9,
                "notes": "Core/shoulder"
            }
        ]
    },
    {
        "id": "8ac11ec6-b617-41af-9d3a-0d24535e03f2",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "4fa626db-648b-4d01-a017-eb4a7fe8f9a5",
                "name": "Back Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Heavy (RPE 7). Rest: 2-3 min between sets Accessory: Quad Stretch + Calf Stretch between sets"
            },
            {
                "id": "a70feb3c-f20a-4e8e-86e1-f6b282122a00",
                "name": "DB Hammer Curl",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8-12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 60 sec between sets Accessory: Close Grip Push-Ups 10x between sets"
            }
        ]
    },
    {
        "id": "58f24785-9024-47c5-a527-622a349adfd8",
        "name": "Core Cashout - 3-4 Rounds",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "81a3eaac-b19d-41bf-a4b3-263e6e1d9237",
                "name": "BOSU Mtn Climbers",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "30x"
            },
            {
                "id": "840dfdec-f443-4b10-986d-570eabc1efc4",
                "name": "SL Glute Bridge",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10"
            },
            {
                "id": "e501abc0-fbde-404c-8603-dab93102de38",
                "name": "Russ. Twist or Partner Throws",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "20x"
            },
            {
                "id": "5a3c13f4-634d-4365-bb40-d52e92b23071",
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
        "id": "5f1e722a-bc7f-4740-bf82-b38dcbbf49d9",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "6ca1f3a4-82d7-42ba-b827-cd9dd8fc2672",
                "name": "Air Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "6515447e-444a-4692-ba1a-8eb1fd2e23a0",
                "name": "Step Up w/ High Knee",
                "sequence": 2,
                "notes": "Lower body activation"
            },
            {
                "id": "0506bfa0-675d-4319-ac24-753f407cf567",
                "name": "\u00bd Burpee",
                "sequence": 3,
                "notes": "Cardio"
            },
            {
                "id": "b5849bc5-db6f-4f0d-af99-80be27a85b0b",
                "name": "Push Ups",
                "sequence": 4,
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "3ea1c4b6-e3c2-4f1f-ad2e-9d16c3538539",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "283edeaf-16e7-4db7-91e0-7078d5d3e7aa",
                "name": "Side Shuffle w/ Swing",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "27ce36c5-2b4e-4847-9318-54d91fa60e61",
                "name": "Knee Hug w/ Hip Opener",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "733da85a-92df-454e-8148-abe30ed0ece1",
                "name": "Quad Pull to Leg Cradle",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "051735de-68fd-41b7-8300-5eaaec6590aa",
                "name": "Walking Lunge w/ Twist",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "eb80be66-3145-4575-bdb1-0d57c11dde8b",
                "name": "Bear Crawl",
                "sequence": 5,
                "notes": "Core/shoulder"
            }
        ]
    },
    {
        "id": "5a2ddb6e-168f-4900-a730-18a88b255fde",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "8703d596-5a3a-44f1-8dbe-ad4550f44258",
                "name": "SA DB Chest Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8/8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Side Lying T-Rotations x5/5 between sets"
            },
            {
                "id": "30bffd2e-6bb1-4346-9317-dc56864425aa",
                "name": "Landmine Rotation",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60 sec between sets Accessory: \u00bd Kneel Lifts 4 x 8/8 between sets"
            }
        ]
    },
    {
        "id": "6cd76eb9-a095-4e0f-8061-3c9a83073f19",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "9be4f266-b486-4655-941d-8ae9439d1be9",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_reps": "30x"
            },
            {
                "id": "891e519c-bf20-431d-bf61-439c1ca58157",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_reps": "12x"
            },
            {
                "id": "ad0c3367-51fd-4f8e-8b36-85c8e24cdf89",
                "name": "Sit Ups",
                "sequence": 3,
                "prescribed_reps": "20x"
            },
            {
                "id": "23d42c93-0974-4c45-8895-2cea7056d745",
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
        "id": "88769b3f-b79f-43f2-b90a-f2e47d7acd48",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "d0881f7e-ba58-44e1-9eb6-27c0eda74d1d",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "6b9d5033-c0e9-438e-a24f-a2190eb03741",
                "name": "Stationary Lunge",
                "sequence": 2,
                "notes": "Hip/leg prep"
            },
            {
                "id": "5e9fa2b4-8c08-4353-964b-c2ef188cc82a",
                "name": "Push-Ups",
                "sequence": 3,
                "notes": "Upper body prep"
            },
            {
                "id": "a03bb65e-a0f2-4785-8356-3021bd673b2b",
                "name": "TRX Rows",
                "sequence": 4,
                "notes": "Upper back activation"
            }
        ]
    },
    {
        "id": "44970cd9-164f-4c70-8bef-809040dde013",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "d53a0b54-70bb-4d6c-897d-1c4973ec21b5",
                "name": "Knee Hug to Quad Pull",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "a60f0b73-869d-46ac-9404-907f59ec2bd5",
                "name": "Lateral Lunge",
                "sequence": 2,
                "notes": "Adductor mobility"
            },
            {
                "id": "419513aa-1c59-42dc-85e5-55e1d95231e0",
                "name": "Inchworms",
                "sequence": 3,
                "notes": "10x - Full body"
            },
            {
                "id": "67c86bfa-b807-4fec-95c4-69a5090ad737",
                "name": "Lunge w/ Reach Up + Twist",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "a4257cb3-dc8c-4ad4-be3f-25617c9abdfc",
                "name": "Toy Soldiers",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "bac28b48-0ede-4b20-99a5-ccb56cb2383c",
                "name": "Lateral Push-off to Land",
                "sequence": 6,
                "notes": "Power/lateral"
            },
            {
                "id": "329f3f1a-c3b5-4800-8525-ba6b96dde945",
                "name": "Mini Band Work",
                "sequence": 7,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "a900207d-28f9-40cb-92bf-1afa341c9585",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "9f188a50-d960-4b4f-bcc9-6b6e2109d3cd",
                "name": "Back Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: SA SL RDL 8/8 between sets"
            },
            {
                "id": "c88ea843-3f47-43a2-89a2-d0779d8e7590",
                "name": "Strict Pull-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8-10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Seated Wall Angel 5x between sets"
            }
        ]
    },
    {
        "id": "8a74c4b6-de7e-4892-a925-5adf64390346",
        "name": "Conditioning - 12 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "eeb3075f-7ac0-4af3-af01-4c8314de6deb",
                "name": "Air Bike",
                "sequence": 1,
                "prescribed_reps": "15/12 cal"
            },
            {
                "id": "7e6dd9f2-eba2-430b-ae24-295142f35184",
                "name": "Box Jumps",
                "sequence": 2,
                "prescribed_reps": "15x"
            },
            {
                "id": "e2904f4e-220d-49c4-8aeb-2e170b80a711",
                "name": "Battle Rope Power Slams",
                "sequence": 3,
                "prescribed_reps": "30x"
            },
            {
                "id": "6953ad98-8460-4c88-b3dc-863fd47f0c47",
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
        "id": "2ed696c0-9ad4-4cc2-a8f2-bc3338d17caf",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "e426bec4-e442-42a2-9578-2580ebf39182",
                "name": "Run or Row or Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "54cd786a-44b8-4509-9a89-1fb238d11b51",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "3f77372f-8839-4114-b554-15ffc79a3682",
                "name": "Knee Hug w/ Hip Opener",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "8d2ce999-d9da-4d26-8803-3ceb3c548b5e",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "4bff83f9-18d6-40d9-9d8e-847c278cbdd9",
                "name": "Leg Cradle",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "98caad10-d7b0-42b9-9959-58fadaa3a3c8",
                "name": "Lateral Lunge",
                "sequence": 4,
                "notes": "Adductor mobility"
            },
            {
                "id": "6906320b-8207-47a6-9741-10df41bcc75f",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "b76f4660-07ca-4fd4-a659-4045a4c89aa0",
                "name": "Bear Crawl",
                "sequence": 6,
                "notes": "Core/shoulder"
            },
            {
                "id": "6aeba316-4014-44e3-8a76-abffd9b3f96a",
                "name": "Supine Leg Kicks",
                "sequence": 7,
                "notes": "10x ea - Hamstring"
            },
            {
                "id": "f6fc4377-34ae-4d03-9805-149e2c223110",
                "name": "Supine Trunk Rotation",
                "sequence": 8,
                "notes": "10x - T-spine mobility"
            }
        ]
    },
    {
        "id": "49c4776a-3b6f-4d96-8772-af8d7df022f1",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "12591aea-22f4-40f0-9835-8e18181bf7c0",
                "name": "Split Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8/8",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Shoulder Taps 10x SLOW between sets"
            },
            {
                "id": "d1d986ac-d69c-4e7f-bf41-24b950baff08",
                "name": "Standing DB Curl to Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Chest/Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "6705c74f-9fcd-46d1-ae99-0cf6e5b245b5",
        "name": "Conditioning - 12'' Ascending Ladder (5, 10, 15, 20...)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "e544781f-d62c-4854-a89b-27c4e60ea509",
                "name": "Air Squat",
                "sequence": 1
            },
            {
                "id": "5a10a538-24d3-4fda-891e-f9a8c460a90b",
                "name": "Push-Up",
                "sequence": 2
            },
            {
                "id": "cab9966c-c288-4e65-b629-9833202ae188",
                "name": "SA Swing",
                "sequence": 3
            },
            {
                "id": "890d57c7-b881-427a-8695-9ea16f720033",
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
        "id": "de7fe613-557a-4692-83ec-112ed5e74a99",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "0088b1cb-aea2-41b4-b6a3-fc7597da45b5",
                "name": "Quick Step Ups",
                "sequence": 1,
                "prescribed_reps": "50x",
                "notes": "Cardio activation"
            },
            {
                "id": "3c5a2120-a9a5-4e82-ae11-ff01bd12ad8f",
                "name": "Quick Lateral Step Over",
                "sequence": 2,
                "prescribed_reps": "50x",
                "notes": "Lateral activation"
            }
        ]
    },
    {
        "id": "7aeb51a5-3acf-40b6-b76d-25a7e6cdfd1a",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "7b27f08a-07d9-4d53-8a6b-a78ce8251ea5",
                "name": "Quad Pull to Knee Hug",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "577505f3-c9fd-4867-bfa8-0e581eb74d8c",
                "name": "Lateral Lunge Opening Foot",
                "sequence": 2,
                "notes": "Adductor mobility"
            },
            {
                "id": "c56985b5-cf3e-4183-addb-a26deb6845c6",
                "name": "Carioca",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "08b1117a-646b-4f33-b2cd-2f2e935e93d9",
                "name": "Rear Lunge + Reach Up",
                "sequence": 4,
                "notes": "Hip/T-spine"
            }
        ]
    },
    {
        "id": "7a501d1e-697f-45d2-bf72-7504d8e397a8",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "a2b9915c-29aa-48c7-b2fd-a283504a597d",
                "name": "Sumo Deadlift (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Groin Stretch + SL RDL Balance between sets"
            },
            {
                "id": "22414087-999c-4091-8797-54e1c6aa5a02",
                "name": "Chin-Ups or Band Pulldown",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 90 sec between sets Accessory: Cat/Cow 10x between sets"
            }
        ]
    },
    {
        "id": "1e476177-dfc7-495a-8f6f-81001de071d8",
        "name": "Conditioning - 3-4 Rounds (10'' Cap)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "2ec9e426-c6cd-48f3-9592-6d06ff56146a",
                "name": "Band Lifts",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10x",
                "notes": "4 rounds total"
            },
            {
                "id": "14ca6aa4-bd12-46ae-8451-e6ad41b847b8",
                "name": "Box Jumps",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12x",
                "notes": "4 rounds total"
            },
            {
                "id": "b1c0ac4d-188b-43d6-9f48-db1be851dacb",
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
        "id": "9e370cca-4a70-4718-aa78-6ab28a96637a",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "33dd32ff-bd82-4e41-8187-672e7e278fb1",
                "name": "Row or Air Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            },
            {
                "id": "326327c2-c89f-414d-aba5-cccfa7e3376b",
                "name": "Hollow Body Windshield Wiper",
                "sequence": 2,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "3fdb77ee-158e-4239-b7f4-67bc80508c46",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "970be908-dd9d-4d41-ab7e-9e1e1e35b5e0",
                "name": "Bushwackers",
                "sequence": 1,
                "notes": "Full body"
            },
            {
                "id": "6e7fd736-1f03-48ad-bf6b-60062e9300b5",
                "name": "Bear Crawl",
                "sequence": 2,
                "notes": "Core/shoulder"
            },
            {
                "id": "6f45ffe5-62ca-41a0-82b7-7c17fb210c7e",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 3,
                "notes": "Lateral movement"
            },
            {
                "id": "d75ce266-b1fa-4789-b8b2-e26281948e94",
                "name": "Seal Jumping Jacks",
                "sequence": 4,
                "notes": "20x - Shoulder mobility"
            },
            {
                "id": "1f0a31d9-4e62-4b79-8205-1566815646f9",
                "name": "Lateral Plank Walk",
                "sequence": 5,
                "notes": "Core/shoulder"
            },
            {
                "id": "49249b12-a4be-411f-8e9a-7f86ef987356",
                "name": "Lunge w/ Reach Up + Twist",
                "sequence": 6,
                "notes": "Hip/T-spine"
            },
            {
                "id": "e0e85cbd-fdfc-4210-b623-c611cba0868f",
                "name": "Inchworm w/ Push-Up",
                "sequence": 7,
                "notes": "10x - Full body prep"
            },
            {
                "id": "41602396-41c6-46de-b2f0-e1b8cf1947b0",
                "name": "Scap Warm-Up w/ Plates",
                "sequence": 8,
                "notes": "Shoulder activation"
            }
        ]
    },
    {
        "id": "39299a88-37df-41a8-b866-1ea3b6249fbf",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "2c7d354a-81aa-4a95-aceb-3e390f977bc8",
                "name": "Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 5). Set 2: Moderate-Heavy (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Quadruped Trunk Rotation between sets"
            },
            {
                "id": "e1b6b9a1-2e42-4c85-8763-9b2ae532a332",
                "name": "DB Lateral Raise",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 45 sec between sets Accessory: DB Front Raise 10x between sets"
            }
        ]
    },
    {
        "id": "f1cde472-5f2b-4713-8d73-20567cf1ace4",
        "name": "Conditioning - 3 Rounds (Interval)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "21ce0588-c9dc-430d-a4bf-8b9d9fd8e3c8",
                "name": "Battle Rope",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            },
            {
                "id": "73a245d5-5273-40f7-9dcd-d0cc66bfbd39",
                "name": "Max Cal Row",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            },
            {
                "id": "8df99ad8-1162-4820-ac7a-abbfb3bd01f0",
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
        "id": "9addb13d-4ab0-4a27-a78c-c0285f982a2b",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "20a4d93f-c84e-42a4-905d-912c5ad4e555",
                "name": "Run or Air Bike or Row",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "3a4bf9e7-4c70-4b10-8ac4-77ab816c1a0f",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "a343cdb2-a0dd-4af9-a0cf-c10128d3b210",
                "name": "Lunge w/ Reach Up + Twist",
                "sequence": 1,
                "notes": "Hip/T-spine"
            },
            {
                "id": "c46f7f9e-0f6a-4321-ae00-7aba1b63627a",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 2,
                "notes": "Lateral movement"
            },
            {
                "id": "b4513aad-1387-4a8c-8c17-fec420f58af0",
                "name": "Bear Crawl",
                "sequence": 3,
                "notes": "Core/shoulder"
            },
            {
                "id": "8521e788-edbb-453f-8049-f919d06ce6c6",
                "name": "High Knee Carioca",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "30fae6c1-0612-4aba-800c-da2a79528d48",
                "name": "Quad Pull Hinge",
                "sequence": 5,
                "notes": "Quad/hip prep"
            },
            {
                "id": "8c7c10dd-f2a5-4460-865b-a5656a15e8d4",
                "name": "Knee Hug w/ Hip Opener",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "e8f957be-45f6-4834-80d1-588ce4165fa0",
                "name": "Butt Kicks",
                "sequence": 7,
                "notes": "Quad activation"
            },
            {
                "id": "268b7129-3147-4426-9e0f-edb7ae458af4",
                "name": "High Knees",
                "sequence": 8,
                "notes": "Hip flexor prep"
            }
        ]
    },
    {
        "id": "36b3a20e-a176-4c54-9a9e-9e89bf24cafd",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "ee3e1481-423b-49de-8d7c-fa25502048f2",
                "name": "BB Strict Press",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Deadbug 10x SLOW between sets"
            },
            {
                "id": "c314a46c-0fcb-45f9-83fb-1e5a075f2521",
                "name": "KB Front Rack Walking Lunge",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets"
            }
        ]
    },
    {
        "id": "2257a012-20fe-4676-b2e2-e5929c06f9e2",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "539de790-dd59-42be-9f3e-3c1b57f70a8b",
                "name": "Run",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "1 Lap",
                "notes": "4 rounds total"
            },
            {
                "id": "8c58d3ff-4666-40ea-a599-c6325e7eaec6",
                "name": "Goblet Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10x",
                "notes": "4 rounds total"
            },
            {
                "id": "72c87c21-0f69-4dc0-a54d-c101f80d2bcd",
                "name": "Push-Up",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "12x",
                "notes": "4 rounds total"
            },
            {
                "id": "2505120a-e324-4f5e-a3ea-5b14a341ac99",
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
        "id": "73860bb8-6b71-4334-a2b1-bc533626f05d",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "9a879ab4-a95f-4fdc-9653-22111bb3456f",
                "name": "Row or Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "096cccd9-4e8d-4fb9-9282-9550e82a0e99",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "ffedbe86-7f36-4c41-8192-54e5f5221367",
                "name": "Knee Hug to Quad Pull",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "caaaf6cb-bb27-4e71-8469-2152e9639fba",
                "name": "Rear Lunge w/ Reach Up",
                "sequence": 2,
                "notes": "Hip/T-spine"
            },
            {
                "id": "57645384-aa1b-4f8b-9abf-0cd2f88f96a8",
                "name": "Leg Cradle",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "15c2b24d-cc52-4995-a90c-bec865d2ff74",
                "name": "High Knee Carioca",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "a75701a3-c39e-469e-bc3a-3853fbe951a8",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "b42c069d-69e9-4821-8062-b455f86288ab",
                "name": "Power A-Skip",
                "sequence": 6,
                "notes": "Dynamic power"
            },
            {
                "id": "082d3e04-12b4-4bda-ac9f-a3aeb92e4976",
                "name": "Lateral A-Skip",
                "sequence": 7,
                "notes": "Lateral movement"
            }
        ]
    },
    {
        "id": "51ba624c-c9d8-4cad-b86d-9e4cea79985b",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "44112942-0062-4b9e-9ddf-48a75bda74ec",
                "name": "Good Morning",
                "sequence": 1,
                "prescribed_reps": "5x w/ pause",
                "notes": "Hip hinge pattern"
            },
            {
                "id": "167dcb5e-8464-4514-93fa-28701724df0b",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_reps": "5x w/ pause",
                "notes": "Squat pattern"
            },
            {
                "id": "e98bde68-c1f9-48e5-a03f-b053b38b3253",
                "name": "Strict Press",
                "sequence": 3,
                "prescribed_reps": "5x",
                "notes": "Shoulder prep"
            },
            {
                "id": "9e9ff33a-c12a-4e3e-92fe-19788f046741",
                "name": "Push Press",
                "sequence": 4,
                "prescribed_reps": "5x",
                "notes": "Power prep"
            }
        ]
    },
    {
        "id": "f94435ee-caa2-4826-a204-c936f2c20612",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "0df93988-0515-450e-a4f3-5b7cc87062ea",
                "name": "BB or KB Front Squat (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Hip Flexor/Hamstring Stretch between sets"
            }
        ]
    },
    {
        "id": "57f5adb6-1f94-4f0f-b02e-3e705d759aff",
        "name": "Conditioning - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "a171a519-8747-4cb4-ad94-6d356ae4a0d5",
                "name": "Burpee Box Jumps",
                "sequence": 1,
                "prescribed_reps": "10x"
            },
            {
                "id": "937b13da-2e93-4194-bb8f-3671ef5525c0",
                "name": "KB Swing",
                "sequence": 2,
                "prescribed_reps": "15x"
            },
            {
                "id": "c2a2a9ca-6cc6-44c4-ae34-a3daf3d3a9e5",
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
        "id": "58f30475-fde3-45bf-94f1-028df8245b42",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "3cd5e216-cb66-4d4a-87cd-29720053c2a6",
                "name": "Step Ups",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "30-50x",
                "notes": "Leg activation"
            },
            {
                "id": "7b44bae7-134a-4d6f-bda6-6b1d26423f3d",
                "name": "Push-Ups",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10-15x",
                "notes": "Upper body prep"
            },
            {
                "id": "379990d6-d5d9-4f8e-85b6-abbbacc2059d",
                "name": "KB Swings",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "25-35x",
                "notes": "Power activation"
            }
        ]
    },
    {
        "id": "09e3567f-9b4d-4489-a207-244059cb7d96",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "099a494a-415d-4049-9392-3907eda15ba6",
                "name": "High Knee March w/ pause",
                "sequence": 1,
                "notes": "Hip flexor/balance"
            },
            {
                "id": "39be9f5c-6e28-4877-a246-1c974d1061ed",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "4854b4e4-caaa-4746-bf2a-7f048faeb1d1",
                "name": "Leg Cradle",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "5f191ed7-8f16-4ef5-8446-0030201898b5",
                "name": "Lunge w/ Reach Up + Twist",
                "sequence": 4,
                "notes": "Hip/T-spine"
            },
            {
                "id": "cc042bbd-a69b-49f0-8e5d-373ed6ba536a",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 5,
                "notes": "Lateral movement"
            },
            {
                "id": "b2da26ae-f4db-4fb0-a69f-5c156a7adaad",
                "name": "Squat w/ 3 sec pause",
                "sequence": 6,
                "notes": "Squat pattern"
            }
        ]
    },
    {
        "id": "cb32f015-213f-4c1c-9b4b-7a90a4110b1b",
        "name": "Band Warm-Up",
        "block_type": "cardio",
        "sequence": 3,
        "exercises": [
            {
                "id": "469d5824-4a6a-461a-965f-77229b67f694",
                "name": "Pull Apart",
                "sequence": 1,
                "prescribed_reps": "12x",
                "notes": "Rear delt/rhomboids"
            },
            {
                "id": "b3ae1b49-676f-43c2-8ea7-54cd672c49b9",
                "name": "Snatch Press",
                "sequence": 2,
                "prescribed_reps": "12x",
                "notes": "Shoulder mobility"
            },
            {
                "id": "5ff1ecdb-1d4b-4627-9ce3-8d6f0357455a",
                "name": "Good Morning",
                "sequence": 3,
                "prescribed_reps": "12x",
                "notes": "Hip hinge prep"
            },
            {
                "id": "bc329cdf-bd2a-4a08-a838-8a9dab1df0f1",
                "name": "OH Squat",
                "sequence": 4,
                "prescribed_reps": "12x",
                "notes": "Shoulder/hip mobility"
            }
        ]
    },
    {
        "id": "7879b6fd-5fe4-4e26-bae5-b9d09392f50a",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "9e8fa2dc-ca13-4ff0-b0e0-27767639dadd",
                "name": "Alternating DB Press to Double",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10/10 alt + 10 double",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: TRX Chest Stretch between sets"
            },
            {
                "id": "74d4edba-78a6-4907-8362-bc0c30691dfe",
                "name": "Suitcase Carry HEAVY",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: PB Glute Bridge 10x between sets"
            }
        ]
    },
    {
        "id": "75d02db9-d24a-4b82-a082-4901e0266a1b",
        "name": "Conditioning - Descending Ladder (20-16-12-8-4)",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "4402e6df-a548-48dc-97fe-513db898a175",
                "name": "Goblet Stationary Lunge",
                "sequence": 1
            },
            {
                "id": "9f725a91-88a1-4e9d-8f78-c665f5f6adf5",
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
        "id": "da5d0c87-c3e9-46f5-8fc8-2f6e1a91a226",
        "name": "Active - 3 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "2ee70399-70e0-42a9-a66f-eb22c52557f1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "Cardio activation"
            },
            {
                "id": "c22da906-9c2c-4a0b-ad4b-9e5e885ffeca",
                "name": "Air Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10x",
                "notes": "Lower body prep"
            },
            {
                "id": "56a9a0a1-7ac4-4248-99cc-70f96f6b3335",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15x",
                "notes": "Power activation"
            }
        ]
    },
    {
        "id": "a12862ce-5eff-4aa5-aa98-268975484e32",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "76cb536e-3fe5-44d7-bcd2-9f4a80333e29",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "2f3f0ffd-0126-43d2-8425-42f970d8baff",
                "name": "Knee Hug to Hip Opener",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "fbe014f5-7ec5-45a8-aa47-9e978b35a458",
                "name": "Carioca",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "ac08ee41-77fc-4869-9578-864ba1fcc83e",
                "name": "Push-Ups",
                "sequence": 4,
                "notes": "Upper body prep"
            },
            {
                "id": "5b17e1f0-86c6-47d2-9978-a694cff6c6f2",
                "name": "Toy Soldier",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "a458a04f-f718-4e64-b5c5-01aa174f3085",
                "name": "Lateral Lunge",
                "sequence": 6,
                "notes": "Adductor mobility"
            }
        ]
    },
    {
        "id": "70568f1c-0790-421e-83c5-ff6d176dfdc3",
        "name": "Shoulder Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "f01d3696-e809-4744-9b67-262f939e393c",
                "name": "Abduction to External Rotation",
                "sequence": 1,
                "prescribed_reps": "12x",
                "notes": "Rotator cuff"
            },
            {
                "id": "3605bcad-26a6-479f-bf04-e74d7cbae994",
                "name": "Press",
                "sequence": 2,
                "prescribed_reps": "12x",
                "notes": "Shoulder activation"
            },
            {
                "id": "5054061e-f354-46c1-9aed-0a542f9d7037",
                "name": "A/T/Y",
                "sequence": 3,
                "prescribed_reps": "6 rounds",
                "notes": "Full shoulder prep"
            }
        ]
    },
    {
        "id": "18b79581-808c-4278-a0ed-d87b63496989",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "7bceb148-0378-458e-919f-25c5c42dd384",
                "name": "Strict Press to Push Press",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "8 strict + 8 push",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Dead Bug (SLOW) x 10 between sets"
            },
            {
                "id": "be160b7f-c9c6-412e-9de1-731d354c3ad3",
                "name": "DB Split Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "8/8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Standing Staggered Stance Hamstring Stretch x 5/5 between sets"
            }
        ]
    },
    {
        "id": "b3f863c4-169f-44c1-b836-19601944076d",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "62c8f040-9512-4264-a952-06980196a36b",
                "name": "KB Swing",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "25x",
                "notes": "4 rounds total"
            },
            {
                "id": "be056704-ec3a-4b35-8206-f9d7f4cca9b3",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "20x",
                "notes": "4 rounds total"
            },
            {
                "id": "e26063f3-c90e-41bb-b12c-7030b2e025e5",
                "name": "Goblet Squat",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "15x",
                "notes": "4 rounds total"
            },
            {
                "id": "1d312246-37f1-476a-8589-d59220e4e5b1",
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
        "id": "9eb8eea6-547d-4bfd-96f3-9e941e8ac8e4",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "37829117-5789-4e64-af6f-4b3c7f773781",
                "name": "Run",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "0b170f85-e1fc-4064-80c1-ae17a9d3f0df",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "c3d59153-dcdf-4b1e-ae5a-4d7ad3866b35",
                "name": "Leg Cradle",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "3b2894f2-eecc-46fa-b8a5-7ef5d8b9bee8",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad/hip prep"
            },
            {
                "id": "66aada1a-1429-4d08-beac-efa061e1f727",
                "name": "Lateral Lunge",
                "sequence": 3,
                "notes": "Adductor mobility"
            },
            {
                "id": "3650c6cd-e54a-48ae-80a2-6b8defac95cf",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "bf2ad8e3-5274-415a-a641-4719cbe27af3",
                "name": "Bear Crawl",
                "sequence": 5,
                "notes": "Core/shoulder"
            },
            {
                "id": "fdc4a20c-ed0e-4e13-882c-28f243669522",
                "name": "Hip Heist",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "73810949-da64-4c31-8a4c-9159623d6ac9",
                "name": "Leg Swings",
                "sequence": 7,
                "notes": "10x ea - Hip mobility"
            },
            {
                "id": "7e1ad074-3114-437c-a794-81bf458cfbba",
                "name": "Sumo Squat",
                "sequence": 8,
                "notes": "10x - Sumo stance prep"
            }
        ]
    },
    {
        "id": "053933b5-e4d9-4bec-850d-35e99f1453da",
        "name": "Movement Prep",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "3d6158e1-4d6a-4ed1-8ced-351802bbd200",
                "name": "RDL",
                "sequence": 1,
                "prescribed_reps": "10x",
                "notes": "Hip hinge pattern"
            },
            {
                "id": "7f07067e-8794-4214-ac98-fcf5f5a8ec41",
                "name": "Lateral Squat",
                "sequence": 2,
                "prescribed_reps": "10x",
                "notes": "Adductor prep"
            },
            {
                "id": "5577d425-8a93-4e98-8a8e-f2315929a939",
                "name": "Sumo DL",
                "sequence": 3,
                "prescribed_reps": "10x",
                "notes": "Movement prep"
            }
        ]
    },
    {
        "id": "37fb7c54-00b9-4f32-aa14-6102613a525f",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "07284a3a-222f-4901-af7b-0b1b071a9c13",
                "name": "Sumo Deadlift",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Set 5: Heavy (RPE 8). Rest: 2-3 min between sets Accessory: 4 Point Bridge w/ ext. 10x between sets"
            },
            {
                "id": "c447b264-a8e0-43ec-a9fe-1ecca03f3244",
                "name": "Split Stance Row",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12/12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Banded Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "277bdc6d-a27e-473c-b66d-836dc2fbcdc5",
        "name": "Conditioning - 3 Rounds (Interval)",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "c2b78b60-84e3-4b9e-b7a2-bfcadcbfabfb",
                "name": "HKTC",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            },
            {
                "id": "5d016840-8e59-491d-b917-0d4434d6ebbb",
                "name": "Box Jumps",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "1 min",
                "notes": "3 rounds total"
            },
            {
                "id": "8b77876e-5695-41ea-b5b6-94b108fcef42",
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
        "id": "44ed72d5-8c8b-4b00-a07c-95c6c087a22a",
        "name": "Active - 3 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "e23ae101-c7d9-4ba2-9281-e2b9c1c6af2f",
                "name": "Lateral Step Up",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "30x",
                "notes": "Lateral activation"
            },
            {
                "id": "fdade178-d31e-4373-af50-31100198b082",
                "name": "Rear Lunge w/ Reach Up",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10x",
                "notes": "Hip/T-spine"
            },
            {
                "id": "9da82250-73c5-4398-a337-68389dec853b",
                "name": "\u00bd Burpee",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10x",
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "0cdfcee3-f3af-433e-9058-718a945a504e",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "87034060-3397-4d65-8226-2f14c9fa7963",
                "name": "High Knee Carioca",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "3fabcf96-61b5-4d71-82a9-e457c0a69ebc",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 2,
                "notes": "Lateral movement"
            },
            {
                "id": "ddea05dc-3479-4f53-9d2b-e04a28abcd32",
                "name": "Quad Pull Hinge",
                "sequence": 3,
                "notes": "Quad/hip prep"
            },
            {
                "id": "42a3429a-fc28-4cba-a126-7cd591623c3f",
                "name": "High Knees",
                "sequence": 4,
                "notes": "Hip flexor prep"
            },
            {
                "id": "d74dc69e-fc95-4181-b7f2-6498861b75fb",
                "name": "Backpedal",
                "sequence": 5,
                "notes": "Hip/hamstring"
            },
            {
                "id": "a52c052b-237c-4d72-afe7-b7b26e054e3b",
                "name": "Butt Kicks",
                "sequence": 6,
                "notes": "Quad activation"
            },
            {
                "id": "da2cfee6-52bd-4be0-a293-4b45c415a85f",
                "name": "A-Skip",
                "sequence": 7,
                "notes": "Dynamic warm-up"
            },
            {
                "id": "067ca224-69bd-48ff-8553-7de92b9afc12",
                "name": "Lateral A-Skip",
                "sequence": 8,
                "notes": "Lateral movement"
            },
            {
                "id": "e49ee838-5730-449a-8be8-e21a4cee3847",
                "name": "Bushwackers",
                "sequence": 9,
                "notes": "Full body"
            }
        ]
    },
    {
        "id": "80aee5b5-a7da-4c8f-98d3-8b2d689de86f",
        "name": "Band Work",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "50ffd755-b1a5-485f-9840-e0af29905db0",
                "name": "Face Pulls",
                "sequence": 1,
                "prescribed_reps": "15x",
                "notes": "Rear delt/rotator cuff"
            },
            {
                "id": "063940f1-8f13-4aba-ba44-dd9326c8ea6c",
                "name": "SA Press",
                "sequence": 2,
                "prescribed_reps": "15/15x",
                "notes": "Shoulder activation"
            },
            {
                "id": "220ddbbd-acd3-42b8-a303-94f86709b8d7",
                "name": "Lat Pulldown",
                "sequence": 3,
                "prescribed_reps": "15x",
                "notes": "Lat activation"
            },
            {
                "id": "ecdb612a-89d9-466a-b950-3a647637fb3c",
                "name": "Palloff Press w/ Rot.",
                "sequence": 4,
                "prescribed_reps": "15/15x",
                "notes": "Anti-rotation core"
            }
        ]
    },
    {
        "id": "cba5ca30-279e-4491-91e2-98e26f4ccf39",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "6b914a0d-4a20-482a-b80b-e6c89233a099",
                "name": "Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Band Pull Apart 10x between sets"
            },
            {
                "id": "c0f91903-5734-46f5-a193-ead663cabf7b",
                "name": "HEAVY Farmers Carry",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Rot. Plank 10x w/ 2 sec pause between sets"
            }
        ]
    },
    {
        "id": "e52859f7-29f1-444f-9fa8-9a0b5bec739f",
        "name": "Conditioning (Optional)",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "d404f55a-3eb0-4bea-bafb-d09ec49cba8a",
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
        "id": "86027e3b-b0cf-4180-a874-12aa0e8af161",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "f909785c-58e6-4317-81fe-818d4c875788",
                "name": "Run or Bike",
                "sequence": 1,
                "notes": "Cardio activation"
            }
        ]
    },
    {
        "id": "23d750d7-530e-4463-8309-ea7072a5ee2b",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "8579a565-0539-43a4-8adc-6b18ee9aaa7d",
                "name": "Side Shuffle w/ Arm Swing",
                "sequence": 1,
                "notes": "Lateral movement"
            },
            {
                "id": "f946b0cb-01a1-4136-82a5-ccdafecd7d2f",
                "name": "Knee Hug to Hip Opener",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "0ea2df50-c741-440f-b1d6-8c828a920acd",
                "name": "Carioca",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "05ccc6a8-842b-48cf-8aac-14937e89fe74",
                "name": "Quad Pull Hinge",
                "sequence": 4,
                "notes": "Quad/hip prep"
            },
            {
                "id": "67fef9bc-80b6-4d37-a99a-611db7cfda4f",
                "name": "Butt Kicks",
                "sequence": 5,
                "notes": "Quad activation"
            },
            {
                "id": "c78e8ae1-5d15-4073-8f66-3b9b64b182cf",
                "name": "Knee Hug to Leg Cradle",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "5bd6d138-87f2-4f58-b73c-912ed14249ea",
                "name": "Lunge Palm to Instep",
                "sequence": 7,
                "notes": "Hip/T-spine"
            },
            {
                "id": "2629bcc9-d587-438d-ab63-1968289a6c58",
                "name": "Toy Soldier",
                "sequence": 8,
                "notes": "Hamstring activation"
            },
            {
                "id": "de21ce3c-65a7-4e4b-bbf9-2788ddff538b",
                "name": "Hurdles",
                "sequence": 9,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "d68fa8f0-15f1-4853-82b4-fd6e18101d3b",
        "name": "Movement Prep (w/ Small Plates)",
        "block_type": "activation",
        "sequence": 3,
        "exercises": [
            {
                "id": "0a1d8523-ad8a-4e96-b5b0-00924d225870",
                "name": "Abduction w/ ER",
                "sequence": 1,
                "prescribed_reps": "12x",
                "notes": "Rotator cuff"
            },
            {
                "id": "2009ee4b-465c-49c0-ba2d-fc1d606ab790",
                "name": "Neutral Grip Press",
                "sequence": 2,
                "prescribed_reps": "12x",
                "notes": "Shoulder prep"
            },
            {
                "id": "1ced3973-3e9f-4d93-93a8-b36aa9059b4f",
                "name": "A/T/Y",
                "sequence": 3,
                "prescribed_reps": "6x",
                "notes": "Full shoulder activation"
            }
        ]
    },
    {
        "id": "18467e38-b98b-4b89-8222-ef6b82479475",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "75d0b1ee-433c-4830-a6b3-c58399408bf3",
                "name": "Bench Press (Pyramid)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavier (RPE 8). Rest: 2-3 min between sets Accessory: Quadruped Trunk Rot. 5/5 between sets"
            },
            {
                "id": "c756de00-d699-4a80-a2af-085c7fbfee36",
                "name": "Heavy Suitcase Carry",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Shoulder Taps 20x SLOW between sets"
            }
        ]
    },
    {
        "id": "d966335b-891f-42ea-b069-3a95c8182870",
        "name": "Conditioning - Descending Ladder (20-15-10-5)",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "540b3103-9f0f-4276-bfda-5ae8840da6f7",
                "name": "Burpees",
                "sequence": 1
            },
            {
                "id": "98a8f42c-367e-4ff7-b372-e72eb67f6f07",
                "name": "Pull-Ups / Band Pulldown",
                "sequence": 2
            },
            {
                "id": "a1ba7b2a-08d5-4ec8-8313-d62dd02c0211",
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
        "id": "e4a4e63c-c022-4e1d-933d-1a4aa19a0187",
        "name": "Active - 2 Rounds",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "a015797e-54ff-43ae-ac59-36e397f4ed4e",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": ":30",
                "notes": "Cardio activation"
            },
            {
                "id": "69204d22-ddb7-4129-ad69-8e11237d2216",
                "name": "Rear Lunge Reach Up",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10x",
                "notes": "Hip/T-spine"
            },
            {
                "id": "670bd70b-d421-46a1-9fbc-4876341aa689",
                "name": "Shoulder Taps SLOW",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "20x",
                "notes": "Core/shoulder stability"
            },
            {
                "id": "2008b5e0-ca9b-46c7-862c-d966e57de177",
                "name": "Squat w/ pause",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "10x",
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "c35c9d42-80a8-4e2b-8a3b-fbbcaa88ab0e",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "76bdb297-0f82-45ad-aaf0-9eb8234b3bdf",
                "name": "High Knee March",
                "sequence": 1,
                "notes": "Hip flexor prep"
            },
            {
                "id": "4702db25-2a81-41d0-9179-0ad782daabbb",
                "name": "SL RDL w/ Reach",
                "sequence": 2,
                "notes": "Balance/hamstring"
            },
            {
                "id": "c57452b1-d62e-4b06-bf0e-336325586fe8",
                "name": "Lat. Shuffle w/ Arm Swing",
                "sequence": 3,
                "notes": "Lateral movement"
            },
            {
                "id": "298ab6ec-41cc-4d92-9863-3424fc9acf1f",
                "name": "Bear Crawl",
                "sequence": 4,
                "notes": "Core/shoulder"
            }
        ]
    },
    {
        "id": "da03ccfc-471a-4a66-acc9-b6cc0ad8b515",
        "name": "Empty Bar Warm-Up",
        "block_type": "cardio",
        "sequence": 3,
        "exercises": [
            {
                "id": "de622842-8b41-41d7-a228-192895e62775",
                "name": "RDL",
                "sequence": 1,
                "prescribed_reps": "12x",
                "notes": "Hip hinge prep"
            },
            {
                "id": "f94c9a44-022b-47cb-9c27-771629704e73",
                "name": "Curls",
                "sequence": 2,
                "prescribed_reps": "12x",
                "notes": "Bicep activation"
            },
            {
                "id": "6b7f94b5-3371-47e6-a424-734f0848e727",
                "name": "Bent Row Underhand",
                "sequence": 3,
                "prescribed_reps": "12x",
                "notes": "Back activation"
            }
        ]
    },
    {
        "id": "0c1e91ab-f7e6-4e0d-b3f4-36704754558e",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "33d032a3-cafb-491a-880f-496a64a010fd",
                "name": "Bent BB Row (Underhand)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Close Grip Push-Up 10-15x between sets"
            },
            {
                "id": "786fe614-32f2-4f30-9e79-c4eb7ad55e0f",
                "name": "Loaded Glute Bridge",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "8-12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 7). Rest: 60 sec between sets Accessory: Supine Trunk Rot. 10x between sets"
            }
        ]
    },
    {
        "id": "94e9b397-ab00-42a3-b6e1-311584938404",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "1a58bc70-b25c-4860-8d3c-98d0512daa6a",
                "name": "Burpees",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10x",
                "notes": "4 rounds total"
            },
            {
                "id": "ca63f0a6-8d2a-4e76-ac47-2e16cd1d9ef1",
                "name": "HKTC w/ Rotation",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "15x",
                "notes": "4 rounds total"
            },
            {
                "id": "8fced460-e8ff-411f-9d5e-05bb78ebacf1",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "25x",
                "notes": "4 rounds total"
            },
            {
                "id": "c0ac2566-7873-48e6-86b6-486183d74ca9",
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
        "id": "403d5102-bff8-44e0-811d-539af67df117",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "5394ee9c-45ee-4d89-911d-212215b4488a",
                "name": "Monsters",
                "sequence": 1,
                "prescribed_reps": "2x",
                "notes": "Full body activation"
            },
            {
                "id": "ccd3af5f-ed21-48fd-8f7d-b0342f1f2395",
                "name": "Banded Bridge",
                "sequence": 2,
                "prescribed_reps": "30x",
                "notes": "Glute activation"
            },
            {
                "id": "f506c921-dc88-4d43-92ee-b61cba6b9301",
                "name": "Banded Squats",
                "sequence": 3,
                "prescribed_reps": "30x",
                "notes": "Lower body prep"
            }
        ]
    },
    {
        "id": "ef6fa34b-f266-48de-9143-8f27f47eabc6",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "fe74540b-4201-48d1-9b03-05c738603cb5",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "a2479a6e-788d-4e2a-94e6-545b917f2856",
                "name": "HS Walk",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "56048b67-64fa-4f33-93d2-49d4b5ab49f8",
                "name": "Push Up W/O",
                "sequence": 3,
                "notes": "Upper body prep"
            },
            {
                "id": "0338679c-966d-4b6c-8834-c7c7b4ebf157",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "0b1296cc-d10b-46d2-a30c-ec9ec3599b6d",
                "name": "Quad Pull",
                "sequence": 5,
                "notes": "Quad stretch"
            },
            {
                "id": "c062c1c1-8029-4061-8c15-8b9248d2d190",
                "name": "Lunge + Reach",
                "sequence": 6,
                "notes": "Hip/T-spine"
            }
        ]
    },
    {
        "id": "670f3ac6-c50c-43c1-a496-388fbdebb193",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "3d925cf6-b24b-46d2-9f53-0b1903d6e586",
                "name": "Lunges",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "e8e592b4-e524-446b-b719-f056e0a5fdad",
                "name": "Pull Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 9). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "a6d0f6de-d859-4196-91f9-e9a435680a86",
                "name": "SL Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 45 sec between sets Accessory: Cobra/Child between sets"
            },
            {
                "id": "feb7b84d-cd54-480c-b3a0-7405be912c90",
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
        "id": "7e891231-6c2d-4c20-b8ce-3d8e9a483795",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "9aff0f05-7867-46d4-b6d2-25094416d75d",
                "name": "Sumo Deadlift",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: Pigeon & Child''s Pose between sets"
            },
            {
                "id": "a328bdba-613c-45c9-a422-13ec65416bcf",
                "name": "Reverse Snow Angel",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10-15",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 6). Set 3: Bodyweight (RPE 7). Rest: 60 sec between sets Accessory: Hollow Rock Hold 30-45 sec between sets"
            }
        ]
    },
    {
        "id": "d7545920-a596-447b-a789-d6cea489a126",
        "name": "Post Workout",
        "block_type": "functional",
        "sequence": 2,
        "exercises": [
            {
                "id": "a869f0b1-e213-4698-950a-c297d4b26460",
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
        "id": "fccf433f-0cb1-47ed-b92d-2a0632d1a649",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "41c1257c-4394-48c7-a852-bca5932ca1a1",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: SL Trunk Rotation between sets"
            },
            {
                "id": "9a4c9e31-839f-4e6d-840d-c50a66c8e3c1",
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
        "id": "905f1c6e-8fa4-4582-a807-10d80c31404f",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "407b2dff-c006-4a8f-861e-e3b7047954de",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light effort warmup"
            },
            {
                "id": "94711fb1-2997-48a4-9034-eb3c5a723ef3",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "1 min",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "255b2159-041d-4c2c-bc4a-b816b25ec69d",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "0c9f4d1b-36ae-4f45-934d-4a171c430c8a",
                "name": "Quad Pull/Knee Hug",
                "sequence": 1,
                "notes": "Hip/quad mobility"
            },
            {
                "id": "9fa03f12-9689-4b82-8755-5d7ad823c43d",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "ea56606c-f47a-4c39-bc7f-da50fde37458",
                "name": "Side Lunge",
                "sequence": 3,
                "notes": "Adductor stretch"
            },
            {
                "id": "3d846a03-0e0d-4131-8e80-43a3c2c15636",
                "name": "A-Skip",
                "sequence": 4,
                "notes": "Dynamic warmup"
            },
            {
                "id": "0876082e-6a6f-44ab-a985-625bfd33b1a9",
                "name": "Push-Ups",
                "sequence": 5,
                "notes": "10 reps - upper body prep"
            }
        ]
    },
    {
        "id": "c2d92148-c886-43a8-86ef-79ca6ac0f052",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "c603fa0c-3b9c-4766-a2f2-9f9af0c47af1",
                "name": "Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "80e0b3af-259d-4c23-ba84-f2937e77b7ac",
                "name": "Heavy Farmers Carry",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "",
                "notes": "Set 1: Heavy (RPE 7). Rest: 5 Burpees between each trip"
            }
        ]
    },
    {
        "id": "d4b64832-32ca-4739-95dc-cbd41ef228f6",
        "name": "Cash Out",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "aa875c03-df21-4cfe-a91f-a37fe3b48623",
                "name": "Ladder",
                "sequence": 1,
                "prescribed_reps": "1 round",
                "notes": "Footwork/agility"
            },
            {
                "id": "8cc79948-2dfe-4bc9-bdbb-b5daac8c1ed2",
                "name": "Wall Sit",
                "sequence": 2,
                "prescribed_reps": "45 sec",
                "notes": "Quad endurance"
            },
            {
                "id": "481063ab-27ce-47fd-8a99-626b089ceab6",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "15 each",
                "notes": "Core rotation"
            },
            {
                "id": "402961f9-77e4-43e3-90c2-2fef847484a8",
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
        "id": "cddda813-2f9a-4f89-8cc7-56a0fe82d409",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "c7edf88c-7399-4a91-84d4-e318a8078fc8",
                "name": "Monster Walk",
                "sequence": 1,
                "prescribed_reps": "2 x 10e",
                "notes": "Glute/hip activation"
            }
        ]
    },
    {
        "id": "a6486c5a-949a-469b-934e-6155a88b1b01",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "914d9c1a-b8fe-41d6-a33a-860211192b87",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor activation"
            },
            {
                "id": "c389f5a4-5824-4f95-ae9d-4fd4bb98930c",
                "name": "Spiderman",
                "sequence": 2,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "4e9cc86f-7894-4ef5-9bd7-ae0f2598cdc2",
                "name": "Hamstring Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "bfe06f7a-4a2c-4aff-918f-bd1684ffd45f",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "5f01bbde-cbc1-4dcd-8e9e-852d62bc86cf",
                "name": "Lunge & Reach",
                "sequence": 5,
                "notes": "Hip/core prep"
            },
            {
                "id": "8f22b671-c787-4cfd-834c-31b42d9a54ed",
                "name": "Burpees",
                "sequence": 6,
                "notes": "10 reps - full body warmup"
            }
        ]
    },
    {
        "id": "52f49533-582b-4d14-aa17-d602ea00f963",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "41558491-f958-4883-9e11-76e0698a7a55",
                "name": "Single Leg Deadlift (S.L.D.L)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8 each",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: T.T.P (Toe Touch Progression) between sets"
            },
            {
                "id": "a34ec787-e9cd-4717-a093-217e2f621481",
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
        "id": "46569fde-ae7f-466d-94de-9e01be7928d1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "7b9143b8-1c61-4986-824d-dfd5639ab8ff",
                "name": "General Movement",
                "sequence": 1,
                "prescribed_reps": "5 min",
                "notes": "Light cardio"
            },
            {
                "id": "098ba893-a844-42d5-8172-8fcd98df2649",
                "name": "Jumping Jacks",
                "sequence": 2,
                "prescribed_reps": "2 x 10 sec",
                "notes": "Elevate heart rate"
            }
        ]
    },
    {
        "id": "c8f84c0b-75b8-4637-82c1-2cb05588cb2c",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "dbeb1cb8-674c-447f-aa34-968c82b4f2fe",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor activation"
            },
            {
                "id": "42fc3299-921b-42bd-9f75-056249b46854",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "c2cf480f-7b62-4cd5-92d5-fb336676da36",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "ca78fbe7-e8af-4fff-9fbd-2028726c57f0",
                "name": "Tin Soldier",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "9334d44c-dd1d-4974-8b60-ccad4555a1b4",
                "name": "Leg Swings",
                "sequence": 5,
                "notes": "Hip mobility (front/back)"
            },
            {
                "id": "a4e7c532-ce18-449d-a0e2-ae9c09df4c1f",
                "name": "Hip Circles",
                "sequence": 6,
                "notes": "Hip joint mobility"
            },
            {
                "id": "851ede89-b48e-4bee-a120-6e4420612a1d",
                "name": "PVC Passover",
                "sequence": 7,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "ac535fbf-0fe7-4c0a-90a3-80042118b90a",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "1b672541-6534-4bbf-978f-82553b3d8600",
                "name": "Single Leg Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "8 each",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 45 sec between sets"
            },
            {
                "id": "f7c85794-cc7b-481a-a42d-b60de3a757da",
                "name": "Push Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 8). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 9). Set 4: Bodyweight (RPE 9). Rest: 60-90 sec between sets"
            },
            {
                "id": "7154b710-841f-49f5-b7c0-b983f5eb17aa",
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
        "id": "fb16c0ff-b4e8-49f7-96de-769adef88a50",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "92cd731a-1ec1-497e-b8cd-cb81a5f5de00",
                "name": "BB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: 3 Way Lat Stretch between sets"
            },
            {
                "id": "d4d37114-89ce-4f74-87bd-a73fef540e5d",
                "name": "Bent BB Row (Overhand)",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Cat/Cow 5x between sets"
            }
        ]
    },
    {
        "id": "9510f624-1af1-4c24-8994-9ac47eee8d69",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 2,
        "exercises": [
            {
                "id": "d1212cea-a5ba-4cad-b218-c8ab7e560078",
                "name": "Wall Ball",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15x",
                "notes": "4 rounds total"
            },
            {
                "id": "9f9d4215-334f-4ff4-ac39-c36c39117da0",
                "name": "Pull-Up or Pulldown",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12x",
                "notes": "4 rounds total"
            },
            {
                "id": "3179d01a-6b77-4042-b299-0df77d3fe7e6",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "9x",
                "notes": "4 rounds total"
            }
        ]
    },
    {
        "id": "9bb961e8-43f0-4b1a-a634-8c1409dfb6e5",
        "name": "Core Auxiliary - 3 Rounds",
        "block_type": "core",
        "sequence": 3,
        "exercises": [
            {
                "id": "1670cabb-70a7-40db-8a9a-5711eb11e6f9",
                "name": "Bosu Mountain Climber",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "20x"
            },
            {
                "id": "aa9055c8-7791-4717-9a89-ad3748f319cc",
                "name": "Russian Twists",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "20x"
            },
            {
                "id": "f6582a44-1013-46c1-b668-8a1958628cb8",
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
        "id": "4871342c-d5f6-4b11-82fb-7d3cb1be89a9",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "32ca7366-3bb1-443d-bbb3-23efb18fe4f0",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Cardio warmup"
            },
            {
                "id": "4bd38e68-1227-4620-8700-5d8d81c99991",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "1 min",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "ab6f5f00-a176-4f4d-9fd7-3960f046b10d",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "64472658-6a1c-40b7-b9f4-ff2750b2c735",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "536318c8-6fa0-4632-8887-23f97d1e98a0",
                "name": "Arm Circles",
                "sequence": 2,
                "notes": "Shoulder mobility"
            },
            {
                "id": "cbae9255-7365-45a1-9108-f930d302c53d",
                "name": "Lunge & Twist",
                "sequence": 3,
                "notes": "Hip/T-spine"
            },
            {
                "id": "ae1a67c6-5577-47df-a6a3-7e27cc97e795",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "1b5bc9c8-6f80-4252-96a1-da82f1f89326",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warmup"
            },
            {
                "id": "cb52f2c6-3654-40b9-bcf5-540b6aab0e51",
                "name": "Burpees",
                "sequence": 6,
                "notes": "10x full body activation"
            }
        ]
    },
    {
        "id": "8f4b6eb7-5c7d-4d23-9848-588f4c1b0b0d",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "8998b6f2-5410-4b2b-9977-6c2bf9400ab8",
                "name": "Slant Bar Triple Extension",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Rest: 60-90 sec between sets Accessory: Hinge Quad Pull between sets"
            },
            {
                "id": "da0bdbdc-1c6e-4b6b-bbac-6772590ff6f3",
                "name": "TGU (Turkish Get-Up)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5 each side",
                "notes": "Set 1: Moderate (RPE 7). Rest: As needed between sides Accessory: PVC Passover between sets"
            },
            {
                "id": "13f41fc2-4da3-4681-9425-0470196893b9",
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
        "id": "149ebe3f-aee0-42fd-aa2d-f912910ee901",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "923c6d2b-06bc-463d-ab20-b195e59655d5",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Cardio warmup"
            },
            {
                "id": "6b3cac61-38bc-448b-8785-05f2db0775c9",
                "name": "Monster Walk",
                "sequence": 2,
                "prescribed_reps": "Full",
                "notes": "Hip activation"
            }
        ]
    },
    {
        "id": "d6a7a562-39a0-4b26-b36c-d6d8942c93c7",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "9786e54a-cdcb-415d-8679-6b4aa9f54b8c",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "142d8942-9bc6-4c57-96a8-6fae48e64d24",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "26dd88d8-6c9a-4fdc-bd57-ab60f68be134",
                "name": "Hamstring Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "4fa977af-c544-4116-8f61-8b04993e96be",
                "name": "Spidermans",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "307848c1-08f6-4a58-b339-27842d5e3708",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "66e3fe82-76e6-4506-8f37-8cfe1a787e48",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x upper body activation"
            }
        ]
    },
    {
        "id": "4e46ba99-7ecc-4c18-a2d0-16e70405ae6e",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "f57523ef-43d8-4d3f-9778-037620d847bb",
                "name": "D.B. Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passovers between sets"
            },
            {
                "id": "d4c9dbd4-a525-432f-8a4f-eb7d87376863",
                "name": "S.L.D.L. (Stiff Leg Deadlift)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8 each side",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: T.T.P. (Toe Touch Progression) between sets"
            }
        ]
    },
    {
        "id": "5e331fe2-f1fc-4b22-849d-434f7dd2fe42",
        "name": "Core Cash Out",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "88d5725b-18a3-4ccb-afba-41df3a87e149",
                "name": "Russian Twist",
                "sequence": 1,
                "prescribed_reps": "12 each side"
            },
            {
                "id": "8472016d-a518-4a19-ad38-5469b6296eb5",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "1 min"
            },
            {
                "id": "8f693ae1-39d8-4d38-8eba-0d7b4b9ed31d",
                "name": "Med Ball Toe Taps",
                "sequence": 3,
                "prescribed_reps": "12"
            },
            {
                "id": "ed92076b-5927-4d91-a9bf-76f782cba8a3",
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
        "id": "1dc9303f-3152-4557-9145-5a31530e1933",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "1230ddc4-dede-4367-badc-e44e08da6227",
                "name": "Clams",
                "sequence": 1,
                "prescribed_reps": "20x each",
                "notes": "Hip activation"
            },
            {
                "id": "c5bab701-fa23-4096-b1f5-030f5ea96685",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_reps": "20x",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "fa534281-0af9-46ea-90ed-f3d6470e0e84",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "59df9d81-79a1-4c9e-b65b-36aa40b4dc3e",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "011edf5e-b478-4874-8847-65a0efb72b68",
                "name": "Lunge & Reach",
                "sequence": 2,
                "notes": "Hip/T-spine"
            },
            {
                "id": "403c537c-e04b-41a9-91db-68bd28bf3ff0",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "eaa6fd9e-c4c1-4cd5-8462-fdc0d1442b68",
                "name": "Bear Crawl",
                "sequence": 4,
                "notes": "Full body warmup (meters)"
            },
            {
                "id": "be4413af-fffd-445f-b3b3-3da3328026c0",
                "name": "Push-Up Walkout",
                "sequence": 5,
                "notes": "Upper body/core"
            },
            {
                "id": "ca38b11c-b433-43a0-a9fb-6aacbade1c64",
                "name": "Quad Pull",
                "sequence": 6,
                "notes": "Quad stretch"
            }
        ]
    },
    {
        "id": "04b26c87-edd4-480d-878c-e32233584eaf",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "5568242a-6b4c-4157-b548-4ed0ff79d790",
                "name": "KB Swings",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "50x",
                "notes": "2 rounds total"
            },
            {
                "id": "0a620023-b3b1-4a1d-9ca6-4b7e0c19c030",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "40x",
                "notes": "2 rounds total"
            },
            {
                "id": "ab3b0ad3-8f73-4619-b969-8527a5cd1c3e",
                "name": "Goblet Squat",
                "sequence": 3,
                "prescribed_sets": 2,
                "prescribed_reps": "30x",
                "notes": "2 rounds total"
            },
            {
                "id": "d59b852c-ad3d-42a9-959a-e039417fb8f2",
                "name": "SA Press",
                "sequence": 4,
                "prescribed_sets": 2,
                "prescribed_reps": "20x each",
                "notes": "2 rounds total"
            },
            {
                "id": "110af0d0-1d48-43b3-908d-79a8b668bd84",
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
        "id": "ac85597b-5ff1-40ba-b51b-b6e5623bafe4",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "1017fbaf-d736-40e9-836d-647ae6798a6f",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Cardio warmup"
            },
            {
                "id": "e513a160-291b-4247-b85d-69bb32aa6fa5",
                "name": "SL Bridge",
                "sequence": 2,
                "prescribed_reps": "20x each",
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "3535c7d6-0cc0-49ee-af7b-56152ef204a5",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "908143ea-2498-42aa-9240-90a94403b362",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "b29ea10b-c8ab-40d3-9d94-4dd52b41b200",
                "name": "Quad Pull Hinge",
                "sequence": 2,
                "notes": "Quad stretch with hip hinge"
            },
            {
                "id": "22b6e7f1-2551-4edd-bb03-7a14f0a99fe6",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "f53d0e4a-91b1-41e5-8b83-b4b63822dc3b",
                "name": "Over Under",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "a43be787-412c-4e15-af35-5976f52109ad",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "88810ae2-e2da-446f-ae52-8698504e92b8",
                "name": "Piriformis",
                "sequence": 6,
                "notes": "Hip external rotation"
            },
            {
                "id": "b3078a20-726e-4f74-8ef0-6ed1ca3f0ebe",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x upper body activation"
            }
        ]
    },
    {
        "id": "77605918-dfa5-45a2-ac7b-e0eefa4fead6",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "b56dfe66-6863-4dc5-82bc-3c723341895b",
                "name": "Bar Thrusters",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "21e9ab19-cd37-4bb8-8099-7638f65ac0f2",
                "name": "Renegade Row",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10 each",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "92ea75f6-76c5-4006-a04f-d68480d28e22",
        "name": "Conditioning - EMOM 5 min (Repeat 2-3x)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "4987fcaf-4f24-4be5-b604-eead47165b2f",
                "name": "Plank",
                "sequence": 1
            },
            {
                "id": "e9da41e1-714a-4389-ad30-7e6c4909d72e",
                "name": "Goblet Squat",
                "sequence": 2
            },
            {
                "id": "4c88b8e8-fbba-4521-9ea9-f56bbc7e27cf",
                "name": "Jump Rope",
                "sequence": 3
            },
            {
                "id": "9398cc9d-9729-4ce7-9adf-bce03a1b071f",
                "name": "Dead Bugs",
                "sequence": 4
            },
            {
                "id": "9aa9d66d-3bf6-4594-997b-1e8c2c883efc",
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
        "id": "5df7e3d7-0da7-428f-a35f-d90344cc63d4",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "ace83b42-5549-4590-b67a-d9a82d4ef273",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "3 min",
                "notes": "Extended cardio warmup"
            }
        ]
    },
    {
        "id": "1b390415-2a19-4b9c-a448-fbfdbc81fc03",
        "name": "Intro - 12 min EMOM",
        "block_type": "functional",
        "sequence": 2,
        "exercises": [
            {
                "id": "eba9c93e-656d-4285-98e7-e3c32fafdb1d",
                "name": "Shoulder Taps",
                "sequence": 1,
                "prescribed_reps": "20"
            },
            {
                "id": "105b6145-c493-48a8-bcc6-07e01b942afb",
                "name": "Bike/Row",
                "sequence": 2,
                "prescribed_reps": "10 cal"
            },
            {
                "id": "88dd98bc-d7bf-424a-ae6a-e15b62fb13fb",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "12 each side"
            },
            {
                "id": "00386eb9-b321-40f7-9ff7-0be17ffa264f",
                "name": "Slamballs",
                "sequence": 4,
                "prescribed_reps": "15"
            }
        ]
    },
    {
        "id": "adbc401d-2bd6-4402-96be-5c555f030b74",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 3,
        "exercises": [
            {
                "id": "e1ed1425-7c88-4d5d-ae9f-0f97389b59f4",
                "name": "PVC Passover",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "1175d160-4805-4df5-b4a6-a13ba08330ba",
                "name": "Push-Ups",
                "sequence": 2,
                "notes": "10x upper body activation"
            },
            {
                "id": "be7ca5d9-e68f-4202-8b38-f853e7249a65",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "4d5ccf3b-16ba-4be0-b415-20ae26d42111",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "27533243-5f45-4928-b026-5ee438adf5b9",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "ba855760-53e7-4c3a-951c-a34343480bfc",
                "name": "High Knee Skip",
                "sequence": 6,
                "notes": "Dynamic warmup"
            }
        ]
    },
    {
        "id": "95c0824b-88e1-4ede-a655-001424a52cf9",
        "name": "Conditioning - 8 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "0525bd65-86de-43bb-9d15-5a0da8a8516b",
                "name": "Air Squats",
                "sequence": 1,
                "prescribed_reps": "20"
            },
            {
                "id": "864ef682-f0cc-4729-baed-553c63a0f374",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_reps": "10"
            },
            {
                "id": "46d214d9-e074-43bb-9da1-04b5026eddbc",
                "name": "TRX Rows / Pull-Ups",
                "sequence": 3,
                "prescribed_reps": "10"
            },
            {
                "id": "26d8e8ab-bbb3-4bd4-b710-37f073b6a60f",
                "name": "Push-Ups",
                "sequence": 4,
                "prescribed_reps": "5"
            }
        ]
    },
    {
        "id": "c7f46fd3-8e3e-431c-9515-048c29bfb14b",
        "name": "Finisher - 2 Rounds",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "032910d4-7540-4b2e-932f-d0178fe88841",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 2
            },
            {
                "id": "b974256d-aadf-4d6b-951e-e09d48f09ffa",
                "name": "Plank",
                "sequence": 2,
                "prescribed_sets": 2
            },
            {
                "id": "45aae971-e7f6-4e94-96cb-12ebaa232509",
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
        "id": "8a4f144a-ef01-4a6d-9b97-769865179972",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "49a24f43-7c95-4f75-b6fb-d8bd48b17a45",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "ebb72735-4f18-404b-8603-5c4f5cb0cec2",
                "name": "Monster Walks",
                "sequence": 2,
                "prescribed_reps": "2x",
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "12c648c8-9d01-40c5-b801-40454cdef9db",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "cb019b83-1386-43eb-86b8-7aad71db6836",
                "name": "Arm Circles",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "70f770c6-adf1-4613-8026-55fd293b2259",
                "name": "High Knee Pull",
                "sequence": 2,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "0419fcc3-91a5-4b78-8198-7fe56d154040",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "7007d8e8-5aca-4ce5-a6b9-b95b10ee1dc6",
                "name": "Bear Crawl (s)",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "5a9b2819-e723-4141-a547-d19ef3101289",
                "name": "Hamstring Walk",
                "sequence": 5,
                "notes": "Hamstring prep"
            },
            {
                "id": "3d2eac66-343b-4521-9e18-290ef1733885",
                "name": "Over & Unders",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "cc37ae97-4e0e-4fdd-b6da-fce720090ad5",
                "name": "Burpees",
                "sequence": 7,
                "notes": "10x - Full body warmup"
            }
        ]
    },
    {
        "id": "f15e00c0-2086-4c9b-b3c9-dc8415ac9f62",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "93830832-a303-4fc9-891a-b27bfd99e9cc",
                "name": "Sumo Deadlift",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: T.T.P (Touch Toes, Pulse) between sets"
            },
            {
                "id": "faf921f9-2e83-4fc4-a72a-aeeb6fec0a6e",
                "name": "Turkish Get-Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Light-Moderate (RPE 7). Rest: As needed between sides Accessory: PVC Passover between sets"
            },
            {
                "id": "b67958ea-a28d-462d-add5-bb0e21614e86",
                "name": "Single Leg Bridges",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "20 total",
                "notes": "Set 1: Bodyweight (RPE 6)"
            }
        ]
    },
    {
        "id": "3a1809df-a6a0-484f-8db1-415884aba801",
        "name": "Conditioning - Chipper (1 Round)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "5bf00225-9218-4a18-8fd6-4703bf798743",
                "name": "Sit-Ups",
                "sequence": 1,
                "prescribed_sets": 1,
                "prescribed_reps": "40",
                "notes": "1 rounds total"
            },
            {
                "id": "e2c5fd1e-0444-42b6-a85d-01dab89c87c7",
                "name": "Wall Sit",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "90\"",
                "notes": "1 rounds total"
            },
            {
                "id": "d79840f6-e2c0-480d-947a-839a3d023360",
                "name": "Jump Rope",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "150 s/u",
                "notes": "1 rounds total"
            },
            {
                "id": "7d96d6ef-58ac-4258-aa74-a044b5d37d38",
                "name": "SA KB Swing",
                "sequence": 4,
                "prescribed_sets": 1,
                "prescribed_reps": "20e",
                "notes": "1 rounds total"
            },
            {
                "id": "ef6831bb-0b3f-47b2-8048-00af38f4ee2d",
                "name": "Burpees",
                "sequence": 5,
                "prescribed_sets": 1,
                "prescribed_reps": "20",
                "notes": "1 rounds total"
            },
            {
                "id": "538c4291-fbe4-47f7-8344-c81731429f3d",
                "name": "Dead Bugs",
                "sequence": 6,
                "prescribed_sets": 1,
                "prescribed_reps": "20e",
                "notes": "1 rounds total"
            },
            {
                "id": "36fa8865-9fac-4e4a-ac8e-ed536bac7f04",
                "name": "Row/Bike",
                "sequence": 7,
                "prescribed_sets": 1,
                "prescribed_reps": "20 cal",
                "notes": "1 rounds total"
            },
            {
                "id": "1ed42697-603d-4cfc-94bc-b91844279ecd",
                "name": "Push-Ups",
                "sequence": 8,
                "prescribed_sets": 1,
                "prescribed_reps": "20",
                "notes": "1 rounds total"
            },
            {
                "id": "e6588f57-cbc8-4b8a-b2c6-9384052feb8a",
                "name": "TGU",
                "sequence": 9,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "1 rounds total"
            },
            {
                "id": "968caaf9-1cc8-4386-b4b5-6c00c8d375df",
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
        "id": "27104930-d1da-434c-bbb1-228e2b133ad3",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "00426f2b-0a9b-4bce-8eb5-ad0e08d3608e",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "794b797b-04c3-479e-96d5-be088118ce44",
                "name": "SL Bridges",
                "sequence": 2,
                "prescribed_reps": "20x",
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "9b97b666-ed38-40eb-9907-7025edeeae5e",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "7c630380-c7d5-4796-921a-347e0a16adb5",
                "name": "Lunge + Reach",
                "sequence": 1,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "31a921f5-10e4-4ade-adf4-55724bd2c4ae",
                "name": "Big Arm Circles",
                "sequence": 2,
                "notes": "Shoulder mobility"
            },
            {
                "id": "b36b39f4-c5a6-4f81-8519-47d0a0d18f9d",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring/hip flexor"
            },
            {
                "id": "294c1b97-59a5-482e-871d-360cc4fec61f",
                "name": "Hip Opener",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "88b3380a-1226-40a2-9c55-9bfdcc2f0751",
                "name": "Quad Pull",
                "sequence": 5,
                "notes": "Quad stretch"
            },
            {
                "id": "0ba3e115-59d6-473a-b074-d59fca3d307f",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body prep"
            },
            {
                "id": "4f3ed932-8ab6-4fda-9947-bbaca0faf51c",
                "name": "High Knee Skip",
                "sequence": 7,
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "1e441ebd-35f8-4059-a7e3-549ad941d589",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "5878be38-55ba-4c62-92a2-de0b9919fd53",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "ca86f154-2b41-4335-8cfc-57dcdee16dfe",
                "name": "Single Leg Squat",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Bodyweight/Light (RPE 7). Set 3: Bodyweight/Light (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "4943ee7b-1c68-4114-b274-76f0ba7c890b",
                "name": "Circuit (x2 Rounds)",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15",
                "notes": ""
            },
            {
                "id": "58f96ab2-e6d7-412c-a5c9-e09a6559d0b7",
                "name": "Slant Bar Twist",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 45 sec between sets Accessory: SL Rotation between sets"
            }
        ]
    },
    {
        "id": "87c5ffb9-76d6-41e0-bbbe-810fe251595c",
        "name": "Conditioning - 9 min EMOM",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "25695c2b-9bc4-486e-a90d-0de732a1ceea",
                "name": "Thruster",
                "sequence": 1,
                "prescribed_reps": "30\""
            },
            {
                "id": "7aa5825a-87d9-4096-baa6-db2f2c76c9f8",
                "name": "Pull-Up/Dead Hang",
                "sequence": 2,
                "prescribed_reps": "30\""
            },
            {
                "id": "d47d5307-41d0-4c61-a25f-3fc8f8d2f6cd",
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
        "id": "eecf4a24-0285-4ba7-b439-52398b6e3a5f",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "c7724a04-c8fa-4a4f-86b8-d535620e1289",
                "name": "Bear Crawl 4-Way",
                "sequence": 1,
                "prescribed_reps": "2x",
                "notes": "Full body activation"
            },
            {
                "id": "076dde3a-e11d-4d2a-b508-f3fb04070207",
                "name": "Row/Bike",
                "sequence": 2,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            }
        ]
    },
    {
        "id": "782fc940-464b-41e0-afbd-e86817161d77",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "67f649ab-8588-495f-b232-fe93403fbaf9",
                "name": "Arm Circles",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "40ced1c9-6a3c-49e8-8445-34da5100fd59",
                "name": "Hip Openers",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "1c728c92-bd20-4e6b-9465-89bf1a26251f",
                "name": "Push-Up Walkout",
                "sequence": 3,
                "notes": "Upper body/core prep"
            },
            {
                "id": "2bb91e0d-1213-473c-828b-93974dbeeeb6",
                "name": "High Knee Skip",
                "sequence": 4,
                "notes": "Lower body activation"
            },
            {
                "id": "9add254f-fce2-4500-900a-c31d8022e667",
                "name": "High Knee Pull",
                "sequence": 5,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "abe3dae6-582d-4d78-b909-333c37b99d31",
                "name": "PVC Figure 8",
                "sequence": 6,
                "notes": "Shoulder/T-spine mobility"
            }
        ]
    },
    {
        "id": "f1ae7fbb-8997-47b2-a23c-ad66d1387dea",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "def8a15d-787b-4992-947f-e0673775dcf8",
                "name": "Pull-Ups / Low TRX Rows",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8-10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "b6b9e2f7-11f8-49c3-9139-0168aa87014e",
                "name": "Slant Bar 3-Way Extension",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60 sec between sets Accessory: Pigeon stretch between sets"
            }
        ]
    },
    {
        "id": "5be5fd83-4cb1-4bf1-94ca-d77383fdf0ac",
        "name": "Conditioning - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "a93e5a2e-2aa3-4df9-98ee-d6748af5f342",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m"
            },
            {
                "id": "ca8d4183-e6de-42f8-a55a-3fc42046f638",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "12e"
            },
            {
                "id": "f54ed244-da51-4fd9-ae69-e1d4df746f20",
                "name": "Thrusters",
                "sequence": 3,
                "prescribed_reps": "10x"
            },
            {
                "id": "cd0cc6d4-5352-4d09-a069-2bd23cedee24",
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
        "id": "6cbf1b27-1d70-4461-b9cf-a598882885c3",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "2cdeebfd-2ba1-4793-82b8-9d1fe1cfa1d7",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "23ee3c92-d6ca-43ed-872b-ed50c748d0c0",
                "name": "Monster Walk",
                "sequence": 2,
                "prescribed_reps": "2x",
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "5d6eb8ae-a36a-47a1-bb4f-0a77507b82b0",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "ff7b2167-ddd3-4b26-a0e5-193a9f0a2d3e",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "0ed353ee-7bd9-4bb2-a485-0fbeabf0387f",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring/hip flexor"
            },
            {
                "id": "dfed167a-b51d-4c87-979b-0efb871dfbcb",
                "name": "PVC Passover",
                "sequence": 3,
                "notes": "Shoulder mobility"
            },
            {
                "id": "90b288cb-8b55-47af-9da4-74606ff7fef4",
                "name": "PVC Good Morning",
                "sequence": 4,
                "notes": "10x - Hip hinge prep"
            },
            {
                "id": "246f7f92-2720-4b38-8453-253721c86370",
                "name": "Spiderman",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "ef092921-c230-4ddf-b100-25e9b9b2f887",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "c18d003c-9990-4ff4-a176-65990de7c284",
        "name": "Intro - 9 min EMOM",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "7ebc602a-9014-4555-a504-635807c5a293",
                "name": "Plank",
                "sequence": 1,
                "prescribed_reps": "40\""
            },
            {
                "id": "dab244fa-cb8e-4677-a7cd-5de5b39a66e9",
                "name": "Bike/Row",
                "sequence": 2,
                "prescribed_reps": "40\""
            },
            {
                "id": "3ec7641b-9358-4d3f-a21c-f9788308f9b7",
                "name": "Sit-Up",
                "sequence": 3,
                "prescribed_reps": "40\""
            }
        ]
    },
    {
        "id": "fd9df814-b1a3-4050-9250-e412d423d3e2",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "56dbfc6f-80ef-4f4f-be6e-ac4493e06aa3",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "8bc7bc7b-3723-4f66-9880-84f8b3503149",
        "name": "Conditioning - 12 min AMRAP",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "4b7e2153-898c-43d9-a62e-e2d0c04f7c71",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "12 cal"
            },
            {
                "id": "7d2ef532-64c1-4f12-8d71-3c4de4e527b3",
                "name": "KB Push Press",
                "sequence": 2,
                "prescribed_reps": "10x"
            },
            {
                "id": "1d740731-a169-4049-97e4-aff258c551fa",
                "name": "Squats",
                "sequence": 3,
                "prescribed_reps": "10x"
            },
            {
                "id": "c2117976-4375-42ce-94ff-93fdcf6c7a92",
                "name": "V-Ups",
                "sequence": 4,
                "prescribed_reps": "10x"
            }
        ]
    },
    {
        "id": "c4fa4d20-7a6a-44de-98e2-2b0223f0518f",
        "name": "Conditioning - 2 Rounds",
        "block_type": "functional",
        "sequence": 6,
        "exercises": [
            {
                "id": "1f8b6965-050b-4238-a4af-a69d66884419",
                "name": "Rope Climb",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "1x",
                "notes": "2 rounds total"
            },
            {
                "id": "94a5a579-3f18-4c98-b679-38bfee41171d",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10x",
                "notes": "2 rounds total"
            },
            {
                "id": "dc52a522-39a9-42ac-9d73-86e3114b7ab1",
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
        "id": "f90f56db-3532-4563-9688-b7de16fd6279",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "7b487d87-fea8-4a9f-95c4-843e03b0cafb",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            }
        ]
    },
    {
        "id": "6bc98ee2-8a9e-46dc-908a-9ffaf97651a9",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "9e679be3-cbce-4491-bb60-c75ac3fa3bcc",
                "name": "Arm Circles",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "66e37abb-2fd3-4e59-8e89-6769b7d7a7b4",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "75d782ef-3376-4f77-8860-fe5ff84ad847",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "2c0ee1ba-2851-4fe8-ab42-f91ab3f29f14",
                "name": "Push-Up Walkout",
                "sequence": 4,
                "notes": "Upper body/core prep"
            },
            {
                "id": "ec56bba1-69b3-4293-814a-60accac19b50",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "c73dee30-e95f-4c26-9685-5552c92e508c",
                "name": "Spiderman",
                "sequence": 6,
                "notes": "Hip mobility"
            },
            {
                "id": "d9d99790-a45a-4a6d-bed3-73c1a857ea99",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "b5ae4ebf-bcaf-437a-9637-e9bffd784635",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "19e78773-5c2b-434b-8533-d8489304dda8",
                "name": "Single Leg Deadlift (SL DL)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 7). Rest: 60-90 sec between sets Accessory: TTP (Touch Toes, Pulse) between sets"
            },
            {
                "id": "7c36c022-af3c-4b2e-bf01-aaebf663712b",
                "name": "Renegade Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "6a643919-5e3d-4ec6-99eb-bd265e18754c",
                "name": "Box Jumps / Step-Ups",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "25 total",
                "notes": "Set 1: Bodyweight (RPE 7)"
            }
        ]
    },
    {
        "id": "1f6456f5-b394-4153-ad3b-2890b3b37dad",
        "name": "Conditioning - EMOM 10 min",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "8d2c302c-cacb-429a-91de-2d4c83cdce65",
                "name": "Burpees",
                "sequence": 1,
                "prescribed_reps": "10x"
            },
            {
                "id": "9a3d4071-76ae-4fb2-a138-d60b977cfd6e",
                "name": "TGU",
                "sequence": 2,
                "prescribed_reps": "1e"
            }
        ]
    },
    {
        "id": "b805527e-119d-4335-a227-17daf35feb4d",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "47c80444-8c8f-43b4-a72b-8405288dc51c",
                "name": "KB Swings",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10x",
                "notes": "4 rounds total"
            },
            {
                "id": "6e2f57df-93b5-48e2-8a79-dc0d4e7a7491",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "4 rounds total"
            },
            {
                "id": "2a471d82-8c92-44a8-9aab-4ead78a61f80",
                "name": "Slamball",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10x",
                "notes": "4 rounds total"
            },
            {
                "id": "3e5572ac-59ad-43c3-a7ca-85e3be6fe249",
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
        "id": "e29e11ba-dc12-4bc1-806f-2bb8175a6c9e",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "53a4b230-c3bc-473a-b040-0009210ba3ad",
                "name": "Clams",
                "sequence": 1,
                "prescribed_reps": "20e",
                "notes": "Glute activation"
            },
            {
                "id": "88c57305-95eb-4de6-9283-cae2bf3f82bc",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_reps": "20x",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "f2d857a2-d7e7-4153-abb2-3b561b88f135",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "9cd9839f-2af5-440d-b497-dd05ffde20c5",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "c9a14107-601a-4445-81d8-9d225e4a25b1",
                "name": "Lunge & Reach",
                "sequence": 2,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "e6ba06bc-962f-4feb-bcc7-f79db6f66e72",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "522f6aa9-4919-430c-9bdf-db62a414af58",
                "name": "Bear Crawl (m)",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "04a49005-8487-4e2d-b640-e3fbce40d7e3",
                "name": "Push-Up Walkout",
                "sequence": 5,
                "notes": "Upper body/core prep"
            },
            {
                "id": "fca7a084-d7dd-429f-9116-a8583231c7f6",
                "name": "Quad Pull",
                "sequence": 6,
                "notes": "Quad stretch"
            },
            {
                "id": "7091f9f4-896a-41e2-aa32-da40df433465",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "bf2ed244-8d03-4bcf-af6b-e9fd98c50050",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "fff197a4-09c6-4f8e-ad17-abfe45f364b9",
                "name": "KB Front Squat",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "8ea7e34f-7ff6-4507-a262-475df1921c1b",
                "name": "Cardio Finisher",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "30 cal",
                "notes": ""
            }
        ]
    },
    {
        "id": "95309b8e-e1d8-4210-8439-2fa81c5b039f",
        "name": "Conditioning - Circuit 1",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "78619269-3591-4dd3-ab96-5e1fd535372b",
                "name": "Bosu Mtn Climbers",
                "sequence": 1,
                "prescribed_reps": "30\""
            },
            {
                "id": "a6ea376d-edc6-4c19-933d-0856c727ba76",
                "name": "OH PVC Squat",
                "sequence": 2,
                "prescribed_reps": "10x"
            },
            {
                "id": "170f5a5f-5550-4a35-9fe8-3628551bcf1d",
                "name": "Sit-Ups",
                "sequence": 3,
                "prescribed_reps": "15x"
            },
            {
                "id": "627776a2-a9fe-4d17-af99-1634325cffcc",
                "name": "Dec. Shoulder Taps",
                "sequence": 4,
                "prescribed_reps": "10e"
            },
            {
                "id": "5910f323-d618-43f5-9321-4fdbd1ce2c97",
                "name": "SA Press",
                "sequence": 5,
                "prescribed_reps": "10e"
            }
        ]
    },
    {
        "id": "0e9e6463-f353-4ed4-9666-f327b8d013a2",
        "name": "Conditioning - 3 Rounds",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "cade2541-0cdf-4bcf-aa52-a5e6d04a851f",
                "name": "Row",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "250m",
                "notes": "3 rounds total"
            },
            {
                "id": "3676a1a8-43c6-42b5-9fec-d47efdfffd43",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12e",
                "notes": "3 rounds total"
            },
            {
                "id": "d7cf7912-3806-4d7e-ac6c-64d291370360",
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
        "id": "472def8c-0f1b-47c4-85a8-45f104890869",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "d148af39-327d-436c-9125-a74958c18f3e",
                "name": "Chin-Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 9). Rest: 90-120 sec between sets Accessory: Bicep/Lat stretch between sets"
            },
            {
                "id": "c0704e1c-fcf1-44dd-8e29-aaea8c9e64f6",
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
        "id": "5884ff28-e4b2-4f93-994f-12f461522564",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "bf616391-d3d9-40f2-ae81-e9986bd4438c",
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
        "id": "76cc892a-7c45-4295-8525-4375eecc009b",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "5cd01a83-ecb9-4762-a29e-b1a1ea15fec2",
                "name": "Bench Press (BB or DB)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "5",
                "notes": "Set 1: Moderate-Heavy (RPE 7). Set 2: Moderate-Heavy (RPE 7). Set 3: Heavy (RPE 8). Set 4: Heavy (RPE 8). Set 5: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "2d8007e7-94b7-4f5c-a2f7-acceae9efab1",
                "name": "Conditioning Block A",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "35 cals",
                "notes": ""
            },
            {
                "id": "9ec59a01-d69e-44b1-b55c-8a4e457c9b73",
                "name": "Bent-Over-Rows",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "8 each",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "542013fd-fc17-489d-aaa7-6865d329c6eb",
                "name": "Conditioning Block B - 25-20-15",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "",
                "notes": ""
            },
            {
                "id": "bed30f31-10d5-470f-8e07-77aedea5dd2d",
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
        "id": "74ff8c7f-8c98-4969-9300-bdb38932c8eb",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "b9aabeb8-4af2-4fd6-a336-7a17c4d6bb62",
                "name": "Half-Kneel Single-Arm Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8 each",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "602c324f-a16a-4bd9-a977-57a05a97ff8b",
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
        "id": "3682f917-496b-411e-9aa1-1ff5e1ba7ffc",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "32494a44-fede-4190-9206-3f05c7357d16",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light-Moderate (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "1119a11e-7196-4e35-a22d-150e9a086bd9",
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
        "id": "259751d2-e446-4c06-8d92-407ce899caf8",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "9a2da294-6012-4bd1-bf67-7e21cb172161",
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
        "id": "39392f50-7ecc-47c4-bf9f-544d90d77035",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "72ff9082-317c-496a-aacd-44784f719ca1",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_reps": "1 min",
                "notes": "Light cardio warmup"
            },
            {
                "id": "9f21a30b-a7e2-4fd1-b978-1b7a935563ba",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "1 min",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "f08b8ed1-0f7a-4e49-bd0b-7873f5ba2c63",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "a49e3891-5a6b-4517-8468-d104ab34274a",
                "name": "Hip Opener",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "ff0f1a0b-703f-490d-b347-a8b2afcf78f9",
                "name": "Spiderman",
                "sequence": 2,
                "notes": "Hip flexor/groin"
            },
            {
                "id": "790c1a2c-e44a-4962-b2f5-9376850cc8a2",
                "name": "High Knee Pull",
                "sequence": 3,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "f61d94ed-dac5-4865-a64f-8a5f66cef3f4",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Adductor stretch"
            },
            {
                "id": "a33292ba-8ffa-4cbf-aa39-c703a478cf1f",
                "name": "Quad Pull",
                "sequence": 5,
                "notes": "Quad stretch"
            },
            {
                "id": "115c220c-8d42-41d3-b65f-fde5e98378b6",
                "name": "PVC Passover",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "9ffa4a16-b9fc-477a-9af0-28e359f349be",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x - Upper body activation"
            }
        ]
    },
    {
        "id": "5813d4ce-4e1d-42ae-9371-13761382c028",
        "name": "EMOM 9 min",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "53501df5-407f-40d4-8eac-e2f5f01e8f70",
                "name": "Slamballs",
                "sequence": 1,
                "prescribed_reps": "15",
                "notes": "Full extension"
            },
            {
                "id": "bc223bc9-d5ba-40d1-9a10-6cf8bd50f791",
                "name": "Farmer Carry Hold",
                "sequence": 2,
                "prescribed_reps": "45\"",
                "notes": "Heavy KBs"
            },
            {
                "id": "7646f665-1649-4fdc-afa4-b1fbd5bff2e8",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "15e",
                "notes": "Controlled"
            }
        ]
    },
    {
        "id": "a1d873e9-ff48-4342-900d-c028e89ae5fb",
        "name": "Cash Out",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "d44acc1d-dc06-4e4c-bf28-6a8fb65f72f0",
                "name": "Russian Twist",
                "sequence": 1,
                "prescribed_reps": "20e",
                "notes": "Weighted if possible"
            },
            {
                "id": "2ff1495f-72b7-48d5-a2af-589bb2c874cd",
                "name": "Monkey Bar",
                "sequence": 2,
                "prescribed_reps": "1x",
                "notes": "Full traverse"
            },
            {
                "id": "e98ca206-4f51-4628-b78d-01fba9498d5c",
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
        "id": "c64946bf-4197-499f-9488-ec625d542ad4",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "56df5e63-73e1-409d-aced-8b109180f59a",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "300m",
                "notes": "Low intensity warmup"
            },
            {
                "id": "73a97da4-60f4-4bba-839b-2614484fd201",
                "name": "Air Squat",
                "sequence": 2,
                "prescribed_reps": "30x",
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "f6210bdc-fc56-47e3-a166-f172dab1a945",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "1cba34d7-dcfe-49f7-8354-bda2fe097ba3",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "3e1e4ad5-c1d5-4507-a484-2c225ee41f3e",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "844391d4-ce54-485f-b254-ba403c7c2657",
                "name": "High Knee Skip",
                "sequence": 3,
                "notes": "Hip flexor activation"
            },
            {
                "id": "cccade41-ffc2-426f-90e6-10674b655010",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "a125c789-6dbb-44ba-87d4-f83ef37669eb",
                "name": "Hip Openers",
                "sequence": 5,
                "notes": "Hip mobility"
            },
            {
                "id": "b3012641-4f87-4ca9-a946-4f8c14a5fe06",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body activation"
            }
        ]
    },
    {
        "id": "20745330-056a-438f-80df-8ca81989f128",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "3aa1fbdb-b8be-45e8-a966-92a23831fffb",
                "name": "Half-Kneel Single-Arm Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "c4ba1cce-4d12-432f-9f26-62e0a5f149ba",
                "name": "Turkish Get-Up (TGU)",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Moderate (RPE 7). Rest: As needed between sides Accessory: Single-Leg Rotation between sets"
            }
        ]
    },
    {
        "id": "7e116650-cebb-4ba4-9d1a-0eb83fb1f2a5",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "bd2c5f22-cb90-4d1c-807a-9cf36f8fafe5",
                "name": "Jump Rope",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "50",
                "notes": "Single-unders. 4 rounds total"
            },
            {
                "id": "83488f31-7d0c-47c4-b306-c001b45732d3",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Weighted. 4 rounds total"
            },
            {
                "id": "81593330-c9c2-4250-82db-0684dda3a716",
                "name": "Half-Kneel Chop",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "Cable or band. 4 rounds total"
            },
            {
                "id": "153bc71e-2779-4bfa-a7d8-bbabe2fe7359",
                "name": "Lateral Skater",
                "sequence": 4,
                "prescribed_sets": 4,
                "prescribed_reps": "15e",
                "notes": "Explosive. 4 rounds total"
            },
            {
                "id": "6a41c67f-f3a5-4a65-bb93-7ecc5f82c9bb",
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
        "id": "fea25eff-dc79-4fa9-a3ce-d8ba636ae764",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "785d1c06-47b0-4463-821b-2622dba610f1",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "01cdfe49-0fd6-4693-955a-527d4a24de78",
                "name": "Air Squats",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Lower body activation"
            },
            {
                "id": "2e739bd3-4dec-4f3f-a555-a6721dfe4789",
                "name": "Push-Ups",
                "sequence": 3,
                "prescribed_reps": "10",
                "notes": "Upper body activation"
            }
        ]
    },
    {
        "id": "96431c73-43a6-4083-933b-3f5b63856fc4",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "cc0a72e3-f284-47e2-982d-535a70c20a3e",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "6045cceb-abb9-42db-94eb-d51ceb72adaa",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "79dc7923-7dfa-42c2-8ac3-87841738b20a",
                "name": "Spiderman",
                "sequence": 3,
                "notes": "Hip flexor/groin"
            },
            {
                "id": "a75c82a0-94f2-4822-b376-d74b3ae20731",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "a34da4fa-f103-4e95-8349-b9d54b95b9aa",
                "name": "Lunge & Twist",
                "sequence": 5,
                "notes": "Hip/thoracic mobility"
            },
            {
                "id": "7ccf2df2-90e9-4e76-8a42-7a1765de3564",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body activation"
            }
        ]
    },
    {
        "id": "c1142c89-5430-468d-8b8b-5699dcdcccdf",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "d4e4847a-722c-478b-a5dc-fc140e15cb73",
                "name": "EMOM 12 min",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": ""
            },
            {
                "id": "c4f796ce-ae27-4bcb-ba29-509532e6ed5f",
                "name": "Single-Leg Deadlift",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Handstand Walk practice between sets"
            }
        ]
    },
    {
        "id": "9a7418e4-1c53-4a77-84f8-0c9b57972186",
        "name": "Conditioning - 6 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "8ec5242b-d3a0-4d66-81c2-c18a81a12397",
                "name": "Hanging Knee Raises",
                "sequence": 1,
                "prescribed_sets": 6,
                "prescribed_reps": "8",
                "notes": "Controlled. 6 rounds total"
            },
            {
                "id": "0e6f8124-339d-4769-af57-78839524a011",
                "name": "Thrusters",
                "sequence": 2,
                "prescribed_sets": 6,
                "prescribed_reps": "8",
                "notes": "Light-moderate. 6 rounds total"
            },
            {
                "id": "3094b508-d4a1-47fc-9626-37c19b3ff73c",
                "name": "Row/Bike",
                "sequence": 3,
                "prescribed_sets": 6,
                "prescribed_reps": "8 cal",
                "notes": "Fast pace. 6 rounds total"
            },
            {
                "id": "0e3e075f-731a-4aa8-8796-fdc1f8053a85",
                "name": "KB Swing",
                "sequence": 4,
                "prescribed_sets": 6,
                "prescribed_reps": "8",
                "notes": "Hip drive. 6 rounds total"
            },
            {
                "id": "3c2f89b2-7a52-4c76-8122-c86a318a688d",
                "name": "Bike/Row Sprint",
                "sequence": 5,
                "prescribed_sets": 6,
                "prescribed_reps": "30\"",
                "notes": "Max effort. 6 rounds total"
            },
            {
                "id": "b1c4d76d-b777-42df-96d9-5f3f957b706b",
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
        "id": "e318946b-8e67-497e-9d16-4fba227e1fe7",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "c2a79435-13d9-4bf6-bb20-4b55df914922",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "b42fab28-7730-4048-aa50-97c748a07602",
                "name": "Monster Walk",
                "sequence": 2,
                "prescribed_reps": "2x",
                "notes": "Glute activation with band"
            }
        ]
    },
    {
        "id": "576be7db-b93d-492e-b271-9bc255d72bce",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "02ec9672-5ace-4a20-b805-4d4d3286d372",
                "name": "PVC Passover",
                "sequence": 1,
                "notes": "Shoulder mobility"
            },
            {
                "id": "0fe45d4a-5334-4dc4-b988-faa5bf9957a2",
                "name": "Side Lunge",
                "sequence": 2,
                "notes": "Adductor stretch"
            },
            {
                "id": "9c711f12-242c-4336-84e1-8e0c163d9b2e",
                "name": "Hamstring Walk",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "c073a563-7091-4c21-aef9-34e666888627",
                "name": "High Knee Pull",
                "sequence": 4,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "d724c38a-748f-4f39-a725-fbf89afc4bc6",
                "name": "Quad Pull",
                "sequence": 5,
                "notes": "Quad stretch"
            },
            {
                "id": "63ab1a36-62cc-48c2-84b3-9a0da2004009",
                "name": "High Knee Skip",
                "sequence": 6,
                "notes": "Hip flexor activation"
            },
            {
                "id": "532a86d1-d90f-4496-b37c-b9f19d961788",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x - Upper body activation"
            }
        ]
    },
    {
        "id": "393fa061-729a-4070-830c-0cf0844b508a",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "6f637ced-a96f-4507-9e94-abf1f911d148",
                "name": "Hand-Release Push-Ups",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 7). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "c75a0c3d-c2b1-4a45-8fe4-4c16cb153ff5",
                "name": "Single-Leg Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "6e",
                "notes": "Set 1: Bodyweight/assisted (RPE 6). Set 2: Bodyweight/assisted (RPE 7). Set 3: Bodyweight/assisted (RPE 7). Set 4: Bodyweight/assisted (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "65b2035c-7147-4860-9a3d-6fe3d79aaa66",
                "name": "KB Strict Press",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "9a87746a-b156-4d6d-aefe-5334012ebd2e",
        "name": "Conditioning - Stations (12 min AMRAP)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "33df09d6-c9f4-4aaa-b88d-f09429ff6748",
                "name": "Step-Up/Box Jump",
                "sequence": 1,
                "notes": "Choose based on ability"
            },
            {
                "id": "a8131e8c-20b2-4530-8f72-202521a2c612",
                "name": "Plank",
                "sequence": 2,
                "notes": "Hold steady"
            },
            {
                "id": "807261e1-95c4-4627-99bf-b8e0030697e7",
                "name": "Devils Press",
                "sequence": 3,
                "notes": "Light DBs"
            },
            {
                "id": "5b902f3b-4949-4f4d-b60c-8c0b95102c53",
                "name": "Russian Twist",
                "sequence": 4,
                "notes": "Weighted"
            }
        ]
    },
    {
        "id": "ac7c133d-65cc-41e7-92d5-523fbc3cfc33",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "652926db-e01b-4ef8-99cd-5255766e7326",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "40 cal",
                "notes": "Steady pace"
            },
            {
                "id": "dedf1374-20b9-463c-8bfe-82319e9242ab",
                "name": "Med Ball Toe Tap",
                "sequence": 2,
                "prescribed_reps": "40",
                "notes": "Fast feet"
            },
            {
                "id": "bce4f34d-45c9-4aff-a96a-028524a495bb",
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
        "id": "cadbf229-18b8-4b34-a565-b7b7939c698d",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 1,
        "exercises": [
            {
                "id": "04eef1ac-b2ef-41d8-8b37-7a620a359ff7",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "e7380954-4574-4735-bf59-5b46029ada8d",
                "name": "Handstand Walk",
                "sequence": 2,
                "notes": "Shoulder/core activation"
            },
            {
                "id": "1e4efaf0-77d9-4209-8bd1-ce170178d5e3",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "87bf86bc-d7fa-4a83-b59f-f00ed918b86b",
                "name": "Bear Crawl (medium)",
                "sequence": 4,
                "notes": "Full body activation"
            },
            {
                "id": "b979c785-a6cf-4b3b-9d46-ae029d3340e5",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "7a7e9410-fc9f-49e4-8ae3-41733b8794a8",
                "name": "Single-Leg Rotation",
                "sequence": 6,
                "notes": "Hip/core mobility"
            }
        ]
    },
    {
        "id": "d6d2feb9-2f31-4651-b031-da2cca23e842",
        "name": "Strength",
        "block_type": "push",
        "sequence": 2,
        "exercises": [
            {
                "id": "9bb73f98-a711-497e-bea9-6ab5389293a6",
                "name": "Single-Leg Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight/assisted (RPE 7). Set 2: Bodyweight/assisted (RPE 7). Set 3: Bodyweight/assisted (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "5802a959-0fe7-4429-ad8f-faa4d01811aa",
                "name": "Pull-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 8). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 9). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            }
        ]
    },
    {
        "id": "74602388-c25f-4d51-9526-61c6e06f7767",
        "name": "Core Challenge - Chipper",
        "block_type": "core",
        "sequence": 3,
        "exercises": [
            {
                "id": "7e3cb48a-0dc1-4d6a-b9a2-8624f83f804f",
                "name": "KB Swing",
                "sequence": 1,
                "prescribed_reps": "50"
            },
            {
                "id": "4ff7a10b-4cab-49cd-bf26-d10b45221b38",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "40"
            },
            {
                "id": "bc627e34-188c-4b11-a580-b3122329d14f",
                "name": "Overhead Squat",
                "sequence": 3,
                "prescribed_reps": "30"
            },
            {
                "id": "44f801c3-3b8e-4e55-8392-b92feb379a9b",
                "name": "Burpees",
                "sequence": 4,
                "prescribed_reps": "20"
            },
            {
                "id": "8aaff07b-c239-4953-bcf2-a7ed168db74b",
                "name": "TGU",
                "sequence": 5,
                "prescribed_reps": "10"
            },
            {
                "id": "3aa00928-e652-4af0-93c3-8c5d86bb637f",
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
        "id": "311e1f44-e102-4229-b504-216c38e4d896",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "5fb2b7a9-d33e-4f8a-8c4c-e728efba7d6c",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Low intensity warmup"
            },
            {
                "id": "4865968c-9849-47e5-8fbb-aff461df9647",
                "name": "Air Squats",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Lower body activation"
            },
            {
                "id": "3f663bdb-84fc-45c7-b5cb-3d692ff5d855",
                "name": "Push-Ups",
                "sequence": 3,
                "prescribed_reps": "10",
                "notes": "Upper body activation"
            },
            {
                "id": "c2a369c2-5a00-4e5b-9517-21d9292b3edc",
                "name": "Sit-Ups",
                "sequence": 4,
                "prescribed_reps": "10",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "0d6249be-31fd-4d3a-8e42-880a68849d9a",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "97463db1-a270-42b0-b7e2-59371ae69661",
                "name": "Piriformis Stretch",
                "sequence": 1,
                "notes": "Hip mobility"
            },
            {
                "id": "577a5075-78df-4740-b47d-bcad2acabd5c",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "c2964279-ac72-4f2f-a53e-1b3b9e6a8ba0",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "fdc374e5-0355-4877-af0f-1fc061fd25bc",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip flexor/groin"
            },
            {
                "id": "92f74581-2ea2-499d-9a50-cb42a096bc7c",
                "name": "Lunge & Twist",
                "sequence": 5,
                "notes": "Hip/thoracic mobility"
            },
            {
                "id": "1a0fe7be-5288-4a6d-8855-c3da846070c1",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "f8b851ff-2bae-4ee1-be3f-24c52f26c6cb",
                "name": "High Knee Skip",
                "sequence": 7,
                "notes": "Hip flexor activation"
            },
            {
                "id": "c09d994b-9d11-451c-9626-523329747f8e",
                "name": "Push-Ups",
                "sequence": 8,
                "notes": "10x - Upper body activation"
            }
        ]
    },
    {
        "id": "e97b37e8-e9d7-4583-8958-12952deac852",
        "name": "Core Intro - 3 Rounds",
        "block_type": "core",
        "sequence": 3,
        "exercises": [
            {
                "id": "fb73788a-4be7-404c-b3c7-a118dd09689f",
                "name": "Hanging Knee to Chest",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Controlled"
            },
            {
                "id": "9248a3fc-0a43-41e6-8449-d3a30fd14b09",
                "name": "Bosu Mountain Climber",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "20e",
                "notes": "Fast pace"
            },
            {
                "id": "40aafaf1-a632-4681-8dfe-3fcbdf905479",
                "name": "Plank",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "30 sec",
                "notes": "Hold steady"
            }
        ]
    },
    {
        "id": "5652593b-8218-4b83-8319-1cac00849366",
        "name": "Cool Down - 2 Rounds",
        "block_type": "recovery",
        "sequence": 4,
        "exercises": [
            {
                "id": "74dfb4b8-79df-4a30-9bd9-d8c4904b4908",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 2,
                "prescribed_reps": "1 min",
                "notes": "Easy pace"
            },
            {
                "id": "5a460859-a6d6-4a6b-8014-8fedef42e3f1",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10",
                "notes": "Controlled"
            },
            {
                "id": "a26956e9-b781-42cf-b246-408fcd49cbcf",
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
        "id": "42a74ffc-6f3b-48a1-baa9-cb5c1922b038",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "83426a15-409b-4cf7-95ab-e229698a489c",
                "name": "KB Strict Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "ad167bfc-0401-4614-90dc-ad0b66a04cf2",
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
        "id": "b2197ee0-3ad0-4ce8-9ef5-a15ab695612f",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "515ffcc0-85af-4cb7-ae06-69795fabfde5",
                "name": "Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "54c178c6-2aaa-4500-9c60-327b7b212235",
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
        "id": "44ba0122-254d-4bea-b8cf-e41703d6695b",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "73d4d07e-8503-4929-90cb-671f160883cb",
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
        "id": "ad786f3c-f379-41bb-8078-cfa1a1a45d73",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "e39b6905-165d-4bfb-bd4a-acce7d58fd67",
                "name": "Single-Leg Squat",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Bodyweight/Light (RPE 7). Set 3: Bodyweight/Light (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "46da0e6c-62bd-4ca8-b2d2-bafc56501161",
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
        "id": "e55ea73e-0b43-4461-b56f-560cbdc2b9f7",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "724169be-2b8f-4c7c-8fb3-cd6badb8a186",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "06d4745d-119c-4add-92c7-f7c1fedec027",
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
        "id": "73c7c680-563b-4112-8fd5-4d0b167318f9",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "4b0c9715-37ec-4af0-a737-9d84cca6f471",
                "name": "Renegade Rows",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "e1336eaf-bd4e-4848-bc95-4ce3d4125472",
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
        "id": "0ec1dfd3-0e6d-4b6d-9ed9-5fcfb00cb90a",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "f42da3c3-7b5b-41cc-9090-6e7ad7623da0",
                "name": "Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "cd7189e0-5bd6-4420-b0b8-94b888e46ae4",
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
        "id": "98f211a7-20aa-401d-aceb-57d278dbd123",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "a1d60ad6-76ba-458a-bfae-f11f253bc442",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light pace"
            },
            {
                "id": "7c0b070e-8dcd-49cd-802f-c1e6b89697f6",
                "name": "Monster Walk",
                "sequence": 2,
                "prescribed_reps": "2x",
                "notes": "Hip activation"
            }
        ]
    },
    {
        "id": "519c0afb-4686-4f41-8953-86a22832ae2f",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "753a4be6-4fcb-4c8b-8b4b-3968a23179f3",
                "name": "Air Squats",
                "sequence": 1,
                "notes": "10x - Lower body prep"
            },
            {
                "id": "d2f74844-a0ce-4ed5-b274-7f9b799bf2a4",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Hip flexor stretch"
            },
            {
                "id": "0c42e65c-7827-4611-aa3c-a97156f48639",
                "name": "Arm Circles",
                "sequence": 3,
                "notes": "Shoulder mobility"
            },
            {
                "id": "8c723da8-20f2-4b5e-ab4a-090f37fc4797",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "61f96cb5-cf75-4696-85f1-106169551434",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warmup"
            },
            {
                "id": "3ffdf764-264f-4a60-869c-b55218361d90",
                "name": "Toy Soldier",
                "sequence": 6,
                "notes": "Hamstring activation"
            },
            {
                "id": "b7de655e-1087-412f-af18-de9f79cb6207",
                "name": "Push-Ups",
                "sequence": 7,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "8dda0fa8-348a-4a97-9b0b-5aa28cce66d8",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "af23ec51-0a8a-4366-a6a5-186bd411e4d9",
                "name": "Goblet Squats",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 6). Set 4: Moderate (RPE 7). Set 5: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "dfad604d-5276-4f13-8021-84ffb2a2b7c9",
                "name": "Hand-Release Push-Ups",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "1c7b3edb-17c0-4a37-9a56-a35ea1383bd9",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "e2d84b6f-305b-43e3-896a-7db3b54e46c6",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "15 cal",
                "notes": "4 rounds total"
            },
            {
                "id": "50d9a875-8661-4d05-8a4b-7d1eb955ada1",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "4 rounds total"
            },
            {
                "id": "4528a420-f7fb-4004-b515-1ffe029e1322",
                "name": "Slamballs",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "15",
                "notes": "4 rounds total"
            },
            {
                "id": "8fde9323-831f-4b59-98fa-b517444af2f4",
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
        "id": "451484d7-b006-44ea-ac56-597b0f22153d",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "6222f4b9-29b1-42c7-9258-4cbc1e08c409",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light pace"
            },
            {
                "id": "1f489933-0f2d-4266-864a-7184a809ee10",
                "name": "Monster Walk",
                "sequence": 2,
                "prescribed_reps": "2x",
                "notes": "Hip activation"
            }
        ]
    },
    {
        "id": "c37516a9-0530-4ec5-a6e7-76319ff3eb3f",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "345dd8b8-9054-4283-abf9-dba0744fe4ce",
                "name": "Push-Ups",
                "sequence": 1,
                "notes": "10x - Upper body prep"
            },
            {
                "id": "3986e6ae-1041-4550-b32a-a5129cf6cff6",
                "name": "Side Lunges",
                "sequence": 2,
                "notes": "Hip adductor mobility"
            },
            {
                "id": "123bf42f-fcf6-4e58-a1a9-2e952e3d36a0",
                "name": "High Knee Pull",
                "sequence": 3,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "c0a9b8f9-420c-46c6-8f50-05089ac45cd1",
                "name": "Quad Pull",
                "sequence": 4,
                "notes": "Quad stretch"
            },
            {
                "id": "c579c759-cf2a-4a74-a788-559153c0e462",
                "name": "Hamstring Walk",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "7e06f09b-620f-421b-8a6b-8e51d05f1ff6",
                "name": "PVC Passovers",
                "sequence": 6,
                "notes": "Shoulder mobility"
            },
            {
                "id": "6015b6e4-27f0-4f1c-bc5f-37cd3c5e6fde",
                "name": "High Knee Skip",
                "sequence": 7,
                "notes": "Dynamic warmup"
            }
        ]
    },
    {
        "id": "5787b2f0-1da3-45f9-a6ce-c7440c2ff404",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "622027bd-5ed8-4ccf-b170-0b3f618b9445",
                "name": "D.B. Bench Press \"Heavy\"",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "6",
                "notes": "Set 1: Heavy (RPE 7). Set 2: Heavy (RPE 7). Set 3: Heavy (RPE 8). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "a3d3b771-b4af-4986-84cd-6745cfad6879",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 2,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Bodyweight/Light (RPE 6). Rest: 60 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "4b8a11e8-7e31-4e38-be2a-ffb31c78c232",
        "name": "Conditioning - The Eight Crazy Nights of Hanukkah! (20 min)",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "99d484f2-3673-435e-8931-ed86f8fb455f",
                "name": "Front Squats",
                "sequence": 1,
                "prescribed_reps": "8"
            },
            {
                "id": "96d08d49-7faf-4e21-8e9e-217f8280fcb4",
                "name": "Hanging Knees to Chest",
                "sequence": 2,
                "prescribed_reps": "8"
            },
            {
                "id": "46756ae1-d903-4efd-8998-d195ab05b67e",
                "name": "KB Push Press",
                "sequence": 3,
                "prescribed_reps": "8"
            },
            {
                "id": "ac4701a2-01a5-4c7e-8bdb-811899da1921",
                "name": "Row/Bike",
                "sequence": 4,
                "prescribed_reps": "8 cal"
            },
            {
                "id": "2e19a33b-54e1-4344-a748-80aee4107332",
                "name": "V-Ups",
                "sequence": 5,
                "prescribed_reps": "8"
            },
            {
                "id": "ae7012bd-1b01-4220-b29b-70a2a475086f",
                "name": "Box Jump/Step-Ups",
                "sequence": 6,
                "prescribed_reps": "8"
            },
            {
                "id": "afd107ff-db81-4fe4-8da6-2c4932dee183",
                "name": "Dead Bugs",
                "sequence": 7,
                "prescribed_reps": "8e"
            },
            {
                "id": "f3a4e13a-7077-45c8-b44d-3f36c8938e17",
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
        "id": "675d7e79-3dc2-45f0-abf2-6462e794c577",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "a92c8270-813c-4157-a4ab-3a1e4d1fd614",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light pace"
            },
            {
                "id": "cf92cc17-30f9-44ef-b34f-6bec1e44c746",
                "name": "SL Bridges",
                "sequence": 2,
                "prescribed_reps": "20x",
                "notes": "Glute activation"
            },
            {
                "id": "9c3f64db-8228-4120-8a6b-beb2f97e678e",
                "name": "Push-Ups",
                "sequence": 3,
                "prescribed_reps": "10x",
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "a5164484-8e91-414d-92fe-d3baa7c3cdf2",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "9bb9939a-8a58-4fcb-90e1-edfdc56c2297",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "77e09795-fcec-4f0c-a97c-199c7ebb32d1",
                "name": "Lunge + Twist",
                "sequence": 2,
                "notes": "Hip/T-spine mobility"
            },
            {
                "id": "af8c3b0a-d765-4c28-b4ee-5bf67f343d9d",
                "name": "Spiderman",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "c0bc7159-adf5-4e17-a511-ff263dacc992",
                "name": "Quad Pull",
                "sequence": 4,
                "notes": "Quad stretch"
            },
            {
                "id": "4a7db802-d741-4292-90b2-c9587972d56f",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "623a988e-6cbd-4079-8669-5c4d952e20d5",
                "name": "Air Squats",
                "sequence": 6,
                "notes": "10x - Lower body prep"
            }
        ]
    },
    {
        "id": "7d0234dc-f834-47a8-94a0-5b14e44303b0",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "fbc7ac73-2742-4a91-b8b3-9bae1e7334d2",
                "name": "Slant Bar 3 Extensions",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 6). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 7). Rest: 60 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "7e8ca29e-1e54-4655-ae74-422850422d94",
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
        "id": "28693211-d3bb-4a3b-b439-280a99c10e4a",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "09cd55ec-0668-4699-b897-e2b8a0d4a28e",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light pace"
            },
            {
                "id": "a002da76-b271-4372-87d2-35a46f45e6d2",
                "name": "Shoulder Taps",
                "sequence": 2,
                "prescribed_reps": "15e",
                "notes": "Core/shoulder activation"
            }
        ]
    },
    {
        "id": "aa620501-f0cc-4ffc-be6d-7bf343cbf4e7",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "feb67e08-bf8d-440d-8a48-10aed429290c",
                "name": "Push-Ups",
                "sequence": 1,
                "notes": "10x - Upper body prep"
            },
            {
                "id": "74ad0358-e2d8-4362-9f17-b16ba1ae2836",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "d46ce42a-5ce4-446b-b395-fb3cc855324a",
                "name": "High Knee/Quad Pull",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "a8a13df7-e599-413e-9d65-b419057ec627",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Hip adductor mobility"
            },
            {
                "id": "a7da8191-5ffd-440e-9201-4349d956da88",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "94d41913-c0c7-46d2-a442-ac4618afd668",
                "name": "Good Morning",
                "sequence": 6,
                "notes": "Posterior chain activation"
            }
        ]
    },
    {
        "id": "06a62a06-200f-4a51-b0da-05b1e5239fd0",
        "name": "Conditioning - Chipper",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "7c7ab9cf-9e28-4fae-9fdc-c7d0c433db89",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "50 cal"
            },
            {
                "id": "2ffe778a-f1d5-4778-bd4f-f6ce7bc307e6",
                "name": "Med Ball Tap",
                "sequence": 2,
                "prescribed_reps": "30x"
            },
            {
                "id": "1da44aa6-7b19-41ef-a695-c1ce4554bf64",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_reps": "30x"
            },
            {
                "id": "da264cd1-c39f-4015-8901-538227e76041",
                "name": "Thrusters",
                "sequence": 4,
                "prescribed_reps": "30x"
            },
            {
                "id": "efbdac78-b138-4294-8584-5b6f30cf077c",
                "name": "Row/Bike",
                "sequence": 5,
                "prescribed_reps": "50 cal"
            },
            {
                "id": "63deefd4-c57e-4702-bf60-c25adb5156a0",
                "name": "Burpees",
                "sequence": 6,
                "prescribed_reps": "30x"
            },
            {
                "id": "a48dd0c5-f13c-4bb0-b261-396d08eaaf4f",
                "name": "Sit-Ups",
                "sequence": 7,
                "prescribed_reps": "30x"
            },
            {
                "id": "0d800aac-c5a2-422e-b0a5-18e46367d0f5",
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
        "id": "b8375a30-e445-405d-805e-65a333c250d1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "05b40e51-a99c-4111-b328-a769bebd7a3f",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "500m",
                "notes": "Light pace"
            },
            {
                "id": "e814c9a7-a4df-461e-8963-bdb14d2ea1ac",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "60 sec / 30 sec each side",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "f8d9f13d-0f1d-4175-96aa-80d8b2b65626",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "63bc076b-91fc-4007-a262-1e7b44e0e751",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "7f102373-b919-4140-85b4-b250c49f7fa1",
                "name": "Toy Soldier",
                "sequence": 2,
                "notes": "Hamstring activation"
            },
            {
                "id": "e7e66e7f-7f25-4b06-92d4-3d06968566f3",
                "name": "Quad Pull & Hinge",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "e1117358-382c-4178-a072-0a1fc1ac0046",
                "name": "Push Up W/O",
                "sequence": 4,
                "notes": "Upper body prep"
            },
            {
                "id": "5472e11d-9115-4e11-ad0b-c71203070230",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "969ec9c8-27e1-4e34-94a7-7508674acadb",
                "name": "SL Rotation",
                "sequence": 6,
                "notes": "Hip/spine mobility"
            }
        ]
    },
    {
        "id": "3da07f6a-f971-4dc2-863f-c5000e77fc51",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "220f221b-7a0e-4fa5-800a-1c4b4c8f453c",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded/SL (RPE 5). Set 2: Banded/SL (RPE 6). Set 3: Banded/SL (RPE 6). Rest: 45 sec between sets Accessory: Hip flexor stretch between sets"
            },
            {
                "id": "e9aee9d8-3c96-400d-a492-73b65140b644",
                "name": "Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "8f649076-5405-49c3-9464-eae597c71218",
                "name": "Bench Press",
                "sequence": 3,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Warm-up (RPE 5). Set 2: Moderate (RPE 6). Set 3: Heavy (RPE 7). Set 4: Heavy (RPE 8+). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "9a1b7a2d-78a1-4206-b00c-5e5a9aae96fa",
        "name": "Core Circuit - 15 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "69dca121-29a3-4f60-b336-c5b1bae14730",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "15"
            },
            {
                "id": "8a375e2e-1b12-4a33-b1b3-f280420e4aaf",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "30c5cf28-65b5-4bf1-a5f7-3a4f9853dceb",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "10e"
            },
            {
                "id": "baddba32-d19b-4c87-96ff-360bf512b68c",
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
        "id": "68b4c044-6b5f-4420-b83c-1aac46876177",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "f8251853-8817-4ff0-ac50-d3cc4c5d546a",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_reps": "2 min",
                "notes": "Light pace"
            },
            {
                "id": "220ca855-fc58-4931-927e-dc96bab66a17",
                "name": "Sit-Ups",
                "sequence": 2,
                "prescribed_reps": "20x",
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "9eef3dd1-b6dd-49ac-bf9b-c72fe582e47e",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "61d02da5-fa85-4213-8362-8d6462529670",
                "name": "Toy Soldier",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "79a79fd1-01b3-4be4-ac7a-39962c17ec32",
                "name": "Leg Cradle",
                "sequence": 2,
                "notes": "Hip opener"
            },
            {
                "id": "223279b0-09a8-421f-b52e-940963457e72",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "03472640-eac0-4856-ad34-1784356a499f",
                "name": "Push-Up Walkout",
                "sequence": 4,
                "notes": "Full body warmup"
            },
            {
                "id": "7181769e-8428-4703-a1f4-b159e75b00c0",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "262f9125-da8e-4868-8524-7d88f49b56ba",
                "name": "Good Mornings",
                "sequence": 6,
                "notes": "Posterior chain activation"
            },
            {
                "id": "53d35177-ef4f-4486-89f4-3098cc00a06b",
                "name": "OH Squat",
                "sequence": 7,
                "notes": "Full body mobility"
            }
        ]
    },
    {
        "id": "8a60e1f2-f711-4049-a51b-5bdbe1a2283f",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "730cd27c-2df1-4386-a26f-a5ff46f56045",
                "name": "Single Leg Deadlift (SLDL)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            },
            {
                "id": "7ef50218-43c8-459e-9e16-cee10e10aa1c",
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
        "id": "9b78e050-d58a-4ccb-a701-38cfebdbc415",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "eb22fae5-932c-4533-b724-3cc3873a81c1",
                "name": "TRX Row",
                "sequence": 1,
                "notes": "Shoulder activation"
            },
            {
                "id": "41f6e86d-f20c-4cf2-b5dd-1027456344c1",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "6175121f-ac40-4366-ac98-a3d25880434d",
                "name": "Dead Bugs",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "afce3787-a1c9-4ce5-b918-c0545b87a6c8",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "1aa65ba5-1472-4ed3-a680-eeeb18de6eca",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "f04f9473-6663-49d2-85a2-35d25c5b064c",
                "name": "Lunge & Reach",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "5bfdee41-9124-414b-acea-d190a24faab5",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "a0536aa5-bedc-4591-b737-abb445cf2b58",
                "name": "HS Walk",
                "sequence": 4,
                "notes": "Hamstring stretch"
            },
            {
                "id": "e3d78589-3658-44c9-8dec-61e4437d5c66",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "f8df1566-9fae-4a66-99ea-d4a77dae9984",
                "name": "Push Up W/o",
                "sequence": 6,
                "notes": "Upper body prep"
            }
        ]
    },
    {
        "id": "0bb6f934-6fed-4992-8125-99674ad7befd",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "4bcf29b7-4b03-4c6d-bc74-663f50c8e667",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "AMAP",
                "notes": "Set 1: Bodyweight (RPE 8). Set 2: Bodyweight (RPE 8). Set 3: Bodyweight (RPE 8). Set 4: Bodyweight (RPE 8). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "4d480a2a-743e-41f5-860f-2aec88abb9fd",
                "name": "Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "be0ac9da-e48d-446d-b9f8-34161b62df12",
        "name": "Conditioning - 12 min EMOM",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "b8ad8c59-a8e9-45cc-b0ee-655438208044",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "10"
            },
            {
                "id": "c7e246d7-b7ec-4669-9ead-d92ac510322e",
                "name": "TRX Row",
                "sequence": 2,
                "prescribed_reps": "12"
            },
            {
                "id": "0fd638cb-99e3-4d0e-a09c-057ef385af7b",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_reps": "8"
            },
            {
                "id": "3d32052e-064c-48f3-8657-e27ae33dff97",
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
        "id": "994509ac-446f-4dd1-aba4-6473e12226a5",
        "name": "Active (Warmup)",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "352b2cac-021b-497d-822b-1195a840d867",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "50862ffa-a17e-454d-8aa1-057d8cca0d21",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "Lower body activation"
            },
            {
                "id": "bf4da49a-653b-4c44-a4ea-f6a9e2cd8803",
                "name": "Push-Ups",
                "sequence": 3,
                "notes": "Upper body activation"
            },
            {
                "id": "c1fc235d-68e4-4e37-818a-a14c0cce629f",
                "name": "Jumping Jacks",
                "sequence": 4,
                "notes": "Full body warmup"
            }
        ]
    },
    {
        "id": "4b527579-e9af-4953-a2dd-eeead6348c06",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "18f4e7b5-5a84-441e-897e-9b1b3971fdb1",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "372d8813-d54f-4a8e-b9e5-88326004e03f",
                "name": "Arm Circles",
                "sequence": 2,
                "notes": "Shoulder mobility"
            },
            {
                "id": "ffb35cd6-8351-4ab4-a919-87b7c7123bae",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "53c80d83-5f63-4dfb-97d8-0ac9a01b775f",
                "name": "Lunge + Twist",
                "sequence": 4,
                "notes": "Hip mobility/rotation"
            },
            {
                "id": "d75eb217-d2cb-4f05-b0f0-92a38664e891",
                "name": "High Knee Skip",
                "sequence": 5,
                "notes": "Dynamic warmup"
            }
        ]
    },
    {
        "id": "0b674e27-87fe-4ed9-aafe-e65f035f4d4c",
        "name": "Intro - EMOM 3 Rounds",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "fa230317-3b4e-4835-b84b-ce50e4cc7642",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10 cal"
            },
            {
                "id": "06164580-f94f-4c35-9917-07e0a092563e",
                "name": "Med Ball Taps",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "15"
            },
            {
                "id": "3436e620-4064-42d3-bc1e-668062aeb667",
                "name": "KB Push Press",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "15"
            }
        ]
    },
    {
        "id": "158032d9-b224-4751-be14-90818d03a534",
        "name": "Conditioning - 10 min AMRAP",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "b751c691-8abc-4f93-a825-e472e788514d",
                "name": "Thrusters",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Light-moderate load"
            },
            {
                "id": "9ecd2891-b113-437c-b765-5a19ded6423e",
                "name": "Hanging Knees",
                "sequence": 2,
                "prescribed_reps": "15",
                "notes": "Core engagement"
            },
            {
                "id": "a14c143c-7ec6-4308-8d19-69ab1a5a8c26",
                "name": "TGU",
                "sequence": 3,
                "prescribed_reps": "1e",
                "notes": "Full movement each side"
            }
        ]
    },
    {
        "id": "8701ebe1-ec6b-4568-a693-5434a5175f62",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "079cfaea-ad41-4e89-9ee2-8f31b197aacb",
                "name": "Sprint Bike",
                "sequence": 1,
                "notes": "Max effort"
            },
            {
                "id": "53ef0935-d53e-4ed9-85d3-ceb7919619c0",
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
        "id": "00de1dfe-8785-4d89-bfc7-91cc3b26d3b1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "43b2e170-f357-4630-9810-ec68a1fd70c6",
                "name": "Jump Rope/Row",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "9148e92f-91de-4807-aebc-ea94ed0ca6ae",
                "name": "Bear Crawl (4-way)",
                "sequence": 2,
                "notes": "Full body activation"
            },
            {
                "id": "a8278000-c830-4750-80c6-a64488a80417",
                "name": "Monsters",
                "sequence": 3,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "591578e3-e9b1-4884-8ba1-44372d16ca20",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "571af1fb-2bdd-41bf-9b6c-bd13a2e56b13",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "8a5afe39-777a-478b-a176-6d6794ff1435",
                "name": "Lunge & Twist",
                "sequence": 2,
                "notes": "Hip mobility/rotation"
            },
            {
                "id": "2aaf934c-a6a7-4b49-aa1e-eb4e8ce5fe95",
                "name": "Over/Under",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "16399f38-74f9-45ee-a664-20faab2a9c3b",
                "name": "Arm Circles",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "c7d86896-0d64-458d-a476-66ebf180e52a",
                "name": "Push Up W/o",
                "sequence": 5,
                "notes": "Upper body prep"
            },
            {
                "id": "90f17e7f-b569-408e-9802-d3fd63b7e98a",
                "name": "Around the World",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "46984945-2043-43b2-8d8f-ccc88b050a49",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "0df4a352-b746-4884-98bd-4b773c2cd824",
                "name": "Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded/SL (RPE 6). Set 2: Banded/SL (RPE 6). Set 3: Banded/SL (RPE 6). Rest: 45-60 sec between sets"
            },
            {
                "id": "d962c00a-8d4e-44d9-b491-25649c48dc24",
                "name": "Single Arm Row",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "ded60a21-376d-4802-bc0c-51e800da582b",
                "name": "Single Leg Squat",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "416f0b8a-c9c9-4108-a967-26dbeee98ba7",
        "name": "Core - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "7c21601e-b074-45cd-b369-ee04e244d145",
                "name": "Front Squat",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Moderate load"
            },
            {
                "id": "074b0f00-d446-4ba4-a0e1-fa877a0e67aa",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_reps": "10e",
                "notes": "Core rotation"
            },
            {
                "id": "42d85f37-d11e-485c-b553-9812a11fd438",
                "name": "Push Press",
                "sequence": 3,
                "prescribed_reps": "10",
                "notes": "Explosive"
            },
            {
                "id": "63e419ad-0ad4-460e-b01a-895699a3f8d5",
                "name": "HKTC",
                "sequence": 4,
                "prescribed_reps": "10",
                "notes": "Hip mobility"
            },
            {
                "id": "7dff305b-081f-4f30-908d-1ee67143e121",
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
        "id": "3ab90b02-f684-4b7a-a782-96c86fec18e0",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "9e8448a0-e5a6-47f3-99e9-ec4cfeb7730f",
                "name": "Banded Bridge",
                "sequence": 1,
                "notes": "Glute activation"
            },
            {
                "id": "489941b3-2a70-47be-9623-8e8efd65a5d7",
                "name": "Banded Squats",
                "sequence": 2,
                "notes": "Lower body activation"
            }
        ]
    },
    {
        "id": "6727a967-f557-4d7f-a4ec-88d61a2adf68",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "b3f77b15-607b-4c9f-9c21-9f17a44237b1",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "68b41349-c32c-41d6-ab16-1fc9f5aca4c7",
                "name": "Hi Touch/Lo Touch",
                "sequence": 2,
                "notes": "Hip mobility"
            },
            {
                "id": "073ec49e-7d1e-4a7a-8859-35bf5a5ea5a8",
                "name": "Quad Pull & Hinge",
                "sequence": 3,
                "notes": "Quad/hip stretch"
            },
            {
                "id": "67586e44-5d80-4b7b-8389-1f8bba46c229",
                "name": "Spiderman",
                "sequence": 4,
                "notes": "Hip mobility"
            },
            {
                "id": "f0945b22-190d-4720-b72d-215cd47f25d6",
                "name": "Pigeon",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "5520f55c-e2e4-4d0b-b274-9440086f6208",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "6c01f779-91c2-4e64-855f-d0398ad4eb10",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "4bf76d7e-a241-4def-bd7b-8a43159bc295",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Hamstring Stretch between sets"
            },
            {
                "id": "f2b22827-7060-420b-b358-79673ef19591",
                "name": "Half Kneel Single Arm Press",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            }
        ]
    },
    {
        "id": "04ea48ef-7d73-4394-9b9a-92175825a2f7",
        "name": "Core - Chipper",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "c3caefe8-277a-471d-bd1f-98fe846cf845",
                "name": "TGU",
                "sequence": 1,
                "prescribed_reps": "5e",
                "notes": "Full movement"
            },
            {
                "id": "0336b29a-b360-41bf-8d70-b0ce27b3843d",
                "name": "Burpees",
                "sequence": 2,
                "prescribed_reps": "20",
                "notes": "Full body"
            },
            {
                "id": "0832d864-b46e-4a9e-9025-81c0ff5cbe8f",
                "name": "Dead Bugs",
                "sequence": 3,
                "prescribed_reps": "15e",
                "notes": "Core anti-extension"
            },
            {
                "id": "83aa4a5f-3e13-444c-af95-5e87b61837d9",
                "name": "SL Bridge",
                "sequence": 4,
                "prescribed_reps": "20e",
                "notes": "Glute isolation"
            },
            {
                "id": "9ab0a2d3-7021-4f69-913b-a44089dcb8be",
                "name": "Air Squat",
                "sequence": 5,
                "prescribed_reps": "100",
                "notes": "Endurance"
            },
            {
                "id": "f9d32b03-4b60-4b8d-bb27-d14a16499926",
                "name": "Shoulder Tap",
                "sequence": 6,
                "prescribed_reps": "20e",
                "notes": "Core stability"
            },
            {
                "id": "4c80307a-f376-4db3-9b86-a4740036a2e4",
                "name": "Back Lunge",
                "sequence": 7,
                "prescribed_reps": "15e",
                "notes": "Lower body"
            },
            {
                "id": "c35f5109-9462-4dca-b094-283965ac4968",
                "name": "Sit Ups",
                "sequence": 8,
                "prescribed_reps": "20",
                "notes": "Core flexion"
            },
            {
                "id": "d4364d4f-f4db-46c9-a711-7eaa0ebddaa6",
                "name": "Push Ups",
                "sequence": 9,
                "prescribed_reps": "10",
                "notes": "Upper body"
            },
            {
                "id": "cfb85d6a-b895-4a8b-94f8-7704fdc563c6",
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
        "id": "5ab0a23d-13c2-4a98-91ae-2cae1b23b686",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "ef870094-b378-4c05-8a4b-bc8c6830c2df",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "bdca1786-5117-4af1-b1c4-2b1bc133157a",
                "name": "Broad Jumps",
                "sequence": 2,
                "notes": "Power activation"
            }
        ]
    },
    {
        "id": "4014e427-0f9b-4f93-abc7-bdd5a31fec4a",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "6beb775e-3ba2-4ce3-9920-c48870e65786",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "224b4da0-4230-4721-a2b1-4f25acd2c5ef",
                "name": "Pigeon Stretch",
                "sequence": 2,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "d35f9b65-d7ee-4913-938b-dc91a0910b87",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "846bfeff-72c8-40f5-a897-2f8c0d3ef686",
                "name": "Toy Soldier",
                "sequence": 4,
                "notes": "Hamstring activation"
            },
            {
                "id": "2ed3f8d4-e51c-4f59-9715-2c4f4a1a087a",
                "name": "Arm Circles",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "c2489c85-0165-4877-8331-fb4bb2231012",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "e3adc12a-b3db-4d26-82af-5726bb5bd7e7",
        "name": "Intro - 3 Rounds",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "682c5b52-3e9e-40fc-b8aa-660d3852d38b",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "12 cal",
                "notes": "Moderate pace"
            },
            {
                "id": "56e94c9a-e252-49df-b88a-368dfd79dd64",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12e",
                "notes": "Core activation"
            },
            {
                "id": "5fc545f2-038a-443a-81dd-8fc49d9c1e4e",
                "name": "KB Swing",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Hip hinge pattern"
            }
        ]
    },
    {
        "id": "a6e5469a-ead0-4cff-b6d5-fee36519545a",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "12d7cfa6-cbf0-4df7-bdd6-29f3268f4907",
                "name": "Standing Shoulder Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "06fa6bbb-10b1-4ac2-9d7f-23e632945265",
                "name": "Split Squats",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "0f5d8ddb-e1e5-4e04-a5a4-1837a56f7246",
        "name": "Conditioning - 4 Rounds",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "bfe00ad7-cc10-49b5-9bb8-244518266144",
                "name": "Bosu Mtn Climber",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "12e",
                "notes": "Core stability. 4 rounds total"
            },
            {
                "id": "a4190ee8-5ba4-421d-b0e9-47e6a9612496",
                "name": "Goblet Squat",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "12",
                "notes": "Lower body. 4 rounds total"
            },
            {
                "id": "26d4b660-a0c9-47d0-bd03-6d754701b366",
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
        "id": "23f3583d-ccfe-45c0-81a0-42f0f030803d",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "414e37c0-7d3c-480f-b1c4-904acbd6d4bf",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "d04393ee-f196-485f-bae9-d5bfac19dfa4",
                "name": "SL Bridges",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "1e59dc9a-df38-4ca3-9eac-c9edab8a2b02",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "5aa0a43e-a499-4933-920d-5b1ad27ea4c1",
                "name": "Hamstring Walk",
                "sequence": 1,
                "notes": "Hamstring activation"
            },
            {
                "id": "4ea490ef-8dfd-4b6b-b646-4e40254479ed",
                "name": "Air Squats",
                "sequence": 2,
                "notes": "10x - Lower body prep"
            },
            {
                "id": "a10810c3-6e00-43f5-8878-6c1f7b17f7ce",
                "name": "Quad Pull",
                "sequence": 3,
                "notes": "Quad stretch"
            },
            {
                "id": "6562c667-1fea-48e4-a6cf-841a5809bde5",
                "name": "Leg Cradle",
                "sequence": 4,
                "notes": "Hip opener"
            },
            {
                "id": "e680ed62-1ff9-4080-b9d7-8cc5a847fbf3",
                "name": "High Knee Pull",
                "sequence": 5,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "908a541e-35c9-482c-afaf-2ec79ecca320",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "86b1753c-482c-4de4-8f3f-881f6b8dfa6f",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "8434198b-b5fb-4ddc-ad96-bbb93cce6ebc",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Set 5: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "65a09e43-b9df-4153-ac2d-f5d52ae4f70c",
                "name": "Weighted Step-Ups",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            }
        ]
    },
    {
        "id": "46260963-8b63-464c-8fdc-5b870dd89db0",
        "name": "Conditioning - 12 min Ladder",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "498fd0ab-6a58-4ab6-b6b8-8d40ded8f68a",
                "name": "KB Front Squat",
                "sequence": 1,
                "notes": "Lower body"
            },
            {
                "id": "489e91a1-cf2d-4ce1-85ab-8fc57eb26408",
                "name": "Burpees",
                "sequence": 2,
                "notes": "Full body"
            },
            {
                "id": "a1bf4064-fcf9-4433-8526-8a4249653711",
                "name": "Sit-Ups",
                "sequence": 3,
                "notes": "Core"
            }
        ]
    },
    {
        "id": "26890c20-df78-40c1-b0b0-eb48ffa53854",
        "name": "Finisher",
        "block_type": "recovery",
        "sequence": 5,
        "exercises": [
            {
                "id": "f0482fe5-4427-4f17-9b65-1a6c82d48f56",
                "name": "Row Sprint",
                "sequence": 1,
                "notes": "Max effort"
            },
            {
                "id": "acea5956-dd2e-4c6a-b045-e3a67af842fd",
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
        "id": "7b182baa-ad5d-4064-9c65-c3cc97099bff",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "af42216c-6efe-4aa6-903e-9b366469ecf3",
                "name": "Row/Bike",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "ab56a122-2459-4813-b268-ff780d01c105",
                "name": "Monster Walk",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "5b8c7567-8724-47a7-982a-6bdb215f0b0f",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "16ef1a61-6dcd-4229-8c46-4c49536441cc",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "db4c6677-69e8-4994-b34f-d638bc74ea31",
                "name": "High Knee Pull",
                "sequence": 2,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "e764a4e7-9632-45ad-897b-cbaf7da19b8b",
                "name": "Toy Soldier",
                "sequence": 3,
                "notes": "Hamstring activation"
            },
            {
                "id": "b0a3bb1d-7fd8-436c-9966-33e3f88d3faa",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Hip adductor mobility"
            },
            {
                "id": "b1b67fe4-5194-4e88-815b-6f6c539a945d",
                "name": "PVC Passover",
                "sequence": 5,
                "notes": "Shoulder mobility"
            },
            {
                "id": "8b194e24-7e1d-4b41-bd68-cfe3a63ff6c8",
                "name": "Push-Ups",
                "sequence": 6,
                "notes": "10x - Upper body prep"
            }
        ]
    },
    {
        "id": "96b05278-9d40-4687-9505-7625c1eac58e",
        "name": "Intro - 9 min EMOM",
        "block_type": "functional",
        "sequence": 3,
        "exercises": [
            {
                "id": "cf5012f7-1a1f-4f86-ad8f-4c244a74aa43",
                "name": "Row/Bike",
                "sequence": 1,
                "prescribed_reps": "10-12 cal",
                "notes": "Moderate effort"
            },
            {
                "id": "7be96597-bd49-40c7-99ae-ad75554bb06b",
                "name": "Plank",
                "sequence": 2,
                "prescribed_reps": "30\"",
                "notes": "Core stability"
            },
            {
                "id": "927300fa-0580-45a1-9fdf-13f57c860948",
                "name": "Bicep Curls",
                "sequence": 3,
                "prescribed_reps": "15",
                "notes": "Arm activation"
            }
        ]
    },
    {
        "id": "446c1f1b-5aaa-43aa-a974-9b05ee547211",
        "name": "Strength",
        "block_type": "push",
        "sequence": 4,
        "exercises": [
            {
                "id": "268eb3d8-41dd-4c9e-9e20-b8c02b6e1454",
                "name": "Half Kneel Single Arm Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "33629f17-d2dc-4218-997d-27ff98180c36",
                "name": "Walking Lunges",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "103b5479-bab1-4732-a21e-9d6242ee51da",
                "name": "Turkish Get-Up (TGU)",
                "sequence": 3,
                "prescribed_sets": 1,
                "prescribed_reps": "5e",
                "notes": "Set 1: Moderate (RPE 7). Accessory: Single Leg Rotation between sides"
            }
        ]
    },
    {
        "id": "a588258a-bae4-44a8-9428-41621d1fdbf9",
        "name": "Conditioning - 1 Round",
        "block_type": "functional",
        "sequence": 5,
        "exercises": [
            {
                "id": "a2053e99-9fd6-4863-b3ca-1ae5f2954724",
                "name": "Bike/Row",
                "sequence": 1,
                "prescribed_sets": 1,
                "prescribed_reps": "25 cal",
                "notes": "Steady pace. 1 rounds total"
            },
            {
                "id": "8f4dd221-892d-4761-8fb2-ab187a713b97",
                "name": "Russian Twist",
                "sequence": 2,
                "prescribed_sets": 1,
                "prescribed_reps": "25e",
                "notes": "Core rotation. 1 rounds total"
            },
            {
                "id": "4c6264a7-469a-45bf-85bc-07d02e39fcd8",
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
        "id": "642a2bc3-aa86-494a-972e-9d2fe0b93763",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "54848707-09df-4278-b602-ea783850bbec",
                "name": "Row/Jump Rope",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "e3e1ef41-30a8-43aa-96a6-acc3a2b31efd",
                "name": "Monsters",
                "sequence": 2,
                "notes": "Glute activation"
            }
        ]
    },
    {
        "id": "619c8a8b-8a3b-43cc-bc1d-6dc3aed95554",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "92c7f109-27a4-40a8-9bdc-10654a5a0f4d",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "9eb4853a-02c4-414c-b3d9-4d2a252e9fa8",
                "name": "Quad Pull & Hinge",
                "sequence": 2,
                "notes": "Quad/hip stretch"
            },
            {
                "id": "b49dbc75-e267-4321-8db2-8e716d87a603",
                "name": "Lunge & Reach",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "6269cd22-63b1-4864-9a71-b33a4d6728d4",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "d67adbef-dd08-4f04-b32c-63539b291dad",
                "name": "Good Mornings",
                "sequence": 5,
                "notes": "Hamstring activation"
            },
            {
                "id": "bc846591-25f0-4878-b1ff-ea59cd0d626b",
                "name": "Spiderman",
                "sequence": 6,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "165c55a6-07d8-41d7-8d79-a560463c0e08",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "e4bd13ef-d308-4c39-bbd7-45bf2ac4b7dc",
                "name": "Banded or Single Leg Bridge",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Banded/SL (RPE 6). Set 2: Banded/SL (RPE 6). Set 3: Banded/SL (RPE 6). Rest: 45-60 sec between sets Accessory: Hamstring Stretch between sets"
            },
            {
                "id": "69f8698d-b011-4224-87f1-beff7519d0f4",
                "name": "Good Mornings",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: Touch Toes, Pulse (TTP) between sets"
            }
        ]
    },
    {
        "id": "907080fb-560e-4b2d-85e9-b7fd6ea75651",
        "name": "Core - 12 Days Style",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "62f39c40-3c0a-4ff7-b4a0-3eb8476b3fa2",
                "name": "TGU",
                "sequence": 1,
                "prescribed_reps": "1e",
                "notes": "Full movement"
            },
            {
                "id": "ccdb85ce-5321-4a22-81da-9dcf5a660bbb",
                "name": "Box Jump/Step Up",
                "sequence": 2,
                "prescribed_reps": "2",
                "notes": "Power"
            },
            {
                "id": "c9b87952-2e9c-45a9-a2d9-7b359558de11",
                "name": "Russian Twist",
                "sequence": 3,
                "prescribed_reps": "3e",
                "notes": "Core rotation"
            },
            {
                "id": "f4426730-1943-43bf-a581-580cdd68c8c4",
                "name": "TRX Row",
                "sequence": 4,
                "prescribed_reps": "4",
                "notes": "Upper back"
            },
            {
                "id": "cb8365fe-84cc-4ee9-a9ee-4bec9639d89f",
                "name": "Push Up",
                "sequence": 5,
                "prescribed_reps": "5",
                "notes": "Upper body"
            },
            {
                "id": "d0604c91-1062-4ead-ad53-ffe0757cac41",
                "name": "Back Lunge",
                "sequence": 6,
                "prescribed_reps": "6e",
                "notes": "Lower body"
            },
            {
                "id": "1ce8efed-c3ba-4b12-b0db-843cf8878e75",
                "name": "Mtn Climber",
                "sequence": 7,
                "prescribed_reps": "7e",
                "notes": "Core/cardio"
            },
            {
                "id": "427a23fa-6fcb-4506-8868-9411869ff2b9",
                "name": "Goblet Squat",
                "sequence": 8,
                "prescribed_reps": "8",
                "notes": "Lower body"
            },
            {
                "id": "bf193035-110f-4645-91bb-39cdb02a1114",
                "name": "Sit Ups",
                "sequence": 9,
                "prescribed_reps": "9",
                "notes": "Core flexion"
            },
            {
                "id": "60c51642-dabc-4cf2-9b09-1108239a7e2d",
                "name": "KB Swing",
                "sequence": 10,
                "prescribed_reps": "10",
                "notes": "Hip hinge"
            },
            {
                "id": "bce1ae81-471b-4b04-ab61-dc399f6a8b08",
                "name": "Thrusters",
                "sequence": 11,
                "prescribed_reps": "11",
                "notes": "Full body"
            },
            {
                "id": "4197a59d-acfe-4613-89bf-861c999adf0a",
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
        "id": "3a7c0c9f-dfee-40fc-ab2a-ca6f91df7af1",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "7d38847f-f374-4ca4-a2f5-a543dcaf6019",
                "name": "Bridge",
                "sequence": 1,
                "notes": "Banded or Single Leg"
            },
            {
                "id": "e05829ab-f367-471f-afa3-500f6db3cfef",
                "name": "Dead Bugs",
                "sequence": 2,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "dbd0e8ff-4bd2-4092-b690-32ec6f669b63",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "3cc9bd1e-d923-4dc8-ada2-124536a04b10",
                "name": "High Knee Pull",
                "sequence": 1,
                "notes": "Hip flexor/hamstring"
            },
            {
                "id": "5654f04e-f88c-4cef-846a-7a98972b5b42",
                "name": "Quad Pull",
                "sequence": 2,
                "notes": "Quad stretch"
            },
            {
                "id": "c4d54047-d5f2-4648-b311-720742127308",
                "name": "Hi Touch/Lo Touch",
                "sequence": 3,
                "notes": "Hip mobility"
            },
            {
                "id": "4b646c2e-f3c8-40e3-a9b4-bb8033628387",
                "name": "Side Lunge",
                "sequence": 4,
                "notes": "Hip adductor mobility"
            },
            {
                "id": "49869ff1-4650-41da-8587-c84c7af392e6",
                "name": "Pigeon/Piriformis",
                "sequence": 5,
                "notes": "Glute/hip stretch"
            },
            {
                "id": "fc28c4d3-3ee1-4725-8439-b9fe15f88f0c",
                "name": "SL Rotation",
                "sequence": 6,
                "notes": "Hip mobility"
            }
        ]
    },
    {
        "id": "001c5101-7143-4a56-9a86-b45051e160bf",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "27f538eb-2197-4ecc-be30-436268c704f7",
                "name": "Pull Ups",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "Max Rep Test",
                "notes": "Set 1: Bodyweight (RPE 9). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Set 4: Bodyweight (RPE 7). Rest: 90-120 sec between sets Accessory: Lat Stretch between sets"
            },
            {
                "id": "1da013ea-99b5-4ffa-afc0-29c0bd8a073a",
                "name": "Slant Bar 3-Way Extension",
                "sequence": 2,
                "prescribed_sets": 3,
                "prescribed_reps": "12",
                "notes": "Set 1: Light (RPE 6). Set 2: Light (RPE 6). Set 3: Light (RPE 6). Rest: 45-60 sec between sets Accessory: Pigeon Stretch between sets"
            },
            {
                "id": "b0cc9fbc-340c-49ff-add3-235c1ca152da",
                "name": "Slant Bar Twist",
                "sequence": 3,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 6). Set 3: Bodyweight (RPE 6). Rest: 45-60 sec between sets Accessory: Cobra/Child Pose between sets"
            },
            {
                "id": "e7881bcb-c696-4157-92ed-49bce77e59e3",
                "name": "Single Leg Squat",
                "sequence": 4,
                "prescribed_sets": 3,
                "prescribed_reps": "10e",
                "notes": "Set 1: Bodyweight (RPE 6). Set 2: Bodyweight (RPE 7). Set 3: Bodyweight (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pull between sets"
            },
            {
                "id": "904629c2-d105-472e-aba0-1afbd8783a00",
                "name": "Arm Set",
                "sequence": 5,
                "prescribed_sets": 3,
                "prescribed_reps": "10-12",
                "notes": ""
            }
        ]
    },
    {
        "id": "fc6f5a03-18ab-4ac7-a554-393a4c4fafe7",
        "name": "Core Cash Out",
        "block_type": "core",
        "sequence": 4,
        "exercises": [
            {
                "id": "e991dd3e-3ba2-42bf-ba54-1c7502161c53",
                "name": "Heel Raise",
                "sequence": 1,
                "prescribed_reps": "10",
                "notes": "Calf work"
            },
            {
                "id": "2334f4e1-3cd4-4792-b938-679c6d50731c",
                "name": "Dead Bugs",
                "sequence": 2,
                "prescribed_reps": "10e",
                "notes": "Core anti-extension"
            },
            {
                "id": "5e3a9de4-eaa0-4ed4-839c-77378973528f",
                "name": "Sit Ups",
                "sequence": 3,
                "prescribed_reps": "12",
                "notes": "Core flexion"
            },
            {
                "id": "8d2ef91d-55f3-4345-97c7-a1083bbe0339",
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
        "id": "9a4ac5b8-43c3-44ef-8ae4-45072f54226b",
        "name": "Active",
        "block_type": "cardio",
        "sequence": 1,
        "exercises": [
            {
                "id": "e64dea99-de7f-4fe6-86a2-564695f51084",
                "name": "Row",
                "sequence": 1,
                "notes": "Low intensity warmup"
            },
            {
                "id": "60e30410-1863-41c7-a732-2f1e52fe6d3c",
                "name": "Bridge",
                "sequence": 2,
                "notes": "Glute activation"
            },
            {
                "id": "785fb3ac-a001-47f3-83dc-7c16de2d4f8f",
                "name": "Plank",
                "sequence": 3,
                "notes": "Core activation"
            }
        ]
    },
    {
        "id": "d54f8c5a-7b78-45b0-9c02-65ad16e56004",
        "name": "Dynamic",
        "block_type": "dynamic_stretch",
        "sequence": 2,
        "exercises": [
            {
                "id": "262e05e3-fb7e-4016-9541-ace90da7f4fe",
                "name": "Quad Pull",
                "sequence": 1,
                "notes": "Quad stretch"
            },
            {
                "id": "ac32ae27-3d07-4db8-a6cb-b412bf2c3805",
                "name": "Lunge & Twist",
                "sequence": 2,
                "notes": "Hip mobility/rotation"
            },
            {
                "id": "41298a52-5c35-4cb2-a5b7-51abf6a5c03f",
                "name": "HS Walk",
                "sequence": 3,
                "notes": "Hamstring stretch"
            },
            {
                "id": "4c3ba3a5-d2ab-4f75-9c13-d5d333ad6eca",
                "name": "PVC Passover",
                "sequence": 4,
                "notes": "Shoulder mobility"
            },
            {
                "id": "cdb18618-139a-466e-acc8-05520db7bcf9",
                "name": "Push Up W/o",
                "sequence": 5,
                "notes": "Upper body prep"
            },
            {
                "id": "caeec3a7-cdc0-4c01-8ae5-1ac7e97a8adb",
                "name": "Arm Circles",
                "sequence": 6,
                "notes": "Shoulder mobility"
            }
        ]
    },
    {
        "id": "282b3ef5-691a-4005-abdc-9c0469299ed3",
        "name": "Strength",
        "block_type": "push",
        "sequence": 3,
        "exercises": [
            {
                "id": "e63cc316-fe2f-4feb-b4ee-4ce2df8fd25e",
                "name": "DB Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 90 sec between sets Accessory: PVC Passover between sets"
            },
            {
                "id": "2e7805b6-c424-46d7-96ee-fcd879fca62f",
                "name": "Single Leg Deadlift (SLDL)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: HS Walk between sets"
            }
        ]
    },
    {
        "id": "ec170443-dd4e-4dc5-aa08-0c67adab20c9",
        "name": "Core - Circuit",
        "block_type": "functional",
        "sequence": 4,
        "exercises": [
            {
                "id": "a1c11578-ee6d-49b6-a404-15f2882070f8",
                "name": "Row",
                "sequence": 1,
                "prescribed_reps": "250m",
                "notes": "Moderate pace"
            },
            {
                "id": "0aa5656a-9b5c-4554-80f1-00494d330957",
                "name": "Front Squat",
                "sequence": 2,
                "prescribed_reps": "10",
                "notes": "Lower body"
            },
            {
                "id": "e7057570-1479-4dbc-a92f-ce17ba6186ae",
                "name": "Burpees",
                "sequence": 3,
                "prescribed_reps": "12",
                "notes": "Full body"
            },
            {
                "id": "d1584cf6-3539-4b3c-8359-3ddef6acf04b",
                "name": "Dead Bugs",
                "sequence": 4,
                "prescribed_reps": "15e",
                "notes": "Core anti-extension"
            },
            {
                "id": "92682580-84d2-4080-8ad2-abcd8740826b",
                "name": "Row",
                "sequence": 5,
                "prescribed_reps": "250m",
                "notes": "Moderate pace"
            },
            {
                "id": "20778c1a-2381-4eeb-87b9-99625f5ec728",
                "name": "Push Press",
                "sequence": 6,
                "prescribed_reps": "10",
                "notes": "Explosive"
            },
            {
                "id": "859f0623-7375-4e06-9fa2-c71ff37c5601",
                "name": "Sit Ups",
                "sequence": 7,
                "prescribed_reps": "12",
                "notes": "Core flexion"
            },
            {
                "id": "2eff14f2-c212-4ea9-afa0-1edf9de090d2",
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
        "id": "3b5d86b3-0273-49f0-b42c-9d3a3d33963c",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "422c1e54-c0c2-4473-b7e3-afaf3577b33f",
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
        "id": "e6b0c2fc-970f-43e4-af85-c97296d2c750",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "f71987f1-5c27-4c10-a853-80dc0b23ec7a",
                "name": "Walking Lunges (Building)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "a46eff37-9160-4ca4-8507-7d54082dfee0",
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
        "id": "96d51f86-cdc0-4a7e-a931-1dd71ae6d689",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "1e86d5a1-3300-42fd-a48a-08c96cbe5f0d",
                "name": "Deadlift (Building)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: Hamstring Walk between sets"
            },
            {
                "id": "87f8c48e-96b5-4977-93a3-4875aa5197c8",
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
        "id": "59a5e80b-d4a1-43e2-9aa4-8bfc09796882",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "8a94a876-8bda-4f9b-98ce-64ac48008e8f",
                "name": "Good Mornings",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Hamstring Walks between sets"
            },
            {
                "id": "f9ed21d8-c058-4ae1-8ef8-78fe56275f4c",
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
        "id": "6205aa94-ec63-42da-a146-5811df63aefb",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "571b4190-95cc-44f4-aec6-5ffec1add2ae",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "1f0d938d-de74-4a2d-91f7-16c979f379aa",
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
        "id": "4496cbb7-35e9-4f06-baca-2cca3aa82a21",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "988b2563-1475-4adb-87cd-4a3dcdca7a70",
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
        "id": "11e9b3e7-db41-402d-b6cb-f42c9c38ba18",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "6080df96-522e-4266-8637-d978f2aeecd8",
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
        "id": "ddfe09fe-eca6-4e32-b5e2-b6a929742742",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "0241b663-9867-452a-a9e7-5c4924c2617a",
                "name": "Single Leg Squat (SL Squat)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Bodyweight/Light (RPE 6). Set 2: Light (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "a592a970-0b03-41c8-b091-3f0be3d3a818",
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
        "id": "2ee1b6ae-c372-47b7-9898-90fc0865966b",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "52b3bdb1-37d5-4e74-b77e-cca0fe4b20a1",
                "name": "KB Front Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "a4f2756a-7724-47cd-b36b-b900c1e402e2",
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
        "id": "64f592d9-612f-4452-874e-3954beaf7905",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "8c649c0b-3b0e-45a4-9c08-d255aefdc133",
                "name": "Split Squats (Building)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "10e",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 8). Rest: 90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "eef1fdc6-b129-4267-8081-58402ce7cf3c",
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
        "id": "8fbca3b3-ce09-45ef-91f7-b1199370d393",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "66e8911b-61bb-4ddd-ba3c-d22e8f7cb34d",
                "name": "Single Leg Deadlift (SL DL)",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Hamstring Walks between sets"
            },
            {
                "id": "2086b00c-f963-4af5-9a7f-9851556fe1c1",
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
        "id": "e79e43ef-cfca-4ae9-95ae-baac143cf5f4",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "a68beefc-a28f-4790-86ce-66be6ddf3cd7",
                "name": "Deadlifts",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: T.T.P. (Touch Toes Progression) between sets"
            },
            {
                "id": "3de4ebb2-6f13-4150-a3f6-913e0ac7da8d",
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
        "id": "49ab5678-c9b4-4710-b727-60cc730efde6",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "400f295c-00c5-4d49-b297-2b4c39ee5748",
                "name": "Deadlifts (Building)",
                "sequence": 1,
                "prescribed_sets": 5,
                "prescribed_reps": "10",
                "notes": "Set 1: Light (RPE 5). Set 2: Moderate (RPE 6). Set 3: Moderate-Heavy (RPE 7). Set 4: Heavy (RPE 7). Set 5: Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: T.T.P. (Touch Toes Progression) between sets"
            },
            {
                "id": "77662020-11b4-4137-89f0-d57ee1d13e88",
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
        "id": "037cf7d9-3fea-4787-a814-4d7a87ae06c7",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "b650b108-978c-4bcc-ad86-68e6e43df2e9",
                "name": "Split Squats",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "0f055121-b3cd-4207-a435-b73eeb230c02",
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
        "id": "5cc6f398-da39-4d63-bbbb-809c908f429c",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "d736a3e1-bd87-4c49-b064-e023a2a945ee",
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
        "id": "68cf4d33-b0c4-4faa-9d5f-2c7f32c666c0",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "31bd4ff9-ee3d-4446-84cd-a2dd650951cc",
                "name": "Bench Press",
                "sequence": 1,
                "prescribed_sets": 4,
                "prescribed_reps": "8",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate-Heavy (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 90-120 sec between sets Accessory: Snow Angels (10 reps) between sets"
            },
            {
                "id": "a943b201-da6e-4a3f-bf0c-0ecebadd4852",
                "name": "Single Leg Deadlift (SL DL)",
                "sequence": 2,
                "prescribed_sets": 4,
                "prescribed_reps": "8e",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Set 4: Moderate-Heavy (RPE 8). Rest: 60-90 sec between sets Accessory: SL Bridge (10e) between sets"
            },
            {
                "id": "19f11cf4-8a4d-4dd6-b9b0-b792a7b17b11",
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
        "id": "fae68b8b-11de-48c0-8725-906c10cd1e8b",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "5c3145b6-7d36-4b26-b352-f256885fc0ae",
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
        "id": "34ea3a76-d424-421f-8d61-e5be95897de9",
        "name": "Strength",
        "block_type": "push",
        "sequence": 1,
        "exercises": [
            {
                "id": "b2b17c23-cfeb-4fb8-93f4-0927b29c05df",
                "name": "Slant Bar (3 Extensions)",
                "sequence": 1,
                "prescribed_sets": 3,
                "prescribed_reps": "10",
                "notes": "Set 1: Moderate (RPE 6). Set 2: Moderate (RPE 7). Set 3: Moderate (RPE 7). Rest: 60-90 sec between sets Accessory: Quad Pulls between sets"
            },
            {
                "id": "463f4614-0160-4046-92ca-d87577efba88",
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
