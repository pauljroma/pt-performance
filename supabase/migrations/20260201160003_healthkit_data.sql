-- ============================================================================
-- HEALTHKIT DATA STORAGE SCHEMA - SMART RECOVERY SPRINT
-- ============================================================================
-- Extends HealthKit data storage with HRV baselines, readiness scoring,
-- and automatic sync to daily_readiness
--
-- Date: 2026-02-01
-- Agent: 3
-- Sprint: Smart Recovery
-- ============================================================================

-- =====================================================
-- SECTION 1: Extend health_kit_data Table
-- =====================================================
-- Add missing columns if table exists, or create full table

DO $$
BEGIN
    -- Add missing columns to existing table if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'health_kit_data') THEN
        -- Add min_heart_rate if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'health_kit_data' AND column_name = 'min_heart_rate') THEN
            ALTER TABLE health_kit_data ADD COLUMN min_heart_rate NUMERIC(5,2);
            COMMENT ON COLUMN health_kit_data.min_heart_rate IS 'Minimum heart rate in beats per minute';
        END IF;

        -- Add max_heart_rate if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'health_kit_data' AND column_name = 'max_heart_rate') THEN
            ALTER TABLE health_kit_data ADD COLUMN max_heart_rate NUMERIC(5,2);
            COMMENT ON COLUMN health_kit_data.max_heart_rate IS 'Maximum heart rate in beats per minute';
        END IF;

        -- Add basal_energy_burned if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'health_kit_data' AND column_name = 'basal_energy_burned') THEN
            ALTER TABLE health_kit_data ADD COLUMN basal_energy_burned NUMERIC(8,2);
            COMMENT ON COLUMN health_kit_data.basal_energy_burned IS 'Basal metabolic energy burned in calories';
        END IF;

        -- Add step_count if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'health_kit_data' AND column_name = 'step_count') THEN
            ALTER TABLE health_kit_data ADD COLUMN step_count INTEGER;
            COMMENT ON COLUMN health_kit_data.step_count IS 'Total step count for the day';
        END IF;

        -- Add respiratory_rate if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'health_kit_data' AND column_name = 'respiratory_rate') THEN
            ALTER TABLE health_kit_data ADD COLUMN respiratory_rate NUMERIC(5,2);
            COMMENT ON COLUMN health_kit_data.respiratory_rate IS 'Respiratory rate in breaths per minute';
        END IF;

        -- Add blood_oxygen if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'health_kit_data' AND column_name = 'blood_oxygen') THEN
            ALTER TABLE health_kit_data ADD COLUMN blood_oxygen NUMERIC(5,2);
            COMMENT ON COLUMN health_kit_data.blood_oxygen IS 'Blood oxygen saturation percentage (SpO2)';
        END IF;

        -- Add raw_data JSONB if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'health_kit_data' AND column_name = 'raw_data') THEN
            ALTER TABLE health_kit_data ADD COLUMN raw_data JSONB;
            COMMENT ON COLUMN health_kit_data.raw_data IS 'Raw HealthKit data payload for debugging and additional metrics';
        END IF;

        RAISE NOTICE 'Extended existing health_kit_data table with additional columns';
    ELSE
        -- Create full table if it does not exist
        CREATE TABLE health_kit_data (
            -- Primary Key
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

            -- Foreign Key
            patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

            -- Sync Date (unique with patient_id)
            sync_date DATE NOT NULL,

            -- HRV Data
            hrv_sdnn NUMERIC(6,2),              -- Standard deviation of NN intervals (ms)
            hrv_rmssd NUMERIC(6,2),             -- Root mean square of successive differences (ms)
            hrv_sample_count INTEGER,           -- Number of HRV samples for the day

            -- Sleep Data
            sleep_duration_minutes INTEGER,     -- Total sleep time
            sleep_in_bed_minutes INTEGER,       -- Time in bed
            sleep_deep_minutes INTEGER,         -- Deep sleep duration
            sleep_rem_minutes INTEGER,          -- REM sleep duration
            sleep_core_minutes INTEGER,         -- Core/light sleep duration
            sleep_awake_minutes INTEGER,        -- Awake time during sleep period

            -- Heart Rate
            resting_heart_rate NUMERIC(5,2),   -- Resting heart rate (bpm)
            avg_heart_rate NUMERIC(5,2),       -- Average heart rate (bpm)
            min_heart_rate NUMERIC(5,2),       -- Minimum heart rate (bpm)
            max_heart_rate NUMERIC(5,2),       -- Maximum heart rate (bpm)

            -- Activity
            active_energy_burned NUMERIC(8,2), -- Active calories burned
            basal_energy_burned NUMERIC(8,2),  -- Basal metabolic calories
            exercise_minutes INTEGER,          -- Exercise minutes
            stand_hours INTEGER,               -- Stand hours (Apple Watch rings)
            step_count INTEGER,                -- Total step count

            -- Respiratory
            respiratory_rate NUMERIC(5,2),     -- Breaths per minute
            blood_oxygen NUMERIC(5,2),         -- SpO2 percentage

            -- Metadata
            synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            source TEXT NOT NULL DEFAULT 'apple_health',
            raw_data JSONB,                    -- Raw HealthKit payload

            -- Unique constraint: one sync per patient per day
            CONSTRAINT health_kit_data_unique_patient_date UNIQUE(patient_id, sync_date)
        );

        -- Create indexes
        CREATE INDEX idx_health_kit_data_patient_id ON health_kit_data(patient_id);
        CREATE INDEX idx_health_kit_data_sync_date ON health_kit_data(sync_date DESC);
        CREATE INDEX idx_health_kit_data_patient_date_desc ON health_kit_data(patient_id, sync_date DESC);

        RAISE NOTICE 'Created new health_kit_data table with all columns';
    END IF;
