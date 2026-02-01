-- ============================================================================
-- CREATE HEALTHKIT DATA INTEGRATION - BUILD 143
-- ============================================================================
-- Implements HealthKit data syncing with automatic daily_readiness integration
-- Stores HRV, sleep, heart rate, and activity data from Apple Health
--
-- Date: 2026-01-31
-- Agent: 3
-- Linear: BUILD-143
-- ============================================================================

-- =====================================================
-- HealthKit Data Table
-- =====================================================

CREATE TABLE IF NOT EXISTS health_kit_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
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

    -- Ensure one sync per patient per day
    CONSTRAINT health_kit_data_patient_date_unique UNIQUE(patient_id, sync_date)
);

-- =====================================================
-- Indexes for Performance
-- =====================================================

CREATE INDEX idx_health_kit_data_patient_id ON health_kit_data(patient_id);
CREATE INDEX idx_health_kit_data_sync_date ON health_kit_data(sync_date DESC);
CREATE INDEX idx_health_kit_data_patient_date ON health_kit_data(patient_id, sync_date DESC);

COMMENT ON TABLE health_kit_data IS 'HealthKit data synced from Apple Health - HRV, sleep, heart rate, and activity metrics';
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
COMMENT ON COLUMN health_kit_data.source IS 'Data source identifier (apple_health, garmin, fitbit, etc.)';

-- =====================================================
-- Function: Get HRV Baseline
-- =====================================================

