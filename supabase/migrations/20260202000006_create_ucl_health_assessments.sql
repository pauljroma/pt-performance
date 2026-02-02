-- ============================================================================
-- CREATE UCL HEALTH ASSESSMENTS SYSTEM - ACP-544
-- ============================================================================
-- Implements weekly UCL (Ulnar Collateral Ligament) health tracking for baseball
-- athletes. Includes symptom monitoring, workload tracking, and risk assessment.
--
-- Date: 2026-02-02
-- Linear: ACP-544
-- ============================================================================

-- =====================================================
-- UCL Health Assessments Table
-- =====================================================

CREATE TABLE IF NOT EXISTS ucl_health_assessments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    assessment_date timestamptz NOT NULL DEFAULT now(),

    -- Medial Elbow Pain Questions
    medial_elbow_pain boolean NOT NULL DEFAULT false,
    medial_pain_severity integer CHECK (medial_pain_severity IS NULL OR (medial_pain_severity >= 1 AND medial_pain_severity <= 10)),
    pain_during_throwing boolean NOT NULL DEFAULT false,
    pain_after_throwing boolean NOT NULL DEFAULT false,
    pain_at_rest boolean NOT NULL DEFAULT false,

    -- Valgus Stress Indicators
    valgus_stress_discomfort boolean NOT NULL DEFAULT false,
    elbow_instability_felt boolean NOT NULL DEFAULT false,
    decreased_velocity boolean NOT NULL DEFAULT false,
    decreased_control_accuracy boolean NOT NULL DEFAULT false,

    -- Neurological Symptoms
    numbness_or_tingling boolean NOT NULL DEFAULT false,
    ring_finger_numbness boolean NOT NULL DEFAULT false,
    pinky_finger_numbness boolean NOT NULL DEFAULT false,

    -- Throwing Workload (past 7 days)
    total_pitch_count integer CHECK (total_pitch_count IS NULL OR total_pitch_count >= 0),
    high_intensity_throws integer CHECK (high_intensity_throws IS NULL OR high_intensity_throws >= 0),
    throwing_days integer CHECK (throwing_days IS NULL OR (throwing_days >= 0 AND throwing_days <= 7)),
    longest_session integer CHECK (longest_session IS NULL OR longest_session >= 0),

    -- Recovery & Fatigue
    arm_fatigue integer NOT NULL DEFAULT 5 CHECK (arm_fatigue >= 1 AND arm_fatigue <= 10),
    recovery_quality integer NOT NULL DEFAULT 3 CHECK (recovery_quality >= 1 AND recovery_quality <= 5),
    adequate_rest_days boolean NOT NULL DEFAULT true,

    -- Calculated Scores (computed by application, stored for history)
    symptom_score numeric(5,2) NOT NULL DEFAULT 0 CHECK (symptom_score >= 0 AND symptom_score <= 100),
    workload_score numeric(5,2) NOT NULL DEFAULT 0 CHECK (workload_score >= 0 AND workload_score <= 100),
    risk_score numeric(5,2) NOT NULL DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_level text NOT NULL DEFAULT 'low' CHECK (risk_level IN ('low', 'moderate', 'high', 'critical')),

    -- Optional notes
    notes text,

    -- Metadata
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes for efficient querying
CREATE INDEX idx_ucl_assessments_patient_date ON ucl_health_assessments(patient_id, assessment_date DESC);
CREATE INDEX idx_ucl_assessments_risk_level ON ucl_health_assessments(risk_level) WHERE risk_level IN ('high', 'critical');
CREATE INDEX idx_ucl_assessments_date ON ucl_health_assessments(assessment_date DESC);

COMMENT ON TABLE ucl_health_assessments IS 'Weekly UCL health assessments for baseball athletes - ACP-544';
COMMENT ON COLUMN ucl_health_assessments.patient_id IS 'Patient/athlete who completed this assessment';
COMMENT ON COLUMN ucl_health_assessments.assessment_date IS 'Date and time of assessment';
COMMENT ON COLUMN ucl_health_assessments.medial_elbow_pain IS 'Whether athlete has pain on inside of elbow';
COMMENT ON COLUMN ucl_health_assessments.medial_pain_severity IS 'Pain severity 1-10 scale if pain present';
COMMENT ON COLUMN ucl_health_assessments.valgus_stress_discomfort IS 'Discomfort during valgus stress test position';
COMMENT ON COLUMN ucl_health_assessments.elbow_instability_felt IS 'Subjective feeling of elbow giving way';
COMMENT ON COLUMN ucl_health_assessments.numbness_or_tingling IS 'Ulnar nerve symptoms in hand/fingers';
COMMENT ON COLUMN ucl_health_assessments.total_pitch_count IS 'Total pitches thrown in past 7 days';
COMMENT ON COLUMN ucl_health_assessments.high_intensity_throws IS 'Throws at >80% effort in past 7 days';
COMMENT ON COLUMN ucl_health_assessments.arm_fatigue IS 'Subjective arm fatigue 1-10 (10=extremely fatigued)';
COMMENT ON COLUMN ucl_health_assessments.recovery_quality IS 'Recovery quality 1-5 (5=excellent)';
COMMENT ON COLUMN ucl_health_assessments.symptom_score IS 'Calculated symptom score 0-100 (higher=more concerning)';
COMMENT ON COLUMN ucl_health_assessments.workload_score IS 'Calculated workload risk score 0-100';
COMMENT ON COLUMN ucl_health_assessments.risk_score IS 'Combined risk score 0-100';
COMMENT ON COLUMN ucl_health_assessments.risk_level IS 'Risk classification: low, moderate, high, critical';

