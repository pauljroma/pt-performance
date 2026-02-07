-- Fix Coaching Function Security
-- Add missing search_path to SECURITY DEFINER functions
-- Created: 2026-02-07

-- ============================================================================
-- Fix: acknowledge_patient_alert
-- ============================================================================

CREATE OR REPLACE FUNCTION acknowledge_patient_alert(alert_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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

-- ============================================================================
-- Fix: resolve_patient_alert
-- ============================================================================

CREATE OR REPLACE FUNCTION resolve_patient_alert(alert_id UUID, notes TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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

-- ============================================================================
-- Fix: dismiss_patient_alert
-- ============================================================================

CREATE OR REPLACE FUNCTION dismiss_patient_alert(alert_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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

-- ============================================================================
-- Fix: get_therapist_coaching_preferences
-- ============================================================================

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
SET search_path = public
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

-- ============================================================================
-- Fix: update_therapist_coaching_preferences_updated_at trigger function
-- ============================================================================

CREATE OR REPLACE FUNCTION update_therapist_coaching_preferences_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- ============================================================================
-- Verification
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'COACHING FUNCTION SECURITY FIX COMPLETE';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Fixed functions:';
    RAISE NOTICE '  - acknowledge_patient_alert (added search_path)';
    RAISE NOTICE '  - resolve_patient_alert (added search_path)';
    RAISE NOTICE '  - dismiss_patient_alert (added search_path)';
    RAISE NOTICE '  - get_therapist_coaching_preferences (added search_path)';
    RAISE NOTICE '  - update_therapist_coaching_preferences_updated_at (added SECURITY DEFINER + search_path)';
    RAISE NOTICE '============================================';
END $$;
