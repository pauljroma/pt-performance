-- Migration: Create Missing RPC Functions for iOS App
-- Created: 2026-02-08
-- Description: Adds RPC functions called from iOS that don't exist in the database
--
-- Functions created:
-- 1. track_template_usage - Increment usage count on clinical templates
-- 2. get_video_watch_statistics - Get aggregated video watch stats
-- 3. get_total_watch_time - Get total seconds of video watched
-- 4. log_detailed_video_view - Insert detailed video view record
-- 5. log_video_cached - Track cached videos for offline use

-- ============================================================================
-- 1. TRACK TEMPLATE USAGE
-- Called from ClinicalTemplateService.swift
-- Increments usage count and updates last_used_at on clinical_templates
-- ============================================================================

-- First, add the missing columns to clinical_templates if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'clinical_templates'
        AND column_name = 'use_count'
    ) THEN
        ALTER TABLE public.clinical_templates ADD COLUMN use_count INTEGER DEFAULT 0;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'clinical_templates'
        AND column_name = 'last_used_at'
    ) THEN
        ALTER TABLE public.clinical_templates ADD COLUMN last_used_at TIMESTAMPTZ;
    END IF;
END $$;

-- Create the track_template_usage function
CREATE OR REPLACE FUNCTION public.track_template_usage(
    p_template_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Validate input
    IF p_template_id IS NULL THEN
        RAISE EXCEPTION 'Template ID is required';
    END IF;

    -- Verify template exists
    IF NOT EXISTS (SELECT 1 FROM public.clinical_templates WHERE id = p_template_id) THEN
        RAISE EXCEPTION 'Template not found: %', p_template_id;
    END IF;

    -- Increment usage count and update last_used_at
    UPDATE public.clinical_templates
    SET
        use_count = COALESCE(use_count, 0) + 1,
        last_used_at = NOW(),
        updated_at = NOW()
    WHERE id = p_template_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.track_template_usage(UUID) TO authenticated;

COMMENT ON FUNCTION public.track_template_usage IS
'Increments usage count and updates last_used_at for a clinical template. Called from ClinicalTemplateService.swift.';


-- ============================================================================
-- 2. GET VIDEO WATCH STATISTICS
-- Called from VideoAnalyticsService.swift
-- Returns aggregated video watch stats for a patient within a date range
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_video_watch_statistics(
    p_patient_id TEXT,
    p_days TEXT DEFAULT '30'
)
RETURNS TABLE (
    total_watched INTEGER,
    total_minutes_watched INTEGER,
    completion_rate NUMERIC,
    most_watched_exercise_id UUID,
    average_watch_duration INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_patient_uuid UUID;
    v_days_int INTEGER;
    v_start_date TIMESTAMPTZ;
BEGIN
    -- Validate and convert inputs
    IF p_patient_id IS NULL OR p_patient_id = '' THEN
        RAISE EXCEPTION 'Patient ID is required';
    END IF;

    BEGIN
        v_patient_uuid := p_patient_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid patient ID format: %', p_patient_id;
    END;

    -- Parse days parameter (default to 30)
    v_days_int := COALESCE(NULLIF(p_days, '')::INTEGER, 30);
    v_start_date := NOW() - (v_days_int || ' days')::INTERVAL;

    RETURN QUERY
    WITH watch_stats AS (
        SELECT
            COUNT(*)::INTEGER as total_count,
            COALESCE(SUM(watch_duration_seconds), 0)::INTEGER as total_seconds,
            COUNT(*) FILTER (WHERE completed = true) as completed_count,
            COALESCE(AVG(watch_duration_seconds), 0)::INTEGER as avg_duration
        FROM public.video_watch_history
        WHERE patient_id = v_patient_uuid
        AND watched_at >= v_start_date
    ),
    most_watched AS (
        SELECT exercise_template_id
        FROM public.video_watch_history
        WHERE patient_id = v_patient_uuid
        AND watched_at >= v_start_date
        GROUP BY exercise_template_id
        ORDER BY COUNT(*) DESC
        LIMIT 1
    )
    SELECT
        ws.total_count,
        (ws.total_seconds / 60)::INTEGER,  -- Convert to minutes
        CASE
            WHEN ws.total_count > 0 THEN ROUND((ws.completed_count::NUMERIC / ws.total_count::NUMERIC) * 100, 2)
            ELSE 0::NUMERIC
        END,
        mw.exercise_template_id,
        ws.avg_duration
    FROM watch_stats ws
    LEFT JOIN most_watched mw ON true;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_video_watch_statistics(TEXT, TEXT) TO authenticated;

COMMENT ON FUNCTION public.get_video_watch_statistics IS
'Returns aggregated video watch statistics for a patient within a specified number of days. Called from VideoAnalyticsService.swift.';


-- ============================================================================
-- 3. GET TOTAL WATCH TIME
-- Called from VideoAnalyticsService.swift
-- Returns total seconds of video watched by a patient
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_total_watch_time(
    p_patient_id TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_patient_uuid UUID;
    v_total_seconds INTEGER;
BEGIN
    -- Validate input
    IF p_patient_id IS NULL OR p_patient_id = '' THEN
        RAISE EXCEPTION 'Patient ID is required';
    END IF;

    BEGIN
        v_patient_uuid := p_patient_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid patient ID format: %', p_patient_id;
    END;

    -- Calculate total watch time
    SELECT COALESCE(SUM(watch_duration_seconds), 0)::INTEGER
    INTO v_total_seconds
    FROM public.video_watch_history
    WHERE patient_id = v_patient_uuid;

    RETURN v_total_seconds;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_total_watch_time(TEXT) TO authenticated;

COMMENT ON FUNCTION public.get_total_watch_time IS
'Returns total seconds of video watched by a patient. Called from VideoAnalyticsService.swift.';


-- ============================================================================
-- 4. LOG DETAILED VIDEO VIEW
-- Called from ExerciseVideoService.swift
-- Inserts a detailed video view record into video_watch_history
-- ============================================================================

-- First, add missing columns to video_watch_history if needed
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'video_watch_history'
        AND column_name = 'video_id'
    ) THEN
        ALTER TABLE public.video_watch_history ADD COLUMN video_id UUID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'video_watch_history'
        AND column_name = 'playback_speed'
    ) THEN
        ALTER TABLE public.video_watch_history ADD COLUMN playback_speed NUMERIC(3,2) DEFAULT 1.0;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'video_watch_history'
        AND column_name = 'angle_watched'
    ) THEN
        ALTER TABLE public.video_watch_history ADD COLUMN angle_watched TEXT;
    END IF;
