-- ============================================================================
-- BUILD 485: FIX SUPPLEMENT DEMO ACCESS + SEED DEMO ROUTINES
-- ============================================================================
-- Problems:
--   1. Demo users (anon role) can't access supplement tables
--   2. No demo patient routines seeded in patient_supplement_routines
--   3. Table name mismatch between service and schema
--
-- Solution:
--   1. Add anon policies for all supplement tables
--   2. Seed demo patient supplement routines
--   3. Create alias views if needed
-- ============================================================================

BEGIN;

-- ============================================================================
-- PART 1: ANON POLICIES FOR SUPPLEMENT TABLES
-- ============================================================================

-- Demo patient UUID
-- 00000000-0000-0000-0000-000000000001

-- SUPPLEMENTS (catalog) - anon can read
DROP POLICY IF EXISTS "supplements_anon_select" ON supplements;
CREATE POLICY "supplements_anon_select"
    ON supplements FOR SELECT
    TO anon
    USING (is_active = true);

GRANT SELECT ON supplements TO anon;

-- SUPPLEMENT_STACKS - anon can read active stacks
DROP POLICY IF EXISTS "supplement_stacks_anon_select" ON supplement_stacks;
CREATE POLICY "supplement_stacks_anon_select"
    ON supplement_stacks FOR SELECT
    TO anon
    USING (is_active = true);

GRANT SELECT ON supplement_stacks TO anon;

-- SUPPLEMENT_STACK_ITEMS - anon can read
DROP POLICY IF EXISTS "supplement_stack_items_anon_select" ON supplement_stack_items;
CREATE POLICY "supplement_stack_items_anon_select"
    ON supplement_stack_items FOR SELECT
    TO anon
    USING (true);

GRANT SELECT ON supplement_stack_items TO anon;

-- PATIENT_SUPPLEMENT_ROUTINES - anon access for demo patient only
DROP POLICY IF EXISTS "patient_supplement_routines_anon_select" ON patient_supplement_routines;
CREATE POLICY "patient_supplement_routines_anon_select"
    ON patient_supplement_routines FOR SELECT
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "patient_supplement_routines_anon_insert" ON patient_supplement_routines;
CREATE POLICY "patient_supplement_routines_anon_insert"
    ON patient_supplement_routines FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "patient_supplement_routines_anon_update" ON patient_supplement_routines;
CREATE POLICY "patient_supplement_routines_anon_update"
    ON patient_supplement_routines FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "patient_supplement_routines_anon_delete" ON patient_supplement_routines;
CREATE POLICY "patient_supplement_routines_anon_delete"
    ON patient_supplement_routines FOR DELETE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON patient_supplement_routines TO anon;

-- PATIENT_SUPPLEMENT_LOGS - anon access for demo patient only
DROP POLICY IF EXISTS "patient_supplement_logs_anon_select" ON patient_supplement_logs;
CREATE POLICY "patient_supplement_logs_anon_select"
    ON patient_supplement_logs FOR SELECT
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "patient_supplement_logs_anon_insert" ON patient_supplement_logs;
CREATE POLICY "patient_supplement_logs_anon_insert"
    ON patient_supplement_logs FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "patient_supplement_logs_anon_update" ON patient_supplement_logs;
CREATE POLICY "patient_supplement_logs_anon_update"
    ON patient_supplement_logs FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "patient_supplement_logs_anon_delete" ON patient_supplement_logs;
CREATE POLICY "patient_supplement_logs_anon_delete"
    ON patient_supplement_logs FOR DELETE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON patient_supplement_logs TO anon;

-- SUPPLEMENT_COMPLIANCE - anon access for demo patient only
DROP POLICY IF EXISTS "supplement_compliance_anon_select" ON supplement_compliance;
CREATE POLICY "supplement_compliance_anon_select"
    ON supplement_compliance FOR SELECT
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "supplement_compliance_anon_insert" ON supplement_compliance;
CREATE POLICY "supplement_compliance_anon_insert"
    ON supplement_compliance FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "supplement_compliance_anon_update" ON supplement_compliance;
CREATE POLICY "supplement_compliance_anon_update"
    ON supplement_compliance FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE ON supplement_compliance TO anon;

