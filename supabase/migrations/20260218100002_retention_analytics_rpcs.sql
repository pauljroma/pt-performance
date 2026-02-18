-- Migration: Retention Cohort Analysis RPC Functions
-- ACP-969: Retention analytics for cohort-based D1/D7/D30/D90 analysis
--
-- Creates RPC functions for:
-- - get_retention_cohorts: D1/D7/D30/D90 retention by signup month cohort
-- - get_retention_drivers: Features used in first 7 days correlated with 30-day retention
-- - get_resurrected_users: Users who returned after 30+ days of inactivity
--
-- Retention definition: user had any session (scheduled_sessions or manual_sessions)
-- completed on day N after their signup date (patients.created_at).

-- =============================================================================
-- GET RETENTION COHORTS RPC
-- =============================================================================
-- Returns D1/D7/D30/D90 retention rates grouped by signup month.
-- Each row represents one monthly cohort with the count of users who signed up
-- that month and the percentage who completed at least one session on each
-- retention milestone day.

CREATE OR REPLACE FUNCTION get_retention_cohorts(months_back INT DEFAULT 6)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
    cutoff_date TIMESTAMPTZ;
BEGIN
    cutoff_date := DATE_TRUNC('month', NOW()) - (months_back || ' months')::INTERVAL;

    SELECT COALESCE(jsonb_agg(cohort_row ORDER BY cohort_month ASC), '[]'::JSONB)
    INTO result
    FROM (
        SELECT
            TO_CHAR(cohort_month, 'YYYY-MM') AS cohort_month,
            cohort_size,
            -- D1: user completed a session within 1 day (0-1 days) of signup
            CASE WHEN cohort_size > 0
                THEN ROUND((d1_retained::NUMERIC / cohort_size) * 100, 1)
                ELSE 0
            END AS d1_retention_pct,
            d1_retained,
            -- D7: user completed a session within 7 days of signup
            CASE WHEN cohort_size > 0
                THEN ROUND((d7_retained::NUMERIC / cohort_size) * 100, 1)
                ELSE 0
            END AS d7_retention_pct,
            d7_retained,
            -- D30: user completed a session within 30 days of signup
            CASE WHEN cohort_size > 0 AND cohort_month <= NOW() - INTERVAL '30 days'
                THEN ROUND((d30_retained::NUMERIC / cohort_size) * 100, 1)
                ELSE NULL
            END AS d30_retention_pct,
            d30_retained,
            -- D90: user completed a session within 90 days of signup
            CASE WHEN cohort_size > 0 AND cohort_month <= NOW() - INTERVAL '90 days'
                THEN ROUND((d90_retained::NUMERIC / cohort_size) * 100, 1)
                ELSE NULL
            END AS d90_retention_pct,
            d90_retained
        FROM (
            SELECT
                DATE_TRUNC('month', p.created_at) AS cohort_month,
                COUNT(DISTINCT p.id) AS cohort_size,

                -- D1 retention: session completed on day 0 or day 1 after signup
                COUNT(DISTINCT p.id) FILTER (
                    WHERE EXISTS (
                        SELECT 1 FROM scheduled_sessions ss
                        WHERE ss.patient_id = p.id
                          AND ss.status = 'completed'
                          AND ss.completed_at IS NOT NULL
                          AND (ss.completed_at::DATE - p.created_at::DATE) BETWEEN 0 AND 1
                    )
                    OR EXISTS (
                        SELECT 1 FROM manual_sessions ms
                        WHERE ms.patient_id = p.id
                          AND ms.completed = true
                          AND ms.completed_at IS NOT NULL
                          AND (ms.completed_at::DATE - p.created_at::DATE) BETWEEN 0 AND 1
                    )
                ) AS d1_retained,

                -- D7 retention: session completed between day 2 and day 7 after signup
                COUNT(DISTINCT p.id) FILTER (
                    WHERE EXISTS (
                        SELECT 1 FROM scheduled_sessions ss
                        WHERE ss.patient_id = p.id
                          AND ss.status = 'completed'
                          AND ss.completed_at IS NOT NULL
                          AND (ss.completed_at::DATE - p.created_at::DATE) BETWEEN 2 AND 7
                    )
                    OR EXISTS (
                        SELECT 1 FROM manual_sessions ms
                        WHERE ms.patient_id = p.id
                          AND ms.completed = true
                          AND ms.completed_at IS NOT NULL
                          AND (ms.completed_at::DATE - p.created_at::DATE) BETWEEN 2 AND 7
                    )
                ) AS d7_retained,

                -- D30 retention: session completed between day 8 and day 30 after signup
                COUNT(DISTINCT p.id) FILTER (
                    WHERE EXISTS (
                        SELECT 1 FROM scheduled_sessions ss
                        WHERE ss.patient_id = p.id
                          AND ss.status = 'completed'
                          AND ss.completed_at IS NOT NULL
                          AND (ss.completed_at::DATE - p.created_at::DATE) BETWEEN 8 AND 30
                    )
                    OR EXISTS (
                        SELECT 1 FROM manual_sessions ms
                        WHERE ms.patient_id = p.id
                          AND ms.completed = true
                          AND ms.completed_at IS NOT NULL
                          AND (ms.completed_at::DATE - p.created_at::DATE) BETWEEN 8 AND 30
                    )
                ) AS d30_retained,

                -- D90 retention: session completed between day 31 and day 90 after signup
                COUNT(DISTINCT p.id) FILTER (
                    WHERE EXISTS (
                        SELECT 1 FROM scheduled_sessions ss
                        WHERE ss.patient_id = p.id
                          AND ss.status = 'completed'
                          AND ss.completed_at IS NOT NULL
                          AND (ss.completed_at::DATE - p.created_at::DATE) BETWEEN 31 AND 90
                    )
                    OR EXISTS (
                        SELECT 1 FROM manual_sessions ms
                        WHERE ms.patient_id = p.id
                          AND ms.completed = true
                          AND ms.completed_at IS NOT NULL
                          AND (ms.completed_at::DATE - p.created_at::DATE) BETWEEN 31 AND 90
                    )
                ) AS d90_retained

            FROM patients p
            WHERE p.created_at >= cutoff_date
            GROUP BY DATE_TRUNC('month', p.created_at)
        ) cohort_data
    ) cohort_row;

    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_retention_cohorts(INT) TO authenticated;

