-- BUILD 138 - Seed Test Data
-- Temporarily allow NULL user_id in audit_logs for system operations

-- Make user_id nullable temporarily
ALTER TABLE audit_logs ALTER COLUMN user_id DROP NOT NULL;

-- Disable audit triggers on tables we're inserting into (USER triggers only, not system)
ALTER TABLE programs DISABLE TRIGGER USER;
ALTER TABLE phases DISABLE TRIGGER USER;
ALTER TABLE sessions DISABLE TRIGGER USER;

-- Insert patient (if doesn't exist)
INSERT INTO patients (id, first_name, last_name)
VALUES ('00000000-0000-0000-0000-000000000001', 'Test', 'Patient')
ON CONFLICT (id) DO NOTHING;

-- Insert exercise templates
INSERT INTO exercise_templates (id, name, equipment_required)
VALUES
  ('00000000-0000-0000-0000-0000000000e1', 'Barbell Bench Press', ARRAY['barbell', 'bench']),
  ('00000000-0000-0000-0000-0000000000e2', 'Barbell Squat', ARRAY['barbell']),
  ('00000000-0000-0000-0000-0000000000e3', 'Pull-ups', ARRAY['pull-up bar']),
  ('00000000-0000-0000-0000-0000000000e4', 'Dumbbell Bench Press', ARRAY['dumbbells', 'bench'])
ON CONFLICT (name) DO UPDATE SET equipment_required = EXCLUDED.equipment_required;

-- Insert program
INSERT INTO programs (id, patient_id, name)
VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'BUILD 138 Test Program')
ON CONFLICT (id) DO NOTHING;

-- Insert phase
INSERT INTO phases (id, program_id, name, duration_weeks, sequence)
VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Test Phase', 4, 1)
ON CONFLICT (id) DO NOTHING;

-- Insert session
INSERT INTO sessions (id, phase_id, name, sequence)
VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Test Session with Equipment', 1)
ON CONFLICT (id) DO NOTHING;

-- Insert session exercises (using subqueries to find exercise IDs by name)
INSERT INTO session_exercises (id, session_id, exercise_template_id, sequence, target_sets, target_reps, target_load, target_rpe, rest_period_seconds)
SELECT '00000000-0000-0000-0000-0000000000e5', '00000000-0000-0000-0000-000000000002', id, 1, 4, 8, 225, 8.0, 180
FROM exercise_templates WHERE name = 'Barbell Bench Press'
ON CONFLICT (id) DO NOTHING;

INSERT INTO session_exercises (id, session_id, exercise_template_id, sequence, target_sets, target_reps, target_load, target_rpe, rest_period_seconds)
SELECT '00000000-0000-0000-0000-0000000000e6', '00000000-0000-0000-0000-000000000002', id, 2, 4, 6, 315, 8.5, 240
FROM exercise_templates WHERE name = 'Barbell Squat'
ON CONFLICT (id) DO NOTHING;

INSERT INTO session_exercises (id, session_id, exercise_template_id, sequence, target_sets, target_reps, target_load, target_rpe, rest_period_seconds)
SELECT '00000000-0000-0000-0000-0000000000e7', '00000000-0000-0000-0000-000000000002', id, 3, 3, 10, 0, 7.5, 120
FROM exercise_templates WHERE name = 'Pull-ups'
ON CONFLICT (id) DO NOTHING;

-- Insert substitution candidate (using subqueries to find exercise IDs by name)
INSERT INTO exercise_substitution_candidates (id, original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-000000000001',
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Bench Press'),
  (SELECT id FROM exercise_templates WHERE name = 'Dumbbell Bench Press'),
  ARRAY['dumbbells', 'bench'],
  0.0,
  'Similar horizontal press'
ON CONFLICT (id) DO NOTHING;

-- Re-enable triggers
ALTER TABLE programs ENABLE TRIGGER USER;
ALTER TABLE phases ENABLE TRIGGER USER;
ALTER TABLE sessions ENABLE TRIGGER USER;

-- Restore NOT NULL constraint
ALTER TABLE audit_logs ALTER COLUMN user_id SET NOT NULL;
