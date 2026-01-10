-- BUILD 138 - Complete Schema Migration
-- Date: 2026-01-04 22:00:00
-- Purpose: Add ALL missing columns to fix integration test failures
-- Pass rate before: 29% (15/51 tests)
-- Expected after: 100% (51/51 tests)

-- ============================================================================
-- 1. EXERCISE_TEMPLATES: Add equipment_required column
-- ============================================================================
-- Error: column exercise_templates.equipment_required does not exist
-- Fix: Add TEXT[] column for equipment list

ALTER TABLE exercise_templates
ADD COLUMN IF NOT EXISTS equipment_required TEXT[];

COMMENT ON COLUMN exercise_templates.equipment_required IS
'Array of equipment needed for this exercise (e.g., ["barbell", "bench", "plates"])';

-- ============================================================================
-- 2. NUTRITION_LOGS: Add macro columns (protein, carbs, fats)
-- ============================================================================
-- Error: column nutrition_logs.protein does not exist (exists as protein_grams)
-- Error: column nutrition_logs.carbs does not exist (exists as carbs_grams)
-- Error: column nutrition_logs.fats does not exist (exists as fats_grams)
-- Fix: Add alias columns that map to existing _grams columns

-- Add new columns
ALTER TABLE nutrition_logs
ADD COLUMN IF NOT EXISTS protein NUMERIC;

ALTER TABLE nutrition_logs
ADD COLUMN IF NOT EXISTS carbs NUMERIC;

ALTER TABLE nutrition_logs
ADD COLUMN IF NOT EXISTS fats NUMERIC;

-- Backfill existing data from _grams columns
UPDATE nutrition_logs
SET
    protein = protein_grams,
    carbs = carbs_grams,
    fats = fats_grams
WHERE protein IS NULL OR carbs IS NULL OR fats IS NULL;

-- Create trigger to keep columns in sync
CREATE OR REPLACE FUNCTION sync_nutrition_macros()
RETURNS TRIGGER AS $$
BEGIN
    -- When new row is inserted or updated, sync both column sets
    IF NEW.protein IS NOT NULL THEN
        NEW.protein_grams = NEW.protein;
    END IF;

    IF NEW.carbs IS NOT NULL THEN
        NEW.carbs_grams = NEW.carbs;
    END IF;

    IF NEW.fats IS NOT NULL THEN
        NEW.fats_grams = NEW.fats;
    END IF;

    -- Also sync the reverse direction
    IF NEW.protein_grams IS NOT NULL AND NEW.protein IS NULL THEN
        NEW.protein = NEW.protein_grams;
    END IF;

    IF NEW.carbs_grams IS NOT NULL AND NEW.carbs IS NULL THEN
        NEW.carbs = NEW.carbs_grams;
    END IF;

    IF NEW.fats_grams IS NOT NULL AND NEW.fats IS NULL THEN
        NEW.fats = NEW.fats_grams;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_nutrition_macros_trigger ON nutrition_logs;
CREATE TRIGGER sync_nutrition_macros_trigger
    BEFORE INSERT OR UPDATE ON nutrition_logs
    FOR EACH ROW
    EXECUTE FUNCTION sync_nutrition_macros();

COMMENT ON COLUMN nutrition_logs.protein IS
'Protein in grams (synced with protein_grams for backward compatibility)';

COMMENT ON COLUMN nutrition_logs.carbs IS
'Carbohydrates in grams (synced with carbs_grams for backward compatibility)';

COMMENT ON COLUMN nutrition_logs.fats IS
'Fats in grams (synced with fats_grams for backward compatibility)';

-- ============================================================================
-- 3. NUTRITION_LOGS: Add logged_at column
-- ============================================================================
-- Error: column nutrition_logs.logged_at does not exist
-- Fix: Add TIMESTAMPTZ column (already added in previous migration, ensuring idempotency)

ALTER TABLE nutrition_logs
ADD COLUMN IF NOT EXISTS logged_at TIMESTAMPTZ;

-- Backfill logged_at from log_date for existing rows
UPDATE nutrition_logs
SET logged_at = log_date::timestamptz
WHERE logged_at IS NULL AND log_date IS NOT NULL;

-- Set default for new rows
ALTER TABLE nutrition_logs
ALTER COLUMN logged_at SET DEFAULT NOW();

COMMENT ON COLUMN nutrition_logs.logged_at IS
'Timestamp when nutrition was logged (populated from log_date for backward compatibility)';

