-- Seed 25 ATG (Knees Over Toes) Workout Templates
-- Based on Ben Patrick's ATG Training methodology
-- Category: mobility/strength, Difficulty: varies

INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file) VALUES

-- ATG Zero (No Equipment)
('0a790001-0001-4000-8000-000000000001', 'ATG Zero - Day 1', 'Knee Ability Zero program Day 1. Bodyweight lower body exercises for knee health and mobility. No equipment needed.', 'mobility', 'beginner', 25, '{
  "blocks": [
    {"name": "Tibialis Work", "sequence": 0, "exercises": [
      {"name": "Wall Tibialis Raise", "sets": 3, "reps": "25", "notes": "Lean against wall, feet forward, raise toes toward shins."},
      {"name": "Toe Raises", "sets": 2, "reps": "20"}
    ]},
    {"name": "Calf & Ankle", "sequence": 1, "exercises": [
      {"name": "Single Leg Calf Raise", "sets": 2, "reps": "15 each", "notes": "Full range of motion, controlled."},
      {"name": "Ankle Circles", "sets": 2, "reps": "10 each direction"}
    ]},
    {"name": "Knee Strengthening", "sequence": 2, "exercises": [
      {"name": "Reverse Step-up", "sets": 3, "reps": "10 each", "notes": "Step backward off low step. Control the descent."},
      {"name": "Split Squat", "sets": 2, "reps": "10 each", "notes": "Back knee toward floor, front knee tracks over toes."}
    ]},
    {"name": "Hamstrings", "sequence": 3, "exercises": [
      {"name": "Assisted Nordic Curl", "sets": 3, "reps": "5", "notes": "Use hands on wall or band for assistance."}
    ]}
  ]
}', ARRAY['atg', 'knees-over-toes', 'bodyweight', 'knee-health', 'zero-equipment', 'beginner'], 'atg_zero_day1.md'),

-- ATG Zero - Day 2
('0a790001-0002-4000-8000-000000000002', 'ATG Zero - Day 2', 'Knee Ability Zero Day 2. Focus on hip mobility and backward walking patterns.', 'mobility', 'beginner', 25, '{
  "blocks": [
    {"name": "Tibialis", "sequence": 0, "exercises": [
      {"name": "Wall Tibialis Raise", "sets": 3, "reps": "25"},
      {"name": "Backward Walking", "duration": "5 min", "notes": "Walk backward with control. Toe-to-heel pattern."}
    ]},
    {"name": "Hip Mobility", "sequence": 1, "exercises": [
      {"name": "90/90 Hip Stretch", "sets": 2, "duration": "30 sec each"},
      {"name": "Couch Stretch", "sets": 2, "duration": "45 sec each", "notes": "Deep hip flexor stretch."}
    ]},
    {"name": "Squat Pattern", "sequence": 2, "exercises": [
      {"name": "ATG Split Squat", "sets": 3, "reps": "10 each", "notes": "Full depth, back knee to floor, front knee past toes."},
      {"name": "Bodyweight Squat", "sets": 2, "reps": "15", "notes": "Knees forward, heels down."}
    ]},
    {"name": "Balance", "sequence": 3, "exercises": [
      {"name": "Single Leg Balance", "sets": 2, "duration": "30 sec each"}
    ]}
  ]
}', ARRAY['atg', 'knees-over-toes', 'bodyweight', 'hip-mobility', 'backward-walking'], 'atg_zero_day2.md'),

-- ATG Zero - Day 3
('0a790001-0003-4000-8000-000000000003', 'ATG Zero - Day 3', 'Knee Ability Zero Day 3. Full lower body integration with emphasis on posterior chain.', 'mobility', 'beginner', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Backward Walking", "duration": "3 min"},
      {"name": "Wall Tibialis Raise", "sets": 2, "reps": "20"}
    ]},
    {"name": "Quad Dominant", "sequence": 1, "exercises": [
      {"name": "Patrick Step", "sets": 3, "reps": "10 each", "notes": "Step forward, allow knee to travel over toes."},
      {"name": "Poliquin Step-up", "sets": 2, "reps": "12 each", "notes": "Heel elevated, full knee bend."}
    ]},
    {"name": "Hip Hinge", "sequence": 2, "exercises": [
      {"name": "Romanian Deadlift (Bodyweight)", "sets": 3, "reps": "12"},
      {"name": "Single Leg RDL", "sets": 2, "reps": "8 each"}
    ]},
    {"name": "Hamstrings", "sequence": 3, "exercises": [
      {"name": "Nordic Curl Negative", "sets": 3, "reps": "5", "notes": "5-second eccentric, push back up with hands."},
      {"name": "Glute Bridge", "sets": 2, "reps": "15"}
    ]}
  ]
}', ARRAY['atg', 'knees-over-toes', 'bodyweight', 'posterior-chain', 'integration'], 'atg_zero_day3.md'),

