-- BUILD 325: Seed Demo Session Exercises
-- Purpose: Add exercises to demo patient's Session 1 (Week 1 - Session 1)
-- Demo Patient: John Brebbia (00000000-0000-0000-0000-000000000001)
-- Session ID: 00000000-0000-0000-0000-000000000401 (Phase 1: Foundation)
--
-- Phase 1 Focus: Build base strength, mobility, and tissue capacity. No throwing.
-- Exercise selection appropriate for foundation phase of return-to-throw program.

-- ============================================================================
-- 1. ENSURE REQUIRED EXERCISE TEMPLATES EXIST
-- ============================================================================

-- Create templates if they don't exist (idempotent inserts)
INSERT INTO exercise_templates (id, name, category, body_region, equipment_type, difficulty_level, technique_cues, common_mistakes, safety_notes)
VALUES
  ('00000000-0000-0000-0000-100000000001', 'Foam Roll Thoracic Extension', 'mobility', 'upper', 'equipment', 'beginner',
   '{"setup": ["Foam roller at mid-back", "Support head with hands", "Knees bent"], "execution": ["Extend back over roller", "Hold stretch", "Roll slightly and repeat"], "breathing": ["Breathe deeply into stretch"]}'::jsonb,
   'Rolling too fast, going onto lower back', 'Excellent for upper back mobility. Stay on mid-back only.'),

  ('00000000-0000-0000-0000-100000000002', 'Band Pull-Apart', 'mobility', 'upper', 'bands', 'beginner',
   '{"setup": ["Hold band at shoulder width", "Arms extended forward"], "execution": ["Pull band apart to chest", "Squeeze shoulder blades", "Control return"], "breathing": ["Exhale pulling", "Inhale returning"]}'::jsonb,
   'Arms drifting up or down, not squeezing shoulder blades', 'Excellent for shoulder health and warm-up.'),

  ('00000000-0000-0000-0000-100000000003', 'Goblet Squat', 'squat', 'lower', 'dumbbell', 'beginner',
   '{"setup": ["Hold dumbbell at chest", "Feet shoulder-width", "Toes slightly out"], "execution": ["Squat down between legs", "Keep chest up", "Drive through heels"], "breathing": ["Inhale descending", "Exhale driving up"]}'::jsonb,
   'Heels lifting, not going deep enough, leaning forward', 'Excellent teaching tool for squat pattern.'),

  ('00000000-0000-0000-0000-100000000004', 'Romanian Deadlift (RDL)', 'hinge', 'lower', 'dumbbell', 'intermediate',
   '{"setup": ["Start standing with weights at hips", "Feet hip-width", "Slight knee bend"], "execution": ["Push hips back", "Weights slide down thighs", "Feel hamstring stretch", "Keep back flat"], "breathing": ["Breathe in during descent", "Exhale driving up"]}'::jsonb,
   'Squatting instead of hinging, rounding back', 'Focus on hip hinge pattern. Keep weight moderate.'),

  ('00000000-0000-0000-0000-100000000005', 'Front Plank', 'anti_extension', 'core', 'bodyweight', 'beginner',
   '{"setup": ["Forearms on ground", "Elbows under shoulders", "Body in straight line"], "execution": ["Squeeze glutes", "Brace core hard", "Hold position"], "breathing": ["Breathe normally", "Maintain core tension"]}'::jsonb,
   'Hips sagging toward ground, hips too high, holding breath', 'Start with shorter holds (20-30 seconds) and build up.'),

  ('00000000-0000-0000-0000-100000000006', 'Dead Bug', 'anti_extension', 'core', 'bodyweight', 'beginner',
   '{"setup": ["Lie on back", "Arms extended to ceiling", "Knees bent 90 degrees over hips"], "execution": ["Lower opposite arm and leg", "Keep lower back pressed to floor", "Return and switch sides"], "breathing": ["Exhale as limbs extend", "Inhale returning"]}'::jsonb,
   'Lower back arching off floor, moving too fast', 'Great core stability exercise for athletes.')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 2. CLEAR EXISTING EXERCISES FROM SESSION 1
-- ============================================================================

DELETE FROM session_exercises
WHERE session_id = '00000000-0000-0000-0000-000000000401';

-- ============================================================================
-- 3. ADD FOUNDATION PHASE EXERCISES TO SESSION 1
-- ============================================================================
-- Note: Using COALESCE with subquery to handle cases where template might have
-- been inserted with uuid_generate_v4() instead of our fixed ID