-- =====================================================
-- Auto-update timestamp trigger
-- =====================================================

CREATE OR REPLACE FUNCTION update_ucl_assessment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ucl_assessment_timestamp_trigger
    BEFORE UPDATE ON ucl_health_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_ucl_assessment_timestamp();

-- =====================================================
-- Function: Get UCL Risk Trend
-- =====================================================

CREATE OR REPLACE FUNCTION get_ucl_risk_trend(
    p_patient_id uuid,
    p_weeks integer DEFAULT 8
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
        'weeks_analyzed', p_weeks,
        'current_date', CURRENT_DATE,
        'trend_data', (
            SELECT json_agg(
                json_build_object(
                    'assessment_date', assessment_date,
                    'risk_score', risk_score,
                    'risk_level', risk_level,
                    'symptom_score', symptom_score,
                    'workload_score', workload_score,
                    'total_pitch_count', total_pitch_count
                ) ORDER BY assessment_date DESC
            )
            FROM ucl_health_assessments
            WHERE patient_id = p_patient_id
                AND assessment_date >= CURRENT_DATE - (p_weeks * 7)
            ORDER BY assessment_date DESC
        ),
        'statistics', (
            SELECT json_build_object(
                'avg_risk_score', ROUND(AVG(risk_score), 1),
                'max_risk_score', MAX(risk_score),
                'min_risk_score', MIN(risk_score),
                'avg_symptom_score', ROUND(AVG(symptom_score), 1),
                'avg_workload_score', ROUND(AVG(workload_score), 1),
                'elevated_risk_count', COUNT(*) FILTER (WHERE risk_level IN ('high', 'critical')),
                'total_assessments', COUNT(*)
            )
            FROM ucl_health_assessments
            WHERE patient_id = p_patient_id
                AND assessment_date >= CURRENT_DATE - (p_weeks * 7)
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_ucl_risk_trend IS
    'Get UCL risk trend data and statistics for a patient over the last N weeks (default 8)';

-- =====================================================
-- Function: Check UCL Alert Threshold
-- =====================================================

CREATE OR REPLACE FUNCTION check_ucl_alert_threshold(
    p_patient_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_latest_assessment record;
    v_previous_assessment record;
    v_alert_needed boolean := false;
    v_alert_type text := null;
    v_alert_message text := null;
BEGIN
    -- Get latest assessment
    SELECT * INTO v_latest_assessment
    FROM ucl_health_assessments
    WHERE patient_id = p_patient_id
    ORDER BY assessment_date DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'alert_needed', false,
            'alert_type', null,
            'message', 'No assessments found'
        );
    END IF;

    -- Check for critical risk
    IF v_latest_assessment.risk_level = 'critical' THEN
        v_alert_needed := true;
        v_alert_type := 'critical';
        v_alert_message := 'Critical UCL risk detected. Stop throwing and consult sports medicine.';
    -- Check for high risk
    ELSIF v_latest_assessment.risk_level = 'high' THEN
        v_alert_needed := true;
        v_alert_type := 'high';
        v_alert_message := 'High UCL risk detected. Consider reducing workload and taking rest.';
    -- Check for rapid increase
    ELSE
        SELECT * INTO v_previous_assessment
        FROM ucl_health_assessments
        WHERE patient_id = p_patient_id
            AND assessment_date < v_latest_assessment.assessment_date
        ORDER BY assessment_date DESC
        LIMIT 1;

        IF FOUND AND (v_latest_assessment.risk_score - v_previous_assessment.risk_score) >= 20 THEN
            v_alert_needed := true;
            v_alert_type := 'increase';
            v_alert_message := 'Significant increase in UCL risk score detected. Monitor closely.';
        END IF;
    END IF;

    RETURN json_build_object(
        'alert_needed', v_alert_needed,
        'alert_type', v_alert_type,
        'message', v_alert_message,
        'latest_risk_score', v_latest_assessment.risk_score,
        'latest_risk_level', v_latest_assessment.risk_level,
        'assessment_date', v_latest_assessment.assessment_date
    );
END;
$$;

COMMENT ON FUNCTION check_ucl_alert_threshold IS
    'Check if UCL risk has crossed alert thresholds for a patient';

-- =====================================================
-- Function: Get Workload Summary
-- =====================================================

CREATE OR REPLACE FUNCTION get_ucl_workload_summary(
    p_patient_id uuid,
    p_weeks integer DEFAULT 4
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
        'weeks_analyzed', p_weeks,
        'total_pitches', COALESCE(SUM(total_pitch_count), 0),
        'avg_weekly_pitches', ROUND(COALESCE(AVG(total_pitch_count), 0), 0),
        'max_weekly_pitches', COALESCE(MAX(total_pitch_count), 0),
        'total_high_intensity', COALESCE(SUM(high_intensity_throws), 0),
        'avg_throwing_days', ROUND(COALESCE(AVG(throwing_days), 0), 1),
        'avg_arm_fatigue', ROUND(COALESCE(AVG(arm_fatigue), 0), 1),
        'avg_recovery_quality', ROUND(COALESCE(AVG(recovery_quality), 0), 1),
        'weeks_with_data', COUNT(*)
    ) INTO v_result
    FROM ucl_health_assessments
    WHERE patient_id = p_patient_id
        AND assessment_date >= CURRENT_DATE - (p_weeks * 7);

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_ucl_workload_summary IS
    'Get workload summary statistics for a patient over the last N weeks';

-- =====================================================
-- Row-Level Security (RLS)
-- =====================================================

ALTER TABLE ucl_health_assessments ENABLE ROW LEVEL SECURITY;

-- Patients can view their own assessments
CREATE POLICY "Patients can view their own UCL assessments"
    ON ucl_health_assessments FOR SELECT
    USING (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

-- Patients can insert their own assessments
CREATE POLICY "Patients can create their own UCL assessments"
    ON ucl_health_assessments FOR INSERT
    WITH CHECK (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

-- Patients can update their own assessments
CREATE POLICY "Patients can update their own UCL assessments"
    ON ucl_health_assessments FOR UPDATE
    USING (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ))
    WITH CHECK (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

-- Patients can delete their own assessments
CREATE POLICY "Patients can delete their own UCL assessments"
    ON ucl_health_assessments FOR DELETE
    USING (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

-- Therapists can view all patient assessments (for monitoring)
CREATE POLICY "Therapists can view all UCL assessments"
    ON ucl_health_assessments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.user_id = auth.uid()
        )
    );

-- Service role has full access
CREATE POLICY "Service role can manage all UCL assessments"
    ON ucl_health_assessments FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- Grant Permissions
-- =====================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON ucl_health_assessments TO authenticated;
GRANT ALL ON ucl_health_assessments TO service_role;

GRANT EXECUTE ON FUNCTION get_ucl_risk_trend TO authenticated;
GRANT EXECUTE ON FUNCTION check_ucl_alert_threshold TO authenticated;
GRANT EXECUTE ON FUNCTION get_ucl_workload_summary TO authenticated;
GRANT EXECUTE ON FUNCTION update_ucl_assessment_timestamp TO authenticated;

-- =====================================================
-- Verification
-- =====================================================

DO $$
DECLARE
    v_table_exists boolean;
    v_trigger_exists boolean;
    v_function_count integer;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'ucl_health_assessments'
    ) INTO v_table_exists;

    SELECT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'update_ucl_assessment_timestamp_trigger'
    ) INTO v_trigger_exists;

    SELECT COUNT(*) INTO v_function_count
    FROM pg_proc
    WHERE proname IN ('get_ucl_risk_trend', 'check_ucl_alert_threshold', 'get_ucl_workload_summary');

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'UCL HEALTH ASSESSMENTS SYSTEM CREATED - ACP-544';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Table Created: %', v_table_exists;
    RAISE NOTICE 'Trigger Created: %', v_trigger_exists;
    RAISE NOTICE 'Functions Created: %/3', v_function_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Features:';
    RAISE NOTICE '  - Weekly UCL health check-in questionnaire';
    RAISE NOTICE '  - Symptom tracking (pain, numbness, instability)';
    RAISE NOTICE '  - Workload monitoring (pitch count, intensity)';
    RAISE NOTICE '  - Risk score calculation (low/moderate/high/critical)';
    RAISE NOTICE '  - Trend analysis and alert thresholds';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies:';
    RAISE NOTICE '  - Patients: Full CRUD on own assessments';
    RAISE NOTICE '  - Therapists: Read-only access to all assessments';
    RAISE NOTICE '  - Service role: Full access';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions:';
    RAISE NOTICE '  - get_ucl_risk_trend(patient_id, weeks)';
    RAISE NOTICE '  - check_ucl_alert_threshold(patient_id)';
    RAISE NOTICE '  - get_ucl_workload_summary(patient_id, weeks)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'UCL HEALTH ASSESSMENTS READY';
    RAISE NOTICE '============================================================================';
END $$;
