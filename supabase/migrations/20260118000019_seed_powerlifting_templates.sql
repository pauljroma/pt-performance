-- Seed Powerlifting workout templates (25 templates)
-- Focus: Squat, Bench, Deadlift programs with percentage-based training

INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file) VALUES

-- BEGINNER PROGRAMS (5)
('00a00001-0001-4000-8000-000000000001', 'Starting Strength Day A', 'Classic beginner program - squat, bench, deadlift focus', 'strength', 'beginner', 60,
'{"blocks": [{"name": "Warm-Up", "sequence": 0, "exercises": [{"name": "Barbell Complex", "sets": 2, "reps": "5", "notes": "Empty bar"}]}, {"name": "Main Lifts", "sequence": 1, "exercises": [{"name": "Back Squat", "sets": 3, "reps": "5", "notes": "Work up to work weight"}, {"name": "Bench Press", "sets": 3, "reps": "5"}, {"name": "Deadlift", "sets": 1, "reps": "5"}]}]}'::jsonb,
ARRAY['powerlifting', 'beginner', 'strength', 'barbell'], 'powerlifting_starting_strength_a.md'),

('00a00001-0002-4000-8000-000000000002', 'Starting Strength Day B', 'Classic beginner program - squat, press, clean focus', 'strength', 'beginner', 60,
'{"blocks": [{"name": "Warm-Up", "sequence": 0, "exercises": [{"name": "Barbell Complex", "sets": 2, "reps": "5", "notes": "Empty bar"}]}, {"name": "Main Lifts", "sequence": 1, "exercises": [{"name": "Back Squat", "sets": 3, "reps": "5"}, {"name": "Overhead Press", "sets": 3, "reps": "5"}, {"name": "Power Clean", "sets": 5, "reps": "3"}]}]}'::jsonb,
ARRAY['powerlifting', 'beginner', 'strength', 'barbell'], 'powerlifting_starting_strength_b.md'),

('00a00001-0003-4000-8000-000000000003', 'Greyskull LP Day A', 'Linear progression with AMRAP sets', 'strength', 'beginner', 50,
'{"blocks": [{"name": "Main Lifts", "sequence": 0, "exercises": [{"name": "Bench Press", "sets": 3, "reps": "5+", "notes": "Last set AMRAP"}, {"name": "Barbell Row", "sets": 3, "reps": "5+"}]}, {"name": "Lower Body", "sequence": 1, "exercises": [{"name": "Back Squat", "sets": 3, "reps": "5+", "notes": "Last set AMRAP"}]}]}'::jsonb,
ARRAY['powerlifting', 'beginner', 'linear-progression'], 'powerlifting_greyskull_a.md'),

('00a00001-0004-4000-8000-000000000004', 'Greyskull LP Day B', 'Linear progression with AMRAP sets', 'strength', 'beginner', 50,
'{"blocks": [{"name": "Main Lifts", "sequence": 0, "exercises": [{"name": "Overhead Press", "sets": 3, "reps": "5+", "notes": "Last set AMRAP"}, {"name": "Chin-Ups", "sets": 3, "reps": "5+"}]}, {"name": "Lower Body", "sequence": 1, "exercises": [{"name": "Deadlift", "sets": 3, "reps": "5+", "notes": "Last set AMRAP"}]}]}'::jsonb,
ARRAY['powerlifting', 'beginner', 'linear-progression'], 'powerlifting_greyskull_b.md'),

('00a00001-0005-4000-8000-000000000005', 'Beginner Squat Focus', 'High frequency squatting for beginners', 'strength', 'beginner', 45,
'{"blocks": [{"name": "Main Lift", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 5, "reps": "5", "notes": "Focus on depth and form"}]}, {"name": "Accessories", "sequence": 1, "exercises": [{"name": "Leg Press", "sets": 3, "reps": "10"}, {"name": "Leg Curl", "sets": 3, "reps": "10"}]}]}'::jsonb,
ARRAY['powerlifting', 'beginner', 'squat'], 'powerlifting_beginner_squat.md'),

