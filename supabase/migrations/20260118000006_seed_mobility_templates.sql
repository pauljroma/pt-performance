-- Mobility Workout Templates
-- 25 mobility-focused workouts for flexibility, recovery, and joint health
-- Run this migration after the system_workout_templates table is created

BEGIN;

-- 1. Morning Mobility Flow
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000001',
    'Morning Mobility Flow',
    'Wake up your body with this gentle 20-minute mobility routine. Perfect for starting your day with improved flexibility and energy.',
    'mobility',
    'beginner',
    20,
    '[{"id": "b1111111-0001-4000-8000-000000000001", "name": "Gentle Activation", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1111111-0001-4000-8000-000000000001", "name": "Cat-Cow Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 cycles", "notes": "Slow, controlled movement synced with breath"}, {"id": "c1111111-0001-4000-8000-000000000002", "name": "Thread the Needle", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "8 each side", "notes": "Thoracic spine rotation"}]}, {"id": "b1111111-0002-4000-8000-000000000001", "name": "Dynamic Stretch", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "c1111111-0002-4000-8000-000000000001", "name": "World''s Greatest Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 each side", "notes": "Hip flexor, hamstring, thoracic rotation"}, {"id": "c1111111-0002-4000-8000-000000000002", "name": "Standing Side Bend", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "8 each side", "notes": "Lateral spine mobility"}, {"id": "c1111111-0002-4000-8000-000000000003", "name": "Neck Circles", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "5 each direction", "notes": "Gentle, slow circles"}]}, {"id": "b1111111-0003-4000-8000-000000000001", "name": "Hip Opening", "block_type": "prehab", "sequence": 3, "exercises": [{"id": "c1111111-0003-4000-8000-000000000001", "name": "90/90 Hip Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Internal and external rotation"}, {"id": "c1111111-0003-4000-8000-000000000002", "name": "Pigeon Pose", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Deep hip flexor stretch"}]}, {"id": "b1111111-0004-4000-8000-000000000001", "name": "Final Flow", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c1111111-0004-4000-8000-000000000001", "name": "Standing Forward Fold", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Let gravity stretch hamstrings"}, {"id": "c1111111-0004-4000-8000-000000000002", "name": "Mountain Pose with Arms Overhead", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "5 breaths", "notes": "Full body extension"}]}]'::jsonb,
    '{mobility,morning,flexibility,beginner,full-body,yoga,stretching,daily}',
    'mobility_morning_flow.md',
    NOW()
);

-- 2. Evening Wind Down
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000002',
    'Evening Wind Down',
    'Relax and release tension with this calming 25-minute evening routine. Promotes better sleep and recovery.',
    'mobility',
    'beginner',
    25,
    '[{"id": "b2222222-0001-4000-8000-000000000001", "name": "Breathing", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c2222222-0001-4000-8000-000000000001", "name": "Diaphragmatic Breathing", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "4 count inhale, 6 count exhale"}, {"id": "c2222222-0001-4000-8000-000000000002", "name": "Supine Spinal Twist", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Relaxed, gravity-assisted"}]}, {"id": "b2222222-0002-4000-8000-000000000001", "name": "Lower Body Release", "block_type": "recovery", "sequence": 2, "exercises": [{"id": "c2222222-0002-4000-8000-000000000001", "name": "Reclined Figure Four", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Piriformis and glute release"}, {"id": "c2222222-0002-4000-8000-000000000002", "name": "Happy Baby Pose", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Inner hip and groin release"}, {"id": "c2222222-0002-4000-8000-000000000003", "name": "Legs Up the Wall", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Passive hamstring stretch, promotes relaxation"}]}, {"id": "b2222222-0003-4000-8000-000000000001", "name": "Upper Body Release", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c2222222-0003-4000-8000-000000000001", "name": "Child''s Pose", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Arms extended, focus on lat stretch"}, {"id": "c2222222-0003-4000-8000-000000000002", "name": "Neck Stretches", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Ear to shoulder, gentle pressure"}]}, {"id": "b2222222-0004-4000-8000-000000000001", "name": "Final Relaxation", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c2222222-0004-4000-8000-000000000001", "name": "Savasana", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Complete relaxation, body scan"}]}]'::jsonb,
    '{mobility,evening,relaxation,recovery,sleep,beginner,stretching,yoga}',
    'mobility_evening_wind_down.md',
    NOW()
);

-- 3. Hip Opener Sequence
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000003',
    'Hip Opener Sequence',
    'Target tight hips with this comprehensive 30-minute hip mobility routine. Great for desk workers and athletes.',
    'mobility',
    'intermediate',
    30,
    '[{"id": "b3333333-0001-4000-8000-000000000001", "name": "Hip Activation", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c3333333-0001-4000-8000-000000000001", "name": "Hip Circles", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 each direction", "notes": "Standing, controlled circles"}, {"id": "c3333333-0001-4000-8000-000000000002", "name": "Leg Swings", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "15 each leg", "notes": "Front to back and side to side"}]}, {"id": "b3333333-0002-4000-8000-000000000001", "name": "Dynamic Hip Mobility", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "c3333333-0002-4000-8000-000000000001", "name": "Walking Lunges with Twist", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 each leg", "notes": "Rotate toward front leg"}, {"id": "c3333333-0002-4000-8000-000000000002", "name": "Lateral Lunges", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 each side", "notes": "Adductor stretch"}, {"id": "c3333333-0002-4000-8000-000000000003", "name": "Inchworm to World''s Greatest", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "6 reps", "notes": "Full hip complex"}]}, {"id": "b3333333-0003-4000-8000-000000000001", "name": "Deep Hip Stretches", "block_type": "prehab", "sequence": 3, "exercises": [{"id": "c3333333-0003-4000-8000-000000000001", "name": "Pigeon Pose", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Hip flexor and external rotator"}, {"id": "c3333333-0003-4000-8000-000000000002", "name": "Frog Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Adductor stretch, rock gently"}, {"id": "c3333333-0003-4000-8000-000000000003", "name": "90/90 Transitions", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 transitions", "notes": "Internal/external rotation flow"}, {"id": "c3333333-0003-4000-8000-000000000004", "name": "Half Kneeling Hip Flexor Stretch", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Reach opposite arm overhead"}]}, {"id": "b3333333-0004-4000-8000-000000000001", "name": "Hip Strength Integration", "block_type": "functional", "sequence": 4, "exercises": [{"id": "c3333333-0004-4000-8000-000000000001", "name": "Clamshells", "sequence": 1, "prescribed_sets": 2, "prescribed_reps": "15 each side", "notes": "Hip external rotation strength"}, {"id": "c3333333-0004-4000-8000-000000000002", "name": "Fire Hydrants", "sequence": 2, "prescribed_sets": 2, "prescribed_reps": "12 each side", "notes": "Hip abduction and rotation"}]}]'::jsonb,
    '{mobility,hips,flexibility,intermediate,desk-worker,athlete,stretching}',
    'mobility_hip_opener.md',
    NOW()
);

