-- Migration: Create Therapist-Patient Assignment Table
-- Build: 119
-- Date: 2026-01-03
-- Purpose: Enable therapists to be assigned specific patients

-- Create therapist_patients table
CREATE TABLE IF NOT EXISTS therapist_patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapist_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    assigned_by UUID REFERENCES auth.users(id),
    notes TEXT,
    active BOOLEAN DEFAULT true,
    UNIQUE(therapist_id, patient_id)
);

-- Create indexes for performance
CREATE INDEX idx_therapist_patients_therapist_id ON therapist_patients(therapist_id);
CREATE INDEX idx_therapist_patients_patient_id ON therapist_patients(patient_id);
CREATE INDEX idx_therapist_patients_active ON therapist_patients(active) WHERE active = true;

-- Enable RLS on therapist_patients
ALTER TABLE therapist_patients ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Therapists can see their assigned patients
CREATE POLICY "Therapists can view assigned patients"
    ON therapist_patients FOR SELECT
    TO authenticated
    USING (
        therapist_id = auth.uid()
        OR patient_id = auth.uid()
        OR is_therapist(auth.uid()) = true
    );

-- RLS Policy: Only therapists/admins can manage assignments
CREATE POLICY "Therapists can manage assignments"
    ON therapist_patients FOR INSERT
    TO authenticated
    WITH CHECK (is_therapist(auth.uid()) = true);

CREATE POLICY "Therapists can update assignments"
    ON therapist_patients FOR UPDATE
    TO authenticated
    USING (therapist_id = auth.uid() OR is_therapist(auth.uid()) = true)
    WITH CHECK (therapist_id = auth.uid() OR is_therapist(auth.uid()) = true);

-- Function: Check if therapist is assigned to patient
CREATE OR REPLACE FUNCTION is_assigned_therapist(therapist_id UUID, patient_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM therapist_patients
        WHERE therapist_patients.therapist_id = $1
        AND therapist_patients.patient_id = $2
        AND active = true
    );
$$;

-- Function: Get all patients for a therapist
CREATE OR REPLACE FUNCTION get_therapist_patients(therapist_id UUID)
RETURNS TABLE (
    patient_id UUID,
    assigned_at TIMESTAMP WITH TIME ZONE,
    notes TEXT
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT patient_id, assigned_at, notes
    FROM therapist_patients
    WHERE therapist_patients.therapist_id = $1
    AND active = true
    ORDER BY assigned_at DESC;
$$;

-- Function: Get therapist for a patient
CREATE OR REPLACE FUNCTION get_patient_therapist(patient_id UUID)
RETURNS TABLE (
    therapist_id UUID,
    assigned_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT therapist_id, assigned_at
    FROM therapist_patients
    WHERE therapist_patients.patient_id = $1
    AND active = true
    ORDER BY assigned_at DESC
    LIMIT 1;
$$;

-- Comment
COMMENT ON TABLE therapist_patients IS 'Therapist-patient assignment table (BUILD 119)';
COMMENT ON FUNCTION is_assigned_therapist IS 'Check if therapist is assigned to patient (BUILD 119)';
COMMENT ON FUNCTION get_therapist_patients IS 'Get all patients for a therapist (BUILD 119)';
COMMENT ON FUNCTION get_patient_therapist IS 'Get primary therapist for a patient (BUILD 119)';
