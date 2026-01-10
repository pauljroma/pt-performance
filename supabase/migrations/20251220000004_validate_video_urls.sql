-- Build 63: Video URL Validation Migration (YUK-41)
-- Add validation for exercise_templates.video_url to ensure proper format
-- Ensures all video URLs point to valid Supabase Storage locations

-- ============================================================================
-- 1. CREATE VALIDATION FUNCTION
-- ============================================================================

-- Function to validate video URL format
CREATE OR REPLACE FUNCTION validate_video_url(url TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    project_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co';
    storage_path TEXT := '/storage/v1/object/public/exercise-videos/';
    valid_extensions TEXT[] := ARRAY['.mp4', '.mov', '.MP4', '.MOV'];
    has_valid_extension BOOLEAN := FALSE;
    ext TEXT;
BEGIN
    -- Allow NULL URLs (not all exercises have videos yet)
    IF url IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Check if URL starts with correct project URL and storage path
    IF url NOT LIKE project_url || storage_path || '%' THEN
        RETURN FALSE;
    END IF;

    -- Check if URL has a valid video extension
    FOREACH ext IN ARRAY valid_extensions
    LOOP
        IF url LIKE '%' || ext THEN
            has_valid_extension := TRUE;
            EXIT;
        END IF;
    END LOOP;

    -- Check that URL is not a thumbnail
    IF url LIKE '%/thumbnails/%' THEN
        RETURN FALSE;
    END IF;

    RETURN has_valid_extension;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Add comment to function
COMMENT ON FUNCTION validate_video_url(TEXT) IS 'Validates that video_url is properly formatted and points to exercise-videos bucket. Returns TRUE for NULL (optional video) or valid Supabase Storage URL. Returns FALSE for invalid URLs, thumbnail URLs, or non-video files.';

-- ============================================================================
-- 2. CREATE VALIDATION FUNCTION FOR THUMBNAIL URLs
-- ============================================================================

-- Function to validate thumbnail URL format
CREATE OR REPLACE FUNCTION validate_thumbnail_url(url TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    project_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co';
    storage_path TEXT := '/storage/v1/object/public/exercise-videos/thumbnails/';
    valid_extensions TEXT[] := ARRAY['.jpg', '.jpeg', '.JPG', '.JPEG'];
    has_valid_extension BOOLEAN := FALSE;
    ext TEXT;
BEGIN
    -- Allow NULL URLs (thumbnails are optional)
    IF url IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Check if URL starts with correct project URL and thumbnail path
    IF url NOT LIKE project_url || storage_path || '%' THEN
        RETURN FALSE;
    END IF;

    -- Check if URL has a valid image extension
    FOREACH ext IN ARRAY valid_extensions
    LOOP
        IF url LIKE '%' || ext THEN
            has_valid_extension := TRUE;
            EXIT;
        END IF;
    END LOOP;

    RETURN has_valid_extension;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Add comment to function
COMMENT ON FUNCTION validate_thumbnail_url(TEXT) IS 'Validates that video_thumbnail_url is properly formatted and points to thumbnails folder. Returns TRUE for NULL (optional thumbnail) or valid Supabase Storage thumbnail URL. Returns FALSE for invalid URLs or non-image files.';

-- ============================================================================
-- 3. VALIDATE EXISTING DATA & FIX INVALID URLs (BEFORE ADDING CONSTRAINTS)
-- ============================================================================

-- Report on current video URL status
DO $$
DECLARE
    total_exercises INTEGER;
    exercises_with_videos INTEGER;
    exercises_with_thumbnails INTEGER;
    invalid_video_urls INTEGER;
    invalid_thumbnail_urls INTEGER;
    placeholder_videos INTEGER;
BEGIN
    -- Count totals
    SELECT COUNT(*) INTO total_exercises FROM exercise_templates;
    SELECT COUNT(*) INTO exercises_with_videos FROM exercise_templates WHERE video_url IS NOT NULL;
    SELECT COUNT(*) INTO exercises_with_thumbnails FROM exercise_templates WHERE video_thumbnail_url IS NOT NULL;

    -- Count invalid URLs (these will fail the constraint)
    SELECT COUNT(*) INTO invalid_video_urls
    FROM exercise_templates
    WHERE video_url IS NOT NULL AND NOT validate_video_url(video_url);

    SELECT COUNT(*) INTO invalid_thumbnail_urls
    FROM exercise_templates
    WHERE video_thumbnail_url IS NOT NULL AND NOT validate_thumbnail_url(video_thumbnail_url);

    -- Count placeholder URLs
    SELECT COUNT(*) INTO placeholder_videos
    FROM exercise_templates
    WHERE video_url LIKE '%PLACEHOLDER%' OR video_url LIKE '%your-supabase-project%';

    -- Report findings
    RAISE NOTICE '=== Video URL Validation Report ===';
    RAISE NOTICE 'Total exercises: %', total_exercises;
    RAISE NOTICE 'Exercises with video URLs: %', exercises_with_videos;
    RAISE NOTICE 'Exercises with thumbnail URLs: %', exercises_with_thumbnails;
    RAISE NOTICE 'Invalid video URLs: %', invalid_video_urls;
    RAISE NOTICE 'Invalid thumbnail URLs: %', invalid_thumbnail_urls;
    RAISE NOTICE 'Placeholder video URLs: %', placeholder_videos;
    RAISE NOTICE '===================================';

    -- Warn if there are invalid URLs
    IF invalid_video_urls > 0 THEN
        RAISE WARNING 'Found % exercises with invalid video URLs - these will be set to NULL', invalid_video_urls;
    END IF;

    IF invalid_thumbnail_urls > 0 THEN
        RAISE WARNING 'Found % exercises with invalid thumbnail URLs - these will be set to NULL', invalid_thumbnail_urls;
    END IF;
END $$;

-- Fix invalid video URLs (set to NULL - will be fixed when actual videos are uploaded)
UPDATE exercise_templates
SET video_url = NULL
WHERE video_url IS NOT NULL AND NOT validate_video_url(video_url);

-- Fix invalid thumbnail URLs
UPDATE exercise_templates
SET video_thumbnail_url = NULL
WHERE video_thumbnail_url IS NOT NULL AND NOT validate_thumbnail_url(video_thumbnail_url);

-- ============================================================================
-- 4. ADD CHECK CONSTRAINTS (AFTER FIXING DATA)
-- ============================================================================

-- Drop existing constraints if they exist
ALTER TABLE exercise_templates DROP CONSTRAINT IF EXISTS exercise_templates_video_url_check;
ALTER TABLE exercise_templates DROP CONSTRAINT IF EXISTS exercise_templates_thumbnail_url_check;

-- Add constraint to validate video URLs
ALTER TABLE exercise_templates
ADD CONSTRAINT exercise_templates_video_url_check
CHECK (validate_video_url(video_url));

-- Add constraint to validate thumbnail URLs
ALTER TABLE exercise_templates
ADD CONSTRAINT exercise_templates_thumbnail_url_check
CHECK (validate_thumbnail_url(video_thumbnail_url));

-- Add comments to constraints
COMMENT ON CONSTRAINT exercise_templates_video_url_check ON exercise_templates IS
'Ensures video_url is NULL or a valid Supabase Storage URL pointing to exercise-videos bucket';

COMMENT ON CONSTRAINT exercise_templates_thumbnail_url_check ON exercise_templates IS
'Ensures video_thumbnail_url is NULL or a valid Supabase Storage URL pointing to thumbnails folder';

-- ============================================================================
-- 5. CREATE HELPER VIEW
-- ============================================================================

-- Create view showing exercises with their video status
CREATE OR REPLACE VIEW exercise_video_status AS
SELECT
    id,
    name,
    category,
    body_region,
    equipment_type,
    difficulty_level,
    video_url,
    video_thumbnail_url,
    video_duration,
    video_file_size,
    CASE
        WHEN video_url IS NOT NULL AND video_thumbnail_url IS NOT NULL THEN 'complete'
        WHEN video_url IS NOT NULL AND video_thumbnail_url IS NULL THEN 'missing_thumbnail'
        WHEN video_url IS NULL THEN 'no_video'
        ELSE 'unknown'
    END as video_status,
    CASE
        WHEN video_url IS NULL THEN FALSE
        WHEN video_url LIKE '%PLACEHOLDER%' THEN FALSE
        WHEN video_url LIKE '%your-supabase-project%' THEN FALSE
        ELSE validate_video_url(video_url)
    END as has_valid_video,
    CASE
        WHEN video_thumbnail_url IS NULL THEN FALSE
        ELSE validate_thumbnail_url(video_thumbnail_url)
    END as has_valid_thumbnail
FROM exercise_templates
ORDER BY name;

-- Add comment to view
COMMENT ON VIEW exercise_video_status IS
'Shows video status for all exercises including validation status and missing components';

-- ============================================================================
-- 6. CREATE TRIGGER TO AUTO-UPDATE THUMBNAIL URL
-- ============================================================================

-- Function to auto-set thumbnail URL when video URL is set
CREATE OR REPLACE FUNCTION auto_set_thumbnail_url()
RETURNS TRIGGER AS $$
DECLARE
    base_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/';
    filename TEXT;
    thumbnail_url TEXT;
BEGIN
    -- If video_url is being set and thumbnail_url is NULL, auto-generate thumbnail URL
    IF NEW.video_url IS NOT NULL AND NEW.video_thumbnail_url IS NULL THEN
        -- Extract filename from video URL
        filename := regexp_replace(NEW.video_url, '^.*/', ''); -- Get last part after /
        filename := regexp_replace(filename, '\.[^.]*$', '');   -- Remove extension

        -- Construct thumbnail URL
        thumbnail_url := base_url || 'thumbnails/' || filename || '.jpg';

        -- Set the thumbnail URL
        NEW.video_thumbnail_url := thumbnail_url;

        RAISE NOTICE 'Auto-generated thumbnail URL: %', thumbnail_url;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS auto_set_thumbnail_url_trigger ON exercise_templates;

CREATE TRIGGER auto_set_thumbnail_url_trigger
BEFORE INSERT OR UPDATE OF video_url ON exercise_templates
FOR EACH ROW
WHEN (NEW.video_url IS NOT NULL)
EXECUTE FUNCTION auto_set_thumbnail_url();

-- Add comment to trigger
COMMENT ON TRIGGER auto_set_thumbnail_url_trigger ON exercise_templates IS
'Automatically generates and sets video_thumbnail_url when video_url is provided';

-- ============================================================================
-- 7. USAGE EXAMPLES AND TESTING
-- ============================================================================

/*
-- Test validation function with valid URL:
SELECT validate_video_url('https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press.mp4');
-- Result: TRUE

-- Test validation function with invalid URL:
SELECT validate_video_url('https://example.com/video.mp4');
-- Result: FALSE

-- Test validation function with NULL:
SELECT validate_video_url(NULL);
-- Result: TRUE

-- Test thumbnail validation:
SELECT validate_thumbnail_url('https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/thumbnails/bench-press.jpg');
-- Result: TRUE

-- View exercise video status:
SELECT * FROM exercise_video_status WHERE video_status = 'no_video';

-- Count exercises by video status:
SELECT
    video_status,
    COUNT(*) as count
FROM exercise_video_status
GROUP BY video_status;

-- Find exercises with invalid URLs:
SELECT
    name,
    video_url,
    has_valid_video,
    video_thumbnail_url,
    has_valid_thumbnail
FROM exercise_video_status
WHERE (video_url IS NOT NULL AND NOT has_valid_video)
   OR (video_thumbnail_url IS NOT NULL AND NOT has_valid_thumbnail);

-- Update exercise with valid video URL (thumbnail URL will auto-generate):
UPDATE exercise_templates
SET video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/deadlift.mp4'
WHERE name = 'Conventional Deadlift';

-- Verify the thumbnail URL was auto-generated:
SELECT name, video_url, video_thumbnail_url
FROM exercise_templates
WHERE name = 'Conventional Deadlift';
*/

-- ============================================================================
-- 8. FINAL VERIFICATION
-- ============================================================================

DO $$
DECLARE
    constraint_count INTEGER;
    view_exists BOOLEAN;
    trigger_exists BOOLEAN;
BEGIN
    -- Check constraints exist
    SELECT COUNT(*) INTO constraint_count
    FROM pg_constraint
    WHERE conname IN ('exercise_templates_video_url_check', 'exercise_templates_thumbnail_url_check');

    -- Check view exists
    SELECT EXISTS(
        SELECT 1 FROM pg_views WHERE viewname = 'exercise_video_status'
    ) INTO view_exists;

    -- Check trigger exists
    SELECT EXISTS(
        SELECT 1 FROM pg_trigger WHERE tgname = 'auto_set_thumbnail_url_trigger'
    ) INTO trigger_exists;

    RAISE NOTICE '=== Migration Complete ===';
    RAISE NOTICE 'Validation constraints: % of 2', constraint_count;
    RAISE NOTICE 'exercise_video_status view: %', CASE WHEN view_exists THEN 'Created' ELSE 'Missing' END;
    RAISE NOTICE 'Auto-thumbnail trigger: %', CASE WHEN trigger_exists THEN 'Created' ELSE 'Missing' END;
    RAISE NOTICE '=========================';

    -- Verify all is good
    IF constraint_count = 2 AND view_exists AND trigger_exists THEN
        RAISE NOTICE '✓ All video URL validation components created successfully';
    ELSE
        RAISE WARNING '✗ Some components missing - review migration logs';
    END IF;
END $$;
