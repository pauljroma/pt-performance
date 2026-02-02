-- Migration: HD Video Exercise Demos (ACP-813)
-- Date: 2026-02-02
-- Description: Create exercise_videos table with multi-angle support for HD video demos
-- Features: Multiple angles (front, side, back, detail), slow-motion support, offline caching metadata

BEGIN;

-- Create exercise_videos table for multi-angle HD video support
CREATE TABLE IF NOT EXISTS exercise_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    angle TEXT NOT NULL CHECK (angle IN ('front', 'side', 'back', 'detail')),
    duration_seconds INTEGER,
    file_size_bytes BIGINT,
    resolution TEXT DEFAULT '1080p' CHECK (resolution IN ('720p', '1080p', '4k')),
    is_primary BOOLEAN DEFAULT false,
    supports_slow_motion BOOLEAN DEFAULT true,
    -- Metadata for offline caching
    content_hash TEXT, -- For cache invalidation
    last_updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for efficient lookups by exercise
CREATE INDEX IF NOT EXISTS idx_exercise_videos_exercise ON exercise_videos(exercise_id);

-- Create index for primary videos
CREATE INDEX IF NOT EXISTS idx_exercise_videos_primary ON exercise_videos(exercise_id) WHERE is_primary = true;

-- Create index for angle lookups
CREATE INDEX IF NOT EXISTS idx_exercise_videos_angle ON exercise_videos(exercise_id, angle);

-- Create unique constraint: only one primary video per exercise
CREATE UNIQUE INDEX IF NOT EXISTS idx_exercise_videos_unique_primary
    ON exercise_videos(exercise_id)
    WHERE is_primary = true;

-- Enable RLS
ALTER TABLE exercise_videos ENABLE ROW LEVEL SECURITY;

-- RLS Policies for exercise_videos

-- Everyone can view exercise videos (content is public)
CREATE POLICY "Anyone can view exercise videos"
    ON exercise_videos FOR SELECT
    USING (true);

-- Only authenticated therapists can manage exercise videos
CREATE POLICY "Therapists can manage exercise videos"
    ON exercise_videos FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND role IN ('therapist', 'admin')
        )
    );

-- View for exercise with all videos aggregated
CREATE OR REPLACE VIEW vw_exercise_with_videos AS
SELECT
    e.*,
    COALESCE(
        json_agg(
            json_build_object(
                'id', ev.id,
                'url', ev.video_url,
                'thumbnail', ev.thumbnail_url,
                'angle', ev.angle,
                'duration', ev.duration_seconds,
                'fileSize', ev.file_size_bytes,
                'resolution', ev.resolution,
                'isPrimary', ev.is_primary,
                'supportsSlowMotion', ev.supports_slow_motion,
                'contentHash', ev.content_hash
            ) ORDER BY
                ev.is_primary DESC,
                CASE ev.angle
                    WHEN 'front' THEN 1
                    WHEN 'side' THEN 2
                    WHEN 'back' THEN 3
                    WHEN 'detail' THEN 4
                END
        ) FILTER (WHERE ev.id IS NOT NULL),
        '[]'::json
    ) as videos,
    COUNT(ev.id) as video_count,
    BOOL_OR(ev.is_primary) as has_primary_video
FROM exercises e
LEFT JOIN exercise_videos ev ON e.id = ev.exercise_id
GROUP BY e.id;

