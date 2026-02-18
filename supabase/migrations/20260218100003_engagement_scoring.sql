-- Migration: Engagement Scoring (ACP-970)
-- Calculate user engagement scores to identify at-risk users before churn.
--
-- Creates:
-- - Table: engagement_scores (stores calculated scores with component breakdown)
-- - Function: calculate_engagement_score(p_patient_id UUID) — single patient scoring
-- - Function: calculate_all_engagement_scores() — batch calculation for all active patients
-- - Function: get_at_risk_users(threshold INT) — users with scores below threshold
--
-- Score Components (weighted composite, 0-100):
-- - workout_frequency (40%): sessions completed in last 14 days / expected sessions
-- - streak_consistency (20%): current_streak / 14 (capped at 1.0)
-- - feature_breadth (20%): distinct feature types used in 14 days / 4
-- - recency (20%): days since last activity (0 days = 1.0, 14+ days = 0.0, linear decay)
--
-- Risk Levels:
-- - 'high_risk': score 0-29
-- - 'at_risk': score 30-49
-- - 'moderate': score 50-69
-- - 'engaged': score 70-89
-- - 'highly_engaged': score 90-100

-- =============================================================================
-- ENGAGEMENT_SCORES TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS engagement_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    score INT NOT NULL CHECK (score >= 0 AND score <= 100),
    components JSONB NOT NULL DEFAULT '{}',
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    risk_level TEXT NOT NULL CHECK (risk_level IN ('high_risk', 'at_risk', 'moderate', 'engaged', 'highly_engaged'))
);

-- Index for efficient lookups by patient (most recent first)
CREATE INDEX IF NOT EXISTS idx_engagement_scores_patient_id
ON engagement_scores(patient_id, calculated_at DESC);

-- Index for at-risk queries
CREATE INDEX IF NOT EXISTS idx_engagement_scores_risk_level
ON engagement_scores(risk_level, score);

-- Index for latest score per patient (used in get_at_risk_users)
CREATE INDEX IF NOT EXISTS idx_engagement_scores_calculated_at
ON engagement_scores(calculated_at DESC);

-- Enable RLS
ALTER TABLE engagement_scores ENABLE ROW LEVEL SECURITY;

-- RLS policies: patients can read their own scores, service role can write
CREATE POLICY "Patients can view own engagement scores"
ON engagement_scores FOR SELECT
USING (
    patient_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM patients p WHERE p.id = engagement_scores.patient_id AND p.user_id = auth.uid()
    )
);

CREATE POLICY "Service role can manage engagement scores"
ON engagement_scores FOR ALL
USING (auth.role() = 'service_role');

-- =============================================================================
-- CALCULATE_ENGAGEMENT_SCORE RPC
-- =============================================================================
-- Calculates a weighted composite engagement score for a single patient.
-- Returns the calculated score row as JSONB.