-- 4. Shoulder Mobility Complex
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000004',
    'Shoulder Mobility Complex',
    'Improve shoulder range of motion and reduce tension with this targeted 25-minute routine.',
    'mobility',
    'intermediate',
    25,
    '[{"id": "b4444444-0001-4000-8000-000000000001", "name": "Shoulder Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c4444444-0001-4000-8000-000000000001", "name": "Arm Circles", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "20 each direction", "notes": "Small to large circles"}, {"id": "c4444444-0001-4000-8000-000000000002", "name": "Shoulder Shrugs", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "15 reps", "notes": "Hold at top for 2 sec"}]}, {"id": "b4444444-0002-4000-8000-000000000001", "name": "Dynamic Shoulder Mobility", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "c4444444-0002-4000-8000-000000000001", "name": "PVC Passovers", "sequence": 1, "prescribed_sets": 2, "prescribed_reps": "10 reps", "notes": "Wide grip, controlled"}, {"id": "c4444444-0002-4000-8000-000000000002", "name": "Wall Slides", "sequence": 2, "prescribed_sets": 2, "prescribed_reps": "12 reps", "notes": "Keep back and arms against wall"}, {"id": "c4444444-0002-4000-8000-000000000003", "name": "Thread the Needle", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 each side", "notes": "Thoracic rotation with shoulder stretch"}]}, {"id": "b4444444-0003-4000-8000-000000000001", "name": "Static Shoulder Stretches", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c4444444-0003-4000-8000-000000000001", "name": "Cross-Body Shoulder Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Posterior deltoid stretch"}, {"id": "c4444444-0003-4000-8000-000000000002", "name": "Doorway Chest Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each arm", "notes": "Three angles: low, mid, high"}, {"id": "c4444444-0003-4000-8000-000000000003", "name": "Sleeper Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Internal rotation stretch"}, {"id": "c4444444-0003-4000-8000-000000000004", "name": "Lat Stretch on Wall", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Arm overhead, lean away"}]}, {"id": "b4444444-0004-4000-8000-000000000001", "name": "Shoulder Stability", "block_type": "prehab", "sequence": 4, "exercises": [{"id": "c4444444-0004-4000-8000-000000000001", "name": "Band Pull-Aparts", "sequence": 1, "prescribed_sets": 2, "prescribed_reps": "15 reps", "notes": "Light resistance, squeeze shoulder blades"}, {"id": "c4444444-0004-4000-8000-000000000002", "name": "Prone Y-T-W Raises", "sequence": 2, "prescribed_sets": 2, "prescribed_reps": "8 each position", "notes": "No weight or light dumbbells"}]}]'::jsonb,
    '{mobility,shoulders,upper-body,flexibility,intermediate,desk-worker,prehab}',
    'mobility_shoulder_complex.md',
    NOW()
);

-- 5. Full Body Stretch
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000005',
    'Full Body Stretch',
    'A comprehensive 35-minute stretching routine hitting every major muscle group. Perfect for rest days.',
    'mobility',
    'beginner',
    35,
    '[{"id": "b5555555-0001-4000-8000-000000000001", "name": "Neck & Shoulders", "block_type": "recovery", "sequence": 1, "exercises": [{"id": "c5555555-0001-4000-8000-000000000001", "name": "Neck Tilts", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "30 sec each side", "notes": "Ear to shoulder"}, {"id": "c5555555-0001-4000-8000-000000000002", "name": "Neck Rotations", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec each side", "notes": "Chin to shoulder"}, {"id": "c5555555-0001-4000-8000-000000000003", "name": "Shoulder Rolls", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 each direction", "notes": "Full range of motion"}]}, {"id": "b5555555-0002-4000-8000-000000000001", "name": "Upper Body", "block_type": "recovery", "sequence": 2, "exercises": [{"id": "c5555555-0002-4000-8000-000000000001", "name": "Triceps Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each arm", "notes": "Elbow to ceiling"}, {"id": "c5555555-0002-4000-8000-000000000002", "name": "Chest Doorway Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec", "notes": "Both arms in doorframe"}, {"id": "c5555555-0002-4000-8000-000000000003", "name": "Cat-Cow", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 cycles", "notes": "Spine flexion and extension"}, {"id": "c5555555-0002-4000-8000-000000000004", "name": "Child''s Pose", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Arms extended for lat stretch"}]}, {"id": "b5555555-0003-4000-8000-000000000001", "name": "Lower Back & Core", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c5555555-0003-4000-8000-000000000001", "name": "Knee to Chest", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Lower back release"}, {"id": "c5555555-0003-4000-8000-000000000002", "name": "Supine Twist", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Let gravity do the work"}, {"id": "c5555555-0003-4000-8000-000000000003", "name": "Cobra Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "45 sec", "notes": "Gentle back extension"}]}, {"id": "b5555555-0004-4000-8000-000000000001", "name": "Hips & Glutes", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c5555555-0004-4000-8000-000000000001", "name": "Figure Four Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Piriformis and glutes"}, {"id": "c5555555-0004-4000-8000-000000000002", "name": "Kneeling Hip Flexor", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Squeeze glute of back leg"}, {"id": "c5555555-0004-4000-8000-000000000003", "name": "Butterfly Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Inner thigh and groin"}]}, {"id": "b5555555-0005-4000-8000-000000000001", "name": "Legs", "block_type": "recovery", "sequence": 5, "exercises": [{"id": "c5555555-0005-4000-8000-000000000001", "name": "Standing Quad Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Keep knees together"}, {"id": "c5555555-0005-4000-8000-000000000002", "name": "Standing Hamstring Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Foot on elevated surface"}, {"id": "c5555555-0005-4000-8000-000000000003", "name": "Calf Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Against wall, straight leg"}, {"id": "c5555555-0005-4000-8000-000000000004", "name": "Seated Forward Fold", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Hamstrings and lower back"}]}]'::jsonb,
    '{mobility,full-body,stretching,beginner,rest-day,flexibility,recovery}',
    'mobility_full_body_stretch.md',
    NOW()
);

-- 6. Yoga for Athletes
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000006',
    'Yoga for Athletes',
    'Athletic yoga flow focusing on strength, balance, and flexibility. 40 minutes of functional movement.',
    'mobility',
    'intermediate',
    40,
    '[{"id": "b6666666-0001-4000-8000-000000000001", "name": "Sun Salutation Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c6666666-0001-4000-8000-000000000001", "name": "Sun Salutation A", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 rounds", "notes": "Flow with breath"}, {"id": "c6666666-0001-4000-8000-000000000002", "name": "Sun Salutation B", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "3 rounds", "notes": "Add Warrior I"}]}, {"id": "b6666666-0002-4000-8000-000000000001", "name": "Standing Balance Series", "block_type": "functional", "sequence": 2, "exercises": [{"id": "c6666666-0002-4000-8000-000000000001", "name": "Warrior III", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "30 sec each side", "notes": "Strong standing leg"}, {"id": "c6666666-0002-4000-8000-000000000002", "name": "Tree Pose", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Focus on hip opening"}, {"id": "c6666666-0002-4000-8000-000000000003", "name": "Half Moon Pose", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 sec each side", "notes": "Use block if needed"}]}, {"id": "b6666666-0003-4000-8000-000000000001", "name": "Hip & Hamstring Opening", "block_type": "prehab", "sequence": 3, "exercises": [{"id": "c6666666-0003-4000-8000-000000000001", "name": "Lizard Pose", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Option to lower to forearms"}, {"id": "c6666666-0003-4000-8000-000000000002", "name": "Half Split (Ardha Hanumanasana)", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Hamstring focus"}, {"id": "c6666666-0003-4000-8000-000000000003", "name": "Pigeon Pose", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Option to fold forward"}]}, {"id": "b6666666-0004-4000-8000-000000000001", "name": "Core & Strength", "block_type": "functional", "sequence": 4, "exercises": [{"id": "c6666666-0004-4000-8000-000000000001", "name": "Plank to Downward Dog Flow", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Engage core throughout"}, {"id": "c6666666-0004-4000-8000-000000000002", "name": "Boat Pose", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "30 sec hold", "notes": "Legs straight if possible"}, {"id": "c6666666-0004-4000-8000-000000000003", "name": "Side Plank", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 sec each side", "notes": "Stack feet or stagger"}]}, {"id": "b6666666-0005-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 5, "exercises": [{"id": "c6666666-0005-4000-8000-000000000001", "name": "Supine Twist", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Relax into the twist"}, {"id": "c6666666-0005-4000-8000-000000000002", "name": "Happy Baby", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Rock side to side"}, {"id": "c6666666-0005-4000-8000-000000000003", "name": "Savasana", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Full body relaxation"}]}]'::jsonb,
    '{mobility,yoga,athlete,intermediate,balance,strength,flexibility}',
    'mobility_yoga_athletes.md',
    NOW()
);

