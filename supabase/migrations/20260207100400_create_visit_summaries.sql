-- Clinical Assessments & Documentation Feature
-- Part 5: Visit Summaries Table
-- Created: 2026-02-07

-- ============================================================================
-- VISIT SUMMARIES TABLE
-- Comprehensive summary of each patient visit including exercises and outcomes
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.visit_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES public.therapists(id),

    -- Visit date
    visit_date DATE NOT NULL,

    -- Exercise summary (JSONB)
    -- Structure: [{ "exercise_id": uuid, "name": "string", "sets_completed": int, "notes": "string" }]
    exercises_performed JSONB,
    total_exercises INTEGER,
    duration_minutes INTEGER,

    -- Session metrics
    avg_pain_score DECIMAL(3,1),
    avg_rpe DECIMAL(3,1),

    -- Clinical documentation
    clinical_notes TEXT,
    patient_response TEXT,       -- How patient responded to treatment
    modifications_made TEXT,     -- Any exercise modifications during session

    -- Follow-up planning
    next_visit_focus TEXT,
    home_program_changes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Patient lookups
CREATE INDEX IF NOT EXISTS idx_visit_summaries_patient_id
    ON public.visit_summaries(patient_id);

-- Session lookups
CREATE INDEX IF NOT EXISTS idx_visit_summaries_session_id
    ON public.visit_summaries(session_id);

-- Therapist lookups
CREATE INDEX IF NOT EXISTS idx_visit_summaries_therapist_id
    ON public.visit_summaries(therapist_id);

-- Date range queries
CREATE INDEX IF NOT EXISTS idx_visit_summaries_date
    ON public.visit_summaries(visit_date DESC);

-- Combined patient + date for visit history
CREATE INDEX IF NOT EXISTS idx_visit_summaries_patient_date
    ON public.visit_summaries(patient_id, visit_date DESC);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE public.visit_summaries ENABLE ROW LEVEL SECURITY;

-- Patients can view their own visit summaries
CREATE POLICY "Patients can view own visit summaries"
    ON public.visit_summaries
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can view visit summaries for their patients
CREATE POLICY "Therapists can view patient visit summaries"
    ON public.visit_summaries
    FOR SELECT
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
        OR
        patient_id IN (
            SELECT tp.patient_id
            FROM public.therapist_patients tp
            JOIN public.therapists t ON t.id = tp.therapist_id
            WHERE t.user_id = auth.uid()
        )
    );

-- Therapists can insert visit summaries
CREATE POLICY "Therapists can insert visit summaries"
    ON public.visit_summaries
    FOR INSERT
    TO authenticated
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can update their own visit summaries
CREATE POLICY "Therapists can update own visit summaries"
    ON public.visit_summaries
    FOR UPDATE
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can delete their own visit summaries
CREATE POLICY "Therapists can delete own visit summaries"
    ON public.visit_summaries
    FOR DELETE
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.visit_summaries TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.visit_summaries IS 'Summary of patient visits including exercises performed and clinical notes';
COMMENT ON COLUMN public.visit_summaries.exercises_performed IS 'Array of exercises completed during the visit with completion details';
COMMENT ON COLUMN public.visit_summaries.patient_response IS 'How the patient responded to the treatment session';
COMMENT ON COLUMN public.visit_summaries.modifications_made IS 'Any exercise or treatment modifications made during the session';
COMMENT ON COLUMN public.visit_summaries.next_visit_focus IS 'Focus areas for the next scheduled visit';
COMMENT ON COLUMN public.visit_summaries.home_program_changes IS 'Changes to the home exercise program based on this visit';