-- ATG Dense - Tibialis Focus
('0a790002-0001-4000-8000-000000000004', 'ATG Dense - Tibialis Focus', 'High-density tibialis training session. Build bulletproof shins and deceleration strength.', 'strength', 'intermediate', 20, '{
  "blocks": [
    {"name": "Tib Bar Work", "sequence": 0, "exercises": [
      {"name": "Tib Bar Tibialis Raise", "sets": 5, "reps": "15-25", "notes": "Work toward 25% bodyweight for 5x25."},
      {"name": "Banded Tibialis Raise", "sets": 3, "reps": "20"}
    ]},
    {"name": "Ankle Strength", "sequence": 1, "exercises": [
      {"name": "Seated Calf Raise", "sets": 3, "reps": "15-20", "notes": "Soleus emphasis."},
      {"name": "Standing Calf Raise", "sets": 3, "reps": "12-15", "notes": "Gastrocnemius emphasis."}
    ]},
    {"name": "Integration", "sequence": 2, "exercises": [
      {"name": "Backward Sled Drag", "duration": "5 min", "notes": "Light weight, continuous movement."}
    ]}
  ]
}', ARRAY['atg', 'tibialis', 'shin-strength', 'deceleration', 'tib-bar'], 'atg_tibialis_focus.md'),

-- ATG Knee Ability Pro - Lower
('0a790003-0001-4000-8000-000000000005', 'ATG Pro - Full Lower Body', 'Complete ATG lower body session with equipment. Targets all knee stabilizers and hip mobility.', 'strength', 'intermediate', 45, '{
  "blocks": [
    {"name": "Tibialis & Calf", "sequence": 0, "exercises": [
      {"name": "Tib Bar Tibialis Raise", "sets": 2, "reps": "15-25"},
      {"name": "Single Leg Calf Raise", "sets": 2, "reps": "10-15 each"},
      {"name": "Seated Calf Raise", "sets": 2, "reps": "15-20"}
    ]},
    {"name": "Knee Dominant", "sequence": 1, "exercises": [
      {"name": "Reverse Step-up", "sets": 3, "reps": "10-20 each", "notes": "Slant board or elevated surface."},
      {"name": "ATG Split Squat", "sets": 3, "reps": "5-10 each", "notes": "Full depth, loaded if ready."}
    ]},
    {"name": "Squat", "sequence": 2, "exercises": [
      {"name": "ATG Squat", "sets": 3, "reps": "5-10", "notes": "Full depth, knees forward, heels elevated if needed."}
    ]},
    {"name": "Hamstrings", "sequence": 3, "exercises": [
      {"name": "Nordic Curl", "sets": 3, "reps": "3-8", "notes": "Use Nordic bench or partner."},
      {"name": "Seated Leg Curl", "sets": 2, "reps": "10-15"}
    ]}
  ]
}', ARRAY['atg', 'knees-over-toes', 'pro', 'equipment', 'full-lower'], 'atg_pro_lower.md'),

-- ATG Sled Session
('0a790004-0001-4000-8000-000000000006', 'ATG Sled Session', 'Ben Patrick signature sled workout. Forward and backward sled work for knee health and conditioning.', 'cardio', 'beginner', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Backward Walking", "duration": "3 min"}
    ]},
    {"name": "Sled Work", "sequence": 1, "exercises": [
      {"name": "Backward Sled Drag", "sets": 10, "distance": "50 yards", "notes": "Light to moderate weight. Stay on toes."},
      {"name": "Forward Sled Push", "sets": 10, "distance": "50 yards", "notes": "Drive through ground, full hip extension."}
    ]},
    {"name": "Tibialis Finisher", "sequence": 2, "exercises": [
      {"name": "Wall Tibialis Raise", "sets": 2, "reps": "20-30"}
    ]}
  ]
}', ARRAY['atg', 'sled', 'conditioning', 'low-impact', 'knee-friendly'], 'atg_sled_session.md'),

