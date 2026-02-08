-- Migration: Create Risk Escalations Table
-- Description: Risk Escalation System (M4) for X2Index Command Center
--              Alerts therapists when athletes show concerning safety patterns
-- Date: 2026-02-08

-- =====================================================
-- Risk Escalations Table
-- =====================================================

CREATE TABLE IF NOT EXISTS risk_escalations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Escalation details
    escalation_type TEXT NOT NULL CHECK (escalation_type IN (
        'low_recovery',      -- Recovery <40% for 3+ days
        'pain_spike',        -- Pain jumps 3+ points
        'missed_sessions',   -- 3+ consecutive misses
        'abnormal_vitals',   -- HR/HRV out of range
        'no_check_in',       -- No check-in for 5+ days
        'adherence_drop',    -- Sudden adherence decline
        'workload_spike',    -- Acute:chronic workload ratio spike
        'sleep_deficit',     -- Chronic sleep deprivation
        'stress_elevation'   -- Sustained high stress levels
    )),
    severity TEXT NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    trigger_data JSONB NOT NULL DEFAULT '{}',
    message TEXT NOT NULL,
    recommendation TEXT NOT NULL,

    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',      -- Awaiting acknowledgment
        'acknowledged', -- Therapist has seen it
        'resolved',     -- Issue has been addressed
        'dismissed'     -- Marked as false positive
    )),

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,

    -- Metadata
    push_notification_sent BOOLEAN DEFAULT false,
    email_notification_sent BOOLEAN DEFAULT false
);

-- =====================================================
-- Indexes
-- =====================================================

-- Primary index for therapist queries (most common access pattern)
CREATE INDEX IF NOT EXISTS idx_risk_escalations_therapist_status
    ON risk_escalations(therapist_id, status);

-- Index for patient-specific queries
CREATE INDEX IF NOT EXISTS idx_risk_escalations_patient
    ON risk_escalations(patient_id);

-- Index for severity-based queries (critical alerts first)
CREATE INDEX IF NOT EXISTS idx_risk_escalations_severity
    ON risk_escalations(severity DESC, created_at DESC);

-- Index for unresolved escalations
CREATE INDEX IF NOT EXISTS idx_risk_escalations_active
    ON risk_escalations(therapist_id, resolved_at)
    WHERE resolved_at IS NULL;

-- Index for escalation type analysis
CREATE INDEX IF NOT EXISTS idx_risk_escalations_type
    ON risk_escalations(escalation_type);

-- Index for time-based queries
CREATE INDEX IF NOT EXISTS idx_risk_escalations_created
    ON risk_escalations(created_at DESC);

-- =====================================================
-- Comments
-- =====================================================

COMMENT ON TABLE risk_escalations IS
    'Risk Escalation System (M4) - Stores safety alerts requiring therapist attention';

COMMENT ON COLUMN risk_escalations.escalation_type IS
    'Type of risk pattern detected (low_recovery, pain_spike, missed_sessions, etc.)';

COMMENT ON COLUMN risk_escalations.severity IS
    'Urgency level: critical=immediate, high=same day, medium=48hrs, low=FYI';

COMMENT ON COLUMN risk_escalations.trigger_data IS
    'JSON data containing the metrics that triggered this escalation';

COMMENT ON COLUMN risk_escalations.status IS
    'Current state of the escalation in the workflow';

-- =====================================================
-- Row-Level Security (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE risk_escalations ENABLE ROW LEVEL SECURITY;

-- Therapists can view escalations for their patients
CREATE POLICY "Therapists can view their patient escalations"
    ON risk_escalations FOR SELECT
    USING (
        therapist_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.user_id = auth.uid()
            AND therapists.id = risk_escalations.therapist_id
        )
    );

-- System/triggers can create escalations (via service role)
CREATE POLICY "Service can create escalations"
    ON risk_escalations FOR INSERT
    WITH CHECK (true);

-- Therapists can update their own escalations (acknowledge, resolve, dismiss)
CREATE POLICY "Therapists can update their escalations"
    ON risk_escalations FOR UPDATE
    USING (therapist_id = auth.uid())
    WITH CHECK (therapist_id = auth.uid());

