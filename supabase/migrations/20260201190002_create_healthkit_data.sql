-- Migration: Create HealthKit Data Storage
-- Sprint: Smart Recovery
-- Created: 2026-02-01
-- Description: Tables for storing HealthKit health metrics synced from iOS devices

-- ============================================================================
-- DROP EXISTING OBJECTS (for clean recreation)
-- ============================================================================
DROP VIEW IF EXISTS vw_healthkit_with_deviation;
DROP TRIGGER IF EXISTS trg_healthkit_update_readiness ON health_kit_data;
DROP FUNCTION IF EXISTS update_daily_readiness_from_healthkit();
DROP TABLE IF EXISTS hrv_baselines CASCADE;
DROP TABLE IF EXISTS health_kit_data CASCADE;

-- ============================================================================
-- HEALTH_KIT_DATA TABLE
-- ============================================================================
-- Stores daily health metrics synced from Apple HealthKit

CREATE TABLE health_kit_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    sync_date DATE NOT NULL,

    -- HRV Metrics
    hrv_sdnn NUMERIC(6,2),           -- Standard deviation of NN intervals (ms)
    hrv_rmssd NUMERIC(6,2),          -- Root mean square of successive differences (ms)
    hrv_sample_count INTEGER,         -- Number of HRV samples collected

    -- Sleep Metrics (all in minutes)
    sleep_duration_minutes INTEGER,   -- Total sleep time
    sleep_in_bed_minutes INTEGER,     -- Total time in bed
    sleep_deep_minutes INTEGER,       -- Deep sleep stage
    sleep_rem_minutes INTEGER,        -- REM sleep stage
    sleep_core_minutes INTEGER,       -- Core/light sleep stage
    sleep_awake_minutes INTEGER,      -- Awake time during sleep period

    -- Heart Rate Metrics
    resting_heart_rate NUMERIC(5,2),  -- Resting heart rate (bpm)
    avg_heart_rate NUMERIC(5,2),      -- Average heart rate for the day (bpm)

    -- Activity Metrics
    active_energy_burned NUMERIC(8,2), -- Active calories burned (kcal)
    exercise_minutes INTEGER,          -- Exercise minutes
    stand_hours INTEGER,               -- Stand hours (0-24)

    -- Metadata
    synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source TEXT DEFAULT 'apple_healthkit',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one record per patient per day
    CONSTRAINT uq_healthkit_patient_date UNIQUE (patient_id, sync_date)
);

-- Add table comment
COMMENT ON TABLE health_kit_data IS 'Daily health metrics synced from Apple HealthKit';

-- ============================================================================
-- HRV_BASELINES TABLE
-- ============================================================================
-- Stores personal HRV baseline for each patient (rolling average)

CREATE TABLE hrv_baselines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Baseline metrics (typically 7-day or 30-day rolling average)
    baseline_sdnn NUMERIC(6,2),
    baseline_rmssd NUMERIC(6,2),
    sample_count INTEGER DEFAULT 0,

    -- Calculation window
    calculation_window_days INTEGER DEFAULT 7,
    last_calculated_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- One baseline record per patient
    CONSTRAINT uq_hrv_baseline_patient UNIQUE (patient_id)
);

-- Add table comment
COMMENT ON TABLE hrv_baselines IS 'Personal HRV baseline tracking for recovery analysis';

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE health_kit_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrv_baselines ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Patients can view own healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Patients can insert own healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Patients can update own healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Therapists can view patient healthkit data" ON health_kit_data;
DROP POLICY IF EXISTS "Patients can view own hrv baseline" ON hrv_baselines;
DROP POLICY IF EXISTS "Patients can insert own hrv baseline" ON hrv_baselines;
DROP POLICY IF EXISTS "Patients can update own hrv baseline" ON hrv_baselines;
DROP POLICY IF EXISTS "Therapists can view patient hrv baseline" ON hrv_baselines;

-- Health Kit Data policies
CREATE POLICY "Patients can view own healthkit data"
    ON health_kit_data FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can insert own healthkit data"
    ON health_kit_data FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update own healthkit data"
    ON health_kit_data FOR UPDATE
    USING (patient_id = auth.uid());

CREATE POLICY "Therapists can view patient healthkit data"
    ON health_kit_data FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = health_kit_data.patient_id
            AND p.therapist_id = auth.uid()
        )
    );

-- HRV Baselines policies
CREATE POLICY "Patients can view own hrv baseline"
    ON hrv_baselines FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can manage own hrv baseline"
    ON hrv_baselines FOR ALL
    USING (patient_id = auth.uid());

CREATE POLICY "Therapists can view patient hrv baseline"
    ON hrv_baselines FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = hrv_baselines.patient_id
            AND p.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Health Kit Data indexes
CREATE INDEX IF NOT EXISTS idx_healthkit_patient_id ON health_kit_data(patient_id);
CREATE INDEX IF NOT EXISTS idx_healthkit_sync_date ON health_kit_data(sync_date);
CREATE INDEX IF NOT EXISTS idx_healthkit_patient_sync_date ON health_kit_data(patient_id, sync_date DESC);

