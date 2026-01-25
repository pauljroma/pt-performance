-- BUILD 283: Create test program for John
-- This seed runs AFTER the audit fix migration, so triggers work correctly

-- Step 1: Create program for John (only if doesn't exist)
INSERT INTO public.programs (patient_id, name, target_level, duration_weeks)
SELECT p.id, 'Return to Sport - Baseball Pitcher', 'Professional', 12
FROM public.patients p
WHERE p.first_name = 'John'
AND NOT EXISTS (SELECT 1 FROM public.programs prog WHERE prog.patient_id = p.id)
LIMIT 1;

-- Step 2: Create phases
WITH john_program AS (
    SELECT prog.id as program_id
    FROM public.programs prog
    JOIN public.patients p ON prog.patient_id = p.id
    WHERE p.first_name = 'John'
    ORDER BY prog.created_at DESC
    LIMIT 1
)
INSERT INTO public.phases (program_id, phase_number, name, duration_weeks, goals, sequence)
SELECT jp.program_id, phase_num, phase_name, 4, phase_goals, phase_num
FROM john_program jp,
(VALUES
    (1, 'Foundation', 'Build base strength and mobility'),
    (2, 'Build', 'Increase strength and power'),
    (3, 'Peak', 'Sport-specific training and return to throwing')
) AS phase_data(phase_num, phase_name, phase_goals)
WHERE NOT EXISTS (SELECT 1 FROM public.phases ph WHERE ph.program_id = jp.program_id);

-- Step 3: Create sessions
WITH john_phases AS (
    SELECT ph.id as phase_id, ph.phase_number
    FROM public.phases ph
    JOIN public.programs prog ON ph.program_id = prog.id
    JOIN public.patients p ON prog.patient_id = p.id
    WHERE p.first_name = 'John'
)
INSERT INTO public.sessions (phase_id, session_number, name, notes)
SELECT jp.phase_id, session_num, session_name, session_notes
FROM john_phases jp,
(VALUES
    (1, 1, 'Upper Body A', 'Focus on push movements'),
    (1, 2, 'Lower Body A', 'Focus on squat pattern'),
    (2, 1, 'Upper Body B', 'Focus on pull movements'),
    (2, 2, 'Lower Body B', 'Focus on hinge pattern'),
    (3, 1, 'Full Body Power', 'Explosive movements'),
    (3, 2, 'Sport Specific', 'Throwing progression')
) AS session_data(phase_num, session_num, session_name, session_notes)
WHERE jp.phase_number = session_data.phase_num
AND NOT EXISTS (SELECT 1 FROM public.sessions s WHERE s.phase_id = jp.phase_id);

-- Verification
DO $$
DECLARE
    v_program_count INT;
    v_phase_count INT;
    v_session_count INT;
BEGIN
    SELECT COUNT(*) INTO v_program_count
    FROM public.programs prog
    JOIN public.patients p ON prog.patient_id = p.id
    WHERE p.first_name = 'John';

    SELECT COUNT(*) INTO v_phase_count
    FROM public.phases ph
    JOIN public.programs prog ON ph.program_id = prog.id
    JOIN public.patients p ON prog.patient_id = p.id
    WHERE p.first_name = 'John';

    SELECT COUNT(*) INTO v_session_count
    FROM public.sessions s
    JOIN public.phases ph ON s.phase_id = ph.id
    JOIN public.programs prog ON ph.program_id = prog.id
    JOIN public.patients p ON prog.patient_id = p.id
    WHERE p.first_name = 'John';

    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'BUILD 283: JOHN TEST PROGRAM CREATED';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Programs: %', v_program_count;
    RAISE NOTICE 'Phases: %', v_phase_count;
    RAISE NOTICE 'Sessions: %', v_session_count;
    RAISE NOTICE '========================================';
END $$;
