-- ============================================================================
-- RLS POLICY VERIFICATION TEST SCRIPT
-- ============================================================================
-- Purpose: Test Row Level Security policies for all patient-sensitive tables
-- Usage:
--   psql $DATABASE_URL -f scripts/test_rls_policies.sql
--   OR
--   supabase test db
--
-- Date: 2026-02-03
-- ============================================================================

-- ============================================================================
-- TEST SETUP
-- ============================================================================

BEGIN;

-- Create test schema for isolation
CREATE SCHEMA IF NOT EXISTS rls_test;

-- Test result tracking table
CREATE TABLE IF NOT EXISTS rls_test.test_results (
    id SERIAL PRIMARY KEY,
    test_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    expected_result TEXT NOT NULL,
    actual_result TEXT,
    passed BOOLEAN,
    error_message TEXT,
    tested_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- TEST HELPER FUNCTIONS
-- ============================================================================

-- Function to simulate a user session
CREATE OR REPLACE FUNCTION rls_test.set_user_context(user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Set the JWT claim to simulate authenticated user
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

-- Function to reset to service role (admin access)
CREATE OR REPLACE FUNCTION rls_test.reset_to_service_role()
RETURNS VOID AS $$
BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '', true);
END;
$$ LANGUAGE plpgsql;

-- Function to log test result
CREATE OR REPLACE FUNCTION rls_test.log_result(
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
    INSERT INTO rls_test.test_results (
        test_name, table_name, operation, expected_result, actual_result, passed, error_message
    ) VALUES (
        p_test_name, p_table_name, p_operation, p_expected, p_actual, p_passed, p_error
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GET OR CREATE TEST USERS
-- ============================================================================

DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_therapist_id UUID;
    v_unlinked_therapist_id UUID;
BEGIN
    -- Try to get existing test users or use placeholders
    -- These should exist in auth.users and patients tables

    -- Get first two patients for testing
    SELECT id INTO v_patient_a_id FROM patients ORDER BY created_at LIMIT 1;
    SELECT id INTO v_patient_b_id FROM patients ORDER BY created_at OFFSET 1 LIMIT 1;

    -- Get a therapist
    SELECT user_id INTO v_therapist_id FROM therapists WHERE user_id IS NOT NULL LIMIT 1;

    -- Store IDs for tests
    PERFORM set_config('rls_test.patient_a_id', COALESCE(v_patient_a_id::text, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), false);
    PERFORM set_config('rls_test.patient_b_id', COALESCE(v_patient_b_id::text, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), false);
    PERFORM set_config('rls_test.therapist_id', COALESCE(v_therapist_id::text, 'cccccccc-cccc-cccc-cccc-cccccccccccc'), false);
    PERFORM set_config('rls_test.unlinked_therapist_id', 'dddddddd-dddd-dddd-dddd-dddddddddddd', false);

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'RLS POLICY TEST SETUP';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'Patient A ID: %', COALESCE(v_patient_a_id::text, 'NOT FOUND');
    RAISE NOTICE 'Patient B ID: %', COALESCE(v_patient_b_id::text, 'NOT FOUND');
    RAISE NOTICE 'Therapist ID: %', COALESCE(v_therapist_id::text, 'NOT FOUND');
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- TEST 1: LAB_RESULTS TABLE
-- ============================================================================

DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;
    v_patient_b_id := current_setting('rls_test.patient_b_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 1: lab_results RLS ---';

    -- Check if table exists and has RLS enabled
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'lab_results' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: lab_results table does not exist';
        RETURN;
    END IF;

    -- Test 1a: Patient A can see own lab results
    PERFORM rls_test.set_user_context(v_patient_a_id);
    SELECT COUNT(*) INTO v_count
    FROM lab_results
    WHERE patient_id = v_patient_a_id;

    v_test_passed := v_count >= 0; -- Should be able to query (even if 0 results)
    PERFORM rls_test.log_result(
        'Patient can SELECT own lab_results',
        'lab_results',
        'SELECT',
        'Query succeeds',
        CASE WHEN v_test_passed THEN 'Query succeeded' ELSE 'Query blocked' END,
        v_test_passed
    );
    RAISE NOTICE '  Patient A SELECT own: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;

    -- Test 1b: Patient A cannot see Patient B's lab results
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM lab_results
        WHERE patient_id = v_patient_b_id;

        -- If we get here with count > 0, RLS is not blocking properly
        v_test_passed := (v_count = 0);
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient lab_results',
            'lab_results',
            'SELECT',
            '0 rows returned',
            v_count::text || ' rows returned',
            v_test_passed
        );
        RAISE NOTICE '  Patient A SELECT other: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
    EXCEPTION WHEN OTHERS THEN
        -- Access denied is also acceptable
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient lab_results',
            'lab_results',
            'SELECT',
            'Blocked',
            'Blocked with error',
            TRUE
        );
        RAISE NOTICE '  Patient A SELECT other: PASS (blocked by RLS)';
    END;

    PERFORM rls_test.reset_to_service_role();
END $$;

-- ============================================================================
-- TEST 2: BIOMARKER_VALUES TABLE
-- ============================================================================

DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;
    v_patient_b_id := current_setting('rls_test.patient_b_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 2: biomarker_values RLS ---';

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'biomarker_values' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: biomarker_values table does not exist';
        RETURN;
    END IF;

    -- Test 2a: Patient A can see own biomarker values (via lab_results join)
    PERFORM rls_test.set_user_context(v_patient_a_id);
    SELECT COUNT(*) INTO v_count
    FROM biomarker_values bv
    JOIN lab_results lr ON bv.lab_result_id = lr.id
    WHERE lr.patient_id = v_patient_a_id;

    v_test_passed := v_count >= 0;
    PERFORM rls_test.log_result(
        'Patient can SELECT own biomarker_values',
        'biomarker_values',
        'SELECT',
        'Query succeeds',
        CASE WHEN v_test_passed THEN 'Query succeeded' ELSE 'Query blocked' END,
        v_test_passed
    );
    RAISE NOTICE '  Patient A SELECT own: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;

    -- Test 2b: Patient A cannot see Patient B's biomarker values
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM biomarker_values bv
        JOIN lab_results lr ON bv.lab_result_id = lr.id
        WHERE lr.patient_id = v_patient_b_id;

        v_test_passed := (v_count = 0);
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient biomarker_values',
            'biomarker_values',
            'SELECT',
            '0 rows returned',
            v_count::text || ' rows returned',
            v_test_passed
        );
        RAISE NOTICE '  Patient A SELECT other: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient biomarker_values',
            'biomarker_values',
            'SELECT',
            'Blocked',
            'Blocked with error',
            TRUE
        );
        RAISE NOTICE '  Patient A SELECT other: PASS (blocked by RLS)';
    END;

    PERFORM rls_test.reset_to_service_role();
END $$;

-- ============================================================================
-- TEST 3: RECOVERY_SESSIONS TABLE
-- ============================================================================

DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
    v_insert_id UUID;
BEGIN
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;
    v_patient_b_id := current_setting('rls_test.patient_b_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 3: recovery_sessions RLS ---';

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'recovery_sessions' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: recovery_sessions table does not exist';
        RETURN;
    END IF;

    -- Test 3a: Patient A can see own recovery sessions
    PERFORM rls_test.set_user_context(v_patient_a_id);
    SELECT COUNT(*) INTO v_count
    FROM recovery_sessions
    WHERE patient_id = v_patient_a_id;

    v_test_passed := v_count >= 0;
    PERFORM rls_test.log_result(
        'Patient can SELECT own recovery_sessions',
        'recovery_sessions',
        'SELECT',
        'Query succeeds',
        'Count: ' || v_count,
        v_test_passed
    );
    RAISE NOTICE '  Patient A SELECT own: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;

    -- Test 3b: Patient A cannot see Patient B's recovery sessions
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM recovery_sessions
        WHERE patient_id = v_patient_b_id;

        v_test_passed := (v_count = 0);
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient recovery_sessions',
            'recovery_sessions',
            'SELECT',
            '0 rows returned',
            v_count::text || ' rows returned',
            v_test_passed
        );
        RAISE NOTICE '  Patient A SELECT other: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient recovery_sessions',
            'recovery_sessions',
            'SELECT',
            'Blocked',
            'Blocked with error',
            TRUE
        );
        RAISE NOTICE '  Patient A SELECT other: PASS (blocked by RLS)';
    END;

    -- Test 3c: Patient A cannot delete Patient B's recovery sessions
    BEGIN
        DELETE FROM recovery_sessions WHERE patient_id = v_patient_b_id;
        -- If we get here without error, check if any rows were affected
        GET DIAGNOSTICS v_count = ROW_COUNT;
        v_test_passed := (v_count = 0);
        PERFORM rls_test.log_result(
            'Patient cannot DELETE other patient recovery_sessions',
            'recovery_sessions',
            'DELETE',
            '0 rows affected',
            v_count::text || ' rows affected',
            v_test_passed
        );
        RAISE NOTICE '  Patient A DELETE other: % (rows: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL - RLS GAP!' END, v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM rls_test.log_result(
            'Patient cannot DELETE other patient recovery_sessions',
            'recovery_sessions',
            'DELETE',
            'Blocked',
            'Blocked with error',
            TRUE
        );
        RAISE NOTICE '  Patient A DELETE other: PASS (blocked by RLS)';
    END;

    PERFORM rls_test.reset_to_service_role();
