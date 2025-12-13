-- ============================================================================
-- ANALYTICS VIEWS VERIFICATION SCRIPT
-- ============================================================================
-- Run this script after applying create_analytics_views.sql
-- This will verify that all views are created correctly and return expected data
-- ============================================================================

-- Set search path
SET search_path TO public;

-- ============================================================================
-- TEST 1: Verify Views Exist
-- ============================================================================
\echo ''
\echo '=========================================================================='
\echo 'TEST 1: Verify Views Exist'
\echo '=========================================================================='

SELECT
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('vw_pain_trend', 'vw_patient_adherence', 'vw_patient_sessions')
ORDER BY table_name;

\echo ''
\echo 'Expected: 3 rows (vw_pain_trend, vw_patient_adherence, vw_patient_sessions)'
\echo ''

-- ============================================================================
-- TEST 2: Verify Permissions
-- ============================================================================
\echo ''
\echo '=========================================================================='
\echo 'TEST 2: Verify View Permissions'
\echo '=========================================================================='

SELECT
  table_name,
  grantee,
  privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN ('vw_pain_trend', 'vw_patient_adherence', 'vw_patient_sessions')
  AND grantee IN ('authenticated', 'service_role')
ORDER BY table_name, grantee;

\echo ''
\echo 'Expected: 6 rows (each view with SELECT for authenticated and service_role)'
\echo ''

-- ============================================================================
-- TEST 3: Check View Schemas
-- ============================================================================
\echo ''
\echo '=========================================================================='
\echo 'TEST 3: Check View Schemas'
\echo '=========================================================================='

\echo ''
\echo 'vw_pain_trend columns:'
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'vw_pain_trend'
ORDER BY ordinal_position;

\echo ''
\echo 'Expected columns: id (text), patient_id (uuid), logged_date (date), avg_pain (numeric), session_number (integer)'
\echo ''

\echo ''
\echo 'vw_patient_adherence columns:'
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'vw_patient_adherence'
ORDER BY ordinal_position;

\echo ''
\echo 'Expected columns: patient_id (uuid), first_name (varchar), last_name (varchar), total_sessions (bigint), completed_sessions (bigint), adherence_pct (numeric)'
\echo ''

\echo ''
\echo 'vw_patient_sessions columns:'
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'vw_patient_sessions'
ORDER BY ordinal_position;

\echo ''
\echo 'Expected columns: id, name, session_number, patient_id, phase_id, program_id, weekday, notes, created_at, intensity_rating, is_throwing_day, session_date, completed, exercise_count, avg_pain_score'
\echo ''

-- ============================================================================
-- TEST 4: Count Data in Views
-- ============================================================================
\echo ''
\echo '=========================================================================='
\echo 'TEST 4: Count Data in All Views'
\echo '=========================================================================='

SELECT
  'vw_pain_trend' AS view_name,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT patient_id) AS unique_patients
FROM vw_pain_trend
UNION ALL
SELECT
  'vw_patient_adherence',
  COUNT(*),
  COUNT(DISTINCT patient_id)
FROM vw_patient_adherence
UNION ALL
SELECT
  'vw_patient_sessions',
  COUNT(*),
  COUNT(DISTINCT patient_id)
FROM vw_patient_sessions;

\echo ''
\echo 'Expected: All views should have data (rows > 0)'
\echo ''

-- ============================================================================
-- TEST 5: Test with Demo Patient
-- ============================================================================
\echo ''
\echo '=========================================================================='
\echo 'TEST 5: Test Views with Demo Patient'
\echo '=========================================================================='

-- Define demo patient ID
\set demo_patient '''00000000-0000-0000-0000-000000000001'''

\echo ''
\echo 'Demo Patient Info:'
SELECT id, first_name, last_name, email
FROM patients
WHERE id = :demo_patient;

\echo ''
\echo 'vw_pain_trend for demo patient:'
SELECT
  id,
  patient_id,
  logged_date,
  avg_pain,
  session_number
