-- =============================================================================
-- Migration: Create Clinical Safety Checks and Exception-Based Coaching System
-- Date: 2026-02-07
-- Build: 180
-- Description: Creates tables for safety rules, patient alerts, therapist coaching
--              preferences, and exception monitoring views
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1. SAFETY_RULES TABLE
-- Clinical safety rules that trigger alerts for patients
-- =============================================================================

CREATE TABLE IF NOT EXISTS safety_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name TEXT NOT NULL,
    rule_type TEXT NOT NULL CHECK (rule_type IN (
        'pain_threshold',
        'adherence_drop',
        'missed_sessions',
        'rpe_spike',
        'workload_flag'
    )),
    condition JSONB NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    message_template TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for safety_rules
CREATE INDEX IF NOT EXISTS idx_safety_rules_type ON safety_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_safety_rules_severity ON safety_rules(severity);
CREATE INDEX IF NOT EXISTS idx_safety_rules_active ON safety_rules(is_active) WHERE is_active = true;

-- Comments
COMMENT ON TABLE safety_rules IS 'Clinical safety rules that trigger alerts for exception-based coaching (Build 180)';
COMMENT ON COLUMN safety_rules.rule_type IS 'Type of rule: pain_threshold, adherence_drop, missed_sessions, rpe_spike, workload_flag';
COMMENT ON COLUMN safety_rules.condition IS 'JSON object with threshold values and comparison operators';
COMMENT ON COLUMN safety_rules.severity IS 'Alert severity level: critical, high, medium, low';
COMMENT ON COLUMN safety_rules.message_template IS 'Template for alert message with {{placeholder}} variables';

-- =============================================================================
-- 2. PATIENT_ALERTS TABLE
-- Generated alerts for patients based on safety rules
-- =============================================================================

CREATE TABLE IF NOT EXISTS patient_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    therapist_id UUID REFERENCES therapists(id),
    rule_id UUID REFERENCES safety_rules(id),
    alert_type TEXT NOT NULL CHECK (alert_type IN (
        'safety_check',
        'exception',
        'pain_alert'
    )),
    severity TEXT NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    trigger_data JSONB,
    status TEXT DEFAULT 'active' CHECK (status IN (
        'active',
        'acknowledged',
        'resolved',
        'dismissed'
    )),
    acknowledged_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for patient_alerts
