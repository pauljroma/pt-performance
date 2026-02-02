-- ============================================================================
-- FATIGUE ACCUMULATION MIGRATION - SMART RECOVERY SPRINT
-- ============================================================================
-- Agent: 1
-- Date: 2026-02-01
-- Migration: 20260201160001_fatigue_accumulation.sql
--
-- Creates the fatigue tracking database schema with:
--   1. fatigue_accumulation table with rolling metrics and computed scores
--   2. RLS policies for patient data access
--   3. calculate_accumulated_fatigue() function for fatigue calculation
--   4. Performance indexes
-- ============================================================================

-- Drop existing objects for idempotency
DROP FUNCTION IF EXISTS calculate_accumulated_fatigue(UUID) CASCADE;
DROP TABLE IF EXISTS fatigue_accumulation CASCADE;

-- ============================================================================
-- 1. CREATE FATIGUE ACCUMULATION TABLE
-- ============================================================================

CREATE TABLE fatigue_accumulation (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Patient relationship
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    calculation_date DATE NOT NULL,

    -- Rolling window metrics
    avg_readiness_7d NUMERIC(5,2),           -- 7-day average readiness score (0-100)
    avg_readiness_14d NUMERIC(5,2),          -- 14-day average readiness score (0-100)
    training_load_7d NUMERIC(12,2),          -- Training volume over last 7 days
    training_load_14d NUMERIC(12,2),         -- Training volume over last 14 days
    acute_chronic_ratio NUMERIC(5,3),        -- ACWR = 7-day avg / 28-day avg

    -- Fatigue indicators
    consecutive_low_readiness INTEGER NOT NULL DEFAULT 0,  -- Days with readiness < 60
    missed_reps_count_7d INTEGER NOT NULL DEFAULT 0,       -- Missed reps in 7 days
    high_rpe_count_7d INTEGER NOT NULL DEFAULT 0,          -- High RPE sessions in 7 days
    pain_reports_7d INTEGER NOT NULL DEFAULT 0,            -- Pain reports in 7 days

    -- Computed fatigue metrics
    fatigue_score NUMERIC(4,1) CHECK (fatigue_score >= 0 AND fatigue_score <= 100),
    fatigue_band TEXT NOT NULL CHECK (fatigue_band IN ('low', 'moderate', 'high', 'critical')),

    -- Deload recommendations
    deload_recommended BOOLEAN NOT NULL DEFAULT false,
    deload_urgency TEXT NOT NULL DEFAULT 'none' CHECK (deload_urgency IN ('none', 'suggested', 'recommended', 'required')),

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Ensure one entry per patient per day
    UNIQUE(patient_id, calculation_date)
);

-- ============================================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Primary lookup: patient + date (most common query pattern)
CREATE INDEX idx_fatigue_accum_patient_date
ON fatigue_accumulation(patient_id, calculation_date DESC);

-- Date-based queries for dashboards and reports
CREATE INDEX idx_fatigue_accum_date
ON fatigue_accumulation(calculation_date DESC);

-- Filter by fatigue severity
CREATE INDEX idx_fatigue_accum_band
ON fatigue_accumulation(fatigue_band);

-- Deload alerts (partial index for efficiency)
CREATE INDEX idx_fatigue_accum_deload_alert
ON fatigue_accumulation(deload_recommended, patient_id)
WHERE deload_recommended = true;

-- Fatigue score sorting
CREATE INDEX idx_fatigue_accum_score
ON fatigue_accumulation(patient_id, fatigue_score DESC);

-- Critical fatigue band (partial index for alerting)
CREATE INDEX idx_fatigue_accum_critical
ON fatigue_accumulation(patient_id, calculation_date)
WHERE fatigue_band = 'critical';

-- ============================================================================
-- 3. AUTO-UPDATE TIMESTAMP TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_fatigue_accum_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_fatigue_accum_updated
    BEFORE UPDATE ON fatigue_accumulation
    FOR EACH ROW
    EXECUTE FUNCTION update_fatigue_accum_timestamp();