-- 7. Foam Rolling Recovery
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000007',
    'Foam Rolling Recovery',
    'Self-myofascial release session targeting major muscle groups. 20 minutes of foam rolling for recovery.',
    'mobility',
    'beginner',
    20,
    '[{"id": "b7777777-0001-4000-8000-000000000001", "name": "Lower Body Rolling", "block_type": "recovery", "sequence": 1, "exercises": [{"id": "c7777777-0001-4000-8000-000000000001", "name": "Foam Roll Calves", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each leg", "notes": "Roll slowly, pause on tender spots"}, {"id": "c7777777-0001-4000-8000-000000000002", "name": "Foam Roll Hamstrings", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each leg", "notes": "Cross legs for more pressure"}, {"id": "c7777777-0001-4000-8000-000000000003", "name": "Foam Roll Quads", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each leg", "notes": "Include outer quad (IT band area)"}, {"id": "c7777777-0001-4000-8000-000000000004", "name": "Foam Roll Adductors", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "60 sec each leg", "notes": "Frog position on roller"}]}, {"id": "b7777777-0002-4000-8000-000000000001", "name": "Glutes & Hips", "block_type": "recovery", "sequence": 2, "exercises": [{"id": "c7777777-0002-4000-8000-000000000001", "name": "Foam Roll Glutes", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Cross ankle over knee for deeper release"}, {"id": "c7777777-0002-4000-8000-000000000002", "name": "Lacrosse Ball Piriformis", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Small circular movements"}, {"id": "c7777777-0002-4000-8000-000000000003", "name": "Foam Roll Hip Flexors", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Prone position, gentle pressure"}]}, {"id": "b7777777-0003-4000-8000-000000000001", "name": "Back & Upper Body", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c7777777-0003-4000-8000-000000000001", "name": "Foam Roll Thoracic Spine", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Arms crossed, extend over roller"}, {"id": "c7777777-0003-4000-8000-000000000002", "name": "Foam Roll Lats", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Side lying position"}, {"id": "c7777777-0003-4000-8000-000000000003", "name": "Lacrosse Ball Upper Traps", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Against wall for control"}, {"id": "c7777777-0003-4000-8000-000000000004", "name": "Lacrosse Ball Pecs", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Against wall or floor"}]}]'::jsonb,
    '{mobility,foam-rolling,recovery,myofascial,beginner,self-massage}',
    'mobility_foam_rolling.md',
    NOW()
);

-- 8. Active Recovery Day
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000008',
    'Active Recovery Day',
    'Light movement and stretching for rest days. 30 minutes to promote blood flow and reduce soreness.',
    'mobility',
    'beginner',
    30,
    '[{"id": "b8888888-0001-4000-8000-000000000001", "name": "Light Cardio", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c8888888-0001-4000-8000-000000000001", "name": "Easy Walk or Light Jog", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Very low intensity, conversational pace"}, {"id": "c8888888-0001-4000-8000-000000000002", "name": "Arm Circles", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "20 each direction", "notes": "Gentle shoulder warmup"}]}, {"id": "b8888888-0002-4000-8000-000000000001", "name": "Gentle Movement", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "c8888888-0002-4000-8000-000000000001", "name": "Cat-Cow", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 cycles", "notes": "Slow, mindful movement"}, {"id": "c8888888-0002-4000-8000-000000000002", "name": "Hip Circles on All Fours", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 each direction", "notes": "Large, controlled circles"}, {"id": "c8888888-0002-4000-8000-000000000003", "name": "Thread the Needle", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "8 each side", "notes": "Gentle thoracic rotation"}, {"id": "c8888888-0002-4000-8000-000000000004", "name": "Downward Dog to Cobra Flow", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "8 reps", "notes": "Slow transitions"}]}, {"id": "b8888888-0003-4000-8000-000000000001", "name": "Static Stretching", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c8888888-0003-4000-8000-000000000001", "name": "Seated Forward Fold", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Relax into the stretch"}, {"id": "c8888888-0003-4000-8000-000000000002", "name": "Supine Figure Four", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Gentle glute stretch"}, {"id": "c8888888-0003-4000-8000-000000000003", "name": "Supine Twist", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Let gravity do the work"}, {"id": "c8888888-0003-4000-8000-000000000004", "name": "Child''s Pose", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Wide knees, arms extended"}]}, {"id": "b8888888-0004-4000-8000-000000000001", "name": "Relaxation", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c8888888-0004-4000-8000-000000000001", "name": "Legs Up Wall", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Promotes circulation"}, {"id": "c8888888-0004-4000-8000-000000000002", "name": "Deep Breathing", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Box breathing: 4-4-4-4"}]}]'::jsonb,
    '{mobility,recovery,rest-day,beginner,low-intensity,stretching}',
    'mobility_active_recovery.md',
    NOW()
);

-- 9. Lower Body Mobility
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000009',
    'Lower Body Mobility',
    'Targeted mobility work for hips, knees, and ankles. 25 minutes for leg day recovery or prep.',
    'mobility',
    'intermediate',
    25,
    '[{"id": "b9999999-0001-4000-8000-000000000001", "name": "Ankle Mobility", "block_type": "prehab", "sequence": 1, "exercises": [{"id": "c9999999-0001-4000-8000-000000000001", "name": "Ankle Circles", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "15 each direction each ankle", "notes": "Full range of motion"}, {"id": "c9999999-0001-4000-8000-000000000002", "name": "Banded Ankle Dorsiflexion", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each ankle", "notes": "Band anchored behind, knee forward"}, {"id": "c9999999-0001-4000-8000-000000000003", "name": "Calf Stretch on Step", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Heel drops off edge"}]}, {"id": "b9999999-0002-4000-8000-000000000001", "name": "Knee & Quad Mobility", "block_type": "prehab", "sequence": 2, "exercises": [{"id": "c9999999-0002-4000-8000-000000000001", "name": "Couch Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Back foot against wall or couch"}, {"id": "c9999999-0002-4000-8000-000000000002", "name": "Heel to Glute Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Side-lying position"}, {"id": "c9999999-0002-4000-8000-000000000003", "name": "Foam Roll Quads", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each leg", "notes": "Pause on tight spots"}]}, {"id": "b9999999-0003-4000-8000-000000000001", "name": "Hip Mobility", "block_type": "prehab", "sequence": 3, "exercises": [{"id": "c9999999-0003-4000-8000-000000000001", "name": "90/90 Hip Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Front and back leg position"}, {"id": "c9999999-0003-4000-8000-000000000002", "name": "Deep Squat Hold", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min total", "notes": "Hold onto support if needed"}, {"id": "c9999999-0003-4000-8000-000000000003", "name": "Frog Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Rock forward and back"}, {"id": "c9999999-0003-4000-8000-000000000004", "name": "Pigeon Pose", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Keep hips square"}]}, {"id": "b9999999-0004-4000-8000-000000000001", "name": "Hamstring & Posterior Chain", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c9999999-0004-4000-8000-000000000001", "name": "Standing Hamstring Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Leg elevated on surface"}, {"id": "c9999999-0004-4000-8000-000000000002", "name": "Seated Forward Fold", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Reach for toes"}, {"id": "c9999999-0004-4000-8000-000000000003", "name": "Foam Roll Hamstrings", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each leg", "notes": "Cross legs for more pressure"}]}]'::jsonb,
    '{mobility,lower-body,hips,ankles,knees,intermediate,flexibility}',
    'mobility_lower_body.md',
    NOW()
);

