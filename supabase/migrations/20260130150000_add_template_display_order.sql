-- BUILD 331: Add display_order column for template ordering
-- Problem: Templates display alphabetically instead of intended sequence order
-- Solution: Add display_order column to control sort order

-- Add display_order column
ALTER TABLE system_workout_templates
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;

-- Add index for efficient ordering
CREATE INDEX IF NOT EXISTS idx_templates_display_order
ON system_workout_templates(category, display_order);

-- Update existing templates with default ordering by created_at
-- This preserves the original entry order
UPDATE system_workout_templates
SET display_order = sub.row_num
FROM (
  SELECT id, ROW_NUMBER() OVER (PARTITION BY category ORDER BY created_at) as row_num
  FROM system_workout_templates
) sub
WHERE system_workout_templates.id = sub.id
  AND system_workout_templates.display_order = 0;

-- Verify the update
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM system_workout_templates
    WHERE display_order > 0;

    IF updated_count = 0 THEN
        RAISE WARNING 'display_order update may have failed - no templates with display_order > 0';
    ELSE
        RAISE NOTICE 'Successfully added display_order to % templates', updated_count;
    END IF;
END $$;
