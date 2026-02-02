-- FIX: Add exercises to Arm Care & Maintenance program
-- Problem: Original migration used hardcoded template UUIDs that didn't exist
-- Solution: Use name-based lookup to find actual template IDs

-- ============================================================================
-- HELPER FUNCTION: Get exercise template ID by name
-- ============================================================================
CREATE OR REPLACE FUNCTION get_exercise_template_id(p_name TEXT)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    SELECT id INTO v_id FROM exercise_templates WHERE name = p_name LIMIT 1;
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- First, ensure the arm care templates exist
-- ============================================================================
INSERT INTO exercise_templates (name, category, body_region, equipment_type, difficulty_level, technique_cues, common_mistakes, safety_notes)
VALUES
    ('J-Band Internal Rotation', 'arm_care', 'upper', 'bands', 'beginner',
     '{"setup": ["J-Band anchored at elbow height", "Elbow at 90 degrees"], "execution": ["Rotate forearm inward", "Control eccentric", "Keep elbow stable"], "breathing": ["Exhale during rotation"]}'::jsonb,
     'Moving elbow, using too heavy resistance', 'Foundation rotator cuff exercise.'),

    ('J-Band External Rotation', 'arm_care', 'upper', 'bands', 'beginner',
     '{"setup": ["J-Band anchored at elbow height", "Elbow at 90 degrees"], "execution": ["Rotate forearm outward", "Control return", "Maintain elbow position"], "breathing": ["Exhale on rotation"]}'::jsonb,
     'Elbow drifting, speeding through reps', 'Critical for shoulder health.'),

    ('90/90 External Rotation', 'arm_care', 'upper', 'dumbbell', 'beginner',
     '{"setup": ["Light dumbbell, lying on side", "Elbow supported, 90 degree angle"], "execution": ["Rotate forearm up", "Hold briefly at top", "Slow lower"], "breathing": ["Exhale lifting"]}'::jsonb,
     'Using too much weight, not controlling tempo', 'Keep it light - 2-5 lbs max.'),

    ('Prone Y-T-W', 'arm_care', 'upper', 'dumbbell', 'beginner',
     '{"setup": ["Face down on bench or floor", "Light dumbbells or no weight"], "execution": ["Y: Arms overhead, thumbs up", "T: Arms to sides, thumbs up", "W: Elbows bent, external rotation"], "breathing": ["Breathe through holds"]}'::jsonb,
     'Using momentum, going too heavy', 'Essential scapular stability. Quality over weight.'),

    ('Scap Push-Ups', 'arm_care', 'upper', 'bodyweight', 'beginner',
     '{"setup": ["Push-up position, arms locked"], "execution": ["Protract shoulder blades apart", "Retract shoulder blades together", "Arms stay straight"], "breathing": ["Exhale protracting"]}'::jsonb,
     'Bending elbows, rushing reps', 'Excellent serratus activation.'),

    ('Forearm Pronation/Supination', 'arm_care', 'upper', 'dumbbell', 'beginner',
     '{"setup": ["Hammer grip on light dumbbell", "Forearm supported on bench"], "execution": ["Rotate palm down slowly", "Return and rotate palm up", "Control throughout"], "breathing": ["Normal breathing"]}'::jsonb,
     'Moving elbow, going too fast', 'Builds forearm endurance for throwing.'),

    ('Wrist Flexion/Extension', 'arm_care', 'upper', 'dumbbell', 'beginner',
     '{"setup": ["Light dumbbell, forearm on bench", "Wrist hanging off edge"], "execution": ["Curl wrist up fully", "Lower past neutral", "Control tempo"], "breathing": ["Breathe naturally"]}'::jsonb,
     'Using momentum, limited range', 'Foundation wrist strength for pitchers.'),

    ('Shoulder Flexion Stretch', 'arm_care', 'upper', 'bodyweight', 'beginner',
     '{"setup": ["Lie on back, arm overhead", "Keep back flat"], "execution": ["Let arm drop toward floor", "Hold stretch 30-45 seconds", "Breathe into stretch"], "breathing": ["Deep diaphragmatic breaths"]}'::jsonb,
     'Arching back, forcing stretch', 'Post-throwing recovery. Never force.'),

    ('Hip 90/90 Stretch', 'mobility', 'lower', 'bodyweight', 'beginner',
     '{"setup": ["Sit with legs in 90/90 position", "Front leg 90 degrees, back leg 90 degrees"], "execution": ["Rotate to switch legs", "Or hold and lean into stretch", "Control transition"], "breathing": ["Breathe deeply into stretch"]}'::jsonb,
     'Forcing range, not controlling movement', 'Essential hip mobility for pitchers.')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- Add session exercises to the Arm Care program
