-- ============================================================================
-- HEALTH INTELLIGENCE VIEWS AND RPC FUNCTIONS FOR iOS APP
-- ============================================================================
-- This migration creates views and RPC functions optimized for iOS app consumption.
-- All views and functions are designed to be efficient for mobile use cases,
-- returning pre-computed data that minimizes client-side processing.
--
-- Views:
--   - v_patient_lab_summary: Latest lab results with optimal/normal/concern status
--   - v_patient_recovery_weekly: Weekly recovery stats (sauna/cold/sessions)
--   - v_patient_fasting_current: Current fasting state and stats
--   - v_patient_supplement_stack: Active supplement stack with timing schedule
--   - v_patient_health_score: Composite health score based on all factors
--
-- RPC Functions:
--   - start_fasting_session: Start a new fast
--   - end_fasting_session: End current fast, calculate actual hours
--   - log_recovery_session: Quick log for recovery activities
--   - log_supplement_dose: Log a supplement dose
--   - get_daily_health_briefing: AI-ready data aggregation for daily briefing
--   - get_lab_analysis_data: Data package for AI analysis of lab results
--   - check_supplement_interactions: Check for interactions between supplements
--
-- Computed/Derived Functions:
--   - calculate_recovery_score: Score based on sauna/cold exposure
--   - calculate_fasting_streak: Consecutive days of fasting
--   - calculate_supplement_adherence_rate: Percentage of supplements taken
--
-- Date: 2026-02-02
-- ============================================================================

BEGIN;

-- ============================================================================
-- HELPER FUNCTION: Get current user's patient ID
-- ============================================================================
-- This function is used by views and RPC functions to get the patient_id
-- for the currently authenticated user. Supports demo mode and email fallback.

CREATE OR REPLACE FUNCTION get_current_user_patient_id()
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_patient_id UUID;
    v_email TEXT;
BEGIN
    -- First try: Direct user_id match
    SELECT id INTO v_patient_id
    FROM patients
    WHERE user_id = auth.uid();

    IF v_patient_id IS NOT NULL THEN
        RETURN v_patient_id;
    END IF;

    -- Second try: Email match (fallback for legacy users)
    v_email := auth.jwt() ->> 'email';
    IF v_email IS NOT NULL THEN
        SELECT id INTO v_patient_id
        FROM patients
        WHERE email = v_email;

        IF v_patient_id IS NOT NULL THEN
            RETURN v_patient_id;
        END IF;
    END IF;

    -- Final fallback: Demo patient if nothing else matches
    -- This allows unauthenticated or demo mode access
    RETURN '00000000-0000-0000-0000-000000000001'::uuid;
END;
$$;

COMMENT ON FUNCTION get_current_user_patient_id() IS
    'Returns the patient_id for the currently authenticated user. Falls back to demo patient if no match found.';

-- ============================================================================
-- VIEW: v_patient_lab_summary
-- ============================================================================
-- Latest lab results with status indicators (optimal/normal/concern)
-- Each row represents a biomarker from the patient's most recent lab results.

CREATE OR REPLACE VIEW v_patient_lab_summary AS
WITH latest_labs AS (
    SELECT DISTINCT ON (bv.biomarker_type)
        lr.patient_id,
        lr.id AS lab_result_id,
        lr.test_date,
        lr.provider,
        bv.biomarker_type,
        bv.value,
        bv.unit,
        bv.is_flagged,
        brr.name AS biomarker_name,
        brr.category,
        brr.optimal_low,
        brr.optimal_high,
        brr.normal_low,
        brr.normal_high,
        brr.description AS biomarker_description
    FROM lab_results lr
    JOIN biomarker_values bv ON bv.lab_result_id = lr.id
    LEFT JOIN biomarker_reference_ranges brr ON brr.biomarker_type = bv.biomarker_type
    ORDER BY bv.biomarker_type, lr.test_date DESC
)
SELECT
    patient_id,
    lab_result_id,
    test_date,
    provider,
    biomarker_type,
    biomarker_name,
    category,
    value,
    unit,
    is_flagged,
    optimal_low,
    optimal_high,
    normal_low,
    normal_high,
    biomarker_description,
    -- Status calculation: optimal, normal, or concern
    CASE
        WHEN value IS NULL THEN 'unknown'
        WHEN optimal_low IS NOT NULL AND optimal_high IS NOT NULL
             AND value >= optimal_low AND value <= optimal_high THEN 'optimal'
        WHEN normal_low IS NOT NULL AND normal_high IS NOT NULL
             AND value >= normal_low AND value <= normal_high THEN 'normal'
        ELSE 'concern'
    END AS status,
    -- Direction indicator for values outside optimal
    CASE
        WHEN value IS NULL THEN NULL
        WHEN optimal_low IS NOT NULL AND value < optimal_low THEN 'low'
        WHEN optimal_high IS NOT NULL AND value > optimal_high THEN 'high'
        ELSE NULL
    END AS direction,
    -- Days since test
    (CURRENT_DATE - test_date) AS days_since_test
FROM latest_labs;

COMMENT ON VIEW v_patient_lab_summary IS
    'Latest lab results per biomarker with optimal/normal/concern status for iOS display. Use RLS via patient_id.';

-- ============================================================================
-- VIEW: v_patient_recovery_weekly
-- ============================================================================
-- Weekly aggregated recovery stats for the past 12 weeks.
-- Shows sauna minutes, cold minutes, and total sessions per week.

CREATE OR REPLACE VIEW v_patient_recovery_weekly AS
WITH weeks AS (
    -- Generate the past 12 weeks
    SELECT generate_series(
        date_trunc('week', CURRENT_DATE - interval '11 weeks'),
        date_trunc('week', CURRENT_DATE),
        '1 week'::interval
    )::date AS week_start
),
recovery_by_week AS (
    SELECT
        rs.patient_id,
        date_trunc('week', rs.logged_at)::date AS week_start,
        -- Sauna totals
        COALESCE(SUM(CASE
            WHEN rs.session_type IN ('sauna_traditional', 'sauna_infrared', 'sauna_steam')
            THEN rs.duration_minutes
        END), 0) AS sauna_minutes,
        -- Cold totals
        COALESCE(SUM(CASE
            WHEN rs.session_type IN ('cold_plunge', 'cold_shower', 'ice_bath')
            THEN rs.duration_minutes
        END), 0) AS cold_minutes,
        -- Contrast totals
        COALESCE(SUM(CASE
            WHEN rs.session_type = 'contrast'
            THEN rs.duration_minutes
        END), 0) AS contrast_minutes,
        -- Session counts by type
        COUNT(*) FILTER (WHERE rs.session_type IN ('sauna_traditional', 'sauna_infrared', 'sauna_steam')) AS sauna_sessions,
        COUNT(*) FILTER (WHERE rs.session_type IN ('cold_plunge', 'cold_shower', 'ice_bath')) AS cold_sessions,
        COUNT(*) FILTER (WHERE rs.session_type = 'contrast') AS contrast_sessions,
        COUNT(*) AS total_sessions
    FROM recovery_sessions rs
    WHERE rs.logged_at >= CURRENT_DATE - interval '12 weeks'
    GROUP BY rs.patient_id, date_trunc('week', rs.logged_at)
)
SELECT
    p.id AS patient_id,
    w.week_start,
    w.week_start + interval '6 days' AS week_end,
    COALESCE(rbw.sauna_minutes, 0)::integer AS sauna_minutes,
    COALESCE(rbw.cold_minutes, 0)::integer AS cold_minutes,
    COALESCE(rbw.contrast_minutes, 0)::integer AS contrast_minutes,
    COALESCE(rbw.sauna_sessions, 0)::integer AS sauna_sessions,
    COALESCE(rbw.cold_sessions, 0)::integer AS cold_sessions,
    COALESCE(rbw.contrast_sessions, 0)::integer AS contrast_sessions,
    COALESCE(rbw.total_sessions, 0)::integer AS total_sessions,
    -- Weekly targets (Huberman-inspired: 57 min sauna, 11 min cold per week)
    ROUND(COALESCE(rbw.sauna_minutes, 0)::numeric / 57.0 * 100, 1) AS sauna_target_pct,
    ROUND(COALESCE(rbw.cold_minutes, 0)::numeric / 11.0 * 100, 1) AS cold_target_pct