-- 10. Upper Body Mobility
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000010',
    'Upper Body Mobility',
    'Comprehensive upper body mobility for shoulders, thoracic spine, and arms. 25 minutes.',
    'mobility',
    'intermediate',
    25,
    '[{"id": "baaaaaaa-0001-4000-8000-000000000001", "name": "Thoracic Spine", "block_type": "prehab", "sequence": 1, "exercises": [{"id": "caaaaaaa-0001-4000-8000-000000000001", "name": "Foam Roll T-Spine", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Arms crossed, extend over roller"}, {"id": "caaaaaaa-0001-4000-8000-000000000002", "name": "Cat-Cow", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 cycles", "notes": "Focus on thoracic movement"}, {"id": "caaaaaaa-0001-4000-8000-000000000003", "name": "Thread the Needle", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 each side", "notes": "Reach deep under body"}]}, {"id": "baaaaaaa-0002-4000-8000-000000000001", "name": "Shoulder Mobility", "block_type": "prehab", "sequence": 2, "exercises": [{"id": "caaaaaaa-0002-4000-8000-000000000001", "name": "Wall Slides", "sequence": 1, "prescribed_sets": 2, "prescribed_reps": "12 reps", "notes": "Keep back and arms against wall"}, {"id": "caaaaaaa-0002-4000-8000-000000000002", "name": "PVC Passovers", "sequence": 2, "prescribed_sets": 2, "prescribed_reps": "10 reps", "notes": "Wide grip, narrow as flexibility allows"}, {"id": "caaaaaaa-0002-4000-8000-000000000003", "name": "Shoulder CARs", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "5 each direction each arm", "notes": "Controlled articular rotations"}, {"id": "caaaaaaa-0002-4000-8000-000000000004", "name": "Band Pull-Aparts", "sequence": 4, "prescribed_sets": 2, "prescribed_reps": "15 reps", "notes": "Light band, squeeze shoulder blades"}]}, {"id": "baaaaaaa-0003-4000-8000-000000000001", "name": "Chest & Lats", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "caaaaaaa-0003-4000-8000-000000000001", "name": "Doorway Chest Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each angle", "notes": "Low, mid, high arm positions"}, {"id": "caaaaaaa-0003-4000-8000-000000000002", "name": "Lat Stretch on Wall", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Arm overhead, lean away"}, {"id": "caaaaaaa-0003-4000-8000-000000000003", "name": "Child''s Pose with Reach", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Walk hands to each side"}]}, {"id": "baaaaaaa-0004-4000-8000-000000000001", "name": "Arms & Wrists", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "caaaaaaa-0004-4000-8000-000000000001", "name": "Wrist Circles", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "15 each direction", "notes": "Full range of motion"}, {"id": "caaaaaaa-0004-4000-8000-000000000002", "name": "Wrist Flexor Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec each arm", "notes": "Arm extended, palm up"}, {"id": "caaaaaaa-0004-4000-8000-000000000003", "name": "Triceps Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 sec each arm", "notes": "Elbow to ceiling"}, {"id": "caaaaaaa-0004-4000-8000-000000000004", "name": "Biceps Wall Stretch", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "30 sec each arm", "notes": "Arm against wall, rotate away"}]}]'::jsonb,
    '{mobility,upper-body,shoulders,thoracic,intermediate,flexibility}',
    'mobility_upper_body.md',
    NOW()
);

-- 11. Spine & Back Mobility
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000011',
    'Spine & Back Mobility',
    'Focus on spinal health with this 25-minute routine for better posture and reduced back pain.',
    'mobility',
    'beginner',
    25,
    '[{"id": "bbbbbbbb-0001-4000-8000-000000000001", "name": "Spinal Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "cbbbbbbb-0001-4000-8000-000000000001", "name": "Pelvic Tilts", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "15 reps", "notes": "Lying on back, tilt pelvis"}, {"id": "cbbbbbbb-0001-4000-8000-000000000002", "name": "Dead Bug Breathing", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 breaths", "notes": "Legs at 90/90, press low back down"}]}, {"id": "bbbbbbbb-0002-4000-8000-000000000001", "name": "Spinal Flexion & Extension", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "cbbbbbbb-0002-4000-8000-000000000001", "name": "Cat-Cow", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "15 cycles", "notes": "Slow, controlled movement"}, {"id": "cbbbbbbb-0002-4000-8000-000000000002", "name": "Child''s Pose to Cobra", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Flow between positions"}, {"id": "cbbbbbbb-0002-4000-8000-000000000003", "name": "Prone Press-Ups", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "McKenzie extension"}]}, {"id": "bbbbbbbb-0003-4000-8000-000000000001", "name": "Spinal Rotation", "block_type": "prehab", "sequence": 3, "exercises": [{"id": "cbbbbbbb-0003-4000-8000-000000000001", "name": "Open Book Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 each side", "notes": "Side-lying thoracic rotation"}, {"id": "cbbbbbbb-0003-4000-8000-000000000002", "name": "Seated Spinal Twist", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Tall spine, rotate from mid-back"}, {"id": "cbbbbbbb-0003-4000-8000-000000000003", "name": "Supine Windshield Wipers", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 each side", "notes": "Knees together, controlled movement"}]}, {"id": "bbbbbbbb-0004-4000-8000-000000000001", "name": "Back Release", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "cbbbbbbb-0004-4000-8000-000000000001", "name": "Knee to Chest", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Lower back release"}, {"id": "cbbbbbbb-0004-4000-8000-000000000002", "name": "Double Knee to Chest", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Rock side to side"}, {"id": "cbbbbbbb-0004-4000-8000-000000000003", "name": "Supine Twist", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Arms in T position"}, {"id": "cbbbbbbb-0004-4000-8000-000000000004", "name": "Happy Baby", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Rock gently side to side"}]}]'::jsonb,
    '{mobility,spine,back,posture,beginner,flexibility,back-pain}',
    'mobility_spine_back.md',
    NOW()
);

-- 12. Ankle & Foot Mobility
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000012',
    'Ankle & Foot Mobility',
    'Improve ankle dorsiflexion and foot health. 15 minutes for better squat depth and injury prevention.',
    'mobility',
    'beginner',
    15,
    '[{"id": "bccccccc-0001-4000-8000-000000000001", "name": "Foot Activation", "block_type": "prehab", "sequence": 1, "exercises": [{"id": "cccccccc-0001-4000-8000-000000000001", "name": "Toe Yoga", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 reps each movement", "notes": "Big toe up/others down, then reverse"}, {"id": "cccccccc-0001-4000-8000-000000000002", "name": "Lacrosse Ball Foot Roll", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each foot", "notes": "Roll through arch and heel"}, {"id": "cccccccc-0001-4000-8000-000000000003", "name": "Toe Spreads", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "15 reps", "notes": "Spread toes wide, hold 3 sec"}]}, {"id": "bccccccc-0002-4000-8000-000000000001", "name": "Ankle Mobility", "block_type": "prehab", "sequence": 2, "exercises": [{"id": "cccccccc-0002-4000-8000-000000000001", "name": "Ankle Circles", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "15 each direction each ankle", "notes": "Full range of motion"}, {"id": "cccccccc-0002-4000-8000-000000000002", "name": "Ankle Dorsiflexion with Band", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each ankle", "notes": "Band pulls ankle forward"}, {"id": "cccccccc-0002-4000-8000-000000000003", "name": "Wall Ankle Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each leg", "notes": "Knee to wall, heel down"}, {"id": "cccccccc-0002-4000-8000-000000000004", "name": "Half Kneeling Ankle Mobilization", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "15 reps each ankle", "notes": "Drive knee forward over toe"}]}, {"id": "bccccccc-0003-4000-8000-000000000001", "name": "Calf Stretching", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "cccccccc-0003-4000-8000-000000000001", "name": "Standing Calf Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Straight leg for gastrocnemius"}, {"id": "cccccccc-0003-4000-8000-000000000002", "name": "Bent Knee Calf Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Bent knee for soleus"}, {"id": "cccccccc-0003-4000-8000-000000000003", "name": "Calf Raises", "sequence": 3, "prescribed_sets": 2, "prescribed_reps": "15 reps", "notes": "Full range, pause at top and bottom"}]}]'::jsonb,
    '{mobility,ankles,feet,squat,beginner,flexibility,prehab}',
    'mobility_ankle_foot.md',
    NOW()
);

