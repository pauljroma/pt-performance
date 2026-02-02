-- Migration: Create nutrition analytics views
-- Date: 2026-02-02
-- Author: Swarm Agent 1
-- Description: Create views for nutrition dashboard analytics
-- Views: vw_nutrition_goal_progress, vw_daily_nutrition, vw_nutrition_trend, vw_macro_distribution

-- ============================================================================
-- 1. VW_DAILY_NUTRITION: Daily nutrition summary
-- ============================================================================
-- Aggregate nutrition_logs by patient and date
-- Used by: NutritionService.fetchDailySummary()

DROP VIEW IF EXISTS vw_daily_nutrition CASCADE;
CREATE VIEW vw_daily_nutrition
WITH (security_invoker = true)
AS
SELECT
    nl.patient_id::TEXT AS patient_id,
    DATE(nl.logged_at) AS log_date,
    COUNT(*)::INT AS meal_count,
    COALESCE(SUM(nl.calories), 0)::INT AS total_calories,
    COALESCE(SUM(COALESCE(nl.protein, nl.protein_grams)), 0)::DOUBLE PRECISION AS total_protein_g,
    COALESCE(SUM(COALESCE(nl.carbs, nl.carbs_grams)), 0)::DOUBLE PRECISION AS total_carbs_g,
    COALESCE(SUM(COALESCE(nl.fats, nl.fats_grams)), 0)::DOUBLE PRECISION AS total_fat_g,
    0::DOUBLE PRECISION AS total_fiber_g  -- fiber_g not tracked in nutrition_logs, default to 0
FROM nutrition_logs nl
WHERE nl.logged_at IS NOT NULL
GROUP BY nl.patient_id, DATE(nl.logged_at)
ORDER BY DATE(nl.logged_at) DESC;

COMMENT ON VIEW vw_daily_nutrition IS 'Daily nutrition summary aggregated from nutrition_logs. Used by NutritionService.fetchDailySummary()';

-- ============================================================================
-- 2. VW_NUTRITION_GOAL_PROGRESS: Daily progress toward nutrition goals
-- ============================================================================
-- Join nutrition_logs with nutrition_goals
-- Calculate daily totals and percentage of goal achieved
-- Used by: NutritionService.fetchGoalProgress()

DROP VIEW IF EXISTS vw_nutrition_goal_progress CASCADE;
CREATE VIEW vw_nutrition_goal_progress
WITH (security_invoker = true)
AS
SELECT
    ng.patient_id::TEXT AS patient_id,
    ng.id::TEXT AS goal_id,
    ng.target_calories,
    ng.target_protein_g,
    ng.target_carbs_g,
    ng.target_fat_g,
    COALESCE(daily.total_calories, 0)::INT AS consumed_calories,
    COALESCE(daily.total_protein_g, 0)::DOUBLE PRECISION AS consumed_protein_g,
    COALESCE(daily.total_carbs_g, 0)::DOUBLE PRECISION AS consumed_carbs_g,
    COALESCE(daily.total_fat_g, 0)::DOUBLE PRECISION AS consumed_fat_g,
    -- Calculate percentages (handle null goals)
    CASE
        WHEN ng.target_calories IS NOT NULL AND ng.target_calories > 0
        THEN ROUND((COALESCE(daily.total_calories, 0)::NUMERIC / ng.target_calories::NUMERIC) * 100, 1)
        ELSE 0
    END::DOUBLE PRECISION AS calories_percent,
    CASE
        WHEN ng.target_protein_g IS NOT NULL AND ng.target_protein_g > 0
        THEN ROUND((COALESCE(daily.total_protein_g, 0)::NUMERIC / ng.target_protein_g::NUMERIC) * 100, 1)
        ELSE 0
    END::DOUBLE PRECISION AS protein_percent