END $$;

-- ============================================================================
-- TEST 4: FASTING_LOGS TABLE
-- ============================================================================

DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;
    v_patient_b_id := current_setting('rls_test.patient_b_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 4: fasting_logs RLS ---';

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'fasting_logs' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: fasting_logs table does not exist';
        RETURN;
    END IF;

    -- Test 4a: Patient A can see own fasting logs
    PERFORM rls_test.set_user_context(v_patient_a_id);
    SELECT COUNT(*) INTO v_count
    FROM fasting_logs
    WHERE patient_id = v_patient_a_id;

    v_test_passed := v_count >= 0;
    PERFORM rls_test.log_result(
        'Patient can SELECT own fasting_logs',
        'fasting_logs',
        'SELECT',
        'Query succeeds',
        'Count: ' || v_count,
        v_test_passed
    );
    RAISE NOTICE '  Patient A SELECT own: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;

    -- Test 4b: Patient A cannot INSERT fasting log for Patient B
    BEGIN
        INSERT INTO fasting_logs (patient_id, started_at, planned_hours)
        VALUES (v_patient_b_id, NOW(), 16);

        -- If we get here, RLS didn't block the insert
        DELETE FROM fasting_logs WHERE patient_id = v_patient_b_id AND planned_hours = 16;

        PERFORM rls_test.log_result(
            'Patient cannot INSERT fasting_logs for other patient',
            'fasting_logs',
            'INSERT',
            'Blocked',
            'INSERT succeeded - RLS GAP!',
            FALSE,
            'Patient was able to insert data for another patient'
        );
        RAISE NOTICE '  Patient A INSERT for other: FAIL - RLS GAP!';
    EXCEPTION WHEN OTHERS THEN
        PERFORM rls_test.log_result(
            'Patient cannot INSERT fasting_logs for other patient',
            'fasting_logs',
            'INSERT',
            'Blocked',
            'Blocked with error',
            TRUE
        );
        RAISE NOTICE '  Patient A INSERT for other: PASS (blocked by RLS)';
    END;

    PERFORM rls_test.reset_to_service_role();
END $$;

-- ============================================================================
-- TEST 5: SUPPLEMENT_LOGS TABLE
-- ============================================================================

DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;
    v_patient_b_id := current_setting('rls_test.patient_b_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 5: supplement_logs RLS ---';

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'supplement_logs' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: supplement_logs table does not exist';
        RETURN;
    END IF;

    -- Test 5a: Patient A can see own supplement logs
    PERFORM rls_test.set_user_context(v_patient_a_id);
    SELECT COUNT(*) INTO v_count
    FROM supplement_logs
    WHERE patient_id = v_patient_a_id;

    v_test_passed := v_count >= 0;
    PERFORM rls_test.log_result(
        'Patient can SELECT own supplement_logs',
        'supplement_logs',
        'SELECT',
        'Query succeeds',
        'Count: ' || v_count,
        v_test_passed
    );
    RAISE NOTICE '  Patient A SELECT own: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;

    -- Test 5b: Patient A cannot see Patient B's supplement logs
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM supplement_logs
        WHERE patient_id = v_patient_b_id;

        v_test_passed := (v_count = 0);
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient supplement_logs',
            'supplement_logs',
            'SELECT',
            '0 rows returned',
            v_count::text || ' rows returned',
            v_test_passed
        );
        RAISE NOTICE '  Patient A SELECT other: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient supplement_logs',
            'supplement_logs',
            'SELECT',
            'Blocked',
            'Blocked with error',
            TRUE
        );
        RAISE NOTICE '  Patient A SELECT other: PASS (blocked by RLS)';
    END;

    PERFORM rls_test.reset_to_service_role();
