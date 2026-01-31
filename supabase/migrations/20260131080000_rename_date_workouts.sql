-- BUILD 340: Rename date-labeled workouts to program-based names
-- Changes "January 2, 2018" → "Foundation - Week 1, Day 1"

-- Update system_workout_templates names based on program_workout_assignments
UPDATE system_workout_templates swt
SET name =
    CASE
        WHEN pwa.week_number <= 8 THEN 'Foundation'
        WHEN pwa.week_number <= 16 THEN 'Strength'
        WHEN pwa.week_number <= 24 THEN 'Power'
        WHEN pwa.week_number <= 32 THEN 'Peak'
        WHEN pwa.week_number <= 40 THEN 'Hypertrophy'
        ELSE 'Recovery'
    END
    || ' - Week ' || pwa.week_number || ', Day ' ||
    CASE pwa.day_of_week
        WHEN 1 THEN '1'
        WHEN 2 THEN '2'
        WHEN 4 THEN '3'
        WHEN 6 THEN '4'
    END
FROM program_workout_assignments pwa
WHERE pwa.template_id = swt.id
AND swt.name ~ '^(January|February|March|April|May|June|July|August|September|October|November|December) \d{1,2}, \d{4}$';

-- Verify the rename
DO $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM system_workout_templates
    WHERE name LIKE 'Foundation -%'
       OR name LIKE 'Strength -%'
       OR name LIKE 'Power -%'
       OR name LIKE 'Peak -%'
       OR name LIKE 'Hypertrophy -%'
       OR name LIKE 'Recovery -%';

    RAISE NOTICE 'Renamed % workouts to program-based names', v_count;
END $$;
