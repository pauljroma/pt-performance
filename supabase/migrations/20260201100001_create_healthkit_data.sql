-- ============================================================================
-- CREATE HEALTHKIT DATA TABLE AND SYNC TRIGGER - SMART RECOVERY SYSTEM
-- ============================================================================
-- Implements HealthKit data syncing with automatic daily_readiness integration
-- Stores HRV, sleep, heart rate, and activity data from Apple Health
--
-- Date: 2026-02-01
-- Migration: 20260201100001_create_healthkit_data.sql
-- ============================================================================

-- =====================================================
-- SECTION 1: HealthKit Data Table
-- =====================================================

CREATE TABLE IF NOT EXISTS health_kit_data (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign Key
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Sync Date
    sync_date DATE NOT NULL,

    -- HRV Data
    hrv_sdnn NUMERIC(6,2),           -- Standard deviation of NN intervals (ms)
    hrv_rmssd NUMERIC(6,2),          -- Root mean square of successive differences (ms)
    hrv_sample_count INTEGER,         -- Number of HRV samples for the day

    -- Sleep Data
    sleep_duration_minutes INTEGER,   -- Total sleep time
    sleep_in_bed_minutes INTEGER,     -- Time in bed
    sleep_deep_minutes INTEGER,       -- Deep sleep duration
    sleep_rem_minutes INTEGER,        -- REM sleep duration
    sleep_core_minutes INTEGER,       -- Core/light sleep duration
    sleep_awake_minutes INTEGER,      -- Awake time during sleep period

    -- Heart Rate
    resting_heart_rate NUMERIC(5,2),  -- Resting heart rate (bpm)
    avg_heart_rate NUMERIC(5,2),      -- Average heart rate (bpm)

    -- Activity
    active_energy_burned NUMERIC(8,2), -- Active calories burned
    exercise_minutes INTEGER,          -- Exercise minutes
    stand_hours INTEGER,               -- Stand hours (Apple Watch rings)

    -- Metadata
    synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source TEXT NOT NULL DEFAULT 'apple_health',

    -- Unique constraint: one sync per patient per day
    CONSTRAINT health_kit_data_unique_patient_date UNIQUE(patient_id, sync_date)
);

-- =====================================================
-- SECTION 2: Indexes for Performance
-- =====================================================

-- Index on patient_id for filtering by patient
CREATE INDEX IF NOT EXISTS idx_health_kit_data_patient_id
    ON health_kit_data(patient_id);

-- Index on sync_date for date-based queries
CREATE INDEX IF NOT EXISTS idx_health_kit_data_sync_date
    ON health_kit_data(sync_date);

-- Composite index for patient + recent data queries
CREATE INDEX IF NOT EXISTS idx_health_kit_data_patient_date_desc
    ON health_kit_data(patient_id, sync_date DESC);

-- =====================================================
-- SECTION 3: Table and Column Comments
-- =====================================================

COMMENT ON TABLE health_kit_data IS 'HealthKit data synced from Apple Health for Smart Recovery system - HRV, sleep, heart rate, and activity metrics';
COMMENT ON COLUMN health_kit_data.id IS 'Unique identifier for the HealthKit data entry';
COMMENT ON COLUMN health_kit_data.patient_id IS 'Reference to the patient who owns this data';
COMMENT ON COLUMN health_kit_data.sync_date IS 'Date for which this health data applies';
COMMENT ON COLUMN health_kit_data.hrv_sdnn IS 'Standard deviation of NN intervals in milliseconds - primary HRV metric';
COMMENT ON COLUMN health_kit_data.hrv_rmssd IS 'Root mean square of successive differences in milliseconds - parasympathetic activity indicator';
COMMENT ON COLUMN health_kit_data.hrv_sample_count IS 'Number of HRV measurements taken for the day';
COMMENT ON COLUMN health_kit_data.sleep_duration_minutes IS 'Total sleep duration in minutes';
COMMENT ON COLUMN health_kit_data.sleep_in_bed_minutes IS 'Total time in bed in minutes';
COMMENT ON COLUMN health_kit_data.sleep_deep_minutes IS 'Deep sleep stage duration in minutes';
COMMENT ON COLUMN health_kit_data.sleep_rem_minutes IS 'REM sleep stage duration in minutes';
COMMENT ON COLUMN health_kit_data.sleep_core_minutes IS 'Core/light sleep stage duration in minutes';
COMMENT ON COLUMN health_kit_data.sleep_awake_minutes IS 'Time spent awake during sleep period in minutes';
COMMENT ON COLUMN health_kit_data.resting_heart_rate IS 'Resting heart rate in beats per minute';
COMMENT ON COLUMN health_kit_data.avg_heart_rate IS 'Average heart rate throughout the day in beats per minute';
COMMENT ON COLUMN health_kit_data.active_energy_burned IS 'Active energy burned in calories';
COMMENT ON COLUMN health_kit_data.exercise_minutes IS 'Exercise minutes for the day';
COMMENT ON COLUMN health_kit_data.stand_hours IS 'Number of stand hours achieved (Apple Watch)';
COMMENT ON COLUMN health_kit_data.synced_at IS 'Timestamp when data was synced from device';
COMMENT ON COLUMN health_kit_data.source IS 'Data source identifier (apple_health, garmin, fitbit, etc.)';

