-- BUILD: Baseball Pack - Pitcher-Specific Programs
-- Purpose: Create comprehensive pitcher training programs for the Baseball Pack feature
-- Programs:
--   1. Weighted Ball Progression (8 weeks) - Build arm strength and velocity
--   2. Arm Care & Maintenance (Ongoing) - Daily/weekly maintenance routines
--   3. Velocity Development (12 weeks) - Complete velocity building program
--
-- Zone-7 (Data Access), Zone-8 (Data Ingestion)
-- Schema follows existing patterns from 20251213000003 and 20260131073500

-- ============================================================================
-- 1. EXERCISE TEMPLATES FOR PITCHER PROGRAMS
-- ============================================================================
-- Baseball-specific exercises for weighted ball, arm care, and velocity work

-- Weighted Ball Exercises
INSERT INTO exercise_templates (id, name, category, body_region, equipment_type, difficulty_level, technique_cues, common_mistakes, safety_notes)
VALUES
  -- 2oz/4oz Foundation Drills
  ('00000000-0000-0000-0002-000000000001', 'Wrist Flicks (2oz)', 'throwing', 'upper', 'equipment', 'beginner',
   '{"setup": ["Hold 2oz ball loosely", "Arm at side"], "execution": ["Flick wrist to release", "Focus on finger snap", "Soft target"], "breathing": ["Breathe naturally"]}'::jsonb,
   'Gripping ball too tightly, using arm instead of wrist', 'Start with 10-15 reps. Build wrist snap mechanics.'),

  ('00000000-0000-0000-0002-000000000002', 'Pivot Pickoffs (4oz)', 'throwing', 'upper', 'equipment', 'beginner',
   '{"setup": ["4oz ball, partner 30ft away", "Start in stretch position"], "execution": ["Quick pivot and throw", "Focus on hip rotation first", "Snap throw to target"], "breathing": ["Exhale on release"]}'::jsonb,
   'Arm-only throws, rushing mechanics', 'Emphasize hip-to-hand sequencing.'),

  ('00000000-0000-0000-0002-000000000003', 'Rocker Throws (4oz)', 'throwing', 'upper', 'equipment', 'beginner',
   '{"setup": ["4oz ball, feet together", "Partner at 45ft"], "execution": ["Rock back and forward", "Generate momentum", "Let arm follow body"], "breathing": ["Exhale through release"]}'::jsonb,
   'Stopping momentum before throw, rigid upper body', 'Build rhythm and connection.'),

  -- 5oz/6oz Load Development
  ('00000000-0000-0000-0002-000000000004', 'Walking Windups (5oz)', 'throwing', 'upper', 'equipment', 'intermediate',
   '{"setup": ["5oz ball, 60ft to partner", "Start 10ft behind release point"], "execution": ["Walk into wind-up", "Maintain momentum through release", "Full arm action"], "breathing": ["Breathe rhythm with motion"]}'::jsonb,
   'Decelerating before release, inconsistent arm path', 'Focus on continuous motion.'),

  ('00000000-0000-0000-0002-000000000005', 'Reverse Throws (6oz)', 'throwing', 'upper', 'equipment', 'intermediate',
   '{"setup": ["6oz ball, back to target", "Partner at 45ft"], "execution": ["Rotate and throw", "Lead with hip turn", "Arm follows rotation"], "breathing": ["Exhale on rotation"]}'::jsonb,
   'Throwing before hips clear, arm drag', 'Develops hip-shoulder separation.'),

  ('00000000-0000-0000-0002-000000000006', 'Constraint Drill - Connection Ball (6oz)', 'throwing', 'upper', 'equipment', 'intermediate',
   '{"setup": ["6oz ball, towel under lead arm", "Partner at 60ft"], "execution": ["Throw while keeping towel in place", "Forces proper sequencing", "Focus on late trunk rotation"], "breathing": ["Normal rhythm"]}'::jsonb,
   'Dropping towel early, arm-only throws', 'Great for connection issues.'),

  -- 7oz/9oz/11oz Overload
  ('00000000-0000-0000-0002-000000000007', 'Pull-Down Throws (7oz)', 'throwing', 'upper', 'equipment', 'advanced',
   '{"setup": ["7oz ball, running start", "Throw into net or partner at 30-40ft"], "execution": ["Build momentum running", "Max intent throw", "Let arm whip through"], "breathing": ["Explosive exhale"]}'::jsonb,
   'Slowing arm to control, cutting off follow-through', 'Max effort intent required. Full recovery between reps.'),

  ('00000000-0000-0000-0002-000000000008', 'Step-Behind Throws (9oz)', 'throwing', 'upper', 'equipment', 'advanced',
   '{"setup": ["9oz ball, crossover step behind", "Partner at 45ft"], "execution": ["Step behind, rotate, throw", "Hip-driven power", "Arm is loose"], "breathing": ["Exhale on rotation"]}'::jsonb,
   'Muscling the throw, tight arm', 'Heavier ball demands looser arm.'),

  ('00000000-0000-0000-0002-000000000009', 'Pivot Pick Max Intent (11oz)', 'throwing', 'upper', 'equipment', 'advanced',
   '{"setup": ["11oz ball, stretch position", "Net or partner 25-30ft"], "execution": ["Quick pivot, max effort", "Trust the arm", "Full deceleration"], "breathing": ["Explosive exhale"]}'::jsonb,
   'Tentative throws, not trusting arm with heavy ball', 'Overload builds arm strength. Commit to throw.'),

  -- Transfer Phase (Regulation Ball)
  ('00000000-0000-0000-0002-000000000010', 'Mound Work - Fastball Command', 'throwing', 'upper', 'equipment', 'intermediate',
   '{"setup": ["Regulation ball, full mound", "Catcher at regulation distance"], "execution": ["Full delivery, 80-85% effort", "Focus on command over velocity", "Hit spots"], "breathing": ["Normal pitching rhythm"]}'::jsonb,
   'Overthrowing, losing mechanics under fatigue', 'Quality over quantity. 15-20 pitch limit for transfer work.'),

  -- Arm Care Exercises
  ('00000000-0000-0000-0002-000000000011', 'J-Band Internal Rotation', 'arm_care', 'upper', 'bands', 'beginner',
   '{"setup": ["J-Band anchored at elbow height", "Elbow at 90 degrees"], "execution": ["Rotate forearm inward", "Control eccentric", "Keep elbow stable"], "breathing": ["Exhale during rotation"]}'::jsonb,
   'Moving elbow, using too heavy resistance', 'Foundation rotator cuff exercise.'),

  ('00000000-0000-0000-0002-000000000012', 'J-Band External Rotation', 'arm_care', 'upper', 'bands', 'beginner',
   '{"setup": ["J-Band anchored at elbow height", "Elbow at 90 degrees"], "execution": ["Rotate forearm outward", "Control return", "Maintain elbow position"], "breathing": ["Exhale on rotation"]}'::jsonb,
   'Elbow drifting, speeding through reps', 'Critical for shoulder health.'),

  ('00000000-0000-0000-0002-000000000013', '90/90 External Rotation', 'arm_care', 'upper', 'dumbbell', 'beginner',
   '{"setup": ["Light dumbbell, lying on side", "Elbow supported, 90 degree angle"], "execution": ["Rotate forearm up", "Hold briefly at top", "Slow lower"], "breathing": ["Exhale lifting"]}'::jsonb,
   'Using too much weight, not controlling tempo', 'Keep it light - 2-5 lbs max.'),

  ('00000000-0000-0000-0002-000000000014', 'Prone Y-T-W', 'arm_care', 'upper', 'dumbbell', 'beginner',
   '{"setup": ["Face down on bench or floor", "Light dumbbells or no weight"], "execution": ["Y: Arms overhead, thumbs up", "T: Arms to sides, thumbs up", "W: Elbows bent, external rotation"], "breathing": ["Breathe through holds"]}'::jsonb,
   'Using momentum, going too heavy', 'Essential scapular stability. Quality over weight.'),

  ('00000000-0000-0000-0002-000000000015', 'Scap Push-Ups', 'arm_care', 'upper', 'bodyweight', 'beginner',
   '{"setup": ["Push-up position, arms locked"], "execution": ["Protract shoulder blades apart", "Retract shoulder blades together", "Arms stay straight"], "breathing": ["Exhale protracting"]}'::jsonb,
   'Bending elbows, rushing reps', 'Excellent serratus activation.'),

  ('00000000-0000-0000-0002-000000000016', 'Forearm Pronation/Supination', 'arm_care', 'upper', 'dumbbell', 'beginner',
   '{"setup": ["Hammer grip on light dumbbell", "Forearm supported on bench"], "execution": ["Rotate palm down slowly", "Return and rotate palm up", "Control throughout"], "breathing": ["Normal breathing"]}'::jsonb,
   'Moving elbow, going too fast', 'Builds forearm endurance for throwing.'),

  ('00000000-0000-0000-0002-000000000017', 'Wrist Flexion/Extension', 'arm_care', 'upper', 'dumbbell', 'beginner',
   '{"setup": ["Light dumbbell, forearm on bench", "Wrist hanging off edge"], "execution": ["Curl wrist up fully", "Lower past neutral", "Control tempo"], "breathing": ["Breathe naturally"]}'::jsonb,
   'Using momentum, limited range', 'Foundation wrist strength for pitchers.'),

  ('00000000-0000-0000-0002-000000000018', 'Shoulder Flexion Stretch', 'arm_care', 'upper', 'bodyweight', 'beginner',
   '{"setup": ["Lie on back, arm overhead", "Keep back flat"], "execution": ["Let arm drop toward floor", "Hold stretch 30-45 seconds", "Breathe into stretch"], "breathing": ["Deep diaphragmatic breaths"]}'::jsonb,
   'Arching back, forcing stretch', 'Post-throwing recovery. Never force.'),

  -- Velocity Development - Strength Exercises
  ('00000000-0000-0000-0002-000000000019', 'Trap Bar Deadlift', 'strength', 'lower', 'barbell', 'intermediate',
   '{"setup": ["Stand center of trap bar", "Feet hip-width"], "execution": ["Hips back, grip handles", "Drive through floor", "Stand tall, squeeze glutes"], "breathing": ["Brace, pull exhale at top"]}'::jsonb,
   'Rounding back, not using legs', 'Primary lower body strength. Critical for velocity.'),

  ('00000000-0000-0000-0002-000000000020', 'Front Squat', 'strength', 'lower', 'barbell', 'intermediate',
   '{"setup": ["Bar in front rack position", "Elbows high"], "execution": ["Descend with upright torso", "Break parallel", "Drive up through heels"], "breathing": ["Inhale down, exhale driving"]}'::jsonb,
   'Elbows dropping, forward lean', 'Builds anterior core and leg strength.'),

  ('00000000-0000-0000-0002-000000000021', 'Single-Leg RDL', 'strength', 'lower', 'dumbbell', 'intermediate',
   '{"setup": ["Single dumbbell opposite hand", "Balance on one leg"], "execution": ["Hinge at hip, reach dumbbell down", "Back leg extends behind", "Drive hip forward to stand"], "breathing": ["Inhale hinge, exhale up"]}'::jsonb,
   'Rotating hips, bending standing knee', 'Posterior chain and balance for delivery.'),

  ('00000000-0000-0000-0002-000000000022', 'Lateral Lunge', 'strength', 'lower', 'dumbbell', 'beginner',
   '{"setup": ["Dumbbells at sides", "Wide stance"], "execution": ["Shift weight to one side", "Sit into hip, knee over toe", "Push back to center"], "breathing": ["Inhale into lunge, exhale back"]}'::jsonb,
   'Knee caving, not sitting into hip', 'Builds lateral hip strength for stride.'),

  ('00000000-0000-0000-0002-000000000023', 'Hip 90/90 Stretch', 'mobility', 'lower', 'bodyweight', 'beginner',
   '{"setup": ["Sit with legs in 90/90 position", "Front leg 90 degrees, back leg 90 degrees"], "execution": ["Rotate to switch legs", "Or hold and lean into stretch", "Control transition"], "breathing": ["Breathe deeply into stretch"]}'::jsonb,
   'Forcing range, not controlling movement', 'Essential hip mobility for pitchers.'),

  -- Velocity Development - Power Exercises
  ('00000000-0000-0000-0002-000000000024', 'Med Ball Scoop Toss', 'power', 'full_body', 'equipment', 'intermediate',
   '{"setup": ["8-12lb med ball, facing wall", "Feet shoulder-width, ball at hips"], "execution": ["Hinge and scoop ball", "Extend hips explosively", "Release ball high on wall"], "breathing": ["Explosive exhale on release"]}'::jsonb,
   'Using arms instead of hips, not extending fully', 'Hip extension power transfer.'),

  ('00000000-0000-0000-0002-000000000025', 'Med Ball Rotational Throw', 'power', 'core', 'equipment', 'intermediate',
   '{"setup": ["6-10lb med ball, perpendicular to wall", "Athletic stance"], "execution": ["Load into back hip", "Rotate explosively through core", "Release ball into wall"], "breathing": ["Exhale through rotation"]}'::jsonb,
   'Arm-only throw, not loading hips', 'Develops rotational power for pitching.'),

  ('00000000-0000-0000-0002-000000000026', 'Med Ball Overhead Slam', 'power', 'core', 'equipment', 'beginner',
   '{"setup": ["10-15lb slam ball", "Stand tall, ball overhead"], "execution": ["Slam ball into ground", "Use full body, not just arms", "Absorb and repeat"], "breathing": ["Exhale forcefully on slam"]}'::jsonb,
   'Only using arms, not following through', 'Total body power and decel training.'),

  ('00000000-0000-0000-0002-000000000027', 'Box Jump', 'power', 'lower', 'equipment', 'intermediate',
   '{"setup": ["Stand facing box, appropriate height", "Athletic stance"], "execution": ["Arm swing and explode", "Land softly in squat position", "Stand, step down"], "breathing": ["Exhale on jump"]}'::jsonb,
   'Not using arms, landing stiff', 'Lower body explosiveness for drive leg.'),

  ('00000000-0000-0000-0002-000000000028', 'Lateral Bound', 'power', 'lower', 'bodyweight', 'intermediate',
   '{"setup": ["Balance on one leg", "Athletic position"], "execution": ["Bound laterally to opposite foot", "Stick landing, pause", "Bound back"], "breathing": ["Exhale on push-off"]}'::jsonb,
   'Not sticking landing, rushing reps', 'Lateral power for stride leg.'),

  ('00000000-0000-0000-0002-000000000029', 'Broad Jump', 'power', 'lower', 'bodyweight', 'beginner',
   '{"setup": ["Athletic stance", "Feet shoulder-width"], "execution": ["Arm swing back", "Explode forward", "Land in athletic position"], "breathing": ["Exhale on jump"]}'::jsonb,
   'Not using arms, landing off-balance', 'Horizontal power development.')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 2. WEIGHTED BALL PROGRESSION PROGRAM (8 Weeks)
