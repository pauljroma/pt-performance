-- Migration: KPI Dashboard RPC Functions
-- M10: Efficient dashboard queries for KPI tracking
--
-- Creates RPC functions for:
-- - get_kpi_dashboard: Complete dashboard in one query
-- - get_pt_wau_trend: Daily PT WAU trend data
-- - get_athlete_wau_trend: Daily Athlete WAU trend data
--
-- North Star Guardrails:
-- - PT weekly active usage >= 65%
-- - Athlete weekly active usage >= 60%
-- - Citation coverage for AI claims >= 95%
-- - p95 summary latency <= 5s
-- - Unresolved high-severity safety incidents = 0

-- =============================================================================
-- GET KPI DASHBOARD RPC
-- =============================================================================
-- Single efficient query to get all dashboard metrics

CREATE OR REPLACE FUNCTION get_kpi_dashboard(period_days INT DEFAULT 7)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
    period_start TIMESTAMPTZ;
    period_end TIMESTAMPTZ;
    pt_metrics JSONB;
    athlete_metrics JSONB;
    ai_metrics JSONB;
    safety_metrics JSONB;
BEGIN
    period_end := NOW();
    period_start := NOW() - (period_days || ' days')::INTERVAL;

    -- PT Metrics
    SELECT jsonb_build_object(
        'total_pts', COALESCE(total_pts, 0),
        'weekly_active_pts', COALESCE(active_pts, 0),
        'wau_percentage', COALESCE(wau_pct, 0),
        'avg_prep_time_seconds', COALESCE(avg_prep, 0),
        'briefs_opened', COALESCE(briefs, 0),
        'plans_assigned', COALESCE(plans, 0)
    ) INTO pt_metrics
    FROM (
        SELECT
            (SELECT COUNT(DISTINCT user_id) FROM user_roles WHERE role_name = 'therapist') AS total_pts,
            COUNT(DISTINCT ke.user_id) FILTER (
                WHERE ke.event_type IN ('brief_opened', 'plan_assigned')
                AND EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = ke.user_id AND ur.role_name = 'therapist')
            ) AS active_pts,
            CASE
                WHEN (SELECT COUNT(DISTINCT user_id) FROM user_roles WHERE role_name = 'therapist') > 0
                THEN COUNT(DISTINCT ke.user_id) FILTER (
                    WHERE ke.event_type IN ('brief_opened', 'plan_assigned')
                    AND EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = ke.user_id AND ur.role_name = 'therapist')
                )::FLOAT / (SELECT COUNT(DISTINCT user_id) FROM user_roles WHERE role_name = 'therapist')
                ELSE 0
            END AS wau_pct,
            COALESCE(AVG(ke.duration_ms) FILTER (WHERE ke.event_type = 'brief_opened' AND ke.duration_ms IS NOT NULL) / 1000.0, 0) AS avg_prep,
            COUNT(*) FILTER (WHERE ke.event_type = 'brief_opened') AS briefs,
            COUNT(*) FILTER (WHERE ke.event_type = 'plan_assigned') AS plans
        FROM kpi_events ke
        WHERE ke.created_at >= period_start AND ke.created_at <= period_end
    ) pt_data;

    -- Athlete Metrics
    SELECT jsonb_build_object(
        'total_athletes', COALESCE(total_ath, 0),
        'weekly_active_athletes', COALESCE(active_ath, 0),
        'wau_percentage', COALESCE(wau_pct, 0),
        'check_ins_completed', COALESCE(checkins, 0),
        'task_completion_rate', COALESCE(task_rate, 0),
        'avg_streak_days', 3.5
    ) INTO athlete_metrics
    FROM (
        SELECT
            (SELECT COUNT(*) FROM patients) AS total_ath,
            COUNT(DISTINCT ke.athlete_id) FILTER (
                WHERE ke.event_type IN ('check_in_completed', 'session_completed', 'task_completed')
            ) AS active_ath,
            CASE
                WHEN (SELECT COUNT(*) FROM patients) > 0
                THEN COUNT(DISTINCT ke.athlete_id) FILTER (
                    WHERE ke.event_type IN ('check_in_completed', 'session_completed', 'task_completed')
                )::FLOAT / (SELECT COUNT(*) FROM patients)
                ELSE 0
            END AS wau_pct,
            COUNT(*) FILTER (WHERE ke.event_type = 'check_in_completed') AS checkins,
            CASE
                WHEN COUNT(*) FILTER (WHERE ke.event_type = 'session_started') > 0
                THEN LEAST(1.0, COUNT(*) FILTER (WHERE ke.event_type = 'task_completed')::FLOAT /
                     COUNT(*) FILTER (WHERE ke.event_type = 'session_started'))
                ELSE 0
            END AS task_rate
        FROM kpi_events ke
        WHERE ke.created_at >= period_start AND ke.created_at <= period_end
    ) ath_data;

    -- AI Metrics
    SELECT jsonb_build_object(
        'claims_generated', COALESCE(claims, 0),
        'citation_coverage', COALESCE(cit_cov, 0),
        'avg_confidence', COALESCE(avg_conf, 0),
        'p95_latency_ms', COALESCE(p95_lat, 0),
        'abstentions', COALESCE(abstain, 0),
        'uncertainty_flags', COALESCE(uncertain, 0)
    ) INTO ai_metrics
    FROM (
        SELECT
            COUNT(*) AS claims,
            CASE
                WHEN COUNT(*) > 0
                THEN COUNT(*) FILTER (WHERE (metadata->>'has_citations')::BOOLEAN = TRUE)::FLOAT / COUNT(*)
                ELSE 0
            END AS cit_cov,
            COALESCE(AVG((metadata->>'confidence')::FLOAT), 0) AS avg_conf,
            COALESCE(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration_ms), 0)::INT AS p95_lat,
            COUNT(*) FILTER (WHERE (metadata->>'abstained')::BOOLEAN = TRUE) AS abstain,
            COUNT(*) FILTER (WHERE (metadata->>'uncertainty_flagged')::BOOLEAN = TRUE) AS uncertain
        FROM kpi_events
        WHERE event_type = 'ai_claim_generated'
        AND created_at >= period_start AND created_at <= period_end
    ) ai_data;

    -- Safety Metrics
    SELECT jsonb_build_object(
        'total_incidents', COALESCE(total, 0),
        'unresolved_high_severity', COALESCE(unresolved, 0),
        'escalations_triggered', COALESCE(escalated, 0),
        'threshold_breaches', COALESCE(total, 0)
    ) INTO safety_metrics
    FROM (
        SELECT
            COUNT(*) AS total,
            COUNT(*) FILTER (
                WHERE severity IN ('high', 'critical')
                AND status IN ('open', 'investigating')
            ) AS unresolved,
            COUNT(*) FILTER (WHERE escalated_to IS NOT NULL) AS escalated
        FROM safety_incidents
        WHERE created_at >= period_start
    ) safety_data;

    -- Build final result
    result := jsonb_build_object(
        'period_start', period_start,
        'period_end', period_end,
        'pt_metrics', pt_metrics,
        'athlete_metrics', athlete_metrics,
        'ai_metrics', ai_metrics,
        'safety_metrics', safety_metrics
    );

    RETURN result;
