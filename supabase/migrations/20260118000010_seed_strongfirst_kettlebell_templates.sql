-- Seed 25 StrongFirst Kettlebell Workout Templates
-- Based on Pavel Tsatsouline's StrongFirst methodology
-- Category: strength/conditioning, Difficulty: varies

INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file) VALUES

-- Simple & Sinister - Standard
('5f1a0001-0001-4000-8000-000000000001', 'Simple & Sinister - Standard', 'Pavel Tsatsouline flagship kettlebell program. 100 swings and 10 get-ups. Minimum effective dose for maximum results.', 'strength', 'intermediate', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Goblet Squat", "sets": 3, "reps": "5", "notes": "Pry at bottom, open hips."},
      {"name": "Hip Bridge", "sets": 3, "reps": "5"},
      {"name": "Halo", "sets": 3, "reps": "5 each direction"}
    ]},
    {"name": "Swings", "sequence": 1, "exercises": [
      {"name": "One-Arm Kettlebell Swing", "sets": 10, "reps": "10", "notes": "Every 30 seconds. 5 left, 5 right per set. Complete in 5 minutes."}
    ]},
    {"name": "Get-ups", "sequence": 2, "exercises": [
      {"name": "Turkish Get-up", "sets": 10, "reps": "1", "notes": "Alternate sides. One rep per minute for 10 minutes."}
    ]},
    {"name": "Cooldown", "sequence": 3, "exercises": [
      {"name": "90/90 Stretch", "sets": 2, "duration": "30 sec each"},
      {"name": "Bretzel Stretch", "sets": 2, "duration": "30 sec each"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'simple-sinister', 'swing', 'getup', 'pavel'], 'simple_sinister_standard.md'),

-- Simple & Sinister - Light Day
('5f1a0001-0002-4000-8000-000000000002', 'Simple & Sinister - Light Day', 'Reduced volume S&S session for recovery days. Maintain movement quality with lower intensity.', 'strength', 'beginner', 20, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Goblet Squat", "sets": 3, "reps": "5"},
      {"name": "Hip Bridge", "sets": 2, "reps": "5"}
    ]},
    {"name": "Swings", "sequence": 1, "exercises": [
      {"name": "One-Arm Kettlebell Swing", "sets": 5, "reps": "10", "notes": "50 total swings. Light bell."}
    ]},
    {"name": "Get-ups", "sequence": 2, "exercises": [
      {"name": "Turkish Get-up", "sets": 5, "reps": "1", "notes": "5 total. Light bell. Focus on form."}
    ]},
    {"name": "Mobility", "sequence": 3, "exercises": [
      {"name": "Bretzel Stretch", "sets": 2, "duration": "45 sec each"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'simple-sinister', 'light-day', 'recovery'], 'simple_sinister_light.md'),

-- Simple & Sinister - Test Day
('5f1a0001-0003-4000-8000-000000000003', 'Simple & Sinister - Test Day', 'S&S timed test protocol. Goal: 100 swings in 5 min, 10 TGUs in 10 min with goal weight.', 'strength', 'advanced', 25, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Goblet Squat", "sets": 3, "reps": "5"},
      {"name": "Halo", "sets": 3, "reps": "5 each"},
      {"name": "Swing Warmup", "sets": 2, "reps": "10", "notes": "Light bell."}
    ]},
    {"name": "Swing Test", "sequence": 1, "exercises": [
      {"name": "One-Arm Kettlebell Swing", "sets": 10, "reps": "10", "notes": "TIMED: Complete all 100 in 5 minutes. 10 swings every 30 sec."}
    ]},
    {"name": "Rest", "sequence": 2, "exercises": [
      {"name": "Rest", "duration": "1 min", "notes": "Quick recovery before get-ups."}
    ]},
    {"name": "Get-up Test", "sequence": 3, "exercises": [
      {"name": "Turkish Get-up", "sets": 10, "reps": "1", "notes": "TIMED: Complete 10 TGUs in 10 minutes. 1 per minute."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'simple-sinister', 'test', 'timed', 'assessment'], 'simple_sinister_test.md'),

-- StrongFirst Swing Focus
('5f1a0002-0001-4000-8000-000000000004', 'StrongFirst Swing Focus', 'Deep dive into the kettlebell swing. Variations and high volume for hip power and conditioning.', 'cardio', 'intermediate', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Hip Bridge", "sets": 3, "reps": "10"},
      {"name": "Deadlift (Light KB)", "sets": 2, "reps": "5"},
      {"name": "Hike Pass", "sets": 2, "reps": "10"}
    ]},
    {"name": "Swing Variations", "sequence": 1, "exercises": [
      {"name": "Two-Hand Kettlebell Swing", "sets": 5, "reps": "15", "notes": "Focus on hip snap."},
      {"name": "One-Arm Kettlebell Swing", "sets": 5, "reps": "10 each", "notes": "Rotate arms each set."},
      {"name": "Hand-to-Hand Swing", "sets": 3, "reps": "20", "notes": "Switch hands at top of swing."}
    ]},
    {"name": "Finisher", "sequence": 2, "exercises": [
      {"name": "Swing EMOM", "sets": 5, "reps": "15", "notes": "Every minute on the minute."}
    ]},
    {"name": "Stretch", "sequence": 3, "exercises": [
      {"name": "Hip Flexor Stretch", "sets": 2, "duration": "45 sec each"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'swing', 'hip-power', 'conditioning'], 'sf_swing_focus.md'),

-- StrongFirst Get-up Mastery
('5f1a0002-0002-4000-8000-000000000005', 'StrongFirst Get-up Mastery', 'Turkish get-up focused session. Break down the movement and build toward heavier bells.', 'strength', 'intermediate', 35, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Arm Bar", "sets": 2, "reps": "3 each", "notes": "Shoulder stability and thoracic mobility."},
      {"name": "Half Kneeling Windmill", "sets": 2, "reps": "3 each"}
    ]},
    {"name": "Get-up Breakdown", "sequence": 1, "exercises": [
      {"name": "TGU to Elbow", "sets": 2, "reps": "3 each", "notes": "Practice first phase."},
      {"name": "TGU to Tall Sit", "sets": 2, "reps": "3 each"},
      {"name": "TGU to Half Kneeling", "sets": 2, "reps": "3 each"}
    ]},
    {"name": "Full Get-ups", "sequence": 2, "exercises": [
      {"name": "Turkish Get-up", "sets": 5, "reps": "1 each side", "notes": "Full movement. Take your time."}
    ]},
    {"name": "Heavy Singles", "sequence": 3, "exercises": [
      {"name": "Heavy Turkish Get-up", "sets": 3, "reps": "1 each", "notes": "Challenge weight. Perfect form."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'turkish-getup', 'mobility', 'stability'], 'sf_getup_mastery.md'),

-- StrongFirst Quick & Dead
('5f1a0003-0001-4000-8000-000000000006', 'StrongFirst Quick & Dead', 'Anti-glycolytic power training. Short explosive efforts with full recovery for maximal power output.', 'strength', 'advanced', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Goblet Squat", "sets": 3, "reps": "5"},
      {"name": "Swing Warmup", "sets": 3, "reps": "10"}
    ]},
    {"name": "Power Series A", "sequence": 1, "exercises": [
      {"name": "One-Arm Swing", "sets": 5, "reps": "5", "notes": "Max power. 3-5 min rest between sets."},
      {"name": "Push-up", "sets": 5, "reps": "5", "notes": "Explosive. Alternate with swings."}
    ]},
    {"name": "Power Series B", "sequence": 2, "exercises": [
      {"name": "One-Arm Swing", "sets": 5, "reps": "5", "notes": "Other arm. Max power."},
      {"name": "Explosive Push-up", "sets": 5, "reps": "5", "notes": "Clapping or release push-ups."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'quick-dead', 'power', 'anti-glycolytic'], 'sf_quick_dead.md'),

-- StrongFirst Total Tension Complex
('5f1a0004-0001-4000-8000-000000000007', 'StrongFirst Total Tension Complex', 'Grind-focused kettlebell session. Slow, controlled lifts for maximum muscle tension and strength.', 'strength', 'intermediate', 40, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Arm Bar", "sets": 2, "duration": "30 sec each"},
      {"name": "Goblet Squat", "sets": 3, "reps": "5"}
    ]},
    {"name": "Grind Lifts", "sequence": 1, "exercises": [
      {"name": "Kettlebell Press", "sets": 5, "reps": "5 each", "notes": "Strict press. Maximum tension."},
      {"name": "Kettlebell Front Squat", "sets": 5, "reps": "5", "notes": "Double KB or single. Full depth."},
      {"name": "Kettlebell Floor Press", "sets": 3, "reps": "5 each", "notes": "Controlled tempo."}
    ]},
    {"name": "Loaded Carries", "sequence": 2, "exercises": [
      {"name": "Farmers Walk", "sets": 3, "distance": "40 yards"},
      {"name": "Rack Walk", "sets": 2, "distance": "40 yards each side"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'grind', 'tension', 'press', 'squat'], 'sf_tension_complex.md'),

-- StrongFirst Double Kettlebell
('5f1a0005-0001-4000-8000-000000000008', 'StrongFirst Double KB Session', 'Double kettlebell training for increased load and complexity. Builds serious strength and stability.', 'strength', 'advanced', 40, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Single KB Swing", "sets": 2, "reps": "10 each"},
      {"name": "Goblet Squat", "sets": 2, "reps": "5"}
    ]},
    {"name": "Double KB Work", "sequence": 1, "exercises": [
      {"name": "Double Kettlebell Swing", "sets": 5, "reps": "10", "notes": "Powerful hip drive."},
      {"name": "Double Kettlebell Clean", "sets": 4, "reps": "5", "notes": "Rack position focus."},
      {"name": "Double Kettlebell Press", "sets": 5, "reps": "3-5", "notes": "Strict press both bells."},
      {"name": "Double Kettlebell Front Squat", "sets": 5, "reps": "5", "notes": "Full depth, vertical torso."}
    ]},
    {"name": "Finisher", "sequence": 2, "exercises": [
      {"name": "Double KB Farmers Walk", "sets": 3, "distance": "50 yards"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'double-kb', 'strength', 'advanced'], 'sf_double_kb.md'),

-- StrongFirst Rite of Passage - Press Ladder
('5f1a0006-0001-4000-8000-000000000009', 'ROP Press Ladder - Light', 'Enter the Kettlebell Rite of Passage. Press ladder program for building overhead strength. Light day.', 'strength', 'intermediate', 35, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Halo", "sets": 3, "reps": "5 each"},
      {"name": "Goblet Squat", "sets": 3, "reps": "5"},
      {"name": "Face-the-Wall Squat", "sets": 2, "reps": "5"}
    ]},
    {"name": "Press Ladders", "sequence": 1, "exercises": [
      {"name": "Clean & Press Ladder", "sets": 3, "reps": "1,2,3", "notes": "3 ladders of 1-2-3. 18 total presses each arm."}
    ]},
    {"name": "Swings", "sequence": 2, "exercises": [
      {"name": "One-Arm Swing", "sets": 5, "reps": "10 each", "notes": "Between press sets."}
    ]},
    {"name": "Variety Pull", "sequence": 3, "exercises": [
      {"name": "Pull-ups", "sets": 3, "reps": "3-5", "notes": "Ladders or straight sets."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'rop', 'press', 'ladder', 'light-day'], 'rop_press_light.md'),

-- StrongFirst ROP - Medium
('5f1a0006-0002-4000-8000-000000000010', 'ROP Press Ladder - Medium', 'Rite of Passage medium volume day. Longer ladders for increased pressing volume.', 'strength', 'intermediate', 40, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Halo", "sets": 3, "reps": "5 each"},
      {"name": "Goblet Squat", "sets": 3, "reps": "5"},
      {"name": "Pump Stretch", "sets": 2, "reps": "5"}
    ]},
    {"name": "Press Ladders", "sequence": 1, "exercises": [
      {"name": "Clean & Press Ladder", "sets": 3, "reps": "1,2,3,4", "notes": "3 ladders of 1-2-3-4. 30 total presses each arm."}
    ]},
    {"name": "Swings", "sequence": 2, "exercises": [
      {"name": "One-Arm Swing", "sets": 6, "reps": "15 each", "notes": "Higher volume swing day."}
    ]},
    {"name": "Pull", "sequence": 3, "exercises": [
      {"name": "Pull-ups", "sets": 3, "reps": "1,2,3", "notes": "Match press ladder structure."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'rop', 'press', 'ladder', 'medium-day'], 'rop_press_medium.md'),

-- StrongFirst ROP - Heavy
('5f1a0006-0003-4000-8000-000000000011', 'ROP Press Ladder - Heavy', 'Rite of Passage heavy day. Max ladder length for peak pressing volume.', 'strength', 'advanced', 45, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Arm Bar", "sets": 2, "reps": "3 each"},
      {"name": "Halo", "sets": 3, "reps": "5 each"},
      {"name": "Goblet Squat", "sets": 3, "reps": "5"}
    ]},
    {"name": "Press Ladders", "sequence": 1, "exercises": [
      {"name": "Clean & Press Ladder", "sets": 5, "reps": "1,2,3,4,5", "notes": "5 ladders of 1-2-3-4-5. 75 total presses each arm."}
    ]},
    {"name": "Swings", "sequence": 2, "exercises": [
      {"name": "One-Arm Swing", "sets": 10, "reps": "10 each", "notes": "100 total swings."}
    ]},
    {"name": "Pull", "sequence": 3, "exercises": [
      {"name": "Pull-ups", "sets": 5, "reps": "1,2,3", "notes": "Volume pulling."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'rop', 'press', 'ladder', 'heavy-day'], 'rop_press_heavy.md'),

-- StrongFirst Snatch Practice
('5f1a0007-0001-4000-8000-000000000012', 'StrongFirst Snatch Practice', 'Kettlebell snatch skill session. Build toward the 100-rep snatch test standard.', 'cardio', 'advanced', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Halo", "sets": 2, "reps": "5 each"},
      {"name": "One-Arm Swing", "sets": 3, "reps": "10 each"},
      {"name": "High Pull", "sets": 2, "reps": "5 each"}
    ]},
    {"name": "Snatch Practice", "sequence": 1, "exercises": [
      {"name": "Kettlebell Snatch", "sets": 5, "reps": "5 each", "notes": "Focus on technique. Soft catch."},
      {"name": "Dead Snatch", "sets": 3, "reps": "3 each", "notes": "From floor each rep. Power focus."}
    ]},
    {"name": "Snatch Volume", "sequence": 2, "exercises": [
      {"name": "Snatch EMOM", "sets": 10, "reps": "5 each", "notes": "10 snatches per minute. Alternate arms."}
    ]},
    {"name": "Cooldown", "sequence": 3, "exercises": [
      {"name": "Arm Bar", "sets": 2, "duration": "30 sec each"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'snatch', 'conditioning', 'power'], 'sf_snatch_practice.md'),

-- StrongFirst Snatch Test Prep
('5f1a0007-0002-4000-8000-000000000013', 'StrongFirst Snatch Test Prep', 'Train for the SFG snatch test: 100 snatches in 5 minutes with competition weight.', 'cardio', 'advanced', 25, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Swing", "sets": 3, "reps": "10"},
      {"name": "High Pull", "sets": 2, "reps": "5 each"}
    ]},
    {"name": "Snatch Test Protocol", "sequence": 1, "exercises": [
      {"name": "Timed Snatch Set", "sets": 1, "reps": "100", "notes": "Goal: Complete 100 snatches in 5 min. 10 per 30 sec. Switch hands as needed."}
    ]},
    {"name": "Practice Protocols", "sequence": 2, "exercises": [
      {"name": "Snatch", "sets": 5, "reps": "20", "notes": "5 sets of 20 with 1-min rest. Build capacity."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'snatch-test', 'sfg', 'certification', 'timed'], 'sf_snatch_test_prep.md'),

-- StrongFirst Armor Building Complex
('5f1a0008-0001-4000-8000-000000000014', 'Armor Building Complex', 'Dan John classic with kettlebells. Build work capacity and full-body strength.', 'strength', 'intermediate', 25, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Goblet Squat", "sets": 3, "reps": "5"},
      {"name": "Halo", "sets": 2, "reps": "5 each"}
    ]},
    {"name": "Armor Building Complex", "sequence": 1, "exercises": [
      {"name": "Double KB Clean", "reps": "2"},
      {"name": "Double KB Press", "reps": "1"},
      {"name": "Double KB Front Squat", "reps": "3", "notes": "2 cleans, 1 press, 3 squats = 1 complex. Complete AMRAP in 20 min or sets of 5-10 complexes."}
    ]},
    {"name": "Swing Finisher", "sequence": 2, "exercises": [
      {"name": "One-Arm Swing", "sets": 5, "reps": "10 each"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'complex', 'dan-john', 'armor-building'], 'sf_armor_building.md'),

-- StrongFirst Clean & Jerk
('5f1a0009-0001-4000-8000-000000000015', 'StrongFirst Clean & Jerk', 'Kettlebell clean and jerk session. Olympic-style lifting with kettlebells for power and conditioning.', 'strength', 'advanced', 35, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Swing", "sets": 3, "reps": "10"},
      {"name": "Goblet Squat", "sets": 2, "reps": "5"},
      {"name": "Press", "sets": 2, "reps": "5 each"}
    ]},
    {"name": "Clean Practice", "sequence": 1, "exercises": [
      {"name": "Kettlebell Clean", "sets": 3, "reps": "5 each", "notes": "Focus on rack position."},
      {"name": "Double KB Clean", "sets": 3, "reps": "3"}
    ]},
    {"name": "Jerk Practice", "sequence": 2, "exercises": [
      {"name": "Push Press", "sets": 3, "reps": "5 each", "notes": "Build leg drive."},
      {"name": "Kettlebell Jerk", "sets": 5, "reps": "3 each", "notes": "Explosive dip and drive."}
    ]},
    {"name": "Full Lift", "sequence": 3, "exercises": [
      {"name": "Clean & Jerk", "sets": 5, "reps": "3 each", "notes": "Full movement. Power and precision."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'clean-jerk', 'olympic', 'power'], 'sf_clean_jerk.md'),

-- StrongFirst Bent Press
('5f1a0010-0001-4000-8000-000000000016', 'StrongFirst Bent Press', 'Old-time strongman bent press. Ultimate display of shoulder strength and flexibility.', 'strength', 'advanced', 40, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Arm Bar", "sets": 3, "reps": "3 each", "notes": "Essential for bent press prep."},
      {"name": "Windmill", "sets": 2, "reps": "3 each"},
      {"name": "Get-up", "sets": 2, "reps": "1 each"}
    ]},
    {"name": "Bent Press Progression", "sequence": 1, "exercises": [
      {"name": "Half Kneeling Windmill", "sets": 2, "reps": "3 each"},
      {"name": "Low Windmill", "sets": 2, "reps": "3 each"},
      {"name": "Side Press", "sets": 3, "reps": "3 each", "notes": "Lean away from pressing arm."}
    ]},
    {"name": "Bent Press", "sequence": 2, "exercises": [
      {"name": "Kettlebell Bent Press", "sets": 5, "reps": "1-3 each", "notes": "Low the body under the bell. Ultimate grind."}
    ]},
    {"name": "Cooldown", "sequence": 3, "exercises": [
      {"name": "Bretzel Stretch", "sets": 2, "duration": "45 sec each"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'bent-press', 'oldtime', 'shoulder-strength'], 'sf_bent_press.md'),

-- StrongFirst Windmill Session
('5f1a0011-0001-4000-8000-000000000017', 'StrongFirst Windmill Session', 'Kettlebell windmill focus. Build hip hinge flexibility and shoulder stability simultaneously.', 'mobility', 'intermediate', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Arm Bar", "sets": 2, "reps": "3 each"},
      {"name": "Hip Hinge", "sets": 2, "reps": "10"},
      {"name": "Halo", "sets": 2, "reps": "5 each"}
    ]},
    {"name": "Windmill Progression", "sequence": 1, "exercises": [
      {"name": "Bodyweight Windmill", "sets": 2, "reps": "5 each", "notes": "Master pattern without load."},
      {"name": "Low Windmill", "sets": 3, "reps": "3 each", "notes": "KB in bottom hand."},
      {"name": "High Windmill", "sets": 3, "reps": "3 each", "notes": "KB overhead in top hand."}
    ]},
    {"name": "Double Windmill", "sequence": 2, "exercises": [
      {"name": "Double Kettlebell Windmill", "sets": 3, "reps": "3 each", "notes": "Advanced: KB in both hands."}
    ]},
    {"name": "Stretch", "sequence": 3, "exercises": [
      {"name": "90/90 Stretch", "sets": 2, "duration": "45 sec each"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'windmill', 'mobility', 'hip-hinge'], 'sf_windmill_session.md'),

-- StrongFirst Bottoms Up
('5f1a0012-0001-4000-8000-000000000018', 'StrongFirst Bottoms Up', 'Bottoms-up kettlebell training. Ultimate grip and shoulder stability challenge.', 'strength', 'advanced', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Wrist Circles", "sets": 2, "reps": "10 each"},
      {"name": "Regular Press", "sets": 2, "reps": "5 each"},
      {"name": "Farmers Walk", "sets": 2, "distance": "30 yards"}
    ]},
    {"name": "Bottoms Up Work", "sequence": 1, "exercises": [
      {"name": "Bottoms Up Clean", "sets": 3, "reps": "3 each", "notes": "Grip hard. Keep bell balanced."},
      {"name": "Bottoms Up Press", "sets": 5, "reps": "1-3 each", "notes": "Crush grip. Total body tension."},
      {"name": "Bottoms Up Walk", "sets": 3, "distance": "20 yards each", "notes": "Maintain position while walking."}
    ]},
    {"name": "Grip Finisher", "sequence": 2, "exercises": [
      {"name": "Heavy Farmers Walk", "sets": 3, "distance": "40 yards"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'bottoms-up', 'grip', 'stability'], 'sf_bottoms_up.md'),

-- StrongFirst Loaded Carries
('5f1a0013-0001-4000-8000-000000000019', 'StrongFirst Loaded Carries', 'Variety of kettlebell carries for core strength and conditioning. Dan John loaded carry emphasis.', 'strength', 'intermediate', 25, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Goblet Squat", "sets": 2, "reps": "5"},
      {"name": "Halo", "sets": 2, "reps": "5 each"}
    ]},
    {"name": "Carries", "sequence": 1, "exercises": [
      {"name": "Farmers Walk", "sets": 3, "distance": "50 yards", "notes": "Double KB at sides."},
      {"name": "Rack Walk", "sets": 3, "distance": "40 yards each", "notes": "Single KB in rack position."},
      {"name": "Overhead Walk", "sets": 3, "distance": "30 yards each", "notes": "Single KB locked out overhead."},
      {"name": "Suitcase Walk", "sets": 3, "distance": "40 yards each", "notes": "Single KB one side. Anti-lateral flexion."}
    ]},
    {"name": "Mixed Carry", "sequence": 2, "exercises": [
      {"name": "Cross Body Carry", "sets": 2, "distance": "40 yards each", "notes": "One KB overhead, one at side."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'loaded-carries', 'core', 'dan-john'], 'sf_loaded_carries.md'),

-- StrongFirst Squat Focus
('5f1a0014-0001-4000-8000-000000000020', 'StrongFirst Squat Focus', 'Kettlebell squat variations for leg strength. From goblet to front squat to pistol progression.', 'strength', 'intermediate', 35, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Goblet Squat Prying", "sets": 3, "reps": "5", "notes": "Pry knees open at bottom."},
      {"name": "Face-the-Wall Squat", "sets": 2, "reps": "5"}
    ]},
    {"name": "Squat Variations", "sequence": 1, "exercises": [
      {"name": "Goblet Squat", "sets": 3, "reps": "8", "notes": "Heavy goblet."},
      {"name": "Double KB Front Squat", "sets": 5, "reps": "5", "notes": "Bells in rack. Vertical torso."},
      {"name": "KB Zercher Squat", "sets": 3, "reps": "6", "notes": "Cradle KB in elbows."}
    ]},
    {"name": "Single Leg", "sequence": 2, "exercises": [
      {"name": "KB Box Pistol", "sets": 3, "reps": "5 each", "notes": "Squat to box, single leg."},
      {"name": "KB Pistol Squat", "sets": 3, "reps": "3 each", "notes": "Full pistol if able. KB as counterbalance."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'squat', 'pistol', 'leg-strength'], 'sf_squat_focus.md'),

-- StrongFirst Flow
('5f1a0015-0001-4000-8000-000000000021', 'StrongFirst Flow', 'Continuous kettlebell flow combining movements. Build work capacity and movement quality.', 'cardio', 'intermediate', 25, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Halo", "sets": 2, "reps": "5 each"},
      {"name": "Goblet Squat", "sets": 2, "reps": "5"}
    ]},
    {"name": "KB Flow", "sequence": 1, "exercises": [
      {"name": "Swing to Clean to Press Flow", "sets": 5, "reps": "5 each", "notes": "1 swing, 1 clean, 1 press = 1 rep. Continuous movement."},
      {"name": "Clean to Squat to Press Flow", "sets": 4, "reps": "5 each", "notes": "Clean, front squat, press overhead."},
      {"name": "Snatch to Windmill Flow", "sets": 3, "reps": "3 each", "notes": "Snatch up, windmill down, snatch up."}
    ]},
    {"name": "Finisher", "sequence": 2, "exercises": [
      {"name": "AMRAP Complex", "sets": 1, "duration": "5 min", "notes": "Swing-Clean-Press-Squat. Max rounds."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'flow', 'complex', 'conditioning'], 'sf_flow.md'),

-- StrongFirst Hardstyle Abs
('5f1a0016-0001-4000-8000-000000000022', 'StrongFirst Hardstyle Abs', 'Core training using StrongFirst hardstyle principles. Tension-based core strength.', 'strength', 'intermediate', 25, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Deadbug", "sets": 2, "reps": "5 each"},
      {"name": "Bird Dog", "sets": 2, "reps": "5 each"}
    ]},
    {"name": "Hardstyle Core", "sequence": 1, "exercises": [
      {"name": "Hollow Body Hold", "sets": 3, "duration": "20-30 sec", "notes": "Maximum tension."},
      {"name": "Hard Roll", "sets": 3, "reps": "3 each direction", "notes": "Roll from back to belly with tension."},
      {"name": "Hardstyle Plank", "sets": 3, "duration": "10-20 sec", "notes": "Max tension. Quality over time."}
    ]},
    {"name": "KB Core", "sequence": 2, "exercises": [
      {"name": "KB Pullover", "sets": 3, "reps": "8", "notes": "Arms overhead to chest."},
      {"name": "Suitcase Deadlift", "sets": 3, "reps": "5 each", "notes": "Single KB. Anti-rotation."},
      {"name": "Turkish Get-up", "sets": 3, "reps": "1 each", "notes": "Ultimate core exercise."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'core', 'abs', 'hardstyle', 'tension'], 'sf_hardstyle_abs.md'),

-- StrongFirst Sport Preparation
('5f1a0017-0001-4000-8000-000000000023', 'StrongFirst Sport Prep', 'Kettlebell training for athletic performance. Power, conditioning, and movement prep for sport.', 'cardio', 'intermediate', 35, '{
  "blocks": [
    {"name": "Movement Prep", "sequence": 0, "exercises": [
      {"name": "Goblet Squat", "sets": 2, "reps": "5"},
      {"name": "Hip Bridge", "sets": 2, "reps": "10"},
      {"name": "Thoracic Rotation", "sets": 2, "reps": "5 each"}
    ]},
    {"name": "Power", "sequence": 1, "exercises": [
      {"name": "KB Swing", "sets": 5, "reps": "10", "notes": "Explosive hip drive."},
      {"name": "KB Push Press", "sets": 4, "reps": "5 each", "notes": "Power from legs."},
      {"name": "KB Jump Squat", "sets": 3, "reps": "5", "notes": "Goblet position. Explosive jump."}
    ]},
    {"name": "Conditioning", "sequence": 2, "exercises": [
      {"name": "Swing Intervals", "sets": 5, "reps": "15", "notes": "30 sec work, 30 sec rest."}
    ]},
    {"name": "Mobility", "sequence": 3, "exercises": [
      {"name": "Bretzel Stretch", "sets": 2, "duration": "30 sec each"},
      {"name": "90/90 Stretch", "sets": 2, "duration": "30 sec each"}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'sport', 'athletic', 'power', 'conditioning'], 'sf_sport_prep.md'),

-- StrongFirst Minimalist
('5f1a0018-0001-4000-8000-000000000024', 'StrongFirst Minimalist', 'Minimum effective dose kettlebell session. Maximum results in minimum time.', 'strength', 'beginner', 15, '{
  "blocks": [
    {"name": "Complete Session", "sequence": 0, "exercises": [
      {"name": "Goblet Squat", "sets": 3, "reps": "5", "notes": "Hip mobility and leg strength."},
      {"name": "One-Arm Swing", "sets": 5, "reps": "10 each", "notes": "Power and conditioning."},
      {"name": "Turkish Get-up", "sets": 3, "reps": "1 each", "notes": "Full body integration."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'minimalist', 'efficient', '15-minute', 'beginner'], 'sf_minimalist.md'),

-- StrongFirst SFG Prep
('5f1a0019-0001-4000-8000-000000000025', 'StrongFirst SFG Cert Prep', 'Training for SFG Level 1 certification. All six fundamental movements plus snatch test prep.', 'strength', 'advanced', 50, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Goblet Squat", "sets": 3, "reps": "5"},
      {"name": "Halo", "sets": 3, "reps": "5 each"},
      {"name": "Hip Bridge", "sets": 2, "reps": "10"}
    ]},
    {"name": "Six Fundamentals", "sequence": 1, "exercises": [
      {"name": "Swing", "sets": 5, "reps": "10 each", "notes": "Hardstyle one-arm swing."},
      {"name": "Goblet Squat", "sets": 3, "reps": "5", "notes": "Pry and pause at bottom."},
      {"name": "Clean", "sets": 3, "reps": "5 each", "notes": "Soft catch in rack."},
      {"name": "Press", "sets": 3, "reps": "5 each", "notes": "Strict military press."},
      {"name": "Snatch", "sets": 3, "reps": "5 each", "notes": "Tame the arc."},
      {"name": "Turkish Get-up", "sets": 3, "reps": "1 each", "notes": "Slow and controlled."}
    ]},
    {"name": "Snatch Test Practice", "sequence": 2, "exercises": [
      {"name": "Timed Snatch", "sets": 1, "reps": "50", "notes": "Half test. Build to full 100."}
    ]}
  ]
}', ARRAY['strongfirst', 'kettlebell', 'sfg', 'certification', 'prep', 'fundamentals'], 'sf_sfg_prep.md');

-- Verify insert
SELECT COUNT(*) as strongfirst_template_count FROM system_workout_templates WHERE 'strongfirst' = ANY(tags) OR 'kettlebell' = ANY(tags);
