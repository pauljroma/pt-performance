-- Create Readiness Adjustments System
-- Implements auto-regulation based on recovery metrics (WHOOP, sleep, HRV)
-- ACP-215, ACP-216, ACP-217, ACP-218, ACP-219
-- Build 69 - Agent 15: Readiness Adjustment Backend

BEGIN;

-- ============================================================================
-- 1. READINESS METRICS TABLE
-- ============================================================================
-- Stores raw readiness data from wearables (WHOOP, Apple Watch, Oura, etc.)

CREATE TABLE IF NOT EXISTS public.readiness_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,

    -- Timestamp
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metric_date DATE NOT NULL,

    -- Recovery metrics (0-100 scale)
    recovery_score NUMERIC CHECK (recovery_score >= 0 AND recovery_score <= 100),
    hrv_score NUMERIC CHECK (hrv_score >= 0 AND hrv_score <= 100),
    sleep_score NUMERIC CHECK (sleep_score >= 0 AND sleep_score <= 100),
    resting_heart_rate NUMERIC,

    -- Sleep details (minutes)
    total_sleep_duration_minutes INT,
    deep_sleep_duration_minutes INT,
    rem_sleep_duration_minutes INT,
    sleep_efficiency_pct NUMERIC,

    -- HRV details (milliseconds)
    hrv_rmssd NUMERIC, -- Root mean square of successive differences
    hrv_avg NUMERIC,   -- Average HRV

    -- Strain/activity metrics
    strain_score NUMERIC,
    activity_minutes INT,
    calories_burned INT,

    -- Data source
    source TEXT NOT NULL CHECK (source IN ('whoop', 'apple_watch', 'oura', 'manual', 'system')),
    source_metadata JSONB DEFAULT '{}'::jsonb,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    UNIQUE(patient_id, metric_date, source)
);

-- Indexes for performance
CREATE INDEX idx_readiness_metrics_patient_id ON public.readiness_metrics(patient_id);
CREATE INDEX idx_readiness_metrics_metric_date ON public.readiness_metrics(metric_date DESC);
CREATE INDEX idx_readiness_metrics_patient_date ON public.readiness_metrics(patient_id, metric_date DESC);
CREATE INDEX idx_readiness_metrics_source ON public.readiness_metrics(source);

-- Comments
COMMENT ON TABLE public.readiness_metrics IS 'Stores readiness data from wearables for workout auto-regulation';
COMMENT ON COLUMN public.readiness_metrics.recovery_score IS 'Overall recovery score 0-100 (primary metric for adjustments)';
COMMENT ON COLUMN public.readiness_metrics.hrv_rmssd IS 'HRV RMSSD in milliseconds - key indicator of autonomic recovery';
COMMENT ON COLUMN public.readiness_metrics.source_metadata IS 'Additional source-specific data in JSON format';

-- ============================================================================
-- 2. READINESS ADJUSTMENTS TABLE
-- ============================================================================
-- Stores calculated adjustments and their application to workouts

CREATE TABLE IF NOT EXISTS public.readiness_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,

    -- Adjustment details
    adjustment_date DATE NOT NULL,
    session_id UUID REFERENCES public.sessions(id) ON DELETE SET NULL,

    -- Input metrics (from readiness_metrics)
    recovery_score NUMERIC NOT NULL,
    hrv_score NUMERIC,
    sleep_score NUMERIC,
    strain_score NUMERIC,

    -- Calculated adjustment multiplier (0.7 - 1.3)
    volume_multiplier NUMERIC NOT NULL CHECK (volume_multiplier >= 0.5 AND volume_multiplier <= 1.5),
    intensity_multiplier NUMERIC NOT NULL CHECK (intensity_multiplier >= 0.5 AND intensity_multiplier <= 1.5),

    -- Adjustment category
    readiness_category TEXT NOT NULL CHECK (readiness_category IN ('optimal', 'good', 'moderate', 'low', 'critical')),

    -- Practitioner override
    is_overridden BOOLEAN DEFAULT FALSE,
    override_reason TEXT,
    overridden_by UUID REFERENCES auth.users(id),
    overridden_at TIMESTAMPTZ,
    original_volume_multiplier NUMERIC,
    original_intensity_multiplier NUMERIC,

    -- Application status
    status TEXT NOT NULL DEFAULT 'calculated' CHECK (status IN ('calculated', 'applied', 'overridden', 'expired')),
    applied_at TIMESTAMPTZ,

    -- Algorithm details
    algorithm_version TEXT NOT NULL DEFAULT 'v1.0',
    calculation_metadata JSONB DEFAULT '{}'::jsonb,

    -- Recommendations
    recommendations TEXT[],
    warnings TEXT[],

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),

    -- Constraints
    UNIQUE(patient_id, adjustment_date)
);