-- ============================================================================

DO $$
DECLARE
    v_program_id UUID;
    v_phase1_id UUID;
    v_phase2_id UUID;
    v_phase3_id UUID;
    v_phase4_id UUID;
    v_library_id UUID;
    -- Session IDs for each phase
    v_p1_s1_id UUID; v_p1_s2_id UUID; v_p1_s3_id UUID;
    v_p2_s1_id UUID; v_p2_s2_id UUID; v_p2_s3_id UUID;
    v_p3_s1_id UUID; v_p3_s2_id UUID; v_p3_s3_id UUID;
    v_p4_s1_id UUID; v_p4_s2_id UUID; v_p4_s3_id UUID;
BEGIN
    -- Create Program
    INSERT INTO programs (
        id, patient_id, name, description, status, metadata
    ) VALUES (
        gen_random_uuid(),
        NULL,  -- System template
        'Weighted Ball Progression',
        'Progressive 8-week weighted ball program using Driveline methodology. Build arm strength, improve arm speed, and develop velocity through systematic overload and underload training.',
        'active',
        jsonb_build_object(
            'duration_weeks', 8,
            'sessions_per_week', 3,
            'sport', 'baseball',
            'position', 'pitcher',
            'category', 'weighted_ball',
            'is_system_template', true,
            'methodology', 'driveline',
            'progression_model', 'linear_periodization',
            'ball_weights', ARRAY['2oz', '4oz', '5oz', '6oz', '7oz', '9oz', '11oz', '5oz_regulation']
        )
    ) RETURNING id INTO v_program_id;

    RAISE NOTICE 'Created Weighted Ball Progression program: %', v_program_id;

    -- Phase 1: Foundation (Weeks 1-2) - 2oz/4oz balls, basic patterns
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes, constraints)
    VALUES (
        gen_random_uuid(), v_program_id, 'Phase 1: Foundation', 1, 2,
        'Build foundational arm mechanics and wrist snap. Establish proper throwing patterns with light implements.',
        'Focus: Mechanics, arm path, wrist snap. Ball weights: 2oz, 4oz. Intensity: LOW. No max effort throws.',
        jsonb_build_object(
            'ball_weights', ARRAY['2oz', '4oz'],
            'max_intensity_pct', 60,
            'throws_per_session', '40-50',
            'recovery_days', 1
        )
    ) RETURNING id INTO v_phase1_id;

    -- Phase 2: Load Development (Weeks 3-4) - 5oz/6oz balls, constraint drills
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes, constraints)
    VALUES (
        gen_random_uuid(), v_program_id, 'Phase 2: Load Development', 2, 2,
        'Develop arm strength through moderate overload. Introduce constraint drills for mechanical improvement.',
        'Focus: Arm strength, hip-shoulder separation. Ball weights: 5oz, 6oz. Intensity: MODERATE.',
        jsonb_build_object(
            'ball_weights', ARRAY['5oz', '6oz'],
            'max_intensity_pct', 75,
            'throws_per_session', '45-55',
            'recovery_days', 1
        )
    ) RETURNING id INTO v_phase2_id;

    -- Phase 3: Overload (Weeks 5-6) - 7oz/9oz/11oz balls, velocity work
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes, constraints)
    VALUES (
        gen_random_uuid(), v_program_id, 'Phase 3: Overload', 3, 2,
        'Build peak arm strength through heavy ball overload. Max intent throws with heavier implements.',
        'Focus: Arm strength overload, velocity intent. Ball weights: 7oz, 9oz, 11oz. Intensity: HIGH. Full recovery essential.',
        jsonb_build_object(
            'ball_weights', ARRAY['7oz', '9oz', '11oz'],
            'max_intensity_pct', 95,
            'throws_per_session', '35-45',
            'recovery_days', 2
        )
    ) RETURNING id INTO v_phase3_id;

    -- Phase 4: Transfer (Weeks 7-8) - Return to regulation, game prep
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes, constraints)
    VALUES (
        gen_random_uuid(), v_program_id, 'Phase 4: Transfer', 4, 2,
        'Transfer arm strength gains to regulation ball. Game-ready preparation and command work.',
        'Focus: Transfer to regulation, command, game prep. Ball weights: 5oz regulation. Intensity: MODERATE-HIGH.',
        jsonb_build_object(
            'ball_weights', ARRAY['5oz_regulation'],
            'max_intensity_pct', 85,
            'throws_per_session', '40-60',
            'recovery_days', 1
        )
    ) RETURNING id INTO v_phase4_id;

    RAISE NOTICE 'Created 4 phases for Weighted Ball Progression';

    -- Create Sessions for Phase 1 (Foundation)
    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase1_id, 'Foundation Session A', 1, 1, true,
         'Light ball mechanics. Focus on arm path and wrist snap. 2oz/4oz balls only.')
    RETURNING id INTO v_p1_s1_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase1_id, 'Foundation Session B', 2, 3, true,
         'Pattern reinforcement. Build rhythm and timing. 2oz/4oz balls only.')
    RETURNING id INTO v_p1_s2_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase1_id, 'Foundation Session C', 3, 5, true,
         'Integration session. Combine all foundation drills. 2oz/4oz balls only.')
    RETURNING id INTO v_p1_s3_id;

    -- Create Sessions for Phase 2 (Load Development)
    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase2_id, 'Load Development Session A', 4, 1, true,
         'Moderate overload introduction. 5oz/6oz balls. Focus on maintaining mechanics under load.')
    RETURNING id INTO v_p2_s1_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase2_id, 'Load Development Session B', 5, 3, true,
         'Constraint drill focus. 6oz connection work. Build hip-shoulder separation.')
    RETURNING id INTO v_p2_s2_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase2_id, 'Load Development Session C', 6, 5, true,
         'Load capacity building. Higher volume with 5oz/6oz. Maintain intent.')
    RETURNING id INTO v_p2_s3_id;

    -- Create Sessions for Phase 3 (Overload)
    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase3_id, 'Overload Session A', 7, 1, true,
         'Heavy ball introduction. 7oz/9oz focus. Max intent with proper recovery.')
    RETURNING id INTO v_p3_s1_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase3_id, 'Overload Session B', 8, 4, true,
         'Peak overload. 9oz/11oz work. Trust the arm, commit to throws.')
    RETURNING id INTO v_p3_s2_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase3_id, 'Overload Session C', 9, 6, true,
         'Velocity intent session. Full spectrum weighted balls. Pull-down focus.')
    RETURNING id INTO v_p3_s3_id;

    -- Create Sessions for Phase 4 (Transfer)
    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase4_id, 'Transfer Session A', 10, 1, true,
         'Return to regulation. Light weighted ball warmup, regulation focus.')
    RETURNING id INTO v_p4_s1_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase4_id, 'Transfer Session B', 11, 3, true,
         'Command development. Regulation ball with intent. Hit spots.')
    RETURNING id INTO v_p4_s2_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase4_id, 'Transfer Session C', 12, 5, true,
         'Game prep bullpen. Simulate game situations. Full delivery work.')
    RETURNING id INTO v_p4_s3_id;

    RAISE NOTICE 'Created 12 sessions for Weighted Ball Progression';

    -- Add Exercises to Phase 1 Sessions
    -- Session A: Foundation mechanics
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p1_s1_id, '00000000-0000-0000-0002-000000000001', 1, 1, 'Warmup', 2, 15, 'Wrist flicks with 2oz ball. Focus on finger snap.'),
        (v_p1_s1_id, '00000000-0000-0000-0002-000000000002', 2, 1, 'Warmup', 2, 10, 'Pivot pickoffs with 4oz. Quick feet, arm follows.'),
        (v_p1_s1_id, '00000000-0000-0000-0002-000000000003', 3, 2, 'Main Work', 3, 10, 'Rocker throws with 4oz. Build rhythm.'),
        (v_p1_s1_id, '00000000-0000-0000-0002-000000000002', 4, 2, 'Main Work', 2, 8, 'Pivot pickoffs - increase distance to 45ft.'),
        (v_p1_s1_id, '00000000-0000-0000-0002-000000000001', 5, 3, 'Finisher', 2, 20, 'Wrist flicks flush. Light effort, high reps.'),
        (v_p1_s1_id, '00000000-0000-0000-0002-000000000011', 6, 3, 'Finisher', 2, 15, 'J-Band internal rotation for arm care.');

    -- Session B: Pattern reinforcement
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p1_s2_id, '00000000-0000-0000-0002-000000000001', 1, 1, 'Warmup', 2, 15, 'Wrist flicks - 2oz, focus on snap.'),
        (v_p1_s2_id, '00000000-0000-0000-0002-000000000003', 2, 2, 'Main Work', 4, 10, 'Rocker throws with 4oz. Rhythm focus.'),
        (v_p1_s2_id, '00000000-0000-0000-0002-000000000002', 3, 2, 'Main Work', 3, 10, 'Pivot pickoffs with 4oz. Increase speed.'),
        (v_p1_s2_id, '00000000-0000-0000-0002-000000000003', 4, 2, 'Main Work', 2, 8, 'Rocker throws - extend distance.'),
        (v_p1_s2_id, '00000000-0000-0000-0002-000000000012', 5, 3, 'Arm Care', 2, 15, 'J-Band external rotation.'),
        (v_p1_s2_id, '00000000-0000-0000-0002-000000000013', 6, 3, 'Arm Care', 2, 12, '90/90 external rotation. 3lb dumbbell.');

    -- Session C: Integration
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p1_s3_id, '00000000-0000-0000-0002-000000000001', 1, 1, 'Warmup', 2, 20, 'Wrist flicks - 2oz, build volume.'),
        (v_p1_s3_id, '00000000-0000-0000-0002-000000000002', 2, 1, 'Warmup', 2, 10, 'Pivot pickoffs - 4oz warmup.'),
        (v_p1_s3_id, '00000000-0000-0000-0002-000000000003', 3, 2, 'Main Work', 3, 12, 'Rocker throws at 60ft.'),
        (v_p1_s3_id, '00000000-0000-0000-0002-000000000002', 4, 2, 'Main Work', 3, 12, 'Pivot pickoffs - game speed.'),
        (v_p1_s3_id, '00000000-0000-0000-0002-000000000003', 5, 2, 'Main Work', 2, 10, 'Rocker throws - max rhythm intent.'),
        (v_p1_s3_id, '00000000-0000-0000-0002-000000000014', 6, 3, 'Arm Care', 2, 10, 'Prone Y-T-W for scapular stability.');

    -- Add Exercises to Phase 2 Sessions
    -- Session A: Moderate overload
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p2_s1_id, '00000000-0000-0000-0002-000000000003', 1, 1, 'Warmup', 2, 10, 'Rocker throws with 4oz warmup.'),
        (v_p2_s1_id, '00000000-0000-0000-0002-000000000004', 2, 2, 'Main Work', 3, 8, 'Walking windups with 5oz. Build momentum.'),
        (v_p2_s1_id, '00000000-0000-0000-0002-000000000005', 3, 2, 'Main Work', 3, 8, 'Reverse throws with 6oz. Hip-driven.'),
        (v_p2_s1_id, '00000000-0000-0000-0002-000000000004', 4, 2, 'Main Work', 2, 10, 'Walking windups - increase intent.'),
        (v_p2_s1_id, '00000000-0000-0000-0002-000000000011', 5, 3, 'Arm Care', 2, 15, 'J-Band internal rotation.'),
        (v_p2_s1_id, '00000000-0000-0000-0002-000000000012', 6, 3, 'Arm Care', 2, 15, 'J-Band external rotation.');

    -- Session B: Constraint drills
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p2_s2_id, '00000000-0000-0000-0002-000000000004', 1, 1, 'Warmup', 2, 8, 'Walking windups with 5oz.'),
        (v_p2_s2_id, '00000000-0000-0000-0002-000000000006', 2, 2, 'Main Work', 4, 8, 'Connection ball drill with 6oz. Key constraint work.'),
        (v_p2_s2_id, '00000000-0000-0000-0002-000000000005', 3, 2, 'Main Work', 3, 8, 'Reverse throws with 6oz.'),
        (v_p2_s2_id, '00000000-0000-0000-0002-000000000006', 4, 2, 'Main Work', 2, 10, 'Connection drill - increase intent.'),
        (v_p2_s2_id, '00000000-0000-0000-0002-000000000013', 5, 3, 'Arm Care', 2, 12, '90/90 external rotation.'),
        (v_p2_s2_id, '00000000-0000-0000-0002-000000000014', 6, 3, 'Arm Care', 2, 10, 'Prone Y-T-W.');

    -- Session C: Load capacity
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p2_s3_id, '00000000-0000-0000-0002-000000000003', 1, 1, 'Warmup', 2, 10, 'Rocker throws warmup.'),
        (v_p2_s3_id, '00000000-0000-0000-0002-000000000004', 2, 2, 'Main Work', 4, 10, 'Walking windups with 5oz - volume focus.'),
        (v_p2_s3_id, '00000000-0000-0000-0002-000000000005', 3, 2, 'Main Work', 4, 10, 'Reverse throws with 6oz - volume focus.'),
        (v_p2_s3_id, '00000000-0000-0000-0002-000000000006', 4, 2, 'Main Work', 2, 8, 'Connection ball finisher.'),
        (v_p2_s3_id, '00000000-0000-0000-0002-000000000015', 5, 3, 'Arm Care', 2, 15, 'Scap push-ups for serratus.'),
        (v_p2_s3_id, '00000000-0000-0000-0002-000000000016', 6, 3, 'Arm Care', 2, 15, 'Forearm pronation/supination.');

    -- Add Exercises to Phase 3 Sessions
    -- Session A: Heavy ball intro
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p3_s1_id, '00000000-0000-0000-0002-000000000004', 1, 1, 'Warmup', 2, 8, 'Walking windups with 5oz warmup.'),
        (v_p3_s1_id, '00000000-0000-0000-0002-000000000007', 2, 2, 'Main Work', 3, 6, 'Pull-down throws with 7oz. MAX INTENT.'),
        (v_p3_s1_id, '00000000-0000-0000-0002-000000000008', 3, 2, 'Main Work', 3, 6, 'Step-behind throws with 9oz. Trust arm.'),
        (v_p3_s1_id, '00000000-0000-0000-0002-000000000007', 4, 2, 'Main Work', 2, 5, 'Pull-downs - peak intent.'),
        (v_p3_s1_id, '00000000-0000-0000-0002-000000000011', 5, 3, 'Recovery', 2, 20, 'J-Band internal rotation - recovery.'),
        (v_p3_s1_id, '00000000-0000-0000-0002-000000000018', 6, 3, 'Recovery', 1, 2, 'Shoulder flexion stretch. Hold 45 seconds.');

    -- Session B: Peak overload
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p3_s2_id, '00000000-0000-0000-0002-000000000005', 1, 1, 'Warmup', 2, 8, 'Reverse throws with 6oz.'),
        (v_p3_s2_id, '00000000-0000-0000-0002-000000000008', 2, 2, 'Main Work', 4, 5, 'Step-behind with 9oz. Commit to throws.'),
        (v_p3_s2_id, '00000000-0000-0000-0002-000000000009', 3, 2, 'Main Work', 3, 5, 'Pivot pick MAX INTENT with 11oz. Peak overload.'),
        (v_p3_s2_id, '00000000-0000-0000-0002-000000000008', 4, 2, 'Main Work', 2, 5, '9oz finisher throws.'),
        (v_p3_s2_id, '00000000-0000-0000-0002-000000000012', 5, 3, 'Recovery', 2, 20, 'J-Band external rotation.'),
        (v_p3_s2_id, '00000000-0000-0000-0002-000000000014', 6, 3, 'Recovery', 2, 10, 'Prone Y-T-W for scapular health.');

    -- Session C: Velocity intent
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p3_s3_id, '00000000-0000-0000-0002-000000000003', 1, 1, 'Warmup', 2, 10, 'Rocker throws light warmup.'),
        (v_p3_s3_id, '00000000-0000-0000-0002-000000000007', 2, 2, 'Velocity Work', 4, 6, 'Pull-down throws with 7oz. FULL INTENT.'),
        (v_p3_s3_id, '00000000-0000-0000-0002-000000000009', 3, 2, 'Velocity Work', 3, 4, '11oz pivot picks. Peak arm strength.'),
        (v_p3_s3_id, '00000000-0000-0000-0002-000000000007', 4, 2, 'Velocity Work', 2, 5, 'Pull-downs - leave it all out there.'),
        (v_p3_s3_id, '00000000-0000-0000-0002-000000000015', 5, 3, 'Recovery', 2, 15, 'Scap push-ups.'),
        (v_p3_s3_id, '00000000-0000-0000-0002-000000000018', 6, 3, 'Recovery', 2, 1, 'Shoulder stretches. Hold 60 seconds each.');

    -- Add Exercises to Phase 4 Sessions
    -- Session A: Return to regulation
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p4_s1_id, '00000000-0000-0000-0002-000000000003', 1, 1, 'Warmup', 2, 10, 'Rocker throws with 4oz.'),
        (v_p4_s1_id, '00000000-0000-0000-0002-000000000004', 2, 1, 'Warmup', 2, 8, 'Walking windups with 5oz.'),
        (v_p4_s1_id, '00000000-0000-0000-0002-000000000010', 3, 2, 'Transfer', 4, 15, 'Mound work - regulation ball. 80% effort, feel the difference.'),
        (v_p4_s1_id, '00000000-0000-0000-0002-000000000010', 4, 2, 'Transfer', 2, 10, 'Regulation at 85% intent.'),
        (v_p4_s1_id, '00000000-0000-0000-0002-000000000011', 5, 3, 'Arm Care', 2, 15, 'J-Band internal rotation.'),
        (v_p4_s1_id, '00000000-0000-0000-0002-000000000012', 6, 3, 'Arm Care', 2, 15, 'J-Band external rotation.');

    -- Session B: Command development
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p4_s2_id, '00000000-0000-0000-0002-000000000002', 1, 1, 'Warmup', 2, 10, 'Pivot pickoffs with 4oz.'),
        (v_p4_s2_id, '00000000-0000-0000-0002-000000000010', 2, 2, 'Command', 1, 20, 'Fastball command - up/down. Hit spots.'),
        (v_p4_s2_id, '00000000-0000-0000-0002-000000000010', 3, 2, 'Command', 1, 20, 'Fastball command - in/out.'),
        (v_p4_s2_id, '00000000-0000-0000-0002-000000000010', 4, 2, 'Command', 1, 15, 'Off-speed work if applicable.'),
        (v_p4_s2_id, '00000000-0000-0000-0002-000000000013', 5, 3, 'Arm Care', 2, 12, '90/90 external rotation.'),
        (v_p4_s2_id, '00000000-0000-0000-0002-000000000014', 6, 3, 'Arm Care', 2, 10, 'Prone Y-T-W.');

    -- Session C: Game prep bullpen
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p4_s3_id, '00000000-0000-0000-0002-000000000001', 1, 1, 'Warmup', 2, 15, 'Wrist flicks to start.'),
        (v_p4_s3_id, '00000000-0000-0000-0002-000000000003', 2, 1, 'Warmup', 2, 10, 'Rocker throws to loosen.'),
        (v_p4_s3_id, '00000000-0000-0000-0002-000000000010', 3, 2, 'Game Prep', 1, 25, 'Simulated inning 1 - game intensity.'),
        (v_p4_s3_id, '00000000-0000-0000-0002-000000000010', 4, 2, 'Game Prep', 1, 25, 'Simulated inning 2 - maintain stuff.'),
        (v_p4_s3_id, '00000000-0000-0000-0002-000000000010', 5, 2, 'Game Prep', 1, 10, 'Finisher - best stuff.'),
        (v_p4_s3_id, '00000000-0000-0000-0002-000000000018', 6, 3, 'Recovery', 2, 1, 'Post-bullpen stretching. Hold 45-60 seconds.');

    RAISE NOTICE 'Added exercises to all Weighted Ball sessions';

    -- Add to Program Library
    INSERT INTO program_library (
        id, title, description, category, duration_weeks, difficulty_level,
        equipment_required, program_id, is_featured, tags, author
    ) VALUES (
        gen_random_uuid(),
        'Weighted Ball Progression',
        'Progressive 8-week weighted ball program to build arm strength and develop velocity. Uses Driveline methodology with systematic overload (heavy balls) and underload (light balls) training. Progresses through Foundation, Load Development, Overload, and Transfer phases. Perfect for pitchers looking to add velocity safely.',
        'baseball',
        8,
        'intermediate',
        ARRAY['weighted_baseballs_2oz_11oz', 'regulation_baseball', 'target_net', 'j_bands'],
        v_program_id,
        true,
        ARRAY['baseball', 'pitcher', 'weighted-ball', 'arm-strength', 'velocity', 'driveline'],
        'PT Performance'
    ) RETURNING id INTO v_library_id;

    RAISE NOTICE 'Created program_library entry: %', v_library_id;
    RAISE NOTICE 'Weighted Ball Progression program creation complete!';
