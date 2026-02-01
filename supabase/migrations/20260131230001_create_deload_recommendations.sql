-- ============================================================================
-- CREATE DELOAD RECOMMENDATIONS TABLE - BUILD 352
-- ============================================================================
-- Stores AI-generated deload recommendations based on fatigue analysis
-- Tracks whether recommendations were accepted or dismissed by patients
--
-- Date: 2026-01-31
-- Agent: 2
-- Linear: BUILD-352
-- ============================================================================

-- =====================================================
-- Deload Recommendations Table
-- =====================================================

CREATE TABLE IF NOT EXISTS deload_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Fatigue analysis summary (JSONB for flexibility)
    fatigue_summary JSONB NOT NULL DEFAULT '{}'::jsonb,
    -- Expected structure:
    -- {
    --   "fatigue_score": 75,
    --   "fatigue_band": "high",
    --   "avg_readiness_7d": 55.2,
    --   "acute_chronic_ratio": 1.4,
    --   "consecutive_low_days": 3,
    --   "contributing_factors": ["sleep_deficit", "high_training_load"]
    -- }

    -- Deload prescription (JSONB, null if no deload recommended)
    prescription JSONB,
    -- Expected structure:
    -- {
    --   "duration_days": 7,
    --   "load_reduction_pct": 50,
    --   "volume_reduction_pct": 40,
    --   "focus": "active_recovery",
    --   "suggested_start_date": "2026-02-01"
    -- }

    -- Recommendation outcome
    deload_recommended BOOLEAN NOT NULL DEFAULT false,
    urgency TEXT NOT NULL DEFAULT 'none' CHECK (urgency IN ('none', 'suggested', 'recommended', 'required')),
    reasoning TEXT,

    -- User response tracking
    accepted BOOLEAN,
    dismissed BOOLEAN,
    dismissed_reason TEXT,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '24 hours')
);

-- =====================================================
-- Indexes
-- =====================================================

CREATE INDEX idx_deload_recommendations_patient ON deload_recommendations(patient_id);
CREATE INDEX idx_deload_recommendations_patient_created ON deload_recommendations(patient_id, created_at DESC);
CREATE INDEX idx_deload_recommendations_urgency ON deload_recommendations(urgency) WHERE urgency != 'none';
-- Note: Partial index with now() not allowed, using simple index instead
CREATE INDEX idx_deload_recommendations_pending ON deload_recommendations(patient_id, expires_at)
    WHERE accepted IS NULL AND dismissed IS NULL;

-- =====================================================
-- Comments
-- =====================================================

COMMENT ON TABLE deload_recommendations IS 'AI-generated deload recommendations based on fatigue analysis';
COMMENT ON COLUMN deload_recommendations.fatigue_summary IS 'JSONB containing fatigue metrics and contributing factors';
COMMENT ON COLUMN deload_recommendations.prescription IS 'JSONB containing deload prescription details (null if no deload needed)';
COMMENT ON COLUMN deload_recommendations.deload_recommended IS 'Whether a deload is recommended based on fatigue analysis';
COMMENT ON COLUMN deload_recommendations.urgency IS 'Urgency level: none, suggested, recommended, required';
COMMENT ON COLUMN deload_recommendations.reasoning IS 'AI-generated explanation for the recommendation';
COMMENT ON COLUMN deload_recommendations.accepted IS 'True if patient accepted the deload recommendation';
COMMENT ON COLUMN deload_recommendations.dismissed IS 'True if patient dismissed the recommendation';
COMMENT ON COLUMN deload_recommendations.dismissed_reason IS 'Optional reason for dismissing recommendation';
COMMENT ON COLUMN deload_recommendations.expires_at IS 'Recommendation expires after 24 hours if not acted upon';

-- =====================================================
-- Auto-update timestamp trigger
-- =====================================================

CREATE OR REPLACE FUNCTION update_deload_recommendations_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_deload_recommendations_timestamp_trigger
    BEFORE UPDATE ON deload_recommendations
    FOR EACH ROW
    EXECUTE FUNCTION update_deload_recommendations_timestamp();

-- =====================================================
-- Row-Level Security (RLS)
-- =====================================================

ALTER TABLE deload_recommendations ENABLE ROW LEVEL SECURITY;

-- Patients can view their own recommendations
CREATE POLICY "Patients can view their own deload recommendations"
    ON deload_recommendations FOR SELECT
    USING (patient_id = auth.uid());

-- Patients can update their own recommendations (accept/dismiss)
CREATE POLICY "Patients can update their own deload recommendations"
    ON deload_recommendations FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Therapists can view all patient recommendations
CREATE POLICY "Therapists can view all deload recommendations"
    ON deload_recommendations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- Service role has full access (for edge functions)
CREATE POLICY "Service role can manage all deload recommendations"
    ON deload_recommendations FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- Grant Permissions
-- =====================================================

GRANT SELECT, UPDATE ON deload_recommendations TO authenticated;
GRANT ALL ON deload_recommendations TO service_role;

-- =====================================================
-- Verification
-- =====================================================

DO $$
DECLARE
    v_table_exists boolean;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = 'deload_recommendations'
    ) INTO v_table_exists;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DELOAD RECOMMENDATIONS TABLE CREATED - BUILD 352';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Table Created: deload_recommendations = %', v_table_exists;
    RAISE NOTICE '';
    RAISE NOTICE 'Columns:';
    RAISE NOTICE '  - id (UUID, PK)';
    RAISE NOTICE '  - patient_id (UUID, FK to patients)';
    RAISE NOTICE '  - fatigue_summary (JSONB)';
    RAISE NOTICE '  - prescription (JSONB, nullable)';
    RAISE NOTICE '  - deload_recommended (BOOLEAN)';
    RAISE NOTICE '  - urgency (TEXT: none/suggested/recommended/required)';
    RAISE NOTICE '  - reasoning (TEXT)';
    RAISE NOTICE '  - accepted (BOOLEAN, nullable)';
    RAISE NOTICE '  - dismissed (BOOLEAN, nullable)';
    RAISE NOTICE '  - dismissed_reason (TEXT, nullable)';
    RAISE NOTICE '  - created_at, updated_at, expires_at';
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes:';
    RAISE NOTICE '  - idx_deload_recommendations_patient';
    RAISE NOTICE '  - idx_deload_recommendations_patient_created';
    RAISE NOTICE '  - idx_deload_recommendations_urgency';
    RAISE NOTICE '  - idx_deload_recommendations_pending';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies:';
    RAISE NOTICE '  - Patients: SELECT, UPDATE on own data';
    RAISE NOTICE '  - Therapists: SELECT on all data';
    RAISE NOTICE '  - Service role: Full access';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DELOAD RECOMMENDATIONS TABLE READY';
    RAISE NOTICE '============================================================================';
END $$;