-- Indexes for performance
CREATE INDEX idx_readiness_adjustments_patient_id ON public.readiness_adjustments(patient_id);
CREATE INDEX idx_readiness_adjustments_date ON public.readiness_adjustments(adjustment_date DESC);
CREATE INDEX idx_readiness_adjustments_session_id ON public.readiness_adjustments(session_id);
CREATE INDEX idx_readiness_adjustments_patient_date ON public.readiness_adjustments(patient_id, adjustment_date DESC);
CREATE INDEX idx_readiness_adjustments_category ON public.readiness_adjustments(readiness_category);
CREATE INDEX idx_readiness_adjustments_status ON public.readiness_adjustments(status);
CREATE INDEX idx_readiness_adjustments_overridden ON public.readiness_adjustments(is_overridden) WHERE is_overridden = TRUE;

-- Comments
COMMENT ON TABLE public.readiness_adjustments IS 'Calculated workout adjustments based on readiness metrics';
COMMENT ON COLUMN public.readiness_adjustments.volume_multiplier IS 'Volume adjustment: 0.7-1.3x (e.g., 0.85 = 85% of prescribed volume)';
COMMENT ON COLUMN public.readiness_adjustments.intensity_multiplier IS 'Intensity adjustment: 0.7-1.3x (e.g., 1.15 = 115% of prescribed intensity)';
COMMENT ON COLUMN public.readiness_adjustments.readiness_category IS 'Readiness band: optimal (90-100), good (75-89), moderate (60-74), low (40-59), critical (<40)';
COMMENT ON COLUMN public.readiness_adjustments.calculation_metadata IS 'Algorithm inputs, thresholds, and decision factors';

-- ============================================================================
-- 3. ADJUSTMENT CALCULATION FUNCTION
-- ============================================================================
-- Calculates volume/intensity multipliers based on recovery score