-- ATG Nordic Protocol
('0a790005-0001-4000-8000-000000000007', 'ATG Nordic Protocol', 'Progressive Nordic hamstring curl program. Build eccentric hamstring strength to bulletproof knees.', 'strength', 'intermediate', 25, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Leg Swings", "sets": 2, "reps": "10 each direction"},
      {"name": "Glute Bridges", "sets": 2, "reps": "15"}
    ]},
    {"name": "Nordic Progression", "sequence": 1, "exercises": [
      {"name": "Nordic Curl Eccentric", "sets": 4, "reps": "5", "notes": "5-sec lowering phase. Push back up with hands."},
      {"name": "Band-Assisted Nordic", "sets": 3, "reps": "5-8", "notes": "Loop band around chest for assistance."},
      {"name": "Full Nordic Curl", "sets": 2, "reps": "3-5", "notes": "If ready. Control the full ROM."}
    ]},
    {"name": "Accessory", "sequence": 2, "exercises": [
      {"name": "Seated Leg Curl", "sets": 3, "reps": "10-12"},
      {"name": "Romanian Deadlift", "sets": 2, "reps": "10"}
    ]}
  ]
}', ARRAY['atg', 'nordic', 'hamstrings', 'eccentric', 'acl-prevention'], 'atg_nordic_protocol.md'),

-- ATG Reverse Nordic Protocol
('0a790005-0002-4000-8000-000000000008', 'ATG Reverse Nordic Protocol', 'Quad-focused reverse Nordic progression. Stretch and strengthen the rectus femoris.', 'strength', 'intermediate', 25, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Couch Stretch", "sets": 2, "duration": "45 sec each"},
      {"name": "Wall Tibialis Raise", "sets": 2, "reps": "20"}
    ]},
    {"name": "Reverse Nordic", "sequence": 1, "exercises": [
      {"name": "Reverse Nordic Eccentric", "sets": 4, "reps": "5", "notes": "Lean back slowly, push up with hands."},
      {"name": "Band-Assisted Reverse Nordic", "sets": 3, "reps": "5-8"},
      {"name": "Full Reverse Nordic", "sets": 2, "reps": "3-5", "notes": "Full ROM if ready."}
    ]},
    {"name": "Accessory", "sequence": 2, "exercises": [
      {"name": "Sissy Squat", "sets": 2, "reps": "8-12"},
      {"name": "VMO Leg Extension", "sets": 2, "reps": "12-15", "notes": "Full knee extension focus."}
    ]}
  ]
}', ARRAY['atg', 'reverse-nordic', 'quad', 'rectus-femoris', 'flexibility'], 'atg_reverse_nordic.md'),

-- ATG Patrick Step Mastery
('0a790006-0001-4000-8000-000000000009', 'ATG Patrick Step Mastery', 'Progress the Patrick Step from bodyweight to loaded. Key exercise for knee-over-toe strength.', 'strength', 'intermediate', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Backward Walking", "duration": "3 min"},
      {"name": "Tibialis Raise", "sets": 2, "reps": "20"}
    ]},
    {"name": "Patrick Step Progression", "sequence": 1, "exercises": [
      {"name": "Bodyweight Patrick Step", "sets": 2, "reps": "10 each", "notes": "Master form before loading."},
      {"name": "Dumbbell Patrick Step", "sets": 3, "reps": "8 each", "notes": "Hold DBs at sides."},
      {"name": "Barbell Patrick Step", "sets": 3, "reps": "5 each", "notes": "Advanced: barbell in front rack or back."}
    ]},
    {"name": "Support Work", "sequence": 2, "exercises": [
      {"name": "Poliquin Step-up", "sets": 2, "reps": "12 each"},
      {"name": "ATG Split Squat", "sets": 2, "reps": "8 each"}
    ]}
  ]
}', ARRAY['atg', 'patrick-step', 'knee-strength', 'quad', 'progression'], 'atg_patrick_step.md'),

-- ATG Split Squat Mastery
('0a790006-0002-4000-8000-000000000010', 'ATG Split Squat Mastery', 'Master the ATG Split Squat from assisted to loaded. The king of knee strengthening exercises.', 'strength', 'intermediate', 35, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Couch Stretch", "sets": 2, "duration": "60 sec each"},
      {"name": "Hip Flexor Stretch", "sets": 2, "duration": "45 sec each"},
      {"name": "Tibialis Raise", "sets": 2, "reps": "15"}
    ]},
    {"name": "ATG Split Squat", "sequence": 1, "exercises": [
      {"name": "Assisted ATG Split Squat", "sets": 2, "reps": "10 each", "notes": "Hold TRX or rack for balance."},
      {"name": "Bodyweight ATG Split Squat", "sets": 3, "reps": "8 each", "notes": "Back knee to floor, front knee past toes."},
      {"name": "Loaded ATG Split Squat", "sets": 3, "reps": "5 each", "notes": "Hold DBs or KB. Progress slowly."}
    ]},
    {"name": "Accessory", "sequence": 2, "exercises": [
      {"name": "Step-up", "sets": 2, "reps": "10 each"},
      {"name": "Calf Raise", "sets": 2, "reps": "15"}
    ]}
  ]
}', ARRAY['atg', 'split-squat', 'knee-strength', 'hip-flexor', 'full-rom'], 'atg_split_squat_mastery.md'),

