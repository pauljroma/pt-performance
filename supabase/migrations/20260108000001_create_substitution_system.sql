-- BUILD 138: AI Equipment Substitution System - Database Schema
-- Create tables for exercise substitution candidates, AI recommendations, and workout instances

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. Exercise Substitution Candidates (Pre-vetted substitution pairs)
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_substitution_candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_exercise_id UUID NOT NULL REFERENCES exercise_templates(id) ON DELETE CASCADE,
    substitute_exercise_id UUID NOT NULL REFERENCES exercise_templates(id) ON DELETE CASCADE,
    equipment_required TEXT[] DEFAULT '{}',
    difficulty_delta FLOAT DEFAULT 0.0, -- -0.5 (much easier) to +0.5 (much harder)
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(original_exercise_id, substitute_exercise_id)
);

-- Index for fast lookups by original exercise
CREATE INDEX IF NOT EXISTS idx_substitution_candidates_original
    ON exercise_substitution_candidates(original_exercise_id);

COMMENT ON TABLE exercise_substitution_candidates IS 'Pre-vetted exercise substitution pairs for rules-first AI recommendations';
COMMENT ON COLUMN exercise_substitution_candidates.equipment_required IS 'Equipment needed for the substitute exercise';
COMMENT ON COLUMN exercise_substitution_candidates.difficulty_delta IS 'Difficulty difference: negative = easier, positive = harder';

-- ============================================================================
-- 2. AI Recommendations (Generated substitutions and adjustments)
-- ============================================================================

CREATE TABLE IF NOT EXISTS recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    recommendation_type TEXT NOT NULL CHECK (recommendation_type IN ('equipment_substitution', 'intensity_adjustment', 'recovery_modification')),
    patch JSONB NOT NULL, -- Structured substitutions in JSONB format
    rationale TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'applied', 'rejected', 'undone')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    applied_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_recommendations_patient
    ON recommendations(patient_id, scheduled_date DESC);
CREATE INDEX IF NOT EXISTS idx_recommendations_session
    ON recommendations(session_id, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_recommendations_status
    ON recommendations(status) WHERE status = 'pending';

COMMENT ON TABLE recommendations IS 'AI-generated workout recommendations with structured patches';
COMMENT ON COLUMN recommendations.patch IS 'JSONB containing substitutions and adjustments with structured format';

-- ============================================================================
-- 3. Session Instances (Copy-on-write workout instances)
-- ============================================================================

CREATE TABLE IF NOT EXISTS session_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    template_session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    instance_data JSONB NOT NULL, -- Deep copy of session + exercises with applied substitutions
    created_from_recommendation_id UUID REFERENCES recommendations(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(patient_id, template_session_id, scheduled_date)
);

-- Index for fast lookups by patient and date
CREATE INDEX IF NOT EXISTS idx_session_instances_patient_date
    ON session_instances(patient_id, scheduled_date DESC);
CREATE INDEX IF NOT EXISTS idx_session_instances_template
    ON session_instances(template_session_id);

COMMENT ON TABLE session_instances IS 'Copy-on-write workout instances with applied AI substitutions - preserves master templates';
COMMENT ON COLUMN session_instances.instance_data IS 'JSONB containing modified session exercises after substitutions applied';

-- ============================================================================
-- 4. Extend daily_readiness with Equipment + WHOOP fields
-- ============================================================================

-- Add equipment availability tracking
ALTER TABLE daily_readiness
    ADD COLUMN IF NOT EXISTS equipment_available TEXT[] DEFAULT '{}';

-- Add intensity preference
ALTER TABLE daily_readiness
    ADD COLUMN IF NOT EXISTS intensity_preference TEXT
    CHECK (intensity_preference IN ('recovery', 'standard', 'go_hard'));

-- Add WHOOP recovery metrics
ALTER TABLE daily_readiness
    ADD COLUMN IF NOT EXISTS whoop_recovery_score FLOAT CHECK (whoop_recovery_score >= 0 AND whoop_recovery_score <= 100);

ALTER TABLE daily_readiness
    ADD COLUMN IF NOT EXISTS whoop_sleep_performance_percentage FLOAT CHECK (whoop_sleep_performance_percentage >= 0 AND whoop_sleep_performance_percentage <= 100);

ALTER TABLE daily_readiness
    ADD COLUMN IF NOT EXISTS whoop_hrv_rmssd FLOAT CHECK (whoop_hrv_rmssd >= 0);

ALTER TABLE daily_readiness
    ADD COLUMN IF NOT EXISTS whoop_strain FLOAT CHECK (whoop_strain >= 0 AND whoop_strain <= 21);

ALTER TABLE daily_readiness
    ADD COLUMN IF NOT EXISTS whoop_synced_at TIMESTAMPTZ;

COMMENT ON COLUMN daily_readiness.equipment_available IS 'Array of equipment available for today (e.g., [''barbell'', ''dumbbells'', ''bench''])';
COMMENT ON COLUMN daily_readiness.intensity_preference IS 'User-selected workout intensity for today';
COMMENT ON COLUMN daily_readiness.whoop_recovery_score IS 'WHOOP recovery score (0-100)';
COMMENT ON COLUMN daily_readiness.whoop_sleep_performance_percentage IS 'WHOOP sleep performance percentage';
COMMENT ON COLUMN daily_readiness.whoop_hrv_rmssd IS 'WHOOP HRV in milliseconds (RMSSD)';

-- ============================================================================
-- 5. Row Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS on new tables
ALTER TABLE exercise_substitution_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_instances ENABLE ROW LEVEL SECURITY;

-- exercise_substitution_candidates: Public read access (pre-vetted data)
CREATE POLICY "Anyone can view substitution candidates"
    ON exercise_substitution_candidates FOR SELECT
    USING (true);

-- recommendations: Patients can view/insert their own
CREATE POLICY "Patients can view own recommendations"
    ON recommendations FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can insert own recommendations"
    ON recommendations FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update own recommendations"
    ON recommendations FOR UPDATE
    USING (patient_id = auth.uid());

-- Therapists can view all recommendations
CREATE POLICY "Therapists can view all recommendations"
    ON recommendations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = recommendations.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- session_instances: Patients can manage their own instances
CREATE POLICY "Patients can view own session instances"
    ON session_instances FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can insert own session instances"
    ON session_instances FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update own session instances"
    ON session_instances FOR UPDATE
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can delete own session instances"
    ON session_instances FOR DELETE
    USING (patient_id = auth.uid());

-- Therapists can view patient session instances
CREATE POLICY "Therapists can view patient session instances"
    ON session_instances FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = session_instances.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- 6. Helper Functions
-- ============================================================================

-- Function to get available substitution candidates for an exercise
CREATE OR REPLACE FUNCTION get_substitution_candidates(
    p_original_exercise_id UUID,
    p_equipment_available TEXT[] DEFAULT '{}'
)
RETURNS TABLE (
    substitute_id UUID,
    substitute_name TEXT,
    equipment_required TEXT[],
    difficulty_delta FLOAT,
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        et.id,
        et.name,
        esc.equipment_required,
        esc.difficulty_delta,
        esc.notes
    FROM exercise_substitution_candidates esc
    JOIN exercise_templates et ON et.id = esc.substitute_exercise_id
    WHERE esc.original_exercise_id = p_original_exercise_id
    AND (
        p_equipment_available = '{}'::TEXT[] OR
        esc.equipment_required <@ p_equipment_available
    )
    ORDER BY esc.difficulty_delta ASC;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_substitution_candidates IS 'Returns available substitution candidates for an exercise filtered by equipment';
