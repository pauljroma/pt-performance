-- Add 'crossfit' to the allowed categories for system_workout_templates

-- Drop and recreate the check constraint with crossfit added
ALTER TABLE system_workout_templates DROP CONSTRAINT IF EXISTS system_workout_templates_category_check;

ALTER TABLE system_workout_templates ADD CONSTRAINT system_workout_templates_category_check
  CHECK (category IN ('strength', 'mobility', 'cardio', 'hybrid', 'full_body', 'upper', 'lower', 'crossfit'));

-- Update the CrossFit templates we just inserted to use the proper category
UPDATE system_workout_templates
SET category = 'crossfit'
WHERE 'crossfit' = ANY(tags);