CREATE OR REPLACE FUNCTION calculate_engagement_score(p_patient_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_workout_frequency FLOAT := 0;
    v_streak_consistency FLOAT := 0;
    v_feature_breadth FLOAT := 0;
    v_recency FLOAT := 0;
    v_score INT;
    v_risk_level TEXT;
    v_components JSONB;
    v_result_id UUID;
    v_now TIMESTAMPTZ := NOW();
    v_14_days_ago TIMESTAMPTZ := NOW() - INTERVAL '14 days';
    v_14_days_ago_date DATE := (NOW() - INTERVAL '14 days')::DATE;
    v_session_count INT := 0;
    v_expected_sessions INT := 7; -- Expected ~1 session every 2 days over 14 days
    v_current_streak INT := 0;
    v_feature_count INT := 0;
    v_days_since_last FLOAT := 14;
    v_last_activity TIMESTAMPTZ;
BEGIN
    -- Verify patient exists
    IF NOT EXISTS (SELECT 1 FROM patients WHERE id = p_patient_id) THEN
        RETURN jsonb_build_object('error', 'Patient not found', 'patient_id', p_patient_id);
    END IF;

    -- =========================================================================
    -- COMPONENT 1: Workout Frequency (40% weight)
    -- Count completed sessions (scheduled + manual) in last 14 days
    -- =========================================================================

    -- Count completed scheduled sessions
    SELECT COUNT(*) INTO v_session_count
    FROM scheduled_sessions
    WHERE patient_id = p_patient_id
      AND status = 'completed'
      AND scheduled_date >= v_14_days_ago_date;

    -- Add completed manual sessions
    SELECT v_session_count + COUNT(*) INTO v_session_count
    FROM manual_sessions
    WHERE patient_id = p_patient_id
      AND completed = TRUE
      AND completed_at >= v_14_days_ago;

    -- Calculate ratio (capped at 1.0)
    v_workout_frequency := LEAST(1.0, v_session_count::FLOAT / GREATEST(v_expected_sessions, 1));

    -- =========================================================================
    -- COMPONENT 2: Streak Consistency (20% weight)
    -- Current streak / 14, capped at 1.0
    -- =========================================================================

    SELECT COALESCE(MAX(current_streak), 0) INTO v_current_streak
    FROM streak_records
    WHERE patient_id = p_patient_id;

    v_streak_consistency := LEAST(1.0, v_current_streak::FLOAT / 14.0);

    -- =========================================================================
    -- COMPONENT 3: Feature Breadth (20% weight)
    -- Count distinct feature types used in last 14 days:
    --   1. daily_readiness
    --   2. exercise_logs
    --   3. manual_sessions
    --   4. streak (streak_history)
    -- Ratio = count / 4
    -- =========================================================================

    SELECT COUNT(*) INTO v_feature_count FROM (
        -- Check daily_readiness usage
        SELECT 'readiness' AS feature
        WHERE EXISTS (
            SELECT 1 FROM daily_readiness
            WHERE patient_id = p_patient_id
              AND date >= v_14_days_ago_date
        )

        UNION ALL

        -- Check exercise_logs usage
        SELECT 'exercise_logs' AS feature
        WHERE EXISTS (
            SELECT 1 FROM exercise_logs
            WHERE patient_id = p_patient_id
              AND logged_at >= v_14_days_ago
        )

        UNION ALL

        -- Check manual_sessions usage
        SELECT 'manual_sessions' AS feature
        WHERE EXISTS (
            SELECT 1 FROM manual_sessions
            WHERE patient_id = p_patient_id
              AND created_at >= v_14_days_ago
        )

        UNION ALL

        -- Check streak activity
        SELECT 'streak' AS feature
        WHERE EXISTS (
            SELECT 1 FROM streak_history
            WHERE patient_id = p_patient_id
              AND activity_date >= v_14_days_ago_date
        )
    ) AS features;

    v_feature_breadth := v_feature_count::FLOAT / 4.0;

    -- =========================================================================
    -- COMPONENT 4: Recency (20% weight)
    -- Days since last activity: 0 days = 1.0, 14+ days = 0.0, linear decay
    -- =========================================================================

    -- Find most recent activity across all tracked tables
    SELECT MAX(last_ts) INTO v_last_activity FROM (
        SELECT MAX(scheduled_date::TIMESTAMPTZ) AS last_ts
        FROM scheduled_sessions
        WHERE patient_id = p_patient_id AND status = 'completed'

        UNION ALL

        SELECT MAX(completed_at) AS last_ts
        FROM manual_sessions
        WHERE patient_id = p_patient_id AND completed = TRUE

        UNION ALL

        SELECT MAX(logged_at) AS last_ts
        FROM exercise_logs
        WHERE patient_id = p_patient_id

        UNION ALL

        SELECT MAX(date::TIMESTAMPTZ) AS last_ts
        FROM daily_readiness
        WHERE patient_id = p_patient_id

        UNION ALL

        SELECT MAX(activity_date::TIMESTAMPTZ) AS last_ts
        FROM streak_history
        WHERE patient_id = p_patient_id
    ) AS latest;

    IF v_last_activity IS NOT NULL THEN
        v_days_since_last := EXTRACT(EPOCH FROM (v_now - v_last_activity)) / 86400.0;
        v_recency := GREATEST(0.0, 1.0 - (v_days_since_last / 14.0));
    ELSE
        v_recency := 0.0;
    END IF;

    -- =========================================================================
    -- CALCULATE FINAL SCORE
    -- =========================================================================

    v_score := ROUND(
        (v_workout_frequency * 0.40 +
         v_streak_consistency * 0.20 +
         v_feature_breadth * 0.20 +
         v_recency * 0.20) * 100
    )::INT;

    -- Clamp to 0-100
    v_score := LEAST(100, GREATEST(0, v_score));

    -- =========================================================================
    -- DETERMINE RISK LEVEL
    -- =========================================================================

    v_risk_level := CASE
        WHEN v_score >= 90 THEN 'highly_engaged'
        WHEN v_score >= 70 THEN 'engaged'
        WHEN v_score >= 50 THEN 'moderate'
        WHEN v_score >= 30 THEN 'at_risk'
        ELSE 'high_risk'
    END;

    -- =========================================================================
    -- BUILD COMPONENTS JSONB
    -- =========================================================================

    v_components := jsonb_build_object(
        'workout_frequency', jsonb_build_object(
            'raw_value', v_workout_frequency,
            'weight', 0.40,
            'weighted_value', ROUND((v_workout_frequency * 0.40 * 100)::NUMERIC, 1),
            'sessions_completed', v_session_count,
            'expected_sessions', v_expected_sessions
        ),
        'streak_consistency', jsonb_build_object(
            'raw_value', v_streak_consistency,
            'weight', 0.20,
            'weighted_value', ROUND((v_streak_consistency * 0.20 * 100)::NUMERIC, 1),
            'current_streak', v_current_streak
        ),
        'feature_breadth', jsonb_build_object(
            'raw_value', v_feature_breadth,
            'weight', 0.20,
            'weighted_value', ROUND((v_feature_breadth * 0.20 * 100)::NUMERIC, 1),
            'features_used', v_feature_count,
            'features_total', 4
        ),
        'recency', jsonb_build_object(
            'raw_value', ROUND(v_recency::NUMERIC, 3),
            'weight', 0.20,
            'weighted_value', ROUND((v_recency * 0.20 * 100)::NUMERIC, 1),
            'days_since_last_activity', ROUND(v_days_since_last::NUMERIC, 1)
        )
    );

    -- =========================================================================
    -- INSERT SCORE RECORD
    -- =========================================================================

    INSERT INTO engagement_scores (patient_id, score, components, calculated_at, risk_level)
    VALUES (p_patient_id, v_score, v_components, v_now, v_risk_level)
    RETURNING id INTO v_result_id;

    RETURN jsonb_build_object(
        'id', v_result_id,
        'patient_id', p_patient_id,
        'score', v_score,
        'risk_level', v_risk_level,
        'components', v_components,
        'calculated_at', v_now
    );
END;
$$;

GRANT EXECUTE ON FUNCTION calculate_engagement_score(UUID) TO authenticated;

COMMENT ON FUNCTION calculate_engagement_score IS
'Calculate engagement score for a single patient. Weighted composite: workout_frequency (40%), streak_consistency (20%), feature_breadth (20%), recency (20%). Score range 0-100.';

-- =============================================================================
-- CALCULATE_ALL_ENGAGEMENT_SCORES RPC
-- =============================================================================
-- Batch calculation for all active patients.
-- Returns a JSON array of results.

CREATE OR REPLACE FUNCTION calculate_all_engagement_scores()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_patient RECORD;
    v_result JSONB;
    v_results JSONB := '[]'::JSONB;
    v_success_count INT := 0;
    v_error_count INT := 0;
    v_start_time TIMESTAMPTZ := NOW();
BEGIN
    -- Iterate over all patients
    FOR v_patient IN
        SELECT id FROM patients
        ORDER BY id
    LOOP
        BEGIN
            v_result := calculate_engagement_score(v_patient.id);

            -- Check if the result contains an error
            IF v_result ? 'error' THEN
                v_error_count := v_error_count + 1;
            ELSE
                v_success_count := v_success_count + 1;
            END IF;

            v_results := v_results || jsonb_build_array(v_result);

        EXCEPTION WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_results := v_results || jsonb_build_array(jsonb_build_object(
                'patient_id', v_patient.id,
                'error', SQLERRM
            ));
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'total_patients', v_success_count + v_error_count,
        'successful', v_success_count,
        'errors', v_error_count,
        'execution_time_ms', EXTRACT(EPOCH FROM (NOW() - v_start_time)) * 1000,
        'results', v_results
    );