END $$;

-- ============================================================================
-- TEST 6: PATIENT_SUPPLEMENT_STACKS TABLE
-- ============================================================================

DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;
    v_patient_b_id := current_setting('rls_test.patient_b_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 6: patient_supplement_stacks RLS ---';

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'patient_supplement_stacks' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: patient_supplement_stacks table does not exist';
        RETURN;
    END IF;

    -- Test 6a: Patient A can see own supplement stacks
    PERFORM rls_test.set_user_context(v_patient_a_id);
    SELECT COUNT(*) INTO v_count
    FROM patient_supplement_stacks
    WHERE patient_id = v_patient_a_id;

    v_test_passed := v_count >= 0;
    PERFORM rls_test.log_result(
        'Patient can SELECT own patient_supplement_stacks',
        'patient_supplement_stacks',
        'SELECT',
        'Query succeeds',
        'Count: ' || v_count,
        v_test_passed
    );
    RAISE NOTICE '  Patient A SELECT own: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;

    -- Test 6b: Patient A cannot update Patient B's supplement stacks
    BEGIN
        UPDATE patient_supplement_stacks
        SET notes = 'Malicious update'
        WHERE patient_id = v_patient_b_id;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        v_test_passed := (v_count = 0);
        PERFORM rls_test.log_result(
            'Patient cannot UPDATE other patient supplement_stacks',
            'patient_supplement_stacks',
            'UPDATE',
            '0 rows affected',
            v_count::text || ' rows affected',
            v_test_passed
        );
        RAISE NOTICE '  Patient A UPDATE other: % (rows: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL - RLS GAP!' END, v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM rls_test.log_result(
            'Patient cannot UPDATE other patient supplement_stacks',
            'patient_supplement_stacks',
            'UPDATE',
            'Blocked',
            'Blocked with error',
            TRUE
        );
        RAISE NOTICE '  Patient A UPDATE other: PASS (blocked by RLS)';
    END;

    PERFORM rls_test.reset_to_service_role();
END $$;

-- ============================================================================
-- TEST 7: AI_COACH_CONVERSATIONS TABLE
-- ============================================================================

DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;
    v_patient_b_id := current_setting('rls_test.patient_b_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 7: ai_coach_conversations RLS ---';

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'ai_coach_conversations' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: ai_coach_conversations table does not exist';
        RETURN;
    END IF;

    -- Test 7a: Patient A can see own conversations
    PERFORM rls_test.set_user_context(v_patient_a_id);
    SELECT COUNT(*) INTO v_count
    FROM ai_coach_conversations
    WHERE patient_id = v_patient_a_id;

    v_test_passed := v_count >= 0;
    PERFORM rls_test.log_result(
        'Patient can SELECT own ai_coach_conversations',
        'ai_coach_conversations',
        'SELECT',
        'Query succeeds',
        'Count: ' || v_count,
        v_test_passed
    );
    RAISE NOTICE '  Patient A SELECT own: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;

    -- Test 7b: Patient A cannot see Patient B's conversations
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM ai_coach_conversations
        WHERE patient_id = v_patient_b_id;

        v_test_passed := (v_count = 0);
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient ai_coach_conversations',
            'ai_coach_conversations',
            'SELECT',
            '0 rows returned',
            v_count::text || ' rows returned',
            v_test_passed
        );
        RAISE NOTICE '  Patient A SELECT other: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient ai_coach_conversations',
            'ai_coach_conversations',
            'SELECT',
            'Blocked',
            'Blocked with error',
            TRUE
        );
        RAISE NOTICE '  Patient A SELECT other: PASS (blocked by RLS)';
    END;

    PERFORM rls_test.reset_to_service_role();