-- 13. Desk Worker Relief
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000013',
    'Desk Worker Relief',
    'Combat the effects of prolonged sitting. 20 minutes to reverse desk posture and reduce stiffness.',
    'mobility',
    'beginner',
    20,
    '[{"id": "bdddddddd-0001-4000-8000-000000000001", "name": "Neck & Shoulders", "block_type": "recovery", "sequence": 1, "exercises": [{"id": "cdddddddd-0001-4000-8000-000000000001", "name": "Chin Tucks", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "15 reps", "notes": "Create double chin, hold 5 sec"}, {"id": "cdddddddd-0001-4000-8000-000000000002", "name": "Neck Stretches", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec each side", "notes": "Ear to shoulder with gentle pressure"}, {"id": "cdddddddd-0001-4000-8000-000000000003", "name": "Upper Trap Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 sec each side", "notes": "Hold chair, lean head away"}]}, {"id": "bdddddddd-0002-4000-8000-000000000001", "name": "Chest & Upper Back", "block_type": "recovery", "sequence": 2, "exercises": [{"id": "cdddddddd-0002-4000-8000-000000000001", "name": "Doorway Chest Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec", "notes": "Open up the chest"}, {"id": "cdddddddd-0002-4000-8000-000000000002", "name": "Wall Slides", "sequence": 2, "prescribed_sets": 2, "prescribed_reps": "12 reps", "notes": "Keep back and arms against wall"}, {"id": "cdddddddd-0002-4000-8000-000000000003", "name": "Thoracic Extension on Chair", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Drape over chair back, extend"}]}, {"id": "bdddddddd-0003-4000-8000-000000000001", "name": "Hips & Lower Back", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "cdddddddd-0003-4000-8000-000000000001", "name": "Standing Hip Flexor Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Squeeze glute of back leg"}, {"id": "cdddddddd-0003-4000-8000-000000000002", "name": "Figure Four in Chair", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Ankle on opposite knee"}, {"id": "cdddddddd-0003-4000-8000-000000000003", "name": "Cat-Cow in Chair", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 cycles", "notes": "Seated spinal mobility"}, {"id": "cdddddddd-0003-4000-8000-000000000004", "name": "Seated Spinal Twist", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Rotate and hold"}]}, {"id": "bdddddddd-0004-4000-8000-000000000001", "name": "Wrists & Arms", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "cdddddddd-0004-4000-8000-000000000001", "name": "Wrist Circles", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 each direction", "notes": "Full range of motion"}, {"id": "cdddddddd-0004-4000-8000-000000000002", "name": "Prayer Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Palms together, lower elbows"}, {"id": "cdddddddd-0004-4000-8000-000000000003", "name": "Reverse Prayer", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Backs of hands together"}]}]'::jsonb,
    '{mobility,desk-worker,posture,office,beginner,stretching,wrists}',
    'mobility_desk_worker.md',
    NOW()
);

-- 14. Post-Run Recovery
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000014',
    'Post-Run Recovery',
    'Essential stretches and mobility work after running. 15 minutes to aid recovery and prevent injury.',
    'mobility',
    'beginner',
    15,
    '[{"id": "beeeeeee-0001-4000-8000-000000000001", "name": "Lower Leg", "block_type": "recovery", "sequence": 1, "exercises": [{"id": "ceeeeeee-0001-4000-8000-000000000001", "name": "Standing Calf Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Against wall, straight leg"}, {"id": "ceeeeeee-0001-4000-8000-000000000002", "name": "Bent Knee Calf Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Soleus focus"}, {"id": "ceeeeeee-0001-4000-8000-000000000003", "name": "Tibialis Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 sec each leg", "notes": "Point toe, roll on top of foot"}]}, {"id": "beeeeeee-0002-4000-8000-000000000001", "name": "Quads & Hip Flexors", "block_type": "recovery", "sequence": 2, "exercises": [{"id": "ceeeeeee-0002-4000-8000-000000000001", "name": "Standing Quad Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Keep knees together"}, {"id": "ceeeeeee-0002-4000-8000-000000000002", "name": "Kneeling Hip Flexor Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Squeeze glute, lean forward"}]}, {"id": "beeeeeee-0003-4000-8000-000000000001", "name": "Hamstrings & Glutes", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "ceeeeeee-0003-4000-8000-000000000001", "name": "Standing Hamstring Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each leg", "notes": "Foot on elevated surface"}, {"id": "ceeeeeee-0003-4000-8000-000000000002", "name": "Figure Four Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Piriformis and glute"}, {"id": "ceeeeeee-0003-4000-8000-000000000003", "name": "IT Band Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Cross leg behind, lean away"}]}, {"id": "beeeeeee-0004-4000-8000-000000000001", "name": "Hip Mobility", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "ceeeeeee-0004-4000-8000-000000000001", "name": "Pigeon Pose", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Deep hip stretch"}, {"id": "ceeeeeee-0004-4000-8000-000000000002", "name": "Butterfly Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Inner thigh and groin"}]}]'::jsonb,
    '{mobility,running,recovery,stretching,beginner,post-workout}',
    'mobility_post_run.md',
    NOW()
);

-- 15. Pre-Workout Warmup Flow
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000015',
    'Pre-Workout Warmup Flow',
    'Dynamic mobility routine to prepare your body for exercise. 10 minutes of movement prep.',
    'mobility',
    'beginner',
    10,
    '[{"id": "bfffffff-0001-4000-8000-000000000001", "name": "General Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "cfffffff-0001-4000-8000-000000000001", "name": "Jumping Jacks", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Elevate heart rate"}, {"id": "cfffffff-0001-4000-8000-000000000002", "name": "High Knees", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Drive knees up"}]}, {"id": "bfffffff-0002-4000-8000-000000000001", "name": "Dynamic Mobility", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "cfffffff-0002-4000-8000-000000000001", "name": "Leg Swings", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 each direction each leg", "notes": "Front/back and side/side"}, {"id": "cfffffff-0002-4000-8000-000000000002", "name": "Arm Circles", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "15 each direction", "notes": "Small to large"}, {"id": "cfffffff-0002-4000-8000-000000000003", "name": "Hip Circles", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 each direction", "notes": "Controlled, full ROM"}, {"id": "cfffffff-0002-4000-8000-000000000004", "name": "Walking Lunges", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "10 total", "notes": "Add twist for thoracic mobility"}]}, {"id": "bfffffff-0003-4000-8000-000000000001", "name": "Movement Prep", "block_type": "prehab", "sequence": 3, "exercises": [{"id": "cfffffff-0003-4000-8000-000000000001", "name": "Inchworms", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "6 reps", "notes": "Walk hands out to plank, walk feet in"}, {"id": "cfffffff-0003-4000-8000-000000000002", "name": "World''s Greatest Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "5 each side", "notes": "Full movement complex"}, {"id": "cfffffff-0003-4000-8000-000000000003", "name": "Glute Bridges", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Squeeze at top"}, {"id": "cfffffff-0003-4000-8000-000000000004", "name": "Bird Dogs", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "8 each side", "notes": "Core stability activation"}]}]'::jsonb,
    '{mobility,warmup,dynamic,pre-workout,beginner,movement-prep}',
    'mobility_pre_workout.md',
    NOW()
);

-- 16. Bedtime Stretch Routine
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000016',
    'Bedtime Stretch Routine',
    'Gentle stretches to release tension and promote better sleep. 15 minutes of calming movement.',
    'mobility',
    'beginner',
    15,
    '[{"id": "b1010101-0001-4000-8000-000000000001", "name": "Breathing & Relaxation", "block_type": "recovery", "sequence": 1, "exercises": [{"id": "c1010101-0001-4000-8000-000000000001", "name": "Diaphragmatic Breathing", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "4-7-8 breathing: inhale 4, hold 7, exhale 8"}, {"id": "c1010101-0001-4000-8000-000000000002", "name": "Neck Rolls", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "5 each direction", "notes": "Slow, gentle circles"}]}, {"id": "b1010101-0002-4000-8000-000000000001", "name": "Upper Body Release", "block_type": "recovery", "sequence": 2, "exercises": [{"id": "c1010101-0002-4000-8000-000000000001", "name": "Seated Side Bend", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Reach arm overhead"}, {"id": "c1010101-0002-4000-8000-000000000002", "name": "Seated Twist", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "45 sec each side", "notes": "Gentle rotation"}, {"id": "c1010101-0002-4000-8000-000000000003", "name": "Child''s Pose", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Wide knees, forehead to floor"}]}, {"id": "b1010101-0003-4000-8000-000000000001", "name": "Lower Body Release", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1010101-0003-4000-8000-000000000001", "name": "Reclined Figure Four", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Gentle hip opener"}, {"id": "c1010101-0003-4000-8000-000000000002", "name": "Supine Twist", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Arms in T position"}, {"id": "c1010101-0003-4000-8000-000000000003", "name": "Legs Up Wall", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Promotes relaxation and circulation"}]}]'::jsonb,
    '{mobility,sleep,bedtime,relaxation,beginner,stretching,gentle}',
    'mobility_bedtime.md',
    NOW()
);

