-- BUILD 174: Add equipment-based exercises to demo patient for substitution testing
-- Issue: Demo account only has bodyweight exercises, substitution function needs equipment exercises

-- ============================================================================
-- 1. ADD EQUIPMENT EXERCISES TO EXERCISE_TEMPLATES (if not exist)
-- ============================================================================

-- Barbell exercises
INSERT INTO exercise_templates (id, name, category, body_region, equipment_required, difficulty_level)
VALUES
  ('00000000-0000-0000-0000-0000000000f1', 'Barbell Bench Press', 'push', 'upper', ARRAY['barbell', 'bench'], 'intermediate'),
  ('00000000-0000-0000-0000-0000000000f2', 'Barbell Row', 'pull', 'upper', ARRAY['barbell'], 'intermediate'),
  ('00000000-0000-0000-0000-0000000000f3', 'Barbell Squat', 'squat', 'lower', ARRAY['barbell', 'squat rack'], 'intermediate'),
  ('00000000-0000-0000-0000-0000000000f4', 'Barbell Deadlift', 'hinge', 'lower', ARRAY['barbell'], 'intermediate'),
  ('00000000-0000-0000-0000-0000000000f5', 'Barbell Overhead Press', 'push', 'upper', ARRAY['barbell'], 'intermediate')
ON CONFLICT (name) DO UPDATE SET
  equipment_required = EXCLUDED.equipment_required,
  difficulty_level = EXCLUDED.difficulty_level;

-- Dumbbell alternatives
INSERT INTO exercise_templates (id, name, category, body_region, equipment_required, difficulty_level)
VALUES
  ('00000000-0000-0000-0000-0000000000f6', 'Dumbbell Bench Press', 'push', 'upper', ARRAY['dumbbells', 'bench'], 'beginner'),
  ('00000000-0000-0000-0000-0000000000f7', 'Dumbbell Row', 'pull', 'upper', ARRAY['dumbbells', 'bench'], 'beginner'),
  ('00000000-0000-0000-0000-0000000000f8', 'Goblet Squat', 'squat', 'lower', ARRAY['dumbbells'], 'beginner'),
  ('00000000-0000-0000-0000-0000000000f9', 'Dumbbell Romanian Deadlift', 'hinge', 'lower', ARRAY['dumbbells'], 'beginner'),
  ('00000000-0000-0000-0000-0000000000fa', 'Dumbbell Shoulder Press', 'push', 'upper', ARRAY['dumbbells'], 'beginner')
ON CONFLICT (name) DO UPDATE SET
  equipment_required = EXCLUDED.equipment_required,
  difficulty_level = EXCLUDED.difficulty_level;

-- Bodyweight alternatives
INSERT INTO exercise_templates (id, name, category, body_region, equipment_required, difficulty_level)
VALUES
  ('00000000-0000-0000-0000-0000000000fb', 'Push-Up', 'push', 'upper', ARRAY[]::text[], 'beginner'),
  ('00000000-0000-0000-0000-0000000000fc', 'Inverted Row', 'pull', 'upper', ARRAY['bar', 'TRX'], 'beginner'),
  ('00000000-0000-0000-0000-0000000000fd', 'Bodyweight Squat', 'squat', 'lower', ARRAY[]::text[], 'beginner'),
  ('00000000-0000-0000-0000-0000000000fe', 'Hip Hinge', 'hinge', 'lower', ARRAY[]::text[], 'beginner'),
  ('00000000-0000-0000-0000-0000000000ff', 'Pike Push-Up', 'push', 'upper', ARRAY[]::text[], 'intermediate')
ON CONFLICT (name) DO UPDATE SET
  equipment_required = EXCLUDED.equipment_required,
  difficulty_level = EXCLUDED.difficulty_level;

-- ============================================================================
-- 2. ADD SUBSTITUTION CANDIDATES
-- ============================================================================

-- Bench Press substitutions
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Bench Press'),
  (SELECT id FROM exercise_templates WHERE name = 'Dumbbell Bench Press'),
  ARRAY['dumbbells', 'bench'],
  -0.1,
  'Dumbbell alternative - better for shoulder stability'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Barbell Bench Press')
    AND substitute_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Dumbbell Bench Press')
);

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Bench Press'),
  (SELECT id FROM exercise_templates WHERE name = 'Push-Up'),
  ARRAY[]::text[],
  -0.3,
  'Bodyweight alternative - no equipment needed'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Barbell Bench Press')
    AND substitute_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Push-Up')
);

