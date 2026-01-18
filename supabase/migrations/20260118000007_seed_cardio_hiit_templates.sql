-- Cardio & HIIT Workout Templates
-- 25 high-intensity and cardio-focused workouts
-- Includes Tabata, EMOM, AMRAP, circuits, and metabolic conditioning

BEGIN;

-- 1. Classic Tabata
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000001',
    'Classic Tabata',
    '4-minute Tabata protocol: 20 seconds work, 10 seconds rest for 8 rounds. Complete 4 different exercises.',
    'cardio',
    'intermediate',
    20,
    '[{"id": "b1110001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1110001-0001-4000-8000-000000000001", "name": "Jumping Jacks", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Elevate heart rate"}, {"id": "c1110001-0001-4000-8000-000000000002", "name": "High Knees", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Pump arms"}, {"id": "c1110001-0001-4000-8000-000000000003", "name": "Arm Circles", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 sec each direction", "notes": "Shoulder warmup"}]}, {"id": "b1110001-0002-4000-8000-000000000001", "name": "Tabata 1 - Squats", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1110001-0002-4000-8000-000000000001", "name": "Air Squats", "sequence": 1, "prescribed_sets": 8, "prescribed_reps": "20 sec work / 10 sec rest", "notes": "Max reps each round, 4 min total"}]}, {"id": "b1110001-0003-4000-8000-000000000001", "name": "Tabata 2 - Push", "block_type": "functional", "sequence": 3, "exercises": [{"id": "c1110001-0003-4000-8000-000000000001", "name": "Push-Ups", "sequence": 1, "prescribed_sets": 8, "prescribed_reps": "20 sec work / 10 sec rest", "notes": "Modify to knees if needed"}]}, {"id": "b1110001-0004-4000-8000-000000000001", "name": "Tabata 3 - Core", "block_type": "functional", "sequence": 4, "exercises": [{"id": "c1110001-0004-4000-8000-000000000001", "name": "Mountain Climbers", "sequence": 1, "prescribed_sets": 8, "prescribed_reps": "20 sec work / 10 sec rest", "notes": "Fast feet, core tight"}]}, {"id": "b1110001-0005-4000-8000-000000000001", "name": "Tabata 4 - Cardio", "block_type": "functional", "sequence": 5, "exercises": [{"id": "c1110001-0005-4000-8000-000000000001", "name": "Burpees", "sequence": 1, "prescribed_sets": 8, "prescribed_reps": "20 sec work / 10 sec rest", "notes": "Full burpees with jump"}]}, {"id": "b1110001-0006-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 6, "exercises": [{"id": "c1110001-0006-4000-8000-000000000001", "name": "Walk in Place", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Lower heart rate gradually"}]}]'::jsonb,
    '{cardio,hiit,tabata,intermediate,bodyweight,conditioning,fat-burn}',
    'cardio_classic_tabata.md',
    NOW()
);

-- 2. 20-Minute EMOM
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000002',
    '20-Minute EMOM',
    'Every Minute on the Minute for 20 minutes. Complete prescribed reps, rest remainder of minute.',
    'cardio',
    'intermediate',
    25,
    '[{"id": "b1120001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1120001-0001-4000-8000-000000000001", "name": "Light Jog or Row", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Easy pace warmup"}, {"id": "c1120001-0001-4000-8000-000000000002", "name": "Dynamic Stretches", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Leg swings, arm circles"}]}, {"id": "b1120001-0002-4000-8000-000000000001", "name": "EMOM - 20 Minutes", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1120001-0002-4000-8000-000000000001", "name": "Minute 1: Kettlebell Swings", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "15 reps", "notes": "Hip drive, squeeze glutes"}, {"id": "c1120001-0002-4000-8000-000000000002", "name": "Minute 2: Box Jumps or Step-Ups", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "12 reps", "notes": "Land softly"}, {"id": "c1120001-0002-4000-8000-000000000003", "name": "Minute 3: Push-Ups", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "15 reps", "notes": "Chest to floor"}, {"id": "c1120001-0002-4000-8000-000000000004", "name": "Minute 4: Goblet Squats", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "12 reps", "notes": "Depth and control"}, {"id": "c1120001-0002-4000-8000-000000000005", "name": "Repeat 5 times", "sequence": 5, "prescribed_sets": 5, "prescribed_reps": "4 min cycles", "notes": "20 minutes total"}]}, {"id": "b1120001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1120001-0003-4000-8000-000000000001", "name": "Walk and Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Lower heart rate, stretch major muscles"}]}]'::jsonb,
    '{cardio,hiit,emom,intermediate,kettlebell,conditioning}',
    'cardio_20min_emom.md',
    NOW()
);

-- 3. Bodyweight AMRAP
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000003',
    'Bodyweight AMRAP',
    'As Many Rounds As Possible in 15 minutes. No equipment needed.',
    'cardio',
    'beginner',
    20,
    '[{"id": "b1130001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1130001-0001-4000-8000-000000000001", "name": "March in Place", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Lift knees high"}, {"id": "c1130001-0001-4000-8000-000000000002", "name": "Arm Swings", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Loosen shoulders"}, {"id": "c1130001-0001-4000-8000-000000000003", "name": "Bodyweight Squats", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Warmup legs"}]}, {"id": "b1130001-0002-4000-8000-000000000001", "name": "15-Min AMRAP", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1130001-0002-4000-8000-000000000001", "name": "Air Squats", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "15 reps", "notes": "Full depth"}, {"id": "c1130001-0002-4000-8000-000000000002", "name": "Push-Ups", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Modify as needed"}, {"id": "c1130001-0002-4000-8000-000000000003", "name": "Sit-Ups", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "15 reps", "notes": "Touch toes"}, {"id": "c1130001-0002-4000-8000-000000000004", "name": "Jumping Jacks", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "20 reps", "notes": "Full extension"}, {"id": "c1130001-0002-4000-8000-000000000005", "name": "Complete as many rounds as possible", "sequence": 5, "prescribed_sets": 1, "prescribed_reps": "15 min cap", "notes": "Track total rounds"}]}, {"id": "b1130001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1130001-0003-4000-8000-000000000001", "name": "Walk and Deep Breathing", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Recover heart rate"}]}]'::jsonb,
    '{cardio,hiit,amrap,beginner,bodyweight,no-equipment}',
    'cardio_bodyweight_amrap.md',
    NOW()
);

