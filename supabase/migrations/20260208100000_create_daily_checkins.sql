-- X2Index M8: Daily Check-Ins Table
-- Athlete daily wellness check-in for readiness calculation
-- Target: <=60 second sync latency

-- ============================================================================
-- CREATE DAILY CHECKINS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS daily_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    date DATE NOT NULL,

    -- Core wellness metrics
    sleep_quality INT NOT NULL CHECK (sleep_quality BETWEEN 1 AND 5),
    sleep_hours NUMERIC(3,1) CHECK (sleep_hours BETWEEN 0 AND 24),
    soreness INT NOT NULL CHECK (soreness BETWEEN 1 AND 10),
    soreness_locations TEXT[],
    stress INT NOT NULL CHECK (stress BETWEEN 1 AND 10),
    energy INT NOT NULL CHECK (energy BETWEEN 1 AND 10),

    -- Optional pain tracking
    pain_score INT CHECK (pain_score BETWEEN 0 AND 10),
    pain_locations TEXT[],

    -- Mood and notes
    mood INT NOT NULL CHECK (mood BETWEEN 1 AND 5),
    free_text TEXT,

    -- Timestamps
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Unique constraint: one check-in per athlete per day
    UNIQUE(athlete_id, date)
);

-- Add comments for documentation
COMMENT ON TABLE daily_checkins IS 'Athlete daily wellness check-ins for X2Index readiness calculation';
COMMENT ON COLUMN daily_checkins.sleep_quality IS 'Sleep quality rating 1-5 (1=poor, 5=excellent)';
COMMENT ON COLUMN daily_checkins.soreness IS 'Muscle soreness level 1-10 (1=none, 10=extreme)';
COMMENT ON COLUMN daily_checkins.stress IS 'Stress level 1-10 (1=calm, 10=extremely stressed)';
COMMENT ON COLUMN daily_checkins.energy IS 'Energy level 1-10 (1=exhausted, 10=fully energized)';
COMMENT ON COLUMN daily_checkins.pain_score IS 'Pain intensity 0-10 (0=none, 10=severe), optional';
COMMENT ON COLUMN daily_checkins.mood IS 'Mood rating 1-5 (1=very low, 5=excellent)';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Primary lookup: athlete's check-ins by date (most recent first)
CREATE INDEX IF NOT EXISTS idx_daily_checkins_athlete_date
ON daily_checkins(athlete_id, date DESC);

-- For streak calculations: find all dates with check-ins
CREATE INDEX IF NOT EXISTS idx_daily_checkins_date
ON daily_checkins(date DESC);

-- For syncing: find unsynced check-ins
CREATE INDEX IF NOT EXISTS idx_daily_checkins_unsynced
ON daily_checkins(synced_at)
WHERE synced_at IS NULL;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE daily_checkins ENABLE ROW LEVEL SECURITY;

-- Athletes can view their own check-ins
CREATE POLICY "Athletes can view own check-ins"
ON daily_checkins FOR SELECT
USING (
    athlete_id IN (
        SELECT id FROM patients
        WHERE user_id = auth.uid()
           OR email = COALESCE(
               (current_setting('request.jwt.claims', true)::json->>'email'),
               auth.email()
           )
    )
);

-- Athletes can insert their own check-ins
CREATE POLICY "Athletes can insert own check-ins"
ON daily_checkins FOR INSERT
WITH CHECK (
    athlete_id IN (
        SELECT id FROM patients
        WHERE user_id = auth.uid()
           OR email = COALESCE(
               (current_setting('request.jwt.claims', true)::json->>'email'),
               auth.email()
           )
    )
);

-- Athletes can update their own check-ins
CREATE POLICY "Athletes can update own check-ins"
ON daily_checkins FOR UPDATE
USING (
    athlete_id IN (
        SELECT id FROM patients
        WHERE user_id = auth.uid()
           OR email = COALESCE(
               (current_setting('request.jwt.claims', true)::json->>'email'),
               auth.email()
           )
    )
);

-- Therapists can view their patients' check-ins
CREATE POLICY "Therapists can view patient check-ins"
ON daily_checkins FOR SELECT
USING (
    athlete_id IN (
        SELECT patient_id FROM therapist_patients tp
        JOIN therapists t ON t.id = tp.therapist_id
        WHERE t.user_id = auth.uid()
    )
);

