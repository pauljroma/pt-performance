-- Migration: Fix meal_plan_items day_of_week null values
-- Description: Set day_of_week for existing items based on created_at
-- Issue: Meals created before Build 241 have null day_of_week

-- Update existing meal_plan_items with null day_of_week
-- Set them to the day of week when they were created
UPDATE meal_plan_items
SET day_of_week = EXTRACT(DOW FROM created_at)::INT
WHERE day_of_week IS NULL;

-- Log how many were updated
DO $$
DECLARE
    updated_count INT;
BEGIN
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % meal_plan_items with day_of_week', updated_count;
END $$;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