-- 4. Sprint Interval Training
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000004',
    'Sprint Interval Training',
    'High-intensity sprint intervals for maximum fat burn. Run, bike, or row.',
    'cardio',
    'advanced',
    25,
    '[{"id": "b1140001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1140001-0001-4000-8000-000000000001", "name": "Easy Jog/Bike/Row", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Gradually increase pace"}, {"id": "c1140001-0001-4000-8000-000000000002", "name": "Dynamic Leg Swings", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 each leg", "notes": "Front/back and side/side"}]}, {"id": "b1140001-0002-4000-8000-000000000001", "name": "Sprint Intervals", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1140001-0002-4000-8000-000000000001", "name": "Sprint", "sequence": 1, "prescribed_sets": 8, "prescribed_reps": "30 sec @ 90-95% effort", "notes": "All-out effort"}, {"id": "c1140001-0002-4000-8000-000000000002", "name": "Recovery", "sequence": 2, "prescribed_sets": 8, "prescribed_reps": "90 sec easy pace", "notes": "Active recovery, keep moving"}, {"id": "c1140001-0002-4000-8000-000000000003", "name": "Total: 8 rounds", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "16 min", "notes": "Modify sprint/rest ratio as needed"}]}, {"id": "b1140001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1140001-0003-4000-8000-000000000001", "name": "Easy Pace", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Bring heart rate down"}, {"id": "c1140001-0003-4000-8000-000000000002", "name": "Leg Stretches", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Quads, hamstrings, calves"}]}]'::jsonb,
    '{cardio,hiit,sprints,advanced,running,fat-burn,intervals}',
    'cardio_sprint_intervals.md',
    NOW()
);

-- 5. Metabolic Conditioning Circuit
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000005',
    'Metabolic Conditioning Circuit',
    '3 rounds of a 10-exercise metabolic circuit. Minimal rest between exercises.',
    'cardio',
    'intermediate',
    35,
    '[{"id": "b1150001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1150001-0001-4000-8000-000000000001", "name": "Jump Rope or Jumping Jacks", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Get heart rate up"}, {"id": "c1150001-0001-4000-8000-000000000002", "name": "World''s Greatest Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "5 each side", "notes": "Hip and thoracic mobility"}]}, {"id": "b1150001-0002-4000-8000-000000000001", "name": "MetCon Circuit - 3 Rounds", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1150001-0002-4000-8000-000000000001", "name": "Kettlebell Swings", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "15 reps", "notes": "Hip hinge power"}, {"id": "c1150001-0002-4000-8000-000000000002", "name": "Box Jumps", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "10 reps", "notes": "Step down to save knees"}, {"id": "c1150001-0002-4000-8000-000000000003", "name": "Dumbbell Thrusters", "sequence": 3, "prescribed_sets": 3, "prescribed_reps": "12 reps", "notes": "Squat to press"}, {"id": "c1150001-0002-4000-8000-000000000004", "name": "Burpees", "sequence": 4, "prescribed_sets": 3, "prescribed_reps": "8 reps", "notes": "Full burpee with jump"}, {"id": "c1150001-0002-4000-8000-000000000005", "name": "Battle Ropes", "sequence": 5, "prescribed_sets": 3, "prescribed_reps": "30 sec", "notes": "Alternating waves"}, {"id": "c1150001-0002-4000-8000-000000000006", "name": "Ball Slams", "sequence": 6, "prescribed_sets": 3, "prescribed_reps": "12 reps", "notes": "Full extension to slam"}, {"id": "c1150001-0002-4000-8000-000000000007", "name": "Mountain Climbers", "sequence": 7, "prescribed_sets": 3, "prescribed_reps": "30 sec", "notes": "Fast feet"}, {"id": "c1150001-0002-4000-8000-000000000008", "name": "Rowing Machine", "sequence": 8, "prescribed_sets": 3, "prescribed_reps": "250m or 60 sec", "notes": "Strong pulls"}, {"id": "c1150001-0002-4000-8000-000000000009", "name": "Plank Hold", "sequence": 9, "prescribed_sets": 3, "prescribed_reps": "45 sec", "notes": "Core tight"}, {"id": "c1150001-0002-4000-8000-000000000010", "name": "Rest Between Rounds", "sequence": 10, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Catch breath, hydrate"}]}, {"id": "b1150001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1150001-0003-4000-8000-000000000001", "name": "Walk and Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Full body stretches"}]}]'::jsonb,
    '{cardio,hiit,metcon,intermediate,circuit,conditioning,fat-burn}',
    'cardio_metcon_circuit.md',
    NOW()
);

-- 6. Jump Rope HIIT
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000006',
    'Jump Rope HIIT',
    'High-intensity jump rope workout with bodyweight exercises. Great for coordination and cardio.',
    'cardio',
    'intermediate',
    20,
    '[{"id": "b1160001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1160001-0001-4000-8000-000000000001", "name": "Easy Jump Rope", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Basic bounce, find rhythm"}, {"id": "c1160001-0001-4000-8000-000000000002", "name": "Wrist Circles", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Loosen wrists"}]}, {"id": "b1160001-0002-4000-8000-000000000001", "name": "Jump Rope Circuit - 4 Rounds", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1160001-0002-4000-8000-000000000001", "name": "Fast Jump Rope", "sequence": 1, "prescribed_sets": 4, "prescribed_reps": "60 sec", "notes": "Max speed"}, {"id": "c1160001-0002-4000-8000-000000000002", "name": "Push-Ups", "sequence": 2, "prescribed_sets": 4, "prescribed_reps": "10 reps", "notes": "Drop rope, quick set"}, {"id": "c1160001-0002-4000-8000-000000000003", "name": "Double Unders or High Knees", "sequence": 3, "prescribed_sets": 4, "prescribed_reps": "30 sec", "notes": "Double unders if skilled"}, {"id": "c1160001-0002-4000-8000-000000000004", "name": "Squat Jumps", "sequence": 4, "prescribed_sets": 4, "prescribed_reps": "10 reps", "notes": "Explosive"}, {"id": "c1160001-0002-4000-8000-000000000005", "name": "Rest", "sequence": 5, "prescribed_sets": 4, "prescribed_reps": "30 sec", "notes": "Quick recovery"}]}, {"id": "b1160001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1160001-0003-4000-8000-000000000001", "name": "Easy Jump Rope", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Slow pace"}, {"id": "c1160001-0003-4000-8000-000000000002", "name": "Calf Stretches", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Important after jumping"}]}]'::jsonb,
    '{cardio,hiit,jump-rope,intermediate,coordination,bodyweight}',
    'cardio_jump_rope_hiit.md',
    NOW()
);

