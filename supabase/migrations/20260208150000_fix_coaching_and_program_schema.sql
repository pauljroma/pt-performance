-- =============================================================================
-- Migration: Fix Coaching Alerts and Program Schema Issues
-- Date: 2026-02-08
-- Description: Creates aliases and views to fix schema mismatches between
--              iOS app expectations and actual database schema
--
-- Issues Fixed:
-- 1. coaching_alerts - iOS expects this, database has patient_alerts
-- 2. coaching_preferences - iOS expects this, database has therapist_coaching_preferences
-- 3. vw_exception_summary - View doesn't exist, iOS expects it
-- 4. program_enrollments.program_id - Column doesn't exist (it's program_library_id)
-- 5. programs foreign key from program_enrollments - Goes through program_library
-- 6. alert_type values mismatch between database and iOS app
-- =============================================================================

BEGIN;

-- =============================================================================
-- 0. UPDATE ALERT_TYPE CHECK CONSTRAINT
-- Expand allowed values to match iOS app expectations
-- =============================================================================

-- First, drop the existing constraint
ALTER TABLE patient_alerts DROP CONSTRAINT IF EXISTS patient_alerts_alert_type_check;

-- Add new constraint with expanded values
ALTER TABLE patient_alerts ADD CONSTRAINT patient_alerts_alert_type_check
    CHECK (alert_type IN (
        -- Original values
        'safety_check',
        'exception',
        'pain_alert',
        -- iOS expected values
        'adherence_dropoff',
        'pain_increase',
        'missed_sessions',
        'workload_spike',
        'recovery_issue',
        'program_completion',
        'milestone_reached',
        'rts_readiness',
        'assessment_due',
        'custom'
    ));

-- =============================================================================
-- 1. CREATE COACHING_ALERTS VIEW (alias for patient_alerts)
-- =============================================================================

CREATE OR REPLACE VIEW coaching_alerts AS
SELECT
    id,
    patient_id,
    therapist_id,
    rule_id,
    -- Map alert_type to iOS expected values where needed
    CASE
        WHEN alert_type = 'pain_alert' THEN 'pain_increase'
        WHEN alert_type = 'safety_check' THEN 'custom'
        WHEN alert_type = 'exception' THEN 'custom'
        ELSE alert_type
    END AS alert_type,
    severity,
    title,
    description AS message,
    trigger_data,
    -- Convert trigger_data to metadata format expected by iOS
    trigger_data::TEXT::JSON AS metadata,
    status,
    status = 'acknowledged' AS is_acknowledged,
    acknowledged_at,
    resolved_at,
    resolution_notes,
    created_at,
    -- Add dismissed_at for compatibility
    CASE WHEN status = 'dismissed' THEN resolved_at ELSE NULL END AS dismissed_at
FROM patient_alerts;

COMMENT ON VIEW coaching_alerts IS 'Alias view for patient_alerts to match iOS app expectations (Build 180)';

-- Grant access to the view
GRANT SELECT, INSERT, UPDATE, DELETE ON coaching_alerts TO authenticated;

-- Create instead-of triggers for DML operations on the view
CREATE OR REPLACE FUNCTION coaching_alerts_insert_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO patient_alerts (
        id, patient_id, therapist_id, rule_id, alert_type,
        severity, title, description, trigger_data, status,
        acknowledged_at, resolved_at, resolution_notes, created_at
    ) VALUES (
        COALESCE(NEW.id, gen_random_uuid()),
        NEW.patient_id,
        NEW.therapist_id,
        NEW.rule_id,
        COALESCE(NEW.alert_type, 'exception'),
        NEW.severity,
        NEW.title,
        NEW.message,
        NEW.trigger_data,
        COALESCE(NEW.status, 'active'),
        NEW.acknowledged_at,
        NEW.resolved_at,
        NEW.resolution_notes,
        COALESCE(NEW.created_at, now())
    )
    RETURNING * INTO NEW;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION coaching_alerts_update_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE patient_alerts SET
        therapist_id = NEW.therapist_id,
        rule_id = NEW.rule_id,
        alert_type = NEW.alert_type,
        severity = NEW.severity,
        title = NEW.title,
        description = NEW.message,
        trigger_data = NEW.trigger_data,
        status = CASE
            WHEN NEW.dismissed_at IS NOT NULL THEN 'dismissed'
            ELSE NEW.status
        END,
        acknowledged_at = NEW.acknowledged_at,
        resolved_at = COALESCE(NEW.resolved_at, NEW.dismissed_at),
        resolution_notes = NEW.resolution_notes
    WHERE id = OLD.id;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION coaching_alerts_delete_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    DELETE FROM patient_alerts WHERE id = OLD.id;
    RETURN OLD;
