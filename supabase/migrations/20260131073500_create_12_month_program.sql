-- BUILD 340: Create 12-Month Performance Program from date-labeled workouts
-- Organizes 184 date-labeled workouts (Jan 2018 - May 2019) into a structured program

-- ============================================================================
-- 0. Schema updates for system/template programs
-- ============================================================================

-- Make patient_id nullable for system/template programs
ALTER TABLE programs ALTER COLUMN patient_id DROP NOT NULL;

COMMENT ON COLUMN programs.patient_id IS 'Patient who owns this program. NULL for system/template programs.';

-- Add metadata column if not exists
ALTER TABLE programs ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

COMMENT ON COLUMN programs.metadata IS 'Flexible JSONB for program metadata (duration_weeks, is_system_template, etc.)';

-- Add duration_weeks and goals columns to phases
ALTER TABLE phases ADD COLUMN IF NOT EXISTS duration_weeks INT;
ALTER TABLE phases ADD COLUMN IF NOT EXISTS goals TEXT;
ALTER TABLE phases ADD COLUMN IF NOT EXISTS constraints JSONB DEFAULT '{}';

COMMENT ON COLUMN phases.duration_weeks IS 'Duration of this phase in weeks';
COMMENT ON COLUMN phases.goals IS 'Primary goals for this phase';
COMMENT ON COLUMN phases.constraints IS 'Any constraints or limitations for this phase';

-- ============================================================================
-- 1. Create program_workout_assignments table (links templates to programs)
-- ============================================================================

CREATE TABLE IF NOT EXISTS program_workout_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    template_id UUID NOT NULL REFERENCES system_workout_templates(id) ON DELETE CASCADE,
    phase_id UUID REFERENCES phases(id) ON DELETE SET NULL,
    week_number INT NOT NULL CHECK (week_number > 0 AND week_number <= 52),
    day_of_week INT NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 7), -- 1=Mon, 7=Sun
    sequence INT NOT NULL, -- Global sequence within program (1-184)
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(program_id, sequence),
    UNIQUE(program_id, week_number, day_of_week)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_pwa_program_week ON program_workout_assignments(program_id, week_number);
CREATE INDEX IF NOT EXISTS idx_pwa_template ON program_workout_assignments(template_id);
CREATE INDEX IF NOT EXISTS idx_pwa_phase ON program_workout_assignments(phase_id);

COMMENT ON TABLE program_workout_assignments IS 'Links system workout templates to programs with week/day scheduling';

-- RLS policies
ALTER TABLE program_workout_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view program workout assignments"
    ON program_workout_assignments FOR SELECT
    USING (true);

-- ============================================================================
-- 2. Create the 12-Month Performance Program
-- ============================================================================

DO $$
DECLARE
    v_program_id UUID;
    v_phase1_id UUID;
    v_phase2_id UUID;
    v_phase3_id UUID;
    v_phase4_id UUID;
    v_phase5_id UUID;
    v_phase6_id UUID;
    v_library_id UUID;
    v_template RECORD;
    v_sequence INT := 0;
    v_week INT;
    v_day INT;
    v_current_phase_id UUID;