END;
$$;

GRANT EXECUTE ON FUNCTION calculate_all_engagement_scores() TO authenticated;

COMMENT ON FUNCTION calculate_all_engagement_scores IS
'Batch calculate engagement scores for all active patients. Returns summary with per-patient results.';

-- =============================================================================
-- GET_AT_RISK_USERS RPC
-- =============================================================================
-- Returns users whose most recent engagement score is below the threshold.

CREATE OR REPLACE FUNCTION get_at_risk_users(threshold INT DEFAULT 30)
RETURNS TABLE (
    patient_id UUID,
    score INT,
    risk_level TEXT,
    components JSONB,
    calculated_at TIMESTAMPTZ,
    days_since_last_activity FLOAT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH latest_scores AS (
        SELECT DISTINCT ON (es.patient_id)
            es.patient_id,
            es.score,
            es.risk_level,
            es.components,
            es.calculated_at
        FROM engagement_scores es
        ORDER BY es.patient_id, es.calculated_at DESC
    )
    SELECT
        ls.patient_id,
        ls.score,
        ls.risk_level,
        ls.components,
        ls.calculated_at,
        COALESCE((ls.components->'recency'->>'days_since_last_activity')::FLOAT, 14.0) AS days_since_last_activity
    FROM latest_scores ls
    WHERE ls.score < threshold
    ORDER BY ls.score ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_at_risk_users(INT) TO authenticated;

COMMENT ON FUNCTION get_at_risk_users IS
'Get users whose latest engagement score is below the given threshold (default 30). Returns patient details sorted by score ascending (most at-risk first).';
