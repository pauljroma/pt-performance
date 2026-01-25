-- BUILD 282: Patient Favorite Templates
-- Allows patients to save favorite workout templates for quick access

-- Create patient_favorite_templates table
CREATE TABLE IF NOT EXISTS public.patient_favorite_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    -- Can favorite either system templates or patient templates
    system_template_id UUID REFERENCES public.system_workout_templates(id) ON DELETE CASCADE,
    patient_template_id UUID REFERENCES public.patient_workout_templates(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure exactly one template type is referenced
    CONSTRAINT favorite_template_type_check CHECK (
        (system_template_id IS NOT NULL AND patient_template_id IS NULL) OR
        (system_template_id IS NULL AND patient_template_id IS NOT NULL)
    ),

    -- Prevent duplicate favorites
    CONSTRAINT unique_system_favorite UNIQUE (patient_id, system_template_id),
    CONSTRAINT unique_patient_favorite UNIQUE (patient_id, patient_template_id)
);

-- Create index for faster lookups
CREATE INDEX idx_patient_favorites_patient ON public.patient_favorite_templates(patient_id);
CREATE INDEX idx_patient_favorites_system ON public.patient_favorite_templates(system_template_id) WHERE system_template_id IS NOT NULL;
CREATE INDEX idx_patient_favorites_patient_template ON public.patient_favorite_templates(patient_template_id) WHERE patient_template_id IS NOT NULL;

-- Enable RLS
ALTER TABLE public.patient_favorite_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Patients can manage their own favorites
CREATE POLICY patients_select_own_favorites ON public.patient_favorite_templates
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY patients_insert_own_favorites ON public.patient_favorite_templates
    FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY patients_delete_own_favorites ON public.patient_favorite_templates
    FOR DELETE
    USING (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, DELETE ON public.patient_favorite_templates TO authenticated;

COMMENT ON TABLE public.patient_favorite_templates IS 'Tracks patient favorite workout templates for quick access in My Workouts';