BEGIN
    -- Create the program (patient_id NULL for system template)
    INSERT INTO programs (
        id,
        patient_id,
        name,
        description,
        status,
        metadata
    ) VALUES (
        gen_random_uuid(),
        NULL,  -- System template, not patient-specific
        '12-Month Performance Program',
        'Comprehensive 48-week periodized training program featuring 184 structured workouts. Progresses through Foundation, Strength, Power, Peak Performance, Hypertrophy, and Active Recovery phases.',
        'active',
        jsonb_build_object(
            'duration_weeks', 48,
            'workouts_per_week', 4,
            'total_workouts', 184,
            'source', 'date_labeled_templates_2018_2019',
            'periodization_model', 'block_periodization',
            'is_system_template', true
        )
    ) RETURNING id INTO v_program_id;

    RAISE NOTICE 'Created program: %', v_program_id;

    -- Create Phase 1: Foundation (Weeks 1-8)
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (
        gen_random_uuid(), v_program_id, 'Foundation', 1, 8,
        'Build movement quality and base strength',
        'Focus: Movement quality, mobility, work capacity. Intensity: Low-Moderate. Volume: High.'
    ) RETURNING id INTO v_phase1_id;

    -- Create Phase 2: Strength (Weeks 9-16)
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (
        gen_random_uuid(), v_program_id, 'Strength', 2, 8,
        'Develop maximal strength and power foundation',
        'Focus: Max strength, power development. Intensity: Moderate-High. Volume: Moderate.'
    ) RETURNING id INTO v_phase2_id;

    -- Create Phase 3: Power/Speed (Weeks 17-24)
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (
        gen_random_uuid(), v_program_id, 'Power/Speed', 3, 8,
        'Express strength as explosive power and speed',
        'Focus: Explosive power, sport-specific conditioning. Intensity: High. Volume: Low-Moderate.'
    ) RETURNING id INTO v_phase3_id;

    -- Create Phase 4: Peak/Maintain (Weeks 25-32)
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (
        gen_random_uuid(), v_program_id, 'Peak/Maintain', 4, 8,
        'Peak performance and skill refinement',
        'Focus: Performance, skill work, competition prep. Intensity: Variable. Volume: Moderate.'
    ) RETURNING id INTO v_phase4_id;

    -- Create Phase 5: Hypertrophy (Weeks 33-40)
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (
        gen_random_uuid(), v_program_id, 'Hypertrophy', 5, 8,
        'Build muscle mass and strength-endurance',
        'Focus: Muscle building, strength-endurance. Intensity: Moderate. Volume: High.'
    ) RETURNING id INTO v_phase5_id;

    -- Create Phase 6: Active Recovery (Weeks 41-48)
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (
        gen_random_uuid(), v_program_id, 'Active Recovery', 6, 8,
        'Recovery, restoration, and preparation for next cycle',
        'Focus: Recovery, mobility, light conditioning. Intensity: Low. Volume: Low.'
    ) RETURNING id INTO v_phase6_id;

    RAISE NOTICE 'Created 6 phases';

    -- ============================================================================
    -- 3. Assign date-labeled workouts in chronological order
    -- ============================================================================

    -- Loop through date-labeled templates in chronological order
    -- Names are formatted as "Month Day, Year" (e.g., "January 2, 2018")
    FOR v_template IN
        SELECT id, name
        FROM system_workout_templates
        WHERE name ~ '^(January|February|March|April|May|June|July|August|September|October|November|December) \d{1,2}, \d{4}$'
        ORDER BY
            -- Parse the date from the name for proper ordering
            TO_DATE(name, 'Month DD, YYYY') ASC
    LOOP
        v_sequence := v_sequence + 1;

        -- Calculate week number (4 workouts per week, so week = ceil(sequence/4))
        v_week := CEIL(v_sequence::DECIMAL / 4);

        -- Calculate day of week (cycle through Mon=1, Tue=2, Thu=4, Sat=6)
        v_day := CASE ((v_sequence - 1) % 4)
            WHEN 0 THEN 1  -- Monday
            WHEN 1 THEN 2  -- Tuesday
            WHEN 2 THEN 4  -- Thursday
            WHEN 3 THEN 6  -- Saturday
        END;

        -- Determine which phase based on week number
        v_current_phase_id := CASE
            WHEN v_week <= 8 THEN v_phase1_id
            WHEN v_week <= 16 THEN v_phase2_id
            WHEN v_week <= 24 THEN v_phase3_id
            WHEN v_week <= 32 THEN v_phase4_id
            WHEN v_week <= 40 THEN v_phase5_id
            ELSE v_phase6_id
        END;

        -- Insert the assignment
        INSERT INTO program_workout_assignments (
            program_id,
            template_id,
            phase_id,
            week_number,
            day_of_week,
            sequence
        ) VALUES (
            v_program_id,
            v_template.id,
            v_current_phase_id,
            v_week,
            v_day,
            v_sequence
        );
    END LOOP;

    RAISE NOTICE 'Assigned % workouts to program', v_sequence;

    -- ============================================================================
    -- 4. Create program_library entry for consumer visibility
    -- ============================================================================

    INSERT INTO program_library (
        id,
        title,
        description,
        category,
        duration_weeks,
        difficulty_level,
        equipment_required,
        program_id,
        is_featured,
        tags,
        author
    ) VALUES (
        gen_random_uuid(),
        '12-Month Performance Program',
        'Complete 48-week periodized training program with 184 structured workouts. Progress through 6 distinct phases: Foundation, Strength, Power/Speed, Peak Performance, Hypertrophy, and Active Recovery. Perfect for athletes looking to build year-round fitness with systematic progression.',
        'performance',
        48,
        'intermediate',
        ARRAY['barbell', 'dumbbells', 'kettlebell', 'pull-up bar', 'resistance bands'],
        v_program_id,
        true,
        ARRAY['periodization', 'year-round', 'athletic', 'strength', 'conditioning', 'comprehensive'],
        'PT Performance'
    ) RETURNING id INTO v_library_id;

    RAISE NOTICE 'Created program_library entry: %', v_library_id;
    RAISE NOTICE 'Successfully created 12-Month Performance Program with % workouts across 6 phases', v_sequence;
END $$;

-- ============================================================================
-- 5. Update display_order on system_workout_templates to match program sequence
-- ============================================================================

-- Update display_order to match chronological sequence for date-labeled workouts
WITH ordered_templates AS (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY TO_DATE(name, 'Month DD, YYYY')) as new_order
    FROM system_workout_templates
    WHERE name ~ '^(January|February|March|April|May|June|July|August|September|October|November|December) \d{1,2}, \d{4}$'
)
UPDATE system_workout_templates st
SET display_order = ot.new_order
FROM ordered_templates ot
WHERE st.id = ot.id;

-- ============================================================================
-- 6. Create helper function to get program schedule
-- ============================================================================

CREATE OR REPLACE FUNCTION get_program_schedule(
    p_program_id UUID,
    p_week_number INT DEFAULT NULL
)
RETURNS TABLE (
    assignment_id UUID,
    week_number INT,
    day_of_week INT,
    day_name TEXT,
    sequence INT,
    phase_name TEXT,
    template_id UUID,
    template_name TEXT,
    template_category TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pwa.id AS assignment_id,
        pwa.week_number,
        pwa.day_of_week,
        CASE pwa.day_of_week
            WHEN 1 THEN 'Monday'
            WHEN 2 THEN 'Tuesday'
            WHEN 3 THEN 'Wednesday'
            WHEN 4 THEN 'Thursday'
            WHEN 5 THEN 'Friday'
            WHEN 6 THEN 'Saturday'
            WHEN 7 THEN 'Sunday'
        END AS day_name,
        pwa.sequence,
        ph.name AS phase_name,
        swt.id AS template_id,
        swt.name AS template_name,
        swt.category AS template_category
    FROM program_workout_assignments pwa
    JOIN system_workout_templates swt ON swt.id = pwa.template_id
    LEFT JOIN phases ph ON ph.id = pwa.phase_id
    WHERE pwa.program_id = p_program_id
    AND (p_week_number IS NULL OR pwa.week_number = p_week_number)
    ORDER BY pwa.sequence;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_program_schedule IS 'Get workout schedule for a program, optionally filtered by week';
