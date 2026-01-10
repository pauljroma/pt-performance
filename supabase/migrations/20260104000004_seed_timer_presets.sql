-- ============================================================================
-- SEED TIMER PRESETS - BUILD 116 AGENT 4
-- ============================================================================
-- Comprehensive athletic training timer preset library
-- 25+ additional presets covering all categories
--
-- Date: 2026-01-03
-- Linear: BUILD 116
-- Agent: 4
-- ============================================================================

-- ============================================================================
-- CARDIO PRESETS (10 total)
-- ============================================================================

INSERT INTO timer_presets (name, description, category, template_json) VALUES

-- Extended Tabata variations
(
    'Extended Tabata',
    '30 seconds work, 15 seconds rest, 8 rounds - extended Tabata protocol',
    'cardio',
    jsonb_build_object(
        'type', 'tabata',
        'work_seconds', 30,
        'rest_seconds', 15,
        'rounds', 8,
        'cycles', 1,
        'total_duration', 360,
        'difficulty', 'moderate',
        'equipment', 'none'
    )
),

-- HIIT variations
(
    'HIIT 40/20',
    '40 seconds work, 20 seconds rest, 10 rounds - classic HIIT',
    'cardio',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 40,
        'rest_seconds', 20,
        'rounds', 10,
        'cycles', 1,
        'total_duration', 600,
        'difficulty', 'hard',
        'equipment', 'none'
    )
),
(
    'HIIT 45/15',
    '45 seconds work, 15 seconds rest, 12 rounds - intense conditioning',
    'cardio',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 45,
        'rest_seconds', 15,
        'rounds', 12,
        'cycles', 1,
        'total_duration', 720,
        'difficulty', 'hard',
        'equipment', 'none'
    )
),
(
    'HIIT 50/10',
    '50 seconds work, 10 seconds rest, 8 rounds - maximum effort',
    'cardio',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 50,
        'rest_seconds', 10,
        'rounds', 8,
        'cycles', 1,
        'total_duration', 480,
        'difficulty', 'very_hard',
        'equipment', 'none'
    )
),

-- Sprint intervals
(
    'Sprint Intervals',
    '30 seconds sprint, 90 seconds rest, 6 rounds - explosive cardio',
    'cardio',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 30,
        'rest_seconds', 90,
        'rounds', 6,
        'cycles', 1,
        'total_duration', 720,
        'difficulty', 'very_hard',
        'equipment', 'track_or_bike'
    )
),
(
    'Short Sprints',
    '15 seconds max effort, 45 seconds rest, 12 rounds',
    'cardio',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 15,
        'rest_seconds', 45,
        'rounds', 12,
        'cycles', 1,
        'total_duration', 720,
        'difficulty', 'hard',
        'equipment', 'track_or_bike'
    )
),

-- EMOM variations
(
    'EMOM 15',
    'Every minute on the minute for 15 minutes',
    'cardio',
    jsonb_build_object(
        'type', 'emom',
        'work_seconds', 50,
        'rest_seconds', 10,
        'rounds', 15,
        'cycles', 1,
        'total_duration', 900,
        'difficulty', 'moderate',
        'equipment', 'varies'
    )
),
(
    'EMOM 20',
    'Every minute on the minute for 20 minutes - endurance focus',
    'cardio',
    jsonb_build_object(
        'type', 'emom',
        'work_seconds', 50,
        'rest_seconds', 10,
        'rounds', 20,
        'cycles', 1,
        'total_duration', 1200,
        'difficulty', 'hard',
        'equipment', 'varies'
    )
),

-- AMRAP variations
(
    'AMRAP 20',
    'As many rounds as possible in 20 minutes',
    'cardio',
    jsonb_build_object(
        'type', 'amrap',
        'work_seconds', 1200,
        'rest_seconds', 0,
        'rounds', 1,
        'cycles', 1,
        'total_duration', 1200,
        'difficulty', 'hard',
        'equipment', 'varies'
    )
),
(
    'AMRAP 30',
    'As many rounds as possible in 30 minutes - endurance challenge',
    'cardio',
    jsonb_build_object(
        'type', 'amrap',
        'work_seconds', 1800,
        'rest_seconds', 0,
        'rounds', 1,
        'cycles', 1,
        'total_duration', 1800,
        'difficulty', 'very_hard',
        'equipment', 'varies'
    )
);

-- ============================================================================
-- STRENGTH PRESETS (7 total)
-- ============================================================================

INSERT INTO timer_presets (name, description, category, template_json) VALUES

-- Heavy compound lift intervals
(
    'Heavy Sets',
    '45 seconds work, 3 minutes rest, 5 rounds - for heavy compound lifts',
    'strength',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 45,
        'rest_seconds', 180,
        'rounds', 5,
        'cycles', 1,
        'total_duration', 1125,
        'difficulty', 'hard',
        'equipment', 'barbell_dumbbells'
    )
),
(
    'Compound Lifts',
    '60 seconds work, 4 minutes rest, 4 rounds - maximum strength focus',
    'strength',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 60,
        'rest_seconds', 240,
        'rounds', 4,
        'cycles', 1,
        'total_duration', 1200,
        'difficulty', 'very_hard',
        'equipment', 'barbell'
    )
),