-- =====================================================
-- SECTION 4: Sync HealthKit to Readiness Function
-- =====================================================

CREATE OR REPLACE FUNCTION sync_healthkit_to_readiness()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sleep_hours NUMERIC(3,1);
    v_energy_level INTEGER;
    v_hrv_baseline NUMERIC;
    v_hrv_deviation NUMERIC;
    v_has_manual_entry BOOLEAN;
BEGIN
    -- Calculate sleep hours from sleep_duration_minutes / 60
    v_sleep_hours := CASE
        WHEN NEW.sleep_duration_minutes IS NOT NULL
        THEN ROUND(NEW.sleep_duration_minutes / 60.0, 1)
        ELSE NULL
    END;

    -- Get 7-day HRV baseline for this patient (exclude current day)
    SELECT AVG(hrv_sdnn) INTO v_hrv_baseline
    FROM health_kit_data
    WHERE patient_id = NEW.patient_id
        AND sync_date < NEW.sync_date
        AND sync_date >= NEW.sync_date - INTERVAL '7 days'
        AND hrv_sdnn IS NOT NULL;

    -- Estimate energy_level based on HRV deviation from baseline (1-10 scale)
    -- Higher HRV relative to baseline indicates better recovery = higher energy
    IF v_hrv_baseline IS NOT NULL AND v_hrv_baseline > 0 AND NEW.hrv_sdnn IS NOT NULL THEN
        -- Calculate percentage deviation from baseline
        v_hrv_deviation := ((NEW.hrv_sdnn - v_hrv_baseline) / v_hrv_baseline) * 100;

        -- Map HRV deviation to energy level (1-10 scale)
        -- +20% above baseline = 10, -20% below baseline = 1
        v_energy_level := CASE
            WHEN v_hrv_deviation >= 20 THEN 10
            WHEN v_hrv_deviation >= 15 THEN 9
            WHEN v_hrv_deviation >= 10 THEN 8
            WHEN v_hrv_deviation >= 5 THEN 7
            WHEN v_hrv_deviation >= 0 THEN 6
            WHEN v_hrv_deviation >= -5 THEN 5
            WHEN v_hrv_deviation >= -10 THEN 4
            WHEN v_hrv_deviation >= -15 THEN 3
            WHEN v_hrv_deviation >= -20 THEN 2
            ELSE 1
        END;
    ELSE
        -- Default to neutral energy level if no baseline data available
        v_energy_level := 5;
    END IF;

    -- Check if daily_readiness already has manual entries for this patient/date
    -- Manual entries are identified by having soreness_level, stress_level, or notes set
    SELECT EXISTS (
        SELECT 1 FROM daily_readiness
        WHERE patient_id = NEW.patient_id
            AND date = NEW.sync_date
            AND (
                soreness_level IS NOT NULL
                OR stress_level IS NOT NULL
                OR notes IS NOT NULL
            )
    ) INTO v_has_manual_entry;

    -- Only update daily_readiness if no manual entries exist for those fields
    IF NOT v_has_manual_entry THEN
        -- UPSERT into daily_readiness with calculated values
        INSERT INTO daily_readiness (
            patient_id,
            date,
            sleep_hours,
            energy_level
        )
        VALUES (
            NEW.patient_id,
            NEW.sync_date,
            v_sleep_hours,
            v_energy_level
        )
        ON CONFLICT (patient_id, date) DO UPDATE SET
            -- Only update sleep_hours if new value is not null
            sleep_hours = COALESCE(EXCLUDED.sleep_hours, daily_readiness.sleep_hours),
            -- Only update energy_level if no manual entry exists
            energy_level = CASE
                WHEN daily_readiness.soreness_level IS NULL
                     AND daily_readiness.stress_level IS NULL
                     AND daily_readiness.notes IS NULL
                THEN COALESCE(EXCLUDED.energy_level, daily_readiness.energy_level)
                ELSE daily_readiness.energy_level
            END,
            updated_at = NOW();
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION sync_healthkit_to_readiness IS 'Trigger function that syncs HealthKit data to daily_readiness table - calculates sleep_hours from minutes and estimates energy_level from HRV baseline comparison';

-- =====================================================
-- SECTION 5: Trigger Definition
-- =====================================================

-- Drop trigger if exists to allow re-running migration
DROP TRIGGER IF EXISTS sync_healthkit_data ON health_kit_data;

-- Create trigger that fires AFTER INSERT OR UPDATE
CREATE TRIGGER sync_healthkit_data
    AFTER INSERT OR UPDATE ON health_kit_data
    FOR EACH ROW
    EXECUTE FUNCTION sync_healthkit_to_readiness();

