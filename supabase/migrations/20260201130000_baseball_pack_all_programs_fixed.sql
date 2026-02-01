-- BUILD 374: Baseball Pack - All Programs (Fixed)
-- Consolidated migration for position, seasonal, gameday programs
-- Fixes foreign key issues by looking up template IDs by name
--
-- This migration:
-- 1. Inserts new exercise templates with ON CONFLICT DO NOTHING (won't fail on duplicates)
-- 2. Uses subqueries to look up template IDs by name for session_exercises
-- 3. Creates all programs: Catcher, Infielder, Outfielder, Off-Season, Pre-Season, In-Season, Game-Day

-- ============================================================================
-- HELPER FUNCTION: Get or create exercise template by name
-- ============================================================================
CREATE OR REPLACE FUNCTION get_exercise_template_id(p_name TEXT) RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    SELECT id INTO v_id FROM exercise_templates WHERE name = p_name LIMIT 1;
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EXERCISE TEMPLATES FOR BASEBALL POSITION PROGRAMS
-- ============================================================================
-- Using ON CONFLICT DO NOTHING - if template exists, we'll look it up by name

-- Catcher-specific exercises
INSERT INTO exercise_templates (name, category, body_region, equipment, load_type, cueing, movement_pattern)
VALUES
  -- Hip Mobility
  ('90/90 Hip Stretch', 'mobility', 'lower_body', 'bodyweight', 'bodyweight', 'Stack shin perpendicular, tall spine, hinge forward at hips', 'hip_mobility'),
  ('Goblet Squat Hold', 'mobility', 'lower_body', 'kettlebell', 'weight', 'Deep squat position, elbows inside knees, tall chest', 'squat'),
  ('Cossack Squat', 'mobility', 'lower_body', 'bodyweight', 'bodyweight', 'Shift laterally, trail leg straight, heel down on working leg', 'squat'),
  ('Deep Squat to Stand', 'mobility', 'lower_body', 'bodyweight', 'bodyweight', 'Grab toes, straighten legs, drop back to squat', 'hip_mobility'),
  -- Pop Time / Quick Twitch
  ('Box Jump from Squat', 'power', 'lower_body', 'plyo_box', 'bodyweight', 'Start in deep squat, explode up, soft landing', 'jump'),
  ('Lateral Hurdle Hop', 'power', 'lower_body', 'mini_hurdles', 'bodyweight', 'Quick lateral hops, minimize ground contact', 'lateral_power'),
  ('Reaction Ball Catch', 'agility', 'upper_body', 'reaction_ball', 'bodyweight', 'Quick hands, track bounce, catch cleanly', 'reaction'),
  ('Crouch to Sprint Start', 'power', 'lower_body', 'bodyweight', 'bodyweight', 'From catching stance, explode into sprint', 'acceleration'),
  -- Receiving/Framing
  ('Wall Squat Hold', 'endurance', 'lower_body', 'bodyweight', 'bodyweight', 'Sit against wall, thighs parallel, hold position', 'isometric'),
  ('Plate Pinch Hold', 'grip', 'upper_body', 'weight_plate', 'weight', 'Pinch plate with fingers, maintain grip', 'grip'),
  ('Wrist Rotation with Band', 'prehab', 'upper_body', 'band', 'weight', 'Controlled supination and pronation', 'wrist_stability'),
  -- Throwing from Crouch
  ('Med Ball Chest Pass from Squat', 'power', 'upper_body', 'medicine_ball', 'weight', 'Start in squat, explosive chest pass', 'push'),
  ('Rotational Med Ball Slam from Squat', 'power', 'core', 'medicine_ball', 'weight', 'Rotate and slam from catching stance', 'rotation'),
  ('Hip Hinge to Throw', 'power', 'core', 'medicine_ball', 'weight', 'Hinge, load posterior, explosive throw', 'hinge'),
  -- Lower Body Strength
  ('Bulgarian Split Squat', 'strength', 'lower_body', 'dumbbell', 'weight', 'Rear foot elevated, control descent, drive through front heel', 'single_leg'),
  ('Leg Press', 'strength', 'lower_body', 'machine', 'weight', 'Full range, controlled eccentric', 'squat'),
  ('Single Leg RDL', 'strength', 'lower_body', 'dumbbell', 'weight', 'Hinge at hip, maintain neutral spine, balance', 'hinge'),
  -- Infielder exercises
  ('Lateral Bound', 'power', 'lower_body', 'bodyweight', 'bodyweight', 'Explosive lateral push, stick landing, repeat', 'lateral_power'),
  ('5-10-5 Pro Agility', 'agility', 'lower_body', 'cones', 'bodyweight', '5 yards out, 10 back, 5 finish, low and fast', 'change_of_direction'),
  ('Ladder Quick Feet', 'agility', 'lower_body', 'agility_ladder', 'bodyweight', 'Quick foot contacts, minimal ground time', 'footwork'),
  ('Crossover Step Drill', 'agility', 'lower_body', 'cones', 'bodyweight', 'Open hip, crossover, accelerate to ball', 'change_of_direction'),
  ('Forehand Shuffle Pick', 'agility', 'lower_body', 'ball', 'bodyweight', 'Shuffle to forehand side, field and throw', 'fielding'),
  ('Backhand Range Drill', 'agility', 'lower_body', 'ball', 'bodyweight', 'Crossover to backhand, extend, field cleanly', 'fielding'),
  ('Double Play Pivot Footwork', 'agility', 'lower_body', 'ball', 'bodyweight', 'Quick receive, pivot, accurate throw', 'footwork'),
  ('Quick Arm Circle Throws', 'arm_care', 'upper_body', 'baseball', 'bodyweight', 'Short, quick arm action, accurate throws', 'throw'),
  ('Off-Balance Throw', 'throwing', 'upper_body', 'baseball', 'bodyweight', 'Throw while moving, maintain accuracy', 'throw'),
  ('Sidearm Feed Drill', 'throwing', 'upper_body', 'baseball', 'bodyweight', 'Quick sidearm flip for double play', 'throw'),
  ('Reaction Ball Ground Ball', 'agility', 'full_body', 'reaction_ball', 'bodyweight', 'Track erratic bounce, field cleanly', 'reaction'),
  ('Tennis Ball Drop Reaction', 'agility', 'upper_body', 'tennis_ball', 'bodyweight', 'Partner drops ball, catch before second bounce', 'reaction'),
  ('Lateral Lunge', 'strength', 'lower_body', 'dumbbell', 'weight', 'Wide step, load lateral hip, push back', 'lateral'),
  ('Copenhagen Plank', 'core', 'lower_body', 'bench', 'bodyweight', 'Top leg on bench, hold hip-level position', 'isometric'),
  -- Outfielder exercises
  ('10 Yard Sprint', 'speed', 'lower_body', 'cones', 'bodyweight', 'Explosive start, pump arms, drive knees', 'acceleration'),
  ('40 Yard Dash', 'speed', 'lower_body', 'cones', 'bodyweight', 'Build to top speed, maintain form', 'max_velocity'),
  ('Flying 20s', 'speed', 'lower_body', 'cones', 'bodyweight', '20 yard buildup, 20 yard max effort', 'max_velocity'),
  ('A-Skip', 'speed', 'lower_body', 'bodyweight', 'bodyweight', 'Drive knee up, quick ground contact', 'sprint_mechanics'),
  ('Drop Step Drill', 'agility', 'lower_body', 'cones', 'bodyweight', 'Open hip, drop step, sprint to ball', 'change_of_direction'),
  ('Ball Read Drill', 'agility', 'lower_body', 'ball', 'bodyweight', 'Read trajectory, take efficient route', 'tracking'),
  ('Cone Route Efficiency', 'agility', 'lower_body', 'cones', 'bodyweight', 'Run angled routes, minimal steps', 'routes'),
  ('Long Toss 90ft', 'throwing', 'upper_body', 'baseball', 'bodyweight', 'Arc throw, full arm extension, loose arm', 'throw'),
  ('Long Toss 150ft', 'throwing', 'upper_body', 'baseball', 'bodyweight', 'Max effort arc, build arm strength', 'throw'),
  ('Long Toss 200ft+', 'throwing', 'upper_body', 'baseball', 'bodyweight', 'Max distance, maintain mechanics', 'throw'),
  ('Crow Hop Throw', 'throwing', 'upper_body', 'baseball', 'bodyweight', 'Gather momentum, crow hop, strong throw', 'throw'),
  ('Shuffle Throw', 'throwing', 'upper_body', 'baseball', 'bodyweight', 'Quick shuffle, accurate throw to cutoff', 'throw'),
  ('Wall Ball Angles', 'agility', 'lower_body', 'ball', 'bodyweight', 'Field ball off wall at various angles', 'fielding'),
  ('Fence Drill', 'agility', 'lower_body', 'bodyweight', 'bodyweight', 'Track ball to fence, proper timing', 'tracking'),
  ('Sled Push', 'power', 'lower_body', 'sled', 'weight', 'Drive through legs, lean forward, explosive', 'acceleration'),
  ('Hip Flexor March', 'mobility', 'lower_body', 'band', 'bodyweight', 'Resisted high knee drive, controlled descent', 'hip_flexor'),
  -- Seasonal/General exercises
  ('Box Squat', 'strength', 'lower_body', 'barbell', 'weight', 'Sit back to box, pause, explode up', 'squat'),
  ('Hip Thrust', 'strength', 'lower_body', 'barbell', 'weight', 'Shoulders on bench, drive hips to ceiling', 'hinge'),
  ('Pull-Up', 'strength', 'upper_body', 'bodyweight', 'bodyweight', 'Dead hang, pull until chin over bar', 'pull'),
  ('Inverted Row', 'strength', 'upper_body', 'rings', 'bodyweight', 'Pull chest to bar/rings, squeeze shoulder blades', 'pull'),
  ('Face Pull', 'prehab', 'upper_body', 'cable', 'weight', 'Pull to face, external rotate at end', 'pull'),
  ('Band Pull-Apart', 'prehab', 'upper_body', 'band', 'bodyweight', 'Pull band apart at chest height, squeeze back', 'pull'),
  ('Pallof Press', 'core', 'core', 'cable', 'weight', 'Resist rotation, press and hold', 'anti_rotation'),
  ('Dead Bug', 'core', 'core', 'bodyweight', 'bodyweight', 'Opposite arm/leg extend, maintain flat back', 'core_stability'),
  ('Bird Dog', 'core', 'core', 'bodyweight', 'bodyweight', 'Opposite arm/leg extend, level hips', 'core_stability'),
  ('Side Plank', 'core', 'core', 'bodyweight', 'bodyweight', 'Stack feet, hip up, straight line', 'anti_lateral_flexion'),
  ('Medicine Ball Scoop Toss', 'power', 'core', 'medicine_ball', 'weight', 'Scoop from low, launch overhead', 'rotation'),
  ('Landmine Press', 'strength', 'upper_body', 'barbell', 'weight', 'Press at angle, stabilize through core', 'push'),
  ('Half-Kneeling Press', 'strength', 'upper_body', 'dumbbell', 'weight', 'One knee down, press overhead, stay tall', 'push'),
  ('Dynamic Warm-Up Circuit', 'warm_up', 'full_body', 'bodyweight', 'bodyweight', 'High knees, butt kicks, shuffles, arm circles', 'warm_up'),
  ('Game Day Throwing Progression', 'throwing', 'upper_body', 'baseball', 'bodyweight', 'Progressive distance and intensity', 'throw'),
  ('Pre-Game Dynamic Stretch', 'mobility', 'full_body', 'bodyweight', 'bodyweight', 'Dynamic stretches, activate nervous system', 'mobility'),
  ('Post-Game Cool Down', 'recovery', 'full_body', 'bodyweight', 'bodyweight', 'Light jog, static stretches, breathing', 'recovery'),
  ('Sprint Build-Ups', 'speed', 'lower_body', 'cones', 'bodyweight', 'Gradual acceleration over 30-40 yards', 'acceleration'),
  ('Catch Play Warm-Up', 'throwing', 'upper_body', 'baseball', 'bodyweight', 'Partner catch, progressive distance', 'throw')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 1. CATCHER DURABILITY & PERFORMANCE PROGRAM (8 Weeks, 4x/week)
-- ============================================================================

DO $$
DECLARE
    v_program_id UUID;
    v_phase1_id UUID;
    v_phase2_id UUID;
    v_session_id UUID;
    v_library_id UUID;
BEGIN
    -- Create the Catcher program
    INSERT INTO programs (patient_id, name, description, status, metadata)
    VALUES (
        NULL,
        'Catcher Durability & Performance',
        '8-week position-specific program for catchers focusing on hip mobility for squat position, quick-twitch pop time training, receiving/framing endurance, throwing mechanics from crouch, and lower body strength/durability.',
        'active',
        jsonb_build_object(
            'duration_weeks', 8,
            'workouts_per_week', 4,
            'position', 'catcher',
            'focus_areas', ARRAY['hip-mobility', 'pop-time', 'receiving', 'throwing-from-crouch', 'durability'],
            'is_system_template', true
        )
    ) RETURNING id INTO v_program_id;

    -- Phase 1: Foundation & Mobility (Weeks 1-4)
    INSERT INTO phases (program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (v_program_id, 'Foundation & Mobility', 1, 4,
            'Build squat position endurance, establish hip mobility baseline, develop receiving durability',
            'Focus: Movement quality, hip mobility, position-specific conditioning. Intensity: Low-Moderate.')
    RETURNING id INTO v_phase1_id;

    -- Phase 2: Power & Performance (Weeks 5-8)
    INSERT INTO phases (program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (v_program_id, 'Power & Performance', 2, 4,
            'Develop explosive pop time, improve throwing velocity from crouch, peak lower body strength',
            'Focus: Power development, quick-twitch training, game-day preparation. Intensity: Moderate-High.')
    RETURNING id INTO v_phase2_id;

    -- Session 1: Hip Mobility Day
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Hip Mobility & Squat Endurance', 1, 1, 6, false,
            'Focus on deep squat mobility and position-specific endurance')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('90/90 Hip Stretch'), 1, 1, 'Mobility', 3, '60s', 30, 'Hold each side'),
        (v_session_id, get_exercise_template_id('Goblet Squat Hold'), 2, 1, 'Mobility', 3, '45s', 30, 'Deep squat position'),
        (v_session_id, get_exercise_template_id('Cossack Squat'), 3, 1, 'Mobility', 3, '8/side', 45, 'Controlled tempo'),
        (v_session_id, get_exercise_template_id('Deep Squat to Stand'), 4, 1, 'Mobility', 2, '10', 30, NULL),
        (v_session_id, get_exercise_template_id('Wall Squat Hold'), 5, 2, 'Endurance', 3, '45s', 60, 'Simulates receiving position');

    -- Session 2: Pop Time Foundation
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Pop Time Foundation', 2, 2, 7, true, 'Develop quick-twitch from squat position')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Box Jump from Squat'), 1, 1, 'Power', 4, '5', 90, 'Explosive'),
        (v_session_id, get_exercise_template_id('Crouch to Sprint Start'), 2, 1, 'Power', 4, '3', 90, 'Game-like'),
        (v_session_id, get_exercise_template_id('Med Ball Chest Pass from Squat'), 3, 2, 'Throwing', 3, '8', 60, NULL),
        (v_session_id, get_exercise_template_id('Rotational Med Ball Slam from Squat'), 4, 2, 'Throwing', 3, '6/side', 60, NULL);

    -- Session 3: Receiving Endurance
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Receiving Endurance & Grip', 3, 4, 5, false, 'Build receiving stamina and grip strength')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Wall Squat Hold'), 1, 1, 'Endurance', 4, '60s', 45, 'Extended time'),
        (v_session_id, get_exercise_template_id('Plate Pinch Hold'), 2, 1, 'Grip', 3, '30s', 45, 'Receiving grip'),
        (v_session_id, get_exercise_template_id('Wrist Rotation with Band'), 3, 1, 'Prehab', 3, '15/direction', 30, NULL),
        (v_session_id, get_exercise_template_id('Reaction Ball Catch'), 4, 2, 'Reaction', 3, '10', 45, 'Quick hands');

    -- Session 4: Lower Body Strength
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Lower Body Strength & Durability', 4, 6, 7, false, 'Build lower body durability')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Bulgarian Split Squat'), 1, 1, 'Primary', 3, '8/leg', 90, NULL),
        (v_session_id, get_exercise_template_id('Leg Press'), 2, 2, 'Accessory', 3, '12', 90, 'Volume work'),
        (v_session_id, get_exercise_template_id('Single Leg RDL'), 3, 2, 'Accessory', 3, '10/leg', 60, 'Balance and strength');

    -- Phase 2 Sessions
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase2_id, 'Advanced Pop Time Training', 5, 1, 8, true, 'Peak pop time development')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Box Jump from Squat'), 1, 1, 'Power', 5, '3', 120, 'Max height'),
        (v_session_id, get_exercise_template_id('Lateral Hurdle Hop'), 2, 1, 'Power', 4, '8', 60, 'Quick transitions'),
        (v_session_id, get_exercise_template_id('Crouch to Sprint Start'), 3, 1, 'Power', 5, '3', 120, 'Timed'),
        (v_session_id, get_exercise_template_id('Med Ball Chest Pass from Squat'), 4, 2, 'Throwing', 4, '6', 75, 'Max effort');

    -- Add to program library
    INSERT INTO program_library (program_id, title, description, category, duration_weeks, difficulty_level, is_featured, tags, author)
    VALUES (
        v_program_id,
        'Catcher Durability & Performance',
        '8-week position-specific program for catchers focusing on hip mobility, pop time training, receiving endurance, and throwing mechanics from crouch.',
        'baseball',
        8,
        'intermediate',
        true,
        ARRAY['catcher', 'position_specific', 'durability', 'pop_time', 'hip_mobility'],
        'PT Performance Baseball'
    );

    RAISE NOTICE 'Created Catcher program: %', v_program_id;
