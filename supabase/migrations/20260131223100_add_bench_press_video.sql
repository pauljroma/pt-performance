-- Add bench press demonstration video (Remotion motion graphics)
-- Generated from scripts/video-generation toolkit

UPDATE exercise_templates
SET
  video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press-motion.mp4',
  video_duration = 30
WHERE name ILIKE '%bench%press%'
  AND video_url IS NULL;

-- Verify update
DO $$
DECLARE
  updated_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO updated_count
  FROM exercise_templates
  WHERE video_url LIKE '%bench-press-motion%';

  RAISE NOTICE 'Updated % exercise(s) with bench press video', updated_count;
END $$;
