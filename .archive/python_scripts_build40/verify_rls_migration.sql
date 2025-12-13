-- ============================================================================
-- RLS Migration Verification Queries
-- Run these after applying 009_fix_rls_policies.sql
-- ============================================================================

-- ============================================================================
-- STEP 1: VERIFY SCHEMA CHANGES
-- ============================================================================

-- Check user_id column exists in patients table
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'patients' AND column_name = 'user_id';

-- Expected: 1 row showing user_id column (uuid type)

-- ============================================================================
-- STEP 2: VERIFY RLS POLICIES CREATED
-- ============================================================================

-- Count patient-facing policies
SELECT COUNT(*) as patient_policies
FROM pg_policies
WHERE schemaname = 'public' AND policyname LIKE 'patients_%';

-- Expected: 11 policies

-- Count therapist-facing policies
SELECT COUNT(*) as therapist_policies
FROM pg_policies
WHERE schemaname = 'public' AND policyname LIKE 'therapists_%';

-- Expected: 11 policies

-- Total RLS policies
SELECT COUNT(*) as total_rls_policies
FROM pg_policies
WHERE schemaname = 'public'
  AND (policyname LIKE 'patients_%' OR policyname LIKE 'therapists_%');

-- Expected: 22 policies

-- ============================================================================
-- STEP 3: LIST ALL CREATED POLICIES
-- ============================================================================

-- Show all patient policies with their tables
SELECT
  tablename,
  policyname,
  cmd as operation
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname LIKE 'patients_%'
ORDER BY tablename, policyname;

-- Expected tables:
-- - phases, sessions, session_exercises
-- - exercise_logs, pain_logs, bullpen_logs, plyo_logs
-- - session_notes, body_comp_measurements, session_status, pain_flags

-- Show all therapist policies with their tables
SELECT
  tablename,
  policyname,
  cmd as operation
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname LIKE 'therapists_%'
ORDER BY tablename, policyname;

-- ============================================================================
-- STEP 4: LINK PATIENTS TO AUTH USERS
-- ============================================================================

-- Check current patient linking status
SELECT
  id,
  first_name,
  last_name,
  email,
  user_id,
  CASE WHEN user_id IS NULL THEN '❌ Not Linked' ELSE '✅ Linked' END as status
FROM patients
ORDER BY email;

-- Link patients by email (UPDATE)
UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.user_id IS NULL
  AND p.email IS NOT NULL;

-- Verify linking results
SELECT
  COUNT(*) as total_patients,
  COUNT(user_id) as linked_patients,
  COUNT(*) - COUNT(user_id) as unlinked_patients,
  ROUND(100.0 * COUNT(user_id) / NULLIF(COUNT(*), 0), 1) as percent_linked
FROM patients;

-- Expected: 100% linked (or close to it)

-- ============================================================================
-- STEP 5: TEST DATA ACCESS
-- ============================================================================

-- Test query: Session exercises (tests hierarchical policies)
SELECT
  s.name as session_name,
  se.target_sets,
  se.target_reps,
  et.name as exercise_name
FROM sessions s
JOIN phases ph ON s.phase_id = ph.id
JOIN programs pr ON ph.program_id = pr.id
JOIN session_exercises se ON se.session_id = s.id
JOIN exercise_templates et ON se.exercise_template_id = et.id
LIMIT 5;

-- Expected: Returns 5 rows with session/exercise data

-- Test query: Exercise logs (tests direct patient_id policies)
SELECT
  el.completed_at::date as date,
  et.name as exercise,
  el.sets_completed,
  el.reps_completed
FROM exercise_logs el
JOIN exercise_templates et ON el.exercise_template_id = et.id
ORDER BY el.completed_at DESC
LIMIT 5;

-- Expected: Returns exercise log data

-- Test query: Pain logs
SELECT
  pain_level,
  pain_location,
  logged_at::date as date
FROM pain_logs
ORDER BY logged_at DESC
LIMIT 5;

-- Expected: Returns pain log data

-- ============================================================================
-- STEP 6: VERIFY RLS IS ENFORCED
-- ============================================================================

-- Check that RLS is enabled on key tables
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'patients', 'programs', 'phases', 'sessions', 'session_exercises',
    'exercise_logs', 'pain_logs', 'bullpen_logs', 'plyo_logs',
    'session_notes', 'body_comp_measurements', 'session_status', 'pain_flags'
  )
ORDER BY tablename;

-- Expected: All tables should have rls_enabled = true

-- ============================================================================
-- STEP 7: PATIENT-SPECIFIC VERIFICATION
-- ============================================================================

-- Get demo patient info
SELECT
  id,
  first_name,
  last_name,
  email,
  user_id,
  therapist_id
FROM patients
WHERE email = 'demo-athlete@ptperformance.app';

-- Expected: Should return 1 row with user_id populated

-- Count data accessible to demo patient
WITH demo_patient AS (
  SELECT id FROM patients WHERE email = 'demo-athlete@ptperformance.app'
)
SELECT
  'programs' as table_name,
  COUNT(*) as record_count
FROM programs
WHERE patient_id IN (SELECT id FROM demo_patient)

UNION ALL

SELECT
  'sessions',
  COUNT(*)
FROM sessions s
JOIN phases ph ON s.phase_id = ph.id
JOIN programs pr ON ph.program_id = pr.id
WHERE pr.patient_id IN (SELECT id FROM demo_patient)

UNION ALL

SELECT
  'exercise_logs',
  COUNT(*)
FROM exercise_logs
WHERE patient_id IN (SELECT id FROM demo_patient)

UNION ALL

SELECT
  'pain_logs',
  COUNT(*)
FROM pain_logs
WHERE patient_id IN (SELECT id FROM demo_patient);

-- Expected: Should show counts for each table type

-- ============================================================================
-- STEP 8: SUMMARY REPORT
-- ============================================================================

-- Complete verification summary
SELECT
  '1. user_id column' as check_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'patients' AND column_name = 'user_id'
  ) THEN '✅ PASS' ELSE '❌ FAIL' END as status

UNION ALL

SELECT
  '2. Patient policies (11)',
  CASE WHEN (
    SELECT COUNT(*) FROM pg_policies
    WHERE policyname LIKE 'patients_%'
  ) = 11 THEN '✅ PASS' ELSE '❌ FAIL' END

UNION ALL

SELECT
  '3. Therapist policies (11)',
  CASE WHEN (
    SELECT COUNT(*) FROM pg_policies
    WHERE policyname LIKE 'therapists_%'
  ) = 11 THEN '✅ PASS' ELSE '❌ FAIL' END

UNION ALL

SELECT
  '4. Patients linked',
  CASE WHEN (
    SELECT COUNT(*) FROM patients WHERE user_id IS NOT NULL
  ) > 0 THEN '✅ PASS' ELSE '❌ FAIL' END

UNION ALL

SELECT
  '5. Sessions accessible',
  CASE WHEN (
    SELECT COUNT(*) FROM sessions LIMIT 1
  ) > 0 THEN '✅ PASS' ELSE '❌ FAIL' END;

-- Expected: All checks should show '✅ PASS'

-- ============================================================================
-- SUCCESS CONFIRMATION
-- ============================================================================

SELECT
  '🎉 RLS Migration Verification Complete!' as message,
  NOW() as verified_at;

-- If all queries above ran successfully and showed expected results,
-- the RLS migration has been successfully applied!
--
-- Next step: Test iOS app Build 8
-- - Login as demo-athlete@ptperformance.app
-- - Navigate to "Today's Session"
-- - Verify data loads without error
