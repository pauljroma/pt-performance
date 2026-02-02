-- Migration: Exercise Explanations and Enhanced Content
-- Sprint: Content & Polish
-- Purpose: Add "Why This Exercise" rationale, target muscles, difficulty progression, and related exercises

-- =============================================================================
-- 1. Add explanation columns to exercise_templates
-- =============================================================================
ALTER TABLE exercise_templates
ADD COLUMN IF NOT EXISTS why_this_exercise TEXT,
ADD COLUMN IF NOT EXISTS target_muscles TEXT[],
ADD COLUMN IF NOT EXISTS secondary_muscles TEXT[],
ADD COLUMN IF NOT EXISTS difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
ADD COLUMN IF NOT EXISTS prerequisites TEXT[],
ADD COLUMN IF NOT EXISTS progression_exercises UUID[],
ADD COLUMN IF NOT EXISTS substitute_exercises UUID[];

-- Add comments for documentation
COMMENT ON COLUMN exercise_templates.why_this_exercise IS 'General rationale explaining why this exercise is effective and beneficial';
COMMENT ON COLUMN exercise_templates.target_muscles IS 'Primary muscles targeted by this exercise';
COMMENT ON COLUMN exercise_templates.secondary_muscles IS 'Secondary/supporting muscles worked during this exercise';
COMMENT ON COLUMN exercise_templates.difficulty_level IS 'Exercise difficulty: 1=Beginner, 2=Novice, 3=Intermediate, 4=Advanced, 5=Expert';
COMMENT ON COLUMN exercise_templates.prerequisites IS 'Exercises or skills that should be mastered before attempting this exercise';
COMMENT ON COLUMN exercise_templates.progression_exercises IS 'UUIDs of more advanced exercises to progress to';
COMMENT ON COLUMN exercise_templates.substitute_exercises IS 'UUIDs of exercises that can substitute for this one';

-- =============================================================================
-- 2. Create exercise_explanations table for context-specific rationale
-- =============================================================================
CREATE TABLE IF NOT EXISTS exercise_explanations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_template_id UUID REFERENCES exercise_templates(id) NOT NULL,
    program_id UUID REFERENCES programs(id),  -- Optional: context-specific explanation

    -- Core explanation content
    why_included TEXT NOT NULL,               -- Why this exercise is in this program
    what_it_targets TEXT,                     -- What muscles/movements it targets
    how_it_helps TEXT,                        -- How it helps the patient's goals
    when_to_feel_it TEXT,                     -- Where patient should feel the exercise

    -- Progress indicators
    signs_of_progress TEXT[],                 -- What improvement looks like
    warning_signs TEXT[],                     -- When to stop or modify

    -- Modifications
    easier_variation TEXT,
    harder_variation TEXT,
    equipment_alternatives TEXT,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(exercise_template_id, program_id)
);

-- Add comments for exercise_explanations
COMMENT ON TABLE exercise_explanations IS 'Context-specific exercise explanations, optionally tied to a program';
COMMENT ON COLUMN exercise_explanations.why_included IS 'Explanation of why this exercise is included in the program context';
COMMENT ON COLUMN exercise_explanations.what_it_targets IS 'Description of targeted muscles and movement patterns';
COMMENT ON COLUMN exercise_explanations.how_it_helps IS 'How this exercise contributes to patient goals';
COMMENT ON COLUMN exercise_explanations.when_to_feel_it IS 'Where the patient should feel the exercise working';
COMMENT ON COLUMN exercise_explanations.signs_of_progress IS 'Indicators of improvement to look for';
COMMENT ON COLUMN exercise_explanations.warning_signs IS 'Signs that indicate the exercise should be stopped or modified';

