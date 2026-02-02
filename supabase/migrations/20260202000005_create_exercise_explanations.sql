-- Migration: ACP-816 - "Why This Exercise" Baseball-Specific Explanations
-- Purpose: Add baseball-specific fields to exercise_explanations table
-- Sprint: Content & Polish

-- =============================================================================
-- 1. Add Baseball-Specific Fields to exercise_explanations
-- =============================================================================

-- Add baseball-specific columns if they don't exist
ALTER TABLE exercise_explanations
ADD COLUMN IF NOT EXISTS baseball_benefit TEXT,           -- "Improves rotational power for hitting"
ADD COLUMN IF NOT EXISTS performance_connection TEXT,     -- "Stronger hips = faster bat speed"
ADD COLUMN IF NOT EXISTS primary_muscles TEXT[],          -- ['glutes', 'core', 'obliques']
ADD COLUMN IF NOT EXISTS secondary_muscles TEXT[],        -- ['hip flexors', 'lower back']
ADD COLUMN IF NOT EXISTS movement_pattern TEXT,           -- 'hip_hinge', 'rotation', 'push', 'pull'
ADD COLUMN IF NOT EXISTS research_note TEXT;              -- Brief research reference

-- Add comments for documentation
COMMENT ON COLUMN exercise_explanations.baseball_benefit IS 'Baseball-specific benefit explanation (e.g., "Improves rotational power for hitting")';
COMMENT ON COLUMN exercise_explanations.performance_connection IS 'On-field performance connection (e.g., "The same hip rotation pattern used in your swing")';
COMMENT ON COLUMN exercise_explanations.primary_muscles IS 'Primary muscles targeted by this exercise';
COMMENT ON COLUMN exercise_explanations.secondary_muscles IS 'Secondary/supporting muscles worked during this exercise';
COMMENT ON COLUMN exercise_explanations.movement_pattern IS 'Movement pattern category: hip_hinge, rotation, push, pull, squat, lunge, carry, core';
COMMENT ON COLUMN exercise_explanations.research_note IS 'Brief research reference or scientific backing';

-- =============================================================================
-- 2. Create Index for Movement Pattern Queries
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_explanations_movement_pattern ON exercise_explanations(movement_pattern);
CREATE INDEX IF NOT EXISTS idx_explanations_primary_muscles ON exercise_explanations USING GIN(primary_muscles);

-- =============================================================================
-- 3. Update View to Include Baseball Fields
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
    ee.id AS explanation_id,
    ee.why_included,
    ee.what_it_targets,
    ee.how_it_helps,
    ee.when_to_feel_it,
    ee.signs_of_progress,
    ee.warning_signs,
    ee.easier_variation,
    ee.harder_variation,
    ee.equipment_alternatives,
    ee.program_id,
    -- Baseball-specific fields (ACP-816)
    ee.baseball_benefit,
    ee.performance_connection,
    ee.primary_muscles AS explanation_primary_muscles,
    ee.secondary_muscles AS explanation_secondary_muscles,
    ee.movement_pattern,
    ee.research_note
FROM exercise_templates et
LEFT JOIN exercise_explanations ee ON et.id = ee.exercise_template_id;

-- Grant access to view
GRANT SELECT ON vw_exercise_with_explanation TO authenticated;

-- =============================================================================
-- 4. Sample Baseball-Specific Exercise Data
-- =============================================================================

-- Cable Rotation / Woodchop exercises
INSERT INTO exercise_explanations (
    exercise_template_id,
    baseball_benefit,
    performance_connection,
    primary_muscles,
    secondary_muscles,
    movement_pattern,
    why_included,
    research_note
)
SELECT
    id,
    'Builds rotational power essential for throwing and hitting',
    'The same hip rotation pattern used in your swing and throw',
    ARRAY['obliques', 'core', 'hip_flexors'],
    ARRAY['shoulders', 'glutes'],
    'rotation',
    'Develops the rotational strength needed for explosive athletic movements',
    'Studies show rotational power correlates strongly with bat speed (Szymanski et al., 2007)'
FROM exercise_templates
WHERE name ILIKE '%cable rotation%' OR name ILIKE '%woodchop%'
ON CONFLICT (exercise_template_id, program_id) DO UPDATE SET
    baseball_benefit = EXCLUDED.baseball_benefit,
    performance_connection = EXCLUDED.performance_connection,
    primary_muscles = EXCLUDED.primary_muscles,
    secondary_muscles = EXCLUDED.secondary_muscles,
    movement_pattern = EXCLUDED.movement_pattern,
    research_note = EXCLUDED.research_note;