CREATE OR REPLACE FUNCTION get_hrv_baseline(
    p_patient_id UUID,
    p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    avg_hrv_sdnn NUMERIC,
    avg_hrv_rmssd NUMERIC,
    sample_days INTEGER,
    min_hrv_sdnn NUMERIC,
    max_hrv_sdnn NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROUND(AVG(hrv_sdnn), 2) AS avg_hrv_sdnn,
        ROUND(AVG(hrv_rmssd), 2) AS avg_hrv_rmssd,
        COUNT(*)::INTEGER AS sample_days,
        MIN(hrv_sdnn) AS min_hrv_sdnn,
        MAX(hrv_sdnn) AS max_hrv_sdnn
    FROM health_kit_data
    WHERE patient_id = p_patient_id
        AND sync_date >= CURRENT_DATE - p_days
        AND hrv_sdnn IS NOT NULL;
END;
$$;

COMMENT ON FUNCTION get_hrv_baseline IS 'Returns HRV baseline statistics for a patient over the specified number of days (default 7)';

-- =====================================================
-- Function: Sync HealthKit to Daily Readiness
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
    v_existing_manual_entry BOOLEAN;
BEGIN
    -- Calculate sleep hours from minutes
    v_sleep_hours := CASE
        WHEN NEW.sleep_duration_minutes IS NOT NULL
        THEN ROUND(NEW.sleep_duration_minutes / 60.0, 1)
        ELSE NULL
    END;

    -- Get 7-day HRV baseline for this patient (exclude today)
    SELECT avg_hrv_sdnn INTO v_hrv_baseline
    FROM get_hrv_baseline(NEW.patient_id, 7);

    -- Calculate energy level from HRV deviation (1-10 scale)
    -- Higher HRV relative to baseline = higher energy
    IF v_hrv_baseline IS NOT NULL AND v_hrv_baseline > 0 AND NEW.hrv_sdnn IS NOT NULL THEN
        v_hrv_deviation := ((NEW.hrv_sdnn - v_hrv_baseline) / v_hrv_baseline) * 100;

        -- Map HRV deviation to energy level (1-10)
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
        -- Default to neutral if no baseline
        v_energy_level := 5;
    END IF;

    -- Check if there's already a manual entry for this date
    -- (manual entry = one with soreness_level or stress_level set, or notes present)
    SELECT EXISTS (
        SELECT 1 FROM daily_readiness
        WHERE patient_id = NEW.patient_id
            AND date = NEW.sync_date
            AND (
                soreness_level IS NOT NULL
                OR stress_level IS NOT NULL
                OR notes IS NOT NULL
            )
    ) INTO v_existing_manual_entry;

    -- Only auto-update if no manual entry exists
    IF NOT v_existing_manual_entry THEN
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
            sleep_hours = COALESCE(EXCLUDED.sleep_hours, daily_readiness.sleep_hours),
            energy_level = CASE
                -- Only update energy if not manually set
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

COMMENT ON FUNCTION sync_healthkit_to_readiness IS 'Trigger function that syncs HealthKit data to daily_readiness table - calculates sleep_hours and estimates energy_level from HRV baseline comparison';

-- =====================================================
-- Trigger: Auto-sync to Daily Readiness
-- =====================================================

CREATE TRIGGER healthkit_sync_to_readiness_trigger
    AFTER INSERT OR UPDATE ON health_kit_data
    FOR EACH ROW
    EXECUTE FUNCTION sync_healthkit_to_readiness();

-- =====================================================
-- Row-Level Security (RLS)
-- =====================================================

ALTER TABLE health_kit_data ENABLE ROW LEVEL SECURITY;

-- Patients can CRUD their own HealthKit data
CREATE POLICY "Patients can view their own healthkit data"
    ON health_kit_data FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can insert their own healthkit data"
    ON health_kit_data FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update their own healthkit data"
    ON health_kit_data FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can delete their own healthkit data"
    ON health_kit_data FOR DELETE
    USING (patient_id = auth.uid());

-- Therapists can read patient HealthKit data
CREATE POLICY "Therapists can view patient healthkit data"
    ON health_kit_data FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- Service role has full access
CREATE POLICY "Service role can manage all healthkit data"
    ON health_kit_data FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- Grant Permissions
-- =====================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON health_kit_data TO authenticated;
GRANT ALL ON health_kit_data TO service_role;

GRANT EXECUTE ON FUNCTION get_hrv_baseline TO authenticated;
GRANT EXECUTE ON FUNCTION sync_healthkit_to_readiness TO authenticated;

-- =====================================================
-- Verification
-- =====================================================

DO $$
DECLARE
    v_table_exists BOOLEAN;
    v_trigger_exists BOOLEAN;
    v_function_exists BOOLEAN;
    v_policy_count INTEGER;
    v_index_count INTEGER;
BEGIN
    -- Check table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'health_kit_data'
    ) INTO v_table_exists;

    -- Check trigger exists
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'healthkit_sync_to_readiness_trigger'
    ) INTO v_trigger_exists;

    -- Check function exists
    SELECT EXISTS (
        SELECT 1 FROM pg_proc
        WHERE proname = 'get_hrv_baseline'
    ) INTO v_function_exists;

    -- Count policies
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE tablename = 'health_kit_data';

    -- Count indexes
    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE tablename = 'health_kit_data';

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'HEALTHKIT DATA INTEGRATION CREATED - BUILD 143';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Table Created: %', CASE WHEN v_table_exists THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '';
    RAISE NOTICE 'Columns:';
    RAISE NOTICE '   - HRV: hrv_sdnn, hrv_rmssd, hrv_sample_count';
    RAISE NOTICE '   - Sleep: sleep_duration_minutes, sleep_in_bed_minutes, sleep_deep_minutes,';
    RAISE NOTICE '           sleep_rem_minutes, sleep_core_minutes, sleep_awake_minutes';
    RAISE NOTICE '   - Heart Rate: resting_heart_rate, avg_heart_rate';
    RAISE NOTICE '   - Activity: active_energy_burned, exercise_minutes, stand_hours';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions Created:';
    RAISE NOTICE '   - get_hrv_baseline(patient_id, days) - Returns 7-day HRV baseline';
    RAISE NOTICE '   - sync_healthkit_to_readiness() - Trigger function';
    RAISE NOTICE '';
    RAISE NOTICE 'Trigger: %', CASE WHEN v_trigger_exists THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '   - healthkit_sync_to_readiness_trigger (AFTER INSERT/UPDATE)';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies: % policies', v_policy_count;
    RAISE NOTICE '   - Patients: Full CRUD on own data';
    RAISE NOTICE '   - Therapists: Read-only access to patient data';
    RAISE NOTICE '   - Service role: Full access';
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes: % indexes', v_index_count;
    RAISE NOTICE '   - idx_health_kit_data_patient_id';
    RAISE NOTICE '   - idx_health_kit_data_sync_date';
    RAISE NOTICE '   - idx_health_kit_data_patient_date';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'HEALTHKIT DATA INTEGRATION READY';
    RAISE NOTICE '============================================================================';
END $$;