-- =============================================================================
-- 3. Create arm_care_education table for educational content
-- =============================================================================
CREATE TABLE IF NOT EXISTS arm_care_education (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Content organization
    category TEXT NOT NULL CHECK (category IN ('anatomy', 'injury_prevention', 'recovery', 'technique', 'programming')),
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,

    -- Content
    summary TEXT NOT NULL,
    content TEXT NOT NULL,                    -- Markdown content
    key_points TEXT[],

    -- Media
    featured_image_url TEXT,
    video_url TEXT,

    -- Related content
    related_exercises UUID[],                 -- Links to exercise_templates
    related_articles UUID[],                  -- Links to other arm_care_education

    -- Organization
    sort_order INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    is_published BOOLEAN DEFAULT true,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comments for arm_care_education
COMMENT ON TABLE arm_care_education IS 'Educational content for arm care and injury prevention';
COMMENT ON COLUMN arm_care_education.category IS 'Content category: anatomy, injury_prevention, recovery, technique, or programming';
COMMENT ON COLUMN arm_care_education.slug IS 'URL-friendly unique identifier for the article';
COMMENT ON COLUMN arm_care_education.content IS 'Full article content in Markdown format';
COMMENT ON COLUMN arm_care_education.related_exercises IS 'UUIDs of related exercise templates';
COMMENT ON COLUMN arm_care_education.related_articles IS 'UUIDs of related arm_care_education articles';

-- =============================================================================
-- 4. Enable Row Level Security
-- =============================================================================
ALTER TABLE exercise_explanations ENABLE ROW LEVEL SECURITY;
ALTER TABLE arm_care_education ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 5. Create RLS Policies
-- =============================================================================

-- Exercise explanations readable by all authenticated users
CREATE POLICY "Exercise explanations readable by authenticated users"
ON exercise_explanations FOR SELECT
TO authenticated
USING (true);

-- Arm care education readable by all authenticated users
CREATE POLICY "Arm care education readable by authenticated users"
ON arm_care_education FOR SELECT
TO authenticated
USING (true);

-- =============================================================================
-- 6. Create Indexes for Performance
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_explanations_exercise ON exercise_explanations(exercise_template_id);
CREATE INDEX IF NOT EXISTS idx_explanations_program ON exercise_explanations(program_id);
CREATE INDEX IF NOT EXISTS idx_arm_care_category ON arm_care_education(category);
CREATE INDEX IF NOT EXISTS idx_arm_care_slug ON arm_care_education(slug);
CREATE INDEX IF NOT EXISTS idx_arm_care_featured ON arm_care_education(is_featured) WHERE is_featured = true;

-- Indexes for new exercise_templates columns
CREATE INDEX IF NOT EXISTS idx_exercise_templates_difficulty ON exercise_templates(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_exercise_templates_target_muscles ON exercise_templates USING GIN(target_muscles);

-- =============================================================================
-- 7. Create View Combining Exercise Templates with Explanations
-- =============================================================================
CREATE OR REPLACE VIEW vw_exercise_with_explanation AS
SELECT
    et.id,
    et.name,
    et.category,
    et.equipment_required,
    et.technique_cues,
    et.common_mistakes,
    et.safety_notes,
    et.why_this_exercise,
    et.target_muscles,
    et.secondary_muscles,
    et.difficulty_level,
    ee.why_included,
    ee.what_it_targets,
    ee.how_it_helps,
    ee.when_to_feel_it,
    ee.signs_of_progress,
    ee.warning_signs,
    ee.easier_variation,
    ee.harder_variation,
    ee.equipment_alternatives,
    ee.program_id
FROM exercise_templates et
LEFT JOIN exercise_explanations ee ON et.id = ee.exercise_template_id;

-- Grant access to view
GRANT SELECT ON vw_exercise_with_explanation TO authenticated;

-- =============================================================================
-- 8. Create updated_at trigger for new tables
-- =============================================================================

-- Function to update updated_at timestamp (create if not exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for exercise_explanations
DROP TRIGGER IF EXISTS update_exercise_explanations_updated_at ON exercise_explanations;
CREATE TRIGGER update_exercise_explanations_updated_at
    BEFORE UPDATE ON exercise_explanations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for arm_care_education
DROP TRIGGER IF EXISTS update_arm_care_education_updated_at ON arm_care_education;
CREATE TRIGGER update_arm_care_education_updated_at
    BEFORE UPDATE ON arm_care_education
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 9. Verification
-- =============================================================================
DO $$
BEGIN
    -- Verify new columns exist on exercise_templates
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'exercise_templates'
        AND column_name = 'why_this_exercise'
    ) THEN
        RAISE NOTICE 'SUCCESS: exercise_templates.why_this_exercise column exists';
    ELSE
        RAISE WARNING 'MISSING: exercise_templates.why_this_exercise column';
    END IF;

    -- Verify exercise_explanations table exists
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'exercise_explanations'
    ) THEN
        RAISE NOTICE 'SUCCESS: exercise_explanations table exists';
    ELSE
        RAISE WARNING 'MISSING: exercise_explanations table';
    END IF;

    -- Verify arm_care_education table exists
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'arm_care_education'
    ) THEN
        RAISE NOTICE 'SUCCESS: arm_care_education table exists';
    ELSE
        RAISE WARNING 'MISSING: arm_care_education table';
    END IF;

    -- Verify view exists
    IF EXISTS (
        SELECT 1 FROM information_schema.views
        WHERE table_name = 'vw_exercise_with_explanation'
    ) THEN
        RAISE NOTICE 'SUCCESS: vw_exercise_with_explanation view exists';
    ELSE
        RAISE WARNING 'MISSING: vw_exercise_with_explanation view';
    END IF;
END $$;
