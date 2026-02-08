-- Migration: Create KPI and Safety Tables for X2Index
-- M9: AI flags uncertainty, abstains on weak evidence, forces escalation when threshold crossed
-- M10: KPI dashboard tracks PT prep time, WAU, adherence, citation coverage, latency, safety events
--
-- North Star Guardrails:
-- - PT weekly active usage >= 65%
-- - Athlete weekly active usage >= 60%
-- - Citation coverage for AI claims >= 95%
-- - p95 summary latency <= 5s
-- - Unresolved high-severity safety incidents = 0

-- =============================================================================
-- SAFETY INCIDENTS TABLE
-- =============================================================================
-- Tracks safety incidents that require attention
-- Includes pain thresholds, vital anomalies, contradictory data, AI uncertainty

CREATE TABLE IF NOT EXISTS safety_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    incident_type TEXT NOT NULL CHECK (incident_type IN (
        'pain_threshold',
        'vital_anomaly',
        'contradictory_data',
        'ai_uncertainty',
        'missed_escalation'
    )),
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT NOT NULL,
    trigger_data JSONB,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'dismissed')),
    escalated_to UUID REFERENCES auth.users(id),
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Comments for documentation
COMMENT ON TABLE safety_incidents IS 'Safety incidents requiring PT review - M9 safety controls';
COMMENT ON COLUMN safety_incidents.incident_type IS 'Type: pain_threshold, vital_anomaly, contradictory_data, ai_uncertainty, missed_escalation';
COMMENT ON COLUMN safety_incidents.severity IS 'Severity level: low, medium, high, critical';
COMMENT ON COLUMN safety_incidents.trigger_data IS 'JSONB data that triggered the incident (e.g., pain_score, hrv_values)';
COMMENT ON COLUMN safety_incidents.status IS 'Status: open, investigating, resolved, dismissed';

-- =============================================================================
-- KPI EVENTS TABLE
-- =============================================================================
-- Tracks all KPI-relevant events for dashboard metrics

CREATE TABLE IF NOT EXISTS kpi_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL CHECK (event_type IN (
        'brief_opened',
        'check_in_completed',
        'plan_assigned',
        'ai_claim_generated',
        'session_started',
        'session_completed',
        'task_completed'
    )),
    user_id UUID REFERENCES auth.users(id),
    athlete_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    metadata JSONB,
    duration_ms INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Comments for documentation
COMMENT ON TABLE kpi_events IS 'KPI tracking events for M10 dashboard - WAU, prep time, latency';
COMMENT ON COLUMN kpi_events.event_type IS 'Event type for KPI categorization';
COMMENT ON COLUMN kpi_events.duration_ms IS 'Duration in milliseconds (for latency/prep time tracking)';
COMMENT ON COLUMN kpi_events.metadata IS 'Additional event-specific data (e.g., confidence scores, citation status)';

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Safety incidents: Quick lookup by status and severity for dashboard
CREATE INDEX idx_safety_incidents_status ON safety_incidents(status, severity);

-- Safety incidents: Find incidents by athlete
CREATE INDEX idx_safety_incidents_athlete ON safety_incidents(athlete_id, created_at DESC);

-- Safety incidents: Find open high-severity incidents (critical for guardrail)
CREATE INDEX idx_safety_incidents_open_high ON safety_incidents(status, severity)
    WHERE status IN ('open', 'investigating') AND severity IN ('high', 'critical');

-- Safety incidents: Created timestamp for time-based queries
CREATE INDEX idx_safety_incidents_created ON safety_incidents(created_at DESC);

-- KPI events: Quick lookup by event type and date for dashboard aggregations
CREATE INDEX idx_kpi_events_type_date ON kpi_events(event_type, created_at);

