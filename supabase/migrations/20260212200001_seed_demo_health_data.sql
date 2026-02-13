-- ============================================================================
-- SEED DEMO HEALTH DATA MIGRATION
-- ============================================================================
-- Seeds fasting logs, supplement stacks, and recovery sessions for the demo patient
--
-- Demo Patient ID: 00000000-0000-0000-0000-000000000001
--
-- Data seeded:
--   - Fasting logs (past 14 days): Mix of 16:8 and 18:6 fasts
--   - Supplement stack: 6 supplements with ~80% compliance
--   - Recovery sessions (past 7 days): Sauna, cold plunge, and contrast therapy
--
-- Date: 2026-02-12
-- ============================================================================

BEGIN;

-- ============================================================================
-- CONSTANTS
-- ============================================================================

DO $$
DECLARE
    v_demo_patient_id UUID := '00000000-0000-0000-0000-000000000001'::uuid;
    v_today DATE := CURRENT_DATE;
    v_now TIMESTAMPTZ := NOW();

    -- Supplement IDs (will be looked up)
    v_vitamin_d_id UUID;
    v_fish_oil_id UUID;
    v_magnesium_id UUID;
    v_creatine_id UUID;
    v_protein_id UUID;
    v_zinc_id UUID;

    -- Loop variables
    v_day INTEGER;
    v_fast_start TIMESTAMPTZ;
    v_fast_end TIMESTAMPTZ;
    v_fast_hours INTEGER;
    v_protocol TEXT;
    v_log_date DATE;