-- 17. Joint Health Circuit
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000017',
    'Joint Health Circuit',
    'Controlled articular rotations (CARs) for all major joints. 20 minutes of joint maintenance.',
    'mobility',
    'intermediate',
    20,
    '[{"id": "b1111110-0001-4000-8000-000000000001", "name": "Upper Body CARs", "block_type": "prehab", "sequence": 1, "exercises": [{"id": "c1111110-0001-4000-8000-000000000001", "name": "Neck CARs", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 each direction", "notes": "Slow, controlled circles"}, {"id": "c1111110-0001-4000-8000-000000000002", "name": "Shoulder CARs", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "5 each direction each arm", "notes": "Full range of motion"}, {"id": "c1111110-0001-4000-8000-000000000003", "name": "Elbow CARs", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "5 each direction each arm", "notes": "Flexion/extension with rotation"}, {"id": "c1111110-0001-4000-8000-000000000004", "name": "Wrist CARs", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "5 each direction each wrist", "notes": "Full circles"}]}, {"id": "b1111110-0002-4000-8000-000000000001", "name": "Spine CARs", "block_type": "prehab", "sequence": 2, "exercises": [{"id": "c1111110-0002-4000-8000-000000000001", "name": "Spinal CARs (Seated)", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 each direction", "notes": "Flexion, extension, rotation, side bend"}, {"id": "c1111110-0002-4000-8000-000000000002", "name": "Cat-Cow Flow", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 cycles", "notes": "Segmental spine movement"}]}, {"id": "b1111110-0003-4000-8000-000000000001", "name": "Lower Body CARs", "block_type": "prehab", "sequence": 3, "exercises": [{"id": "c1111110-0003-4000-8000-000000000001", "name": "Hip CARs", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 each direction each hip", "notes": "Standing or quadruped"}, {"id": "c1111110-0003-4000-8000-000000000002", "name": "Knee CARs", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "5 each direction each knee", "notes": "Flexion/extension focus"}, {"id": "c1111110-0003-4000-8000-000000000003", "name": "Ankle CARs", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "5 each direction each ankle", "notes": "Full circles"}]}, {"id": "b1111110-0004-4000-8000-000000000001", "name": "Integration", "block_type": "functional", "sequence": 4, "exercises": [{"id": "c1111110-0004-4000-8000-000000000001", "name": "90/90 Hip Transitions", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 transitions", "notes": "Smooth movement between positions"}, {"id": "c1111110-0004-4000-8000-000000000002", "name": "Bear Sit to Squat", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "8 reps", "notes": "Full range lower body integration"}]}]'::jsonb,
    '{mobility,joints,CARs,intermediate,prehab,maintenance}',
    'mobility_joint_health.md',
    NOW()
);

-- 18. Dynamic Mobility Complex
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000018',
    'Dynamic Mobility Complex',
    'Active mobility work combining movement and stretching. 25 minutes of athletic preparation.',
    'mobility',
    'intermediate',
    25,
    '[{"id": "b1212121-0001-4000-8000-000000000001", "name": "Locomotion Patterns", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1212121-0001-4000-8000-000000000001", "name": "High Knees", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "20 yards", "notes": "Pump arms"}, {"id": "c1212121-0001-4000-8000-000000000002", "name": "Butt Kicks", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "20 yards", "notes": "Heel to glute"}, {"id": "c1212121-0001-4000-8000-000000000003", "name": "Carioca", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "20 yards each direction", "notes": "Hip rotation focus"}, {"id": "c1212121-0001-4000-8000-000000000004", "name": "A-Skips", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "20 yards", "notes": "Drive knee, opposite arm"}]}, {"id": "b1212121-0002-4000-8000-000000000001", "name": "Dynamic Stretches", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "c1212121-0002-4000-8000-000000000001", "name": "Walking Knee Hugs", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 each leg", "notes": "Pull knee to chest"}, {"id": "c1212121-0002-4000-8000-000000000002", "name": "Walking Quad Pulls", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "10 each leg", "notes": "Reach opposite arm up"}, {"id": "c1212121-0002-4000-8000-000000000003", "name": "Toy Soldiers", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 each leg", "notes": "Hamstring activation"}, {"id": "c1212121-0002-4000-8000-000000000004", "name": "Walking Spiderman", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "8 each side", "notes": "Add thoracic rotation"}]}, {"id": "b1212121-0003-4000-8000-000000000001", "name": "Active Mobility", "block_type": "prehab", "sequence": 3, "exercises": [{"id": "c1212121-0003-4000-8000-000000000001", "name": "Inchworms with Push-Up", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "8 reps", "notes": "Add push-up at bottom"}, {"id": "c1212121-0003-4000-8000-000000000002", "name": "Reverse Lunges with Overhead Reach", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "8 each leg", "notes": "Reach same side as back leg"}, {"id": "c1212121-0003-4000-8000-000000000003", "name": "Lateral Lunges with Rotation", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "8 each side", "notes": "Rotate toward front leg"}, {"id": "c1212121-0003-4000-8000-000000000004", "name": "Squat to Stand", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "10 reps", "notes": "Touch toes, drop into squat, stand"}]}, {"id": "b1212121-0004-4000-8000-000000000001", "name": "Activation", "block_type": "prehab", "sequence": 4, "exercises": [{"id": "c1212121-0004-4000-8000-000000000001", "name": "Glute Bridges", "sequence": 1, "prescribed_sets": 2, "prescribed_reps": "12 reps", "notes": "Squeeze at top"}, {"id": "c1212121-0004-4000-8000-000000000002", "name": "Dead Bugs", "sequence": 2, "prescribed_sets": 2, "prescribed_reps": "10 each side", "notes": "Press low back down"}, {"id": "c1212121-0004-4000-8000-000000000003", "name": "Band Pull-Aparts", "sequence": 3, "prescribed_sets": 2, "prescribed_reps": "15 reps", "notes": "Squeeze shoulder blades"}]}]'::jsonb,
    '{mobility,dynamic,warmup,intermediate,athletic,movement-prep}',
    'mobility_dynamic_complex.md',
    NOW()
);

-- 19. Sun Salutation Flow
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000019',
    'Sun Salutation Flow',
    'Classic yoga sun salutation sequence. 15 minutes of energizing flow.',
    'mobility',
    'beginner',
    15,
    '[{"id": "b1313131-0001-4000-8000-000000000001", "name": "Centering", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1313131-0001-4000-8000-000000000001", "name": "Mountain Pose", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 breaths", "notes": "Ground feet, lengthen spine"}, {"id": "c1313131-0001-4000-8000-000000000002", "name": "Intention Setting", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "1 min", "notes": "Set intention for practice"}]}, {"id": "b1313131-0002-4000-8000-000000000001", "name": "Sun Salutation A", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "c1313131-0002-4000-8000-000000000001", "name": "Surya Namaskar A", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 rounds", "notes": "Mountain - Forward Fold - Half Lift - Chaturanga - Up Dog - Down Dog - Forward Fold - Mountain"}]}, {"id": "b1313131-0003-4000-8000-000000000001", "name": "Sun Salutation B", "block_type": "dynamic_stretch", "sequence": 3, "exercises": [{"id": "c1313131-0003-4000-8000-000000000001", "name": "Surya Namaskar B", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 rounds", "notes": "Add Chair Pose and Warrior I"}]}, {"id": "b1313131-0004-4000-8000-000000000001", "name": "Cool Down", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c1313131-0004-4000-8000-000000000001", "name": "Standing Forward Fold", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Let gravity stretch"}, {"id": "c1313131-0004-4000-8000-000000000002", "name": "Child''s Pose", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Rest and breathe"}, {"id": "c1313131-0004-4000-8000-000000000003", "name": "Savasana", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Final relaxation"}]}]'::jsonb,
    '{mobility,yoga,sun-salutation,beginner,flow,energizing}',
    'mobility_sun_salutation.md',
    NOW()
);