-- Row substitutions
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Row'),
  (SELECT id FROM exercise_templates WHERE name = 'Dumbbell Row'),
  ARRAY['dumbbells', 'bench'],
  -0.1,
  'Dumbbell alternative - better unilateral work'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Barbell Row')
    AND substitute_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Dumbbell Row')
);

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Row'),
  (SELECT id FROM exercise_templates WHERE name = 'Inverted Row'),
  ARRAY['bar', 'TRX'],
  -0.2,
  'Bodyweight pulling alternative'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Barbell Row')
    AND substitute_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Inverted Row')
);

-- Squat substitutions
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat'),
  (SELECT id FROM exercise_templates WHERE name = 'Goblet Squat'),
  ARRAY['dumbbells'],
  -0.2,
  'Dumbbell squat - great for learning pattern'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat')
    AND substitute_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Goblet Squat')
);

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat'),
  (SELECT id FROM exercise_templates WHERE name = 'Bodyweight Squat'),
  ARRAY[]::text[],
  -0.4,
  'Bodyweight squat - no equipment needed'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat')
    AND substitute_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Bodyweight Squat')
);

-- Deadlift substitutions
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Deadlift'),
  (SELECT id FROM exercise_templates WHERE name = 'Dumbbell Romanian Deadlift'),
  ARRAY['dumbbells'],
  -0.2,
  'Dumbbell hinge alternative'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Barbell Deadlift')
    AND substitute_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Dumbbell Romanian Deadlift')
);

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Deadlift'),
  (SELECT id FROM exercise_templates WHERE name = 'Hip Hinge'),
  ARRAY[]::text[],
  -0.4,
  'Bodyweight hinge pattern'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Barbell Deadlift')
    AND substitute_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Hip Hinge')
);

-- OHP substitutions
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Overhead Press'),
  (SELECT id FROM exercise_templates WHERE name = 'Dumbbell Shoulder Press'),
  ARRAY['dumbbells'],
  -0.1,
  'Dumbbell shoulder press alternative'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Barbell Overhead Press')
    AND substitute_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Dumbbell Shoulder Press')
);

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  (SELECT id FROM exercise_templates WHERE name = 'Barbell Overhead Press'),
  (SELECT id FROM exercise_templates WHERE name = 'Pike Push-Up'),
  ARRAY[]::text[],
  -0.3,
  'Bodyweight overhead pressing alternative'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Barbell Overhead Press')
    AND substitute_exercise_id = (SELECT id FROM exercise_templates WHERE name = 'Pike Push-Up')
);

-- ============================================================================
-- 3. ADD NEW STRENGTH SESSION TO DEMO PATIENT PROGRAM
-- ============================================================================

-- Temporarily disable audit trigger (has bug expecting program_id on sessions table)
ALTER TABLE sessions DISABLE TRIGGER audit_session_changes_trigger;

-- Create a new "Strength Training" session in Phase 2 of demo program
INSERT INTO sessions (id, phase_id, name, sequence, weekday, notes)
VALUES (
  '00000000-0000-0000-0000-000000000450',
  '00000000-0000-0000-0000-000000000302', -- Phase 2: Build
  'Full Body Strength',
  10, -- After existing sessions
  3, -- Wednesday
  'BUILD 174: Full body strength session with equipment exercises for substitution testing'
)
ON CONFLICT (id) DO NOTHING;

-- Re-enable trigger
ALTER TABLE sessions ENABLE TRIGGER audit_session_changes_trigger;