CREATE OR REPLACE FUNCTION public.calculate_adjustment_multipliers(
    p_recovery_score NUMERIC,
    p_hrv_score NUMERIC DEFAULT NULL,
    p_sleep_score NUMERIC DEFAULT NULL,
    p_strain_score NUMERIC DEFAULT NULL
)
RETURNS TABLE (
    volume_multiplier NUMERIC,
    intensity_multiplier NUMERIC,
    readiness_category TEXT,
    recommendations TEXT[],
    warnings TEXT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_composite_score NUMERIC;
    v_volume_mult NUMERIC;
    v_intensity_mult NUMERIC;
    v_category TEXT;
    v_recommendations TEXT[] := ARRAY[]::TEXT[];
    v_warnings TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Calculate composite score (weighted average)
    -- Recovery score: 50%, HRV: 25%, Sleep: 20%, Strain consideration: 5%
    v_composite_score := p_recovery_score * 0.5;

    IF p_hrv_score IS NOT NULL THEN
        v_composite_score := v_composite_score + (p_hrv_score * 0.25);
    ELSE
        v_composite_score := v_composite_score + (p_recovery_score * 0.25); -- Use recovery as fallback
    END IF;

    IF p_sleep_score IS NOT NULL THEN
        v_composite_score := v_composite_score + (p_sleep_score * 0.20);
    ELSE
        v_composite_score := v_composite_score + (p_recovery_score * 0.20); -- Use recovery as fallback
    END IF;

    -- Strain consideration (inverse relationship - high strain = reduce adjustment)
    IF p_strain_score IS NOT NULL AND p_strain_score > 15 THEN
        v_composite_score := v_composite_score - (LEAST((p_strain_score - 15) / 2, 10)); -- Cap reduction at 10 points
        v_warnings := array_append(v_warnings, 'High accumulated strain detected - conservative adjustment applied');
    END IF;

    -- Ensure composite score stays in valid range
    v_composite_score := GREATEST(0, LEAST(100, v_composite_score));

    -- Calculate multipliers based on composite score
    -- Optimal (90-100): 1.1-1.3x volume, 1.0-1.15x intensity
    IF v_composite_score >= 90 THEN
        v_volume_mult := 1.1 + ((v_composite_score - 90) / 100); -- 1.1 to 1.2
        v_intensity_mult := 1.0 + ((v_composite_score - 90) / 66.67); -- 1.0 to 1.15
        v_category := 'optimal';
        v_recommendations := ARRAY[
            'Excellent recovery - consider progressive overload',
            'Optimal conditions for skill work and technique refinement',
            'Good day for testing maximal efforts or PRs'
        ];

    -- Good (75-89): 1.0-1.1x volume, 0.95-1.0x intensity
    ELSIF v_composite_score >= 75 THEN
        v_volume_mult := 1.0 + ((v_composite_score - 75) / 140); -- 1.0 to 1.1
        v_intensity_mult := 0.95 + ((v_composite_score - 75) / 280); -- 0.95 to 1.0
        v_category := 'good';
        v_recommendations := ARRAY[
            'Good recovery - proceed with planned training',
            'Monitor RPE and adjust within session if needed',
            'Consider adding optional accessory work'
        ];

    -- Moderate (60-74): 0.85-1.0x volume, 0.85-0.95x intensity
    ELSIF v_composite_score >= 60 THEN
        v_volume_mult := 0.85 + ((v_composite_score - 60) / 93.33); -- 0.85 to 1.0
        v_intensity_mult := 0.85 + ((v_composite_score - 60) / 140); -- 0.85 to 0.95
        v_category := 'moderate';
        v_recommendations := ARRAY[
            'Moderate recovery - reduce volume and intensity slightly',
            'Focus on movement quality over load',
            'Consider eliminating optional exercises',
            'Monitor for pain or excessive fatigue'
        ];
        v_warnings := array_append(v_warnings, 'Moderate readiness - conservative adjustments recommended');

    -- Low (40-59): 0.7-0.85x volume, 0.7-0.85x intensity
    ELSIF v_composite_score >= 40 THEN
        v_volume_mult := 0.7 + ((v_composite_score - 40) / 133.33); -- 0.7 to 0.85
        v_intensity_mult := 0.7 + ((v_composite_score - 40) / 133.33); -- 0.7 to 0.85
        v_category := 'low';
        v_recommendations := ARRAY[
            'Low recovery - significant reduction recommended',
            'Focus on movement practice and technique',
            'Consider active recovery or mobility work instead',
            'Prioritize primary movements only'
        ];
        v_warnings := array_append(v_warnings, 'Low readiness - consider deload or active recovery day');

    -- Critical (<40): 0.5-0.7x volume, 0.5-0.7x intensity
    ELSE
        v_volume_mult := 0.5 + (v_composite_score / 133.33); -- 0.5 to 0.7
        v_intensity_mult := 0.5 + (v_composite_score / 133.33); -- 0.5 to 0.7
        v_category := 'critical';
        v_recommendations := ARRAY[
            'Critical recovery state - strongly consider rest day',
            'If training, use very light loads (technique only)',
            'Prioritize recovery: sleep, nutrition, stress management',
            'Monitor for illness or overtraining symptoms'
        ];
        v_warnings := array_append(v_warnings, 'CRITICAL readiness - rest day strongly recommended');
        v_warnings := array_append(v_warnings, 'Consult with practitioner before proceeding');
    END IF;

    -- Add HRV-specific warnings
    IF p_hrv_score IS NOT NULL AND p_hrv_score < 40 THEN
        v_warnings := array_append(v_warnings, 'Very low HRV - autonomic stress detected');
    END IF;

    -- Add sleep-specific warnings
    IF p_sleep_score IS NOT NULL AND p_sleep_score < 50 THEN
        v_warnings := array_append(v_warnings, 'Poor sleep quality - increased injury risk');
    END IF;

    -- Round multipliers to 2 decimal places
    v_volume_mult := ROUND(v_volume_mult::numeric, 2);
    v_intensity_mult := ROUND(v_intensity_mult::numeric, 2);

    RETURN QUERY SELECT v_volume_mult, v_intensity_mult, v_category, v_recommendations, v_warnings;
END;
$$;

COMMENT ON FUNCTION public.calculate_adjustment_multipliers IS 'Calculates volume/intensity multipliers from readiness metrics using composite scoring algorithm';

-- ============================================================================
-- 4. CREATE ADJUSTMENT FUNCTION
-- ============================================================================
-- Creates or updates an adjustment record for a patient

CREATE OR REPLACE FUNCTION public.create_readiness_adjustment(
    p_patient_id UUID,
    p_adjustment_date DATE,
    p_session_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_adjustment_id UUID;
    v_metrics RECORD;
    v_multipliers RECORD;
BEGIN
    -- Get most recent readiness metrics for the date
    SELECT *
    INTO v_metrics
    FROM public.readiness_metrics
    WHERE patient_id = p_patient_id
        AND metric_date = p_adjustment_date
    ORDER BY recovery_score DESC NULLS LAST, recorded_at DESC
    LIMIT 1;

    -- If no metrics found, return NULL
    IF v_metrics IS NULL THEN
        RAISE NOTICE 'No readiness metrics found for patient % on date %', p_patient_id, p_adjustment_date;
        RETURN NULL;
    END IF;

    -- Calculate multipliers
    SELECT *
    INTO v_multipliers
    FROM public.calculate_adjustment_multipliers(
        v_metrics.recovery_score,
        v_metrics.hrv_score,
        v_metrics.sleep_score,
        v_metrics.strain_score
    );

    -- Insert or update adjustment
    INSERT INTO public.readiness_adjustments (
        patient_id,
        adjustment_date,
        session_id,
        recovery_score,
        hrv_score,
        sleep_score,
        strain_score,
        volume_multiplier,
        intensity_multiplier,
        readiness_category,
        recommendations,
        warnings,
        calculation_metadata,
        created_by
    ) VALUES (
        p_patient_id,
        p_adjustment_date,
        p_session_id,
        v_metrics.recovery_score,
        v_metrics.hrv_score,
        v_metrics.sleep_score,
        v_metrics.strain_score,
        v_multipliers.volume_multiplier,
        v_multipliers.intensity_multiplier,
        v_multipliers.readiness_category,
        v_multipliers.recommendations,
        v_multipliers.warnings,
        jsonb_build_object(
            'source', v_metrics.source,
            'recorded_at', v_metrics.recorded_at,
            'composite_inputs', jsonb_build_object(
                'recovery_weight', 0.5,
                'hrv_weight', 0.25,
                'sleep_weight', 0.20
            )
        ),
        auth.uid()
    )
    ON CONFLICT (patient_id, adjustment_date)
    DO UPDATE SET
        session_id = EXCLUDED.session_id,
        recovery_score = EXCLUDED.recovery_score,
        hrv_score = EXCLUDED.hrv_score,
        sleep_score = EXCLUDED.sleep_score,
        strain_score = EXCLUDED.strain_score,
        volume_multiplier = EXCLUDED.volume_multiplier,
        intensity_multiplier = EXCLUDED.intensity_multiplier,
        readiness_category = EXCLUDED.readiness_category,
        recommendations = EXCLUDED.recommendations,
        warnings = EXCLUDED.warnings,
        calculation_metadata = EXCLUDED.calculation_metadata,
        updated_at = NOW()
    WHERE public.readiness_adjustments.is_overridden = FALSE
    RETURNING id INTO v_adjustment_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        'CREATE',
        'readiness_adjustment',
        v_adjustment_id,
        'calculate_adjustment',
        format('Readiness adjustment calculated: %s (volume: %sx, intensity: %sx)',
               v_multipliers.readiness_category,
               v_multipliers.volume_multiplier,
               v_multipliers.intensity_multiplier),
        p_patient_id,
        NULL,
        jsonb_build_object('adjustment_id', v_adjustment_id),
        FALSE,
        'DATA_MODIFICATION'
    );

    RETURN v_adjustment_id;
END;
$$;

COMMENT ON FUNCTION public.create_readiness_adjustment IS 'Creates adjustment record from latest readiness metrics';

-- ============================================================================
-- 5. OVERRIDE ADJUSTMENT FUNCTION
-- ============================================================================
-- Allows practitioners to override calculated adjustments

CREATE OR REPLACE FUNCTION public.override_readiness_adjustment(
    p_adjustment_id UUID,
    p_volume_multiplier NUMERIC,
    p_intensity_multiplier NUMERIC,
    p_override_reason TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_original_volume NUMERIC;
    v_original_intensity NUMERIC;
    v_patient_id UUID;
BEGIN
    -- Get original values
    SELECT volume_multiplier, intensity_multiplier, patient_id
    INTO v_original_volume, v_original_intensity, v_patient_id
    FROM public.readiness_adjustments
    WHERE id = p_adjustment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Adjustment not found: %', p_adjustment_id;
    END IF;

    -- Validate multipliers
    IF p_volume_multiplier < 0.5 OR p_volume_multiplier > 1.5 THEN
        RAISE EXCEPTION 'Volume multiplier must be between 0.5 and 1.5';
    END IF;

    IF p_intensity_multiplier < 0.5 OR p_intensity_multiplier > 1.5 THEN
        RAISE EXCEPTION 'Intensity multiplier must be between 0.5 and 1.5';
    END IF;

    -- Update adjustment
    UPDATE public.readiness_adjustments
    SET
        is_overridden = TRUE,
        override_reason = p_override_reason,
        overridden_by = auth.uid(),
        overridden_at = NOW(),
        original_volume_multiplier = v_original_volume,
        original_intensity_multiplier = v_original_intensity,
        volume_multiplier = p_volume_multiplier,
        intensity_multiplier = p_intensity_multiplier,
        status = 'overridden',
        updated_at = NOW()
    WHERE id = p_adjustment_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        'UPDATE',
        'readiness_adjustment',
        p_adjustment_id,
        'override_adjustment',
        format('Practitioner override: volume %s→%s, intensity %s→%s. Reason: %s',
               v_original_volume, p_volume_multiplier,
               v_original_intensity, p_intensity_multiplier,
               p_override_reason),
        v_patient_id,
        jsonb_build_object('volume_multiplier', v_original_volume, 'intensity_multiplier', v_original_intensity),
        jsonb_build_object('volume_multiplier', p_volume_multiplier, 'intensity_multiplier', p_intensity_multiplier),
        FALSE,
        'DATA_MODIFICATION'
    );

    RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION public.override_readiness_adjustment IS 'Allows practitioners to override calculated adjustments with audit trail';

-- ============================================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS on readiness_metrics
ALTER TABLE public.readiness_metrics ENABLE ROW LEVEL SECURITY;

-- Patients can view and insert their own metrics
CREATE POLICY "Patients can view their own readiness metrics"
ON public.readiness_metrics
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Patients can insert their own readiness metrics"
ON public.readiness_metrics
FOR INSERT
TO authenticated
WITH CHECK (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- Therapists can view metrics for their patients
CREATE POLICY "Therapists can view patient readiness metrics"
ON public.readiness_metrics
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.therapists t
        JOIN public.patients p ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
        AND p.id = patient_id
    )
);

