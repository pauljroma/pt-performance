-- Seed Bodybuilding workout templates (25 templates)
-- Focus: Hypertrophy, muscle splits, pump training

INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file) VALUES

-- PUSH/PULL/LEGS (6)
('00b00001-0001-4000-8000-000000000001', 'PPL Push Day', 'Push day - chest, shoulders, triceps focus', 'strength', 'intermediate', 75,
'{"blocks": [{"name": "Chest", "sequence": 0, "exercises": [{"name": "Barbell Bench Press", "sets": 4, "reps": "8-10"}, {"name": "Incline Dumbbell Press", "sets": 3, "reps": "10-12"}, {"name": "Cable Fly", "sets": 3, "reps": "12-15"}]}, {"name": "Shoulders", "sequence": 1, "exercises": [{"name": "Overhead Press", "sets": 4, "reps": "8-10"}, {"name": "Lateral Raise", "sets": 4, "reps": "12-15"}]}, {"name": "Triceps", "sequence": 2, "exercises": [{"name": "Tricep Pushdown", "sets": 3, "reps": "10-12"}, {"name": "Overhead Tricep Extension", "sets": 3, "reps": "12-15"}]}]}'::jsonb,
ARRAY['bodybuilding', 'push', 'ppl', 'hypertrophy'], 'bodybuilding_ppl_push.md'),

('00b00001-0002-4000-8000-000000000002', 'PPL Pull Day', 'Pull day - back and biceps focus', 'strength', 'intermediate', 75,
'{"blocks": [{"name": "Back Width", "sequence": 0, "exercises": [{"name": "Pull-Up", "sets": 4, "reps": "8-10"}, {"name": "Lat Pulldown", "sets": 3, "reps": "10-12"}]}, {"name": "Back Thickness", "sequence": 1, "exercises": [{"name": "Barbell Row", "sets": 4, "reps": "8-10"}, {"name": "Seated Cable Row", "sets": 3, "reps": "10-12"}, {"name": "Face Pull", "sets": 3, "reps": "15-20"}]}, {"name": "Biceps", "sequence": 2, "exercises": [{"name": "Barbell Curl", "sets": 3, "reps": "10-12"}, {"name": "Incline Dumbbell Curl", "sets": 3, "reps": "12-15"}, {"name": "Hammer Curl", "sets": 3, "reps": "12"}]}]}'::jsonb,
ARRAY['bodybuilding', 'pull', 'ppl', 'hypertrophy'], 'bodybuilding_ppl_pull.md'),

('00b00001-0003-4000-8000-000000000003', 'PPL Legs Day', 'Leg day - quads, hamstrings, calves', 'strength', 'intermediate', 80,
'{"blocks": [{"name": "Quads", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 4, "reps": "8-10"}, {"name": "Leg Press", "sets": 4, "reps": "10-12"}, {"name": "Leg Extension", "sets": 3, "reps": "12-15"}]}, {"name": "Hamstrings", "sequence": 1, "exercises": [{"name": "Romanian Deadlift", "sets": 4, "reps": "10-12"}, {"name": "Lying Leg Curl", "sets": 4, "reps": "10-12"}]}, {"name": "Calves", "sequence": 2, "exercises": [{"name": "Standing Calf Raise", "sets": 4, "reps": "12-15"}, {"name": "Seated Calf Raise", "sets": 3, "reps": "15-20"}]}]}'::jsonb,
ARRAY['bodybuilding', 'legs', 'ppl', 'hypertrophy'], 'bodybuilding_ppl_legs.md'),

('00b00001-0004-4000-8000-000000000004', 'PPL Push Day (Volume)', 'High volume push day for advanced', 'strength', 'advanced', 90,
'{"blocks": [{"name": "Chest", "sequence": 0, "exercises": [{"name": "Incline Barbell Press", "sets": 4, "reps": "6-8"}, {"name": "Flat Dumbbell Press", "sets": 4, "reps": "8-10"}, {"name": "Cable Crossover", "sets": 4, "reps": "12-15"}, {"name": "Machine Chest Press", "sets": 3, "reps": "12-15"}]}, {"name": "Shoulders", "sequence": 1, "exercises": [{"name": "Seated Dumbbell Press", "sets": 4, "reps": "8-10"}, {"name": "Cable Lateral Raise", "sets": 4, "reps": "15"}, {"name": "Rear Delt Fly", "sets": 4, "reps": "15"}]}, {"name": "Triceps", "sequence": 2, "exercises": [{"name": "Close Grip Bench", "sets": 3, "reps": "8-10"}, {"name": "Rope Pushdown", "sets": 3, "reps": "12-15"}, {"name": "Skull Crusher", "sets": 3, "reps": "12"}]}]}'::jsonb,
ARRAY['bodybuilding', 'push', 'ppl', 'volume', 'advanced'], 'bodybuilding_ppl_push_vol.md'),