END;
$$;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS coaching_alerts_insert ON coaching_alerts;
DROP TRIGGER IF EXISTS coaching_alerts_update ON coaching_alerts;
DROP TRIGGER IF EXISTS coaching_alerts_delete ON coaching_alerts;

-- Create the instead-of triggers
CREATE TRIGGER coaching_alerts_insert
    INSTEAD OF INSERT ON coaching_alerts
    FOR EACH ROW
    EXECUTE FUNCTION coaching_alerts_insert_trigger();

CREATE TRIGGER coaching_alerts_update
    INSTEAD OF UPDATE ON coaching_alerts
    FOR EACH ROW
    EXECUTE FUNCTION coaching_alerts_update_trigger();

CREATE TRIGGER coaching_alerts_delete
    INSTEAD OF DELETE ON coaching_alerts
    FOR EACH ROW
    EXECUTE FUNCTION coaching_alerts_delete_trigger();

-- =============================================================================
-- 2. CREATE COACHING_PREFERENCES VIEW (alias for therapist_coaching_preferences)
-- =============================================================================

CREATE OR REPLACE VIEW coaching_preferences AS
SELECT
    id,
    therapist_id,
    notify_on_critical AS email_notifications,
    notify_on_high AS push_notifications,
    notify_on_critical AS critical_alert_sound,
    email_digest_frequency != 'none' AS daily_digest_enabled,
    CASE
        WHEN email_digest_frequency = 'daily' THEN '09:00'
        ELSE NULL
    END AS daily_digest_time,
    ARRAY['critical', 'high', 'medium', 'low']::TEXT[] AS alert_priorities_enabled,
    ARRAY['pain_threshold', 'adherence_drop', 'missed_sessions', 'rpe_spike', 'workload_flag']::TEXT[] AS alert_types_enabled,
    NULL::INT AS auto_acknowledge_hours,
    created_at,
    updated_at
FROM therapist_coaching_preferences;

COMMENT ON VIEW coaching_preferences IS 'Alias view for therapist_coaching_preferences to match iOS app expectations (Build 180)';

-- Grant access to the view
GRANT SELECT ON coaching_preferences TO authenticated;

-- =============================================================================
-- 3. CREATE VW_EXCEPTION_SUMMARY VIEW
-- Aggregates exception counts for a therapist's caseload
-- =============================================================================

CREATE OR REPLACE VIEW vw_exception_summary AS
SELECT
    p.therapist_id,
    COUNT(DISTINCT pa.id) FILTER (WHERE pa.status = 'active') AS total_active_alerts,
    COUNT(DISTINCT pa.id) FILTER (WHERE pa.status = 'active' AND pa.severity = 'critical') AS critical_count,
    COUNT(DISTINCT pa.id) FILTER (WHERE pa.status = 'active' AND pa.severity = 'high') AS high_count,
    COUNT(DISTINCT pa.id) FILTER (WHERE pa.status = 'active' AND pa.severity = 'medium') AS medium_count,
    COUNT(DISTINCT pa.id) FILTER (WHERE pa.status = 'active' AND pa.severity = 'low') AS low_count,
    COUNT(DISTINCT p.id) FILTER (WHERE pa.status = 'active') AS patients_needing_attention,
    MIN(pa.created_at) FILTER (WHERE pa.status = 'active') AS oldest_unresolved_date
FROM patients p
LEFT JOIN patient_alerts pa ON pa.patient_id = p.id
WHERE p.therapist_id IS NOT NULL
GROUP BY p.therapist_id;

COMMENT ON VIEW vw_exception_summary IS 'Aggregated exception summary by therapist for dashboard display (Build 180)';

-- Grant access to the view
GRANT SELECT ON vw_exception_summary TO authenticated;