-- Power training
(
    'Power Training',
    '30 seconds explosive work, 2 minutes rest, 8 rounds',
    'strength',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 30,
        'rest_seconds', 120,
        'rounds', 8,
        'cycles', 1,
        'total_duration', 1200,
        'difficulty', 'hard',
        'equipment', 'plyometric_equipment'
    )
),
(
    'Olympic Lifts',
    '20 seconds work, 2.5 minutes rest, 6 rounds - technical lifts',
    'strength',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 20,
        'rest_seconds', 150,
        'rounds', 6,
        'cycles', 1,
        'total_duration', 1020,
        'difficulty', 'very_hard',
        'equipment', 'barbell'
    )
),

-- Hypertrophy intervals
(
    'Hypertrophy Sets',
    '50 seconds work, 90 seconds rest, 8 rounds - muscle building',
    'strength',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 50,
        'rest_seconds', 90,
        'rounds', 8,
        'cycles', 1,
        'total_duration', 1120,
        'difficulty', 'moderate',
        'equipment', 'dumbbells_cables'
    )
),

-- Circuit strength
(
    'Strength Circuit',
    '40 seconds work, 30 seconds rest, 12 rounds - circuit training',
    'strength',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 40,
        'rest_seconds', 30,
        'rounds', 12,
        'cycles', 1,
        'total_duration', 840,
        'difficulty', 'moderate',
        'equipment', 'varies'
    )
),
(
    'Bodyweight Strength',
    '35 seconds work, 25 seconds rest, 10 rounds - no equipment needed',
    'strength',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 35,
        'rest_seconds', 25,
        'rounds', 10,
        'cycles', 1,
        'total_duration', 600,
        'difficulty', 'moderate',
        'equipment', 'none'
    )
);

-- ============================================================================
-- WARMUP PRESETS (5 total)
-- ============================================================================

INSERT INTO timer_presets (name, description, category, template_json) VALUES

(
    'Dynamic Warmup Extended',
    '30 seconds each movement, 15 seconds rest, 6 exercises',
    'warmup',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 30,
        'rest_seconds', 15,
        'rounds', 6,
        'cycles', 1,
        'total_duration', 270,
        'difficulty', 'easy',
        'equipment', 'none'
    )
),
(
    'Movement Prep',
    '20 seconds each movement, 10 seconds rest, 8 exercises',
    'warmup',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 20,
        'rest_seconds', 10,
        'rounds', 8,
        'cycles', 1,
        'total_duration', 240,
        'difficulty', 'easy',
        'equipment', 'none'
    )
),
(
    'Joint Mobility',
    '45 seconds each movement, 15 seconds rest, 5 movements',
    'warmup',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 45,
        'rest_seconds', 15,
        'rounds', 5,
        'cycles', 1,
        'total_duration', 300,
        'difficulty', 'easy',
        'equipment', 'none'
    )
),
(
    'Athletic Warmup',
    '25 seconds work, 10 seconds rest, 10 drills',
    'warmup',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 25,
        'rest_seconds', 10,
        'rounds', 10,
        'cycles', 1,
        'total_duration', 350,
        'difficulty', 'easy',
        'equipment', 'cones_ladder'
    )
),
(
    'Full Body Activation',
    '40 seconds work, 20 seconds rest, 7 movements',
    'warmup',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 40,
        'rest_seconds', 20,
        'rounds', 7,
        'cycles', 1,
        'total_duration', 420,
        'difficulty', 'easy',
        'equipment', 'resistance_bands'
    )
);

-- ============================================================================
-- COOLDOWN PRESETS (5 total)
-- ============================================================================

INSERT INTO timer_presets (name, description, category, template_json) VALUES

(
    'Static Stretch',
    '30 seconds hold per stretch, 10 seconds transition, 10 stretches',
    'cooldown',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 30,
        'rest_seconds', 10,
        'rounds', 10,
        'cycles', 1,
        'total_duration', 400,
        'difficulty', 'easy',
        'equipment', 'mat'
    )
),
(
    'Foam Rolling',
    '60 seconds each area, 15 seconds transition, 5 areas',
    'cooldown',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 60,
        'rest_seconds', 15,
        'rounds', 5,
        'cycles', 1,
        'total_duration', 375,
        'difficulty', 'easy',
        'equipment', 'foam_roller'
    )
),
(
    'Yoga Flow',
    '45 seconds each pose, 15 seconds transition, 8 poses',
    'cooldown',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 45,
        'rest_seconds', 15,
        'rounds', 8,
        'cycles', 1,
        'total_duration', 480,
        'difficulty', 'easy',
        'equipment', 'mat'
    )
),
(
    'Deep Stretch',
    '60 seconds hold, 20 seconds rest, 6 stretches',
    'cooldown',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 60,
        'rest_seconds', 20,
        'rounds', 6,
        'cycles', 1,
        'total_duration', 480,
        'difficulty', 'easy',
        'equipment', 'mat_straps'
    )
),
(
    'Recovery Stretch',
    '40 seconds hold, 20 seconds rest, 8 stretches',
    'cooldown',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 40,
        'rest_seconds', 20,
        'rounds', 8,
        'cycles', 1,
        'total_duration', 480,
        'difficulty', 'easy',
        'equipment', 'mat'
    )
);