-- 7. Rowing Intervals
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000007',
    'Rowing Intervals',
    'Interval-based rowing workout for full-body cardio conditioning.',
    'cardio',
    'intermediate',
    25,
    '[{"id": "b1170001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1170001-0001-4000-8000-000000000001", "name": "Easy Row", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min @ 18-20 SPM", "notes": "Focus on technique"}, {"id": "c1170001-0001-4000-8000-000000000002", "name": "Arm Only Strokes", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "1 min", "notes": "Arms only, legs straight"}, {"id": "c1170001-0001-4000-8000-000000000003", "name": "Arms + Back Strokes", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "1 min", "notes": "Add back swing"}]}, {"id": "b1170001-0002-4000-8000-000000000001", "name": "Rowing Intervals", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1170001-0002-4000-8000-000000000001", "name": "500m Row", "sequence": 1, "prescribed_sets": 4, "prescribed_reps": "Hard effort", "notes": "Target: under 2 min"}, {"id": "c1170001-0002-4000-8000-000000000002", "name": "Rest", "sequence": 2, "prescribed_sets": 4, "prescribed_reps": "90 sec", "notes": "Active recovery, stay on rower"}, {"id": "c1170001-0002-4000-8000-000000000003", "name": "250m Sprint", "sequence": 3, "prescribed_sets": 4, "prescribed_reps": "Max effort", "notes": "All out"}, {"id": "c1170001-0002-4000-8000-000000000004", "name": "Rest", "sequence": 4, "prescribed_sets": 4, "prescribed_reps": "60 sec", "notes": "Recover"}]}, {"id": "b1170001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1170001-0003-4000-8000-000000000001", "name": "Easy Row", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Bring heart rate down"}, {"id": "c1170001-0003-4000-8000-000000000002", "name": "Hamstring Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "On the rower or standing"}]}]'::jsonb,
    '{cardio,rowing,intervals,intermediate,full-body,rower}',
    'cardio_rowing_intervals.md',
    NOW()
);

-- 8. Plyometric Power
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000008',
    'Plyometric Power',
    'Explosive plyometric workout for power and athleticism. Jump training with cardio benefits.',
    'cardio',
    'advanced',
    30,
    '[{"id": "b1180001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1180001-0001-4000-8000-000000000001", "name": "Light Jog", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Easy pace"}, {"id": "c1180001-0001-4000-8000-000000000002", "name": "Leg Swings", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "15 each leg", "notes": "Front/back and lateral"}, {"id": "c1180001-0001-4000-8000-000000000003", "name": "Squat Jumps (Low)", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Half effort warmup"}]}, {"id": "b1180001-0002-4000-8000-000000000001", "name": "Plyometric Circuit - 3 Rounds", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1180001-0002-4000-8000-000000000001", "name": "Box Jumps", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "8 reps", "notes": "Land softly, step down"}, {"id": "c1180001-0002-4000-8000-000000000002", "name": "Broad Jumps", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "6 reps", "notes": "Max distance, stick landing"}, {"id": "c1180001-0002-4000-8000-000000000003", "name": "Lateral Bounds", "sequence": 3, "prescribed_sets": 3, "prescribed_reps": "10 each side", "notes": "Single leg landing"}, {"id": "c1180001-0002-4000-8000-000000000004", "name": "Tuck Jumps", "sequence": 4, "prescribed_sets": 3, "prescribed_reps": "8 reps", "notes": "Knees to chest"}, {"id": "c1180001-0002-4000-8000-000000000005", "name": "Depth Jumps", "sequence": 5, "prescribed_sets": 3, "prescribed_reps": "6 reps", "notes": "Step off box, immediate jump"}, {"id": "c1180001-0002-4000-8000-000000000006", "name": "Skater Jumps", "sequence": 6, "prescribed_sets": 3, "prescribed_reps": "12 total", "notes": "Side to side"}, {"id": "c1180001-0002-4000-8000-000000000007", "name": "Rest Between Rounds", "sequence": 7, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Full recovery for quality"}]}, {"id": "b1180001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1180001-0003-4000-8000-000000000001", "name": "Walk", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Lower heart rate"}, {"id": "c1180001-0003-4000-8000-000000000002", "name": "Leg Stretches", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Quads, hamstrings, calves, hip flexors"}]}]'::jsonb,
    '{cardio,hiit,plyometrics,advanced,power,athletic,jumping}',
    'cardio_plyometric_power.md',
    NOW()
);

-- 9. Bike HIIT
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000009',
    'Bike HIIT',
    'High-intensity cycling intervals. Use assault bike, spin bike, or outdoor cycling.',
    'cardio',
    'intermediate',
    25,
    '[{"id": "b1190001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1190001-0001-4000-8000-000000000001", "name": "Easy Cycling", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Light resistance, moderate cadence"}, {"id": "c1190001-0001-4000-8000-000000000002", "name": "Leg Spins", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "20 sec fast", "notes": "High cadence, low resistance"}]}, {"id": "b1190001-0002-4000-8000-000000000001", "name": "HIIT Intervals", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1190001-0002-4000-8000-000000000001", "name": "Sprint Interval", "sequence": 1, "prescribed_sets": 10, "prescribed_reps": "30 sec all-out", "notes": "Max effort, high resistance"}, {"id": "c1190001-0002-4000-8000-000000000002", "name": "Recovery", "sequence": 2, "prescribed_sets": 10, "prescribed_reps": "60 sec easy", "notes": "Keep pedaling, low resistance"}, {"id": "c1190001-0002-4000-8000-000000000003", "name": "Total Time", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "15 min", "notes": "10 rounds of 30/60"}]}, {"id": "b1190001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1190001-0003-4000-8000-000000000001", "name": "Easy Cycling", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Spin legs out"}, {"id": "c1190001-0003-4000-8000-000000000002", "name": "Quad and Hip Flexor Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Off the bike"}]}]'::jsonb,
    '{cardio,hiit,cycling,bike,intermediate,fat-burn,intervals}',
    'cardio_bike_hiit.md',
    NOW()
);

-- 10. Ladder Workout
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000010',
    'Ladder Workout',
    'Descending rep ladder from 10 to 1. Complete all reps of each exercise before moving to next rep count.',
    'cardio',
    'intermediate',
    25,
    '[{"id": "b1200001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1200001-0001-4000-8000-000000000001", "name": "Jumping Jacks", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Get moving"}, {"id": "c1200001-0001-4000-8000-000000000002", "name": "Inchworms", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "6 reps", "notes": "Warmup hamstrings and shoulders"}]}, {"id": "b1200001-0002-4000-8000-000000000001", "name": "Ladder 10-1", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1200001-0002-4000-8000-000000000001", "name": "Burpees", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10-9-8-7-6-5-4-3-2-1", "notes": "Start with 10, then 9, etc."}, {"id": "c1200001-0002-4000-8000-000000000002", "name": "Kettlebell Swings", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10-9-8-7-6-5-4-3-2-1", "notes": "Match burpee reps"}, {"id": "c1200001-0002-4000-8000-000000000003", "name": "Box Jumps", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10-9-8-7-6-5-4-3-2-1", "notes": "Step down each rep"}, {"id": "c1200001-0002-4000-8000-000000000004", "name": "Total Reps Each Exercise", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "55 reps", "notes": "165 total movements"}]}, {"id": "b1200001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1200001-0003-4000-8000-000000000001", "name": "Walk and Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Focus on recovery"}]}]'::jsonb,
    '{cardio,hiit,ladder,intermediate,conditioning,fat-burn}',
    'cardio_ladder_workout.md',
    NOW()
);

