-- Reset Demo Patient Workout to Show Weights
-- Demo patient ID: 00000000-0000-0000-0000-000000000001
-- Session ID: 00000000-0000-0000-0000-000000000401

-- Step 1: Reset the scheduled session to 'scheduled' status for today
UPDATE scheduled_sessions
SET
    status = 'scheduled',
    scheduled_date = CURRENT_DATE
WHERE patient_id = '00000000-0000-0000-0000-000000000001'
  AND id = '00000000-0000-0000-0000-000000000401';

-- Step 2: Update session_exercises with weights for the demo session
-- First, let's see what exercises exist and update them with proper weights

-- Update Back Squat (exercise 1)
UPDATE session_exercises
SET
    prescribed_load = 185,
    load_unit = 'lbs'
WHERE session_id = '00000000-0000-0000-0000-000000000101'
  AND sequence = 1;

-- Update Bench Press (exercise 2)
UPDATE session_exercises
SET
    prescribed_load = 155,
    load_unit = 'lbs'
WHERE session_id = '00000000-0000-0000-0000-000000000101'
  AND sequence = 2;

-- Update Barbell Row (exercise 3)
UPDATE session_exercises
SET
    prescribed_load = 135,
    load_unit = 'lbs'
WHERE session_id = '00000000-0000-0000-0000-000000000101'
  AND sequence = 3;

-- Update Dumbbell Shoulder Press (exercise 4)
UPDATE session_exercises
SET
    prescribed_load = 40,
    load_unit = 'lbs'
WHERE session_id = '00000000-0000-0000-0000-000000000101'
  AND sequence = 4;

-- Update Romanian Deadlift (exercise 5)
UPDATE session_exercises
SET
    prescribed_load = 135,
    load_unit = 'lbs'
WHERE session_id = '00000000-0000-0000-0000-000000000101'
  AND sequence = 5;

-- Step 3: Clear any existing exercise logs for this session today
DELETE FROM exercise_logs
WHERE session_exercise_id IN (
    SELECT se.id FROM session_exercises se
    WHERE se.session_id = '00000000-0000-0000-0000-000000000101'
)
AND logged_at::date = CURRENT_DATE;

-- Verify the updates
SELECT
    se.sequence,
    et.name as exercise_name,
    se.prescribed_sets,
    se.prescribed_reps,
    se.prescribed_load,
    se.load_unit
FROM session_exercises se
JOIN exercise_templates et ON se.exercise_template_id = et.id
WHERE se.session_id = '00000000-0000-0000-0000-000000000101'
ORDER BY se.sequence;
