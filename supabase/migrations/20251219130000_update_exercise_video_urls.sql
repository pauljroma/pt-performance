-- Build 69: Update Exercise Templates with Video URLs (ACP-174)
-- Updates all 50+ exercises with video and thumbnail URLs pointing to Supabase Storage
-- This migration assumes videos have been uploaded to the exercise-videos bucket

-- ============================================================================
-- 1. UPDATE EXERCISE TEMPLATES WITH VIDEO URLS
-- ============================================================================

-- Note: Using placeholder URLs that match the uploaded filenames
-- Replace 'https://rpbxeaxlaoyoqkohytlw.supabase.co' with your actual Supabase project URL
-- For local development, use: 'http://localhost:54321'

-- Function to generate video URL (local or remote)
CREATE OR REPLACE FUNCTION generate_video_url(filename TEXT, is_thumbnail BOOLEAN DEFAULT false)
RETURNS TEXT AS $$
DECLARE
    base_url TEXT;
    path_prefix TEXT;
BEGIN
    -- Determine if we're running locally or in production
    -- In production, replace with actual project URL
    base_url := 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos';

    -- For thumbnails, add /thumbnails/ prefix
    IF is_thumbnail THEN
        path_prefix := '/thumbnails/';
    ELSE
        path_prefix := '/';
    END IF;

    RETURN base_url || path_prefix || filename;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- 2. UPDATE UPPER BODY - PUSH EXERCISES
-- ============================================================================

-- 1. Barbell Bench Press
UPDATE exercise_templates
SET
    video_url = generate_video_url('bench-press.mp4'),
    video_thumbnail_url = generate_video_url('bench-press.jpg', true),
    video_duration = 30,
    video_file_size = 5242880, -- ~5MB
    video_thumbnail_timestamp = 3,
    updated_at = now()
WHERE name = 'Barbell Bench Press';

-- 2. Incline Dumbbell Press
UPDATE exercise_templates
SET
    video_url = generate_video_url('incline-db-press.mp4'),
    video_thumbnail_url = generate_video_url('incline-db-press.jpg', true),
    video_duration = 30,
    video_file_size = 5242880,
    video_thumbnail_timestamp = 3,
    updated_at = now()
WHERE name = 'Incline Dumbbell Press';

-- 3. Barbell Overhead Press
UPDATE exercise_templates
SET
    video_url = generate_video_url('overhead-press.mp4'),
    video_thumbnail_url = generate_video_url('overhead-press.jpg', true),
    video_duration = 30,
    video_file_size = 5242880,
    video_thumbnail_timestamp = 3,
    updated_at = now()
WHERE name = 'Barbell Overhead Press';

-- 4. Seated Dumbbell Shoulder Press
UPDATE exercise_templates
SET
    video_url = generate_video_url('db-shoulder-press.mp4'),
    video_thumbnail_url = generate_video_url('db-shoulder-press.jpg', true),
    video_duration = 30,
    video_file_size = 5242880,
    video_thumbnail_timestamp = 3,
    updated_at = now()
WHERE name = 'Seated Dumbbell Shoulder Press';

-- 5. Push-up
UPDATE exercise_templates
SET
    video_url = generate_video_url('pushup.mp4'),
    video_thumbnail_url = generate_video_url('pushup.jpg', true),
    video_duration = 30,
    video_file_size = 5242880,
    video_thumbnail_timestamp = 3,
    updated_at = now()
WHERE name = 'Push-up';

-- 6. Parallel Bar Dips
UPDATE exercise_templates
SET
    video_url = generate_video_url('dips.mp4'),
    video_thumbnail_url = generate_video_url('dips.jpg', true),
    video_duration = 30,
    video_file_size = 5242880,
    video_thumbnail_timestamp = 3,
    updated_at = now()
WHERE name = 'Parallel Bar Dips';

-- 7. Single-Arm Landmine Press
UPDATE exercise_templates
SET
    video_url = generate_video_url('landmine-press.mp4'),
    video_thumbnail_url = generate_video_url('landmine-press.jpg', true),
    video_duration = 30,
    video_file_size = 5242880,
    video_thumbnail_timestamp = 3,
    updated_at = now()
WHERE name = 'Single-Arm Landmine Press';

