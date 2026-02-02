-- Link uploaded exercise demonstration videos to exercise_templates
-- Videos generated with Remotion motion graphics toolkit

-- Bench Press
UPDATE exercise_templates
SET video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press-motion.mp4',
    video_duration = 30
WHERE name ILIKE '%bench%press%' AND video_url IS NULL;

-- Squat
UPDATE exercise_templates
SET video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/squat-motion.mp4',
    video_duration = 30
WHERE name ILIKE '%squat%' AND video_url IS NULL;

-- Deadlift
UPDATE exercise_templates
SET video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/deadlift-motion.mp4',
    video_duration = 30
WHERE name ILIKE '%deadlift%' AND video_url IS NULL;

-- Overhead Press / Shoulder Press
UPDATE exercise_templates
SET video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/overhead-press-motion.mp4',
    video_duration = 30
WHERE (name ILIKE '%overhead%press%' OR name ILIKE '%shoulder%press%') AND video_url IS NULL;

-- Pull-up
UPDATE exercise_templates
SET video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/pull-up-motion.mp4',
    video_duration = 30
WHERE name ILIKE '%pull%up%' AND video_url IS NULL;

-- Log results
DO $$
DECLARE
    video_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO video_count FROM exercise_templates WHERE video_url IS NOT NULL;
    RAISE NOTICE 'Total exercises with videos: %', video_count;
END $$;