-- Demo mode bypass
CREATE POLICY "Demo mode check-ins access"
ON daily_checkins FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM patients p
        WHERE p.id = daily_checkins.athlete_id
        AND p.email = 'demo@ptperformance.com'
    )
);

-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- Upsert daily check-in (insert or update)
CREATE OR REPLACE FUNCTION upsert_daily_checkin(
    p_athlete_id UUID,
    p_date DATE,
    p_sleep_quality INT,
    p_sleep_hours NUMERIC DEFAULT NULL,
    p_soreness INT DEFAULT 1,
    p_soreness_locations TEXT[] DEFAULT NULL,
    p_stress INT DEFAULT 1,
    p_energy INT DEFAULT 5,
    p_pain_score INT DEFAULT NULL,
    p_pain_locations TEXT[] DEFAULT NULL,
    p_mood INT DEFAULT 3,
    p_free_text TEXT DEFAULT NULL
)
RETURNS daily_checkins
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result daily_checkins;
BEGIN
    INSERT INTO daily_checkins (
        athlete_id,
        date,
        sleep_quality,
        sleep_hours,
        soreness,
        soreness_locations,
        stress,
        energy,
        pain_score,
        pain_locations,
        mood,
        free_text,
        completed_at,
        synced_at
    ) VALUES (
        p_athlete_id,
        p_date,
        p_sleep_quality,
        p_sleep_hours,
        p_soreness,
        p_soreness_locations,
        p_stress,
        p_energy,
        p_pain_score,
        p_pain_locations,
        p_mood,
        p_free_text,
        NOW(),
        NOW()
    )
    ON CONFLICT (athlete_id, date)
    DO UPDATE SET
        sleep_quality = EXCLUDED.sleep_quality,
        sleep_hours = EXCLUDED.sleep_hours,
        soreness = EXCLUDED.soreness,
        soreness_locations = EXCLUDED.soreness_locations,
        stress = EXCLUDED.stress,
        energy = EXCLUDED.energy,
        pain_score = EXCLUDED.pain_score,
        pain_locations = EXCLUDED.pain_locations,
        mood = EXCLUDED.mood,
        free_text = EXCLUDED.free_text,
        completed_at = NOW(),
        synced_at = NOW()
    RETURNING * INTO v_result;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION upsert_daily_checkin IS 'Insert or update a daily check-in for an athlete';

-- Get daily check-in for a specific date
CREATE OR REPLACE FUNCTION get_daily_checkin(
    p_athlete_id UUID,
    p_date DATE
)
RETURNS daily_checkins
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result daily_checkins;
BEGIN
    SELECT * INTO v_result
    FROM daily_checkins
    WHERE athlete_id = p_athlete_id
      AND date = p_date;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_daily_checkin IS 'Get a daily check-in for a specific athlete and date';

-- Get check-in history for N days
CREATE OR REPLACE FUNCTION get_checkin_history(
    p_athlete_id UUID,
    p_days INT DEFAULT 7
)
RETURNS SETOF daily_checkins
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM daily_checkins
    WHERE athlete_id = p_athlete_id
      AND date >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    ORDER BY date DESC;
END;
$$;

COMMENT ON FUNCTION get_checkin_history IS 'Get check-in history for the last N days';

