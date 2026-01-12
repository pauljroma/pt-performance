-- Populate test video URLs and instruction data for Feature #1 testing
-- BUILD 170: Exercise Alternative Videos & Explanations

-- Use a demo/placeholder video URL (you can replace with real URLs later)
-- Using Apple's sample video URL for testing
DO $$
DECLARE
  demo_video_url TEXT := 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
BEGIN

-- 1. Barbell Bench Press (if exists)
UPDATE exercise_templates
SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/4A90E2/FFFFFF?text=Barbell+Bench+Press',
  technique_cues = jsonb_build_object(
    'setup', ARRAY[
      'Lie flat on bench with eyes under the bar',
      'Feet flat on floor, create slight arch in lower back',
      'Grip bar slightly wider than shoulder width',
      'Unrack bar and hold directly over chest with arms extended'
    ],
    'execution', ARRAY[
      'Lower bar to mid-chest with control (2-3 second descent)',
      'Keep elbows at 45-degree angle to body',
      'Touch chest lightly, then press bar back up',
      'Squeeze chest at top of movement',
      'Maintain shoulder blade retraction throughout'
    ],
    'breathing', ARRAY[
      'Inhale deeply as you lower the bar',
      'Hold breath at bottom for stability',
      'Exhale forcefully as you press up'
    ]
  ),
  form_cues = jsonb_build_array(
    jsonb_build_object('cue', 'Retract shoulder blades (squeeze them together)', 'timestamp', 5),
    jsonb_build_object('cue', 'Bar path should be slightly diagonal', 'timestamp', 15),
    jsonb_build_object('cue', 'Leg drive through the floor', 'timestamp', 20)
  ),
  safety_notes = 'Always use a spotter when lifting heavy weight. Do not bounce the bar off your chest. Keep wrists straight and aligned with forearms. If you feel shoulder pain, reduce weight or adjust grip width.',
  common_mistakes = 'Flaring elbows out to 90 degrees (increases shoulder injury risk). Bouncing bar off chest instead of controlled touch. Losing shoulder blade position. Lifting hips off bench. Uneven bar path or arm extension.'
WHERE name ILIKE '%barbell%bench%press%' OR name ILIKE '%barbell bench%';

-- 2. Dumbbell Bench Press (if exists)
UPDATE exercise_templates
SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/4A90E2/FFFFFF?text=Dumbbell+Bench+Press',
  technique_cues = jsonb_build_object(
    'setup', ARRAY[
      'Sit on bench with dumbbells on thighs',
      'Lie back while bringing dumbbells to chest level',
      'Position dumbbells at chest height with palms forward',
      'Feet flat on floor, slight arch in lower back'
    ],
    'execution', ARRAY[
      'Press dumbbells up until arms are extended',
      'Dumbbells should move in a slight arc, coming together at top',
      'Lower with control back to chest level',
      'Keep elbows at 45-degree angle',
      'Squeeze chest at top of movement'
    ],
    'breathing', ARRAY[
      'Inhale as you lower the dumbbells',
      'Exhale as you press up'
    ]
  ),
  form_cues = jsonb_build_array(
    jsonb_build_object('cue', 'Keep wrists neutral, not bent', 'timestamp', 8),
    jsonb_build_object('cue', 'Dumbbells should be level at top', 'timestamp', 12),
    jsonb_build_object('cue', 'Control the descent - dont drop', 'timestamp', 18)
  ),
  safety_notes = 'Use a spotter for heavy weights. Be careful bringing dumbbells into position and setting them down. Keep core engaged throughout. Stop if you feel shoulder clicking or pain.',
  common_mistakes = 'Pressing dumbbells straight up (should arc slightly inward). Clinking dumbbells together at top. Lowering dumbbells too far below chest level. Using momentum instead of control. Uneven pressing (one side faster than other).'
WHERE name ILIKE '%dumbbell%bench%press%' OR name ILIKE '%dumbbell bench%';

