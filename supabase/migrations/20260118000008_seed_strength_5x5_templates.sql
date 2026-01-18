-- Seed 25 Strength/5x5 Workout Templates
-- Based on StrongLifts 5x5 and Madcow 5x5 programs
-- Category: strength, Difficulty: varies

INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file) VALUES

-- Classic StrongLifts 5x5 Workout A
('5f5a0001-0001-4000-8000-000000000001', 'StrongLifts 5x5 - Workout A', 'The classic StrongLifts Workout A: Squat, Bench Press, and Barbell Row. Perfect for beginners building foundational strength with compound movements.', 'strength', 'beginner', 45, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"},
      {"name": "Empty Bar Squats", "sets": 2, "reps": "10"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5", "notes": "Add 5 lbs each session. Rest 3-5 min between sets."},
      {"name": "Barbell Bench Press", "sets": 5, "reps": "5", "notes": "Add 5 lbs each session. Rest 3 min between sets."},
      {"name": "Barbell Row", "sets": 5, "reps": "5", "notes": "Add 5 lbs each session. Pendlay rows from floor."}
    ]},
    {"name": "Recovery", "sequence": 2, "exercises": [
      {"name": "Static Stretching", "duration": "5 min"}
    ]}
  ]
}', ARRAY['5x5', 'stronglifts', 'beginner', 'compound', 'barbell', 'full-body'], 'stronglifts_workout_a.md'),

-- Classic StrongLifts 5x5 Workout B
('5f5a0001-0002-4000-8000-000000000002', 'StrongLifts 5x5 - Workout B', 'The classic StrongLifts Workout B: Squat, Overhead Press, and Deadlift. Builds total body strength with emphasis on posterior chain.', 'strength', 'beginner', 45, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"},
      {"name": "Empty Bar Squats", "sets": 2, "reps": "10"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5", "notes": "Add 5 lbs each session. Rest 3-5 min between sets."},
      {"name": "Overhead Press", "sets": 5, "reps": "5", "notes": "Add 5 lbs each session. Strict press, no leg drive."},
      {"name": "Deadlift", "sets": 1, "reps": "5", "notes": "Add 10 lbs each session. One heavy set of 5."}
    ]},
    {"name": "Recovery", "sequence": 2, "exercises": [
      {"name": "Static Stretching", "duration": "5 min"}
    ]}
  ]
}', ARRAY['5x5', 'stronglifts', 'beginner', 'compound', 'barbell', 'full-body'], 'stronglifts_workout_b.md'),

-- Madcow 5x5 - Monday (Heavy)
('5f5a0002-0001-4000-8000-000000000003', 'Madcow 5x5 - Monday (Heavy)', 'Madcow intermediate program heavy day. Work up to PR sets of 5 on squat, bench, and row with ramping sets.', 'strength', 'intermediate', 60, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"},
      {"name": "Dynamic Stretching", "duration": "5 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5", "notes": "Ramp up: 4x5 building to 1x5 PR. Add weight each week."},
      {"name": "Barbell Bench Press", "sets": 5, "reps": "5", "notes": "Ramp up: 4x5 building to 1x5 PR."},
      {"name": "Barbell Row", "sets": 5, "reps": "5", "notes": "Ramp up: 4x5 building to 1x5 PR."}
    ]},
    {"name": "Recovery", "sequence": 2, "exercises": [
      {"name": "Foam Rolling", "duration": "5 min"}
    ]}
  ]
}', ARRAY['5x5', 'madcow', 'intermediate', 'strength', 'barbell', 'heavy-day'], 'madcow_monday.md'),

-- Madcow 5x5 - Wednesday (Light)
('5f5a0002-0002-4000-8000-000000000004', 'Madcow 5x5 - Wednesday (Light)', 'Madcow intermediate program light/recovery day. Lower volume to promote recovery while maintaining movement patterns.', 'strength', 'intermediate', 45, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 4, "reps": "5", "notes": "Light day: Use ~80% of Monday top set."},
      {"name": "Incline Bench Press", "sets": 4, "reps": "5", "notes": "Lighter pressing variant for recovery."},
      {"name": "Deadlift", "sets": 4, "reps": "5", "notes": "Ramp up: 3x5 + 1x5 moderate."}
    ]},
    {"name": "Recovery", "sequence": 2, "exercises": [
      {"name": "Light Stretching", "duration": "5 min"}
    ]}
  ]
}', ARRAY['5x5', 'madcow', 'intermediate', 'strength', 'barbell', 'light-day'], 'madcow_wednesday.md'),

