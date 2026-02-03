-- ============================================================================
-- HEALTH INTELLIGENCE OPTIMIZATIONS MIGRATION
-- ============================================================================
-- Advanced PostgreSQL optimizations for health intelligence tables:
-- - GIN indexes for JSONB columns
-- - BRIN indexes for time-series data
-- - Materialized views for analytics
-- - RPC functions for common queries
-- - Computed columns via triggers
-- - Statistics tuning
--
-- Date: 2026-02-02
-- ============================================================================

BEGIN;

-- ============================================================================
-- GIN INDEXES FOR JSONB COLUMNS
-- ============================================================================
-- GIN indexes enable fast searches within JSONB arrays and objects

-- Recovery protocol phases (for searching by phase type, duration, etc.)
CREATE INDEX IF NOT EXISTS idx_recovery_protocols_phases_gin
    ON recovery_protocols USING GIN (phases jsonb_path_ops);

-- Supplement interactions (for checking drug interactions)
CREATE INDEX IF NOT EXISTS idx_supplements_interactions_gin
    ON supplements USING GIN (interactions jsonb_path_ops);

-- ============================================================================
-- BRIN INDEXES FOR TIME-SERIES DATA
-- ============================================================================
-- BRIN indexes are much smaller than B-tree for time-series data
-- They work best when data is naturally ordered by time (inserted chronologically)
-- Use these for large tables where queries filter by date ranges

-- Lab results by test date (chronological)
CREATE INDEX IF NOT EXISTS idx_lab_results_test_date_brin
    ON lab_results USING BRIN (test_date) WITH (pages_per_range = 32);

-- Recovery sessions by logged time
CREATE INDEX IF NOT EXISTS idx_recovery_sessions_logged_at_brin
    ON recovery_sessions USING BRIN (logged_at) WITH (pages_per_range = 32);

-- Fasting logs by start time
CREATE INDEX IF NOT EXISTS idx_fasting_logs_started_at_brin
    ON fasting_logs USING BRIN (started_at) WITH (pages_per_range = 32);

-- Supplement logs by logged time
CREATE INDEX IF NOT EXISTS idx_supplement_logs_logged_at_brin
    ON supplement_logs USING BRIN (logged_at) WITH (pages_per_range = 32);

-- ============================================================================
-- COVERING INDEXES (Index-Only Scans)
-- ============================================================================
-- Include frequently accessed columns to avoid table lookups

-- Biomarker dashboard: get value, unit, flag without hitting table
CREATE INDEX IF NOT EXISTS idx_biomarker_values_covering
    ON biomarker_values (lab_result_id, biomarker_type)
    INCLUDE (value, unit, is_flagged);

-- Recovery summary: get type and duration without table lookup
CREATE INDEX IF NOT EXISTS idx_recovery_sessions_summary
    ON recovery_sessions (patient_id, logged_at DESC)
    INCLUDE (session_type, duration_minutes, temperature_f);

-- Fasting summary: get duration info without table lookup
CREATE INDEX IF NOT EXISTS idx_fasting_logs_summary
    ON fasting_logs (patient_id, started_at DESC)
    INCLUDE (planned_hours, actual_hours, completed, protocol_type);

-- ============================================================================
-- EXPRESSION INDEXES
-- ============================================================================

-- Index on date part of logged_at for daily aggregations
-- Note: We use (logged_at AT TIME ZONE 'UTC')::date for immutability
CREATE INDEX IF NOT EXISTS idx_recovery_sessions_date
    ON recovery_sessions (((logged_at AT TIME ZONE 'UTC')::date));

CREATE INDEX IF NOT EXISTS idx_supplement_logs_date
    ON supplement_logs (((logged_at AT TIME ZONE 'UTC')::date));

-- Index for searching supplements by lowercase name
CREATE INDEX IF NOT EXISTS idx_supplements_name_lower
    ON supplements (lower(name));

-- ============================================================================
-- STATISTICS TUNING
-- ============================================================================
-- Increase statistics targets for columns used in complex queries
-- Higher values = better query plans but longer ANALYZE time

ALTER TABLE biomarker_values ALTER COLUMN biomarker_type SET STATISTICS 1000;
ALTER TABLE biomarker_reference_ranges ALTER COLUMN biomarker_type SET STATISTICS 1000;
ALTER TABLE supplements ALTER COLUMN category SET STATISTICS 500;
ALTER TABLE recovery_sessions ALTER COLUMN session_type SET STATISTICS 500;