-- 3. Barbell Squat (if exists)
UPDATE exercise_templates
SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/E24A4A/FFFFFF?text=Barbell+Squat',
  technique_cues = jsonb_build_object(
    'setup', ARRAY[
      'Position bar on upper back (high bar) or rear delts (low bar)',
      'Grip bar with hands outside shoulders',
      'Feet shoulder-width apart, toes slightly out',
      'Unrack bar and step back with 2-3 steps',
      'Brace core and engage lats'
    ],
    'execution', ARRAY[
      'Initiate movement by pushing hips back',
      'Bend knees and lower until thighs parallel to ground',
      'Keep chest up and knees tracking over toes',
      'Drive through heels to stand back up',
      'Maintain neutral spine throughout'
    ],
    'breathing', ARRAY[
      'Take deep breath before descent (into belly)',
      'Hold breath during descent and ascent (Valsalva maneuver)',
      'Exhale at top of movement'
    ]
  ),
  form_cues = jsonb_build_array(
    jsonb_build_object('cue', 'Big breath into belly, brace core', 'timestamp', 3),
    jsonb_build_object('cue', 'Knees should not cave inward', 'timestamp', 10),
    jsonb_build_object('cue', 'Weight on mid-foot, not toes', 'timestamp', 15)
  ),
  safety_notes = 'Always use safety bars or a spotter. Do not round your back. If you cannot maintain neutral spine, reduce weight. Keep head neutral (looking slightly down). Warm up thoroughly before heavy sets.',
  common_mistakes = 'Knees caving inward (valgus collapse). Rising with hips first (good morning squat). Looking up excessively. Weight shifting to toes. Not reaching proper depth. Losing core tension at bottom.'
WHERE name ILIKE '%barbell%squat%' OR name ILIKE '%back squat%';

-- 4. Goblet Squat (bodyweight alternative)
UPDATE exercise_templates
SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/E24A4A/FFFFFF?text=Goblet+Squat',
  technique_cues = jsonb_build_object(
    'setup', ARRAY[
      'Hold dumbbell or kettlebell at chest height',
      'Cup weight with both hands under the top end',
      'Feet slightly wider than shoulder-width',
      'Toes pointed slightly outward',
      'Stand tall with chest up'
    ],
    'execution', ARRAY[
      'Initiate by pushing hips back',
      'Lower down until elbows touch inside of knees',
      'Keep weight at chest throughout movement',
      'Use elbows to gently push knees out',
      'Drive through heels to stand back up'
    ],
    'breathing', ARRAY[
      'Inhale as you descend',
      'Exhale as you stand up'
    ]
  ),
  form_cues = jsonb_build_array(
    jsonb_build_object('cue', 'Chest stays upright', 'timestamp', 5),
    jsonb_build_object('cue', 'Elbows inside knees at bottom', 'timestamp', 12),
    jsonb_build_object('cue', 'Drive knees out with elbows', 'timestamp', 15)
  ),
  safety_notes = 'Great beginner exercise for learning squat mechanics. Keep weight close to body. Do not round lower back. Start with lighter weight to master form.',
  common_mistakes = 'Leaning too far forward. Not squatting deep enough. Knees caving inward. Holding weight too far from chest. Losing balance forward onto toes.'
WHERE name ILIKE '%goblet%squat%';

-- 5. Dumbbell Row (if exists)
UPDATE exercise_templates
SET
  video_url = demo_video_url,
  video_thumbnail_url = 'https://via.placeholder.com/640x360/4AE290/FFFFFF?text=Dumbbell+Row',
  technique_cues = jsonb_build_object(
    'setup', ARRAY[
      'Place one knee and hand on bench for support',
      'Other foot flat on floor for stability',
      'Hold dumbbell in free hand with arm extended',
      'Keep back flat and parallel to ground',
      'Look down to maintain neutral neck'
    ],
    'execution', ARRAY[
      'Pull dumbbell up toward hip, leading with elbow',
      'Keep elbow close to body (dont flare out)',
      'Squeeze shoulder blade at top of movement',
      'Lower with control back to starting position',
      'Minimal torso rotation throughout'
    ],
    'breathing', ARRAY[
      'Exhale as you pull the weight up',
      'Inhale as you lower the weight down'
    ]
  ),
  form_cues = jsonb_build_array(
    jsonb_build_object('cue', 'Elbow should travel straight back', 'timestamp', 8),
    jsonb_build_object('cue', 'Think about pulling elbow, not hand', 'timestamp', 12),
    jsonb_build_object('cue', 'Squeeze shoulder blade at top', 'timestamp', 15)
  ),
  safety_notes = 'Keep back flat - do not round. Avoid jerking or using momentum. Keep core engaged to protect lower back. If you feel lower back strain, reduce weight or check form.',
  common_mistakes = 'Rotating torso excessively. Using momentum instead of muscle control. Flaring elbow out to side. Rounding back. Not pulling elbow back far enough. Using too much weight (sacrificing form).'
WHERE name ILIKE '%dumbbell%row%' OR name ILIKE '%single%arm%row%';

END $$;

-- Grant permissions
GRANT SELECT ON exercise_templates TO anon, authenticated;

-- Log completion
DO $$
BEGIN
  RAISE NOTICE 'Test exercise data populated successfully for Feature #1 testing';
END $$;
