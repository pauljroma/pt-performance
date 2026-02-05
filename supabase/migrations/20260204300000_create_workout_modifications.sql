-- BUILD HEALTH-PLATFORM: Create workout_modifications table for Adaptive Training Engine
-- This table stores suggested workout modifications based on health/readiness data
-- Athletes can accept or decline these suggestions

-- Create enum types for modification status and type
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'modification_status') THEN
        CREATE TYPE modification_status AS ENUM (
            'pending',
            'accepted',
            'declined',
            'modified',
            'expired'
        );
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'modification_type') THEN
        CREATE TYPE modification_type AS ENUM (
            'load_adjustment',
            'volume_reduction',
            'exercise_swap',
            'workout_delay',
            'insert_recovery_day',
            'trigger_deload',
            'intensity_zone_change',
            'skip_workout'
        );
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'modification_trigger') THEN
        CREATE TYPE modification_trigger AS ENUM (
            'low_readiness',
            'high_readiness',
            'consecutive_low_days',
            'high_acwr',
            'low_hrv',
            'poor_sleep',
            'pain_reported',
            'high_fatigue',
            'manual_request',
            'ai_coach_suggestion'
        );
    END IF;
END$$;

-- Create the workout_modifications table
CREATE TABLE IF NOT EXISTS workout_modifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    scheduled_session_id UUID REFERENCES scheduled_sessions(id) ON DELETE SET NULL,
    session_name TEXT,
    scheduled_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Modification details
    modification_type TEXT NOT NULL,
    trigger TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',

    -- Health context
    readiness_score NUMERIC(5,2),
    fatigue_score NUMERIC(5,2),

    -- Specific modification parameters
    load_adjustment_percentage NUMERIC(5,2),
    volume_reduction_sets INTEGER,
    delay_days INTEGER,
    deload_duration_days INTEGER,
    exercise_modifications JSONB,

    -- Explanation
    reason TEXT NOT NULL,
    detailed_explanation TEXT,

    -- Resolution
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    athlete_feedback TEXT,

    -- Constraints
    CONSTRAINT valid_modification_type CHECK (
        modification_type IN (
            'load_adjustment', 'volume_reduction', 'exercise_swap',
            'workout_delay', 'insert_recovery_day', 'trigger_deload',
            'intensity_zone_change', 'skip_workout'
        )
    ),
    CONSTRAINT valid_trigger CHECK (
        trigger IN (
            'low_readiness', 'high_readiness', 'consecutive_low_days',
            'high_acwr', 'low_hrv', 'poor_sleep', 'pain_reported',
            'high_fatigue', 'manual_request', 'ai_coach_suggestion'
        )
    ),
    CONSTRAINT valid_status CHECK (
        status IN ('pending', 'accepted', 'declined', 'modified', 'expired')
    )
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_workout_modifications_patient_id
    ON workout_modifications(patient_id);

CREATE INDEX IF NOT EXISTS idx_workout_modifications_status
    ON workout_modifications(status);

CREATE INDEX IF NOT EXISTS idx_workout_modifications_scheduled_date
    ON workout_modifications(scheduled_date);

CREATE INDEX IF NOT EXISTS idx_workout_modifications_patient_pending
    ON workout_modifications(patient_id, status)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_workout_modifications_created_at
    ON workout_modifications(created_at DESC);

-- Enable Row Level Security
ALTER TABLE workout_modifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Patients can view their own modifications
CREATE POLICY "patients_view_own_modifications"
    ON workout_modifications FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
        OR
        -- Demo patient access for testing
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- Patients can update their own modifications (accept/decline)
CREATE POLICY "patients_update_own_modifications"
    ON workout_modifications FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
        OR
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    )
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
        OR
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- System can insert modifications (via service role or SECURITY DEFINER function)
CREATE POLICY "system_insert_modifications"
    ON workout_modifications FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
        OR
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- Therapists can view their patients' modifications
CREATE POLICY "therapists_view_patient_modifications"
    ON workout_modifications FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT patient_id FROM therapist_patients
            WHERE therapist_id IN (
                SELECT id FROM therapists WHERE user_id = auth.uid()
            )
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON workout_modifications TO authenticated;