FROM nutrition_goals ng
LEFT JOIN LATERAL (
    SELECT
        SUM(nl.calories)::INT AS total_calories,
        SUM(COALESCE(nl.protein, nl.protein_grams))::DOUBLE PRECISION AS total_protein_g,
        SUM(COALESCE(nl.carbs, nl.carbs_grams))::DOUBLE PRECISION AS total_carbs_g,
        SUM(COALESCE(nl.fats, nl.fats_grams))::DOUBLE PRECISION AS total_fat_g
    FROM nutrition_logs nl
    WHERE nl.patient_id = ng.patient_id
      AND DATE(nl.logged_at) = CURRENT_DATE
) daily ON true
WHERE ng.active = true;

COMMENT ON VIEW vw_nutrition_goal_progress IS 'Daily progress toward nutrition goals with percentage calculations. Used by NutritionService.fetchGoalProgress()';

-- ============================================================================
-- 3. VW_NUTRITION_TREND: Weekly nutrition trends
-- ============================================================================
-- Rolling weekly averages for macros
-- Used by: NutritionService.fetchWeeklyTrends()

DROP VIEW IF EXISTS vw_nutrition_trend CASCADE;
CREATE VIEW vw_nutrition_trend
WITH (security_invoker = true)
AS
SELECT
    patient_id::TEXT AS patient_id,
    week_start,
    days_logged::INT AS days_logged,
    avg_daily_calories::DOUBLE PRECISION AS avg_daily_calories,
    avg_daily_protein_g::DOUBLE PRECISION AS avg_daily_protein_g,
    avg_daily_carbs_g::DOUBLE PRECISION AS avg_daily_carbs_g,
    avg_daily_fat_g::DOUBLE PRECISION AS avg_daily_fat_g
FROM (
    SELECT
        nl.patient_id,
        DATE_TRUNC('week', DATE(nl.logged_at))::DATE AS week_start,
        COUNT(DISTINCT DATE(nl.logged_at)) AS days_logged,
        ROUND(AVG(daily_totals.daily_calories)::NUMERIC, 0) AS avg_daily_calories,
        ROUND(AVG(daily_totals.daily_protein)::NUMERIC, 1) AS avg_daily_protein_g,
        ROUND(AVG(daily_totals.daily_carbs)::NUMERIC, 1) AS avg_daily_carbs_g,
        ROUND(AVG(daily_totals.daily_fat)::NUMERIC, 1) AS avg_daily_fat_g
    FROM nutrition_logs nl
    JOIN LATERAL (
        SELECT
            DATE(nl2.logged_at) AS log_date,
            SUM(nl2.calories) AS daily_calories,
            SUM(COALESCE(nl2.protein, nl2.protein_grams)) AS daily_protein,
            SUM(COALESCE(nl2.carbs, nl2.carbs_grams)) AS daily_carbs,
            SUM(COALESCE(nl2.fats, nl2.fats_grams)) AS daily_fat
        FROM nutrition_logs nl2
        WHERE nl2.patient_id = nl.patient_id
          AND DATE(nl2.logged_at) = DATE(nl.logged_at)
        GROUP BY DATE(nl2.logged_at)
    ) daily_totals ON true
    WHERE nl.logged_at IS NOT NULL
      AND nl.logged_at >= CURRENT_DATE - INTERVAL '12 weeks'
    GROUP BY nl.patient_id, DATE_TRUNC('week', DATE(nl.logged_at))
) weekly_data
ORDER BY week_start DESC;

COMMENT ON VIEW vw_nutrition_trend IS 'Weekly nutrition trends with rolling averages. Used by NutritionService.fetchWeeklyTrends()';

-- ============================================================================
-- 4. VW_MACRO_DISTRIBUTION: Macro percentage breakdown
-- ============================================================================
-- Calculate percentage of calories from each macro
-- Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
-- Used by: NutritionService.fetchMacroDistribution()

