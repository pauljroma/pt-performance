-- Clinical Assessments & Documentation Feature
-- Part 6: Analytics Views for Assessment Progress
-- Created: 2026-02-07

-- ============================================================================
-- VIEW: Assessment Progress Dashboard
-- Overview of patient assessment status and trends
-- ============================================================================

CREATE OR REPLACE VIEW public.vw_assessment_progress AS
SELECT
    p.id AS patient_id,
    p.first_name,
    p.last_name,
    p.therapist_id,

    -- Latest assessment info
    ca.id AS latest_assessment_id,
    ca.assessment_type AS latest_assessment_type,
    ca.assessment_date AS latest_assessment_date,
    ca.status AS latest_assessment_status,
    ca.pain_at_rest AS current_pain_at_rest,
    ca.pain_with_activity AS current_pain_with_activity,

    -- Assessment counts
    (
        SELECT COUNT(*)
        FROM public.clinical_assessments
        WHERE patient_id = p.id
    ) AS total_assessments,
    (
        SELECT COUNT(*)
        FROM public.clinical_assessments
        WHERE patient_id = p.id AND assessment_type = 'progress'
    ) AS progress_assessments,

    -- Days since last assessment
    CURRENT_DATE - ca.assessment_date AS days_since_last_assessment,

    -- SOAP note counts
    (
        SELECT COUNT(*)
        FROM public.soap_notes
        WHERE patient_id = p.id
    ) AS total_soap_notes,
    (
        SELECT COUNT(*)
        FROM public.soap_notes
        WHERE patient_id = p.id AND status = 'draft'
    ) AS pending_soap_notes,

    -- Latest functional status
    (
        SELECT functional_status
        FROM public.soap_notes
        WHERE patient_id = p.id
          AND functional_status IS NOT NULL
        ORDER BY note_date DESC
        LIMIT 1
    ) AS current_functional_status

FROM public.patients p
LEFT JOIN LATERAL (
    SELECT *
    FROM public.clinical_assessments
    WHERE patient_id = p.id
    ORDER BY assessment_date DESC
    LIMIT 1
) ca ON true;

-- Grant access
GRANT SELECT ON public.vw_assessment_progress TO authenticated;

-- ============================================================================
-- VIEW: Outcome Measures Trend
-- Track outcome measure scores over time
-- ============================================================================

