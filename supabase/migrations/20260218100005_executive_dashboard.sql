-- Migration: Executive Dashboard RPC Functions
-- ACP-974: Executive Dashboard - Real-time KPIs for board-ready reporting
--
-- Creates RPC functions for:
-- - get_executive_dashboard(): Full executive dashboard with all KPI sections
-- - get_daily_digest(): Condensed daily digest format suitable for email delivery
--
-- Aggregates from: kpi_events, user_subscriptions, patients, sessions,
--                  app_feedback, safety_incidents, scheduled_sessions

-- =============================================================================
-- GET EXECUTIVE DASHBOARD RPC
-- =============================================================================
-- Returns a comprehensive JSONB payload with all executive KPI sections.
-- Uses CTEs for single-pass efficiency across all metric categories.

CREATE OR REPLACE FUNCTION get_executive_dashboard()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
    now_ts TIMESTAMPTZ := NOW();
    today_start TIMESTAMPTZ := date_trunc('day', NOW());
    week_start TIMESTAMPTZ := date_trunc('week', NOW());
    month_start TIMESTAMPTZ := date_trunc('month', NOW());
    prev_week_start TIMESTAMPTZ := date_trunc('week', NOW()) - INTERVAL '7 days';
    prev_week_end TIMESTAMPTZ := date_trunc('week', NOW());
