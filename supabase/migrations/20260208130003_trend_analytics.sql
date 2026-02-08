-- 20260208130003_trend_analytics.sql
-- Create database objects for Historical Trend Analysis (M8)
-- Supports 30/90/180 day views with materialized aggregates

-- ============================================================================
-- 1. MATERIALIZED VIEW: Daily Aggregates for Trend Analysis
-- ============================================================================
-- Pre-computed daily metrics for efficient trend queries
-- Refreshed periodically via cron job

DROP MATERIALIZED VIEW IF EXISTS mv_daily_patient_metrics CASCADE;

CREATE MATERIALIZED VIEW mv_daily_patient_metrics AS
SELECT
    p.id AS patient_id,
    d.date::date AS metric_date,

    -- Session Adherence (completed/scheduled percentage for the day)
    COALESCE(
        (SELECT COUNT(*)::float / NULLIF(COUNT(*), 0) * 100
         FROM sessions s
         JOIN phases ph ON ph.id = s.phase_id
         JOIN programs pr ON pr.id = ph.program_id
         WHERE pr.patient_id = p.id
           AND DATE(s.completed_at) = d.date
           AND s.completed = true),
        0
    ) AS adherence_score,

    -- Average Pain Level for the day
    COALESCE(
        (SELECT AVG(el.pain_score)
         FROM exercise_logs el
         WHERE el.patient_id = p.id
           AND DATE(el.logged_at) = d.date
           AND el.pain_score IS NOT NULL),
        NULL
    ) AS avg_pain_level,

    -- Recovery Score (from daily_readiness if available)
    (SELECT dr.readiness_score
     FROM daily_readiness dr
     WHERE dr.patient_id = p.id
       AND dr.date = d.date
     LIMIT 1
    ) AS recovery_score,

    -- Sleep Quality (from daily_readiness)
    (SELECT dr.sleep_hours
     FROM daily_readiness dr
     WHERE dr.patient_id = p.id
       AND dr.date = d.date
     LIMIT 1
    ) AS sleep_quality,

    -- Training Volume (count of exercise logs as proxy)
    COALESCE(
        (SELECT COUNT(*)
         FROM exercise_logs el
         WHERE el.patient_id = p.id
           AND DATE(el.logged_at) = d.date),
        0
    ) AS workload_volume,

    -- Average RPE for the day (for intensity tracking)
    (SELECT AVG(el.rpe)
     FROM exercise_logs el
     WHERE el.patient_id = p.id
       AND DATE(el.logged_at) = d.date
       AND el.rpe IS NOT NULL
    ) AS avg_rpe,

    -- Session count for the day
    (SELECT COUNT(*)
     FROM sessions s
     JOIN phases ph ON ph.id = s.phase_id
     JOIN programs pr ON pr.id = ph.program_id
     WHERE pr.patient_id = p.id
       AND DATE(s.completed_at) = d.date
       AND s.completed = true
    ) AS sessions_completed

FROM patients p
CROSS JOIN (
    SELECT generate_series(
        CURRENT_DATE - INTERVAL '365 days',
        CURRENT_DATE,
        INTERVAL '1 day'
    )::date AS date
) d
WHERE EXISTS (
    -- Only include patients with activity
    SELECT 1 FROM exercise_logs el
    WHERE el.patient_id = p.id
)
WITH DATA;

-- Create indexes for fast lookups
CREATE UNIQUE INDEX idx_mv_daily_metrics_patient_date
    ON mv_daily_patient_metrics(patient_id, metric_date);

CREATE INDEX idx_mv_daily_metrics_date
    ON mv_daily_patient_metrics(metric_date);

COMMENT ON MATERIALIZED VIEW mv_daily_patient_metrics IS
    'Pre-computed daily metrics for trend analysis. Refresh daily via cron.';


-- ============================================================================
-- 2. FUNCTION: Get Trend Data for a Metric
-- ============================================================================
-- Returns aggregated data points for a specific metric and time range

