-- ============================================================================
-- RLS POLICY TESTS (pgTAP format for supabase test db)
-- ============================================================================
-- Purpose: Verify Row Level Security policies work correctly
-- Usage: supabase test db
--
-- Date: 2026-02-03
-- ============================================================================

BEGIN;

-- Load pgTAP extension
SELECT plan(50);  -- Adjust based on actual test count

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to simulate authenticated user
CREATE OR REPLACE FUNCTION set_auth_user(user_id UUID)
RETURNS VOID AS $$
BEGIN
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
CREATE OR REPLACE FUNCTION reset_auth()
RETURNS VOID AS $$
BEGIN
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', '', true);
END;
$$ LANGUAGE plpgsql;

-- Get test patient IDs
DO $$
DECLARE
    v_patient_a_id UUID;
    v_patient_b_id UUID;
    v_therapist_id UUID;
BEGIN
    SELECT id INTO v_patient_a_id FROM patients ORDER BY created_at LIMIT 1;
    SELECT id INTO v_patient_b_id FROM patients ORDER BY created_at OFFSET 1 LIMIT 1;
    SELECT user_id INTO v_therapist_id FROM therapists WHERE user_id IS NOT NULL LIMIT 1;

    PERFORM set_config('test.patient_a_id', COALESCE(v_patient_a_id::text, gen_random_uuid()::text), false);
    PERFORM set_config('test.patient_b_id', COALESCE(v_patient_b_id::text, gen_random_uuid()::text), false);
    PERFORM set_config('test.therapist_id', COALESCE(v_therapist_id::text, gen_random_uuid()::text), false);
END $$;

-- ============================================================================
-- TEST: RLS IS ENABLED ON ALL SENSITIVE TABLES
-- ============================================================================

SELECT has_table('public', 'patients', 'patients table exists');
SELECT has_table('public', 'daily_readiness', 'daily_readiness table exists');

-- Check RLS is enabled
SELECT ok(
    (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'lab_results'),
    'RLS is enabled on lab_results'
);

SELECT ok(
    (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'biomarker_values'),
    'RLS is enabled on biomarker_values'
);

SELECT ok(
    (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'recovery_sessions'),
    'RLS is enabled on recovery_sessions'
);

SELECT ok(
    (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'fasting_logs'),
    'RLS is enabled on fasting_logs'
);

SELECT ok(
    (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'supplement_logs'),
    'RLS is enabled on supplement_logs'
);

SELECT ok(
    (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'patient_supplement_stacks'),
    'RLS is enabled on patient_supplement_stacks'
);

SELECT ok(
    (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'ai_coach_conversations'),
    'RLS is enabled on ai_coach_conversations'
);

SELECT ok(
    (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'ai_coach_messages'),
    'RLS is enabled on ai_coach_messages'
);

SELECT ok(
    (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'daily_readiness'),
    'RLS is enabled on daily_readiness'
);

-- ============================================================================
-- TEST: POLICIES EXIST FOR ALL SENSITIVE TABLES
-- ============================================================================

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'lab_results'),
    'lab_results has RLS policies'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'biomarker_values'),
    'biomarker_values has RLS policies'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'recovery_sessions'),
    'recovery_sessions has RLS policies'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'fasting_logs'),
    'fasting_logs has RLS policies'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'supplement_logs'),
    'supplement_logs has RLS policies'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'patient_supplement_stacks'),
    'patient_supplement_stacks has RLS policies'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'ai_coach_conversations'),
    'ai_coach_conversations has RLS policies'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'ai_coach_messages'),
    'ai_coach_messages has RLS policies'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'daily_readiness'),
    'daily_readiness has RLS policies'
);

-- ============================================================================
-- TEST: POLICY TYPES EXIST (SELECT, INSERT, UPDATE, DELETE)
-- ============================================================================

-- Check lab_results has all CRUD policies
SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'lab_results' AND cmd = 'SELECT'),
    'lab_results has SELECT policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'lab_results' AND cmd = 'INSERT'),
    'lab_results has INSERT policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'lab_results' AND cmd = 'UPDATE'),
    'lab_results has UPDATE policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'lab_results' AND cmd = 'DELETE'),
    'lab_results has DELETE policy'
);

-- Check fasting_logs has all CRUD policies
SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'fasting_logs' AND cmd = 'SELECT'),
    'fasting_logs has SELECT policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'fasting_logs' AND cmd = 'INSERT'),
    'fasting_logs has INSERT policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'fasting_logs' AND cmd = 'UPDATE'),
    'fasting_logs has UPDATE policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'fasting_logs' AND cmd = 'DELETE'),
    'fasting_logs has DELETE policy'
);

-- Check supplement_logs has all CRUD policies
SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'supplement_logs' AND cmd = 'SELECT'),
    'supplement_logs has SELECT policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'supplement_logs' AND cmd = 'INSERT'),
    'supplement_logs has INSERT policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'supplement_logs' AND cmd = 'UPDATE'),
    'supplement_logs has UPDATE policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'supplement_logs' AND cmd = 'DELETE'),
    'supplement_logs has DELETE policy'
);

