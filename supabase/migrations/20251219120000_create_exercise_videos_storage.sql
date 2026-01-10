-- Build 69: Create Exercise Videos Storage Bucket (ACP-170)
-- Creates Supabase Storage bucket for exercise videos with proper RLS policies
-- Sets up infrastructure for video library feature

-- ============================================================================
-- 1. CREATE STORAGE BUCKET
-- ============================================================================

-- Insert storage bucket (idempotent)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'exercise-videos',
    'exercise-videos',
    true, -- Public bucket for read access
    52428800, -- 50MB file size limit
    ARRAY[
        'video/mp4',
        'video/quicktime', -- .mov files
        'image/jpeg',
        'image/jpg'
    ]
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Add comment
-- Note: COMMENT ON TABLE storage.buckets requires table ownership
-- COMMENT ON TABLE storage.buckets IS 'Storage buckets for files. exercise-videos bucket stores exercise demo videos and thumbnails.';

-- ============================================================================
-- 2. CREATE RLS POLICIES FOR BUCKET
-- ============================================================================

-- Enable RLS on storage.objects if not already enabled
-- Note: storage.objects RLS is managed by Supabase
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "exercise_videos_public_read" ON storage.objects;
DROP POLICY IF EXISTS "exercise_videos_authenticated_upload" ON storage.objects;
DROP POLICY IF EXISTS "exercise_videos_authenticated_update" ON storage.objects;
DROP POLICY IF EXISTS "exercise_videos_authenticated_delete" ON storage.objects;

-- Policy 1: Public read access
-- Anyone can view/download exercise videos
CREATE POLICY "exercise_videos_public_read"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'exercise-videos');

-- COMMENT ON POLICY "exercise_videos_public_read" ON storage.objects IS
-- 'Allows public read access to all files in exercise-videos bucket. Videos are meant to be publicly accessible.';

-- Policy 2: Authenticated users can upload
-- Only authenticated users (therapists) can upload videos
CREATE POLICY "exercise_videos_authenticated_upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'exercise-videos'
    AND (LOWER(storage.filename(name)) LIKE '%.mp4'
         OR LOWER(storage.filename(name)) LIKE '%.mov'
         OR LOWER(storage.filename(name)) LIKE '%.jpg'
         OR LOWER(storage.filename(name)) LIKE '%.jpeg')
);

-- COMMENT ON POLICY "exercise_videos_authenticated_upload" ON storage.objects IS
-- 'Allows authenticated users to upload video (.mp4, .mov) and image (.jpg, .jpeg) files to exercise-videos bucket.';

-- Policy 3: Authenticated users can update
-- Only authenticated users can update/replace their uploaded files
CREATE POLICY "exercise_videos_authenticated_update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'exercise-videos')
WITH CHECK (bucket_id = 'exercise-videos');

-- COMMENT ON POLICY "exercise_videos_authenticated_update" ON storage.objects IS
-- 'Allows authenticated users to update/replace files in exercise-videos bucket.';

-- Policy 4: Authenticated users can delete
-- Only authenticated users can delete files
CREATE POLICY "exercise_videos_authenticated_delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'exercise-videos');

-- COMMENT ON POLICY "exercise_videos_authenticated_delete" ON storage.objects IS
-- 'Allows authenticated users to delete files from exercise-videos bucket.';

-- ============================================================================
-- 3. CREATE HELPER FUNCTIONS
-- ============================================================================

-- Function to get public URL for a storage object
CREATE OR REPLACE FUNCTION get_video_public_url(object_path TEXT)
RETURNS TEXT AS $$
DECLARE
    project_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co';
BEGIN
    RETURN project_url || '/storage/v1/object/public/exercise-videos/' || object_path;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION get_video_public_url(TEXT) IS
'Helper function to generate public URL for exercise video. Usage: SELECT get_video_public_url(''bench-press.mp4'')';