-- =============================================================================
-- 3b. UPDATE VW_PATIENT_EXCEPTIONS VIEW
-- Add columns expected by iOS app (alert_count, critical_count, high_count, etc.)
-- =============================================================================

-- Drop and recreate to add new computed columns for iOS compatibility
DROP VIEW IF EXISTS vw_patient_exceptions CASCADE;

CREATE OR REPLACE VIEW vw_patient_exceptions AS
WITH patient_pain AS (
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
    SELECT
        patient_id::uuid AS patient_id,
        adherence_pct,
        total_sessions,
        completed_sessions
    FROM vw_patient_adherence
),
missed_sessions AS (
    SELECT
        ss.patient_id,
        COUNT(*) FILTER (WHERE ss.status = 'cancelled' OR (ss.status = 'scheduled' AND ss.scheduled_date < CURRENT_DATE)) AS missed_count
    FROM scheduled_sessions ss
    WHERE ss.scheduled_date > CURRENT_DATE - interval '14 days'
    GROUP BY ss.patient_id
),
workload_status AS (
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
    SELECT
        pa.patient_id,
        COUNT(*) AS alert_count,
        COUNT(*) FILTER (WHERE pa.severity = 'critical') AS critical_count,
        COUNT(*) FILTER (WHERE pa.severity = 'high') AS high_count,
        MAX(pa.severity) AS max_severity,
        MIN(pa.created_at) AS oldest_alert_date,
        MAX(pa.created_at) AS latest_alert_date
    FROM patient_alerts pa
    WHERE pa.status = 'active'
    GROUP BY pa.patient_id
)
SELECT
    p.id,
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
    COALESCE(pa_adh.adherence_pct, 0) AS adherence_pct,
    COALESCE(pa_adh.total_sessions, 0) AS total_sessions,
    COALESCE(pa_adh.completed_sessions, 0) AS completed_sessions,
    CASE
        WHEN pa_adh.adherence_pct < 40 THEN 'critical'
        WHEN pa_adh.adherence_pct < 60 THEN 'high'
        WHEN pa_adh.adherence_pct < 80 THEN 'medium'
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

    -- Alert summary (iOS expected columns)
    COALESCE(aa.alert_count, 0)::INT AS alert_count,
    COALESCE(aa.critical_count, 0)::INT AS critical_count,
    COALESCE(aa.high_count, 0)::INT AS high_count,
    aa.max_severity AS max_alert_severity,
    aa.oldest_alert_date,
    aa.latest_alert_date,

    -- Legacy column name for backwards compatibility
    COALESCE(aa.alert_count, 0)::INT AS active_alert_count,

    -- Computed exception flags
    (pp.max_pain_7d >= 7 OR ws.joint_pain = true) AS has_pain_exception,
    (pa_adh.adherence_pct < 60) AS has_adherence_exception,
    (ms.missed_count >= 3) AS has_missed_sessions_exception,
    (ws.high_acwr = true OR ws.rpe_overshoot = true) AS has_workload_exception,

    -- Overall exception status
    CASE
        WHEN pp.max_pain_7d >= 8 OR pa_adh.adherence_pct < 40 OR ms.missed_count >= 5 OR ws.high_acwr = true THEN 'critical'
        WHEN pp.max_pain_7d >= 6 OR pa_adh.adherence_pct < 60 OR ms.missed_count >= 3 THEN 'high'
        WHEN pp.max_pain_7d >= 4 OR pa_adh.adherence_pct < 80 OR ms.missed_count >= 1 THEN 'medium'
        ELSE 'normal'
    END AS exception_status,

    -- Needs attention flag
    (
        pp.max_pain_7d >= 7 OR
        pa_adh.adherence_pct < 60 OR
        ms.missed_count >= 3 OR
        ws.high_acwr = true OR
        ws.rpe_overshoot = true OR
        ws.joint_pain = true OR
        aa.alert_count > 0
    ) AS needs_attention

FROM patients p
LEFT JOIN therapists t ON t.id = p.therapist_id
LEFT JOIN patient_pain pp ON pp.patient_id = p.id
LEFT JOIN patient_adherence pa_adh ON pa_adh.patient_id = p.id
LEFT JOIN missed_sessions ms ON ms.patient_id = p.id
LEFT JOIN workload_status ws ON ws.patient_id = p.id
LEFT JOIN active_alerts aa ON aa.patient_id = p.id;

