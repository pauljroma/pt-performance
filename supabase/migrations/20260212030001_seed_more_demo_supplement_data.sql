-- ============================================================================
-- BUILD 485b: SEED MORE DEMO SUPPLEMENT ROUTINES
-- ============================================================================
-- The previous migration only created 1 routine. Let's add more.
-- ============================================================================

BEGIN;

-- First, let's see what supplements we have and insert routines for common ones
-- Use fixed doses since the supplements table might have different column names
INSERT INTO patient_supplement_routines (
    id, patient_id, supplement_id, dose, dose_unit, timing,
    days_of_week, is_active, start_date, notes
)
SELECT
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001'::uuid,
    s.id,
    CASE s.name
        WHEN 'Creatine Monohydrate' THEN 5
        WHEN 'Vitamin D3' THEN 5000
        WHEN 'Magnesium Glycinate' THEN 400
        WHEN 'Omega-3 Fish Oil' THEN 3000
        WHEN 'Ashwagandha KSM-66' THEN 600
        WHEN 'Vitamin K2 MK-7' THEN 100
        WHEN 'Zinc Picolinate' THEN 30
        ELSE 500
    END::numeric,
    CASE s.name
        WHEN 'Vitamin D3' THEN 'IU'
        WHEN 'Vitamin K2 MK-7' THEN 'mcg'
        ELSE 'mg'
    END,
    CASE s.name
        WHEN 'Creatine Monohydrate' THEN 'post_workout'
        WHEN 'Vitamin D3' THEN 'morning'
        WHEN 'Magnesium Glycinate' THEN 'before_bed'
        WHEN 'Omega-3 Fish Oil' THEN 'with_meal'
        WHEN 'Ashwagandha KSM-66' THEN 'evening'
        WHEN 'Vitamin K2 MK-7' THEN 'morning'
        WHEN 'Zinc Picolinate' THEN 'with_meal'
        ELSE 'morning'
    END::supplement_timing_type,
    ARRAY[0,1,2,3,4,5,6],
    true,
    CURRENT_DATE - INTERVAL '30 days',
    CASE s.name
        WHEN 'Creatine Monohydrate' THEN 'Take daily for strength gains'
        WHEN 'Vitamin D3' THEN 'Take with breakfast for absorption'
        WHEN 'Magnesium Glycinate' THEN '30 min before bed for sleep quality'
        WHEN 'Omega-3 Fish Oil' THEN 'Take with largest meal'
        WHEN 'Ashwagandha KSM-66' THEN 'Evening for stress reduction'
        WHEN 'Vitamin K2 MK-7' THEN 'Take with D3 for synergy'
        WHEN 'Zinc Picolinate' THEN 'Take with food to avoid nausea'
        ELSE 'Auto-seeded demo routine'
    END
FROM supplements s
WHERE s.is_active = true
AND s.name ILIKE ANY(ARRAY[
    '%creatine%',
    '%vitamin d%',
    '%magnesium%',
    '%omega%',
    '%ashwagandha%',
    '%vitamin k%',
    '%zinc%'
])
AND NOT EXISTS (
    SELECT 1 FROM patient_supplement_routines psr
    WHERE psr.patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    AND psr.supplement_id = s.id
    AND psr.is_active = true
)
LIMIT 7
ON CONFLICT DO NOTHING;

-- If no supplements matched by name, insert by category with default values
INSERT INTO patient_supplement_routines (
    id, patient_id, supplement_id, dose, dose_unit, timing,
    days_of_week, is_active, start_date, notes
)
SELECT
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001'::uuid,
    s.id,
    500,  -- Default dose
    'mg', -- Default unit
    'morning'::supplement_timing_type,
    ARRAY[0,1,2,3,4,5,6],
    true,
    CURRENT_DATE - INTERVAL '14 days',
    'Seeded from category: ' || s.category::text
FROM supplements s
WHERE s.is_active = true
AND s.category::text IN ('performance', 'health', 'sleep')
AND NOT EXISTS (
    SELECT 1 FROM patient_supplement_routines psr
    WHERE psr.patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    AND psr.supplement_id = s.id
)
LIMIT 5
ON CONFLICT DO NOTHING;

-- Also seed into patient_supplement_stacks if that's a separate table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'patient_supplement_stacks' AND table_type = 'BASE TABLE') THEN
        -- Check what columns exist in patient_supplement_stacks
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'patient_supplement_stacks' AND column_name = 'supplement_id') THEN
            EXECUTE '
                INSERT INTO patient_supplement_stacks (
                    id, patient_id, supplement_id, dosage, dosage_unit, frequency, timing,
                    is_active
                )
                SELECT
                    gen_random_uuid(),
                    ''00000000-0000-0000-0000-000000000001''::uuid,
                    s.id,
                    500,
                    ''mg'',
                    ''daily'',
                    ''morning'',
                    true
                FROM supplements s
                WHERE s.is_active = true
                AND s.category::text IN (''performance'', ''health'', ''sleep'', ''recovery'')
                AND NOT EXISTS (
                    SELECT 1 FROM patient_supplement_stacks pss
                    WHERE pss.patient_id = ''00000000-0000-0000-0000-000000000001''::uuid
                    AND pss.supplement_id = s.id
                )
                LIMIT 5
                ON CONFLICT DO NOTHING
            ';
            RAISE NOTICE 'Seeded patient_supplement_stacks table';
        END IF;
    END IF;
END $$;

-- Verification
DO $$
DECLARE
    routine_count INTEGER;
    stacks_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO routine_count
    FROM patient_supplement_routines
    WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    AND is_active = true;

    -- Check if patient_supplement_stacks exists and count
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'patient_supplement_stacks' AND table_type = 'BASE TABLE') THEN
        EXECUTE 'SELECT COUNT(*) FROM patient_supplement_stacks WHERE patient_id = ''00000000-0000-0000-0000-000000000001''::uuid' INTO stacks_count;
    ELSE
        stacks_count := routine_count;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Demo Supplement Data Seeding Complete';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Demo patient routines: %', routine_count;
    RAISE NOTICE 'Demo patient stacks: %', stacks_count;
    RAISE NOTICE '';
END $$;

COMMIT;
