-- =============================================================================
-- Fix Migration: Complete exercise_explanations setup
-- Applies the view and triggers that failed in 20260201170002
-- =============================================================================

-- Create View Combining Exercise Templates with Explanations
-- Note: Removed 'description' column as it doesn't exist in exercise_templates
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

-- Create updated_at trigger function (if not exists)
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

-- Verification
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.views
        WHERE table_name = 'vw_exercise_with_explanation'
    ) THEN
        RAISE NOTICE 'SUCCESS: vw_exercise_with_explanation view created';
    ELSE
        RAISE WARNING 'FAILED: vw_exercise_with_explanation view not found';
    END IF;
END $$;
