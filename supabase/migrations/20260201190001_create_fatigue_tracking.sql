-- Migration: Create Fatigue Tracking Tables and Functions
-- Sprint: Smart Recovery
-- Created: 2026-02-01
-- Description: Implements accumulated fatigue tracking with rolling metrics,
--              fatigue scoring, and deload recommendations

-- ============================================================================
-- TABLE: fatigue_accumulation
-- ============================================================================
-- Tracks accumulated fatigue metrics over rolling time windows to identify
-- when athletes need recovery interventions or deload periods

CREATE TABLE IF NOT EXISTS fatigue_accumulation (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign key to patient
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Calculation date (one record per patient per day)
    calculation_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Rolling readiness metrics
    avg_readiness_7d NUMERIC(5,2),           -- 7-day average readiness score (0-100)
    avg_readiness_14d NUMERIC(5,2),          -- 14-day average readiness score (0-100)

    -- Training load metrics
    training_load_7d NUMERIC(10,2),          -- Acute load (7-day sum)
    training_load_14d NUMERIC(10,2),         -- Partial chronic reference (14-day sum)
    acute_chronic_ratio NUMERIC(4,2),        -- ACWR: acute/chronic workload ratio

    -- Fatigue indicators
    consecutive_low_readiness INTEGER DEFAULT 0,  -- Days in a row with readiness < 60
    missed_reps_count_7d INTEGER DEFAULT 0,       -- Missed reps in last 7 days
    high_rpe_count_7d INTEGER DEFAULT 0,          -- Sessions with RPE >= 8 in last 7 days
    pain_reports_7d INTEGER DEFAULT 0,            -- Pain reports in last 7 days

    -- Computed fatigue assessment
    fatigue_score NUMERIC(5,2) CHECK (fatigue_score >= 0 AND fatigue_score <= 100),
    fatigue_band TEXT CHECK (fatigue_band IN ('low', 'moderate', 'high', 'critical')),

    -- Deload recommendations
    deload_recommended BOOLEAN DEFAULT FALSE,
    deload_urgency TEXT DEFAULT 'none' CHECK (deload_urgency IN ('none', 'suggested', 'recommended', 'required')),

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one record per patient per day
    CONSTRAINT fatigue_accumulation_patient_date_unique UNIQUE (patient_id, calculation_date)
);

-- Add table comment
COMMENT ON TABLE fatigue_accumulation IS 'Tracks accumulated fatigue metrics and deload recommendations for Smart Recovery';

-- Column comments
COMMENT ON COLUMN fatigue_accumulation.avg_readiness_7d IS '7-day rolling average of daily readiness scores';
COMMENT ON COLUMN fatigue_accumulation.avg_readiness_14d IS '14-day rolling average of daily readiness scores';
COMMENT ON COLUMN fatigue_accumulation.training_load_7d IS 'Acute training load (sum of session loads over 7 days)';
COMMENT ON COLUMN fatigue_accumulation.training_load_14d IS '14-day training load for chronic reference calculation';
COMMENT ON COLUMN fatigue_accumulation.acute_chronic_ratio IS 'ACWR - ratio of acute (7d) to chronic (28d) workload';
COMMENT ON COLUMN fatigue_accumulation.consecutive_low_readiness IS 'Number of consecutive days with readiness below threshold';
COMMENT ON COLUMN fatigue_accumulation.fatigue_score IS 'Computed fatigue score from 0 (fresh) to 100 (exhausted)';
COMMENT ON COLUMN fatigue_accumulation.fatigue_band IS 'Categorical fatigue level: low (<30), moderate (30-50), high (50-70), critical (>70)';
COMMENT ON COLUMN fatigue_accumulation.deload_urgency IS 'How urgently a deload is needed based on accumulated fatigue';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index for patient lookups (most common query pattern)
CREATE INDEX IF NOT EXISTS idx_fatigue_accumulation_patient_id
    ON fatigue_accumulation(patient_id);

-- Index for date-based queries and time-series analysis
CREATE INDEX IF NOT EXISTS idx_fatigue_accumulation_calculation_date
    ON fatigue_accumulation(calculation_date DESC);

-- Composite index for patient + date range queries
CREATE INDEX IF NOT EXISTS idx_fatigue_accumulation_patient_date
    ON fatigue_accumulation(patient_id, calculation_date DESC);

-- Index for finding patients needing deload
CREATE INDEX IF NOT EXISTS idx_fatigue_accumulation_deload_recommended
    ON fatigue_accumulation(deload_recommended)
    WHERE deload_recommended = TRUE;