-- INTERMEDIATE PROGRAMS (10)
('00a00001-0006-4000-8000-000000000006', '5/3/1 Squat Day', 'Wendler 5/3/1 squat focus with BBB accessories', 'strength', 'intermediate', 75,
'{"blocks": [{"name": "Main Lift", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 3, "reps": "5/3/1", "notes": "Week dependent - 65/75/85% or 70/80/90% or 75/85/95%"}]}, {"name": "BBB", "sequence": 1, "exercises": [{"name": "Back Squat", "sets": 5, "reps": "10", "notes": "50-60% of TM"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Leg Curl", "sets": 5, "reps": "10"}, {"name": "Ab Wheel", "sets": 5, "reps": "10"}]}]}'::jsonb,
ARRAY['powerlifting', 'intermediate', '531', 'squat'], 'powerlifting_531_squat.md'),

('00a00001-0007-4000-8000-000000000007', '5/3/1 Bench Day', 'Wendler 5/3/1 bench focus with BBB accessories', 'strength', 'intermediate', 75,
'{"blocks": [{"name": "Main Lift", "sequence": 0, "exercises": [{"name": "Bench Press", "sets": 3, "reps": "5/3/1", "notes": "Week dependent percentages"}]}, {"name": "BBB", "sequence": 1, "exercises": [{"name": "Bench Press", "sets": 5, "reps": "10", "notes": "50-60% of TM"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Dumbbell Row", "sets": 5, "reps": "10"}, {"name": "Face Pull", "sets": 5, "reps": "15"}]}]}'::jsonb,
ARRAY['powerlifting', 'intermediate', '531', 'bench'], 'powerlifting_531_bench.md'),

('00a00001-0008-4000-8000-000000000008', '5/3/1 Deadlift Day', 'Wendler 5/3/1 deadlift focus with BBB accessories', 'strength', 'intermediate', 75,
'{"blocks": [{"name": "Main Lift", "sequence": 0, "exercises": [{"name": "Deadlift", "sets": 3, "reps": "5/3/1", "notes": "Week dependent percentages"}]}, {"name": "BBB", "sequence": 1, "exercises": [{"name": "Deadlift", "sets": 5, "reps": "10", "notes": "50-60% of TM"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Hanging Leg Raise", "sets": 5, "reps": "10"}, {"name": "Back Extension", "sets": 5, "reps": "10"}]}]}'::jsonb,
ARRAY['powerlifting', 'intermediate', '531', 'deadlift'], 'powerlifting_531_deadlift.md'),

('00a00001-0009-4000-8000-000000000009', '5/3/1 OHP Day', 'Wendler 5/3/1 overhead press focus', 'strength', 'intermediate', 75,
'{"blocks": [{"name": "Main Lift", "sequence": 0, "exercises": [{"name": "Overhead Press", "sets": 3, "reps": "5/3/1", "notes": "Week dependent percentages"}]}, {"name": "BBB", "sequence": 1, "exercises": [{"name": "Overhead Press", "sets": 5, "reps": "10", "notes": "50-60% of TM"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Chin-Up", "sets": 5, "reps": "10"}, {"name": "Dips", "sets": 5, "reps": "10"}]}]}'::jsonb,
ARRAY['powerlifting', 'intermediate', '531', 'press'], 'powerlifting_531_ohp.md'),

('00a00001-0010-4000-8000-000000000010', 'Texas Method Volume Day', 'High volume Monday session', 'strength', 'intermediate', 90,
'{"blocks": [{"name": "Main Lifts", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 5, "reps": "5", "notes": "90% of 5RM"}, {"name": "Bench Press", "sets": 5, "reps": "5", "notes": "90% of 5RM"}, {"name": "Deadlift", "sets": 1, "reps": "5", "notes": "90% of 5RM"}]}]}'::jsonb,
ARRAY['powerlifting', 'intermediate', 'texas-method', 'volume'], 'powerlifting_texas_volume.md'),

('00a00001-0011-4000-8000-000000000011', 'Texas Method Intensity Day', 'Heavy singles/PRs Friday session', 'strength', 'intermediate', 75,
'{"blocks": [{"name": "Main Lifts", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 1, "reps": "5", "notes": "PR attempt or 2.5lb increase"}, {"name": "Bench Press", "sets": 1, "reps": "5", "notes": "PR attempt"}, {"name": "Power Clean", "sets": 5, "reps": "3"}]}]}'::jsonb,
ARRAY['powerlifting', 'intermediate', 'texas-method', 'intensity'], 'powerlifting_texas_intensity.md'),