-- Get check-in streak
CREATE OR REPLACE FUNCTION get_checkin_streak(
    p_athlete_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_streak INT := 0;
    v_longest_streak INT := 0;
    v_temp_streak INT := 0;
    v_expected_date DATE;
    v_last_date DATE;
    v_total_checkins INT;
    r RECORD;
BEGIN
    -- Get total check-ins
    SELECT COUNT(*) INTO v_total_checkins
    FROM daily_checkins
    WHERE athlete_id = p_athlete_id;

    -- Calculate streaks by iterating through dates
    v_expected_date := CURRENT_DATE;

    FOR r IN (
        SELECT DISTINCT date
        FROM daily_checkins
        WHERE athlete_id = p_athlete_id
        ORDER BY date DESC
    ) LOOP
        IF r.date = v_expected_date THEN
            v_temp_streak := v_temp_streak + 1;
            v_expected_date := v_expected_date - 1;

            -- Update current streak if we're still in sequence from today
            IF v_last_date IS NULL OR r.date = v_last_date - 1 THEN
                v_current_streak := v_temp_streak;
            END IF;
        ELSE
            -- Gap found - reset temp streak
            IF v_temp_streak > v_longest_streak THEN
                v_longest_streak := v_temp_streak;
            END IF;
            v_temp_streak := 1;
            v_expected_date := r.date - 1;
        END IF;

        v_last_date := r.date;
    END LOOP;

    -- Final check for longest streak
    IF v_temp_streak > v_longest_streak THEN
        v_longest_streak := v_temp_streak;
    END IF;

    -- If no check-in today or yesterday, current streak is 0
    IF NOT EXISTS (
        SELECT 1 FROM daily_checkins
        WHERE athlete_id = p_athlete_id
          AND date >= CURRENT_DATE - 1
    ) THEN
        v_current_streak := 0;
    END IF;

    RETURN json_build_object(
        'current_streak', v_current_streak,
        'longest_streak', v_longest_streak,
        'last_check_in_date', v_last_date,
        'total_check_ins', v_total_checkins
    );
END;
$$;

COMMENT ON FUNCTION get_checkin_streak IS 'Calculate check-in streak statistics for an athlete';

-- Calculate readiness score from check-in
CREATE OR REPLACE FUNCTION calculate_checkin_readiness(
    p_sleep_quality INT,
    p_soreness INT,
    p_stress INT,
    p_energy INT,
    p_mood INT,
    p_pain_score INT DEFAULT NULL
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_score NUMERIC;
    v_sleep_component NUMERIC;
    v_energy_component NUMERIC;
    v_soreness_component NUMERIC;
    v_stress_component NUMERIC;
    v_mood_component NUMERIC;
    v_pain_penalty NUMERIC := 0;
BEGIN
    -- Weighted formula:
    -- Sleep Quality: 30% (inverted - higher is better)
    -- Energy: 25% (inverted - higher is better)
    -- Soreness: 20% (lower is better)
    -- Stress: 15% (lower is better)
    -- Mood: 10% (inverted - higher is better)

    v_sleep_component := (p_sleep_quality::NUMERIC / 5.0) * 30.0;
    v_energy_component := (p_energy::NUMERIC / 10.0) * 25.0;
    v_soreness_component := ((11 - p_soreness)::NUMERIC / 10.0) * 20.0;
    v_stress_component := ((11 - p_stress)::NUMERIC / 10.0) * 15.0;
    v_mood_component := (p_mood::NUMERIC / 5.0) * 10.0;

    v_score := v_sleep_component + v_energy_component + v_soreness_component + v_stress_component + v_mood_component;

    -- Pain penalty
    IF p_pain_score IS NOT NULL AND p_pain_score > 0 THEN
        v_pain_penalty := p_pain_score::NUMERIC * 2;
        v_score := v_score - v_pain_penalty;
    END IF;

    -- Clamp to 0-100
    RETURN GREATEST(0, LEAST(100, v_score));
END;
$$;

COMMENT ON FUNCTION calculate_checkin_readiness IS 'Calculate readiness score from check-in metrics';

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update synced_at timestamp when check-in is modified
CREATE OR REPLACE FUNCTION update_checkin_synced_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.synced_at := NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_checkin_synced_at
    BEFORE UPDATE ON daily_checkins
    FOR EACH ROW
    EXECUTE FUNCTION update_checkin_synced_at();

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON daily_checkins TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_daily_checkin TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_checkin TO authenticated;
GRANT EXECUTE ON FUNCTION get_checkin_history TO authenticated;
GRANT EXECUTE ON FUNCTION get_checkin_streak TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_checkin_readiness TO authenticated;

-- Service role for background jobs
GRANT ALL ON daily_checkins TO service_role;
GRANT EXECUTE ON FUNCTION upsert_daily_checkin TO service_role;
GRANT EXECUTE ON FUNCTION get_daily_checkin TO service_role;
GRANT EXECUTE ON FUNCTION get_checkin_history TO service_role;
GRANT EXECUTE ON FUNCTION get_checkin_streak TO service_role;
GRANT EXECUTE ON FUNCTION calculate_checkin_readiness TO service_role;