FROM vw_pain_trend
WHERE patient_id = :demo_patient
ORDER BY logged_date DESC
LIMIT 10;

\echo ''
\echo 'Expected: 6 rows (one for each day with pain logs in demo data)'
\echo ''

\echo ''
\echo 'vw_patient_adherence for demo patient:'
SELECT
  patient_id,
  first_name,
  last_name,
  total_sessions,
  completed_sessions,
  adherence_pct
FROM vw_patient_adherence
WHERE patient_id = :demo_patient;

\echo ''
\echo 'Expected: 1 row showing John Brebbia with 24 total sessions'
\echo ''

\echo ''
\echo 'vw_patient_sessions for demo patient (last 10 sessions):'
SELECT
  id,
  name,
  session_number,
  patient_id,
  session_date,
  completed,
  exercise_count,
  avg_pain_score
FROM vw_patient_sessions
WHERE patient_id = :demo_patient
ORDER BY session_number DESC
LIMIT 10;

\echo ''
\echo 'Expected: 10 rows showing sessions 24 down to 15'
\echo ''

-- ============================================================================
-- TEST 6: Simulate iOS AnalyticsService Queries
-- ============================================================================
\echo ''
\echo '=========================================================================='
\echo 'TEST 6: Simulate iOS AnalyticsService Queries'
\echo '=========================================================================='

\echo ''
\echo 'fetchPainTrend() - Last 14 days:'
SELECT *
FROM vw_pain_trend
WHERE patient_id = :demo_patient
  AND logged_date >= CURRENT_DATE - INTERVAL '14 days'
ORDER BY logged_date ASC;

\echo ''
\echo 'fetchAdherence() - Single record:'
SELECT
  adherence_pct AS "adherencePercentage",
  completed_sessions AS "completedSessions",
  total_sessions AS "totalSessions"
FROM vw_patient_adherence
WHERE patient_id = :demo_patient;

\echo ''
\echo 'fetchRecentSessions() - Last 10 sessions:'
SELECT
  id,
  session_number AS "sessionNumber",
  session_date AS "sessionDate",
  completed,
  exercise_count AS "exerciseCount"
FROM vw_patient_sessions
WHERE patient_id = :demo_patient
ORDER BY session_number DESC
LIMIT 10;

-- ============================================================================
-- TEST 7: Check Underlying Data
-- ============================================================================
\echo ''
\echo '=========================================================================='
\echo 'TEST 7: Verify Underlying Tables Have Data'
\echo '=========================================================================='

SELECT 'pain_logs' AS table_name, COUNT(*) AS row_count FROM pain_logs
UNION ALL
SELECT 'patients', COUNT(*) FROM patients
UNION ALL
SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL
SELECT 'phases', COUNT(*) FROM phases
UNION ALL
SELECT 'programs', COUNT(*) FROM programs
ORDER BY table_name;

\echo ''
\echo 'Expected: All tables should have rows > 0'
\echo ''

-- ============================================================================
-- SUMMARY
-- ============================================================================
\echo ''
\echo '=========================================================================='
\echo 'VERIFICATION SUMMARY'
\echo '=========================================================================='
\echo ''
\echo 'If all tests passed, you should see:'
\echo '  ✅ All 3 views exist'
\echo '  ✅ All views have proper permissions (authenticated, service_role)'
\echo '  ✅ All views have correct schema (matching Swift CodingKeys)'
\echo '  ✅ All views return data'
\echo '  ✅ Demo patient data is accessible through all views'
\echo '  ✅ iOS AnalyticsService queries return expected results'
\echo '  ✅ Underlying tables contain demo data'
\echo ''
\echo 'Next steps:'
\echo '  1. Test History tab in iOS app'
\echo '  2. Verify no errors in Xcode console'
\echo '  3. Confirm UI displays all components correctly'
\echo ''
\echo '=========================================================================='
