-- ============================================================================
-- BUILD 486: FIX SUPPLEMENT LOG TABLE COMPATIBILITY
-- ============================================================================
-- Problem: iOS service writes to patient_supplement_logs but reads from
--          supplement_logs (two different tables with different column names)
--
-- Solution: Standardize on supplement_logs table - create compatibility view
--           if needed and ensure anon access for demo patient
-- ============================================================================

BEGIN;

-- ============================================================================
-- PART 1: CHECK WHICH TABLE EXISTS AND STANDARDIZE
-- ============================================================================

-- If supplement_logs is the primary table, ensure it has the right structure
DO $$
BEGIN
    -- Check if supplement_logs exists as a table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_logs' AND table_type = 'BASE TABLE') THEN
        RAISE NOTICE 'supplement_logs table exists';

        -- Ensure columns exist for iOS compatibility (may already exist)
        -- The iOS app writes with: dose_amount, dose_unit, taken_at
        -- The iOS app reads with: dosage, dosage_unit, logged_at

        -- Add alias columns if they don't exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplement_logs' AND column_name = 'dose_amount') THEN
            -- Create computed/virtual approach won't work, so we'll handle in view
            NULL;
        END IF;
    END IF;

    -- Check if patient_supplement_logs exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'patient_supplement_logs' AND table_type = 'BASE TABLE') THEN
        RAISE NOTICE 'patient_supplement_logs table exists';
    END IF;
END $$;

-- ============================================================================
-- PART 2: CREATE VIEW FOR UNIFIED ACCESS (supplement_logs_unified)
-- ============================================================================
-- This view provides a unified interface that handles both table structures

DROP VIEW IF EXISTS supplement_logs_unified;

-- Create view that reads from whichever table exists with standardized columns
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_logs' AND table_type = 'BASE TABLE') THEN
        -- supplement_logs is the source - map to unified format
        EXECUTE '
            CREATE VIEW supplement_logs_unified AS
            SELECT
                id,
                patient_id,
                supplement_id,
                COALESCE(dosage, 0) AS dosage,
                COALESCE(dosage_unit, ''mg'') AS dosage_unit,
                COALESCE(dosage, 0) AS dose_amount,
                COALESCE(dosage_unit, ''mg'') AS dose_unit,
                timing,
                logged_at,
                logged_at AS taken_at,
                notes,
                created_at,
                updated_at
            FROM supplement_logs
        ';
        RAISE NOTICE 'Created supplement_logs_unified view from supplement_logs';
    ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'patient_supplement_logs' AND table_type = 'BASE TABLE') THEN
        -- patient_supplement_logs is the source - map to unified format
        EXECUTE '
            CREATE VIEW supplement_logs_unified AS
            SELECT
                id,
                patient_id,
                supplement_id,
                COALESCE(dose_amount, 0) AS dosage,
                COALESCE(dose_unit, ''mg'') AS dosage_unit,
                COALESCE(dose_amount, 0) AS dose_amount,
                COALESCE(dose_unit, ''mg'') AS dose_unit,
                timing,
                taken_at AS logged_at,
                taken_at,
                notes,
                created_at,
                updated_at
            FROM patient_supplement_logs
        ';
        RAISE NOTICE 'Created supplement_logs_unified view from patient_supplement_logs';
    END IF;
END $$;

-- Grant access to the unified view
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'supplement_logs_unified') THEN
        EXECUTE 'GRANT SELECT ON supplement_logs_unified TO authenticated';
        EXECUTE 'GRANT SELECT ON supplement_logs_unified TO anon';
        RAISE NOTICE 'Granted access to supplement_logs_unified view';
    END IF;
END $$;

