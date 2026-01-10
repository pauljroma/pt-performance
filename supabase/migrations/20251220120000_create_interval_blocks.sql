-- Migration: Create interval blocks for time-based training (Tabata, EMOM, AMRAP, etc.)
-- Date: 2025-12-20
-- Description: Adds support for interval-based training blocks (warmups, conditioning, etc.)

-- Create interval_block_templates table (reusable templates like "Classic Tabata")
CREATE TABLE IF NOT EXISTS interval_block_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    block_type TEXT NOT NULL DEFAULT 'mobility', -- 'mobility', 'endurance', 'recovery'
    work_duration INT NOT NULL, -- seconds
    rest_duration INT NOT NULL, -- seconds
    rounds INT NOT NULL,
    exercises JSONB, -- Array of exercise names or instructions
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create session_interval_blocks table (blocks attached to sessions)
CREATE TABLE IF NOT EXISTS session_interval_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    template_id UUID REFERENCES interval_block_templates(id),

    -- Block configuration
    name TEXT NOT NULL,
    description TEXT,
    block_type TEXT NOT NULL DEFAULT 'mobility',
    sort_order INT NOT NULL DEFAULT 0, -- 0 = before exercises (warmup)

    -- Timing configuration
    work_duration INT NOT NULL, -- seconds
    rest_duration INT NOT NULL, -- seconds
    rounds INT NOT NULL,
    exercises JSONB NOT NULL, -- [{name: "Jumping Jacks", videoUrl: "..."}, ...]

    -- Completion tracking
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    session_rpe INT CHECK (session_rpe >= 0 AND session_rpe <= 10),
    total_duration INT, -- actual duration in seconds

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_session_interval_blocks_session_id
    ON session_interval_blocks(session_id);
CREATE INDEX IF NOT EXISTS idx_session_interval_blocks_sort_order
    ON session_interval_blocks(session_id, sort_order);

-- Add RLS policies for interval blocks
ALTER TABLE session_interval_blocks ENABLE ROW LEVEL SECURITY;

-- Therapists can manage all interval blocks
CREATE POLICY "Therapists can view all interval blocks"
    ON session_interval_blocks
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.id = auth.uid()
        )
    );

CREATE POLICY "Therapists can insert interval blocks"
    ON session_interval_blocks
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.id = auth.uid()
        )
    );

CREATE POLICY "Therapists can update interval blocks"
    ON session_interval_blocks
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.id = auth.uid()
        )
    );

-- Patients can view their own session's interval blocks
CREATE POLICY "Patients can view their session interval blocks"
    ON session_interval_blocks
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sessions s
            JOIN programs p ON s.phase_id = (
                SELECT id FROM phases WHERE program_id = p.id LIMIT 1
            )
            JOIN patients pat ON p.patient_id = pat.id
            WHERE s.id = session_interval_blocks.session_id
            AND pat.id = auth.uid()
        )
    );

-- Patients can update completion status on their blocks
CREATE POLICY "Patients can complete their interval blocks"
    ON session_interval_blocks
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM sessions s
            JOIN programs p ON s.phase_id = (
                SELECT id FROM phases WHERE program_id = p.id LIMIT 1
            )
            JOIN patients pat ON p.patient_id = pat.id
            WHERE s.id = session_interval_blocks.session_id
            AND pat.id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM sessions s
            JOIN programs p ON s.phase_id = (
                SELECT id FROM phases WHERE program_id = p.id LIMIT 1
            )
            JOIN patients pat ON p.patient_id = pat.id
            WHERE s.id = session_interval_blocks.session_id
            AND pat.id = auth.uid()
        )
    );

-- RLS for templates (read-only for now)
ALTER TABLE interval_block_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view interval block templates"
    ON interval_block_templates
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Therapists can manage interval block templates"
    ON interval_block_templates
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.id = auth.uid()
        )
    );

-- Seed common Tabata templates
INSERT INTO interval_block_templates (name, description, block_type, work_duration, rest_duration, rounds, exercises) VALUES
-- Classic Tabata
('Classic Tabata', '20s work, 10s rest, 8 rounds - original Tabata protocol', 'mobility', 20, 10, 8,
 '[{"name": "Jumping Jacks"}, {"name": "High Knees"}, {"name": "Butt Kicks"}, {"name": "Arm Circles"}]'::jsonb),

-- Modified Tabata (easier)
('Tabata Light', '20s work, 20s rest, 6 rounds - beginner friendly', 'mobility', 20, 20, 6,
 '[{"name": "March in Place"}, {"name": "Arm Swings"}, {"name": "Hip Circles"}]'::jsonb),

-- Extended work
('Extended Work Tabata', '30s work, 15s rest, 8 rounds', 'endurance', 30, 15, 8,
 '[{"name": "Mountain Climbers"}, {"name": "Burpees"}, {"name": "Jump Squats"}]'::jsonb),

-- Short bursts
('Quick Burst', '10s work, 10s rest, 12 rounds - explosive work', 'endurance', 10, 10, 12,
 '[{"name": "Box Jumps"}, {"name": "Medicine Ball Slams"}]'::jsonb),

-- Recovery/Mobility
('Dynamic Warmup', '30s per movement, 10s transition, 8 rounds', 'mobility', 30, 10, 8,
 '[{"name": "World''s Greatest Stretch"}, {"name": "Spiderman Lunge"}, {"name": "Inchworms"}, {"name": "Leg Swings"}]'::jsonb),

-- EMOM style (Every Minute on the Minute)
('EMOM Warmup', '40s work, 20s rest, 5 rounds', 'mobility', 40, 20, 5,
 '[{"name": "Jumping Jacks"}, {"name": "Push-ups"}, {"name": "Squats"}, {"name": "Plank"}]'::jsonb)

ON CONFLICT DO NOTHING;

-- Add updated_at trigger for both tables
CREATE OR REPLACE FUNCTION update_interval_blocks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_interval_block_templates_updated_at
    BEFORE UPDATE ON interval_block_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_interval_blocks_updated_at();

CREATE TRIGGER update_session_interval_blocks_updated_at
    BEFORE UPDATE ON session_interval_blocks
    FOR EACH ROW
    EXECUTE FUNCTION update_interval_blocks_updated_at();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON interval_block_templates TO authenticated;
GRANT SELECT, INSERT, UPDATE ON session_interval_blocks TO authenticated;
