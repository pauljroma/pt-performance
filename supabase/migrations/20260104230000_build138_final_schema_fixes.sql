-- BUILD 138 - Final Schema Fixes
-- Date: 2026-01-04 23:00:00
-- Purpose: Add all missing columns required by BUILD 138 Edge Functions
-- This migration is idempotent and can be run multiple times safely

-- =====================================================
-- Fix 1: Add equipment_required to exercise_templates
-- =====================================================
-- This column is queried by ai-exercise-substitution Edge Function
-- Query: exercise_templates!inner(name, equipment_required)

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'exercise_templates'
        AND column_name = 'equipment_required'
    ) THEN
        ALTER TABLE exercise_templates
        ADD COLUMN equipment_required TEXT[];

        RAISE NOTICE 'Added equipment_required column to exercise_templates';
    ELSE
        RAISE NOTICE 'equipment_required column already exists in exercise_templates';
    END IF;
END $$;

-- =====================================================
-- Fix 2: Add logged_at to nutrition_logs
-- =====================================================
-- This column is used by get_daily_nutrition_summary() RPC function

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_logs'
        AND column_name = 'logged_at'
    ) THEN
        ALTER TABLE nutrition_logs
        ADD COLUMN logged_at TIMESTAMPTZ DEFAULT NOW();

        -- Backfill existing rows with created_at if they have it
        UPDATE nutrition_logs
        SET logged_at = created_at
        WHERE logged_at IS NULL AND created_at IS NOT NULL;

        RAISE NOTICE 'Added logged_at column to nutrition_logs';
    ELSE
        RAISE NOTICE 'logged_at column already exists in nutrition_logs';
    END IF;
END $$;

-- =====================================================
-- Fix 3: Add whoop_credentials to patients table
-- =====================================================
-- This column is queried by sync-whoop-recovery Edge Function

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'patients'
        AND column_name = 'whoop_credentials'
    ) THEN
        ALTER TABLE patients
        ADD COLUMN whoop_credentials JSONB;

        RAISE NOTICE 'Added whoop_credentials column to patients';
    ELSE
        RAISE NOTICE 'whoop_credentials column already exists in patients';
    END IF;
END $$;

-- =====================================================
-- Fix 4: Update get_daily_nutrition_summary RPC if it exists
-- =====================================================
-- The RPC function expects nutrition_logs to have certain column names
-- We need to ensure it uses the correct column names

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_daily_nutrition_summary(uuid, date);

-- Recreate with correct column references
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
    SELECT
        COALESCE(ng.daily_calories, 2000),
        COALESCE(ng.protein_grams, 150),
        COALESCE(ng.carbs_grams, 200),
        COALESCE(ng.fats_grams, 65)
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

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION get_daily_nutrition_summary(uuid, date) TO service_role;
GRANT EXECUTE ON FUNCTION get_daily_nutrition_summary(uuid, date) TO authenticated;

-- =====================================================
-- Verification queries
-- =====================================================
-- Run these to verify the migration succeeded

-- Check exercise_templates.equipment_required
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'exercise_templates'
        AND column_name = 'equipment_required'
    ) THEN
        RAISE NOTICE '✓ exercise_templates.equipment_required exists';
    ELSE
        RAISE WARNING '✗ exercise_templates.equipment_required is missing';
    END IF;
END $$;

-- Check nutrition_logs.logged_at
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_logs'
        AND column_name = 'logged_at'
    ) THEN
        RAISE NOTICE '✓ nutrition_logs.logged_at exists';
    ELSE
        RAISE WARNING '✗ nutrition_logs.logged_at is missing';
    END IF;
END $$;

-- Check patients.whoop_credentials
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'patients'
        AND column_name = 'whoop_credentials'
    ) THEN
        RAISE NOTICE '✓ patients.whoop_credentials exists';
    ELSE
        RAISE WARNING '✗ patients.whoop_credentials is missing';
    END IF;
END $$;

-- Check RPC function exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc
        WHERE proname = 'get_daily_nutrition_summary'
    ) THEN
        RAISE NOTICE '✓ get_daily_nutrition_summary() RPC function exists';
    ELSE
        RAISE WARNING '✗ get_daily_nutrition_summary() RPC function is missing';
    END IF;
END $$;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';

-- Migration complete
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'BUILD 138 Final Schema Fixes - COMPLETE';
    RAISE NOTICE '========================================';
END $$;