('00b00001-0005-4000-8000-000000000005', 'PPL Pull Day (Volume)', 'High volume pull day for advanced', 'strength', 'advanced', 90,
'{"blocks": [{"name": "Back", "sequence": 0, "exercises": [{"name": "Weighted Pull-Up", "sets": 4, "reps": "6-8"}, {"name": "Pendlay Row", "sets": 4, "reps": "6-8"}, {"name": "Single Arm Dumbbell Row", "sets": 3, "reps": "10-12"}, {"name": "Wide Grip Lat Pulldown", "sets": 3, "reps": "10-12"}, {"name": "Cable Row", "sets": 3, "reps": "12-15"}]}, {"name": "Rear Delts", "sequence": 1, "exercises": [{"name": "Face Pull", "sets": 4, "reps": "15-20"}, {"name": "Reverse Pec Deck", "sets": 3, "reps": "15"}]}, {"name": "Biceps", "sequence": 2, "exercises": [{"name": "EZ Bar Curl", "sets": 4, "reps": "8-10"}, {"name": "Preacher Curl", "sets": 3, "reps": "10-12"}, {"name": "Cable Curl", "sets": 3, "reps": "15"}]}]}'::jsonb,
ARRAY['bodybuilding', 'pull', 'ppl', 'volume', 'advanced'], 'bodybuilding_ppl_pull_vol.md'),

('00b00001-0006-4000-8000-000000000006', 'PPL Legs Day (Volume)', 'High volume leg day for advanced', 'strength', 'advanced', 90,
'{"blocks": [{"name": "Quads", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 4, "reps": "6-8"}, {"name": "Hack Squat", "sets": 4, "reps": "8-10"}, {"name": "Walking Lunge", "sets": 3, "reps": "12 each"}, {"name": "Leg Extension", "sets": 4, "reps": "12-15"}]}, {"name": "Hamstrings", "sequence": 1, "exercises": [{"name": "Romanian Deadlift", "sets": 4, "reps": "8-10"}, {"name": "Seated Leg Curl", "sets": 4, "reps": "10-12"}, {"name": "Good Morning", "sets": 3, "reps": "12"}]}, {"name": "Calves", "sequence": 2, "exercises": [{"name": "Standing Calf Raise", "sets": 5, "reps": "10-12"}, {"name": "Seated Calf Raise", "sets": 4, "reps": "15-20"}]}]}'::jsonb,
ARRAY['bodybuilding', 'legs', 'ppl', 'volume', 'advanced'], 'bodybuilding_ppl_legs_vol.md'),

-- UPPER/LOWER SPLIT (4)
('00b00001-0007-4000-8000-000000000007', 'Upper Body A (Strength)', 'Upper body strength focus', 'strength', 'intermediate', 70,
'{"blocks": [{"name": "Horizontal Push", "sequence": 0, "exercises": [{"name": "Barbell Bench Press", "sets": 4, "reps": "5-6"}]}, {"name": "Horizontal Pull", "sequence": 1, "exercises": [{"name": "Barbell Row", "sets": 4, "reps": "5-6"}]}, {"name": "Vertical Push", "sequence": 2, "exercises": [{"name": "Overhead Press", "sets": 3, "reps": "6-8"}]}, {"name": "Vertical Pull", "sequence": 3, "exercises": [{"name": "Weighted Pull-Up", "sets": 3, "reps": "6-8"}]}, {"name": "Arms", "sequence": 4, "exercises": [{"name": "Barbell Curl", "sets": 3, "reps": "8-10"}, {"name": "Skull Crusher", "sets": 3, "reps": "8-10"}]}]}'::jsonb,
ARRAY['bodybuilding', 'upper', 'upper-lower', 'strength'], 'bodybuilding_upper_a.md'),