-- =====================================================
-- SECTION 6: Row-Level Security (RLS)
-- =====================================================

-- Enable RLS on the table
ALTER TABLE health_kit_data ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Users can read own patient healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Users can insert own patient healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Users can update own patient healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Users can delete own patient healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Service role full access to healthkit data" ON health_kit_data;

-- SELECT policy: Authenticated users can read their own patient's health_kit_data
CREATE POLICY "Users can read own patient healthkit data"
    ON health_kit_data FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- INSERT policy: Authenticated users can insert their own patient's health_kit_data
CREATE POLICY "Users can insert own patient healthkit data"
    ON health_kit_data FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- UPDATE policy: Authenticated users can update their own patient's health_kit_data
CREATE POLICY "Users can update own patient healthkit data"
    ON health_kit_data FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- DELETE policy: Authenticated users can delete their own patient's health_kit_data
CREATE POLICY "Users can delete own patient healthkit data"
    ON health_kit_data FOR DELETE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Service role has full access for backend operations
CREATE POLICY "Service role full access to healthkit data"
    ON health_kit_data FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- SECTION 7: Grant Statements
-- =====================================================

-- Grant CRUD permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON health_kit_data TO authenticated;

-- Grant full access to service role
GRANT ALL ON health_kit_data TO service_role;

-- Grant execute on the sync function
GRANT EXECUTE ON FUNCTION sync_healthkit_to_readiness TO authenticated;
GRANT EXECUTE ON FUNCTION sync_healthkit_to_readiness TO service_role;

-- =====================================================
-- SECTION 8: Verification
-- =====================================================

DO $$
DECLARE
    v_table_exists BOOLEAN;
    v_trigger_exists BOOLEAN;
    v_function_exists BOOLEAN;
    v_policy_count INTEGER;
    v_index_count INTEGER;
BEGIN
    -- Verify table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'health_kit_data'
    ) INTO v_table_exists;

    -- Verify trigger exists
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'sync_healthkit_data'
    ) INTO v_trigger_exists;

    -- Verify function exists
    SELECT EXISTS (
        SELECT 1 FROM pg_proc
        WHERE proname = 'sync_healthkit_to_readiness'
    ) INTO v_function_exists;

    -- Count RLS policies
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE tablename = 'health_kit_data';

    -- Count indexes
    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE tablename = 'health_kit_data';

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'HEALTHKIT DATA TABLE AND SYNC TRIGGER - SMART RECOVERY SYSTEM';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Table: health_kit_data - %', CASE WHEN v_table_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE '';
    RAISE NOTICE 'Columns:';
    RAISE NOTICE '  - id UUID PRIMARY KEY';
    RAISE NOTICE '  - patient_id UUID (FK to patients)';
    RAISE NOTICE '  - sync_date DATE';
    RAISE NOTICE '  - HRV: hrv_sdnn, hrv_rmssd, hrv_sample_count';
    RAISE NOTICE '  - Sleep: sleep_duration_minutes, sleep_in_bed_minutes, sleep_deep_minutes,';
    RAISE NOTICE '           sleep_rem_minutes, sleep_core_minutes, sleep_awake_minutes';
    RAISE NOTICE '  - Heart Rate: resting_heart_rate, avg_heart_rate';
    RAISE NOTICE '  - Activity: active_energy_burned, exercise_minutes, stand_hours';
    RAISE NOTICE '  - Metadata: synced_at, source';
    RAISE NOTICE '';
    RAISE NOTICE 'Function: sync_healthkit_to_readiness() - %', CASE WHEN v_function_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE '  - Calculates sleep_hours from sleep_duration_minutes / 60';
    RAISE NOTICE '  - Estimates energy_level from HRV deviation vs 7-day baseline';
    RAISE NOTICE '  - UPSERTs into daily_readiness (respects manual entries)';
    RAISE NOTICE '';
    RAISE NOTICE 'Trigger: sync_healthkit_data - %', CASE WHEN v_trigger_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE '  - Fires AFTER INSERT OR UPDATE on health_kit_data';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies: % policies created', v_policy_count;
    RAISE NOTICE '  - Users can read/insert/update/delete own patient data';
    RAISE NOTICE '  - Uses subquery: patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())';
    RAISE NOTICE '  - Service role has full access';
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes: % indexes created', v_index_count;
    RAISE NOTICE '  - idx_health_kit_data_patient_id';
    RAISE NOTICE '  - idx_health_kit_data_sync_date';
    RAISE NOTICE '  - idx_health_kit_data_patient_date_desc';
    RAISE NOTICE '';
    RAISE NOTICE 'Grants:';
    RAISE NOTICE '  - authenticated: SELECT, INSERT, UPDATE, DELETE';
    RAISE NOTICE '  - service_role: ALL';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'MIGRATION COMPLETE: 20260201100001_create_healthkit_data.sql';
    RAISE NOTICE '============================================================================';
END $$;