-- Madcow 5x5 - Friday (Medium/PR Day)
('5f5a0002-0003-4000-8000-000000000005', 'Madcow 5x5 - Friday (Medium)', 'Madcow intermediate program medium day with PR triple. Push new personal records on the final heavy set.', 'strength', 'intermediate', 60, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"},
      {"name": "Dynamic Warmup", "duration": "5 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5,5,5,3,8", "notes": "4x5 ramp + 1x3 PR + 1x8 backoff."},
      {"name": "Barbell Bench Press", "sets": 5, "reps": "5,5,5,3,8", "notes": "4x5 ramp + 1x3 PR + 1x8 backoff."},
      {"name": "Barbell Row", "sets": 5, "reps": "5,5,5,3,8", "notes": "4x5 ramp + 1x3 PR + 1x8 backoff."}
    ]},
    {"name": "Recovery", "sequence": 2, "exercises": [
      {"name": "Foam Rolling", "duration": "5 min"}
    ]}
  ]
}', ARRAY['5x5', 'madcow', 'intermediate', 'strength', 'barbell', 'pr-day'], 'madcow_friday.md'),

-- Bill Starr 5x5 Original
('5f5a0003-0001-4000-8000-000000000006', 'Bill Starr 5x5 Original', 'The original 5x5 program by legendary strength coach Bill Starr. Focus on power cleans, squats, and bench with explosive training.', 'strength', 'intermediate', 60, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Jump Rope", "duration": "3 min"},
      {"name": "Dynamic Stretching", "duration": "5 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Power Clean", "sets": 5, "reps": "5", "notes": "Explosive hip extension. Build to heavy set."},
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5", "notes": "Full depth. Ramp up weight each set."},
      {"name": "Barbell Bench Press", "sets": 5, "reps": "5", "notes": "Controlled descent, explosive press."}
    ]},
    {"name": "Accessory", "sequence": 2, "exercises": [
      {"name": "Barbell Curl", "sets": 3, "reps": "8-10"},
      {"name": "Tricep Dips", "sets": 3, "reps": "8-10"}
    ]}
  ]
}', ARRAY['5x5', 'bill-starr', 'intermediate', 'power', 'barbell', 'classic'], 'bill_starr_5x5.md'),

-- Ice Cream Fitness 5x5 - Workout A
('5f5a0004-0001-4000-8000-000000000007', 'Ice Cream Fitness 5x5 - Day A', 'Jason Blaha Ice Cream Fitness: StrongLifts base with hypertrophy accessories. Great for size and strength gains.', 'strength', 'beginner', 75, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5"},
      {"name": "Barbell Bench Press", "sets": 5, "reps": "5"},
      {"name": "Barbell Row", "sets": 5, "reps": "5"}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Barbell Shrugs", "sets": 3, "reps": "8"},
      {"name": "Skullcrushers", "sets": 3, "reps": "8"},
      {"name": "Barbell Curl", "sets": 3, "reps": "8"},
      {"name": "Cable Crunches", "sets": 3, "reps": "10-20"}
    ]}
  ]
}', ARRAY['5x5', 'icf', 'beginner', 'hypertrophy', 'strength', 'accessories'], 'icf_workout_a.md'),

-- Ice Cream Fitness 5x5 - Workout B
('5f5a0004-0002-4000-8000-000000000008', 'Ice Cream Fitness 5x5 - Day B', 'Jason Blaha Ice Cream Fitness Day B: Deadlift focus with overhead pressing and arm accessories.', 'strength', 'beginner', 75, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5"},
      {"name": "Overhead Press", "sets": 5, "reps": "5"},
      {"name": "Deadlift", "sets": 1, "reps": "5"}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Barbell Row", "sets": 3, "reps": "8"},
      {"name": "Close Grip Bench Press", "sets": 3, "reps": "8"},
      {"name": "Barbell Curl", "sets": 3, "reps": "8"},
      {"name": "Cable Crunches", "sets": 3, "reps": "10-20"}
    ]}
  ]
}', ARRAY['5x5', 'icf', 'beginner', 'hypertrophy', 'strength', 'accessories'], 'icf_workout_b.md'),

