-- ============================================================================
-- SEED DEMO SUPPLEMENT LOGS MIGRATION
-- ============================================================================
-- Seeds 14 days of supplement logs for the demo patient with realistic patterns
--
-- Demo Patient ID: 00000000-0000-0000-0000-000000000001
--
-- Patterns:
--   - ~75-85% overall compliance
--   - Morning supplements more consistent (~90%)
--   - Evening supplements sometimes missed (~70%)
--   - Weekends slightly lower compliance
--   - Current day has some logged, some pending
--
-- Tables affected:
--   - supplement_logs: Individual supplement intake entries
--   - supplement_compliance: Daily aggregate compliance records
--
-- Date: 2026-02-12
-- ============================================================================

BEGIN;

-- ============================================================================
-- SEED SUPPLEMENT LOGS
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
    v_zinc_id UUID;
    v_ashwagandha_id UUID;
    v_collagen_id UUID;
    v_l_theanine_id UUID;

    -- Loop variables
    v_day INTEGER;
    v_log_date DATE;
    v_day_of_week INTEGER;
    v_is_weekend BOOLEAN;
    v_morning_time TIME;
    v_afternoon_time TIME;
    v_evening_time TIME;
    v_bedtime TIME;

    -- Compliance tracking
    v_planned_count INTEGER;
    v_taken_count INTEGER;
    v_missed_supplements JSONB;

    -- Random timing variation
    v_time_offset INTEGER;
