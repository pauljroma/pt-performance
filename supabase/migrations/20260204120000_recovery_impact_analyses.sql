-- ============================================================================
-- RECOVERY IMPACT ANALYSES TABLE MIGRATION
-- ============================================================================
-- Creates the table for storing AI-generated recovery impact analyses
-- Used by the recovery-impact-analyzer edge function
--
-- Date: 2026-02-04
-- ============================================================================

BEGIN;

-- ============================================================================
-- RECOVERY IMPACT ANALYSES TABLE
-- ============================================================================
-- Stores AI-generated analyses of how different recovery modalities
-- (sauna, cold plunge, contrast therapy, etc.) impact patient outcomes
-- including sleep, readiness, and training performance.

CREATE TABLE IF NOT EXISTS recovery_impact_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    analysis_period JSONB,
    total_recovery_sessions INTEGER,
    modality_impacts JSONB,
    correlation_insights JSONB,
    overall_recommendations JSONB,
    optimal_recovery_protocol JSONB,
    ai_analysis TEXT,
    data_quality JSONB,
    disclaimer TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE recovery_impact_analyses IS 'AI-generated analyses of recovery modality impacts on patient outcomes (sleep, readiness, training). Used by recovery-impact-analyzer edge function for caching analysis results.';
COMMENT ON COLUMN recovery_impact_analyses.patient_id IS 'Reference to the patient this analysis belongs to';
COMMENT ON COLUMN recovery_impact_analyses.analysis_period IS 'JSONB with start_date, end_date, days_analyzed for the analysis window';
COMMENT ON COLUMN recovery_impact_analyses.total_recovery_sessions IS 'Total number of recovery sessions analyzed';
COMMENT ON COLUMN recovery_impact_analyses.modality_impacts IS 'JSONB array of impact analyses per recovery modality (sauna, cold plunge, etc.)';
COMMENT ON COLUMN recovery_impact_analyses.correlation_insights IS 'JSONB array of correlation findings between recovery and outcomes';
COMMENT ON COLUMN recovery_impact_analyses.overall_recommendations IS 'JSONB array of personalized recommendations';
COMMENT ON COLUMN recovery_impact_analyses.optimal_recovery_protocol IS 'JSONB object describing the optimal recovery protocol for this patient';
COMMENT ON COLUMN recovery_impact_analyses.ai_analysis IS 'Full AI-generated narrative analysis text';
COMMENT ON COLUMN recovery_impact_analyses.data_quality IS 'JSONB with data quality metrics (completeness, confidence scores)';
COMMENT ON COLUMN recovery_impact_analyses.disclaimer IS 'Medical/legal disclaimer text';

-- ============================================================================
-- INDEXES
-- ============================================================================
-- Composite index for cache lookups: find most recent analysis for a patient

CREATE INDEX IF NOT EXISTS idx_recovery_impact_analyses_patient_created
    ON recovery_impact_analyses(patient_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_recovery_impact_analyses_patient_id
    ON recovery_impact_analyses(patient_id);

CREATE INDEX IF NOT EXISTS idx_recovery_impact_analyses_created_at
    ON recovery_impact_analyses(created_at DESC);

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE recovery_impact_analyses ENABLE ROW LEVEL SECURITY;

-- Patients can view their own recovery impact analyses
CREATE POLICY "Patients view own recovery impact analyses"
    ON recovery_impact_analyses FOR SELECT
    USING (patient_id = auth.uid());

-- Therapists can view their patients' recovery impact analyses
CREATE POLICY "Therapists view patient recovery impact analyses"
    ON recovery_impact_analyses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = recovery_impact_analyses.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

-- Demo patient: Any authenticated user can SELECT
CREATE POLICY "recovery_impact_analyses_demo_patient_select"
    ON recovery_impact_analyses FOR SELECT
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Demo patient: Any authenticated user can INSERT
CREATE POLICY "recovery_impact_analyses_demo_patient_insert"
    ON recovery_impact_analyses FOR INSERT
    TO authenticated
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Service role can manage all recovery impact analyses
CREATE POLICY "Service role can manage recovery impact analyses"
    ON recovery_impact_analyses FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT ON recovery_impact_analyses TO authenticated;
GRANT ALL ON recovery_impact_analyses TO service_role;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_table_exists boolean;
    v_index_count integer;
    v_policy_count integer;
BEGIN
    -- Check table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'recovery_impact_analyses'
    ) INTO v_table_exists;

    -- Count indexes
    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE tablename = 'recovery_impact_analyses';

    -- Count policies
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE tablename = 'recovery_impact_analyses';

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'RECOVERY IMPACT ANALYSES MIGRATION COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Table Created: recovery_impact_analyses';
    RAISE NOTICE '  - Stores AI-generated recovery modality impact analyses';
    RAISE NOTICE '  - Supports recovery-impact-analyzer edge function';
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes Created: %', v_index_count;
    RAISE NOTICE '  - idx_recovery_impact_analyses_patient_created (cache lookup)';
    RAISE NOTICE '  - idx_recovery_impact_analyses_patient_id';
    RAISE NOTICE '  - idx_recovery_impact_analyses_created_at';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies Created: %', v_policy_count;
    RAISE NOTICE '  - Patients view own analyses';
    RAISE NOTICE '  - Therapists view patient analyses';
    RAISE NOTICE '  - Demo patient access (SELECT, INSERT)';
    RAISE NOTICE '  - Service role full access';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;