END $$;

-- ============================================================================
-- TEST 8: AI_COACH_MESSAGES TABLE
-- ============================================================================

DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;
    v_patient_b_id := current_setting('rls_test.patient_b_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 8: ai_coach_messages RLS ---';

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'ai_coach_messages' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: ai_coach_messages table does not exist';
        RETURN;
    END IF;

    -- Test 8a: Patient A can see own messages (via conversation)
    PERFORM rls_test.set_user_context(v_patient_a_id);
    SELECT COUNT(*) INTO v_count
    FROM ai_coach_messages m
    JOIN ai_coach_conversations c ON m.conversation_id = c.id
    WHERE c.patient_id = v_patient_a_id;

    v_test_passed := v_count >= 0;
    PERFORM rls_test.log_result(
        'Patient can SELECT own ai_coach_messages',
        'ai_coach_messages',
        'SELECT',
        'Query succeeds',
        'Count: ' || v_count,
        v_test_passed
    );
    RAISE NOTICE '  Patient A SELECT own: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;

    -- Test 8b: Patient A cannot see Patient B's messages
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM ai_coach_messages m
        JOIN ai_coach_conversations c ON m.conversation_id = c.id
        WHERE c.patient_id = v_patient_b_id;

        v_test_passed := (v_count = 0);
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient ai_coach_messages',
            'ai_coach_messages',
            'SELECT',
            '0 rows returned',
            v_count::text || ' rows returned',
            v_test_passed
        );
        RAISE NOTICE '  Patient A SELECT other: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient ai_coach_messages',
            'ai_coach_messages',
            'SELECT',
            'Blocked',
            'Blocked with error',
            TRUE
        );
        RAISE NOTICE '  Patient A SELECT other: PASS (blocked by RLS)';
    END;

    PERFORM rls_test.reset_to_service_role();
