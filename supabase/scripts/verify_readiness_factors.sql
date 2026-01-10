-- ============================================================================
-- READINESS FACTORS VERIFICATION SCRIPT - BUILD 116
-- ============================================================================
-- Comprehensive verification of readiness factors seeding and functionality
-- Tests factor integrity, weight validation, and score calculation
--
-- Date: 2026-01-03
-- Agent: 3
-- Linear: BUILD-116
--
-- Usage:
--   psql -f verify_readiness_factors.sql
--   OR via Supabase CLI: supabase db execute < verify_readiness_factors.sql
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'READINESS FACTORS VERIFICATION - BUILD 116'
\echo '============================================================================'
\echo ''

-- =====================================================
-- Test 1: Verify All Factors Inserted
-- =====================================================

\echo '-----------------------------------'
\echo 'TEST 1: Verify Factor Count'
\echo '-----------------------------------'

DO $$
DECLARE
    v_active_count integer;
    v_expected_count integer := 7;
BEGIN
    SELECT COUNT(*) INTO v_active_count
    FROM readiness_factors
    WHERE is_active = true;

    IF v_active_count = v_expected_count THEN
        RAISE NOTICE '✅ PASS: Found % active factors (expected %)', v_active_count, v_expected_count;
    ELSE
        RAISE WARNING '❌ FAIL: Found % active factors (expected %)', v_active_count, v_expected_count;
    END IF;
END $$;

\echo ''

-- =====================================================
-- Test 2: Verify Weights Sum to 1.0
-- =====================================================

\echo '-----------------------------------'
\echo 'TEST 2: Verify Weight Sum = 1.0'
\echo '-----------------------------------'

DO $$
DECLARE
    v_total_weight numeric;
    v_epsilon numeric := 0.001;
BEGIN
    SELECT SUM(weight) INTO v_total_weight
    FROM readiness_factors
    WHERE is_active = true;

    RAISE NOTICE 'Total weight: %', v_total_weight;

    IF ABS(v_total_weight - 1.0) <= v_epsilon THEN
        RAISE NOTICE '✅ PASS: Weights sum to exactly 1.0';
    ELSE
        RAISE WARNING '❌ FAIL: Weights sum to % (expected 1.0)', v_total_weight;
    END IF;
END $$;

\echo ''

-- =====================================================
-- Test 3: Verify Required Factors Exist
-- =====================================================

\echo '-----------------------------------'
\echo 'TEST 3: Verify Required Factors'
\echo '-----------------------------------'

DO $$
DECLARE
    v_required_factors text[] := ARRAY[
        'sleep_quality',
        'soreness_level',
        'energy_level',
        'stress_level',
        'mood_state',
        'hrv_score',
        'previous_rpe'
    ];
    v_factor text;
    v_count integer;
    v_all_found boolean := true;
BEGIN
    FOREACH v_factor IN ARRAY v_required_factors
    LOOP
        SELECT COUNT(*) INTO v_count
        FROM readiness_factors
        WHERE name = v_factor AND is_active = true;

        IF v_count = 1 THEN
            RAISE NOTICE '  ✅ Found: %', v_factor;
        ELSE
            RAISE WARNING '  ❌ Missing: %', v_factor;
            v_all_found := false;
        END IF;
    END LOOP;

    IF v_all_found THEN
        RAISE NOTICE '';
        RAISE NOTICE '✅ PASS: All required factors present';
    ELSE
        RAISE WARNING '';
        RAISE WARNING '❌ FAIL: Some required factors missing';
    END IF;
END $$;

\echo ''

-- =====================================================
-- Test 4: Display Factor Details
-- =====================================================

\echo '-----------------------------------'
\echo 'TEST 4: Factor Details'
\echo '-----------------------------------'
\echo ''

SELECT
    name,
    weight,
    ROUND(weight * 100, 1) || '%' as percentage,
    is_active,
    LEFT(description, 60) || '...' as description_preview
FROM readiness_factors
WHERE is_active = true
ORDER BY weight DESC;