-- Check daily_readiness has all CRUD policies
SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'daily_readiness' AND cmd = 'SELECT'),
    'daily_readiness has SELECT policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'daily_readiness' AND cmd = 'INSERT'),
    'daily_readiness has INSERT policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'daily_readiness' AND cmd = 'UPDATE'),
    'daily_readiness has UPDATE policy'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'daily_readiness' AND cmd = 'DELETE'),
    'daily_readiness has DELETE policy'
);

-- ============================================================================
-- TEST: POLICIES USE auth.uid() FOR PATIENT ACCESS
-- ============================================================================

-- Check that SELECT policies reference auth.uid()
SELECT ok(
    (SELECT qual LIKE '%auth.uid()%' FROM pg_policies
     WHERE tablename = 'lab_results' AND cmd = 'SELECT' AND policyname LIKE '%Patients%' LIMIT 1),
    'lab_results patient SELECT policy uses auth.uid()'
);

SELECT ok(
    (SELECT qual LIKE '%auth.uid()%' FROM pg_policies
     WHERE tablename = 'fasting_logs' AND cmd = 'SELECT' AND policyname LIKE '%Patients%' LIMIT 1),
    'fasting_logs patient SELECT policy uses auth.uid()'
);

SELECT ok(
    (SELECT qual LIKE '%auth.uid()%' FROM pg_policies
     WHERE tablename = 'supplement_logs' AND cmd = 'SELECT' AND policyname LIKE '%Patients%' LIMIT 1),
    'supplement_logs patient SELECT policy uses auth.uid()'
);

SELECT ok(
    (SELECT qual LIKE '%auth.uid()%' FROM pg_policies
     WHERE tablename = 'daily_readiness' AND cmd = 'SELECT' AND policyname LIKE '%Patients%' LIMIT 1),
    'daily_readiness patient SELECT policy uses auth.uid()'
);

-- ============================================================================
-- TEST: THERAPIST POLICIES USE PROPER LINKAGE CHECK
-- ============================================================================

-- Check that therapist SELECT policies reference therapist_patients table
SELECT ok(
    (SELECT qual LIKE '%therapist_patients%' FROM pg_policies
     WHERE tablename = 'lab_results' AND cmd = 'SELECT' AND policyname LIKE '%Therapist%' LIMIT 1),
    'lab_results therapist SELECT policy checks therapist_patients linkage'
);

SELECT ok(
    (SELECT qual LIKE '%therapist_patients%' FROM pg_policies
     WHERE tablename = 'recovery_sessions' AND cmd = 'SELECT' AND policyname LIKE '%Therapist%' LIMIT 1),
    'recovery_sessions therapist SELECT policy checks therapist_patients linkage'
);

SELECT ok(
    (SELECT qual LIKE '%therapist_patients%' FROM pg_policies
     WHERE tablename = 'fasting_logs' AND cmd = 'SELECT' AND policyname LIKE '%Therapist%' LIMIT 1),
    'fasting_logs therapist SELECT policy checks therapist_patients linkage'
);

SELECT ok(
    (SELECT qual LIKE '%therapist_patients%' FROM pg_policies
     WHERE tablename = 'supplement_logs' AND cmd = 'SELECT' AND policyname LIKE '%Therapist%' LIMIT 1),
    'supplement_logs therapist SELECT policy checks therapist_patients linkage'
);

-- ============================================================================
-- TEST: NO OVERLY PERMISSIVE POLICIES
-- ============================================================================

-- Check no policies use just 'true' as their condition (except for service_role)
SELECT ok(
    NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename IN ('lab_results', 'biomarker_values', 'recovery_sessions',
                           'fasting_logs', 'supplement_logs', 'patient_supplement_stacks',
                           'ai_coach_conversations', 'ai_coach_messages', 'daily_readiness')
        AND (qual = 'true' OR qual = '(true)')
        AND roles::text NOT LIKE '%service_role%'
    ),
    'No overly permissive policies (using just true) on sensitive tables'
);

-- ============================================================================
-- TEST: AI COACH MESSAGES INHERIT ACCESS FROM CONVERSATIONS
-- ============================================================================

SELECT ok(
    (SELECT qual LIKE '%ai_coach_conversations%' FROM pg_policies
     WHERE tablename = 'ai_coach_messages' AND cmd = 'SELECT' LIMIT 1),
    'ai_coach_messages policy checks conversation ownership'
);

-- ============================================================================
-- TEST: BIOMARKER VALUES INHERIT ACCESS FROM LAB RESULTS
-- ============================================================================

SELECT ok(
    (SELECT qual LIKE '%lab_results%' FROM pg_policies
     WHERE tablename = 'biomarker_values' AND cmd = 'SELECT' LIMIT 1),
    'biomarker_values policy checks lab_result ownership'
);

-- ============================================================================
-- TEST: THERAPIST_PATIENTS TABLE HAS PROPER RLS
-- ============================================================================

SELECT ok(
    (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'therapist_patients'),
    'RLS is enabled on therapist_patients'
);

SELECT ok(
    (SELECT COUNT(*) > 0 FROM pg_policies WHERE tablename = 'therapist_patients'),
    'therapist_patients has RLS policies'
);

-- ============================================================================
-- FINISH
-- ============================================================================

SELECT * FROM finish();

ROLLBACK;