-- 8. Cable Chest Fly
UPDATE exercise_templates
SET
    video_url = generate_video_url('cable-fly.mp4'),
    video_thumbnail_url = generate_video_url('cable-fly.jpg', true),
    video_duration = 30,
    video_file_size = 5242880,
    video_thumbnail_timestamp = 3,
    updated_at = now()
WHERE name = 'Cable Chest Fly';

-- ============================================================================
-- 3. UPDATE UPPER BODY - PULL EXERCISES
-- ============================================================================

UPDATE exercise_templates SET video_url = generate_video_url('pullup.mp4'), video_thumbnail_url = generate_video_url('pullup.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Pull-up';
UPDATE exercise_templates SET video_url = generate_video_url('barbell-row.mp4'), video_thumbnail_url = generate_video_url('barbell-row.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Barbell Bent-Over Row';
UPDATE exercise_templates SET video_url = generate_video_url('lat-pulldown.mp4'), video_thumbnail_url = generate_video_url('lat-pulldown.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Lat Pulldown';
UPDATE exercise_templates SET video_url = generate_video_url('cable-row.mp4'), video_thumbnail_url = generate_video_url('cable-row.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Seated Cable Row';
UPDATE exercise_templates SET video_url = generate_video_url('face-pull.mp4'), video_thumbnail_url = generate_video_url('face-pull.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Cable Face Pull';
UPDATE exercise_templates SET video_url = generate_video_url('db-row.mp4'), video_thumbnail_url = generate_video_url('db-row.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Single-Arm Dumbbell Row';
UPDATE exercise_templates SET video_url = generate_video_url('inverted-row.mp4'), video_thumbnail_url = generate_video_url('inverted-row.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Inverted Row';

-- ============================================================================
-- 4. UPDATE LOWER BODY - SQUAT EXERCISES
-- ============================================================================

UPDATE exercise_templates SET video_url = generate_video_url('back-squat.mp4'), video_thumbnail_url = generate_video_url('back-squat.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Barbell Back Squat';
UPDATE exercise_templates SET video_url = generate_video_url('front-squat.mp4'), video_thumbnail_url = generate_video_url('front-squat.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Barbell Front Squat';
UPDATE exercise_templates SET video_url = generate_video_url('goblet-squat.mp4'), video_thumbnail_url = generate_video_url('goblet-squat.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Goblet Squat';
UPDATE exercise_templates SET video_url = generate_video_url('leg-press.mp4'), video_thumbnail_url = generate_video_url('leg-press.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Leg Press';

-- ============================================================================
-- 5. UPDATE LOWER BODY - HINGE EXERCISES
-- ============================================================================

UPDATE exercise_templates SET video_url = generate_video_url('deadlift.mp4'), video_thumbnail_url = generate_video_url('deadlift.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Conventional Deadlift';
UPDATE exercise_templates SET video_url = generate_video_url('rdl.mp4'), video_thumbnail_url = generate_video_url('rdl.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Romanian Deadlift (RDL)';
UPDATE exercise_templates SET video_url = generate_video_url('hip-thrust.mp4'), video_thumbnail_url = generate_video_url('hip-thrust.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Barbell Hip Thrust';
UPDATE exercise_templates SET video_url = generate_video_url('glute-bridge.mp4'), video_thumbnail_url = generate_video_url('glute-bridge.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Glute Bridge';
UPDATE exercise_templates SET video_url = generate_video_url('nordic-curl.mp4'), video_thumbnail_url = generate_video_url('nordic-curl.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Nordic Hamstring Curl';

-- ============================================================================
-- 6. UPDATE LOWER BODY - LUNGE & ACCESSORIES
-- ============================================================================

UPDATE exercise_templates SET video_url = generate_video_url('bulgarian-split-squat.mp4'), video_thumbnail_url = generate_video_url('bulgarian-split-squat.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Bulgarian Split Squat';
UPDATE exercise_templates SET video_url = generate_video_url('walking-lunge.mp4'), video_thumbnail_url = generate_video_url('walking-lunge.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Walking Lunge';
UPDATE exercise_templates SET video_url = generate_video_url('step-up.mp4'), video_thumbnail_url = generate_video_url('step-up.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Box Step-up';
UPDATE exercise_templates SET video_url = generate_video_url('leg-curl.mp4'), video_thumbnail_url = generate_video_url('leg-curl.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Lying Leg Curl';
UPDATE exercise_templates SET video_url = generate_video_url('leg-extension.mp4'), video_thumbnail_url = generate_video_url('leg-extension.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Leg Extension';
UPDATE exercise_templates SET video_url = generate_video_url('calf-raise.mp4'), video_thumbnail_url = generate_video_url('calf-raise.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Standing Calf Raise';

-- ============================================================================
-- 7. UPDATE CORE & STABILITY EXERCISES
-- ============================================================================

UPDATE exercise_templates SET video_url = generate_video_url('plank.mp4'), video_thumbnail_url = generate_video_url('plank.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Front Plank';
UPDATE exercise_templates SET video_url = generate_video_url('side-plank.mp4'), video_thumbnail_url = generate_video_url('side-plank.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Side Plank';
UPDATE exercise_templates SET video_url = generate_video_url('pallof-press.mp4'), video_thumbnail_url = generate_video_url('pallof-press.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Pallof Press';
UPDATE exercise_templates SET video_url = generate_video_url('dead-bug.mp4'), video_thumbnail_url = generate_video_url('dead-bug.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Dead Bug';
UPDATE exercise_templates SET video_url = generate_video_url('bird-dog.mp4'), video_thumbnail_url = generate_video_url('bird-dog.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Bird Dog';
UPDATE exercise_templates SET video_url = generate_video_url('russian-twist.mp4'), video_thumbnail_url = generate_video_url('russian-twist.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Russian Twist';
UPDATE exercise_templates SET video_url = generate_video_url('hanging-leg-raise.mp4'), video_thumbnail_url = generate_video_url('hanging-leg-raise.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Hanging Leg Raise';
UPDATE exercise_templates SET video_url = generate_video_url('ab-wheel.mp4'), video_thumbnail_url = generate_video_url('ab-wheel.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Ab Wheel Rollout';
UPDATE exercise_templates SET video_url = generate_video_url('cable-crunch.mp4'), video_thumbnail_url = generate_video_url('cable-crunch.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Cable Crunch';
UPDATE exercise_templates SET video_url = generate_video_url('mountain-climbers.mp4'), video_thumbnail_url = generate_video_url('mountain-climbers.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Mountain Climbers';

-- ============================================================================
-- 8. UPDATE ACCESSORIES & MOBILITY EXERCISES
-- ============================================================================

UPDATE exercise_templates SET video_url = generate_video_url('bicep-curl.mp4'), video_thumbnail_url = generate_video_url('bicep-curl.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Dumbbell Bicep Curl';
UPDATE exercise_templates SET video_url = generate_video_url('tricep-pushdown.mp4'), video_thumbnail_url = generate_video_url('tricep-pushdown.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Cable Tricep Pushdown';
UPDATE exercise_templates SET video_url = generate_video_url('lateral-raise.mp4'), video_thumbnail_url = generate_video_url('lateral-raise.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Dumbbell Lateral Raise';
UPDATE exercise_templates SET video_url = generate_video_url('rear-delt-fly.mp4'), video_thumbnail_url = generate_video_url('rear-delt-fly.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Bent-Over Rear Delt Fly';
UPDATE exercise_templates SET video_url = generate_video_url('farmers-walk.mp4'), video_thumbnail_url = generate_video_url('farmers-walk.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Farmers Walk';
UPDATE exercise_templates SET video_url = generate_video_url('band-pull-apart.mp4'), video_thumbnail_url = generate_video_url('band-pull-apart.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Band Pull-Apart';
UPDATE exercise_templates SET video_url = generate_video_url('cat-cow.mp4'), video_thumbnail_url = generate_video_url('cat-cow.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Cat-Cow Stretch';
UPDATE exercise_templates SET video_url = generate_video_url('thread-needle.mp4'), video_thumbnail_url = generate_video_url('thread-needle.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Thread the Needle';
UPDATE exercise_templates SET video_url = generate_video_url('worlds-greatest.mp4'), video_thumbnail_url = generate_video_url('worlds-greatest.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'World''s Greatest Stretch';
UPDATE exercise_templates SET video_url = generate_video_url('foam-roll-thoracic.mp4'), video_thumbnail_url = generate_video_url('foam-roll-thoracic.jpg', true), video_duration = 30, video_file_size = 5242880, video_thumbnail_timestamp = 3, updated_at = now() WHERE name = 'Foam Roll Thoracic Extension';

-- ============================================================================
-- 9. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    total_exercises INTEGER;
    exercises_with_videos INTEGER;
    exercises_with_thumbnails INTEGER;
    missing_video_count INTEGER;
BEGIN
    -- Count total exercises
    SELECT COUNT(*) INTO total_exercises FROM exercise_templates;

    -- Count exercises with videos
    SELECT COUNT(*) INTO exercises_with_videos
    FROM exercise_templates
    WHERE video_url IS NOT NULL AND video_url != '';

    -- Count exercises with thumbnails
    SELECT COUNT(*) INTO exercises_with_thumbnails
    FROM exercise_templates
    WHERE video_thumbnail_url IS NOT NULL AND video_thumbnail_url != '';

    -- Count exercises missing videos
    SELECT COUNT(*) INTO missing_video_count
    FROM exercise_templates
    WHERE video_url IS NULL OR video_url = '';

    RAISE NOTICE '=== Build 69: Exercise Video URLs Update Complete ===';
    RAISE NOTICE 'Total exercises: %', total_exercises;
    RAISE NOTICE 'Exercises with videos: %', exercises_with_videos;
    RAISE NOTICE 'Exercises with thumbnails: %', exercises_with_thumbnails;
    RAISE NOTICE 'Exercises missing videos: %', missing_video_count;
    RAISE NOTICE '=======================================================';

    IF exercises_with_videos >= 50 THEN
        RAISE NOTICE '✓ Successfully updated 50+ exercises with video URLs';
    ELSE
        RAISE WARNING '⚠ Only % exercises have video URLs (target: 50+)', exercises_with_videos;
    END IF;
END $$;

-- ============================================================================
-- 10. CREATE VIEW FOR VIDEO STATUS
-- ============================================================================

CREATE OR REPLACE VIEW exercise_video_status AS
SELECT
    et.id,
    et.name,
    et.category,
    et.body_region,
    et.equipment_type,
    et.difficulty_level,
    CASE
        WHEN et.video_url IS NOT NULL AND et.video_url != '' THEN true
        ELSE false
    END AS has_video,
    CASE
        WHEN et.video_thumbnail_url IS NOT NULL AND et.video_thumbnail_url != '' THEN true
        ELSE false
    END AS has_thumbnail,
    et.video_url,
    et.video_thumbnail_url,
    et.video_duration,
    ROUND(et.video_file_size::numeric / 1048576, 2) AS video_size_mb,
    -- Check if video exists in storage
    video_exists_in_storage(
        extract_video_filename(et.video_url)
    ) AS video_file_exists,
    et.view_count,
    et.download_count,
    et.is_favorite,
    et.updated_at
FROM exercise_templates et
WHERE et.video_url IS NOT NULL OR et.video_thumbnail_url IS NOT NULL
ORDER BY et.name;

COMMENT ON VIEW exercise_video_status IS
'Shows video status for all exercises including whether files exist in storage.';

-- ============================================================================
-- NOTES
-- ============================================================================

/*
This migration updates exercise_templates with video URLs.

IMPORTANT:
1. Videos must be uploaded to Supabase Storage BEFORE running this migration
2. Run: ./scripts/generate_placeholder_videos.sh
3. Run: ./scripts/upload_videos_to_supabase.sh --local
4. Then run this migration

URL STRUCTURE:
- Videos: /storage/v1/object/public/exercise-videos/{filename}.mp4
- Thumbnails: /storage/v1/object/public/exercise-videos/thumbnails/{filename}.jpg

VERIFICATION:
-- Check video status
SELECT * FROM exercise_video_status;

-- Find exercises without videos
SELECT name, category FROM exercise_templates
WHERE video_url IS NULL OR video_url = '';

-- Verify file existence in storage
SELECT
    name,
    has_video,
    video_file_exists,
    video_url
FROM exercise_video_status
WHERE has_video = true AND video_file_exists = false;
*/