BEGIN
    WITH
    -- =========================================================================
    -- OVERVIEW: Total users, DAU, WAU, MAU, DAU/MAU ratio
    -- =========================================================================
    user_counts AS (
        SELECT
            (SELECT COUNT(*) FROM patients) AS total_users,
            (SELECT COUNT(DISTINCT user_id) FROM user_roles) AS total_accounts
    ),
    dau AS (
        SELECT COUNT(DISTINCT COALESCE(ke.user_id, ke.athlete_id)) AS active_today
        FROM kpi_events ke
        WHERE ke.created_at >= today_start
    ),
    wau AS (
        SELECT COUNT(DISTINCT COALESCE(ke.user_id, ke.athlete_id)) AS active_this_week
        FROM kpi_events ke
        WHERE ke.created_at >= week_start
    ),
    mau AS (
        SELECT COUNT(DISTINCT COALESCE(ke.user_id, ke.athlete_id)) AS active_this_month
        FROM kpi_events ke
        WHERE ke.created_at >= month_start
    ),
    overview AS (
        SELECT jsonb_build_object(
            'total_users', uc.total_users,
            'dau', d.active_today,
            'wau', w.active_this_week,
            'mau', m.active_this_month,
            'dau_mau_ratio', CASE
                WHEN m.active_this_month > 0
                THEN ROUND((d.active_today::NUMERIC / m.active_this_month), 4)
                ELSE 0
            END
        ) AS data
        FROM user_counts uc, dau d, wau w, mau m
    ),

    -- =========================================================================
    -- REVENUE: MRR estimate, subscriber count, trial count
    -- =========================================================================
    revenue AS (
        SELECT jsonb_build_object(
            'subscriber_count', COALESCE(COUNT(*) FILTER (
                WHERE status = 'active' AND is_trial = FALSE
            ), 0),
            'trial_count', COALESCE(COUNT(*) FILTER (
                WHERE status = 'active' AND is_trial = TRUE
            ), 0),
            'mrr_estimate', COALESCE(COUNT(*) FILTER (
                WHERE status = 'active' AND is_trial = FALSE
            ), 0) * 29.99,  -- avg monthly subscription price
            'total_active', COALESCE(COUNT(*) FILTER (
                WHERE status = 'active'
            ), 0),
            'churn_count', COALESCE(COUNT(*) FILTER (
                WHERE status IN ('expired', 'cancelled')
                AND updated_at >= month_start
            ), 0)
        ) AS data
        FROM user_subscriptions
    ),

    -- =========================================================================
    -- ENGAGEMENT: avg sessions per user per week, avg streak length
    -- =========================================================================
    weekly_sessions AS (
        SELECT
            COALESCE(ke.user_id, ke.athlete_id) AS uid,
            COUNT(*) AS session_count
        FROM kpi_events ke
        WHERE ke.event_type IN ('session_started', 'session_completed')
        AND ke.created_at >= week_start
        AND COALESCE(ke.user_id, ke.athlete_id) IS NOT NULL
        GROUP BY COALESCE(ke.user_id, ke.athlete_id)
    ),
    engagement AS (
        SELECT jsonb_build_object(
            'avg_sessions_per_user_per_week', COALESCE(
                ROUND(AVG(ws.session_count)::NUMERIC, 2), 0
            ),
            'total_sessions_this_week', COALESCE(SUM(ws.session_count), 0),
            'active_users_with_sessions', COUNT(ws.uid),
            'avg_streak_length', COALESCE(
                (SELECT ROUND(AVG(streak)::NUMERIC, 1) FROM (
                    SELECT
                        COALESCE(ke2.user_id, ke2.athlete_id) AS uid,
                        COUNT(DISTINCT ke2.created_at::DATE) AS streak
                    FROM kpi_events ke2
                    WHERE ke2.event_type IN ('session_completed', 'check_in_completed', 'task_completed')
                    AND ke2.created_at >= now_ts - INTERVAL '30 days'
                    AND COALESCE(ke2.user_id, ke2.athlete_id) IS NOT NULL
                    GROUP BY COALESCE(ke2.user_id, ke2.athlete_id)
                ) streaks),
            0)
        ) AS data
        FROM weekly_sessions ws
    ),

    -- =========================================================================
    -- SATISFACTION: avg rating, feedback count from app_feedback
    -- =========================================================================
    satisfaction AS (
        SELECT jsonb_build_object(
            'avg_rating', COALESCE(ROUND(AVG(rating)::NUMERIC, 2), 0),
            'feedback_count', COUNT(*),
            'feedback_last_30d', COUNT(*) FILTER (
                WHERE created_at >= now_ts - INTERVAL '30 days'
            ),
            'avg_rating_last_30d', COALESCE(
                ROUND(AVG(rating) FILTER (
                    WHERE created_at >= now_ts - INTERVAL '30 days'
                )::NUMERIC, 2), 0
            ),
            'rating_distribution', jsonb_build_object(
                '1_star', COUNT(*) FILTER (WHERE rating = 1),
                '2_star', COUNT(*) FILTER (WHERE rating = 2),
                '3_star', COUNT(*) FILTER (WHERE rating = 3),
                '4_star', COUNT(*) FILTER (WHERE rating = 4),
                '5_star', COUNT(*) FILTER (WHERE rating = 5)
            )
        ) AS data
        FROM app_feedback
    ),

    -- =========================================================================
    -- SAFETY: open incidents grouped by severity
    -- =========================================================================
    safety AS (
        SELECT jsonb_build_object(
            'open_incidents', jsonb_build_object(
                'critical', COALESCE(COUNT(*) FILTER (
                    WHERE severity = 'critical' AND status IN ('open', 'investigating')
                ), 0),
                'high', COALESCE(COUNT(*) FILTER (
                    WHERE severity = 'high' AND status IN ('open', 'investigating')
                ), 0),
                'medium', COALESCE(COUNT(*) FILTER (
                    WHERE severity = 'medium' AND status IN ('open', 'investigating')
                ), 0),
                'low', COALESCE(COUNT(*) FILTER (
                    WHERE severity = 'low' AND status IN ('open', 'investigating')
                ), 0)
            ),
            'total_open', COALESCE(COUNT(*) FILTER (
                WHERE status IN ('open', 'investigating')
            ), 0),
            'resolved_this_week', COALESCE(COUNT(*) FILTER (
                WHERE status = 'resolved' AND resolved_at >= week_start
            ), 0),
            'total_this_month', COALESCE(COUNT(*) FILTER (
                WHERE created_at >= month_start
            ), 0)
        ) AS data
        FROM safety_incidents
    ),

    -- =========================================================================
    -- TRENDS: Week-over-week changes for DAU, sessions, new signups
    -- =========================================================================
    this_week_metrics AS (
        SELECT
            COUNT(DISTINCT COALESCE(ke.user_id, ke.athlete_id)) AS dau_avg,
            COUNT(*) FILTER (WHERE ke.event_type IN ('session_started', 'session_completed')) AS sessions,
            (SELECT COUNT(*) FROM patients WHERE created_at >= week_start) AS new_signups
        FROM kpi_events ke
        WHERE ke.created_at >= week_start
    ),
    prev_week_metrics AS (
        SELECT
            COUNT(DISTINCT COALESCE(ke.user_id, ke.athlete_id)) AS dau_avg,
            COUNT(*) FILTER (WHERE ke.event_type IN ('session_started', 'session_completed')) AS sessions,
            (SELECT COUNT(*) FROM patients
             WHERE created_at >= prev_week_start AND created_at < prev_week_end) AS new_signups
        FROM kpi_events ke
        WHERE ke.created_at >= prev_week_start AND ke.created_at < prev_week_end
    ),
    trends AS (
        SELECT jsonb_build_object(
            'dau', jsonb_build_object(
                'current', tw.dau_avg,
                'previous', pw.dau_avg,
                'change_pct', CASE
                    WHEN pw.dau_avg > 0
                    THEN ROUND(((tw.dau_avg - pw.dau_avg)::NUMERIC / pw.dau_avg) * 100, 1)
                    ELSE 0
                END
            ),
            'sessions', jsonb_build_object(
                'current', tw.sessions,
                'previous', pw.sessions,
                'change_pct', CASE
                    WHEN pw.sessions > 0
                    THEN ROUND(((tw.sessions - pw.sessions)::NUMERIC / pw.sessions) * 100, 1)
                    ELSE 0
                END
            ),
            'new_signups', jsonb_build_object(
                'current', tw.new_signups,
                'previous', pw.new_signups,
                'change_pct', CASE
                    WHEN pw.new_signups > 0
                    THEN ROUND(((tw.new_signups - pw.new_signups)::NUMERIC / pw.new_signups) * 100, 1)
                    ELSE 0
                END
            )
        ) AS data
        FROM this_week_metrics tw, prev_week_metrics pw
    )

    -- =========================================================================
    -- BUILD FINAL RESULT
    -- =========================================================================
    SELECT jsonb_build_object(
        'generated_at', now_ts,
        'overview', o.data,
        'revenue', r.data,
        'engagement', e.data,
        'satisfaction', s.data,
        'safety', sf.data,
        'trends', t.data
    ) INTO result
    FROM overview o, revenue r, engagement e, satisfaction s, safety sf, trends t;

    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_executive_dashboard() TO authenticated;

