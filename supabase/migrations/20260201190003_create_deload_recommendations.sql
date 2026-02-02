-- Migration: Create Deload Recommendations Tables
-- Sprint: Smart Recovery
-- Created: 2026-02-01
-- Description: Tables for AI-driven deload recommendations and active deload tracking

-- ============================================================================
-- DROP EXISTING OBJECTS (for clean recreation)
-- ============================================================================
DROP FUNCTION IF EXISTS get_active_deload(UUID);
DROP FUNCTION IF EXISTS apply_deload_adjustment(UUID, NUMERIC);
DROP TABLE IF EXISTS active_deloads CASCADE;
DROP TABLE IF EXISTS deload_recommendations CASCADE;

-- ============================================================================
-- DELOAD RECOMMENDATIONS TABLE
-- ============================================================================
-- Stores AI-generated deload recommendations based on fatigue analysis

CREATE TABLE deload_recommendations (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Patient reference
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    recommendation_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Urgency classification
    urgency TEXT NOT NULL CHECK (urgency IN ('none', 'suggested', 'recommended', 'required')),
    reasoning TEXT,

    -- Fatigue snapshot at time of recommendation
    fatigue_score NUMERIC(5,2) CHECK (fatigue_score >= 0 AND fatigue_score <= 100),
    fatigue_band TEXT CHECK (fatigue_band IN ('low', 'moderate', 'high', 'critical')),
    avg_readiness_7d NUMERIC(5,2) CHECK (avg_readiness_7d >= 0 AND avg_readiness_7d <= 100),
    acute_chronic_ratio NUMERIC(4,2) CHECK (acute_chronic_ratio >= 0),
    consecutive_low_days INTEGER DEFAULT 0 CHECK (consecutive_low_days >= 0),
    contributing_factors TEXT[] DEFAULT '{}',

    -- Deload prescription
    duration_days INTEGER CHECK (duration_days > 0 AND duration_days <= 14),
    load_reduction_pct NUMERIC(5,2) CHECK (load_reduction_pct >= 0 AND load_reduction_pct <= 100),
    volume_reduction_pct NUMERIC(5,2) CHECK (volume_reduction_pct >= 0 AND volume_reduction_pct <= 100),
    focus TEXT CHECK (focus IN ('technique', 'mobility', 'active_recovery', 'complete_rest')),
    suggested_start_date DATE,

    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'dismissed', 'completed')),
    accepted_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add table comment
COMMENT ON TABLE deload_recommendations IS 'AI-generated deload recommendations based on fatigue analysis';

-- ============================================================================
-- ACTIVE DELOADS TABLE
-- ============================================================================
-- Tracks currently active deload periods for patients