END $$;

-- Add comments for new columns
COMMENT ON TABLE health_kit_data IS 'HealthKit data synced from Apple Health for Smart Recovery system - HRV, sleep, heart rate, activity, and respiratory metrics';

-- =====================================================
-- SECTION 2: HRV Baselines Table
-- =====================================================

CREATE TABLE IF NOT EXISTS hrv_baselines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Patient reference (one baseline record per patient)
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Rolling baseline values (SDNN)
    baseline_7d NUMERIC(6,2),              -- 7-day rolling average
    baseline_14d NUMERIC(6,2),             -- 14-day rolling average
    baseline_30d NUMERIC(6,2),             -- 30-day rolling average

    -- Standard deviation for variance detection
    stddev_7d NUMERIC(6,2),                -- 7-day standard deviation
    stddev_30d NUMERIC(6,2),               -- 30-day standard deviation

    -- Sample counts for data quality assessment
    sample_count_7d INTEGER DEFAULT 0,     -- Number of samples in 7-day window
    sample_count_14d INTEGER DEFAULT 0,    -- Number of samples in 14-day window
    sample_count_30d INTEGER DEFAULT 0,    -- Number of samples in 30-day window

    -- Timestamps
    last_calculated_at TIMESTAMPTZ,        -- When baselines were last calculated
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one baseline record per patient
    CONSTRAINT hrv_baselines_unique_patient UNIQUE(patient_id)
);

-- Indexes for hrv_baselines
CREATE INDEX IF NOT EXISTS idx_hrv_baselines_patient_id ON hrv_baselines(patient_id);
CREATE INDEX IF NOT EXISTS idx_hrv_baselines_last_calculated ON hrv_baselines(last_calculated_at DESC);