-- ATG Squat Progression
('0a790007-0001-4000-8000-000000000011', 'ATG Squat Progression', 'Build to full-depth ATG squats with heels elevated progression. Develop complete quad and knee strength.', 'strength', 'intermediate', 35, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Cat-Cow", "sets": 2, "reps": "10"},
      {"name": "Deep Squat Hold", "sets": 2, "duration": "30 sec"},
      {"name": "Tibialis Raise", "sets": 2, "reps": "20"}
    ]},
    {"name": "Squat Progression", "sequence": 1, "exercises": [
      {"name": "Goblet Squat", "sets": 2, "reps": "10", "notes": "Warmup with light weight."},
      {"name": "Heels Elevated Squat", "sets": 3, "reps": "8", "notes": "Use slant board or plates under heels."},
      {"name": "ATG Squat (Flat)", "sets": 3, "reps": "5-8", "notes": "Progress to flat ground when mobile enough."}
    ]},
    {"name": "Accessory", "sequence": 2, "exercises": [
      {"name": "Cyclist Squat", "sets": 2, "reps": "12", "notes": "Narrow stance, heels elevated, knees forward."},
      {"name": "Wall Sit", "sets": 2, "duration": "30-60 sec"}
    ]}
  ]
}', ARRAY['atg', 'squat', 'heels-elevated', 'quad', 'mobility'], 'atg_squat_progression.md'),

-- ATG Hip Mobility
('0a790008-0001-4000-8000-000000000012', 'ATG Hip Mobility', 'Deep hip mobility work using ATG principles. Open hips for better squat depth and athleticism.', 'mobility', 'beginner', 30, '{
  "blocks": [
    {"name": "Hip Openers", "sequence": 0, "exercises": [
      {"name": "90/90 Hip Stretch", "sets": 2, "duration": "60 sec each side"},
      {"name": "Pigeon Pose", "sets": 2, "duration": "60 sec each"},
      {"name": "Frog Stretch", "sets": 2, "duration": "60 sec"}
    ]},
    {"name": "Hip Flexor", "sequence": 1, "exercises": [
      {"name": "Couch Stretch", "sets": 2, "duration": "90 sec each", "notes": "Deep hip flexor and quad stretch."},
      {"name": "Half Kneeling Hip Flexor Stretch", "sets": 2, "duration": "45 sec each"}
    ]},
    {"name": "Active Mobility", "sequence": 2, "exercises": [
      {"name": "Deep Squat Hold", "sets": 3, "duration": "30 sec"},
      {"name": "Cossack Squat", "sets": 2, "reps": "8 each"},
      {"name": "Hip Circles", "sets": 2, "reps": "10 each direction"}
    ]}
  ]
}', ARRAY['atg', 'hip-mobility', 'flexibility', 'squat-depth', 'stretching'], 'atg_hip_mobility.md'),

-- ATG Back Ability - Lower Back
('0a790009-0001-4000-8000-000000000013', 'ATG Back Ability', 'Ben Patrick Back Ability program. Address lower back issues through targeted strengthening and mobility.', 'mobility', 'beginner', 30, '{
  "blocks": [
    {"name": "Spine Mobility", "sequence": 0, "exercises": [
      {"name": "Cat-Cow", "sets": 2, "reps": "10"},
      {"name": "Prone Press-up", "sets": 2, "reps": "10", "notes": "McKenzie extension."},
      {"name": "Child Pose", "sets": 2, "duration": "30 sec"}
    ]},
    {"name": "Hip Work", "sequence": 1, "exercises": [
      {"name": "Hip Flexor Stretch", "sets": 2, "duration": "60 sec each"},
      {"name": "Piriformis Stretch", "sets": 2, "duration": "45 sec each"},
      {"name": "Glute Bridges", "sets": 3, "reps": "15"}
    ]},
    {"name": "Core Stability", "sequence": 2, "exercises": [
      {"name": "Dead Bug", "sets": 3, "reps": "10 each side"},
      {"name": "Bird Dog", "sets": 3, "reps": "10 each side"},
      {"name": "Plank", "sets": 2, "duration": "30 sec"}
    ]},
    {"name": "Lower Chain", "sequence": 3, "exercises": [
      {"name": "Jefferson Curl", "sets": 2, "reps": "8", "notes": "Light weight, controlled spinal flexion."},
      {"name": "Back Extension", "sets": 2, "reps": "12"}
    ]}
  ]
}', ARRAY['atg', 'back-ability', 'lower-back', 'spine', 'core'], 'atg_back_ability.md'),

