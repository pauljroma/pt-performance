-- Migration: Create workout_templates system for therapists
-- Date: 2025-12-15
-- Author: Build 46 Swarm Agent 2
-- Description: Enable therapists to create and reuse workout templates

BEGIN;

-- Create workout_templates table
CREATE TABLE IF NOT EXISTS workout_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('strength', 'mobility', 'rehab', 'cardio', 'hybrid', 'other')),
    difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    duration_weeks INTEGER CHECK (duration_weeks > 0),
    created_by UUID NOT NULL REFERENCES patients(id), -- therapist who created
    is_public BOOLEAN DEFAULT FALSE,
    tags TEXT[], -- Array of tags for searchability
    usage_count INTEGER DEFAULT 0, -- Track how many times template has been used
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create template_phases table
CREATE TABLE IF NOT EXISTS template_phases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES workout_templates(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    sequence INTEGER NOT NULL CHECK (sequence > 0),
    duration_weeks INTEGER CHECK (duration_weeks > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure unique sequence per template
    UNIQUE(template_id, sequence)
);

-- Create template_sessions table
CREATE TABLE IF NOT EXISTS template_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phase_id UUID NOT NULL REFERENCES template_phases(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    sequence INTEGER NOT NULL CHECK (sequence > 0),
    exercises JSONB NOT NULL DEFAULT '[]', -- Array of exercise configs
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure unique sequence per phase
    UNIQUE(phase_id, sequence)
);

-- Create indexes for performance
CREATE INDEX idx_workout_templates_created_by ON workout_templates(created_by);
CREATE INDEX idx_workout_templates_category ON workout_templates(category);
CREATE INDEX idx_workout_templates_difficulty ON workout_templates(difficulty_level);
CREATE INDEX idx_workout_templates_public ON workout_templates(is_public) WHERE is_public = TRUE;
CREATE INDEX idx_workout_templates_tags ON workout_templates USING GIN(tags);

CREATE INDEX idx_template_phases_template ON template_phases(template_id);
CREATE INDEX idx_template_phases_sequence ON template_phases(template_id, sequence);

CREATE INDEX idx_template_sessions_phase ON template_sessions(phase_id);
CREATE INDEX idx_template_sessions_sequence ON template_sessions(phase_id, sequence);

-- Enable RLS
ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE template_phases ENABLE ROW LEVEL SECURITY;
ALTER TABLE template_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for workout_templates

-- Therapists can view all public templates and their own templates
CREATE POLICY "Therapists view templates"
    ON workout_templates FOR SELECT
    USING (
        is_public = TRUE OR
        created_by = auth.uid() OR
        auth.role() = 'therapist'
    );

-- Patients can view public templates
CREATE POLICY "Patients view public templates"
    ON workout_templates FOR SELECT
    USING (is_public = TRUE);

-- Therapists can create templates
CREATE POLICY "Therapists create templates"
    ON workout_templates FOR INSERT
    WITH CHECK (
        auth.role() = 'therapist' AND
        created_by = auth.uid()
    );

-- Therapists can update their own templates
CREATE POLICY "Therapists update own templates"
    ON workout_templates FOR UPDATE
    USING (created_by = auth.uid())
    WITH CHECK (created_by = auth.uid());

-- Therapists can delete their own templates
CREATE POLICY "Therapists delete own templates"
    ON workout_templates FOR DELETE
    USING (created_by = auth.uid());

-- RLS Policies for template_phases

-- Users can view phases of templates they can access
CREATE POLICY "Users view template phases"
    ON template_phases FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM workout_templates
            WHERE workout_templates.id = template_phases.template_id
            AND (
                workout_templates.is_public = TRUE OR
                workout_templates.created_by = auth.uid() OR
                auth.role() = 'therapist'
            )
        )
    );

-- Therapists can create phases for their templates
CREATE POLICY "Therapists create template phases"
    ON template_phases FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM workout_templates
            WHERE workout_templates.id = template_phases.template_id
            AND workout_templates.created_by = auth.uid()
        )
    );

-- Therapists can update phases of their templates
CREATE POLICY "Therapists update template phases"
    ON template_phases FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM workout_templates
            WHERE workout_templates.id = template_phases.template_id
            AND workout_templates.created_by = auth.uid()
        )
    );

-- Therapists can delete phases of their templates
CREATE POLICY "Therapists delete template phases"
    ON template_phases FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM workout_templates
            WHERE workout_templates.id = template_phases.template_id
            AND workout_templates.created_by = auth.uid()
        )
    );

-- RLS Policies for template_sessions

-- Users can view sessions of templates they can access
CREATE POLICY "Users view template sessions"
    ON template_sessions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM template_phases
            JOIN workout_templates ON workout_templates.id = template_phases.template_id
            WHERE template_phases.id = template_sessions.phase_id
            AND (
                workout_templates.is_public = TRUE OR
                workout_templates.created_by = auth.uid() OR
                auth.role() = 'therapist'
            )
        )
    );

