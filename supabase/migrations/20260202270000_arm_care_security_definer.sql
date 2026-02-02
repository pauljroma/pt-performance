-- Migration: Arm Care Security Definer Functions for Demo Patient
-- Date: 2026-02-02
-- Purpose: Allow demo patient arm care assessments to bypass RLS
-- Similar to daily_readiness SECURITY DEFINER pattern

-- ============================================================================
-- UPSERT FUNCTION (SECURITY DEFINER)
-- ============================================================================

CREATE OR REPLACE FUNCTION upsert_arm_care_assessment(
    p_patient_id UUID,
    p_date DATE,
    p_shoulder_pain_score INTEGER,
    p_shoulder_stiffness_score INTEGER,
    p_shoulder_strength_score INTEGER,
    p_elbow_pain_score INTEGER,
    p_elbow_tightness_score INTEGER,
    p_valgus_stress_score INTEGER,
    p_pain_locations JSONB DEFAULT '[]'::jsonb,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_shoulder_score NUMERIC;
    v_elbow_score NUMERIC;
    v_overall_score NUMERIC;
    v_traffic_light TEXT;
    v_result arm_care_assessments;
BEGIN
    -- Calculate scores
    v_shoulder_score := (p_shoulder_pain_score + p_shoulder_stiffness_score + p_shoulder_strength_score)::NUMERIC / 3.0;
    v_elbow_score := (p_elbow_pain_score + p_elbow_tightness_score + p_valgus_stress_score)::NUMERIC / 3.0;
    v_overall_score := (v_shoulder_score + v_elbow_score) / 2.0;

    -- Determine traffic light
    IF v_overall_score >= 8 THEN
        v_traffic_light := 'green';
    ELSIF v_overall_score >= 5 THEN
        v_traffic_light := 'yellow';
    ELSE
        v_traffic_light := 'red';
    END IF;

    -- Upsert the assessment
    INSERT INTO arm_care_assessments (
        patient_id,
        date,
        shoulder_pain_score,
        shoulder_stiffness_score,
        shoulder_strength_score,
        elbow_pain_score,
        elbow_tightness_score,
        valgus_stress_score,
        shoulder_score,
        elbow_score,
        overall_score,
        traffic_light,
        pain_locations,
        notes
    ) VALUES (
        p_patient_id,
        p_date,
        p_shoulder_pain_score,
        p_shoulder_stiffness_score,
        p_shoulder_strength_score,
        p_elbow_pain_score,
        p_elbow_tightness_score,
        p_valgus_stress_score,
        v_shoulder_score,
        v_elbow_score,
        v_overall_score,
        v_traffic_light,
        p_pain_locations,
        p_notes
    )
    ON CONFLICT (patient_id, date)
    DO UPDATE SET
        shoulder_pain_score = EXCLUDED.shoulder_pain_score,
        shoulder_stiffness_score = EXCLUDED.shoulder_stiffness_score,
        shoulder_strength_score = EXCLUDED.shoulder_strength_score,
        elbow_pain_score = EXCLUDED.elbow_pain_score,
        elbow_tightness_score = EXCLUDED.elbow_tightness_score,
        valgus_stress_score = EXCLUDED.valgus_stress_score,
        shoulder_score = EXCLUDED.shoulder_score,
        elbow_score = EXCLUDED.elbow_score,
        overall_score = EXCLUDED.overall_score,
        traffic_light = EXCLUDED.traffic_light,
        pain_locations = EXCLUDED.pain_locations,
        notes = EXCLUDED.notes,
        updated_at = NOW()
    RETURNING * INTO v_result;

    -- Return as JSON
    RETURN jsonb_build_object(
        'id', v_result.id,
        'patient_id', v_result.patient_id,
        'date', v_result.date,
        'shoulder_pain_score', v_result.shoulder_pain_score,
        'shoulder_stiffness_score', v_result.shoulder_stiffness_score,
        'shoulder_strength_score', v_result.shoulder_strength_score,
        'elbow_pain_score', v_result.elbow_pain_score,
        'elbow_tightness_score', v_result.elbow_tightness_score,
        'valgus_stress_score', v_result.valgus_stress_score,
        'shoulder_score', v_result.shoulder_score,
        'elbow_score', v_result.elbow_score,
        'overall_score', v_result.overall_score,
        'traffic_light', v_result.traffic_light,
        'pain_locations', v_result.pain_locations,
        'notes', v_result.notes,
        'created_at', v_result.created_at,
        'updated_at', v_result.updated_at
    );
END;
$$;

-- ============================================================================
-- GET TODAY'S ASSESSMENT FUNCTION (SECURITY DEFINER)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_arm_care_assessment(
    p_patient_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result arm_care_assessments;
BEGIN
    SELECT * INTO v_result
    FROM arm_care_assessments
    WHERE patient_id = p_patient_id
      AND date = p_date
    LIMIT 1;

    IF v_result IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN jsonb_build_object(
        'id', v_result.id,
        'patient_id', v_result.patient_id,
        'date', v_result.date,
        'shoulder_pain_score', v_result.shoulder_pain_score,
        'shoulder_stiffness_score', v_result.shoulder_stiffness_score,
        'shoulder_strength_score', v_result.shoulder_strength_score,
        'elbow_pain_score', v_result.elbow_pain_score,
        'elbow_tightness_score', v_result.elbow_tightness_score,
        'valgus_stress_score', v_result.valgus_stress_score,
        'shoulder_score', v_result.shoulder_score,
        'elbow_score', v_result.elbow_score,
        'overall_score', v_result.overall_score,
        'traffic_light', v_result.traffic_light,
        'pain_locations', v_result.pain_locations,
        'notes', v_result.notes,
        'created_at', v_result.created_at,
        'updated_at', v_result.updated_at
    );
END;
$$;

-- Grant execute to anon and authenticated
GRANT EXECUTE ON FUNCTION upsert_arm_care_assessment TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_arm_care_assessment TO anon, authenticated;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc
        WHERE proname = 'upsert_arm_care_assessment'
    ) THEN
        RAISE NOTICE '✅ upsert_arm_care_assessment function created';
    ELSE
        RAISE EXCEPTION 'Failed to create upsert_arm_care_assessment function';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_proc
        WHERE proname = 'get_arm_care_assessment'
    ) THEN
        RAISE NOTICE '✅ get_arm_care_assessment function created';
    ELSE
        RAISE EXCEPTION 'Failed to create get_arm_care_assessment function';
    END IF;
END $$;
