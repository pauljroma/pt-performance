-- Debug: Check the hardcoded demo patient ID

DO $$
DECLARE
    v_demo_id UUID := '00000000-0000-0000-0000-000000000001'::UUID;
    v_count INT;
BEGIN
    RAISE NOTICE '=== Demo Patient (00000000-0000-0000-0000-000000000001) ===';

    -- Check if patient exists
    SELECT COUNT(*) INTO v_count FROM patients WHERE id = v_demo_id;
    RAISE NOTICE 'Patient record exists: %', CASE WHEN v_count > 0 THEN 'YES' ELSE 'NO' END;

    -- Check enrollments
    SELECT COUNT(*) INTO v_count FROM program_enrollments WHERE patient_id = v_demo_id AND status = 'active';
    RAISE NOTICE 'Active enrollments: %', v_count;

    -- Check daily_readiness
    SELECT COUNT(*) INTO v_count FROM daily_readiness WHERE patient_id = v_demo_id;
    RAISE NOTICE 'Daily readiness entries: %', v_count;

    -- Check arm_care_assessments
    SELECT COUNT(*) INTO v_count FROM arm_care_assessments WHERE patient_id = v_demo_id;
    RAISE NOTICE 'Arm care assessments: %', v_count;

    -- Check programs (direct assignment)
    SELECT COUNT(*) INTO v_count FROM programs WHERE patient_id = v_demo_id AND status = 'active';
    RAISE NOTICE 'Direct program assignments: %', v_count;

    -- Check sessions via direct programs
    SELECT COUNT(*) INTO v_count
    FROM sessions s
    JOIN phases p ON p.id = s.phase_id
    JOIN programs prog ON prog.id = p.program_id
    WHERE prog.patient_id = v_demo_id;
    RAISE NOTICE 'Sessions via direct programs: %', v_count;

    -- Check scheduled_sessions
    SELECT COUNT(*) INTO v_count FROM scheduled_sessions WHERE patient_id = v_demo_id;
    RAISE NOTICE 'Scheduled sessions: %', v_count;
END $$;

-- Show patient details if exists
SELECT id, email, first_name, last_name, user_id
FROM patients
WHERE id = '00000000-0000-0000-0000-000000000001'::UUID;
