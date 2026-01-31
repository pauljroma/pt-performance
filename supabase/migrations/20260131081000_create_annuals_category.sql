-- BUILD 340: Create "Annuals" category and rename program to "Foundation"

-- Update the program name
UPDATE programs
SET name = 'Foundation',
    description = 'Comprehensive 48-week periodized training program with 181 structured workouts. Build a solid athletic foundation through 6 progressive phases: Foundation, Strength, Power, Peak Performance, Hypertrophy, and Active Recovery.'
WHERE name = '12-Month Performance Program';

-- Update the program_library entry
UPDATE program_library
SET
    title = 'Foundation',
    category = 'annuals',
    description = 'Complete 48-week periodized training program with 181 structured workouts. Build a solid athletic foundation through progressive phases focusing on movement quality, strength development, power expression, and strategic recovery. Perfect for athletes committed to year-round systematic training.',
    tags = ARRAY['annual', 'periodization', 'year-round', 'athletic', 'strength', 'conditioning', 'comprehensive', 'foundation']
WHERE title = '12-Month Performance Program';

-- Verify
DO $$
DECLARE
    v_program_name TEXT;
    v_library_category TEXT;
BEGIN
    SELECT name INTO v_program_name FROM programs WHERE name = 'Foundation';
    SELECT category INTO v_library_category FROM program_library WHERE title = 'Foundation';

    RAISE NOTICE 'Program renamed to: %', v_program_name;
    RAISE NOTICE 'Program library category: %', v_library_category;
END $$;