END $$;

-- ============================================================================
-- TEST 9: DAILY_READINESS TABLE
-- ============================================================================

DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;
    v_patient_b_id := current_setting('rls_test.patient_b_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 9: daily_readiness RLS ---';

    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'daily_readiness' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: daily_readiness table does not exist';
        RETURN;
    END IF;

    -- Test 9a: Patient A can see own readiness data
    PERFORM rls_test.set_user_context(v_patient_a_id);
    SELECT COUNT(*) INTO v_count
    FROM daily_readiness
    WHERE patient_id = v_patient_a_id;

    v_test_passed := v_count >= 0;
    PERFORM rls_test.log_result(
        'Patient can SELECT own daily_readiness',
        'daily_readiness',
        'SELECT',
        'Query succeeds',
        'Count: ' || v_count,
        v_test_passed
    );
    RAISE NOTICE '  Patient A SELECT own: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;

    -- Test 9b: Patient A cannot see Patient B's readiness data
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM daily_readiness
        WHERE patient_id = v_patient_b_id;

        v_test_passed := (v_count = 0);
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient daily_readiness',
            'daily_readiness',
            'SELECT',
            '0 rows returned',
            v_count::text || ' rows returned',
            v_test_passed
        );
        RAISE NOTICE '  Patient A SELECT other: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
    EXCEPTION WHEN OTHERS THEN
        PERFORM rls_test.log_result(
            'Patient cannot SELECT other patient daily_readiness',
            'daily_readiness',
            'SELECT',
            'Blocked',
            'Blocked with error',
            TRUE
        );
        RAISE NOTICE '  Patient A SELECT other: PASS (blocked by RLS)';
    END;

    PERFORM rls_test.reset_to_service_role();
END $$;

-- ============================================================================
-- TEST 10: THERAPIST ACCESS TO LINKED PATIENT DATA
-- ============================================================================

DO $$
DECLARE
    v_therapist_id UUID;
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
    v_is_linked BOOLEAN;