CREATE INDEX IF NOT EXISTS idx_patient_alerts_patient_id ON patient_alerts(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_alerts_therapist_id ON patient_alerts(therapist_id);
CREATE INDEX IF NOT EXISTS idx_patient_alerts_rule_id ON patient_alerts(rule_id);
CREATE INDEX IF NOT EXISTS idx_patient_alerts_status ON patient_alerts(status);
CREATE INDEX IF NOT EXISTS idx_patient_alerts_severity ON patient_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_patient_alerts_created_at ON patient_alerts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_patient_alerts_active ON patient_alerts(patient_id, status)
    WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_patient_alerts_active_critical ON patient_alerts(therapist_id, severity)
    WHERE status = 'active' AND severity IN ('critical', 'high');

-- Comments
COMMENT ON TABLE patient_alerts IS 'Generated alerts for patients based on safety rules (Build 180)';
COMMENT ON COLUMN patient_alerts.alert_type IS 'Type of alert: safety_check, exception, pain_alert';
COMMENT ON COLUMN patient_alerts.trigger_data IS 'JSON object with data that triggered the alert';
COMMENT ON COLUMN patient_alerts.status IS 'Alert status: active, acknowledged, resolved, dismissed';

-- =============================================================================
-- 3. THERAPIST_COACHING_PREFERENCES TABLE
-- Per-therapist alert settings and notification preferences
-- =============================================================================

CREATE TABLE IF NOT EXISTS therapist_coaching_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapist_id UUID NOT NULL REFERENCES therapists(id) UNIQUE,
    pain_threshold INT DEFAULT 7 CHECK (pain_threshold BETWEEN 1 AND 10),
    adherence_threshold INT DEFAULT 60 CHECK (adherence_threshold BETWEEN 0 AND 100),
    missed_sessions_threshold INT DEFAULT 3 CHECK (missed_sessions_threshold >= 1),
    notify_on_critical BOOLEAN DEFAULT true,
    notify_on_high BOOLEAN DEFAULT true,
    notify_on_medium BOOLEAN DEFAULT false,
    email_digest_frequency TEXT DEFAULT 'daily' CHECK (email_digest_frequency IN (
        'realtime',
        'hourly',
        'daily',
        'weekly',
        'none'
    )),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index for therapist_coaching_preferences
CREATE INDEX IF NOT EXISTS idx_therapist_coaching_prefs_therapist_id
    ON therapist_coaching_preferences(therapist_id);

-- Comments
COMMENT ON TABLE therapist_coaching_preferences IS 'Per-therapist alert settings for exception-based coaching (Build 180)';
COMMENT ON COLUMN therapist_coaching_preferences.pain_threshold IS 'Pain score threshold (1-10) that triggers alert';
COMMENT ON COLUMN therapist_coaching_preferences.adherence_threshold IS 'Adherence percentage below which alerts trigger';
COMMENT ON COLUMN therapist_coaching_preferences.missed_sessions_threshold IS 'Number of missed sessions before alerting';
COMMENT ON COLUMN therapist_coaching_preferences.email_digest_frequency IS 'How often to send email digests: realtime, hourly, daily, weekly, none';

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_therapist_coaching_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS therapist_coaching_preferences_updated_at ON therapist_coaching_preferences;
CREATE TRIGGER therapist_coaching_preferences_updated_at
    BEFORE UPDATE ON therapist_coaching_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_therapist_coaching_preferences_updated_at();

-- =============================================================================
-- 4. VW_PATIENT_EXCEPTIONS VIEW
-- Consolidated view of patients needing attention with computed fields
-- =============================================================================

CREATE OR REPLACE VIEW vw_patient_exceptions AS
WITH patient_pain AS (
    -- Get latest pain scores for each patient
    SELECT
        el.patient_id,
        MAX(el.pain_score) FILTER (WHERE el.logged_at > now() - interval '7 days') AS max_pain_7d,
        AVG(el.pain_score) FILTER (WHERE el.logged_at > now() - interval '7 days') AS avg_pain_7d,
        MAX(el.logged_at) AS last_pain_logged
    FROM exercise_logs el
    WHERE el.pain_score IS NOT NULL
    GROUP BY el.patient_id
),
patient_adherence AS (
    -- Get adherence stats from existing view
    -- Cast patient_id to UUID for join compatibility
    SELECT
        patient_id::uuid AS patient_id,
        adherence_pct,
        total_sessions,
        completed_sessions
    FROM vw_patient_adherence
),
missed_sessions AS (
    -- Count missed scheduled sessions in last 14 days
    SELECT
        ss.patient_id,
        COUNT(*) FILTER (WHERE ss.status = 'cancelled' OR (ss.status = 'scheduled' AND ss.scheduled_date < CURRENT_DATE)) AS missed_count
    FROM scheduled_sessions ss
    WHERE ss.scheduled_date > CURRENT_DATE - interval '14 days'
    GROUP BY ss.patient_id
),
workload_status AS (
    -- Get latest workload flags
    SELECT DISTINCT ON (wf.patient_id)
        wf.patient_id,
        wf.acwr,
        wf.high_acwr,
        wf.low_acwr,
        wf.rpe_overshoot,
        wf.joint_pain,
        wf.deload_triggered
    FROM workload_flags wf
    ORDER BY wf.patient_id, wf.calculated_at DESC
),
active_alerts AS (
    -- Count active alerts per patient
    SELECT
        pa.patient_id,
        COUNT(*) AS alert_count,
        MAX(pa.severity) AS max_severity
    FROM patient_alerts pa
    WHERE pa.status = 'active'
    GROUP BY pa.patient_id
)
SELECT
    p.id AS patient_id,
    p.first_name,
    p.last_name,
    p.email,
    p.therapist_id,
    t.first_name AS therapist_first_name,
    t.last_name AS therapist_last_name,

    -- Pain metrics
    COALESCE(pp.max_pain_7d, 0) AS max_pain_7d,
    COALESCE(pp.avg_pain_7d, 0) AS avg_pain_7d,
    CASE
        WHEN pp.max_pain_7d >= 8 THEN 'critical'
        WHEN pp.max_pain_7d >= 6 THEN 'high'
        WHEN pp.max_pain_7d >= 4 THEN 'medium'
        ELSE 'low'
    END AS pain_severity,

    -- Adherence metrics
    COALESCE(pa.adherence_pct, 0) AS adherence_pct,
    COALESCE(pa.total_sessions, 0) AS total_sessions,
    COALESCE(pa.completed_sessions, 0) AS completed_sessions,
    CASE
        WHEN pa.adherence_pct < 40 THEN 'critical'
        WHEN pa.adherence_pct < 60 THEN 'high'
        WHEN pa.adherence_pct < 80 THEN 'medium'
        ELSE 'low'
    END AS adherence_severity,

    -- Missed sessions
    COALESCE(ms.missed_count, 0) AS missed_sessions_14d,
    CASE
        WHEN ms.missed_count >= 5 THEN 'critical'
        WHEN ms.missed_count >= 3 THEN 'high'
        WHEN ms.missed_count >= 1 THEN 'medium'
        ELSE 'low'
    END AS missed_severity,

    -- Workload status
    COALESCE(ws.acwr, 0) AS acwr,
    COALESCE(ws.high_acwr, false) AS high_acwr,
    COALESCE(ws.low_acwr, false) AS low_acwr,
    COALESCE(ws.rpe_overshoot, false) AS rpe_overshoot,
    COALESCE(ws.joint_pain, false) AS joint_pain,
    COALESCE(ws.deload_triggered, false) AS deload_triggered,

    -- Alert summary
    COALESCE(aa.alert_count, 0) AS active_alert_count,
    aa.max_severity AS max_alert_severity,

    -- Computed exception flags
    (pp.max_pain_7d >= 7 OR ws.joint_pain = true) AS has_pain_exception,
    (pa.adherence_pct < 60) AS has_adherence_exception,
    (ms.missed_count >= 3) AS has_missed_sessions_exception,
    (ws.high_acwr = true OR ws.rpe_overshoot = true) AS has_workload_exception,

    -- Overall exception status
    CASE
        WHEN pp.max_pain_7d >= 8 OR pa.adherence_pct < 40 OR ms.missed_count >= 5 OR ws.high_acwr = true THEN 'critical'
        WHEN pp.max_pain_7d >= 6 OR pa.adherence_pct < 60 OR ms.missed_count >= 3 THEN 'high'
        WHEN pp.max_pain_7d >= 4 OR pa.adherence_pct < 80 OR ms.missed_count >= 1 THEN 'medium'
        ELSE 'normal'
    END AS exception_status,

    -- Needs attention flag
    (
        pp.max_pain_7d >= 7 OR
        pa.adherence_pct < 60 OR
        ms.missed_count >= 3 OR
        ws.high_acwr = true OR
        ws.rpe_overshoot = true OR
        ws.joint_pain = true OR
        aa.alert_count > 0
    ) AS needs_attention

FROM patients p
LEFT JOIN therapists t ON t.id = p.therapist_id
LEFT JOIN patient_pain pp ON pp.patient_id = p.id
LEFT JOIN patient_adherence pa ON pa.patient_id = p.id
LEFT JOIN missed_sessions ms ON ms.patient_id = p.id
LEFT JOIN workload_status ws ON ws.patient_id = p.id
LEFT JOIN active_alerts aa ON aa.patient_id = p.id;

COMMENT ON VIEW vw_patient_exceptions IS 'Consolidated view of patients needing attention with computed exception fields (Build 180)';

-- =============================================================================
-- 5. ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Enable RLS on all new tables
ALTER TABLE safety_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE therapist_coaching_preferences ENABLE ROW LEVEL SECURITY;

-- ---------- SAFETY_RULES RLS ----------
-- Safety rules are readable by all authenticated users
CREATE POLICY "Authenticated users can read safety rules"
    ON safety_rules FOR SELECT
    TO authenticated
    USING (true);

-- Only therapists can create/update safety rules
CREATE POLICY "Therapists can manage safety rules"
    ON safety_rules FOR ALL
    TO authenticated
    USING (is_therapist(auth.uid()) = true)
    WITH CHECK (is_therapist(auth.uid()) = true);

-- ---------- PATIENT_ALERTS RLS ----------
-- Patients can view their own alerts
CREATE POLICY "Patients can view own alerts"
    ON patient_alerts FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Therapists can view alerts for their patients
CREATE POLICY "Therapists can view patient alerts"
    ON patient_alerts FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            JOIN therapists t ON t.id = p.therapist_id
            WHERE t.user_id = auth.uid()
        )
        OR
        therapist_id IN (
            SELECT id FROM therapists WHERE user_id = auth.uid()
        )
        OR
        is_therapist(auth.uid()) = true
    );

