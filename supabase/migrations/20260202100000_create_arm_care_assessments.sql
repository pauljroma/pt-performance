-- ACP-522: Arm Care Daily Assessment Table
-- 30-second shoulder/elbow check with traffic light system
-- Created: 2026-02-02

-- ============================================================================
-- ARM CARE ASSESSMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.arm_care_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Shoulder metrics (0-10 scale, higher is better)
    -- 0 = severe issue, 10 = no issue
    shoulder_pain_score INTEGER NOT NULL CHECK (shoulder_pain_score >= 0 AND shoulder_pain_score <= 10),
    shoulder_stiffness_score INTEGER NOT NULL CHECK (shoulder_stiffness_score >= 0 AND shoulder_stiffness_score <= 10),
    shoulder_strength_score INTEGER NOT NULL CHECK (shoulder_strength_score >= 0 AND shoulder_strength_score <= 10),

    -- Elbow metrics (0-10 scale, higher is better)
    elbow_pain_score INTEGER NOT NULL CHECK (elbow_pain_score >= 0 AND elbow_pain_score <= 10),
    elbow_tightness_score INTEGER NOT NULL CHECK (elbow_tightness_score >= 0 AND elbow_tightness_score <= 10),
    valgus_stress_score INTEGER NOT NULL CHECK (valgus_stress_score >= 0 AND valgus_stress_score <= 10),

    -- Computed scores (calculated by trigger)
    shoulder_score NUMERIC(4,2) NOT NULL,
    elbow_score NUMERIC(4,2) NOT NULL,
    overall_score NUMERIC(4,2) NOT NULL,

    -- Traffic light status
    -- green (8-10): Full workout OK
    -- yellow (5-7): Reduce throwing volume 50%, extra arm care
    -- red (0-4): No throwing, recovery protocol only
    traffic_light TEXT NOT NULL CHECK (traffic_light IN ('green', 'yellow', 'red')),

    -- Optional pain locations (JSONB array)
    pain_locations JSONB DEFAULT '[]'::jsonb,

    -- Optional notes
    notes TEXT,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- One assessment per patient per day
    CONSTRAINT arm_care_assessments_patient_date_unique UNIQUE (patient_id, date)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Patient lookups
CREATE INDEX IF NOT EXISTS idx_arm_care_assessments_patient_id
    ON public.arm_care_assessments(patient_id);

-- Date range queries
CREATE INDEX IF NOT EXISTS idx_arm_care_assessments_date
    ON public.arm_care_assessments(date DESC);

-- Combined patient + date for efficient daily lookups
CREATE INDEX IF NOT EXISTS idx_arm_care_assessments_patient_date
    ON public.arm_care_assessments(patient_id, date DESC);

-- Traffic light filtering
CREATE INDEX IF NOT EXISTS idx_arm_care_assessments_traffic_light
    ON public.arm_care_assessments(traffic_light);

-- ============================================================================
-- TRIGGER: Calculate Scores and Traffic Light
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_arm_care_scores()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Calculate shoulder score (average of 3 shoulder metrics)
    NEW.shoulder_score := (NEW.shoulder_pain_score + NEW.shoulder_stiffness_score + NEW.shoulder_strength_score)::NUMERIC / 3.0;

    -- Calculate elbow score (average of 3 elbow metrics)
    NEW.elbow_score := (NEW.elbow_pain_score + NEW.elbow_tightness_score + NEW.valgus_stress_score)::NUMERIC / 3.0;

    -- Calculate overall score (average of shoulder and elbow)
    NEW.overall_score := (NEW.shoulder_score + NEW.elbow_score) / 2.0;

    -- Determine traffic light based on overall score
    -- Green (8-10): Full workout OK
    -- Yellow (5-7): Reduce throwing 50%
    -- Red (0-4): No throwing
    IF NEW.overall_score >= 8 THEN
        NEW.traffic_light := 'green';
    ELSIF NEW.overall_score >= 5 THEN
        NEW.traffic_light := 'yellow';
    ELSE
        NEW.traffic_light := 'red';
    END IF;

    -- Update timestamp
    NEW.updated_at := NOW();

    RETURN NEW;
END;
$$;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_calculate_arm_care_scores ON public.arm_care_assessments;
CREATE TRIGGER trigger_calculate_arm_care_scores
    BEFORE INSERT OR UPDATE ON public.arm_care_assessments
    FOR EACH ROW
    EXECUTE FUNCTION calculate_arm_care_scores();

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE public.arm_care_assessments ENABLE ROW LEVEL SECURITY;

-- Patients can view and manage their own assessments
CREATE POLICY "Patients can view own arm care assessments"
    ON public.arm_care_assessments
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Patients can insert own arm care assessments"
    ON public.arm_care_assessments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Patients can update own arm care assessments"
    ON public.arm_care_assessments
    FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Patients can delete own arm care assessments"
    ON public.arm_care_assessments
    FOR DELETE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can view their patients' assessments
