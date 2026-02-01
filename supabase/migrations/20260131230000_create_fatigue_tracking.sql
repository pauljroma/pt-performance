-- ============================================================================
-- CREATE FATIGUE TRACKING SYSTEM
-- ============================================================================
-- Implements accumulated fatigue tracking with ACWR (acute:chronic workload ratio)
-- and deload recommendations based on multiple fatigue indicators
--
-- Date: 2026-01-31
-- Agent: 1
-- ============================================================================

-- ============================================================================
-- 1. CREATE FATIGUE ACCUMULATION TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS fatigue_accumulation (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Patient relationship
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    calculation_date DATE NOT NULL,

    -- Rolling readiness metrics
    avg_readiness_7d NUMERIC(5,2),
    avg_readiness_14d NUMERIC(5,2),

    -- Training load metrics
    training_load_7d NUMERIC(12,2),
    training_load_14d NUMERIC(12,2),
    acute_chronic_ratio NUMERIC(5,3),  -- ACWR = 7-day avg / 28-day avg

    -- Fatigue indicators
    consecutive_low_readiness INTEGER NOT NULL DEFAULT 0,
    missed_reps_count_7d INTEGER NOT NULL DEFAULT 0,
    high_rpe_count_7d INTEGER NOT NULL DEFAULT 0,
    pain_reports_7d INTEGER NOT NULL DEFAULT 0,

    -- Computed fatigue metrics
    fatigue_score NUMERIC(5,2) CHECK (fatigue_score >= 0 AND fatigue_score <= 100),
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

CREATE INDEX idx_fatigue_accumulation_patient_date
ON fatigue_accumulation(patient_id, calculation_date DESC);

CREATE INDEX idx_fatigue_accumulation_date
ON fatigue_accumulation(calculation_date DESC);

CREATE INDEX idx_fatigue_accumulation_fatigue_band
ON fatigue_accumulation(fatigue_band);

CREATE INDEX idx_fatigue_accumulation_deload
ON fatigue_accumulation(deload_recommended)
WHERE deload_recommended = true;

CREATE INDEX idx_fatigue_accumulation_patient_score
ON fatigue_accumulation(patient_id, fatigue_score DESC);

-- ============================================================================
-- 3. AUTO-UPDATE TIMESTAMP TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_fatigue_accumulation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_fatigue_accumulation_updated
    BEFORE UPDATE ON fatigue_accumulation
    FOR EACH ROW
    EXECUTE FUNCTION update_fatigue_accumulation_timestamp();

-- ============================================================================
-- 4. CREATE CALCULATE ACCUMULATED FATIGUE FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_accumulated_fatigue(p_patient_id UUID)
RETURNS UUID
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

    -- Result
    v_result_id UUID;

    -- For consecutive low readiness calculation
    v_readiness_record RECORD;
    v_streak_broken BOOLEAN := false;
BEGIN
    -- ========================================================================
    -- Calculate 7-day and 14-day average readiness from daily_readiness
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
    -- Calculate training load from manual_sessions (total_volume)
    -- ========================================================================
    SELECT COALESCE(SUM(total_volume), 0)
    INTO v_training_load_7d
    FROM manual_sessions
    WHERE patient_id = p_patient_id
      AND completed = true
      AND completed_at >= CURRENT_DATE - INTERVAL '7 days'
      AND completed_at <= CURRENT_DATE;

    SELECT COALESCE(SUM(total_volume), 0)
    INTO v_training_load_14d
    FROM manual_sessions
    WHERE patient_id = p_patient_id
      AND completed = true
      AND completed_at >= CURRENT_DATE - INTERVAL '14 days'
      AND completed_at <= CURRENT_DATE;

    SELECT COALESCE(SUM(total_volume), 0)
    INTO v_training_load_28d
    FROM manual_sessions
    WHERE patient_id = p_patient_id
      AND completed = true
      AND completed_at >= CURRENT_DATE - INTERVAL '28 days'
      AND completed_at <= CURRENT_DATE;

    -- ========================================================================
    -- Calculate ACWR (Acute:Chronic Workload Ratio) = 7-day avg / 28-day avg
    -- ========================================================================
    IF v_training_load_28d > 0 THEN
        -- 7-day average load / 28-day average load
        v_acute_chronic_ratio := (v_training_load_7d / 7.0) / (v_training_load_28d / 28.0);
    ELSE
        v_acute_chronic_ratio := NULL;
    END IF;

    -- ========================================================================
    -- Count consecutive low readiness days (score < 60)
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
    -- Count high RPE sessions (avg_rpe >= 8) in last 7 days
    -- ========================================================================
    SELECT COUNT(*)
    INTO v_high_rpe_count_7d
    FROM manual_sessions
    WHERE patient_id = p_patient_id
      AND completed = true
      AND completed_at >= CURRENT_DATE - INTERVAL '7 days'
      AND completed_at <= CURRENT_DATE
      AND avg_rpe >= 8;

    -- ========================================================================
    -- Count pain reports from exercise_logs in last 7 days
    -- (pain_score > 0 indicates a pain report)
    -- ========================================================================
    SELECT COUNT(DISTINCT el.id)
    INTO v_pain_reports_7d
    FROM exercise_logs el
    WHERE el.patient_id = p_patient_id
      AND el.performed_at >= CURRENT_DATE - INTERVAL '7 days'
      AND el.performed_at <= CURRENT_DATE
      AND el.pain_score > 0;

    -- ========================================================================
    -- Count missed reps in last 7 days
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
      AND el.performed_at >= CURRENT_DATE - INTERVAL '7 days'
      AND el.performed_at <= CURRENT_DATE;

    -- ========================================================================
    -- Compute fatigue_score using weighted formula
    -- ========================================================================
    -- Components:
    -- 1. (100 - avg_readiness_7d) * 0.3 - Lower readiness = higher fatigue
    -- 2. ACWR factor * 0.25 - ACWR deviation from optimal (0.8-1.3) range
    -- 3. consecutive_low * 10 * 0.2 - Consecutive low readiness days penalty
    -- 4. pain_reports * 15 * 0.15 - Pain reports penalty
    -- 5. high_rpe_count * 8 * 0.1 - High RPE sessions penalty

    -- ACWR factor calculation: optimal range is 0.8-1.3
    -- Below 0.8 = undertraining (low risk)
    -- 0.8-1.3 = optimal (low risk)
    -- 1.3-1.5 = moderate risk
    -- >1.5 = high risk
    IF v_acute_chronic_ratio IS NULL THEN
        v_acwr_factor := 0;
    ELSIF v_acute_chronic_ratio < 0.8 THEN
        v_acwr_factor := (0.8 - v_acute_chronic_ratio) * 25; -- Slight penalty for undertraining
    ELSIF v_acute_chronic_ratio <= 1.3 THEN
        v_acwr_factor := 0; -- Optimal range
    ELSIF v_acute_chronic_ratio <= 1.5 THEN
        v_acwr_factor := (v_acute_chronic_ratio - 1.3) * 100; -- 0-20 range
    ELSE
        v_acwr_factor := 20 + (v_acute_chronic_ratio - 1.5) * 150; -- High risk, escalating
    END IF;
    -- Cap ACWR factor at 100
    v_acwr_factor := LEAST(v_acwr_factor, 100);

    -- Calculate total fatigue score
    v_fatigue_score :=
        COALESCE((100 - COALESCE(v_avg_readiness_7d, 50)) * 0.3, 15) +  -- Readiness component
        v_acwr_factor * 0.25 +                                           -- ACWR component
        LEAST(v_consecutive_low_readiness * 10, 50) * 0.2 +             -- Consecutive low (capped at 50)
        LEAST(v_pain_reports_7d * 15, 60) * 0.15 +                      -- Pain reports (capped at 60)
        LEAST(v_high_rpe_count_7d * 8, 40) * 0.1;                       -- High RPE (capped at 40)

    -- Ensure fatigue score is within 0-100 range
    v_fatigue_score := GREATEST(0, LEAST(100, v_fatigue_score));

    -- ========================================================================
    -- Determine fatigue_band
    -- ========================================================================
    v_fatigue_band := CASE
        WHEN v_fatigue_score <= 25 THEN 'low'
        WHEN v_fatigue_score <= 50 THEN 'moderate'
        WHEN v_fatigue_score <= 75 THEN 'high'
        ELSE 'critical'
    END;

    -- ========================================================================
    -- Set deload_recommended and deload_urgency based on score
    -- ========================================================================
    IF v_fatigue_score >= 76 THEN
        v_deload_recommended := true;
        v_deload_urgency := 'required';
    ELSIF v_fatigue_score >= 51 THEN
        v_deload_recommended := true;
        v_deload_urgency := 'recommended';
    ELSIF v_fatigue_score >= 35 THEN
        v_deload_recommended := false;
        v_deload_urgency := 'suggested';
    ELSE
        v_deload_recommended := false;
        v_deload_urgency := 'none';
    END IF;

    -- Also recommend deload if ACWR is dangerously high
    IF v_acute_chronic_ratio IS NOT NULL AND v_acute_chronic_ratio > 1.5 THEN
        v_deload_recommended := true;
        IF v_deload_urgency = 'none' OR v_deload_urgency = 'suggested' THEN
            v_deload_urgency := 'recommended';
        END IF;
    END IF;

    -- Also recommend deload for extended consecutive low readiness
    IF v_consecutive_low_readiness >= 5 THEN
        v_deload_recommended := true;
        IF v_deload_urgency = 'none' OR v_deload_urgency = 'suggested' THEN
            v_deload_urgency := 'recommended';
        END IF;
    END IF;

    -- ========================================================================
    -- UPSERT into fatigue_accumulation table
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
    RETURNING id INTO v_result_id;

    RETURN v_result_id;
END;
$$;

COMMENT ON FUNCTION calculate_accumulated_fatigue(UUID) IS
'Calculate accumulated fatigue metrics for a patient and upsert into fatigue_accumulation table.
Uses ACWR (acute:chronic workload ratio), readiness trends, pain reports, and RPE to compute
a fatigue score (0-100) with bands (low/moderate/high/critical) and deload recommendations.';

-- ============================================================================
-- 5. ROW-LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE fatigue_accumulation ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------
-- Patient Policies: Read/Write their own data
-- ----------------------------------------

-- Patients can view their own fatigue data
CREATE POLICY "Patients can view their own fatigue data"
    ON fatigue_accumulation FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id
            FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    );