-- 20. Moon Salutation Flow
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000020',
    'Moon Salutation Flow',
    'Calming yoga sequence for evening practice. 15 minutes of gentle, cooling movement.',
    'mobility',
    'beginner',
    15,
    '[{"id": "b1414141-0001-4000-8000-000000000001", "name": "Grounding", "block_type": "recovery", "sequence": 1, "exercises": [{"id": "c1414141-0001-4000-8000-000000000001", "name": "Mountain Pose", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 breaths", "notes": "Feel feet connect to earth"}, {"id": "c1414141-0001-4000-8000-000000000002", "name": "Side Body Stretch", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "3 breaths each side", "notes": "Reach arm overhead, lean"}]}, {"id": "b1414141-0002-4000-8000-000000000001", "name": "Moon Salutation", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "c1414141-0002-4000-8000-000000000001", "name": "Chandra Namaskar", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "4 rounds", "notes": "Star Pose - Triangle - Pyramid - Low Lunge - Deep Side Lunge - Squat - return"}]}, {"id": "b1414141-0003-4000-8000-000000000001", "name": "Hip Opening", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1414141-0003-4000-8000-000000000001", "name": "Butterfly Pose", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Let knees drop"}, {"id": "c1414141-0003-4000-8000-000000000002", "name": "Reclined Bound Angle", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Support knees with blocks if needed"}]}, {"id": "b1414141-0004-4000-8000-000000000001", "name": "Final Rest", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c1414141-0004-4000-8000-000000000001", "name": "Supine Twist", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Relax into the twist"}, {"id": "c1414141-0004-4000-8000-000000000002", "name": "Savasana", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Complete relaxation"}]}]'::jsonb,
    '{mobility,yoga,moon-salutation,beginner,evening,calming}',
    'mobility_moon_salutation.md',
    NOW()
);

-- 21. PNF Stretching Routine
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000021',
    'PNF Stretching Routine',
    'Proprioceptive neuromuscular facilitation stretching for advanced flexibility gains. 30 minutes.',
    'mobility',
    'advanced',
    30,
    '[{"id": "b1515151-0001-4000-8000-000000000001", "name": "Lower Body PNF", "block_type": "recovery", "sequence": 1, "exercises": [{"id": "c1515151-0001-4000-8000-000000000001", "name": "PNF Hamstring Stretch", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "per leg", "notes": "Contract 6 sec, relax, stretch deeper - repeat 3x"}, {"id": "c1515151-0001-4000-8000-000000000002", "name": "PNF Hip Flexor Stretch", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "per side", "notes": "Push hip down 6 sec, relax, sink deeper"}, {"id": "c1515151-0001-4000-8000-000000000003", "name": "PNF Quad Stretch", "sequence": 3, "prescribed_sets": 3, "prescribed_reps": "per leg", "notes": "Push foot into hand 6 sec, relax, pull deeper"}, {"id": "c1515151-0001-4000-8000-000000000004", "name": "PNF Adductor Stretch", "sequence": 4, "prescribed_sets": 3, "prescribed_reps": "total", "notes": "Press knees out 6 sec, relax, fold forward"}]}, {"id": "b1515151-0002-4000-8000-000000000001", "name": "Upper Body PNF", "block_type": "recovery", "sequence": 2, "exercises": [{"id": "c1515151-0002-4000-8000-000000000001", "name": "PNF Chest Stretch", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "per arm", "notes": "Press into doorway 6 sec, relax, lean deeper"}, {"id": "c1515151-0002-4000-8000-000000000002", "name": "PNF Lat Stretch", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "per side", "notes": "Pull against anchor 6 sec, relax, reach further"}, {"id": "c1515151-0002-4000-8000-000000000003", "name": "PNF Triceps Stretch", "sequence": 3, "prescribed_sets": 3, "prescribed_reps": "per arm", "notes": "Press elbow into hand 6 sec, relax, pull deeper"}]}, {"id": "b1515151-0003-4000-8000-000000000001", "name": "Hip PNF Complex", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1515151-0003-4000-8000-000000000001", "name": "PNF Pigeon Pose", "sequence": 1, "prescribed_sets": 3, "prescribed_reps": "per side", "notes": "Press shin down 6 sec, relax, fold forward"}, {"id": "c1515151-0003-4000-8000-000000000002", "name": "PNF 90/90 Stretch", "sequence": 2, "prescribed_sets": 3, "prescribed_reps": "per position", "notes": "Contract against floor 6 sec, relax, sink deeper"}]}]'::jsonb,
    '{mobility,PNF,advanced,flexibility,stretching,deep-stretch}',
    'mobility_pnf.md',
    NOW()
);

-- 22. Myofascial Release Session
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000022',
    'Myofascial Release Session',
    'Comprehensive self-massage using various tools. 30 minutes for deep tissue work.',
    'mobility',
    'intermediate',
    30,
    '[{"id": "b1616161-0001-4000-8000-000000000001", "name": "Feet & Lower Leg", "block_type": "recovery", "sequence": 1, "exercises": [{"id": "c1616161-0001-4000-8000-000000000001", "name": "Lacrosse Ball Foot Release", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min each foot", "notes": "Roll through arch, heel, ball of foot"}, {"id": "c1616161-0001-4000-8000-000000000002", "name": "Foam Roll Calves", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "90 sec each leg", "notes": "Cross legs for more pressure"}, {"id": "c1616161-0001-4000-8000-000000000003", "name": "Foam Roll Shins (Tibialis)", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each leg", "notes": "Gentle pressure"}]}, {"id": "b1616161-0002-4000-8000-000000000001", "name": "Thighs", "block_type": "recovery", "sequence": 2, "exercises": [{"id": "c1616161-0002-4000-8000-000000000001", "name": "Foam Roll Quads", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "90 sec each leg", "notes": "Include inner and outer quad"}, {"id": "c1616161-0002-4000-8000-000000000002", "name": "Foam Roll IT Band", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Stack legs for more pressure"}, {"id": "c1616161-0002-4000-8000-000000000003", "name": "Foam Roll Adductors", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "90 sec each leg", "notes": "Frog position on roller"}, {"id": "c1616161-0002-4000-8000-000000000004", "name": "Foam Roll Hamstrings", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "90 sec each leg", "notes": "Cross legs for depth"}]}, {"id": "b1616161-0003-4000-8000-000000000001", "name": "Hips & Glutes", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1616161-0003-4000-8000-000000000001", "name": "Lacrosse Ball Glutes", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min each side", "notes": "Find tender spots, apply sustained pressure"}, {"id": "c1616161-0003-4000-8000-000000000002", "name": "Lacrosse Ball Piriformis", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Cross ankle over knee"}, {"id": "c1616161-0003-4000-8000-000000000003", "name": "Foam Roll TFL/Hip Flexor", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Prone position, gentle"}]}, {"id": "b1616161-0004-4000-8000-000000000001", "name": "Back & Upper Body", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c1616161-0004-4000-8000-000000000001", "name": "Foam Roll Thoracic Spine", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Arms crossed or overhead"}, {"id": "c1616161-0004-4000-8000-000000000002", "name": "Foam Roll Lats", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Thumb up position"}, {"id": "c1616161-0004-4000-8000-000000000003", "name": "Lacrosse Ball Upper Back", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Between spine and shoulder blade"}, {"id": "c1616161-0004-4000-8000-000000000004", "name": "Lacrosse Ball Pec Minor", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Against wall, below collarbone"}]}]'::jsonb,
    '{mobility,myofascial,foam-rolling,intermediate,recovery,self-massage}',
    'mobility_myofascial_release.md',
    NOW()
);