-- Function to extract filename from storage path
CREATE OR REPLACE FUNCTION extract_video_filename(video_url TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN regexp_replace(video_url, '^.*/([^/]+)$', '\1');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION extract_video_filename(TEXT) IS
'Extracts filename from full video URL. Usage: SELECT extract_video_filename(''https://.../.../video.mp4'')';

-- Function to check if video exists in storage
CREATE OR REPLACE FUNCTION video_exists_in_storage(video_filename TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM storage.objects
        WHERE bucket_id = 'exercise-videos'
        AND name = video_filename
    );
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION video_exists_in_storage(TEXT) IS
'Checks if a video file exists in exercise-videos bucket. Usage: SELECT video_exists_in_storage(''bench-press.mp4'')';

-- ============================================================================
-- 4. CREATE VIEW FOR VIDEO STORAGE STATUS
-- ============================================================================

-- Create view showing all videos in storage
CREATE OR REPLACE VIEW video_storage_inventory AS
SELECT
    o.id,
    o.name AS filename,
    o.bucket_id,
    CASE
        WHEN o.name LIKE 'thumbnails/%' THEN 'thumbnail'
        WHEN o.name LIKE '%.mp4' OR o.name LIKE '%.mov' THEN 'video'
        WHEN o.name LIKE '%.jpg' OR o.name LIKE '%.jpeg' THEN 'image'
        ELSE 'other'
    END AS file_type,
    o.metadata->>'size' AS file_size_bytes,
    ROUND((o.metadata->>'size')::numeric / 1048576, 2) AS file_size_mb,
    o.metadata->>'mimetype' AS mime_type,
    o.created_at,
    o.updated_at,
    get_video_public_url(o.name) AS public_url,
    -- Link to exercise_templates
    (SELECT COUNT(*)
     FROM exercise_templates et
     WHERE et.video_url = get_video_public_url(o.name)
        OR et.video_thumbnail_url = get_video_public_url(o.name)
    ) AS linked_exercise_count
FROM storage.objects o
WHERE o.bucket_id = 'exercise-videos'
ORDER BY o.created_at DESC;

COMMENT ON VIEW video_storage_inventory IS
'Shows all files in exercise-videos storage bucket with metadata and links to exercises.';

-- ============================================================================
-- 5. CREATE TRIGGER FOR STORAGE WEBHOOK (THUMBNAIL GENERATION)
-- ============================================================================

-- Enable the http extension for making HTTP requests
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- Create function to trigger thumbnail generation
CREATE OR REPLACE FUNCTION trigger_thumbnail_generation()
RETURNS TRIGGER AS $$
DECLARE
    function_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/generate-video-thumbnail';
    service_key TEXT;
    response_status INTEGER;
BEGIN
    -- Only process video files (not thumbnails)
    IF NEW.bucket_id = 'exercise-videos'
       AND (NEW.name LIKE '%.mp4' OR NEW.name LIKE '%.mov' OR NEW.name LIKE '%.MP4' OR NEW.name LIKE '%.MOV')
       AND NEW.name NOT LIKE 'thumbnails/%' THEN

        -- Get service role key from secrets (must be configured)
        -- Note: In production, store this in Vault or environment variables
        service_key := current_setting('app.settings.supabase_service_role_key', true);

        -- Call Edge Function asynchronously
        PERFORM extensions.http_post(
            url := function_url,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || COALESCE(service_key, '')
            ),
            body := jsonb_build_object(
                'type', TG_OP,
                'table', TG_TABLE_NAME,
                'record', row_to_json(NEW),
                'old_record', row_to_json(OLD)
            )
        );

        RAISE NOTICE 'Thumbnail generation triggered for: %', NEW.name;
    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log error but don't fail the insert
    RAISE WARNING 'Failed to trigger thumbnail generation: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION trigger_thumbnail_generation() IS
'Trigger function that calls generate-video-thumbnail Edge Function when video uploaded. Runs asynchronously.';

-- Create trigger on storage.objects
DROP TRIGGER IF EXISTS on_video_upload ON storage.objects;

CREATE TRIGGER on_video_upload
AFTER INSERT ON storage.objects
FOR EACH ROW
WHEN (NEW.bucket_id = 'exercise-videos' AND NEW.name NOT LIKE 'thumbnails/%')
EXECUTE FUNCTION trigger_thumbnail_generation();

-- COMMENT ON TRIGGER on_video_upload ON storage.objects IS
-- 'Automatically triggers thumbnail generation when video uploaded to exercise-videos bucket.';

-- ============================================================================
-- 6. CREATE MAINTENANCE FUNCTIONS
-- ============================================================================

-- Function to clean up orphaned videos (not linked to any exercise)
CREATE OR REPLACE FUNCTION cleanup_orphaned_videos()
RETURNS TABLE (
    deleted_filename TEXT,
    file_size_mb NUMERIC
) AS $$
DECLARE
    orphan_record RECORD;
BEGIN
    FOR orphan_record IN
        SELECT
            o.name,
            ROUND((o.metadata->>'size')::numeric / 1048576, 2) AS size_mb
        FROM storage.objects o
        WHERE o.bucket_id = 'exercise-videos'
        AND o.name NOT LIKE 'thumbnails/%'
        AND NOT EXISTS (
            SELECT 1
            FROM exercise_templates et
            WHERE et.video_url = get_video_public_url(o.name)
        )
        AND o.created_at < NOW() - INTERVAL '30 days' -- Only cleanup old orphans
    LOOP
        -- Delete from storage
        DELETE FROM storage.objects
        WHERE bucket_id = 'exercise-videos' AND name = orphan_record.name;

        deleted_filename := orphan_record.name;
        file_size_mb := orphan_record.size_mb;
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_orphaned_videos() IS
'Deletes videos from storage that are not linked to any exercise and are older than 30 days. Use carefully!';

