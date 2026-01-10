-- Build 63: Exercise Videos Storage Bucket Policies (YUK-39)
-- Configure Row Level Security policies for exercise-videos bucket

-- ============================================================================
-- 1. CREATE STORAGE BUCKET
-- ============================================================================

-- Create the exercise-videos bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'exercise-videos',
    'exercise-videos',
    true,  -- Public bucket for read access
    15728640,  -- 15 MB limit (15 * 1024 * 1024 bytes)
    ARRAY['video/mp4', 'video/quicktime', 'image/jpeg', 'image/jpg']::text[]
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 15728640,
    allowed_mime_types = ARRAY['video/mp4', 'video/quicktime', 'image/jpeg', 'image/jpg']::text[];

-- ============================================================================
-- 2. DROP EXISTING POLICIES (for clean redeployment)
-- ============================================================================

DROP POLICY IF EXISTS "Public read access for exercise videos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload exercise videos" ON storage.objects;
DROP POLICY IF EXISTS "Admin and therapist can upload videos" ON storage.objects;
DROP POLICY IF EXISTS "Admin and therapist can delete videos" ON storage.objects;
DROP POLICY IF EXISTS "System can manage thumbnails" ON storage.objects;

-- ============================================================================
-- 3. CREATE RLS POLICIES
-- ============================================================================

-- Policy 1: Public READ access
-- Anyone can view and download exercise videos (required for app display)
CREATE POLICY "Public read access for exercise videos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'exercise-videos');

-- Policy 2: Authenticated users can UPLOAD videos
-- Only authenticated users can upload (will be further restricted by role check)
CREATE POLICY "Authenticated users can upload exercise videos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'exercise-videos'
    AND (
        -- Check if user is admin or therapist
        EXISTS (
            SELECT 1
            FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (
                auth.users.raw_user_meta_data->>'role' = 'admin'
                OR auth.users.raw_user_meta_data->>'role' = 'therapist'
            )
        )
        OR
        -- Alternative: Check from therapists table
        EXISTS (
            SELECT 1
            FROM therapists
            WHERE therapists.auth_id = auth.uid()
        )
    )
);

-- Policy 3: Admin and therapist can UPDATE videos
-- Allow updating metadata or replacing videos
CREATE POLICY "Admin and therapist can update videos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'exercise-videos'
    AND (
        EXISTS (
            SELECT 1
            FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (
                auth.users.raw_user_meta_data->>'role' = 'admin'
                OR auth.users.raw_user_meta_data->>'role' = 'therapist'
            )
        )
        OR
        EXISTS (
            SELECT 1
            FROM therapists
            WHERE therapists.auth_id = auth.uid()
        )
    )
);

-- Policy 4: Admin and therapist can DELETE videos
-- Only admin or therapist users can delete videos
CREATE POLICY "Admin and therapist can delete videos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'exercise-videos'
    AND (
        EXISTS (
            SELECT 1
            FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (
                auth.users.raw_user_meta_data->>'role' = 'admin'
                OR auth.users.raw_user_meta_data->>'role' = 'therapist'
            )
        )
        OR
        EXISTS (
            SELECT 1
            FROM therapists
            WHERE therapists.auth_id = auth.uid()
        )
    )
);

-- Policy 5: Allow service role to manage thumbnails
-- Edge Function uses service role to auto-generate thumbnails
CREATE POLICY "System can manage thumbnails"
ON storage.objects FOR ALL
TO service_role
USING (
    bucket_id = 'exercise-videos'
    AND (storage.foldername(name))[1] = 'thumbnails'
);

-- ============================================================================
-- 4. ENABLE RLS ON STORAGE.OBJECTS
-- ============================================================================

-- Ensure RLS is enabled on the storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. CREATE HELPER FUNCTION FOR VIDEO URL GENERATION
-- ============================================================================