-- ATG Standards Test
('0a790010-0001-4000-8000-000000000014', 'ATG Standards Test', 'Test your ATG benchmarks. Tibialis, calf, nordic, and split squat standards to measure progress.', 'strength', 'intermediate', 40, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Backward Walking", "duration": "5 min"},
      {"name": "Dynamic Stretching", "duration": "3 min"}
    ]},
    {"name": "Tibialis Standard", "sequence": 1, "exercises": [
      {"name": "Tib Bar Tibialis Raise", "sets": 1, "reps": "Max", "notes": "Test: 25% bodyweight for 25 reps."}
    ]},
    {"name": "Calf Standard", "sequence": 2, "exercises": [
      {"name": "Single Leg Calf Raise", "sets": 1, "reps": "Max", "notes": "Test: 25% bodyweight added for 20 reps."}
    ]},
    {"name": "Nordic Standard", "sequence": 3, "exercises": [
      {"name": "Nordic Curl", "sets": 1, "reps": "Max", "notes": "Test: 25% bodyweight added for 5 reps."}
    ]},
    {"name": "Split Squat Standard", "sequence": 4, "exercises": [
      {"name": "ATG Split Squat", "sets": 1, "reps": "Max each", "notes": "Test: Bodyweight for 30 reps each leg."}
    ]},
    {"name": "Cooldown", "sequence": 5, "exercises": [
      {"name": "Static Stretching", "duration": "5 min"}
    ]}
  ]
}', ARRAY['atg', 'standards', 'benchmark', 'testing', 'assessment'], 'atg_standards_test.md'),

-- ATG Bulletproof Ankles
('0a790011-0001-4000-8000-000000000015', 'ATG Bulletproof Ankles', 'Complete ankle strengthening program. Build resilient ankles for better squat mobility and injury prevention.', 'mobility', 'beginner', 25, '{
  "blocks": [
    {"name": "Tibialis", "sequence": 0, "exercises": [
      {"name": "Tibialis Raise", "sets": 3, "reps": "20-25"},
      {"name": "Toe Walk", "duration": "2 min"}
    ]},
    {"name": "Calf Complex", "sequence": 1, "exercises": [
      {"name": "Bent Knee Calf Raise", "sets": 3, "reps": "15", "notes": "Soleus focus."},
      {"name": "Straight Leg Calf Raise", "sets": 3, "reps": "12", "notes": "Gastrocnemius focus."},
      {"name": "Single Leg Calf Raise", "sets": 2, "reps": "10 each"}
    ]},
    {"name": "Ankle Mobility", "sequence": 2, "exercises": [
      {"name": "Ankle Circles", "sets": 2, "reps": "10 each direction"},
      {"name": "Knee-to-Wall Ankle Stretch", "sets": 2, "duration": "45 sec each"},
      {"name": "Deep Squat Hold", "sets": 2, "duration": "30 sec"}
    ]},
    {"name": "Balance", "sequence": 3, "exercises": [
      {"name": "Single Leg Balance", "sets": 2, "duration": "30 sec each"},
      {"name": "BOSU Balance", "sets": 2, "duration": "30 sec each", "notes": "If available."}
    ]}
  ]
}', ARRAY['atg', 'ankle', 'calf', 'mobility', 'balance', 'injury-prevention'], 'atg_bulletproof_ankles.md'),

-- ATG Athlete Speed Day
('0a790012-0001-4000-8000-000000000016', 'ATG Athlete Speed Day', 'Speed and explosiveness using ATG principles. Sled work, plyometrics, and tibialis for athletic performance.', 'cardio', 'intermediate', 35, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Backward Walking", "duration": "3 min"},
      {"name": "A-Skips", "sets": 2, "distance": "20 yards"},
      {"name": "High Knees", "sets": 2, "distance": "20 yards"}
    ]},
    {"name": "Plyometrics", "sequence": 1, "exercises": [
      {"name": "Box Jumps", "sets": 4, "reps": "5"},
      {"name": "Broad Jumps", "sets": 4, "reps": "5"},
      {"name": "Depth Jumps", "sets": 3, "reps": "3", "notes": "Step off box, immediately jump max height."}
    ]},
    {"name": "Sled Work", "sequence": 2, "exercises": [
      {"name": "Sled Sprint", "sets": 6, "distance": "30 yards", "notes": "Light sled, max effort."},
      {"name": "Backward Sled Drag", "sets": 4, "distance": "30 yards"}
    ]},
    {"name": "Tibialis", "sequence": 3, "exercises": [
      {"name": "Tibialis Raise", "sets": 2, "reps": "25", "notes": "Deceleration strength."}
    ]}
  ]
}', ARRAY['atg', 'speed', 'plyometrics', 'athlete', 'explosiveness'], 'atg_athlete_speed.md'),