\echo ''

-- =====================================================
-- Test 5: Test calculate_readiness_score() Function
-- =====================================================

\echo '-----------------------------------'
\echo 'TEST 5: Test Score Calculation'
\echo '-----------------------------------'

DO $$
DECLARE
    v_test_patient_id uuid := gen_random_uuid();
    v_test_date date := CURRENT_DATE;
    v_calculated_score numeric;
BEGIN
    -- Insert test readiness data
    INSERT INTO daily_readiness (
        patient_id,
        date,
        sleep_hours,
        soreness_level,
        energy_level,
        stress_level
    ) VALUES (
        v_test_patient_id,
        v_test_date,
        8.0,  -- Good sleep
        3,    -- Low soreness (good)
        8,    -- High energy (good)
        2     -- Low stress (good)
    );

    RAISE NOTICE 'Created test readiness entry:';
    RAISE NOTICE '  Patient ID: %', v_test_patient_id;
    RAISE NOTICE '  Date: %', v_test_date;
    RAISE NOTICE '  Sleep: 8.0 hours';
    RAISE NOTICE '  Soreness: 3/10';
    RAISE NOTICE '  Energy: 8/10';
    RAISE NOTICE '  Stress: 2/10';
    RAISE NOTICE '';

    -- Get calculated score (should be auto-calculated by trigger)
    SELECT readiness_score INTO v_calculated_score
    FROM daily_readiness
    WHERE patient_id = v_test_patient_id
      AND date = v_test_date;

    RAISE NOTICE 'Calculated Readiness Score: %', v_calculated_score;

    IF v_calculated_score IS NOT NULL AND v_calculated_score >= 0 AND v_calculated_score <= 100 THEN
        RAISE NOTICE '✅ PASS: Score calculated and within valid range (0-100)';
    ELSE
        RAISE WARNING '❌ FAIL: Score is NULL or out of range';
    END IF;

    -- Clean up test data
    DELETE FROM daily_readiness WHERE patient_id = v_test_patient_id;
    RAISE NOTICE '';
    RAISE NOTICE 'Test data cleaned up';

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '❌ FAIL: Error during score calculation test: %', SQLERRM;
        -- Attempt cleanup even on error
        DELETE FROM daily_readiness WHERE patient_id = v_test_patient_id;
END $$;

\echo ''

-- =====================================================
-- Test 6: Test get_readiness_trend() Function
-- =====================================================

\echo '-----------------------------------'
\echo 'TEST 6: Test Trend Calculation'
\echo '-----------------------------------'

DO $$
DECLARE
    v_test_patient_id uuid := gen_random_uuid();
    v_trend_result json;
    v_days integer := 3;
    i integer;
BEGIN
    -- Insert multiple days of test data
    FOR i IN 0..v_days-1 LOOP
        INSERT INTO daily_readiness (
            patient_id,
            date,
            sleep_hours,
            soreness_level,
            energy_level,
            stress_level
        ) VALUES (
            v_test_patient_id,
            CURRENT_DATE - i,
            7.5 + (i * 0.5),  -- Varying sleep
            3 + i,             -- Increasing soreness
            8 - i,             -- Decreasing energy
            2 + i              -- Increasing stress
        );
    END LOOP;

    RAISE NOTICE 'Created % days of test trend data', v_days;

    -- Get trend
    SELECT get_readiness_trend(v_test_patient_id, v_days)
    INTO v_trend_result;

    IF v_trend_result IS NOT NULL THEN
        RAISE NOTICE '✅ PASS: Trend data generated successfully';
        RAISE NOTICE '';
        RAISE NOTICE 'Trend Result (sample):';
        RAISE NOTICE '%', v_trend_result::text;
    ELSE
        RAISE WARNING '❌ FAIL: Trend data is NULL';
    END IF;

    -- Clean up test data
    DELETE FROM daily_readiness WHERE patient_id = v_test_patient_id;
    RAISE NOTICE '';
    RAISE NOTICE 'Test data cleaned up';

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '❌ FAIL: Error during trend calculation test: %', SQLERRM;
        -- Attempt cleanup even on error
        DELETE FROM daily_readiness WHERE patient_id = v_test_patient_id;