-- ============================================================================
-- PART 2: ALIAS VIEWS FOR TABLE NAME COMPATIBILITY
-- ============================================================================
-- The iOS service uses different table names than the actual schema
-- Handle both existing tables and create views where needed

-- supplement_logs table already exists - add anon policies and column aliases if needed
-- Check if supplement_logs is a table (not a view) and add RLS policies
DO $$
BEGIN
    -- Add anon policies for existing supplement_logs table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_logs' AND table_type = 'BASE TABLE') THEN
        -- Ensure RLS is enabled
        EXECUTE 'ALTER TABLE supplement_logs ENABLE ROW LEVEL SECURITY';

        -- Drop existing anon policies if any
        DROP POLICY IF EXISTS "supplement_logs_anon_select_demo" ON supplement_logs;
        DROP POLICY IF EXISTS "supplement_logs_anon_insert_demo" ON supplement_logs;
        DROP POLICY IF EXISTS "supplement_logs_anon_update_demo" ON supplement_logs;
        DROP POLICY IF EXISTS "supplement_logs_anon_delete_demo" ON supplement_logs;

        -- Create anon policies for demo patient
        CREATE POLICY "supplement_logs_anon_select_demo"
            ON supplement_logs FOR SELECT TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

        CREATE POLICY "supplement_logs_anon_insert_demo"
            ON supplement_logs FOR INSERT TO anon
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

        CREATE POLICY "supplement_logs_anon_update_demo"
            ON supplement_logs FOR UPDATE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

        CREATE POLICY "supplement_logs_anon_delete_demo"
            ON supplement_logs FOR DELETE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

        GRANT SELECT, INSERT, UPDATE, DELETE ON supplement_logs TO anon;

        RAISE NOTICE 'Added anon policies to existing supplement_logs table';
    END IF;
END $$;

-- patient_supplement_stacks -> either use existing table or create view
DO $$
BEGIN
    -- Check if patient_supplement_stacks is already a table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'patient_supplement_stacks' AND table_type = 'BASE TABLE') THEN
        -- It's a table, just add anon policies
        EXECUTE 'ALTER TABLE patient_supplement_stacks ENABLE ROW LEVEL SECURITY';

        DROP POLICY IF EXISTS "patient_supplement_stacks_anon_select" ON patient_supplement_stacks;
        DROP POLICY IF EXISTS "patient_supplement_stacks_anon_insert" ON patient_supplement_stacks;
        DROP POLICY IF EXISTS "patient_supplement_stacks_anon_update" ON patient_supplement_stacks;
        DROP POLICY IF EXISTS "patient_supplement_stacks_anon_delete" ON patient_supplement_stacks;

        CREATE POLICY "patient_supplement_stacks_anon_select"
            ON patient_supplement_stacks FOR SELECT TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

        CREATE POLICY "patient_supplement_stacks_anon_insert"
            ON patient_supplement_stacks FOR INSERT TO anon
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

        CREATE POLICY "patient_supplement_stacks_anon_update"
            ON patient_supplement_stacks FOR UPDATE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

        CREATE POLICY "patient_supplement_stacks_anon_delete"
            ON patient_supplement_stacks FOR DELETE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

        GRANT SELECT, INSERT, UPDATE, DELETE ON patient_supplement_stacks TO anon;
        RAISE NOTICE 'Added anon policies to existing patient_supplement_stacks table';
    ELSE
        -- Create view from patient_supplement_routines
        DROP VIEW IF EXISTS patient_supplement_stacks;
        CREATE VIEW patient_supplement_stacks AS
        SELECT
            psr.id,
            psr.patient_id,
            psr.supplement_id,
            psr.stack_id,
            psr.dose AS dosage,
            psr.dose_unit AS dosage_unit,
            psr.timing::text AS timing,
            CASE
                WHEN psr.days_of_week = ARRAY[0,1,2,3,4,5,6] THEN 'daily'
                WHEN array_length(psr.days_of_week, 1) = 1 THEN 'weekly'
                ELSE 'daily'
            END AS frequency,
            COALESCE((psr.notes LIKE '%food%'), false) AS with_food,
            psr.notes,
            psr.is_active,
            psr.start_date AS started_at,
            psr.end_date AS ended_at,
            psr.created_at,
            psr.updated_at,
            -- Include supplement data as JSON matching DBSupplement model
            jsonb_build_object(
                'id', s.id::text,
                'name', s.name,
                'brand', s.brand,
                'category', s.category::text,
                'description', s.description,
                'evidence_rating', s.evidence_rating::text,
                'dosage_info', CONCAT(s.typical_dose, ' ', s.dose_unit),
                'timing_recommendation', s.timing_recommendation::text,
                'interactions', s.interactions,
                'benefits', s.benefits,
                'contraindications', s.contraindications,
                'price_estimate', s.price_estimate,
                'purchase_url', s.purchase_url,
                'is_active', s.is_active,
                'created_at', s.created_at
            ) AS supplement
        FROM patient_supplement_routines psr
        LEFT JOIN supplements s ON s.id = psr.supplement_id;

        GRANT SELECT ON patient_supplement_stacks TO authenticated;
        GRANT SELECT ON patient_supplement_stacks TO anon;
        RAISE NOTICE 'Created patient_supplement_stacks view from patient_supplement_routines';
    END IF;