-- ATG Knee Rehab Gentle
('0a790013-0001-4000-8000-000000000017', 'ATG Knee Rehab - Gentle Start', 'Gentle introduction to ATG for those recovering from knee injury or surgery. Conservative progression.', 'mobility', 'beginner', 20, '{
  "blocks": [
    {"name": "Blood Flow", "sequence": 0, "exercises": [
      {"name": "Backward Walking", "duration": "5 min", "notes": "Very slow and controlled."},
      {"name": "Stationary Bike", "duration": "5 min", "notes": "Low resistance, easy spin."}
    ]},
    {"name": "Gentle Tibialis", "sequence": 1, "exercises": [
      {"name": "Seated Tibialis Raise", "sets": 3, "reps": "15", "notes": "No weight, just movement."},
      {"name": "Toe Taps", "sets": 2, "reps": "20"}
    ]},
    {"name": "ROM Work", "sequence": 2, "exercises": [
      {"name": "Heel Slides", "sets": 2, "reps": "15", "notes": "Lying on back, slide heel toward glute."},
      {"name": "Quad Sets", "sets": 3, "reps": "10", "notes": "Squeeze quad, push knee into floor."},
      {"name": "Straight Leg Raise", "sets": 2, "reps": "10"}
    ]},
    {"name": "Gentle Stretch", "sequence": 3, "exercises": [
      {"name": "Calf Stretch", "sets": 2, "duration": "30 sec each"},
      {"name": "Gentle Hip Flexor Stretch", "sets": 2, "duration": "30 sec each"}
    ]}
  ]
}', ARRAY['atg', 'rehab', 'gentle', 'knee-injury', 'recovery', 'conservative'], 'atg_knee_rehab_gentle.md'),

-- ATG Full Body Integration
('0a790014-0001-4000-8000-000000000018', 'ATG Full Body Integration', 'Full body workout integrating ATG lower body with pushing and pulling. Complete athletic development.', 'strength', 'intermediate', 50, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Backward Walking", "duration": "3 min"},
      {"name": "Band Pull Aparts", "sets": 2, "reps": "15"}
    ]},
    {"name": "Lower - ATG", "sequence": 1, "exercises": [
      {"name": "Tibialis Raise", "sets": 2, "reps": "20"},
      {"name": "ATG Split Squat", "sets": 3, "reps": "8 each"},
      {"name": "Nordic Curl", "sets": 3, "reps": "5"}
    ]},
    {"name": "Push", "sequence": 2, "exercises": [
      {"name": "Push-ups", "sets": 3, "reps": "10-15"},
      {"name": "Pike Push-ups", "sets": 2, "reps": "8-10"}
    ]},
    {"name": "Pull", "sequence": 3, "exercises": [
      {"name": "Pull-ups", "sets": 3, "reps": "5-10"},
      {"name": "Inverted Rows", "sets": 3, "reps": "10"}
    ]},
    {"name": "Core", "sequence": 4, "exercises": [
      {"name": "Dead Bug", "sets": 2, "reps": "10 each"},
      {"name": "Plank", "sets": 2, "duration": "30 sec"}
    ]}
  ]
}', ARRAY['atg', 'full-body', 'integration', 'push-pull', 'athletic'], 'atg_full_body_integration.md'),

-- ATG Ben Patrick 20-Min Workout
('0a790015-0001-4000-8000-000000000019', 'ATG Ben Patrick 20-Min', 'Ben Patrick signature 20-minute workout. Efficient full lower body session for busy schedules.', 'strength', 'intermediate', 20, '{
  "blocks": [
    {"name": "Sled", "sequence": 0, "exercises": [
      {"name": "Backward Sled Drag", "distance": "50 yards"},
      {"name": "Forward Sled Push", "distance": "50 yards"}
    ]},
    {"name": "Tibialis & Calf", "sequence": 1, "exercises": [
      {"name": "Tibialis Raise", "sets": 2, "reps": "15"},
      {"name": "Single Leg Calf Raise", "sets": 2, "reps": "10 each"},
      {"name": "Seated Calf Raise", "sets": 2, "reps": "15"}
    ]},
    {"name": "Main Lift", "sequence": 2, "exercises": [
      {"name": "ATG Squat", "sets": 10, "reps": "1", "notes": "10 singles with 10-second eccentric each rep."},
      {"name": "Reverse Slant Step-up", "sets": 3, "reps": "20"}
    ]},
    {"name": "Hamstring", "sequence": 3, "exercises": [
      {"name": "Nordic Curl Eccentric", "sets": 3, "reps": "5"}
    ]}
  ]
}', ARRAY['atg', 'ben-patrick', '20-minute', 'efficient', 'signature'], 'atg_ben_patrick_20min.md'),

