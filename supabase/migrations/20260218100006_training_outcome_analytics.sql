-- 20260218100006_training_outcome_analytics.sql
-- Training Outcome Analytics (ACP-981)
-- Correlates training inputs with outcomes: strength gains, body composition,
-- performance. Identifies most effective programs. Provides personalization
-- algorithm inputs.

-- ============================================================================
-- 1. FUNCTION: Get Training Outcomes for a Patient
-- ============================================================================
-- Returns a comprehensive JSONB payload with volume progression, strength
-- gains, pain/RPE trends, adherence, and recovery-performance correlation
-- over a configurable period.

CREATE OR REPLACE FUNCTION get_training_outcomes(
    p_patient_id UUID,
    period_days INT DEFAULT 90
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_start_date DATE := CURRENT_DATE - (period_days || ' days')::INTERVAL;
    v_result JSONB;
    v_volume_progression JSONB;
    v_strength_gains JSONB;
    v_pain_trend JSONB;
    v_rpe_trend JSONB;
    v_adherence JSONB;
    v_recovery_correlation JSONB;
BEGIN
    -- Validate patient exists
    IF NOT EXISTS (SELECT 1 FROM patients WHERE id = p_patient_id) THEN
        RETURN jsonb_build_object(
            'error', 'Patient not found',
            'patient_id', p_patient_id
        );
    END IF;

    -- ========================================================================
    -- VOLUME PROGRESSION: Weekly total volume over the period
    -- Volume = SUM(actual_sets * avg(actual_reps) * actual_load) per week
    -- Sources: exercise_logs (prescribed sessions) + manual sessions
    -- ========================================================================
    WITH weekly_volume AS (
        SELECT
            date_trunc('week', el.logged_at)::date AS week_start,
            COALESCE(
                SUM(
                    el.actual_sets
                    * COALESCE(
                        (SELECT AVG(v) FROM unnest(el.actual_reps) AS v), 0
                      )
                    * COALESCE(el.actual_load, 0)
                ),
                0
            ) AS total_volume,
            COUNT(*) AS log_count
        FROM exercise_logs el
        WHERE el.patient_id = p_patient_id
          AND el.logged_at >= v_start_date
        GROUP BY date_trunc('week', el.logged_at)::date
        ORDER BY week_start
    )
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'week_start', wv.week_start,
            'total_volume', ROUND(wv.total_volume::numeric, 1),
            'log_count', wv.log_count
        ) ORDER BY wv.week_start
    ), '[]'::jsonb)
    INTO v_volume_progression
    FROM weekly_volume wv;

    -- ========================================================================
    -- STRENGTH GAINS: Exercises where max load increased
    -- Compares first-week max load vs last-week max load per exercise
    -- ========================================================================
    WITH exercise_loads AS (
        -- From prescribed sessions: exercise name via session_exercises -> exercise_templates
        SELECT
            et.name AS exercise_name,
            el.actual_load,
            el.logged_at
        FROM exercise_logs el
        JOIN session_exercises se ON se.id = el.session_exercise_id
        JOIN exercise_templates et ON et.id = se.exercise_id
        WHERE el.patient_id = p_patient_id
          AND el.logged_at >= v_start_date
          AND el.actual_load IS NOT NULL
          AND el.actual_load > 0

        UNION ALL

        -- From manual sessions: exercise name stored directly
        SELECT
            mse.exercise_name,
            el.actual_load,
            el.logged_at
        FROM exercise_logs el
        JOIN manual_session_exercises mse ON mse.id = el.manual_session_exercise_id
        WHERE el.patient_id = p_patient_id
          AND el.logged_at >= v_start_date
          AND el.actual_load IS NOT NULL
          AND el.actual_load > 0
    ),
    first_last AS (
        SELECT
            exercise_name,
            -- Max load in the first 25% of the period
            MAX(CASE
                WHEN logged_at < v_start_date + ((period_days * 0.25) || ' days')::INTERVAL
                THEN actual_load
            END) AS start_load,
            -- Max load in the last 25% of the period
            MAX(CASE
                WHEN logged_at >= CURRENT_DATE - ((period_days * 0.25) || ' days')::INTERVAL
                THEN actual_load
            END) AS current_load,
            COUNT(*) AS data_points
        FROM exercise_loads
        GROUP BY exercise_name
        HAVING
            -- Must have data in both windows
            MAX(CASE
                WHEN logged_at < v_start_date + ((period_days * 0.25) || ' days')::INTERVAL
                THEN actual_load
            END) IS NOT NULL
            AND MAX(CASE
                WHEN logged_at >= CURRENT_DATE - ((period_days * 0.25) || ' days')::INTERVAL
                THEN actual_load
            END) IS NOT NULL
    )
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'exercise_name', fl.exercise_name,
            'start_load', ROUND(fl.start_load::numeric, 1),
            'current_load', ROUND(fl.current_load::numeric, 1),
            'pct_change', ROUND(
                ((fl.current_load - fl.start_load) / NULLIF(fl.start_load, 0) * 100)::numeric,
                1
            ),
            'data_points', fl.data_points
        ) ORDER BY ((fl.current_load - fl.start_load) / NULLIF(fl.start_load, 0)) DESC
    ), '[]'::jsonb)
    INTO v_strength_gains
    FROM first_last fl
    WHERE fl.start_load > 0;

    -- ========================================================================
    -- PAIN TREND: Average pain score by week (descending = good)
    -- ========================================================================
    WITH weekly_pain AS (
        SELECT
            date_trunc('week', el.logged_at)::date AS week_start,
            ROUND(AVG(el.pain_score)::numeric, 2) AS avg_pain,
            COUNT(*) AS sample_count
        FROM exercise_logs el
        WHERE el.patient_id = p_patient_id
          AND el.logged_at >= v_start_date
          AND el.pain_score IS NOT NULL
        GROUP BY date_trunc('week', el.logged_at)::date
        ORDER BY week_start
    )
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'week_start', wp.week_start,
            'avg_pain', wp.avg_pain,
            'sample_count', wp.sample_count
        ) ORDER BY wp.week_start
    ), '[]'::jsonb)
    INTO v_pain_trend
    FROM weekly_pain wp;

    -- ========================================================================
    -- RPE TREND: Average RPE by week
    -- ========================================================================
    WITH weekly_rpe AS (
        SELECT
            date_trunc('week', el.logged_at)::date AS week_start,
            ROUND(AVG(el.rpe)::numeric, 2) AS avg_rpe,
            COUNT(*) AS sample_count
        FROM exercise_logs el
        WHERE el.patient_id = p_patient_id
          AND el.logged_at >= v_start_date
          AND el.rpe IS NOT NULL
        GROUP BY date_trunc('week', el.logged_at)::date
        ORDER BY week_start
    )
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'week_start', wr.week_start,
            'avg_rpe', wr.avg_rpe,
            'sample_count', wr.sample_count
        ) ORDER BY wr.week_start
    ), '[]'::jsonb)
    INTO v_rpe_trend
    FROM weekly_rpe wr;

    -- ========================================================================
    -- ADHERENCE: Sessions completed / sessions scheduled per week
    -- Combines prescribed (scheduled_sessions) and manual sessions
    -- ========================================================================
    WITH weekly_adherence AS (
        SELECT
            week_start,
            SUM(completed) AS sessions_completed,
            SUM(scheduled) AS sessions_scheduled
        FROM (
            -- Prescribed scheduled sessions
            SELECT
                date_trunc('week', ss.scheduled_date)::date AS week_start,
                COUNT(*) FILTER (WHERE ss.status = 'completed') AS completed,
                COUNT(*) AS scheduled
            FROM scheduled_sessions ss
            WHERE ss.patient_id = p_patient_id
              AND ss.scheduled_date >= v_start_date
              AND ss.status != 'cancelled'
            GROUP BY date_trunc('week', ss.scheduled_date)::date

            UNION ALL

            -- Completed sessions from programs (sessions linked via phases/programs)
            SELECT
                date_trunc('week', s.completed_at)::date AS week_start,
                COUNT(*) AS completed,
                COUNT(*) AS scheduled
            FROM sessions s
            JOIN phases ph ON ph.id = s.phase_id
            JOIN programs pr ON pr.id = ph.program_id
            WHERE pr.patient_id = p_patient_id
              AND s.completed_at >= v_start_date
              AND s.completed = true
            GROUP BY date_trunc('week', s.completed_at)::date
        ) combined
        GROUP BY week_start
        ORDER BY week_start
    )
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'week_start', wa.week_start,
            'sessions_completed', wa.sessions_completed,
            'sessions_scheduled', wa.sessions_scheduled,
            'adherence_pct', CASE
                WHEN wa.sessions_scheduled > 0
                THEN ROUND((wa.sessions_completed::numeric / wa.sessions_scheduled * 100), 1)
                ELSE 0
            END
        ) ORDER BY wa.week_start
    ), '[]'::jsonb)
    INTO v_adherence
    FROM weekly_adherence wa;

    -- ========================================================================
    -- RECOVERY CORRELATION: Readiness scores vs next-day performance
    -- Correlates daily_readiness.readiness_score with next-day avg RPE
    -- and volume (lower RPE at higher volume after good readiness = positive)
    -- ========================================================================
    WITH readiness_and_performance AS (
        SELECT
            dr.date AS readiness_date,
            dr.readiness_score,
            next_day.avg_rpe AS next_day_avg_rpe,
            next_day.total_volume AS next_day_volume,
            next_day.log_count AS next_day_log_count
        FROM daily_readiness dr
        LEFT JOIN LATERAL (
            SELECT
                AVG(el.rpe) AS avg_rpe,
                SUM(
                    el.actual_sets
                    * COALESCE(
                        (SELECT AVG(v) FROM unnest(el.actual_reps) AS v), 0
                      )
                    * COALESCE(el.actual_load, 0)
                ) AS total_volume,
                COUNT(*) AS log_count
            FROM exercise_logs el
            WHERE el.patient_id = p_patient_id
              AND DATE(el.logged_at) = dr.date + INTERVAL '1 day'
        ) next_day ON true
        WHERE dr.patient_id = p_patient_id
          AND dr.date >= v_start_date
          AND dr.readiness_score IS NOT NULL
          AND next_day.log_count > 0
    ),
    correlation_stats AS (
        SELECT
            COUNT(*) AS data_points,
            ROUND(AVG(readiness_score)::numeric, 1) AS avg_readiness,
            -- Average performance metrics when readiness is above median
            ROUND(AVG(CASE
                WHEN readiness_score >= (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY readiness_score) FROM readiness_and_performance)
                THEN next_day_avg_rpe
            END)::numeric, 2) AS high_readiness_avg_rpe,
            ROUND(AVG(CASE
                WHEN readiness_score < (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY readiness_score) FROM readiness_and_performance)
                THEN next_day_avg_rpe
            END)::numeric, 2) AS low_readiness_avg_rpe,
            ROUND(AVG(CASE
                WHEN readiness_score >= (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY readiness_score) FROM readiness_and_performance)
                THEN next_day_volume
            END)::numeric, 1) AS high_readiness_avg_volume,
            ROUND(AVG(CASE
                WHEN readiness_score < (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY readiness_score) FROM readiness_and_performance)
                THEN next_day_volume
            END)::numeric, 1) AS low_readiness_avg_volume,
            -- Pearson correlation coefficient between readiness and volume
            CASE
                WHEN COUNT(*) >= 5 THEN
                    ROUND(CORR(readiness_score, next_day_volume)::numeric, 3)
                ELSE NULL
            END AS readiness_volume_correlation,
            CASE
                WHEN COUNT(*) >= 5 THEN
                    ROUND(CORR(readiness_score, next_day_avg_rpe)::numeric, 3)
                ELSE NULL
            END AS readiness_rpe_correlation
        FROM readiness_and_performance
    )
    SELECT jsonb_build_object(
        'data_points', cs.data_points,
        'avg_readiness', cs.avg_readiness,
        'high_readiness_avg_rpe', cs.high_readiness_avg_rpe,
        'low_readiness_avg_rpe', cs.low_readiness_avg_rpe,
        'high_readiness_avg_volume', cs.high_readiness_avg_volume,
        'low_readiness_avg_volume', cs.low_readiness_avg_volume,
        'readiness_volume_correlation', cs.readiness_volume_correlation,
        'readiness_rpe_correlation', cs.readiness_rpe_correlation,
        'interpretation', CASE
            WHEN cs.data_points < 5 THEN 'Insufficient data for correlation analysis (need 5+ paired data points)'
            WHEN cs.readiness_volume_correlation > 0.3 THEN 'Positive: Higher readiness scores are associated with higher training volume'
            WHEN cs.readiness_volume_correlation < -0.3 THEN 'Inverse: Higher readiness may lead to overtraining or reduced session quality'
            ELSE 'Neutral: No strong linear relationship detected between readiness and performance'
        END
    )
    INTO v_recovery_correlation
    FROM correlation_stats cs;

    -- ========================================================================
    -- ASSEMBLE FINAL RESULT
    -- ========================================================================
    v_result := jsonb_build_object(
        'patient_id', p_patient_id,
        'period_days', period_days,
        'period_start', v_start_date,
        'period_end', CURRENT_DATE,
        'generated_at', NOW(),
        'volume_progression', v_volume_progression,
        'strength_gains', v_strength_gains,
        'pain_trend', v_pain_trend,
        'rpe_trend', v_rpe_trend,
        'adherence', v_adherence,
        'recovery_correlation', v_recovery_correlation
    );

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_training_outcomes IS
    'Returns comprehensive training outcome analytics for a patient over a configurable period. ACP-981.';