END $$;

-- ============================================================================
-- 3. ARM CARE & MAINTENANCE PROGRAM (Ongoing)
-- ============================================================================

DO $$
DECLARE
    v_program_id UUID;
    v_phase_daily_id UUID;
    v_phase_weekly_id UUID;
    v_library_id UUID;
    v_daily_pre_id UUID;
    v_daily_post_id UUID;
    v_weekly_strength_id UUID;
    v_weekly_recovery_id UUID;
BEGIN
    -- Create Program
    INSERT INTO programs (
        id, patient_id, name, description, status, metadata
    ) VALUES (
        gen_random_uuid(),
        NULL,
        'Arm Care & Maintenance',
        'Comprehensive arm care program for pitchers. Combines daily maintenance routines with weekly strength and recovery work to keep the throwing arm healthy and ready.',
        'active',
        jsonb_build_object(
            'duration_weeks', 52,  -- Ongoing/repeating
            'sessions_per_week', 5,
            'sport', 'baseball',
            'position', 'pitcher',
            'category', 'arm_care',
            'is_system_template', true,
            'session_duration_minutes', '15-20',
            'usage', 'ongoing_maintenance'
        )
    ) RETURNING id INTO v_program_id;

    RAISE NOTICE 'Created Arm Care & Maintenance program: %', v_program_id;

    -- Phase: Daily Routines
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (
        gen_random_uuid(), v_program_id, 'Daily Arm Care', 1, 52,
        'Maintain shoulder health, prevent injury, prepare arm for throwing demands.',
        'Perform pre-throwing and post-throwing routines every throwing day. 15-20 minutes each.'
    ) RETURNING id INTO v_phase_daily_id;

    -- Phase: Weekly Strength/Recovery
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
    VALUES (
        gen_random_uuid(), v_program_id, 'Weekly Strength & Recovery', 2, 52,
        'Build shoulder strength, scapular stability, and forearm endurance. Full recovery protocols.',
        '2x per week on non-throwing days. One strength focus, one recovery focus.'
    ) RETURNING id INTO v_phase_weekly_id;

    RAISE NOTICE 'Created 2 phases for Arm Care program';

    -- Daily Sessions
    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase_daily_id, 'Pre-Throwing Routine', 1, NULL, true,
         '15-minute pre-throwing arm care. Perform before any throwing activity.')
    RETURNING id INTO v_daily_pre_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase_daily_id, 'Post-Throwing Routine', 2, NULL, true,
         '15-minute post-throwing recovery. Perform immediately after throwing.')
    RETURNING id INTO v_daily_post_id;

    -- Weekly Sessions
    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase_weekly_id, 'Shoulder Strength Day', 3, 2, false,
         '20-minute shoulder strengthening session. Perform on non-throwing day.')
    RETURNING id INTO v_weekly_strength_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES
        (gen_random_uuid(), v_phase_weekly_id, 'Recovery & Mobility Day', 4, 4, false,
         '20-minute recovery session. Focus on soft tissue and mobility.')
    RETURNING id INTO v_weekly_recovery_id;

    RAISE NOTICE 'Created 4 sessions for Arm Care program';

    -- Pre-Throwing Routine Exercises
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_daily_pre_id, '00000000-0000-0000-0002-000000000011', 1, 1, 'J-Band Series', 1, 15, 'Internal rotation - slow, controlled.'),
        (v_daily_pre_id, '00000000-0000-0000-0002-000000000012', 2, 1, 'J-Band Series', 1, 15, 'External rotation - full range.'),
        (v_daily_pre_id, '00000000-0000-0000-0002-000000000011', 3, 1, 'J-Band Series', 1, 15, 'Internal rotation - increase tempo.'),
        (v_daily_pre_id, '00000000-0000-0000-0002-000000000012', 4, 1, 'J-Band Series', 1, 15, 'External rotation - throwing tempo.'),
        (v_daily_pre_id, '00000000-0000-0000-0002-000000000015', 5, 2, 'Activation', 2, 12, 'Scap push-ups for serratus activation.'),
        (v_daily_pre_id, '00000000-0000-0000-0002-000000000014', 6, 2, 'Activation', 1, 8, 'Prone Y-T-W. Light or no weight.'),
        (v_daily_pre_id, '00000000-0000-0000-0002-000000000016', 7, 3, 'Forearm', 1, 20, 'Forearm pronation/supination.'),
        (v_daily_pre_id, '00000000-0000-0000-0002-000000000017', 8, 3, 'Forearm', 1, 15, 'Wrist flexion/extension.');

    -- Post-Throwing Routine Exercises
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_daily_post_id, '00000000-0000-0000-0002-000000000011', 1, 1, 'Flush', 2, 20, 'J-Band internal rotation - light flush.'),
        (v_daily_post_id, '00000000-0000-0000-0002-000000000012', 2, 1, 'Flush', 2, 20, 'J-Band external rotation - recovery tempo.'),
        (v_daily_post_id, '00000000-0000-0000-0002-000000000018', 3, 2, 'Stretching', 1, 2, 'Shoulder flexion stretch. Hold 45 seconds each side.'),
        (v_daily_post_id, '00000000-0000-0000-0002-000000000018', 4, 2, 'Stretching', 1, 2, 'Cross-body stretch. Hold 30 seconds each.'),
        (v_daily_post_id, '00000000-0000-0000-0002-000000000016', 5, 3, 'Forearm Recovery', 1, 25, 'Light forearm pronation/supination.'),
        (v_daily_post_id, '00000000-0000-0000-0002-000000000017', 6, 3, 'Forearm Recovery', 1, 20, 'Light wrist flexion/extension.');

    -- Weekly Strength Session Exercises
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_weekly_strength_id, '00000000-0000-0000-0002-000000000013', 1, 1, 'Rotator Cuff', 3, 12, '90/90 external rotation. 3-5 lbs.'),
        (v_weekly_strength_id, '00000000-0000-0000-0002-000000000014', 2, 1, 'Rotator Cuff', 3, 10, 'Prone Y-T-W. 2-3 lbs.'),
        (v_weekly_strength_id, '00000000-0000-0000-0002-000000000015', 3, 2, 'Scapular', 3, 15, 'Scap push-ups. Slow tempo.'),
        (v_weekly_strength_id, '00000000-0000-0000-0002-000000000011', 4, 2, 'Scapular', 2, 15, 'J-Band rows for mid-trap.'),
        (v_weekly_strength_id, '00000000-0000-0000-0002-000000000016', 5, 3, 'Forearm', 3, 15, 'Forearm pronation/supination. Progressive load.'),
        (v_weekly_strength_id, '00000000-0000-0000-0002-000000000017', 6, 3, 'Forearm', 3, 15, 'Wrist flexion/extension. Progressive load.');

    -- Weekly Recovery Session Exercises
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_weekly_recovery_id, '00000000-0000-0000-0002-000000000018', 1, 1, 'Stretching', 2, 2, 'Shoulder flexion stretch. Hold 60 seconds.'),
        (v_weekly_recovery_id, '00000000-0000-0000-0002-000000000018', 2, 1, 'Stretching', 2, 2, 'Cross-body stretch. Hold 45 seconds.'),
        (v_weekly_recovery_id, '00000000-0000-0000-0002-000000000018', 3, 1, 'Stretching', 2, 2, 'Sleeper stretch if tolerated. Hold 30 seconds.'),
        (v_weekly_recovery_id, '00000000-0000-0000-0002-000000000011', 4, 2, 'Light Flush', 2, 25, 'J-Band internal rotation. Very light.'),
        (v_weekly_recovery_id, '00000000-0000-0000-0002-000000000012', 5, 2, 'Light Flush', 2, 25, 'J-Band external rotation. Blood flow focus.'),
        (v_weekly_recovery_id, '00000000-0000-0000-0002-000000000023', 6, 3, 'Mobility', 2, 10, 'Hip 90/90 stretch. Total body recovery.');

    RAISE NOTICE 'Added exercises to all Arm Care sessions';

    -- Add to Program Library
    INSERT INTO program_library (
        id, title, description, category, duration_weeks, difficulty_level,
        equipment_required, program_id, is_featured, tags, author
    ) VALUES (
        gen_random_uuid(),
        'Arm Care & Maintenance',
        'Essential arm care program for every pitcher. Includes pre-throwing warmup routines, post-throwing recovery protocols, weekly shoulder strengthening, and mobility work. 15-20 minute sessions designed for daily/weekly use throughout the season. The foundation of a healthy throwing arm.',
        'baseball',
        52,  -- Ongoing
        'beginner',
        ARRAY['j_bands', 'light_dumbbells', 'foam_roller'],
        v_program_id,
        true,
        ARRAY['baseball', 'pitcher', 'arm-care', 'shoulder', 'prehab', 'maintenance', 'recovery'],
        'PT Performance'
    ) RETURNING id INTO v_library_id;

    RAISE NOTICE 'Created program_library entry: %', v_library_id;
    RAISE NOTICE 'Arm Care & Maintenance program creation complete!';
