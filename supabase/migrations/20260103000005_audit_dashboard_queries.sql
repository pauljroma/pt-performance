-- Migration: Audit Log Review Dashboard Queries
-- Build: 119
-- Date: 2026-01-03
-- Purpose: Enable monthly compliance reviews and anomaly detection

-- View: Monthly Audit Summary
CREATE OR REPLACE VIEW vw_monthly_audit_summary AS
SELECT
    DATE_TRUNC('month', accessed_at) AS month,
    therapist_id,
    patient_id,
    table_name,
    action,
    COUNT(*) AS access_count,
    MIN(accessed_at) AS first_access,
    MAX(accessed_at) AS last_access
FROM therapist_access_logs
GROUP BY
    DATE_TRUNC('month', accessed_at),
    therapist_id,
    patient_id,
    table_name,
    action
ORDER BY
    month DESC,
    access_count DESC;

-- View: Suspicious Access Patterns (>10 accesses per hour)
CREATE OR REPLACE VIEW vw_suspicious_access_patterns AS
SELECT
    DATE_TRUNC('hour', accessed_at) AS hour,
    therapist_id,
    patient_id,
    COUNT(*) AS access_count,
    ARRAY_AGG(DISTINCT table_name) AS tables_accessed,
    ARRAY_AGG(DISTINCT action) AS actions_performed
FROM therapist_access_logs
GROUP BY
    DATE_TRUNC('hour', accessed_at),
    therapist_id,
    patient_id
HAVING COUNT(*) > 10
ORDER BY hour DESC, access_count DESC;

-- View: Patient Access History (all access to specific patient)
CREATE OR REPLACE VIEW vw_patient_access_history AS
SELECT
    therapist_access_logs.patient_id,
    therapist_access_logs.therapist_id,
    therapist_access_logs.table_name,
    therapist_access_logs.action,
    therapist_access_logs.accessed_at,
    therapist_access_logs.record_id,
    user_roles.role_name AS therapist_role
FROM therapist_access_logs
LEFT JOIN user_roles ON user_roles.user_id = therapist_access_logs.therapist_id
ORDER BY therapist_access_logs.accessed_at DESC;

-- Function: Generate Audit Report for Date Range
CREATE OR REPLACE FUNCTION generate_audit_report(
    start_date DATE,
    end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    therapist_id UUID,
    therapist_access_count BIGINT,
    unique_patients_accessed BIGINT,
    tables_accessed TEXT[],
    most_common_action TEXT
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT
        therapist_id,
        COUNT(*) AS therapist_access_count,
        COUNT(DISTINCT patient_id) AS unique_patients_accessed,
        ARRAY_AGG(DISTINCT table_name) AS tables_accessed,
        MODE() WITHIN GROUP (ORDER BY action) AS most_common_action
    FROM therapist_access_logs
    WHERE accessed_at >= start_date
    AND accessed_at < end_date + INTERVAL '1 day'
    GROUP BY therapist_id
    ORDER BY therapist_access_count DESC;
$$;

-- Function: Detect Anomalies in Access Patterns
CREATE OR REPLACE FUNCTION detect_anomalies()
RETURNS TABLE (
    anomaly_type TEXT,
    therapist_id UUID,
    patient_id UUID,
    details TEXT,
    severity TEXT
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    -- Anomaly 1: High-frequency access (>50 accesses in 1 hour)
    SELECT
        'HIGH_FREQUENCY_ACCESS' AS anomaly_type,
        therapist_id,
        patient_id,
        'Accessed ' || COUNT(*) || ' times in 1 hour' AS details,
        'HIGH' AS severity
    FROM therapist_access_logs
    WHERE accessed_at >= NOW() - INTERVAL '1 hour'
    GROUP BY therapist_id, patient_id
    HAVING COUNT(*) > 50

    UNION ALL

    -- Anomaly 2: After-hours access (outside 6 AM - 10 PM)
    SELECT
        'AFTER_HOURS_ACCESS' AS anomaly_type,
        therapist_id,
        patient_id,
        'Access at ' || accessed_at::TEXT AS details,
        'MEDIUM' AS severity
    FROM therapist_access_logs
    WHERE accessed_at >= NOW() - INTERVAL '7 days'
    AND EXTRACT(HOUR FROM accessed_at) NOT BETWEEN 6 AND 22

    UNION ALL

    -- Anomaly 3: Access to inactive assignments
    SELECT
        'INACTIVE_ASSIGNMENT_ACCESS' AS anomaly_type,
        tal.therapist_id,
        tal.patient_id,
        'Access after assignment ended' AS details,
        'HIGH' AS severity
    FROM therapist_access_logs tal
    LEFT JOIN therapist_patients tp ON
        tp.therapist_id = tal.therapist_id
        AND tp.patient_id = tal.patient_id
    WHERE tal.accessed_at >= NOW() - INTERVAL '30 days'
    AND (tp.active = false OR tp.id IS NULL)

    ORDER BY severity DESC, anomaly_type;
$$;

-- Function: Get Compliance Officer Dashboard Summary
CREATE OR REPLACE FUNCTION get_compliance_dashboard()
RETURNS TABLE (
    metric_name TEXT,
    metric_value TEXT,
    metric_date DATE
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT 'Total Therapist Access Logs', COUNT(*)::TEXT, CURRENT_DATE
    FROM therapist_access_logs

    UNION ALL

    SELECT 'Access Logs Last 30 Days', COUNT(*)::TEXT, CURRENT_DATE
    FROM therapist_access_logs
    WHERE accessed_at >= NOW() - INTERVAL '30 days'

    UNION ALL

    SELECT 'Active Therapist-Patient Assignments', COUNT(*)::TEXT, CURRENT_DATE
    FROM therapist_patients
    WHERE active = true

    UNION ALL

    SELECT 'Detected Anomalies (Last 7 Days)', COUNT(*)::TEXT, CURRENT_DATE
    FROM (SELECT * FROM detect_anomalies()) AS anomalies

    UNION ALL

    SELECT 'Unique Therapists with Access', COUNT(DISTINCT therapist_id)::TEXT, CURRENT_DATE
    FROM therapist_access_logs
    WHERE accessed_at >= NOW() - INTERVAL '30 days';
$$;

-- Comment
COMMENT ON VIEW vw_monthly_audit_summary IS 'Monthly access summary for compliance review (BUILD 119)';
COMMENT ON VIEW vw_suspicious_access_patterns IS 'Detect unusual access patterns (>10/hour) (BUILD 119)';
COMMENT ON VIEW vw_patient_access_history IS 'Complete access history for any patient (BUILD 119)';
COMMENT ON FUNCTION generate_audit_report IS 'Generate audit report for date range (BUILD 119)';
COMMENT ON FUNCTION detect_anomalies IS 'Detect anomalous access patterns (BUILD 119)';
COMMENT ON FUNCTION get_compliance_dashboard IS 'Compliance officer dashboard summary (BUILD 119)';