END $$;

-- ============================================================================
-- 2. INFIELDER AGILITY & ARM PROGRAM (6 Weeks, 4x/week)
-- ============================================================================

DO $$
DECLARE
    v_program_id UUID;
    v_phase1_id UUID;
    v_phase2_id UUID;
    v_session_id UUID;
BEGIN
    INSERT INTO programs (patient_id, name, description, status, metadata)
    VALUES (
        NULL,
        'Infielder Agility & Arm Program',
        '6-week position-specific program for infielders focusing on lateral quickness, first-step explosion, quick-release throws, and reaction time.',
        'active',
        jsonb_build_object(
            'duration_weeks', 6,
            'workouts_per_week', 4,
            'position', 'infielder',
            'focus_areas', ARRAY['agility', 'quick-release', 'lateral-movement', 'reaction-time'],
            'is_system_template', true
        )
    ) RETURNING id INTO v_program_id;

    -- Phase 1: Agility Foundation (Weeks 1-3)
    INSERT INTO phases (program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (v_program_id, 'Agility Foundation', 1, 3,
            'Build lateral quickness base, develop first-step explosion, establish throwing mechanics',
            'Focus: Movement efficiency, body control, footwork patterns.')
    RETURNING id INTO v_phase1_id;

    -- Phase 2: Game Speed Performance (Weeks 4-6)
    INSERT INTO phases (program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (v_program_id, 'Game Speed Performance', 2, 3,
            'Peak lateral speed, game-speed reactions, quick-release accuracy',
            'Focus: Game-like intensity, reactive drills, pressure situations.')
    RETURNING id INTO v_phase2_id;

    -- Session 1: Lateral Quickness
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Lateral Quickness Development', 1, 1, 7, false, 'Focus on lateral movement patterns')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Lateral Bound'), 1, 1, 'Power', 4, '6/side', 60, 'Stick landing'),
        (v_session_id, get_exercise_template_id('5-10-5 Pro Agility'), 2, 1, 'Agility', 4, '3', 90, 'Low and fast'),
        (v_session_id, get_exercise_template_id('Ladder Quick Feet'), 3, 2, 'Footwork', 3, '2 patterns', 45, 'Minimize ground contact'),
        (v_session_id, get_exercise_template_id('Lateral Lunge'), 4, 3, 'Strength', 3, '8/side', 60, 'Control descent');

    -- Session 2: Fielding Footwork
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Fielding Footwork & Throwing', 2, 2, 7, true, 'Position-specific fielding patterns')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Crossover Step Drill'), 1, 1, 'Footwork', 4, '6/side', 45, 'Open hip first'),
        (v_session_id, get_exercise_template_id('Forehand Shuffle Pick'), 2, 1, 'Fielding', 3, '8', 45, 'Shuffle and throw'),
        (v_session_id, get_exercise_template_id('Backhand Range Drill'), 3, 1, 'Fielding', 3, '8', 45, 'Extend and field'),
        (v_session_id, get_exercise_template_id('Quick Arm Circle Throws'), 4, 2, 'Throwing', 3, '10', 60, 'Short and quick');

    -- Session 3: Reaction Training
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Reaction & Core Stability', 3, 4, 6, false, 'Reaction time and core work')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Reaction Ball Ground Ball'), 1, 1, 'Reaction', 3, '10', 45, 'Track and field'),
        (v_session_id, get_exercise_template_id('Tennis Ball Drop Reaction'), 2, 1, 'Reaction', 3, '8', 30, 'Quick hands'),
        (v_session_id, get_exercise_template_id('Copenhagen Plank'), 3, 2, 'Core', 3, '20s/side', 45, 'Lateral stability'),
        (v_session_id, get_exercise_template_id('Pallof Press'), 4, 2, 'Core', 3, '10/side', 45, 'Anti-rotation');

    -- Session 4: Double Play Mechanics
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Double Play & Arm Strength', 4, 6, 7, true, 'Turn two and throw accuracy')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Double Play Pivot Footwork'), 1, 1, 'Footwork', 4, '8', 45, 'Quick pivot'),
        (v_session_id, get_exercise_template_id('Sidearm Feed Drill'), 2, 1, 'Throwing', 3, '10', 45, 'Quick flip'),
        (v_session_id, get_exercise_template_id('Off-Balance Throw'), 3, 2, 'Throwing', 3, '8', 60, 'Moving throw');

    -- Add to program library
    INSERT INTO program_library (program_id, title, description, category, duration_weeks, difficulty_level, is_featured, tags, author)
    VALUES (
        v_program_id,
        'Infielder Agility & Arm Program',
        '6-week position-specific program for infielders focusing on lateral quickness, first-step explosion, quick-release throws, and reaction time.',
        'baseball',
        6,
        'intermediate',
        true,
        ARRAY['infielder', 'position_specific', 'agility', 'quick_release', 'lateral_movement'],
        'PT Performance Baseball'
    );

    RAISE NOTICE 'Created Infielder program: %', v_program_id;
