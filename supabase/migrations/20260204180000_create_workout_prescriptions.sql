-- Workout Prescriptions Table
-- Tracks workouts assigned by therapists to specific patients

CREATE TABLE IF NOT EXISTS workout_prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Template reference (can be system or patient template)
    template_id UUID,
    template_type TEXT CHECK (template_type IN ('system', 'patient', 'custom')),

    -- Prescription details
    name TEXT NOT NULL,
    instructions TEXT,
    due_date DATE,
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),

    -- Status tracking
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'viewed', 'started', 'completed', 'expired', 'cancelled')),

    -- Link to actual session when started
    manual_session_id UUID REFERENCES manual_sessions(id) ON DELETE SET NULL,

    -- Timestamps
    prescribed_at TIMESTAMPTZ DEFAULT NOW(),
    viewed_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_prescriptions_patient ON workout_prescriptions(patient_id);
CREATE INDEX idx_prescriptions_therapist ON workout_prescriptions(therapist_id);
CREATE INDEX idx_prescriptions_status ON workout_prescriptions(status);
CREATE INDEX idx_prescriptions_due_date ON workout_prescriptions(due_date);

-- RLS Policies
ALTER TABLE workout_prescriptions ENABLE ROW LEVEL SECURITY;

-- Therapists can see prescriptions for their patients
CREATE POLICY therapist_view_prescriptions ON workout_prescriptions
    FOR SELECT TO authenticated
    USING (
        therapist_id = auth.uid() OR
        patient_id IN (SELECT id FROM patients WHERE therapist_id = auth.uid())
    );

-- Therapists can create prescriptions for their patients
CREATE POLICY therapist_create_prescriptions ON workout_prescriptions
    FOR INSERT TO authenticated
    WITH CHECK (
        patient_id IN (SELECT id FROM patients WHERE therapist_id = auth.uid())
    );

-- Therapists can update their prescriptions
CREATE POLICY therapist_update_prescriptions ON workout_prescriptions
    FOR UPDATE TO authenticated
    USING (therapist_id = auth.uid());

-- Patients can view their own prescriptions
CREATE POLICY patient_view_own_prescriptions ON workout_prescriptions
    FOR SELECT TO authenticated
    USING (
        patient_id IN (SELECT id FROM patients WHERE id::text = auth.uid()::text)
    );

-- Patients can update status of their prescriptions (viewed, started, completed)
CREATE POLICY patient_update_own_prescriptions ON workout_prescriptions
    FOR UPDATE TO authenticated
    USING (
        patient_id IN (SELECT id FROM patients WHERE id::text = auth.uid()::text)
    )
    WITH CHECK (
        -- Patients can only update certain fields
        status IN ('viewed', 'started', 'completed')
    );

-- Comments
COMMENT ON TABLE workout_prescriptions IS 'Workouts prescribed by therapists to specific patients';
COMMENT ON COLUMN workout_prescriptions.template_id IS 'Reference to system_workout_templates or patient_workout_templates';
COMMENT ON COLUMN workout_prescriptions.manual_session_id IS 'Links to the actual session when patient starts the workout';