-- ATG Poliquin Step Mastery
('0a790016-0001-4000-8000-000000000020', 'ATG Poliquin Step Mastery', 'Master the Poliquin Step-up named after legendary coach Charles Poliquin. VMO and quad development.', 'strength', 'intermediate', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Tibialis Raise", "sets": 2, "reps": "20"},
      {"name": "Calf Raise", "sets": 2, "reps": "15"}
    ]},
    {"name": "Poliquin Progression", "sequence": 1, "exercises": [
      {"name": "Bodyweight Poliquin Step-up", "sets": 2, "reps": "15 each", "notes": "Heel elevated, slow tempo."},
      {"name": "Dumbbell Poliquin Step-up", "sets": 3, "reps": "10 each", "notes": "Hold light DBs."},
      {"name": "Barbell Poliquin Step-up", "sets": 3, "reps": "8 each", "notes": "Advanced progression."}
    ]},
    {"name": "Accessory", "sequence": 2, "exercises": [
      {"name": "VMO Leg Extension", "sets": 2, "reps": "12-15"},
      {"name": "Terminal Knee Extension", "sets": 2, "reps": "15"}
    ]},
    {"name": "Stretch", "sequence": 3, "exercises": [
      {"name": "Quad Stretch", "sets": 2, "duration": "45 sec each"}
    ]}
  ]
}', ARRAY['atg', 'poliquin', 'step-up', 'vmo', 'quad', 'charles-poliquin'], 'atg_poliquin_step.md'),

-- ATG Cyclist Squat Focus
('0a790017-0001-4000-8000-000000000021', 'ATG Cyclist Squat Focus', 'Cyclist squat session for massive quad development. Narrow stance, heels elevated, knees forward.', 'strength', 'intermediate', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Tibialis Raise", "sets": 2, "reps": "20"},
      {"name": "Goblet Squat", "sets": 2, "reps": "10"}
    ]},
    {"name": "Cyclist Squat", "sequence": 1, "exercises": [
      {"name": "Bodyweight Cyclist Squat", "sets": 2, "reps": "15", "notes": "Heels on slant board, narrow stance."},
      {"name": "Goblet Cyclist Squat", "sets": 3, "reps": "10", "notes": "Hold KB at chest."},
      {"name": "Barbell Cyclist Squat", "sets": 4, "reps": "8", "notes": "Front rack or high bar position."}
    ]},
    {"name": "Accessory", "sequence": 2, "exercises": [
      {"name": "Sissy Squat", "sets": 2, "reps": "10"},
      {"name": "Leg Extension", "sets": 2, "reps": "12-15"}
    ]},
    {"name": "Stretch", "sequence": 3, "exercises": [
      {"name": "Couch Stretch", "sets": 2, "duration": "60 sec each"}
    ]}
  ]
}', ARRAY['atg', 'cyclist-squat', 'quad', 'heels-elevated', 'narrow-stance'], 'atg_cyclist_squat.md'),

-- ATG VMO Development
('0a790018-0001-4000-8000-000000000022', 'ATG VMO Development', 'Target the vastus medialis oblique (VMO) for knee stability and tracking. Key for patellar health.', 'strength', 'intermediate', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Tibialis Raise", "sets": 2, "reps": "20"},
      {"name": "Terminal Knee Extension", "sets": 2, "reps": "15"}
    ]},
    {"name": "VMO Work", "sequence": 1, "exercises": [
      {"name": "Poliquin Step-up", "sets": 3, "reps": "12 each", "notes": "Focus on full knee extension at top."},
      {"name": "Cyclist Squat", "sets": 3, "reps": "10"},
      {"name": "Peterson Step-up", "sets": 2, "reps": "12 each", "notes": "Single leg step-up, opposite leg stays down."}
    ]},
    {"name": "Isolation", "sequence": 2, "exercises": [
      {"name": "Leg Extension (Last 15 degrees)", "sets": 3, "reps": "15", "notes": "Focus on lockout portion only."},
      {"name": "Spanish Squat Hold", "sets": 2, "duration": "30 sec"}
    ]},
    {"name": "Stretch", "sequence": 3, "exercises": [
      {"name": "Quad Stretch", "sets": 2, "duration": "45 sec each"}
    ]}
  ]
}', ARRAY['atg', 'vmo', 'knee-stability', 'patellar', 'quad'], 'atg_vmo_development.md'),