BEGIN

    -- ============================================================================
    -- SECTION 1: FASTING LOGS (Past 14 Days)
    -- ============================================================================

    -- Check if fasting_logs table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fasting_logs') THEN
        RAISE NOTICE 'Seeding fasting logs for demo patient...';

        -- Clear existing fasting logs for demo patient
        DELETE FROM fasting_logs WHERE patient_id = v_demo_patient_id;

        -- Day 1 (14 days ago) - 16:8 fast, completed
        v_fast_start := (v_today - INTERVAL '14 days' + TIME '20:00:00')::TIMESTAMPTZ;
        v_fast_end := (v_today - INTERVAL '13 days' + TIME '12:00:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 16, 16.0, '16:8', 'Felt great, had black coffee during fast', true);

        -- Day 2 (13 days ago) - 16:8 fast, completed
        v_fast_start := (v_today - INTERVAL '13 days' + TIME '19:30:00')::TIMESTAMPTZ;
        v_fast_end := (v_today - INTERVAL '12 days' + TIME '11:30:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 16, 16.0, '16:8', 'Easy fast, walked in the morning', true);

        -- Day 3 (12 days ago) - No fast (rest day)

        -- Day 4 (11 days ago) - 18:6 fast, completed
        v_fast_start := (v_today - INTERVAL '11 days' + TIME '18:00:00')::TIMESTAMPTZ;
        v_fast_end := (v_today - INTERVAL '10 days' + TIME '12:00:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 18, 18.0, '18:6', 'First 18:6 of the week, felt challenging but good', true);

        -- Day 5 (10 days ago) - 16:8 fast, completed
        v_fast_start := (v_today - INTERVAL '10 days' + TIME '20:30:00')::TIMESTAMPTZ;
        v_fast_end := (v_today - INTERVAL '9 days' + TIME '12:30:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 16, 16.0, '16:8', 'Standard 16:8, no issues', true);

        -- Day 6 (9 days ago) - 16:8 fast, broke early
        v_fast_start := (v_today - INTERVAL '9 days' + TIME '20:00:00')::TIMESTAMPTZ;
        v_fast_end := (v_today - INTERVAL '8 days' + TIME '10:00:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 16, 14.0, '16:8', 'Had early meeting with breakfast provided, broke fast early', false);

        -- Day 7 (8 days ago) - No fast (weekend)

        -- Day 8 (7 days ago) - 18:6 fast, completed
        v_fast_start := (v_today - INTERVAL '7 days' + TIME '18:30:00')::TIMESTAMPTZ;
        v_fast_end := (v_today - INTERVAL '6 days' + TIME '12:30:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 18, 18.0, '18:6', 'Great focus during work hours', true);

        -- Day 9 (6 days ago) - 16:8 fast, completed
        v_fast_start := (v_today - INTERVAL '6 days' + TIME '21:00:00')::TIMESTAMPTZ;
        v_fast_end := (v_today - INTERVAL '5 days' + TIME '13:00:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 16, 16.0, '16:8', 'Late dinner, pushed eating window back', true);

        -- Day 10 (5 days ago) - 16:8 fast, completed
        v_fast_start := (v_today - INTERVAL '5 days' + TIME '19:00:00')::TIMESTAMPTZ;
        v_fast_end := (v_today - INTERVAL '4 days' + TIME '11:00:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 16, 16.0, '16:8', 'Smooth fast, energy levels high', true);

        -- Day 11 (4 days ago) - 18:6 fast, completed
        v_fast_start := (v_today - INTERVAL '4 days' + TIME '17:00:00')::TIMESTAMPTZ;
        v_fast_end := (v_today - INTERVAL '3 days' + TIME '11:00:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 18, 18.0, '18:6', 'Post-workout fast, felt the gains', true);

        -- Day 12 (3 days ago) - No fast (recovery day)

        -- Day 13 (2 days ago) - 16:8 fast, completed
        v_fast_start := (v_today - INTERVAL '2 days' + TIME '20:00:00')::TIMESTAMPTZ;
        v_fast_end := (v_today - INTERVAL '1 day' + TIME '12:00:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 16, 16.0, '16:8', 'Consistent 16:8, feeling adapted', true);

        -- Day 14 (yesterday) - 16:8 fast, completed
        v_fast_start := (v_today - INTERVAL '1 day' + TIME '19:30:00')::TIMESTAMPTZ;
        v_fast_end := (v_today + TIME '11:30:00')::TIMESTAMPTZ;
        INSERT INTO fasting_logs (patient_id, started_at, ended_at, planned_hours, actual_hours, protocol_type, notes, completed)
        VALUES (v_demo_patient_id, v_fast_start, v_fast_end, 16, 16.0, '16:8', 'Morning workout while fasted', true);

        RAISE NOTICE 'Fasting logs seeded: 11 fasts over 14 days (10 completed, 1 broken early)';
    ELSE
        RAISE NOTICE 'Table fasting_logs does not exist, skipping...';
    END IF;

    -- ============================================================================
    -- SECTION 2: SUPPLEMENT STACK & COMPLIANCE LOGS
    -- ============================================================================

    -- Check if supplement tables exist
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplements')
       AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'patient_supplement_stacks')
       AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_logs') THEN

        RAISE NOTICE 'Seeding supplement data for demo patient...';

        -- Look up existing supplements by name (they already exist in the catalog from seed data)
        SELECT id INTO v_vitamin_d_id FROM supplements WHERE name ILIKE '%vitamin d%' LIMIT 1;
        SELECT id INTO v_fish_oil_id FROM supplements WHERE name ILIKE '%fish oil%' OR name ILIKE '%omega%' LIMIT 1;
        SELECT id INTO v_magnesium_id FROM supplements WHERE name ILIKE '%magnesium%' LIMIT 1;
        SELECT id INTO v_creatine_id FROM supplements WHERE name ILIKE '%creatine%' LIMIT 1;
        SELECT id INTO v_protein_id FROM supplements WHERE name ILIKE '%protein%' OR name ILIKE '%whey%' LIMIT 1;
        SELECT id INTO v_zinc_id FROM supplements WHERE name ILIKE '%zinc%' LIMIT 1;

        -- Log found supplements
        RAISE NOTICE 'Found supplements: VitD=%, Fish Oil=%, Mag=%, Creatine=%, Protein=%, Zinc=%',
            v_vitamin_d_id, v_fish_oil_id, v_magnesium_id, v_creatine_id, v_protein_id, v_zinc_id;

        -- Only seed if we found at least some supplements
        IF v_vitamin_d_id IS NULL AND v_magnesium_id IS NULL THEN
            RAISE NOTICE 'No supplements found in catalog, skipping supplement stack seeding';
        ELSE
            -- Clear existing supplement stacks for demo patient
            DELETE FROM patient_supplement_stacks WHERE patient_id = v_demo_patient_id;

        -- Add supplements to demo patient's stack (only if they exist)
            IF v_vitamin_d_id IS NOT NULL THEN
                INSERT INTO patient_supplement_stacks (patient_id, supplement_id, dosage, dosage_unit, frequency, timing, is_active, started_at, notes)
                VALUES (v_demo_patient_id, v_vitamin_d_id, 5000, 'IU', 'daily', 'morning', true, v_now - INTERVAL '30 days', 'Take with breakfast');
            END IF;
            IF v_fish_oil_id IS NOT NULL THEN
                INSERT INTO patient_supplement_stacks (patient_id, supplement_id, dosage, dosage_unit, frequency, timing, is_active, started_at, notes)
                VALUES (v_demo_patient_id, v_fish_oil_id, 3, 'g', 'daily', 'morning', true, v_now - INTERVAL '30 days', 'Nordic Naturals Ultimate Omega');
            END IF;
            IF v_magnesium_id IS NOT NULL THEN
                INSERT INTO patient_supplement_stacks (patient_id, supplement_id, dosage, dosage_unit, frequency, timing, is_active, started_at, notes)
                VALUES (v_demo_patient_id, v_magnesium_id, 400, 'mg', 'daily', 'before_bed', true, v_now - INTERVAL '30 days', 'Helps with sleep quality');
            END IF;
            IF v_creatine_id IS NOT NULL THEN
                INSERT INTO patient_supplement_stacks (patient_id, supplement_id, dosage, dosage_unit, frequency, timing, is_active, started_at, notes)
                VALUES (v_demo_patient_id, v_creatine_id, 5, 'g', 'daily', 'post_workout', true, v_now - INTERVAL '30 days', 'Mix with post-workout shake');
            END IF;
            IF v_protein_id IS NOT NULL THEN
                INSERT INTO patient_supplement_stacks (patient_id, supplement_id, dosage, dosage_unit, frequency, timing, is_active, started_at, notes)
                VALUES (v_demo_patient_id, v_protein_id, 30, 'g', 'daily', 'post_workout', true, v_now - INTERVAL '30 days', 'Optimum Nutrition Gold Standard');
            END IF;
            IF v_zinc_id IS NOT NULL THEN
                INSERT INTO patient_supplement_stacks (patient_id, supplement_id, dosage, dosage_unit, frequency, timing, is_active, started_at, notes)
                VALUES (v_demo_patient_id, v_zinc_id, 30, 'mg', 'daily', 'evening', true, v_now - INTERVAL '30 days', 'Take with dinner');
            END IF;

            RAISE NOTICE 'Supplement stack created for found supplements';

        -- Clear existing supplement logs for demo patient
        DELETE FROM supplement_logs WHERE patient_id = v_demo_patient_id;

        -- Create compliance logs (~80% adherence over past 14 days)
        -- We'll log supplements for most days, skipping some to simulate real-world compliance
        FOR v_day IN 1..14 LOOP
            v_log_date := v_today - (v_day || ' days')::INTERVAL;

            -- Morning supplements (Vitamin D, Fish Oil) - 85% compliance
            IF v_day NOT IN (3, 10) THEN  -- Skip days 3 and 10
                IF v_vitamin_d_id IS NOT NULL THEN
                    INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at)
                    VALUES (v_demo_patient_id, v_vitamin_d_id, 5000, 'IU', 'morning', v_log_date + TIME '08:00:00');
                END IF;
                IF v_fish_oil_id IS NOT NULL THEN
                    INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at)
                    VALUES (v_demo_patient_id, v_fish_oil_id, 3, 'g', 'morning', v_log_date + TIME '08:05:00');
                END IF;
            END IF;

            -- Post-workout supplements (Creatine, Protein) - 78% compliance
            IF v_day NOT IN (2, 7, 11) THEN  -- Skip days 2, 7, and 11
                IF v_creatine_id IS NOT NULL THEN
                    INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at)
                    VALUES (v_demo_patient_id, v_creatine_id, 5, 'g', 'post_workout', v_log_date + TIME '17:30:00');
                END IF;
                IF v_protein_id IS NOT NULL THEN
                    INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at)
                    VALUES (v_demo_patient_id, v_protein_id, 30, 'g', 'post_workout', v_log_date + TIME '17:35:00');
                END IF;
            END IF;

            -- Evening supplements (Zinc, Magnesium) - 78% compliance
            IF v_day NOT IN (4, 8, 12) THEN  -- Skip days 4, 8, and 12
                IF v_zinc_id IS NOT NULL THEN
                    INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at)
                    VALUES (v_demo_patient_id, v_zinc_id, 30, 'mg', 'evening', v_log_date + TIME '19:00:00');
                END IF;
                IF v_magnesium_id IS NOT NULL THEN
                    INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at)
                    VALUES (v_demo_patient_id, v_magnesium_id, 400, 'mg', 'before_bed', v_log_date + TIME '21:30:00');
                END IF;
            END IF;
        END LOOP;

        RAISE NOTICE 'Supplement compliance logs created: ~80%% adherence over 14 days';
        END IF;  -- End of supplements found check
    ELSE
        RAISE NOTICE 'Supplement tables do not exist, skipping...';
    END IF;

    -- ============================================================================
    -- SECTION 3: RECOVERY SESSIONS (Past 7 Days)
    -- ============================================================================

    -- Check if recovery_sessions table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'recovery_sessions') THEN
        RAISE NOTICE 'Seeding recovery sessions for demo patient...';

        -- Clear existing recovery sessions for demo patient
        DELETE FROM recovery_sessions WHERE patient_id = v_demo_patient_id;

        -- Sauna session 1 (6 days ago) - Traditional sauna, 18 min, 180F
        INSERT INTO recovery_sessions (patient_id, session_type, duration_minutes, temperature_f, notes, logged_at)
        VALUES (v_demo_patient_id, 'sauna_traditional', 18, 180.0, 'Post-workout sauna, felt great', (v_today - INTERVAL '6 days' + TIME '18:00:00')::TIMESTAMPTZ);

        -- Cold plunge session 1 (6 days ago) - After sauna, 3 min, 42F
        INSERT INTO recovery_sessions (patient_id, session_type, duration_minutes, temperature_f, notes, logged_at)
        VALUES (v_demo_patient_id, 'cold_plunge', 3, 42.0, 'Post-sauna cold plunge, challenging but invigorating', (v_today - INTERVAL '6 days' + TIME '18:25:00')::TIMESTAMPTZ);

        -- Sauna session 2 (4 days ago) - Traditional sauna, 20 min, 175F
        INSERT INTO recovery_sessions (patient_id, session_type, duration_minutes, temperature_f, notes, logged_at)
        VALUES (v_demo_patient_id, 'sauna_traditional', 20, 175.0, 'Morning sauna for circulation', (v_today - INTERVAL '4 days' + TIME '07:30:00')::TIMESTAMPTZ);

        -- Cold plunge session 2 (3 days ago) - Standalone, 4 min, 40F
        INSERT INTO recovery_sessions (patient_id, session_type, duration_minutes, temperature_f, notes, logged_at)
        VALUES (v_demo_patient_id, 'cold_plunge', 4, 40.0, 'Morning cold plunge for dopamine boost', (v_today - INTERVAL '3 days' + TIME '06:30:00')::TIMESTAMPTZ);

        -- Contrast therapy session (2 days ago) - Full protocol
        INSERT INTO recovery_sessions (patient_id, session_type, duration_minutes, temperature_f, notes, logged_at)
        VALUES (v_demo_patient_id, 'contrast', 35, NULL, 'Full contrast protocol: 15min sauna (185F) -> 2min cold (38F) -> 10min sauna -> 2min cold -> 6min sauna', (v_today - INTERVAL '2 days' + TIME '17:00:00')::TIMESTAMPTZ);

        -- Sauna session 3 (yesterday) - Infrared sauna, 15 min, 170F
        INSERT INTO recovery_sessions (patient_id, session_type, duration_minutes, temperature_f, notes, logged_at)
        VALUES (v_demo_patient_id, 'sauna_infrared', 15, 170.0, 'Quick infrared session before dinner', (v_today - INTERVAL '1 day' + TIME '18:30:00')::TIMESTAMPTZ);

        -- Cold plunge session 3 (yesterday) - After infrared, 2 min, 45F
        INSERT INTO recovery_sessions (patient_id, session_type, duration_minutes, temperature_f, notes, logged_at)
        VALUES (v_demo_patient_id, 'cold_plunge', 2, 45.0, 'Brief cold exposure after sauna', (v_today - INTERVAL '1 day' + TIME '18:50:00')::TIMESTAMPTZ);

        RAISE NOTICE 'Recovery sessions seeded: 3 sauna, 3 cold plunge, 1 contrast therapy';
    ELSE
        RAISE NOTICE 'Table recovery_sessions does not exist, skipping...';
    END IF;

END $$;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_demo_patient_id UUID := '00000000-0000-0000-0000-000000000001'::uuid;
    v_fasting_count INTEGER := 0;
    v_supplement_stack_count INTEGER := 0;
    v_supplement_log_count INTEGER := 0;
    v_recovery_count INTEGER := 0;
BEGIN
    -- Count fasting logs
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fasting_logs') THEN
        SELECT COUNT(*) INTO v_fasting_count FROM fasting_logs WHERE patient_id = v_demo_patient_id;
    END IF;

    -- Count supplement stack items
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'patient_supplement_stacks') THEN
        SELECT COUNT(*) INTO v_supplement_stack_count FROM patient_supplement_stacks WHERE patient_id = v_demo_patient_id AND is_active = true;
    END IF;

    -- Count supplement logs
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_logs') THEN
        SELECT COUNT(*) INTO v_supplement_log_count FROM supplement_logs WHERE patient_id = v_demo_patient_id;
    END IF;

    -- Count recovery sessions
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'recovery_sessions') THEN
        SELECT COUNT(*) INTO v_recovery_count FROM recovery_sessions WHERE patient_id = v_demo_patient_id;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DEMO HEALTH DATA SEED COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Demo Patient ID: %', v_demo_patient_id;
    RAISE NOTICE '';
    RAISE NOTICE 'Data Seeded:';
    RAISE NOTICE '  Fasting Logs:        % records (14 days, mix of 16:8 and 18:6)', v_fasting_count;
    RAISE NOTICE '  Supplement Stack:    % active supplements', v_supplement_stack_count;
    RAISE NOTICE '  Supplement Logs:     % compliance records (~80%% adherence)', v_supplement_log_count;
    RAISE NOTICE '  Recovery Sessions:   % sessions (sauna, cold plunge, contrast)', v_recovery_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Supplements Added:';
    RAISE NOTICE '  - Vitamin D3 (5000 IU, morning)';
    RAISE NOTICE '  - Omega-3 Fish Oil (3g, morning)';
    RAISE NOTICE '  - Magnesium Glycinate (400mg, before bed)';
    RAISE NOTICE '  - Creatine Monohydrate (5g, post-workout)';
    RAISE NOTICE '  - Whey Protein (30g, post-workout)';
    RAISE NOTICE '  - Zinc Picolinate (30mg, evening)';
    RAISE NOTICE '';
    RAISE NOTICE 'Recovery Protocol:';
    RAISE NOTICE '  - 3 sauna sessions (traditional + infrared, 15-20 min, 170-185F)';
    RAISE NOTICE '  - 3 cold plunge sessions (2-4 min, 38-45F)';
    RAISE NOTICE '  - 1 contrast therapy session (35 min total)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;

COMMIT;
