-- ============================================================================
-- RLS Policy Fix Verification Script
-- Run this after applying migration 009_fix_rls_policies.sql
-- Date: 2025-12-09
-- ============================================================================

-- TEST 1: Verify user_id column exists on patients table
-- Expected: 1 row showing user_id column
SELECT '=== TEST 1: Verify user_id Column ===' as test;

SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'patients'
  AND column_name = 'user_id';

-- TEST 2: Verify user_id index exists
-- Expected: 1 row showing idx_patients_user_id
SELECT '=== TEST 2: Verify user_id Index ===' as test;

SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'patients'
  AND indexname = 'idx_patients_user_id';

-- TEST 3: Count RLS policies per table
-- Expected: Each core table should have 2 policies (patient + therapist)
SELECT '=== TEST 3: Policy Count Per Table ===' as test;

SELECT
  tablename,
  COUNT(*) as policy_count,
  string_agg(policyname, ', ' ORDER BY policyname) as policies
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'patients', 'programs', 'phases', 'sessions', 'session_exercises',
    'exercise_logs', 'pain_logs', 'bullpen_logs', 'plyo_logs',
    'session_notes', 'body_comp_measurements', 'session_status', 'pain_flags'
  )
GROUP BY tablename
ORDER BY tablename;

-- TEST 4: List all patient-facing policies
-- Expected: 13 policies starting with 'patients_see_own_'
SELECT '=== TEST 4: Patient Policies ===' as test;

SELECT
  tablename,
  policyname,
  cmd as operation
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname LIKE 'patients_%'
ORDER BY tablename, policyname;

-- TEST 5: List all therapist-facing policies
-- Expected: 13 policies starting with 'therapists_see_patient_'
SELECT '=== TEST 5: Therapist Policies ===' as test;

SELECT
  tablename,
  policyname,
  cmd as operation
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname LIKE 'therapists_%'
ORDER BY tablename, policyname;

-- TEST 6: Check RLS is enabled on all tables
-- Expected: All core tables have RLS enabled
SELECT '=== TEST 6: RLS Enabled Status ===' as test;

SELECT
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'patients', 'therapists', 'programs', 'phases', 'sessions',
    'session_exercises', 'exercise_logs', 'pain_logs', 'bullpen_logs',
    'plyo_logs', 'session_notes', 'body_comp_measurements',
    'session_status', 'pain_flags', 'exercise_templates'
  )
ORDER BY tablename;

-- TEST 7: Check existing patient records
-- Expected: Shows current patient records and their user_id status
SELECT '=== TEST 7: Patient Records Status ===' as test;

SELECT
  id,
  first_name,
  last_name,
  email,
  user_id,
  CASE
    WHEN user_id IS NULL THEN '❌ NOT LINKED'
    ELSE '✅ LINKED'
  END as auth_status,
  therapist_id,
  created_at
FROM patients
ORDER BY created_at DESC
LIMIT 10;

-- TEST 8: Check auth users
-- Expected: Shows auth.users records
SELECT '=== TEST 8: Auth Users ===' as test;

SELECT
  id,
  email,
  created_at,
  confirmed_at IS NOT NULL as email_confirmed,
  last_sign_in_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- TEST 9: Sample data query (tests hierarchical joins)
-- Expected: Returns session data if patients have programs/phases/sessions
SELECT '=== TEST 9: Sample Data Query ===' as test;

SELECT
  p.first_name || ' ' || p.last_name as patient_name,
  p.email as patient_email,
  pr.name as program_name,
  ph.name as phase_name,
  s.name as session_name,
  s.target_date,
  COUNT(se.id) as exercise_count
FROM patients p
LEFT JOIN programs pr ON pr.patient_id = p.id
LEFT JOIN phases ph ON ph.program_id = pr.id
LEFT JOIN sessions s ON s.phase_id = ph.id
LEFT JOIN session_exercises se ON se.session_id = s.id
GROUP BY p.id, p.first_name, p.last_name, p.email, pr.name, ph.name, s.name, s.target_date
ORDER BY p.created_at DESC, s.target_date
LIMIT 10;