-- System can insert metrics (for automated imports)
CREATE POLICY "System can insert readiness metrics"
ON public.readiness_metrics
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE id = auth.uid()
        AND raw_user_meta_data->>'role' IN ('admin', 'system')
    )
);

-- Enable RLS on readiness_adjustments
ALTER TABLE public.readiness_adjustments ENABLE ROW LEVEL SECURITY;

-- Patients can view their own adjustments
CREATE POLICY "Patients can view their own readiness adjustments"
ON public.readiness_adjustments
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- Therapists can view and modify adjustments for their patients
CREATE POLICY "Therapists can view patient readiness adjustments"
ON public.readiness_adjustments
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.therapists t
        JOIN public.patients p ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
        AND p.id = patient_id
    )
);

CREATE POLICY "Therapists can override patient readiness adjustments"
ON public.readiness_adjustments
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.therapists t
        JOIN public.patients p ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
        AND p.id = patient_id
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.therapists t
        JOIN public.patients p ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
        AND p.id = patient_id
    )
);

-- System can create adjustments
CREATE POLICY "System can create readiness adjustments"
ON public.readiness_adjustments
FOR INSERT
TO authenticated
WITH CHECK (true); -- Controlled by function security

-- ============================================================================
-- 7. TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_readiness_metrics_updated_at
BEFORE UPDATE ON public.readiness_metrics
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_readiness_adjustments_updated_at
BEFORE UPDATE ON public.readiness_adjustments
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 8. HELPER VIEWS
-- ============================================================================