-- Only allow deletion by service role (for data cleanup)
CREATE POLICY "Service can delete escalations"
    ON risk_escalations FOR DELETE
    USING (false);

-- =====================================================
-- Trigger: Notify Therapist on New Escalation
-- =====================================================

CREATE OR REPLACE FUNCTION notify_therapist_on_escalation()
RETURNS TRIGGER AS $$
DECLARE
    patient_name TEXT;
    therapist_push_token TEXT;
BEGIN
    -- Get patient name
    SELECT CONCAT(first_name, ' ', last_name)
    INTO patient_name
    FROM patients
    WHERE id = NEW.patient_id;

    -- Get therapist push token if available
    SELECT token
    INTO therapist_push_token
    FROM push_tokens
    WHERE user_id = NEW.therapist_id
    AND is_active = true
    ORDER BY updated_at DESC
    LIMIT 1;

    -- Log the notification event (for debugging and analytics)
    INSERT INTO audit_logs (
        action,
        table_name,
        record_id,
        user_id,
        old_data,
        new_data
    ) VALUES (
        'ESCALATION_CREATED',
        'risk_escalations',
        NEW.id,
        NEW.therapist_id,
        NULL,
        jsonb_build_object(
            'escalation_type', NEW.escalation_type,
            'severity', NEW.severity,
            'patient_name', patient_name,
            'message', NEW.message
        )
    );

    -- For critical and high severity, trigger immediate notification
    -- Note: Actual push notification is sent via Edge Function
    IF NEW.severity IN ('critical', 'high') AND therapist_push_token IS NOT NULL THEN
        -- Queue notification for Edge Function to process
        INSERT INTO notification_queue (
            user_id,
            notification_type,
            title,
            body,
            data,
            priority
        ) VALUES (
            NEW.therapist_id,
            'risk_escalation',
            CASE
                WHEN NEW.severity = 'critical' THEN 'CRITICAL: ' || NEW.escalation_type
                ELSE 'High Priority: ' || NEW.escalation_type
            END,
            CONCAT(patient_name, ': ', LEFT(NEW.message, 100)),
            jsonb_build_object(
                'escalation_id', NEW.id,
                'patient_id', NEW.patient_id,
                'severity', NEW.severity,
                'type', NEW.escalation_type
            ),
            CASE WHEN NEW.severity = 'critical' THEN 'high' ELSE 'normal' END
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger if notification_queue table exists
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = 'notification_queue'
    ) THEN
        DROP TRIGGER IF EXISTS risk_escalation_notify ON risk_escalations;
        CREATE TRIGGER risk_escalation_notify
            AFTER INSERT ON risk_escalations
            FOR EACH ROW
            EXECUTE FUNCTION notify_therapist_on_escalation();
    END IF;
END $$;

-- =====================================================
-- View: Escalation Summary for Dashboard
-- =====================================================

CREATE OR REPLACE VIEW vw_escalation_summary AS
SELECT
    therapist_id,
    COUNT(*) FILTER (WHERE resolved_at IS NULL) AS total_active,
    COUNT(*) FILTER (WHERE severity = 'critical' AND resolved_at IS NULL) AS critical_count,
    COUNT(*) FILTER (WHERE severity = 'high' AND resolved_at IS NULL) AS high_count,
    COUNT(*) FILTER (WHERE severity = 'medium' AND resolved_at IS NULL) AS medium_count,
    COUNT(*) FILTER (WHERE severity = 'low' AND resolved_at IS NULL) AS low_count,
    COUNT(*) FILTER (WHERE acknowledged_at IS NULL AND resolved_at IS NULL) AS unacknowledged_count,
    COUNT(DISTINCT patient_id) FILTER (WHERE resolved_at IS NULL) AS patients_affected,
    MIN(created_at) FILTER (WHERE acknowledged_at IS NULL AND resolved_at IS NULL) AS oldest_unacknowledged_date
FROM risk_escalations
GROUP BY therapist_id;

COMMENT ON VIEW vw_escalation_summary IS
    'Aggregated escalation counts by therapist for dashboard display';

-- =====================================================
-- View: Escalations with Patient Info
-- =====================================================

