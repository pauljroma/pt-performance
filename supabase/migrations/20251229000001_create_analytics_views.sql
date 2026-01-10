-- Create Analytics Views for History Tab
-- Build 102 - 2025-12-29
-- Fixes "data couldn't be read" error in History tab

-- 1. Pain Trend View - Daily pain score aggregation for charts
CREATE OR REPLACE VIEW vw_pain_trend AS
SELECT
    el.id,
    el.patient_id,
    DATE(el.performed_at) as logged_date,
    AVG(el.pain_score) as avg_pain,
    COUNT(*) as exercise_count,
    s.session_number
FROM exercise_logs el
LEFT JOIN session_exercises se ON el.session_exercise_id = se.id
LEFT JOIN sessions s ON se.session_id = s.id
WHERE el.pain_score IS NOT NULL
GROUP BY el.id, el.patient_id, DATE(el.performed_at), s.session_number;

-- Grant access
GRANT SELECT ON vw_pain_trend TO authenticated;

-- RLS policy for patient isolation
ALTER VIEW vw_pain_trend SET (security_invoker = on);

-- 2. Patient Adherence View - 30-day completion percentage
CREATE OR REPLACE VIEW vw_patient_adherence AS
SELECT
    p.id as patient_id,
    ROUND((COUNT(CASE WHEN s.completed THEN 1 END)::numeric / NULLIF(COUNT(*), 0) * 100), 1) as adherence_pct,
    COUNT(CASE WHEN s.completed THEN 1 END) as completed_sessions,
    COUNT(*) as total_sessions,
    NULL::jsonb as weekly_breakdown
FROM patients p
LEFT JOIN programs pr ON pr.patient_id = p.id
LEFT JOIN phases ph ON ph.program_id = pr.id
LEFT JOIN sessions s ON s.phase_id = ph.id
WHERE s.created_at >= NOW() - INTERVAL '30 days'
GROUP BY p.id;

-- Grant access
GRANT SELECT ON vw_patient_adherence TO authenticated;

-- RLS policy for patient isolation
ALTER VIEW vw_patient_adherence SET (security_invoker = on);

-- 3. Patient Sessions View - Session summaries for history list
CREATE OR REPLACE VIEW vw_patient_sessions AS
SELECT
    s.id,
    pr.patient_id,
    s.session_number,
    COALESCE(s.completed_at, s.created_at) as session_date,
    s.completed,
    COUNT(DISTINCT se.id) as exercise_count,
    AVG(el.pain_score) as avg_pain_score
FROM sessions s
JOIN phases ph ON s.phase_id = ph.id
JOIN programs pr ON ph.program_id = pr.id
LEFT JOIN session_exercises se ON se.session_id = s.id
LEFT JOIN exercise_logs el ON el.session_exercise_id = se.id
GROUP BY s.id, pr.patient_id, s.session_number, s.completed_at, s.created_at, s.completed;

-- Grant access
GRANT SELECT ON vw_patient_sessions TO authenticated;

-- RLS policy for patient isolation
ALTER VIEW vw_patient_sessions SET (security_invoker = on);
