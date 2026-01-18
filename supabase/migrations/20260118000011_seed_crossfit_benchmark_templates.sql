-- Seed 25 CrossFit Benchmark & Hero WOD Templates
-- Famous CrossFit workouts including "The Girls" and Hero WODs
-- Category: crossfit, Difficulty: varies

INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file) VALUES

-- MURPH - With Vest
('cf100001-0001-4000-8000-000000000001', 'Murph (With Vest)', 'Hero WOD honoring Lt. Michael Murphy, Navy SEAL. 1 mile run, 100 pull-ups, 200 push-ups, 300 squats, 1 mile run. Wear 20/14 lb vest. Partition as needed.', 'cardio', 'advanced', 60, '{
  "blocks": [
    {"name": "Run", "sequence": 0, "exercises": [
      {"name": "Run", "distance": "1 mile", "notes": "Start with vest on."}
    ]},
    {"name": "Calisthenics", "sequence": 1, "exercises": [
      {"name": "Pull-ups", "reps": "100", "notes": "Partition as needed. Popular: 20 rounds of 5-10-15 (Cindy)."},
      {"name": "Push-ups", "reps": "200", "notes": "Break up however you want."},
      {"name": "Air Squats", "reps": "300", "notes": "Keep moving. 20 lb/14 lb vest throughout."}
    ]},
    {"name": "Final Run", "sequence": 2, "exercises": [
      {"name": "Run", "distance": "1 mile", "notes": "Finish strong. Elite time: sub-40 min."}
    ]}
  ]
}', ARRAY['crossfit', 'hero-wod', 'murph', 'memorial-day', 'weighted-vest', 'bodyweight'], 'murph_vest.md'),

-- MURPH - Without Vest (Scaled)
('cf100001-0002-4000-8000-000000000002', 'Murph (No Vest)', 'Murph scaled without vest. 1 mile run, 100 pull-ups, 200 push-ups, 300 squats, 1 mile run. Partition the reps as needed.', 'cardio', 'intermediate', 50, '{
  "blocks": [
    {"name": "Run", "sequence": 0, "exercises": [
      {"name": "Run", "distance": "1 mile"}
    ]},
    {"name": "Calisthenics", "sequence": 1, "exercises": [
      {"name": "Pull-ups", "reps": "100", "notes": "No vest. Partition: 20x5, 10x10, or 5x20."},
      {"name": "Push-ups", "reps": "200", "notes": "Break as needed. Keep quality."},
      {"name": "Air Squats", "reps": "300", "notes": "Full depth on every rep."}
    ]},
    {"name": "Final Run", "sequence": 2, "exercises": [
      {"name": "Run", "distance": "1 mile", "notes": "Push through the finish."}
    ]}
  ]
}', ARRAY['crossfit', 'hero-wod', 'murph', 'no-vest', 'scaled', 'bodyweight'], 'murph_no_vest.md'),

-- FRAN
('cf100002-0001-4000-8000-000000000003', 'Fran', 'CrossFit benchmark. 21-15-9 thrusters and pull-ups for time. Fast, brutal sprint. Elite time: sub-3 min.', 'cardio', 'intermediate', 10, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Thrusters", "reps": "21-15-9", "load": "95/65 lb", "notes": "Front squat to overhead press in one movement."},
      {"name": "Pull-ups", "reps": "21-15-9", "notes": "Kipping allowed. Fast transitions."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'fran', 'the-girls', 'thruster', 'sprint'], 'fran.md'),

-- GRACE
('cf100002-0002-4000-8000-000000000004', 'Grace', 'CrossFit benchmark. 30 clean and jerks for time at 135/95 lb. Simple but brutal test of Olympic lifting under fatigue.', 'cardio', 'intermediate', 10, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Clean and Jerk", "reps": "30", "load": "135/95 lb", "notes": "Touch and go or singles. Elite time: sub-2 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'grace', 'the-girls', 'clean-jerk', 'olympic'], 'grace.md'),

