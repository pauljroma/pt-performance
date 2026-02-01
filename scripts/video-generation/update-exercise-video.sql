-- Update exercise template with video URL after uploading to Supabase Storage
-- Run this in Supabase SQL Editor or via CLI

-- ============================================================================
-- OPTION 1: Update by exercise name pattern
-- ============================================================================

-- Bench Press example
UPDATE exercise_templates
SET
  video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press.mp4',
  video_duration = 30,
  video_file_size = NULL  -- Will be set by upload script if available
WHERE name ILIKE '%bench%press%'
  AND (category = 'push' OR body_region = 'upper');

-- Verify the update
SELECT id, name, video_url, video_duration
FROM exercise_templates
WHERE name ILIKE '%bench%press%';


-- ============================================================================
-- OPTION 2: Batch update multiple exercises
-- ============================================================================

-- Update multiple exercises at once using a CTE
WITH video_mappings AS (
  SELECT * FROM (VALUES
    ('bench-press.mp4', '%bench%press%', 30),
    ('squat.mp4', '%squat%', 30),
    ('deadlift.mp4', '%deadlift%', 30),
    ('overhead-press.mp4', '%overhead%press%', 30),
    ('pull-up.mp4', '%pull%up%', 30),
    ('push-up.mp4', '%push%up%', 30),
    ('lunge.mp4', '%lunge%', 30),
    ('row.mp4', '%row%', 30)
  ) AS t(filename, name_pattern, duration)
)
UPDATE exercise_templates et
SET
  video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/' || vm.filename,
  video_duration = vm.duration
FROM video_mappings vm
WHERE et.name ILIKE vm.name_pattern;


-- ============================================================================
-- OPTION 3: Update by exercise ID (most precise)
-- ============================================================================

-- Get exercise IDs first
SELECT id, name, category, body_region
FROM exercise_templates
WHERE video_url IS NULL
ORDER BY name;

-- Then update specific exercises
UPDATE exercise_templates
SET
  video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press-animated.mp4',
  video_duration = 30
WHERE id = 'YOUR-EXERCISE-UUID-HERE';


-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check exercises with videos
SELECT
  name,
  video_url,
  video_duration,
  video_thumbnail_url
FROM exercise_templates
WHERE video_url IS NOT NULL
ORDER BY name;

-- Check exercises without videos
SELECT name, category, body_region
FROM exercise_templates
WHERE video_url IS NULL
ORDER BY category, name;

-- Storage inventory (shows what's actually in the bucket)
SELECT * FROM video_storage_inventory;

-- Check for mismatches (videos in storage but not linked)
SELECT filename, public_url, linked_exercise_count
FROM video_storage_inventory
WHERE linked_exercise_count = 0;


-- ============================================================================
-- ADD AI DISCLOSURE FLAG (if using AI-generated videos)
-- ============================================================================

-- First, add the column if it doesn't exist
ALTER TABLE exercise_templates
ADD COLUMN IF NOT EXISTS is_ai_generated BOOLEAN DEFAULT FALSE;

-- Mark AI-generated videos
UPDATE exercise_templates
SET is_ai_generated = TRUE
WHERE video_url LIKE '%ai%' OR video_url LIKE '%runway%';

-- Query to show AI-generated videos
SELECT name, video_url, is_ai_generated
FROM exercise_templates
WHERE is_ai_generated = TRUE;
