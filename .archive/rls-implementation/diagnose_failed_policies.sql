-- Diagnostic: Check why session_status and plyo_logs policies failed

-- ============================================================================
-- 1. CHECK IF TABLES EXIST
-- ============================================================================

SELECT
  table_name,
  CASE
    WHEN table_name IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
    THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status
FROM (VALUES ('session_status'), ('plyo_logs')) AS t(table_name);

-- ============================================================================
-- 2. CHECK TABLE COLUMNS
-- ============================================================================

-- Session Status columns
SELECT
  'session_status' as table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'session_status'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Plyo Logs columns
SELECT
  'plyo_logs' as table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'plyo_logs'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================================================
-- 3. CHECK EXISTING POLICIES
-- ============================================================================

-- All policies on session_status
SELECT
  policyname,
  cmd as command_type,
  qual as using_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'session_status';

-- All policies on plyo_logs
SELECT
  policyname,
  cmd as command_type,
  qual as using_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'plyo_logs';

-- ============================================================================
-- 4. CHECK IF RLS IS ENABLED
-- ============================================================================

SELECT
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('session_status', 'plyo_logs');

-- ============================================================================
-- 5. CHECK FOR CONFLICTING POLICIES
-- ============================================================================

-- Check if policies with same name already exist
SELECT
  tablename,
  policyname,
  'CONFLICT: Policy already exists' as issue
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname IN (
    'patients_see_own_session_status',
    'therapists_see_patient_session_status',
    'patients_see_own_plyo_logs',
    'therapists_see_patient_plyo_logs'
  );