-- Function to get videos for a specific exercise
CREATE OR REPLACE FUNCTION get_exercise_videos(p_exercise_id UUID)
RETURNS TABLE (
    id UUID,
    video_url TEXT,
    thumbnail_url TEXT,
    angle TEXT,
    duration_seconds INTEGER,
    file_size_bytes BIGINT,
    resolution TEXT,
    is_primary BOOLEAN,
    supports_slow_motion BOOLEAN,
    content_hash TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ev.id,
        ev.video_url,
        ev.thumbnail_url,
        ev.angle,
        ev.duration_seconds,
        ev.file_size_bytes,
        ev.resolution,
        ev.is_primary,
        ev.supports_slow_motion,
        ev.content_hash
    FROM exercise_videos ev
    WHERE ev.exercise_id = p_exercise_id
    ORDER BY
        ev.is_primary DESC,
        CASE ev.angle
            WHEN 'front' THEN 1
            WHEN 'side' THEN 2
            WHEN 'back' THEN 3
            WHEN 'detail' THEN 4
        END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get primary video for an exercise
CREATE OR REPLACE FUNCTION get_primary_exercise_video(p_exercise_id UUID)
RETURNS TABLE (
    id UUID,
    video_url TEXT,
    thumbnail_url TEXT,
    angle TEXT,
    duration_seconds INTEGER,
    file_size_bytes BIGINT,
    resolution TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ev.id,
        ev.video_url,
        ev.thumbnail_url,
        ev.angle,
        ev.duration_seconds,
        ev.file_size_bytes,
        ev.resolution
    FROM exercise_videos ev
    WHERE ev.exercise_id = p_exercise_id
    AND ev.is_primary = true
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to set primary video for an exercise (unsets others)
CREATE OR REPLACE FUNCTION set_primary_exercise_video(
    p_exercise_id UUID,
    p_video_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    -- Unset all other primary videos for this exercise
    UPDATE exercise_videos
    SET is_primary = false
    WHERE exercise_id = p_exercise_id
    AND id != p_video_id;

    -- Set the specified video as primary
    UPDATE exercise_videos
    SET is_primary = true
    WHERE id = p_video_id
    AND exercise_id = p_exercise_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create table for tracking video cache status on client devices
CREATE TABLE IF NOT EXISTS video_cache_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES exercise_videos(id) ON DELETE CASCADE,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    cache_size_bytes BIGINT,
    content_hash TEXT,
    device_identifier TEXT,

    UNIQUE(patient_id, video_id, device_identifier)
);

-- Create index for cache lookups
CREATE INDEX IF NOT EXISTS idx_video_cache_patient ON video_cache_status(patient_id);
CREATE INDEX IF NOT EXISTS idx_video_cache_video ON video_cache_status(video_id);

-- Enable RLS on cache status
ALTER TABLE video_cache_status ENABLE ROW LEVEL SECURITY;

-- Patients can manage their own cache status
CREATE POLICY "Patients manage own video cache status"
    ON video_cache_status FOR ALL
    USING (patient_id = auth.uid());

-- Function to log video cache status from client
CREATE OR REPLACE FUNCTION log_video_cached(
    p_patient_id UUID,
    p_video_id UUID,
    p_cache_size_bytes BIGINT,
    p_content_hash TEXT,
    p_device_identifier TEXT
) RETURNS UUID AS $$
DECLARE
    v_cache_id UUID;
BEGIN
    INSERT INTO video_cache_status (
        patient_id,
        video_id,
        cache_size_bytes,
        content_hash,
        device_identifier
    )
    VALUES (
        p_patient_id,
        p_video_id,
        p_cache_size_bytes,
        p_content_hash,
        p_device_identifier
    )
    ON CONFLICT (patient_id, video_id, device_identifier)
    DO UPDATE SET
        cached_at = NOW(),
        cache_size_bytes = EXCLUDED.cache_size_bytes,
        content_hash = EXCLUDED.content_hash
    RETURNING id INTO v_cache_id;

    RETURN v_cache_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get videos needing cache refresh
CREATE OR REPLACE FUNCTION get_stale_cached_videos(
    p_patient_id UUID,
    p_device_identifier TEXT
) RETURNS TABLE (
    video_id UUID,
    video_url TEXT,
    current_hash TEXT,
    cached_hash TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ev.id as video_id,
        ev.video_url,
        ev.content_hash as current_hash,
        vcs.content_hash as cached_hash
    FROM exercise_videos ev
    JOIN video_cache_status vcs ON ev.id = vcs.video_id
    WHERE vcs.patient_id = p_patient_id
    AND vcs.device_identifier = p_device_identifier
    AND ev.content_hash != vcs.content_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update video_views table to support angle tracking
ALTER TABLE video_views
ADD COLUMN IF NOT EXISTS video_id UUID REFERENCES exercise_videos(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS playback_speed DECIMAL(3,2) DEFAULT 1.0,
ADD COLUMN IF NOT EXISTS angle_watched TEXT;

-- Create index for video_views by video_id
CREATE INDEX IF NOT EXISTS idx_video_views_video_id ON video_views(video_id);

-- Function to log detailed video view with angle and speed
CREATE OR REPLACE FUNCTION log_detailed_video_view(
    p_patient_id UUID,
    p_exercise_id UUID,
    p_video_id UUID,
    p_watch_duration INTEGER DEFAULT NULL,
    p_completed BOOLEAN DEFAULT FALSE,
    p_playback_speed DECIMAL DEFAULT 1.0,
    p_angle_watched TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_view_id UUID;
BEGIN
    INSERT INTO video_views (
        patient_id,
        exercise_id,
        video_id,
        watch_duration,
        completed,
        playback_speed,
        angle_watched,
        viewed_at
    )
    VALUES (
        p_patient_id,
        p_exercise_id,
        p_video_id,
        p_watch_duration,
        p_completed,
        p_playback_speed,
        p_angle_watched,
        NOW()
    )
    RETURNING id INTO v_view_id;

    RETURN v_view_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
