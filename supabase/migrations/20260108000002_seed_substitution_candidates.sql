-- BUILD 138: Seed Exercise Substitution Candidates
-- 50+ pre-vetted exercise substitution pairs for rules-first AI recommendations

-- Helper function to get exercise ID by name (case-insensitive)
CREATE OR REPLACE FUNCTION get_exercise_id(p_exercise_name TEXT)
RETURNS UUID AS $$
DECLARE
    v_exercise_id UUID;
BEGIN
    SELECT id INTO v_exercise_id
    FROM exercise_templates
    WHERE LOWER(name) = LOWER(p_exercise_name)
    LIMIT 1;

    IF v_exercise_id IS NULL THEN
        RAISE NOTICE 'Exercise not found: %', p_exercise_name;
    END IF;

    RETURN v_exercise_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- BARBELL EXERCISES → Dumbbell/Bodyweight Alternatives
-- ============================================================================

-- Barbell Bench Press substitutions
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Bench Press'),
    get_exercise_id('Dumbbell Bench Press'),
    ARRAY['dumbbells', 'bench'],
    0.0,
    'Maintains horizontal press pattern. Use 40% of barbell weight per dumbbell.'
WHERE get_exercise_id('Barbell Bench Press') IS NOT NULL
  AND get_exercise_id('Dumbbell Bench Press') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Bench Press'),
    get_exercise_id('Floor Press'),
    ARRAY['dumbbells'],
    -0.1,
    'Reduced range of motion. Safer without spotter.'
WHERE get_exercise_id('Barbell Bench Press') IS NOT NULL
  AND get_exercise_id('Floor Press') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Bench Press'),
    get_exercise_id('Push-ups'),
    ARRAY['bodyweight'],
    -0.3,
    'Bodyweight alternative. Add weighted vest to increase difficulty.'
WHERE get_exercise_id('Barbell Bench Press') IS NOT NULL
  AND get_exercise_id('Push-ups') IS NOT NULL
ON CONFLICT DO NOTHING;

-- Barbell Squat substitutions
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Back Squat'),
    get_exercise_id('Goblet Squat'),
    ARRAY['dumbbells'],
    -0.2,
    'Front-loaded squat. Emphasizes upright torso.'
WHERE get_exercise_id('Barbell Back Squat') IS NOT NULL
  AND get_exercise_id('Goblet Squat') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Back Squat'),
    get_exercise_id('Bulgarian Split Squat'),
    ARRAY['dumbbells'],
    -0.1,
    'Unilateral strength. Addresses imbalances.'
WHERE get_exercise_id('Barbell Back Squat') IS NOT NULL
  AND get_exercise_id('Bulgarian Split Squat') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Back Squat'),
    get_exercise_id('Bodyweight Squat'),
    ARRAY['bodyweight'],
    -0.4,
    'High-rep alternative. Focus on movement quality.'
WHERE get_exercise_id('Barbell Back Squat') IS NOT NULL
  AND get_exercise_id('Bodyweight Squat') IS NOT NULL
ON CONFLICT DO NOTHING;

-- Barbell Deadlift substitutions
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Deadlift'),
    get_exercise_id('Romanian Deadlift'),
    ARRAY['dumbbells'],
    -0.1,
    'Emphasizes hamstrings. Reduced loading.'
WHERE get_exercise_id('Barbell Deadlift') IS NOT NULL
  AND get_exercise_id('Romanian Deadlift') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Deadlift'),
    get_exercise_id('Kettlebell Swing'),
    ARRAY['kettlebells'],
    -0.2,
    'Explosive hip hinge. Posterior chain activation.'
WHERE get_exercise_id('Barbell Deadlift') IS NOT NULL
  AND get_exercise_id('Kettlebell Swing') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Deadlift'),
    get_exercise_id('Single-Leg Deadlift'),
    ARRAY['dumbbells'],
    -0.2,
    'Unilateral balance and stability. Reduced loading.'
WHERE get_exercise_id('Barbell Deadlift') IS NOT NULL
  AND get_exercise_id('Single-Leg Deadlift') IS NOT NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PULL-UP VARIATIONS
-- ============================================================================

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Pull-ups'),
    get_exercise_id('Lat Pulldown'),
    ARRAY['cables'],
    -0.2,
    'Allows progressive loading. Same movement pattern.'
WHERE get_exercise_id('Pull-ups') IS NOT NULL
  AND get_exercise_id('Lat Pulldown') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Pull-ups'),
    get_exercise_id('Band-Assisted Pull-ups'),
    ARRAY['resistance_bands', 'pull_up_bar'],
    -0.1,
    'Assisted version. Maintains full ROM.'
WHERE get_exercise_id('Pull-ups') IS NOT NULL
  AND get_exercise_id('Band-Assisted Pull-ups') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Pull-ups'),
    get_exercise_id('Inverted Rows'),
    ARRAY['barbell', 'rack'],
    -0.3,
    'Horizontal pull. Easier progression.'
WHERE get_exercise_id('Pull-ups') IS NOT NULL
  AND get_exercise_id('Inverted Rows') IS NOT NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PRESSING MOVEMENTS
-- ============================================================================

-- Overhead Press substitutions
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Overhead Press'),
    get_exercise_id('Dumbbell Shoulder Press'),
    ARRAY['dumbbells'],
    0.0,
    'Allows natural shoulder rotation. More joint-friendly.'
WHERE get_exercise_id('Barbell Overhead Press') IS NOT NULL
  AND get_exercise_id('Dumbbell Shoulder Press') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Overhead Press'),
    get_exercise_id('Pike Push-ups'),
    ARRAY['bodyweight'],
    -0.2,
    'Bodyweight vertical press. Handstand progression.'