COMMENT ON FUNCTION get_executive_dashboard IS
    'ACP-974: Executive Dashboard - returns full KPI dashboard with overview, revenue, engagement, satisfaction, safety, and trends';


-- =============================================================================
-- GET DAILY DIGEST RPC
-- =============================================================================
-- Returns a condensed JSONB summary suitable for daily/weekly email digests.
-- Focuses on headline numbers and notable changes.

CREATE OR REPLACE FUNCTION get_daily_digest()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
    now_ts TIMESTAMPTZ := NOW();
    today_start TIMESTAMPTZ := date_trunc('day', NOW());
    yesterday_start TIMESTAMPTZ := date_trunc('day', NOW()) - INTERVAL '1 day';
    week_start TIMESTAMPTZ := date_trunc('week', NOW());
BEGIN
    WITH
    -- Headline numbers
    headline AS (
        SELECT
            (SELECT COUNT(*) FROM patients) AS total_users,
            (SELECT COUNT(DISTINCT COALESCE(user_id, athlete_id))
             FROM kpi_events WHERE created_at >= today_start) AS dau_today,
            (SELECT COUNT(DISTINCT COALESCE(user_id, athlete_id))
             FROM kpi_events WHERE created_at >= yesterday_start
             AND created_at < today_start) AS dau_yesterday,
            (SELECT COUNT(*) FROM user_subscriptions
             WHERE status = 'active' AND is_trial = FALSE) AS paying_subscribers,
            (SELECT COUNT(*) FROM user_subscriptions
             WHERE status = 'active' AND is_trial = TRUE) AS active_trials,
            (SELECT COUNT(*) FROM safety_incidents
             WHERE status IN ('open', 'investigating')
             AND severity IN ('high', 'critical')) AS critical_open_incidents
    ),
    -- Activity snapshot (bounded to last 2 days for efficiency)
    activity AS (
        SELECT
            COUNT(*) FILTER (WHERE event_type = 'session_completed'
                AND created_at >= today_start) AS sessions_today,
            COUNT(*) FILTER (WHERE event_type = 'check_in_completed'
                AND created_at >= today_start) AS check_ins_today,
            COUNT(*) FILTER (WHERE event_type = 'brief_opened'
                AND created_at >= today_start) AS briefs_today,
            COUNT(*) FILTER (WHERE event_type = 'session_completed'
                AND created_at >= yesterday_start
                AND created_at < today_start) AS sessions_yesterday
        FROM kpi_events
        WHERE created_at >= yesterday_start
    ),
    -- New feedback
    recent_feedback AS (
        SELECT
            COUNT(*) AS feedback_count,
            COALESCE(ROUND(AVG(rating)::NUMERIC, 1), 0) AS avg_rating
        FROM app_feedback
        WHERE created_at >= today_start
    ),
    -- New signups
    signups AS (
        SELECT
            (SELECT COUNT(*) FROM patients WHERE created_at >= today_start) AS today,
            (SELECT COUNT(*) FROM patients
             WHERE created_at >= yesterday_start AND created_at < today_start) AS yesterday
    ),
    -- Anomalies / alerts
    alerts AS (
        SELECT COALESCE(jsonb_agg(alert), '[]'::JSONB) AS items FROM (
            -- Alert: critical safety incidents
            SELECT jsonb_build_object(
                'type', 'safety',
                'severity', 'critical',
                'message', COUNT(*) || ' critical/high safety incident(s) open'
            ) AS alert
            FROM safety_incidents
            WHERE status IN ('open', 'investigating')
            AND severity IN ('high', 'critical')
            HAVING COUNT(*) > 0

            UNION ALL

            -- Alert: DAU dropped more than 30% from yesterday
            SELECT jsonb_build_object(
                'type', 'engagement',
                'severity', 'warning',
                'message', 'DAU dropped >30% compared to yesterday'
            ) AS alert
            WHERE (
                SELECT COUNT(DISTINCT COALESCE(user_id, athlete_id))
                FROM kpi_events WHERE created_at >= yesterday_start
                AND created_at < today_start
            ) > 0
            AND (
                SELECT COUNT(DISTINCT COALESCE(user_id, athlete_id))
                FROM kpi_events WHERE created_at >= today_start
            )::FLOAT / NULLIF((
                SELECT COUNT(DISTINCT COALESCE(user_id, athlete_id))
                FROM kpi_events WHERE created_at >= yesterday_start
                AND created_at < today_start
            ), 0) < 0.7

            UNION ALL

            -- Alert: low feedback ratings today
            SELECT jsonb_build_object(
                'type', 'satisfaction',
                'severity', 'warning',
                'message', 'Average feedback rating today is below 3.0'
            ) AS alert
            WHERE (
                SELECT AVG(rating) FROM app_feedback
                WHERE created_at >= today_start
            ) < 3.0
            AND (
                SELECT COUNT(*) FROM app_feedback
                WHERE created_at >= today_start
            ) >= 2
        ) anomalies
    )

    SELECT jsonb_build_object(
        'digest_date', today_start::DATE,
        'generated_at', now_ts,
        'headline', jsonb_build_object(
            'total_users', h.total_users,
            'dau_today', h.dau_today,
            'dau_yesterday', h.dau_yesterday,
            'dau_change_pct', CASE
                WHEN h.dau_yesterday > 0
                THEN ROUND(((h.dau_today - h.dau_yesterday)::NUMERIC / h.dau_yesterday) * 100, 1)
                ELSE 0
            END,
            'paying_subscribers', h.paying_subscribers,
            'active_trials', h.active_trials,
            'mrr_estimate', h.paying_subscribers * 29.99,
            'critical_open_incidents', h.critical_open_incidents
        ),
        'activity', jsonb_build_object(
            'sessions_today', a.sessions_today,
            'sessions_yesterday', a.sessions_yesterday,
            'check_ins_today', a.check_ins_today,
            'briefs_opened_today', a.briefs_today
        ),
        'feedback', jsonb_build_object(
            'new_today', rf.feedback_count,
            'avg_rating_today', rf.avg_rating
        ),
        'signups', jsonb_build_object(
            'today', sg.today,
            'yesterday', sg.yesterday
        ),
        'alerts', al.items
    ) INTO result
    FROM headline h, activity a, recent_feedback rf, signups sg, alerts al;

    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_daily_digest() TO authenticated;

COMMENT ON FUNCTION get_daily_digest IS
    'ACP-974: Daily Digest - returns condensed KPI summary for daily/weekly email digests with anomaly alerts';


-- =============================================================================
-- INDEXES FOR EXECUTIVE DASHBOARD PERFORMANCE
-- =============================================================================

-- Composite index for DAU/WAU/MAU calculations on kpi_events
CREATE INDEX IF NOT EXISTS idx_kpi_events_user_athlete_created
ON kpi_events (created_at, COALESCE(user_id, athlete_id))
WHERE COALESCE(user_id, athlete_id) IS NOT NULL;

-- Index for subscription status lookups
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status_trial
ON user_subscriptions (status, is_trial)
WHERE status = 'active';

-- Index for feedback recency queries
CREATE INDEX IF NOT EXISTS idx_app_feedback_created_at
ON app_feedback (created_at DESC);

-- Index for patient signup date (for new signups trend)
CREATE INDEX IF NOT EXISTS idx_patients_created_at
ON patients (created_at DESC);
