-- 20251213150000_create_analytics_views.sql
-- Create analytics views for patient history tab
-- Supports pain trends, adherence tracking, and session summaries

-- ============================================================================
-- 1. VW_PAIN_TREND: Pain trend data over time
-- ============================================================================
-- Returns daily pain scores from exercise logs
-- Used by: HistoryView pain trend chart

DROP VIEW IF EXISTS vw_pain_trend CASCADE;
CREATE VIEW vw_pain_trend AS
SELECT
  el.id,
  el.patient_id,
  DATE(el.logged_at) as logged_date,
  AVG(el.pain_score) as avg_pain,
  se.session_id,
  s.sequence as session_number
FROM exercise_logs el
LEFT JOIN session_exercises se ON se.id = el.session_exercise_id
LEFT JOIN sessions s ON s.id = se.session_id
WHERE el.pain_score IS NOT NULL
GROUP BY el.id, el.patient_id, DATE(el.logged_at), se.session_id, s.sequence
ORDER BY logged_date DESC;

COMMENT ON VIEW vw_pain_trend IS 'Daily pain trend data for patient history charts';

-- ============================================================================
-- 2. VW_PATIENT_ADHERENCE: Adherence statistics
-- ============================================================================
-- Returns adherence percentage and session completion counts
-- Used by: HistoryView adherence card

DROP VIEW IF EXISTS vw_patient_adherence CASCADE;
CREATE VIEW vw_patient_adherence AS
SELECT
  p.id as patient_id,
  p.first_name,
  p.last_name,
  COUNT(DISTINCT s.id) as total_sessions,
  COUNT(DISTINCT CASE WHEN s.completed = true THEN s.id END) as completed_sessions,
  CASE
    WHEN COUNT(DISTINCT s.id) > 0 THEN
      ROUND((COUNT(DISTINCT CASE WHEN s.completed = true THEN s.id END)::numeric / COUNT(DISTINCT s.id)::numeric) * 100, 1)
    ELSE 0
  END as adherence_pct
FROM patients p
LEFT JOIN programs pr ON pr.patient_id = p.id AND pr.status = 'active'
LEFT JOIN phases ph ON ph.program_id = pr.id
LEFT JOIN sessions s ON s.phase_id = ph.id
GROUP BY p.id, p.first_name, p.last_name;

COMMENT ON VIEW vw_patient_adherence IS 'Patient adherence statistics for active programs';

-- ============================================================================
-- 3. VW_PATIENT_SESSIONS: Session summaries with completion status
-- ============================================================================
-- Returns recent session details for patient history list
-- Used by: HistoryView recent sessions section

DROP VIEW IF EXISTS vw_patient_sessions CASCADE;
CREATE VIEW vw_patient_sessions AS
SELECT
  s.id,
  pr.patient_id,
  s.sequence as session_number,
  s.created_at as session_date,
  COALESCE(s.completed, false) as completed,
  s.completed_at,
  s.total_volume,
  s.avg_rpe,
  s.avg_pain as avg_pain_score,
  s.duration_minutes,
  COUNT(DISTINCT se.id) as exercise_count,
  ph.name as phase_name,
  pr.name as program_name
FROM sessions s
JOIN phases ph ON ph.id = s.phase_id
JOIN programs pr ON pr.id = ph.program_id
LEFT JOIN session_exercises se ON se.session_id = s.id
GROUP BY
  s.id,
  pr.patient_id,
  s.sequence,
  s.created_at,
  s.completed,
  s.completed_at,
  s.total_volume,
  s.avg_rpe,
  s.avg_pain,
  s.duration_minutes,
  ph.name,
  pr.name
ORDER BY s.sequence DESC;

COMMENT ON VIEW vw_patient_sessions IS 'Patient session summaries with completion status and metrics';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) FOR VIEWS
-- ============================================================================

-- Grant access to authenticated users
GRANT SELECT ON vw_pain_trend TO authenticated;
GRANT SELECT ON vw_patient_adherence TO authenticated;
GRANT SELECT ON vw_patient_sessions TO authenticated;

-- Note: RLS on underlying tables (patients, sessions, exercise_logs) will filter results

-- ============================================================================
-- VALIDATION
-- ============================================================================

DO $$
DECLARE
  pain_trend_exists boolean;
  adherence_exists boolean;
  sessions_exists boolean;
BEGIN
  -- Check views exist
  SELECT EXISTS(
    SELECT 1 FROM information_schema.views WHERE table_name = 'vw_pain_trend'
  ) INTO pain_trend_exists;

  SELECT EXISTS(
    SELECT 1 FROM information_schema.views WHERE table_name = 'vw_patient_adherence'
  ) INTO adherence_exists;

  SELECT EXISTS(
    SELECT 1 FROM information_schema.views WHERE table_name = 'vw_patient_sessions'
  ) INTO sessions_exists;

  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'ANALYTICS VIEWS CREATED';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'vw_pain_trend: %', CASE WHEN pain_trend_exists THEN '✅ EXISTS' ELSE '❌ MISSING' END;
  RAISE NOTICE 'vw_patient_adherence: %', CASE WHEN adherence_exists THEN '✅ EXISTS' ELSE '❌ MISSING' END;
  RAISE NOTICE 'vw_patient_sessions: %', CASE WHEN sessions_exists THEN '✅ EXISTS' ELSE '❌ MISSING' END;
  RAISE NOTICE '============================================';
END $$;