CREATE POLICY "Therapists can view patient arm care assessments"
    ON public.arm_care_assessments
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM public.patients p
            JOIN public.therapists t ON p.therapist_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- ============================================================================
-- RPC: Get Arm Care Trend
-- ============================================================================

CREATE OR REPLACE FUNCTION get_arm_care_trend(
    p_patient_id UUID,
    p_days INTEGER DEFAULT 7
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
    v_assessments JSONB;
    v_statistics JSONB;
    v_green_days INTEGER;
    v_yellow_days INTEGER;
    v_red_days INTEGER;
    v_avg_overall NUMERIC;
    v_avg_shoulder NUMERIC;
    v_avg_elbow NUMERIC;
    v_total INTEGER;
    v_trend TEXT;
    v_first_half_avg NUMERIC;
    v_second_half_avg NUMERIC;
BEGIN
    -- Get assessments for the period
    SELECT jsonb_agg(
        jsonb_build_object(
            'date', a.date,
            'overall_score', a.overall_score,
            'shoulder_score', a.shoulder_score,
            'elbow_score', a.elbow_score,
            'traffic_light', a.traffic_light
        ) ORDER BY a.date
    )
    INTO v_assessments
    FROM public.arm_care_assessments a
    WHERE a.patient_id = p_patient_id
      AND a.date >= CURRENT_DATE - (p_days || ' days')::INTERVAL;

    -- Calculate traffic light counts
    SELECT
        COUNT(*) FILTER (WHERE traffic_light = 'green'),
        COUNT(*) FILTER (WHERE traffic_light = 'yellow'),
        COUNT(*) FILTER (WHERE traffic_light = 'red'),
        COUNT(*),
        AVG(overall_score),
        AVG(shoulder_score),
        AVG(elbow_score)
    INTO
        v_green_days, v_yellow_days, v_red_days, v_total,
        v_avg_overall, v_avg_shoulder, v_avg_elbow
    FROM public.arm_care_assessments
    WHERE patient_id = p_patient_id
      AND date >= CURRENT_DATE - (p_days || ' days')::INTERVAL;

    -- Calculate trend direction
    IF v_total >= 3 THEN
        SELECT AVG(overall_score)
        INTO v_first_half_avg
        FROM (
            SELECT overall_score
            FROM public.arm_care_assessments
            WHERE patient_id = p_patient_id
              AND date >= CURRENT_DATE - (p_days || ' days')::INTERVAL
            ORDER BY date
            LIMIT v_total / 2
        ) first_half;

        SELECT AVG(overall_score)
        INTO v_second_half_avg
        FROM (
            SELECT overall_score
            FROM public.arm_care_assessments
            WHERE patient_id = p_patient_id
              AND date >= CURRENT_DATE - (p_days || ' days')::INTERVAL
            ORDER BY date DESC
            LIMIT v_total / 2
        ) second_half;

        IF v_second_half_avg - v_first_half_avg > 0.5 THEN
            v_trend := 'improving';
        ELSIF v_second_half_avg - v_first_half_avg < -0.5 THEN
            v_trend := 'declining';
        ELSE
            v_trend := 'stable';
        END IF;
    ELSE
        v_trend := 'stable';
    END IF;

    -- Build statistics object
    v_statistics := jsonb_build_object(
        'avg_overall_score', v_avg_overall,
        'avg_shoulder_score', v_avg_shoulder,
        'avg_elbow_score', v_avg_elbow,
        'green_days', v_green_days,
        'yellow_days', v_yellow_days,
        'red_days', v_red_days,
        'total_assessments', v_total,
        'trend_direction', v_trend
    );

    -- Build final result
    v_result := jsonb_build_object(
        'patient_id', p_patient_id,
        'days_analyzed', p_days,
        'assessments', COALESCE(v_assessments, '[]'::jsonb),
        'statistics', v_statistics
    );

    RETURN v_result;
END;
$$;

-- ============================================================================
-- RPC: Get Today's Workout Modifications
-- ============================================================================

CREATE OR REPLACE FUNCTION get_arm_care_workout_modifications(
    p_patient_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_assessment RECORD;
    v_modifications JSONB;
    v_recommendations TEXT[];
    v_warnings TEXT[];
BEGIN
    -- Get today's assessment
    SELECT *
    INTO v_assessment
    FROM public.arm_care_assessments
    WHERE patient_id = p_patient_id
      AND date = CURRENT_DATE
    LIMIT 1;

    -- If no assessment, return default caution
    IF v_assessment IS NULL THEN
        RETURN jsonb_build_object(
            'has_assessment', false,
            'traffic_light', 'yellow',
            'throwing_volume_multiplier', 0.75,
            'recommendations', ARRAY['Complete arm care assessment for personalized recommendations'],
            'warnings', ARRAY[]::TEXT[]
        );
    END IF;

    -- Build recommendations based on traffic light
    CASE v_assessment.traffic_light
        WHEN 'green' THEN
            v_recommendations := ARRAY[
                'Full throwing program approved',
                'Continue normal arm care routine',
                'Monitor any changes during activity'
            ];
            v_warnings := ARRAY[]::TEXT[];

        WHEN 'yellow' THEN
            v_recommendations := ARRAY[
                'Reduce throwing volume by 50%',
                'Add 10-15 minutes of extra arm care',
                'Focus on controlled movements',
                'Use lighter intensity throws'
            ];

            IF v_assessment.shoulder_score < v_assessment.elbow_score THEN
                v_warnings := ARRAY['Shoulder requires extra attention today'];
                v_recommendations := array_append(v_recommendations, 'Prioritize shoulder mobility work');
            ELSIF v_assessment.elbow_score < v_assessment.shoulder_score THEN
                v_warnings := ARRAY['Elbow requires extra attention today'];
                v_recommendations := array_append(v_recommendations, 'Add forearm and wrist stretches');
            ELSE
                v_warnings := ARRAY[]::TEXT[];
            END IF;

        WHEN 'red' THEN
            v_recommendations := ARRAY[
                'No throwing today - rest the arm',
                'Complete recovery protocol exercises',
                'Apply ice/heat as needed',
                'Consider light range of motion work only'
            ];
            v_warnings := ARRAY[
                'Arm needs recovery - avoid high-stress movements',
                'If pain persists, consult your therapist'
            ];

            IF v_assessment.shoulder_score <= 4 THEN
                v_warnings := array_append(v_warnings, 'Shoulder pain is elevated - prioritize rest');
            END IF;
            IF v_assessment.elbow_score <= 4 THEN
                v_warnings := array_append(v_warnings, 'Elbow discomfort detected - no valgus stress');
            END IF;
    END CASE;

    -- Build result
    v_modifications := jsonb_build_object(
        'has_assessment', true,
        'assessment_id', v_assessment.id,
        'date', v_assessment.date,
        'traffic_light', v_assessment.traffic_light,
        'overall_score', v_assessment.overall_score,
        'shoulder_score', v_assessment.shoulder_score,
        'elbow_score', v_assessment.elbow_score,
        'throwing_volume_multiplier',
            CASE v_assessment.traffic_light
                WHEN 'green' THEN 1.0
                WHEN 'yellow' THEN 0.5
                WHEN 'red' THEN 0.0
            END,
        'extra_arm_care_required', v_assessment.traffic_light IN ('yellow', 'red'),
        'recovery_protocol_required', v_assessment.traffic_light = 'red',
        'recommendations', v_recommendations,
        'warnings', v_warnings
    );

    RETURN v_modifications;
END;
$$;

-- ============================================================================
-- VIEW: Arm Care Dashboard
-- ============================================================================

CREATE OR REPLACE VIEW public.vw_arm_care_dashboard AS
SELECT
    p.id AS patient_id,
    p.first_name,
    p.last_name,
    p.therapist_id,
    aca.date AS last_assessment_date,
    aca.overall_score AS last_overall_score,
    aca.shoulder_score AS last_shoulder_score,
    aca.elbow_score AS last_elbow_score,
    aca.traffic_light AS last_traffic_light,
    (
        SELECT COUNT(*)
        FROM public.arm_care_assessments
        WHERE patient_id = p.id
          AND date >= CURRENT_DATE - INTERVAL '7 days'
    ) AS assessments_last_7_days,
    (
        SELECT COUNT(*) FILTER (WHERE traffic_light = 'red')
        FROM public.arm_care_assessments
        WHERE patient_id = p.id
          AND date >= CURRENT_DATE - INTERVAL '7 days'
    ) AS red_days_last_7
FROM public.patients p
LEFT JOIN LATERAL (
    SELECT *
    FROM public.arm_care_assessments
    WHERE patient_id = p.id
    ORDER BY date DESC
    LIMIT 1
) aca ON true;

-- Grant access to authenticated users
GRANT SELECT ON public.vw_arm_care_dashboard TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.arm_care_assessments IS 'ACP-522: Daily arm care assessments for baseball/throwing athletes with traffic light system';
COMMENT ON COLUMN public.arm_care_assessments.traffic_light IS 'green (8-10): Full workout OK, yellow (5-7): 50% volume + extra care, red (0-4): No throwing, recovery only';
COMMENT ON FUNCTION get_arm_care_trend IS 'Returns arm care trend data for a patient over specified days';
COMMENT ON FUNCTION get_arm_care_workout_modifications IS 'Returns workout modifications based on todays arm care assessment';
