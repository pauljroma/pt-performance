-- Clinical Assessments & Documentation Feature
-- Part 3: SOAP Notes Table
-- Created: 2026-02-07

-- ============================================================================
-- SOAP NOTES TABLE
-- Subjective, Objective, Assessment, Plan documentation for each visit
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.soap_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES public.therapists(id),
    session_id UUID REFERENCES public.sessions(id) ON DELETE SET NULL,

    -- Note date
    note_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- SOAP Components
    subjective TEXT,   -- Patient's report of symptoms, pain, function
    objective TEXT,    -- Therapist's observations, measurements, tests
    assessment TEXT,   -- Clinical interpretation and analysis
    plan TEXT,         -- Treatment plan, goals, next steps

    -- Additional clinical data
    vitals JSONB,  -- { "blood_pressure": "120/80", "heart_rate": 72, "temperature": 98.6 }
    pain_level INTEGER CHECK (pain_level BETWEEN 0 AND 10),
    functional_status VARCHAR(50) CHECK (functional_status IN ('improving', 'stable', 'declining')),

    -- Billing & Documentation
    time_spent_minutes INTEGER,
    cpt_codes JSONB,  -- ["97110", "97140", "97530"]

    -- Metadata
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'complete', 'signed', 'addendum')),
    signed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Patient lookups
CREATE INDEX IF NOT EXISTS idx_soap_notes_patient_id
    ON public.soap_notes(patient_id);

-- Therapist lookups
CREATE INDEX IF NOT EXISTS idx_soap_notes_therapist_id
    ON public.soap_notes(therapist_id);

-- Session linkage
CREATE INDEX IF NOT EXISTS idx_soap_notes_session_id
    ON public.soap_notes(session_id);

-- Date range queries
CREATE INDEX IF NOT EXISTS idx_soap_notes_date
    ON public.soap_notes(note_date DESC);

-- Combined patient + date for visit history
CREATE INDEX IF NOT EXISTS idx_soap_notes_patient_date
    ON public.soap_notes(patient_id, note_date DESC);

-- Status filtering
CREATE INDEX IF NOT EXISTS idx_soap_notes_status
    ON public.soap_notes(status);

-- Therapist + status for dashboard (pending signatures)
CREATE INDEX IF NOT EXISTS idx_soap_notes_therapist_status
    ON public.soap_notes(therapist_id, status);

-- Functional status tracking
CREATE INDEX IF NOT EXISTS idx_soap_notes_functional_status
    ON public.soap_notes(patient_id, functional_status, note_date DESC);

-- ============================================================================
-- TRIGGER: Update timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_soap_note_timestamp()
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

DROP TRIGGER IF EXISTS trigger_soap_note_updated ON public.soap_notes;
CREATE TRIGGER trigger_soap_note_updated
    BEFORE UPDATE ON public.soap_notes
    FOR EACH ROW
    EXECUTE FUNCTION update_soap_note_timestamp();

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE public.soap_notes ENABLE ROW LEVEL SECURITY;

-- Patients can view their own SOAP notes
CREATE POLICY "Patients can view own SOAP notes"
    ON public.soap_notes
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can view SOAP notes for their patients
CREATE POLICY "Therapists can view patient SOAP notes"
    ON public.soap_notes
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

-- Therapists can insert SOAP notes
CREATE POLICY "Therapists can insert SOAP notes"
    ON public.soap_notes
    FOR INSERT
    TO authenticated
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can update their own SOAP notes (except signed ones)
CREATE POLICY "Therapists can update own SOAP notes"
    ON public.soap_notes
    FOR UPDATE
    TO authenticated
    USING (
        status != 'signed'
        AND therapist_id IN (
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

-- Therapists can delete their own draft SOAP notes only
CREATE POLICY "Therapists can delete own draft SOAP notes"
    ON public.soap_notes
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

GRANT SELECT, INSERT, UPDATE, DELETE ON public.soap_notes TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.soap_notes IS 'SOAP (Subjective, Objective, Assessment, Plan) notes for clinical documentation';
COMMENT ON COLUMN public.soap_notes.subjective IS 'Patient reported symptoms, pain levels, and functional limitations';
COMMENT ON COLUMN public.soap_notes.objective IS 'Therapist observations, measurements, and test results';
COMMENT ON COLUMN public.soap_notes.assessment IS 'Clinical interpretation and analysis of findings';
COMMENT ON COLUMN public.soap_notes.plan IS 'Treatment plan, goals, and next steps';
COMMENT ON COLUMN public.soap_notes.vitals IS 'Vital signs stored as JSONB (blood_pressure, heart_rate, etc.)';
COMMENT ON COLUMN public.soap_notes.cpt_codes IS 'Array of CPT codes for billing';
COMMENT ON COLUMN public.soap_notes.status IS 'Note status: draft, complete, signed (locked), or addendum';