END $$;

-- ============================================================================
-- 4. VELOCITY DEVELOPMENT PROGRAM (12 Weeks)
-- ============================================================================

DO $$
DECLARE
    v_program_id UUID;
    v_phase1_id UUID;
    v_phase2_id UUID;
    v_phase3_id UUID;
    v_library_id UUID;
    -- Phase 1 Sessions
    v_p1_throw1_id UUID; v_p1_throw2_id UUID; v_p1_str1_id UUID; v_p1_str2_id UUID;
    -- Phase 2 Sessions
    v_p2_throw1_id UUID; v_p2_throw2_id UUID; v_p2_power1_id UUID; v_p2_power2_id UUID;
    -- Phase 3 Sessions
    v_p3_throw1_id UUID; v_p3_throw2_id UUID; v_p3_intent1_id UUID; v_p3_intent2_id UUID;
BEGIN
    -- Create Program
    INSERT INTO programs (
        id, patient_id, name, description, status, metadata
    ) VALUES (
        gen_random_uuid(),
        NULL,
        'Velocity Development Program',
        'Comprehensive 12-week velocity development program combining strength training, power development, and intent-based throwing. Build the physical foundation and throwing mechanics to maximize velocity potential.',
        'active',
        jsonb_build_object(
            'duration_weeks', 12,
            'sessions_per_week', 4,
            'sport', 'baseball',
            'position', 'pitcher',
            'category', 'velocity',
            'is_system_template', true,
            'session_split', '2_throwing_2_strength',
            'progression_model', 'block_periodization'
        )
    ) RETURNING id INTO v_program_id;

    RAISE NOTICE 'Created Velocity Development program: %', v_program_id;

    -- Phase 1: Strength Foundation (Weeks 1-4)
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes, constraints)
    VALUES (
        gen_random_uuid(), v_program_id, 'Phase 1: Strength Foundation', 1, 4,
        'Build foundational lower body strength and hip mobility. Establish movement quality that translates to pitching.',
        'Focus: Lower body power base, hip mobility, core stability. 2 strength + 2 throwing days per week.',
        jsonb_build_object(
            'strength_focus', ARRAY['trap_bar_deadlift', 'front_squat', 'single_leg_rdl'],
            'mobility_focus', ARRAY['hip_90_90', 'lateral_lunge'],
            'throwing_intensity', 'moderate',
            'progression_criteria', jsonb_build_object('strength_gains', true, 'mobility_improvement', true)
        )
    ) RETURNING id INTO v_phase1_id;

    -- Phase 2: Power Development (Weeks 5-8)
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes, constraints)
    VALUES (
        gen_random_uuid(), v_program_id, 'Phase 2: Power Development', 2, 4,
        'Convert strength to explosive power. Med ball work, plyometrics, and weighted ball training.',
        'Focus: Rotational power, lower body explosiveness, weighted ball integration. Maintain strength base.',
        jsonb_build_object(
            'power_focus', ARRAY['med_ball_rotational', 'med_ball_scoop', 'box_jump', 'lateral_bound'],
            'weighted_ball', true,
            'throwing_intensity', 'moderate_high',
            'progression_criteria', jsonb_build_object('power_metrics', true, 'throwing_velocity', true)
        )
    ) RETURNING id INTO v_phase2_id;

    -- Phase 3: Intent Training (Weeks 9-12)
    INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes, constraints)
    VALUES (
        gen_random_uuid(), v_program_id, 'Phase 3: Intent Training', 3, 4,
        'Peak velocity through max intent throwing. Express developed strength and power on the mound.',
        'Focus: Max effort throws, bullpen intensity, velocity expression. Maintain power base, reduce volume.',
        jsonb_build_object(
            'intent_level', 'max',
            'throwing_intensity', 'high',
            'strength_maintenance', true,
            'recovery_priority', 'high',
            'progression_criteria', jsonb_build_object('peak_velocity', true, 'consistency', true)
        )
    ) RETURNING id INTO v_phase3_id;

    RAISE NOTICE 'Created 3 phases for Velocity Development';

    -- Phase 1 Sessions (2 throwing, 2 strength)
    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase1_id, 'Throwing Day A - Foundation', 1, 1, true,
         'Foundation throwing. Focus on mechanics and arm path. Moderate intent.')
    RETURNING id INTO v_p1_throw1_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase1_id, 'Strength Day A - Lower Body', 2, 2, false,
         'Lower body strength focus. Deadlift and squat patterns.')
    RETURNING id INTO v_p1_str1_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase1_id, 'Throwing Day B - Mechanics', 3, 4, true,
         'Mechanics focus. Hip mobility integration with throwing.')
    RETURNING id INTO v_p1_throw2_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase1_id, 'Strength Day B - Single Leg', 4, 5, false,
         'Single leg strength and hip mobility. Unilateral focus.')
    RETURNING id INTO v_p1_str2_id;

    -- Phase 2 Sessions (2 throwing with weighted balls, 2 power)
    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase2_id, 'Throwing Day A - Weighted Balls', 5, 1, true,
         'Weighted ball work. Overload and underload throws.')
    RETURNING id INTO v_p2_throw1_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase2_id, 'Power Day A - Med Ball', 6, 2, false,
         'Med ball power development. Rotational and scoop throws.')
    RETURNING id INTO v_p2_power1_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase2_id, 'Throwing Day B - Velocity Intent', 7, 4, true,
         'Increasing velocity intent. Weighted ball to regulation transition.')
    RETURNING id INTO v_p2_throw2_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase2_id, 'Power Day B - Plyometrics', 8, 5, false,
         'Lower body plyometrics. Explosive power development.')
    RETURNING id INTO v_p2_power2_id;

    -- Phase 3 Sessions (2 max intent throwing, 2 maintenance)
    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase3_id, 'Max Intent Day A', 9, 1, true,
         'MAX INTENT throwing. Pull-downs and bullpen work.')
    RETURNING id INTO v_p3_throw1_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase3_id, 'Maintenance Day A', 10, 2, false,
         'Strength maintenance and recovery. Keep gains, reduce fatigue.')
    RETURNING id INTO v_p3_intent1_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase3_id, 'Max Intent Day B', 11, 4, true,
         'MAX INTENT continuation. Express velocity on mound.')
    RETURNING id INTO v_p3_throw2_id;

    INSERT INTO sessions (id, phase_id, name, sequence, weekday, is_throwing_day, notes)
    VALUES (gen_random_uuid(), v_phase3_id, 'Maintenance Day B', 12, 5, false,
         'Power maintenance and arm care. Recovery focused.')
    RETURNING id INTO v_p3_intent2_id;

    RAISE NOTICE 'Created 12 sessions for Velocity Development';

    -- Phase 1 Exercises
    -- Throwing Day A
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p1_throw1_id, '00000000-0000-0000-0002-000000000011', 1, 1, 'Warmup', 2, 15, 'J-Band warmup.'),
        (v_p1_throw1_id, '00000000-0000-0000-0002-000000000012', 2, 1, 'Warmup', 2, 15, 'J-Band external rotation.'),
        (v_p1_throw1_id, '00000000-0000-0000-0002-000000000003', 3, 2, 'Throwing', 4, 10, 'Rocker throws. Build rhythm.'),
        (v_p1_throw1_id, '00000000-0000-0000-0002-000000000004', 4, 2, 'Throwing', 3, 8, 'Walking windups. Momentum building.'),
        (v_p1_throw1_id, '00000000-0000-0000-0002-000000000010', 5, 2, 'Throwing', 2, 15, 'Flat ground work. 75-80% intent.'),
        (v_p1_throw1_id, '00000000-0000-0000-0002-000000000014', 6, 3, 'Arm Care', 2, 10, 'Prone Y-T-W post-throwing.');

    -- Strength Day A
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p1_str1_id, '00000000-0000-0000-0002-000000000023', 1, 1, 'Warmup', 2, 10, 'Hip 90/90 mobility.'),
        (v_p1_str1_id, '00000000-0000-0000-0002-000000000019', 2, 2, 'Primary', 4, 5, 'Trap bar deadlift. Build to working weight.'),
        (v_p1_str1_id, '00000000-0000-0000-0002-000000000020', 3, 2, 'Primary', 4, 6, 'Front squat. Upright torso.'),
        (v_p1_str1_id, '00000000-0000-0000-0002-000000000022', 4, 3, 'Accessory', 3, 8, 'Lateral lunge each side.'),
        (v_p1_str1_id, '00000000-0000-0000-0002-000000000029', 5, 3, 'Accessory', 3, 5, 'Broad jump for power.'),
        (v_p1_str1_id, '00000000-0000-0000-0002-000000000015', 6, 4, 'Core', 3, 15, 'Scap push-ups.');

    -- Throwing Day B
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p1_throw2_id, '00000000-0000-0000-0002-000000000023', 1, 1, 'Warmup', 2, 10, 'Hip 90/90 pre-throwing.'),
        (v_p1_throw2_id, '00000000-0000-0000-0002-000000000011', 2, 1, 'Warmup', 2, 15, 'J-Band series.'),
        (v_p1_throw2_id, '00000000-0000-0000-0002-000000000005', 3, 2, 'Throwing', 3, 8, 'Reverse throws. Hip-driven.'),
        (v_p1_throw2_id, '00000000-0000-0000-0002-000000000004', 4, 2, 'Throwing', 3, 10, 'Walking windups.'),
        (v_p1_throw2_id, '00000000-0000-0000-0002-000000000010', 5, 2, 'Throwing', 2, 20, 'Flat ground. Focus on mechanics.'),
        (v_p1_throw2_id, '00000000-0000-0000-0002-000000000018', 6, 3, 'Recovery', 2, 2, 'Shoulder stretching.');

    -- Strength Day B
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p1_str2_id, '00000000-0000-0000-0002-000000000023', 1, 1, 'Warmup', 3, 10, 'Hip 90/90 thorough warmup.'),
        (v_p1_str2_id, '00000000-0000-0000-0002-000000000021', 2, 2, 'Primary', 4, 8, 'Single-leg RDL each side.'),
        (v_p1_str2_id, '00000000-0000-0000-0002-000000000022', 3, 2, 'Primary', 4, 10, 'Lateral lunge each side.'),
        (v_p1_str2_id, '00000000-0000-0000-0002-000000000028', 4, 3, 'Power', 3, 6, 'Lateral bounds each direction.'),
        (v_p1_str2_id, '00000000-0000-0000-0002-000000000014', 5, 4, 'Arm Care', 2, 10, 'Prone Y-T-W.'),
        (v_p1_str2_id, '00000000-0000-0000-0002-000000000016', 6, 4, 'Arm Care', 2, 15, 'Forearm work.');

    -- Phase 2 Exercises
    -- Throwing Day A (Weighted Balls)
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p2_throw1_id, '00000000-0000-0000-0002-000000000011', 1, 1, 'Warmup', 2, 15, 'J-Band series.'),
        (v_p2_throw1_id, '00000000-0000-0000-0002-000000000004', 2, 2, 'Light Balls', 3, 8, 'Walking windups with 5oz.'),
        (v_p2_throw1_id, '00000000-0000-0000-0002-000000000005', 3, 2, 'Light Balls', 3, 8, 'Reverse throws with 6oz.'),
        (v_p2_throw1_id, '00000000-0000-0000-0002-000000000007', 4, 3, 'Heavy Balls', 3, 6, 'Pull-downs with 7oz. BUILD INTENT.'),
        (v_p2_throw1_id, '00000000-0000-0000-0002-000000000008', 5, 3, 'Heavy Balls', 2, 5, 'Step-behind with 9oz.'),
        (v_p2_throw1_id, '00000000-0000-0000-0002-000000000012', 6, 4, 'Arm Care', 2, 20, 'J-Band flush.');

    -- Power Day A (Med Ball)
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p2_power1_id, '00000000-0000-0000-0002-000000000023', 1, 1, 'Warmup', 2, 10, 'Hip 90/90.'),
        (v_p2_power1_id, '00000000-0000-0000-0002-000000000025', 2, 2, 'Rotational', 4, 8, 'Med ball rotational throws. MAX EFFORT each rep.'),
        (v_p2_power1_id, '00000000-0000-0000-0002-000000000024', 3, 2, 'Rotational', 4, 8, 'Med ball scoop toss. Hip extension power.'),
        (v_p2_power1_id, '00000000-0000-0000-0002-000000000026', 4, 3, 'Total Body', 3, 8, 'Med ball overhead slam.'),
        (v_p2_power1_id, '00000000-0000-0000-0002-000000000019', 5, 4, 'Strength', 3, 5, 'Trap bar deadlift maintenance.'),
        (v_p2_power1_id, '00000000-0000-0000-0002-000000000015', 6, 5, 'Core', 2, 15, 'Scap push-ups.');

    -- Throwing Day B (Velocity Intent)
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p2_throw2_id, '00000000-0000-0000-0002-000000000003', 1, 1, 'Warmup', 2, 10, 'Rocker throws light.'),
        (v_p2_throw2_id, '00000000-0000-0000-0002-000000000007', 2, 2, 'Overload', 3, 6, 'Pull-downs 7oz. INTENT building.'),
        (v_p2_throw2_id, '00000000-0000-0000-0002-000000000010', 3, 3, 'Transfer', 3, 15, 'Regulation ball - carry intent.'),
        (v_p2_throw2_id, '00000000-0000-0000-0002-000000000010', 4, 3, 'Transfer', 2, 10, 'Increasing intent each set.'),
        (v_p2_throw2_id, '00000000-0000-0000-0002-000000000014', 5, 4, 'Arm Care', 2, 10, 'Prone Y-T-W.'),
        (v_p2_throw2_id, '00000000-0000-0000-0002-000000000018', 6, 4, 'Arm Care', 2, 2, 'Shoulder stretching.');

    -- Power Day B (Plyometrics)
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p2_power2_id, '00000000-0000-0000-0002-000000000029', 1, 1, 'Warmup', 2, 5, 'Broad jump warmup.'),
        (v_p2_power2_id, '00000000-0000-0000-0002-000000000027', 2, 2, 'Plyos', 4, 5, 'Box jumps. Full extension.'),
        (v_p2_power2_id, '00000000-0000-0000-0002-000000000028', 3, 2, 'Plyos', 4, 6, 'Lateral bounds. Stick landings.'),
        (v_p2_power2_id, '00000000-0000-0000-0002-000000000029', 4, 2, 'Plyos', 3, 6, 'Broad jump max distance.'),
        (v_p2_power2_id, '00000000-0000-0000-0002-000000000021', 5, 3, 'Strength', 3, 8, 'Single-leg RDL maintenance.'),
        (v_p2_power2_id, '00000000-0000-0000-0002-000000000011', 6, 4, 'Arm Care', 2, 15, 'J-Band series.');

    -- Phase 3 Exercises
    -- Max Intent Day A
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p3_throw1_id, '00000000-0000-0000-0002-000000000011', 1, 1, 'Warmup', 2, 15, 'J-Band thorough warmup.'),
        (v_p3_throw1_id, '00000000-0000-0000-0002-000000000003', 2, 1, 'Warmup', 2, 10, 'Rocker throws to loosen.'),
        (v_p3_throw1_id, '00000000-0000-0000-0002-000000000007', 3, 2, 'Max Intent', 4, 5, 'Pull-downs with 7oz. MAX EFFORT.'),
        (v_p3_throw1_id, '00000000-0000-0000-0002-000000000010', 4, 3, 'Transfer', 3, 15, 'Flat ground MAX INTENT regulation.'),
        (v_p3_throw1_id, '00000000-0000-0000-0002-000000000010', 5, 3, 'Transfer', 2, 10, 'Bullpen work. Game intensity.'),
        (v_p3_throw1_id, '00000000-0000-0000-0002-000000000018', 6, 4, 'Recovery', 2, 2, 'Extended stretching protocol.');

    -- Maintenance Day A
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p3_intent1_id, '00000000-0000-0000-0002-000000000023', 1, 1, 'Mobility', 3, 10, 'Hip 90/90 thorough.'),
        (v_p3_intent1_id, '00000000-0000-0000-0002-000000000019', 2, 2, 'Strength', 3, 5, 'Trap bar deadlift maintenance - moderate load.'),
        (v_p3_intent1_id, '00000000-0000-0000-0002-000000000020', 3, 2, 'Strength', 3, 6, 'Front squat maintenance.'),
        (v_p3_intent1_id, '00000000-0000-0000-0002-000000000025', 4, 3, 'Power', 3, 6, 'Med ball rotational - maintain explosiveness.'),
        (v_p3_intent1_id, '00000000-0000-0000-0002-000000000014', 5, 4, 'Arm Care', 2, 10, 'Prone Y-T-W.'),
        (v_p3_intent1_id, '00000000-0000-0000-0002-000000000016', 6, 4, 'Arm Care', 2, 15, 'Forearm work.');

    -- Max Intent Day B
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p3_throw2_id, '00000000-0000-0000-0002-000000000012', 1, 1, 'Warmup', 2, 15, 'J-Band series.'),
        (v_p3_throw2_id, '00000000-0000-0000-0002-000000000004', 2, 1, 'Warmup', 2, 8, 'Walking windups to warm up.'),
        (v_p3_throw2_id, '00000000-0000-0000-0002-000000000009', 3, 2, 'Max Intent', 3, 4, 'Pivot picks 11oz. PEAK OVERLOAD.'),
        (v_p3_throw2_id, '00000000-0000-0000-0002-000000000010', 4, 3, 'Transfer', 1, 25, 'Simulated inning - max stuff.'),
        (v_p3_throw2_id, '00000000-0000-0000-0002-000000000010', 5, 3, 'Transfer', 1, 20, 'Second inning - maintain velocity.'),
        (v_p3_throw2_id, '00000000-0000-0000-0002-000000000018', 6, 4, 'Recovery', 3, 2, 'Full recovery protocol.');

    -- Maintenance Day B
    INSERT INTO session_exercises (session_id, exercise_template_id, sequence, block_number, block_label, target_sets, target_reps, notes)
    VALUES
        (v_p3_intent2_id, '00000000-0000-0000-0002-000000000023', 1, 1, 'Mobility', 3, 10, 'Hip 90/90.'),
        (v_p3_intent2_id, '00000000-0000-0000-0002-000000000024', 2, 2, 'Power', 3, 6, 'Med ball scoop toss - maintain power.'),
        (v_p3_intent2_id, '00000000-0000-0000-0002-000000000027', 3, 2, 'Power', 3, 5, 'Box jumps maintenance.'),
        (v_p3_intent2_id, '00000000-0000-0000-0002-000000000011', 4, 3, 'Arm Care', 2, 20, 'J-Band internal rotation.'),
        (v_p3_intent2_id, '00000000-0000-0000-0002-000000000012', 5, 3, 'Arm Care', 2, 20, 'J-Band external rotation.'),
        (v_p3_intent2_id, '00000000-0000-0000-0002-000000000018', 6, 4, 'Recovery', 2, 2, 'Full shoulder stretching.');

    RAISE NOTICE 'Added exercises to all Velocity Development sessions';

    -- Add to Program Library
    INSERT INTO program_library (
        id, title, description, category, duration_weeks, difficulty_level,
        equipment_required, program_id, is_featured, tags, author
    ) VALUES (
        gen_random_uuid(),
        'Velocity Development Program',
        'Complete 12-week velocity development program for pitchers serious about adding MPH. Combines foundational strength training, explosive power development, and intent-based throwing into a systematic approach. Progress through Strength Foundation, Power Development, and Intent Training phases. 4 sessions per week (2 throwing, 2 strength/power). Designed to maximize velocity potential safely.',
        'baseball',
        12,
        'advanced',
        ARRAY['barbell', 'trap_bar', 'dumbbells', 'weighted_baseballs', 'medicine_balls', 'plyo_box', 'j_bands'],
        v_program_id,
        true,
        ARRAY['baseball', 'pitcher', 'velocity', 'power', 'strength', 'explosive'],
        'PT Performance'
    ) RETURNING id INTO v_library_id;

    RAISE NOTICE 'Created program_library entry: %', v_library_id;
    RAISE NOTICE 'Velocity Development Program creation complete!';