CREATE OR REPLACE FUNCTION get_trend_data(
    p_patient_id UUID,
    p_metric_type TEXT,
    p_start_date TIMESTAMPTZ,
    p_aggregation TEXT DEFAULT 'daily'
)
RETURNS TABLE (
    data_date DATE,
    metric_value DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_interval TEXT;
BEGIN
    -- Determine aggregation interval
    v_interval := CASE p_aggregation
        WHEN 'daily' THEN '1 day'
        WHEN 'weekly' THEN '1 week'
        WHEN 'monthly' THEN '1 month'
        ELSE '1 day'
    END;

    RETURN QUERY
    WITH date_series AS (
        SELECT generate_series(
            p_start_date::date,
            CURRENT_DATE,
            v_interval::interval
        )::date AS period_start
    ),
    raw_data AS (
        SELECT
            metric_date,
            CASE p_metric_type
                WHEN 'adherence' THEN adherence_score
                WHEN 'pain' THEN avg_pain_level
                WHEN 'recovery' THEN recovery_score
                WHEN 'sleep' THEN sleep_quality
                WHEN 'volume' THEN workload_volume
                WHEN 'intensity' THEN avg_rpe
                ELSE adherence_score
            END AS value
        FROM mv_daily_patient_metrics
        WHERE patient_id = p_patient_id
          AND metric_date >= p_start_date::date
    )
    SELECT
        ds.period_start AS data_date,
        COALESCE(
            AVG(rd.value),
            0
        )::DOUBLE PRECISION AS metric_value
    FROM date_series ds
    LEFT JOIN raw_data rd ON (
        CASE p_aggregation
            WHEN 'daily' THEN rd.metric_date = ds.period_start
            WHEN 'weekly' THEN rd.metric_date >= ds.period_start
                AND rd.metric_date < ds.period_start + INTERVAL '1 week'
            WHEN 'monthly' THEN rd.metric_date >= ds.period_start
                AND rd.metric_date < ds.period_start + INTERVAL '1 month'
            ELSE rd.metric_date = ds.period_start
        END
    )
    GROUP BY ds.period_start
    ORDER BY ds.period_start;
END;
$$;

COMMENT ON FUNCTION get_trend_data IS
    'Returns aggregated trend data for a specific metric and patient';


-- ============================================================================
-- 3. FUNCTION: Get Trend Data for Date Interval
-- ============================================================================
-- Returns data points within a specific date range

CREATE OR REPLACE FUNCTION get_trend_data_for_interval(
    p_patient_id UUID,
    p_metric_type TEXT,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS TABLE (
    data_date DATE,
    metric_value DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        metric_date AS data_date,
        CASE p_metric_type
            WHEN 'adherence' THEN adherence_score
            WHEN 'pain' THEN avg_pain_level
            WHEN 'recovery' THEN recovery_score
            WHEN 'sleep' THEN sleep_quality
            WHEN 'volume' THEN workload_volume
            WHEN 'intensity' THEN avg_rpe
            ELSE adherence_score
        END::DOUBLE PRECISION AS metric_value
    FROM mv_daily_patient_metrics
    WHERE patient_id = p_patient_id
      AND metric_date >= p_start_date::date
      AND metric_date <= p_end_date::date
    ORDER BY metric_date;
END;
$$;

COMMENT ON FUNCTION get_trend_data_for_interval IS
    'Returns trend data for a specific date interval';


-- ============================================================================
-- 4. FUNCTION: Calculate Moving Average
-- ============================================================================
-- Calculates moving average for a given window

CREATE OR REPLACE FUNCTION calculate_moving_average(
    p_patient_id UUID,
    p_metric_type TEXT,
    p_window_days INT DEFAULT 7,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days'
)
RETURNS TABLE (
    data_date DATE,
    raw_value DOUBLE PRECISION,
    moving_avg DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH raw_data AS (
        SELECT
            metric_date,
            CASE p_metric_type
                WHEN 'adherence' THEN adherence_score
                WHEN 'pain' THEN avg_pain_level
                WHEN 'recovery' THEN recovery_score
                WHEN 'sleep' THEN sleep_quality
                WHEN 'volume' THEN workload_volume
                WHEN 'intensity' THEN avg_rpe
                ELSE adherence_score
            END AS value
        FROM mv_daily_patient_metrics
        WHERE patient_id = p_patient_id
          AND metric_date >= p_start_date
    )
    SELECT
        rd.metric_date AS data_date,
        rd.value::DOUBLE PRECISION AS raw_value,
        AVG(rd.value) OVER (
            ORDER BY rd.metric_date
            ROWS BETWEEN p_window_days - 1 PRECEDING AND CURRENT ROW
        )::DOUBLE PRECISION AS moving_avg
    FROM raw_data rd
    ORDER BY rd.metric_date;
END;
$$;

COMMENT ON FUNCTION calculate_moving_average IS
    'Calculates moving average for trend smoothing';


-- ============================================================================
-- 5. FUNCTION: Get Best Period
-- ============================================================================
-- Finds the best performing period of a given length

CREATE OR REPLACE FUNCTION get_best_period(
    p_patient_id UUID,
    p_metric_type TEXT,
    p_period_days INT DEFAULT 7,
    p_higher_is_better BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    period_start DATE,
    period_end DATE,
    avg_value DOUBLE PRECISION,
    peak_value DOUBLE PRECISION,
    peak_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH raw_data AS (
        SELECT
            metric_date,
            CASE p_metric_type
                WHEN 'adherence' THEN adherence_score
                WHEN 'pain' THEN avg_pain_level
                WHEN 'recovery' THEN recovery_score
                WHEN 'sleep' THEN sleep_quality
                WHEN 'volume' THEN workload_volume
                WHEN 'intensity' THEN avg_rpe
                ELSE adherence_score
            END AS value
        FROM mv_daily_patient_metrics
        WHERE patient_id = p_patient_id
          AND metric_date >= CURRENT_DATE - INTERVAL '365 days'
    ),
    windows AS (
        SELECT
            rd.metric_date AS window_start,
            rd.metric_date + (p_period_days - 1) AS window_end,
            AVG(rd2.value) AS window_avg,
            CASE
                WHEN p_higher_is_better THEN MAX(rd2.value)
                ELSE MIN(rd2.value)
            END AS window_peak,
            (SELECT rd3.metric_date
             FROM raw_data rd3
             WHERE rd3.metric_date BETWEEN rd.metric_date AND rd.metric_date + (p_period_days - 1)
             ORDER BY CASE WHEN p_higher_is_better THEN rd3.value ELSE -rd3.value END DESC
             LIMIT 1
            ) AS window_peak_date
        FROM raw_data rd
        JOIN raw_data rd2 ON rd2.metric_date BETWEEN rd.metric_date AND rd.metric_date + (p_period_days - 1)
        GROUP BY rd.metric_date
    )
    SELECT
        w.window_start AS period_start,
        w.window_end AS period_end,
        w.window_avg::DOUBLE PRECISION AS avg_value,
        w.window_peak::DOUBLE PRECISION AS peak_value,
        w.window_peak_date AS peak_date
    FROM windows w
    ORDER BY CASE WHEN p_higher_is_better THEN w.window_avg ELSE -w.window_avg END DESC
    LIMIT 1;
END;
$$;

COMMENT ON FUNCTION get_best_period IS
    'Finds the best performing period of specified length';


-- ============================================================================
-- 6. INDEXES FOR TIME-RANGE QUERIES
-- ============================================================================
-- Optimize queries for trend data retrieval

-- Index on exercise_logs for date-based queries
CREATE INDEX IF NOT EXISTS idx_exercise_logs_patient_logged_at
    ON exercise_logs(patient_id, logged_at DESC);

-- Index on sessions for completion date queries
CREATE INDEX IF NOT EXISTS idx_sessions_completed_at
    ON sessions(completed_at DESC)
    WHERE completed = TRUE;

-- Index on daily_readiness for date lookups
CREATE INDEX IF NOT EXISTS idx_daily_readiness_patient_date
    ON daily_readiness(patient_id, date DESC);


-- ============================================================================
-- 7. CRON JOB SETUP (pg_cron extension required)
-- ============================================================================
-- Refresh materialized view daily at 3 AM

-- Note: This requires pg_cron extension to be enabled
-- Run this separately if pg_cron is available:
--
-- SELECT cron.schedule(
--     'refresh_daily_metrics',
--     '0 3 * * *',
--     $$REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_patient_metrics$$
-- );


-- ============================================================================
-- 8. MANUAL REFRESH FUNCTION
-- ============================================================================
-- Function to manually refresh the materialized view

CREATE OR REPLACE FUNCTION refresh_trend_analytics()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_patient_metrics;
END;
$$;

COMMENT ON FUNCTION refresh_trend_analytics IS
    'Manually refresh trend analytics materialized view';


-- ============================================================================
-- 9. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT ON mv_daily_patient_metrics TO authenticated;
GRANT EXECUTE ON FUNCTION get_trend_data TO authenticated;
GRANT EXECUTE ON FUNCTION get_trend_data_for_interval TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_moving_average TO authenticated;
GRANT EXECUTE ON FUNCTION get_best_period TO authenticated;
GRANT EXECUTE ON FUNCTION refresh_trend_analytics TO service_role;


-- ============================================================================
-- 10. VALIDATION
-- ============================================================================

DO $$
DECLARE
    mv_exists BOOLEAN;
    fn_trend_data_exists BOOLEAN;
    fn_interval_exists BOOLEAN;
    fn_moving_avg_exists BOOLEAN;
    fn_best_period_exists BOOLEAN;
BEGIN
    -- Check materialized view
    SELECT EXISTS(
        SELECT 1 FROM pg_matviews WHERE matviewname = 'mv_daily_patient_metrics'
    ) INTO mv_exists;

    -- Check functions
    SELECT EXISTS(
        SELECT 1 FROM pg_proc WHERE proname = 'get_trend_data'
    ) INTO fn_trend_data_exists;

    SELECT EXISTS(
        SELECT 1 FROM pg_proc WHERE proname = 'get_trend_data_for_interval'
    ) INTO fn_interval_exists;

    SELECT EXISTS(
        SELECT 1 FROM pg_proc WHERE proname = 'calculate_moving_average'
    ) INTO fn_moving_avg_exists;

    SELECT EXISTS(
        SELECT 1 FROM pg_proc WHERE proname = 'get_best_period'
    ) INTO fn_best_period_exists;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'TREND ANALYTICS MIGRATION COMPLETE';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Materialized View: %', CASE WHEN mv_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE 'get_trend_data: %', CASE WHEN fn_trend_data_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE 'get_trend_data_for_interval: %', CASE WHEN fn_interval_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE 'calculate_moving_average: %', CASE WHEN fn_moving_avg_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE 'get_best_period: %', CASE WHEN fn_best_period_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'To enable automatic refresh, run:';
    RAISE NOTICE 'SELECT cron.schedule(''refresh_daily_metrics'', ''0 3 * * *'', ''REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_patient_metrics'');';
    RAISE NOTICE '';
END $$;