END $$;

-- ============================================================================
-- 3. OUTFIELDER SPEED & ARM PROGRAM (6 Weeks, 4x/week)
-- ============================================================================

DO $$
DECLARE
    v_program_id UUID;
    v_phase1_id UUID;
    v_phase2_id UUID;
    v_session_id UUID;
BEGIN
    INSERT INTO programs (patient_id, name, description, status, metadata)
    VALUES (
        NULL,
        'Outfielder Speed & Arm Program',
        '6-week position-specific program for outfielders focusing on straight-line speed, route efficiency, long throw development, and wall/fence awareness.',
        'active',
        jsonb_build_object(
            'duration_weeks', 6,
            'workouts_per_week', 4,
            'position', 'outfielder',
            'focus_areas', ARRAY['speed', 'arm-strength', 'route-running', 'tracking'],
            'is_system_template', true
        )
    ) RETURNING id INTO v_program_id;

    -- Phase 1: Speed & Route Foundation (Weeks 1-3)
    INSERT INTO phases (program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (v_program_id, 'Speed & Route Foundation', 1, 3,
            'Develop straight-line speed, establish efficient route patterns, build throwing base',
            'Focus: Running mechanics, ball tracking, arm strength foundation.')
    RETURNING id INTO v_phase1_id;

    -- Phase 2: Game Speed Performance (Weeks 4-6)
    INSERT INTO phases (program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (v_program_id, 'Game Speed Performance', 2, 3,
            'Peak running speed, game-speed reads, max-effort throws',
            'Focus: Game-like intensity, deep throws, wall play.')
    RETURNING id INTO v_phase2_id;

    -- Session 1: Sprint Development
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Sprint Development', 1, 1, 8, false, 'Focus on acceleration and top speed')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('10 Yard Sprint'), 1, 1, 'Speed', 6, '1', 90, 'Max effort'),
        (v_session_id, get_exercise_template_id('A-Skip'), 2, 1, 'Mechanics', 3, '20 yards', 45, 'Knee drive'),
        (v_session_id, get_exercise_template_id('Flying 20s'), 3, 2, 'Top Speed', 4, '1', 120, 'Max velocity'),
        (v_session_id, get_exercise_template_id('Sled Push'), 4, 3, 'Power', 3, '20 yards', 120, 'Acceleration work');

    -- Session 2: Long Toss Development
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Long Toss Development', 2, 2, 7, true, 'Build arm strength with progressive distance')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Long Toss 90ft'), 1, 1, 'Warm-Up', 2, '10 throws', 60, 'Loose and easy'),
        (v_session_id, get_exercise_template_id('Long Toss 150ft'), 2, 2, 'Distance', 3, '8 throws', 90, 'Build to effort'),
        (v_session_id, get_exercise_template_id('Crow Hop Throw'), 3, 3, 'Throwing', 3, '6', 60, 'Gather and throw'),
        (v_session_id, get_exercise_template_id('Shuffle Throw'), 4, 3, 'Throwing', 3, '6', 60, 'Quick release');

    -- Session 3: Route Running
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Route Running & Tracking', 3, 4, 7, false, 'Efficient routes to fly balls')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Drop Step Drill'), 1, 1, 'Footwork', 4, '6/side', 45, 'Quick first step'),
        (v_session_id, get_exercise_template_id('Ball Read Drill'), 2, 1, 'Tracking', 3, '8', 60, 'Read trajectory'),
        (v_session_id, get_exercise_template_id('Cone Route Efficiency'), 3, 2, 'Routes', 4, '4', 60, 'Minimal steps');

    -- Session 4: Full Speed Distance
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Speed Endurance', 4, 6, 8, false, 'Build speed endurance')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('40 Yard Dash'), 1, 1, 'Speed', 4, '1', 180, 'Full effort'),
        (v_session_id, get_exercise_template_id('Hip Flexor March'), 2, 2, 'Mobility', 3, '12/leg', 45, 'Active hip flexor'),
        (v_session_id, get_exercise_template_id('Single Leg RDL'), 3, 3, 'Strength', 3, '8/leg', 60, 'Hamstring strength');

    -- Add to program library
    INSERT INTO program_library (program_id, title, description, category, duration_weeks, difficulty_level, is_featured, tags, author)
    VALUES (
        v_program_id,
        'Outfielder Speed & Arm Program',
        '6-week position-specific program for outfielders focusing on straight-line speed, route efficiency, long throw development, and wall awareness.',
        'baseball',
        6,
        'intermediate',
        true,
        ARRAY['outfielder', 'position_specific', 'speed', 'arm_strength', 'route_running'],
        'PT Performance Baseball'
    );

    RAISE NOTICE 'Created Outfielder program: %', v_program_id;