-- Hip Hinge exercises (Deadlifts, RDLs)
INSERT INTO exercise_explanations (
    exercise_template_id,
    baseball_benefit,
    performance_connection,
    primary_muscles,
    secondary_muscles,
    movement_pattern,
    why_included,
    research_note
)
SELECT
    id,
    'Develops posterior chain power for explosive movements',
    'Strong glutes and hamstrings drive your throwing stride and hitting load',
    ARRAY['glutes', 'hamstrings', 'lower_back'],
    ARRAY['core', 'traps'],
    'hip_hinge',
    'Builds foundational strength for all athletic hip-driven movements',
    'Hip extension strength correlates with throwing velocity (Kageyama et al., 2015)'
FROM exercise_templates
WHERE name ILIKE '%deadlift%' OR name ILIKE '%rdl%' OR name ILIKE '%romanian%'
ON CONFLICT (exercise_template_id, program_id) DO UPDATE SET
    baseball_benefit = EXCLUDED.baseball_benefit,
    performance_connection = EXCLUDED.performance_connection,
    primary_muscles = EXCLUDED.primary_muscles,
    secondary_muscles = EXCLUDED.secondary_muscles,
    movement_pattern = EXCLUDED.movement_pattern,
    research_note = EXCLUDED.research_note;

-- Squat exercises
INSERT INTO exercise_explanations (
    exercise_template_id,
    baseball_benefit,
    performance_connection,
    primary_muscles,
    secondary_muscles,
    movement_pattern,
    why_included,
    research_note
)
SELECT
    id,
    'Builds lower body power for explosive movements',
    'Leg strength translates directly to throwing velocity and hitting power',
    ARRAY['quads', 'glutes', 'core'],
    ARRAY['hamstrings', 'adductors'],
    'squat',
    'Fundamental lower body strength exercise for athletic performance',
    'Squat strength positively correlates with sprint speed and jump height'
FROM exercise_templates
WHERE name ILIKE '%squat%' AND name NOT ILIKE '%pistol%'
ON CONFLICT (exercise_template_id, program_id) DO UPDATE SET
    baseball_benefit = EXCLUDED.baseball_benefit,
    performance_connection = EXCLUDED.performance_connection,
    primary_muscles = EXCLUDED.primary_muscles,
    secondary_muscles = EXCLUDED.secondary_muscles,
    movement_pattern = EXCLUDED.movement_pattern,
    research_note = EXCLUDED.research_note;

-- Push exercises (Bench Press, Push-ups)
INSERT INTO exercise_explanations (
    exercise_template_id,
    baseball_benefit,
    performance_connection,
    primary_muscles,
    secondary_muscles,
    movement_pattern,
    why_included,
    research_note
)
SELECT
    id,
    'Develops upper body pressing strength for arm acceleration',
    'Chest and triceps strength supports the late acceleration phase of throwing',
    ARRAY['chest', 'triceps', 'front_delts'],
    ARRAY['core', 'serratus'],
    'push',
    'Builds pushing strength while maintaining shoulder stability',
    'Balanced upper body strength reduces injury risk (Wilk et al., 2011)'
FROM exercise_templates
WHERE name ILIKE '%bench press%' OR name ILIKE '%push-up%' OR name ILIKE '%pushup%'
ON CONFLICT (exercise_template_id, program_id) DO UPDATE SET
    baseball_benefit = EXCLUDED.baseball_benefit,
    performance_connection = EXCLUDED.performance_connection,
    primary_muscles = EXCLUDED.primary_muscles,
    secondary_muscles = EXCLUDED.secondary_muscles,
    movement_pattern = EXCLUDED.movement_pattern,
    research_note = EXCLUDED.research_note;

-- Pull exercises (Rows, Pull-ups)
INSERT INTO exercise_explanations (
    exercise_template_id,
    baseball_benefit,
    performance_connection,
    primary_muscles,
    secondary_muscles,
    movement_pattern,
    why_included,
    research_note
)
SELECT
    id,
    'Strengthens the decelerators that protect your arm',
    'Strong back muscles safely slow your arm down after release',
    ARRAY['lats', 'rhomboids', 'rear_delts'],
    ARRAY['biceps', 'traps', 'rotator_cuff'],
    'pull',
    'Critical for maintaining shoulder health in throwing athletes',
    'Posterior shoulder strength ratio is key for injury prevention'
FROM exercise_templates
WHERE name ILIKE '%row%' OR name ILIKE '%pull-up%' OR name ILIKE '%pullup%' OR name ILIKE '%lat pulldown%'
ON CONFLICT (exercise_template_id, program_id) DO UPDATE SET
    baseball_benefit = EXCLUDED.baseball_benefit,
    performance_connection = EXCLUDED.performance_connection,
    primary_muscles = EXCLUDED.primary_muscles,
    secondary_muscles = EXCLUDED.secondary_muscles,
    movement_pattern = EXCLUDED.movement_pattern,
    research_note = EXCLUDED.research_note;