-- HRV Baselines indexes
CREATE INDEX IF NOT EXISTS idx_hrv_baselines_patient_id ON hrv_baselines(patient_id);

-- ============================================================================
-- TRIGGER: Auto-update daily_readiness when HealthKit data syncs
-- ============================================================================

CREATE OR REPLACE FUNCTION update_daily_readiness_from_healthkit()
RETURNS TRIGGER AS $$
DECLARE
    v_baseline_rmssd NUMERIC(6,2);
    v_hrv_deviation NUMERIC(5,2);
    v_sleep_score INTEGER;
    v_readiness_score INTEGER;
BEGIN
    -- Get patient's HRV baseline
    SELECT baseline_rmssd INTO v_baseline_rmssd
    FROM hrv_baselines
    WHERE patient_id = NEW.patient_id;

    -- Calculate HRV deviation from baseline (percentage)
    IF v_baseline_rmssd IS NOT NULL AND v_baseline_rmssd > 0 AND NEW.hrv_rmssd IS NOT NULL THEN
        v_hrv_deviation := ((NEW.hrv_rmssd - v_baseline_rmssd) / v_baseline_rmssd) * 100;
    ELSE
        v_hrv_deviation := 0;
    END IF;

    -- Calculate sleep score (0-100 based on duration and quality)
    IF NEW.sleep_duration_minutes IS NOT NULL THEN
        -- Optimal sleep is 420-540 minutes (7-9 hours)
        v_sleep_score := LEAST(100, GREATEST(0,
            CASE
                WHEN NEW.sleep_duration_minutes >= 420 AND NEW.sleep_duration_minutes <= 540 THEN 100
                WHEN NEW.sleep_duration_minutes < 420 THEN (NEW.sleep_duration_minutes::NUMERIC / 420) * 100
                ELSE 100 - ((NEW.sleep_duration_minutes - 540)::NUMERIC / 60) * 10
            END
        ));
    ELSE
        v_sleep_score := NULL;
    END IF;

    -- Calculate overall readiness score
    IF NEW.hrv_rmssd IS NOT NULL OR v_sleep_score IS NOT NULL THEN
        v_readiness_score := COALESCE(
            (
                COALESCE(50 + (v_hrv_deviation * 0.5), 50) * 0.6 +
                COALESCE(v_sleep_score, 50) * 0.4
            )::INTEGER,
            50
        );
        v_readiness_score := LEAST(100, GREATEST(0, v_readiness_score));
    ELSE
        v_readiness_score := NULL;
    END IF;

    -- Update or insert daily_readiness record
    INSERT INTO daily_readiness (
        patient_id,
        readiness_date,
        hrv_score,
        sleep_score,
        readiness_score,
        data_source,
        updated_at
    )
    VALUES (
        NEW.patient_id,
        NEW.sync_date,
        NEW.hrv_rmssd,
        v_sleep_score,
        v_readiness_score,
        'healthkit',
        NOW()
    )
    ON CONFLICT (patient_id, readiness_date)
    DO UPDATE SET
        hrv_score = EXCLUDED.hrv_score,
        sleep_score = EXCLUDED.sleep_score,
        readiness_score = EXCLUDED.readiness_score,
        data_source = EXCLUDED.data_source,
        updated_at = NOW();

    -- Update HRV baseline (rolling 7-day average)
    INSERT INTO hrv_baselines (
        patient_id,
        baseline_rmssd,
        baseline_sdnn,
        sample_count,
        last_calculated_at
    )
    SELECT
        NEW.patient_id,
        AVG(hrv_rmssd),
        AVG(hrv_sdnn),
        COUNT(*),
        NOW()
    FROM health_kit_data
    WHERE patient_id = NEW.patient_id
    AND sync_date >= NEW.sync_date - INTERVAL '7 days'
    AND hrv_rmssd IS NOT NULL
    ON CONFLICT (patient_id)
    DO UPDATE SET
        baseline_rmssd = EXCLUDED.baseline_rmssd,
        baseline_sdnn = EXCLUDED.baseline_sdnn,
        sample_count = EXCLUDED.sample_count,
        last_calculated_at = NOW(),
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS trg_healthkit_update_readiness ON health_kit_data;
CREATE TRIGGER trg_healthkit_update_readiness
    AFTER INSERT OR UPDATE ON health_kit_data
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_readiness_from_healthkit();

-- ============================================================================
-- VIEW: HealthKit data with HRV deviation from baseline
-- ============================================================================

