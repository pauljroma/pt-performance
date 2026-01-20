-- Migration: Create nutrition_logs table
-- Description: Stores patient nutrition tracking data with meal details and macros
-- Created: 2026-01-19

-- Create the nutrition_logs table
CREATE TABLE nutrition_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'pre_workout', 'post_workout')),
    food_items JSONB NOT NULL DEFAULT '[]',
    total_calories INT,
    total_protein_g DOUBLE PRECISION,
    total_carbs_g DOUBLE PRECISION,
    total_fat_g DOUBLE PRECISION,
    total_fiber_g DOUBLE PRECISION,
    notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add table comment
COMMENT ON TABLE nutrition_logs IS 'Stores patient nutrition tracking data including meals, macros, and food items';

-- Create indexes for common query patterns
CREATE INDEX idx_nutrition_logs_patient_id ON nutrition_logs(patient_id);
CREATE INDEX idx_nutrition_logs_logged_at ON nutrition_logs(logged_at);
CREATE INDEX idx_nutrition_logs_meal_type ON nutrition_logs(meal_type);

-- Enable Row Level Security
ALTER TABLE nutrition_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for patients
CREATE POLICY "Patients can view their own nutrition logs"
    ON nutrition_logs FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can insert their own nutrition logs"
    ON nutrition_logs FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update their own nutrition logs"
    ON nutrition_logs FOR UPDATE
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can delete their own nutrition logs"
    ON nutrition_logs FOR DELETE
    USING (patient_id = auth.uid());

-- RLS Policy for therapists to view their assigned patients' logs
CREATE POLICY "Therapists can view patient nutrition logs"
    ON nutrition_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patient_therapist_assignments pta
            WHERE pta.patient_id = nutrition_logs.patient_id
            AND pta.therapist_id = auth.uid()
        )
    );

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_logs TO authenticated;
