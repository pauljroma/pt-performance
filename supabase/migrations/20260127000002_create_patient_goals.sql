-- Migration: Create Patient Goals Table
-- Ticket: ACP-523
-- Date: 2026-01-27
-- Purpose: Enable patients to set, track, and manage personal performance/recovery goals

-- Create the patient_goals table
CREATE TABLE IF NOT EXISTS patient_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'custom'
        CHECK (category IN ('strength', 'mobility', 'endurance', 'pain_reduction', 'body_composition', 'rehabilitation', 'custom')),
    target_value DOUBLE PRECISION,
    current_value DOUBLE PRECISION,
    unit TEXT,
    target_date DATE,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Comment on the table
COMMENT ON TABLE patient_goals IS 'Patient-defined goals for tracking progress across strength, mobility, rehab, etc.';

-- Indexes for common query patterns
CREATE INDEX idx_patient_goals_patient_id ON patient_goals(patient_id);
CREATE INDEX idx_patient_goals_status ON patient_goals(status);
CREATE INDEX idx_patient_goals_patient_status ON patient_goals(patient_id, status);
CREATE INDEX idx_patient_goals_created_at ON patient_goals(created_at DESC);
CREATE INDEX idx_patient_goals_category ON patient_goals(category);

-- Auto-update updated_at on row modification
CREATE OR REPLACE FUNCTION update_patient_goals_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_patient_goals_updated_at
    BEFORE UPDATE ON patient_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_patient_goals_updated_at();

-- Enable Row Level Security
ALTER TABLE patient_goals ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Patients can view their own goals
CREATE POLICY "Patients can view own goals"
    ON patient_goals FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- RLS Policy: Patients can insert their own goals
CREATE POLICY "Patients can insert own goals"
    ON patient_goals FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- RLS Policy: Patients can update their own goals
CREATE POLICY "Patients can update own goals"
    ON patient_goals FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- RLS Policy: Patients can delete their own goals
CREATE POLICY "Patients can delete own goals"
    ON patient_goals FOR DELETE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- RLS Policy: Therapists can view goals of their assigned patients
CREATE POLICY "Therapists can view patient goals"
    ON patient_goals FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE therapist_id IN (
                SELECT id FROM therapists WHERE user_id = auth.uid()
            )
        )
    );