-- Comments
COMMENT ON TABLE hrv_baselines IS 'Rolling HRV baseline calculations for each patient - used for readiness scoring';
COMMENT ON COLUMN hrv_baselines.patient_id IS 'Reference to the patient';
COMMENT ON COLUMN hrv_baselines.baseline_7d IS '7-day rolling average HRV SDNN in milliseconds';
COMMENT ON COLUMN hrv_baselines.baseline_14d IS '14-day rolling average HRV SDNN in milliseconds';
COMMENT ON COLUMN hrv_baselines.baseline_30d IS '30-day rolling average HRV SDNN in milliseconds';
COMMENT ON COLUMN hrv_baselines.stddev_7d IS '7-day standard deviation for variance detection';
COMMENT ON COLUMN hrv_baselines.stddev_30d IS '30-day standard deviation for variance detection';
COMMENT ON COLUMN hrv_baselines.sample_count_7d IS 'Number of HRV samples in 7-day window';
COMMENT ON COLUMN hrv_baselines.sample_count_14d IS 'Number of HRV samples in 14-day window';
COMMENT ON COLUMN hrv_baselines.sample_count_30d IS 'Number of HRV samples in 30-day window';
COMMENT ON COLUMN hrv_baselines.last_calculated_at IS 'Timestamp of last baseline calculation';

-- =====================================================
-- SECTION 3: Add data_source Column to daily_readiness
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'daily_readiness' AND column_name = 'data_source') THEN
        ALTER TABLE daily_readiness ADD COLUMN data_source TEXT DEFAULT 'manual';
        COMMENT ON COLUMN daily_readiness.data_source IS 'Source of data: manual, apple_health, whoop, garmin, fitbit';
        RAISE NOTICE 'Added data_source column to daily_readiness';
    ELSE
        RAISE NOTICE 'data_source column already exists in daily_readiness';
    END IF;
END $$;