INSERT INTO session_exercises (
  id,
  session_id,
  exercise_template_id,
  sequence,
  prescribed_sets,
  prescribed_reps,
  prescribed_load,
  load_unit,
  rest_period_seconds,
  notes
)
VALUES
  -- 1. Foam Rolling (Warmup) - 2 minutes
  ('00000000-0000-0000-0000-200000000001',
   '00000000-0000-0000-0000-000000000401',
   COALESCE(
     (SELECT id FROM exercise_templates WHERE name = 'Foam Roll Thoracic Extension' LIMIT 1),
     '00000000-0000-0000-0000-100000000001'
   ),
   1, 2, '60 seconds', NULL, NULL, 30,
   'Warmup: Focus on thoracic mobility. Roll slowly.'),

  -- 2. Band Pull-Aparts (Shoulder Activation) - 3x15
  ('00000000-0000-0000-0000-200000000002',
   '00000000-0000-0000-0000-000000000401',
   COALESCE(
     (SELECT id FROM exercise_templates WHERE name = 'Band Pull-Apart' LIMIT 1),
     '00000000-0000-0000-0000-100000000002'
   ),
   2, 3, '15', NULL, NULL, 45,
   'Shoulder activation. Control the movement, squeeze at end.'),

  -- 3. Goblet Squat (Foundation Strength) - 3x10 @ 25lbs
  ('00000000-0000-0000-0000-200000000003',
   '00000000-0000-0000-0000-000000000401',
   COALESCE(
     (SELECT id FROM exercise_templates WHERE name = 'Goblet Squat' LIMIT 1),
     '00000000-0000-0000-0000-100000000003'
   ),
   3, 3, '10', 25, 'lbs', 90,
   'Foundation squat pattern. Focus on depth and control.'),

  -- 4. Romanian Deadlift (Posterior Chain) - 3x10 @ 20lbs each hand
  ('00000000-0000-0000-0000-200000000004',
   '00000000-0000-0000-0000-000000000401',
   COALESCE(
     (SELECT id FROM exercise_templates WHERE name = 'Romanian Deadlift (RDL)' LIMIT 1),
     '00000000-0000-0000-0000-100000000004'
   ),
   4, 3, '10', 20, 'lbs', 90,
   'Dumbbell RDL. Keep back flat, feel the hamstring stretch.'),

  -- 5. Front Plank (Core Stability) - 3x30 seconds
  ('00000000-0000-0000-0000-200000000005',
   '00000000-0000-0000-0000-000000000401',
   COALESCE(
     (SELECT id FROM exercise_templates WHERE name = 'Front Plank' LIMIT 1),
     '00000000-0000-0000-0000-100000000005'
   ),
   5, 3, '30 seconds', NULL, NULL, 60,
   'Core stability. Maintain neutral spine throughout.'),

  -- 6. Dead Bug (Core Control) - 3x10 each side
  ('00000000-0000-0000-0000-200000000006',
   '00000000-0000-0000-0000-000000000401',
   COALESCE(
     (SELECT id FROM exercise_templates WHERE name = 'Dead Bug' LIMIT 1),
     '00000000-0000-0000-0000-100000000006'
   ),
   6, 3, '10 each side', NULL, NULL, 60,
   'Core control exercise. Keep lower back pressed to floor.')

ON CONFLICT (id) DO UPDATE SET
  exercise_template_id = EXCLUDED.exercise_template_id,
  sequence = EXCLUDED.sequence,
  prescribed_sets = EXCLUDED.prescribed_sets,
  prescribed_reps = EXCLUDED.prescribed_reps,
  prescribed_load = EXCLUDED.prescribed_load,
  load_unit = EXCLUDED.load_unit,
  rest_period_seconds = EXCLUDED.rest_period_seconds,
  notes = EXCLUDED.notes;

-- ============================================================================
-- 4. VERIFICATION
-- ============================================================================

DO $$
DECLARE
  exercise_count INT;
  session_name TEXT;
BEGIN
  -- Get session name
  SELECT name INTO session_name
  FROM sessions
  WHERE id = '00000000-0000-0000-0000-000000000401';

  -- Count exercises added
  SELECT COUNT(*) INTO exercise_count
  FROM session_exercises
  WHERE session_id = '00000000-0000-0000-0000-000000000401';

  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'BUILD 325: Demo Session Exercises Seeded';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Session: % (Phase 1: Foundation)', session_name;
  RAISE NOTICE 'Exercises added: %', exercise_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Exercise lineup:';
  RAISE NOTICE '  1. Foam Roll Thoracic Extension (Warmup)';
  RAISE NOTICE '  2. Band Pull-Apart (Activation)';
  RAISE NOTICE '  3. Goblet Squat (Lower Body)';
  RAISE NOTICE '  4. Romanian Deadlift (Posterior Chain)';
  RAISE NOTICE '  5. Front Plank (Core Stability)';
  RAISE NOTICE '  6. Dead Bug (Core Control)';
  RAISE NOTICE '============================================';

  IF exercise_count < 6 THEN
    RAISE WARNING 'Expected 6 exercises, got %. Some inserts may have failed.', exercise_count;
  END IF;
END $$;
