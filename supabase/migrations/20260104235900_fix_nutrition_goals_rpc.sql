-- BUILD 138 - Fix nutrition_goals Column Names in RPC
-- Date: 2026-01-04 23:59:00
-- Purpose: Fix get_daily_nutrition_summary RPC to use correct column names

-- Drop existing function
DROP FUNCTION IF EXISTS get_daily_nutrition_summary(uuid, date);

-- Recreate with CORRECT column references (daily_protein_grams not protein_grams)
CREATE OR REPLACE FUNCTION get_daily_nutrition_summary(
    p_patient_id UUID,
    p_date DATE
)
RETURNS TABLE (
    total_calories NUMERIC,
    total_protein NUMERIC,
    total_carbs NUMERIC,
    total_fats NUMERIC,
    goal_calories INTEGER,
    goal_protein NUMERIC,
    goal_carbs NUMERIC,
    goal_fats NUMERIC,
    calories_remaining NUMERIC,
    protein_remaining NUMERIC,
    carbs_remaining NUMERIC,
    fats_remaining NUMERIC
) AS $$
DECLARE
    v_goal_calories INTEGER := 2000;
    v_goal_protein NUMERIC := 150;
    v_goal_carbs NUMERIC := 200;
    v_goal_fats NUMERIC := 65;
BEGIN
    -- Get patient's nutrition goals if they exist
    -- CRITICAL: Use daily_protein_grams not protein_grams
    SELECT
        COALESCE(ng.daily_calories, 2000),
        COALESCE(ng.daily_protein_grams, 150),
        COALESCE(ng.daily_carbs_grams, 200),
        COALESCE(ng.daily_fats_grams, 65)
    INTO
        v_goal_calories,
        v_goal_protein,
        v_goal_carbs,
        v_goal_fats
    FROM nutrition_goals ng
    WHERE ng.patient_id = p_patient_id
    ORDER BY ng.created_at DESC
    LIMIT 1;

    -- Calculate totals from nutrition_logs for the specified date
    -- Use logged_at instead of created_at for date filtering
    RETURN QUERY
    SELECT
        COALESCE(SUM(nl.calories), 0)::NUMERIC as total_calories,
        COALESCE(SUM(nl.protein_grams), 0)::NUMERIC as total_protein,
        COALESCE(SUM(nl.carbs_grams), 0)::NUMERIC as total_carbs,
        COALESCE(SUM(nl.fats_grams), 0)::NUMERIC as total_fats,
        v_goal_calories as goal_calories,
        v_goal_protein as goal_protein,
        v_goal_carbs as goal_carbs,
        v_goal_fats as goal_fats,
        (v_goal_calories - COALESCE(SUM(nl.calories), 0))::NUMERIC as calories_remaining,
        (v_goal_protein - COALESCE(SUM(nl.protein_grams), 0))::NUMERIC as protein_remaining,
        (v_goal_carbs - COALESCE(SUM(nl.carbs_grams), 0))::NUMERIC as carbs_remaining,
        (v_goal_fats - COALESCE(SUM(nl.fats_grams), 0))::NUMERIC as fats_remaining
    FROM nutrition_logs nl
    WHERE nl.patient_id = p_patient_id
      AND DATE(nl.logged_at) = p_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to service role and authenticated users
GRANT EXECUTE ON FUNCTION get_daily_nutrition_summary(uuid, date) TO service_role;
GRANT EXECUTE ON FUNCTION get_daily_nutrition_summary(uuid, date) TO authenticated;

-- Verification
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc
        WHERE proname = 'get_daily_nutrition_summary'
    ) THEN
        RAISE NOTICE '✓ get_daily_nutrition_summary() RPC function recreated with correct column names';
    ELSE
        RAISE WARNING '✗ Failed to create get_daily_nutrition_summary() RPC function';
    END IF;
END $$;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