-- ============================================================================
-- 4. CALCULATE ACCUMULATED FATIGUE FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_accumulated_fatigue(p_patient_id UUID)
RETURNS fatigue_accumulation
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    -- Rolling readiness metrics
    v_avg_readiness_7d NUMERIC;
    v_avg_readiness_14d NUMERIC;

    -- Training load metrics
    v_training_load_7d NUMERIC;
    v_training_load_14d NUMERIC;
    v_training_load_28d NUMERIC;
    v_acute_chronic_ratio NUMERIC;

    -- Fatigue indicators
    v_consecutive_low_readiness INTEGER := 0;
    v_missed_reps_count_7d INTEGER := 0;
    v_high_rpe_count_7d INTEGER := 0;
    v_pain_reports_7d INTEGER := 0;

    -- Computed values
    v_fatigue_score NUMERIC;
    v_fatigue_band TEXT;
    v_deload_recommended BOOLEAN;
    v_deload_urgency TEXT;

    -- ACWR factor for scoring
    v_acwr_factor NUMERIC;

    -- Result record
    v_result fatigue_accumulation;

    -- For consecutive low readiness calculation
    v_readiness_record RECORD;
    v_streak_broken BOOLEAN := false;
BEGIN
    -- ========================================================================
    -- STEP 1: Calculate 7-day and 14-day average readiness from daily_readiness
    -- ========================================================================
    SELECT AVG(readiness_score)
    INTO v_avg_readiness_7d
    FROM daily_readiness
    WHERE patient_id = p_patient_id
      AND date >= CURRENT_DATE - INTERVAL '7 days'
      AND date <= CURRENT_DATE;

    SELECT AVG(readiness_score)
    INTO v_avg_readiness_14d
    FROM daily_readiness
    WHERE patient_id = p_patient_id
      AND date >= CURRENT_DATE - INTERVAL '14 days'
      AND date <= CURRENT_DATE;

    -- ========================================================================
    -- STEP 2: Calculate training load from exercise_logs joined with patient_sessions
    -- Training load = SUM(sets * reps * load)
    -- ========================================================================

    -- 7-day training load
    SELECT COALESCE(SUM(
        COALESCE(el.actual_sets, 1) *
        COALESCE(el.actual_reps, 1) *
        COALESCE(el.actual_load, 0)
    ), 0)
    INTO v_training_load_7d
    FROM exercise_logs el
    WHERE el.patient_id = p_patient_id
      AND el.logged_at >= CURRENT_DATE - INTERVAL '7 days'
      AND el.logged_at <= CURRENT_DATE + INTERVAL '1 day';

    -- 14-day training load
    SELECT COALESCE(SUM(
        COALESCE(el.actual_sets, 1) *
        COALESCE(el.actual_reps, 1) *
        COALESCE(el.actual_load, 0)
    ), 0)
    INTO v_training_load_14d
    FROM exercise_logs el
    WHERE el.patient_id = p_patient_id
      AND el.logged_at >= CURRENT_DATE - INTERVAL '14 days'
      AND el.logged_at <= CURRENT_DATE + INTERVAL '1 day';

    -- 28-day training load (for ACWR calculation)
    SELECT COALESCE(SUM(
        COALESCE(el.actual_sets, 1) *
        COALESCE(el.actual_reps, 1) *
        COALESCE(el.actual_load, 0)
    ), 0)
    INTO v_training_load_28d
    FROM exercise_logs el
    WHERE el.patient_id = p_patient_id
      AND el.logged_at >= CURRENT_DATE - INTERVAL '28 days'
      AND el.logged_at <= CURRENT_DATE + INTERVAL '1 day';

    -- ========================================================================
    -- STEP 3: Calculate ACWR (Acute:Chronic Workload Ratio)
    -- ACWR = (7-day avg load per day) / (28-day avg load per day)
    -- Optimal range: 0.8 - 1.3
    -- ========================================================================
    IF v_training_load_28d > 0 THEN
        v_acute_chronic_ratio := (v_training_load_7d / 7.0) / (v_training_load_28d / 28.0);
    ELSE
        v_acute_chronic_ratio := NULL;
    END IF;

    -- ========================================================================
    -- STEP 4: Count consecutive low readiness days (score < 60)
    -- Starting from today and going backwards
    -- ========================================================================
    FOR v_readiness_record IN
        SELECT date, readiness_score
        FROM daily_readiness
        WHERE patient_id = p_patient_id
          AND date <= CURRENT_DATE
        ORDER BY date DESC
        LIMIT 30
    LOOP
        IF NOT v_streak_broken THEN
            IF v_readiness_record.readiness_score < 60 THEN
                v_consecutive_low_readiness := v_consecutive_low_readiness + 1;
            ELSE
                v_streak_broken := true;
            END IF;
        END IF;
    END LOOP;

    -- ========================================================================
    -- STEP 5: Count missed reps in last 7 days
    -- (where actual_reps < target_reps from session_exercises)
    -- ========================================================================
    SELECT COALESCE(SUM(
        CASE
            WHEN se.target_reps IS NOT NULL AND el.actual_reps < se.target_reps
            THEN se.target_reps - el.actual_reps
            ELSE 0
        END
    ), 0)
    INTO v_missed_reps_count_7d
    FROM exercise_logs el
    JOIN session_exercises se ON el.session_exercise_id = se.id
    WHERE el.patient_id = p_patient_id
      AND el.logged_at >= CURRENT_DATE - INTERVAL '7 days'
      AND el.logged_at <= CURRENT_DATE + INTERVAL '1 day';

    -- ========================================================================
    -- STEP 6: Count high RPE sessions (RPE >= 8) in last 7 days
    -- ========================================================================
    SELECT COUNT(DISTINCT el.id)
    INTO v_high_rpe_count_7d
    FROM exercise_logs el
    WHERE el.patient_id = p_patient_id
      AND el.logged_at >= CURRENT_DATE - INTERVAL '7 days'
      AND el.logged_at <= CURRENT_DATE + INTERVAL '1 day'
      AND el.rpe >= 8;

    -- ========================================================================
    -- STEP 7: Count pain reports from exercise_logs in last 7 days
    -- (pain_score > 0 indicates a pain report)
    -- ========================================================================
    SELECT COUNT(DISTINCT el.id)
    INTO v_pain_reports_7d
    FROM exercise_logs el
    WHERE el.patient_id = p_patient_id
      AND el.logged_at >= CURRENT_DATE - INTERVAL '7 days'
      AND el.logged_at <= CURRENT_DATE + INTERVAL '1 day'
      AND el.pain_score > 0;

    -- ========================================================================
    -- STEP 8: Compute fatigue_score using weighted formula
    -- ========================================================================
    -- Formula components:
    -- 1. (100 - avg_readiness_7d) * 0.30 - Lower readiness = higher fatigue
    -- 2. ACWR factor * 0.25 - ACWR deviation from optimal range
    -- 3. consecutive_low * 10 * 0.20 - Consecutive low readiness penalty
    -- 4. pain_reports * 15 * 0.15 - Pain reports penalty
    -- 5. high_rpe_count * 8 * 0.10 - High RPE sessions penalty

    -- Calculate ACWR factor based on optimal range (0.8-1.3)
    IF v_acute_chronic_ratio IS NULL THEN
        v_acwr_factor := 0;
    ELSIF v_acute_chronic_ratio < 0.8 THEN
        -- Undertraining: slight penalty
        v_acwr_factor := (0.8 - v_acute_chronic_ratio) * 30;
    ELSIF v_acute_chronic_ratio <= 1.3 THEN
        -- Optimal range: no penalty
        v_acwr_factor := 0;
    ELSIF v_acute_chronic_ratio <= 1.5 THEN
        -- Moderate risk zone
        v_acwr_factor := (v_acute_chronic_ratio - 1.3) * 100;
    ELSE
        -- High risk zone (>1.5): escalating penalty
        v_acwr_factor := 20 + (v_acute_chronic_ratio - 1.5) * 150;
    END IF;

    -- Cap ACWR factor at 100
    v_acwr_factor := LEAST(v_acwr_factor, 100);

    -- Calculate total fatigue score using weighted formula
    v_fatigue_score :=
        COALESCE((100 - COALESCE(v_avg_readiness_7d, 50)) * 0.30, 15) +  -- Readiness component
        v_acwr_factor * 0.25 +                                           -- ACWR component
        LEAST(v_consecutive_low_readiness * 10, 50) * 0.20 +            -- Consecutive low (capped)
        LEAST(v_pain_reports_7d * 15, 60) * 0.15 +                      -- Pain reports (capped)
        LEAST(v_high_rpe_count_7d * 8, 40) * 0.10;                      -- High RPE (capped)

    -- Ensure fatigue score is within 0-100 range
    v_fatigue_score := GREATEST(0, LEAST(100, ROUND(v_fatigue_score, 1)));

    -- ========================================================================
    -- STEP 9: Determine fatigue_band based on score
    -- low (0-25), moderate (26-50), high (51-75), critical (76-100)
    -- ========================================================================
    v_fatigue_band := CASE
        WHEN v_fatigue_score <= 25 THEN 'low'
        WHEN v_fatigue_score <= 50 THEN 'moderate'
        WHEN v_fatigue_score <= 75 THEN 'high'
        ELSE 'critical'
    END;

    -- ========================================================================
    -- STEP 10: Set deload_recommended and deload_urgency
    -- none (<35), suggested (35-50), recommended (51-75), required (>75)
    -- ========================================================================
    IF v_fatigue_score > 75 THEN
        v_deload_recommended := true;
        v_deload_urgency := 'required';
    ELSIF v_fatigue_score > 50 THEN
        v_deload_recommended := true;
        v_deload_urgency := 'recommended';
    ELSIF v_fatigue_score >= 35 THEN
        v_deload_recommended := false;
        v_deload_urgency := 'suggested';
    ELSE
        v_deload_recommended := false;
        v_deload_urgency := 'none';
    END IF;

    -- Override: Recommend deload if ACWR is dangerously high
    IF v_acute_chronic_ratio IS NOT NULL AND v_acute_chronic_ratio > 1.5 THEN
        v_deload_recommended := true;
        IF v_deload_urgency = 'none' OR v_deload_urgency = 'suggested' THEN
            v_deload_urgency := 'recommended';
        END IF;
    END IF;

    -- Override: Recommend deload for extended consecutive low readiness (5+ days)
    IF v_consecutive_low_readiness >= 5 THEN
        v_deload_recommended := true;
        IF v_deload_urgency = 'none' OR v_deload_urgency = 'suggested' THEN
            v_deload_urgency := 'recommended';
        END IF;
    END IF;

    -- ========================================================================
    -- STEP 11: UPSERT result to fatigue_accumulation table
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
        v_acute_chronic_ratio,
        v_consecutive_low_readiness,
        v_missed_reps_count_7d,
        v_high_rpe_count_7d,
        v_pain_reports_7d,
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
        updated_at = now()
    RETURNING * INTO v_result;

    -- ========================================================================
    -- STEP 12: Return the result record
    -- ========================================================================
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION calculate_accumulated_fatigue(UUID) IS
'Calculate accumulated fatigue metrics for a patient and upsert into fatigue_accumulation table.

