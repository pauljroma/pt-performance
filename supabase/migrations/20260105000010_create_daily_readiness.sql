-- ============================================================================
-- CREATE DAILY READINESS SYSTEM - BUILD 116
-- ============================================================================
-- Implements daily readiness tracking with configurable factors and trend analysis
-- Allows patients to log daily wellness metrics and calculate readiness scores
--
-- Date: 2026-01-03
-- Agent: 1
-- Linear: BUILD-116
-- ============================================================================

-- =====================================================
-- Readiness Factors Table (Configuration)
-- =====================================================

CREATE TABLE IF NOT EXISTS readiness_factors (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    weight numeric(3,2) NOT NULL CHECK (weight >= 0 AND weight <= 1),
    description text,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_readiness_factors_active ON readiness_factors(is_active) WHERE is_active = true;

COMMENT ON TABLE readiness_factors IS 'Configurable factors that contribute to daily readiness score calculation';
COMMENT ON COLUMN readiness_factors.name IS 'Factor name (e.g., sleep_quality, soreness, energy)';
COMMENT ON COLUMN readiness_factors.weight IS 'Weight in score calculation (0.0 to 1.0, sum should equal 1.0)';
COMMENT ON COLUMN readiness_factors.description IS 'Description of what this factor measures';
COMMENT ON COLUMN readiness_factors.is_active IS 'Whether this factor is currently used in calculations';

-- Seed default readiness factors
INSERT INTO readiness_factors (name, weight, description) VALUES
    ('sleep_quality', 0.35, 'Sleep duration and quality - most important factor'),
    ('soreness_level', 0.25, 'Muscle soreness and pain levels - inverse scoring'),
    ('energy_level', 0.20, 'Subjective energy and motivation levels'),
    ('stress_level', 0.15, 'Mental stress and anxiety - inverse scoring'),
    ('nutrition_quality', 0.05, 'Quality of previous day nutrition')
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- Daily Readiness Table (Patient Data)
-- =====================================================

CREATE TABLE IF NOT EXISTS daily_readiness (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    date date NOT NULL,

    -- Core metrics (1-10 scale)
    sleep_hours numeric(3,1) CHECK (sleep_hours >= 0 AND sleep_hours <= 24),
    soreness_level integer CHECK (soreness_level >= 1 AND soreness_level <= 10),
    energy_level integer CHECK (energy_level >= 1 AND energy_level <= 10),
    stress_level integer CHECK (stress_level >= 1 AND stress_level <= 10),

    -- Calculated score
    readiness_score numeric(4,1) CHECK (readiness_score >= 0 AND readiness_score <= 100),

    -- Optional fields
    notes text,

    -- Metadata
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    -- Ensure one entry per patient per day
    UNIQUE(patient_id, date)
);

CREATE INDEX idx_daily_readiness_patient ON daily_readiness(patient_id, date DESC);
CREATE INDEX idx_daily_readiness_date ON daily_readiness(date DESC);
CREATE INDEX idx_daily_readiness_score ON daily_readiness(readiness_score DESC);

COMMENT ON TABLE daily_readiness IS 'Daily readiness tracking for patients - wellness metrics and calculated readiness score';
COMMENT ON COLUMN daily_readiness.patient_id IS 'Patient who logged this readiness data';
COMMENT ON COLUMN daily_readiness.date IS 'Date of readiness entry';
COMMENT ON COLUMN daily_readiness.sleep_hours IS 'Hours of sleep (0-24)';
COMMENT ON COLUMN daily_readiness.soreness_level IS 'Muscle soreness (1=no soreness, 10=extreme soreness)';
COMMENT ON COLUMN daily_readiness.energy_level IS 'Energy level (1=exhausted, 10=fully energized)';
COMMENT ON COLUMN daily_readiness.stress_level IS 'Stress level (1=no stress, 10=extreme stress)';
COMMENT ON COLUMN daily_readiness.readiness_score IS 'Calculated readiness score (0-100, higher is better)';
COMMENT ON COLUMN daily_readiness.notes IS 'Optional notes from patient about how they feel';

-- =====================================================
-- Auto-update timestamp trigger
-- =====================================================

CREATE OR REPLACE FUNCTION update_readiness_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_readiness_timestamp_trigger
    BEFORE UPDATE ON daily_readiness
    FOR EACH ROW
    EXECUTE FUNCTION update_readiness_timestamp();

CREATE TRIGGER update_factors_timestamp_trigger
    BEFORE UPDATE ON readiness_factors
    FOR EACH ROW
    EXECUTE FUNCTION update_readiness_timestamp();

-- =====================================================
-- Function: Calculate Readiness Score
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_readiness_score(
    p_patient_id uuid,
    p_date date
)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sleep_hours numeric;
    v_soreness_level integer;
    v_energy_level integer;
    v_stress_level integer;

    v_sleep_score numeric;
    v_soreness_score numeric;
    v_energy_score numeric;
    v_stress_score numeric;

    v_sleep_weight numeric;
    v_soreness_weight numeric;
    v_energy_weight numeric;
    v_stress_weight numeric;

    v_total_score numeric;
BEGIN
    -- Get raw metrics from daily_readiness
    SELECT sleep_hours, soreness_level, energy_level, stress_level
    INTO v_sleep_hours, v_soreness_level, v_energy_level, v_stress_level
    FROM daily_readiness
    WHERE patient_id = p_patient_id AND date = p_date;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No readiness data found for patient % on date %', p_patient_id, p_date;
    END IF;

    -- Get factor weights
    SELECT weight INTO v_sleep_weight FROM readiness_factors WHERE name = 'sleep_quality' AND is_active = true;
    SELECT weight INTO v_soreness_weight FROM readiness_factors WHERE name = 'soreness_level' AND is_active = true;
    SELECT weight INTO v_energy_weight FROM readiness_factors WHERE name = 'energy_level' AND is_active = true;
    SELECT weight INTO v_stress_weight FROM readiness_factors WHERE name = 'stress_level' AND is_active = true;

    -- Calculate component scores (normalize to 0-100)
    -- Sleep: optimal is 7-9 hours, score decreases outside this range
    v_sleep_score = CASE
        WHEN v_sleep_hours IS NULL THEN 50
        WHEN v_sleep_hours >= 7 AND v_sleep_hours <= 9 THEN 100
        WHEN v_sleep_hours >= 6 AND v_sleep_hours < 7 THEN 80
        WHEN v_sleep_hours > 9 AND v_sleep_hours <= 10 THEN 80
        WHEN v_sleep_hours >= 5 AND v_sleep_hours < 6 THEN 60
        WHEN v_sleep_hours > 10 AND v_sleep_hours <= 11 THEN 60
        ELSE 40
    END;

    -- Soreness: inverse score (lower soreness = higher score)
    v_soreness_score = CASE
        WHEN v_soreness_level IS NULL THEN 50
        ELSE 100 - ((v_soreness_level - 1) * 11.11)
    END;

    -- Energy: direct score (higher energy = higher score)
    v_energy_score = CASE
        WHEN v_energy_level IS NULL THEN 50
        ELSE (v_energy_level - 1) * 11.11
    END;

    -- Stress: inverse score (lower stress = higher score)
    v_stress_score = CASE
        WHEN v_stress_level IS NULL THEN 50
        ELSE 100 - ((v_stress_level - 1) * 11.11)
    END;

    -- Calculate weighted total
    v_total_score =
        (v_sleep_score * COALESCE(v_sleep_weight, 0.35)) +
        (v_soreness_score * COALESCE(v_soreness_weight, 0.25)) +
        (v_energy_score * COALESCE(v_energy_weight, 0.20)) +
        (v_stress_score * COALESCE(v_stress_weight, 0.15));

    -- Round to 1 decimal place
    RETURN ROUND(v_total_score, 1);
END;
$$;

COMMENT ON FUNCTION calculate_readiness_score IS
    'Calculate weighted readiness score for a patient on a specific date based on multiple factors';

-- =====================================================
-- Function: Get Readiness Trend
-- =====================================================

CREATE OR REPLACE FUNCTION get_readiness_trend(
    p_patient_id uuid,
    p_days integer DEFAULT 7
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result json;
BEGIN
    SELECT json_build_object(
        'patient_id', p_patient_id,
        'days_analyzed', p_days,
        'current_date', CURRENT_DATE,
        'trend_data', (
            SELECT json_agg(
                json_build_object(
                    'date', date,
                    'readiness_score', readiness_score,
                    'sleep_hours', sleep_hours,
                    'soreness_level', soreness_level,
                    'energy_level', energy_level,
                    'stress_level', stress_level,
                    'notes', notes
                ) ORDER BY date DESC
            )
            FROM daily_readiness
            WHERE patient_id = p_patient_id
                AND date >= CURRENT_DATE - p_days
            ORDER BY date DESC
        ),
        'statistics', (
            SELECT json_build_object(
                'avg_readiness', ROUND(AVG(readiness_score), 1),
                'min_readiness', MIN(readiness_score),
                'max_readiness', MAX(readiness_score),
                'avg_sleep', ROUND(AVG(sleep_hours), 1),
                'avg_soreness', ROUND(AVG(soreness_level), 1),
                'avg_energy', ROUND(AVG(energy_level), 1),
                'avg_stress', ROUND(AVG(stress_level), 1),
                'total_entries', COUNT(*)
            )
            FROM daily_readiness
            WHERE patient_id = p_patient_id
                AND date >= CURRENT_DATE - p_days
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_readiness_trend IS
    'Get readiness trend data and statistics for a patient over the last N days (default 7)';

-- =====================================================
-- Trigger: Auto-calculate readiness score on insert/update
-- =====================================================

CREATE OR REPLACE FUNCTION auto_calculate_readiness_score()
RETURNS TRIGGER AS $$
BEGIN
    -- Only calculate if we have at least one metric
    IF NEW.sleep_hours IS NOT NULL OR
       NEW.soreness_level IS NOT NULL OR
       NEW.energy_level IS NOT NULL OR
       NEW.stress_level IS NOT NULL THEN

        NEW.readiness_score = calculate_readiness_score(NEW.patient_id, NEW.date);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_calculate_readiness_trigger
    BEFORE INSERT OR UPDATE ON daily_readiness
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_readiness_score();

COMMENT ON FUNCTION auto_calculate_readiness_score IS
    'Automatically calculate and update readiness score when readiness data is inserted or updated';

-- =====================================================
-- Row-Level Security (RLS)
-- =====================================================

ALTER TABLE readiness_factors ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Readiness Factors: Everyone can read (needed for UI), only service role can modify
CREATE POLICY "Anyone can read active readiness factors"
    ON readiness_factors FOR SELECT
    TO authenticated
    USING (is_active = true);

CREATE POLICY "Service role can manage readiness factors"
    ON readiness_factors FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Daily Readiness: Patients can CRUD their own data
CREATE POLICY "Patients can view their own readiness data"
    ON daily_readiness FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can insert their own readiness data"
    ON daily_readiness FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update their own readiness data"
    ON daily_readiness FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can delete their own readiness data"
    ON daily_readiness FOR DELETE
    USING (patient_id = auth.uid());

-- Therapists have read-only access to all patient readiness data
CREATE POLICY "Therapists can view all readiness data"
    ON daily_readiness FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- Service role can do everything (for backend operations)
CREATE POLICY "Service role can manage all readiness data"
    ON daily_readiness FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- Grant Permissions
-- =====================================================

GRANT SELECT ON readiness_factors TO authenticated;
GRANT ALL ON readiness_factors TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON daily_readiness TO authenticated;
GRANT ALL ON daily_readiness TO service_role;

GRANT EXECUTE ON FUNCTION calculate_readiness_score TO authenticated;
GRANT EXECUTE ON FUNCTION get_readiness_trend TO authenticated;
GRANT EXECUTE ON FUNCTION auto_calculate_readiness_score TO authenticated;
GRANT EXECUTE ON FUNCTION update_readiness_timestamp TO authenticated;

-- =====================================================
-- Test Queries
-- =====================================================

-- Test Query 1: Count readiness entries for a patient
-- Usage: SELECT COUNT(*) FROM daily_readiness WHERE patient_id = 'YOUR-UUID-HERE';

-- Test Query 2: Calculate readiness score for a patient on a specific date
-- Usage: SELECT calculate_readiness_score('YOUR-UUID-HERE', CURRENT_DATE);

-- Test Query 3: Get readiness trend for last 7 days
-- Usage: SELECT get_readiness_trend('YOUR-UUID-HERE', 7);

-- Test Query 4: View all active readiness factors
-- SELECT * FROM readiness_factors WHERE is_active = true ORDER BY weight DESC;

-- Test Query 5: View recent readiness data with scores
-- SELECT date, readiness_score, sleep_hours, soreness_level, energy_level, stress_level
-- FROM daily_readiness
-- WHERE patient_id = 'YOUR-UUID-HERE'
-- ORDER BY date DESC
-- LIMIT 7;

-- =====================================================
-- Verification
-- =====================================================

DO $$
DECLARE
    v_factors_count integer;
    v_readiness_count integer;
BEGIN
    SELECT COUNT(*) INTO v_factors_count FROM readiness_factors WHERE is_active = true;
    SELECT COUNT(*) INTO v_readiness_count FROM daily_readiness;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DAILY READINESS SYSTEM CREATED - BUILD 116';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Tables Created:';
    RAISE NOTICE '   - readiness_factors (% active factors)', v_factors_count;
    RAISE NOTICE '   - daily_readiness (% existing entries)', v_readiness_count;
    RAISE NOTICE '';
    RAISE NOTICE '✅ Functions Created:';
    RAISE NOTICE '   - calculate_readiness_score(patient_id, date) → numeric';
    RAISE NOTICE '   - get_readiness_trend(patient_id, days) → json';
    RAISE NOTICE '   - auto_calculate_readiness_score() [trigger]';
    RAISE NOTICE '';
    RAISE NOTICE '✅ RLS Policies (6 policies):';
    RAISE NOTICE '   - Patients: Full CRUD on own data';
    RAISE NOTICE '   - Therapists: Read-only access to all patient data';
    RAISE NOTICE '   - Service role: Full access';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Indexes Created:';
    RAISE NOTICE '   - idx_readiness_factors_active';
    RAISE NOTICE '   - idx_daily_readiness_patient';
    RAISE NOTICE '   - idx_daily_readiness_date';
    RAISE NOTICE '   - idx_daily_readiness_score';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Triggers:';
    RAISE NOTICE '   - Auto-calculate readiness score on insert/update';
    RAISE NOTICE '   - Auto-update timestamps';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DAILY READINESS SYSTEM READY FOR BUILD 116';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Test with:';
    RAISE NOTICE '  SELECT COUNT(*) FROM daily_readiness WHERE patient_id = ''test-uuid'';';
    RAISE NOTICE '  SELECT calculate_readiness_score(''test-uuid'', CURRENT_DATE);';
    RAISE NOTICE '  SELECT get_readiness_trend(''test-uuid'', 7);';
    RAISE NOTICE '';
END $$;