-- Lunge exercises
INSERT INTO exercise_explanations (
    exercise_template_id,
    baseball_benefit,
    performance_connection,
    primary_muscles,
    secondary_muscles,
    movement_pattern,
    why_included,
    research_note
)
SELECT
    id,
    'Builds single-leg stability for athletic movements',
    'Mimics the stride pattern used in pitching and hitting',
    ARRAY['quads', 'glutes', 'core'],
    ARRAY['hamstrings', 'hip_flexors'],
    'lunge',
    'Develops unilateral strength and balance crucial for throwing mechanics',
    'Single-leg strength improves force transfer through the kinetic chain'
FROM exercise_templates
WHERE name ILIKE '%lunge%' OR name ILIKE '%split squat%'
ON CONFLICT (exercise_template_id, program_id) DO UPDATE SET
    baseball_benefit = EXCLUDED.baseball_benefit,
    performance_connection = EXCLUDED.performance_connection,
    primary_muscles = EXCLUDED.primary_muscles,
    secondary_muscles = EXCLUDED.secondary_muscles,
    movement_pattern = EXCLUDED.movement_pattern,
    research_note = EXCLUDED.research_note;

-- Core exercises (Planks, Anti-rotation)
INSERT INTO exercise_explanations (
    exercise_template_id,
    baseball_benefit,
    performance_connection,
    primary_muscles,
    secondary_muscles,
    movement_pattern,
    why_included,
    research_note
)
SELECT
    id,
    'Develops core stability for force transfer',
    'A stable core transfers power from your legs through your arm',
    ARRAY['core', 'obliques', 'transverse_abdominis'],
    ARRAY['hip_flexors', 'lower_back'],
    'core',
    'Builds the stability needed to transfer power through the kinetic chain',
    'Core stability correlates with throwing velocity and accuracy'
FROM exercise_templates
WHERE name ILIKE '%plank%' OR name ILIKE '%pallof%' OR name ILIKE '%dead bug%' OR name ILIKE '%bird dog%'
ON CONFLICT (exercise_template_id, program_id) DO UPDATE SET
    baseball_benefit = EXCLUDED.baseball_benefit,
    performance_connection = EXCLUDED.performance_connection,
    primary_muscles = EXCLUDED.primary_muscles,
    secondary_muscles = EXCLUDED.secondary_muscles,
    movement_pattern = EXCLUDED.movement_pattern,
    research_note = EXCLUDED.research_note;

-- Shoulder/Rotator Cuff exercises
INSERT INTO exercise_explanations (
    exercise_template_id,
    baseball_benefit,
    performance_connection,
    primary_muscles,
    secondary_muscles,
    movement_pattern,
    why_included,
    research_note
)
SELECT
    id,
    'Protects your shoulder for a long, healthy career',
    'Strong rotator cuff muscles stabilize and protect during throwing',
    ARRAY['rotator_cuff', 'rear_delts', 'serratus'],
    ARRAY['traps', 'rhomboids'],
    'accessory',
    'Essential prehab work for throwing athletes',
    'Rotator cuff strengthening reduces injury risk by 50% (Reinold et al., 2018)'
FROM exercise_templates
WHERE name ILIKE '%external rotation%' OR name ILIKE '%internal rotation%'
   OR name ILIKE '%face pull%' OR name ILIKE '%band pull apart%'
   OR name ILIKE '%y raise%' OR name ILIKE '%t raise%' OR name ILIKE '%w raise%'
ON CONFLICT (exercise_template_id, program_id) DO UPDATE SET
    baseball_benefit = EXCLUDED.baseball_benefit,
    performance_connection = EXCLUDED.performance_connection,
    primary_muscles = EXCLUDED.primary_muscles,
    secondary_muscles = EXCLUDED.secondary_muscles,
    movement_pattern = EXCLUDED.movement_pattern,
    research_note = EXCLUDED.research_note;

-- =============================================================================
-- 5. Verification
-- =============================================================================
DO $$
DECLARE
    baseball_count INTEGER;
BEGIN
    -- Verify baseball_benefit column exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'exercise_explanations'
        AND column_name = 'baseball_benefit'
    ) THEN
        RAISE NOTICE 'SUCCESS: exercise_explanations.baseball_benefit column exists';
    ELSE
        RAISE WARNING 'MISSING: exercise_explanations.baseball_benefit column';
    END IF;

    -- Count explanations with baseball benefits
    SELECT COUNT(*) INTO baseball_count
    FROM exercise_explanations
    WHERE baseball_benefit IS NOT NULL;

    RAISE NOTICE 'SUCCESS: % exercise explanations with baseball benefits', baseball_count;

    -- Verify view includes baseball fields
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vw_exercise_with_explanation'
        AND column_name = 'baseball_benefit'
    ) THEN
        RAISE NOTICE 'SUCCESS: vw_exercise_with_explanation includes baseball_benefit';
    ELSE
        RAISE WARNING 'MISSING: baseball_benefit in vw_exercise_with_explanation view';
    END IF;
END $$;
