-- Test Baseball Pack Programs
-- Run this in Supabase Dashboard SQL Editor:
-- https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new

-- 1. Check all baseball programs in program_library
SELECT
    title,
    duration_weeks,
    difficulty_level,
    is_featured,
    array_to_string(tags, ', ') as tags
FROM program_library
WHERE category = 'baseball'
ORDER BY title;

-- 2. Count programs by type
SELECT
    CASE
        WHEN 'pitcher' = ANY(tags) THEN 'Pitcher'
        WHEN 'catcher' = ANY(tags) THEN 'Catcher'
        WHEN 'infielder' = ANY(tags) THEN 'Infielder'
        WHEN 'outfielder' = ANY(tags) THEN 'Outfielder'
        WHEN 'off_season' = ANY(tags) THEN 'Off-Season'
        WHEN 'game_day' = ANY(tags) THEN 'Game-Day'
        ELSE 'Other'
    END as program_type,
    COUNT(*) as count
FROM program_library
WHERE category = 'baseball'
GROUP BY 1
ORDER BY 1;

-- 3. Check exercise templates for baseball
SELECT COUNT(*) as total_baseball_templates
FROM exercise_templates
WHERE category IN ('throwing', 'arm_care', 'mobility', 'power', 'agility', 'speed', 'grip', 'prehab');

-- 4. Verify sessions and exercises for a sample program (Catcher)
SELECT
    p.name as program_name,
    ph.name as phase_name,
    s.name as session_name,
    COUNT(se.id) as exercise_count
FROM programs p
JOIN phases ph ON ph.program_id = p.id
JOIN sessions s ON s.phase_id = ph.id
LEFT JOIN session_exercises se ON se.session_id = s.id
WHERE p.name = 'Catcher Durability & Performance'
GROUP BY p.name, ph.name, s.name, s.sequence
ORDER BY ph.sequence, s.sequence;

-- 5. Quick summary
SELECT
    (SELECT COUNT(*) FROM program_library WHERE category = 'baseball') as baseball_programs,
    (SELECT COUNT(*) FROM programs WHERE name LIKE '%Catcher%' OR name LIKE '%Infielder%' OR name LIKE '%Outfielder%' OR name LIKE '%Off-Season%' OR name LIKE '%Game-Day%' OR name LIKE '%Weighted Ball%' OR name LIKE '%Arm Care%' OR name LIKE '%Velocity%') as total_programs,
    (SELECT COUNT(*) FROM exercise_templates WHERE category IN ('throwing', 'arm_care')) as throwing_templates;