('00b00001-0008-4000-8000-000000000008', 'Upper Body B (Hypertrophy)', 'Upper body hypertrophy focus', 'strength', 'intermediate', 75,
'{"blocks": [{"name": "Chest", "sequence": 0, "exercises": [{"name": "Incline Dumbbell Press", "sets": 4, "reps": "10-12"}, {"name": "Cable Fly", "sets": 3, "reps": "12-15"}]}, {"name": "Back", "sequence": 1, "exercises": [{"name": "Lat Pulldown", "sets": 4, "reps": "10-12"}, {"name": "Seated Cable Row", "sets": 3, "reps": "12-15"}]}, {"name": "Shoulders", "sequence": 2, "exercises": [{"name": "Lateral Raise", "sets": 4, "reps": "12-15"}, {"name": "Face Pull", "sets": 3, "reps": "15-20"}]}, {"name": "Arms", "sequence": 3, "exercises": [{"name": "Incline Dumbbell Curl", "sets": 3, "reps": "12-15"}, {"name": "Rope Pushdown", "sets": 3, "reps": "12-15"}]}]}'::jsonb,
ARRAY['bodybuilding', 'upper', 'upper-lower', 'hypertrophy'], 'bodybuilding_upper_b.md'),

('00b00001-0009-4000-8000-000000000009', 'Lower Body A (Strength)', 'Lower body strength focus - quad dominant', 'strength', 'intermediate', 70,
'{"blocks": [{"name": "Main Lift", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 4, "reps": "5-6"}]}, {"name": "Secondary", "sequence": 1, "exercises": [{"name": "Romanian Deadlift", "sets": 4, "reps": "6-8"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Leg Press", "sets": 3, "reps": "8-10"}, {"name": "Leg Curl", "sets": 3, "reps": "10-12"}, {"name": "Calf Raise", "sets": 4, "reps": "12-15"}]}]}'::jsonb,
ARRAY['bodybuilding', 'lower', 'upper-lower', 'strength'], 'bodybuilding_lower_a.md'),

('00b00001-0010-4000-8000-000000000010', 'Lower Body B (Hypertrophy)', 'Lower body hypertrophy focus - posterior dominant', 'strength', 'intermediate', 75,
'{"blocks": [{"name": "Main Lift", "sequence": 0, "exercises": [{"name": "Deadlift", "sets": 4, "reps": "5-6"}]}, {"name": "Quads", "sequence": 1, "exercises": [{"name": "Bulgarian Split Squat", "sets": 3, "reps": "10-12"}, {"name": "Leg Extension", "sets": 3, "reps": "12-15"}]}, {"name": "Hamstrings", "sequence": 2, "exercises": [{"name": "Lying Leg Curl", "sets": 4, "reps": "10-12"}, {"name": "Glute Ham Raise", "sets": 3, "reps": "8-10"}]}, {"name": "Calves", "sequence": 3, "exercises": [{"name": "Seated Calf Raise", "sets": 4, "reps": "15-20"}]}]}'::jsonb,
ARRAY['bodybuilding', 'lower', 'upper-lower', 'hypertrophy'], 'bodybuilding_lower_b.md'),

-- BRO SPLIT (5)
('00b00001-0011-4000-8000-000000000011', 'Chest Day', 'Classic bro split chest workout', 'strength', 'intermediate', 60,
'{"blocks": [{"name": "Compound", "sequence": 0, "exercises": [{"name": "Barbell Bench Press", "sets": 4, "reps": "6-8"}, {"name": "Incline Dumbbell Press", "sets": 4, "reps": "8-10"}]}, {"name": "Isolation", "sequence": 1, "exercises": [{"name": "Dumbbell Fly", "sets": 3, "reps": "10-12"}, {"name": "Cable Crossover", "sets": 3, "reps": "12-15"}, {"name": "Pec Deck", "sets": 3, "reps": "12-15"}]}]}'::jsonb,
ARRAY['bodybuilding', 'chest', 'bro-split'], 'bodybuilding_chest_day.md'),

('00b00001-0012-4000-8000-000000000012', 'Back Day', 'Classic bro split back workout', 'strength', 'intermediate', 65,
'{"blocks": [{"name": "Width", "sequence": 0, "exercises": [{"name": "Pull-Up", "sets": 4, "reps": "8-10"}, {"name": "Wide Grip Lat Pulldown", "sets": 3, "reps": "10-12"}]}, {"name": "Thickness", "sequence": 1, "exercises": [{"name": "Barbell Row", "sets": 4, "reps": "8-10"}, {"name": "T-Bar Row", "sets": 3, "reps": "10-12"}, {"name": "Seated Cable Row", "sets": 3, "reps": "12-15"}]}, {"name": "Lower Back", "sequence": 2, "exercises": [{"name": "Back Extension", "sets": 3, "reps": "12-15"}]}]}'::jsonb,
ARRAY['bodybuilding', 'back', 'bro-split'], 'bodybuilding_back_day.md'),

