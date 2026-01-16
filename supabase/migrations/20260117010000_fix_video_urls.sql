-- Fix video URLs to use shorter, faster-loading sample clips
-- The previous URLs were full-length movies that are too large for mobile streaming

-- Use Apple's sample HLS streams which are optimized for mobile
-- Or use shorter MP4 clips

-- Bodyweight Squat - use a short sample clip
UPDATE exercise_templates
SET video_url = 'https://storage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4'
WHERE id = '00000000-0000-0000-0000-000000000013';

-- Push-ups - use a different short clip
UPDATE exercise_templates
SET video_url = 'https://storage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4'
WHERE id = '00000000-0000-0000-0000-000000000010';

-- Hip Hinge
UPDATE exercise_templates
SET video_url = 'https://storage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4'
WHERE id = '00000000-0000-0000-0000-0000000000fe';

-- Prone Y Raise
UPDATE exercise_templates
SET video_url = 'https://storage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4'
WHERE id = '00000000-0000-0000-0000-000000000b01';

-- Pike Push-Up
UPDATE exercise_templates
SET video_url = 'https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4'
WHERE id = '00000000-0000-0000-0000-0000000000ff';
