-- Clinical Assessments & Documentation Feature
-- Part 1: Clinical Assessments Table
-- Created: 2026-02-07

-- ============================================================================
-- CLINICAL ASSESSMENTS TABLE
-- Comprehensive assessment data for intake, progress, discharge, and follow-up
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.clinical_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES public.therapists(id),
    assessment_type VARCHAR(50) NOT NULL CHECK (assessment_type IN ('intake', 'progress', 'discharge', 'follow_up')),
    assessment_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- ROM Measurements (JSONB)
    -- Structure: { "joint": { "movement": { "left": degrees, "right": degrees, "normal": degrees } } }
    -- Example: { "shoulder": { "flexion": { "left": 170, "right": 175, "normal": 180 }, "abduction": {...} } }
    rom_measurements JSONB,

    -- Functional Tests (JSONB)
    -- Structure: { "test_name": { "score": value, "notes": "...", "passed": boolean } }
    -- Example: { "single_leg_squat": { "left": "good", "right": "fair", "notes": "..." } }
    functional_tests JSONB,

    -- Pain Assessment (0-10 scale)
    pain_at_rest INTEGER CHECK (pain_at_rest BETWEEN 0 AND 10),
    pain_with_activity INTEGER CHECK (pain_with_activity BETWEEN 0 AND 10),
    pain_worst INTEGER CHECK (pain_worst BETWEEN 0 AND 10),

    -- Pain Locations (JSONB)
    -- Structure: [{ "location": "string", "description": "string", "intensity": 0-10 }]
    pain_locations JSONB,

    -- History & Goals
    chief_complaint TEXT,
    history_of_present_illness TEXT,
    past_medical_history TEXT,

    -- Functional Goals (JSONB)
    -- Structure: [{ "goal": "string", "timeframe": "string", "status": "pending|in_progress|achieved" }]
    functional_goals JSONB,

    -- Clinical Findings
    objective_findings TEXT,
    assessment_summary TEXT,
    treatment_plan TEXT,

    -- Metadata
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'complete', 'signed')),
    signed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Patient lookups
CREATE INDEX IF NOT EXISTS idx_clinical_assessments_patient_id
    ON public.clinical_assessments(patient_id);

-- Therapist lookups
CREATE INDEX IF NOT EXISTS idx_clinical_assessments_therapist_id
    ON public.clinical_assessments(therapist_id);

-- Assessment type filtering
CREATE INDEX IF NOT EXISTS idx_clinical_assessments_type
    ON public.clinical_assessments(assessment_type);

-- Date range queries
CREATE INDEX IF NOT EXISTS idx_clinical_assessments_date
    ON public.clinical_assessments(assessment_date DESC);

-- Combined patient + date for efficient history lookups
CREATE INDEX IF NOT EXISTS idx_clinical_assessments_patient_date
    ON public.clinical_assessments(patient_id, assessment_date DESC);

-- Status filtering (e.g., find all draft assessments)
CREATE INDEX IF NOT EXISTS idx_clinical_assessments_status
    ON public.clinical_assessments(status);

-- Therapist + status for dashboard queries
CREATE INDEX IF NOT EXISTS idx_clinical_assessments_therapist_status
    ON public.clinical_assessments(therapist_id, status);

-- ============================================================================
-- TRIGGER: Update timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_clinical_assessment_timestamp()
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

DROP TRIGGER IF EXISTS trigger_clinical_assessment_updated ON public.clinical_assessments;
CREATE TRIGGER trigger_clinical_assessment_updated
    BEFORE UPDATE ON public.clinical_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_clinical_assessment_timestamp();

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE public.clinical_assessments ENABLE ROW LEVEL SECURITY;

-- Patients can view their own assessments
CREATE POLICY "Patients can view own clinical assessments"
    ON public.clinical_assessments
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can view assessments for their patients
CREATE POLICY "Therapists can view patient clinical assessments"
    ON public.clinical_assessments
    FOR SELECT
    TO authenticated
    USING (
        -- Direct therapist assignment
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
        OR
        -- Via therapist_patients relationship
        patient_id IN (
            SELECT tp.patient_id
            FROM public.therapist_patients tp
            JOIN public.therapists t ON t.id = tp.therapist_id
            WHERE t.user_id = auth.uid()
        )
    );

-- Therapists can insert assessments for their patients
CREATE POLICY "Therapists can insert clinical assessments"
    ON public.clinical_assessments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can update their own assessments
CREATE POLICY "Therapists can update own clinical assessments"
    ON public.clinical_assessments
    FOR UPDATE
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can delete their own draft assessments only
CREATE POLICY "Therapists can delete own draft assessments"
    ON public.clinical_assessments
    FOR DELETE
    TO authenticated
    USING (
        status = 'draft'
        AND therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.clinical_assessments TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.clinical_assessments IS 'Comprehensive clinical assessments including intake, progress, discharge, and follow-up evaluations';
COMMENT ON COLUMN public.clinical_assessments.rom_measurements IS 'Range of motion measurements stored as JSONB with joint/movement/side structure';
COMMENT ON COLUMN public.clinical_assessments.functional_tests IS 'Functional test results stored as JSONB with test name and scoring';
COMMENT ON COLUMN public.clinical_assessments.pain_locations IS 'Array of pain locations with descriptions and intensity ratings';
COMMENT ON COLUMN public.clinical_assessments.functional_goals IS 'Patient functional goals with status tracking';
COMMENT ON COLUMN public.clinical_assessments.status IS 'Assessment status: draft (in progress), complete (finished), signed (locked)';
