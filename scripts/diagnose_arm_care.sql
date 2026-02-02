-- Diagnose Arm Care & Maintenance Program
-- Run this in Supabase Dashboard SQL Editor:
-- https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new

-- 1. Check if the program exists
SELECT
    'PROGRAM' as entity,
    id,
    name,
    status
FROM programs
WHERE name = 'Arm Care & Maintenance';

-- 2. Check phases for the program
SELECT
    'PHASES' as entity,
    ph.id,
    ph.name,
    ph.sequence
FROM phases ph
JOIN programs p ON p.id = ph.program_id
WHERE p.name = 'Arm Care & Maintenance'
ORDER BY ph.sequence;

-- 3. Check sessions for the program
SELECT
    'SESSIONS' as entity,
    s.id,
    s.name,
    ph.name as phase_name,
    s.sequence
FROM sessions s
JOIN phases ph ON ph.id = s.phase_id
JOIN programs p ON p.id = ph.program_id
WHERE p.name = 'Arm Care & Maintenance'
ORDER BY ph.sequence, s.sequence;

-- 4. Check session_exercises for the program (THIS IS KEY)
SELECT
    'SESSION_EXERCISES' as entity,
    s.name as session_name,
    se.id as session_exercise_id,
    et.name as exercise_name,
    se.sequence,
    se.target_sets,
    se.target_reps
FROM session_exercises se
JOIN sessions s ON s.id = se.session_id
JOIN phases ph ON ph.id = s.phase_id
JOIN programs p ON p.id = ph.program_id
LEFT JOIN exercise_templates et ON et.id = se.exercise_template_id
WHERE p.name = 'Arm Care & Maintenance'
ORDER BY s.sequence, se.sequence;

-- 5. Check if the required exercise templates exist
SELECT
    'REQUIRED_TEMPLATES' as entity,
    id,
    name,
    category
FROM exercise_templates
WHERE id IN (
    '00000000-0000-0000-0002-000000000011',
    '00000000-0000-0000-0002-000000000012',
    '00000000-0000-0000-0002-000000000013',
    '00000000-0000-0000-0002-000000000014',
    '00000000-0000-0000-0002-000000000015',
    '00000000-0000-0000-0002-000000000016',
    '00000000-0000-0000-0002-000000000017',
    '00000000-0000-0000-0002-000000000018',
    '00000000-0000-0000-0002-000000000023'
);

-- 6. Count summary
SELECT
    (SELECT COUNT(*) FROM programs WHERE name = 'Arm Care & Maintenance') as program_count,
    (SELECT COUNT(*) FROM phases ph JOIN programs p ON p.id = ph.program_id WHERE p.name = 'Arm Care & Maintenance') as phase_count,
    (SELECT COUNT(*) FROM sessions s JOIN phases ph ON ph.id = s.phase_id JOIN programs p ON p.id = ph.program_id WHERE p.name = 'Arm Care & Maintenance') as session_count,
    (SELECT COUNT(*) FROM session_exercises se JOIN sessions s ON s.id = se.session_id JOIN phases ph ON ph.id = s.phase_id JOIN programs p ON p.id = ph.program_id WHERE p.name = 'Arm Care & Maintenance') as exercise_count;