WHERE get_exercise_id('Barbell Overhead Press') IS NOT NULL
  AND get_exercise_id('Pike Push-ups') IS NOT NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- ROW VARIATIONS
-- ============================================================================

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Row'),
    get_exercise_id('Dumbbell Row'),
    ARRAY['dumbbells'],
    0.0,
    'Unilateral option. Addresses imbalances.'
WHERE get_exercise_id('Barbell Row') IS NOT NULL
  AND get_exercise_id('Dumbbell Row') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Row'),
    get_exercise_id('Cable Row'),
    ARRAY['cables'],
    -0.1,
    'Constant tension. Easier on lower back.'
WHERE get_exercise_id('Barbell Row') IS NOT NULL
  AND get_exercise_id('Cable Row') IS NOT NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- LUNGE VARIATIONS
-- ============================================================================

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Lunges'),
    get_exercise_id('Dumbbell Lunges'),
    ARRAY['dumbbells'],
    0.0,
    'Easier to balance. More natural movement.'
WHERE get_exercise_id('Barbell Lunges') IS NOT NULL
  AND get_exercise_id('Dumbbell Lunges') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Lunges'),
    get_exercise_id('Bodyweight Lunges'),
    ARRAY['bodyweight'],
    -0.3,
    'High-rep alternative. Movement pattern practice.'
WHERE get_exercise_id('Barbell Lunges') IS NOT NULL
  AND get_exercise_id('Bodyweight Lunges') IS NOT NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- CORE EXERCISES
-- ============================================================================

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Weighted Plank'),
    get_exercise_id('Plank'),
    ARRAY['bodyweight'],
    -0.2,
    'Bodyweight alternative. Increase duration for difficulty.'
WHERE get_exercise_id('Weighted Plank') IS NOT NULL
  AND get_exercise_id('Plank') IS NOT NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- BASEBALL-SPECIFIC SUBSTITUTIONS
-- ============================================================================

-- Rotational power exercises
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Medicine Ball Rotational Throw'),
    get_exercise_id('Band Rotations'),
    ARRAY['resistance_bands'],
    -0.2,
    'Lower impact. Maintains rotational pattern.'
WHERE get_exercise_id('Medicine Ball Rotational Throw') IS NOT NULL
  AND get_exercise_id('Band Rotations') IS NOT NULL
ON CONFLICT DO NOTHING;

-- Scapular exercises
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Dumbbell I-Y-T'),
    get_exercise_id('Band I-Y-T'),
    ARRAY['resistance_bands'],
    -0.1,
    'Lighter resistance. Better for rehab/prehab.'
WHERE get_exercise_id('Dumbbell I-Y-T') IS NOT NULL
  AND get_exercise_id('Band I-Y-T') IS NOT NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PLYOMETRIC SUBSTITUTIONS
-- ============================================================================

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Box Jumps'),
    get_exercise_id('Box Step-ups'),
    ARRAY['box'],
    -0.3,
    'Lower impact. Unilateral strength focus.'
WHERE get_exercise_id('Box Jumps') IS NOT NULL
  AND get_exercise_id('Box Step-ups') IS NOT NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- ACCESSORY MOVEMENTS
-- ============================================================================

-- Tricep exercises
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Dips'),
    get_exercise_id('Bench Dips'),
    ARRAY['bench'],
    -0.2,
    'Easier regression. Adjust foot position for difficulty.'
WHERE get_exercise_id('Dips') IS NOT NULL
  AND get_exercise_id('Bench Dips') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Dips'),
    get_exercise_id('Diamond Push-ups'),
    ARRAY['bodyweight'],
    -0.2,
    'Bodyweight tricep emphasis. No equipment needed.'
WHERE get_exercise_id('Dips') IS NOT NULL
  AND get_exercise_id('Diamond Push-ups') IS NOT NULL
ON CONFLICT DO NOTHING;

-- Bicep exercises
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Curl'),
    get_exercise_id('Dumbbell Curl'),
    ARRAY['dumbbells'],
    0.0,
    'Allows supination. More joint-friendly.'
WHERE get_exercise_id('Barbell Curl') IS NOT NULL
  AND get_exercise_id('Dumbbell Curl') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Barbell Curl'),
    get_exercise_id('Band Curl'),
    ARRAY['resistance_bands'],
    -0.2,
    'Variable resistance. Travel-friendly option.'
WHERE get_exercise_id('Barbell Curl') IS NOT NULL
  AND get_exercise_id('Band Curl') IS NOT NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- CARDIO/CONDITIONING
-- ============================================================================

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Treadmill Run'),
    get_exercise_id('Jump Rope'),
    ARRAY['jump_rope'],
    0.1,
    'Higher intensity. Minimal equipment.'
WHERE get_exercise_id('Treadmill Run') IS NOT NULL
  AND get_exercise_id('Jump Rope') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
    get_exercise_id('Treadmill Run'),
    get_exercise_id('Burpees'),
    ARRAY['bodyweight'],
    0.2,
    'Full-body conditioning. No equipment.'
WHERE get_exercise_id('Treadmill Run') IS NOT NULL
  AND get_exercise_id('Burpees') IS NOT NULL
ON CONFLICT DO NOTHING;

-- Drop helper function
DROP FUNCTION IF EXISTS get_exercise_id(TEXT);

-- Summary
DO $$
DECLARE
    candidate_count INT;
BEGIN
    SELECT COUNT(*) INTO candidate_count FROM exercise_substitution_candidates;
    RAISE NOTICE 'Seeded % exercise substitution candidates', candidate_count;
END $$;
