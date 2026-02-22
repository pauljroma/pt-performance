-- 001_init_schema.sql
-- Initial database schema for PT Performance
-- Creates the core tables that all subsequent migrations depend on
--
-- This migration was reconstructed from the production schema.
-- The original file (001_init_supabase.sql) was never committed to version control.
-- All tables use CREATE TABLE IF NOT EXISTS for idempotency.

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. THERAPISTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS therapists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE,
    credentials TEXT,
    specialty TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 2. PATIENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    therapist_id UUID REFERENCES therapists(id) ON DELETE SET NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    date_of_birth DATE,
    sport TEXT,
    position TEXT,
    injury_type TEXT,
    target_level TEXT,
    profile_image_url TEXT,
    medical_history JSONB DEFAULT '{}'::jsonb,
    medications JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 3. PROGRAMS
-- ============================================================================

CREATE TABLE IF NOT EXISTS programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    target_level TEXT,
    duration_weeks INT,
    status TEXT DEFAULT 'active',
    program_type TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 4. PHASES
-- ============================================================================

CREATE TABLE IF NOT EXISTS phases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    phase_number INT,
    sequence INT,
    name TEXT NOT NULL,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 5. SESSIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phase_id UUID NOT NULL REFERENCES phases(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sequence INT,
    weekday INT,
    notes TEXT,
    completed BOOLEAN DEFAULT false,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    total_volume NUMERIC,
    avg_rpe NUMERIC,
    avg_pain NUMERIC,
    duration_minutes INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 6. EXERCISE TEMPLATES
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT,
    body_region TEXT,
    description TEXT,
    instructions TEXT,
    video_url TEXT,
    video_thumbnail_url TEXT,
    video_duration INT,
    form_cues JSONB DEFAULT '[]'::jsonb,
    difficulty_level TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 7. SESSION EXERCISES (join between sessions and exercise_templates)
-- ============================================================================

CREATE TABLE IF NOT EXISTS session_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    exercise_template_id UUID NOT NULL REFERENCES exercise_templates(id) ON DELETE CASCADE,
    sequence INT,
    order_index INT,
    prescribed_sets INT,
    prescribed_reps TEXT,
    prescribed_load NUMERIC,
    load_unit TEXT DEFAULT 'lbs',
    rest_period_seconds INT,
    notes TEXT,
    target_sets INT,
    target_reps INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 8. EXERCISE LOGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,
    session_exercise_id UUID REFERENCES session_exercises(id) ON DELETE SET NULL,
    exercise_template_id UUID REFERENCES exercise_templates(id) ON DELETE SET NULL,
    performed_at TIMESTAMPTZ DEFAULT now(),
    logged_at TIMESTAMPTZ DEFAULT now(),
    actual_sets INT,
    actual_reps JSONB,
    actual_load NUMERIC,
    load_unit TEXT DEFAULT 'lbs',
    rpe INT,
    pain_score INT,
    notes TEXT,
    completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 9. PAIN LOGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS pain_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    logged_at TIMESTAMPTZ DEFAULT now(),
    pain_during INT,
    pain_before INT,
    pain_after INT,
    body_region TEXT,
    pain_location TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 10. BULLPEN LOGS (throwing workload tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS bullpen_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    logged_at TIMESTAMPTZ DEFAULT now(),
    pitch_count INT,
    pitch_type TEXT,
    velocity NUMERIC,
    pain_score INT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 11. BODY COMPOSITION MEASUREMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS body_comp_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    recorded_at TIMESTAMPTZ DEFAULT now(),
    measurement_date DATE,
    weight_lb NUMERIC,
    body_fat_percent NUMERIC,
    muscle_mass_lb NUMERIC,
    bmi NUMERIC,
    waist_in NUMERIC,
    chest_in NUMERIC,
    arm_in NUMERIC,
    leg_in NUMERIC,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 12. SESSION NOTES (clinical documentation)
-- ============================================================================

CREATE TABLE IF NOT EXISTS session_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,
    note_type TEXT DEFAULT 'general',
    note_text TEXT,
    content TEXT,
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Patients
CREATE INDEX IF NOT EXISTS idx_patients_therapist_id ON patients(therapist_id);
CREATE INDEX IF NOT EXISTS idx_patients_user_id ON patients(user_id);

-- Programs
CREATE INDEX IF NOT EXISTS idx_programs_patient_id ON programs(patient_id);

-- Phases
CREATE INDEX IF NOT EXISTS idx_phases_program_id ON phases(program_id);

-- Sessions
CREATE INDEX IF NOT EXISTS idx_sessions_phase_id ON sessions(phase_id);

-- Session exercises
CREATE INDEX IF NOT EXISTS idx_session_exercises_session_id ON session_exercises(session_id);
CREATE INDEX IF NOT EXISTS idx_session_exercises_template_id ON session_exercises(exercise_template_id);

-- Exercise logs
CREATE INDEX IF NOT EXISTS idx_exercise_logs_patient_id ON exercise_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_exercise_logs_session_id ON exercise_logs(session_id);

-- Pain logs
CREATE INDEX IF NOT EXISTS idx_pain_logs_patient_id ON pain_logs(patient_id);

-- Bullpen logs
CREATE INDEX IF NOT EXISTS idx_bullpen_logs_patient_id ON bullpen_logs(patient_id);

-- Body comp
CREATE INDEX IF NOT EXISTS idx_body_comp_patient_id ON body_comp_measurements(patient_id);

-- Session notes
CREATE INDEX IF NOT EXISTS idx_session_notes_patient_id ON session_notes(patient_id);
CREATE INDEX IF NOT EXISTS idx_session_notes_session_id ON session_notes(session_id);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    tbl TEXT;
    missing TEXT[] := '{}';
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'therapists', 'patients', 'programs', 'phases', 'sessions',
        'exercise_templates', 'session_exercises', 'exercise_logs',
        'pain_logs', 'bullpen_logs', 'body_comp_measurements', 'session_notes'
    ]
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_tables
            WHERE schemaname = 'public' AND tablename = tbl
        ) THEN
            missing := array_append(missing, tbl);
        END IF;
    END LOOP;

    IF array_length(missing, 1) > 0 THEN
        RAISE EXCEPTION 'Init schema verification failed. Missing tables: %', array_to_string(missing, ', ');
    ELSE
        RAISE NOTICE 'Init schema verified: all 12 core tables exist';
    END IF;
END $$;