FROM patients p
CROSS JOIN weeks w
LEFT JOIN recovery_by_week rbw
    ON rbw.patient_id = p.id
    AND rbw.week_start = w.week_start;

COMMENT ON VIEW v_patient_recovery_weekly IS
    'Weekly recovery stats for past 12 weeks with target percentages. Filter by patient_id.';

-- ============================================================================
-- VIEW: v_patient_fasting_current
-- ============================================================================
-- Current fasting state and recent stats for the patient.
-- Shows active fast (if any) and summary statistics.

CREATE OR REPLACE VIEW v_patient_fasting_current AS
WITH current_fast AS (
    SELECT
        patient_id,
        id AS fast_id,
        started_at,
        planned_hours,
        protocol_type,
        notes,
        -- Calculate current fasting hours
        EXTRACT(EPOCH FROM (now() - started_at)) / 3600.0 AS current_hours,
        -- Progress percentage
        ROUND(
            (EXTRACT(EPOCH FROM (now() - started_at)) / 3600.0 / planned_hours * 100)::numeric,
            1
        ) AS progress_pct,
        -- Estimated completion time
        started_at + (planned_hours || ' hours')::interval AS estimated_end_at
    FROM fasting_logs
    WHERE ended_at IS NULL
),
fasting_stats AS (
    SELECT
        patient_id,
        COUNT(*) AS total_fasts_30d,
        COUNT(*) FILTER (WHERE completed) AS completed_fasts_30d,
        ROUND(AVG(actual_hours) FILTER (WHERE completed), 1) AS avg_duration_hours,
        MAX(actual_hours) AS longest_fast_hours,
        SUM(actual_hours) FILTER (WHERE completed) AS total_fasting_hours_30d
    FROM fasting_logs
    WHERE started_at >= CURRENT_DATE - interval '30 days'
    GROUP BY patient_id
),
streak_calc AS (
    SELECT
        patient_id,
        COUNT(*) AS current_streak
    FROM (
        SELECT
            patient_id,
            started_at::date AS fast_date,
            ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY started_at::date DESC) AS rn
        FROM fasting_logs
        WHERE completed = true
    ) s
    WHERE fast_date = CURRENT_DATE - (rn - 1)::integer
    GROUP BY patient_id
)
SELECT
    p.id AS patient_id,
    -- Current fast info (NULL if not fasting)
    cf.fast_id AS current_fast_id,
    cf.started_at AS current_fast_started_at,
    cf.planned_hours AS current_fast_planned_hours,
    ROUND(cf.current_hours::numeric, 2) AS current_fast_hours,
    cf.progress_pct AS current_fast_progress_pct,
    cf.estimated_end_at AS current_fast_estimated_end,
    cf.protocol_type AS current_fast_protocol,
    -- Is currently fasting?
    (cf.fast_id IS NOT NULL) AS is_fasting,
    -- 30-day stats
    COALESCE(fs.total_fasts_30d, 0)::integer AS total_fasts_30d,
    COALESCE(fs.completed_fasts_30d, 0)::integer AS completed_fasts_30d,
    COALESCE(fs.avg_duration_hours, 0)::numeric AS avg_duration_hours,
    COALESCE(fs.longest_fast_hours, 0)::numeric AS longest_fast_hours,
    COALESCE(fs.total_fasting_hours_30d, 0)::numeric AS total_fasting_hours_30d,
    -- Streak
    COALESCE(sc.current_streak, 0)::integer AS current_streak,
    -- Completion rate
    CASE
        WHEN COALESCE(fs.total_fasts_30d, 0) > 0
        THEN ROUND(COALESCE(fs.completed_fasts_30d, 0)::numeric / fs.total_fasts_30d * 100, 1)
        ELSE 0
    END AS completion_rate_30d
FROM patients p
LEFT JOIN current_fast cf ON cf.patient_id = p.id
LEFT JOIN fasting_stats fs ON fs.patient_id = p.id
LEFT JOIN streak_calc sc ON sc.patient_id = p.id;

COMMENT ON VIEW v_patient_fasting_current IS
    'Current fasting state and 30-day stats including streak. Filter by patient_id.';

-- ============================================================================
-- VIEW: v_patient_supplement_stack
-- ============================================================================
-- Active supplement stack with timing schedule for the patient.
-- Returns all active supplements with dosage and timing information.

CREATE OR REPLACE VIEW v_patient_supplement_stack AS
WITH today_doses AS (
    SELECT
        sl.patient_id,
        sl.supplement_id,
        COUNT(*) AS doses_today,
        MAX(sl.logged_at) AS last_dose_at
    FROM supplement_logs sl
    WHERE (sl.logged_at AT TIME ZONE 'UTC')::date = CURRENT_DATE
    GROUP BY sl.patient_id, sl.supplement_id
),
week_adherence AS (
    SELECT
        pss.patient_id,
        pss.supplement_id,
        COUNT(sl.id) AS doses_this_week,
        CASE
            WHEN pss.frequency = 'daily' THEN 7
            WHEN pss.frequency = 'twice daily' THEN 14
            WHEN pss.frequency = 'three times daily' THEN 21
            WHEN pss.frequency = 'every other day' THEN 4
            ELSE 7
        END AS expected_doses_week
    FROM patient_supplement_stacks pss
    LEFT JOIN supplement_logs sl
        ON sl.patient_id = pss.patient_id
        AND sl.supplement_id = pss.supplement_id
        AND sl.logged_at >= CURRENT_DATE - interval '7 days'
    WHERE pss.is_active = true
    GROUP BY pss.patient_id, pss.supplement_id, pss.frequency
)
SELECT
    pss.patient_id,
    pss.id AS stack_entry_id,
    pss.supplement_id,
    s.name AS supplement_name,
    s.category AS supplement_category,
    s.description AS supplement_description,
    s.evidence_rating,
    pss.dosage,
    pss.dosage_unit,
    pss.frequency,
    pss.timing,
    pss.started_at,
    pss.notes,
    -- Today's doses
    COALESCE(td.doses_today, 0)::integer AS doses_today,
    td.last_dose_at,
    -- Expected doses today based on frequency
    CASE
        WHEN pss.frequency = 'daily' THEN 1
        WHEN pss.frequency = 'twice daily' THEN 2
        WHEN pss.frequency = 'three times daily' THEN 3
        WHEN pss.frequency = 'every other day' THEN
            CASE WHEN (CURRENT_DATE - pss.started_at::date) % 2 = 0 THEN 1 ELSE 0 END
        ELSE 1
    END::integer AS expected_doses_today,
    -- Is due for next dose?
    CASE
        WHEN pss.frequency = 'daily' AND COALESCE(td.doses_today, 0) < 1 THEN true
        WHEN pss.frequency = 'twice daily' AND COALESCE(td.doses_today, 0) < 2 THEN true
        WHEN pss.frequency = 'three times daily' AND COALESCE(td.doses_today, 0) < 3 THEN true
        ELSE false
    END AS is_due,
    -- Weekly adherence rate
    ROUND(
        COALESCE(wa.doses_this_week, 0)::numeric /
        NULLIF(wa.expected_doses_week, 0) * 100,
        1
    ) AS weekly_adherence_pct,
    -- Days on supplement
    (CURRENT_DATE - pss.started_at::date) AS days_on_supplement,
    -- Timing display helper
    CASE pss.timing
        WHEN 'morning' THEN 'Take in morning'
        WHEN 'afternoon' THEN 'Take in afternoon'
        WHEN 'evening' THEN 'Take in evening'
        WHEN 'pre_workout' THEN 'Take before workout'
        WHEN 'post_workout' THEN 'Take after workout'
        WHEN 'with_meal' THEN 'Take with meal'
        WHEN 'before_bed' THEN 'Take before bed'
        ELSE 'Take as directed'
    END AS timing_instruction