-- ============================================================================
-- TRIGGER: AUTO-CALCULATE FASTING ACTUAL HOURS
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_fasting_actual_hours()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ended_at IS NOT NULL AND NEW.started_at IS NOT NULL THEN
        NEW.actual_hours := EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at)) / 3600.0;
        NEW.completed := NEW.actual_hours >= NEW.planned_hours;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_calculate_fasting_hours ON fasting_logs;
CREATE TRIGGER trigger_calculate_fasting_hours
    BEFORE INSERT OR UPDATE ON fasting_logs
    FOR EACH ROW
    EXECUTE FUNCTION calculate_fasting_actual_hours();

-- ============================================================================
-- RPC FUNCTIONS FOR COMMON QUERIES
-- ============================================================================

-- Get patient's biomarker trends (last N results for a specific biomarker)
CREATE OR REPLACE FUNCTION get_biomarker_trend(
    p_patient_id UUID,
    p_biomarker_type TEXT,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    test_date DATE,
    value NUMERIC,
    unit TEXT,
    is_flagged BOOLEAN,
    optimal_low NUMERIC,
    optimal_high NUMERIC,
    normal_low NUMERIC,
    normal_high NUMERIC
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        lr.test_date,
        bv.value,
        bv.unit,
        bv.is_flagged,
        brr.optimal_low,
        brr.optimal_high,
        brr.normal_low,
        brr.normal_high
    FROM biomarker_values bv
    JOIN lab_results lr ON lr.id = bv.lab_result_id
    LEFT JOIN biomarker_reference_ranges brr ON brr.biomarker_type = bv.biomarker_type
    WHERE lr.patient_id = p_patient_id
      AND bv.biomarker_type = p_biomarker_type
    ORDER BY lr.test_date DESC
    LIMIT p_limit;
$$;

-- Get patient's weekly recovery summary
CREATE OR REPLACE FUNCTION get_weekly_recovery_summary(
    p_patient_id UUID,
    p_weeks_back INTEGER DEFAULT 4
)
RETURNS TABLE (
    week_start DATE,
    sauna_minutes INTEGER,
    cold_minutes INTEGER,
    contrast_minutes INTEGER,
    total_sessions INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        date_trunc('week', logged_at)::date AS week_start,
        COALESCE(SUM(CASE WHEN session_type IN ('sauna_traditional', 'sauna_infrared', 'sauna_steam')
                          THEN duration_minutes END), 0)::integer AS sauna_minutes,
        COALESCE(SUM(CASE WHEN session_type IN ('cold_plunge', 'cold_shower', 'ice_bath')
                          THEN duration_minutes END), 0)::integer AS cold_minutes,
        COALESCE(SUM(CASE WHEN session_type = 'contrast'
                          THEN duration_minutes END), 0)::integer AS contrast_minutes,
        COUNT(*)::integer AS total_sessions
    FROM recovery_sessions
    WHERE patient_id = p_patient_id
      AND logged_at >= now() - (p_weeks_back || ' weeks')::interval
    GROUP BY date_trunc('week', logged_at)
    ORDER BY week_start DESC;
$$;

-- Get patient's fasting stats
CREATE OR REPLACE FUNCTION get_fasting_stats(
    p_patient_id UUID,
    p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    total_fasts INTEGER,
    completed_fasts INTEGER,
    completion_rate NUMERIC,
    total_fasting_hours NUMERIC,
    avg_fasting_hours NUMERIC,
    longest_fast_hours NUMERIC,
    current_streak INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    WITH fasting_data AS (
        SELECT
            COUNT(*) AS total_fasts,
            COUNT(*) FILTER (WHERE completed) AS completed_fasts,
            SUM(actual_hours) AS total_hours,
            AVG(actual_hours) AS avg_hours,
            MAX(actual_hours) AS max_hours
        FROM fasting_logs
        WHERE patient_id = p_patient_id
          AND started_at >= now() - (p_days_back || ' days')::interval
    ),
    streak_data AS (
        SELECT COUNT(*) AS current_streak
        FROM (
            SELECT
                started_at::date AS fast_date,
                ROW_NUMBER() OVER (ORDER BY started_at::date DESC)::integer AS rn
            FROM fasting_logs
            WHERE patient_id = p_patient_id
              AND completed = true
        ) s
        WHERE fast_date = CURRENT_DATE - (rn - 1)
    )
    SELECT
        fd.total_fasts::integer,
        fd.completed_fasts::integer,
        CASE WHEN fd.total_fasts > 0
             THEN ROUND(fd.completed_fasts::numeric / fd.total_fasts * 100, 1)
             ELSE 0 END AS completion_rate,
        ROUND(COALESCE(fd.total_hours, 0), 1) AS total_fasting_hours,
        ROUND(COALESCE(fd.avg_hours, 0), 1) AS avg_fasting_hours,
        ROUND(COALESCE(fd.max_hours, 0), 1) AS longest_fast_hours,
        COALESCE(sd.current_streak, 0)::integer AS current_streak
    FROM fasting_data fd
    CROSS JOIN streak_data sd;
$$;

-- Get patient's supplement adherence
CREATE OR REPLACE FUNCTION get_supplement_adherence(
    p_patient_id UUID,
    p_days_back INTEGER DEFAULT 7
)
RETURNS TABLE (
    supplement_name TEXT,
    planned_frequency TEXT,
    doses_logged INTEGER,
    expected_doses INTEGER,
    adherence_rate NUMERIC
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        s.name AS supplement_name,
        pss.frequency AS planned_frequency,
        COUNT(sl.id)::integer AS doses_logged,
        CASE
            WHEN pss.frequency = 'daily' THEN p_days_back
            WHEN pss.frequency = 'twice daily' THEN p_days_back * 2
            WHEN pss.frequency = 'three times daily' THEN p_days_back * 3
            ELSE p_days_back
        END::integer AS expected_doses,
        ROUND(
            COUNT(sl.id)::numeric /
            NULLIF(CASE
                WHEN pss.frequency = 'daily' THEN p_days_back
                WHEN pss.frequency = 'twice daily' THEN p_days_back * 2
                WHEN pss.frequency = 'three times daily' THEN p_days_back * 3
                ELSE p_days_back
            END, 0) * 100,
            1
        ) AS adherence_rate
    FROM patient_supplement_stacks pss
    JOIN supplements s ON s.id = pss.supplement_id
    LEFT JOIN supplement_logs sl ON sl.patient_id = pss.patient_id
                                 AND sl.supplement_id = pss.supplement_id
                                 AND sl.logged_at >= now() - (p_days_back || ' days')::interval
    WHERE pss.patient_id = p_patient_id
      AND pss.is_active = true
    GROUP BY s.name, pss.frequency;
$$;

-- Get flagged biomarkers (outside optimal range)
CREATE OR REPLACE FUNCTION get_flagged_biomarkers(
    p_patient_id UUID
)
RETURNS TABLE (
    biomarker_type TEXT,
    biomarker_name TEXT,
    category TEXT,
    value NUMERIC,
    unit TEXT,
    optimal_low NUMERIC,
    optimal_high NUMERIC,
    status TEXT,
    test_date DATE
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    WITH latest_results AS (
        SELECT DISTINCT ON (bv.biomarker_type)
            bv.biomarker_type,
            bv.value,
            bv.unit,
            lr.test_date
        FROM biomarker_values bv
        JOIN lab_results lr ON lr.id = bv.lab_result_id
        WHERE lr.patient_id = p_patient_id
        ORDER BY bv.biomarker_type, lr.test_date DESC
    )
    SELECT
        lr.biomarker_type,
        brr.name AS biomarker_name,
        brr.category,
        lr.value,
        lr.unit,
        brr.optimal_low,
        brr.optimal_high,
        CASE
            WHEN lr.value < brr.optimal_low THEN 'low'
            WHEN lr.value > brr.optimal_high THEN 'high'
            ELSE 'optimal'
        END AS status,
        lr.test_date
    FROM latest_results lr
    JOIN biomarker_reference_ranges brr ON brr.biomarker_type = lr.biomarker_type
    WHERE lr.value < brr.optimal_low OR lr.value > brr.optimal_high
    ORDER BY brr.category, brr.name;
$$;

-- ============================================================================
-- MATERIALIZED VIEW: PATIENT HEALTH DASHBOARD
-- ============================================================================
-- Pre-computed summary for quick dashboard loading
-- Refresh periodically (e.g., every hour or on-demand)

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_patient_health_summary AS
SELECT
    p.id AS patient_id,
    -- Lab stats
    (SELECT COUNT(*) FROM lab_results WHERE patient_id = p.id) AS total_lab_tests,
    (SELECT MAX(test_date) FROM lab_results WHERE patient_id = p.id) AS last_lab_date,
    (SELECT COUNT(*) FROM biomarker_values bv
     JOIN lab_results lr ON lr.id = bv.lab_result_id
     WHERE lr.patient_id = p.id AND bv.is_flagged = true
     AND lr.test_date = (SELECT MAX(test_date) FROM lab_results WHERE patient_id = p.id)
    ) AS flagged_biomarkers_count,
    -- Recovery stats (last 30 days)
    (SELECT COALESCE(SUM(duration_minutes), 0) FROM recovery_sessions
     WHERE patient_id = p.id AND logged_at >= now() - interval '30 days'
     AND session_type IN ('sauna_traditional', 'sauna_infrared', 'sauna_steam')
    ) AS sauna_minutes_30d,
    (SELECT COALESCE(SUM(duration_minutes), 0) FROM recovery_sessions
     WHERE patient_id = p.id AND logged_at >= now() - interval '30 days'
     AND session_type IN ('cold_plunge', 'cold_shower', 'ice_bath')
    ) AS cold_minutes_30d,
    -- Fasting stats (last 30 days)
    (SELECT COUNT(*) FROM fasting_logs
     WHERE patient_id = p.id AND started_at >= now() - interval '30 days'
    ) AS fasts_30d,
    (SELECT COALESCE(SUM(actual_hours), 0) FROM fasting_logs
     WHERE patient_id = p.id AND started_at >= now() - interval '30 days' AND completed = true
    ) AS fasting_hours_30d,
    -- Supplement stats
    (SELECT COUNT(*) FROM patient_supplement_stacks
     WHERE patient_id = p.id AND is_active = true
    ) AS active_supplements,
    -- Timestamps
    now() AS refreshed_at
FROM patients p;

-- Index on materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_patient_health_summary_patient
    ON mv_patient_health_summary (patient_id);

-- Function to refresh the materialized view
CREATE OR REPLACE FUNCTION refresh_patient_health_summary()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_patient_health_summary;
$$;

-- ============================================================================
-- GRANTS FOR RPC FUNCTIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_biomarker_trend(UUID, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_recovery_summary(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_fasting_stats(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_supplement_adherence(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_flagged_biomarkers(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION refresh_patient_health_summary() TO service_role;

-- Grant select on materialized view
GRANT SELECT ON mv_patient_health_summary TO authenticated;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_index_count integer;
    v_function_count integer;
BEGIN
    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname LIKE 'idx_%'
      AND (indexname LIKE '%health%' OR indexname LIKE '%biomarker%'
           OR indexname LIKE '%recovery%' OR indexname LIKE '%fasting%'
           OR indexname LIKE '%supplement%' OR indexname LIKE '%lab%');

    SELECT COUNT(*) INTO v_function_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname IN ('get_biomarker_trend', 'get_weekly_recovery_summary',
                        'get_fasting_stats', 'get_supplement_adherence',
                        'get_flagged_biomarkers', 'refresh_patient_health_summary');

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'HEALTH INTELLIGENCE OPTIMIZATIONS COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Optimizations Applied:';
    RAISE NOTICE '  - Health-related indexes: %', v_index_count;
    RAISE NOTICE '  - RPC functions: %', v_function_count;
    RAISE NOTICE '  - Materialized view: mv_patient_health_summary';
    RAISE NOTICE '  - Auto-calculate trigger: fasting actual_hours';
    RAISE NOTICE '  - Statistics tuning: biomarker_type, category, session_type';
    RAISE NOTICE '';
    RAISE NOTICE 'New GIN Indexes (JSONB search):';
    RAISE NOTICE '  - idx_recovery_protocols_phases_gin';
    RAISE NOTICE '  - idx_supplements_interactions_gin';
    RAISE NOTICE '';
    RAISE NOTICE 'New BRIN Indexes (time-series):';
    RAISE NOTICE '  - idx_lab_results_test_date_brin';
    RAISE NOTICE '  - idx_recovery_sessions_logged_at_brin';
    RAISE NOTICE '  - idx_fasting_logs_started_at_brin';
    RAISE NOTICE '  - idx_supplement_logs_logged_at_brin';
    RAISE NOTICE '';
    RAISE NOTICE 'RPC Functions:';
    RAISE NOTICE '  - get_biomarker_trend(patient_id, biomarker_type, limit)';
    RAISE NOTICE '  - get_weekly_recovery_summary(patient_id, weeks_back)';
    RAISE NOTICE '  - get_fasting_stats(patient_id, days_back)';
    RAISE NOTICE '  - get_supplement_adherence(patient_id, days_back)';
    RAISE NOTICE '  - get_flagged_biomarkers(patient_id)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;
