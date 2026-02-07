-- Clinical Assessments & Documentation Feature
-- Part 4: Clinical Templates Table
-- Created: 2026-02-07

-- ============================================================================
-- CLINICAL TEMPLATES TABLE
-- Reusable templates for SOAP notes, assessments, intake, and discharge
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.clinical_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapist_id UUID REFERENCES public.therapists(id) ON DELETE SET NULL,

    -- Template identification
    name VARCHAR(100) NOT NULL,
    description TEXT,
    template_type VARCHAR(50) NOT NULL CHECK (template_type IN ('soap', 'assessment', 'discharge', 'intake')),
    body_region VARCHAR(50),  -- e.g., 'shoulder', 'knee', 'lumbar_spine', 'cervical', 'general'

    -- Template content (JSONB)
    -- Structure varies by template_type, contains pre-filled sections
    template_content JSONB NOT NULL,

    -- Default values (JSONB)
    -- Pre-populated values when template is applied
    default_values JSONB,

    -- Template flags
    is_system_template BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Therapist lookups
CREATE INDEX IF NOT EXISTS idx_clinical_templates_therapist_id
    ON public.clinical_templates(therapist_id);

-- Template type filtering
CREATE INDEX IF NOT EXISTS idx_clinical_templates_type
    ON public.clinical_templates(template_type);

-- Body region filtering
CREATE INDEX IF NOT EXISTS idx_clinical_templates_body_region
    ON public.clinical_templates(body_region);

-- System templates lookup
CREATE INDEX IF NOT EXISTS idx_clinical_templates_system
    ON public.clinical_templates(is_system_template) WHERE is_system_template = true;

-- Active templates
CREATE INDEX IF NOT EXISTS idx_clinical_templates_active
    ON public.clinical_templates(is_active) WHERE is_active = true;

-- Combined type + body region for quick filtering
CREATE INDEX IF NOT EXISTS idx_clinical_templates_type_region
    ON public.clinical_templates(template_type, body_region);

-- ============================================================================
-- TRIGGER: Update timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_clinical_template_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_clinical_template_updated ON public.clinical_templates;
CREATE TRIGGER trigger_clinical_template_updated
    BEFORE UPDATE ON public.clinical_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_clinical_template_timestamp();

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE public.clinical_templates ENABLE ROW LEVEL SECURITY;

-- Everyone can view system templates
CREATE POLICY "Everyone can view system templates"
    ON public.clinical_templates
    FOR SELECT
    TO authenticated
    USING (is_system_template = true);

-- Therapists can view their own templates
CREATE POLICY "Therapists can view own templates"
    ON public.clinical_templates
    FOR SELECT
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can create their own templates
CREATE POLICY "Therapists can create templates"
    ON public.clinical_templates
    FOR INSERT
    TO authenticated
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
        AND is_system_template = false
    );

-- Therapists can update their own templates
CREATE POLICY "Therapists can update own templates"
    ON public.clinical_templates
    FOR UPDATE
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
        AND is_system_template = false
    );

-- Therapists can delete their own templates
CREATE POLICY "Therapists can delete own templates"
    ON public.clinical_templates
    FOR DELETE
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
        AND is_system_template = false
    );

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.clinical_templates TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.clinical_templates IS 'Reusable templates for clinical documentation (SOAP notes, assessments, etc.)';
COMMENT ON COLUMN public.clinical_templates.template_type IS 'Type of template: soap, assessment, discharge, or intake';
COMMENT ON COLUMN public.clinical_templates.body_region IS 'Body region the template is designed for (shoulder, knee, lumbar_spine, etc.)';
COMMENT ON COLUMN public.clinical_templates.template_content IS 'Template structure and pre-filled content as JSONB';
COMMENT ON COLUMN public.clinical_templates.default_values IS 'Default values to pre-populate when template is applied';
COMMENT ON COLUMN public.clinical_templates.is_system_template IS 'True for system-provided templates, false for user-created';