-- Starting Strength - Workout A
('5f5a0005-0001-4000-8000-000000000009', 'Starting Strength - Day A', 'Mark Rippetoe Starting Strength program Day A. Squat, Bench, Deadlift focus for novice lifters.', 'strength', 'beginner', 45, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Empty Bar Work", "sets": 2, "reps": "5-10", "notes": "All main lifts with empty bar"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 3, "reps": "5", "notes": "Linear progression. Add 5 lbs each session."},
      {"name": "Barbell Bench Press", "sets": 3, "reps": "5", "notes": "Alternate with Overhead Press."},
      {"name": "Deadlift", "sets": 1, "reps": "5", "notes": "One heavy work set after warmups."}
    ]}
  ]
}', ARRAY['3x5', 'starting-strength', 'beginner', 'linear-progression', 'barbell'], 'starting_strength_a.md'),

-- Starting Strength - Workout B
('5f5a0005-0002-4000-8000-000000000010', 'Starting Strength - Day B', 'Mark Rippetoe Starting Strength program Day B. Squat, Press, Power Clean for explosive strength.', 'strength', 'beginner', 45, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Empty Bar Work", "sets": 2, "reps": "5-10"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 3, "reps": "5", "notes": "Linear progression. Add 5 lbs each session."},
      {"name": "Overhead Press", "sets": 3, "reps": "5", "notes": "Strict press, no leg drive."},
      {"name": "Power Clean", "sets": 5, "reps": "3", "notes": "Explosive hip extension. Focus on technique."}
    ]}
  ]
}', ARRAY['3x5', 'starting-strength', 'beginner', 'linear-progression', 'barbell', 'olympic'], 'starting_strength_b.md'),

-- 5x5 Push Day
('5f5a0006-0001-4000-8000-000000000011', '5x5 Push Day', 'Dedicated push workout using 5x5 methodology. Focus on chest, shoulders, and triceps with compound movements.', 'strength', 'intermediate', 50, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Band Pull Aparts", "sets": 2, "reps": "15"},
      {"name": "Arm Circles", "duration": "2 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Bench Press", "sets": 5, "reps": "5", "notes": "Primary push movement."},
      {"name": "Overhead Press", "sets": 5, "reps": "5", "notes": "Strict press."},
      {"name": "Incline Dumbbell Press", "sets": 3, "reps": "8-10"}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Dips", "sets": 3, "reps": "8-12"},
      {"name": "Lateral Raises", "sets": 3, "reps": "12-15"}
    ]}
  ]
}', ARRAY['5x5', 'push', 'chest', 'shoulders', 'triceps', 'ppl'], '5x5_push.md'),

-- 5x5 Pull Day
('5f5a0006-0002-4000-8000-000000000012', '5x5 Pull Day', 'Dedicated pull workout using 5x5 methodology. Focus on back and biceps with heavy compound rowing and deadlifts.', 'strength', 'intermediate', 50, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Band Pull Aparts", "sets": 2, "reps": "15"},
      {"name": "Cat-Cow Stretch", "sets": 1, "reps": "10"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Deadlift", "sets": 5, "reps": "5", "notes": "Heavy compound pull."},
      {"name": "Barbell Row", "sets": 5, "reps": "5", "notes": "Pendlay rows from floor."},
      {"name": "Weighted Pull-ups", "sets": 3, "reps": "5-8"}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Face Pulls", "sets": 3, "reps": "15"},
      {"name": "Barbell Curl", "sets": 3, "reps": "10"}
    ]}
  ]
}', ARRAY['5x5', 'pull', 'back', 'biceps', 'deadlift', 'ppl'], '5x5_pull.md'),