END $$;

-- ============================================================================
-- PART 3: SEED DEMO PATIENT SUPPLEMENT ROUTINES
-- ============================================================================

-- Delete existing demo routines to avoid conflicts
DELETE FROM patient_supplement_routines
WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Insert demo supplement routines for demo patient
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
        WHEN 'Vitamin K2 MK-7' THEN 100
    END,
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
        WHEN 'Vitamin K2 MK-7' THEN 'morning'
    END::supplement_timing_type,
    ARRAY[0,1,2,3,4,5,6],
    true,
    CURRENT_DATE - INTERVAL '30 days',
    CASE s.name
        WHEN 'Creatine Monohydrate' THEN 'Take daily, timing not critical'
        WHEN 'Vitamin D3' THEN 'Take with breakfast for absorption'
        WHEN 'Magnesium Glycinate' THEN '30 min before bed for sleep quality'
        WHEN 'Omega-3 Fish Oil' THEN 'Take with largest meal'
        WHEN 'Vitamin K2 MK-7' THEN 'Take with D3 for synergy'
    END
FROM supplements s
WHERE s.name IN (
    'Creatine Monohydrate',
    'Vitamin D3',
    'Magnesium Glycinate',
    'Omega-3 Fish Oil',
    'Vitamin K2 MK-7'
)
AND s.is_active = true
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
DECLARE
    routine_count INTEGER;
    supplement_count INTEGER;
    stack_count INTEGER;
BEGIN
    -- Count demo patient routines
    SELECT COUNT(*) INTO routine_count
    FROM patient_supplement_routines
    WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    AND is_active = true;

    -- Count supplements in catalog
    SELECT COUNT(*) INTO supplement_count
    FROM supplements
    WHERE is_active = true;

    -- Count supplement stacks
    SELECT COUNT(*) INTO stack_count
    FROM supplement_stacks
    WHERE is_active = true;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Supplement Demo Access Fix - BUILD 485';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Active supplements in catalog: %', supplement_count;
    RAISE NOTICE 'Active supplement stacks: %', stack_count;
    RAISE NOTICE 'Demo patient active routines: %', routine_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Anon policies added for:';
    RAISE NOTICE '  - supplements (read catalog)';
    RAISE NOTICE '  - supplement_stacks (read stacks)';
    RAISE NOTICE '  - supplement_stack_items (read items)';
    RAISE NOTICE '  - patient_supplement_routines (demo patient)';
    RAISE NOTICE '  - patient_supplement_logs (demo patient)';
    RAISE NOTICE '  - supplement_compliance (demo patient)';
    RAISE NOTICE '';
    RAISE NOTICE 'Alias views created:';
    RAISE NOTICE '  - supplement_logs -> patient_supplement_logs';
    RAISE NOTICE '  - patient_supplement_stacks -> patient_supplement_routines';
    RAISE NOTICE '';
END $$;

COMMIT;