COMMENT ON VIEW vw_patient_exceptions IS 'Consolidated view of patients needing attention with iOS-compatible columns (Build 180)';

-- Grant access
GRANT SELECT ON vw_patient_exceptions TO authenticated;

-- Set security invoker for RLS
ALTER VIEW vw_patient_exceptions SET (security_invoker = on);

-- =============================================================================
-- 4. CREATE VW_PROGRAM_ENROLLMENTS_WITH_PROGRAMS VIEW
-- Joins program_enrollments through program_library to programs
-- This provides the programs relationship that the iOS app expects
-- =============================================================================

CREATE OR REPLACE VIEW vw_program_enrollments_with_programs AS
SELECT
    pe.id,
    pe.patient_id,
    pe.program_library_id,
    pl.program_id,  -- The actual program_id through program_library
    pe.enrolled_at,
    pe.started_at,
    pe.completed_at,
    pe.status,
    pe.progress_percentage,
    pe.notes,
    -- Program details (via program_library -> programs)
    pr.id AS program_pk,
    pr.name AS program_name,
    pr.description AS program_description,
    pr.therapist_id AS program_therapist_id,
    -- Additional program_library details
    pl.title AS library_title,
    pl.category AS library_category,
    pl.difficulty_level,
    pl.duration_weeks
FROM program_enrollments pe
JOIN program_library pl ON pl.id = pe.program_library_id
JOIN programs pr ON pr.id = pl.program_id;

COMMENT ON VIEW vw_program_enrollments_with_programs IS 'Program enrollments with joined program details via program_library (Build 180)';

-- Grant access to the view
GRANT SELECT ON vw_program_enrollments_with_programs TO authenticated;

-- =============================================================================
-- 5. Add dropped_at column to program_enrollments if not exists
-- The iOS app expects this column for retention tracking
-- =============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'program_enrollments'
        AND column_name = 'dropped_at'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE program_enrollments ADD COLUMN dropped_at TIMESTAMPTZ;
        COMMENT ON COLUMN program_enrollments.dropped_at IS 'Timestamp when user dropped/cancelled the program (Build 180)';
    END IF;
END $$;

-- =============================================================================
-- 6. VALIDATION
-- =============================================================================

DO $$
DECLARE
    coaching_alerts_exists BOOLEAN;
    coaching_prefs_exists BOOLEAN;
    exception_summary_exists BOOLEAN;
    enrollments_view_exists BOOLEAN;
    dropped_at_exists BOOLEAN;
BEGIN
    -- Check views exist
    SELECT EXISTS(
        SELECT 1 FROM information_schema.views
        WHERE table_name = 'coaching_alerts' AND table_schema = 'public'
    ) INTO coaching_alerts_exists;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.views
        WHERE table_name = 'coaching_preferences' AND table_schema = 'public'
    ) INTO coaching_prefs_exists;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.views
        WHERE table_name = 'vw_exception_summary' AND table_schema = 'public'
    ) INTO exception_summary_exists;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.views
        WHERE table_name = 'vw_program_enrollments_with_programs' AND table_schema = 'public'
    ) INTO enrollments_view_exists;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'program_enrollments'
        AND column_name = 'dropped_at'
        AND table_schema = 'public'
    ) INTO dropped_at_exists;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'SCHEMA FIX VALIDATION';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'coaching_alerts view: %', CASE WHEN coaching_alerts_exists THEN 'CREATED' ELSE 'MISSING' END;
    RAISE NOTICE 'coaching_preferences view: %', CASE WHEN coaching_prefs_exists THEN 'CREATED' ELSE 'MISSING' END;
    RAISE NOTICE 'vw_exception_summary view: %', CASE WHEN exception_summary_exists THEN 'CREATED' ELSE 'MISSING' END;
    RAISE NOTICE 'vw_program_enrollments_with_programs view: %', CASE WHEN enrollments_view_exists THEN 'CREATED' ELSE 'MISSING' END;
    RAISE NOTICE 'program_enrollments.dropped_at column: %', CASE WHEN dropped_at_exists THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE '============================================';
END $$;

COMMIT;
