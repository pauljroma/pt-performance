-- Fix vw_pain_trend Type Compatibility
-- Build 102 - 2025-12-31
-- Fixes UUID vs String and DATE vs TIMESTAMP issues for Swift Codable

-- Drop the old view
DROP VIEW IF EXISTS vw_pain_trend;

-- Recreate with proper types for Swift compatibility
CREATE OR REPLACE VIEW vw_pain_trend AS
SELECT
    -- Use MD5 hash of patient_id + date as TEXT id (not UUID)
    MD5(el.patient_id::text || DATE(el.performed_at)::text) as id,
    el.patient_id,
    -- Convert DATE to TIMESTAMP for ISO8601 decoder compatibility
    (DATE(el.performed_at) || ' 00:00:00')::timestamp as logged_date,
    AVG(el.pain_score) as avg_pain,
    COUNT(*) as exercise_count,
    MAX(s.session_number) as session_number
FROM exercise_logs el
LEFT JOIN session_exercises se ON el.session_exercise_id = se.id
LEFT JOIN sessions s ON se.session_id = s.id
WHERE el.pain_score IS NOT NULL
-- Group by patient and date (not by el.id) for proper daily aggregation
GROUP BY el.patient_id, DATE(el.performed_at);

-- Grant access
GRANT SELECT ON vw_pain_trend TO authenticated;

-- RLS policy for patient isolation
ALTER VIEW vw_pain_trend SET (security_invoker = on);