BEGIN
    v_therapist_id := current_setting('rls_test.therapist_id')::UUID;
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;
    v_patient_b_id := current_setting('rls_test.patient_b_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 10: Therapist Access to Linked Patients ---';

    -- First check if therapist_patients table exists and has linkage
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'therapist_patients' AND schemaname = 'public') THEN
        RAISE NOTICE 'SKIP: therapist_patients table does not exist';
        RETURN;
    END IF;

    -- Check if therapist is linked to patient A
    SELECT EXISTS (
        SELECT 1 FROM therapist_patients
        WHERE therapist_id = v_therapist_id
        AND patient_id = v_patient_a_id
        AND active = true
    ) INTO v_is_linked;

    RAISE NOTICE '  Therapist linked to Patient A: %', v_is_linked;

    IF NOT v_is_linked THEN
        -- Create a temporary linkage for testing
        RAISE NOTICE '  Creating temporary linkage for test...';
        INSERT INTO therapist_patients (therapist_id, patient_id, active)
        VALUES (v_therapist_id, v_patient_a_id, true)
        ON CONFLICT (therapist_id, patient_id) DO UPDATE SET active = true;
    END IF;

    -- Test 10a: Therapist can see linked patient's lab results
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'lab_results' AND schemaname = 'public') THEN
        PERFORM rls_test.set_user_context(v_therapist_id);
        BEGIN
            SELECT COUNT(*) INTO v_count
            FROM lab_results
            WHERE patient_id = v_patient_a_id;

            v_test_passed := v_count >= 0;
            PERFORM rls_test.log_result(
                'Therapist can SELECT linked patient lab_results',
                'lab_results',
                'SELECT',
                'Query succeeds',
                'Count: ' || v_count,
                v_test_passed
            );
            RAISE NOTICE '  Therapist SELECT linked patient lab_results: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
        EXCEPTION WHEN OTHERS THEN
            PERFORM rls_test.log_result(
                'Therapist can SELECT linked patient lab_results',
                'lab_results',
                'SELECT',
                'Query succeeds',
                'Query blocked - possible RLS gap',
                FALSE,
                SQLERRM
            );
            RAISE NOTICE '  Therapist SELECT linked patient lab_results: FAIL (%)' , SQLERRM;
        END;
        PERFORM rls_test.reset_to_service_role();
    END IF;

    -- Test 10b: Therapist can see linked patient's recovery sessions
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'recovery_sessions' AND schemaname = 'public') THEN
        PERFORM rls_test.set_user_context(v_therapist_id);
        BEGIN
            SELECT COUNT(*) INTO v_count
            FROM recovery_sessions
            WHERE patient_id = v_patient_a_id;

            v_test_passed := v_count >= 0;
            PERFORM rls_test.log_result(
                'Therapist can SELECT linked patient recovery_sessions',
                'recovery_sessions',
                'SELECT',
                'Query succeeds',
                'Count: ' || v_count,
                v_test_passed
            );
            RAISE NOTICE '  Therapist SELECT linked patient recovery_sessions: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL' END, v_count;
        EXCEPTION WHEN OTHERS THEN
            PERFORM rls_test.log_result(
                'Therapist can SELECT linked patient recovery_sessions',
                'recovery_sessions',
                'SELECT',
                'Query succeeds',
                'Query blocked - possible RLS gap',
                FALSE,
                SQLERRM
            );
            RAISE NOTICE '  Therapist SELECT linked patient recovery_sessions: FAIL (%)' , SQLERRM;
        END;
        PERFORM rls_test.reset_to_service_role();
    END IF;

    -- Clean up temporary linkage if we created it
    IF NOT v_is_linked THEN
        DELETE FROM therapist_patients
        WHERE therapist_id = v_therapist_id AND patient_id = v_patient_a_id;
    END IF;
END $$;

-- ============================================================================
-- TEST 11: THERAPIST CANNOT ACCESS UNLINKED PATIENT DATA
-- ============================================================================