('00a00001-0012-4000-8000-000000000012', 'GZCL Method T1/T2', 'GZCL tiered training approach', 'strength', 'intermediate', 75,
'{"blocks": [{"name": "T1 - Main Lift", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 5, "reps": "3", "notes": "85%+ intensity"}]}, {"name": "T2 - Secondary", "sequence": 1, "exercises": [{"name": "Front Squat", "sets": 3, "reps": "8", "notes": "65-75% intensity"}]}, {"name": "T3 - Accessories", "sequence": 2, "exercises": [{"name": "Leg Press", "sets": 3, "reps": "12"}, {"name": "Leg Curl", "sets": 3, "reps": "15"}]}]}'::jsonb,
ARRAY['powerlifting', 'intermediate', 'gzcl'], 'powerlifting_gzcl.md'),

('00a00001-0013-4000-8000-000000000013', 'Sheiko Bench Prep', 'Russian-style high frequency bench', 'strength', 'intermediate', 90,
'{"blocks": [{"name": "Bench Variations", "sequence": 0, "exercises": [{"name": "Bench Press", "sets": 5, "reps": "4", "notes": "70%"}, {"name": "Close Grip Bench", "sets": 4, "reps": "5", "notes": "65%"}, {"name": "Bench Press", "sets": 4, "reps": "3", "notes": "75%"}]}, {"name": "Accessories", "sequence": 1, "exercises": [{"name": "Tricep Pushdown", "sets": 4, "reps": "10"}, {"name": "Dumbbell Fly", "sets": 3, "reps": "12"}]}]}'::jsonb,
ARRAY['powerlifting', 'intermediate', 'sheiko', 'bench'], 'powerlifting_sheiko_bench.md'),

('00a00001-0014-4000-8000-000000000014', 'Conjugate Max Effort Upper', 'Westside-style ME upper body', 'strength', 'intermediate', 90,
'{"blocks": [{"name": "Max Effort", "sequence": 0, "exercises": [{"name": "Floor Press", "sets": 1, "reps": "1-3", "notes": "Work to max"}]}, {"name": "Supplemental", "sequence": 1, "exercises": [{"name": "Close Grip Bench", "sets": 4, "reps": "8"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Tricep Extension", "sets": 4, "reps": "12"}, {"name": "Lat Pulldown", "sets": 4, "reps": "12"}, {"name": "Rear Delt Fly", "sets": 3, "reps": "15"}]}]}'::jsonb,
ARRAY['powerlifting', 'intermediate', 'conjugate', 'max-effort'], 'powerlifting_conjugate_me_upper.md'),

('00a00001-0015-4000-8000-000000000015', 'Conjugate Max Effort Lower', 'Westside-style ME lower body', 'strength', 'intermediate', 90,
'{"blocks": [{"name": "Max Effort", "sequence": 0, "exercises": [{"name": "Box Squat", "sets": 1, "reps": "1-3", "notes": "Work to max"}]}, {"name": "Supplemental", "sequence": 1, "exercises": [{"name": "Good Morning", "sets": 4, "reps": "8"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Reverse Hyper", "sets": 4, "reps": "12"}, {"name": "GHD", "sets": 4, "reps": "10"}, {"name": "Ab Wheel", "sets": 3, "reps": "15"}]}]}'::jsonb,
ARRAY['powerlifting', 'intermediate', 'conjugate', 'max-effort'], 'powerlifting_conjugate_me_lower.md'),

-- ADVANCED PROGRAMS (10)
('00a00001-0016-4000-8000-000000000016', 'Conjugate Dynamic Effort Upper', 'Westside-style DE upper - speed bench', 'strength', 'advanced', 90,
'{"blocks": [{"name": "Dynamic Effort", "sequence": 0, "exercises": [{"name": "Speed Bench", "sets": 9, "reps": "3", "notes": "50% + bands, 45-60sec rest"}]}, {"name": "Supplemental", "sequence": 1, "exercises": [{"name": "JM Press", "sets": 4, "reps": "8"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Dumbbell Tricep Extension", "sets": 4, "reps": "15"}, {"name": "Face Pull", "sets": 4, "reps": "20"}, {"name": "Hammer Curl", "sets": 3, "reps": "12"}]}]}'::jsonb,
ARRAY['powerlifting', 'advanced', 'conjugate', 'dynamic-effort'], 'powerlifting_conjugate_de_upper.md'),