INPUTS:
  - p_patient_id: UUID of the patient to calculate fatigue for

CALCULATIONS:
  1. 7-day and 14-day average readiness from daily_readiness table
  2. Training load from exercise_logs (sets * reps * load)
  3. ACWR (Acute:Chronic Workload Ratio) = 7-day avg / 28-day avg
  4. Consecutive low readiness days (readiness_score < 60)
  5. Missed reps count (actual_reps < target_reps)
  6. High RPE session count (RPE >= 8)
  7. Pain report count (pain_score > 0)

FATIGUE SCORE FORMULA:
  (100 - avg_readiness_7d) * 0.30 +
  acwr_factor * 0.25 +
  consecutive_low * 10 * 0.20 (capped at 50) +
  pain_reports * 15 * 0.15 (capped at 60) +
  high_rpe_count * 8 * 0.10 (capped at 40)

FATIGUE BANDS:
  - low: 0-25
  - moderate: 26-50
  - high: 51-75
  - critical: 76-100

DELOAD URGENCY:
  - none: fatigue_score < 35
  - suggested: 35-50
  - recommended: 51-75
  - required: > 75

RETURNS:
  Complete fatigue_accumulation record after upsert';

-- ============================================================================
-- 5. ROW-LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE fatigue_accumulation ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------
-- Patient Policies: CRUD on own data
-- ----------------------------------------