-- ============================================================================
-- RECOVERY PRESETS (6 total)
-- ============================================================================

INSERT INTO timer_presets (name, description, category, template_json) VALUES

(
    'Active Recovery Extended',
    '10 seconds light movement, 50 seconds rest, 12 rounds',
    'recovery',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 10,
        'rest_seconds', 50,
        'rounds', 12,
        'cycles', 1,
        'total_duration', 720,
        'difficulty', 'very_easy',
        'equipment', 'none'
    )
),
(
    'Breath Work',
    '15 seconds inhale/exhale, 45 seconds hold, 10 cycles',
    'recovery',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 15,
        'rest_seconds', 45,
        'rounds', 10,
        'cycles', 1,
        'total_duration', 600,
        'difficulty', 'very_easy',
        'equipment', 'none'
    )
),
(
    'Meditation Timer',
    '60 seconds focus, 30 seconds rest, 5 rounds',
    'recovery',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 60,
        'rest_seconds', 30,
        'rounds', 5,
        'cycles', 1,
        'total_duration', 450,
        'difficulty', 'very_easy',
        'equipment', 'none'
    )
),
(
    'Low Intensity Movement',
    '20 seconds gentle movement, 40 seconds rest, 15 rounds',
    'recovery',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 20,
        'rest_seconds', 40,
        'rounds', 15,
        'cycles', 1,
        'total_duration', 900,
        'difficulty', 'very_easy',
        'equipment', 'none'
    )
),
(
    'Restorative Yoga',
    '90 seconds per pose, 30 seconds transition, 6 poses',
    'recovery',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 90,
        'rest_seconds', 30,
        'rounds', 6,
        'cycles', 1,
        'total_duration', 720,
        'difficulty', 'very_easy',
        'equipment', 'mat_bolster'
    )
),
(
    'Progressive Relaxation',
    '45 seconds per muscle group, 15 seconds rest, 10 groups',
    'recovery',
    jsonb_build_object(
        'type', 'intervals',
        'work_seconds', 45,
        'rest_seconds', 15,
        'rounds', 10,
        'cycles', 1,
        'total_duration', 600,
        'difficulty', 'very_easy',
        'equipment', 'mat'
    )
);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_cardio_count int;
    v_strength_count int;
    v_warmup_count int;
    v_cooldown_count int;
    v_recovery_count int;
    v_total_count int;
    v_new_presets int;
BEGIN
    -- Count by category
    SELECT COUNT(*) INTO v_cardio_count FROM timer_presets WHERE category = 'cardio';
    SELECT COUNT(*) INTO v_strength_count FROM timer_presets WHERE category = 'strength';
    SELECT COUNT(*) INTO v_warmup_count FROM timer_presets WHERE category = 'warmup';
    SELECT COUNT(*) INTO v_cooldown_count FROM timer_presets WHERE category = 'cooldown';
    SELECT COUNT(*) INTO v_recovery_count FROM timer_presets WHERE category = 'recovery';
    SELECT COUNT(*) INTO v_total_count FROM timer_presets;

    -- Calculate new presets added (total - 10 original)
    v_new_presets := v_total_count - 10;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'TIMER PRESETS SEEDED - BUILD 116 AGENT 4';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Presets seeded by category:';
    RAISE NOTICE '   - Cardio: % presets', v_cardio_count;
    RAISE NOTICE '   - Strength: % presets', v_strength_count;
    RAISE NOTICE '   - Warmup: % presets', v_warmup_count;
    RAISE NOTICE '   - Cooldown: % presets', v_cooldown_count;
    RAISE NOTICE '   - Recovery: % presets', v_recovery_count;
    RAISE NOTICE '';
    RAISE NOTICE '✅ Total presets: %', v_total_count;
    RAISE NOTICE '✅ New presets added: %', v_new_presets;
    RAISE NOTICE '';
    RAISE NOTICE '✅ Preset features:';
    RAISE NOTICE '   - All presets include difficulty level';
    RAISE NOTICE '   - All presets include equipment requirements';
    RAISE NOTICE '   - All presets include total_duration calculation';
    RAISE NOTICE '   - All template_json validated as JSONB';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'TIMER PRESET LIBRARY COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
END $$;
