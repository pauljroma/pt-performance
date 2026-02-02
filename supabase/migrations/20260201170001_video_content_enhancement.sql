-- Migration: Enhanced Video Content Support
-- Created: 2026-02-01
-- Description: Adds tables for HD video streaming support, user video preferences, and watch history analytics

-- Enhanced video metadata for HD streaming
CREATE TABLE IF NOT EXISTS exercise_video_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_template_id UUID REFERENCES exercise_templates(id) NOT NULL,

    -- Video variants for adaptive streaming
    video_url_sd TEXT,           -- 480p
    video_url_hd TEXT,           -- 720p
    video_url_fhd TEXT,          -- 1080p
    thumbnail_url TEXT,

    -- Video properties
    duration_seconds INTEGER,
    file_size_bytes BIGINT,
    aspect_ratio TEXT DEFAULT '16:9',

    -- Content metadata
    has_audio BOOLEAN DEFAULT false,
    has_captions BOOLEAN DEFAULT false,
    caption_url TEXT,

    -- Analytics
    view_count INTEGER DEFAULT 0,
    avg_watch_time_seconds NUMERIC(8,2),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(exercise_template_id)
);

-- Video quality preferences per user
CREATE TABLE IF NOT EXISTS user_video_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES patients(id) NOT NULL,

    preferred_quality TEXT DEFAULT 'auto' CHECK (preferred_quality IN ('auto', 'sd', 'hd', 'fhd')),
    auto_play BOOLEAN DEFAULT true,
    show_captions BOOLEAN DEFAULT false,
    playback_speed NUMERIC(3,2) DEFAULT 1.0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(patient_id)
);

-- Video watch history for analytics
CREATE TABLE IF NOT EXISTS video_watch_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES patients(id) NOT NULL,
    exercise_template_id UUID REFERENCES exercise_templates(id) NOT NULL,

    watched_at TIMESTAMPTZ DEFAULT NOW(),
    watch_duration_seconds INTEGER,
    completed BOOLEAN DEFAULT false,
    quality_used TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE exercise_video_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_video_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_watch_history ENABLE ROW LEVEL SECURITY;

-- Video metadata is readable by all authenticated users
CREATE POLICY "Video metadata readable by authenticated users"
ON exercise_video_metadata FOR SELECT
TO authenticated
USING (true);

-- User preferences accessible by owner
CREATE POLICY "Users can manage their video preferences"
ON user_video_preferences FOR ALL
TO authenticated
USING (patient_id::text = auth.uid()::text)
WITH CHECK (patient_id::text = auth.uid()::text);

-- Watch history accessible by owner
CREATE POLICY "Users can manage their watch history"
ON video_watch_history FOR ALL
TO authenticated
USING (patient_id::text = auth.uid()::text)
WITH CHECK (patient_id::text = auth.uid()::text);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_video_metadata_exercise ON exercise_video_metadata(exercise_template_id);
CREATE INDEX IF NOT EXISTS idx_video_prefs_patient ON user_video_preferences(patient_id);
CREATE INDEX IF NOT EXISTS idx_watch_history_patient ON video_watch_history(patient_id);
CREATE INDEX IF NOT EXISTS idx_watch_history_exercise ON video_watch_history(exercise_template_id);
CREATE INDEX IF NOT EXISTS idx_watch_history_date ON video_watch_history(watched_at);

-- Function to increment video view count
CREATE OR REPLACE FUNCTION increment_video_view_count(p_exercise_template_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE exercise_video_metadata
    SET view_count = view_count + 1,
        updated_at = NOW()
    WHERE exercise_template_id = p_exercise_template_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION increment_video_view_count(UUID) TO authenticated;