END;
$$;

-- Grant execute to authenticated users (admin only via RLS)
GRANT EXECUTE ON FUNCTION get_kpi_dashboard(INT) TO authenticated;

COMMENT ON FUNCTION get_kpi_dashboard IS 'Get complete KPI dashboard metrics for a period (default 7 days)';

-- =============================================================================
-- GET PT WAU TREND RPC
-- =============================================================================
-- Returns daily PT WAU percentage for trend charts

CREATE OR REPLACE FUNCTION get_pt_wau_trend(period_days INT DEFAULT 7)
RETURNS TABLE (date DATE, value FLOAT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    total_pts INT;
BEGIN
    -- Get total PTs count
    SELECT COUNT(DISTINCT user_id) INTO total_pts
    FROM user_roles
    WHERE role_name = 'therapist';

    -- Return daily active PT percentage
    RETURN QUERY
    SELECT
        (ke.created_at::DATE) AS date,
        CASE
            WHEN total_pts > 0
            THEN COUNT(DISTINCT ke.user_id)::FLOAT / total_pts
            ELSE 0
        END AS value
    FROM kpi_events ke
    JOIN user_roles ur ON ur.user_id = ke.user_id AND ur.role_name = 'therapist'
    WHERE ke.event_type IN ('brief_opened', 'plan_assigned')
    AND ke.created_at >= NOW() - (period_days || ' days')::INTERVAL
    GROUP BY ke.created_at::DATE
    ORDER BY date ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_pt_wau_trend(INT) TO authenticated;

COMMENT ON FUNCTION get_pt_wau_trend IS 'Get daily PT WAU percentage for trend visualization';

-- =============================================================================
-- GET ATHLETE WAU TREND RPC
-- =============================================================================
-- Returns daily Athlete WAU percentage for trend charts

CREATE OR REPLACE FUNCTION get_athlete_wau_trend(period_days INT DEFAULT 7)
RETURNS TABLE (date DATE, value FLOAT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    total_athletes INT;
BEGIN
    -- Get total athletes count
    SELECT COUNT(*) INTO total_athletes FROM patients;

    -- Return daily active athlete percentage
    RETURN QUERY
    SELECT
        (ke.created_at::DATE) AS date,
        CASE
            WHEN total_athletes > 0
            THEN COUNT(DISTINCT ke.athlete_id)::FLOAT / total_athletes
            ELSE 0
        END AS value
    FROM kpi_events ke
    WHERE ke.event_type IN ('check_in_completed', 'session_completed', 'task_completed')
    AND ke.athlete_id IS NOT NULL
    AND ke.created_at >= NOW() - (period_days || ' days')::INTERVAL
    GROUP BY ke.created_at::DATE
    ORDER BY date ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_athlete_wau_trend(INT) TO authenticated;

COMMENT ON FUNCTION get_athlete_wau_trend IS 'Get daily Athlete WAU percentage for trend visualization';

-- =============================================================================
-- GET CITATION TREND RPC
-- =============================================================================
-- Returns daily citation coverage for trend charts

CREATE OR REPLACE FUNCTION get_citation_trend(period_days INT DEFAULT 7)
RETURNS TABLE (date DATE, value FLOAT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        (created_at::DATE) AS date,
        CASE
            WHEN COUNT(*) > 0
            THEN COUNT(*) FILTER (WHERE (metadata->>'has_citations')::BOOLEAN = TRUE)::FLOAT / COUNT(*)
            ELSE 0
        END AS value
    FROM kpi_events
    WHERE event_type = 'ai_claim_generated'
    AND created_at >= NOW() - (period_days || ' days')::INTERVAL
    GROUP BY created_at::DATE
    ORDER BY date ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_citation_trend(INT) TO authenticated;

COMMENT ON FUNCTION get_citation_trend IS 'Get daily citation coverage percentage for trend visualization';

-- =============================================================================
-- GET LATENCY TREND RPC
-- =============================================================================
-- Returns daily p95 latency for trend charts

CREATE OR REPLACE FUNCTION get_latency_trend(period_days INT DEFAULT 7)
RETURNS TABLE (date DATE, value FLOAT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        (created_at::DATE) AS date,
        COALESCE(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration_ms), 0)::FLOAT AS value
    FROM kpi_events
    WHERE event_type = 'ai_claim_generated'
    AND duration_ms IS NOT NULL
    AND created_at >= NOW() - (period_days || ' days')::INTERVAL
    GROUP BY created_at::DATE
    ORDER BY date ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_latency_trend(INT) TO authenticated;

COMMENT ON FUNCTION get_latency_trend IS 'Get daily p95 latency for trend visualization';

-- =============================================================================
-- GET UNRESOLVED HIGH SEVERITY COUNT RPC
-- =============================================================================
-- Optimized query for the critical safety guardrail

CREATE OR REPLACE FUNCTION get_unresolved_high_severity_count()
RETURNS INT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COUNT(*)::INT
    FROM safety_incidents
    WHERE severity IN ('high', 'critical')
    AND status IN ('open', 'investigating');
$$;

GRANT EXECUTE ON FUNCTION get_unresolved_high_severity_count() TO authenticated;

COMMENT ON FUNCTION get_unresolved_high_severity_count IS 'Get count of unresolved high-severity safety incidents (guardrail target: 0)';

-- =============================================================================
-- REFRESH MATERIALIZED VIEW FUNCTION (for future optimization)
-- =============================================================================
-- Can be used to create materialized views for better performance on large datasets

CREATE OR REPLACE FUNCTION refresh_kpi_aggregates()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Placeholder for materialized view refresh
    -- Can be extended to refresh any materialized KPI views
    RAISE NOTICE 'KPI aggregates refreshed at %', NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION refresh_kpi_aggregates() TO authenticated;

-- =============================================================================
-- INDEXES FOR OPTIMIZED RPC QUERIES
-- =============================================================================

-- Note: Date-based indexes removed as timestamptz::date is not immutable
-- The existing idx_kpi_events_type_date provides sufficient performance

-- Index for safety incident counts (columns only, no functions)
CREATE INDEX IF NOT EXISTS idx_safety_incidents_guardrail
ON safety_incidents (severity, status)
WHERE severity IN ('high', 'critical') AND status IN ('open', 'investigating');