('00a00001-0017-4000-8000-000000000017', 'Conjugate Dynamic Effort Lower', 'Westside-style DE lower - speed squat/pulls', 'strength', 'advanced', 90,
'{"blocks": [{"name": "Dynamic Effort", "sequence": 0, "exercises": [{"name": "Box Squat", "sets": 12, "reps": "2", "notes": "50-60% + bands, 45sec rest"}]}, {"name": "Supplemental", "sequence": 1, "exercises": [{"name": "Speed Deadlift", "sets": 8, "reps": "1", "notes": "60-70%"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Belt Squat", "sets": 4, "reps": "12"}, {"name": "Reverse Hyper", "sets": 4, "reps": "15"}, {"name": "Standing Ab Crunch", "sets": 4, "reps": "15"}]}]}'::jsonb,
ARRAY['powerlifting', 'advanced', 'conjugate', 'dynamic-effort'], 'powerlifting_conjugate_de_lower.md'),

('00a00001-0018-4000-8000-000000000018', 'Peaking Squat Session', 'Competition prep - heavy singles', 'strength', 'advanced', 90,
'{"blocks": [{"name": "Warm-Up", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 3, "reps": "3", "notes": "50/60/70%"}]}, {"name": "Heavy Singles", "sequence": 1, "exercises": [{"name": "Back Squat", "sets": 3, "reps": "1", "notes": "85/90/95% - opener practice"}]}, {"name": "Back-Off", "sequence": 2, "exercises": [{"name": "Pause Squat", "sets": 3, "reps": "2", "notes": "75%"}]}]}'::jsonb,
ARRAY['powerlifting', 'advanced', 'peaking', 'squat'], 'powerlifting_peaking_squat.md'),

('00a00001-0019-4000-8000-000000000019', 'Peaking Bench Session', 'Competition prep - heavy bench singles', 'strength', 'advanced', 75,
'{"blocks": [{"name": "Warm-Up", "sequence": 0, "exercises": [{"name": "Bench Press", "sets": 3, "reps": "3", "notes": "50/60/70%"}]}, {"name": "Heavy Singles", "sequence": 1, "exercises": [{"name": "Bench Press", "sets": 3, "reps": "1", "notes": "85/90/95%"}]}, {"name": "Back-Off", "sequence": 2, "exercises": [{"name": "Close Grip Bench", "sets": 3, "reps": "3", "notes": "70%"}]}]}'::jsonb,
ARRAY['powerlifting', 'advanced', 'peaking', 'bench'], 'powerlifting_peaking_bench.md'),

('00a00001-0020-4000-8000-000000000020', 'Peaking Deadlift Session', 'Competition prep - heavy deadlift singles', 'strength', 'advanced', 75,
'{"blocks": [{"name": "Warm-Up", "sequence": 0, "exercises": [{"name": "Deadlift", "sets": 2, "reps": "3", "notes": "50/65%"}]}, {"name": "Heavy Singles", "sequence": 1, "exercises": [{"name": "Deadlift", "sets": 3, "reps": "1", "notes": "80/87/93%"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Block Pull", "sets": 2, "reps": "2", "notes": "85%"}]}]}'::jsonb,
ARRAY['powerlifting', 'advanced', 'peaking', 'deadlift'], 'powerlifting_peaking_deadlift.md'),

('00a00001-0021-4000-8000-000000000021', 'Squat Specialization', 'High frequency squat program', 'strength', 'advanced', 90,
'{"blocks": [{"name": "Primary Squat", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 6, "reps": "3", "notes": "80%"}]}, {"name": "Secondary Squat", "sequence": 1, "exercises": [{"name": "Pause Squat", "sets": 4, "reps": "3", "notes": "70%, 3sec pause"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Bulgarian Split Squat", "sets": 3, "reps": "8"}, {"name": "Leg Extension", "sets": 3, "reps": "12"}, {"name": "Standing Calf Raise", "sets": 4, "reps": "15"}]}]}'::jsonb,
ARRAY['powerlifting', 'advanced', 'specialization', 'squat'], 'powerlifting_squat_special.md'),