FROM patient_supplement_stacks pss
JOIN supplements s ON s.id = pss.supplement_id
LEFT JOIN today_doses td ON td.patient_id = pss.patient_id AND td.supplement_id = pss.supplement_id
LEFT JOIN week_adherence wa ON wa.patient_id = pss.patient_id AND wa.supplement_id = pss.supplement_id
WHERE pss.is_active = true;

COMMENT ON VIEW v_patient_supplement_stack IS
    'Active supplement stack with timing, dosage, and adherence stats. Filter by patient_id.';

-- ============================================================================
-- VIEW: v_patient_health_score
-- ============================================================================
-- Composite health score based on all health factors.
-- Returns a score from 0-100 with component breakdowns.

CREATE OR REPLACE VIEW v_patient_health_score AS
WITH lab_score AS (
    -- Score based on percentage of biomarkers in optimal range
    SELECT
        lr.patient_id,
        COUNT(*) AS total_biomarkers,
        COUNT(*) FILTER (WHERE
            bv.value >= brr.optimal_low AND bv.value <= brr.optimal_high
        ) AS optimal_count,
        COUNT(*) FILTER (WHERE
            bv.value >= brr.normal_low AND bv.value <= brr.normal_high
            AND NOT (bv.value >= brr.optimal_low AND bv.value <= brr.optimal_high)
        ) AS normal_count,
        -- Lab score: optimal = 100%, normal = 70%, concern = 0%
        ROUND(
            (COUNT(*) FILTER (WHERE bv.value >= brr.optimal_low AND bv.value <= brr.optimal_high) * 100.0 +
             COUNT(*) FILTER (WHERE bv.value >= brr.normal_low AND bv.value <= brr.normal_high
                AND NOT (bv.value >= brr.optimal_low AND bv.value <= brr.optimal_high)) * 70.0) /
            NULLIF(COUNT(*), 0),
            1
        ) AS score
    FROM lab_results lr
    JOIN biomarker_values bv ON bv.lab_result_id = lr.id
    JOIN biomarker_reference_ranges brr ON brr.biomarker_type = bv.biomarker_type
    WHERE lr.test_date = (
        SELECT MAX(test_date) FROM lab_results WHERE patient_id = lr.patient_id
    )
    GROUP BY lr.patient_id
),
recovery_score AS (
    -- Score based on meeting weekly recovery targets
    SELECT
        patient_id,
        -- Sauna target: 57 min/week (capped at 100%)
        LEAST(SUM(CASE
            WHEN session_type IN ('sauna_traditional', 'sauna_infrared', 'sauna_steam')
            THEN duration_minutes
        END)::numeric / 57.0 * 100, 100) AS sauna_score,
        -- Cold target: 11 min/week (capped at 100%)
        LEAST(SUM(CASE
            WHEN session_type IN ('cold_plunge', 'cold_shower', 'ice_bath')
            THEN duration_minutes
        END)::numeric / 11.0 * 100, 100) AS cold_score
    FROM recovery_sessions
    WHERE logged_at >= CURRENT_DATE - interval '7 days'
    GROUP BY patient_id
),
fasting_score AS (
    -- Score based on fasting consistency (completing fasts)
    SELECT
        patient_id,
        CASE
            WHEN COUNT(*) > 0
            THEN ROUND(COUNT(*) FILTER (WHERE completed)::numeric / COUNT(*) * 100, 1)
            ELSE 0
        END AS score
    FROM fasting_logs
    WHERE started_at >= CURRENT_DATE - interval '30 days'
    GROUP BY patient_id
),
supplement_adherence_per_supplement AS (
    -- First calculate adherence per supplement (avoids nested aggregate)
    SELECT
        pss.patient_id,
        pss.supplement_id,
        pss.frequency,
        COUNT(sl.id) AS doses_logged,
        CASE
            WHEN pss.frequency = 'daily' THEN 7
            WHEN pss.frequency = 'twice daily' THEN 14
            WHEN pss.frequency = 'three times daily' THEN 21
            ELSE 7
        END AS expected_doses
    FROM patient_supplement_stacks pss
    LEFT JOIN supplement_logs sl
        ON sl.patient_id = pss.patient_id
        AND sl.supplement_id = pss.supplement_id
        AND sl.logged_at >= CURRENT_DATE - interval '7 days'
    WHERE pss.is_active = true
    GROUP BY pss.patient_id, pss.supplement_id, pss.frequency
),
supplement_score AS (
    -- Then average across all supplements for the patient
    SELECT
        patient_id,
        ROUND(AVG(LEAST(doses_logged::numeric / NULLIF(expected_doses, 0) * 100, 100)), 1) AS score
    FROM supplement_adherence_per_supplement
    GROUP BY patient_id
)
SELECT
    p.id AS patient_id,
    -- Component scores (NULL if no data)
    COALESCE(ls.score, NULL) AS lab_score,
    ROUND((COALESCE(rs.sauna_score, 0) + COALESCE(rs.cold_score, 0)) / 2, 1) AS recovery_score,
    COALESCE(fs.score, NULL) AS fasting_score,
    COALESCE(ss.score, NULL) AS supplement_score,
    -- Component details
    ls.total_biomarkers,
    ls.optimal_count AS biomarkers_optimal,
    ls.normal_count AS biomarkers_normal,
    ROUND(rs.sauna_score, 1) AS recovery_sauna_score,
    ROUND(rs.cold_score, 1) AS recovery_cold_score,
    -- Composite health score (weighted average of available components)
    -- Weights: Labs 30%, Recovery 25%, Fasting 20%, Supplements 25%
    ROUND(
        (
            COALESCE(ls.score * 0.30, 0) +
            COALESCE((rs.sauna_score + rs.cold_score) / 2 * 0.25, 0) +
            COALESCE(fs.score * 0.20, 0) +
            COALESCE(ss.score * 0.25, 0)
        ) /
        (
            CASE WHEN ls.score IS NOT NULL THEN 0.30 ELSE 0 END +
            CASE WHEN rs.sauna_score IS NOT NULL OR rs.cold_score IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN fs.score IS NOT NULL THEN 0.20 ELSE 0 END +
            CASE WHEN ss.score IS NOT NULL THEN 0.25 ELSE 0 END
        ),
        0
    ) AS health_score,
    -- Score interpretation
    CASE
        WHEN ROUND(
            (COALESCE(ls.score * 0.30, 0) + COALESCE((rs.sauna_score + rs.cold_score) / 2 * 0.25, 0) +
             COALESCE(fs.score * 0.20, 0) + COALESCE(ss.score * 0.25, 0)) /
            (CASE WHEN ls.score IS NOT NULL THEN 0.30 ELSE 0 END +
             CASE WHEN rs.sauna_score IS NOT NULL OR rs.cold_score IS NOT NULL THEN 0.25 ELSE 0 END +
             CASE WHEN fs.score IS NOT NULL THEN 0.20 ELSE 0 END +
             CASE WHEN ss.score IS NOT NULL THEN 0.25 ELSE 0 END), 0) >= 90 THEN 'excellent'
        WHEN ROUND(
            (COALESCE(ls.score * 0.30, 0) + COALESCE((rs.sauna_score + rs.cold_score) / 2 * 0.25, 0) +
             COALESCE(fs.score * 0.20, 0) + COALESCE(ss.score * 0.25, 0)) /
            (CASE WHEN ls.score IS NOT NULL THEN 0.30 ELSE 0 END +
             CASE WHEN rs.sauna_score IS NOT NULL OR rs.cold_score IS NOT NULL THEN 0.25 ELSE 0 END +
             CASE WHEN fs.score IS NOT NULL THEN 0.20 ELSE 0 END +
             CASE WHEN ss.score IS NOT NULL THEN 0.25 ELSE 0 END), 0) >= 75 THEN 'good'
        WHEN ROUND(
            (COALESCE(ls.score * 0.30, 0) + COALESCE((rs.sauna_score + rs.cold_score) / 2 * 0.25, 0) +
             COALESCE(fs.score * 0.20, 0) + COALESCE(ss.score * 0.25, 0)) /
            (CASE WHEN ls.score IS NOT NULL THEN 0.30 ELSE 0 END +
             CASE WHEN rs.sauna_score IS NOT NULL OR rs.cold_score IS NOT NULL THEN 0.25 ELSE 0 END +
             CASE WHEN fs.score IS NOT NULL THEN 0.20 ELSE 0 END +
             CASE WHEN ss.score IS NOT NULL THEN 0.25 ELSE 0 END), 0) >= 60 THEN 'fair'
        ELSE 'needs_attention'
    END AS health_status,
    -- Data freshness
    (SELECT MAX(test_date) FROM lab_results WHERE patient_id = p.id) AS last_lab_date,
    (SELECT MAX(logged_at) FROM recovery_sessions WHERE patient_id = p.id) AS last_recovery_at,
    (SELECT MAX(started_at) FROM fasting_logs WHERE patient_id = p.id) AS last_fast_at,
    (SELECT MAX(logged_at) FROM supplement_logs WHERE patient_id = p.id) AS last_supplement_at,
    now() AS calculated_at