('00b00001-0013-4000-8000-000000000013', 'Shoulder Day', 'Classic bro split shoulder workout', 'strength', 'intermediate', 55,
'{"blocks": [{"name": "Compound", "sequence": 0, "exercises": [{"name": "Overhead Press", "sets": 4, "reps": "6-8"}, {"name": "Seated Dumbbell Press", "sets": 3, "reps": "8-10"}]}, {"name": "Isolation", "sequence": 1, "exercises": [{"name": "Lateral Raise", "sets": 4, "reps": "12-15"}, {"name": "Front Raise", "sets": 3, "reps": "12-15"}, {"name": "Rear Delt Fly", "sets": 4, "reps": "12-15"}, {"name": "Face Pull", "sets": 3, "reps": "15-20"}]}]}'::jsonb,
ARRAY['bodybuilding', 'shoulders', 'bro-split'], 'bodybuilding_shoulder_day.md'),

('00b00001-0014-4000-8000-000000000014', 'Arm Day', 'Classic bro split arm workout', 'strength', 'intermediate', 55,
'{"blocks": [{"name": "Biceps", "sequence": 0, "exercises": [{"name": "Barbell Curl", "sets": 4, "reps": "8-10"}, {"name": "Incline Dumbbell Curl", "sets": 3, "reps": "10-12"}, {"name": "Preacher Curl", "sets": 3, "reps": "10-12"}, {"name": "Hammer Curl", "sets": 3, "reps": "12-15"}]}, {"name": "Triceps", "sequence": 1, "exercises": [{"name": "Close Grip Bench", "sets": 4, "reps": "8-10"}, {"name": "Skull Crusher", "sets": 3, "reps": "10-12"}, {"name": "Tricep Pushdown", "sets": 3, "reps": "12-15"}, {"name": "Overhead Extension", "sets": 3, "reps": "12-15"}]}]}'::jsonb,
ARRAY['bodybuilding', 'arms', 'bro-split'], 'bodybuilding_arm_day.md'),

('00b00001-0015-4000-8000-000000000015', 'Leg Day (Bro Split)', 'Classic bro split leg workout', 'strength', 'intermediate', 70,
'{"blocks": [{"name": "Quads", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 4, "reps": "6-8"}, {"name": "Leg Press", "sets": 4, "reps": "10-12"}, {"name": "Leg Extension", "sets": 3, "reps": "12-15"}]}, {"name": "Hamstrings", "sequence": 1, "exercises": [{"name": "Romanian Deadlift", "sets": 4, "reps": "8-10"}, {"name": "Lying Leg Curl", "sets": 4, "reps": "10-12"}]}, {"name": "Calves", "sequence": 2, "exercises": [{"name": "Standing Calf Raise", "sets": 5, "reps": "12-15"}, {"name": "Seated Calf Raise", "sets": 4, "reps": "15-20"}]}]}'::jsonb,
ARRAY['bodybuilding', 'legs', 'bro-split'], 'bodybuilding_leg_day.md'),

-- SPECIALTY WORKOUTS (10)
('00b00001-0016-4000-8000-000000000016', 'Chest & Back Superset', 'Arnold-style opposing muscle groups', 'strength', 'intermediate', 60,
'{"blocks": [{"name": "Superset 1", "sequence": 0, "exercises": [{"name": "Bench Press", "sets": 4, "reps": "8-10", "notes": "Superset with Pull-Up"}, {"name": "Pull-Up", "sets": 4, "reps": "8-10"}]}, {"name": "Superset 2", "sequence": 1, "exercises": [{"name": "Incline Dumbbell Press", "sets": 3, "reps": "10-12", "notes": "Superset with Dumbbell Row"}, {"name": "Single Arm Dumbbell Row", "sets": 3, "reps": "10-12"}]}, {"name": "Superset 3", "sequence": 2, "exercises": [{"name": "Cable Fly", "sets": 3, "reps": "12-15", "notes": "Superset with Lat Pulldown"}, {"name": "Lat Pulldown", "sets": 3, "reps": "12-15"}]}]}'::jsonb,
ARRAY['bodybuilding', 'superset', 'chest', 'back'], 'bodybuilding_chest_back_ss.md'),