-- Therapists can create alerts for their patients
CREATE POLICY "Therapists can create patient alerts"
    ON patient_alerts FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT p.id FROM patients p
            JOIN therapists t ON t.id = p.therapist_id
            WHERE t.user_id = auth.uid()
        )
        OR
        is_therapist(auth.uid()) = true
    );

-- Therapists can update alerts they have access to
CREATE POLICY "Therapists can update patient alerts"
    ON patient_alerts FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            JOIN therapists t ON t.id = p.therapist_id
            WHERE t.user_id = auth.uid()
        )
        OR
        therapist_id IN (
            SELECT id FROM therapists WHERE user_id = auth.uid()
        )
        OR
        is_therapist(auth.uid()) = true
    )
    WITH CHECK (
        patient_id IN (
            SELECT p.id FROM patients p
            JOIN therapists t ON t.id = p.therapist_id
            WHERE t.user_id = auth.uid()
        )
        OR
        therapist_id IN (
            SELECT id FROM therapists WHERE user_id = auth.uid()
        )
        OR
        is_therapist(auth.uid()) = true
    );

-- Service role can manage all alerts (for automated systems)
CREATE POLICY "Service can manage all alerts"
    ON patient_alerts FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ---------- THERAPIST_COACHING_PREFERENCES RLS ----------