-- ============================================================================
-- 4. PATIENTS: Add whoop_credentials column
-- ============================================================================
-- Error: column patients.whoop_credentials may not exist
-- Fix: Add JSONB column for WHOOP API credentials (already added in previous migration, ensuring idempotency)

ALTER TABLE patients
ADD COLUMN IF NOT EXISTS whoop_credentials JSONB;

COMMENT ON COLUMN patients.whoop_credentials IS
'JSONB containing WHOOP API credentials: {"access_token": "...", "refresh_token": "...", "expires_at": "..."}';

-- ============================================================================
-- 5. Update Helper Function to use new column names
-- ============================================================================
-- Update get_daily_nutrition_summary to work with both column sets

CREATE OR REPLACE FUNCTION get_daily_nutrition_summary(
    p_patient_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    total_calories INT,
    total_protein NUMERIC,
    total_carbs NUMERIC,
    total_fats NUMERIC,
    goal_calories INT,
    goal_protein NUMERIC,
    goal_carbs NUMERIC,
    goal_fats NUMERIC,
    calories_remaining INT,
    protein_remaining NUMERIC,
    carbs_remaining NUMERIC,
    fats_remaining NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(nl.calories), 0)::INT AS total_calories,
        -- Use new column names, fall back to old if needed
        COALESCE(SUM(COALESCE(nl.protein, nl.protein_grams)), 0) AS total_protein,
        COALESCE(SUM(COALESCE(nl.carbs, nl.carbs_grams)), 0) AS total_carbs,
        COALESCE(SUM(COALESCE(nl.fats, nl.fats_grams)), 0) AS total_fats,
        COALESCE(ng.target_calories, 2000) AS goal_calories,
        COALESCE(ng.target_protein, 150) AS goal_protein,
        COALESCE(ng.target_carbs, 200) AS goal_carbs,
        COALESCE(ng.target_fats, 65) AS goal_fats,
        (COALESCE(ng.target_calories, 2000) - COALESCE(SUM(nl.calories), 0))::INT AS calories_remaining,
        (COALESCE(ng.target_protein, 150) - COALESCE(SUM(COALESCE(nl.protein, nl.protein_grams)), 0)) AS protein_remaining,
        (COALESCE(ng.target_carbs, 200) - COALESCE(SUM(COALESCE(nl.carbs, nl.carbs_grams)), 0)) AS carbs_remaining,
        (COALESCE(ng.target_fats, 65) - COALESCE(SUM(COALESCE(nl.fats, nl.fats_grams)), 0)) AS fats_remaining
    FROM patients p
    LEFT JOIN nutrition_logs nl ON nl.patient_id = p.id
        AND (nl.logged_at::date = p_date OR nl.log_date = p_date)
    LEFT JOIN nutrition_goals ng ON ng.patient_id = p.id
    WHERE p.id = p_patient_id
    GROUP BY p.id, ng.target_calories, ng.target_protein, ng.target_carbs, ng.target_fats;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 6. Verify Schema Changes
-- ============================================================================

-- Verify exercise_templates.equipment_required exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'exercise_templates'
        AND column_name = 'equipment_required'
    ) THEN
        RAISE EXCEPTION 'exercise_templates.equipment_required was not created!';
    END IF;
END $$;

-- Verify nutrition_logs.protein exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_logs'
        AND column_name = 'protein'
    ) THEN
        RAISE EXCEPTION 'nutrition_logs.protein was not created!';
    END IF;
END $$;

-- Verify nutrition_logs.carbs exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_logs'
        AND column_name = 'carbs'
    ) THEN
        RAISE EXCEPTION 'nutrition_logs.carbs was not created!';
    END IF;
END $$;

-- Verify nutrition_logs.fats exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_logs'
        AND column_name = 'fats'
    ) THEN
        RAISE EXCEPTION 'nutrition_logs.fats was not created!';
    END IF;
END $$;

-- Verify nutrition_logs.logged_at exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_logs'
        AND column_name = 'logged_at'
    ) THEN
        RAISE EXCEPTION 'nutrition_logs.logged_at was not created!';
    END IF;
END $$;

-- Verify patients.whoop_credentials exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'patients'
        AND column_name = 'whoop_credentials'
    ) THEN
        RAISE EXCEPTION 'patients.whoop_credentials was not created!';
    END IF;
END $$;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMENT ON TABLE nutrition_logs IS
'BUILD 138: Updated to support both old column names (protein_grams, carbs_grams, fats_grams) and new column names (protein, carbs, fats) for backward compatibility';