CREATE OR REPLACE VIEW public.vw_outcome_measures_trend AS
SELECT
    om.patient_id,
    om.measure_type,
    om.assessment_date,
    om.raw_score,
    om.normalized_score,
    om.interpretation,
    om.previous_score,
    om.change_from_previous,
    om.meets_mcid,

    -- Running statistics
    AVG(om.raw_score) OVER (
        PARTITION BY om.patient_id, om.measure_type
        ORDER BY om.assessment_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_avg_score,

    -- First score for this measure (baseline)
    FIRST_VALUE(om.raw_score) OVER (
        PARTITION BY om.patient_id, om.measure_type
        ORDER BY om.assessment_date
    ) AS baseline_score,

    -- Total change from baseline
    om.raw_score - FIRST_VALUE(om.raw_score) OVER (
        PARTITION BY om.patient_id, om.measure_type
        ORDER BY om.assessment_date
    ) AS change_from_baseline,

    -- Assessment number in sequence
    ROW_NUMBER() OVER (
        PARTITION BY om.patient_id, om.measure_type
        ORDER BY om.assessment_date
    ) AS assessment_sequence

FROM public.outcome_measures om
ORDER BY om.patient_id, om.measure_type, om.assessment_date;

-- Grant access
GRANT SELECT ON public.vw_outcome_measures_trend TO authenticated;

-- ============================================================================
-- VIEW: Pain Trend from Assessments
-- Track pain scores over time from clinical assessments
-- ============================================================================

CREATE OR REPLACE VIEW public.vw_clinical_pain_trend AS
SELECT
    ca.patient_id,
    ca.assessment_date,
    ca.assessment_type,
    ca.pain_at_rest,
    ca.pain_with_activity,
    ca.pain_worst,

    -- Calculate average pain
    ROUND((COALESCE(ca.pain_at_rest, 0) + COALESCE(ca.pain_with_activity, 0) + COALESCE(ca.pain_worst, 0))::NUMERIC /
        NULLIF((CASE WHEN ca.pain_at_rest IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN ca.pain_with_activity IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN ca.pain_worst IS NOT NULL THEN 1 ELSE 0 END), 0), 1) AS avg_pain,

    -- Previous assessment pain values
    LAG(ca.pain_at_rest) OVER (
        PARTITION BY ca.patient_id
        ORDER BY ca.assessment_date
    ) AS prev_pain_at_rest,
    LAG(ca.pain_with_activity) OVER (
        PARTITION BY ca.patient_id
        ORDER BY ca.assessment_date
    ) AS prev_pain_with_activity,

    -- Pain trend direction
    CASE
        WHEN LAG(ca.pain_with_activity) OVER (PARTITION BY ca.patient_id ORDER BY ca.assessment_date) IS NULL THEN 'baseline'
        WHEN ca.pain_with_activity < LAG(ca.pain_with_activity) OVER (PARTITION BY ca.patient_id ORDER BY ca.assessment_date) - 1 THEN 'improving'
        WHEN ca.pain_with_activity > LAG(ca.pain_with_activity) OVER (PARTITION BY ca.patient_id ORDER BY ca.assessment_date) + 1 THEN 'worsening'
        ELSE 'stable'
    END AS pain_trend

FROM public.clinical_assessments ca
WHERE ca.status IN ('complete', 'signed')
ORDER BY ca.patient_id, ca.assessment_date;

-- Grant access
GRANT SELECT ON public.vw_clinical_pain_trend TO authenticated;

-- ============================================================================
-- VIEW: Therapist Documentation Dashboard
-- Summary for therapist dashboard showing pending work
-- ============================================================================

CREATE OR REPLACE VIEW public.vw_therapist_documentation_dashboard AS
SELECT
    t.id AS therapist_id,
    t.first_name AS therapist_first_name,
    t.last_name AS therapist_last_name,

    -- SOAP notes pending
    (
        SELECT COUNT(*)
        FROM public.soap_notes sn
        WHERE sn.therapist_id = t.id AND sn.status = 'draft'
    ) AS draft_soap_notes,
    (
        SELECT COUNT(*)
        FROM public.soap_notes sn
        WHERE sn.therapist_id = t.id AND sn.status = 'complete'
    ) AS unsigned_soap_notes,

    -- Assessments pending
    (
        SELECT COUNT(*)
        FROM public.clinical_assessments ca
        WHERE ca.therapist_id = t.id AND ca.status = 'draft'
    ) AS draft_assessments,
    (
        SELECT COUNT(*)
        FROM public.clinical_assessments ca
        WHERE ca.therapist_id = t.id AND ca.status = 'complete'
    ) AS unsigned_assessments,

    -- Today's documentation
    (
        SELECT COUNT(*)
        FROM public.soap_notes sn
        WHERE sn.therapist_id = t.id AND sn.note_date = CURRENT_DATE
    ) AS soap_notes_today,

    -- This week's completed documentation
    (
        SELECT COUNT(*)
        FROM public.soap_notes sn
        WHERE sn.therapist_id = t.id
          AND sn.signed_at >= DATE_TRUNC('week', CURRENT_DATE)
          AND sn.status = 'signed'
    ) AS signed_notes_this_week,

    -- Patients needing reassessment (last assessment > 30 days ago)
    (
        SELECT COUNT(DISTINCT ca.patient_id)
        FROM public.clinical_assessments ca
        WHERE ca.therapist_id = t.id
          AND ca.assessment_date < CURRENT_DATE - INTERVAL '30 days'
          AND NOT EXISTS (
              SELECT 1
              FROM public.clinical_assessments ca2
              WHERE ca2.patient_id = ca.patient_id
                AND ca2.assessment_date > ca.assessment_date
          )
    ) AS patients_needing_reassessment

FROM public.therapists t;

-- Grant access
GRANT SELECT ON public.vw_therapist_documentation_dashboard TO authenticated;

-- ============================================================================
-- VIEW: Visit Summary with Exercise Details
-- Expanded visit summary with exercise information
-- ============================================================================

CREATE OR REPLACE VIEW public.vw_visit_summary_details AS
SELECT
    vs.id,
    vs.patient_id,
    vs.session_id,
    vs.therapist_id,
    vs.visit_date,
    vs.total_exercises,
    vs.duration_minutes,
    vs.avg_pain_score,
    vs.avg_rpe,
    vs.clinical_notes,
    vs.patient_response,
    vs.modifications_made,
    vs.next_visit_focus,
    vs.home_program_changes,
    vs.created_at,

    -- Patient info
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,

    -- Therapist info
    t.first_name AS therapist_first_name,
    t.last_name AS therapist_last_name,

    -- Associated SOAP note (if exists)
    (
        SELECT sn.id
        FROM public.soap_notes sn
        WHERE sn.session_id = vs.session_id
        LIMIT 1
    ) AS soap_note_id,

    -- Exercise count by type from session_exercises
    (
        SELECT COUNT(*)
        FROM public.session_exercises se
        JOIN public.exercise_templates et ON et.id = se.exercise_template_id
        WHERE se.session_id = vs.session_id
          AND et.category = 'strength'
    ) AS strength_exercises,
    (
        SELECT COUNT(*)
        FROM public.session_exercises se
        JOIN public.exercise_templates et ON et.id = se.exercise_template_id
        WHERE se.session_id = vs.session_id
          AND et.category = 'mobility'
    ) AS mobility_exercises

FROM public.visit_summaries vs
JOIN public.patients p ON p.id = vs.patient_id
JOIN public.therapists t ON t.id = vs.therapist_id;

-- Grant access
GRANT SELECT ON public.vw_visit_summary_details TO authenticated;

-- ============================================================================
-- FUNCTION: Get Patient Assessment Timeline
-- Returns chronological assessment and documentation history
-- ============================================================================

CREATE OR REPLACE FUNCTION get_patient_assessment_timeline(
    p_patient_id UUID,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    event_type TEXT,
    event_id UUID,
    event_date DATE,
    event_title TEXT,
    event_status TEXT,
    event_details JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    (
        -- Clinical Assessments
        SELECT
            'assessment'::TEXT AS event_type,
            ca.id AS event_id,
            ca.assessment_date AS event_date,
            ca.assessment_type || ' Assessment' AS event_title,
            ca.status AS event_status,
            jsonb_build_object(
                'pain_at_rest', ca.pain_at_rest,
                'pain_with_activity', ca.pain_with_activity,
                'therapist_id', ca.therapist_id
            ) AS event_details
        FROM public.clinical_assessments ca
        WHERE ca.patient_id = p_patient_id

        UNION ALL

        -- SOAP Notes
        SELECT
            'soap_note'::TEXT AS event_type,
            sn.id AS event_id,
            sn.note_date AS event_date,
            'SOAP Note' AS event_title,
            sn.status AS event_status,
            jsonb_build_object(
                'pain_level', sn.pain_level,
                'functional_status', sn.functional_status,
                'time_spent_minutes', sn.time_spent_minutes
            ) AS event_details
        FROM public.soap_notes sn
        WHERE sn.patient_id = p_patient_id

        UNION ALL

        -- Outcome Measures
        SELECT
            'outcome_measure'::TEXT AS event_type,
            om.id AS event_id,
            om.assessment_date AS event_date,
            om.measure_type || ' Assessment' AS event_title,
            CASE WHEN om.meets_mcid THEN 'mcid_achieved' ELSE 'recorded' END AS event_status,
            jsonb_build_object(
                'raw_score', om.raw_score,
                'normalized_score', om.normalized_score,
                'interpretation', om.interpretation,
                'change_from_previous', om.change_from_previous
            ) AS event_details
        FROM public.outcome_measures om
        WHERE om.patient_id = p_patient_id

        UNION ALL

        -- Visit Summaries
        SELECT
            'visit_summary'::TEXT AS event_type,
            vs.id AS event_id,
            vs.visit_date AS event_date,
            'Visit Summary' AS event_title,
            'recorded'::TEXT AS event_status,
            jsonb_build_object(
                'total_exercises', vs.total_exercises,
                'duration_minutes', vs.duration_minutes,
                'avg_pain_score', vs.avg_pain_score,
                'avg_rpe', vs.avg_rpe
            ) AS event_details
        FROM public.visit_summaries vs
        WHERE vs.patient_id = p_patient_id
    )
    ORDER BY event_date DESC, event_id
    LIMIT p_limit;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_patient_assessment_timeline TO authenticated;

-- ============================================================================
-- FUNCTION: Get Outcome Measure Summary
-- Returns summary statistics for outcome measures
-- ============================================================================

CREATE OR REPLACE FUNCTION get_outcome_measure_summary(
    p_patient_id UUID,
    p_measure_type VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    measure_type VARCHAR(50),
    total_assessments INTEGER,
    baseline_score DECIMAL(6,2),
    latest_score DECIMAL(6,2),
    best_score DECIMAL(6,2),
    total_change DECIMAL(6,2),
    mcid_achieved BOOLEAN,
    times_mcid_met INTEGER,
    first_assessment_date DATE,
    latest_assessment_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        om.measure_type,
        COUNT(*)::INTEGER AS total_assessments,
        (ARRAY_AGG(om.raw_score ORDER BY om.assessment_date ASC))[1] AS baseline_score,
        (ARRAY_AGG(om.raw_score ORDER BY om.assessment_date DESC))[1] AS latest_score,
        CASE
            WHEN om.measure_type IN ('DASH', 'QuickDASH', 'NDI', 'ODI') THEN MIN(om.raw_score)
            ELSE MAX(om.raw_score)
        END AS best_score,
        (ARRAY_AGG(om.raw_score ORDER BY om.assessment_date DESC))[1] -
        (ARRAY_AGG(om.raw_score ORDER BY om.assessment_date ASC))[1] AS total_change,
        BOOL_OR(om.meets_mcid) AS mcid_achieved,
        COUNT(*) FILTER (WHERE om.meets_mcid = true)::INTEGER AS times_mcid_met,
        MIN(om.assessment_date) AS first_assessment_date,
        MAX(om.assessment_date) AS latest_assessment_date
    FROM public.outcome_measures om
    WHERE om.patient_id = p_patient_id
      AND (p_measure_type IS NULL OR om.measure_type = p_measure_type)
    GROUP BY om.measure_type;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_outcome_measure_summary TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON VIEW public.vw_assessment_progress IS 'Dashboard view showing patient assessment progress and status';
COMMENT ON VIEW public.vw_outcome_measures_trend IS 'Trend analysis of outcome measure scores over time';
COMMENT ON VIEW public.vw_clinical_pain_trend IS 'Pain score trends from clinical assessments';
COMMENT ON VIEW public.vw_therapist_documentation_dashboard IS 'Therapist dashboard for pending documentation';
COMMENT ON VIEW public.vw_visit_summary_details IS 'Expanded visit summary with patient and exercise details';
COMMENT ON FUNCTION get_patient_assessment_timeline IS 'Returns chronological timeline of all patient documentation events';
COMMENT ON FUNCTION get_outcome_measure_summary IS 'Returns summary statistics for patient outcome measures';
