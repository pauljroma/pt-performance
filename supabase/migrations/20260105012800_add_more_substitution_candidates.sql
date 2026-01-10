-- Add more substitution candidates for BUILD 138 tests

-- Barbell Squat alternatives
INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000002',
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat'),
  (SELECT id FROM exercise_templates WHERE name = 'Goblet Squat'),
  ARRAY['dumbbells'],
  -0.1,
  'Similar squat pattern with dumbbell'
WHERE EXISTS (SELECT 1 FROM exercise_templates WHERE name = 'Goblet Squat')
ON CONFLICT (id) DO NOTHING;

-- Pull-ups alternatives
INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000003',
  (SELECT id FROM exercise_templates WHERE name = 'Pull-ups'),
  (SELECT id FROM exercise_templates WHERE name = 'Lat Pulldown'),
  ARRAY['cable machine'],
  -0.2,
  'Similar pulling pattern'
WHERE EXISTS (SELECT 1 FROM exercise_templates WHERE name = 'Lat Pulldown')
ON CONFLICT (id) DO NOTHING;

-- Create missing exercise templates if they don't exist
INSERT INTO exercise_templates (id, name, equipment_required)
VALUES
  ('00000000-0000-0000-0000-0000000000e8', 'Goblet Squat', ARRAY['dumbbells']),
  ('00000000-0000-0000-0000-0000000000e9', 'Lat Pulldown', ARRAY['cable machine'])
ON CONFLICT (name) DO UPDATE SET equipment_required = EXCLUDED.equipment_required;

-- Re-insert substitution candidates now that exercises exist
INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000002',
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat'),
  (SELECT id FROM exercise_templates WHERE name = 'Goblet Squat'),
  ARRAY['dumbbells'],
  -0.1,
  'Similar squat pattern with dumbbell'
ON CONFLICT (id) DO NOTHING;

INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000003',
  (SELECT id FROM exercise_templates WHERE name = 'Pull-ups'),
  (SELECT id FROM exercise_templates WHERE name = 'Lat Pulldown'),
  ARRAY['cable machine'],
  -0.2,
  'Similar pulling pattern'
ON CONFLICT (id) DO NOTHING;
