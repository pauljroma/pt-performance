-- ============================================================================
-- FIX SECURITY DEFINER ISSUES
-- ============================================================================
-- Supabase Splinter recommendation: Remove SECURITY DEFINER from views
-- and functions to enforce proper RLS policies of the querying user

-- ============================================================================
-- 1. FIX get_current_therapist_id() FUNCTION
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS get_current_therapist_id();

-- Recreate as SECURITY INVOKER (default - uses caller's permissions)
-- This is safer as it respects RLS policies
CREATE OR REPLACE FUNCTION get_current_therapist_id()
RETURNS uuid AS $$
  SELECT id FROM therapists WHERE user_id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL SECURITY INVOKER;

COMMENT ON FUNCTION get_current_therapist_id() IS
  'Returns therapist ID for current authenticated user. Uses SECURITY INVOKER to respect RLS policies.';

-- Grant execute to authenticated users (needed for RLS policies)
GRANT EXECUTE ON FUNCTION get_current_therapist_id() TO authenticated;
GRANT EXECUTE ON FUNCTION get_current_therapist_id() TO service_role;

-- ============================================================================
-- 2. ENSURE VIEWS ARE NOT SECURITY DEFINER
-- ============================================================================

-- Recreate vw_agent_error_summary without SECURITY DEFINER
DROP VIEW IF EXISTS vw_agent_error_summary CASCADE;

CREATE VIEW vw_agent_error_summary
WITH (security_invoker = true) AS
SELECT
  endpoint,
  DATE(created_at) as error_date,
  COUNT(*) as error_count,
  AVG(response_time_ms) as avg_response_time_ms,
  ARRAY_AGG(DISTINCT error_message) as error_messages
FROM agent_logs
WHERE error_message IS NOT NULL
GROUP BY endpoint, DATE(created_at)
ORDER BY error_date DESC, error_count DESC;

COMMENT ON VIEW vw_agent_error_summary IS
  'Daily error summary by endpoint. Uses SECURITY INVOKER to respect RLS policies.';

-- Recreate vw_agent_endpoint_performance without SECURITY DEFINER
DROP VIEW IF EXISTS vw_agent_endpoint_performance CASCADE;

CREATE VIEW vw_agent_endpoint_performance
WITH (security_invoker = true) AS
SELECT
  endpoint,
  COUNT(*) as total_requests,
  COUNT(CASE WHEN error_message IS NULL THEN 1 END) as successful_requests,
  COUNT(CASE WHEN error_message IS NOT NULL THEN 1 END) as failed_requests,
  ROUND(
    (COUNT(CASE WHEN error_message IS NULL THEN 1 END)::numeric / COUNT(*)::numeric) * 100,
    2
  ) as success_rate_pct,
  ROUND(AVG(response_time_ms)::numeric, 2) as avg_response_time_ms,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY response_time_ms)::numeric, 2) as p50_response_time_ms,
  ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms)::numeric, 2) as p95_response_time_ms,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_time_ms)::numeric, 2) as p99_response_time_ms
FROM agent_logs
GROUP BY endpoint;

COMMENT ON VIEW vw_agent_endpoint_performance IS
  'Endpoint performance metrics and success rates. Uses SECURITY INVOKER to respect RLS policies.';

-- ============================================================================
-- 3. FIX PATIENT DETAIL VIEWS
-- ============================================================================

-- These views need to respect RLS policies
DROP VIEW IF EXISTS vw_patient_sessions CASCADE;
CREATE VIEW vw_patient_sessions
WITH (security_invoker = true) AS
SELECT
  s.id,
  s.patient_id,
  s.phase_id,
  s.name as session_name,
  s.session_date,
  s.completed,
  s.notes,
  ph.name as phase_name,
  ph.program_id,
  pr.name as program_name
FROM sessions s
LEFT JOIN phases ph ON s.phase_id = ph.id
LEFT JOIN programs pr ON ph.program_id = pr.id;

COMMENT ON VIEW vw_patient_sessions IS
  'Patient sessions with phase and program info. Uses SECURITY INVOKER.';

-- Recreate vw_pain_trend
DROP VIEW IF EXISTS vw_pain_trend CASCADE;
CREATE VIEW vw_pain_trend
WITH (security_invoker = true) AS
SELECT
  patient_id,
  session_date,
  pain_level,
  notes
FROM sessions
WHERE pain_level IS NOT NULL
ORDER BY patient_id, session_date;

COMMENT ON VIEW vw_pain_trend IS
  'Pain trend data for patients. Uses SECURITY INVOKER.';

-- Recreate vw_patient_adherence
DROP VIEW IF EXISTS vw_patient_adherence CASCADE;
CREATE VIEW vw_patient_adherence
WITH (security_invoker = true) AS
SELECT
  s.patient_id,
  COUNT(*) as total_sessions,
  COUNT(CASE WHEN s.completed THEN 1 END) as completed_sessions,
  ROUND(
    (COUNT(CASE WHEN s.completed THEN 1 END)::numeric / COUNT(*)::numeric) * 100,
    1
  ) as adherence_rate
FROM sessions s
GROUP BY s.patient_id;

COMMENT ON VIEW vw_patient_adherence IS
  'Patient adherence metrics. Uses SECURITY INVOKER.';

-- ============================================================================
-- 4. GRANT PERMISSIONS
-- ============================================================================

-- Grant SELECT on all views to authenticated users
GRANT SELECT ON vw_agent_error_summary TO authenticated;
GRANT SELECT ON vw_agent_endpoint_performance TO authenticated;
GRANT SELECT ON vw_patient_sessions TO authenticated;
GRANT SELECT ON vw_pain_trend TO authenticated;
GRANT SELECT ON vw_patient_adherence TO authenticated;

-- Grant SELECT to service_role (for migrations and admin)
GRANT SELECT ON vw_agent_error_summary TO service_role;
GRANT SELECT ON vw_agent_endpoint_performance TO service_role;
GRANT SELECT ON vw_patient_sessions TO service_role;
GRANT SELECT ON vw_pain_trend TO service_role;
GRANT SELECT ON vw_patient_adherence TO service_role;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'SECURITY DEFINER FIXES APPLIED';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '✅ get_current_therapist_id() → SECURITY INVOKER';
  RAISE NOTICE '✅ vw_agent_error_summary → SECURITY INVOKER';
  RAISE NOTICE '✅ vw_agent_endpoint_performance → SECURITY INVOKER';
  RAISE NOTICE '✅ vw_patient_sessions → SECURITY INVOKER';
  RAISE NOTICE '✅ vw_pain_trend → SECURITY INVOKER';
  RAISE NOTICE '✅ vw_patient_adherence → SECURITY INVOKER';
  RAISE NOTICE '';
  RAISE NOTICE 'All views and functions now use SECURITY INVOKER';
  RAISE NOTICE 'This enforces RLS policies of the querying user (more secure)';
  RAISE NOTICE '========================================================================';
END $$;
