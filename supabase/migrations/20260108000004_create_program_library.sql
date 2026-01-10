-- BUILD 138: Program Library - Consumer Program Catalog
-- Create tables for program library and user enrollments

-- ============================================================================
-- 1. Program Library Table (Consumer-facing program catalog)
-- ============================================================================

CREATE TABLE IF NOT EXISTS program_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL UNIQUE,
    description TEXT,
    category TEXT NOT NULL, -- 'baseball', 'strength', 'mobility', 'conditioning', etc.
    duration_weeks INT NOT NULL CHECK (duration_weeks > 0),
    difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    equipment_required TEXT[] DEFAULT '{}',
    cover_image_url TEXT,
    program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE, -- Link to actual program template
    is_featured BOOLEAN DEFAULT false,
    tags TEXT[] DEFAULT '{}', -- ['pitcher', 'in-season', 'velocity', etc.]
    author TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_program_library_category
    ON program_library(category);
CREATE INDEX IF NOT EXISTS idx_program_library_difficulty
    ON program_library(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_program_library_featured
    ON program_library(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_program_library_tags
    ON program_library USING GIN (tags);

COMMENT ON TABLE program_library IS 'Consumer-facing program catalog with metadata for browsing and discovery';
COMMENT ON COLUMN program_library.program_id IS 'Reference to actual program template (programs table)';
COMMENT ON COLUMN program_library.tags IS 'Searchable tags for filtering (e.g., pitcher, hitter, velocity, arm-care)';

-- ============================================================================
-- 2. Program Enrollments Table (Track user self-enrollments)
-- ============================================================================

CREATE TABLE IF NOT EXISTS program_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    program_library_id UUID NOT NULL REFERENCES program_library(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
    progress_percentage INT DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    notes TEXT,
    UNIQUE(patient_id, program_library_id)
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_program_enrollments_patient
    ON program_enrollments(patient_id, enrolled_at DESC);
CREATE INDEX IF NOT EXISTS idx_program_enrollments_status
    ON program_enrollments(status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_program_enrollments_program
    ON program_enrollments(program_library_id);

COMMENT ON TABLE program_enrollments IS 'Track user self-enrollments in program library programs';
COMMENT ON COLUMN program_enrollments.progress_percentage IS 'Calculated progress through program (0-100)';

-- ============================================================================
-- 3. Row Level Security
-- ============================================================================

ALTER TABLE program_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE program_enrollments ENABLE ROW LEVEL SECURITY;

-- program_library: Public read access (all users can browse)
CREATE POLICY "Anyone can view program library"
    ON program_library FOR SELECT
    USING (true);

-- Therapists can manage program library
CREATE POLICY "Therapists can insert program library items"
    ON program_library FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.therapist_id = auth.uid()
        )
    );

CREATE POLICY "Therapists can update program library items"
    ON program_library FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.therapist_id = auth.uid()
        )
    );

-- program_enrollments: Patients can manage their own enrollments
CREATE POLICY "Patients can view own enrollments"
    ON program_enrollments FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can insert own enrollments"
    ON program_enrollments FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update own enrollments"
    ON program_enrollments FOR UPDATE
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can delete own enrollments"
    ON program_enrollments FOR DELETE
    USING (patient_id = auth.uid());

-- Therapists can view their patients' enrollments
CREATE POLICY "Therapists can view patient enrollments"
    ON program_enrollments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = program_enrollments.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- 4. Helper Functions
-- ============================================================================

-- Function to search program library
CREATE OR REPLACE FUNCTION search_program_library(
    p_query TEXT DEFAULT NULL,
    p_category TEXT DEFAULT NULL,
    p_difficulty TEXT DEFAULT NULL,
    p_tags TEXT[] DEFAULT NULL,
    p_limit INT DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    category TEXT,
    duration_weeks INT,
    difficulty_level TEXT,
    equipment_required TEXT[],
    cover_image_url TEXT,
    is_featured BOOLEAN,
    tags TEXT[],
    enrollment_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pl.id,
        pl.title,
        pl.description,
        pl.category,
        pl.duration_weeks,
        pl.difficulty_level,
        pl.equipment_required,
        pl.cover_image_url,
        pl.is_featured,
        pl.tags,
        COUNT(pe.id) AS enrollment_count
    FROM program_library pl
    LEFT JOIN program_enrollments pe ON pe.program_library_id = pl.id
    WHERE
        (p_query IS NULL OR pl.title ILIKE '%' || p_query || '%' OR pl.description ILIKE '%' || p_query || '%')
        AND (p_category IS NULL OR pl.category = p_category)
        AND (p_difficulty IS NULL OR pl.difficulty_level = p_difficulty)
        AND (p_tags IS NULL OR pl.tags && p_tags)
    GROUP BY pl.id
    ORDER BY pl.is_featured DESC, enrollment_count DESC, pl.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION search_program_library IS 'Search and filter program library with optional criteria';

-- Function to get enrolled programs for a patient
CREATE OR REPLACE FUNCTION get_patient_enrolled_programs(
    p_patient_id UUID,
    p_status TEXT DEFAULT 'active'
)
RETURNS TABLE (
    enrollment_id UUID,
    program_id UUID,
    program_title TEXT,
    program_description TEXT,
    duration_weeks INT,
    enrolled_at TIMESTAMPTZ,
    progress_percentage INT,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pe.id AS enrollment_id,
        pl.id AS program_id,
        pl.title AS program_title,
        pl.description AS program_description,
        pl.duration_weeks,
        pe.enrolled_at,
        pe.progress_percentage,
        pe.status
    FROM program_enrollments pe
    JOIN program_library pl ON pl.id = pe.program_library_id
    WHERE pe.patient_id = p_patient_id
    AND (p_status IS NULL OR pe.status = p_status)
    ORDER BY pe.enrolled_at DESC;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_patient_enrolled_programs IS 'Get all enrolled programs for a patient with optional status filter';

-- Function to calculate enrollment progress
CREATE OR REPLACE FUNCTION calculate_enrollment_progress(
    p_enrollment_id UUID
)
RETURNS INT AS $$
DECLARE
    v_program_id UUID;
    v_total_sessions INT;
    v_completed_sessions INT;
    v_progress INT;
BEGIN
    -- Get program_id from enrollment
    SELECT program_id INTO v_program_id
    FROM program_library pl
    JOIN program_enrollments pe ON pe.program_library_id = pl.id
    WHERE pe.id = p_enrollment_id;

    IF v_program_id IS NULL THEN
        RETURN 0;
    END IF;

    -- Count total sessions in program
    SELECT COUNT(*) INTO v_total_sessions
    FROM sessions s
    JOIN phases ph ON ph.id = s.phase_id
    WHERE ph.program_id = v_program_id;

    IF v_total_sessions = 0 THEN
        RETURN 0;
    END IF;

    -- Count completed sessions (sessions with logged exercises)
    -- This is a placeholder - actual implementation would track session completion
    v_completed_sessions := 0;

    -- Calculate percentage
    v_progress := (v_completed_sessions * 100 / v_total_sessions);

    -- Update enrollment progress
    UPDATE program_enrollments
    SET progress_percentage = v_progress
    WHERE id = p_enrollment_id;

    RETURN v_progress;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_enrollment_progress IS 'Calculate and update enrollment progress based on session completion';

-- ============================================================================
-- 5. Trigger to update updated_at timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_program_library_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER program_library_updated_at
    BEFORE UPDATE ON program_library
    FOR EACH ROW
    EXECUTE FUNCTION update_program_library_updated_at();