-- 5x5 Legs Day
('5f5a0006-0003-4000-8000-000000000013', '5x5 Legs Day', 'Dedicated leg workout using 5x5 methodology. Heavy squats and accessories for complete lower body development.', 'strength', 'intermediate', 55, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Leg Swings", "sets": 2, "reps": "10 each"},
      {"name": "Goblet Squats", "sets": 2, "reps": "10"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5", "notes": "Primary leg movement. Full depth."},
      {"name": "Romanian Deadlift", "sets": 5, "reps": "5", "notes": "Hamstring focus."},
      {"name": "Front Squat", "sets": 3, "reps": "5", "notes": "Quad emphasis."}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Leg Press", "sets": 3, "reps": "10"},
      {"name": "Calf Raises", "sets": 4, "reps": "12-15"}
    ]}
  ]
}', ARRAY['5x5', 'legs', 'squat', 'quads', 'hamstrings', 'ppl'], '5x5_legs.md'),

-- 5x5 Upper Body
('5f5a0007-0001-4000-8000-000000000014', '5x5 Upper Body', 'Complete upper body workout using 5x5 methodology. Balance of pushing and pulling movements.', 'strength', 'intermediate', 60, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Band Pull Aparts", "sets": 2, "reps": "15"},
      {"name": "Push-ups", "sets": 2, "reps": "10"}
    ]},
    {"name": "Push", "sequence": 1, "exercises": [
      {"name": "Barbell Bench Press", "sets": 5, "reps": "5"},
      {"name": "Overhead Press", "sets": 5, "reps": "5"}
    ]},
    {"name": "Pull", "sequence": 2, "exercises": [
      {"name": "Barbell Row", "sets": 5, "reps": "5"},
      {"name": "Weighted Pull-ups", "sets": 3, "reps": "6-8"}
    ]},
    {"name": "Accessories", "sequence": 3, "exercises": [
      {"name": "Face Pulls", "sets": 3, "reps": "15"},
      {"name": "Dips", "sets": 3, "reps": "8-12"}
    ]}
  ]
}', ARRAY['5x5', 'upper-body', 'push', 'pull', 'strength', 'upper-lower'], '5x5_upper.md'),

-- 5x5 Lower Body
('5f5a0007-0002-4000-8000-000000000015', '5x5 Lower Body', 'Complete lower body workout using 5x5 methodology. Heavy squats and deadlifts for maximum strength.', 'strength', 'intermediate', 55, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Leg Swings", "sets": 2, "reps": "10 each"},
      {"name": "Box Jumps", "sets": 2, "reps": "5"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5", "notes": "Full depth squats."},
      {"name": "Deadlift", "sets": 3, "reps": "5", "notes": "Alternate with RDL weekly."}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Walking Lunges", "sets": 3, "reps": "10 each"},
      {"name": "Leg Curl", "sets": 3, "reps": "10-12"},
      {"name": "Calf Raises", "sets": 4, "reps": "15"}
    ]}
  ]
}', ARRAY['5x5', 'lower-body', 'squat', 'deadlift', 'strength', 'upper-lower'], '5x5_lower.md'),

-- 5x5 Full Body A (3 day split)
('5f5a0008-0001-4000-8000-000000000016', '5x5 Full Body - Day A', 'Full body 5x5 workout Day A. Hit all major muscle groups with squat, bench, and row focus.', 'strength', 'beginner', 50, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"},
      {"name": "Dynamic Stretching", "duration": "3 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5"},
      {"name": "Barbell Bench Press", "sets": 5, "reps": "5"},
      {"name": "Barbell Row", "sets": 5, "reps": "5"}
    ]},
    {"name": "Finisher", "sequence": 2, "exercises": [
      {"name": "Plank", "sets": 3, "duration": "30-60 sec"}
    ]}
  ]
}', ARRAY['5x5', 'full-body', 'beginner', '3-day', 'compound', 'barbell'], '5x5_fullbody_a.md'),

-- 5x5 Full Body B (3 day split)
('5f5a0008-0002-4000-8000-000000000017', '5x5 Full Body - Day B', 'Full body 5x5 workout Day B. Deadlift and overhead press focus for posterior chain and shoulders.', 'strength', 'beginner', 50, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"},
      {"name": "Dynamic Stretching", "duration": "3 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Deadlift", "sets": 3, "reps": "5"},
      {"name": "Overhead Press", "sets": 5, "reps": "5"},
      {"name": "Weighted Pull-ups", "sets": 3, "reps": "5-8", "notes": "Or Lat Pulldown if needed."}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Dumbbell Lunges", "sets": 3, "reps": "10 each"}
    ]}
  ]
}', ARRAY['5x5', 'full-body', 'beginner', '3-day', 'compound', 'barbell'], '5x5_fullbody_b.md'),

