-- Add bodyweight/minimal equipment substitutions for BUILD 138 tests

-- Create bodyweight exercise templates if they don't exist
INSERT INTO exercise_templates (id, name, equipment_required)
VALUES
  ('00000000-0000-0000-0000-000000000010', 'Push-ups', ARRAY['none']),
  ('00000000-0000-0000-0000-000000000011', 'Bodyweight Rows', ARRAY['none']),
  ('00000000-0000-0000-0000-000000000012', 'Dumbbell Floor Press', ARRAY['dumbbells'])
ON CONFLICT (name) DO UPDATE SET equipment_required = EXCLUDED.equipment_required;

-- Add more flexible substitution candidates
-- Barbell Bench Press → Push-ups (bodyweight)
INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000010',
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Bench Press'),
  (SELECT id FROM exercise_templates WHERE name = 'Push-ups'),
  ARRAY['none'],
  -0.3,
  'Bodyweight alternative for horizontal press'
ON CONFLICT (id) DO NOTHING;

-- Barbell Bench Press → Dumbbell Floor Press (just dumbbells, no bench)
INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000011',
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Bench Press'),
  (SELECT id FROM exercise_templates WHERE name = 'Dumbbell Floor Press'),
  ARRAY['dumbbells'],
  -0.1,
  'Similar press with just dumbbells'
ON CONFLICT (id) DO NOTHING;

-- Pull-ups → Bodyweight Rows (bodyweight)
INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000012',
  (SELECT id FROM exercise_templates WHERE name = 'Pull-ups'),
  (SELECT id FROM exercise_templates WHERE name = 'Bodyweight Rows'),
  ARRAY['none'],
  -0.2,
  'Bodyweight pulling alternative'
ON CONFLICT (id) DO NOTHING;