-- Index for fatigue band filtering
CREATE INDEX IF NOT EXISTS idx_fatigue_accumulation_fatigue_band
    ON fatigue_accumulation(fatigue_band);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS
ALTER TABLE fatigue_accumulation ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can read their own fatigue data
-- (patients can see their own data via patient_id match)
CREATE POLICY fatigue_accumulation_select_own ON fatigue_accumulation
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Service role can do everything (for background calculations)
CREATE POLICY fatigue_accumulation_service_all ON fatigue_accumulation
    FOR ALL
    TO service_role
    USING (TRUE)
    WITH CHECK (TRUE);

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

-- Create trigger to auto-update updated_at timestamp
CREATE TRIGGER set_fatigue_accumulation_updated_at
    BEFORE UPDATE ON fatigue_accumulation
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FUNCTION: calculate_accumulated_fatigue
-- ============================================================================
-- Calculates fatigue score and metrics for a patient based on:
-- - Rolling readiness averages
-- - Training load and ACWR
-- - Consecutive low readiness days
-- - Pain and high RPE indicators

-- Drop existing function if it exists (to allow return type change)
DROP FUNCTION IF EXISTS calculate_accumulated_fatigue(UUID);

CREATE OR REPLACE FUNCTION calculate_accumulated_fatigue(p_patient_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_record_id UUID;
    v_avg_readiness_7d NUMERIC(5,2);
    v_avg_readiness_14d NUMERIC(5,2);
    v_training_load_7d NUMERIC(10,2);
    v_training_load_14d NUMERIC(10,2);
    v_training_load_28d NUMERIC(10,2);
    v_acwr NUMERIC(4,2);
    v_consecutive_low INTEGER := 0;
    v_missed_reps INTEGER := 0;
    v_high_rpe_count INTEGER := 0;
    v_pain_reports INTEGER := 0;
    v_fatigue_score NUMERIC(5,2);
    v_fatigue_band TEXT;
    v_deload_recommended BOOLEAN := FALSE;
    v_deload_urgency TEXT := 'none';
    v_readiness_record RECORD;
    v_low_streak INTEGER := 0;
BEGIN
    -- ========================================================================
    -- Calculate 7-day readiness average
    -- ========================================================================
    SELECT AVG(overall_score)
    INTO v_avg_readiness_7d
    FROM daily_readiness
    WHERE patient_id = p_patient_id
      AND assessment_date >= CURRENT_DATE - INTERVAL '7 days'
      AND assessment_date <= CURRENT_DATE;

    -- ========================================================================
    -- Calculate 14-day readiness average
    -- ========================================================================
    SELECT AVG(overall_score)
    INTO v_avg_readiness_14d
    FROM daily_readiness
    WHERE patient_id = p_patient_id
      AND assessment_date >= CURRENT_DATE - INTERVAL '14 days'
      AND assessment_date <= CURRENT_DATE;

    -- ========================================================================
    -- Calculate consecutive low readiness days
    -- ========================================================================
    FOR v_readiness_record IN
        SELECT overall_score, assessment_date
        FROM daily_readiness
        WHERE patient_id = p_patient_id
          AND assessment_date >= CURRENT_DATE - INTERVAL '14 days'
        ORDER BY assessment_date DESC
    LOOP
        IF v_readiness_record.overall_score < 60 THEN
            v_low_streak := v_low_streak + 1;
        ELSE
            EXIT; -- Break on first non-low day
        END IF;
    END LOOP;
    v_consecutive_low := v_low_streak;

    -- ========================================================================
    -- Calculate training loads from manual sessions
    -- ========================================================================
    -- 7-day acute load (using total_volume from manual_sessions)
    SELECT COALESCE(SUM(total_volume), 0)
    INTO v_training_load_7d
    FROM manual_sessions
    WHERE patient_id = p_patient_id
      AND completed_at >= CURRENT_DATE - INTERVAL '7 days'
      AND completed_at IS NOT NULL;

    -- 14-day load (for reference)
    SELECT COALESCE(SUM(total_volume), 0)
    INTO v_training_load_14d
    FROM manual_sessions
    WHERE patient_id = p_patient_id
      AND completed_at >= CURRENT_DATE - INTERVAL '14 days'
      AND completed_at IS NOT NULL;

    -- 28-day chronic load (for ACWR calculation)
    SELECT COALESCE(SUM(total_volume), 0)
    INTO v_training_load_28d
    FROM manual_sessions
    WHERE patient_id = p_patient_id
      AND completed_at >= CURRENT_DATE - INTERVAL '28 days'
      AND completed_at IS NOT NULL;

    -- ========================================================================
    -- Calculate ACWR (Acute:Chronic Workload Ratio)
    -- ========================================================================
    -- Chronic load = 28-day average weekly load
    IF v_training_load_28d > 0 THEN
        v_acwr := v_training_load_7d / (v_training_load_28d / 4.0);
    ELSE
        v_acwr := 1.0; -- Default to 1.0 if no chronic data
    END IF;

    -- Cap ACWR for display
    IF v_acwr > 3.0 THEN
        v_acwr := 3.0;
    END IF;

    -- ========================================================================
    -- Count missed reps in last 7 days (estimate from exercise_logs)
    -- ========================================================================
    -- Note: Using 0 as default since we don't track prescribed vs completed in exercise_logs
    v_missed_reps := 0;

    -- ========================================================================
    -- Count high RPE sessions (RPE >= 8) in last 7 days
    -- ========================================================================
    SELECT COUNT(*)
    INTO v_high_rpe_count
    FROM manual_sessions
    WHERE patient_id = p_patient_id
      AND completed_at >= CURRENT_DATE - INTERVAL '7 days'
      AND completed_at IS NOT NULL
      AND avg_rpe >= 8;

    -- ========================================================================
    -- Count pain reports in last 7 days
    -- ========================================================================
    SELECT COUNT(*)
    INTO v_pain_reports
    FROM daily_readiness
    WHERE patient_id = p_patient_id
      AND assessment_date >= CURRENT_DATE - INTERVAL '7 days'
      AND (pain_level >= 5 OR soreness_level >= 7);

    -- ========================================================================
    -- Calculate fatigue score (0-100)
    -- ========================================================================
    -- Weighted formula:
    -- - Low readiness contributes to fatigue (40% weight)
    -- - High ACWR (>1.3) contributes to fatigue (25% weight)
    -- - Consecutive low days (15% weight)
    -- - Pain reports (10% weight)
    -- - High RPE sessions (10% weight)

    v_fatigue_score := 0;

    -- Readiness component (inverted - low readiness = high fatigue)
    -- Scale: readiness 100 = 0 fatigue, readiness 0 = 40 fatigue points
    IF v_avg_readiness_7d IS NOT NULL THEN
        v_fatigue_score := v_fatigue_score + ((100 - v_avg_readiness_7d) * 0.4);
    END IF;

    -- ACWR component
    -- Optimal range is 0.8-1.3, outside this adds fatigue
    IF v_acwr > 1.3 THEN
        -- High ACWR: each 0.1 above 1.3 adds fatigue
        v_fatigue_score := v_fatigue_score + LEAST(25, (v_acwr - 1.3) * 25);
    ELSIF v_acwr < 0.8 AND v_acwr > 0 THEN
        -- Very low ACWR might indicate detraining/recovery
        v_fatigue_score := v_fatigue_score + 5;
    END IF;

    -- Consecutive low readiness days component
    -- Each consecutive day adds 3 points, max 15
    v_fatigue_score := v_fatigue_score + LEAST(15, v_consecutive_low * 3);

    -- Pain reports component
    -- Each pain report adds 2.5 points, max 10
    v_fatigue_score := v_fatigue_score + LEAST(10, v_pain_reports * 2.5);

    -- High RPE sessions component
    -- Each high RPE session adds 2 points, max 10
    v_fatigue_score := v_fatigue_score + LEAST(10, v_high_rpe_count * 2);

    -- Ensure score is within bounds
    v_fatigue_score := GREATEST(0, LEAST(100, v_fatigue_score));

    -- ========================================================================
    -- Determine fatigue band
    -- ========================================================================
    v_fatigue_band := CASE
        WHEN v_fatigue_score < 30 THEN 'low'
        WHEN v_fatigue_score < 50 THEN 'moderate'
        WHEN v_fatigue_score < 70 THEN 'high'
        ELSE 'critical'
    END;

    -- ========================================================================
    -- Determine deload recommendation
    -- ========================================================================
    IF v_fatigue_score >= 70 OR v_consecutive_low >= 5 OR v_acwr > 1.8 THEN
        v_deload_recommended := TRUE;
        v_deload_urgency := 'required';
    ELSIF v_fatigue_score >= 55 OR v_consecutive_low >= 3 OR v_acwr > 1.5 THEN
        v_deload_recommended := TRUE;
        v_deload_urgency := 'recommended';
    ELSIF v_fatigue_score >= 40 OR v_consecutive_low >= 2 OR v_acwr > 1.3 THEN
        v_deload_recommended := FALSE;
        v_deload_urgency := 'suggested';
    ELSE
        v_deload_recommended := FALSE;
        v_deload_urgency := 'none';
    END IF;

    -- ========================================================================
    -- Upsert the fatigue accumulation record
    -- ========================================================================
    INSERT INTO fatigue_accumulation (
        patient_id,
        calculation_date,
        avg_readiness_7d,
        avg_readiness_14d,
        training_load_7d,
        training_load_14d,
        acute_chronic_ratio,
        consecutive_low_readiness,
        missed_reps_count_7d,
        high_rpe_count_7d,
        pain_reports_7d,
        fatigue_score,
        fatigue_band,
        deload_recommended,
        deload_urgency
    )
    VALUES (
        p_patient_id,
        CURRENT_DATE,
        v_avg_readiness_7d,
        v_avg_readiness_14d,
        v_training_load_7d,
        v_training_load_14d,
        v_acwr,
        v_consecutive_low,
        v_missed_reps,
        v_high_rpe_count,
        v_pain_reports,
        v_fatigue_score,
        v_fatigue_band,
        v_deload_recommended,
        v_deload_urgency
    )
    ON CONFLICT (patient_id, calculation_date)
    DO UPDATE SET
        avg_readiness_7d = EXCLUDED.avg_readiness_7d,
        avg_readiness_14d = EXCLUDED.avg_readiness_14d,
        training_load_7d = EXCLUDED.training_load_7d,
        training_load_14d = EXCLUDED.training_load_14d,
        acute_chronic_ratio = EXCLUDED.acute_chronic_ratio,
        consecutive_low_readiness = EXCLUDED.consecutive_low_readiness,
        missed_reps_count_7d = EXCLUDED.missed_reps_count_7d,
        high_rpe_count_7d = EXCLUDED.high_rpe_count_7d,
        pain_reports_7d = EXCLUDED.pain_reports_7d,
        fatigue_score = EXCLUDED.fatigue_score,
        fatigue_band = EXCLUDED.fatigue_band,
        deload_recommended = EXCLUDED.deload_recommended,
        deload_urgency = EXCLUDED.deload_urgency,
        updated_at = NOW()
    RETURNING id INTO v_record_id;

    RETURN v_record_id;
END;
$$;

-- Function comment
COMMENT ON FUNCTION calculate_accumulated_fatigue(UUID) IS
'Calculates accumulated fatigue metrics for a patient including readiness averages, training load, ACWR, and determines deload recommendations';

-- ============================================================================
-- VERIFICATION BLOCK
-- ============================================================================

DO $$
DECLARE
    v_table_exists BOOLEAN;
    v_function_exists BOOLEAN;
    v_index_count INTEGER;
    v_policy_count INTEGER;
BEGIN
    -- Verify table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'fatigue_accumulation'
    ) INTO v_table_exists;

    IF NOT v_table_exists THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: fatigue_accumulation table was not created';
    END IF;

    -- Verify function exists
    SELECT EXISTS (
        SELECT 1 FROM pg_proc
        WHERE proname = 'calculate_accumulated_fatigue'
    ) INTO v_function_exists;

    IF NOT v_function_exists THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: calculate_accumulated_fatigue function was not created';
    END IF;

    -- Verify indexes were created
    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE tablename = 'fatigue_accumulation'
    AND indexname LIKE 'idx_fatigue_accumulation%';

    IF v_index_count < 4 THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: Expected at least 4 indexes, found %', v_index_count;
    END IF;

    -- Verify RLS policies
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE tablename = 'fatigue_accumulation';

    IF v_policy_count < 2 THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: Expected at least 2 RLS policies, found %', v_policy_count;
    END IF;

    -- Verify required columns exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'fatigue_accumulation'
        AND column_name = 'fatigue_score'
    ) THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: fatigue_score column not found';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'fatigue_accumulation'
        AND column_name = 'acute_chronic_ratio'
    ) THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: acute_chronic_ratio column not found';
    END IF;

    RAISE NOTICE '✓ VERIFICATION PASSED: fatigue_accumulation table created successfully';
    RAISE NOTICE '✓ VERIFICATION PASSED: calculate_accumulated_fatigue function created';
    RAISE NOTICE '✓ VERIFICATION PASSED: % indexes created', v_index_count;
    RAISE NOTICE '✓ VERIFICATION PASSED: % RLS policies created', v_policy_count;
    RAISE NOTICE '✓ Migration 20260201190001_create_fatigue_tracking.sql completed successfully';
END;
$$;