-- ============================================================================
-- PART 3: ENSURE supplement_logs HAS CORRECT COLUMNS FOR WRITING
-- ============================================================================
-- Add columns if they don't exist (for compatibility with iOS write operations)

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_logs' AND table_type = 'BASE TABLE') THEN
        -- Add dose_amount if not exists (alias for dosage)
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplement_logs' AND column_name = 'dose_amount') THEN
            ALTER TABLE supplement_logs ADD COLUMN dose_amount NUMERIC;
            -- Copy existing dosage values
            UPDATE supplement_logs SET dose_amount = dosage WHERE dose_amount IS NULL;
            RAISE NOTICE 'Added dose_amount column to supplement_logs';
        END IF;

        -- Add dose_unit if not exists (alias for dosage_unit)
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplement_logs' AND column_name = 'dose_unit') THEN
            ALTER TABLE supplement_logs ADD COLUMN dose_unit TEXT DEFAULT 'mg';
            -- Copy existing dosage_unit values
            UPDATE supplement_logs SET dose_unit = dosage_unit WHERE dose_unit IS NULL;
            RAISE NOTICE 'Added dose_unit column to supplement_logs';
        END IF;

        -- Add taken_at if not exists (alias for logged_at)
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplement_logs' AND column_name = 'taken_at') THEN
            ALTER TABLE supplement_logs ADD COLUMN taken_at TIMESTAMPTZ;
            -- Copy existing logged_at values
            UPDATE supplement_logs SET taken_at = logged_at WHERE taken_at IS NULL;
            RAISE NOTICE 'Added taken_at column to supplement_logs';
        END IF;

        -- Add with_food if not exists
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplement_logs' AND column_name = 'with_food') THEN
            ALTER TABLE supplement_logs ADD COLUMN with_food BOOLEAN DEFAULT false;
            RAISE NOTICE 'Added with_food column to supplement_logs';
        END IF;

        -- Create trigger to sync alias columns
        CREATE OR REPLACE FUNCTION sync_supplement_log_columns()
        RETURNS TRIGGER AS $trigger$
        BEGIN
            -- Sync dosage <-> dose_amount
            IF NEW.dosage IS NOT NULL AND NEW.dose_amount IS NULL THEN
                NEW.dose_amount := NEW.dosage;
            ELSIF NEW.dose_amount IS NOT NULL AND NEW.dosage IS NULL THEN
                NEW.dosage := NEW.dose_amount;
            END IF;

            -- Sync dosage_unit <-> dose_unit
            IF NEW.dosage_unit IS NOT NULL AND NEW.dose_unit IS NULL THEN
                NEW.dose_unit := NEW.dosage_unit;
            ELSIF NEW.dose_unit IS NOT NULL AND NEW.dosage_unit IS NULL THEN
                NEW.dosage_unit := NEW.dose_unit;
            END IF;

            -- Sync logged_at <-> taken_at
            IF NEW.logged_at IS NOT NULL AND NEW.taken_at IS NULL THEN
                NEW.taken_at := NEW.logged_at;
            ELSIF NEW.taken_at IS NOT NULL AND NEW.logged_at IS NULL THEN
                NEW.logged_at := NEW.taken_at;
            END IF;

            -- Set defaults
            IF NEW.logged_at IS NULL AND NEW.taken_at IS NULL THEN
                NEW.logged_at := NOW();
                NEW.taken_at := NOW();
            END IF;

            RETURN NEW;
        END;
        $trigger$ LANGUAGE plpgsql;

        DROP TRIGGER IF EXISTS sync_supplement_log_columns_trigger ON supplement_logs;
        CREATE TRIGGER sync_supplement_log_columns_trigger
            BEFORE INSERT OR UPDATE ON supplement_logs
            FOR EACH ROW
            EXECUTE FUNCTION sync_supplement_log_columns();

        RAISE NOTICE 'Created column sync trigger on supplement_logs';
    END IF;
END $$;

-- ============================================================================
-- PART 4: ENSURE ANON POLICIES EXIST
-- ============================================================================

-- Add anon policies to supplement_logs if not already there
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_logs' AND table_type = 'BASE TABLE') THEN
        -- Enable RLS
        EXECUTE 'ALTER TABLE supplement_logs ENABLE ROW LEVEL SECURITY';

        -- Drop existing anon policies
        DROP POLICY IF EXISTS "supplement_logs_anon_select_demo" ON supplement_logs;
        DROP POLICY IF EXISTS "supplement_logs_anon_insert_demo" ON supplement_logs;
        DROP POLICY IF EXISTS "supplement_logs_anon_update_demo" ON supplement_logs;
        DROP POLICY IF EXISTS "supplement_logs_anon_delete_demo" ON supplement_logs;

        -- Create fresh anon policies for demo patient
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
        RAISE NOTICE 'Added/refreshed anon policies on supplement_logs';
    END IF;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
DECLARE
    logs_table_exists BOOLEAN;
    patient_logs_table_exists BOOLEAN;
    unified_view_exists BOOLEAN;
    column_count INTEGER;
BEGIN
    -- Check what exists
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'supplement_logs' AND table_type = 'BASE TABLE') INTO logs_table_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'patient_supplement_logs' AND table_type = 'BASE TABLE') INTO patient_logs_table_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'supplement_logs_unified') INTO unified_view_exists;

    -- Count columns in supplement_logs
    SELECT COUNT(*) INTO column_count
    FROM information_schema.columns
    WHERE table_name = 'supplement_logs';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Supplement Log Table Compatibility - BUILD 486';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'supplement_logs table exists: %', logs_table_exists;
    RAISE NOTICE 'patient_supplement_logs table exists: %', patient_logs_table_exists;
    RAISE NOTICE 'supplement_logs_unified view exists: %', unified_view_exists;
    RAISE NOTICE 'supplement_logs column count: %', column_count;
    RAISE NOTICE '';
    RAISE NOTICE 'iOS app should now be able to:';
    RAISE NOTICE '  - Write to supplement_logs with dose_amount/dose_unit/taken_at';
    RAISE NOTICE '  - Read from supplement_logs with dosage/dosage_unit/logged_at';
    RAISE NOTICE '  - Both column sets are synced via trigger';
    RAISE NOTICE '';
END $$;

COMMIT;