-- Function to get storage statistics
CREATE OR REPLACE FUNCTION get_storage_statistics()
RETURNS TABLE (
    total_files INTEGER,
    total_videos INTEGER,
    total_thumbnails INTEGER,
    total_size_mb NUMERIC,
    average_video_size_mb NUMERIC,
    oldest_file_date TIMESTAMP WITH TIME ZONE,
    newest_file_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER,
        COUNT(*) FILTER (WHERE name LIKE '%.mp4' OR name LIKE '%.mov')::INTEGER,
        COUNT(*) FILTER (WHERE name LIKE 'thumbnails/%')::INTEGER,
        ROUND(SUM((metadata->>'size')::numeric) / 1048576, 2),
        ROUND(AVG((metadata->>'size')::numeric) FILTER (
            WHERE name LIKE '%.mp4' OR name LIKE '%.mov'
        ) / 1048576, 2),
        MIN(created_at),
        MAX(created_at)
    FROM storage.objects
    WHERE bucket_id = 'exercise-videos';
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_storage_statistics() IS
'Returns statistics about exercise-videos storage bucket usage.';

-- ============================================================================
-- 7. VERIFICATION AND TESTING
-- ============================================================================

DO $$
DECLARE
    bucket_exists BOOLEAN;
    policy_count INTEGER;
    function_count INTEGER;
    trigger_exists BOOLEAN;
BEGIN
    -- Check bucket exists
    SELECT EXISTS(
        SELECT 1 FROM storage.buckets WHERE id = 'exercise-videos'
    ) INTO bucket_exists;

    -- Count policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'objects' AND policyname LIKE 'exercise_videos%';

    -- Count helper functions
    SELECT COUNT(*) INTO function_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname IN (
        'get_video_public_url',
        'extract_video_filename',
        'video_exists_in_storage',
        'trigger_thumbnail_generation',
        'cleanup_orphaned_videos',
        'get_storage_statistics'
    );

    -- Check trigger exists
    SELECT EXISTS(
        SELECT 1 FROM pg_trigger WHERE tgname = 'on_video_upload'
    ) INTO trigger_exists;

    RAISE NOTICE '=== Build 69: Storage Bucket Migration Complete ===';
    RAISE NOTICE 'Bucket created: %', CASE WHEN bucket_exists THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE 'RLS policies created: % of 4', policy_count;
    RAISE NOTICE 'Helper functions created: % of 6', function_count;
    RAISE NOTICE 'Thumbnail trigger created: %', CASE WHEN trigger_exists THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '==================================================';

    -- Verify everything is good
    IF bucket_exists AND policy_count = 4 AND function_count = 6 AND trigger_exists THEN
        RAISE NOTICE '✓ All storage infrastructure created successfully';
    ELSE
        RAISE WARNING '✗ Some components missing - review migration logs';
    END IF;
END $$;

-- ============================================================================
-- 8. USAGE EXAMPLES
-- ============================================================================

/*
-- View storage statistics:
SELECT * FROM get_storage_statistics();

-- View all files in storage:
SELECT * FROM video_storage_inventory;

-- Check if a specific video exists:
SELECT video_exists_in_storage('bench-press.mp4');

-- Get public URL for a video:
SELECT get_video_public_url('bench-press.mp4');

-- Extract filename from URL:
SELECT extract_video_filename('https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press.mp4');

-- Find orphaned videos (not linked to exercises):
SELECT
    filename,
    file_size_mb,
    created_at
FROM video_storage_inventory
WHERE linked_exercise_count = 0;

-- Cleanup old orphaned videos (BE CAREFUL!):
SELECT * FROM cleanup_orphaned_videos();
*/

-- ============================================================================
-- 9. SECURITY NOTES
-- ============================================================================

/*
SECURITY CONSIDERATIONS:

1. PUBLIC READ ACCESS:
   - All files in exercise-videos bucket are publicly readable
   - This is intentional - exercise videos should be accessible to patients
   - Do NOT store sensitive data in this bucket

2. AUTHENTICATED WRITE ACCESS:
   - Only authenticated users can upload/modify/delete
   - Consider adding role-based checks for therapist-only access
   - Example: Add WHERE clause: (auth.jwt()->>'role' = 'therapist')

3. FILE SIZE LIMITS:
   - Maximum file size: 50MB
   - Enforced at bucket level
   - Adjust if needed for higher quality videos

4. MIME TYPE RESTRICTIONS:
   - Only video (mp4, mov) and image (jpg, jpeg) files allowed
   - Prevents upload of potentially dangerous file types

5. THUMBNAIL TRIGGER:
   - Runs asynchronously - does not block uploads
   - Failures in thumbnail generation will not fail video upload
   - Monitor Edge Function logs for thumbnail generation issues

6. STORAGE QUOTA:
   - Monitor storage usage with get_storage_statistics()
   - Supabase free tier: 1GB storage
   - Pro tier: 100GB storage
   - Consider CDN for video delivery at scale
*/
