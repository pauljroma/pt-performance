-- BUILD 384: Create patient favorite exercises table
-- Allows patients to mark exercises as favorites for quick access

BEGIN;

-- Create the patient_favorite_exercises table
CREATE TABLE IF NOT EXISTS patient_favorite_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    exercise_template_id UUID NOT NULL REFERENCES exercise_templates(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(patient_id, exercise_template_id)
);

-- Enable RLS
ALTER TABLE patient_favorite_exercises ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Patients can only see and manage their own favorites
CREATE POLICY "patient_favorite_exercises_select_own"
    ON patient_favorite_exercises FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "patient_favorite_exercises_insert_own"
    ON patient_favorite_exercises FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "patient_favorite_exercises_delete_own"
    ON patient_favorite_exercises FOR DELETE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_patient_favorite_exercises_patient
    ON patient_favorite_exercises(patient_id);

-- Grant permissions
GRANT ALL ON patient_favorite_exercises TO authenticated;

COMMIT;
