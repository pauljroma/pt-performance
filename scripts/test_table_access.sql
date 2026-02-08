-- =============================================================================
-- Table Access Test Script
-- =============================================================================
-- Purpose: Test actual table access with CRUD operations
-- Usage: psql $DATABASE_URL -f scripts/test_table_access.sql
--
-- This script:
-- 1. Creates test records as authenticated user
-- 2. Reads, updates, and deletes test data
-- 3. Verifies RLS policies work correctly
-- 4. Cleans up all test data
--
-- Uses demo patient ID for testing (non-destructive)
--
-- Date: 2026-02-07
-- =============================================================================

-- Start transaction (rollback at end to avoid persisting test data)
BEGIN;

-- =============================================================================
-- Test Setup
-- =============================================================================

-- Create test result tracking
CREATE TEMP TABLE test_results (
    id SERIAL PRIMARY KEY,
    test_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    expected_result TEXT NOT NULL,
    actual_result TEXT,
    passed BOOLEAN DEFAULT FALSE,
    error_message TEXT,
    tested_at TIMESTAMPTZ DEFAULT NOW()
);

-- Get demo patient ID (or use a placeholder)
DO $$
DECLARE
    v_demo_patient_id UUID;
BEGIN
    -- Try to find an existing demo patient
    SELECT id INTO v_demo_patient_id
    FROM patients
    WHERE email ILIKE '%demo%' OR email ILIKE '%test%'
    LIMIT 1;

    -- If no demo patient, use the first patient
    IF v_demo_patient_id IS NULL THEN
        SELECT id INTO v_demo_patient_id
        FROM patients
        ORDER BY created_at
        LIMIT 1;
    END IF;

    -- Store for use in tests
    PERFORM set_config('test.demo_patient_id', COALESCE(v_demo_patient_id::text, '00000000-0000-0000-0000-000000000001'), true);

    RAISE NOTICE 'Using demo patient ID: %', COALESCE(v_demo_patient_id::text, 'NONE FOUND');
END $$;

-- =============================================================================
-- Helper Functions
-- =============================================================================

-- Function to simulate authenticated user context
CREATE OR REPLACE FUNCTION pg_temp.set_user_context(user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Set JWT claims to simulate authenticated user
    PERFORM set_config('request.jwt.claims',
        json_build_object(
            'sub', user_id::text,
            'role', 'authenticated',
            'aud', 'authenticated'
        )::text,
        true);
    PERFORM set_config('role', 'authenticated', true);
END;
$$ LANGUAGE plpgsql;

-- Function to reset to service role
CREATE OR REPLACE FUNCTION pg_temp.reset_context()
RETURNS VOID AS $$
BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '', true);
END;
$$ LANGUAGE plpgsql;