-- Therapists can view their own preferences
CREATE POLICY "Therapists can view own coaching preferences"
    ON therapist_coaching_preferences FOR SELECT
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM therapists WHERE user_id = auth.uid()
        )
    );

-- Therapists can manage their own preferences
CREATE POLICY "Therapists can manage own coaching preferences"
    ON therapist_coaching_preferences FOR ALL
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM therapists WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM therapists WHERE user_id = auth.uid()
        )
    );

-- =============================================================================
-- 6. GRANT VIEW ACCESS
-- =============================================================================

GRANT SELECT ON vw_patient_exceptions TO authenticated;

-- =============================================================================
-- 7. HELPER FUNCTIONS
-- =============================================================================

-- Function to acknowledge an alert
CREATE OR REPLACE FUNCTION acknowledge_patient_alert(alert_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE patient_alerts
    SET
        status = 'acknowledged',
        acknowledged_at = now()
    WHERE id = alert_id
    AND status = 'active';
END;
$$;

-- Function to resolve an alert with notes
CREATE OR REPLACE FUNCTION resolve_patient_alert(alert_id UUID, notes TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE patient_alerts
    SET
        status = 'resolved',
        resolved_at = now(),
        resolution_notes = notes
    WHERE id = alert_id
    AND status IN ('active', 'acknowledged');
END;
$$;

-- Function to dismiss an alert
CREATE OR REPLACE FUNCTION dismiss_patient_alert(alert_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE patient_alerts
    SET
        status = 'dismissed',
        resolved_at = now()
    WHERE id = alert_id
    AND status IN ('active', 'acknowledged');
END;
$$;

-- Function to get therapist preferences with defaults
CREATE OR REPLACE FUNCTION get_therapist_coaching_preferences(p_therapist_id UUID)
RETURNS TABLE (
    pain_threshold INT,
    adherence_threshold INT,
    missed_sessions_threshold INT,
    notify_on_critical BOOLEAN,
    notify_on_high BOOLEAN,
    notify_on_medium BOOLEAN,
    email_digest_frequency TEXT
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT
        COALESCE(tcp.pain_threshold, 7),
        COALESCE(tcp.adherence_threshold, 60),
        COALESCE(tcp.missed_sessions_threshold, 3),
        COALESCE(tcp.notify_on_critical, true),
        COALESCE(tcp.notify_on_high, true),
        COALESCE(tcp.notify_on_medium, false),
        COALESCE(tcp.email_digest_frequency, 'daily')
    FROM therapists t
    LEFT JOIN therapist_coaching_preferences tcp ON tcp.therapist_id = t.id
    WHERE t.id = p_therapist_id;
$$;

COMMENT ON FUNCTION acknowledge_patient_alert IS 'Mark a patient alert as acknowledged (Build 180)';
COMMENT ON FUNCTION resolve_patient_alert IS 'Mark a patient alert as resolved with optional notes (Build 180)';
COMMENT ON FUNCTION dismiss_patient_alert IS 'Dismiss a patient alert (Build 180)';
COMMENT ON FUNCTION get_therapist_coaching_preferences IS 'Get therapist coaching preferences with defaults (Build 180)';

-- =============================================================================
-- 8. SEED DEFAULT SAFETY RULES
-- =============================================================================

-- Pain threshold rules
INSERT INTO safety_rules (rule_name, rule_type, condition, severity, message_template, is_active)
VALUES
    (
        'Critical Pain Alert',
        'pain_threshold',
        '{"threshold": 8, "operator": ">=", "window_days": 1}'::jsonb,
        'critical',
        'Patient {{patient_name}} reported pain level {{pain_score}}/10, which exceeds the critical threshold.',
        true
    ),
    (
        'High Pain Alert',
        'pain_threshold',
        '{"threshold": 7, "operator": ">=", "window_days": 1}'::jsonb,
        'high',
        'Patient {{patient_name}} reported pain level {{pain_score}}/10, which requires attention.',
        true
    ),
    (
        'Sustained Moderate Pain',
        'pain_threshold',
        '{"threshold": 5, "operator": ">=", "window_days": 3, "consecutive_days": 3}'::jsonb,
        'medium',
        'Patient {{patient_name}} has reported moderate pain (5+) for {{consecutive_days}} consecutive days.',
        true
    );

-- Adherence drop rules
INSERT INTO safety_rules (rule_name, rule_type, condition, severity, message_template, is_active)
VALUES
    (
        'Critical Adherence Drop',
        'adherence_drop',
        '{"threshold": 40, "operator": "<", "window_days": 14}'::jsonb,
        'critical',
        'Patient {{patient_name}} adherence has dropped to {{adherence_pct}}%, below critical threshold of 40%.',
        true
    ),
    (
        'Low Adherence Alert',
        'adherence_drop',
        '{"threshold": 60, "operator": "<", "window_days": 14}'::jsonb,
        'high',
        'Patient {{patient_name}} adherence is at {{adherence_pct}}%, below target threshold of 60%.',
        true
    ),
    (
        'Adherence Decline Warning',
        'adherence_drop',
        '{"threshold": 80, "operator": "<", "previous_threshold": 90, "decline_pct": 15}'::jsonb,
        'medium',
        'Patient {{patient_name}} adherence has declined by {{decline_pct}}% (now at {{adherence_pct}}%).',
        true
    );

-- Missed sessions rules
INSERT INTO safety_rules (rule_name, rule_type, condition, severity, message_template, is_active)
VALUES
    (
        'Multiple Missed Sessions',
        'missed_sessions',
        '{"threshold": 5, "operator": ">=", "window_days": 14}'::jsonb,
        'critical',
        'Patient {{patient_name}} has missed {{missed_count}} sessions in the past 14 days.',
        true
    ),
    (
        'Missed Sessions Alert',
        'missed_sessions',
        '{"threshold": 3, "operator": ">=", "window_days": 7}'::jsonb,
        'high',
        'Patient {{patient_name}} has missed {{missed_count}} sessions in the past week.',
        true
    ),
    (
        'Session Skip Warning',
        'missed_sessions',
        '{"threshold": 2, "operator": ">=", "window_days": 7}'::jsonb,
        'medium',
        'Patient {{patient_name}} has skipped {{missed_count}} scheduled sessions.',
        true
    );

-- RPE spike rules
INSERT INTO safety_rules (rule_name, rule_type, condition, severity, message_template, is_active)
VALUES
    (
        'RPE Overshoot Alert',
        'rpe_spike',
        '{"threshold": 2, "operator": ">=", "above_prescribed": true}'::jsonb,
        'high',
        'Patient {{patient_name}} RPE exceeded prescribed target by {{rpe_overshoot}} points.',
        true
    ),
    (
        'Consistent RPE Elevation',
        'rpe_spike',
        '{"threshold": 9, "operator": ">=", "window_days": 3, "consecutive_sessions": 3}'::jsonb,
        'high',
        'Patient {{patient_name}} has reported RPE 9+ for {{consecutive_sessions}} consecutive sessions.',
        true
    );

-- Workload flag rules
INSERT INTO safety_rules (rule_name, rule_type, condition, severity, message_template, is_active)
VALUES
    (
        'High ACWR Injury Risk',
        'workload_flag',
        '{"acwr_threshold": 1.5, "operator": ">="}'::jsonb,
        'critical',
        'Patient {{patient_name}} ACWR is {{acwr}} (>1.5), indicating elevated injury risk.',
        true
    ),
    (
        'Low ACWR Detraining Risk',
        'workload_flag',
        '{"acwr_threshold": 0.8, "operator": "<"}'::jsonb,
        'medium',
        'Patient {{patient_name}} ACWR is {{acwr}} (<0.8), indicating potential detraining.',
        true
    ),
    (
        'Deload Triggered',
        'workload_flag',
        '{"deload_triggered": true}'::jsonb,
        'high',
        'Auto-deload has been triggered for patient {{patient_name}} due to workload flags.',
        true
    );

-- =============================================================================
-- 9. VALIDATION
-- =============================================================================

DO $$
DECLARE
    safety_rules_count INT;
    patient_alerts_exists BOOLEAN;
    coaching_prefs_exists BOOLEAN;
    exceptions_view_exists BOOLEAN;
BEGIN
    -- Count seeded safety rules
    SELECT COUNT(*) INTO safety_rules_count FROM safety_rules;

    -- Check tables exist
    SELECT EXISTS(
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'patient_alerts' AND table_schema = 'public'
    ) INTO patient_alerts_exists;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'therapist_coaching_preferences' AND table_schema = 'public'
    ) INTO coaching_prefs_exists;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.views
        WHERE table_name = 'vw_patient_exceptions' AND table_schema = 'public'
    ) INTO exceptions_view_exists;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'COACHING ALERTS SYSTEM VALIDATION';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'safety_rules: % rules seeded', safety_rules_count;
    RAISE NOTICE 'patient_alerts table: %', CASE WHEN patient_alerts_exists THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE 'therapist_coaching_preferences table: %', CASE WHEN coaching_prefs_exists THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE 'vw_patient_exceptions view: %', CASE WHEN exceptions_view_exists THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE '============================================';
END $$;

COMMIT;
