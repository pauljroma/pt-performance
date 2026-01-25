-- Migration: Fix nutrition_goals goal_type column
-- Description: Ensure goal_type column exists and has correct constraints
-- Issue: PGRST204 error - 'goal_type' column not found in schema cache

-- Add goal_type column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals'
        AND column_name = 'goal_type'
    ) THEN
        ALTER TABLE nutrition_goals
        ADD COLUMN goal_type TEXT DEFAULT 'daily'
        CHECK (goal_type IN ('daily', 'weekly'));

        RAISE NOTICE 'Added goal_type column to nutrition_goals';
    ELSE
        RAISE NOTICE 'goal_type column already exists in nutrition_goals';
    END IF;
END $$;

-- Make sure the column is NOT NULL with default
-- This is safe because we added a DEFAULT above
ALTER TABLE nutrition_goals
    ALTER COLUMN goal_type SET DEFAULT 'daily';

-- Update any NULL values to 'daily'
UPDATE nutrition_goals
SET goal_type = 'daily'
WHERE goal_type IS NULL;

-- Now make it NOT NULL if not already
DO $$
BEGIN
    -- Check if column is nullable and make it NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_goals'
        AND column_name = 'goal_type'
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE nutrition_goals
        ALTER COLUMN goal_type SET NOT NULL;

        RAISE NOTICE 'Made goal_type NOT NULL';
    END IF;
END $$;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';

-- Verify the column exists
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'nutrition_goals'
AND column_name = 'goal_type';