-- 11. 30-Minute Cardio Burn
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000011',
    '30-Minute Cardio Burn',
    'Sustained cardio workout alternating between different modalities. Keep heart rate elevated.',
    'cardio',
    'beginner',
    30,
    '[{"id": "b1210001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1210001-0001-4000-8000-000000000001", "name": "March in Place", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Gradual warmup"}, {"id": "c1210001-0001-4000-8000-000000000002", "name": "Arm Swings", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "1 min", "notes": "Loosen upper body"}]}, {"id": "b1210001-0002-4000-8000-000000000001", "name": "Cardio Blocks", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1210001-0002-4000-8000-000000000001", "name": "Block 1: Low Impact", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Step touches, marching, side steps"}, {"id": "c1210001-0002-4000-8000-000000000002", "name": "Block 2: Moderate", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Jumping jacks, high knees, butt kicks"}, {"id": "c1210001-0002-4000-8000-000000000003", "name": "Block 3: Active Recovery", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "March in place, slow movements"}, {"id": "c1210001-0002-4000-8000-000000000004", "name": "Block 4: Higher Intensity", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Squat jumps, skaters, fast feet"}, {"id": "c1210001-0002-4000-8000-000000000005", "name": "Block 5: Moderate", "sequence": 5, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Punches, kicks, lateral shuffles"}, {"id": "c1210001-0002-4000-8000-000000000006", "name": "Block 6: Finisher", "sequence": 6, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "All-out effort, your choice"}]}, {"id": "b1210001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1210001-0003-4000-8000-000000000001", "name": "Walk and Deep Breathing", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Slow down gradually"}]}]'::jsonb,
    '{cardio,beginner,low-impact,fat-burn,sustained,endurance}',
    'cardio_30min_burn.md',
    NOW()
);

-- 12. Death by Burpees
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000012',
    'Death by Burpees',
    'EMOM burpee challenge. Add 1 burpee each minute until you can''t complete the reps in time.',
    'cardio',
    'advanced',
    20,
    '[{"id": "b1220001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1220001-0001-4000-8000-000000000001", "name": "Jumping Jacks", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Elevate heart rate"}, {"id": "c1220001-0001-4000-8000-000000000002", "name": "Air Squats", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "15 reps", "notes": "Warm up legs"}, {"id": "c1220001-0001-4000-8000-000000000003", "name": "Push-Up to Down Dog", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Upper body prep"}, {"id": "c1220001-0001-4000-8000-000000000004", "name": "Practice Burpees", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "5 reps", "notes": "Get the movement down"}]}, {"id": "b1220001-0002-4000-8000-000000000001", "name": "Death by Burpees", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1220001-0002-4000-8000-000000000001", "name": "Minute 1", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "1 burpee", "notes": "Rest remainder"}, {"id": "c1220001-0002-4000-8000-000000000002", "name": "Minute 2", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 burpees", "notes": "Add 1 each minute"}, {"id": "c1220001-0002-4000-8000-000000000003", "name": "Continue Adding", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "Until failure", "notes": "Stop when you can''t complete reps in the minute"}, {"id": "c1220001-0002-4000-8000-000000000004", "name": "Target: 15+ minutes", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "120+ burpees", "notes": "Elite: 20 min = 210 burpees"}]}, {"id": "b1220001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1220001-0003-4000-8000-000000000001", "name": "Walk", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Recover heart rate"}, {"id": "c1220001-0003-4000-8000-000000000002", "name": "Child''s Pose", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Back recovery"}]}]'::jsonb,
    '{cardio,hiit,burpees,advanced,challenge,emom,conditioning}',
    'cardio_death_by_burpees.md',
    NOW()
);

-- 13. Cardio Kickboxing
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000013',
    'Cardio Kickboxing',
    'High-energy kickboxing-inspired cardio workout. Punch, kick, and move for a full-body burn.',
    'cardio',
    'intermediate',
    30,
    '[{"id": "b1230001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1230001-0001-4000-8000-000000000001", "name": "Jump Rope or Jog", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Light cardio"}, {"id": "c1230001-0001-4000-8000-000000000002", "name": "Arm Circles", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec each direction", "notes": "Shoulder mobility"}, {"id": "c1230001-0001-4000-8000-000000000003", "name": "Hip Circles", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 each direction", "notes": "Loosen hips for kicks"}]}, {"id": "b1230001-0002-4000-8000-000000000001", "name": "Combo 1", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1230001-0002-4000-8000-000000000001", "name": "Jab-Cross", "sequence": 1, "prescribed_sets": 4, "prescribed_reps": "30 sec", "notes": "Rotate hips, fast hands"}, {"id": "c1230001-0002-4000-8000-000000000002", "name": "Front Kicks", "sequence": 2, "prescribed_sets": 4, "prescribed_reps": "30 sec alternating", "notes": "Snap the kick"}, {"id": "c1230001-0002-4000-8000-000000000003", "name": "Squat + Hook", "sequence": 3, "prescribed_sets": 4, "prescribed_reps": "30 sec", "notes": "Squat, hook left, hook right"}]}, {"id": "b1230001-0003-4000-8000-000000000001", "name": "Combo 2", "block_type": "functional", "sequence": 3, "exercises": [{"id": "c1230001-0003-4000-8000-000000000001", "name": "Jab-Cross-Hook-Uppercut", "sequence": 1, "prescribed_sets": 4, "prescribed_reps": "30 sec", "notes": "Full combo"}, {"id": "c1230001-0003-4000-8000-000000000002", "name": "Roundhouse Kicks", "sequence": 2, "prescribed_sets": 4, "prescribed_reps": "30 sec alternating", "notes": "Pivot on standing foot"}, {"id": "c1230001-0003-4000-8000-000000000003", "name": "Bob and Weave", "sequence": 3, "prescribed_sets": 4, "prescribed_reps": "30 sec", "notes": "Duck side to side"}]}, {"id": "b1230001-0004-4000-8000-000000000001", "name": "Finisher", "block_type": "functional", "sequence": 4, "exercises": [{"id": "c1230001-0004-4000-8000-000000000001", "name": "Speed Bag Punches", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Fast circular punches"}, {"id": "c1230001-0004-4000-8000-000000000002", "name": "Burpees with Punch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Add 2 punches at top"}]}, {"id": "b1230001-0005-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 5, "exercises": [{"id": "c1230001-0005-4000-8000-000000000001", "name": "Shadow Boxing (Light)", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Easy pace"}, {"id": "c1230001-0005-4000-8000-000000000002", "name": "Stretching", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Shoulders, hips, quads"}]}]'::jsonb,
    '{cardio,kickboxing,martial-arts,intermediate,full-body,fun}',
    'cardio_kickboxing.md',
    NOW()
);

