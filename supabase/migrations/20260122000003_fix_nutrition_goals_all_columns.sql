-- Migration: Fix nutrition_goals table - ensure all columns exist
-- Description: Add all missing columns that iOS app expects
-- Issue: PGRST204 errors for start_date, protein_per_kg, etc.

-- Helper function to add column if not exists
DO $$
DECLARE
    col_exists BOOLEAN;
BEGIN
    -- Check and add goal_type
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'goal_type'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN goal_type TEXT DEFAULT 'daily' CHECK (goal_type IN ('daily', 'weekly'));
        RAISE NOTICE 'Added goal_type column';
    END IF;

    -- Check and add target_calories
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'target_calories'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN target_calories INT;
        RAISE NOTICE 'Added target_calories column';
    END IF;

    -- Check and add target_protein_g
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'target_protein_g'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN target_protein_g DOUBLE PRECISION;
        RAISE NOTICE 'Added target_protein_g column';
    END IF;

    -- Check and add target_carbs_g
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'target_carbs_g'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN target_carbs_g DOUBLE PRECISION;
        RAISE NOTICE 'Added target_carbs_g column';
    END IF;

    -- Check and add target_fat_g
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'target_fat_g'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN target_fat_g DOUBLE PRECISION;
        RAISE NOTICE 'Added target_fat_g column';
    END IF;

    -- Check and add target_fiber_g
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'target_fiber_g'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN target_fiber_g DOUBLE PRECISION;
        RAISE NOTICE 'Added target_fiber_g column';
    END IF;

    -- Check and add target_water_ml
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'target_water_ml'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN target_water_ml INT;
        RAISE NOTICE 'Added target_water_ml column';
    END IF;

    -- Check and add protein_per_kg
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'protein_per_kg'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN protein_per_kg DOUBLE PRECISION;
        RAISE NOTICE 'Added protein_per_kg column';
    END IF;

    -- Check and add active
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'active'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN active BOOLEAN DEFAULT TRUE;
        RAISE NOTICE 'Added active column';
    END IF;

    -- Check and add start_date
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'start_date'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN start_date DATE DEFAULT CURRENT_DATE;
        RAISE NOTICE 'Added start_date column';
    END IF;

    -- Check and add end_date
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'end_date'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN end_date DATE;
        RAISE NOTICE 'Added end_date column';
    END IF;

    -- Check and add notes
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'notes'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN notes TEXT;
        RAISE NOTICE 'Added notes column';
    END IF;

    -- Check and add created_by
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'created_by'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN created_by UUID;
        RAISE NOTICE 'Added created_by column';
    END IF;

    -- Check and add created_at
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'created_at'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added created_at column';
    END IF;

    -- Check and add updated_at
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals' AND column_name = 'updated_at'
    ) INTO col_exists;
    IF NOT col_exists THEN
        ALTER TABLE nutrition_goals ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column';
    END IF;
END $$;

-- Ensure start_date is NOT NULL with default
UPDATE nutrition_goals SET start_date = CURRENT_DATE WHERE start_date IS NULL;
ALTER TABLE nutrition_goals ALTER COLUMN start_date SET DEFAULT CURRENT_DATE;

-- Ensure goal_type is NOT NULL with default
UPDATE nutrition_goals SET goal_type = 'daily' WHERE goal_type IS NULL;
ALTER TABLE nutrition_goals ALTER COLUMN goal_type SET DEFAULT 'daily';

-- Ensure active has default
ALTER TABLE nutrition_goals ALTER COLUMN active SET DEFAULT TRUE;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';

-- Verify all columns exist
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'nutrition_goals'
ORDER BY ordinal_position;