COMMENT ON FUNCTION get_retention_cohorts IS
'ACP-969: Returns D1/D7/D30/D90 retention rates grouped by signup month cohort.
Retention = user completed any session (scheduled or manual) within the milestone window.
D1 = days 0-1, D7 = days 2-7, D30 = days 8-30, D90 = days 31-90.
Cohorts that have not yet reached a milestone return NULL for that metric.';


-- =============================================================================
-- GET RETENTION DRIVERS RPC
-- =============================================================================
-- Identifies features used in the first 7 days that correlate with 30-day retention.
-- Returns a list of "driver" features with usage counts among retained vs churned users.

CREATE OR REPLACE FUNCTION get_retention_drivers()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
BEGIN
    -- Only analyze users who signed up at least 30 days ago so we can measure D30 retention
    WITH eligible_users AS (
        SELECT
            p.id AS patient_id,
            p.created_at AS signup_at
        FROM patients p
        WHERE p.created_at <= NOW() - INTERVAL '30 days'
    ),

    -- Determine which users are "retained" at D30 (had a session on days 8-30)
    user_retention AS (
        SELECT
            eu.patient_id,
            eu.signup_at,
            (
                EXISTS (
                    SELECT 1 FROM scheduled_sessions ss
                    WHERE ss.patient_id = eu.patient_id
                      AND ss.status = 'completed'
                      AND ss.completed_at IS NOT NULL
                      AND (ss.completed_at::DATE - eu.signup_at::DATE) BETWEEN 8 AND 30
                )
                OR EXISTS (
                    SELECT 1 FROM manual_sessions ms
                    WHERE ms.patient_id = eu.patient_id
                      AND ms.completed = true
                      AND ms.completed_at IS NOT NULL
                      AND (ms.completed_at::DATE - eu.signup_at::DATE) BETWEEN 8 AND 30
                )
            ) AS retained_d30
        FROM eligible_users eu
    ),

    -- Count first-week feature usage for each user
    first_week_features AS (
        SELECT
            ur.patient_id,
            ur.retained_d30,

            -- Feature: completed a scheduled session in first 7 days
            EXISTS (
                SELECT 1 FROM scheduled_sessions ss
                WHERE ss.patient_id = ur.patient_id
                  AND ss.status = 'completed'
                  AND ss.completed_at IS NOT NULL
                  AND (ss.completed_at::DATE - ur.signup_at::DATE) BETWEEN 0 AND 7
            ) AS used_scheduled_sessions,

            -- Feature: completed a manual session in first 7 days
            EXISTS (
                SELECT 1 FROM manual_sessions ms
                WHERE ms.patient_id = ur.patient_id
                  AND ms.completed = true
                  AND ms.completed_at IS NOT NULL
                  AND (ms.completed_at::DATE - ur.signup_at::DATE) BETWEEN 0 AND 7
            ) AS used_manual_sessions,

            -- Feature: logged daily readiness in first 7 days
            EXISTS (
                SELECT 1 FROM daily_readiness dr
                WHERE dr.patient_id = ur.patient_id
                  AND (dr.date - ur.signup_at::DATE) BETWEEN 0 AND 7
            ) AS used_daily_readiness,

            -- Feature: had streak activity in first 7 days
            EXISTS (
                SELECT 1 FROM streak_history sh
                WHERE sh.patient_id = ur.patient_id
                  AND (sh.activity_date - ur.signup_at::DATE) BETWEEN 0 AND 7
            ) AS used_streak_tracking,

            -- Feature: had exercise logs in first 7 days
            EXISTS (
                SELECT 1 FROM exercise_logs el
                WHERE el.patient_id = ur.patient_id
                  AND (el.performed_at::DATE - ur.signup_at::DATE) BETWEEN 0 AND 7
            ) AS used_exercise_logging,

            -- Feature: had KPI events (check-ins, tasks) in first 7 days
            EXISTS (
                SELECT 1 FROM kpi_events ke
                WHERE ke.athlete_id = ur.patient_id
                  AND ke.event_type IN ('check_in_completed', 'task_completed')
                  AND (ke.created_at::DATE - ur.signup_at::DATE) BETWEEN 0 AND 7
            ) AS used_check_ins

        FROM user_retention ur
    ),

    -- Aggregate per feature
    driver_stats AS (
        SELECT
            feature_name,
            total_users,
            users_with_feature,
            retained_with_feature,
            retained_without_feature,
            users_without_feature,
            -- Retention rate among users who used this feature
            CASE WHEN users_with_feature > 0
                THEN ROUND((retained_with_feature::NUMERIC / users_with_feature) * 100, 1)
                ELSE 0
            END AS retention_rate_with,
            -- Retention rate among users who did NOT use this feature
            CASE WHEN users_without_feature > 0
                THEN ROUND((retained_without_feature::NUMERIC / users_without_feature) * 100, 1)
                ELSE 0
            END AS retention_rate_without
        FROM (
            SELECT
                'scheduled_sessions' AS feature_name,
                COUNT(*) AS total_users,
                COUNT(*) FILTER (WHERE used_scheduled_sessions) AS users_with_feature,
                COUNT(*) FILTER (WHERE used_scheduled_sessions AND retained_d30) AS retained_with_feature,
                COUNT(*) FILTER (WHERE NOT used_scheduled_sessions AND retained_d30) AS retained_without_feature,
                COUNT(*) FILTER (WHERE NOT used_scheduled_sessions) AS users_without_feature
            FROM first_week_features

            UNION ALL

            SELECT
                'manual_sessions',
                COUNT(*),
                COUNT(*) FILTER (WHERE used_manual_sessions),
                COUNT(*) FILTER (WHERE used_manual_sessions AND retained_d30),
                COUNT(*) FILTER (WHERE NOT used_manual_sessions AND retained_d30),
                COUNT(*) FILTER (WHERE NOT used_manual_sessions)
            FROM first_week_features

            UNION ALL

            SELECT
                'daily_readiness',
                COUNT(*),
                COUNT(*) FILTER (WHERE used_daily_readiness),
                COUNT(*) FILTER (WHERE used_daily_readiness AND retained_d30),
                COUNT(*) FILTER (WHERE NOT used_daily_readiness AND retained_d30),
                COUNT(*) FILTER (WHERE NOT used_daily_readiness)
            FROM first_week_features

            UNION ALL

            SELECT
                'streak_tracking',
                COUNT(*),
                COUNT(*) FILTER (WHERE used_streak_tracking),
                COUNT(*) FILTER (WHERE used_streak_tracking AND retained_d30),
                COUNT(*) FILTER (WHERE NOT used_streak_tracking AND retained_d30),
                COUNT(*) FILTER (WHERE NOT used_streak_tracking)
            FROM first_week_features

            UNION ALL

            SELECT
                'exercise_logging',
                COUNT(*),
                COUNT(*) FILTER (WHERE used_exercise_logging),
                COUNT(*) FILTER (WHERE used_exercise_logging AND retained_d30),
                COUNT(*) FILTER (WHERE NOT used_exercise_logging AND retained_d30),
                COUNT(*) FILTER (WHERE NOT used_exercise_logging)
            FROM first_week_features

            UNION ALL

            SELECT
                'check_ins',
                COUNT(*),
                COUNT(*) FILTER (WHERE used_check_ins),
                COUNT(*) FILTER (WHERE used_check_ins AND retained_d30),
                COUNT(*) FILTER (WHERE NOT used_check_ins AND retained_d30),
                COUNT(*) FILTER (WHERE NOT used_check_ins)
            FROM first_week_features
        ) features
    )

    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'feature', feature_name,
            'total_users', total_users,
            'users_with_feature', users_with_feature,
            'users_without_feature', users_without_feature,
            'retained_with_feature', retained_with_feature,
            'retained_without_feature', retained_without_feature,
            'retention_rate_with_pct', retention_rate_with,
            'retention_rate_without_pct', retention_rate_without,
            'lift_pct', CASE
                WHEN retention_rate_without > 0
                THEN ROUND(((retention_rate_with - retention_rate_without) / retention_rate_without) * 100, 1)
                WHEN retention_rate_with > 0 THEN 100.0
                ELSE 0
            END
        )
        ORDER BY retention_rate_with DESC
    ), '[]'::JSONB)
    INTO result
    FROM driver_stats;

    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_retention_drivers() TO authenticated;