-- KPI events: Find events by user for PT WAU calculation
CREATE INDEX idx_kpi_events_user ON kpi_events(user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

-- KPI events: Find events by athlete for athlete WAU calculation
CREATE INDEX idx_kpi_events_athlete ON kpi_events(athlete_id, created_at DESC)
    WHERE athlete_id IS NOT NULL;

-- KPI events: AI claim events for citation coverage and latency
CREATE INDEX idx_kpi_events_ai_claims ON kpi_events(event_type, created_at)
    WHERE event_type = 'ai_claim_generated';

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on both tables
ALTER TABLE safety_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_events ENABLE ROW LEVEL SECURITY;

-- Safety incidents: Therapists can view/manage incidents for their patients
CREATE POLICY "therapist_view_safety_incidents" ON safety_incidents
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = safety_incidents.athlete_id
            AND tp.therapist_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM user_roles ur
            WHERE ur.user_id = auth.uid()
            AND ur.role = 'admin'
        )
    );

CREATE POLICY "therapist_insert_safety_incidents" ON safety_incidents
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = safety_incidents.athlete_id
            AND tp.therapist_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM user_roles ur
            WHERE ur.user_id = auth.uid()
            AND ur.role = 'admin'
        )
    );

CREATE POLICY "therapist_update_safety_incidents" ON safety_incidents
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = safety_incidents.athlete_id
            AND tp.therapist_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM user_roles ur
            WHERE ur.user_id = auth.uid()
            AND ur.role = 'admin'
        )
    );

-- KPI events: Insert by authenticated users, read by admins
CREATE POLICY "authenticated_insert_kpi_events" ON kpi_events
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "admin_view_kpi_events" ON kpi_events
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            WHERE ur.user_id = auth.uid()
            AND ur.role = 'admin'
        )
    );

-- KPI events: Users can view their own events
CREATE POLICY "user_view_own_kpi_events" ON kpi_events
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR athlete_id IN (
            SELECT id FROM patients WHERE id::text = auth.uid()::text
        )
    );

-- =============================================================================
-- VIEWS FOR DASHBOARD AGGREGATIONS
-- =============================================================================

-- View: Weekly Active Users (PTs)
CREATE OR REPLACE VIEW vw_pt_wau AS
SELECT
    date_trunc('week', kpi.created_at) AS week_start,
    COUNT(DISTINCT kpi.user_id) AS active_pts,
    (SELECT COUNT(DISTINCT user_id) FROM user_roles WHERE role = 'therapist') AS total_pts,
    CASE
        WHEN (SELECT COUNT(DISTINCT user_id) FROM user_roles WHERE role = 'therapist') > 0
        THEN COUNT(DISTINCT kpi.user_id)::FLOAT / (SELECT COUNT(DISTINCT user_id) FROM user_roles WHERE role = 'therapist')
        ELSE 0
    END AS wau_percentage
FROM kpi_events kpi
JOIN user_roles ur ON ur.user_id = kpi.user_id AND ur.role = 'therapist'
WHERE kpi.event_type IN ('brief_opened', 'plan_assigned')
AND kpi.created_at >= NOW() - INTERVAL '7 days'
GROUP BY week_start;

-- View: Weekly Active Users (Athletes)
CREATE OR REPLACE VIEW vw_athlete_wau AS
SELECT
    date_trunc('week', kpi.created_at) AS week_start,
    COUNT(DISTINCT kpi.athlete_id) AS active_athletes,
    (SELECT COUNT(*) FROM patients) AS total_athletes,
    CASE
        WHEN (SELECT COUNT(*) FROM patients) > 0
        THEN COUNT(DISTINCT kpi.athlete_id)::FLOAT / (SELECT COUNT(*) FROM patients)
        ELSE 0
    END AS wau_percentage
FROM kpi_events kpi
WHERE kpi.event_type IN ('check_in_completed', 'session_completed', 'task_completed')
AND kpi.created_at >= NOW() - INTERVAL '7 days'
GROUP BY week_start;

