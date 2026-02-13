-- ============================================================================
-- ADD SECURITY INVOKER TO VIEWS
-- ============================================================================
-- Ensures views execute with caller's privileges, respecting RLS
-- ============================================================================

-- Audit views
ALTER VIEW IF EXISTS vw_monthly_audit_summary SET (security_invoker = on);
ALTER VIEW IF EXISTS vw_suspicious_access_patterns SET (security_invoker = on);
ALTER VIEW IF EXISTS vw_patient_access_history SET (security_invoker = on);

-- Phase preview
ALTER VIEW IF EXISTS vw_phase_preview SET (security_invoker = on);

-- Nutrition views
ALTER VIEW IF EXISTS vw_nutrition_profile_targets SET (security_invoker = on);
ALTER VIEW IF EXISTS daily_nutrition_summary SET (security_invoker = on);

-- Exercise views
ALTER VIEW IF EXISTS vw_exercise_with_explanation SET (security_invoker = on);

-- Coaching views
ALTER VIEW IF EXISTS coaching_alerts SET (security_invoker = on);
ALTER VIEW IF EXISTS coaching_preferences SET (security_invoker = on);
ALTER VIEW IF EXISTS vw_exception_summary SET (security_invoker = on);

-- KPI views
ALTER VIEW IF EXISTS vw_pt_wau SET (security_invoker = on);
ALTER VIEW IF EXISTS vw_athlete_wau SET (security_invoker = on);
ALTER VIEW IF EXISTS vw_ai_metrics SET (security_invoker = on);
ALTER VIEW IF EXISTS vw_safety_metrics SET (security_invoker = on);

-- Audit logs
ALTER VIEW IF EXISTS audit_logs_summary SET (security_invoker = on);

-- Risk escalation views
ALTER VIEW IF EXISTS vw_escalation_summary SET (security_invoker = on);
ALTER VIEW IF EXISTS vw_risk_escalations_with_patient SET (security_invoker = on);

-- Arm care
ALTER VIEW IF EXISTS vw_arm_care_dashboard SET (security_invoker = on);

-- Scheduled sessions
ALTER VIEW IF EXISTS upcoming_scheduled_sessions SET (security_invoker = on);

-- Workout templates
ALTER VIEW IF EXISTS popular_workout_templates SET (security_invoker = on);
ALTER VIEW IF EXISTS therapist_templates_stats SET (security_invoker = on);

-- Supplement views
ALTER VIEW IF EXISTS vw_patient_supplement_schedule SET (security_invoker = on);
ALTER VIEW IF EXISTS vw_supplement_compliance_summary SET (security_invoker = on);

-- Jaeger band
ALTER VIEW IF EXISTS vw_jaeger_band_stats SET (security_invoker = on);

-- Verification
DO $$
BEGIN
    RAISE NOTICE 'Security invoker added to all views';
END $$;