COMMENT ON FUNCTION get_retention_drivers IS
'ACP-969: Identifies features used in the first 7 days that correlate with 30-day retention.
Analyzes usage of: scheduled_sessions, manual_sessions, daily_readiness, streak_tracking,
exercise_logging, and check_ins. Returns retention rates with and without each feature,
plus the lift percentage. Only analyzes users who signed up >= 30 days ago.';


-- =============================================================================
-- GET RESURRECTED USERS RPC
-- =============================================================================
-- Finds users who returned after 30+ days of inactivity (default).
-- "Resurrection" = completing a session after a gap of period_days with no sessions.

CREATE OR REPLACE FUNCTION get_resurrected_users(period_days INT DEFAULT 30)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
    gap_interval INTERVAL;
BEGIN
    gap_interval := (period_days || ' days')::INTERVAL;

    WITH all_sessions AS (
        -- Union all session completion events with a unified schema
        SELECT
            patient_id,
            completed_at,
            'scheduled' AS session_type
        FROM scheduled_sessions
        WHERE status = 'completed'
          AND completed_at IS NOT NULL

        UNION ALL

        SELECT
            patient_id,
            completed_at,
            'manual' AS session_type
        FROM manual_sessions
        WHERE completed = true
          AND completed_at IS NOT NULL
    ),

    -- For each session, compute the gap since the previous session
    sessions_with_gaps AS (
        SELECT
            patient_id,
            completed_at,
            session_type,
            LAG(completed_at) OVER (
                PARTITION BY patient_id ORDER BY completed_at
            ) AS prev_session_at,
            completed_at - LAG(completed_at) OVER (
                PARTITION BY patient_id ORDER BY completed_at
            ) AS gap_duration
        FROM all_sessions
    ),

    -- Identify resurrection events: sessions where the gap exceeds period_days
    resurrections AS (
        SELECT
            sg.patient_id,
            sg.completed_at AS resurrected_at,
            sg.prev_session_at AS last_active_at,
            EXTRACT(DAY FROM sg.gap_duration)::INT AS inactive_days,
            sg.session_type AS return_session_type
        FROM sessions_with_gaps sg
        WHERE sg.gap_duration >= gap_interval
          AND sg.prev_session_at IS NOT NULL
    )

    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'patient_id', r.patient_id,
            'resurrected_at', r.resurrected_at,
            'last_active_at', r.last_active_at,
            'inactive_days', r.inactive_days,
            'return_session_type', r.return_session_type,
            'signup_date', p.created_at,
            'days_since_signup', EXTRACT(DAY FROM (r.resurrected_at - p.created_at))::INT
        )
        ORDER BY r.resurrected_at DESC
    ), '[]'::JSONB)
    INTO result
    FROM resurrections r
    JOIN patients p ON p.id = r.patient_id;

    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_resurrected_users(INT) TO authenticated;