FROM patients p
LEFT JOIN lab_score ls ON ls.patient_id = p.id
LEFT JOIN recovery_score rs ON rs.patient_id = p.id
LEFT JOIN fasting_score fs ON fs.patient_id = p.id
LEFT JOIN supplement_score ss ON ss.patient_id = p.id;

COMMENT ON VIEW v_patient_health_score IS
    'Composite health score (0-100) with component breakdowns. Filter by patient_id.';

-- ============================================================================
-- RPC FUNCTION: start_fasting_session
-- ============================================================================
-- Starts a new fasting session for the patient.
-- Returns the created fasting log entry.

CREATE OR REPLACE FUNCTION start_fasting_session(
    p_patient_id UUID,
    p_protocol_type TEXT,
    p_planned_hours INTEGER DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    patient_id UUID,
    started_at TIMESTAMPTZ,
    planned_hours INTEGER,
    protocol_type TEXT,
    notes TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_planned_hours INTEGER;
    v_new_id UUID;
BEGIN
    -- Check for existing active fast
    IF EXISTS (
        SELECT 1 FROM fasting_logs fl
        WHERE fl.patient_id = p_patient_id AND fl.ended_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Patient already has an active fasting session. End the current fast first.';
    END IF;

    -- Get planned hours from protocol if not specified
    IF p_planned_hours IS NULL THEN
        SELECT fp.fasting_hours INTO v_planned_hours
        FROM fasting_protocols fp
        WHERE fp.name ILIKE '%' || p_protocol_type || '%'
        LIMIT 1;

        -- Default to 16 hours if protocol not found
        v_planned_hours := COALESCE(v_planned_hours, 16);
    ELSE
        v_planned_hours := p_planned_hours;
    END IF;

    -- Create the fasting log entry
    INSERT INTO fasting_logs (
        patient_id,
        started_at,
        planned_hours,
        protocol_type,
        notes,
        completed
    ) VALUES (
        p_patient_id,
        now(),
        v_planned_hours,
        p_protocol_type,
        p_notes,
        false
    )
    RETURNING fasting_logs.id INTO v_new_id;

    -- Return the created entry
    RETURN QUERY
    SELECT
        fl.id,
        fl.patient_id,
        fl.started_at,
        fl.planned_hours,
        fl.protocol_type,
        fl.notes
    FROM fasting_logs fl
    WHERE fl.id = v_new_id;
END;
$$;

COMMENT ON FUNCTION start_fasting_session(UUID, TEXT, INTEGER, TEXT) IS
    'Start a new fasting session. Protocol types: 16:8, 18:6, 20:4, OMAD, 24-hour, etc.';

-- ============================================================================
-- RPC FUNCTION: end_fasting_session
-- ============================================================================
-- Ends the current fasting session for the patient.
-- Calculates actual hours and completion status automatically via trigger.

CREATE OR REPLACE FUNCTION end_fasting_session(
    p_patient_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    patient_id UUID,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    planned_hours INTEGER,
    actual_hours NUMERIC,
    completed BOOLEAN,
    protocol_type TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_fast_id UUID;
BEGIN
    -- Find active fast
    SELECT fl.id INTO v_fast_id
    FROM fasting_logs fl
    WHERE fl.patient_id = p_patient_id AND fl.ended_at IS NULL
    ORDER BY fl.started_at DESC
    LIMIT 1;

    IF v_fast_id IS NULL THEN
        RAISE EXCEPTION 'No active fasting session found for this patient.';
    END IF;

    -- Update the fasting log (trigger will calculate actual_hours and completed)
    UPDATE fasting_logs fl
    SET
        ended_at = now(),
        notes = COALESCE(p_notes, fl.notes),
        updated_at = now()
    WHERE fl.id = v_fast_id;

    -- Return the updated entry
    RETURN QUERY
    SELECT
        fl.id,
        fl.patient_id,
        fl.started_at,
        fl.ended_at,
        fl.planned_hours,
        fl.actual_hours,
        fl.completed,
        fl.protocol_type
    FROM fasting_logs fl
    WHERE fl.id = v_fast_id;
END;
$$;

COMMENT ON FUNCTION end_fasting_session(UUID, TEXT) IS
    'End the current fasting session. Automatically calculates actual hours and completion status.';

-- ============================================================================
-- RPC FUNCTION: log_recovery_session
-- ============================================================================
-- Quick logging of a recovery session (sauna, cold plunge, etc.)

CREATE OR REPLACE FUNCTION log_recovery_session(
    p_patient_id UUID,
    p_session_type recovery_session_type,
    p_duration_minutes INTEGER,
    p_temperature_f NUMERIC DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_logged_at TIMESTAMPTZ DEFAULT now()
)
RETURNS TABLE (
    id UUID,
    patient_id UUID,
    session_type recovery_session_type,
    duration_minutes INTEGER,
    temperature_f NUMERIC,
    logged_at TIMESTAMPTZ,
    notes TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_new_id UUID;
BEGIN
    -- Validate duration
    IF p_duration_minutes <= 0 THEN
        RAISE EXCEPTION 'Duration must be greater than 0 minutes.';
    END IF;

    -- Create the recovery session entry
    INSERT INTO recovery_sessions (
        patient_id,
        session_type,
        duration_minutes,
        temperature_f,
        notes,
        logged_at
    ) VALUES (
        p_patient_id,
        p_session_type,
        p_duration_minutes,
        p_temperature_f,
        p_notes,
        p_logged_at
    )
    RETURNING recovery_sessions.id INTO v_new_id;

    -- Return the created entry
    RETURN QUERY
    SELECT
        rs.id,
        rs.patient_id,
        rs.session_type,
        rs.duration_minutes,
        rs.temperature_f,
        rs.logged_at,
        rs.notes
    FROM recovery_sessions rs
    WHERE rs.id = v_new_id;
END;
$$;

COMMENT ON FUNCTION log_recovery_session(UUID, recovery_session_type, INTEGER, NUMERIC, TEXT, TIMESTAMPTZ) IS
    'Quick log a recovery session (sauna, cold plunge, etc.). Types: sauna_traditional, sauna_infrared, sauna_steam, cold_plunge, cold_shower, ice_bath, contrast.';

-- ============================================================================
-- RPC FUNCTION: log_supplement_dose
-- ============================================================================
-- Log a supplement dose taken by the patient.

CREATE OR REPLACE FUNCTION log_supplement_dose(
    p_patient_id UUID,
    p_supplement_id UUID,
    p_dosage NUMERIC,
    p_timing supplement_timing,
    p_dosage_unit TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_logged_at TIMESTAMPTZ DEFAULT now()
)
RETURNS TABLE (
    id UUID,
    patient_id UUID,
    supplement_id UUID,
    supplement_name TEXT,
    dosage NUMERIC,
    dosage_unit TEXT,
    timing supplement_timing,
    logged_at TIMESTAMPTZ,
    notes TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_new_id UUID;
    v_dosage_unit TEXT;
BEGIN
    -- Validate dosage
    IF p_dosage <= 0 THEN
        RAISE EXCEPTION 'Dosage must be greater than 0.';
    END IF;

    -- Get dosage unit from stack if not provided
    IF p_dosage_unit IS NULL THEN
        SELECT pss.dosage_unit INTO v_dosage_unit
        FROM patient_supplement_stacks pss
        WHERE pss.patient_id = p_patient_id
          AND pss.supplement_id = p_supplement_id
          AND pss.is_active = true
        LIMIT 1;

        -- Default to 'mg' if not found
        v_dosage_unit := COALESCE(v_dosage_unit, 'mg');
    ELSE
        v_dosage_unit := p_dosage_unit;
    END IF;

    -- Create the supplement log entry
    INSERT INTO supplement_logs (
        patient_id,
        supplement_id,
        dosage,
        dosage_unit,
        timing,
        notes,
        logged_at
    ) VALUES (
        p_patient_id,
        p_supplement_id,
        p_dosage,
        v_dosage_unit,
        p_timing,
        p_notes,
        p_logged_at
    )
    RETURNING supplement_logs.id INTO v_new_id;

    -- Return the created entry with supplement name
    RETURN QUERY
    SELECT
        sl.id,
        sl.patient_id,
        sl.supplement_id,
        s.name AS supplement_name,
        sl.dosage,
        sl.dosage_unit,
        sl.timing,
        sl.logged_at,
        sl.notes
    FROM supplement_logs sl
    JOIN supplements s ON s.id = sl.supplement_id
    WHERE sl.id = v_new_id;
END;
$$;

COMMENT ON FUNCTION log_supplement_dose(UUID, UUID, NUMERIC, supplement_timing, TEXT, TEXT, TIMESTAMPTZ) IS
    'Log a supplement dose. Timing options: morning, afternoon, evening, pre_workout, post_workout, with_meal, before_bed.';

-- ============================================================================
-- RPC FUNCTION: get_daily_health_briefing
-- ============================================================================
-- Aggregates health data for AI-powered daily briefing generation.
-- Returns a comprehensive data package optimized for LLM consumption.

CREATE OR REPLACE FUNCTION get_daily_health_briefing(
    p_patient_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
    v_patient_name TEXT;
    v_current_fast JSONB;
    v_yesterday_recovery JSONB;
    v_supplement_status JSONB;
    v_flagged_biomarkers JSONB;
    v_health_score NUMERIC;
    v_health_status TEXT;
    v_fasting_streak INTEGER;
    v_recovery_streak INTEGER;
BEGIN
    -- Get patient name
    SELECT COALESCE(first_name || ' ' || last_name, first_name, 'Patient')
    INTO v_patient_name
    FROM patients WHERE id = p_patient_id;

    -- Current fasting status
    SELECT jsonb_build_object(
        'is_fasting', (ended_at IS NULL),
        'started_at', started_at,
        'current_hours', ROUND(EXTRACT(EPOCH FROM (now() - started_at)) / 3600.0, 1),
        'planned_hours', planned_hours,
        'protocol', protocol_type,
        'progress_pct', ROUND(EXTRACT(EPOCH FROM (now() - started_at)) / 3600.0 / planned_hours * 100, 1)
    ) INTO v_current_fast
    FROM fasting_logs
    WHERE patient_id = p_patient_id AND ended_at IS NULL
    ORDER BY started_at DESC
    LIMIT 1;

    -- Yesterday's recovery sessions
    SELECT jsonb_agg(jsonb_build_object(
        'type', session_type,
        'duration_minutes', duration_minutes,
        'temperature_f', temperature_f
    )) INTO v_yesterday_recovery
    FROM recovery_sessions
    WHERE patient_id = p_patient_id
      AND (logged_at AT TIME ZONE 'UTC')::date = CURRENT_DATE - 1;

    -- Supplements due today
    SELECT jsonb_agg(jsonb_build_object(
        'name', s.name,
        'dosage', pss.dosage,
        'dosage_unit', pss.dosage_unit,
        'timing', pss.timing,
        'doses_today', COALESCE(
            (SELECT COUNT(*) FROM supplement_logs sl
             WHERE sl.patient_id = pss.patient_id
               AND sl.supplement_id = pss.supplement_id
               AND (sl.logged_at AT TIME ZONE 'UTC')::date = CURRENT_DATE),
            0
        ),
        'expected_doses', CASE
            WHEN pss.frequency = 'daily' THEN 1
            WHEN pss.frequency = 'twice daily' THEN 2
            WHEN pss.frequency = 'three times daily' THEN 3
            ELSE 1
        END
    )) INTO v_supplement_status
    FROM patient_supplement_stacks pss
    JOIN supplements s ON s.id = pss.supplement_id
    WHERE pss.patient_id = p_patient_id AND pss.is_active = true;

    -- Flagged biomarkers from latest labs
    SELECT jsonb_agg(jsonb_build_object(
        'biomarker', brr.name,
        'category', brr.category,
        'value', bv.value,
        'unit', bv.unit,
        'status', CASE
            WHEN bv.value < brr.optimal_low THEN 'low'
            WHEN bv.value > brr.optimal_high THEN 'high'
            ELSE 'normal'
        END,
        'optimal_range', brr.optimal_low || '-' || brr.optimal_high
    )) INTO v_flagged_biomarkers
    FROM lab_results lr
    JOIN biomarker_values bv ON bv.lab_result_id = lr.id
    JOIN biomarker_reference_ranges brr ON brr.biomarker_type = bv.biomarker_type
    WHERE lr.patient_id = p_patient_id
      AND lr.test_date = (SELECT MAX(test_date) FROM lab_results WHERE patient_id = p_patient_id)
      AND (bv.value < brr.optimal_low OR bv.value > brr.optimal_high);

    -- Get health score
    SELECT health_score, health_status
    INTO v_health_score, v_health_status
    FROM v_patient_health_score
    WHERE patient_id = p_patient_id;

    -- Calculate fasting streak
    SELECT current_streak INTO v_fasting_streak
    FROM v_patient_fasting_current
    WHERE patient_id = p_patient_id;

    -- Build the complete briefing package
    v_result := jsonb_build_object(
        'patient_name', v_patient_name,
        'patient_id', p_patient_id,
        'briefing_date', CURRENT_DATE,
        'briefing_time', now(),

        'health_overview', jsonb_build_object(
            'score', v_health_score,
            'status', v_health_status,
            'fasting_streak_days', COALESCE(v_fasting_streak, 0)
        ),

        'current_fast', COALESCE(v_current_fast, jsonb_build_object('is_fasting', false)),

        'yesterday_recovery', COALESCE(v_yesterday_recovery, '[]'::jsonb),

        'supplements_today', COALESCE(v_supplement_status, '[]'::jsonb),

        'flagged_biomarkers', COALESCE(v_flagged_biomarkers, '[]'::jsonb),

        'recommendations', jsonb_build_object(
            'priority_actions', (
                SELECT jsonb_agg(action) FROM (
                    -- Check if supplements are due
                    SELECT 'Take your morning supplements' AS action
                    WHERE EXISTS (
                        SELECT 1 FROM patient_supplement_stacks pss
                        WHERE pss.patient_id = p_patient_id
                          AND pss.is_active = true
                          AND pss.timing = 'morning'
                          AND NOT EXISTS (
                              SELECT 1 FROM supplement_logs sl
                              WHERE sl.patient_id = pss.patient_id
                                AND sl.supplement_id = pss.supplement_id
                                AND (sl.logged_at AT TIME ZONE 'UTC')::date = CURRENT_DATE
                          )
                    )
                    UNION ALL
                    -- Check recovery this week
                    SELECT 'Consider a sauna or cold exposure session' AS action
                    WHERE (
                        SELECT COALESCE(SUM(duration_minutes), 0)
                        FROM recovery_sessions
                        WHERE patient_id = p_patient_id
                          AND session_type IN ('sauna_traditional', 'sauna_infrared', 'cold_plunge')
                          AND logged_at >= CURRENT_DATE - interval '7 days'
                    ) < 30
                ) actions
            )
        )
    );

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_daily_health_briefing(UUID) IS
    'Get AI-ready data package for generating daily health briefings. Returns JSONB with all relevant health data.';

-- ============================================================================
-- RPC FUNCTION: get_lab_analysis_data
-- ============================================================================
-- Returns comprehensive lab data package for AI analysis of a specific lab result.

CREATE OR REPLACE FUNCTION get_lab_analysis_data(
    p_patient_id UUID,
    p_lab_result_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
    v_lab_id UUID;
    v_test_date DATE;
    v_provider TEXT;
    v_biomarkers JSONB;
    v_previous_values JSONB;
    v_patient_context JSONB;
BEGIN
    -- Get lab result ID (most recent if not specified)
    IF p_lab_result_id IS NULL THEN
        SELECT id, test_date, provider::text INTO v_lab_id, v_test_date, v_provider
        FROM lab_results
        WHERE patient_id = p_patient_id
        ORDER BY test_date DESC
        LIMIT 1;
    ELSE
        SELECT id, test_date, provider::text INTO v_lab_id, v_test_date, v_provider
        FROM lab_results
        WHERE id = p_lab_result_id AND patient_id = p_patient_id;
    END IF;

    IF v_lab_id IS NULL THEN
        RETURN jsonb_build_object(
            'error', 'No lab results found',
            'patient_id', p_patient_id
        );
    END IF;

    -- Get all biomarkers from this lab with reference ranges
    SELECT jsonb_agg(
        jsonb_build_object(
            'biomarker_type', bv.biomarker_type,
            'name', brr.name,
            'category', brr.category,
            'value', bv.value,
            'unit', bv.unit,
            'is_flagged', bv.is_flagged,
            'optimal_low', brr.optimal_low,
            'optimal_high', brr.optimal_high,
            'normal_low', brr.normal_low,
            'normal_high', brr.normal_high,
            'status', CASE
                WHEN bv.value >= brr.optimal_low AND bv.value <= brr.optimal_high THEN 'optimal'
                WHEN bv.value >= brr.normal_low AND bv.value <= brr.normal_high THEN 'normal'
                ELSE 'concern'
            END,
            'direction', CASE
                WHEN bv.value < brr.optimal_low THEN 'low'
                WHEN bv.value > brr.optimal_high THEN 'high'
                ELSE NULL
            END,
            'description', brr.description
        )
        ORDER BY brr.category, brr.name
    ) INTO v_biomarkers
    FROM biomarker_values bv
    LEFT JOIN biomarker_reference_ranges brr ON brr.biomarker_type = bv.biomarker_type
    WHERE bv.lab_result_id = v_lab_id;

    -- Get previous values for trending (last 3 results per biomarker)
    SELECT jsonb_object_agg(
        biomarker_type,
        values_array
    ) INTO v_previous_values
    FROM (
        SELECT
            bv.biomarker_type,
            jsonb_agg(
                jsonb_build_object(
                    'test_date', lr.test_date,
                    'value', bv.value
                )
                ORDER BY lr.test_date DESC
            ) AS values_array
        FROM biomarker_values bv
        JOIN lab_results lr ON lr.id = bv.lab_result_id
        WHERE lr.patient_id = p_patient_id
          AND lr.test_date < v_test_date
          AND bv.biomarker_type IN (
              SELECT bv2.biomarker_type FROM biomarker_values bv2 WHERE bv2.lab_result_id = v_lab_id
          )
        GROUP BY bv.biomarker_type
    ) trends;

    -- Get patient context
    SELECT jsonb_build_object(
        'name', COALESCE(first_name || ' ' || last_name, first_name, 'Patient'),
        'age', EXTRACT(YEAR FROM age(date_of_birth)),
        'gender', gender
    ) INTO v_patient_context
    FROM patients
    WHERE id = p_patient_id;

    -- Build complete analysis package
    v_result := jsonb_build_object(
        'lab_result_id', v_lab_id,
        'patient_id', p_patient_id,
        'patient', v_patient_context,
        'test_date', v_test_date,
        'provider', v_provider,
        'biomarkers', COALESCE(v_biomarkers, '[]'::jsonb),
        'historical_values', COALESCE(v_previous_values, '{}'::jsonb),
        'summary', jsonb_build_object(
            'total_biomarkers', (SELECT COUNT(*) FROM biomarker_values WHERE lab_result_id = v_lab_id),
            'optimal_count', (
                SELECT COUNT(*)
                FROM biomarker_values bv
                JOIN biomarker_reference_ranges brr ON brr.biomarker_type = bv.biomarker_type
                WHERE bv.lab_result_id = v_lab_id
                  AND bv.value >= brr.optimal_low
                  AND bv.value <= brr.optimal_high
            ),
            'flagged_count', (SELECT COUNT(*) FROM biomarker_values WHERE lab_result_id = v_lab_id AND is_flagged),
            'categories', (
                SELECT jsonb_agg(DISTINCT brr.category)
                FROM biomarker_values bv
                JOIN biomarker_reference_ranges brr ON brr.biomarker_type = bv.biomarker_type
                WHERE bv.lab_result_id = v_lab_id
            )
        ),
        'generated_at', now()
    );

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_lab_analysis_data(UUID, UUID) IS
    'Get comprehensive lab data package for AI analysis. Includes biomarkers, reference ranges, historical trends, and patient context.';

-- ============================================================================
-- RPC FUNCTION: check_supplement_interactions
-- ============================================================================
-- Check for known interactions between a set of supplements.

CREATE OR REPLACE FUNCTION check_supplement_interactions(
    p_supplement_ids UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
    v_supplements JSONB;
    v_interactions JSONB;
BEGIN
    -- Get supplement details
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', s.id,
            'name', s.name,
            'category', s.category,
            'interactions', s.interactions
        )
    ) INTO v_supplements
    FROM supplements s
    WHERE s.id = ANY(p_supplement_ids);

    -- Find interactions between the selected supplements
    -- Each supplement has an 'interactions' JSONB array listing names of interacting supplements
    WITH supplement_names AS (
        SELECT id, name, interactions
        FROM supplements
        WHERE id = ANY(p_supplement_ids)
    ),
    found_interactions AS (
        SELECT
            s1.name AS supplement_1,
            s2.name AS supplement_2,
            jsonb_array_elements_text(s1.interactions) AS interaction_detail
        FROM supplement_names s1
        CROSS JOIN supplement_names s2
        WHERE s1.id < s2.id -- Avoid duplicates
          AND (
              s1.interactions @> jsonb_build_array(s2.name)
              OR s2.interactions @> jsonb_build_array(s1.name)
          )
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'supplement_1', supplement_1,
            'supplement_2', supplement_2,
            'details', interaction_detail
        )
    ) INTO v_interactions
    FROM found_interactions;

    -- Build result
    v_result := jsonb_build_object(
        'supplements_checked', COALESCE(v_supplements, '[]'::jsonb),
        'supplement_count', array_length(p_supplement_ids, 1),
        'interactions_found', COALESCE(jsonb_array_length(v_interactions), 0) > 0,
        'interactions', COALESCE(v_interactions, '[]'::jsonb),
        'warning_level', CASE
            WHEN COALESCE(jsonb_array_length(v_interactions), 0) > 2 THEN 'high'
            WHEN COALESCE(jsonb_array_length(v_interactions), 0) > 0 THEN 'moderate'
            ELSE 'none'
        END,
        'recommendation', CASE
            WHEN COALESCE(jsonb_array_length(v_interactions), 0) > 0 THEN
                'Review interactions with your healthcare provider before combining these supplements.'
            ELSE
                'No known interactions found between these supplements.'
        END,
        'checked_at', now()
    );

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION check_supplement_interactions(UUID[]) IS
    'Check for known interactions between an array of supplement IDs. Returns interaction details and warnings.';

-- ============================================================================
-- COMPUTED FUNCTION: calculate_recovery_score
-- ============================================================================
-- Calculate a recovery score (0-100) based on sauna and cold exposure.

CREATE OR REPLACE FUNCTION calculate_recovery_score(
    p_patient_id UUID,
    p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    recovery_score NUMERIC,
    sauna_score NUMERIC,
    cold_score NUMERIC,
    sauna_minutes INTEGER,
    cold_minutes INTEGER,
    total_sessions INTEGER,
    target_met BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    WITH recovery_data AS (
        SELECT
            COALESCE(SUM(CASE
                WHEN session_type IN ('sauna_traditional', 'sauna_infrared', 'sauna_steam')
                THEN duration_minutes
            END), 0)::integer AS sauna_mins,
            COALESCE(SUM(CASE
                WHEN session_type IN ('cold_plunge', 'cold_shower', 'ice_bath')
                THEN duration_minutes
            END), 0)::integer AS cold_mins,
            COUNT(*)::integer AS sessions
        FROM recovery_sessions
        WHERE patient_id = p_patient_id
          AND logged_at >= CURRENT_DATE - (p_days || ' days')::interval
    )
    SELECT
        -- Combined score (average of sauna and cold, capped at 100)
        ROUND(LEAST(
            (LEAST(sauna_mins::numeric / (57.0 * p_days / 7), 1) * 50) +
            (LEAST(cold_mins::numeric / (11.0 * p_days / 7), 1) * 50),
            100
        ), 1) AS recovery_score,
        -- Individual scores (capped at 100)
        ROUND(LEAST(sauna_mins::numeric / (57.0 * p_days / 7) * 100, 100), 1) AS sauna_score,
        ROUND(LEAST(cold_mins::numeric / (11.0 * p_days / 7) * 100, 100), 1) AS cold_score,
        sauna_mins AS sauna_minutes,
        cold_mins AS cold_minutes,
        sessions AS total_sessions,
        -- Target met if both sauna >= 57 min and cold >= 11 min per week
        (sauna_mins >= 57.0 * p_days / 7 AND cold_mins >= 11.0 * p_days / 7) AS target_met
    FROM recovery_data;
$$;

COMMENT ON FUNCTION calculate_recovery_score(UUID, INTEGER) IS
    'Calculate recovery score (0-100) based on sauna (target 57 min/week) and cold exposure (target 11 min/week).';

-- ============================================================================
-- COMPUTED FUNCTION: calculate_fasting_streak
-- ============================================================================
-- Calculate the current consecutive days of completed fasts.

CREATE OR REPLACE FUNCTION calculate_fasting_streak(
    p_patient_id UUID
)
RETURNS TABLE (
    current_streak INTEGER,
    longest_streak INTEGER,
    last_fast_date DATE,
    streak_start_date DATE
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    WITH completed_fasts AS (
        SELECT DISTINCT started_at::date AS fast_date
        FROM fasting_logs
        WHERE patient_id = p_patient_id
          AND completed = true
    ),
    streak_calc AS (
        SELECT
            fast_date,
            fast_date - ROW_NUMBER() OVER (ORDER BY fast_date)::integer AS streak_group
        FROM completed_fasts
    ),
    streaks AS (
        SELECT
            MIN(fast_date) AS streak_start,
            MAX(fast_date) AS streak_end,
            COUNT(*)::integer AS streak_length
        FROM streak_calc
        GROUP BY streak_group
    ),
    current AS (
        SELECT
            streak_length,
            streak_start,
            streak_end
        FROM streaks
        WHERE streak_end = CURRENT_DATE OR streak_end = CURRENT_DATE - 1
        ORDER BY streak_end DESC
        LIMIT 1
    )
    SELECT
        COALESCE((SELECT streak_length FROM current WHERE streak_end >= CURRENT_DATE - 1), 0) AS current_streak,
        COALESCE((SELECT MAX(streak_length) FROM streaks), 0) AS longest_streak,
        (SELECT MAX(fast_date) FROM completed_fasts) AS last_fast_date,
        (SELECT streak_start FROM current) AS streak_start_date;
$$;

COMMENT ON FUNCTION calculate_fasting_streak(UUID) IS
    'Calculate current and longest fasting streaks (consecutive days of completed fasts).';

-- ============================================================================
-- COMPUTED FUNCTION: calculate_supplement_adherence_rate
-- ============================================================================
-- Calculate supplement adherence rate over a period.

CREATE OR REPLACE FUNCTION calculate_supplement_adherence_rate(
    p_patient_id UUID,
    p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    overall_adherence_pct NUMERIC,
    supplements_tracked INTEGER,
    doses_logged INTEGER,
    doses_expected INTEGER,
    by_supplement JSONB
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    WITH stack AS (
        SELECT
            pss.supplement_id,
            s.name AS supplement_name,
            pss.frequency,
            CASE
                WHEN pss.frequency = 'daily' THEN p_days
                WHEN pss.frequency = 'twice daily' THEN p_days * 2
                WHEN pss.frequency = 'three times daily' THEN p_days * 3
                WHEN pss.frequency = 'every other day' THEN CEIL(p_days / 2.0)::integer
                ELSE p_days
            END AS expected_doses
        FROM patient_supplement_stacks pss
        JOIN supplements s ON s.id = pss.supplement_id
        WHERE pss.patient_id = p_patient_id
          AND pss.is_active = true
    ),
    doses AS (
        SELECT
            sl.supplement_id,
            COUNT(*) AS dose_count
        FROM supplement_logs sl
        WHERE sl.patient_id = p_patient_id
          AND sl.logged_at >= CURRENT_DATE - (p_days || ' days')::interval
        GROUP BY sl.supplement_id
    ),
    combined AS (
        SELECT
            st.supplement_id,
            st.supplement_name,
            st.expected_doses,
            COALESCE(d.dose_count, 0)::integer AS actual_doses,
            ROUND(
                COALESCE(d.dose_count, 0)::numeric / NULLIF(st.expected_doses, 0) * 100,
                1
            ) AS adherence_pct
        FROM stack st
        LEFT JOIN doses d ON d.supplement_id = st.supplement_id
    )
    SELECT
        ROUND(AVG(adherence_pct), 1) AS overall_adherence_pct,
        COUNT(*)::integer AS supplements_tracked,
        SUM(actual_doses)::integer AS doses_logged,
        SUM(expected_doses)::integer AS doses_expected,
        jsonb_agg(
            jsonb_build_object(
                'supplement_id', supplement_id,
                'name', supplement_name,
                'doses_logged', actual_doses,
                'doses_expected', expected_doses,
                'adherence_pct', adherence_pct
            )
        ) AS by_supplement
    FROM combined;
$$;

COMMENT ON FUNCTION calculate_supplement_adherence_rate(UUID, INTEGER) IS
    'Calculate supplement adherence rate over N days. Returns overall rate and per-supplement breakdown.';

-- ============================================================================
-- INDEXES FOR VIEW OPTIMIZATION
-- ============================================================================

-- Index for lab summary view - getting latest per biomarker
CREATE INDEX IF NOT EXISTS idx_lab_results_patient_test_date_desc
    ON lab_results (patient_id, test_date DESC);

-- Index for recovery weekly view - use UTC timezone for immutability
CREATE INDEX IF NOT EXISTS idx_recovery_sessions_patient_week
    ON recovery_sessions (patient_id, ((logged_at AT TIME ZONE 'UTC')::date));

-- Index for fasting current view - active fasts
CREATE INDEX IF NOT EXISTS idx_fasting_logs_patient_active
    ON fasting_logs (patient_id)
    WHERE ended_at IS NULL;

-- Index for supplement stack view - active stacks
CREATE INDEX IF NOT EXISTS idx_supplement_stacks_patient_active
    ON patient_supplement_stacks (patient_id)
    WHERE is_active = true;

-- Index for supplement logs - today's doses
CREATE INDEX IF NOT EXISTS idx_supplement_logs_patient_date
    ON supplement_logs (patient_id, ((logged_at AT TIME ZONE 'UTC')::date));

-- ============================================================================
-- GRANTS
-- ============================================================================

-- Grant execute on helper function
GRANT EXECUTE ON FUNCTION get_current_user_patient_id() TO authenticated;

-- Grant select on views
GRANT SELECT ON v_patient_lab_summary TO authenticated;
GRANT SELECT ON v_patient_recovery_weekly TO authenticated;
GRANT SELECT ON v_patient_fasting_current TO authenticated;
GRANT SELECT ON v_patient_supplement_stack TO authenticated;
GRANT SELECT ON v_patient_health_score TO authenticated;

-- Grant execute on RPC functions
GRANT EXECUTE ON FUNCTION start_fasting_session(UUID, TEXT, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION end_fasting_session(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION log_recovery_session(UUID, recovery_session_type, INTEGER, NUMERIC, TEXT, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION log_supplement_dose(UUID, UUID, NUMERIC, supplement_timing, TEXT, TEXT, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_health_briefing(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_lab_analysis_data(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION check_supplement_interactions(UUID[]) TO authenticated;

-- Grant execute on computed functions
GRANT EXECUTE ON FUNCTION calculate_recovery_score(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_fasting_streak(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_supplement_adherence_rate(UUID, INTEGER) TO authenticated;

-- Grant to service role
GRANT ALL ON v_patient_lab_summary TO service_role;
GRANT ALL ON v_patient_recovery_weekly TO service_role;
GRANT ALL ON v_patient_fasting_current TO service_role;
GRANT ALL ON v_patient_supplement_stack TO service_role;
GRANT ALL ON v_patient_health_score TO service_role;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_view_count integer;
    v_function_count integer;
    v_index_count integer;
BEGIN
    -- Count views
    SELECT COUNT(*) INTO v_view_count
    FROM pg_views
    WHERE schemaname = 'public'
      AND viewname IN (
          'v_patient_lab_summary',
          'v_patient_recovery_weekly',
          'v_patient_fasting_current',
          'v_patient_supplement_stack',
          'v_patient_health_score'
      );

    -- Count functions
    SELECT COUNT(*) INTO v_function_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname IN (
          'get_current_user_patient_id',
          'start_fasting_session',
          'end_fasting_session',
          'log_recovery_session',
          'log_supplement_dose',
          'get_daily_health_briefing',
          'get_lab_analysis_data',
          'check_supplement_interactions',
          'calculate_recovery_score',
          'calculate_fasting_streak',
          'calculate_supplement_adherence_rate'
      );

    -- Count new indexes
    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname IN (
          'idx_lab_results_patient_test_date_desc',
          'idx_recovery_sessions_patient_week',
          'idx_fasting_logs_patient_active',
          'idx_supplement_stacks_patient_active',
          'idx_supplement_logs_patient_date'
      );

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'HEALTH INTELLIGENCE VIEWS & RPC FUNCTIONS MIGRATION COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Views Created: %/5', v_view_count;
    RAISE NOTICE '  - v_patient_lab_summary: Latest lab results with optimal/normal/concern status';
    RAISE NOTICE '  - v_patient_recovery_weekly: Weekly recovery stats (sauna/cold/sessions)';
    RAISE NOTICE '  - v_patient_fasting_current: Current fasting state and stats';
    RAISE NOTICE '  - v_patient_supplement_stack: Active supplement stack with timing';
    RAISE NOTICE '  - v_patient_health_score: Composite health score (0-100)';
    RAISE NOTICE '';
    RAISE NOTICE 'RPC Functions Created: %/11', v_function_count;
    RAISE NOTICE '  - start_fasting_session(patient_id, protocol_type, planned_hours, notes)';
    RAISE NOTICE '  - end_fasting_session(patient_id, notes)';
    RAISE NOTICE '  - log_recovery_session(patient_id, type, duration, temperature, notes)';
    RAISE NOTICE '  - log_supplement_dose(patient_id, supplement_id, dosage, timing, unit, notes)';
    RAISE NOTICE '  - get_daily_health_briefing(patient_id) -> JSONB';
    RAISE NOTICE '  - get_lab_analysis_data(patient_id, lab_result_id) -> JSONB';
    RAISE NOTICE '  - check_supplement_interactions(supplement_ids[]) -> JSONB';
    RAISE NOTICE '  - calculate_recovery_score(patient_id, days) -> table';
    RAISE NOTICE '  - calculate_fasting_streak(patient_id) -> table';
    RAISE NOTICE '  - calculate_supplement_adherence_rate(patient_id, days) -> table';
    RAISE NOTICE '';
    RAISE NOTICE 'Optimization Indexes Created: %/5', v_index_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Security:';
    RAISE NOTICE '  - All views filter by patient_id (use RLS or WHERE clause)';
    RAISE NOTICE '  - RPC functions use SECURITY DEFINER with explicit search_path';
    RAISE NOTICE '  - Grants configured for authenticated role';
    RAISE NOTICE '';
    RAISE NOTICE 'iOS App Usage:';
    RAISE NOTICE '  - SELECT * FROM v_patient_health_score WHERE patient_id = $1';
    RAISE NOTICE '  - SELECT start_fasting_session($1, ''16:8'')';
    RAISE NOTICE '  - SELECT * FROM get_daily_health_briefing($1)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;