-- Patients can insert their own fatigue data
CREATE POLICY "Patients can insert their own fatigue data"
    ON fatigue_accumulation FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT p.id
            FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    );

-- Patients can update their own fatigue data
CREATE POLICY "Patients can update their own fatigue data"
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

-- Patients can delete their own fatigue data
CREATE POLICY "Patients can delete their own fatigue data"
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
-- Therapist Policy: Read patient fatigue data
-- ----------------------------------------

CREATE POLICY "Therapists can view patient fatigue data"
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

CREATE POLICY "Service role has full access to fatigue data"
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
GRANT EXECUTE ON FUNCTION update_fatigue_accumulation_timestamp() TO authenticated;

-- ============================================================================
-- 7. TABLE COMMENTS
-- ============================================================================

COMMENT ON TABLE fatigue_accumulation IS
'Accumulated fatigue tracking with ACWR analysis and deload recommendations.
One row per patient per day, calculated by calculate_accumulated_fatigue() function.';

COMMENT ON COLUMN fatigue_accumulation.patient_id IS 'Patient this fatigue record belongs to';
COMMENT ON COLUMN fatigue_accumulation.calculation_date IS 'Date this fatigue calculation was performed for';
COMMENT ON COLUMN fatigue_accumulation.avg_readiness_7d IS 'Rolling 7-day average readiness score (0-100)';
COMMENT ON COLUMN fatigue_accumulation.avg_readiness_14d IS 'Rolling 14-day average readiness score (0-100)';
COMMENT ON COLUMN fatigue_accumulation.training_load_7d IS 'Total training volume over last 7 days from manual_sessions';
COMMENT ON COLUMN fatigue_accumulation.training_load_14d IS 'Total training volume over last 14 days from manual_sessions';
COMMENT ON COLUMN fatigue_accumulation.acute_chronic_ratio IS 'ACWR = 7-day avg load / 28-day avg load. Optimal: 0.8-1.3';
COMMENT ON COLUMN fatigue_accumulation.consecutive_low_readiness IS 'Number of consecutive days with readiness score < 60';
COMMENT ON COLUMN fatigue_accumulation.missed_reps_count_7d IS 'Count of missed reps (actual < target) over last 7 days';
COMMENT ON COLUMN fatigue_accumulation.high_rpe_count_7d IS 'Count of sessions with avg_rpe >= 8 over last 7 days';
COMMENT ON COLUMN fatigue_accumulation.pain_reports_7d IS 'Count of exercise_logs with pain_score > 0 over last 7 days';
COMMENT ON COLUMN fatigue_accumulation.fatigue_score IS 'Computed fatigue score 0-100 based on weighted formula';
COMMENT ON COLUMN fatigue_accumulation.fatigue_band IS 'Fatigue band: low (0-25), moderate (26-50), high (51-75), critical (76-100)';
COMMENT ON COLUMN fatigue_accumulation.deload_recommended IS 'Whether a deload is recommended based on fatigue indicators';
COMMENT ON COLUMN fatigue_accumulation.deload_urgency IS 'Urgency of deload: none, suggested, recommended, required';

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

    IF v_index_count < 5 THEN
        RAISE EXCEPTION 'FAILED: Expected at least 5 indexes, found %', v_index_count;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'FATIGUE TRACKING SYSTEM CREATED SUCCESSFULLY';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Table: fatigue_accumulation';
    RAISE NOTICE '  - RLS enabled: %', v_rls_enabled;
    RAISE NOTICE '  - Policies: %', v_policy_count;
    RAISE NOTICE '  - Indexes: %', v_index_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Function: calculate_accumulated_fatigue(patient_id UUID) -> UUID';
    RAISE NOTICE '  - Calculates 7d/14d readiness averages from daily_readiness';
    RAISE NOTICE '  - Calculates training load from manual_sessions';
    RAISE NOTICE '  - Computes ACWR (acute:chronic workload ratio)';
    RAISE NOTICE '  - Counts consecutive low readiness days';
    RAISE NOTICE '  - Counts pain reports from exercise_logs';
    RAISE NOTICE '  - Computes weighted fatigue score (0-100)';
    RAISE NOTICE '  - Determines fatigue band and deload recommendations';
    RAISE NOTICE '  - UPSERTS result into fatigue_accumulation table';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies:';
    RAISE NOTICE '  - Patients: Full CRUD on own data';
    RAISE NOTICE '  - Therapists: Read-only access to all patient data';
    RAISE NOTICE '  - Service role: Full access';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Usage: SELECT calculate_accumulated_fatigue(''patient-uuid-here'');';
    RAISE NOTICE '';
END $$;