-- ATG Jefferson Curl Mastery
('0a790019-0001-4000-8000-000000000023', 'ATG Jefferson Curl Mastery', 'Progressive Jefferson Curl program for spinal health. Build bulletproof back through controlled flexion.', 'mobility', 'intermediate', 25, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Cat-Cow", "sets": 2, "reps": "10"},
      {"name": "Toe Touch", "sets": 2, "reps": "10", "notes": "Gentle, no strain."}
    ]},
    {"name": "Jefferson Curl", "sequence": 1, "exercises": [
      {"name": "Bodyweight Jefferson Curl", "sets": 2, "reps": "10", "notes": "Stand on platform, curl down vertebra by vertebra."},
      {"name": "Light Jefferson Curl", "sets": 3, "reps": "8", "notes": "5-10 lbs. Very controlled."},
      {"name": "Moderate Jefferson Curl", "sets": 2, "reps": "5", "notes": "Progress slowly over weeks."}
    ]},
    {"name": "Support Work", "sequence": 2, "exercises": [
      {"name": "Romanian Deadlift", "sets": 2, "reps": "10"},
      {"name": "Back Extension", "sets": 2, "reps": "12"}
    ]},
    {"name": "Stretch", "sequence": 3, "exercises": [
      {"name": "Child Pose", "sets": 1, "duration": "60 sec"},
      {"name": "Seated Forward Fold", "sets": 1, "duration": "60 sec"}
    ]}
  ]
}', ARRAY['atg', 'jefferson-curl', 'spine', 'flexibility', 'back-health'], 'atg_jefferson_curl.md'),

-- ATG Sissy Squat Mastery
('0a790020-0001-4000-8000-000000000024', 'ATG Sissy Squat Mastery', 'Progress the sissy squat from assisted to full. Ultimate quad stretch and strength exercise.', 'strength', 'advanced', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Tibialis Raise", "sets": 2, "reps": "20"},
      {"name": "Couch Stretch", "sets": 2, "duration": "45 sec each"},
      {"name": "Cyclist Squat", "sets": 2, "reps": "10"}
    ]},
    {"name": "Sissy Squat Progression", "sequence": 1, "exercises": [
      {"name": "Band-Assisted Sissy Squat", "sets": 2, "reps": "10", "notes": "Hold band or rack for support."},
      {"name": "Sissy Squat Machine", "sets": 3, "reps": "8", "notes": "If available."},
      {"name": "Freestanding Sissy Squat", "sets": 3, "reps": "5-8", "notes": "Advanced. Control the descent."},
      {"name": "Weighted Sissy Squat", "sets": 2, "reps": "5", "notes": "Hold plate at chest."}
    ]},
    {"name": "Finisher", "sequence": 2, "exercises": [
      {"name": "Wall Sit", "sets": 2, "duration": "45 sec"},
      {"name": "Quad Stretch", "sets": 2, "duration": "60 sec each"}
    ]}
  ]
}', ARRAY['atg', 'sissy-squat', 'quad', 'advanced', 'flexibility'], 'atg_sissy_squat.md'),

-- ATG Pre-Game Activation
('0a790021-0001-4000-8000-000000000025', 'ATG Pre-Game Activation', 'Quick ATG activation routine before sports or training. Prime the body for explosive performance.', 'mobility', 'beginner', 15, '{
  "blocks": [
    {"name": "Blood Flow", "sequence": 0, "exercises": [
      {"name": "Backward Walking", "duration": "2 min"},
      {"name": "High Knees", "sets": 2, "distance": "20 yards"}
    ]},
    {"name": "Activation", "sequence": 1, "exercises": [
      {"name": "Wall Tibialis Raise", "sets": 2, "reps": "15"},
      {"name": "Bodyweight Split Squat", "sets": 1, "reps": "5 each"},
      {"name": "Glute Bridges", "sets": 1, "reps": "10"}
    ]},
    {"name": "Dynamic Prep", "sequence": 2, "exercises": [
      {"name": "Leg Swings", "sets": 1, "reps": "10 each direction"},
      {"name": "Walking Lunges", "sets": 1, "reps": "5 each"},
      {"name": "Squat Jumps", "sets": 2, "reps": "5"}
    ]}
  ]
}', ARRAY['atg', 'activation', 'pre-game', 'warmup', 'sports-prep'], 'atg_pregame_activation.md');

-- Verify insert
SELECT COUNT(*) as atg_template_count FROM system_workout_templates WHERE 'atg' = ANY(tags);
