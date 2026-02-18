-- Migration: Product Health Metrics RPC
-- ACP-975: Track product health - feature adoption curves, user satisfaction trends,
-- support ticket volume, app store ratings. Leading indicators for problems.
--
-- Creates RPC function:
-- - get_product_health(period_days): Complete product health dashboard in one query
--
-- Metrics:
-- - DAU/WAU/MAU counts and trends
-- - Feature adoption: sessions, manual_workouts, readiness, streaks, ai_chat
-- - Satisfaction: average app_feedback rating, NPS proxy
-- - Safety: open incident count by severity
-- - Subscription health: trials, conversions, cancellations

-- =============================================================================
-- GET PRODUCT HEALTH RPC
-- =============================================================================

CREATE OR REPLACE FUNCTION get_product_health(period_days INT DEFAULT 30)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
    period_start TIMESTAMPTZ;
    period_end TIMESTAMPTZ;
    prev_period_start TIMESTAMPTZ;
    engagement_metrics JSONB;
    feature_adoption JSONB;
    satisfaction_metrics JSONB;
    safety_metrics JSONB;
    subscription_health JSONB;
    total_active_users INT;
BEGIN
    period_end := NOW();
    period_start := NOW() - (period_days || ' days')::INTERVAL;
    prev_period_start := period_start - (period_days || ' days')::INTERVAL;

    -- =========================================================================
    -- ENGAGEMENT: DAU / WAU / MAU
    -- =========================================================================
    -- DAU = distinct patients with any session/readiness/exercise_log activity today
    -- WAU = distinct patients with activity in last 7 days
    -- MAU = distinct patients with activity in last 30 days
    --
    -- Activity sources:
    --   - sessions: completed prescribed sessions (via scheduled_sessions)
    --   - manual_sessions: ad-hoc workouts
    --   - daily_readiness: readiness check-ins
    --   - kpi_events: session_completed, check_in_completed events

    WITH active_patients AS (
        -- Patients with readiness check-ins in period
        SELECT DISTINCT patient_id, date::TIMESTAMPTZ AS activity_at
        FROM daily_readiness
        WHERE date >= (period_start::DATE)
        UNION ALL
        -- Patients with manual sessions in period
        SELECT DISTINCT patient_id, created_at AS activity_at
        FROM manual_sessions
        WHERE created_at >= period_start
        UNION ALL
        -- Patients tracked via kpi_events (session_completed, check_in_completed)
        SELECT DISTINCT athlete_id AS patient_id, created_at AS activity_at
        FROM kpi_events
        WHERE athlete_id IS NOT NULL
          AND event_type IN ('session_completed', 'check_in_completed', 'task_completed')
          AND created_at >= period_start
    ),
    current_counts AS (
        SELECT
            COUNT(DISTINCT patient_id) FILTER (
                WHERE activity_at::DATE = CURRENT_DATE
            ) AS dau,
            COUNT(DISTINCT patient_id) FILTER (
                WHERE activity_at >= NOW() - INTERVAL '7 days'
            ) AS wau,
            COUNT(DISTINCT patient_id) FILTER (
                WHERE activity_at >= NOW() - INTERVAL '30 days'
            ) AS mau,
            COUNT(DISTINCT patient_id) AS period_active
        FROM active_patients
    ),
    -- Previous period for trend comparison
    prev_active_patients AS (
        SELECT DISTINCT patient_id, date::TIMESTAMPTZ AS activity_at
        FROM daily_readiness
        WHERE date >= (prev_period_start::DATE) AND date < (period_start::DATE)
        UNION ALL
        SELECT DISTINCT patient_id, created_at AS activity_at
        FROM manual_sessions
        WHERE created_at >= prev_period_start AND created_at < period_start
        UNION ALL
        SELECT DISTINCT athlete_id AS patient_id, created_at AS activity_at
        FROM kpi_events
        WHERE athlete_id IS NOT NULL
          AND event_type IN ('session_completed', 'check_in_completed', 'task_completed')
          AND created_at >= prev_period_start AND created_at < period_start
    ),
    prev_counts AS (
        SELECT
            COUNT(DISTINCT patient_id) FILTER (
                WHERE activity_at >= prev_period_start + (period_days - 1 || ' days')::INTERVAL
            ) AS prev_dau,
            COUNT(DISTINCT patient_id) FILTER (
                WHERE activity_at >= period_start - INTERVAL '7 days'
            ) AS prev_wau,
            COUNT(DISTINCT patient_id) AS prev_mau
        FROM prev_active_patients
    ),
    total_patients AS (
        SELECT COUNT(*) AS total FROM patients
    )
    SELECT jsonb_build_object(
        'dau', COALESCE(cc.dau, 0),
        'wau', COALESCE(cc.wau, 0),
        'mau', COALESCE(cc.mau, 0),
        'total_patients', COALESCE(tp.total, 0),
        'dau_trend', CASE
            WHEN COALESCE(pc.prev_dau, 0) > 0
            THEN ROUND(((cc.dau - pc.prev_dau)::NUMERIC / pc.prev_dau) * 100, 1)
            ELSE NULL
        END,
        'wau_trend', CASE
            WHEN COALESCE(pc.prev_wau, 0) > 0
            THEN ROUND(((cc.wau - pc.prev_wau)::NUMERIC / pc.prev_wau) * 100, 1)
            ELSE NULL
        END,
        'mau_trend', CASE
            WHEN COALESCE(pc.prev_mau, 0) > 0
            THEN ROUND(((cc.mau - pc.prev_mau)::NUMERIC / pc.prev_mau) * 100, 1)
            ELSE NULL
        END,
        'dau_wau_ratio', CASE
            WHEN COALESCE(cc.wau, 0) > 0
            THEN ROUND(cc.dau::NUMERIC / cc.wau, 3)
            ELSE NULL
        END,
        'wau_mau_ratio', CASE
            WHEN COALESCE(cc.mau, 0) > 0
            THEN ROUND(cc.wau::NUMERIC / cc.mau, 3)
            ELSE NULL
        END
    ) INTO engagement_metrics
    FROM current_counts cc
    CROSS JOIN prev_counts pc
    CROSS JOIN total_patients tp;

    -- Store total_active_users for feature adoption denominator
    SELECT COALESCE((engagement_metrics->>'mau')::INT, 0) INTO total_active_users;

    -- =========================================================================
    -- FEATURE ADOPTION
    -- =========================================================================
    -- Percentage of active users (MAU) who used each major feature in the period

    WITH feature_users AS (
        -- Sessions (prescribed): patients who completed a session via kpi_events
        SELECT 'sessions' AS feature,
               COUNT(DISTINCT athlete_id) AS users
        FROM kpi_events
        WHERE event_type = 'session_completed'
          AND athlete_id IS NOT NULL
          AND created_at >= period_start

        UNION ALL

        -- Manual workouts
        SELECT 'manual_workouts' AS feature,
               COUNT(DISTINCT patient_id) AS users
        FROM manual_sessions
        WHERE created_at >= period_start

        UNION ALL

        -- Readiness check-ins
        SELECT 'readiness' AS feature,
               COUNT(DISTINCT patient_id) AS users
        FROM daily_readiness
        WHERE date >= (period_start::DATE)

        UNION ALL

        -- Streaks: patients with an active streak (last_activity_date in period)
        SELECT 'streaks' AS feature,
               COUNT(DISTINCT patient_id) AS users
        FROM streak_records
        WHERE last_activity_date >= (period_start::DATE)
          AND current_streak > 0

        UNION ALL

        -- AI Chat: patients who started an AI chat session
        SELECT 'ai_chat' AS feature,
               COUNT(DISTINCT athlete_id) AS users
        FROM ai_chat_sessions
        WHERE started_at >= period_start
    )
    SELECT jsonb_object_agg(
        feature,
        jsonb_build_object(
            'users', users,
            'adoption_pct', CASE
                WHEN total_active_users > 0
                THEN ROUND((users::NUMERIC / total_active_users) * 100, 1)
                ELSE 0
            END
        )
    ) INTO feature_adoption
    FROM feature_users;

    -- =========================================================================
    -- SATISFACTION
    -- =========================================================================
    -- Average app_feedback rating, NPS proxy (% 4-5 stars - % 1-2 stars)

    SELECT jsonb_build_object(
        'avg_rating', COALESCE(ROUND(AVG(rating)::NUMERIC, 2), 0),
        'total_reviews', COUNT(*),
        'rating_distribution', jsonb_build_object(
            '1_star', COUNT(*) FILTER (WHERE rating = 1),
            '2_star', COUNT(*) FILTER (WHERE rating = 2),
            '3_star', COUNT(*) FILTER (WHERE rating = 3),
            '4_star', COUNT(*) FILTER (WHERE rating = 4),
            '5_star', COUNT(*) FILTER (WHERE rating = 5)
        ),
        'nps_proxy', CASE
            WHEN COUNT(*) > 0
            THEN ROUND(
                (
                    COUNT(*) FILTER (WHERE rating >= 4)::NUMERIC / COUNT(*) * 100
                ) - (
                    COUNT(*) FILTER (WHERE rating <= 2)::NUMERIC / COUNT(*) * 100
                ), 1
            )
            ELSE NULL
        END,
        'recent_low_ratings', (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'rating', sub.rating,
                'feedback', sub.feedback,
                'timestamp', sub.timestamp,
                'app_version', sub.app_version
            ) ORDER BY sub.timestamp DESC), '[]'::JSONB)
            FROM (
                SELECT rating, feedback, timestamp, app_version
                FROM app_feedback
                WHERE rating <= 2
                  AND timestamp >= period_start
                ORDER BY timestamp DESC
                LIMIT 10
            ) sub
        )
    ) INTO satisfaction_metrics
    FROM app_feedback
    WHERE timestamp >= period_start;

    -- =========================================================================
    -- SAFETY
    -- =========================================================================
    -- Open incident count by severity

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
        'incidents_in_period', COALESCE(COUNT(*) FILTER (
            WHERE created_at >= period_start
        ), 0),
        'resolved_in_period', COALESCE(COUNT(*) FILTER (
            WHERE status = 'resolved' AND resolved_at >= period_start
        ), 0),
        'avg_resolution_hours', COALESCE(
            ROUND(
                AVG(
                    EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600
                ) FILTER (
                    WHERE status = 'resolved' AND resolved_at >= period_start
                )::NUMERIC, 1
            ), 0
        )
    ) INTO safety_metrics
    FROM safety_incidents;

    -- =========================================================================
    -- SUBSCRIPTION HEALTH
    -- =========================================================================
    -- New trials, conversions, cancellations in period

    SELECT jsonb_build_object(
        'new_trials', COALESCE(COUNT(*) FILTER (
            WHERE is_trial = TRUE AND created_at >= period_start
        ), 0),
        'active_subscriptions', COALESCE(COUNT(*) FILTER (
            WHERE status = 'active'
        ), 0),
        'conversions', COALESCE(COUNT(*) FILTER (
            WHERE is_trial = FALSE
              AND status = 'active'
              AND created_at >= period_start
        ), 0),
        'cancellations', COALESCE(COUNT(*) FILTER (
            WHERE status = 'cancelled'
              AND updated_at >= period_start
        ), 0),
        'expired', COALESCE(COUNT(*) FILTER (
            WHERE status = 'expired'
              AND expires_date >= period_start
              AND expires_date <= period_end
        ), 0),
        'trial_conversion_rate', CASE
            WHEN COUNT(*) FILTER (WHERE is_trial = TRUE AND created_at >= prev_period_start) > 0
            THEN ROUND(
                COUNT(*) FILTER (
                    WHERE is_trial = FALSE AND status = 'active' AND created_at >= period_start
                )::NUMERIC /
                NULLIF(COUNT(*) FILTER (
                    WHERE is_trial = TRUE AND created_at >= prev_period_start
                ), 0) * 100, 1
            )
            ELSE NULL
        END,
        'churn_rate', CASE
            WHEN COUNT(*) FILTER (WHERE status IN ('active', 'cancelled', 'expired')) > 0
            THEN ROUND(
                (
                    COUNT(*) FILTER (WHERE status = 'cancelled' AND updated_at >= period_start) +
                    COUNT(*) FILTER (WHERE status = 'expired' AND expires_date >= period_start AND expires_date <= period_end)
                )::NUMERIC /
                NULLIF(COUNT(*) FILTER (WHERE created_at < period_start AND status IN ('active', 'cancelled', 'expired')), 0) * 100, 1
            )
            ELSE NULL
        END
    ) INTO subscription_health
    FROM user_subscriptions;

    -- =========================================================================
    -- BUILD FINAL RESULT
    -- =========================================================================

    result := jsonb_build_object(
        'period_start', period_start,
        'period_end', period_end,
        'period_days', period_days,
        'engagement', engagement_metrics,
        'feature_adoption', COALESCE(feature_adoption, '{}'::JSONB),
        'satisfaction', satisfaction_metrics,
        'safety', safety_metrics,
        'subscription_health', subscription_health,
        'generated_at', NOW()
    );

    RETURN result;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_product_health(INT) TO authenticated;