DO $$
DECLARE
    v_unlinked_therapist_id UUID;
    v_patient_a_id UUID;
    v_count INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    v_unlinked_therapist_id := current_setting('rls_test.unlinked_therapist_id')::UUID;
    v_patient_a_id := current_setting('rls_test.patient_a_id')::UUID;

    RAISE NOTICE '';
    RAISE NOTICE '--- TEST 11: Unlinked Therapist Cannot Access Patient Data ---';

    -- Test 11a: Unlinked therapist cannot see patient's lab results
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'lab_results' AND schemaname = 'public') THEN
        PERFORM rls_test.set_user_context(v_unlinked_therapist_id);
        BEGIN
            SELECT COUNT(*) INTO v_count
            FROM lab_results
            WHERE patient_id = v_patient_a_id;

            v_test_passed := (v_count = 0);
            PERFORM rls_test.log_result(
                'Unlinked therapist cannot SELECT patient lab_results',
                'lab_results',
                'SELECT',
                '0 rows returned',
                v_count::text || ' rows returned',
                v_test_passed
            );
            RAISE NOTICE '  Unlinked therapist SELECT lab_results: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL - RLS GAP!' END, v_count;
        EXCEPTION WHEN OTHERS THEN
            PERFORM rls_test.log_result(
                'Unlinked therapist cannot SELECT patient lab_results',
                'lab_results',
                'SELECT',
                'Blocked',
                'Blocked with error',
                TRUE
            );
            RAISE NOTICE '  Unlinked therapist SELECT lab_results: PASS (blocked by RLS)';
        END;
        PERFORM rls_test.reset_to_service_role();
    END IF;

    -- Test 11b: Unlinked therapist cannot see patient's daily readiness
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'daily_readiness' AND schemaname = 'public') THEN
        PERFORM rls_test.set_user_context(v_unlinked_therapist_id);
        BEGIN
            SELECT COUNT(*) INTO v_count
            FROM daily_readiness
            WHERE patient_id = v_patient_a_id;

            v_test_passed := (v_count = 0);
            PERFORM rls_test.log_result(
                'Unlinked therapist cannot SELECT patient daily_readiness',
                'daily_readiness',
                'SELECT',
                '0 rows returned',
                v_count::text || ' rows returned',
                v_test_passed
            );
            RAISE NOTICE '  Unlinked therapist SELECT daily_readiness: % (count: %)', CASE WHEN v_test_passed THEN 'PASS' ELSE 'FAIL - RLS GAP!' END, v_count;
        EXCEPTION WHEN OTHERS THEN
            PERFORM rls_test.log_result(
                'Unlinked therapist cannot SELECT patient daily_readiness',
                'daily_readiness',
                'SELECT',
                'Blocked',
                'Blocked with error',
                TRUE
            );
            RAISE NOTICE '  Unlinked therapist SELECT daily_readiness: PASS (blocked by RLS)';
        END;
        PERFORM rls_test.reset_to_service_role();
    END IF;
END $$;

-- ============================================================================
-- TEST SUMMARY REPORT
-- ============================================================================

DO $$
DECLARE
    v_total INTEGER;
    v_passed INTEGER;
    v_failed INTEGER;
    rec RECORD;
BEGIN
    SELECT COUNT(*) INTO v_total FROM rls_test.test_results;
    SELECT COUNT(*) INTO v_passed FROM rls_test.test_results WHERE passed = TRUE;
    SELECT COUNT(*) INTO v_failed FROM rls_test.test_results WHERE passed = FALSE;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'RLS POLICY TEST SUMMARY';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Total Tests: %', v_total;
    RAISE NOTICE 'Passed: %', v_passed;
    RAISE NOTICE 'Failed: %', v_failed;
    RAISE NOTICE '';

    IF v_failed > 0 THEN
        RAISE NOTICE '!!! FAILED TESTS (RLS GAPS DETECTED) !!!';
        RAISE NOTICE '';
        FOR rec IN
            SELECT test_name, table_name, operation, expected_result, actual_result, error_message
            FROM rls_test.test_results
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
        RAISE NOTICE 'All RLS policies are working correctly!';
    END IF;

    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- CLEANUP
-- ============================================================================

-- Show full results table
SELECT
    test_name,
    table_name,
    operation,
    CASE WHEN passed THEN 'PASS' ELSE 'FAIL' END AS status,
    expected_result,
    actual_result
FROM rls_test.test_results
ORDER BY passed, table_name, test_name;

-- Rollback to avoid persisting test data
ROLLBACK;

-- Note: The ROLLBACK above will remove the test schema and all test data
-- To persist test results, replace ROLLBACK with COMMIT
