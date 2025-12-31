-- BUILD 102 - Fix vw_pain_trend view type mismatches
-- Fixes decoding errors in AnalyticsService by ensuring proper data types

-- Drop existing view
DROP VIEW IF EXISTS vw_pain_trend;

-- Recreate with proper types for Swift Codable decoding
CREATE OR REPLACE VIEW vw_pain_trend AS
SELECT
    -- Use MD5 hash of date+patient as unique ID (TEXT type, not UUID)
    MD5(el.patient_id::text || DATE(el.performed_at)::text) as id,
    el.patient_id,
    -- Convert DATE to TIMESTAMP for ISO8601 decoding
    (DATE(el.performed_at) || ' 00:00:00')::timestamp as logged_date,
    -- Average pain score for the day
    AVG(el.pain_score) as avg_pain,
    -- Get session number (use MAX in case of multiple sessions per day)
    MAX(s.session_number) as session_number
FROM exercise_logs el
LEFT JOIN session_exercises se ON el.session_exercise_id = se.id
LEFT JOIN sessions s ON se.session_id = s.id
WHERE el.pain_score IS NOT NULL
-- Group by patient and date (NOT by el.id since we want daily aggregates)
GROUP BY el.patient_id, DATE(el.performed_at)
ORDER BY logged_date DESC;

-- Grant permissions
GRANT SELECT ON vw_pain_trend TO authenticated;

-- Comment
COMMENT ON VIEW vw_pain_trend IS 'Daily pain scores aggregated from exercise logs - type-safe for Swift Codable';
