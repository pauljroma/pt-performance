-- Migration: Create Nutrition Analytics Views
-- Created: 2026-01-19
-- Description: Views for nutrition tracking analytics and reporting

-- Daily nutrition summary view
CREATE OR REPLACE VIEW vw_daily_nutrition AS
SELECT
    patient_id::text as patient_id,
    DATE(logged_at) as log_date,
    COUNT(*) as meal_count,
    COALESCE(SUM(total_calories), 0) as total_calories,
    COALESCE(SUM(total_protein_g), 0) as total_protein_g,
    COALESCE(SUM(total_carbs_g), 0) as total_carbs_g,
    COALESCE(SUM(total_fat_g), 0) as total_fat_g,
    COALESCE(SUM(total_fiber_g), 0) as total_fiber_g
FROM nutrition_logs
GROUP BY patient_id, DATE(logged_at);

ALTER VIEW vw_daily_nutrition SET (security_invoker = on);
GRANT SELECT ON vw_daily_nutrition TO authenticated;

-- Weekly nutrition trend view
CREATE OR REPLACE VIEW vw_nutrition_trend AS
SELECT
    patient_id::text as patient_id,
    DATE_TRUNC('week', logged_at)::date as week_start,
    COUNT(DISTINCT DATE(logged_at)) as days_logged,
    COALESCE(AVG(daily.total_calories), 0) as avg_daily_calories,
    COALESCE(AVG(daily.total_protein_g), 0) as avg_daily_protein_g,
    COALESCE(AVG(daily.total_carbs_g), 0) as avg_daily_carbs_g,
    COALESCE(AVG(daily.total_fat_g), 0) as avg_daily_fat_g
FROM (
    SELECT
        patient_id,
        DATE(logged_at) as log_date,
        DATE_TRUNC('week', logged_at) as week_start,
        SUM(total_calories) as total_calories,
        SUM(total_protein_g) as total_protein_g,
        SUM(total_carbs_g) as total_carbs_g,
        SUM(total_fat_g) as total_fat_g
    FROM nutrition_logs
    GROUP BY patient_id, DATE(logged_at), DATE_TRUNC('week', logged_at)
) daily
GROUP BY patient_id, DATE_TRUNC('week', logged_at);

ALTER VIEW vw_nutrition_trend SET (security_invoker = on);
GRANT SELECT ON vw_nutrition_trend TO authenticated;

-- Goal progress view
CREATE OR REPLACE VIEW vw_nutrition_goal_progress AS
SELECT
    ng.patient_id::text as patient_id,
    ng.id::text as goal_id,
    ng.target_calories,
    ng.target_protein_g,
    ng.target_carbs_g,
    ng.target_fat_g,
    COALESCE(today.total_calories, 0) as consumed_calories,
    COALESCE(today.total_protein_g, 0) as consumed_protein_g,
    COALESCE(today.total_carbs_g, 0) as consumed_carbs_g,
    COALESCE(today.total_fat_g, 0) as consumed_fat_g,
    CASE WHEN ng.target_calories > 0
        THEN ROUND((COALESCE(today.total_calories, 0)::numeric / ng.target_calories) * 100, 1)
        ELSE 0
    END as calories_percent,
    CASE WHEN ng.target_protein_g > 0
        THEN ROUND((COALESCE(today.total_protein_g, 0) / ng.target_protein_g) * 100, 1)
        ELSE 0
    END as protein_percent
FROM nutrition_goals ng
LEFT JOIN (
    SELECT
        patient_id,
        SUM(total_calories) as total_calories,
        SUM(total_protein_g) as total_protein_g,
        SUM(total_carbs_g) as total_carbs_g,
        SUM(total_fat_g) as total_fat_g
    FROM nutrition_logs
    WHERE DATE(logged_at) = CURRENT_DATE
    GROUP BY patient_id
) today ON ng.patient_id = today.patient_id
WHERE ng.active = TRUE;

ALTER VIEW vw_nutrition_goal_progress SET (security_invoker = on);
GRANT SELECT ON vw_nutrition_goal_progress TO authenticated;

-- Macro distribution view (for pie charts)
CREATE OR REPLACE VIEW vw_macro_distribution AS
SELECT
    patient_id::text as patient_id,
    DATE(logged_at) as log_date,
    COALESCE(SUM(total_protein_g) * 4, 0) as protein_calories,
    COALESCE(SUM(total_carbs_g) * 4, 0) as carbs_calories,
    COALESCE(SUM(total_fat_g) * 9, 0) as fat_calories,
    CASE WHEN COALESCE(SUM(total_calories), 0) > 0 THEN
        ROUND((SUM(total_protein_g) * 4 / NULLIF(SUM(total_calories), 0)) * 100, 1)
    ELSE 0 END as protein_percent,
    CASE WHEN COALESCE(SUM(total_calories), 0) > 0 THEN
        ROUND((SUM(total_carbs_g) * 4 / NULLIF(SUM(total_calories), 0)) * 100, 1)
    ELSE 0 END as carbs_percent,
    CASE WHEN COALESCE(SUM(total_calories), 0) > 0 THEN
        ROUND((SUM(total_fat_g) * 9 / NULLIF(SUM(total_calories), 0)) * 100, 1)
    ELSE 0 END as fat_percent
FROM nutrition_logs
GROUP BY patient_id, DATE(logged_at);

ALTER VIEW vw_macro_distribution SET (security_invoker = on);
GRANT SELECT ON vw_macro_distribution TO authenticated;