CREATE OR REPLACE VIEW vw_healthkit_with_deviation AS
SELECT
    hkd.id,
    hkd.patient_id,
    hkd.sync_date,

    -- HRV metrics
    hkd.hrv_sdnn,
    hkd.hrv_rmssd,
    hkd.hrv_sample_count,

    -- Baseline comparison
    hb.baseline_rmssd,
    hb.baseline_sdnn,

    -- HRV deviation from baseline (percentage)
    CASE
        WHEN hb.baseline_rmssd IS NOT NULL AND hb.baseline_rmssd > 0 THEN
            ROUND(((hkd.hrv_rmssd - hb.baseline_rmssd) / hb.baseline_rmssd) * 100, 2)
        ELSE NULL
    END AS hrv_rmssd_deviation_pct,

    CASE
        WHEN hb.baseline_sdnn IS NOT NULL AND hb.baseline_sdnn > 0 THEN
            ROUND(((hkd.hrv_sdnn - hb.baseline_sdnn) / hb.baseline_sdnn) * 100, 2)
        ELSE NULL
    END AS hrv_sdnn_deviation_pct,

    -- Recovery status based on HRV deviation
    CASE
        WHEN hb.baseline_rmssd IS NULL OR hb.baseline_rmssd = 0 THEN 'insufficient_data'
        WHEN ((hkd.hrv_rmssd - hb.baseline_rmssd) / hb.baseline_rmssd) * 100 >= 10 THEN 'above_baseline'
        WHEN ((hkd.hrv_rmssd - hb.baseline_rmssd) / hb.baseline_rmssd) * 100 <= -10 THEN 'below_baseline'
        ELSE 'within_baseline'
    END AS recovery_status,

    -- Sleep metrics
    hkd.sleep_duration_minutes,
    hkd.sleep_in_bed_minutes,
    hkd.sleep_deep_minutes,
    hkd.sleep_rem_minutes,
    hkd.sleep_core_minutes,
    hkd.sleep_awake_minutes,

    -- Sleep efficiency
    CASE
        WHEN hkd.sleep_in_bed_minutes > 0 THEN
            ROUND((hkd.sleep_duration_minutes::NUMERIC / hkd.sleep_in_bed_minutes) * 100, 1)
        ELSE NULL
    END AS sleep_efficiency_pct,

    -- Heart rate metrics
    hkd.resting_heart_rate,
    hkd.avg_heart_rate,

    -- Activity metrics
    hkd.active_energy_burned,
    hkd.exercise_minutes,
    hkd.stand_hours,

    -- Metadata
    hkd.synced_at,
    hkd.source,
    hkd.created_at,
    hkd.updated_at

FROM health_kit_data hkd
LEFT JOIN hrv_baselines hb ON hkd.patient_id = hb.patient_id;

-- Add view comment
COMMENT ON VIEW vw_healthkit_with_deviation IS 'HealthKit data with HRV deviation from personal baseline';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_table_count INTEGER := 0;
    v_index_count INTEGER := 0;
    v_policy_count INTEGER := 0;
    v_trigger_count INTEGER := 0;
    v_view_count INTEGER := 0;
BEGIN
    -- Verify tables
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN ('health_kit_data', 'hrv_baselines');

    IF v_table_count < 2 THEN
        RAISE EXCEPTION 'Missing tables. Expected 2, found %', v_table_count;
    END IF;

    -- Verify indexes
    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND indexname IN (
        'idx_healthkit_patient_id',
        'idx_healthkit_sync_date',
        'idx_healthkit_patient_sync_date',
        'idx_hrv_baselines_patient_id'
    );

    IF v_index_count < 4 THEN
        RAISE EXCEPTION 'Missing indexes. Expected 4, found %', v_index_count;
    END IF;

    -- Verify RLS is enabled
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename = 'health_kit_data'
        AND rowsecurity = true
    ) THEN
        RAISE EXCEPTION 'RLS not enabled on health_kit_data';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename = 'hrv_baselines'
        AND rowsecurity = true
    ) THEN
        RAISE EXCEPTION 'RLS not enabled on hrv_baselines';
    END IF;

    -- Verify policies
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename IN ('health_kit_data', 'hrv_baselines');

    IF v_policy_count < 6 THEN
        RAISE EXCEPTION 'Missing RLS policies. Expected at least 6, found %', v_policy_count;
    END IF;

    -- Verify trigger
    SELECT COUNT(*) INTO v_trigger_count
    FROM information_schema.triggers
    WHERE trigger_schema = 'public'
    AND trigger_name = 'trg_healthkit_update_readiness';

    IF v_trigger_count < 1 THEN
        RAISE EXCEPTION 'Missing trigger trg_healthkit_update_readiness';
    END IF;

    -- Verify view
    SELECT COUNT(*) INTO v_view_count
    FROM information_schema.views
    WHERE table_schema = 'public'
    AND table_name = 'vw_healthkit_with_deviation';

    IF v_view_count < 1 THEN
        RAISE EXCEPTION 'Missing view vw_healthkit_with_deviation';
    END IF;

    RAISE NOTICE '✓ Migration 20260201190002_create_healthkit_data verified successfully';
    RAISE NOTICE '  - Tables: %', v_table_count;
    RAISE NOTICE '  - Indexes: %', v_index_count;
    RAISE NOTICE '  - RLS Policies: %', v_policy_count;
    RAISE NOTICE '  - Triggers: %', v_trigger_count;
    RAISE NOTICE '  - Views: %', v_view_count;
END $$;