COMMENT ON FUNCTION get_resurrected_users IS
'ACP-969: Finds users who returned after a specified gap of inactivity (default 30 days).
Examines both scheduled_sessions and manual_sessions completion timestamps.
Returns resurrection events with the patient_id, resurrection date, last active date,
number of inactive days, and session type that triggered the return.';


-- =============================================================================
-- INDEXES FOR OPTIMIZED RETENTION QUERIES
-- =============================================================================

-- Index for efficient cohort lookups on patients by signup month
CREATE INDEX IF NOT EXISTS idx_patients_created_at_month
ON patients (created_at);

-- Index for scheduled session completion date lookups
CREATE INDEX IF NOT EXISTS idx_scheduled_sessions_completed_at
ON scheduled_sessions (patient_id, completed_at)
WHERE status = 'completed' AND completed_at IS NOT NULL;

-- Index for manual session completion date lookups
CREATE INDEX IF NOT EXISTS idx_manual_sessions_retention_completed
ON manual_sessions (patient_id, completed_at)
WHERE completed = true AND completed_at IS NOT NULL;

-- Index for exercise_logs performed_at with patient for driver analysis
CREATE INDEX IF NOT EXISTS idx_exercise_logs_patient_performed
ON exercise_logs (patient_id, performed_at);

-- Index for daily_readiness date lookups with patient
CREATE INDEX IF NOT EXISTS idx_daily_readiness_patient_date
ON daily_readiness (patient_id, date);

-- Index for streak_history activity_date lookups with patient
-- (may already exist but IF NOT EXISTS is safe)
CREATE INDEX IF NOT EXISTS idx_streak_history_patient_activity
ON streak_history (patient_id, activity_date);

-- Index for kpi_events athlete + type for driver analysis
CREATE INDEX IF NOT EXISTS idx_kpi_events_athlete_type_date
ON kpi_events (athlete_id, event_type, created_at)
WHERE athlete_id IS NOT NULL;
