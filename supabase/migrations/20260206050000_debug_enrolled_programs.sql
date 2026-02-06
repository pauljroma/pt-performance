-- Build 448: Debug enrolled programs issue
-- Check why enrolled programs work for demo but not real accounts

-- ============================================================================
-- Debug: Compare demo vs paul@romatech.com
-- ============================================================================

DO $$
DECLARE
    v_demo_patient_id UUID;
    v_paul_patient_id UUID;
    v_demo_count INT;
    v_paul_count INT;
BEGIN
    -- Get patient IDs
    SELECT id INTO v_demo_patient_id FROM patients WHERE email = 'demo@ptperformance.com' LIMIT 1;
    SELECT id INTO v_paul_patient_id FROM patients WHERE email = 'paul@romatech.com' LIMIT 1;

    RAISE NOTICE '=== Patient IDs ===';
    RAISE NOTICE 'demo@ptperformance.com patient_id: %', v_demo_patient_id;
    RAISE NOTICE 'paul@romatech.com patient_id: %', v_paul_patient_id;

    -- Check enrollments
    SELECT COUNT(*) INTO v_demo_count FROM program_enrollments WHERE patient_id = v_demo_patient_id AND status = 'active';
    SELECT COUNT(*) INTO v_paul_count FROM program_enrollments WHERE patient_id = v_paul_patient_id AND status = 'active';

    RAISE NOTICE '=== Active Enrollments ===';
    RAISE NOTICE 'demo: % active enrollments', v_demo_count;
    RAISE NOTICE 'paul: % active enrollments', v_paul_count;

    -- Check daily_readiness
    SELECT COUNT(*) INTO v_demo_count FROM daily_readiness WHERE patient_id = v_demo_patient_id;
    SELECT COUNT(*) INTO v_paul_count FROM daily_readiness WHERE patient_id = v_paul_patient_id;

    RAISE NOTICE '=== Daily Readiness Entries ===';
    RAISE NOTICE 'demo: % entries', v_demo_count;
    RAISE NOTICE 'paul: % entries', v_paul_count;

    -- Check arm_care_assessments
    SELECT COUNT(*) INTO v_demo_count FROM arm_care_assessments WHERE patient_id = v_demo_patient_id;
    SELECT COUNT(*) INTO v_paul_count FROM arm_care_assessments WHERE patient_id = v_paul_patient_id;

    RAISE NOTICE '=== Arm Care Assessments ===';
    RAISE NOTICE 'demo: % entries', v_demo_count;
    RAISE NOTICE 'paul: % entries', v_paul_count;

    -- Check if patients have user_id set
    RAISE NOTICE '=== Patient user_id Check ===';
    SELECT user_id INTO v_demo_patient_id FROM patients WHERE email = 'demo@ptperformance.com';
    SELECT user_id INTO v_paul_patient_id FROM patients WHERE email = 'paul@romatech.com';
    RAISE NOTICE 'demo user_id: %', v_demo_patient_id;
    RAISE NOTICE 'paul user_id: %', v_paul_patient_id;
END $$;

-- ============================================================================
-- List paul's actual enrollments with program titles
-- ============================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE '=== Paul enrollments with program details ===';
    FOR r IN
        SELECT pe.id, pe.status, pe.progress_percentage, pl.title
        FROM program_enrollments pe
        JOIN program_library pl ON pl.id = pe.program_library_id
        WHERE pe.patient_id = '743bbbd4-771a-418e-b161-a7a9e88c83e7'::UUID
        ORDER BY pe.enrolled_at DESC
    LOOP
        RAISE NOTICE 'Enrollment %: % (%) - %', r.id, r.title, r.status, r.progress_percentage || '%';
    END LOOP;
END $$;
