-- ============================================================================
-- SEED DEMO PATIENT LAB RESULTS MIGRATION
-- ============================================================================
-- Seeds comprehensive lab results for the demo patient with 3 months of data
-- including normal, flagged low, flagged high, and optimal athlete values.
--
-- Demo Patient ID: 00000000-0000-0000-0000-000000000001
-- Date: 2026-02-12
-- ============================================================================

BEGIN;

-- ============================================================================
-- LAB RESULT 1: BLOOD PANEL - January 2026
-- ============================================================================
-- Complete blood count and iron studies

INSERT INTO lab_results (
    id,
    patient_id,
    test_date,
    provider,
    notes
) VALUES (
    '10000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    '2026-01-15',
    'quest',
    'Comprehensive blood panel - annual checkup'
) ON CONFLICT (id) DO NOTHING;

-- Blood Panel Biomarkers
INSERT INTO biomarker_values (id, lab_result_id, biomarker_type, value, unit, is_flagged) VALUES
    -- Normal Values - Blood Count
    ('20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'hemoglobin', 15.2, 'g/dL', false),
    ('20000000-0000-0000-0000-000000000002'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'hematocrit', 45.5, '%', false),
    ('20000000-0000-0000-0000-000000000003'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'rbc', 5.1, 'M/uL', false),
    ('20000000-0000-0000-0000-000000000004'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'wbc', 6.2, 'K/uL', false),
    ('20000000-0000-0000-0000-000000000005'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'platelets', 245, 'K/uL', false),

    -- Iron Studies - Slightly Low Ferritin (flagged)
    ('20000000-0000-0000-0000-000000000006'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'ferritin', 28, 'ng/mL', true),
    ('20000000-0000-0000-0000-000000000007'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'iron', 85, 'ug/dL', false),
    ('20000000-0000-0000-0000-000000000008'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'tibc', 380, 'ug/dL', false),

    -- Vitamins - Normal
    ('20000000-0000-0000-0000-000000000009'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'vitamin_d', 58, 'ng/mL', false),
    ('20000000-0000-0000-0000-000000000010'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'vitamin_b12', 650, 'pg/mL', false),

    -- Inflammation - Slightly High CRP (flagged)
    ('20000000-0000-0000-0000-000000000011'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'crp', 3.2, 'mg/L', true)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- LAB RESULT 2: METABOLIC PANEL - February 2026
-- ============================================================================
-- Lipids, glucose, and metabolic markers

INSERT INTO lab_results (
    id,
    patient_id,
    test_date,
    provider,
    notes
) VALUES (
    '10000000-0000-0000-0000-000000000002'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    '2026-02-05',
    'labcorp',
    'Metabolic panel with lipids - follow-up on training adaptations'
) ON CONFLICT (id) DO NOTHING;

-- Metabolic Panel Biomarkers
INSERT INTO biomarker_values (id, lab_result_id, biomarker_type, value, unit, is_flagged) VALUES
    -- Glucose/Metabolic - Normal
    ('20000000-0000-0000-0000-000000000012'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'glucose_fasting', 82, 'mg/dL', false),
    ('20000000-0000-0000-0000-000000000013'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'hba1c', 5.1, '%', false),
    ('20000000-0000-0000-0000-000000000014'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'insulin_fasting', 4.5, 'uIU/mL', false),

    -- Lipid Panel - Slightly High LDL (flagged), Good HDL
    ('20000000-0000-0000-0000-000000000015'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'hdl', 62, 'mg/dL', false),
    ('20000000-0000-0000-0000-000000000016'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'ldl', 138, 'mg/dL', true),
    ('20000000-0000-0000-0000-000000000017'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'total_cholesterol', 215, 'mg/dL', false),
    ('20000000-0000-0000-0000-000000000018'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'triglycerides', 78, 'mg/dL', false),

    -- Electrolytes - Slightly Low Magnesium (flagged)
    ('20000000-0000-0000-0000-000000000019'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'magnesium', 1.6, 'mg/dL', true),
    ('20000000-0000-0000-0000-000000000020'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'sodium', 140, 'mEq/L', false),
    ('20000000-0000-0000-0000-000000000021'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'potassium', 4.3, 'mEq/L', false),
    ('20000000-0000-0000-0000-000000000022'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'calcium', 9.6, 'mg/dL', false),

    -- Liver Function - Normal
    ('20000000-0000-0000-0000-000000000023'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'alt', 22, 'U/L', false),
    ('20000000-0000-0000-0000-000000000024'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'ast', 24, 'U/L', false),

    -- Kidney Function - Normal
    ('20000000-0000-0000-0000-000000000025'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'creatinine', 1.0, 'mg/dL', false),
    ('20000000-0000-0000-0000-000000000026'::uuid, '10000000-0000-0000-0000-000000000002'::uuid, 'bun', 15, 'mg/dL', false)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- LAB RESULT 3: HORMONE PANEL - December 2025
-- ============================================================================
-- Comprehensive hormone profile for athletic performance optimization

INSERT INTO lab_results (
    id,
    patient_id,
    test_date,
    provider,
    notes
) VALUES (
    '10000000-0000-0000-0000-000000000003'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    '2025-12-10',
    'quest',
    'Hormone panel - baseline assessment for performance optimization'
) ON CONFLICT (id) DO NOTHING;

-- Hormone Panel Biomarkers
INSERT INTO biomarker_values (id, lab_result_id, biomarker_type, value, unit, is_flagged) VALUES
    -- Testosterone - Optimal Athlete Values
    ('20000000-0000-0000-0000-000000000027'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'testosterone_total', 725, 'ng/dL', false),
    ('20000000-0000-0000-0000-000000000028'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'testosterone_free', 18.5, 'pg/mL', false),

    -- Stress Hormones - Good Recovery Status
    ('20000000-0000-0000-0000-000000000029'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'cortisol_am', 14.2, 'ug/dL', false),
    ('20000000-0000-0000-0000-000000000030'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'dhea_s', 385, 'ug/dL', false),

    -- Thyroid Function - Normal
    ('20000000-0000-0000-0000-000000000031'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'thyroid_tsh', 1.8, 'mIU/L', false),
    ('20000000-0000-0000-0000-000000000032'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'thyroid_free_t3', 3.4, 'pg/mL', false),
    ('20000000-0000-0000-0000-000000000033'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'thyroid_free_t4', 1.3, 'ng/dL', false),

    -- Growth & Recovery Markers
    ('20000000-0000-0000-0000-000000000034'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'igf1', 215, 'ng/mL', false),

    -- Estrogen Balance (male)
    ('20000000-0000-0000-0000-000000000035'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'estradiol', 28, 'pg/mL', false),

    -- Inflammation Marker - Slightly Elevated (from December)
    ('20000000-0000-0000-0000-000000000036'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 'homocysteine', 8.5, 'umol/L', false)
ON CONFLICT (id) DO NOTHING;


COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_lab_results_count integer;
    v_biomarker_values_count integer;
    v_flagged_count integer;
    v_normal_count integer;
    v_jan_count integer;
    v_feb_count integer;
    v_dec_count integer;
BEGIN
    -- Count lab results for demo patient
    SELECT COUNT(*) INTO v_lab_results_count
    FROM lab_results
    WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    AND id IN (
        '10000000-0000-0000-0000-000000000001'::uuid,
        '10000000-0000-0000-0000-000000000002'::uuid,
        '10000000-0000-0000-0000-000000000003'::uuid
    );

    -- Count biomarker values
    SELECT COUNT(*) INTO v_biomarker_values_count
    FROM biomarker_values
    WHERE lab_result_id IN (
        '10000000-0000-0000-0000-000000000001'::uuid,
        '10000000-0000-0000-0000-000000000002'::uuid,
        '10000000-0000-0000-0000-000000000003'::uuid
    );

    -- Count flagged vs normal
    SELECT COUNT(*) INTO v_flagged_count
    FROM biomarker_values
    WHERE lab_result_id IN (
        '10000000-0000-0000-0000-000000000001'::uuid,
        '10000000-0000-0000-0000-000000000002'::uuid,
        '10000000-0000-0000-0000-000000000003'::uuid
    )
    AND is_flagged = true;

    SELECT COUNT(*) INTO v_normal_count
    FROM biomarker_values
    WHERE lab_result_id IN (
        '10000000-0000-0000-0000-000000000001'::uuid,
        '10000000-0000-0000-0000-000000000002'::uuid,
        '10000000-0000-0000-0000-000000000003'::uuid
    )
    AND is_flagged = false;

    -- Count biomarkers per panel
    SELECT COUNT(*) INTO v_jan_count
    FROM biomarker_values
    WHERE lab_result_id = '10000000-0000-0000-0000-000000000001'::uuid;

    SELECT COUNT(*) INTO v_feb_count
    FROM biomarker_values
    WHERE lab_result_id = '10000000-0000-0000-0000-000000000002'::uuid;

    SELECT COUNT(*) INTO v_dec_count
    FROM biomarker_values
    WHERE lab_result_id = '10000000-0000-0000-0000-000000000003'::uuid;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DEMO PATIENT LAB RESULTS SEED COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Demo Patient ID: 00000000-0000-0000-0000-000000000001';
    RAISE NOTICE '';
    RAISE NOTICE 'Lab Results Created: %', v_lab_results_count;
    RAISE NOTICE '  - Blood Panel (January 2026):    % biomarkers', v_jan_count;
    RAISE NOTICE '  - Metabolic Panel (February 2026): % biomarkers', v_feb_count;
    RAISE NOTICE '  - Hormone Panel (December 2025): % biomarkers', v_dec_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Total Biomarker Values: %', v_biomarker_values_count;
    RAISE NOTICE '  - Normal values:  %', v_normal_count;
    RAISE NOTICE '  - Flagged values: %', v_flagged_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Flagged Biomarkers (out of range):';
    RAISE NOTICE '  - Ferritin (28 ng/mL) - LOW: Below optimal for athletes';
    RAISE NOTICE '  - CRP (3.2 mg/L) - HIGH: Indicates elevated inflammation';
    RAISE NOTICE '  - LDL Cholesterol (138 mg/dL) - HIGH: Above optimal range';
    RAISE NOTICE '  - Magnesium (1.6 mg/dL) - LOW: Below normal range';
    RAISE NOTICE '';
    RAISE NOTICE 'Optimal Athlete Values:';
    RAISE NOTICE '  - Testosterone Total: 725 ng/dL (optimal for male athlete)';
    RAISE NOTICE '  - Free Testosterone: 18.5 pg/mL (good bioavailability)';
    RAISE NOTICE '  - Cortisol AM: 14.2 ug/dL (healthy stress response)';
    RAISE NOTICE '  - IGF-1: 215 ng/mL (good anabolic/recovery marker)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;

COMMIT;
