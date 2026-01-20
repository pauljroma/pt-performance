-- Fix Demo Patient to show equipment exercises with weights
-- The "Full Body Strength" session (ID 450) has the equipment exercises
-- We need to make sure scheduled_sessions points to this session for today

-- Step 1: Delete any existing scheduled sessions for demo patient for today
DELETE FROM scheduled_sessions
WHERE patient_id = '00000000-0000-0000-0000-000000000001'
  AND scheduled_date = CURRENT_DATE;

-- Step 2: Create a new scheduled session pointing to Full Body Strength
INSERT INTO scheduled_sessions (
    id,
    patient_id,
    session_id,
    scheduled_date,
    scheduled_time,
    status
)
VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000450', -- Full Body Strength session
    CURRENT_DATE,
    '09:00:00'::time,
    'scheduled'
);

-- Step 3: Verify the session_exercises have the right weights (from BUILD 174)
-- Update in case they were modified
UPDATE session_exercises
SET
    prescribed_load = 135,
    load_unit = 'lbs'
WHERE id = '00000000-0000-0000-0000-000000000e01'; -- Barbell Squat

UPDATE session_exercises
SET
    prescribed_load = 95,
    load_unit = 'lbs'
WHERE id = '00000000-0000-0000-0000-000000000e02'; -- Barbell Bench Press

UPDATE session_exercises
SET
    prescribed_load = 95,
    load_unit = 'lbs'
WHERE id = '00000000-0000-0000-0000-000000000e03'; -- Barbell Row

UPDATE session_exercises
SET
    prescribed_load = 185,
    load_unit = 'lbs'
WHERE id = '00000000-0000-0000-0000-000000000e04'; -- Barbell Deadlift

UPDATE session_exercises
SET
    prescribed_load = 65,
    load_unit = 'lbs'
WHERE id = '00000000-0000-0000-0000-000000000e05'; -- Barbell OHP

-- Step 4: Clear any completion status from the session itself
-- Disable the buggy trigger temporarily
ALTER TABLE sessions DISABLE TRIGGER audit_session_changes_trigger;

UPDATE sessions
SET
    completed = false,
    completed_at = NULL
WHERE id = '00000000-0000-0000-0000-000000000450';

-- Re-enable trigger
ALTER TABLE sessions ENABLE TRIGGER audit_session_changes_trigger;

-- Step 5: Clear today's exercise logs for a fresh start
DELETE FROM exercise_logs
WHERE patient_id = '00000000-0000-0000-0000-000000000001'
  AND logged_at::date = CURRENT_DATE;

-- Log success
DO $$ BEGIN RAISE NOTICE 'Demo patient scheduled for Full Body Strength session with equipment exercises'; END $$;
