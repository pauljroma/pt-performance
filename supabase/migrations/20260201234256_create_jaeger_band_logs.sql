-- ACP-521: Jaeger Band Protocol Integration
-- Migration to create jaeger_band_logs table for tracking J-Band routine completions

-- Create jaeger_band_logs table
CREATE TABLE IF NOT EXISTS public.jaeger_band_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    variation TEXT NOT NULL CHECK (variation IN ('full', 'quick', 'travel', 'pre_throw')),
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    exercises_completed INTEGER NOT NULL DEFAULT 0,
    exercises_skipped INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    arm_soreness_before INTEGER CHECK (arm_soreness_before IS NULL OR (arm_soreness_before >= 1 AND arm_soreness_before <= 10)),
    arm_soreness_after INTEGER CHECK (arm_soreness_after IS NULL OR (arm_soreness_after >= 1 AND arm_soreness_after <= 10)),
    was_pre_throwing_warmup BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_jaeger_band_logs_patient_id ON public.jaeger_band_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_jaeger_band_logs_completed_at ON public.jaeger_band_logs(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_jaeger_band_logs_patient_completed ON public.jaeger_band_logs(patient_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_jaeger_band_logs_variation ON public.jaeger_band_logs(variation);

-- Enable RLS
ALTER TABLE public.jaeger_band_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Patients can view their own J-Band logs
CREATE POLICY "Patients can view their own jaeger_band_logs"
    ON public.jaeger_band_logs
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

-- Patients can insert their own J-Band logs
CREATE POLICY "Patients can insert their own jaeger_band_logs"
    ON public.jaeger_band_logs
    FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

-- Patients can update their own J-Band logs
CREATE POLICY "Patients can update their own jaeger_band_logs"
    ON public.jaeger_band_logs
    FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

-- Patients can delete their own J-Band logs
CREATE POLICY "Patients can delete their own jaeger_band_logs"
    ON public.jaeger_band_logs
    FOR DELETE
    USING (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

-- Therapists can view their patients' J-Band logs
CREATE POLICY "Therapists can view their patients jaeger_band_logs"
    ON public.jaeger_band_logs
    FOR SELECT
    USING (
        patient_id IN (
            SELECT p.id FROM public.patients p
            JOIN public.therapists t ON p.therapist_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_jaeger_band_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_jaeger_band_logs_updated_at
    BEFORE UPDATE ON public.jaeger_band_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_jaeger_band_logs_updated_at();

-- Create view for J-Band statistics
CREATE OR REPLACE VIEW public.vw_jaeger_band_stats AS
SELECT
    patient_id,
    COUNT(*) as total_sessions,
    COUNT(*) FILTER (WHERE completed_at >= DATE_TRUNC('week', CURRENT_TIMESTAMP)) as sessions_this_week,
    ROUND(AVG(duration_minutes)::numeric, 1) as avg_duration_minutes,
    SUM(duration_minutes) as total_minutes,
    SUM(exercises_completed) as total_exercises_completed,
    SUM(exercises_skipped) as total_exercises_skipped,
    ROUND(
        (SUM(exercises_completed)::numeric / NULLIF(SUM(exercises_completed + exercises_skipped), 0) * 100),
        1
    ) as completion_rate_pct,
    MODE() WITHIN GROUP (ORDER BY variation) as most_used_variation,
    MAX(completed_at) as last_session_at,
    MIN(completed_at) as first_session_at,
    ROUND(AVG(arm_soreness_before)::numeric, 1) as avg_soreness_before,
    ROUND(AVG(arm_soreness_after)::numeric, 1) as avg_soreness_after,
    ROUND(AVG(arm_soreness_before - arm_soreness_after)::numeric, 1) as avg_soreness_improvement
FROM public.jaeger_band_logs
GROUP BY patient_id;

-- Grant access to the view
GRANT SELECT ON public.vw_jaeger_band_stats TO authenticated;

-- Create function to get J-Band streak for a patient
CREATE OR REPLACE FUNCTION public.get_jaeger_band_streak(p_patient_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    streak INTEGER := 0;
    check_date DATE := CURRENT_DATE;
    has_session BOOLEAN;
BEGIN
    LOOP
        SELECT EXISTS(
            SELECT 1 FROM public.jaeger_band_logs
            WHERE patient_id = p_patient_id
            AND DATE(completed_at) = check_date
        ) INTO has_session;

        IF has_session THEN
            streak := streak + 1;
            check_date := check_date - INTERVAL '1 day';
        ELSE
            EXIT;
        END IF;

        -- Safety limit to prevent infinite loops
        IF streak > 365 THEN
            EXIT;
        END IF;
    END LOOP;

    RETURN streak;
END;
$$;

-- Grant execute on function
GRANT EXECUTE ON FUNCTION public.get_jaeger_band_streak(UUID) TO authenticated;

-- Create function to check if J-Band was completed today
CREATE OR REPLACE FUNCTION public.has_completed_jaeger_band_today(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM public.jaeger_band_logs
        WHERE patient_id = p_patient_id
        AND DATE(completed_at) = CURRENT_DATE
    );
END;
$$;

-- Grant execute on function
GRANT EXECUTE ON FUNCTION public.has_completed_jaeger_band_today(UUID) TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE public.jaeger_band_logs IS 'Tracks Jaeger Band arm care routine completions for patients';
COMMENT ON COLUMN public.jaeger_band_logs.variation IS 'Protocol variation: full, quick, travel, or pre_throw';
COMMENT ON COLUMN public.jaeger_band_logs.arm_soreness_before IS 'Self-reported arm soreness level (1-10) before routine';
COMMENT ON COLUMN public.jaeger_band_logs.arm_soreness_after IS 'Self-reported arm soreness level (1-10) after routine';
COMMENT ON COLUMN public.jaeger_band_logs.was_pre_throwing_warmup IS 'Whether this session was used as a pre-throwing warm-up';
COMMENT ON VIEW public.vw_jaeger_band_stats IS 'Aggregated statistics for J-Band routine completions per patient';
COMMENT ON FUNCTION public.get_jaeger_band_streak IS 'Returns the current consecutive day streak of J-Band completions for a patient';
COMMENT ON FUNCTION public.has_completed_jaeger_band_today IS 'Returns true if the patient has completed a J-Band routine today';