-- View: AI Claim Metrics (Citation Coverage, Latency)
CREATE OR REPLACE VIEW vw_ai_metrics AS
SELECT
    date_trunc('day', created_at) AS day,
    COUNT(*) AS claims_generated,
    COUNT(*) FILTER (WHERE (metadata->>'has_citations')::BOOLEAN = TRUE) AS claims_with_citations,
    CASE
        WHEN COUNT(*) > 0
        THEN COUNT(*) FILTER (WHERE (metadata->>'has_citations')::BOOLEAN = TRUE)::FLOAT / COUNT(*)
        ELSE 0
    END AS citation_coverage,
    AVG((metadata->>'confidence')::FLOAT) AS avg_confidence,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration_ms) AS p95_latency_ms,
    COUNT(*) FILTER (WHERE (metadata->>'abstained')::BOOLEAN = TRUE) AS abstentions,
    COUNT(*) FILTER (WHERE (metadata->>'uncertainty_flagged')::BOOLEAN = TRUE) AS uncertainty_flags
FROM kpi_events
WHERE event_type = 'ai_claim_generated'
GROUP BY day
ORDER BY day DESC;

-- View: Safety Metrics Summary
CREATE OR REPLACE VIEW vw_safety_metrics AS
SELECT
    date_trunc('week', created_at) AS week_start,
    COUNT(*) AS total_incidents,
    COUNT(*) FILTER (WHERE severity IN ('high', 'critical') AND status IN ('open', 'investigating')) AS unresolved_high_severity,
    COUNT(*) FILTER (WHERE escalated_to IS NOT NULL) AS escalations_triggered,
    COUNT(*) FILTER (WHERE status = 'resolved') AS resolved_incidents,
    COUNT(*) FILTER (WHERE status = 'dismissed') AS dismissed_incidents
FROM safety_incidents
GROUP BY week_start
ORDER BY week_start DESC;

-- =============================================================================
-- FUNCTIONS FOR SAFETY CHECKS
-- =============================================================================

-- Function: Check if an incident requires escalation
CREATE OR REPLACE FUNCTION check_incident_escalation()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-set escalation deadline for high/critical severity
    IF NEW.severity IN ('high', 'critical') AND NEW.status = 'open' THEN
        -- Could add notification logic here via pg_notify
        PERFORM pg_notify(
            'safety_escalation',
            json_build_object(
                'incident_id', NEW.id,
                'athlete_id', NEW.athlete_id,
                'severity', NEW.severity,
                'type', NEW.incident_type
            )::text
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Notify on high-severity incident creation
DROP TRIGGER IF EXISTS trigger_check_escalation ON safety_incidents;
CREATE TRIGGER trigger_check_escalation
    AFTER INSERT OR UPDATE OF severity, status ON safety_incidents
    FOR EACH ROW
    EXECUTE FUNCTION check_incident_escalation();

-- =============================================================================
-- SEED DEMO DATA (for development/testing)
-- =============================================================================

-- Only run in development/test environments
DO $$
BEGIN
    -- Check if this is a dev environment (has demo users)
    IF EXISTS (SELECT 1 FROM patients WHERE email LIKE '%demo%' LIMIT 1) THEN
        -- Insert sample KPI events
        INSERT INTO kpi_events (event_type, user_id, athlete_id, duration_ms, metadata, created_at)
        SELECT
            (ARRAY['brief_opened', 'check_in_completed', 'plan_assigned', 'session_completed'])[floor(random() * 4 + 1)],
            (SELECT id FROM auth.users ORDER BY random() LIMIT 1),
            (SELECT id FROM patients ORDER BY random() LIMIT 1),
            floor(random() * 5000 + 500)::INT,
            '{"demo": true}'::JSONB,
            NOW() - (random() * INTERVAL '7 days')
        FROM generate_series(1, 50);

        -- Insert sample AI claim events
        INSERT INTO kpi_events (event_type, duration_ms, metadata, created_at)
        SELECT
            'ai_claim_generated',
            floor(random() * 4000 + 1000)::INT,
            json_build_object(
                'has_citations', random() > 0.05,
                'confidence', random() * 0.4 + 0.6,
                'abstained', random() < 0.02,
                'uncertainty_flagged', random() < 0.05
            )::JSONB,
            NOW() - (random() * INTERVAL '7 days')
        FROM generate_series(1, 100);

        RAISE NOTICE 'Seeded demo KPI events';
    END IF;
END $$;