-- =====================================================
-- SECTION 4: Function - calculate_hrv_baseline
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_hrv_baseline(p_patient_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_baseline_7d NUMERIC(6,2);
    v_baseline_14d NUMERIC(6,2);
    v_baseline_30d NUMERIC(6,2);
    v_stddev_7d NUMERIC(6,2);
    v_stddev_30d NUMERIC(6,2);
    v_count_7d INTEGER;
    v_count_14d INTEGER;
    v_count_30d INTEGER;
BEGIN
    -- Calculate 7-day baseline
    SELECT
        ROUND(AVG(hrv_sdnn), 2),
        ROUND(STDDEV(hrv_sdnn), 2),
        COUNT(*)::INTEGER
    INTO v_baseline_7d, v_stddev_7d, v_count_7d
    FROM health_kit_data
    WHERE patient_id = p_patient_id
        AND sync_date >= CURRENT_DATE - INTERVAL '7 days'
        AND hrv_sdnn IS NOT NULL;

    -- Calculate 14-day baseline
    SELECT
        ROUND(AVG(hrv_sdnn), 2),
        COUNT(*)::INTEGER
    INTO v_baseline_14d, v_count_14d
    FROM health_kit_data
    WHERE patient_id = p_patient_id
        AND sync_date >= CURRENT_DATE - INTERVAL '14 days'
        AND hrv_sdnn IS NOT NULL;

    -- Calculate 30-day baseline
    SELECT
        ROUND(AVG(hrv_sdnn), 2),
        ROUND(STDDEV(hrv_sdnn), 2),
        COUNT(*)::INTEGER
    INTO v_baseline_30d, v_stddev_30d, v_count_30d
    FROM health_kit_data
    WHERE patient_id = p_patient_id
        AND sync_date >= CURRENT_DATE - INTERVAL '30 days'
        AND hrv_sdnn IS NOT NULL;

    -- UPSERT into hrv_baselines
    INSERT INTO hrv_baselines (
        patient_id,
        baseline_7d,
        baseline_14d,
        baseline_30d,
        stddev_7d,
        stddev_30d,
        sample_count_7d,
        sample_count_14d,
        sample_count_30d,
        last_calculated_at,
        updated_at
    )
    VALUES (
        p_patient_id,
        v_baseline_7d,
        v_baseline_14d,
        v_baseline_30d,
        v_stddev_7d,
        v_stddev_30d,
        COALESCE(v_count_7d, 0),
        COALESCE(v_count_14d, 0),
        COALESCE(v_count_30d, 0),
        NOW(),
        NOW()
    )
    ON CONFLICT (patient_id) DO UPDATE SET
        baseline_7d = EXCLUDED.baseline_7d,
        baseline_14d = EXCLUDED.baseline_14d,
        baseline_30d = EXCLUDED.baseline_30d,
        stddev_7d = EXCLUDED.stddev_7d,
        stddev_30d = EXCLUDED.stddev_30d,
        sample_count_7d = EXCLUDED.sample_count_7d,
        sample_count_14d = EXCLUDED.sample_count_14d,
        sample_count_30d = EXCLUDED.sample_count_30d,
        last_calculated_at = NOW(),
        updated_at = NOW();

END;
$$;

COMMENT ON FUNCTION calculate_hrv_baseline IS 'Calculates and stores rolling HRV baselines (7d, 14d, 30d) for a patient';

-- =====================================================
-- SECTION 5: Function - get_hrv_readiness_score
-- =====================================================

CREATE OR REPLACE FUNCTION get_hrv_readiness_score(p_patient_id UUID)
RETURNS TABLE (
    today_hrv NUMERIC,
    baseline_hrv NUMERIC,
    deviation_pct NUMERIC,
    readiness_impact TEXT,
    suggested_adjustment NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_today_hrv NUMERIC;
    v_baseline_hrv NUMERIC;
    v_stddev NUMERIC;
    v_deviation_pct NUMERIC;
    v_readiness_impact TEXT;
    v_suggested_adjustment NUMERIC;
BEGIN
    -- Get today's HRV
    SELECT hrv_sdnn INTO v_today_hrv
    FROM health_kit_data
    WHERE patient_id = p_patient_id
        AND sync_date = CURRENT_DATE
        AND hrv_sdnn IS NOT NULL
    ORDER BY synced_at DESC
    LIMIT 1;

    -- If no today's HRV, try yesterday
    IF v_today_hrv IS NULL THEN
        SELECT hrv_sdnn INTO v_today_hrv
        FROM health_kit_data
        WHERE patient_id = p_patient_id
            AND sync_date = CURRENT_DATE - INTERVAL '1 day'
            AND hrv_sdnn IS NOT NULL
        ORDER BY synced_at DESC
        LIMIT 1;
    END IF;

    -- Get baseline (prefer 7-day, fallback to 14-day, then 30-day)
    SELECT
        COALESCE(baseline_7d, baseline_14d, baseline_30d),
        COALESCE(stddev_7d, stddev_30d)
    INTO v_baseline_hrv, v_stddev
    FROM hrv_baselines
    WHERE patient_id = p_patient_id;

    -- If no baseline exists, calculate it now
    IF v_baseline_hrv IS NULL THEN
        PERFORM calculate_hrv_baseline(p_patient_id);

        SELECT
            COALESCE(baseline_7d, baseline_14d, baseline_30d),
            COALESCE(stddev_7d, stddev_30d)
        INTO v_baseline_hrv, v_stddev
        FROM hrv_baselines
        WHERE patient_id = p_patient_id;
    END IF;

    -- Calculate deviation percentage
    IF v_baseline_hrv IS NOT NULL AND v_baseline_hrv > 0 AND v_today_hrv IS NOT NULL THEN
        v_deviation_pct := ROUND(((v_today_hrv - v_baseline_hrv) / v_baseline_hrv) * 100, 1);
    ELSE
        v_deviation_pct := 0;
    END IF;

    -- Determine readiness impact and suggested adjustment
    -- Based on standard deviation bands if available, otherwise percentage thresholds
    IF v_stddev IS NOT NULL AND v_stddev > 0 AND v_today_hrv IS NOT NULL AND v_baseline_hrv IS NOT NULL THEN
        -- Use standard deviation bands
        CASE
            WHEN v_today_hrv < v_baseline_hrv - (2 * v_stddev) THEN
                v_readiness_impact := 'significant_decrease';
                v_suggested_adjustment := -0.20;  -- Reduce intensity by 20%
            WHEN v_today_hrv < v_baseline_hrv - v_stddev THEN
                v_readiness_impact := 'below_baseline';
                v_suggested_adjustment := -0.10;  -- Reduce intensity by 10%
            WHEN v_today_hrv > v_baseline_hrv + (2 * v_stddev) THEN
                v_readiness_impact := 'significant_increase';
                v_suggested_adjustment := 0.10;   -- Increase intensity by 10%
            WHEN v_today_hrv > v_baseline_hrv + v_stddev THEN
                v_readiness_impact := 'above_baseline';
                v_suggested_adjustment := 0.05;   -- Increase intensity by 5%
            ELSE
                v_readiness_impact := 'normal';
                v_suggested_adjustment := 0.00;   -- No adjustment
        END CASE;
    ELSE
        -- Fallback to percentage-based thresholds
        CASE
            WHEN v_deviation_pct <= -20 THEN
                v_readiness_impact := 'significant_decrease';
                v_suggested_adjustment := -0.20;
            WHEN v_deviation_pct <= -10 THEN
                v_readiness_impact := 'below_baseline';
                v_suggested_adjustment := -0.10;
            WHEN v_deviation_pct >= 20 THEN
                v_readiness_impact := 'significant_increase';
                v_suggested_adjustment := 0.10;
            WHEN v_deviation_pct >= 10 THEN
                v_readiness_impact := 'above_baseline';
                v_suggested_adjustment := 0.05;
            ELSE
                v_readiness_impact := 'normal';
                v_suggested_adjustment := 0.00;
        END CASE;
    END IF;

    -- Handle case where we have no data
    IF v_today_hrv IS NULL THEN
        v_readiness_impact := 'no_data';
        v_suggested_adjustment := 0.00;
    END IF;

    RETURN QUERY SELECT
        v_today_hrv,
        v_baseline_hrv,
        v_deviation_pct,
        v_readiness_impact,
        v_suggested_adjustment;
END;
$$;

COMMENT ON FUNCTION get_hrv_readiness_score IS 'Returns HRV readiness assessment with today''s HRV, baseline, deviation percentage, impact classification, and suggested training intensity adjustment (-0.20 to +0.10)';

-- =====================================================
-- SECTION 6: Function - sync_healthkit_to_readiness
-- =====================================================

-- Drop existing trigger first to avoid conflicts
DROP TRIGGER IF EXISTS sync_healthkit_data ON health_kit_data;
DROP TRIGGER IF EXISTS healthkit_sync_to_readiness_trigger ON health_kit_data;

CREATE OR REPLACE FUNCTION sync_healthkit_to_readiness()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sleep_hours NUMERIC(3,1);
    v_energy_level INTEGER;
    v_hrv_result RECORD;
    v_has_manual_entry BOOLEAN;
BEGIN
    -- Calculate sleep hours from minutes
    v_sleep_hours := CASE
        WHEN NEW.sleep_duration_minutes IS NOT NULL
        THEN ROUND(NEW.sleep_duration_minutes / 60.0, 1)
        ELSE NULL
    END;

    -- Recalculate HRV baseline for this patient
    PERFORM calculate_hrv_baseline(NEW.patient_id);

    -- Get HRV readiness score
    SELECT * INTO v_hrv_result
    FROM get_hrv_readiness_score(NEW.patient_id);

    -- Calculate energy level from HRV readiness impact (1-10 scale)
    v_energy_level := CASE v_hrv_result.readiness_impact
        WHEN 'significant_increase' THEN 9
        WHEN 'above_baseline' THEN 8
        WHEN 'normal' THEN 6
        WHEN 'below_baseline' THEN 4
        WHEN 'significant_decrease' THEN 2
        WHEN 'no_data' THEN 5
        ELSE 5
    END;

    -- Adjust energy level based on deviation percentage for finer granularity
    IF v_hrv_result.deviation_pct IS NOT NULL AND v_hrv_result.readiness_impact != 'no_data' THEN
        IF v_hrv_result.deviation_pct >= 25 THEN
            v_energy_level := 10;
        ELSIF v_hrv_result.deviation_pct <= -25 THEN
            v_energy_level := 1;
        END IF;
    END IF;

    -- Check if there's already a manual entry for this date
    SELECT EXISTS (
        SELECT 1 FROM daily_readiness
        WHERE patient_id = NEW.patient_id
            AND date = NEW.sync_date
            AND (
                soreness_level IS NOT NULL
                OR stress_level IS NOT NULL
                OR (notes IS NOT NULL AND notes != '')
            )
            AND data_source = 'manual'
    ) INTO v_has_manual_entry;

    -- UPSERT into daily_readiness
    IF NOT v_has_manual_entry THEN
        INSERT INTO daily_readiness (
            patient_id,
            date,
            sleep_hours,
            energy_level,
            data_source
        )
        VALUES (
            NEW.patient_id,
            NEW.sync_date,
            v_sleep_hours,
            v_energy_level,
            NEW.source
        )
        ON CONFLICT (patient_id, date) DO UPDATE SET
            sleep_hours = COALESCE(EXCLUDED.sleep_hours, daily_readiness.sleep_hours),
            energy_level = CASE
                -- Only update energy if entry was from HealthKit or not manually entered
                WHEN daily_readiness.data_source != 'manual'
                     OR daily_readiness.data_source IS NULL
                THEN COALESCE(EXCLUDED.energy_level, daily_readiness.energy_level)
                ELSE daily_readiness.energy_level
            END,
            data_source = CASE
                WHEN daily_readiness.data_source = 'manual' THEN daily_readiness.data_source
                ELSE EXCLUDED.data_source
            END,
            updated_at = NOW();
    ELSE
        -- Update only sleep_hours if manual entry exists (preserve manual inputs)
        UPDATE daily_readiness
        SET
            sleep_hours = COALESCE(v_sleep_hours, sleep_hours),
            updated_at = NOW()
        WHERE patient_id = NEW.patient_id
            AND date = NEW.sync_date;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION sync_healthkit_to_readiness IS 'Trigger function that syncs HealthKit data to daily_readiness - calculates sleep_hours, derives energy_level from HRV baseline analysis, respects manual entries';

-- =====================================================
-- SECTION 7: Trigger Definition
-- =====================================================

CREATE TRIGGER sync_healthkit_to_readiness_trigger
    AFTER INSERT OR UPDATE ON health_kit_data
    FOR EACH ROW
    EXECUTE FUNCTION sync_healthkit_to_readiness();

-- =====================================================
-- SECTION 8: Updated Timestamp Trigger for hrv_baselines
-- =====================================================

CREATE OR REPLACE FUNCTION update_hrv_baselines_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_hrv_baselines_timestamp_trigger ON hrv_baselines;
CREATE TRIGGER update_hrv_baselines_timestamp_trigger
    BEFORE UPDATE ON hrv_baselines
    FOR EACH ROW
    EXECUTE FUNCTION update_hrv_baselines_timestamp();

-- =====================================================
-- SECTION 9: Row-Level Security (RLS)
-- =====================================================

-- Enable RLS on hrv_baselines
ALTER TABLE hrv_baselines ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Patients can view own hrv baselines" ON hrv_baselines;
DROP POLICY IF EXISTS "Service role can manage all hrv baselines" ON hrv_baselines;
DROP POLICY IF EXISTS "Therapists can view patient hrv baselines" ON hrv_baselines;

-- Patients can view their own HRV baselines
CREATE POLICY "Patients can view own hrv baselines"
    ON hrv_baselines FOR SELECT
    USING (patient_id = auth.uid());

-- Therapists can view patient HRV baselines
CREATE POLICY "Therapists can view patient hrv baselines"
    ON hrv_baselines FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- Service role has full access
CREATE POLICY "Service role can manage all hrv baselines"
    ON hrv_baselines FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Ensure health_kit_data RLS is enabled (idempotent)
ALTER TABLE health_kit_data ENABLE ROW LEVEL SECURITY;

-- Drop and recreate policies for health_kit_data to ensure consistency
DROP POLICY IF EXISTS "Users can read own patient healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Users can insert own patient healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Users can update own patient healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Users can delete own patient healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Service role full access to healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Patients can view their own healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Patients can insert their own healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Patients can update their own healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Patients can delete their own healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Therapists can view patient healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Service role can manage all healthkit data" ON health_kit_data;

-- Patients can CRUD their own HealthKit data
CREATE POLICY "Patients can view own healthkit data"
    ON health_kit_data FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can insert own healthkit data"
    ON health_kit_data FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update own healthkit data"
    ON health_kit_data FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can delete own healthkit data"
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
CREATE POLICY "Service role full access healthkit data"
    ON health_kit_data FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- SECTION 10: Additional Indexes
-- =====================================================

-- Index for HRV queries (used in baseline calculations)
CREATE INDEX IF NOT EXISTS idx_health_kit_data_hrv_sdnn
    ON health_kit_data(patient_id, sync_date DESC)
    WHERE hrv_sdnn IS NOT NULL;

-- Index for raw_data queries (GIN index for JSONB)
CREATE INDEX IF NOT EXISTS idx_health_kit_data_raw_data
    ON health_kit_data USING GIN (raw_data);

-- =====================================================
-- SECTION 11: Grant Permissions
-- =====================================================

-- Grants for hrv_baselines
GRANT SELECT ON hrv_baselines TO authenticated;
GRANT ALL ON hrv_baselines TO service_role;

-- Grants for health_kit_data (refresh to ensure consistency)
GRANT SELECT, INSERT, UPDATE, DELETE ON health_kit_data TO authenticated;
GRANT ALL ON health_kit_data TO service_role;

-- Grants for functions
GRANT EXECUTE ON FUNCTION calculate_hrv_baseline TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_hrv_baseline TO service_role;

GRANT EXECUTE ON FUNCTION get_hrv_readiness_score TO authenticated;
GRANT EXECUTE ON FUNCTION get_hrv_readiness_score TO service_role;

GRANT EXECUTE ON FUNCTION sync_healthkit_to_readiness TO authenticated;
GRANT EXECUTE ON FUNCTION sync_healthkit_to_readiness TO service_role;

GRANT EXECUTE ON FUNCTION update_hrv_baselines_timestamp TO authenticated;
GRANT EXECUTE ON FUNCTION update_hrv_baselines_timestamp TO service_role;

-- =====================================================
-- SECTION 12: Verification
-- =====================================================

DO $$
DECLARE
    v_healthkit_table_exists BOOLEAN;
    v_hrv_baselines_exists BOOLEAN;
    v_data_source_column_exists BOOLEAN;
    v_calculate_hrv_function_exists BOOLEAN;
    v_readiness_score_function_exists BOOLEAN;
    v_sync_function_exists BOOLEAN;
    v_sync_trigger_exists BOOLEAN;
    v_healthkit_policy_count INTEGER;
    v_baselines_policy_count INTEGER;
    v_healthkit_index_count INTEGER;
    v_baselines_index_count INTEGER;
    v_new_columns_added TEXT[];
BEGIN
    -- Check health_kit_data table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'health_kit_data'
    ) INTO v_healthkit_table_exists;

    -- Check hrv_baselines table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'hrv_baselines'
    ) INTO v_hrv_baselines_exists;

    -- Check data_source column in daily_readiness
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'daily_readiness' AND column_name = 'data_source'
    ) INTO v_data_source_column_exists;

    -- Check functions exist
    SELECT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'calculate_hrv_baseline'
    ) INTO v_calculate_hrv_function_exists;

    SELECT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'get_hrv_readiness_score'
    ) INTO v_readiness_score_function_exists;

    SELECT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'sync_healthkit_to_readiness'
    ) INTO v_sync_function_exists;

    -- Check trigger exists
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'sync_healthkit_to_readiness_trigger'
    ) INTO v_sync_trigger_exists;

    -- Count RLS policies
    SELECT COUNT(*) INTO v_healthkit_policy_count
    FROM pg_policies WHERE tablename = 'health_kit_data';

    SELECT COUNT(*) INTO v_baselines_policy_count
    FROM pg_policies WHERE tablename = 'hrv_baselines';

    -- Count indexes
    SELECT COUNT(*) INTO v_healthkit_index_count
    FROM pg_indexes WHERE tablename = 'health_kit_data';

    SELECT COUNT(*) INTO v_baselines_index_count
    FROM pg_indexes WHERE tablename = 'hrv_baselines';

    -- Build list of new columns
    v_new_columns_added := ARRAY[]::TEXT[];
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'health_kit_data' AND column_name = 'min_heart_rate') THEN
        v_new_columns_added := array_append(v_new_columns_added, 'min_heart_rate');
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'health_kit_data' AND column_name = 'max_heart_rate') THEN
        v_new_columns_added := array_append(v_new_columns_added, 'max_heart_rate');
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'health_kit_data' AND column_name = 'basal_energy_burned') THEN
        v_new_columns_added := array_append(v_new_columns_added, 'basal_energy_burned');
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'health_kit_data' AND column_name = 'step_count') THEN
        v_new_columns_added := array_append(v_new_columns_added, 'step_count');
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'health_kit_data' AND column_name = 'respiratory_rate') THEN
        v_new_columns_added := array_append(v_new_columns_added, 'respiratory_rate');
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'health_kit_data' AND column_name = 'blood_oxygen') THEN
        v_new_columns_added := array_append(v_new_columns_added, 'blood_oxygen');
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'health_kit_data' AND column_name = 'raw_data') THEN
        v_new_columns_added := array_append(v_new_columns_added, 'raw_data');
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'HEALTHKIT DATA STORAGE SCHEMA - SMART RECOVERY SPRINT';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables:';
    RAISE NOTICE '  health_kit_data: %', CASE WHEN v_healthkit_table_exists THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE '  hrv_baselines: %', CASE WHEN v_hrv_baselines_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE '';
    RAISE NOTICE 'New Columns Added to health_kit_data:';
    RAISE NOTICE '  %', array_to_string(v_new_columns_added, ', ');
    RAISE NOTICE '';
    RAISE NOTICE 'daily_readiness.data_source: %', CASE WHEN v_data_source_column_exists THEN 'ADDED' ELSE 'MISSING' END;
    RAISE NOTICE '';
    RAISE NOTICE 'Functions:';
    RAISE NOTICE '  calculate_hrv_baseline(p_patient_id): %', CASE WHEN v_calculate_hrv_function_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE '  get_hrv_readiness_score(p_patient_id): %', CASE WHEN v_readiness_score_function_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE '  sync_healthkit_to_readiness(): %', CASE WHEN v_sync_function_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE '';
    RAISE NOTICE 'Trigger:';
    RAISE NOTICE '  sync_healthkit_to_readiness_trigger: %', CASE WHEN v_sync_trigger_exists THEN 'ACTIVE' ELSE 'MISSING' END;
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies:';
    RAISE NOTICE '  health_kit_data: % policies', v_healthkit_policy_count;
    RAISE NOTICE '  hrv_baselines: % policies', v_baselines_policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes:';
    RAISE NOTICE '  health_kit_data: % indexes', v_healthkit_index_count;
    RAISE NOTICE '  hrv_baselines: % indexes', v_baselines_index_count;
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'get_hrv_readiness_score() Returns:';
    RAISE NOTICE '  - today_hrv: Current day HRV SDNN value';
    RAISE NOTICE '  - baseline_hrv: Rolling baseline HRV';
    RAISE NOTICE '  - deviation_pct: Percentage deviation from baseline';
    RAISE NOTICE '  - readiness_impact: significant_decrease/below_baseline/normal/above_baseline/significant_increase';
    RAISE NOTICE '  - suggested_adjustment: Training intensity adjustment (-0.20 to +0.10)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'MIGRATION COMPLETE: 20260201160003_healthkit_data.sql';
    RAISE NOTICE '============================================================================';
END $$;