-- 14. Stair Climber HIIT
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000014',
    'Stair Climber HIIT',
    'Interval workout on the stair climber. Also works with actual stairs.',
    'cardio',
    'intermediate',
    25,
    '[{"id": "b1240001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1240001-0001-4000-8000-000000000001", "name": "Easy Climb", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Level 4-5, find rhythm"}, {"id": "c1240001-0001-4000-8000-000000000002", "name": "Leg Swings", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 each leg", "notes": "Off the machine"}]}, {"id": "b1240001-0002-4000-8000-000000000001", "name": "Stair Intervals", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1240001-0002-4000-8000-000000000001", "name": "Fast Climb", "sequence": 1, "prescribed_sets": 8, "prescribed_reps": "45 sec @ Level 10+", "notes": "High intensity"}, {"id": "c1240001-0002-4000-8000-000000000002", "name": "Recovery", "sequence": 2, "prescribed_sets": 8, "prescribed_reps": "45 sec @ Level 5", "notes": "Active recovery"}, {"id": "c1240001-0002-4000-8000-000000000003", "name": "Total Time", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "12 min", "notes": "8 intervals"}]}, {"id": "b1240001-0003-4000-8000-000000000001", "name": "Variations", "block_type": "functional", "sequence": 3, "exercises": [{"id": "c1240001-0003-4000-8000-000000000001", "name": "Skip Steps", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Every other step"}, {"id": "c1240001-0003-4000-8000-000000000002", "name": "Sideways Climb (Right)", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Face right, climb sideways"}, {"id": "c1240001-0003-4000-8000-000000000003", "name": "Sideways Climb (Left)", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Face left"}]}, {"id": "b1240001-0004-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c1240001-0004-4000-8000-000000000001", "name": "Easy Climb", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Lower intensity"}, {"id": "c1240001-0004-4000-8000-000000000002", "name": "Calf and Quad Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Off the machine"}]}]'::jsonb,
    '{cardio,hiit,stairs,intermediate,lower-body,glutes}',
    'cardio_stair_climber.md',
    NOW()
);

-- 15. Chipper Workout
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000015',
    'Chipper Workout',
    'Complete all reps of each exercise before moving to the next. Chip away at the work.',
    'cardio',
    'advanced',
    35,
    '[{"id": "b1250001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1250001-0001-4000-8000-000000000001", "name": "Row or Bike", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Easy pace"}, {"id": "c1250001-0001-4000-8000-000000000002", "name": "Dynamic Stretches", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Full body"}]}, {"id": "b1250001-0002-4000-8000-000000000001", "name": "The Chipper", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1250001-0002-4000-8000-000000000001", "name": "Calorie Row", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "50 calories", "notes": "Hard effort"}, {"id": "c1250001-0002-4000-8000-000000000002", "name": "Box Jumps", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "40 reps", "notes": "24/20 inch"}, {"id": "c1250001-0002-4000-8000-000000000003", "name": "Kettlebell Swings", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 reps", "notes": "53/35 lbs"}, {"id": "c1250001-0002-4000-8000-000000000004", "name": "Burpees", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "20 reps", "notes": "Chest to floor"}, {"id": "c1250001-0002-4000-8000-000000000005", "name": "Pull-Ups or Ring Rows", "sequence": 5, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Strict or kipping"}, {"id": "c1250001-0002-4000-8000-000000000006", "name": "Time Cap", "sequence": 6, "prescribed_sets": 1, "prescribed_reps": "25 min", "notes": "Record your time"}]}, {"id": "b1250001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1250001-0003-4000-8000-000000000001", "name": "Easy Row", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Flush lactic acid"}, {"id": "c1250001-0003-4000-8000-000000000002", "name": "Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Focus on worked muscles"}]}]'::jsonb,
    '{cardio,hiit,chipper,advanced,crossfit-style,conditioning}',
    'cardio_chipper.md',
    NOW()
);

-- 16. Treadmill Hill Sprints
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000016',
    'Treadmill Hill Sprints',
    'Incline interval training on the treadmill. Build power and burn calories.',
    'cardio',
    'intermediate',
    25,
    '[{"id": "b1260001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1260001-0001-4000-8000-000000000001", "name": "Walk @ 0% Incline", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min @ 3.5 mph", "notes": "Easy warmup"}, {"id": "c1260001-0001-4000-8000-000000000002", "name": "Jog @ 2% Incline", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min @ 5.0 mph", "notes": "Increase pace"}, {"id": "c1260001-0001-4000-8000-000000000003", "name": "Run @ 4% Incline", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "1 min @ 6.0 mph", "notes": "Build up"}]}, {"id": "b1260001-0002-4000-8000-000000000001", "name": "Hill Intervals", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1260001-0002-4000-8000-000000000001", "name": "Hill Sprint", "sequence": 1, "prescribed_sets": 8, "prescribed_reps": "30 sec @ 10% incline, 7.0+ mph", "notes": "All-out effort"}, {"id": "c1260001-0002-4000-8000-000000000002", "name": "Recovery Walk", "sequence": 2, "prescribed_sets": 8, "prescribed_reps": "60 sec @ 0% incline, 3.0 mph", "notes": "Catch your breath"}, {"id": "c1260001-0002-4000-8000-000000000003", "name": "Total", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "12 min", "notes": "8 hill sprints"}]}, {"id": "b1260001-0003-4000-8000-000000000001", "name": "Finisher", "block_type": "functional", "sequence": 3, "exercises": [{"id": "c1260001-0003-4000-8000-000000000001", "name": "Incline Walk", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min @ 15% incline, 3.5 mph", "notes": "Glute burner"}]}, {"id": "b1260001-0004-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c1260001-0004-4000-8000-000000000001", "name": "Easy Walk", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min @ 0% incline", "notes": "Recover"}, {"id": "c1260001-0004-4000-8000-000000000002", "name": "Calf Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each leg", "notes": "Important after incline work"}]}]'::jsonb,
    '{cardio,hiit,treadmill,intermediate,running,hills,fat-burn}',
    'cardio_treadmill_hills.md',
    NOW()
);

