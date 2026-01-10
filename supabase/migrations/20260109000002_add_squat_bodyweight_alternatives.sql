-- Add bodyweight alternatives for Barbell Squat

-- Create bodyweight squat exercise templates
INSERT INTO exercise_templates (id, name, equipment_required)
VALUES
  ('00000000-0000-0000-0000-000000000013', 'Bodyweight Squat', ARRAY['none']),
  ('00000000-0000-0000-0000-000000000014', 'Bulgarian Split Squat', ARRAY['none']),
  ('00000000-0000-0000-0000-000000000015', 'Resistance Band Squat', ARRAY['resistance_band'])
ON CONFLICT (name) DO UPDATE SET equipment_required = EXCLUDED.equipment_required;

-- Barbell Squat → Bodyweight Squat
INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000013',
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat'),
  (SELECT id FROM exercise_templates WHERE name = 'Bodyweight Squat'),
  ARRAY['none'],
  -0.4,
  'Bodyweight squat alternative'
ON CONFLICT (id) DO NOTHING;

-- Barbell Squat → Bulgarian Split Squat (single leg, harder)
INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000014',
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat'),
  (SELECT id FROM exercise_templates WHERE name = 'Bulgarian Split Squat'),
  ARRAY['none'],
  -0.1,
  'Single-leg squat variation for bodyweight'
ON CONFLICT (id) DO NOTHING;

-- Barbell Squat → Resistance Band Squat
INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000015',
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat'),
  (SELECT id FROM exercise_templates WHERE name = 'Resistance Band Squat'),
  ARRAY['resistance_band'],
  -0.2,
  'Resistance band squat alternative'
ON CONFLICT (id) DO NOTHING;