END $$;

CREATE OR REPLACE FUNCTION public.log_detailed_video_view(
    p_patient_id TEXT,
    p_exercise_id TEXT,
    p_video_id TEXT,
    p_watch_duration TEXT,
    p_completed TEXT,
    p_playback_speed TEXT,
    p_angle_watched TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_patient_uuid UUID;
    v_exercise_uuid UUID;
    v_video_uuid UUID;
    v_watch_duration INTEGER;
    v_completed BOOLEAN;
    v_playback_speed NUMERIC(3,2);
    v_new_id UUID;
BEGIN
    -- Validate and convert patient_id
    IF p_patient_id IS NULL OR p_patient_id = '' THEN
        RAISE EXCEPTION 'Patient ID is required';
    END IF;

    BEGIN
        v_patient_uuid := p_patient_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid patient ID format: %', p_patient_id;
    END;

    -- Convert exercise_id
    IF p_exercise_id IS NOT NULL AND p_exercise_id != '' THEN
        BEGIN
            v_exercise_uuid := p_exercise_id::UUID;
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Invalid exercise ID format: %', p_exercise_id;
        END;
    END IF;

    -- Convert video_id
    IF p_video_id IS NOT NULL AND p_video_id != '' THEN
        BEGIN
            v_video_uuid := p_video_id::UUID;
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Invalid video ID format: %', p_video_id;
        END;
    END IF;

    -- Convert watch_duration
    v_watch_duration := COALESCE(NULLIF(p_watch_duration, '')::INTEGER, 0);

    -- Convert completed (handle string boolean)
    v_completed := LOWER(COALESCE(p_completed, 'false')) IN ('true', '1', 'yes');

    -- Convert playback_speed
    v_playback_speed := COALESCE(NULLIF(p_playback_speed, '')::NUMERIC(3,2), 1.0);

    -- Insert the record
    INSERT INTO public.video_watch_history (
        id,
        patient_id,
        exercise_template_id,
        video_id,
        watch_duration_seconds,
        completed,
        playback_speed,
        angle_watched,
        watched_at,
        created_at
    ) VALUES (
        gen_random_uuid(),
        v_patient_uuid,
        v_exercise_uuid,
        v_video_uuid,
        v_watch_duration,
        v_completed,
        v_playback_speed,
        NULLIF(p_angle_watched, ''),
        NOW(),
        NOW()
    )
    RETURNING id INTO v_new_id;

    RETURN v_new_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.log_detailed_video_view(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

COMMENT ON FUNCTION public.log_detailed_video_view IS
'Inserts a detailed video view record into video_watch_history. Called from ExerciseVideoService.swift.';


-- ============================================================================
-- 5. LOG VIDEO CACHED
-- Called from ExerciseVideoService.swift
-- Tracks cached videos for offline use
-- ============================================================================

-- Create video_cache_log table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.video_cache_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    video_id UUID NOT NULL,
    cache_size_bytes BIGINT NOT NULL DEFAULT 0,
    content_hash TEXT,
    device_identifier TEXT NOT NULL,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique constraint: one cache record per video per device per patient
    UNIQUE(patient_id, video_id, device_identifier)
);

-- Create indexes for video_cache_log
CREATE INDEX IF NOT EXISTS idx_video_cache_log_patient_id
    ON public.video_cache_log(patient_id);
CREATE INDEX IF NOT EXISTS idx_video_cache_log_video_id
    ON public.video_cache_log(video_id);
CREATE INDEX IF NOT EXISTS idx_video_cache_log_device
    ON public.video_cache_log(device_identifier);

-- Enable RLS
ALTER TABLE public.video_cache_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies for video_cache_log
DROP POLICY IF EXISTS "Patients can manage own cache logs" ON public.video_cache_log;
CREATE POLICY "Patients can manage own cache logs"
    ON public.video_cache_log
    FOR ALL
    TO authenticated
    USING (patient_id::text = auth.uid()::text)
    WITH CHECK (patient_id::text = auth.uid()::text);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.video_cache_log TO authenticated;

-- Create the log_video_cached function
CREATE OR REPLACE FUNCTION public.log_video_cached(
    p_patient_id TEXT,
    p_video_id TEXT,
    p_cache_size_bytes TEXT,
    p_content_hash TEXT,
    p_device_identifier TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_patient_uuid UUID;
    v_video_uuid UUID;
    v_cache_size BIGINT;
    v_result_id UUID;
BEGIN
    -- Validate and convert patient_id
    IF p_patient_id IS NULL OR p_patient_id = '' THEN
        RAISE EXCEPTION 'Patient ID is required';
    END IF;

    BEGIN
        v_patient_uuid := p_patient_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid patient ID format: %', p_patient_id;
    END;

    -- Validate and convert video_id
    IF p_video_id IS NULL OR p_video_id = '' THEN
        RAISE EXCEPTION 'Video ID is required';
    END IF;

    BEGIN
        v_video_uuid := p_video_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid video ID format: %', p_video_id;
    END;

    -- Validate device_identifier
    IF p_device_identifier IS NULL OR p_device_identifier = '' THEN
        RAISE EXCEPTION 'Device identifier is required';
    END IF;

    -- Convert cache_size_bytes
    v_cache_size := COALESCE(NULLIF(p_cache_size_bytes, '')::BIGINT, 0);

    -- Upsert the cache log record
    INSERT INTO public.video_cache_log (
        patient_id,
        video_id,
        cache_size_bytes,
        content_hash,
        device_identifier,
        cached_at,
        created_at
    ) VALUES (
        v_patient_uuid,
        v_video_uuid,
        v_cache_size,
        NULLIF(p_content_hash, ''),
        p_device_identifier,
        NOW(),
        NOW()
    )
    ON CONFLICT (patient_id, video_id, device_identifier)
    DO UPDATE SET
        cache_size_bytes = EXCLUDED.cache_size_bytes,
        content_hash = EXCLUDED.content_hash,
        cached_at = NOW()
    RETURNING id INTO v_result_id;

    RETURN v_result_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.log_video_cached(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

COMMENT ON FUNCTION public.log_video_cached IS
'Tracks cached videos for offline use. Upserts into video_cache_log table. Called from ExerciseVideoService.swift.';

-- Add comment on table
COMMENT ON TABLE public.video_cache_log IS 'Tracks videos cached on user devices for offline viewing';


-- ============================================================================
-- VERIFICATION BLOCK
-- ============================================================================

DO $$
DECLARE
    v_function_count INTEGER := 0;
    v_missing_functions TEXT := '';
BEGIN
    -- Check track_template_usage exists
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'track_template_usage'
    ) THEN
        v_function_count := v_function_count + 1;
    ELSE
        v_missing_functions := v_missing_functions || 'track_template_usage, ';
    END IF;

    -- Check get_video_watch_statistics exists
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'get_video_watch_statistics'
    ) THEN
        v_function_count := v_function_count + 1;
    ELSE
        v_missing_functions := v_missing_functions || 'get_video_watch_statistics, ';
    END IF;

    -- Check get_total_watch_time exists
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'get_total_watch_time'
    ) THEN
        v_function_count := v_function_count + 1;
    ELSE
        v_missing_functions := v_missing_functions || 'get_total_watch_time, ';
    END IF;

    -- Check log_detailed_video_view exists
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'log_detailed_video_view'
    ) THEN
        v_function_count := v_function_count + 1;
    ELSE
        v_missing_functions := v_missing_functions || 'log_detailed_video_view, ';
    END IF;

    -- Check log_video_cached exists
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'log_video_cached'
    ) THEN
        v_function_count := v_function_count + 1;
    ELSE
        v_missing_functions := v_missing_functions || 'log_video_cached, ';
    END IF;

    -- Check video_cache_log table exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'video_cache_log'
    ) THEN
        RAISE EXCEPTION 'video_cache_log table was not created';
    END IF;

    -- Check use_count column was added to clinical_templates
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'clinical_templates'
        AND column_name = 'use_count'
    ) THEN
        RAISE EXCEPTION 'use_count column was not added to clinical_templates';
    END IF;

    -- Raise exception if any functions are missing
    IF v_function_count < 5 THEN
        RAISE EXCEPTION 'Missing RPC functions: %', RTRIM(v_missing_functions, ', ');
    END IF;

    RAISE NOTICE '==============================================';
    RAISE NOTICE 'VERIFICATION PASSED: All 5 RPC functions created';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '1. track_template_usage(p_template_id UUID) - OK';
    RAISE NOTICE '2. get_video_watch_statistics(p_patient_id TEXT, p_days TEXT) - OK';
    RAISE NOTICE '3. get_total_watch_time(p_patient_id TEXT) - OK';
    RAISE NOTICE '4. log_detailed_video_view(...) - OK';
    RAISE NOTICE '5. log_video_cached(...) - OK';
    RAISE NOTICE '';
    RAISE NOTICE 'Additional changes:';
    RAISE NOTICE '- Added use_count, last_used_at columns to clinical_templates';
    RAISE NOTICE '- Added video_id, playback_speed, angle_watched columns to video_watch_history';
    RAISE NOTICE '- Created video_cache_log table with RLS policies';
    RAISE NOTICE '==============================================';
END $$;