-- 17. Partner HIIT
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000017',
    'Partner HIIT',
    'You-go-I-go partner workout. One works while the other rests.',
    'cardio',
    'intermediate',
    30,
    '[{"id": "b1270001-0001-4000-8000-000000000001", "name": "Warmup Together", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1270001-0001-4000-8000-000000000001", "name": "High Knees", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Both partners"}, {"id": "c1270001-0001-4000-8000-000000000002", "name": "Butt Kicks", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Warm up legs"}, {"id": "c1270001-0001-4000-8000-000000000003", "name": "Arm Circles", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 sec each direction", "notes": "Shoulder warmup"}]}, {"id": "b1270001-0002-4000-8000-000000000001", "name": "Partner Circuit - 3 Rounds", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1270001-0002-4000-8000-000000000001", "name": "Partner A: Row 250m", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "While B does wall sit", "notes": "Switch when A finishes"}, {"id": "c1270001-0002-4000-8000-000000000002", "name": "Partner A: Burpees x 10", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "While B does plank", "notes": "Switch when A finishes"}, {"id": "c1270001-0002-4000-8000-000000000003", "name": "Partner A: KB Swings x 20", "sequence": 3, "prescribed_sets": 3, "prescribed_reps": "While B does dead hang", "notes": "Switch when A finishes"}, {"id": "c1270001-0002-4000-8000-000000000004", "name": "Partner A: Box Jumps x 15", "sequence": 4, "prescribed_sets": 3, "prescribed_reps": "While B does squat hold", "notes": "Switch when A finishes"}, {"id": "c1270001-0002-4000-8000-000000000005", "name": "Rest Between Rounds", "sequence": 5, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Recover together"}]}, {"id": "b1270001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1270001-0003-4000-8000-000000000001", "name": "Partner Stretching", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Assist each other with stretches"}]}]'::jsonb,
    '{cardio,hiit,partner,intermediate,teamwork,fun,social}',
    'cardio_partner_hiit.md',
    NOW()
);

-- 18. Core HIIT
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000018',
    'Core HIIT',
    'High-intensity core workout. Build abs while burning calories.',
    'cardio',
    'intermediate',
    20,
    '[{"id": "b1280001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1280001-0001-4000-8000-000000000001", "name": "Jumping Jacks", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Elevate heart rate"}, {"id": "c1280001-0001-4000-8000-000000000002", "name": "Cat-Cow", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Warm up spine"}]}, {"id": "b1280001-0002-4000-8000-000000000001", "name": "Core HIIT Circuit - 3 Rounds", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1280001-0002-4000-8000-000000000001", "name": "Mountain Climbers", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "30 sec", "notes": "Fast and controlled"}, {"id": "c1280001-0002-4000-8000-000000000002", "name": "Rest", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "10 sec", "notes": "Quick transition"}, {"id": "c1280001-0002-4000-8000-000000000003", "name": "Bicycle Crunches", "sequence": 3, "prescribed_sets": 3, "prescribed_reps": "30 sec", "notes": "Touch elbow to knee"}, {"id": "c1280001-0002-4000-8000-000000000004", "name": "Rest", "sequence": 4, "prescribed_sets": 3, "prescribed_reps": "10 sec", "notes": "Quick transition"}, {"id": "c1280001-0002-4000-8000-000000000005", "name": "Plank Jacks", "sequence": 5, "prescribed_sets": 3, "prescribed_reps": "30 sec", "notes": "Jump feet wide and back"}, {"id": "c1280001-0002-4000-8000-000000000006", "name": "Rest", "sequence": 6, "prescribed_sets": 3, "prescribed_reps": "10 sec", "notes": "Quick transition"}, {"id": "c1280001-0002-4000-8000-000000000007", "name": "V-Ups", "sequence": 7, "prescribed_sets": 3, "prescribed_reps": "30 sec", "notes": "Touch toes"}, {"id": "c1280001-0002-4000-8000-000000000008", "name": "Rest", "sequence": 8, "prescribed_sets": 3, "prescribed_reps": "10 sec", "notes": "Quick transition"}, {"id": "c1280001-0002-4000-8000-000000000009", "name": "Burpees", "sequence": 9, "prescribed_sets": 3, "prescribed_reps": "30 sec", "notes": "Full body with core"}, {"id": "c1280001-0002-4000-8000-000000000010", "name": "Rest Between Rounds", "sequence": 10, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Recover"}]}, {"id": "b1280001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1280001-0003-4000-8000-000000000001", "name": "Child''s Pose", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Stretch lower back"}, {"id": "c1280001-0003-4000-8000-000000000002", "name": "Supine Twist", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Release spine"}]}]'::jsonb,
    '{cardio,hiit,core,intermediate,abs,conditioning}',
    'cardio_core_hiit.md',
    NOW()
);

-- 19. 5K Prep Intervals
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000019',
    '5K Prep Intervals',
    'Interval training designed to improve your 5K time. Run faster, longer.',
    'cardio',
    'intermediate',
    35,
    '[{"id": "b1290001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1290001-0001-4000-8000-000000000001", "name": "Easy Jog", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Conversational pace"}, {"id": "c1290001-0001-4000-8000-000000000002", "name": "Dynamic Stretches", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Leg swings, high knees, butt kicks"}, {"id": "c1290001-0001-4000-8000-000000000003", "name": "Strides", "sequence": 3, "prescribed_sets": 4, "prescribed_reps": "20 sec each", "notes": "Gradually accelerate to near-sprint, decelerate"}]}, {"id": "b1290001-0002-4000-8000-000000000001", "name": "Interval Set", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1290001-0002-4000-8000-000000000001", "name": "800m Repeats", "sequence": 1, "prescribed_sets": 4, "prescribed_reps": "@ 5K pace or faster", "notes": "Target: 10-15 sec faster than race pace"}, {"id": "c1290001-0002-4000-8000-000000000002", "name": "Recovery Jog", "sequence": 2, "prescribed_sets": 4, "prescribed_reps": "400m easy", "notes": "Between each 800m"}, {"id": "c1290001-0002-4000-8000-000000000003", "name": "Total Distance", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "~3 miles of intervals", "notes": "Adjust based on fitness"}]}, {"id": "b1290001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1290001-0003-4000-8000-000000000001", "name": "Easy Jog", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Very slow pace"}, {"id": "c1290001-0003-4000-8000-000000000002", "name": "Walk", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Lower heart rate"}, {"id": "c1290001-0003-4000-8000-000000000003", "name": "Static Stretches", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Calves, quads, hamstrings, hip flexors"}]}]'::jsonb,
    '{cardio,running,5k,intermediate,intervals,race-prep}',
    'cardio_5k_intervals.md',
    NOW()
);