-- CINDY
('cf100002-0003-4000-8000-000000000005', 'Cindy', 'CrossFit benchmark. 20-min AMRAP of 5 pull-ups, 10 push-ups, 15 air squats. Test of muscular endurance and pacing.', 'cardio', 'beginner', 20, '{
  "blocks": [
    {"name": "20-Min AMRAP", "sequence": 0, "exercises": [
      {"name": "Pull-ups", "reps": "5"},
      {"name": "Push-ups", "reps": "10"},
      {"name": "Air Squats", "reps": "15", "notes": "1 round = 5-10-15. Elite: 25+ rounds."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'cindy', 'the-girls', 'amrap', 'bodyweight'], 'cindy.md'),

-- HELEN
('cf100002-0004-4000-8000-000000000006', 'Helen', 'CrossFit benchmark. 3 rounds: 400m run, 21 KB swings, 12 pull-ups. Classic conditioning test.', 'cardio', 'intermediate', 15, '{
  "blocks": [
    {"name": "3 Rounds For Time", "sequence": 0, "exercises": [
      {"name": "Run", "distance": "400m"},
      {"name": "Kettlebell Swing", "reps": "21", "load": "53/35 lb", "notes": "Russian or American swing."},
      {"name": "Pull-ups", "reps": "12", "notes": "Elite time: sub-8 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'helen', 'the-girls', 'running', 'kettlebell'], 'helen.md'),

-- DIANE
('cf100002-0005-4000-8000-000000000007', 'Diane', 'CrossFit benchmark. 21-15-9 deadlifts and handstand push-ups for time. Heavy pulling meets inverted pressing.', 'cardio', 'advanced', 10, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Deadlift", "reps": "21-15-9", "load": "225/155 lb"},
      {"name": "Handstand Push-ups", "reps": "21-15-9", "notes": "Strict or kipping. Elite: sub-4 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'diane', 'the-girls', 'deadlift', 'hspu'], 'diane.md'),

-- ISABEL
('cf100002-0006-4000-8000-000000000008', 'Isabel', 'CrossFit benchmark. 30 snatches for time at 135/95 lb. Fast and explosive Olympic lifting sprint.', 'cardio', 'advanced', 10, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Snatch", "reps": "30", "load": "135/95 lb", "notes": "Power or squat snatch. Elite: sub-2 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'isabel', 'the-girls', 'snatch', 'olympic'], 'isabel.md'),

-- ANNIE
('cf100002-0007-4000-8000-000000000009', 'Annie', 'CrossFit benchmark. 50-40-30-20-10 double-unders and sit-ups. Classic conditioning and core test.', 'cardio', 'beginner', 15, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Double Unders", "reps": "50-40-30-20-10", "notes": "Jump rope passes twice per jump."},
      {"name": "Sit-ups", "reps": "50-40-30-20-10", "notes": "AbMat or GHD. Elite: sub-6 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'annie', 'the-girls', 'double-unders', 'core'], 'annie.md'),

-- KAREN
('cf100002-0008-4000-8000-000000000010', 'Karen', 'CrossFit benchmark. 150 wall balls for time. Simple, brutal, lung-burning test of leg and shoulder endurance.', 'cardio', 'intermediate', 15, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Wall Ball", "reps": "150", "load": "20/14 lb", "notes": "10 ft target. Elite: sub-6 min. Keep moving."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'karen', 'the-girls', 'wall-ball', 'endurance'], 'karen.md'),

-- JACKIE
('cf100002-0009-4000-8000-000000000011', 'Jackie', 'CrossFit benchmark. 1000m row, 50 thrusters, 30 pull-ups for time. Classic CrossFit triplet.', 'cardio', 'intermediate', 15, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Row", "distance": "1000m"},
      {"name": "Thrusters", "reps": "50", "load": "45/35 lb"},
      {"name": "Pull-ups", "reps": "30", "notes": "Elite: sub-7 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'jackie', 'the-girls', 'rowing', 'thruster'], 'jackie.md'),

-- NANCY
('cf100002-0010-4000-8000-000000000012', 'Nancy', 'CrossFit benchmark. 5 rounds: 400m run, 15 overhead squats at 95/65 lb. Running and mobility test.', 'cardio', 'intermediate', 20, '{
  "blocks": [
    {"name": "5 Rounds For Time", "sequence": 0, "exercises": [
      {"name": "Run", "distance": "400m"},
      {"name": "Overhead Squat", "reps": "15", "load": "95/65 lb", "notes": "Full depth, active shoulders. Elite: sub-12 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'nancy', 'the-girls', 'running', 'overhead-squat'], 'nancy.md'),

-- CHELSEA
('cf100002-0011-4000-8000-000000000013', 'Chelsea', 'CrossFit benchmark. EMOM for 30 min: 5 pull-ups, 10 push-ups, 15 squats. Sustained effort pacing challenge.', 'cardio', 'intermediate', 30, '{
  "blocks": [
    {"name": "EMOM 30 Min", "sequence": 0, "exercises": [
      {"name": "Pull-ups", "reps": "5"},
      {"name": "Push-ups", "reps": "10"},
      {"name": "Air Squats", "reps": "15", "notes": "Complete all reps within each minute. 30 total rounds."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'chelsea', 'the-girls', 'emom', 'bodyweight'], 'chelsea.md'),

-- ELIZABETH
('cf100002-0012-4000-8000-000000000014', 'Elizabeth', 'CrossFit benchmark. 21-15-9 cleans and ring dips for time. Power meets gymnastics.', 'cardio', 'advanced', 12, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Clean", "reps": "21-15-9", "load": "135/95 lb", "notes": "Power or squat clean."},
      {"name": "Ring Dips", "reps": "21-15-9", "notes": "Full lockout. Elite: sub-6 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'elizabeth', 'the-girls', 'clean', 'ring-dips'], 'elizabeth.md'),

-- DT - Hero WOD
('cf100003-0001-4000-8000-000000000015', 'DT', 'Hero WOD for SSgt Timothy Davis. 5 rounds: 12 deadlifts, 9 hang power cleans, 6 push jerks at 155/105 lb. Grip destroyer.', 'cardio', 'advanced', 15, '{
  "blocks": [
    {"name": "5 Rounds For Time", "sequence": 0, "exercises": [
      {"name": "Deadlift", "reps": "12", "load": "155/105 lb"},
      {"name": "Hang Power Clean", "reps": "9", "load": "155/105 lb"},
      {"name": "Push Jerk", "reps": "6", "load": "155/105 lb", "notes": "Do not release bar. Elite: sub-8 min."}
    ]}
  ]
}', ARRAY['crossfit', 'hero-wod', 'dt', 'barbell', 'grip', 'complex'], 'dt.md'),

-- THE SEVEN - Hero WOD
('cf100003-0002-4000-8000-000000000016', 'The Seven', 'Hero WOD for 7 CIA officers. 7 rounds: 7 handstand push-ups, 7 thrusters, 7 knees-to-elbows, 7 deadlifts, 7 burpees, 7 KB swings, 7 pull-ups.', 'cardio', 'advanced', 45, '{
  "blocks": [
    {"name": "7 Rounds For Time", "sequence": 0, "exercises": [
      {"name": "Handstand Push-ups", "reps": "7"},
      {"name": "Thrusters", "reps": "7", "load": "135/95 lb"},
      {"name": "Knees-to-Elbows", "reps": "7"},
      {"name": "Deadlift", "reps": "7", "load": "245/165 lb"},
      {"name": "Burpees", "reps": "7"},
      {"name": "Kettlebell Swing", "reps": "7", "load": "53/35 lb"},
      {"name": "Pull-ups", "reps": "7", "notes": "7 movements, 7 reps each, 7 rounds."}
    ]}
  ]
}', ARRAY['crossfit', 'hero-wod', 'the-seven', 'long', 'varied'], 'the_seven.md'),

-- MICHAEL - Hero WOD
('cf100003-0003-4000-8000-000000000017', 'Michael', 'Hero WOD for Lt Michael McGreevy. 3 rounds: 800m run, 50 back extensions, 50 sit-ups. Running and posterior chain.', 'cardio', 'intermediate', 30, '{
  "blocks": [
    {"name": "3 Rounds For Time", "sequence": 0, "exercises": [
      {"name": "Run", "distance": "800m"},
      {"name": "Back Extensions", "reps": "50"},
      {"name": "Sit-ups", "reps": "50", "notes": "Elite: sub-25 min."}
    ]}
  ]
}', ARRAY['crossfit', 'hero-wod', 'michael', 'running', 'posterior-chain'], 'michael.md'),

-- FILTHY FIFTY
('cf100004-0001-4000-8000-000000000018', 'Filthy Fifty', 'Classic CrossFit chipper. 50 reps each of 10 movements for time. Mental and physical grind.', 'cardio', 'advanced', 35, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Box Jumps", "reps": "50", "height": "24/20 in"},
      {"name": "Jumping Pull-ups", "reps": "50"},
      {"name": "Kettlebell Swings", "reps": "50", "load": "35/26 lb"},
      {"name": "Walking Lunges", "reps": "50 steps"},
      {"name": "Knees-to-Elbows", "reps": "50"},
      {"name": "Push Press", "reps": "50", "load": "45/35 lb"},
      {"name": "Back Extensions", "reps": "50"},
      {"name": "Wall Balls", "reps": "50", "load": "20/14 lb"},
      {"name": "Burpees", "reps": "50"},
      {"name": "Double Unders", "reps": "50", "notes": "Elite: sub-20 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'filthy-fifty', 'chipper', 'long', 'varied'], 'filthy_fifty.md'),

-- RANDY - Hero WOD
('cf100003-0004-4000-8000-000000000019', 'Randy', 'Hero WOD for Randy Simmons LAPD SWAT. 75 power snatches for time at 75/55 lb. High-rep Olympic lifting sprint.', 'cardio', 'intermediate', 10, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Power Snatch", "reps": "75", "load": "75/55 lb", "notes": "Touch and go or singles. Elite: sub-4 min."}
    ]}
  ]
}', ARRAY['crossfit', 'hero-wod', 'randy', 'snatch', 'olympic', 'high-rep'], 'randy.md'),

-- JT - Hero WOD
('cf100003-0005-4000-8000-000000000020', 'JT', 'Hero WOD for PO1 Jeff Taylor Navy SEAL. 21-15-9 handstand push-ups, ring dips, push-ups. Upper body pressing gauntlet.', 'cardio', 'advanced', 15, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Handstand Push-ups", "reps": "21-15-9"},
      {"name": "Ring Dips", "reps": "21-15-9"},
      {"name": "Push-ups", "reps": "21-15-9", "notes": "All pushing. Elite: sub-8 min."}
    ]}
  ]
}', ARRAY['crossfit', 'hero-wod', 'jt', 'pressing', 'gymnastics', 'upper-body'], 'jt.md'),

-- NATE - Hero WOD
('cf100003-0006-4000-8000-000000000021', 'Nate', 'Hero WOD for Chief Petty Officer Nate Hardy. 20-min AMRAP: 2 muscle-ups, 4 handstand push-ups, 8 KB swings 70/53 lb.', 'cardio', 'advanced', 20, '{
  "blocks": [
    {"name": "20-Min AMRAP", "sequence": 0, "exercises": [
      {"name": "Muscle-ups", "reps": "2"},
      {"name": "Handstand Push-ups", "reps": "4"},
      {"name": "Kettlebell Swing", "reps": "8", "load": "70/53 lb", "notes": "Elite: 15+ rounds."}
    ]}
  ]
}', ARRAY['crossfit', 'hero-wod', 'nate', 'muscle-up', 'advanced-gymnastics'], 'nate.md'),

-- BADGER - Hero WOD
('cf100003-0007-4000-8000-000000000022', 'Badger', 'Hero WOD for Navy Chief Mark Carter. 3 rounds: 30 squat cleans 95/65 lb, 30 pull-ups, 800m run. Long grinding test.', 'cardio', 'advanced', 40, '{
  "blocks": [
    {"name": "3 Rounds For Time", "sequence": 0, "exercises": [
      {"name": "Squat Clean", "reps": "30", "load": "95/65 lb"},
      {"name": "Pull-ups", "reps": "30"},
      {"name": "Run", "distance": "800m", "notes": "Elite: sub-30 min."}
    ]}
  ]
}', ARRAY['crossfit', 'hero-wod', 'badger', 'squat-clean', 'running', 'long'], 'badger.md'),

-- AMANDA
('cf100002-0013-4000-8000-000000000023', 'Amanda', 'CrossFit benchmark. 9-7-5 muscle-ups and squat snatches 135/95 lb. High skill, heavy weight.', 'cardio', 'advanced', 12, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Muscle-ups", "reps": "9-7-5"},
      {"name": "Squat Snatch", "reps": "9-7-5", "load": "135/95 lb", "notes": "Elite: sub-6 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'amanda', 'the-girls', 'muscle-up', 'snatch'], 'amanda.md'),

-- ANGIE
('cf100002-0014-4000-8000-000000000024', 'Angie', 'CrossFit benchmark. 100 pull-ups, 100 push-ups, 100 sit-ups, 100 air squats for time. Complete each before moving on.', 'cardio', 'intermediate', 25, '{
  "blocks": [
    {"name": "For Time", "sequence": 0, "exercises": [
      {"name": "Pull-ups", "reps": "100", "notes": "Complete all before moving on."},
      {"name": "Push-ups", "reps": "100"},
      {"name": "Sit-ups", "reps": "100"},
      {"name": "Air Squats", "reps": "100", "notes": "Elite: sub-15 min."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'angie', 'the-girls', 'bodyweight', 'chipper'], 'angie.md'),

-- FIGHT GONE BAD
('cf100004-0002-4000-8000-000000000025', 'Fight Gone Bad', 'Classic CrossFit benchmark. 3 rounds: 1 min each of wall balls, SDHP, box jumps, push press, row. 1 min rest between rounds.', 'cardio', 'intermediate', 20, '{
  "blocks": [
    {"name": "3 Rounds", "sequence": 0, "exercises": [
      {"name": "Wall Ball", "duration": "1 min", "load": "20/14 lb", "notes": "Max reps in 1 minute."},
      {"name": "Sumo Deadlift High Pull", "duration": "1 min", "load": "75/55 lb"},
      {"name": "Box Jump", "duration": "1 min", "height": "20 in"},
      {"name": "Push Press", "duration": "1 min", "load": "75/55 lb"},
      {"name": "Row (Calories)", "duration": "1 min", "notes": "1 min rest after each round. Total all reps. Elite: 400+ reps."}
    ]}
  ]
}', ARRAY['crossfit', 'benchmark', 'fight-gone-bad', 'mixed-modal', 'timed-intervals'], 'fight_gone_bad.md');

-- Verify insert
SELECT COUNT(*) as crossfit_template_count FROM system_workout_templates WHERE 'crossfit' = ANY(tags);