END $$;

-- ============================================================================
-- 5. VERIFICATION QUERIES
-- ============================================================================

DO $$
DECLARE
    v_program_count INT;
    v_phase_count INT;
    v_session_count INT;
    v_exercise_count INT;
    v_library_count INT;
BEGIN
    -- Count programs created
    SELECT COUNT(*) INTO v_program_count
    FROM programs
    WHERE name IN ('Weighted Ball Progression', 'Arm Care & Maintenance', 'Velocity Development Program');

    -- Count phases
    SELECT COUNT(*) INTO v_phase_count
    FROM phases ph
    JOIN programs p ON p.id = ph.program_id
    WHERE p.name IN ('Weighted Ball Progression', 'Arm Care & Maintenance', 'Velocity Development Program');

    -- Count sessions
    SELECT COUNT(*) INTO v_session_count
    FROM sessions s
    JOIN phases ph ON ph.id = s.phase_id
    JOIN programs p ON p.id = ph.program_id
    WHERE p.name IN ('Weighted Ball Progression', 'Arm Care & Maintenance', 'Velocity Development Program');

    -- Count exercise assignments
    SELECT COUNT(*) INTO v_exercise_count
    FROM session_exercises se
    JOIN sessions s ON s.id = se.session_id
    JOIN phases ph ON ph.id = s.phase_id
    JOIN programs p ON p.id = ph.program_id
    WHERE p.name IN ('Weighted Ball Progression', 'Arm Care & Maintenance', 'Velocity Development Program');

    -- Count library entries
    SELECT COUNT(*) INTO v_library_count
    FROM program_library
    WHERE title IN ('Weighted Ball Progression', 'Arm Care & Maintenance', 'Velocity Development Program');

    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Baseball Pack - Pitcher Programs Migration Complete';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'PROGRAMS CREATED: %', v_program_count;
    RAISE NOTICE '  1. Weighted Ball Progression (8 weeks, 3x/week)';
    RAISE NOTICE '  2. Arm Care & Maintenance (Ongoing, 4-5x/week)';
    RAISE NOTICE '  3. Velocity Development Program (12 weeks, 4x/week)';
    RAISE NOTICE '';
    RAISE NOTICE 'STRUCTURE:';
    RAISE NOTICE '  - Phases: %', v_phase_count;
    RAISE NOTICE '  - Sessions: %', v_session_count;
    RAISE NOTICE '  - Exercise assignments: %', v_exercise_count;
    RAISE NOTICE '  - Program Library entries: %', v_library_count;
    RAISE NOTICE '';
    RAISE NOTICE 'TAGS COVERAGE:';
    RAISE NOTICE '  - baseball, pitcher, weighted-ball, arm-strength, velocity, driveline';
    RAISE NOTICE '  - arm-care, shoulder, prehab, maintenance, recovery';
    RAISE NOTICE '  - power, strength, explosive';
    RAISE NOTICE '============================================================';

    IF v_program_count < 3 THEN
        RAISE WARNING 'Expected 3 programs, got %. Check for conflicts.', v_program_count;
    END IF;

    IF v_library_count < 3 THEN
        RAISE WARNING 'Expected 3 library entries, got %. Check for conflicts.', v_library_count;
    END IF;
END $$;