DROP VIEW IF EXISTS vw_macro_distribution CASCADE;
CREATE VIEW vw_macro_distribution
WITH (security_invoker = true)
AS
SELECT
    patient_id::TEXT AS patient_id,
    log_date,
    protein_calories::DOUBLE PRECISION AS protein_calories,
    carbs_calories::DOUBLE PRECISION AS carbs_calories,
    fat_calories::DOUBLE PRECISION AS fat_calories,
    -- Calculate percentages
    CASE
        WHEN total_macro_calories > 0
        THEN ROUND((protein_calories::NUMERIC / total_macro_calories::NUMERIC) * 100, 1)
        ELSE 0
    END::DOUBLE PRECISION AS protein_percent,
    CASE
        WHEN total_macro_calories > 0
        THEN ROUND((carbs_calories::NUMERIC / total_macro_calories::NUMERIC) * 100, 1)
        ELSE 0
    END::DOUBLE PRECISION AS carbs_percent,
    CASE
        WHEN total_macro_calories > 0
        THEN ROUND((fat_calories::NUMERIC / total_macro_calories::NUMERIC) * 100, 1)
        ELSE 0
    END::DOUBLE PRECISION AS fat_percent
FROM (
    SELECT
        nl.patient_id,
        DATE(nl.logged_at) AS log_date,
        -- Calculate calories from each macro
        COALESCE(SUM(COALESCE(nl.protein, nl.protein_grams)), 0) * 4 AS protein_calories,
        COALESCE(SUM(COALESCE(nl.carbs, nl.carbs_grams)), 0) * 4 AS carbs_calories,
        COALESCE(SUM(COALESCE(nl.fats, nl.fats_grams)), 0) * 9 AS fat_calories,
        -- Total calories from macros
        (COALESCE(SUM(COALESCE(nl.protein, nl.protein_grams)), 0) * 4) +
        (COALESCE(SUM(COALESCE(nl.carbs, nl.carbs_grams)), 0) * 4) +
        (COALESCE(SUM(COALESCE(nl.fats, nl.fats_grams)), 0) * 9) AS total_macro_calories
    FROM nutrition_logs nl
    WHERE nl.logged_at IS NOT NULL
    GROUP BY nl.patient_id, DATE(nl.logged_at)
) macro_data
ORDER BY log_date DESC;

COMMENT ON VIEW vw_macro_distribution IS 'Macro percentage breakdown by date. Protein/Carbs: 4 cal/g, Fat: 9 cal/g. Used by NutritionService.fetchMacroDistribution()';

-- ============================================================================
-- 5. GRANT PERMISSIONS
-- ============================================================================

-- Grant SELECT to authenticated users (RLS on underlying tables will filter)
GRANT SELECT ON vw_daily_nutrition TO authenticated;
GRANT SELECT ON vw_nutrition_goal_progress TO authenticated;
GRANT SELECT ON vw_nutrition_trend TO authenticated;
GRANT SELECT ON vw_macro_distribution TO authenticated;

-- ============================================================================
-- 6. VALIDATION
-- ============================================================================

DO $$
DECLARE
    daily_exists BOOLEAN;
    goal_progress_exists BOOLEAN;
    trend_exists BOOLEAN;
    macro_exists BOOLEAN;
BEGIN
    -- Check views exist
    SELECT EXISTS(
        SELECT 1 FROM information_schema.views WHERE table_name = 'vw_daily_nutrition'
    ) INTO daily_exists;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.views WHERE table_name = 'vw_nutrition_goal_progress'
    ) INTO goal_progress_exists;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.views WHERE table_name = 'vw_nutrition_trend'
    ) INTO trend_exists;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.views WHERE table_name = 'vw_macro_distribution'
    ) INTO macro_exists;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'NUTRITION ANALYTICS VIEWS CREATED';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'vw_daily_nutrition: %', CASE WHEN daily_exists THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE 'vw_nutrition_goal_progress: %', CASE WHEN goal_progress_exists THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE 'vw_nutrition_trend: %', CASE WHEN trend_exists THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE 'vw_macro_distribution: %', CASE WHEN macro_exists THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE '============================================';

    -- Raise exception if any view is missing
    IF NOT daily_exists OR NOT goal_progress_exists OR NOT trend_exists OR NOT macro_exists THEN
        RAISE EXCEPTION 'One or more nutrition analytics views failed to create';
    END IF;
END $$;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
