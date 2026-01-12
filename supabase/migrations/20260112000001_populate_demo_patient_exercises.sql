-- Populate test data for demo patient's exercises
-- BUILD 170: Add video/instructions for demo patient workout

DO $$
DECLARE
  demo_video_url TEXT := 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
BEGIN

-- 1. Band Pull Apart
UPDATE exercise_templates
SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/4AE2A6/FFFFFF?text=Band+Pull+Apart',
  technique_cues = jsonb_build_object(
    'setup', ARRAY[
      'Hold resistance band with both hands at chest height',
      'Arms extended straight in front of you',
      'Hands shoulder-width apart on band',
      'Stand tall with feet hip-width apart',
      'Engage your core and keep shoulders down'
    ],
    'execution', ARRAY[
      'Pull band apart by moving hands out to sides',
      'Squeeze shoulder blades together at end range',
      'Keep arms straight throughout movement',
      'Control the band back to starting position',
      'Maintain constant tension on the band'
    ],
    'breathing', ARRAY[
      'Exhale as you pull the band apart',
      'Inhale as you return to center'
    ]
  ),
  form_cues = jsonb_build_array(
    jsonb_build_object('cue', 'Keep shoulders down and back', 'timestamp', 5),
    jsonb_build_object('cue', 'Squeeze shoulder blades together', 'timestamp', 10),
    jsonb_build_object('cue', 'Arms stay at chest height', 'timestamp', 15)
  ),
  safety_notes = 'Start with light resistance band. Avoid shrugging shoulders up toward ears. Keep wrists neutral. Stop if you feel pain in shoulders or neck. Great for shoulder health and posture.',
  common_mistakes = 'Allowing shoulders to elevate toward ears. Bending elbows during pull. Moving arms up or down from chest height. Using too much resistance (sacrificing form). Rushing the movement without control.',
  equipment_required = ARRAY['Resistance Band']
WHERE name ILIKE '%band%pull%apart%' OR name ILIKE '%band pull apart%';

-- 2. Scapular Wall Slide
UPDATE exercise_templates
SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/E2A64A/FFFFFF?text=Scapular+Wall+Slide',
  technique_cues = jsonb_build_object(
    'setup', ARRAY[
      'Stand with back against wall',
      'Feet about 6 inches away from wall',
      'Press lower back, upper back, and head against wall',
      'Raise arms to 90 degrees with elbows bent (goal post position)',
      'Try to keep forearms and backs of hands against wall'
    ],
    'execution', ARRAY[
      'Slowly slide arms up the wall as high as comfortable',
      'Maintain contact with wall (lower back, upper back, head)',
      'Stop if back or head comes off wall',
      'Slowly slide arms back down to starting position',
      'Focus on scapular upward rotation'
    ],
    'breathing', ARRAY[
      'Inhale at starting position',
      'Exhale as you slide arms up',
      'Inhale as you slide back down'
    ]
  ),
  form_cues = jsonb_build_array(
    jsonb_build_object('cue', 'Keep lower back flat against wall', 'timestamp', 5),
    jsonb_build_object('cue', 'Do not arch back as arms go up', 'timestamp', 12),
    jsonb_build_object('cue', 'Move slowly and controlled', 'timestamp', 18)
  ),
  safety_notes = 'Stop if you feel pinching in shoulders. It is normal to only get partway up at first. Do not force range of motion. This exercise improves shoulder mobility and scapular control. Very safe for shoulder rehabilitation.',
  common_mistakes = 'Arching lower back off wall to get arms higher. Rushing the movement. Allowing head to come forward. Forcing arms up beyond comfortable range. Not maintaining wall contact.',
  equipment_required = ARRAY['Wall']
WHERE name ILIKE '%scapular%wall%slide%' OR name ILIKE '%wall%slide%';

-- 3. Plank
UPDATE exercise_templates
SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/A64AE2/FFFFFF?text=Plank',
  technique_cues = jsonb_build_object(
    'setup', ARRAY[
      'Start in push-up position or on forearms',
      'Elbows directly under shoulders (forearm plank)',
      'Feet hip-width apart',
      'Body forms straight line from head to heels',
      'Engage core by pulling belly button toward spine'
    ],
    'execution', ARRAY[
      'Hold static position maintaining straight body line',
      'Squeeze glutes to prevent hips from sagging',
      'Keep core tight throughout hold',
      'Look down at floor (neutral neck)',
      'Breathe normally, do not hold breath'
    ],
    'breathing', ARRAY[
      'Breathe normally throughout hold',
      'Avoid holding your breath',
      'Keep breathing rhythm steady'
    ]
  ),
  form_cues = jsonb_build_array(
    jsonb_build_object('cue', 'Body should be straight like a plank', 'timestamp', 5),
    jsonb_build_object('cue', 'Do not let hips sag or pike up', 'timestamp', 10),
    jsonb_build_object('cue', 'Squeeze core and glutes', 'timestamp', 15)
  ),
  safety_notes = 'Stop if you feel lower back pain. It is better to hold shorter time with perfect form than longer with poor form. Modify to knees if needed. Build up hold time gradually. Great core stability exercise.',
  common_mistakes = 'Hips sagging toward floor (lower back arches). Hips piking up too high. Holding breath. Looking up (hyperextending neck). Not engaging core. Shoulders shrugging toward ears.',
  equipment_required = ARRAY[]::text[]
WHERE name ILIKE '%plank%' AND NOT (name ILIKE '%side%' OR name ILIKE '%up%down%');

-- 4. Add some equipment exercises for better substitution testing
-- Push-Up (common bodyweight that could substitute to equipment exercises)
UPDATE exercise_templates
SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/4A90E2/FFFFFF?text=Push+Up',
  technique_cues = jsonb_build_object(
    'setup', ARRAY[
      'Start in plank position with hands slightly wider than shoulders',
      'Hands flat on ground, fingers pointing forward',
      'Body forms straight line from head to heels',
      'Feet hip-width apart',
      'Engage core before starting'
    ],
    'execution', ARRAY[
      'Lower body by bending elbows to 90 degrees',
      'Keep elbows at 45-degree angle to body',
      'Chest should nearly touch ground',
      'Press through palms to push back up',
      'Maintain straight body line throughout'
    ],
    'breathing', ARRAY[
      'Inhale as you lower down',
      'Exhale as you push back up'
    ]
  ),
  form_cues = jsonb_build_array(
    jsonb_build_object('cue', 'Keep core tight - no sagging hips', 'timestamp', 5),
    jsonb_build_object('cue', 'Elbows 45 degrees, not flared wide', 'timestamp', 10),
    jsonb_build_object('cue', 'Full range - chest to ground', 'timestamp', 15)
  ),
  safety_notes = 'Modify to knees if full push-up is too difficult. Keep wrists straight. Stop if you feel shoulder or wrist pain. Build strength gradually.',
  common_mistakes = 'Hips sagging. Not going deep enough. Elbows flaring too wide. Head dropping down. Using momentum instead of control.',
  equipment_required = ARRAY[]::text[]
WHERE name ILIKE '%push%up%' OR name ILIKE '%pushup%' AND NOT name ILIKE '%pike%';

END $$;

-- Log completion
DO $$
BEGIN
  RAISE NOTICE 'Demo patient exercise data populated successfully';
END $$;