-- 20. Battle Ropes HIIT
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000020',
    'Battle Ropes HIIT',
    'High-intensity battle rope workout. Upper body and cardio in one session.',
    'cardio',
    'intermediate',
    20,
    '[{"id": "b1300001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1300001-0001-4000-8000-000000000001", "name": "Jump Rope or Jog", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Get blood flowing"}, {"id": "c1300001-0001-4000-8000-000000000002", "name": "Arm Circles", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec each direction", "notes": "Loosen shoulders"}, {"id": "c1300001-0001-4000-8000-000000000003", "name": "Practice Waves", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Light warm-up waves"}]}, {"id": "b1300001-0002-4000-8000-000000000001", "name": "Battle Rope Circuit - 4 Rounds", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1300001-0002-4000-8000-000000000001", "name": "Alternating Waves", "sequence": 1, "prescribed_sets": 4, "prescribed_reps": "30 sec", "notes": "Fast alternating"}, {"id": "c1300001-0002-4000-8000-000000000002", "name": "Rest", "sequence": 2, "prescribed_sets": 4, "prescribed_reps": "15 sec", "notes": "Quick recovery"}, {"id": "c1300001-0002-4000-8000-000000000003", "name": "Double Waves (Slams)", "sequence": 3, "prescribed_sets": 4, "prescribed_reps": "30 sec", "notes": "Both arms together, slam down"}, {"id": "c1300001-0002-4000-8000-000000000004", "name": "Rest", "sequence": 4, "prescribed_sets": 4, "prescribed_reps": "15 sec", "notes": "Quick recovery"}, {"id": "c1300001-0002-4000-8000-000000000005", "name": "Circles", "sequence": 5, "prescribed_sets": 4, "prescribed_reps": "30 sec (15 each direction)", "notes": "Outward circles, then inward"}, {"id": "c1300001-0002-4000-8000-000000000006", "name": "Rest", "sequence": 6, "prescribed_sets": 4, "prescribed_reps": "15 sec", "notes": "Quick recovery"}, {"id": "c1300001-0002-4000-8000-000000000007", "name": "Snakes", "sequence": 7, "prescribed_sets": 4, "prescribed_reps": "30 sec", "notes": "Move arms side to side"}, {"id": "c1300001-0002-4000-8000-000000000008", "name": "Rest Between Rounds", "sequence": 8, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Recover"}]}, {"id": "b1300001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1300001-0003-4000-8000-000000000001", "name": "Shoulder Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each arm", "notes": "Cross-body and overhead"}, {"id": "c1300001-0003-4000-8000-000000000002", "name": "Lat Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Side bend with reach"}]}]'::jsonb,
    '{cardio,hiit,battle-ropes,intermediate,upper-body,conditioning}',
    'cardio_battle_ropes.md',
    NOW()
);

-- 21. Pyramid HIIT
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000021',
    'Pyramid HIIT',
    'Work intervals increase then decrease in a pyramid format. 10-20-30-40-30-20-10 seconds.',
    'cardio',
    'intermediate',
    25,
    '[{"id": "b1310001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1310001-0001-4000-8000-000000000001", "name": "March in Place", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Gradual warmup"}, {"id": "c1310001-0001-4000-8000-000000000002", "name": "Arm Swings", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Loosen shoulders"}, {"id": "c1310001-0001-4000-8000-000000000003", "name": "Bodyweight Squats", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Warm up legs"}]}, {"id": "b1310001-0002-4000-8000-000000000001", "name": "Pyramid - Exercise 1: Burpees", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1310001-0002-4000-8000-000000000001", "name": "10 sec work / 10 sec rest", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "Level 1", "notes": "Max effort"}, {"id": "c1310001-0002-4000-8000-000000000002", "name": "20 sec work / 10 sec rest", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "Level 2", "notes": "Max effort"}, {"id": "c1310001-0002-4000-8000-000000000003", "name": "30 sec work / 10 sec rest", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "Level 3", "notes": "Max effort"}, {"id": "c1310001-0002-4000-8000-000000000004", "name": "40 sec work / 10 sec rest", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "Peak", "notes": "Max effort"}, {"id": "c1310001-0002-4000-8000-000000000005", "name": "30-20-10 back down", "sequence": 5, "prescribed_sets": 1, "prescribed_reps": "Descend", "notes": "Complete the pyramid"}]}, {"id": "b1310001-0003-4000-8000-000000000001", "name": "Pyramid - Exercise 2: Mountain Climbers", "block_type": "functional", "sequence": 3, "exercises": [{"id": "c1310001-0003-4000-8000-000000000001", "name": "Same 10-20-30-40-30-20-10 pattern", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "Full pyramid", "notes": "10 sec rest between each"}]}, {"id": "b1310001-0004-4000-8000-000000000001", "name": "Pyramid - Exercise 3: Squat Jumps", "block_type": "functional", "sequence": 4, "exercises": [{"id": "c1310001-0004-4000-8000-000000000001", "name": "Same pattern", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "Full pyramid", "notes": "Land softly"}]}, {"id": "b1310001-0005-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 5, "exercises": [{"id": "c1310001-0005-4000-8000-000000000001", "name": "Walk and Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Full body recovery"}]}]'::jsonb,
    '{cardio,hiit,pyramid,intermediate,bodyweight,conditioning}',
    'cardio_pyramid_hiit.md',
    NOW()
);

-- 22. Low Impact HIIT
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000022',
    'Low Impact HIIT',
    'High-intensity cardio without jumping. Joint-friendly but still challenging.',
    'cardio',
    'beginner',
    25,
    '[{"id": "b1320001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1320001-0001-4000-8000-000000000001", "name": "March in Place", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Lift knees high"}, {"id": "c1320001-0001-4000-8000-000000000002", "name": "Arm Circles", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec each direction", "notes": "Big circles"}]}, {"id": "b1320001-0002-4000-8000-000000000001", "name": "Low Impact Circuit - 3 Rounds", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1320001-0002-4000-8000-000000000001", "name": "Fast March", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "45 sec", "notes": "Pump arms, high knees, no jump"}, {"id": "c1320001-0002-4000-8000-000000000002", "name": "Rest", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "15 sec", "notes": "Quick recovery"}, {"id": "c1320001-0002-4000-8000-000000000003", "name": "Step-Out Squats", "sequence": 3, "prescribed_sets": 3, "prescribed_reps": "45 sec", "notes": "Step wide, squat, step together"}, {"id": "c1320001-0002-4000-8000-000000000004", "name": "Rest", "sequence": 4, "prescribed_sets": 3, "prescribed_reps": "15 sec", "notes": "Quick recovery"}, {"id": "c1320001-0002-4000-8000-000000000005", "name": "Standing Mountain Climbers", "sequence": 5, "prescribed_sets": 3, "prescribed_reps": "45 sec", "notes": "Drive knees up alternating, stay standing"}, {"id": "c1320001-0002-4000-8000-000000000006", "name": "Rest", "sequence": 6, "prescribed_sets": 3, "prescribed_reps": "15 sec", "notes": "Quick recovery"}, {"id": "c1320001-0002-4000-8000-000000000007", "name": "Reverse Lunges with Reach", "sequence": 7, "prescribed_sets": 3, "prescribed_reps": "45 sec", "notes": "Step back, reach arms up"}, {"id": "c1320001-0002-4000-8000-000000000008", "name": "Rest", "sequence": 8, "prescribed_sets": 3, "prescribed_reps": "15 sec", "notes": "Quick recovery"}, {"id": "c1320001-0002-4000-8000-000000000009", "name": "Boxer Shuffle", "sequence": 9, "prescribed_sets": 3, "prescribed_reps": "45 sec", "notes": "Fast feet, stay light"}, {"id": "c1320001-0002-4000-8000-000000000010", "name": "Rest Between Rounds", "sequence": 10, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Recover"}]}, {"id": "b1320001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1320001-0003-4000-8000-000000000001", "name": "Slow March", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Lower heart rate"}, {"id": "c1320001-0003-4000-8000-000000000002", "name": "Standing Stretches", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Quads, hamstrings, calves"}]}]'::jsonb,
    '{cardio,hiit,low-impact,beginner,joint-friendly,no-jumping}',
    'cardio_low_impact_hiit.md',
    NOW()
);

