-- Clinical Assessments & Documentation Feature
-- Part 2: Outcome Measures Table
-- Created: 2026-02-07

-- ============================================================================
-- OUTCOME MEASURES TABLE
-- Standardized outcome measures (LEFS, DASH, QuickDASH, PSFS, OMAK, VAS, NDI, ODI)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.outcome_measures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES public.therapists(id),
    clinical_assessment_id UUID REFERENCES public.clinical_assessments(id) ON DELETE SET NULL,

    -- Measure identification
    measure_type VARCHAR(50) NOT NULL CHECK (measure_type IN (
        'LEFS',       -- Lower Extremity Functional Scale
        'DASH',       -- Disabilities of the Arm, Shoulder and Hand
        'QuickDASH',  -- Quick DASH (shortened version)
        'PSFS',       -- Patient-Specific Functional Scale
        'OMAK',       -- Outcome Measures in Arthritis Knowledge
        'VAS',        -- Visual Analog Scale
        'NDI',        -- Neck Disability Index
        'ODI'         -- Oswestry Disability Index
    )),
    assessment_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Responses (JSONB)
    -- Structure varies by measure type, stores individual question responses
    -- Example for LEFS: { "q1": 4, "q2": 3, ... } (0-4 scale for each question)
    responses JSONB NOT NULL,

    -- Scoring
    raw_score DECIMAL(6,2),
    normalized_score DECIMAL(6,2),  -- Percentage or standardized score
    interpretation VARCHAR(50),      -- e.g., "minimal disability", "moderate disability"

    -- Progress tracking
    previous_score DECIMAL(6,2),
    change_from_previous DECIMAL(6,2),
    meets_mcid BOOLEAN,  -- Meets Minimal Clinically Important Difference

    -- Optional notes
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Patient lookups
CREATE INDEX IF NOT EXISTS idx_outcome_measures_patient_id
    ON public.outcome_measures(patient_id);

-- Therapist lookups
CREATE INDEX IF NOT EXISTS idx_outcome_measures_therapist_id
    ON public.outcome_measures(therapist_id);

-- Measure type filtering
CREATE INDEX IF NOT EXISTS idx_outcome_measures_type
    ON public.outcome_measures(measure_type);

-- Date range queries
CREATE INDEX IF NOT EXISTS idx_outcome_measures_date
    ON public.outcome_measures(assessment_date DESC);

-- Combined patient + measure type for progress tracking
CREATE INDEX IF NOT EXISTS idx_outcome_measures_patient_type
    ON public.outcome_measures(patient_id, measure_type, assessment_date DESC);

-- Clinical assessment linkage
CREATE INDEX IF NOT EXISTS idx_outcome_measures_assessment_id
    ON public.outcome_measures(clinical_assessment_id);

-- MCID achievements for reporting
CREATE INDEX IF NOT EXISTS idx_outcome_measures_mcid
    ON public.outcome_measures(meets_mcid) WHERE meets_mcid = true;

-- ============================================================================
-- TRIGGER: Calculate scores and track progress
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_outcome_measure_scores()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_previous RECORD;
    v_mcid_threshold DECIMAL(6,2);