('00b00001-0017-4000-8000-000000000017', 'Arms Supersets', 'Biceps/triceps superset workout', 'strength', 'intermediate', 50,
'{"blocks": [{"name": "Superset 1", "sequence": 0, "exercises": [{"name": "Barbell Curl", "sets": 4, "reps": "10", "notes": "Superset with Skull Crusher"}, {"name": "Skull Crusher", "sets": 4, "reps": "10"}]}, {"name": "Superset 2", "sequence": 1, "exercises": [{"name": "Hammer Curl", "sets": 3, "reps": "12", "notes": "Superset with Rope Pushdown"}, {"name": "Rope Pushdown", "sets": 3, "reps": "12"}]}, {"name": "Superset 3", "sequence": 2, "exercises": [{"name": "Concentration Curl", "sets": 3, "reps": "12", "notes": "Superset with Overhead Extension"}, {"name": "Overhead Tricep Extension", "sets": 3, "reps": "12"}]}]}'::jsonb,
ARRAY['bodybuilding', 'superset', 'arms'], 'bodybuilding_arms_ss.md'),

('00b00001-0018-4000-8000-000000000018', 'Giant Set Chest', 'High intensity chest giant sets', 'strength', 'advanced', 45,
'{"blocks": [{"name": "Giant Set A", "sequence": 0, "exercises": [{"name": "Incline Dumbbell Press", "sets": 3, "reps": "10", "notes": "No rest between exercises"}, {"name": "Flat Dumbbell Press", "sets": 3, "reps": "10"}, {"name": "Decline Push-Up", "sets": 3, "reps": "15"}, {"name": "Cable Crossover", "sets": 3, "reps": "15"}]}, {"name": "Giant Set B", "sequence": 1, "exercises": [{"name": "Machine Chest Press", "sets": 3, "reps": "12"}, {"name": "Pec Deck", "sets": 3, "reps": "12"}, {"name": "Push-Up", "sets": 3, "reps": "to failure"}]}]}'::jsonb,
ARRAY['bodybuilding', 'giant-set', 'chest', 'advanced'], 'bodybuilding_giant_chest.md'),

('00b00001-0019-4000-8000-000000000019', 'FST-7 Back', 'Fascia stretch training for back', 'strength', 'advanced', 65,
'{"blocks": [{"name": "Compound Work", "sequence": 0, "exercises": [{"name": "Barbell Row", "sets": 4, "reps": "8-10"}, {"name": "Pull-Up", "sets": 4, "reps": "8-10"}, {"name": "T-Bar Row", "sets": 3, "reps": "10-12"}]}, {"name": "FST-7 Finisher", "sequence": 1, "exercises": [{"name": "Lat Pulldown", "sets": 7, "reps": "10-12", "notes": "30-45 sec rest, squeeze and stretch"}]}]}'::jsonb,
ARRAY['bodybuilding', 'fst-7', 'back', 'advanced'], 'bodybuilding_fst7_back.md'),

('00b00001-0020-4000-8000-000000000020', 'Drop Set Delts', 'Mechanical drop set shoulder workout', 'strength', 'advanced', 50,
'{"blocks": [{"name": "Compound", "sequence": 0, "exercises": [{"name": "Seated Dumbbell Press", "sets": 4, "reps": "8-10"}]}, {"name": "Drop Sets", "sequence": 1, "exercises": [{"name": "Lateral Raise", "sets": 4, "reps": "10+10+10", "notes": "Triple drop set"}, {"name": "Front Raise", "sets": 3, "reps": "10+10+10", "notes": "Triple drop set"}, {"name": "Rear Delt Fly", "sets": 3, "reps": "12+12+12", "notes": "Triple drop set"}]}]}'::jsonb,
ARRAY['bodybuilding', 'drop-set', 'shoulders', 'advanced'], 'bodybuilding_drop_delts.md'),

('00b00001-0021-4000-8000-000000000021', 'Blood Flow Restriction Arms', 'BFR training for arms', 'strength', 'intermediate', 40,
'{"blocks": [{"name": "Biceps BFR", "sequence": 0, "exercises": [{"name": "Barbell Curl", "sets": 4, "reps": "30/15/15/15", "notes": "BFR bands, 30 sec rest"}]}, {"name": "Triceps BFR", "sequence": 1, "exercises": [{"name": "Tricep Pushdown", "sets": 4, "reps": "30/15/15/15", "notes": "BFR bands, 30 sec rest"}]}, {"name": "Superset BFR", "sequence": 2, "exercises": [{"name": "Hammer Curl", "sets": 3, "reps": "20", "notes": "Superset with Overhead Extension"}, {"name": "Overhead Extension", "sets": 3, "reps": "20"}]}]}'::jsonb,
ARRAY['bodybuilding', 'bfr', 'arms'], 'bodybuilding_bfr_arms.md'),

