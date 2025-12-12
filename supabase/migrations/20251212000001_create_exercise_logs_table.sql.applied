-- Migration: Create exercise_logs table for tracking patient exercise performance
-- Date: 2025-12-12
-- Purpose: Allow patients to log sets, reps, load, RPE, and pain for each exercise

-- Create exercise_logs table
CREATE TABLE IF NOT EXISTS exercise_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_exercise_id UUID NOT NULL REFERENCES session_exercises(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Performance data
    actual_sets INT NOT NULL CHECK (actual_sets > 0),
    actual_reps INT[] NOT NULL,  -- Array of reps per set
    actual_load NUMERIC(6,2),  -- Weight used
    load_unit TEXT DEFAULT 'lbs' CHECK (load_unit IN ('lbs', 'kg')),

    -- Subjective metrics
    rpe INT NOT NULL CHECK (rpe >= 0 AND rpe <= 10),  -- Rating of Perceived Exertion
    pain_score INT NOT NULL CHECK (pain_score >= 0 AND pain_score <= 10),  -- Pain level

    -- Additional context
    notes TEXT,
    completed BOOLEAN DEFAULT true,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_exercise_logs_patient_id ON exercise_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_exercise_logs_session_exercise_id ON exercise_logs(session_exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercise_logs_logged_at ON exercise_logs(logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_exercise_logs_patient_logged_at ON exercise_logs(patient_id, logged_at DESC);

-- RLS Policies
ALTER TABLE exercise_logs ENABLE ROW LEVEL SECURITY;

-- Patients can only see their own logs
CREATE POLICY "exercise_logs_select_patient" ON exercise_logs
    FOR SELECT
    USING (patient_id = auth.uid());

-- Patients can insert their own logs
CREATE POLICY "exercise_logs_insert_patient" ON exercise_logs
    FOR INSERT
    WITH CHECK (patient_id = auth.uid());

-- Patients can update their own logs
CREATE POLICY "exercise_logs_update_patient" ON exercise_logs
    FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Therapists can view logs for their patients
CREATE POLICY "exercise_logs_select_therapist" ON exercise_logs
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = exercise_logs.patient_id
            AND p.therapist_id = (
                SELECT id FROM therapists WHERE user_id = auth.uid()
            )
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON exercise_logs TO authenticated;
GRANT SELECT ON exercise_logs TO anon;  -- For demo purposes

-- Add comment
COMMENT ON TABLE exercise_logs IS 'Tracks patient exercise performance including sets, reps, load, RPE, and pain levels';