BEGIN
    -- Get the most recent previous score for this patient and measure type
    SELECT raw_score, normalized_score
    INTO v_previous
    FROM public.outcome_measures
    WHERE patient_id = NEW.patient_id
      AND measure_type = NEW.measure_type
      AND id != COALESCE(NEW.id, gen_random_uuid())
    ORDER BY assessment_date DESC, created_at DESC
    LIMIT 1;

    -- Set previous score if exists
    IF v_previous IS NOT NULL THEN
        NEW.previous_score := v_previous.raw_score;
        NEW.change_from_previous := NEW.raw_score - v_previous.raw_score;
    END IF;

    -- Determine MCID threshold based on measure type
    -- These are commonly accepted MCID values
    v_mcid_threshold := CASE NEW.measure_type
        WHEN 'LEFS' THEN 9.0    -- 9 points
        WHEN 'DASH' THEN 10.0   -- 10 points (improvement is negative)
        WHEN 'QuickDASH' THEN 10.0
        WHEN 'PSFS' THEN 2.0    -- 2 points
        WHEN 'VAS' THEN 20.0    -- 20mm on 100mm scale
        WHEN 'NDI' THEN 10.0    -- 10 points
        WHEN 'ODI' THEN 10.0    -- 10 points
        ELSE 10.0               -- Default threshold
    END;

    -- Calculate if MCID is met (for measures where lower is better, check negative change)
    IF NEW.change_from_previous IS NOT NULL THEN
        IF NEW.measure_type IN ('DASH', 'QuickDASH', 'NDI', 'ODI') THEN
            -- Lower scores are better for these measures
            NEW.meets_mcid := NEW.change_from_previous <= -v_mcid_threshold;
        ELSE
            -- Higher scores are better for these measures
            NEW.meets_mcid := NEW.change_from_previous >= v_mcid_threshold;
        END IF;
    END IF;

    -- Set interpretation based on normalized score and measure type
    IF NEW.normalized_score IS NOT NULL THEN
        NEW.interpretation := CASE NEW.measure_type
            WHEN 'LEFS' THEN
                CASE
                    WHEN NEW.normalized_score >= 80 THEN 'minimal_disability'
                    WHEN NEW.normalized_score >= 60 THEN 'mild_disability'
                    WHEN NEW.normalized_score >= 40 THEN 'moderate_disability'
                    WHEN NEW.normalized_score >= 20 THEN 'severe_disability'
                    ELSE 'complete_disability'
                END
            WHEN 'ODI' THEN
                CASE
                    WHEN NEW.normalized_score <= 20 THEN 'minimal_disability'
                    WHEN NEW.normalized_score <= 40 THEN 'moderate_disability'
                    WHEN NEW.normalized_score <= 60 THEN 'severe_disability'
                    WHEN NEW.normalized_score <= 80 THEN 'crippled'
                    ELSE 'bed_bound'
                END
            WHEN 'NDI' THEN
                CASE
                    WHEN NEW.normalized_score <= 10 THEN 'no_disability'
                    WHEN NEW.normalized_score <= 30 THEN 'mild_disability'
                    WHEN NEW.normalized_score <= 50 THEN 'moderate_disability'
                    WHEN NEW.normalized_score <= 70 THEN 'severe_disability'
                    ELSE 'complete_disability'
                END
            ELSE NEW.interpretation  -- Keep existing if set manually
        END;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_calculate_outcome_scores ON public.outcome_measures;
CREATE TRIGGER trigger_calculate_outcome_scores
    BEFORE INSERT OR UPDATE ON public.outcome_measures
    FOR EACH ROW
    EXECUTE FUNCTION calculate_outcome_measure_scores();

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE public.outcome_measures ENABLE ROW LEVEL SECURITY;

-- Patients can view their own outcome measures
CREATE POLICY "Patients can view own outcome measures"
    ON public.outcome_measures
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can view outcome measures for their patients
CREATE POLICY "Therapists can view patient outcome measures"
    ON public.outcome_measures
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

-- Therapists can insert outcome measures
CREATE POLICY "Therapists can insert outcome measures"
    ON public.outcome_measures
    FOR INSERT
    TO authenticated
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can update their own outcome measures
CREATE POLICY "Therapists can update own outcome measures"
    ON public.outcome_measures
    FOR UPDATE
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can delete their own outcome measures
CREATE POLICY "Therapists can delete own outcome measures"
    ON public.outcome_measures
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

GRANT SELECT, INSERT, UPDATE, DELETE ON public.outcome_measures TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.outcome_measures IS 'Standardized patient-reported outcome measures (LEFS, DASH, PSFS, etc.)';
COMMENT ON COLUMN public.outcome_measures.measure_type IS 'Type of outcome measure: LEFS, DASH, QuickDASH, PSFS, OMAK, VAS, NDI, ODI';
COMMENT ON COLUMN public.outcome_measures.responses IS 'Individual question responses stored as JSONB';
COMMENT ON COLUMN public.outcome_measures.raw_score IS 'Raw score calculated from responses';
COMMENT ON COLUMN public.outcome_measures.normalized_score IS 'Normalized/percentage score for comparison';
COMMENT ON COLUMN public.outcome_measures.meets_mcid IS 'Whether the change meets Minimal Clinically Important Difference';