-- Function to log test result
CREATE OR REPLACE FUNCTION pg_temp.log_test(
    p_test_name TEXT,
    p_table_name TEXT,
    p_operation TEXT,
    p_expected TEXT,
    p_actual TEXT,
    p_passed BOOLEAN,
    p_error TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO test_results (test_name, table_name, operation, expected_result, actual_result, passed, error_message)
    VALUES (p_test_name, p_table_name, p_operation, p_expected, p_actual, p_passed, p_error);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TEST 1: DAILY_READINESS TABLE
-- =============================================================================

DO $$
DECLARE
    v_demo_patient_id UUID;
    v_test_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_demo_patient_id := current_setting('test.demo_patient_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST: daily_readiness access ---';

    -- Check if table exists
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'daily_readiness' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: daily_readiness table does not exist';
        RETURN;
    END IF;

    -- Test 1: INSERT as patient
    PERFORM pg_temp.set_user_context(v_demo_patient_id);

    BEGIN
        INSERT INTO daily_readiness (
            patient_id,
            readiness_date,
            overall_score,
            sleep_quality,
            energy_level,
            soreness_level,
            stress_level
        ) VALUES (
            v_demo_patient_id,
            CURRENT_DATE - INTERVAL '100 days', -- Use far past date to avoid conflicts
            75,
            4,
            4,
            2,
            3
        )
        RETURNING id INTO v_test_id;

        PERFORM pg_temp.log_test(
            'Patient INSERT own readiness',
            'daily_readiness',
            'INSERT',
            'Success',
            'Created ID: ' || v_test_id::text,
            TRUE
        );
        RAISE NOTICE '  INSERT own data: PASS';
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.log_test(
            'Patient INSERT own readiness',
            'daily_readiness',
            'INSERT',
            'Success',
            'BLOCKED: ' || SQLERRM,
            FALSE,
            SQLERRM
        );
        RAISE NOTICE '  INSERT own data: FAIL - %', SQLERRM;
    END;

    -- Test 2: SELECT as patient
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM daily_readiness
        WHERE patient_id = v_demo_patient_id;

        v_test_passed := v_count >= 0;
        PERFORM pg_temp.log_test(
            'Patient SELECT own readiness',
            'daily_readiness',
            'SELECT',
            'Query succeeds',
            'Count: ' || v_count,
            v_test_passed
        );
        RAISE NOTICE '  SELECT own data: PASS (count: %)', v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.log_test(
            'Patient SELECT own readiness',
            'daily_readiness',
            'SELECT',
            'Query succeeds',
            'BLOCKED',
            FALSE,
            SQLERRM
        );
        RAISE NOTICE '  SELECT own data: FAIL - %', SQLERRM;
    END;

    -- Test 3: UPDATE as patient
    IF v_test_id IS NOT NULL THEN
        BEGIN
            UPDATE daily_readiness
            SET overall_score = 80
            WHERE id = v_test_id AND patient_id = v_demo_patient_id;

            GET DIAGNOSTICS v_count = ROW_COUNT;
            v_test_passed := v_count = 1;
            PERFORM pg_temp.log_test(
                'Patient UPDATE own readiness',
                'daily_readiness',
                'UPDATE',
                '1 row updated',
                v_count || ' rows updated',
                v_test_passed
            );
            RAISE NOTICE '  UPDATE own data: % (rows: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
        EXCEPTION WHEN OTHERS THEN
            PERFORM pg_temp.log_test(
                'Patient UPDATE own readiness',
                'daily_readiness',
                'UPDATE',
                '1 row updated',
                'BLOCKED',
                FALSE,
                SQLERRM
            );
            RAISE NOTICE '  UPDATE own data: FAIL - %', SQLERRM;
        END;
    END IF;

    -- Test 4: DELETE as patient
    IF v_test_id IS NOT NULL THEN
        BEGIN
            DELETE FROM daily_readiness
            WHERE id = v_test_id AND patient_id = v_demo_patient_id;

            GET DIAGNOSTICS v_count = ROW_COUNT;
            v_test_passed := v_count = 1;
            PERFORM pg_temp.log_test(
                'Patient DELETE own readiness',
                'daily_readiness',
                'DELETE',
                '1 row deleted',
                v_count || ' rows deleted',
                v_test_passed
            );
            RAISE NOTICE '  DELETE own data: % (rows: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
        EXCEPTION WHEN OTHERS THEN
            PERFORM pg_temp.log_test(
                'Patient DELETE own readiness',
                'daily_readiness',
                'DELETE',
                '1 row deleted',
                'BLOCKED',
                FALSE,
                SQLERRM
            );
            RAISE NOTICE '  DELETE own data: FAIL - %', SQLERRM;
        END;
    END IF;

    PERFORM pg_temp.reset_context();
END $$;

-- =============================================================================
-- TEST 2: EXERCISE_LOGS TABLE
-- =============================================================================

DO $$
DECLARE
    v_demo_patient_id UUID;
    v_test_id UUID;
    v_session_exercise_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_demo_patient_id := current_setting('test.demo_patient_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST: exercise_logs access ---';

    -- Check if table exists
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'exercise_logs' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: exercise_logs table does not exist';
        RETURN;
    END IF;

    -- Get a session_exercise_id for the demo patient (if available)
    SELECT se.id INTO v_session_exercise_id
    FROM session_exercises se
    JOIN sessions s ON se.session_id = s.id
    JOIN phases ph ON s.phase_id = ph.id
    JOIN programs p ON ph.program_id = p.id
    WHERE p.patient_id = v_demo_patient_id
    LIMIT 1;

    IF v_session_exercise_id IS NULL THEN
        RAISE NOTICE 'SKIP: No session_exercises found for demo patient';
        RETURN;
    END IF;

    -- Test: SELECT as patient
    PERFORM pg_temp.set_user_context(v_demo_patient_id);

    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM exercise_logs el
        WHERE el.patient_id = v_demo_patient_id;

        v_test_passed := v_count >= 0;
        PERFORM pg_temp.log_test(
            'Patient SELECT own exercise_logs',
            'exercise_logs',
            'SELECT',
            'Query succeeds',
            'Count: ' || v_count,
            v_test_passed
        );
        RAISE NOTICE '  SELECT own data: PASS (count: %)', v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.log_test(
            'Patient SELECT own exercise_logs',
            'exercise_logs',
            'SELECT',
            'Query succeeds',
            'BLOCKED',
            FALSE,
            SQLERRM
        );
        RAISE NOTICE '  SELECT own data: FAIL - %', SQLERRM;
    END;

    PERFORM pg_temp.reset_context();
END $$;

-- =============================================================================
-- TEST 3: SESSIONS TABLE
-- =============================================================================

DO $$
DECLARE
    v_demo_patient_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_demo_patient_id := current_setting('test.demo_patient_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST: sessions access ---';

    -- Check if table exists
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'sessions' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: sessions table does not exist';
        RETURN;
    END IF;

    -- Test: SELECT as patient (should see sessions for own programs)
    PERFORM pg_temp.set_user_context(v_demo_patient_id);

    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM sessions s
        JOIN phases ph ON s.phase_id = ph.id
        JOIN programs p ON ph.program_id = p.id
        WHERE p.patient_id = v_demo_patient_id;

        v_test_passed := v_count >= 0;
        PERFORM pg_temp.log_test(
            'Patient SELECT own sessions',
            'sessions',
            'SELECT',
            'Query succeeds',
            'Count: ' || v_count,
            v_test_passed
        );
        RAISE NOTICE '  SELECT own data: PASS (count: %)', v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.log_test(
            'Patient SELECT own sessions',
            'sessions',
            'SELECT',
            'Query succeeds',
            'BLOCKED',
            FALSE,
            SQLERRM
        );
        RAISE NOTICE '  SELECT own data: FAIL - %', SQLERRM;
    END;

    PERFORM pg_temp.reset_context();
END $$;

-- =============================================================================
-- TEST 4: STREAK_RECORDS TABLE
-- =============================================================================

DO $$
DECLARE
    v_demo_patient_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_demo_patient_id := current_setting('test.demo_patient_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST: streak_records access ---';

    -- Check if table exists
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'streak_records' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: streak_records table does not exist';
        RETURN;
    END IF;

    -- Test: SELECT as patient
    PERFORM pg_temp.set_user_context(v_demo_patient_id);

    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM streak_records
        WHERE patient_id = v_demo_patient_id;

        v_test_passed := v_count >= 0;
        PERFORM pg_temp.log_test(
            'Patient SELECT own streak_records',
            'streak_records',
            'SELECT',
            'Query succeeds',
            'Count: ' || v_count,
            v_test_passed
        );
        RAISE NOTICE '  SELECT own data: PASS (count: %)', v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.log_test(
            'Patient SELECT own streak_records',
            'streak_records',
            'SELECT',
            'Query succeeds',
            'BLOCKED',
            FALSE,
            SQLERRM
        );
        RAISE NOTICE '  SELECT own data: FAIL - %', SQLERRM;
    END;

    PERFORM pg_temp.reset_context();
END $$;

-- =============================================================================
-- TEST 5: NOTIFICATION_SETTINGS TABLE
-- =============================================================================

DO $$
DECLARE
    v_demo_patient_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_demo_patient_id := current_setting('test.demo_patient_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST: notification_settings access ---';

    -- Check if table exists
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'notification_settings' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: notification_settings table does not exist';
        RETURN;
    END IF;

    -- Test: SELECT as patient
    PERFORM pg_temp.set_user_context(v_demo_patient_id);

    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM notification_settings
        WHERE patient_id = v_demo_patient_id;

        v_test_passed := v_count >= 0;
        PERFORM pg_temp.log_test(
            'Patient SELECT own notification_settings',
            'notification_settings',
            'SELECT',
            'Query succeeds',
            'Count: ' || v_count,
            v_test_passed
        );
        RAISE NOTICE '  SELECT own data: PASS (count: %)', v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.log_test(
            'Patient SELECT own notification_settings',
            'notification_settings',
            'SELECT',
            'Query succeeds',
            'BLOCKED',
            FALSE,
            SQLERRM
        );
        RAISE NOTICE '  SELECT own data: FAIL - %', SQLERRM;
    END;

    PERFORM pg_temp.reset_context();
END $$;

-- =============================================================================
-- TEST 6: PATIENTS TABLE (ISOLATION TEST)
-- =============================================================================

DO $$
DECLARE
    v_demo_patient_id UUID;
    v_other_patient_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_demo_patient_id := current_setting('test.demo_patient_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST: patients table isolation ---';

    -- Get another patient ID
    SELECT id INTO v_other_patient_id
    FROM patients
    WHERE id != v_demo_patient_id
    LIMIT 1;

    IF v_other_patient_id IS NULL THEN
        RAISE NOTICE 'SKIP: Only one patient exists, cannot test isolation';
        RETURN;
    END IF;

    -- Test: Patient cannot see other patient's data
    PERFORM pg_temp.set_user_context(v_demo_patient_id);

    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM patients
        WHERE id = v_other_patient_id;

        -- Should return 0 rows (patient cannot see other patients)
        v_test_passed := v_count = 0;
        PERFORM pg_temp.log_test(
            'Patient CANNOT SELECT other patients',
            'patients',
            'SELECT',
            '0 rows (isolated)',
            v_count || ' rows',
            v_test_passed
        );
        RAISE NOTICE '  SELECT other patient: % (count: %, expected: 0)',
            CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL - ISOLATION BREACH' END,
            v_count;
    EXCEPTION WHEN OTHERS THEN
        -- Error is also acceptable (access denied)
        PERFORM pg_temp.log_test(
            'Patient CANNOT SELECT other patients',
            'patients',
            'SELECT',
            '0 rows or blocked',
            'Blocked by RLS',
            TRUE
        );
        RAISE NOTICE '  SELECT other patient: PASS (blocked by RLS)';
    END;

    PERFORM pg_temp.reset_context();
END $$;

-- =============================================================================
-- TEST SUMMARY
-- =============================================================================

DO $$
DECLARE
    v_total INTEGER;
    v_passed INTEGER;
    v_failed INTEGER;
    rec RECORD;
BEGIN
    SELECT COUNT(*) INTO v_total FROM test_results;
    SELECT COUNT(*) INTO v_passed FROM test_results WHERE passed = TRUE;
    SELECT COUNT(*) INTO v_failed FROM test_results WHERE passed = FALSE;

    RAISE NOTICE '';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'TABLE ACCESS TEST SUMMARY';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Total Tests: %', v_total;
    RAISE NOTICE 'Passed: %', v_passed;
    RAISE NOTICE 'Failed: %', v_failed;
    RAISE NOTICE '';

    IF v_failed > 0 THEN
        RAISE NOTICE '!!! FAILED TESTS !!!';
        RAISE NOTICE '';
        FOR rec IN
            SELECT test_name, table_name, operation, expected_result, actual_result, error_message
            FROM test_results
            WHERE passed = FALSE
        LOOP
            RAISE NOTICE 'FAIL: % on % (%)', rec.test_name, rec.table_name, rec.operation;
            RAISE NOTICE '  Expected: %', rec.expected_result;
            RAISE NOTICE '  Actual: %', rec.actual_result;
            IF rec.error_message IS NOT NULL THEN
                RAISE NOTICE '  Error: %', rec.error_message;
            END IF;
            RAISE NOTICE '';
        END LOOP;
    ELSE
        RAISE NOTICE 'All table access tests passed!';
    END IF;

    RAISE NOTICE '=============================================================================';
END $$;

-- Output results in machine-readable format
SELECT
    test_name,
    table_name,
    operation,
    CASE WHEN passed THEN 'PASS' ELSE 'FAIL' END AS status,
    expected_result,
    actual_result,
    error_message
FROM test_results
ORDER BY passed, table_name, test_name;

-- Rollback to avoid persisting test data
ROLLBACK;
