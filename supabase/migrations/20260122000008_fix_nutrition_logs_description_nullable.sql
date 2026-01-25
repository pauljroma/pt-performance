-- Migration: Fix nutrition_logs description column to be nullable
-- Description: Remove NOT NULL constraint from description column
-- Issue: 23502 - "null value in column \"description\" violates not-null constraint"

-- Make description column nullable (if it exists with NOT NULL)
ALTER TABLE nutrition_logs
    ALTER COLUMN description DROP NOT NULL;

-- Also ensure notes is nullable (backup check)
ALTER TABLE nutrition_logs
    ALTER COLUMN notes DROP NOT NULL;

-- Reload schema
NOTIFY pgrst, 'reload schema';
