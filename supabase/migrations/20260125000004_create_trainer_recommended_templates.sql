-- BUILD 282: Trainer Recommended Templates
-- Allows therapists to recommend specific workout templates to their patients

-- Create trainer_recommended_templates table
CREATE TABLE IF NOT EXISTS public.trainer_recommended_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES public.therapists(id) ON DELETE CASCADE,
    -- Can recommend system templates only (patient templates are personal)
    system_template_id UUID NOT NULL REFERENCES public.system_workout_templates(id) ON DELETE CASCADE,
    notes TEXT, -- Optional notes from trainer about why this is recommended
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Prevent duplicate recommendations
    CONSTRAINT unique_trainer_recommendation UNIQUE (patient_id, system_template_id)
);

-- Create indexes for faster lookups
CREATE INDEX idx_trainer_recommendations_patient ON public.trainer_recommended_templates(patient_id);
CREATE INDEX idx_trainer_recommendations_therapist ON public.trainer_recommended_templates(therapist_id);
CREATE INDEX idx_trainer_recommendations_template ON public.trainer_recommended_templates(system_template_id);

-- Enable RLS
ALTER TABLE public.trainer_recommended_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Patients can view recommendations for them
CREATE POLICY patients_select_own_recommendations ON public.trainer_recommended_templates
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

-- Therapists can manage recommendations for their patients
CREATE POLICY therapists_select_recommendations ON public.trainer_recommended_templates
    FOR SELECT
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists WHERE user_id = auth.uid()
        )
    );

CREATE POLICY therapists_insert_recommendations ON public.trainer_recommended_templates
    FOR INSERT
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM public.therapists WHERE user_id = auth.uid()
        )
    );

CREATE POLICY therapists_delete_recommendations ON public.trainer_recommended_templates
    FOR DELETE
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists WHERE user_id = auth.uid()
        )
    );

-- Grant permissions
GRANT SELECT ON public.trainer_recommended_templates TO authenticated;
GRANT INSERT, DELETE ON public.trainer_recommended_templates TO authenticated;

COMMENT ON TABLE public.trainer_recommended_templates IS 'Tracks workout templates recommended by therapists to their patients';