('00b00001-0022-4000-8000-000000000022', 'Rest-Pause Chest', 'Rest-pause training for chest', 'strength', 'advanced', 45,
'{"blocks": [{"name": "Rest-Pause Sets", "sequence": 0, "exercises": [{"name": "Incline Barbell Press", "sets": 3, "reps": "8+4+4", "notes": "Rest-pause: 15 sec rest between mini-sets"}, {"name": "Flat Dumbbell Press", "sets": 3, "reps": "10+5+5", "notes": "Rest-pause"}]}, {"name": "Finisher", "sequence": 1, "exercises": [{"name": "Cable Fly", "sets": 3, "reps": "15"}, {"name": "Push-Up", "sets": 2, "reps": "to failure"}]}]}'::jsonb,
ARRAY['bodybuilding', 'rest-pause', 'chest', 'advanced'], 'bodybuilding_rp_chest.md'),

('00b00001-0023-4000-8000-000000000023', 'Full Body Pump', 'Quick full body hypertrophy session', 'full_body', 'intermediate', 60,
'{"blocks": [{"name": "Chest & Back", "sequence": 0, "exercises": [{"name": "Dumbbell Bench Press", "sets": 3, "reps": "12"}, {"name": "Lat Pulldown", "sets": 3, "reps": "12"}]}, {"name": "Shoulders", "sequence": 1, "exercises": [{"name": "Lateral Raise", "sets": 3, "reps": "15"}, {"name": "Face Pull", "sets": 3, "reps": "15"}]}, {"name": "Arms", "sequence": 2, "exercises": [{"name": "Barbell Curl", "sets": 2, "reps": "12"}, {"name": "Tricep Pushdown", "sets": 2, "reps": "12"}]}, {"name": "Legs", "sequence": 3, "exercises": [{"name": "Leg Press", "sets": 3, "reps": "15"}, {"name": "Leg Curl", "sets": 3, "reps": "12"}]}]}'::jsonb,
ARRAY['bodybuilding', 'full-body', 'pump'], 'bodybuilding_full_pump.md'),

('00b00001-0024-4000-8000-000000000024', 'Classic Physique Posing', 'Posing practice with isometric holds', 'strength', 'advanced', 30,
'{"blocks": [{"name": "Front Poses", "sequence": 0, "exercises": [{"name": "Front Double Biceps", "sets": 3, "reps": "30 sec hold"}, {"name": "Front Lat Spread", "sets": 3, "reps": "30 sec hold"}, {"name": "Vacuum Pose", "sets": 3, "reps": "20 sec hold"}]}, {"name": "Side Poses", "sequence": 1, "exercises": [{"name": "Side Chest", "sets": 3, "reps": "30 sec each side"}, {"name": "Side Tricep", "sets": 3, "reps": "30 sec each side"}]}, {"name": "Back Poses", "sequence": 2, "exercises": [{"name": "Back Double Biceps", "sets": 3, "reps": "30 sec hold"}, {"name": "Back Lat Spread", "sets": 3, "reps": "30 sec hold"}]}]}'::jsonb,
ARRAY['bodybuilding', 'posing', 'competition'], 'bodybuilding_posing.md'),

('00b00001-0025-4000-8000-000000000025', 'Pre-Contest Depletion', 'Glycogen depletion workout for contest prep', 'full_body', 'advanced', 90,
'{"blocks": [{"name": "Chest & Back", "sequence": 0, "exercises": [{"name": "Machine Chest Press", "sets": 4, "reps": "20"}, {"name": "Lat Pulldown", "sets": 4, "reps": "20"}]}, {"name": "Shoulders", "sequence": 1, "exercises": [{"name": "Machine Shoulder Press", "sets": 4, "reps": "20"}, {"name": "Lateral Raise", "sets": 4, "reps": "20"}]}, {"name": "Arms", "sequence": 2, "exercises": [{"name": "Cable Curl", "sets": 3, "reps": "25"}, {"name": "Tricep Pushdown", "sets": 3, "reps": "25"}]}, {"name": "Legs", "sequence": 3, "exercises": [{"name": "Leg Press", "sets": 5, "reps": "25"}, {"name": "Leg Extension", "sets": 4, "reps": "25"}, {"name": "Leg Curl", "sets": 4, "reps": "25"}]}]}'::jsonb,
ARRAY['bodybuilding', 'depletion', 'contest-prep', 'advanced'], 'bodybuilding_depletion.md');