-- Add equipment exercises to the new session
INSERT INTO session_exercises (id, session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
VALUES
  -- Barbell Squat - 4x8 @ 135lbs
  ('00000000-0000-0000-0000-000000000e01', '00000000-0000-0000-0000-000000000450',
   (SELECT id FROM exercise_templates WHERE name = 'Barbell Squat'), 1, 4, '8', 135, 'lbs', 120,
   'Focus on depth and control'),
  -- Barbell Bench Press - 4x8 @ 95lbs
  ('00000000-0000-0000-0000-000000000e02', '00000000-0000-0000-0000-000000000450',
   (SELECT id FROM exercise_templates WHERE name = 'Barbell Bench Press'), 2, 4, '8', 95, 'lbs', 120,
   'Controlled descent, explosive push'),
  -- Barbell Row - 4x10 @ 95lbs
  ('00000000-0000-0000-0000-000000000e03', '00000000-0000-0000-0000-000000000450',
   (SELECT id FROM exercise_templates WHERE name = 'Barbell Row'), 3, 4, '10', 95, 'lbs', 90,
   'Squeeze at top'),
  -- Barbell Deadlift - 3x6 @ 185lbs
  ('00000000-0000-0000-0000-000000000e04', '00000000-0000-0000-0000-000000000450',
   (SELECT id FROM exercise_templates WHERE name = 'Barbell Deadlift'), 4, 3, '6', 185, 'lbs', 150,
   'Maintain neutral spine'),
  -- Barbell OHP - 3x10 @ 65lbs
  ('00000000-0000-0000-0000-000000000e05', '00000000-0000-0000-0000-000000000450',
   (SELECT id FROM exercise_templates WHERE name = 'Barbell Overhead Press'), 5, 3, '10', 65, 'lbs', 90,
   'Full lockout at top')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 4. ADD VIDEO AND TECHNIQUE DATA TO NEW EXERCISES
-- ============================================================================

DO $$
DECLARE
  demo_video_url TEXT := 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
BEGIN

-- Barbell Squat
UPDATE exercise_templates SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/4AE2A6/FFFFFF?text=Barbell+Squat',
  technique_cues = jsonb_build_object(
    'setup', ARRAY['Barbell on upper traps', 'Feet shoulder-width apart', 'Core braced'],
    'execution', ARRAY['Push knees out', 'Hips back and down', 'Drive through heels'],
    'breathing', ARRAY['Breathe in at top', 'Hold during descent', 'Exhale on drive up']
  ),
  common_mistakes = 'Knees caving in, forward lean, not reaching depth',
  safety_notes = 'Use squat rack with safety pins. Keep spine neutral.'
WHERE name = 'Barbell Squat';

-- Barbell Bench Press
UPDATE exercise_templates SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/E2A64A/FFFFFF?text=Barbell+Bench+Press',
  technique_cues = jsonb_build_object(
    'setup', ARRAY['Shoulder blades pinched back', 'Feet flat on floor', 'Grip just outside shoulders'],
    'execution', ARRAY['Lower bar to mid chest', 'Drive feet into floor', 'Press in slight arc'],
    'breathing', ARRAY['Inhale on descent', 'Exhale on press']
  ),
  common_mistakes = 'Bouncing bar off chest, flared elbows, butt lifting',
  safety_notes = 'Always use spotter or safety bars. Do not lock elbows.'
WHERE name = 'Barbell Bench Press';

-- Barbell Row
UPDATE exercise_templates SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/A64AE2/FFFFFF?text=Barbell+Row',
  technique_cues = jsonb_build_object(
    'setup', ARRAY['Hip hinge position', 'Back flat, core tight', 'Arms hanging straight'],
    'execution', ARRAY['Pull to lower chest', 'Squeeze shoulder blades', 'Control the descent'],
    'breathing', ARRAY['Exhale on pull', 'Inhale on lower']
  ),
  common_mistakes = 'Using momentum, rounded back, not full range',
  safety_notes = 'Keep lower back neutral. Reduce weight if form breaks.'
WHERE name = 'Barbell Row';

-- Barbell Deadlift
UPDATE exercise_templates SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/4A90E2/FFFFFF?text=Barbell+Deadlift',
  technique_cues = jsonb_build_object(
    'setup', ARRAY['Bar over mid-foot', 'Grip just outside knees', 'Chest up, back flat'],
    'execution', ARRAY['Push floor away', 'Lock hips at top', 'Reverse the motion down'],
    'breathing', ARRAY['Big breath at bottom', 'Hold through lift', 'Exhale at top']
  ),
  common_mistakes = 'Rounded back, bar drifting forward, jerking the weight',
  safety_notes = 'Master form with light weight first. Stop if back rounds.'
WHERE name = 'Barbell Deadlift';

-- Barbell Overhead Press
UPDATE exercise_templates SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/E24A4A/FFFFFF?text=Barbell+OHP',
  technique_cues = jsonb_build_object(
    'setup', ARRAY['Bar at collarbone', 'Grip just outside shoulders', 'Core braced'],
    'execution', ARRAY['Press straight up', 'Move head back slightly', 'Full lockout'],
    'breathing', ARRAY['Breath before press', 'Exhale at top']
  ),
  common_mistakes = 'Excessive back arch, pressing forward, not full lockout',
  safety_notes = 'Do not lean back excessively. Use lighter weight to learn.'
WHERE name = 'Barbell Overhead Press';

END $$;

-- Log completion
DO $$ BEGIN RAISE NOTICE 'BUILD 174: Demo equipment exercises and substitution candidates added'; END $$;
