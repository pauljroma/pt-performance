-- Reset session exercises back to original barbell exercises for testing
-- Session ID: 00000000-0000-0000-0000-000000000401

UPDATE session_exercises
SET
    exercise_template_id = '00000000-0000-0000-0000-0000000000e2',
    prescribed_load = 135,
    load_unit = 'lbs',
    notes = 'Focus on depth and control'
WHERE session_id = '00000000-0000-0000-0000-000000000401'
AND sequence = 1;

UPDATE session_exercises
SET
    exercise_template_id = 'cb7cbaec-78ee-4a50-b497-e53b83b7016a',
    prescribed_load = 95,
    load_unit = 'lbs',
    notes = NULL
WHERE session_id = '00000000-0000-0000-0000-000000000401'
AND sequence = 2;

UPDATE session_exercises
SET
    exercise_template_id = '00000000-0000-0000-0000-0000000000f2',
    prescribed_load = 95,
    load_unit = 'lbs',
    notes = NULL
WHERE session_id = '00000000-0000-0000-0000-000000000401'
AND sequence = 3;

UPDATE session_exercises
SET
    exercise_template_id = '00000000-0000-0000-0000-0000000000f4',
    prescribed_load = 135,
    load_unit = 'lbs',
    notes = NULL
WHERE session_id = '00000000-0000-0000-0000-000000000401'
AND sequence = 4;

UPDATE session_exercises
SET
    exercise_template_id = '5ca6d6a0-6446-4db5-8f61-7a8bc651f701',
    prescribed_load = 65,
    load_unit = 'lbs',
    notes = NULL
WHERE session_id = '00000000-0000-0000-0000-000000000401'
AND sequence = 5;

-- Mark old recommendations as rejected so new ones can be created
UPDATE recommendations
SET status = 'rejected'
WHERE session_id = '00000000-0000-0000-0000-000000000401'
AND status = 'applied';