CREATE TABLE active_deloads (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    recommendation_id UUID REFERENCES deload_recommendations(id) ON DELETE SET NULL,

    -- Deload period
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    -- Deload parameters
    load_reduction_pct NUMERIC(5,2) NOT NULL CHECK (load_reduction_pct >= 0 AND load_reduction_pct <= 100),
    volume_reduction_pct NUMERIC(5,2) NOT NULL CHECK (volume_reduction_pct >= 0 AND volume_reduction_pct <= 100),
    focus TEXT NOT NULL CHECK (focus IN ('technique', 'mobility', 'active_recovery', 'complete_rest')),

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- Partial unique index to ensure only one active deload per patient
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_deload_per_patient
    ON active_deloads(patient_id)
    WHERE is_active = true;

-- Add table comment
COMMENT ON TABLE active_deloads IS 'Tracks currently active deload periods for patients';

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE deload_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_deloads ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view deload recommendations for their patients" ON deload_recommendations;
DROP POLICY IF EXISTS "Users can insert deload recommendations for their patients" ON deload_recommendations;
DROP POLICY IF EXISTS "Users can update deload recommendations for their patients" ON deload_recommendations;
DROP POLICY IF EXISTS "Users can view active deloads for their patients" ON active_deloads;
DROP POLICY IF EXISTS "Users can insert active deloads for their patients" ON active_deloads;
DROP POLICY IF EXISTS "Users can update active deloads for their patients" ON active_deloads;

-- Deload recommendations policies
CREATE POLICY "Users can view deload recommendations for their patients"
    ON deload_recommendations FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert deload recommendations for their patients"
    ON deload_recommendations FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update deload recommendations for their patients"
    ON deload_recommendations FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Active deloads policies
CREATE POLICY "Users can view active deloads for their patients"
    ON active_deloads FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert active deloads for their patients"
    ON active_deloads FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update active deloads for their patients"
    ON active_deloads FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Deload recommendations indexes
CREATE INDEX IF NOT EXISTS idx_deload_recommendations_patient_id
    ON deload_recommendations(patient_id);

CREATE INDEX IF NOT EXISTS idx_deload_recommendations_patient_date
    ON deload_recommendations(patient_id, recommendation_date DESC);

CREATE INDEX IF NOT EXISTS idx_deload_recommendations_status
    ON deload_recommendations(status)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_deload_recommendations_urgency
    ON deload_recommendations(urgency)
    WHERE urgency IN ('recommended', 'required');

-- Active deloads indexes
CREATE INDEX IF NOT EXISTS idx_active_deloads_patient_id
    ON active_deloads(patient_id);

CREATE INDEX IF NOT EXISTS idx_active_deloads_active
    ON active_deloads(patient_id, is_active)
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_active_deloads_date_range
    ON active_deloads(start_date, end_date);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to get current active deload for a patient
CREATE OR REPLACE FUNCTION get_active_deload(p_patient_id UUID)
RETURNS TABLE (
    id UUID,
    patient_id UUID,
    recommendation_id UUID,
    start_date DATE,
    end_date DATE,
    load_reduction_pct NUMERIC,
    volume_reduction_pct NUMERIC,
    focus TEXT,
    days_remaining INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ad.id,
        ad.patient_id,
        ad.recommendation_id,
        ad.start_date,
        ad.end_date,
        ad.load_reduction_pct,
        ad.volume_reduction_pct,
        ad.focus,
        (ad.end_date - CURRENT_DATE)::INTEGER as days_remaining
    FROM active_deloads ad
    WHERE ad.patient_id = p_patient_id
      AND ad.is_active = true
      AND CURRENT_DATE BETWEEN ad.start_date AND ad.end_date
    LIMIT 1;
END;
$$;

COMMENT ON FUNCTION get_active_deload(UUID) IS 'Returns the current active deload period for a patient, if any';

-- Function to apply deload adjustment to base load
CREATE OR REPLACE FUNCTION apply_deload_adjustment(
    p_patient_id UUID,
    p_base_load NUMERIC
)
RETURNS TABLE (
    adjusted_load NUMERIC,
    reduction_applied NUMERIC,
    is_deload_active BOOLEAN,
    deload_focus TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deload RECORD;
    v_reduction_pct NUMERIC;
BEGIN
    -- Get active deload for patient
    SELECT * INTO v_deload
    FROM active_deloads ad
    WHERE ad.patient_id = p_patient_id
      AND ad.is_active = true
      AND CURRENT_DATE BETWEEN ad.start_date AND ad.end_date
    LIMIT 1;

    -- If no active deload, return base load unchanged
    IF v_deload IS NULL THEN
        RETURN QUERY SELECT
            p_base_load,
            0::NUMERIC,
            false,
            NULL::TEXT;
        RETURN;
    END IF;

    -- Calculate reduction
    v_reduction_pct := v_deload.load_reduction_pct / 100.0;

    RETURN QUERY SELECT
        ROUND(p_base_load * (1 - v_reduction_pct), 2),
        ROUND(p_base_load * v_reduction_pct, 2),
        true,
        v_deload.focus;
END;
$$;

COMMENT ON FUNCTION apply_deload_adjustment(UUID, NUMERIC) IS 'Applies deload load reduction to a base load value if patient has active deload';

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to update updated_at timestamp
CREATE TRIGGER update_deload_recommendations_updated_at
    BEFORE UPDATE ON deload_recommendations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_active_deloads_updated_at
    BEFORE UPDATE ON active_deloads
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_table_count INTEGER;
    v_function_count INTEGER;
    v_index_count INTEGER;
    v_policy_count INTEGER;
BEGIN
    -- Verify tables exist
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('deload_recommendations', 'active_deloads');

    IF v_table_count != 2 THEN
        RAISE EXCEPTION 'Expected 2 tables, found %', v_table_count;
    END IF;

    -- Verify functions exist
    SELECT COUNT(*) INTO v_function_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname IN ('get_active_deload', 'apply_deload_adjustment');

    IF v_function_count != 2 THEN
        RAISE EXCEPTION 'Expected 2 functions, found %', v_function_count;
    END IF;

    -- Verify indexes exist
    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname LIKE 'idx_deload%'
      OR indexname LIKE 'idx_active_deloads%';

    IF v_index_count < 7 THEN
        RAISE EXCEPTION 'Expected at least 7 indexes, found %', v_index_count;
    END IF;

    -- Verify RLS policies exist
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('deload_recommendations', 'active_deloads');

    IF v_policy_count < 6 THEN
        RAISE EXCEPTION 'Expected at least 6 RLS policies, found %', v_policy_count;
    END IF;

    RAISE NOTICE '✓ Deload recommendations migration verified successfully';
    RAISE NOTICE '  - Tables: %', v_table_count;
    RAISE NOTICE '  - Functions: %', v_function_count;
    RAISE NOTICE '  - Indexes: %', v_index_count;
    RAISE NOTICE '  - RLS Policies: %', v_policy_count;
END $$;