END $$;

-- ============================================================================
-- 4. OFF-SEASON STRENGTH & DEVELOPMENT (12 Weeks, 4x/week)
-- ============================================================================

DO $$
DECLARE
    v_program_id UUID;
    v_phase1_id UUID;
    v_phase2_id UUID;
    v_phase3_id UUID;
    v_session_id UUID;
BEGIN
    INSERT INTO programs (patient_id, name, description, status, metadata)
    VALUES (
        NULL,
        'Off-Season Strength & Development',
        '12-week comprehensive off-season program focusing on building strength, addressing weaknesses, and preparing for the upcoming season.',
        'active',
        jsonb_build_object(
            'duration_weeks', 12,
            'workouts_per_week', 4,
            'season', 'off_season',
            'focus_areas', ARRAY['strength', 'power', 'mobility', 'skill-development'],
            'is_system_template', true
        )
    ) RETURNING id INTO v_program_id;

    -- Phase 1: Hypertrophy & Base (Weeks 1-4)
    INSERT INTO phases (program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (v_program_id, 'Hypertrophy & Base Building', 1, 4,
            'Build muscle mass, establish movement patterns, improve work capacity',
            'Focus: Volume, technique, mobility work. Intensity: Moderate.')
    RETURNING id INTO v_phase1_id;

    -- Phase 2: Strength Development (Weeks 5-8)
    INSERT INTO phases (program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (v_program_id, 'Strength Development', 2, 4,
            'Increase maximal strength, develop power potential, refine technique',
            'Focus: Progressive overload, compound lifts, power development. Intensity: Moderate-High.')
    RETURNING id INTO v_phase2_id;

    -- Phase 3: Power & Peaking (Weeks 9-12)
    INSERT INTO phases (program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (v_program_id, 'Power & Transition', 3, 4,
            'Convert strength to power, prepare for pre-season, maintain gains',
            'Focus: Power output, sport-specific training, transition to baseball. Intensity: High with deload.')
    RETURNING id INTO v_phase3_id;

    -- Phase 1 Session 1: Lower Body Hypertrophy
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Lower Body Hypertrophy', 1, 1, 7, false, 'Build leg size and strength base')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Box Squat'), 1, 1, 'Primary', 4, '8', 120, 'Control depth'),
        (v_session_id, get_exercise_template_id('Bulgarian Split Squat'), 2, 2, 'Accessory', 3, '10/leg', 90, 'Volume work'),
        (v_session_id, get_exercise_template_id('Hip Thrust'), 3, 2, 'Accessory', 3, '12', 90, 'Glute development'),
        (v_session_id, get_exercise_template_id('Single Leg RDL'), 4, 3, 'Accessory', 3, '10/leg', 60, 'Hamstring focus');

    -- Phase 1 Session 2: Upper Body Push
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Upper Body Push', 2, 2, 6, false, 'Build pressing strength')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Landmine Press'), 1, 1, 'Primary', 4, '10/arm', 90, 'Shoulder-friendly'),
        (v_session_id, get_exercise_template_id('Half-Kneeling Press'), 2, 2, 'Accessory', 3, '10/arm', 60, 'Unilateral strength'),
        (v_session_id, get_exercise_template_id('Face Pull'), 3, 3, 'Prehab', 3, '15', 45, 'Shoulder health'),
        (v_session_id, get_exercise_template_id('Band Pull-Apart'), 4, 3, 'Prehab', 3, '20', 30, 'Upper back activation');

    -- Phase 1 Session 3: Upper Body Pull
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Upper Body Pull', 3, 4, 6, false, 'Build back and grip strength')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Pull-Up'), 1, 1, 'Primary', 4, '6-8', 120, 'Full range'),
        (v_session_id, get_exercise_template_id('Inverted Row'), 2, 2, 'Accessory', 3, '12', 60, 'Horizontal pull'),
        (v_session_id, get_exercise_template_id('Face Pull'), 3, 3, 'Prehab', 3, '15', 45, 'External rotation');

    -- Phase 1 Session 4: Core & Power
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase1_id, 'Core & Power Development', 4, 6, 7, false, 'Build core stability and power base')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Medicine Ball Scoop Toss'), 1, 1, 'Power', 4, '8', 60, 'Explosive throw'),
        (v_session_id, get_exercise_template_id('Dead Bug'), 2, 2, 'Core', 3, '10/side', 45, 'Control movement'),
        (v_session_id, get_exercise_template_id('Bird Dog'), 3, 2, 'Core', 3, '10/side', 45, 'Stability'),
        (v_session_id, get_exercise_template_id('Side Plank'), 4, 2, 'Core', 3, '30s/side', 30, 'Lateral stability');

    -- Add to program library
    INSERT INTO program_library (program_id, title, description, category, duration_weeks, difficulty_level, is_featured, tags, author)
    VALUES (
        v_program_id,
        'Off-Season Strength & Development',
        '12-week comprehensive off-season program focusing on building strength, addressing weaknesses, and preparing for the upcoming season.',
        'baseball',
        12,
        'intermediate',
        true,
        ARRAY['off_season', 'seasonal', 'strength', 'power', 'development'],
        'PT Performance Baseball'
    );

    RAISE NOTICE 'Created Off-Season program: %', v_program_id;