('00a00001-0022-4000-8000-000000000022', 'Deadlift Specialization', 'High frequency pulling program', 'strength', 'advanced', 90,
'{"blocks": [{"name": "Primary Pull", "sequence": 0, "exercises": [{"name": "Deadlift", "sets": 5, "reps": "3", "notes": "80%"}]}, {"name": "Secondary Pull", "sequence": 1, "exercises": [{"name": "Deficit Deadlift", "sets": 4, "reps": "4", "notes": "70%"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Barbell Row", "sets": 4, "reps": "8"}, {"name": "Good Morning", "sets": 3, "reps": "10"}, {"name": "Hanging Leg Raise", "sets": 3, "reps": "12"}]}]}'::jsonb,
ARRAY['powerlifting', 'advanced', 'specialization', 'deadlift'], 'powerlifting_deadlift_special.md'),

('00a00001-0023-4000-8000-000000000023', 'Bench Specialization', 'High frequency pressing program', 'strength', 'advanced', 90,
'{"blocks": [{"name": "Primary Press", "sequence": 0, "exercises": [{"name": "Bench Press", "sets": 6, "reps": "4", "notes": "77.5%"}]}, {"name": "Secondary Press", "sequence": 1, "exercises": [{"name": "Spoto Press", "sets": 4, "reps": "4", "notes": "70%"}]}, {"name": "Accessories", "sequence": 2, "exercises": [{"name": "Incline Dumbbell Press", "sets": 3, "reps": "10"}, {"name": "Tricep Dips", "sets": 3, "reps": "12"}, {"name": "Cable Fly", "sets": 3, "reps": "15"}]}]}'::jsonb,
ARRAY['powerlifting', 'advanced', 'specialization', 'bench'], 'powerlifting_bench_special.md'),

('00a00001-0024-4000-8000-000000000024', 'Full Meet Prep Day 1', 'Competition prep - squat focus', 'strength', 'advanced', 120,
'{"blocks": [{"name": "Competition Squat", "sequence": 0, "exercises": [{"name": "Back Squat", "sets": 1, "reps": "1", "notes": "Opener weight - commands practice"}]}, {"name": "Volume", "sequence": 1, "exercises": [{"name": "Back Squat", "sets": 4, "reps": "4", "notes": "75%"}]}, {"name": "Bench Touch", "sequence": 2, "exercises": [{"name": "Bench Press", "sets": 4, "reps": "4", "notes": "70%"}]}, {"name": "Accessories", "sequence": 3, "exercises": [{"name": "Leg Press", "sets": 3, "reps": "10"}, {"name": "Lat Pulldown", "sets": 3, "reps": "12"}]}]}'::jsonb,
ARRAY['powerlifting', 'advanced', 'meet-prep', 'competition'], 'powerlifting_meet_prep_1.md'),

('00a00001-0025-4000-8000-000000000025', 'Full Meet Prep Day 2', 'Competition prep - bench/deadlift focus', 'strength', 'advanced', 120,
'{"blocks": [{"name": "Competition Bench", "sequence": 0, "exercises": [{"name": "Bench Press", "sets": 1, "reps": "1", "notes": "Opener weight - commands practice"}]}, {"name": "Competition Deadlift", "sequence": 1, "exercises": [{"name": "Deadlift", "sets": 1, "reps": "1", "notes": "Opener weight"}]}, {"name": "Volume", "sequence": 2, "exercises": [{"name": "Close Grip Bench", "sets": 4, "reps": "6", "notes": "70%"}, {"name": "RDL", "sets": 3, "reps": "8", "notes": "65%"}]}, {"name": "Accessories", "sequence": 3, "exercises": [{"name": "Tricep Pushdown", "sets": 3, "reps": "12"}, {"name": "Back Extension", "sets": 3, "reps": "12"}]}]}'::jsonb,
ARRAY['powerlifting', 'advanced', 'meet-prep', 'competition'], 'powerlifting_meet_prep_2.md');