-- Therapists can create sessions for their templates
CREATE POLICY "Therapists create template sessions"
    ON template_sessions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM template_phases
            JOIN workout_templates ON workout_templates.id = template_phases.template_id
            WHERE template_phases.id = template_sessions.phase_id
            AND workout_templates.created_by = auth.uid()
        )
    );

-- Therapists can update sessions of their templates
CREATE POLICY "Therapists update template sessions"
    ON template_sessions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM template_phases
            JOIN workout_templates ON workout_templates.id = template_phases.template_id
            WHERE template_phases.id = template_sessions.phase_id
            AND workout_templates.created_by = auth.uid()
        )
    );

-- Therapists can delete sessions of their templates
CREATE POLICY "Therapists delete template sessions"
    ON template_sessions FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM template_phases
            JOIN workout_templates ON workout_templates.id = template_phases.template_id
            WHERE template_phases.id = template_sessions.phase_id
            AND workout_templates.created_by = auth.uid()
        )
    );

-- Create triggers for updated_at timestamps

CREATE OR REPLACE FUNCTION update_workout_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER workout_templates_updated_at
    BEFORE UPDATE ON workout_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_workout_templates_updated_at();

CREATE OR REPLACE FUNCTION update_template_phases_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER template_phases_updated_at
    BEFORE UPDATE ON template_phases
    FOR EACH ROW
    EXECUTE FUNCTION update_template_phases_updated_at();

CREATE OR REPLACE FUNCTION update_template_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER template_sessions_updated_at
    BEFORE UPDATE ON template_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_template_sessions_updated_at();

-- Create function to increment template usage count
CREATE OR REPLACE FUNCTION increment_template_usage(template_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE workout_templates
    SET usage_count = usage_count + 1
    WHERE id = template_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to create program from template
CREATE OR REPLACE FUNCTION create_program_from_template(
    p_template_id UUID,
    p_patient_id UUID,
    p_program_name TEXT,
    p_start_date DATE DEFAULT CURRENT_DATE
)
RETURNS UUID AS $$
DECLARE
    v_program_id UUID;
    v_phase RECORD;
    v_new_phase_id UUID;
    v_session RECORD;
    v_current_date DATE := p_start_date;
BEGIN
    -- Create program
    INSERT INTO programs (patient_id, name, start_date, status)
    VALUES (p_patient_id, p_program_name, p_start_date, 'active')
    RETURNING id INTO v_program_id;

    -- Copy phases from template
    FOR v_phase IN
        SELECT * FROM template_phases
        WHERE template_id = p_template_id
        ORDER BY sequence
    LOOP
        -- Create phase
        INSERT INTO phases (program_id, name, sequence, duration_weeks)
        VALUES (v_program_id, v_phase.name, v_phase.sequence, v_phase.duration_weeks)
        RETURNING id INTO v_new_phase_id;

        -- Copy sessions from template phase
        FOR v_session IN
            SELECT * FROM template_sessions
            WHERE phase_id = v_phase.id
            ORDER BY sequence
        LOOP
            -- Create session with exercises from template
            INSERT INTO sessions (phase_id, name, sequence, exercises, notes)
            VALUES (v_new_phase_id, v_session.name, v_session.sequence, v_session.exercises, v_session.notes);
        END LOOP;
    END LOOP;

    -- Increment template usage count
    PERFORM increment_template_usage(p_template_id);

    RETURN v_program_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create view for popular templates
CREATE OR REPLACE VIEW popular_workout_templates AS
SELECT
    wt.*,
    COUNT(DISTINCT tp.id) as phase_count,
    COUNT(DISTINCT ts.id) as total_sessions
FROM workout_templates wt
LEFT JOIN template_phases tp ON wt.id = tp.template_id
LEFT JOIN template_sessions ts ON tp.id = ts.phase_id
WHERE wt.is_public = TRUE
GROUP BY wt.id
ORDER BY wt.usage_count DESC, wt.created_at DESC;

-- Create view for therapist's templates with stats
CREATE OR REPLACE VIEW therapist_templates_stats AS
SELECT
    wt.*,
    COUNT(DISTINCT tp.id) as phase_count,
    COUNT(DISTINCT ts.id) as total_sessions,
    p.email as creator_email,
    p.name as creator_name
FROM workout_templates wt
LEFT JOIN template_phases tp ON wt.id = tp.template_id
LEFT JOIN template_sessions ts ON tp.id = ts.phase_id
LEFT JOIN patients p ON wt.created_by = p.id
GROUP BY wt.id, p.email, p.name
ORDER BY wt.created_at DESC;

COMMIT;

-- Sample seed data (comment out for production)
-- INSERT INTO workout_templates (name, description, category, difficulty_level, duration_weeks, created_by, is_public)
-- SELECT
--     'ACL Rehabilitation Program',
--     'Comprehensive ACL rehabilitation focusing on strength and stability',
--     'rehab',
--     'intermediate',
--     12,
--     (SELECT id FROM patients WHERE role = 'therapist' LIMIT 1),
--     TRUE
-- WHERE EXISTS (SELECT 1 FROM patients WHERE role = 'therapist');