-- Recent adjustments with patient info
CREATE OR REPLACE VIEW public.vw_recent_adjustments AS
SELECT
    ra.id,
    ra.patient_id,
    p.first_name || ' ' || p.last_name as patient_name,
    ra.adjustment_date,
    ra.readiness_category,
    ra.recovery_score,
    ra.volume_multiplier,
    ra.intensity_multiplier,
    ra.is_overridden,
    ra.status,
    ra.recommendations,
    ra.warnings,
    ra.created_at
FROM public.readiness_adjustments ra
JOIN public.patients p ON p.id = ra.patient_id
ORDER BY ra.adjustment_date DESC, ra.created_at DESC;

-- Adjustment trends (7-day rolling average)
CREATE OR REPLACE VIEW public.vw_adjustment_trends AS
SELECT
    patient_id,
    adjustment_date,
    recovery_score,
    volume_multiplier,
    intensity_multiplier,
    readiness_category,
    AVG(recovery_score) OVER (
        PARTITION BY patient_id
        ORDER BY adjustment_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as recovery_score_7d_avg,
    AVG(volume_multiplier) OVER (
        PARTITION BY patient_id
        ORDER BY adjustment_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as volume_multiplier_7d_avg
FROM public.readiness_adjustments
ORDER BY patient_id, adjustment_date DESC;

-- ============================================================================
-- 9. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT ON public.readiness_metrics TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.readiness_adjustments TO authenticated;
GRANT SELECT ON public.vw_recent_adjustments TO authenticated;
GRANT SELECT ON public.vw_adjustment_trends TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_adjustment_multipliers TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_readiness_adjustment TO authenticated;
GRANT EXECUTE ON FUNCTION public.override_readiness_adjustment TO authenticated;

COMMIT;