-- 23. Assault Bike Destroyer
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000023',
    'Assault Bike Destroyer',
    'Brutal assault bike workout. Short but intense calorie-burning session.',
    'cardio',
    'advanced',
    20,
    '[{"id": "b1330001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1330001-0001-4000-8000-000000000001", "name": "Easy Bike", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min @ 50-60 RPM", "notes": "Light resistance"}, {"id": "c1330001-0001-4000-8000-000000000002", "name": "Building Sprints", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "15 sec build", "notes": "Increase intensity each one"}]}, {"id": "b1330001-0002-4000-8000-000000000001", "name": "Assault Bike Intervals", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1330001-0002-4000-8000-000000000001", "name": "Max Effort Sprint", "sequence": 1, "prescribed_sets": 5, "prescribed_reps": "20 sec @ 100%", "notes": "All out, nothing left"}, {"id": "c1330001-0002-4000-8000-000000000002", "name": "Recovery", "sequence": 2, "prescribed_sets": 5, "prescribed_reps": "40 sec easy", "notes": "Keep pedaling slowly"}, {"id": "c1330001-0002-4000-8000-000000000003", "name": "Total Time", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "5 rounds of 20/40"}]}, {"id": "b1330001-0003-4000-8000-000000000001", "name": "Calorie Challenge", "block_type": "functional", "sequence": 3, "exercises": [{"id": "c1330001-0003-4000-8000-000000000001", "name": "50 Calorie Sprint", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "For time", "notes": "All out until 50 cals"}, {"id": "c1330001-0003-4000-8000-000000000002", "name": "Rest", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Full recovery"}, {"id": "c1330001-0003-4000-8000-000000000003", "name": "30 Calorie Sprint", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "For time", "notes": "All out again"}]}, {"id": "b1330001-0004-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c1330001-0004-4000-8000-000000000001", "name": "Easy Pedal", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Spin out the legs"}, {"id": "c1330001-0004-4000-8000-000000000002", "name": "Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Quads, hip flexors"}]}]'::jsonb,
    '{cardio,hiit,assault-bike,advanced,brutal,calorie-burn}',
    'cardio_assault_bike.md',
    NOW()
);

-- 24. Quick 10-Minute Blast
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000024',
    'Quick 10-Minute Blast',
    'No excuses - just 10 minutes of maximum effort. Perfect when time is short.',
    'cardio',
    'intermediate',
    10,
    '[{"id": "b1340001-0001-4000-8000-000000000001", "name": "Quick Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1340001-0001-4000-8000-000000000001", "name": "Jumping Jacks", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Fast pace"}, {"id": "c1340001-0001-4000-8000-000000000002", "name": "High Knees", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Get heart rate up quick"}]}, {"id": "b1340001-0002-4000-8000-000000000001", "name": "10-Minute AMRAP", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1340001-0002-4000-8000-000000000001", "name": "Burpees", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 reps", "notes": "Full burpee"}, {"id": "c1340001-0002-4000-8000-000000000002", "name": "Air Squats", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Full depth"}, {"id": "c1340001-0002-4000-8000-000000000003", "name": "Push-Ups", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Chest to floor"}, {"id": "c1340001-0002-4000-8000-000000000004", "name": "Mountain Climbers", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "20 reps (10 each leg)", "notes": "Fast pace"}, {"id": "c1340001-0002-4000-8000-000000000005", "name": "Repeat for 10 minutes", "sequence": 5, "prescribed_sets": 1, "prescribed_reps": "Max rounds", "notes": "Track your score"}]}, {"id": "b1340001-0003-4000-8000-000000000001", "name": "Quick Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1340001-0003-4000-8000-000000000001", "name": "Walk in Place", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Catch your breath"}]}]'::jsonb,
    '{cardio,hiit,quick,intermediate,10-minute,no-equipment,time-efficient}',
    'cardio_10min_blast.md',
    NOW()
);

-- 25. Fartlek Run
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'ca4d10f1-0001-4000-8000-000000000025',
    'Fartlek Run',
    'Swedish "speed play" running workout. Unstructured intervals based on how you feel.',
    'cardio',
    'intermediate',
    35,
    '[{"id": "b1350001-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1350001-0001-4000-8000-000000000001", "name": "Easy Jog", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Conversational pace"}, {"id": "c1350001-0001-4000-8000-000000000002", "name": "Dynamic Stretches", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Leg swings, high knees"}]}, {"id": "b1350001-0002-4000-8000-000000000001", "name": "Fartlek Session", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c1350001-0002-4000-8000-000000000001", "name": "Moderate Run", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2-3 min", "notes": "Comfortable but purposeful"}, {"id": "c1350001-0002-4000-8000-000000000002", "name": "Fast Surge", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30-90 sec", "notes": "Pick up pace significantly"}, {"id": "c1350001-0002-4000-8000-000000000003", "name": "Recovery Jog", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "1-2 min", "notes": "Easy pace, recover"}, {"id": "c1350001-0002-4000-8000-000000000004", "name": "Sprint to Landmark", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "Pick a target", "notes": "Sprint to tree, sign, etc."}, {"id": "c1350001-0002-4000-8000-000000000005", "name": "Continue Pattern", "sequence": 5, "prescribed_sets": 1, "prescribed_reps": "20 min total", "notes": "Vary efforts based on feel"}, {"id": "c1350001-0002-4000-8000-000000000006", "name": "Suggested Surges", "sequence": 6, "prescribed_sets": 1, "prescribed_reps": "6-10 total", "notes": "Mix of 30 sec to 3 min efforts"}]}, {"id": "b1350001-0003-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1350001-0003-4000-8000-000000000001", "name": "Easy Jog", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Very slow pace"}, {"id": "c1350001-0003-4000-8000-000000000002", "name": "Walk", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Lower heart rate"}, {"id": "c1350001-0003-4000-8000-000000000003", "name": "Stretching", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Focus on calves, quads, hip flexors"}]}]'::jsonb,
    '{cardio,running,fartlek,intermediate,outdoor,speed-play}',
    'cardio_fartlek_run.md',
    NOW()
);

COMMIT;