-- 5x5 Full Body C (3 day split)
('5f5a0008-0003-4000-8000-000000000018', '5x5 Full Body - Day C', 'Full body 5x5 workout Day C. Front squat variation with close grip bench for tricep emphasis.', 'strength', 'beginner', 50, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"},
      {"name": "Mobility Work", "duration": "3 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Front Squat", "sets": 5, "reps": "5", "notes": "Quad emphasis variation."},
      {"name": "Close Grip Bench Press", "sets": 5, "reps": "5"},
      {"name": "Barbell Row", "sets": 5, "reps": "5"}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Romanian Deadlift", "sets": 3, "reps": "8"}
    ]}
  ]
}', ARRAY['5x5', 'full-body', 'beginner', '3-day', 'compound', 'variation'], '5x5_fullbody_c.md'),

-- 5x5 Deload Week
('5f5a0009-0001-4000-8000-000000000019', '5x5 Deload Week', 'Recovery week for 5x5 programs. Reduce weight by 40% while maintaining movement patterns. Essential for long-term progress.', 'strength', 'beginner', 40, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"},
      {"name": "Mobility Work", "duration": "5 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 3, "reps": "5", "notes": "60% of working weight. Focus on form."},
      {"name": "Barbell Bench Press", "sets": 3, "reps": "5", "notes": "60% of working weight."},
      {"name": "Barbell Row", "sets": 3, "reps": "5", "notes": "60% of working weight."}
    ]},
    {"name": "Recovery", "sequence": 2, "exercises": [
      {"name": "Foam Rolling", "duration": "10 min"},
      {"name": "Static Stretching", "duration": "5 min"}
    ]}
  ]
}', ARRAY['5x5', 'deload', 'recovery', 'light', 'maintenance'], '5x5_deload.md'),

-- Texas Method - Volume Day
('5f5a000a-0001-4000-8000-000000000020', 'Texas Method - Volume Day', 'Texas Method Monday: High volume 5x5 workout to drive adaptation. Heavy enough to be challenging but not maximal.', 'strength', 'intermediate', 70, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"},
      {"name": "Dynamic Warmup", "duration": "5 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 5, "reps": "5", "notes": "90% of 5RM. Volume accumulation."},
      {"name": "Barbell Bench Press", "sets": 5, "reps": "5", "notes": "90% of 5RM."},
      {"name": "Deadlift", "sets": 1, "reps": "5", "notes": "Heavy single set."}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Back Extension", "sets": 3, "reps": "10-15"},
      {"name": "Weighted Dips", "sets": 3, "reps": "8-10"}
    ]}
  ]
}', ARRAY['5x5', 'texas-method', 'intermediate', 'volume', 'periodization'], 'texas_volume.md'),

-- Texas Method - Recovery Day
('5f5a000a-0002-4000-8000-000000000021', 'Texas Method - Recovery Day', 'Texas Method Wednesday: Light recovery day at 80% of volume day weights. Active recovery for supercompensation.', 'strength', 'intermediate', 45, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 2, "reps": "5", "notes": "80% of Monday weight. Light and fast."},
      {"name": "Overhead Press", "sets": 3, "reps": "5", "notes": "Moderate weight pressing."},
      {"name": "Pull-ups", "sets": 3, "reps": "Max"}
    ]},
    {"name": "Recovery", "sequence": 2, "exercises": [
      {"name": "Foam Rolling", "duration": "10 min"}
    ]}
  ]
}', ARRAY['5x5', 'texas-method', 'intermediate', 'recovery', 'light-day'], 'texas_recovery.md'),

-- Texas Method - Intensity Day
('5f5a000a-0003-4000-8000-000000000022', 'Texas Method - Intensity Day', 'Texas Method Friday: Heavy singles/doubles at new PRs. The payoff day where you test your progress.', 'strength', 'intermediate', 60, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Light Cardio", "duration": "5 min"},
      {"name": "Mobility Work", "duration": "5 min"}
    ]},
    {"name": "Main Lifts", "sequence": 1, "exercises": [
      {"name": "Barbell Back Squat", "sets": 1, "reps": "5", "notes": "Work up to new 5RM PR."},
      {"name": "Barbell Bench Press", "sets": 1, "reps": "5", "notes": "Work up to new 5RM PR."},
      {"name": "Power Clean", "sets": 5, "reps": "3", "notes": "Explosive power work."}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Barbell Curl", "sets": 3, "reps": "8-10"}
    ]}
  ]
}', ARRAY['5x5', 'texas-method', 'intermediate', 'intensity', 'pr-day'], 'texas_intensity.md'),