BEGIN

    -- ============================================================================
    -- VERIFY TABLES EXIST
    -- ============================================================================

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_logs') THEN
        RAISE NOTICE 'supplement_logs table does not exist, skipping...';
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplements') THEN
        RAISE NOTICE 'supplements table does not exist, skipping...';
        RETURN;
    END IF;

    RAISE NOTICE 'Starting demo supplement log seeding...';

    -- ============================================================================
    -- LOOK UP SUPPLEMENT IDS
    -- ============================================================================

    SELECT id INTO v_vitamin_d_id FROM supplements WHERE name ILIKE '%vitamin d%' LIMIT 1;
    SELECT id INTO v_fish_oil_id FROM supplements WHERE name ILIKE '%fish oil%' OR name ILIKE '%omega%' LIMIT 1;
    SELECT id INTO v_magnesium_id FROM supplements WHERE name ILIKE '%magnesium%' LIMIT 1;
    SELECT id INTO v_creatine_id FROM supplements WHERE name ILIKE '%creatine%' LIMIT 1;
    SELECT id INTO v_zinc_id FROM supplements WHERE name ILIKE '%zinc%' LIMIT 1;
    SELECT id INTO v_ashwagandha_id FROM supplements WHERE name ILIKE '%ashwagandha%' LIMIT 1;
    SELECT id INTO v_collagen_id FROM supplements WHERE name ILIKE '%collagen%' LIMIT 1;
    SELECT id INTO v_l_theanine_id FROM supplements WHERE name ILIKE '%theanine%' LIMIT 1;

    RAISE NOTICE 'Found supplements - VitD: %, Fish Oil: %, Mag: %, Creatine: %, Zinc: %, Ashwa: %, Collagen: %, Theanine: %',
        v_vitamin_d_id IS NOT NULL,
        v_fish_oil_id IS NOT NULL,
        v_magnesium_id IS NOT NULL,
        v_creatine_id IS NOT NULL,
        v_zinc_id IS NOT NULL,
        v_ashwagandha_id IS NOT NULL,
        v_collagen_id IS NOT NULL,
        v_l_theanine_id IS NOT NULL;

    -- Check if we have at least a few supplements to work with
    IF v_vitamin_d_id IS NULL AND v_magnesium_id IS NULL AND v_creatine_id IS NULL THEN
        RAISE NOTICE 'No supplements found in catalog, skipping supplement log seeding';
        RETURN;
    END IF;

    -- ============================================================================
    -- CLEAR EXISTING DEMO DATA
    -- ============================================================================

    DELETE FROM supplement_logs WHERE patient_id = v_demo_patient_id;
    RAISE NOTICE 'Cleared existing supplement logs for demo patient';

    -- Clear supplement_compliance if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_compliance') THEN
        DELETE FROM supplement_compliance WHERE patient_id = v_demo_patient_id;
        RAISE NOTICE 'Cleared existing supplement compliance for demo patient';
    END IF;

    -- ============================================================================
    -- SEED SUPPLEMENT LOGS FOR PAST 14 DAYS
    -- ============================================================================

    -- Loop through days (14 days ago to today)
    FOR v_day IN 0..13 LOOP
        v_log_date := v_today - (v_day || ' days')::INTERVAL;
        v_day_of_week := EXTRACT(DOW FROM v_log_date)::INTEGER;  -- 0 = Sunday, 6 = Saturday
        v_is_weekend := v_day_of_week IN (0, 6);

        -- Reset counters for this day
        v_planned_count := 0;
        v_taken_count := 0;
        v_missed_supplements := '[]'::jsonb;

        -- Vary timing slightly each day (realistic variation)
        v_time_offset := (v_day % 5) * 5;  -- 0, 5, 10, 15, 20 minute offsets
        v_morning_time := ('07:30:00'::TIME + (v_time_offset || ' minutes')::INTERVAL);
        v_afternoon_time := ('14:00:00'::TIME + (v_time_offset || ' minutes')::INTERVAL);
        v_evening_time := ('18:30:00'::TIME + (v_time_offset || ' minutes')::INTERVAL);
        v_bedtime := ('21:30:00'::TIME + (v_time_offset || ' minutes')::INTERVAL);

        -- ========================================================================
        -- MORNING SUPPLEMENTS (~90% compliance, slightly lower on weekends)
        -- ========================================================================

        -- Vitamin D3 (morning, with breakfast)
        IF v_vitamin_d_id IS NOT NULL THEN
            v_planned_count := v_planned_count + 1;
            -- Miss day 3 and day 10, and sometimes weekends
            IF v_day NOT IN (3, 10) AND NOT (v_is_weekend AND v_day % 7 = 0) THEN
                INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at, notes)
                VALUES (
                    v_demo_patient_id,
                    v_vitamin_d_id,
                    5000,
                    'IU',
                    'morning',
                    (v_log_date + v_morning_time)::TIMESTAMPTZ,
                    CASE
                        WHEN v_day = 0 THEN NULL  -- Today - no note
                        WHEN v_day = 1 THEN 'Taken with eggs'
                        WHEN v_day = 5 THEN 'With breakfast shake'
                        ELSE NULL
                    END
                );
                v_taken_count := v_taken_count + 1;
            ELSE
                v_missed_supplements := v_missed_supplements || jsonb_build_object('supplement_id', v_vitamin_d_id, 'timing', 'morning');
            END IF;
        END IF;

        -- Fish Oil / Omega-3 (morning, with food)
        IF v_fish_oil_id IS NOT NULL THEN
            v_planned_count := v_planned_count + 1;
            -- Miss days 3, 8, and one weekend
            IF v_day NOT IN (3, 8) AND NOT (v_is_weekend AND v_day = 6) THEN
                INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at, notes)
                VALUES (
                    v_demo_patient_id,
                    v_fish_oil_id,
                    3,
                    'g',
                    'morning',
                    (v_log_date + v_morning_time + INTERVAL '5 minutes')::TIMESTAMPTZ,
                    NULL
                );
                v_taken_count := v_taken_count + 1;
            ELSE
                v_missed_supplements := v_missed_supplements || jsonb_build_object('supplement_id', v_fish_oil_id, 'timing', 'morning');
            END IF;
        END IF;

        -- Collagen (morning, before food ideally)
        IF v_collagen_id IS NOT NULL THEN
            v_planned_count := v_planned_count + 1;
            -- Miss days 2, 7, 11 and weekends sometimes
            IF v_day NOT IN (2, 7, 11) AND NOT (v_is_weekend AND v_day % 6 = 0) THEN
                INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at, notes)
                VALUES (
                    v_demo_patient_id,
                    v_collagen_id,
                    15,
                    'g',
                    'morning',
                    (v_log_date + v_morning_time - INTERVAL '15 minutes')::TIMESTAMPTZ,
                    CASE WHEN v_day = 4 THEN 'Added to morning coffee' ELSE NULL END
                );
                v_taken_count := v_taken_count + 1;
            ELSE
                v_missed_supplements := v_missed_supplements || jsonb_build_object('supplement_id', v_collagen_id, 'timing', 'morning');
            END IF;
        END IF;

        -- ========================================================================
        -- AFTERNOON / POST-WORKOUT SUPPLEMENTS (~80% compliance)
        -- ========================================================================

        -- Creatine (post-workout or afternoon)
        IF v_creatine_id IS NOT NULL THEN
            v_planned_count := v_planned_count + 1;
            -- Miss days 1, 5, 9, 12 (some training days skipped)
            IF v_day NOT IN (1, 5, 9, 12) THEN
                INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at, notes)
                VALUES (
                    v_demo_patient_id,
                    v_creatine_id,
                    5,
                    'g',
                    'post_workout',
                    (v_log_date + v_afternoon_time + INTERVAL '30 minutes')::TIMESTAMPTZ,
                    CASE
                        WHEN v_day = 2 THEN 'Post leg day'
                        WHEN v_day = 8 THEN 'Mixed with post-workout shake'
                        ELSE NULL
                    END
                );
                v_taken_count := v_taken_count + 1;
            ELSE
                v_missed_supplements := v_missed_supplements || jsonb_build_object('supplement_id', v_creatine_id, 'timing', 'post_workout');
            END IF;
        END IF;

        -- ========================================================================
        -- EVENING SUPPLEMENTS (~70% compliance - lower due to busy evenings)
        -- ========================================================================

        -- Zinc (evening, with dinner)
        IF v_zinc_id IS NOT NULL THEN
            v_planned_count := v_planned_count + 1;
            -- Miss days 2, 4, 6, 9, 11, 13 (more frequent misses for evening)
            IF v_day NOT IN (2, 4, 6, 9, 11, 13) THEN
                INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at, notes)
                VALUES (
                    v_demo_patient_id,
                    v_zinc_id,
                    30,
                    'mg',
                    'evening',
                    (v_log_date + v_evening_time)::TIMESTAMPTZ,
                    NULL
                );
                v_taken_count := v_taken_count + 1;
            ELSE
                v_missed_supplements := v_missed_supplements || jsonb_build_object('supplement_id', v_zinc_id, 'timing', 'evening');
            END IF;
        END IF;

        -- Ashwagandha (evening, for cortisol/stress)
        IF v_ashwagandha_id IS NOT NULL THEN
            v_planned_count := v_planned_count + 1;
            -- Miss days 1, 5, 8, 10, 12
            IF v_day NOT IN (1, 5, 8, 10, 12) THEN
                INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at, notes)
                VALUES (
                    v_demo_patient_id,
                    v_ashwagandha_id,
                    600,
                    'mg',
                    'evening',
                    (v_log_date + v_evening_time + INTERVAL '30 minutes')::TIMESTAMPTZ,
                    CASE WHEN v_day = 3 THEN 'Noticed better sleep quality' ELSE NULL END
                );
                v_taken_count := v_taken_count + 1;
            ELSE
                v_missed_supplements := v_missed_supplements || jsonb_build_object('supplement_id', v_ashwagandha_id, 'timing', 'evening');
            END IF;
        END IF;

        -- ========================================================================
        -- BEDTIME SUPPLEMENTS (~75% compliance)
        -- ========================================================================

        -- Magnesium Glycinate (before bed, for sleep)
        IF v_magnesium_id IS NOT NULL THEN
            v_planned_count := v_planned_count + 1;
            -- Miss days 1, 4, 7, 10, 12
            IF v_day NOT IN (1, 4, 7, 10, 12) THEN
                INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at, notes)
                VALUES (
                    v_demo_patient_id,
                    v_magnesium_id,
                    400,
                    'mg',
                    'before_bed',
                    (v_log_date + v_bedtime)::TIMESTAMPTZ,
                    CASE
                        WHEN v_day = 2 THEN 'Helped with muscle recovery'
                        WHEN v_day = 6 THEN 'Good sleep'
                        ELSE NULL
                    END
                );
                v_taken_count := v_taken_count + 1;
            ELSE
                v_missed_supplements := v_missed_supplements || jsonb_build_object('supplement_id', v_magnesium_id, 'timing', 'before_bed');
            END IF;
        END IF;

        -- L-Theanine (before bed, for relaxation)
        IF v_l_theanine_id IS NOT NULL THEN
            v_planned_count := v_planned_count + 1;
            -- Miss days 0, 3, 5, 8, 11 (today (day 0) not taken yet in this example)
            IF v_day NOT IN (0, 3, 5, 8, 11) THEN
                INSERT INTO supplement_logs (patient_id, supplement_id, dosage, dosage_unit, timing, logged_at, notes)
                VALUES (
                    v_demo_patient_id,
                    v_l_theanine_id,
                    200,
                    'mg',
                    'before_bed',
                    (v_log_date + v_bedtime + INTERVAL '10 minutes')::TIMESTAMPTZ,
                    NULL
                );
                v_taken_count := v_taken_count + 1;
            ELSE
                v_missed_supplements := v_missed_supplements || jsonb_build_object('supplement_id', v_l_theanine_id, 'timing', 'before_bed');
            END IF;
        END IF;

        -- ========================================================================
        -- UPDATE SUPPLEMENT COMPLIANCE TABLE
        -- ========================================================================

        -- Skip today for compliance (partial day)
        IF v_day > 0 AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_compliance') THEN
            INSERT INTO supplement_compliance (
                patient_id,
                date,
                planned_supplements,
                taken_supplements,
                missed_supplements
            )
            VALUES (
                v_demo_patient_id,
                v_log_date,
                v_planned_count,
                v_taken_count,
                v_missed_supplements
            )
            ON CONFLICT (patient_id, date) DO UPDATE SET
                planned_supplements = EXCLUDED.planned_supplements,
                taken_supplements = EXCLUDED.taken_supplements,
                missed_supplements = EXCLUDED.missed_supplements,
                updated_at = NOW();
        END IF;

        RAISE NOTICE 'Day % (%) - Planned: %, Taken: %, Weekend: %',
            v_day,
            v_log_date,
            v_planned_count,
            v_taken_count,
            v_is_weekend;

    END LOOP;

    RAISE NOTICE 'Supplement log seeding complete!';