-- ============================================================================
DO $$
DECLARE
    v_program_id UUID;
    v_phase_daily_id UUID;
    v_phase_weekly_id UUID;
    v_daily_pre_id UUID;
    v_daily_post_id UUID;
    v_weekly_strength_id UUID;
    v_weekly_recovery_id UUID;
    v_existing_count INT;
BEGIN
    -- Get the Arm Care program ID
    SELECT id INTO v_program_id
    FROM programs
    WHERE name = 'Arm Care & Maintenance'
    LIMIT 1;

    IF v_program_id IS NULL THEN
        RAISE NOTICE 'Arm Care & Maintenance program not found. Skipping.';
        RETURN;
    END IF;

    RAISE NOTICE 'Found Arm Care & Maintenance program: %', v_program_id;

    -- Get the phases
    SELECT id INTO v_phase_daily_id
    FROM phases
    WHERE program_id = v_program_id AND name = 'Daily Arm Care'
    LIMIT 1;

    SELECT id INTO v_phase_weekly_id
    FROM phases
    WHERE program_id = v_program_id AND name = 'Weekly Strength & Recovery'
    LIMIT 1;

    RAISE NOTICE 'Daily phase: %, Weekly phase: %', v_phase_daily_id, v_phase_weekly_id;

    -- Get the sessions
    SELECT id INTO v_daily_pre_id
    FROM sessions
    WHERE phase_id = v_phase_daily_id AND name = 'Pre-Throwing Routine'
    LIMIT 1;

    SELECT id INTO v_daily_post_id
    FROM sessions
    WHERE phase_id = v_phase_daily_id AND name = 'Post-Throwing Routine'
    LIMIT 1;

    SELECT id INTO v_weekly_strength_id
    FROM sessions
    WHERE phase_id = v_phase_weekly_id AND name = 'Shoulder Strength Day'
    LIMIT 1;

    SELECT id INTO v_weekly_recovery_id
    FROM sessions
    WHERE phase_id = v_phase_weekly_id AND name = 'Recovery & Mobility Day'
    LIMIT 1;

    RAISE NOTICE 'Sessions - Pre: %, Post: %, Strength: %, Recovery: %',
        v_daily_pre_id, v_daily_post_id, v_weekly_strength_id, v_weekly_recovery_id;

    -- Check if exercises already exist
    SELECT COUNT(*) INTO v_existing_count
    FROM session_exercises se
    WHERE se.session_id IN (v_daily_pre_id, v_daily_post_id, v_weekly_strength_id, v_weekly_recovery_id);

    IF v_existing_count > 0 THEN
        RAISE NOTICE 'Session exercises already exist (% found). Skipping to avoid duplicates.', v_existing_count;
        RETURN;
    END IF;

    -- ========================================================================
    -- PRE-THROWING ROUTINE (15 minutes)
    -- ========================================================================
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_daily_pre_id, get_exercise_template_id('J-Band Internal Rotation'), 1, 1, 'J-Band Series', 1, 15, 'Internal rotation - slow, controlled.'),
        (v_daily_pre_id, get_exercise_template_id('J-Band External Rotation'), 2, 1, 'J-Band Series', 1, 15, 'External rotation - full range.'),
        (v_daily_pre_id, get_exercise_template_id('J-Band Internal Rotation'), 3, 1, 'J-Band Series', 1, 15, 'Internal rotation - increase tempo.'),
        (v_daily_pre_id, get_exercise_template_id('J-Band External Rotation'), 4, 1, 'J-Band Series', 1, 15, 'External rotation - throwing tempo.'),
        (v_daily_pre_id, get_exercise_template_id('Scap Push-Ups'), 5, 2, 'Activation', 2, 12, 'Scap push-ups for serratus activation.'),
        (v_daily_pre_id, get_exercise_template_id('Prone Y-T-W'), 6, 2, 'Activation', 1, 8, 'Prone Y-T-W. Light or no weight.'),
        (v_daily_pre_id, get_exercise_template_id('Forearm Pronation/Supination'), 7, 3, 'Forearm', 1, 20, 'Forearm pronation/supination.'),
        (v_daily_pre_id, get_exercise_template_id('Wrist Flexion/Extension'), 8, 3, 'Forearm', 1, 15, 'Wrist flexion/extension.');

    RAISE NOTICE 'Added 8 exercises to Pre-Throwing Routine';

    -- ========================================================================
    -- POST-THROWING ROUTINE (15 minutes)
    -- ========================================================================
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_daily_post_id, get_exercise_template_id('J-Band Internal Rotation'), 1, 1, 'Flush', 2, 20, 'J-Band internal rotation - light flush.'),
        (v_daily_post_id, get_exercise_template_id('J-Band External Rotation'), 2, 1, 'Flush', 2, 20, 'J-Band external rotation - recovery tempo.'),
        (v_daily_post_id, get_exercise_template_id('Shoulder Flexion Stretch'), 3, 2, 'Stretching', 1, 2, 'Shoulder flexion stretch. Hold 45 seconds each side.'),
        (v_daily_post_id, get_exercise_template_id('Shoulder Flexion Stretch'), 4, 2, 'Stretching', 1, 2, 'Cross-body stretch. Hold 30 seconds each.'),
        (v_daily_post_id, get_exercise_template_id('Forearm Pronation/Supination'), 5, 3, 'Forearm Recovery', 1, 25, 'Light forearm pronation/supination.'),
        (v_daily_post_id, get_exercise_template_id('Wrist Flexion/Extension'), 6, 3, 'Forearm Recovery', 1, 20, 'Light wrist flexion/extension.');

    RAISE NOTICE 'Added 6 exercises to Post-Throwing Routine';

    -- ========================================================================
    -- WEEKLY SHOULDER STRENGTH DAY (20 minutes)
    -- ========================================================================
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_weekly_strength_id, get_exercise_template_id('90/90 External Rotation'), 1, 1, 'Rotator Cuff', 3, 12, '90/90 external rotation. 3-5 lbs.'),
        (v_weekly_strength_id, get_exercise_template_id('Prone Y-T-W'), 2, 1, 'Rotator Cuff', 3, 10, 'Prone Y-T-W. 2-3 lbs.'),
        (v_weekly_strength_id, get_exercise_template_id('Scap Push-Ups'), 3, 2, 'Scapular', 3, 15, 'Scap push-ups. Slow tempo.'),
        (v_weekly_strength_id, get_exercise_template_id('J-Band Internal Rotation'), 4, 2, 'Scapular', 2, 15, 'J-Band rows for mid-trap.'),
        (v_weekly_strength_id, get_exercise_template_id('Forearm Pronation/Supination'), 5, 3, 'Forearm', 3, 15, 'Forearm pronation/supination. Progressive load.'),
        (v_weekly_strength_id, get_exercise_template_id('Wrist Flexion/Extension'), 6, 3, 'Forearm', 3, 15, 'Wrist flexion/extension. Progressive load.');

    RAISE NOTICE 'Added 6 exercises to Shoulder Strength Day';

    -- ========================================================================
    -- WEEKLY RECOVERY & MOBILITY DAY (20 minutes)
    -- ========================================================================
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_weekly_recovery_id, get_exercise_template_id('Shoulder Flexion Stretch'), 1, 1, 'Stretching', 2, 2, 'Shoulder flexion stretch. Hold 60 seconds.'),
        (v_weekly_recovery_id, get_exercise_template_id('Shoulder Flexion Stretch'), 2, 1, 'Stretching', 2, 2, 'Cross-body stretch. Hold 45 seconds.'),
        (v_weekly_recovery_id, get_exercise_template_id('Shoulder Flexion Stretch'), 3, 1, 'Stretching', 2, 2, 'Sleeper stretch if tolerated. Hold 30 seconds.'),
        (v_weekly_recovery_id, get_exercise_template_id('J-Band Internal Rotation'), 4, 2, 'Light Flush', 2, 25, 'J-Band internal rotation. Very light.'),
        (v_weekly_recovery_id, get_exercise_template_id('J-Band External Rotation'), 5, 2, 'Light Flush', 2, 25, 'J-Band external rotation. Blood flow focus.'),
        (v_weekly_recovery_id, get_exercise_template_id('Hip 90/90 Stretch'), 6, 3, 'Mobility', 2, 10, 'Hip 90/90 stretch. Total body recovery.');

    RAISE NOTICE 'Added 6 exercises to Recovery & Mobility Day';

    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Arm Care & Maintenance Program Exercises Fixed!';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Total exercises added: 26';
    RAISE NOTICE '  - Pre-Throwing Routine: 8 exercises';
    RAISE NOTICE '  - Post-Throwing Routine: 6 exercises';
    RAISE NOTICE '  - Shoulder Strength Day: 6 exercises';
    RAISE NOTICE '  - Recovery & Mobility Day: 6 exercises';
    RAISE NOTICE '============================================================';

END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT
    'VERIFICATION' as check_type,
    s.name as session_name,
    COUNT(se.id) as exercise_count
FROM sessions s
JOIN phases ph ON ph.id = s.phase_id
JOIN programs p ON p.id = ph.program_id
LEFT JOIN session_exercises se ON se.session_id = s.id
WHERE p.name = 'Arm Care & Maintenance'
GROUP BY s.name, s.sequence
ORDER BY s.sequence;