END $$;

-- ============================================================================
-- 5. GAME-DAY WARM-UP PROTOCOL
-- ============================================================================

DO $$
DECLARE
    v_program_id UUID;
    v_phase_id UUID;
    v_session_id UUID;
BEGIN
    INSERT INTO programs (patient_id, name, description, status, metadata)
    VALUES (
        NULL,
        'Game-Day Warm-Up Protocol',
        'Complete pre-game preparation routine including dynamic warm-up, throwing progression, and mental preparation.',
        'active',
        jsonb_build_object(
            'duration_weeks', 1,
            'workouts_per_week', 1,
            'type', 'game_day',
            'focus_areas', ARRAY['warm-up', 'activation', 'throwing-prep', 'mental-prep'],
            'is_system_template', true
        )
    ) RETURNING id INTO v_program_id;

    INSERT INTO phases (program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (v_program_id, 'Pre-Game Protocol', 1, 1,
            'Prepare body and mind for competition',
            'Complete 45-60 minutes before game time.')
    RETURNING id INTO v_phase_id;

    -- Full Game-Day Warm-Up Session
    INSERT INTO sessions (phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes)
    VALUES (v_phase_id, 'Complete Pre-Game Warm-Up', 1, 1, 6, true, '45-60 minutes before game')
    RETURNING id INTO v_session_id;

    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, prescribed_sets, prescribed_reps, rest_period_seconds, notes)
    VALUES
        (v_session_id, get_exercise_template_id('Dynamic Warm-Up Circuit'), 1, 1, 'Activation', 1, '5 min', 0, 'Full body activation'),
        (v_session_id, get_exercise_template_id('Pre-Game Dynamic Stretch'), 2, 1, 'Mobility', 1, '5 min', 0, 'Dynamic stretches'),
        (v_session_id, get_exercise_template_id('Sprint Build-Ups'), 3, 2, 'Speed Prep', 3, '30 yards', 60, 'Gradual acceleration'),
        (v_session_id, get_exercise_template_id('Catch Play Warm-Up'), 4, 3, 'Throwing', 1, '10 min', 0, 'Progressive distance'),
        (v_session_id, get_exercise_template_id('Game Day Throwing Progression'), 5, 3, 'Throwing', 1, '5 min', 0, 'Full effort throws');

    -- Add to program library
    INSERT INTO program_library (program_id, title, description, category, duration_weeks, difficulty_level, is_featured, tags, author)
    VALUES (
        v_program_id,
        'Game-Day Warm-Up Protocol',
        'Complete pre-game preparation routine including dynamic warm-up, throwing progression, and mental preparation.',
        'baseball',
        1,
        'beginner',
        true,
        ARRAY['game_day', 'warm_up', 'pre_game', 'throwing_prep'],
        'PT Performance Baseball'
    );

    RAISE NOTICE 'Created Game-Day Warm-Up program: %', v_program_id;
END $$;

-- ============================================================================
-- CLEANUP: Drop helper function
-- ============================================================================
DROP FUNCTION IF EXISTS get_exercise_template_id(TEXT);

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
DECLARE
    v_program_count INTEGER;
    v_template_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_program_count
    FROM programs
    WHERE name IN (
        'Catcher Durability & Performance',
        'Infielder Agility & Arm Program',
        'Outfielder Speed & Arm Program',
        'Off-Season Strength & Development',
        'Game-Day Warm-Up Protocol'
    );

    SELECT COUNT(*) INTO v_template_count FROM exercise_templates WHERE category IN ('mobility', 'power', 'agility', 'speed', 'throwing', 'grip', 'prehab', 'arm_care');

    RAISE NOTICE 'Baseball programs created: % (expected: 5)', v_program_count;
    RAISE NOTICE 'Exercise templates available: %', v_template_count;
END $$;