-- Function to generate public URL for a video
CREATE OR REPLACE FUNCTION get_video_public_url(video_filename TEXT)
RETURNS TEXT AS $$
DECLARE
    project_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co';
    bucket_name TEXT := 'exercise-videos';
BEGIN
    RETURN project_url || '/storage/v1/object/public/' || bucket_name || '/' || video_filename;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to generate thumbnail URL from video filename
CREATE OR REPLACE FUNCTION get_thumbnail_url(video_filename TEXT)
RETURNS TEXT AS $$
DECLARE
    project_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co';
    bucket_name TEXT := 'exercise-videos';
    base_name TEXT;
BEGIN
    -- Extract filename without extension
    base_name := regexp_replace(video_filename, '\.[^.]*$', '');
    RETURN project_url || '/storage/v1/object/public/' || bucket_name || '/thumbnails/' || base_name || '.jpg';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- 6. ADD COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON POLICY "Public read access for exercise videos" ON storage.objects IS
'Allows public read access to all files in exercise-videos bucket. Required for app to display videos to patients.';

COMMENT ON POLICY "Authenticated users can upload exercise videos" ON storage.objects IS
'Allows authenticated users with admin or therapist role to upload new exercise videos. Maximum file size: 15 MB.';

COMMENT ON POLICY "Admin and therapist can update videos" ON storage.objects IS
'Allows admin and therapist users to update video files or metadata.';

COMMENT ON POLICY "Admin and therapist can delete videos" ON storage.objects IS
'Allows admin and therapist users to delete exercise videos. Use with caution as this may break exercise_templates references.';

COMMENT ON POLICY "System can manage thumbnails" ON storage.objects IS
'Allows Edge Function (service role) to automatically generate and manage video thumbnails in the thumbnails/ folder.';

-- ============================================================================
-- 7. VERIFICATION QUERIES
-- ============================================================================

-- Verify bucket was created
DO $$
DECLARE
    bucket_exists BOOLEAN;
    bucket_public BOOLEAN;
    bucket_size_limit BIGINT;
BEGIN
    SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'exercise-videos') INTO bucket_exists;
    SELECT public FROM storage.buckets WHERE id = 'exercise-videos' INTO bucket_public;
    SELECT file_size_limit FROM storage.buckets WHERE id = 'exercise-videos' INTO bucket_size_limit;

    IF bucket_exists THEN
        RAISE NOTICE '✓ Bucket "exercise-videos" created successfully';
        RAISE NOTICE '  - Public access: %', bucket_public;
        RAISE NOTICE '  - File size limit: % MB', bucket_size_limit / 1024 / 1024;
    ELSE
        RAISE WARNING '✗ Bucket "exercise-videos" not found';
    END IF;
END $$;

-- List all policies for exercise-videos bucket
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'objects'
    AND schemaname = 'storage'
    AND policyname LIKE '%exercise%video%';

    RAISE NOTICE '✓ Created % RLS policies for exercise-videos bucket', policy_count;
END $$;

-- ============================================================================
-- 8. USAGE EXAMPLES
-- ============================================================================

/*
-- Example: Upload a video from TypeScript/JavaScript:

const { data, error } = await supabase.storage
  .from('exercise-videos')
  .upload('bench-press.mp4', videoFile, {
    cacheControl: '3600',
    upsert: false
  });

-- Example: Get public URL:

const { data } = supabase.storage
  .from('exercise-videos')
  .getPublicUrl('bench-press.mp4');

console.log(data.publicUrl);
// Output: https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press.mp4

-- Example: List all videos:

const { data, error } = await supabase.storage
  .from('exercise-videos')
  .list();

-- Example: Delete a video (admin/therapist only):

const { error } = await supabase.storage
  .from('exercise-videos')
  .remove(['old-video.mp4']);

-- Example: Use helper functions in SQL:

SELECT
    name,
    get_video_public_url(video_url) as full_video_url,
    get_thumbnail_url(video_url) as thumbnail_url
FROM exercise_templates
WHERE video_url IS NOT NULL;
*/
