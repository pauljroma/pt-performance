-- Migration: Create nutrition_goals table
-- Description: Stores nutrition goals for patients (daily/weekly targets)

CREATE TABLE nutrition_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    goal_type TEXT NOT NULL CHECK (goal_type IN ('daily', 'weekly')),
    target_calories INT,
    target_protein_g DOUBLE PRECISION,
    target_carbs_g DOUBLE PRECISION,
    target_fat_g DOUBLE PRECISION,
    target_fiber_g DOUBLE PRECISION,
    target_water_ml INT,
    protein_per_kg DOUBLE PRECISION, -- protein per kg body weight
    active BOOLEAN DEFAULT TRUE,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    notes TEXT,
    created_by UUID REFERENCES auth.users(id), -- therapist or patient
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_nutrition_goals_patient_id ON nutrition_goals(patient_id);
CREATE INDEX idx_nutrition_goals_active ON nutrition_goals(active) WHERE active = TRUE;

-- Enable RLS
ALTER TABLE nutrition_goals ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Patients can view their own nutrition goals"
    ON nutrition_goals FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can insert their own nutrition goals"
    ON nutrition_goals FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update their own nutrition goals"
    ON nutrition_goals FOR UPDATE
    USING (patient_id = auth.uid());

-- Therapists can manage patient goals
CREATE POLICY "Therapists can view patient nutrition goals"
    ON nutrition_goals FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patient_therapist_assignments pta
            WHERE pta.patient_id = nutrition_goals.patient_id
            AND pta.therapist_id = auth.uid()
        )
    );

CREATE POLICY "Therapists can insert patient nutrition goals"
    ON nutrition_goals FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patient_therapist_assignments pta
            WHERE pta.patient_id = nutrition_goals.patient_id
            AND pta.therapist_id = auth.uid()
        )
    );

CREATE POLICY "Therapists can update patient nutrition goals"
    ON nutrition_goals FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM patient_therapist_assignments pta
            WHERE pta.patient_id = nutrition_goals.patient_id
            AND pta.therapist_id = auth.uid()
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_goals TO authenticated;