-- TEST 10: Policy coverage summary
-- Expected: Shows which tables have complete policy coverage
SELECT '=== TEST 10: Policy Coverage Summary ===' as test;

WITH table_list AS (
  SELECT unnest(ARRAY[
    'patients', 'programs', 'phases', 'sessions', 'session_exercises',
    'exercise_logs', 'pain_logs', 'bullpen_logs', 'plyo_logs',
    'session_notes', 'body_comp_measurements', 'session_status', 'pain_flags'
  ]) as tablename
),
policy_counts AS (
  SELECT
    tablename,
    COUNT(CASE WHEN policyname LIKE 'patients_%' THEN 1 END) as patient_policies,
    COUNT(CASE WHEN policyname LIKE 'therapists_%' THEN 1 END) as therapist_policies,
    COUNT(*) as total_policies
  FROM pg_policies
  WHERE schemaname = 'public'
  GROUP BY tablename
)
SELECT
  tl.tablename,
  COALESCE(pc.patient_policies, 0) as patient_policies,
  COALESCE(pc.therapist_policies, 0) as therapist_policies,
  COALESCE(pc.total_policies, 0) as total_policies,
  CASE
    WHEN COALESCE(pc.patient_policies, 0) >= 1
     AND COALESCE(pc.therapist_policies, 0) >= 1 THEN '✅ COMPLETE'
    WHEN COALESCE(pc.patient_policies, 0) >= 1 THEN '⚠️  PARTIAL (patient only)'
    WHEN COALESCE(pc.therapist_policies, 0) >= 1 THEN '⚠️  PARTIAL (therapist only)'
    ELSE '❌ NO POLICIES'
  END as status
FROM table_list tl
LEFT JOIN policy_counts pc ON tl.tablename = pc.tablename
ORDER BY tl.tablename;

-- ============================================================================
-- SUMMARY
-- ============================================================================

SELECT '=== VERIFICATION SUMMARY ===' as summary;

SELECT
  'Total Tables Checked' as metric,
  COUNT(DISTINCT tablename)::text as value
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'patients', 'programs', 'phases', 'sessions', 'session_exercises',
    'exercise_logs', 'pain_logs', 'bullpen_logs', 'plyo_logs',
    'session_notes', 'body_comp_measurements', 'session_status', 'pain_flags'
  )
UNION ALL
SELECT
  'Total Policies Created' as metric,
  COUNT(*)::text as value
FROM pg_policies
WHERE schemaname = 'public'
  AND (policyname LIKE 'patients_%' OR policyname LIKE 'therapists_%')
  AND tablename IN (
    'patients', 'programs', 'phases', 'sessions', 'session_exercises',
    'exercise_logs', 'pain_logs', 'bullpen_logs', 'plyo_logs',
    'session_notes', 'body_comp_measurements', 'session_status', 'pain_flags'
  )
UNION ALL
SELECT
  'Patient Policies' as metric,
  COUNT(*)::text as value
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname LIKE 'patients_%'
UNION ALL
SELECT
  'Therapist Policies' as metric,
  COUNT(*)::text as value
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname LIKE 'therapists_%';

-- ============================================================================
-- EXPECTED RESULTS SUMMARY:
-- ============================================================================
-- TEST 1: Should return 1 row with user_id | uuid | YES
-- TEST 2: Should return 1 row with idx_patients_user_id
-- TEST 3: Should show 13 tables, each with 2 policies
-- TEST 4: Should show 13 patient policies
-- TEST 5: Should show 13+ therapist policies
-- TEST 6: Should show all tables with rls_enabled = true
-- TEST 7: Shows patient records - need to link user_id if NULL
-- TEST 8: Shows auth users
-- TEST 9: Shows sample data if exists
-- TEST 10: Shows all 13 tables with ✅ COMPLETE status
-- ============================================================================
