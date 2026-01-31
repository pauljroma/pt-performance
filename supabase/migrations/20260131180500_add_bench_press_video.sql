-- Add bench press video URL to exercise templates
-- Video uploaded to Supabase storage: bench-press-motion.mp4

UPDATE exercise_templates
SET
  video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press-motion.mp4',
  video_duration = 30
WHERE name ILIKE '%bench%press%';

-- Verify update
SELECT name, video_url, video_duration
FROM exercise_templates
WHERE name ILIKE '%bench%press%';