CREATE OR REPLACE VIEW vw_risk_escalations_with_patient AS
SELECT
    re.*,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name
FROM risk_escalations re
JOIN patients p ON re.patient_id = p.id;

COMMENT ON VIEW vw_risk_escalations_with_patient IS
    'Escalations joined with patient information for display';

-- =====================================================
-- Function: Get Escalation Stats by Type
-- =====================================================

CREATE OR REPLACE FUNCTION get_escalation_stats(
    p_therapist_id UUID,
    p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    escalation_type TEXT,
    total_count BIGINT,
    resolved_count BIGINT,
    avg_resolution_time_hours NUMERIC,
    patients_affected BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        re.escalation_type,
        COUNT(*) AS total_count,
        COUNT(*) FILTER (WHERE re.resolved_at IS NOT NULL) AS resolved_count,
        ROUND(
            AVG(
                EXTRACT(EPOCH FROM (re.resolved_at - re.created_at)) / 3600
            ) FILTER (WHERE re.resolved_at IS NOT NULL),
            1
        ) AS avg_resolution_time_hours,
        COUNT(DISTINCT re.patient_id) AS patients_affected
    FROM risk_escalations re
    WHERE re.therapist_id = p_therapist_id
      AND re.created_at >= NOW() - (p_days || ' days')::INTERVAL
    GROUP BY re.escalation_type
    ORDER BY total_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_escalation_stats IS
    'Returns escalation statistics by type for a therapist over specified days';

-- =====================================================
-- Function: Check for Duplicate Escalation
-- =====================================================

CREATE OR REPLACE FUNCTION has_active_escalation(
    p_patient_id UUID,
    p_escalation_type TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM risk_escalations
        WHERE patient_id = p_patient_id
          AND escalation_type = p_escalation_type
          AND resolved_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION has_active_escalation IS
    'Checks if an active escalation of the given type already exists for a patient';

-- =====================================================
-- Seed Sample Data (for development)
-- =====================================================

-- Note: Uncomment for development/testing
/*
DO $$
DECLARE
    v_patient_id UUID;
    v_therapist_id UUID;
BEGIN
    -- Get a sample patient and therapist for testing
    SELECT p.id, p.therapist_id
    INTO v_patient_id, v_therapist_id
    FROM patients p
    LIMIT 1;

    IF v_patient_id IS NOT NULL THEN
        -- Insert sample escalations
        INSERT INTO risk_escalations (
            patient_id, therapist_id, escalation_type, severity,
            trigger_data, message, recommendation
        ) VALUES
        (
            v_patient_id, v_therapist_id, 'pain_spike', 'critical',
            '{"new_pain_level": 8, "previous_pain_level": 3, "increase": 5}',
            'Pain level spiked from 3 to 8 (+5 points)',
            'Immediate follow-up recommended. Review recent activities for potential injury.'
        ),
        (
            v_patient_id, v_therapist_id, 'low_recovery', 'high',
            '{"average_score": 35, "consecutive_days": 4, "threshold": 40}',
            'Recovery score has been below 40% for 4 consecutive days (avg: 35%)',
            'Consider reducing training intensity. Schedule a check-in call.'
        ),
        (
            v_patient_id, v_therapist_id, 'missed_sessions', 'medium',
            '{"consecutive_misses": 3, "threshold": 3}',
            'Patient has missed 3 consecutive scheduled sessions',
            'Reach out to understand barriers to adherence.'
        );

        RAISE NOTICE 'Sample escalations created for patient %', v_patient_id;
    END IF;
END $$;
*/

-- =====================================================
-- Verification
-- =====================================================

DO $$
DECLARE
    escalation_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO escalation_count FROM risk_escalations;

    RAISE NOTICE 'Migration complete:';
    RAISE NOTICE '  - risk_escalations table: % rows', escalation_count;
    RAISE NOTICE '  - RLS policies enabled';
    RAISE NOTICE '  - Indexes created';
    RAISE NOTICE '  - Views created: vw_escalation_summary, vw_risk_escalations_with_patient';
    RAISE NOTICE '  - Functions created: get_escalation_stats, has_active_escalation';
END $$;
