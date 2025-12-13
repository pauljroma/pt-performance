-- ============================================================================
-- CREATE ANALYTICS VIEWS FOR HISTORY TAB
-- ============================================================================
-- This file creates the three views needed for the iOS History tab:
-- 1. vw_pain_trend - Pain data over time
-- 2. vw_patient_adherence - Adherence statistics
-- 3. vw_patient_sessions - Session history with patient linkage
-- ============================================================================

-- ============================================================================
-- 1. vw_pain_trend
-- ============================================================================
DROP VIEW IF EXISTS vw_pain_trend CASCADE;

CREATE VIEW vw_pain_trend AS
SELECT
    gen_random_uuid()::text AS id,
    patient_id,
    day AS logged_date,
    avg_pain_during AS avg_pain,
    NULL::int AS session_number
FROM (
    SELECT
        patient_id,
        date(logged_at) AS day,
        avg(pain_during) AS avg_pain_during
    FROM pain_logs
    GROUP BY patient_id, date(logged_at)
) pain_by_day;

ALTER VIEW vw_pain_trend SET (security_invoker = true);

COMMENT ON VIEW vw_pain_trend IS 'Pain trend data aggregated by day for iOS app';

-- ============================================================================
-- 2. vw_patient_adherence
-- ============================================================================
DROP VIEW IF EXISTS vw_patient_adherence CASCADE;

CREATE VIEW vw_patient_adherence AS
SELECT
    p.id AS patient_id,
    p.first_name,
    p.last_name,
    COUNT(s.id) AS total_sessions,
    COUNT(CASE WHEN s.completed THEN 1 END) AS completed_sessions,
    CASE
        WHEN COUNT(s.id) > 0
        THEN (COUNT(CASE WHEN s.completed THEN 1 END)::float / COUNT(s.id)::float * 100)
        ELSE 0
    END AS adherence_pct
FROM patients p
LEFT JOIN programs pr ON pr.patient_id = p.id
LEFT JOIN phases ph ON ph.program_id = pr.id
LEFT JOIN sessions s ON s.phase_id = ph.id
GROUP BY p.id, p.first_name, p.last_name;

ALTER VIEW vw_patient_adherence SET (security_invoker = true);

COMMENT ON VIEW vw_patient_adherence IS 'Patient adherence statistics for iOS app';

-- ============================================================================
-- 3. vw_patient_sessions
-- ============================================================================
DROP VIEW IF EXISTS vw_patient_sessions CASCADE;

CREATE VIEW vw_patient_sessions AS
SELECT
    s.id,
    s.name,
    s.sequence AS session_number,
    prog.patient_id,
    s.phase_id,
    ph.program_id,
    s.weekday,
    s.notes,
    s.created_at,
    s.intensity_rating,
    s.is_throwing_day,
    s.created_at::date AS session_date,
    s.completed,
    (SELECT COUNT(*) FROM session_exercises se WHERE se.session_id = s.id) AS exercise_count,
    s.avg_pain AS avg_pain_score
FROM sessions s
INNER JOIN phases ph ON s.phase_id = ph.id
INNER JOIN programs prog ON ph.program_id = prog.id;

ALTER VIEW vw_patient_sessions SET (security_invoker = true);

COMMENT ON VIEW vw_patient_sessions IS 'Sessions joined with patient_id for iOS app compatibility';

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================
GRANT SELECT ON vw_pain_trend TO authenticated;
GRANT SELECT ON vw_patient_adherence TO authenticated;
GRANT SELECT ON vw_patient_sessions TO authenticated;

GRANT SELECT ON vw_pain_trend TO service_role;
GRANT SELECT ON vw_patient_adherence TO service_role;
GRANT SELECT ON vw_patient_sessions TO service_role;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'ANALYTICS VIEWS CREATED SUCCESSFULLY';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Created views:';
  RAISE NOTICE '  ✅ vw_pain_trend - Pain data over time';
  RAISE NOTICE '  ✅ vw_patient_adherence - Adherence statistics';
  RAISE NOTICE '  ✅ vw_patient_sessions - Session history';
  RAISE NOTICE '';
  RAISE NOTICE '🎉 History tab should now work in iOS app!';
  RAISE NOTICE '========================================================================';
END $$;