-- ============================================================================
-- 2. FUNCTION: Get Program Effectiveness Rankings
-- ============================================================================
-- Ranks programs by average adherence rate and average strength gain
-- percentage across all patients who completed them.

CREATE OR REPLACE FUNCTION get_program_effectiveness()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
BEGIN
    WITH program_patients AS (
        -- All programs that have at least some completed sessions
        SELECT
            pr.id AS program_id,
            pr.name AS program_name,
            pr.patient_id,
            pr.status AS program_status,
            pr.created_at AS program_created_at
        FROM programs pr
        WHERE EXISTS (
            SELECT 1
            FROM phases ph
            JOIN sessions s ON s.phase_id = ph.id
            WHERE ph.program_id = pr.id
              AND s.completed = true
        )
    ),

    -- Adherence per program-patient: completed sessions / total sessions
    program_adherence AS (
        SELECT
            pp.program_id,
            pp.program_name,
            pp.patient_id,
            COUNT(*) FILTER (WHERE s.completed = true) AS completed_sessions,
            COUNT(*) AS total_sessions,
            CASE
                WHEN COUNT(*) > 0
                THEN ROUND(
                    (COUNT(*) FILTER (WHERE s.completed = true))::numeric / COUNT(*) * 100,
                    1
                )
                ELSE 0
            END AS adherence_pct
        FROM program_patients pp
        JOIN phases ph ON ph.program_id = pp.program_id
        JOIN sessions s ON s.phase_id = ph.id
        GROUP BY pp.program_id, pp.program_name, pp.patient_id
    ),

    -- Strength gains per program-patient
    -- Compare max load in first vs last third of sessions for each exercise
    program_strength AS (
        SELECT
            pp.program_id,
            pp.patient_id,
            et.name AS exercise_name,
            MAX(CASE
                WHEN el.logged_at < pp.program_created_at + INTERVAL '30 days'
                THEN el.actual_load
            END) AS early_max_load,
            MAX(CASE
                WHEN el.logged_at >= (
                    SELECT MAX(s2.completed_at) - INTERVAL '30 days'
                    FROM sessions s2
                    JOIN phases ph2 ON ph2.id = s2.phase_id
                    WHERE ph2.program_id = pp.program_id
                      AND s2.completed = true
                )
                THEN el.actual_load
            END) AS late_max_load
        FROM program_patients pp
        JOIN phases ph ON ph.program_id = pp.program_id
        JOIN sessions s ON s.phase_id = ph.id
        JOIN exercise_logs el ON el.session_id = s.id
            AND el.patient_id = pp.patient_id
            AND el.actual_load IS NOT NULL
            AND el.actual_load > 0
        JOIN session_exercises se ON se.id = el.session_exercise_id
        JOIN exercise_templates et ON et.id = se.exercise_id
        GROUP BY pp.program_id, pp.patient_id, et.name
        HAVING
            MAX(CASE
                WHEN el.logged_at < pp.program_created_at + INTERVAL '30 days'
                THEN el.actual_load
            END) IS NOT NULL
            AND MAX(CASE
                WHEN el.logged_at >= (
                    SELECT MAX(s2.completed_at) - INTERVAL '30 days'
                    FROM sessions s2
                    JOIN phases ph2 ON ph2.id = s2.phase_id
                    WHERE ph2.program_id = pp.program_id
                      AND s2.completed = true
                )
                THEN el.actual_load
            END) IS NOT NULL
    ),

    -- Average strength gain pct per program
    program_strength_agg AS (
        SELECT
            ps.program_id,
            ROUND(
                AVG(
                    (ps.late_max_load - ps.early_max_load) / NULLIF(ps.early_max_load, 0) * 100
                )::numeric,
                1
            ) AS avg_strength_gain_pct,
            COUNT(DISTINCT ps.exercise_name) AS exercises_measured,
            COUNT(DISTINCT ps.patient_id) AS patients_with_strength_data
        FROM program_strength ps
        WHERE ps.early_max_load > 0
        GROUP BY ps.program_id
    ),

    -- Average pain change per program (first vs last month)
    program_pain AS (
        SELECT
            pp.program_id,
            ROUND(AVG(CASE
                WHEN el.logged_at < pp.program_created_at + INTERVAL '30 days'
                THEN el.pain_score
            END)::numeric, 2) AS early_avg_pain,
            ROUND(AVG(CASE
                WHEN el.logged_at >= (
                    SELECT MAX(s2.completed_at) - INTERVAL '30 days'
                    FROM sessions s2
                    JOIN phases ph2 ON ph2.id = s2.phase_id
                    WHERE ph2.program_id = pp.program_id
                      AND s2.completed = true
                )
                THEN el.pain_score
            END)::numeric, 2) AS late_avg_pain
        FROM program_patients pp
        JOIN phases ph ON ph.program_id = pp.program_id
        JOIN sessions s ON s.phase_id = ph.id
        JOIN exercise_logs el ON el.session_id = s.id
            AND el.patient_id = pp.patient_id
            AND el.pain_score IS NOT NULL
        GROUP BY pp.program_id, pp.program_created_at
    ),

    -- Aggregate per program
    program_rankings AS (
        SELECT
            pa.program_id,
            pa.program_name,
            COUNT(DISTINCT pa.patient_id) AS patient_count,
            ROUND(AVG(pa.adherence_pct)::numeric, 1) AS avg_adherence_pct,
            SUM(pa.completed_sessions) AS total_completed_sessions,
            SUM(pa.total_sessions) AS total_sessions,
            psa.avg_strength_gain_pct,
            psa.exercises_measured,
            psa.patients_with_strength_data,
            pp_pain.early_avg_pain,
            pp_pain.late_avg_pain,
            CASE
                WHEN pp_pain.early_avg_pain IS NOT NULL AND pp_pain.late_avg_pain IS NOT NULL
                THEN ROUND((pp_pain.early_avg_pain - pp_pain.late_avg_pain)::numeric, 2)
                ELSE NULL
            END AS pain_reduction
        FROM program_adherence pa
        LEFT JOIN program_strength_agg psa ON psa.program_id = pa.program_id
        LEFT JOIN program_pain pp_pain ON pp_pain.program_id = pa.program_id
        GROUP BY
            pa.program_id,
            pa.program_name,
            psa.avg_strength_gain_pct,
            psa.exercises_measured,
            psa.patients_with_strength_data,
            pp_pain.early_avg_pain,
            pp_pain.late_avg_pain
    )

    SELECT jsonb_build_object(
        'generated_at', NOW(),
        'programs', COALESCE(jsonb_agg(
            jsonb_build_object(
                'program_id', pr.program_id,
                'program_name', pr.program_name,
                'patient_count', pr.patient_count,
                'avg_adherence_pct', pr.avg_adherence_pct,
                'total_completed_sessions', pr.total_completed_sessions,
                'total_sessions', pr.total_sessions,
                'avg_strength_gain_pct', pr.avg_strength_gain_pct,
                'exercises_measured', COALESCE(pr.exercises_measured, 0),
                'patients_with_strength_data', COALESCE(pr.patients_with_strength_data, 0),
                'early_avg_pain', pr.early_avg_pain,
                'late_avg_pain', pr.late_avg_pain,
                'pain_reduction', pr.pain_reduction,
                'effectiveness_score', ROUND((
                    -- Composite score: weighted adherence + strength + pain reduction
                    COALESCE(pr.avg_adherence_pct * 0.4, 0)
                    + COALESCE(LEAST(pr.avg_strength_gain_pct, 50) * 0.8, 0)
                    + COALESCE(pr.pain_reduction * 5, 0)
                )::numeric, 1)
            )
            ORDER BY (
                COALESCE(pr.avg_adherence_pct * 0.4, 0)
                + COALESCE(LEAST(pr.avg_strength_gain_pct, 50) * 0.8, 0)
                + COALESCE(pr.pain_reduction * 5, 0)
            ) DESC
        ), '[]'::jsonb)
    )
    INTO v_result
    FROM program_rankings pr;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_program_effectiveness IS
    'Ranks programs by adherence, strength gains, and pain reduction across all patients. ACP-981.';