-- Create helper function to fetch pending modifications
CREATE OR REPLACE FUNCTION get_pending_modifications(p_patient_id UUID)
RETURNS SETOF workout_modifications
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT *
    FROM workout_modifications
    WHERE patient_id = p_patient_id
      AND status = 'pending'
      AND scheduled_date >= CURRENT_DATE
    ORDER BY scheduled_date ASC, created_at DESC;
$$;

-- Create helper function to resolve a modification
CREATE OR REPLACE FUNCTION resolve_modification(
    p_modification_id UUID,
    p_status TEXT,
    p_feedback TEXT DEFAULT NULL
)
RETURNS workout_modifications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result workout_modifications;
BEGIN
    -- Validate status
    IF p_status NOT IN ('accepted', 'declined', 'modified') THEN
        RAISE EXCEPTION 'Invalid status: %', p_status;
    END IF;

    UPDATE workout_modifications
    SET
        status = p_status,
        resolved_at = NOW(),
        athlete_feedback = COALESCE(p_feedback, athlete_feedback)
    WHERE id = p_modification_id
    RETURNING * INTO result;

    IF result IS NULL THEN
        RAISE EXCEPTION 'Modification not found: %', p_modification_id;
    END IF;

    RETURN result;
END;
$$;

-- Create function to expire old pending modifications
CREATE OR REPLACE FUNCTION expire_old_modifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE workout_modifications
    SET status = 'expired'
    WHERE status = 'pending'
      AND scheduled_date < CURRENT_DATE;

    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$;

-- Create function to generate modification (called from iOS app)
CREATE OR REPLACE FUNCTION create_workout_modification(
    p_patient_id UUID,
    p_scheduled_session_id UUID DEFAULT NULL,
    p_scheduled_date DATE DEFAULT CURRENT_DATE,
    p_modification_type TEXT DEFAULT 'load_adjustment',
    p_trigger TEXT DEFAULT 'low_readiness',
    p_readiness_score NUMERIC DEFAULT NULL,
    p_fatigue_score NUMERIC DEFAULT NULL,
    p_load_adjustment_percentage NUMERIC DEFAULT NULL,
    p_volume_reduction_sets INTEGER DEFAULT NULL,
    p_delay_days INTEGER DEFAULT NULL,
    p_deload_duration_days INTEGER DEFAULT NULL,
    p_exercise_modifications JSONB DEFAULT NULL,
    p_reason TEXT DEFAULT '',
    p_detailed_explanation TEXT DEFAULT NULL
)
RETURNS workout_modifications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result workout_modifications;
    session_name_val TEXT;
BEGIN
    -- Get session name if session ID provided
    IF p_scheduled_session_id IS NOT NULL THEN
        SELECT name INTO session_name_val
        FROM scheduled_sessions
        WHERE id = p_scheduled_session_id;
    END IF;

    INSERT INTO workout_modifications (
        patient_id,
        scheduled_session_id,
        session_name,
        scheduled_date,
        modification_type,
        trigger,
        status,
        readiness_score,
        fatigue_score,
        load_adjustment_percentage,
        volume_reduction_sets,
        delay_days,
        deload_duration_days,
        exercise_modifications,
        reason,
        detailed_explanation
    ) VALUES (
        p_patient_id,
        p_scheduled_session_id,
        session_name_val,
        p_scheduled_date,
        p_modification_type,
        p_trigger,
        'pending',
        p_readiness_score,
        p_fatigue_score,
        p_load_adjustment_percentage,
        p_volume_reduction_sets,
        p_delay_days,
        p_deload_duration_days,
        p_exercise_modifications,
        p_reason,
        p_detailed_explanation
    )
    RETURNING * INTO result;

    RETURN result;
END;
$$;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION get_pending_modifications(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION resolve_modification(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_workout_modification(
    UUID, UUID, DATE, TEXT, TEXT, NUMERIC, NUMERIC,
    NUMERIC, INTEGER, INTEGER, INTEGER, JSONB, TEXT, TEXT
) TO authenticated;

-- Add comment for documentation
COMMENT ON TABLE workout_modifications IS 'Stores suggested workout modifications from the Adaptive Training Engine based on health/readiness data';
COMMENT ON FUNCTION get_pending_modifications(UUID) IS 'Fetch all pending workout modifications for a patient';
COMMENT ON FUNCTION resolve_modification(UUID, TEXT, TEXT) IS 'Accept or decline a workout modification';
COMMENT ON FUNCTION create_workout_modification IS 'Create a new workout modification suggestion';
