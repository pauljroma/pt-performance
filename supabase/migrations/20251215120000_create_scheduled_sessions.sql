-- Migration: Create scheduled_sessions table for patient scheduling
-- Date: 2025-12-15
-- Author: Build 46 Swarm Agent 1
-- Description: Enable patients to schedule workout sessions in advance

BEGIN;

-- Create scheduled_sessions table
CREATE TABLE IF NOT EXISTS scheduled_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    scheduled_time TIME NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled', 'rescheduled')),
    completed_at TIMESTAMPTZ,
    reminder_sent BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure patient can't schedule same session twice on same date
    UNIQUE(patient_id, session_id, scheduled_date)
);

-- Create indexes for performance
CREATE INDEX idx_scheduled_sessions_patient ON scheduled_sessions(patient_id);
CREATE INDEX idx_scheduled_sessions_date ON scheduled_sessions(scheduled_date);
CREATE INDEX idx_scheduled_sessions_status ON scheduled_sessions(status);
CREATE INDEX idx_scheduled_sessions_upcoming ON scheduled_sessions(patient_id, scheduled_date)
    WHERE status = 'scheduled' AND scheduled_date >= CURRENT_DATE;

-- Enable RLS
ALTER TABLE scheduled_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Patients can view their own scheduled sessions
CREATE POLICY "Patients view own scheduled sessions"
    ON scheduled_sessions FOR SELECT
    USING (patient_id = auth.uid());

-- Therapists can view all scheduled sessions
CREATE POLICY "Therapists view all scheduled sessions"
    ON scheduled_sessions FOR SELECT
    USING (
        auth.role() = 'therapist' OR
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = scheduled_sessions.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- Patients can create their own scheduled sessions
CREATE POLICY "Patients create own scheduled sessions"
    ON scheduled_sessions FOR INSERT
    WITH CHECK (
        patient_id = auth.uid() AND
        -- Verify session belongs to their active program
        EXISTS (
            SELECT 1 FROM sessions s
            JOIN phases ph ON s.phase_id = ph.id
            JOIN programs p ON ph.program_id = p.id
            WHERE s.id = scheduled_sessions.session_id
            AND p.patient_id = auth.uid()
            AND p.status = 'active'
        )
    );

-- Patients can update their own scheduled sessions
CREATE POLICY "Patients update own scheduled sessions"
    ON scheduled_sessions FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Therapists can manage all scheduled sessions
CREATE POLICY "Therapists manage scheduled sessions"
    ON scheduled_sessions FOR ALL
    USING (
        auth.role() = 'therapist' OR
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = scheduled_sessions.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_scheduled_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER scheduled_sessions_updated_at
    BEFORE UPDATE ON scheduled_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_scheduled_sessions_updated_at();

-- Create function to mark session as completed
CREATE OR REPLACE FUNCTION complete_scheduled_session(session_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE scheduled_sessions
    SET
        status = 'completed',
        completed_at = NOW()
    WHERE id = session_id
    AND status = 'scheduled';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create view for upcoming sessions (next 7 days)
CREATE OR REPLACE VIEW upcoming_scheduled_sessions AS
SELECT
    ss.*,
    s.name as session_name,
    ph.name as phase_name,
    p.name as program_name
FROM scheduled_sessions ss
JOIN sessions s ON ss.session_id = s.id
JOIN phases ph ON s.phase_id = ph.id
JOIN programs p ON ph.program_id = p.id
WHERE ss.status = 'scheduled'
AND ss.scheduled_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY ss.scheduled_date, ss.scheduled_time;

COMMIT;

-- Sample data (for testing - comment out for production)
-- INSERT INTO scheduled_sessions (patient_id, session_id, scheduled_date, scheduled_time)
-- SELECT
--     (SELECT id FROM patients LIMIT 1),
--     (SELECT id FROM sessions LIMIT 1),
--     CURRENT_DATE + 1,
--     '10:00:00'
-- WHERE EXISTS (SELECT 1 FROM patients LIMIT 1)
-- AND EXISTS (SELECT 1 FROM sessions LIMIT 1);