-- ============================================================================
-- 3. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Composite index for volume/strength queries by patient and date
CREATE INDEX IF NOT EXISTS idx_exercise_logs_patient_load_date
    ON exercise_logs(patient_id, logged_at DESC)
    WHERE actual_load IS NOT NULL AND actual_load > 0;

-- Index to support joining exercise_logs to session_exercises for exercise names
CREATE INDEX IF NOT EXISTS idx_exercise_logs_session_exercise_id
    ON exercise_logs(session_exercise_id)
    WHERE session_exercise_id IS NOT NULL;

-- Index to support joining exercise_logs to manual_session_exercises
CREATE INDEX IF NOT EXISTS idx_exercise_logs_manual_exercise_id
    ON exercise_logs(manual_session_exercise_id)
    WHERE manual_session_exercise_id IS NOT NULL;


-- ============================================================================
-- 4. GRANT PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_training_outcomes TO authenticated;
GRANT EXECUTE ON FUNCTION get_training_outcomes TO service_role;
GRANT EXECUTE ON FUNCTION get_program_effectiveness TO authenticated;
GRANT EXECUTE ON FUNCTION get_program_effectiveness TO service_role;


-- ============================================================================
-- 5. VALIDATION
-- ============================================================================

DO $$
DECLARE
    fn_training_outcomes_exists BOOLEAN;
    fn_program_effectiveness_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM pg_proc WHERE proname = 'get_training_outcomes'
    ) INTO fn_training_outcomes_exists;

    SELECT EXISTS(
        SELECT 1 FROM pg_proc WHERE proname = 'get_program_effectiveness'
    ) INTO fn_program_effectiveness_exists;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'TRAINING OUTCOME ANALYTICS MIGRATION (ACP-981)';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'get_training_outcomes: %', CASE WHEN fn_training_outcomes_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE 'get_program_effectiveness: %', CASE WHEN fn_program_effectiveness_exists THEN 'CREATED' ELSE 'FAILED' END;
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
END $$;