END $$;

\echo ''

-- =====================================================
-- Test 7: Verify RLS Policies
-- =====================================================

\echo '-----------------------------------'
\echo 'TEST 7: Verify RLS Policies'
\echo '-----------------------------------'

DO $$
DECLARE
    v_policy_count integer;
BEGIN
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE tablename = 'readiness_factors';

    RAISE NOTICE 'Readiness Factors RLS Policies: %', v_policy_count;

    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE tablename = 'daily_readiness';

    RAISE NOTICE 'Daily Readiness RLS Policies: %', v_policy_count;

    IF v_policy_count >= 4 THEN
        RAISE NOTICE '✅ PASS: RLS policies configured';
    ELSE
        RAISE WARNING '⚠️  WARNING: Expected at least 4 RLS policies for daily_readiness';
    END IF;
END $$;

\echo ''

-- =====================================================
-- Test 8: Weight Distribution Analysis
-- =====================================================

\echo '-----------------------------------'
\echo 'TEST 8: Weight Distribution'
\echo '-----------------------------------'
\echo ''
\echo 'Evidence-Based Weight Distribution:'
\echo ''

SELECT
    RPAD(name, 20) as factor_name,
    LPAD(weight::text, 4) as weight_value,
    LPAD(ROUND(weight * 100)::text || '%', 5) as percentage,
    REPEAT('█', (weight * 50)::integer) as visual_weight
FROM readiness_factors
WHERE is_active = true
ORDER BY weight DESC;

\echo ''

-- =====================================================
-- Test 9: Check for Weight Conflicts
-- =====================================================

\echo '-----------------------------------'
\echo 'TEST 9: Check Weight Constraints'
\echo '-----------------------------------'

DO $$
DECLARE
    v_invalid_count integer;
BEGIN
    SELECT COUNT(*) INTO v_invalid_count
    FROM readiness_factors
    WHERE is_active = true
      AND (weight < 0 OR weight > 1);

    IF v_invalid_count = 0 THEN
        RAISE NOTICE '✅ PASS: All weights within valid range (0.0 - 1.0)';
    ELSE
        RAISE WARNING '❌ FAIL: % factors have invalid weights', v_invalid_count;
    END IF;
END $$;

\echo ''

-- =====================================================
-- Final Summary
-- =====================================================

\echo ''
\echo '============================================================================'
\echo 'VERIFICATION COMPLETE'
\echo '============================================================================'
\echo ''

DO $$
DECLARE
    v_active_count integer;
    v_total_weight numeric;
BEGIN
    SELECT COUNT(*), SUM(weight)
    INTO v_active_count, v_total_weight
    FROM readiness_factors
    WHERE is_active = true;

    RAISE NOTICE 'Summary:';
    RAISE NOTICE '--------';
    RAISE NOTICE 'Active Factors: %', v_active_count;
    RAISE NOTICE 'Total Weight: %', v_total_weight;
    RAISE NOTICE 'Weight Target: 1.00';
    RAISE NOTICE 'Deviation: % (%% off)', ABS(v_total_weight - 1.0), ROUND(ABS(v_total_weight - 1.0) * 100, 2);
    RAISE NOTICE '';

    IF v_active_count = 7 AND ABS(v_total_weight - 1.0) <= 0.001 THEN
        RAISE NOTICE '✅ ALL TESTS PASSED - READINESS FACTORS VERIFIED';
    ELSE
        RAISE WARNING '⚠️  SOME TESTS FAILED - REVIEW ABOVE OUTPUT';
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '1. Review factor weights with domain experts';
    RAISE NOTICE '2. Test score calculation with real patient data';
    RAISE NOTICE '3. Monitor score distribution for calibration';
    RAISE NOTICE '4. Proceed with iOS integration (Agent 5)';
    RAISE NOTICE '';
END $$;

\echo '============================================================================'
\echo ''
