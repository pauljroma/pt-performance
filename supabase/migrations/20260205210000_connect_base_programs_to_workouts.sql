-- Connect BASE pack programs from program_library to actual workout content
-- This creates the programs/phases/sessions structure for seeded programs
--
-- Build 440+ - Fix: Users can now see workouts after enrolling in BASE programs
--
-- Problem: program_library entries from XLS have program_id = NULL
-- Solution: Create programs structure and link via program_id

-- ============================================================================
-- Step 1: Create programs for BASE pack seeded entries
-- ============================================================================

DO $$
DECLARE
    v_foundation_program_id UUID;
    v_strength_builder_program_id UUID;
    v_mobility_program_id UUID;
    v_phase_id UUID;
    v_lower_body_template UUID;
    v_hinge_day_template UUID;
    v_mobility_template UUID;
    v_push_template UUID;
    v_pull_template UUID;
    v_heavy_legs_template UUID;
    week_num INT;
    day_num INT;
BEGIN
    -- ========================================================================
    -- Create workout templates first
    -- Using correct schema: id, name, description, category, difficulty, duration_minutes, exercises, tags
    -- ========================================================================

    -- WO-BASE-010: Foundation Lower Body
    INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags)
    VALUES (
        gen_random_uuid(),
        'Foundation Lower Body',
        'Full lower body workout focusing on squat patterns, hip hinges, and core stability. Perfect for beginners.',
        'lower',
        'beginner',
        45,
        '[
            {"exercise_name": "World Greatest Stretch", "block_name": "Warm-Up", "sequence": 1, "target_sets": 2, "target_reps": "5-6 each", "notes": "Dynamic hip opener"},
            {"exercise_name": "Goblet Squat", "block_name": "Main Work", "sequence": 2, "target_sets": 3, "target_reps": "10-12", "rest_period_seconds": 90, "notes": "Keep chest up, knees tracking over toes"},
            {"exercise_name": "Reverse Lunge", "block_name": "Main Work", "sequence": 3, "target_sets": 3, "target_reps": "10 each", "rest_period_seconds": 60, "notes": "Step back far enough to keep front knee behind toes"},
            {"exercise_name": "Push-Up", "block_name": "Main Work", "sequence": 4, "target_sets": 3, "target_reps": "10-15", "rest_period_seconds": 60, "notes": "Superset with rows"},
            {"exercise_name": "Bent Over Row", "block_name": "Main Work", "sequence": 5, "target_sets": 3, "target_reps": "10-12", "rest_period_seconds": 60, "notes": "Hinge at hips, pull to belly button"},
            {"exercise_name": "Glute Bridge", "block_name": "Finisher", "sequence": 6, "target_sets": 3, "target_reps": "15-20", "rest_period_seconds": 45, "notes": "Squeeze glutes at top"},
            {"exercise_name": "Plank", "block_name": "Finisher", "sequence": 7, "target_sets": 3, "target_reps": "30-45 sec", "rest_period_seconds": 30, "notes": "Keep hips level, engage core"}
        ]'::jsonb,
        '{lower-body,beginner,strength,squat,goblet-squat,lunge,core}'
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_lower_body_template;

    IF v_lower_body_template IS NULL THEN
        SELECT id INTO v_lower_body_template FROM system_workout_templates WHERE name = 'Foundation Lower Body' LIMIT 1;
    END IF;

    -- WO-BASE-011: Foundation Hinge Day
    INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags)
    VALUES (
        gen_random_uuid(),
        'Foundation Hinge Day',
        'Hip hinge focused workout with Romanian deadlifts and single-leg work. Builds posterior chain strength.',
        'lower',
        'beginner',
        45,
        '[
            {"exercise_name": "Cat-Cow", "block_name": "Warm-Up", "sequence": 1, "target_sets": 2, "target_reps": "10-12", "notes": "Flow smoothly between positions"},
            {"exercise_name": "Romanian Deadlift", "block_name": "Main Work", "sequence": 2, "target_sets": 3, "target_reps": "10-12", "rest_period_seconds": 90, "notes": "Push hips back, slight knee bend, feel hamstring stretch"},
            {"exercise_name": "Step-Up", "block_name": "Main Work", "sequence": 3, "target_sets": 3, "target_reps": "10 each", "rest_period_seconds": 60, "notes": "Drive through front heel"},
            {"exercise_name": "DB Shoulder Press", "block_name": "Main Work", "sequence": 4, "target_sets": 3, "target_reps": "10-12", "rest_period_seconds": 60, "notes": "Superset with pulldowns"},
            {"exercise_name": "Lat Pulldown", "block_name": "Main Work", "sequence": 5, "target_sets": 3, "target_reps": "10-12", "rest_period_seconds": 60, "notes": "Pull to upper chest, squeeze lats"},
            {"exercise_name": "Dead Bug", "block_name": "Core", "sequence": 6, "target_sets": 3, "target_reps": "10 each", "rest_period_seconds": 45, "notes": "Keep low back pressed into floor"},
            {"exercise_name": "Side Plank", "block_name": "Core", "sequence": 7, "target_sets": 2, "target_reps": "20-30 sec each", "rest_period_seconds": 30, "notes": "Stack hips, keep body straight"}
        ]'::jsonb,
        '{lower-body,beginner,hinge,rdl,posterior-chain,core}'
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_hinge_day_template;

    IF v_hinge_day_template IS NULL THEN
        SELECT id INTO v_hinge_day_template FROM system_workout_templates WHERE name = 'Foundation Hinge Day' LIMIT 1;
    END IF;

    -- WO-BASE-020: Mobility Flow
    INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags)
    VALUES (
        gen_random_uuid(),
        'Mobility Flow',
        'Full body mobility routine. Use as warm-up before workouts or standalone recovery session.',
        'mobility',
        'beginner',
        20,
        '[
            {"exercise_name": "Cat-Cow", "block_name": "Spine Mobility", "sequence": 1, "target_sets": 2, "target_reps": "10-12", "notes": "Smooth flow, breathe with movement"},
            {"exercise_name": "Thoracic Rotation", "block_name": "Spine Mobility", "sequence": 2, "target_sets": 2, "target_reps": "10 each", "notes": "Open chest toward ceiling"},
            {"exercise_name": "90/90 Hip Stretch", "block_name": "Hip Mobility", "sequence": 3, "target_sets": 1, "target_reps": "45 sec each", "notes": "Sit tall, rotate between positions"},
            {"exercise_name": "Hip Flexor Stretch", "block_name": "Hip Mobility", "sequence": 4, "target_sets": 1, "target_reps": "45 sec each", "notes": "Squeeze glute of back leg"},
            {"exercise_name": "Ankle Mobility", "block_name": "Lower Body", "sequence": 5, "target_sets": 2, "target_reps": "15 each", "notes": "Knee over toes, heel stays down"},
            {"exercise_name": "Shoulder Pass-Through", "block_name": "Upper Body", "sequence": 6, "target_sets": 2, "target_reps": "10", "notes": "Wide grip, keep arms straight"}
        ]'::jsonb,
        '{mobility,flexibility,recovery,warm-up,beginner}'
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_mobility_template;

    IF v_mobility_template IS NULL THEN
        SELECT id INTO v_mobility_template FROM system_workout_templates WHERE name = 'Mobility Flow' LIMIT 1;
    END IF;

    -- WO-BASE-013: Upper Body Push
    INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags)
    VALUES (
        gen_random_uuid(),
        'Upper Body Push',
        'Pressing focused workout targeting chest, shoulders, and triceps. Intermediate level with compound and isolation movements.',
        'push',
        'intermediate',
        50,
        '[
            {"exercise_name": "Shoulder Pass-Through", "block_name": "Warm-Up", "sequence": 1, "target_sets": 2, "target_reps": "10-15", "notes": "Use PVC or band, keep arms straight"},
            {"exercise_name": "Barbell Bench Press", "block_name": "Main Lifts", "sequence": 2, "target_sets": 4, "target_reps": "6-8", "rest_period_seconds": 120, "notes": "Retract shoulder blades, arch upper back"},
            {"exercise_name": "Barbell Overhead Press", "block_name": "Main Lifts", "sequence": 3, "target_sets": 4, "target_reps": "6-8", "rest_period_seconds": 90, "notes": "Brace core, press straight up"},
            {"exercise_name": "Incline DB Press", "block_name": "Accessory Work", "sequence": 4, "target_sets": 3, "target_reps": "8-12", "rest_period_seconds": 60, "notes": "30-45 degree incline"},
            {"exercise_name": "Lateral Raise", "block_name": "Accessory Work", "sequence": 5, "target_sets": 3, "target_reps": "12-15", "rest_period_seconds": 45, "notes": "Superset with pushdowns"},
            {"exercise_name": "Tricep Pushdown", "block_name": "Accessory Work", "sequence": 6, "target_sets": 3, "target_reps": "12-15", "rest_period_seconds": 45, "notes": "Keep elbows pinned"},
            {"exercise_name": "Dumbbell Flye", "block_name": "Accessory Work", "sequence": 7, "target_sets": 3, "target_reps": "10-12", "rest_period_seconds": 60, "notes": "Slight bend in elbows, stretch at bottom"}
        ]'::jsonb,
        '{upper-body,push,chest,shoulders,triceps,intermediate,strength}'
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_push_template;

    IF v_push_template IS NULL THEN
        SELECT id INTO v_push_template FROM system_workout_templates WHERE name = 'Upper Body Push' LIMIT 1;
    END IF;

    -- WO-BASE-014: Upper Body Pull
    INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags)
    VALUES (
        gen_random_uuid(),
        'Upper Body Pull',
        'Pulling focused workout targeting back and biceps. Compound pulls with targeted isolation work.',
        'pull',
        'intermediate',
        50,
        '[
            {"exercise_name": "Face Pulls", "block_name": "Warm-Up", "sequence": 1, "target_sets": 2, "target_reps": "15-20", "notes": "Light weight, external rotation at top"},
            {"exercise_name": "Pull-Up", "block_name": "Main Lifts", "sequence": 2, "target_sets": 4, "target_reps": "6-10", "rest_period_seconds": 120, "notes": "Full hang to chin over bar. Use band if needed"},
            {"exercise_name": "Barbell Row", "block_name": "Main Lifts", "sequence": 3, "target_sets": 4, "target_reps": "6-8", "rest_period_seconds": 90, "notes": "45-degree torso angle, pull to lower chest"},
            {"exercise_name": "Chest Supported Row", "block_name": "Accessory Work", "sequence": 4, "target_sets": 3, "target_reps": "10-12", "rest_period_seconds": 60, "notes": "Removes lower back fatigue"},
            {"exercise_name": "Straight Arm Pulldown", "block_name": "Accessory Work", "sequence": 5, "target_sets": 3, "target_reps": "12-15", "rest_period_seconds": 45, "notes": "Superset with curls"},
            {"exercise_name": "Bicep Curl", "block_name": "Accessory Work", "sequence": 6, "target_sets": 3, "target_reps": "10-12", "rest_period_seconds": 45, "notes": "Control the negative"},
            {"exercise_name": "Hammer Curl", "block_name": "Accessory Work", "sequence": 7, "target_sets": 3, "target_reps": "10-12", "rest_period_seconds": 45, "notes": "Neutral grip, targets brachialis"}
        ]'::jsonb,
        '{upper-body,pull,back,biceps,lats,intermediate,strength}'
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_pull_template;

    IF v_pull_template IS NULL THEN
        SELECT id INTO v_pull_template FROM system_workout_templates WHERE name = 'Upper Body Pull' LIMIT 1;
    END IF;

    -- WO-BASE-015: Heavy Leg Day
    INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags)
    VALUES (
        gen_random_uuid(),
        'Heavy Leg Day',
        'Strength focused lower body workout with squats and deadlifts. For intermediate to advanced lifters.',
        'legs',
        'intermediate',
        60,
        '[
            {"exercise_name": "90/90 Hip Stretch", "block_name": "Warm-Up", "sequence": 1, "target_sets": 2, "target_reps": "45-60 sec each", "notes": "Open up hips before heavy lifting"},
            {"exercise_name": "Back Squat", "block_name": "Main Lifts", "sequence": 2, "target_sets": 4, "target_reps": "6-8", "rest_period_seconds": 150, "notes": "Brace hard, depth to parallel or below"},
            {"exercise_name": "Conventional Deadlift", "block_name": "Main Lifts", "sequence": 3, "target_sets": 4, "target_reps": "5-8", "rest_period_seconds": 120, "notes": "Push floor away, keep bar close"},
            {"exercise_name": "Bulgarian Split Squat", "block_name": "Accessory Work", "sequence": 4, "target_sets": 3, "target_reps": "8-10 each", "rest_period_seconds": 90, "notes": "Rear foot elevated"},
            {"exercise_name": "Leg Curl", "block_name": "Accessory Work", "sequence": 5, "target_sets": 3, "target_reps": "12-15", "rest_period_seconds": 45, "notes": "Superset with extensions"},
            {"exercise_name": "Leg Extension", "block_name": "Accessory Work", "sequence": 6, "target_sets": 3, "target_reps": "12-15", "rest_period_seconds": 45, "notes": "Squeeze at top"},
            {"exercise_name": "Hip Thrust", "block_name": "Accessory Work", "sequence": 7, "target_sets": 3, "target_reps": "10-12", "rest_period_seconds": 60, "notes": "Pause at top, squeeze glutes"},
            {"exercise_name": "Calf Raise", "block_name": "Accessory Work", "sequence": 8, "target_sets": 3, "target_reps": "15-20", "rest_period_seconds": 30, "notes": "Full stretch at bottom, pause at top"}
        ]'::jsonb,
        '{lower-body,legs,squat,deadlift,strength,intermediate,heavy}'
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_heavy_legs_template;

    IF v_heavy_legs_template IS NULL THEN
        SELECT id INTO v_heavy_legs_template FROM system_workout_templates WHERE name = 'Heavy Leg Day' LIMIT 1;
    END IF;

    RAISE NOTICE 'Created/found workout templates';

    -- ========================================================================
    -- Create Foundation Strength Program (8 weeks, 3x/week = 24 workouts)
    -- ========================================================================

    INSERT INTO programs (
        id,
        patient_id,
        name,
        description,
        status,
        metadata
    ) VALUES (
        gen_random_uuid(),
        NULL,  -- System template
        'Foundation Strength',
        'Build a solid foundation of strength with this beginner-friendly 8-week program. Focus on compound movements, proper form, and progressive overload.',
        'active',
        jsonb_build_object(
            'duration_weeks', 8,
            'workouts_per_week', 3,
            'total_workouts', 24,
            'difficulty', 'beginner',
            'is_system_template', true,
            'pack_code', 'BASE'
        )
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_foundation_program_id;

    IF v_foundation_program_id IS NULL THEN
        SELECT id INTO v_foundation_program_id FROM programs WHERE name = 'Foundation Strength' AND patient_id IS NULL LIMIT 1;
    END IF;

    RAISE NOTICE 'Foundation Strength program ID: %', v_foundation_program_id;

    -- Create phases for Foundation Strength
    IF v_foundation_program_id IS NOT NULL THEN
        -- Phase 1: Learn the Basics (weeks 1-4)
        INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
        VALUES (
            gen_random_uuid(), v_foundation_program_id, 'Learn the Basics', 1, 4,
            'Master fundamental movement patterns with lighter weights',
            'Focus on form and technique. Build work capacity and movement quality.'
        )
        ON CONFLICT DO NOTHING
        RETURNING id INTO v_phase_id;

        IF v_phase_id IS NULL THEN
            SELECT id INTO v_phase_id FROM phases WHERE program_id = v_foundation_program_id AND sequence = 1 LIMIT 1;
        END IF;

        -- Assign workouts for weeks 1-4 (Lower, Hinge, Mobility)
        FOR week_num IN 1..4 LOOP
            -- Monday: Lower Body
            INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
            VALUES (v_foundation_program_id, v_lower_body_template, v_phase_id, week_num, 1, (week_num - 1) * 3 + 1)
            ON CONFLICT DO NOTHING;

            -- Wednesday: Hinge Day
            INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
            VALUES (v_foundation_program_id, v_hinge_day_template, v_phase_id, week_num, 3, (week_num - 1) * 3 + 2)
            ON CONFLICT DO NOTHING;

            -- Friday: Mobility Flow
            INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
            VALUES (v_foundation_program_id, v_mobility_template, v_phase_id, week_num, 5, (week_num - 1) * 3 + 3)
            ON CONFLICT DO NOTHING;
        END LOOP;

        -- Phase 2: Build Strength (weeks 5-8)
        INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
        VALUES (
            gen_random_uuid(), v_foundation_program_id, 'Build Strength', 2, 4,
            'Progressive overload with compound movements',
            'Increase weights gradually. Focus on strength gains while maintaining form.'
        )
        ON CONFLICT DO NOTHING
        RETURNING id INTO v_phase_id;

        IF v_phase_id IS NULL THEN
            SELECT id INTO v_phase_id FROM phases WHERE program_id = v_foundation_program_id AND sequence = 2 LIMIT 1;
        END IF;

        -- Assign workouts for weeks 5-8 (Heavy Legs, Push, Pull)
        FOR week_num IN 5..8 LOOP
            -- Monday: Heavy Legs
            INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
            VALUES (v_foundation_program_id, v_heavy_legs_template, v_phase_id, week_num, 1, (week_num - 1) * 3 + 1)
            ON CONFLICT DO NOTHING;

            -- Wednesday: Push
            INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
            VALUES (v_foundation_program_id, v_push_template, v_phase_id, week_num, 3, (week_num - 1) * 3 + 2)
            ON CONFLICT DO NOTHING;

            -- Friday: Pull
            INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
            VALUES (v_foundation_program_id, v_pull_template, v_phase_id, week_num, 5, (week_num - 1) * 3 + 3)
            ON CONFLICT DO NOTHING;
        END LOOP;

        RAISE NOTICE 'Created Foundation Strength phases and workout assignments';
    END IF;

    -- ========================================================================
    -- Create Strength Builder Program (12 weeks, 4x/week = 48 workouts)
    -- ========================================================================

    INSERT INTO programs (
        id,
        patient_id,
        name,
        description,
        status,
        metadata
    ) VALUES (
        gen_random_uuid(),
        NULL,
        'Strength Builder',
        'Take your strength to the next level with this 12-week intermediate program. Progressive heavy compound lifts with strategic accessory work.',
        'active',
        jsonb_build_object(
            'duration_weeks', 12,
            'workouts_per_week', 4,
            'total_workouts', 48,
            'difficulty', 'intermediate',
            'is_system_template', true,
            'pack_code', 'BASE'
        )
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_strength_builder_program_id;

    IF v_strength_builder_program_id IS NULL THEN
        SELECT id INTO v_strength_builder_program_id FROM programs WHERE name = 'Strength Builder' AND patient_id IS NULL LIMIT 1;
    END IF;

    RAISE NOTICE 'Strength Builder program ID: %', v_strength_builder_program_id;

    IF v_strength_builder_program_id IS NOT NULL THEN
        -- Phase 1: Volume (weeks 1-4)
        INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
        VALUES (gen_random_uuid(), v_strength_builder_program_id, 'Volume Phase', 1, 4, 'Higher rep ranges to build work capacity', 'Moderate weights, higher volume')
        ON CONFLICT DO NOTHING;

        -- Phase 2: Strength (weeks 5-8)
        INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
        VALUES (gen_random_uuid(), v_strength_builder_program_id, 'Strength Phase', 2, 4, 'Lower reps with heavier weights', 'Focus on progressive overload')
        ON CONFLICT DO NOTHING;

        -- Phase 3: Peak (weeks 9-12)
        INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
        VALUES (gen_random_uuid(), v_strength_builder_program_id, 'Peak Phase', 3, 4, 'Test your new strength levels', 'Near-max efforts with full recovery')
        ON CONFLICT DO NOTHING;

        -- Assign workouts for all 12 weeks (4x/week: Heavy Legs, Push, Pull, Mobility)
        FOR week_num IN 1..12 LOOP
            SELECT id INTO v_phase_id FROM phases
            WHERE program_id = v_strength_builder_program_id
            AND sequence = CASE WHEN week_num <= 4 THEN 1 WHEN week_num <= 8 THEN 2 ELSE 3 END
            LIMIT 1;

            -- Monday: Heavy Legs
            INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
            VALUES (v_strength_builder_program_id, v_heavy_legs_template, v_phase_id, week_num, 1, (week_num - 1) * 4 + 1)
            ON CONFLICT DO NOTHING;

            -- Tuesday: Push
            INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
            VALUES (v_strength_builder_program_id, v_push_template, v_phase_id, week_num, 2, (week_num - 1) * 4 + 2)
            ON CONFLICT DO NOTHING;

            -- Thursday: Pull
            INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
            VALUES (v_strength_builder_program_id, v_pull_template, v_phase_id, week_num, 4, (week_num - 1) * 4 + 3)
            ON CONFLICT DO NOTHING;

            -- Saturday: Mobility
            INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
            VALUES (v_strength_builder_program_id, v_mobility_template, v_phase_id, week_num, 6, (week_num - 1) * 4 + 4)
            ON CONFLICT DO NOTHING;
        END LOOP;

        RAISE NOTICE 'Created Strength Builder phases and workout assignments';
    END IF;

    -- ========================================================================
    -- Create Mobility Mastery Program (6 weeks, 5x/week = 30 sessions)
    -- ========================================================================

    INSERT INTO programs (
        id,
        patient_id,
        name,
        description,
        status,
        metadata
    ) VALUES (
        gen_random_uuid(),
        NULL,
        'Mobility Mastery',
        'Improve flexibility and movement quality with this 6-week mobility-focused program. Daily mobility work to enhance performance and prevent injury.',
        'active',
        jsonb_build_object(
            'duration_weeks', 6,
            'workouts_per_week', 5,
            'total_workouts', 30,
            'difficulty', 'beginner',
            'is_system_template', true,
            'pack_code', 'BASE'
        )
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_mobility_program_id;

    IF v_mobility_program_id IS NULL THEN
        SELECT id INTO v_mobility_program_id FROM programs WHERE name = 'Mobility Mastery' AND patient_id IS NULL LIMIT 1;
    END IF;

    RAISE NOTICE 'Mobility Mastery program ID: %', v_mobility_program_id;

    IF v_mobility_program_id IS NOT NULL THEN
        -- Single phase for mobility program
        INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals, notes)
        VALUES (gen_random_uuid(), v_mobility_program_id, 'Daily Mobility', 1, 6, 'Consistent daily mobility practice', 'Short sessions, high frequency')
        ON CONFLICT DO NOTHING
        RETURNING id INTO v_phase_id;

        IF v_phase_id IS NULL THEN
            SELECT id INTO v_phase_id FROM phases WHERE program_id = v_mobility_program_id LIMIT 1;
        END IF;

        -- Assign mobility workouts for all 6 weeks (5x/week)
        FOR week_num IN 1..6 LOOP
            FOR day_num IN 1..5 LOOP
                INSERT INTO program_workout_assignments (program_id, template_id, phase_id, week_number, day_of_week, sequence)
                VALUES (v_mobility_program_id, v_mobility_template, v_phase_id, week_num, day_num, (week_num - 1) * 5 + day_num)
                ON CONFLICT DO NOTHING;
            END LOOP;
        END LOOP;

        RAISE NOTICE 'Created Mobility Mastery phases and workout assignments';
    END IF;

    -- ========================================================================
    -- Update program_library entries to link to these programs
    -- ========================================================================

    -- Update Foundation Strength in program_library
    UPDATE program_library
    SET program_id = v_foundation_program_id,
        updated_at = NOW()
    WHERE LOWER(title) LIKE '%foundation%strength%'
      AND program_id IS NULL;

    RAISE NOTICE 'Updated Foundation Strength in program_library: % rows', FOUND;

    -- Update Strength Builder in program_library
    UPDATE program_library
    SET program_id = v_strength_builder_program_id,
        updated_at = NOW()
    WHERE LOWER(title) LIKE '%strength%builder%'
      AND program_id IS NULL;

    RAISE NOTICE 'Updated Strength Builder in program_library: % rows', FOUND;

    -- Update Mobility Mastery in program_library
    UPDATE program_library
    SET program_id = v_mobility_program_id,
        updated_at = NOW()
    WHERE LOWER(title) LIKE '%mobility%mastery%'
      AND program_id IS NULL;

    RAISE NOTICE 'Updated Mobility Mastery in program_library: % rows', FOUND;

    RAISE NOTICE 'Migration complete!';

END $$;

-- ============================================================================
-- Summary
-- ============================================================================
-- Created:
-- - 6 system_workout_templates with full exercise blocks
-- - 3 programs (Foundation Strength, Strength Builder, Mobility Mastery)
-- - Program phases for each
-- - Program workout assignments linking templates to programs
-- - Updated program_library.program_id to enable workout display
--
-- Users enrolled in these programs will now see workouts in ProgramWorkoutScheduleView