END $$;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_demo_patient_id UUID := '00000000-0000-0000-0000-000000000001'::uuid;
    v_total_logs INTEGER := 0;
    v_compliance_records INTEGER := 0;
    v_avg_compliance NUMERIC := 0;
    v_morning_logs INTEGER := 0;
    v_evening_logs INTEGER := 0;
    v_bedtime_logs INTEGER := 0;
BEGIN
    -- Count total logs
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_logs') THEN
        SELECT COUNT(*) INTO v_total_logs
        FROM supplement_logs
        WHERE patient_id = v_demo_patient_id;

        SELECT COUNT(*) INTO v_morning_logs
        FROM supplement_logs
        WHERE patient_id = v_demo_patient_id AND timing = 'morning';

        SELECT COUNT(*) INTO v_evening_logs
        FROM supplement_logs
        WHERE patient_id = v_demo_patient_id AND timing = 'evening';

        SELECT COUNT(*) INTO v_bedtime_logs
        FROM supplement_logs
        WHERE patient_id = v_demo_patient_id AND timing = 'before_bed';
    END IF;

    -- Count compliance records and average
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_compliance') THEN
        SELECT COUNT(*), COALESCE(AVG(compliance_rate), 0)
        INTO v_compliance_records, v_avg_compliance
        FROM supplement_compliance
        WHERE patient_id = v_demo_patient_id;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DEMO SUPPLEMENT LOGS SEED COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Demo Patient ID: %', v_demo_patient_id;
    RAISE NOTICE '';
    RAISE NOTICE 'Supplement Logs Created:';
    RAISE NOTICE '  Total Logs:           % entries', v_total_logs;
    RAISE NOTICE '  Morning Logs:         % entries', v_morning_logs;
    RAISE NOTICE '  Evening Logs:         % entries', v_evening_logs;
    RAISE NOTICE '  Before Bed Logs:      % entries', v_bedtime_logs;
    RAISE NOTICE '';
    RAISE NOTICE 'Compliance Tracking:';
    RAISE NOTICE '  Compliance Records:   % days', v_compliance_records;
    RAISE NOTICE '  Average Compliance:   %', ROUND(v_avg_compliance, 1) || '%';
    RAISE NOTICE '';
    RAISE NOTICE 'Patterns Applied:';
    RAISE NOTICE '  - Morning supplements: ~90%% compliance (most consistent)';
    RAISE NOTICE '  - Evening supplements: ~70%% compliance (busy evenings)';
    RAISE NOTICE '  - Before bed:          ~75%% compliance';
    RAISE NOTICE '  - Weekends:            Slightly lower compliance';
    RAISE NOTICE '  - Today:               Some logged, some pending';
    RAISE NOTICE '';
    RAISE NOTICE 'Supplements Included (if found in catalog):';
    RAISE NOTICE '  - Vitamin D3 (5000 IU, morning)';
    RAISE NOTICE '  - Omega-3 Fish Oil (3g, morning)';
    RAISE NOTICE '  - Collagen Peptides (15g, morning)';
    RAISE NOTICE '  - Creatine Monohydrate (5g, post-workout)';
    RAISE NOTICE '  - Zinc Picolinate (30mg, evening)';
    RAISE NOTICE '  - Ashwagandha KSM-66 (600mg, evening)';
    RAISE NOTICE '  - Magnesium Glycinate (400mg, before bed)';
    RAISE NOTICE '  - L-Theanine (200mg, before bed)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;