-- SELECT: Patients can view their own fatigue data
CREATE POLICY "fatigue_accum_patient_select"
    ON fatigue_accumulation FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id
            FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    );

-- INSERT: Patients can insert their own fatigue data
CREATE POLICY "fatigue_accum_patient_insert"
    ON fatigue_accumulation FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT p.id
            FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE: Patients can update their own fatigue data
CREATE POLICY "fatigue_accum_patient_update"
    ON fatigue_accumulation FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id
            FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT p.id
            FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE: Patients can delete their own fatigue data
CREATE POLICY "fatigue_accum_patient_delete"
    ON fatigue_accumulation FOR DELETE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id
            FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    );

-- ----------------------------------------
-- Therapist Policy: Read all patient data
-- ----------------------------------------

CREATE POLICY "fatigue_accum_therapist_select"
    ON fatigue_accumulation FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM auth.users u
            WHERE u.id = auth.uid()
              AND u.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- ----------------------------------------
-- Service Role: Full access
-- ----------------------------------------

CREATE POLICY "fatigue_accum_service_all"
    ON fatigue_accumulation FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- 6. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON fatigue_accumulation TO authenticated;
GRANT ALL ON fatigue_accumulation TO service_role;
GRANT EXECUTE ON FUNCTION calculate_accumulated_fatigue(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_fatigue_accum_timestamp() TO authenticated;

-- ============================================================================
-- 7. TABLE AND COLUMN COMMENTS
-- ============================================================================

COMMENT ON TABLE fatigue_accumulation IS
'Accumulated fatigue tracking with ACWR analysis and deload recommendations.
One row per patient per day, calculated by calculate_accumulated_fatigue() function.
Part of Smart Recovery Sprint for automated fatigue monitoring.';

COMMENT ON COLUMN fatigue_accumulation.id IS 'Primary key UUID';
COMMENT ON COLUMN fatigue_accumulation.patient_id IS 'Patient this fatigue record belongs to';
COMMENT ON COLUMN fatigue_accumulation.calculation_date IS 'Date this fatigue calculation was performed for';
COMMENT ON COLUMN fatigue_accumulation.avg_readiness_7d IS 'Rolling 7-day average readiness score (0-100)';
COMMENT ON COLUMN fatigue_accumulation.avg_readiness_14d IS 'Rolling 14-day average readiness score (0-100)';
COMMENT ON COLUMN fatigue_accumulation.training_load_7d IS 'Training volume (sets * reps * load) over last 7 days';
COMMENT ON COLUMN fatigue_accumulation.training_load_14d IS 'Training volume (sets * reps * load) over last 14 days';
COMMENT ON COLUMN fatigue_accumulation.acute_chronic_ratio IS 'ACWR = 7-day avg load / 28-day avg load. Optimal: 0.8-1.3, Risk: >1.5';
COMMENT ON COLUMN fatigue_accumulation.consecutive_low_readiness IS 'Number of consecutive days with readiness score < 60';
COMMENT ON COLUMN fatigue_accumulation.missed_reps_count_7d IS 'Count of missed reps (actual < target) over last 7 days';
COMMENT ON COLUMN fatigue_accumulation.high_rpe_count_7d IS 'Count of exercises with RPE >= 8 over last 7 days';
COMMENT ON COLUMN fatigue_accumulation.pain_reports_7d IS 'Count of exercise_logs with pain_score > 0 over last 7 days';
COMMENT ON COLUMN fatigue_accumulation.fatigue_score IS 'Computed fatigue score 0-100 based on weighted formula';
COMMENT ON COLUMN fatigue_accumulation.fatigue_band IS 'Fatigue band: low (0-25), moderate (26-50), high (51-75), critical (76-100)';
COMMENT ON COLUMN fatigue_accumulation.deload_recommended IS 'Whether a deload is recommended based on fatigue indicators';
COMMENT ON COLUMN fatigue_accumulation.deload_urgency IS 'Urgency of deload: none (<35), suggested (35-50), recommended (51-75), required (>75)';
COMMENT ON COLUMN fatigue_accumulation.created_at IS 'Timestamp when record was created';
COMMENT ON COLUMN fatigue_accumulation.updated_at IS 'Timestamp when record was last updated';

-- ============================================================================
-- 8. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_table_exists BOOLEAN;
    v_rls_enabled BOOLEAN;
    v_policy_count INTEGER;
    v_function_exists BOOLEAN;
    v_index_count INTEGER;
BEGIN
    -- Check table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'fatigue_accumulation'
    ) INTO v_table_exists;

    IF NOT v_table_exists THEN
        RAISE EXCEPTION 'FAILED: fatigue_accumulation table was not created';
    END IF;

    -- Check RLS is enabled
    SELECT relrowsecurity
    FROM pg_class
    WHERE relname = 'fatigue_accumulation'
    INTO v_rls_enabled;

    IF NOT v_rls_enabled THEN
        RAISE EXCEPTION 'FAILED: RLS is not enabled on fatigue_accumulation';
    END IF;

    -- Count policies
    SELECT COUNT(*)
    FROM pg_policies
    WHERE tablename = 'fatigue_accumulation'
    INTO v_policy_count;

    IF v_policy_count < 6 THEN
        RAISE EXCEPTION 'FAILED: Expected 6 RLS policies, found %', v_policy_count;
    END IF;

    -- Check function exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_schema = 'public'
          AND routine_name = 'calculate_accumulated_fatigue'
    ) INTO v_function_exists;

    IF NOT v_function_exists THEN
        RAISE EXCEPTION 'FAILED: calculate_accumulated_fatigue function was not created';
    END IF;

    -- Count indexes
    SELECT COUNT(*)
    FROM pg_indexes
    WHERE tablename = 'fatigue_accumulation'
    INTO v_index_count;

    IF v_index_count < 6 THEN
        RAISE EXCEPTION 'FAILED: Expected at least 6 indexes, found %', v_index_count;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'FATIGUE ACCUMULATION MIGRATION - SMART RECOVERY SPRINT';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Table: fatigue_accumulation';
    RAISE NOTICE '  - RLS enabled: %', v_rls_enabled;
    RAISE NOTICE '  - Policies: %', v_policy_count;
    RAISE NOTICE '  - Indexes: %', v_index_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Function: calculate_accumulated_fatigue(p_patient_id UUID)';
    RAISE NOTICE '  RETURNS fatigue_accumulation record';
    RAISE NOTICE '';
    RAISE NOTICE 'Columns:';
    RAISE NOTICE '  Rolling Window Metrics:';
    RAISE NOTICE '    - avg_readiness_7d, avg_readiness_14d';
    RAISE NOTICE '    - training_load_7d, training_load_14d';
    RAISE NOTICE '    - acute_chronic_ratio (ACWR)';
    RAISE NOTICE '';
    RAISE NOTICE '  Fatigue Indicators:';
    RAISE NOTICE '    - consecutive_low_readiness';
    RAISE NOTICE '    - missed_reps_count_7d';
    RAISE NOTICE '    - high_rpe_count_7d';
    RAISE NOTICE '    - pain_reports_7d';
    RAISE NOTICE '';
    RAISE NOTICE '  Computed Scores:';
    RAISE NOTICE '    - fatigue_score (0-100)';
    RAISE NOTICE '    - fatigue_band (low/moderate/high/critical)';
    RAISE NOTICE '';
    RAISE NOTICE '  Recommendations:';
    RAISE NOTICE '    - deload_recommended (boolean)';
    RAISE NOTICE '    - deload_urgency (none/suggested/recommended/required)';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies:';
    RAISE NOTICE '  - Patients: Full CRUD on own data';
    RAISE NOTICE '  - Therapists: Read-only access to all patient data';
    RAISE NOTICE '  - Service role: Full access';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'Agent 1 - Smart Recovery Sprint - Migration Complete';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Usage: SELECT * FROM calculate_accumulated_fatigue(''patient-uuid'');';
    RAISE NOTICE '';
END $$;