-- 23. Flexibility Builder
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000023',
    'Flexibility Builder',
    'Progressive stretching routine to improve overall flexibility. 35 minutes of deep stretching.',
    'mobility',
    'intermediate',
    35,
    '[{"id": "b1717171-0001-4000-8000-000000000001", "name": "Warmup", "block_type": "cardio", "sequence": 1, "exercises": [{"id": "c1717171-0001-4000-8000-000000000001", "name": "Light Cardio", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "Jumping jacks or marching"}, {"id": "c1717171-0001-4000-8000-000000000002", "name": "Dynamic Arm Circles", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "20 each direction", "notes": "Warm up shoulders"}]}, {"id": "b1717171-0002-4000-8000-000000000001", "name": "Lower Body Flexibility", "block_type": "recovery", "sequence": 2, "exercises": [{"id": "c1717171-0002-4000-8000-000000000001", "name": "Forward Fold", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Let gravity stretch"}, {"id": "c1717171-0002-4000-8000-000000000002", "name": "Wide Leg Forward Fold", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Walk hands between legs"}, {"id": "c1717171-0002-4000-8000-000000000003", "name": "Half Split Each Leg", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "90 sec each", "notes": "Work toward full split"}, {"id": "c1717171-0002-4000-8000-000000000004", "name": "Frog Stretch", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Work toward middle split"}, {"id": "c1717171-0002-4000-8000-000000000005", "name": "Pigeon Pose", "sequence": 5, "prescribed_sets": 1, "prescribed_reps": "2 min each side", "notes": "Fold forward for deeper stretch"}]}, {"id": "b1717171-0003-4000-8000-000000000001", "name": "Upper Body Flexibility", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1717171-0003-4000-8000-000000000001", "name": "Shoulder Stretch Series", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "45 sec each stretch", "notes": "Cross-body, overhead triceps, behind back"}, {"id": "c1717171-0003-4000-8000-000000000002", "name": "Chest Opener", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Hands clasped behind back"}, {"id": "c1717171-0003-4000-8000-000000000003", "name": "Lat Stretch", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "60 sec each side", "notes": "Arm overhead, lean away"}]}, {"id": "b1717171-0004-4000-8000-000000000001", "name": "Spine & Hips", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c1717171-0004-4000-8000-000000000001", "name": "Supine Twist", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Keep both shoulders down"}, {"id": "c1717171-0004-4000-8000-000000000002", "name": "Happy Baby", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "90 sec", "notes": "Pull feet toward armpits"}, {"id": "c1717171-0004-4000-8000-000000000003", "name": "Reclined Butterfly", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Let hips open naturally"}]}]'::jsonb,
    '{mobility,flexibility,intermediate,deep-stretch,splits,progress}',
    'mobility_flexibility_builder.md',
    NOW()
);

-- 24. Movement Prep Flow
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000024',
    'Movement Prep Flow',
    'Athletic preparation routine combining activation and mobility. 15 minutes before training.',
    'mobility',
    'intermediate',
    15,
    '[{"id": "b1818181-0001-4000-8000-000000000001", "name": "Tissue Prep", "block_type": "recovery", "sequence": 1, "exercises": [{"id": "c1818181-0001-4000-8000-000000000001", "name": "Foam Roll Quads", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "30 sec each leg", "notes": "Quick passes"}, {"id": "c1818181-0001-4000-8000-000000000002", "name": "Foam Roll T-Spine", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "30 sec", "notes": "Extension focus"}, {"id": "c1818181-0001-4000-8000-000000000003", "name": "Lacrosse Ball Glutes", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "30 sec each side", "notes": "Hit major trigger points"}]}, {"id": "b1818181-0002-4000-8000-000000000001", "name": "Mobility", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "c1818181-0002-4000-8000-000000000001", "name": "World''s Greatest Stretch", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 each side", "notes": "Full complex"}, {"id": "c1818181-0002-4000-8000-000000000002", "name": "Deep Squat Hold", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "60 sec", "notes": "Push knees out"}, {"id": "c1818181-0002-4000-8000-000000000003", "name": "Wall Ankle Mobilization", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 each ankle", "notes": "Knee to wall"}]}, {"id": "b1818181-0003-4000-8000-000000000001", "name": "Activation", "block_type": "prehab", "sequence": 3, "exercises": [{"id": "c1818181-0003-4000-8000-000000000001", "name": "Glute Bridges", "sequence": 1, "prescribed_sets": 2, "prescribed_reps": "10 reps", "notes": "Squeeze at top"}, {"id": "c1818181-0003-4000-8000-000000000002", "name": "Dead Bugs", "sequence": 2, "prescribed_sets": 2, "prescribed_reps": "8 each side", "notes": "Core stability"}, {"id": "c1818181-0003-4000-8000-000000000003", "name": "Band Pull-Aparts", "sequence": 3, "prescribed_sets": 2, "prescribed_reps": "15 reps", "notes": "Shoulder activation"}, {"id": "c1818181-0003-4000-8000-000000000004", "name": "Bird Dogs", "sequence": 4, "prescribed_sets": 2, "prescribed_reps": "8 each side", "notes": "Opposite arm/leg"}]}]'::jsonb,
    '{mobility,warmup,athletic,intermediate,activation,movement-prep}',
    'mobility_movement_prep.md',
    NOW()
);

-- 25. Recovery Day Protocol
INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    'a1b2c3d4-1111-4000-8000-000000000025',
    'Recovery Day Protocol',
    'Complete recovery routine combining foam rolling, stretching, and relaxation. 40 minutes of restoration.',
    'mobility',
    'beginner',
    40,
    '[{"id": "b1919191-0001-4000-8000-000000000001", "name": "Myofascial Release", "block_type": "recovery", "sequence": 1, "exercises": [{"id": "c1919191-0001-4000-8000-000000000001", "name": "Foam Roll Full Body", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 min", "notes": "Calves, quads, hamstrings, glutes, back, lats"}, {"id": "c1919191-0001-4000-8000-000000000002", "name": "Lacrosse Ball Trouble Spots", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Focus on areas of tension"}]}, {"id": "b1919191-0002-4000-8000-000000000001", "name": "Gentle Movement", "block_type": "dynamic_stretch", "sequence": 2, "exercises": [{"id": "c1919191-0002-4000-8000-000000000001", "name": "Cat-Cow", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "10 cycles", "notes": "Slow, mindful movement"}, {"id": "c1919191-0002-4000-8000-000000000002", "name": "Thread the Needle", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "8 each side", "notes": "Thoracic rotation"}, {"id": "c1919191-0002-4000-8000-000000000003", "name": "Hip Circles", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "10 each direction", "notes": "On all fours"}]}, {"id": "b1919191-0003-4000-8000-000000000001", "name": "Deep Stretching", "block_type": "recovery", "sequence": 3, "exercises": [{"id": "c1919191-0003-4000-8000-000000000001", "name": "Pigeon Pose", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "2 min each side", "notes": "Option to fold forward"}, {"id": "c1919191-0003-4000-8000-000000000002", "name": "Seated Forward Fold", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Relax into the stretch"}, {"id": "c1919191-0003-4000-8000-000000000003", "name": "Supine Twist", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "90 sec each side", "notes": "Let gravity work"}, {"id": "c1919191-0003-4000-8000-000000000004", "name": "Child''s Pose", "sequence": 4, "prescribed_sets": 1, "prescribed_reps": "2 min", "notes": "Wide knees, arms extended"}]}, {"id": "b1919191-0004-4000-8000-000000000001", "name": "Relaxation", "block_type": "recovery", "sequence": 4, "exercises": [{"id": "c1919191-0004-4000-8000-000000000001", "name": "Legs Up Wall", "sequence": 1, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Promotes circulation and recovery"}, {"id": "c1919191-0004-4000-8000-000000000002", "name": "Diaphragmatic Breathing", "sequence": 2, "prescribed_sets": 1, "prescribed_reps": "3 min", "notes": "4-7-8 pattern"}, {"id": "c1919191-0004-4000-8000-000000000003", "name": "Savasana", "sequence": 3, "prescribed_sets": 1, "prescribed_reps": "5 min", "notes": "Complete body scan relaxation"}]}]'::jsonb,
    '{mobility,recovery,rest-day,beginner,foam-rolling,stretching,relaxation}',
    'mobility_recovery_day.md',
    NOW()
);

COMMIT;