COMMENT ON FUNCTION get_product_health IS
'ACP-975: Get product health metrics dashboard.
Returns engagement (DAU/WAU/MAU), feature adoption curves,
satisfaction (app ratings, NPS proxy), safety incident counts,
and subscription health (trials, conversions, churn).
Default period is 30 days.';

-- =============================================================================
-- INDEXES FOR OPTIMIZED PRODUCT HEALTH QUERIES
-- =============================================================================

-- app_feedback: timestamp index for period filtering
CREATE INDEX IF NOT EXISTS idx_app_feedback_timestamp
ON app_feedback (timestamp DESC);

-- app_feedback: rating + timestamp for low-rating queries
CREATE INDEX IF NOT EXISTS idx_app_feedback_rating_timestamp
ON app_feedback (rating, timestamp DESC)
WHERE rating <= 2;

-- daily_readiness: date index for period filtering (if not exists)
CREATE INDEX IF NOT EXISTS idx_daily_readiness_date
ON daily_readiness (date DESC);

-- streak_records: active streaks lookup
CREATE INDEX IF NOT EXISTS idx_streak_records_active
ON streak_records (last_activity_date, current_streak)
WHERE current_streak > 0;

-- ai_chat_sessions: started_at for period filtering
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_started
ON ai_chat_sessions (started_at DESC);

-- user_subscriptions: status + dates for subscription health
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_created
ON user_subscriptions (created_at DESC);

-- manual_sessions: created_at for period-based adoption counting
CREATE INDEX IF NOT EXISTS idx_manual_sessions_created_period
ON manual_sessions (created_at DESC);