-- Powerlifting 5x5 Competition Prep
('5f5a000b-0001-4000-8000-000000000023', 'Powerlifting 5x5 - Squat Focus', 'Competition-style squat training using 5x5. Pause squats and accessories for powerlifting specificity.', 'strength', 'advanced', 65, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Foam Rolling", "duration": "5 min"},
      {"name": "Dynamic Stretching", "duration": "5 min"},
      {"name": "Box Jumps", "sets": 3, "reps": "3"}
    ]},
    {"name": "Main Lift", "sequence": 1, "exercises": [
      {"name": "Competition Squat", "sets": 5, "reps": "5", "notes": "Competition stance. Full depth."},
      {"name": "Pause Squat", "sets": 3, "reps": "3", "notes": "3-second pause at bottom."}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Leg Press", "sets": 4, "reps": "8-10"},
      {"name": "Good Mornings", "sets": 3, "reps": "10"},
      {"name": "Ab Wheel", "sets": 3, "reps": "10-15"}
    ]}
  ]
}', ARRAY['5x5', 'powerlifting', 'advanced', 'squat', 'competition'], 'pl_squat_5x5.md'),

-- Powerlifting 5x5 Bench Focus
('5f5a000b-0002-4000-8000-000000000024', 'Powerlifting 5x5 - Bench Focus', 'Competition-style bench training using 5x5. Pause bench and tricep work for raw powerlifting.', 'strength', 'advanced', 60, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Band Pull Aparts", "sets": 3, "reps": "15"},
      {"name": "Push-ups", "sets": 2, "reps": "10"},
      {"name": "Rotator Cuff Work", "duration": "3 min"}
    ]},
    {"name": "Main Lift", "sequence": 1, "exercises": [
      {"name": "Competition Bench Press", "sets": 5, "reps": "5", "notes": "Pause on chest. Competition commands."},
      {"name": "Close Grip Bench Press", "sets": 4, "reps": "6-8", "notes": "Tricep overload."}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Dumbbell Rows", "sets": 4, "reps": "10"},
      {"name": "Tricep Pushdowns", "sets": 3, "reps": "12-15"},
      {"name": "Face Pulls", "sets": 3, "reps": "15-20"}
    ]}
  ]
}', ARRAY['5x5', 'powerlifting', 'advanced', 'bench', 'competition'], 'pl_bench_5x5.md'),

-- Powerlifting 5x5 Deadlift Focus
('5f5a000b-0003-4000-8000-000000000025', 'Powerlifting 5x5 - Deadlift Focus', 'Competition-style deadlift training. Heavy pulls with deficit and pause variations for lockout strength.', 'strength', 'advanced', 60, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Hip Circles", "sets": 2, "reps": "10 each"},
      {"name": "Leg Swings", "sets": 2, "reps": "10 each"},
      {"name": "Glute Bridges", "sets": 2, "reps": "10"}
    ]},
    {"name": "Main Lift", "sequence": 1, "exercises": [
      {"name": "Competition Deadlift", "sets": 5, "reps": "5", "notes": "Conventional or sumo per competition style."},
      {"name": "Deficit Deadlift", "sets": 3, "reps": "3", "notes": "2-4 inch deficit for speed off floor."}
    ]},
    {"name": "Accessories", "sequence": 2, "exercises": [
      {"name": "Romanian Deadlift", "sets": 3, "reps": "8"},
      {"name": "Barbell Row", "sets": 4, "reps": "8"},
      {"name": "Hanging Leg Raises", "sets": 3, "reps": "10-15"}
    ]}
  ]
}', ARRAY['5x5', 'powerlifting', 'advanced', 'deadlift', 'competition'], 'pl_deadlift_5x5.md');

-- Verify insert
SELECT COUNT(*) as strength_5x5_template_count FROM system_workout_templates WHERE 'strength' = ANY(tags) OR '5x5' = ANY(tags);
