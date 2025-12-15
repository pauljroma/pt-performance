-- Migration: Add video support to exercises table
-- Date: 2025-12-15
-- Author: Build 46 Swarm Agent 4
-- Description: Enable video demonstrations for exercises

BEGIN;

-- Add video columns to exercises table
ALTER TABLE exercises
ADD COLUMN IF NOT EXISTS video_url TEXT,
ADD COLUMN IF NOT EXISTS video_thumbnail_url TEXT,
ADD COLUMN IF NOT EXISTS video_duration INTEGER, -- Duration in seconds
ADD COLUMN IF NOT EXISTS form_cues JSONB DEFAULT '[]'; -- Array of form tips

-- Create index for exercises with videos
CREATE INDEX IF NOT EXISTS idx_exercises_with_video
    ON exercises(id)
    WHERE video_url IS NOT NULL;

-- Create video_views table to track which patients have watched which videos
CREATE TABLE IF NOT EXISTS video_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ DEFAULT NOW(),
    watch_duration INTEGER, -- Seconds watched
    completed BOOLEAN DEFAULT FALSE, -- Did they watch to the end?

    -- Track unique views per patient per exercise per day
    UNIQUE(patient_id, exercise_id, viewed_at)
);

-- Create indexes for video_views
CREATE INDEX idx_video_views_patient ON video_views(patient_id);
CREATE INDEX idx_video_views_exercise ON video_views(exercise_id);
CREATE INDEX idx_video_views_date ON video_views(viewed_at);

-- Enable RLS
ALTER TABLE video_views ENABLE ROW LEVEL SECURITY;

-- RLS Policies for video_views

-- Patients can view their own video watch history
CREATE POLICY "Patients view own video views"
    ON video_views FOR SELECT
    USING (patient_id = auth.uid());

-- Patients can log their own video views
CREATE POLICY "Patients create own video views"
    ON video_views FOR INSERT
    WITH CHECK (patient_id = auth.uid());

-- Therapists can view all video views for their patients
CREATE POLICY "Therapists view patient video views"
    ON video_views FOR SELECT
    USING (
        auth.role() = 'therapist' OR
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = video_views.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- Create function to log video view
CREATE OR REPLACE FUNCTION log_video_view(
    p_patient_id UUID,
    p_exercise_id UUID,
    p_watch_duration INTEGER DEFAULT NULL,
    p_completed BOOLEAN DEFAULT FALSE
)
RETURNS UUID AS $$
DECLARE
    v_view_id UUID;
BEGIN
    -- Insert or update video view for today
    INSERT INTO video_views (patient_id, exercise_id, watch_duration, completed, viewed_at)
    VALUES (p_patient_id, p_exercise_id, p_watch_duration, p_completed, NOW())
    ON CONFLICT (patient_id, exercise_id, viewed_at)
    DO UPDATE SET
        watch_duration = GREATEST(video_views.watch_duration, EXCLUDED.watch_duration),
        completed = video_views.completed OR EXCLUDED.completed
    RETURNING id INTO v_view_id;

    RETURN v_view_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create view for exercise video statistics
CREATE OR REPLACE VIEW exercise_video_stats AS
SELECT
    e.id as exercise_id,
    e.name as exercise_name,
    e.video_url,
    e.video_duration,
    COUNT(DISTINCT vv.patient_id) as total_viewers,
    COUNT(vv.id) as total_views,
    COUNT(vv.id) FILTER (WHERE vv.completed = TRUE) as completed_views,
    CASE
        WHEN COUNT(vv.id) > 0 THEN
            COUNT(vv.id) FILTER (WHERE vv.completed = TRUE)::FLOAT / COUNT(vv.id)
        ELSE 0
    END as completion_rate,
    AVG(vv.watch_duration) as avg_watch_duration
FROM exercises e
LEFT JOIN video_views vv ON e.id = vv.exercise_id
WHERE e.video_url IS NOT NULL
GROUP BY e.id, e.name, e.video_url, e.video_duration;

-- Create function to get recommended exercises with videos for patient
CREATE OR REPLACE FUNCTION get_exercises_with_videos_for_patient(p_patient_id UUID)
RETURNS TABLE (
    exercise_id UUID,
    exercise_name TEXT,
    video_url TEXT,
    video_thumbnail_url TEXT,
    video_duration INTEGER,
    form_cues JSONB,
    has_watched BOOLEAN,
    last_watched TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id,
        e.name,
        e.video_url,
        e.video_thumbnail_url,
        e.video_duration,
        e.form_cues,
        EXISTS (
            SELECT 1 FROM video_views vv
            WHERE vv.patient_id = p_patient_id
            AND vv.exercise_id = e.id
        ) as has_watched,
        (
            SELECT MAX(viewed_at)
            FROM video_views vv
            WHERE vv.patient_id = p_patient_id
            AND vv.exercise_id = e.id
        ) as last_watched
    FROM exercises e
    WHERE e.video_url IS NOT NULL
    ORDER BY e.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;

-- Sample data (comment out for production)
-- UPDATE exercises
-- SET
--     video_url = 'https://example.com/videos/squat.mp4',
--     video_thumbnail_url = 'https://example.com/thumbnails/squat.jpg',
--     video_duration = 45,
--     form_cues = '[
--         {"cue": "Keep chest up", "timestamp": 5},
--         {"cue": "Drive through heels", "timestamp": 15},
--         {"cue": "Control the descent", "timestamp": 25}
--     ]'::jsonb
-- WHERE name ILIKE '%squat%'
-- AND video_url IS NULL;
