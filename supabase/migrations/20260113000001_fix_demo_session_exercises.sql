-- BUILD 174 FIX: Add equipment exercises to demo patient's FIRST session
-- The demo patient's Session 1 is: 00000000-0000-0000-0000-000000000401
-- This is the session that loads automatically on login

-- First, clear any existing exercises from Session 1 to avoid duplicates
DELETE FROM session_exercises
WHERE session_id = '00000000-0000-0000-0000-000000000401';

-- Add equipment exercises to Session 1 (the session that auto-loads for demo patient)
INSERT INTO session_exercises (id, session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
VALUES
  -- Barbell Squat - 4x8 @ 135lbs
  ('00000000-0000-0000-0000-000000000a01', '00000000-0000-0000-0000-000000000401',
   (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat' LIMIT 1),
   1, 4, '8', 135, 'lbs', 120, 'Focus on depth and control'),

  -- Barbell Bench Press - 4x8 @ 95lbs
  ('00000000-0000-0000-0000-000000000a02', '00000000-0000-0000-0000-000000000401',
   (SELECT id FROM exercise_templates WHERE name = 'Barbell Bench Press' LIMIT 1),
   2, 4, '8', 95, 'lbs', 120, 'Controlled descent, explosive push'),

  -- Barbell Row - 4x10 @ 95lbs
  ('00000000-0000-0000-0000-000000000a03', '00000000-0000-0000-0000-000000000401',
   (SELECT id FROM exercise_templates WHERE name = 'Barbell Row' LIMIT 1),
   3, 4, '10', 95, 'lbs', 90, 'Squeeze at top'),

  -- Barbell Deadlift - 3x6 @ 185lbs
  ('00000000-0000-0000-0000-000000000a04', '00000000-0000-0000-0000-000000000401',
   (SELECT id FROM exercise_templates WHERE name = 'Barbell Deadlift' LIMIT 1),
   4, 3, '6', 185, 'lbs', 150, 'Maintain neutral spine'),

  -- Barbell OHP - 3x10 @ 65lbs
  ('00000000-0000-0000-0000-000000000a05', '00000000-0000-0000-0000-000000000401',
   (SELECT id FROM exercise_templates WHERE name = 'Barbell Overhead Press' LIMIT 1),
   5, 3, '10', 65, 'lbs', 90, 'Full lockout at top')
ON CONFLICT (id) DO UPDATE SET
  exercise_template_id = EXCLUDED.exercise_template_id,
  prescribed_sets = EXCLUDED.prescribed_sets,
  prescribed_reps = EXCLUDED.prescribed_reps,
  prescribed_load = EXCLUDED.prescribed_load;

-- Verify the exercises were added
DO $$
DECLARE
  exercise_count INT;
BEGIN
  SELECT COUNT(*) INTO exercise_count
  FROM session_exercises
  WHERE session_id = '00000000-0000-0000-0000-000000000401';

  RAISE NOTICE 'BUILD 174 FIX: Added % exercises to demo Session 1', exercise_count;
END $$;
