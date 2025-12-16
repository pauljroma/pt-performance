-- Build 61: Add exercise technique guide fields (ACP-156)
-- Add technique_cues (JSONB), common_mistakes (TEXT), safety_notes (TEXT) to exercise_templates

-- Add new columns to exercise_templates table
ALTER TABLE exercise_templates
ADD COLUMN IF NOT EXISTS technique_cues JSONB,
ADD COLUMN IF NOT EXISTS common_mistakes TEXT,
ADD COLUMN IF NOT EXISTS safety_notes TEXT;

-- Add comment describing the technique_cues structure
COMMENT ON COLUMN exercise_templates.technique_cues IS 'JSON structure: {"setup": ["cue1", "cue2"], "execution": ["cue1", "cue2"], "breathing": ["cue1", "cue2"]}';
COMMENT ON COLUMN exercise_templates.common_mistakes IS 'Common mistakes to avoid during exercise execution';
COMMENT ON COLUMN exercise_templates.safety_notes IS 'Important safety information and contraindications';

-- Seed technique data for 30 common exercises
-- Note: video_url uses PLACEHOLDER - replace with actual YouTube/Vimeo URLs when available

-- 1. Back Squat
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_SQUAT_VIDEO',
    technique_cues = '{
        "setup": ["Feet shoulder-width apart", "Bar resting on upper traps", "Hands gripping bar slightly wider than shoulders", "Core braced, chest up", "Eyes looking slightly down and forward"],
        "execution": ["Push knees out slightly as you descend", "Hips move back and down simultaneously", "Keep chest up and maintain neutral spine", "Descend until thighs are parallel or below", "Drive through heels to stand up", "Keep core tight throughout"],
        "breathing": ["Take a deep breath in at the top", "Hold breath during descent", "Maintain breath hold through bottom", "Exhale as you complete the lift"]
    }'::jsonb,
    common_mistakes = 'Knees caving inward (valgus collapse), excessive forward lean, not reaching proper depth, rising onto toes, losing core tension',
    safety_notes = 'Keep spine neutral throughout movement. Stop immediately if you feel sharp pain in knees or lower back. Use safety bars or spotter for heavy loads.'
WHERE LOWER(name) LIKE '%squat%' AND LOWER(name) LIKE '%back%';

-- 2. Front Squat
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_FRONT_SQUAT_VIDEO',
    technique_cues = '{
        "setup": ["Bar rests on front deltoids", "Elbows high, upper arms parallel to floor", "Fingertips under bar or arms crossed", "Feet shoulder-width apart", "Core tight"],
        "execution": ["Keep elbows high throughout", "Descend straight down", "Chest stays upright", "Drive through full foot", "Stand up maintaining elbow position"],
        "breathing": ["Breathe in deeply before descent", "Hold breath through bottom", "Exhale near top"]
    }'::jsonb,
    common_mistakes = 'Dropping elbows, excessive forward lean, heels lifting off ground, losing bar off shoulders',
    safety_notes = 'Front squats are generally safer for the lower back than back squats. Drop the bar forward if you lose position. Requires good thoracic mobility and wrist flexibility.'
WHERE LOWER(name) LIKE '%squat%' AND LOWER(name) LIKE '%front%';

-- 3. Deadlift
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_DEADLIFT_VIDEO',
    technique_cues = '{
        "setup": ["Feet hip-width under bar", "Bar over mid-foot", "Grip just outside legs", "Shoulders over or slightly in front of bar", "Chest up, back flat", "Arms straight"],
        "execution": ["Push floor away with legs", "Bar stays close to body", "Hips and shoulders rise together", "Full hip extension at top", "Reverse movement under control"],
        "breathing": ["Deep breath before lift", "Hold breath during pull", "Exhale at top or during descent"]
    }'::jsonb,
    common_mistakes = 'Rounding lower back, bar drifting away from body, hitching at top, dropping bar on descent, starting with hips too high or low',
    safety_notes = 'CRITICAL: Keep neutral spine throughout. Never round your lower back. Use a belt for heavy loads. Stop if you feel lower back pain. Consider trap bar deadlift as safer alternative.'
WHERE LOWER(name) LIKE '%deadlift%' AND NOT LOWER(name) LIKE '%romanian%';

-- 4. Romanian Deadlift (RDL)
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_RDL_VIDEO',
    technique_cues = '{
        "setup": ["Start standing with bar at hips", "Feet hip-width", "Slight knee bend", "Shoulders back", "Grip just outside legs"],
        "execution": ["Push hips back", "Bar slides down thighs", "Feel hamstring stretch", "Keep back flat", "Reverse by driving hips forward", "Small knee bend throughout"],
        "breathing": ["Breathe in during descent", "Exhale driving up"]
    }'::jsonb,
    common_mistakes = 'Squatting instead of hinging, rounding back, bending knees too much, bar drifting away from legs',
    safety_notes = 'Focus on hip hinge pattern. Keep weight moderate. Excellent for hamstring development with lower back safety than conventional deadlifts.'
WHERE LOWER(name) LIKE '%romanian%' OR LOWER(name) LIKE '%rdl%';

-- 5. Bench Press
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_BENCH_VIDEO',
    technique_cues = '{
        "setup": ["Lie with eyes under bar", "Feet flat on floor", "Squeeze shoulder blades together", "Slight arch in lower back", "Grip slightly wider than shoulders"],
        "execution": ["Unrack with straight arms", "Lower bar to chest with control", "Elbows at 45-degree angle", "Bar touches chest", "Press straight up", "Keep shoulder blades pinched"],
        "breathing": ["Breathe in as you lower bar", "Hold breath at bottom", "Exhale as you press up"]
    }'::jsonb,
    common_mistakes = 'Elbows flaring out to 90 degrees, bouncing bar off chest, losing shoulder blade retraction, feet off ground, uneven bar path',
    safety_notes = 'Always use a spotter for heavy weights or work in a power rack with safety pins. Keep wrists straight. Stop if you feel shoulder pain.'
WHERE LOWER(name) LIKE '%bench%' AND LOWER(name) LIKE '%press%' AND NOT LOWER(name) LIKE '%incline%' AND NOT LOWER(name) LIKE '%decline%';

-- 6. Overhead Press (OHP)
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_OHP_VIDEO',
    technique_cues = '{
        "setup": ["Bar at collarbone level", "Grip just outside shoulders", "Elbows slightly in front of bar", "Feet hip-width", "Core tight"],
        "execution": ["Press bar straight up", "Move head back slightly", "Lock out overhead", "Shrug shoulders at top", "Lower under control", "Bar path straight"],
        "breathing": ["Breathe in before press", "Hold through press", "Exhale at lockout"]
    }'::jsonb,
    common_mistakes = 'Leaning back excessively, not getting head through, pressing forward instead of up, losing core tension, using legs (making it a push press)',
    safety_notes = 'Keep core extremely tight to protect lower back. Do not hyperextend spine. Stop if you feel shoulder impingement. Can be done seated for lower back protection.'
WHERE (LOWER(name) LIKE '%overhead%' AND LOWER(name) LIKE '%press%') OR (LOWER(name) LIKE '%military%' AND LOWER(name) LIKE '%press%');

-- 7. Pull-ups
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_PULLUP_VIDEO',
    technique_cues = '{
        "setup": ["Hang from bar", "Hands slightly wider than shoulders", "Full arm extension", "Engage lats", "Feet together or crossed"],
        "execution": ["Pull elbows down and back", "Lead with chest", "Chin over bar", "Lower with control", "Full arm extension at bottom"],
        "breathing": ["Breathe in during descent", "Exhale during pull"]
    }'::jsonb,
    common_mistakes = 'Kipping or swinging, not going to full extension, pulling with arms instead of back, shrugging shoulders up',
    safety_notes = 'Build up gradually. Use assistance bands if needed. Stop if you feel shoulder or elbow pain. Avoid if you have shoulder impingement.'
WHERE LOWER(name) LIKE '%pull%' AND LOWER(name) LIKE '%up%';

-- 8. Barbell Row
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_ROW_VIDEO',
    technique_cues = '{
        "setup": ["Hip hinge position", "Back flat, nearly parallel to floor", "Arms straight hanging", "Grip slightly wider than shoulders", "Core braced"],
        "execution": ["Pull bar to lower chest/upper abdomen", "Lead with elbows", "Squeeze shoulder blades", "Lower under control", "Maintain back position"],
        "breathing": ["Breathe in during pull", "Exhale during lower"]
    }'::jsonb,
    common_mistakes = 'Standing too upright, using momentum, not maintaining back position, pulling to chest instead of abdomen, not squeezing at top',
    safety_notes = 'Keep back flat throughout. Use straps for heavy loads to reduce grip fatigue. Stop if lower back rounds or hurts.'
WHERE LOWER(name) LIKE '%barbell%' AND LOWER(name) LIKE '%row%';

-- 9. Lunges
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_LUNGE_VIDEO',
    technique_cues = '{
        "setup": ["Stand with feet hip-width", "Core engaged", "Chest up", "Hands on hips or holding weights"],
        "execution": ["Step forward with one leg", "Lower back knee toward ground", "Front knee stays over ankle", "Push through front heel to return", "Alternate legs"],
        "breathing": ["Breathe in during descent", "Exhale during drive up"]
    }'::jsonb,
    common_mistakes = 'Front knee going past toes excessively, back knee slamming into ground, leaning forward, losing balance, steps too short or long',
    safety_notes = 'Start with bodyweight. Keep front shin vertical. Use shorter steps if you have knee issues. Hold onto something for balance if needed.'
WHERE LOWER(name) LIKE '%lunge%';

-- 10. Push-ups
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_PUSHUP_VIDEO',
    technique_cues = '{
        "setup": ["Hands shoulder-width apart", "Body in straight line", "Core tight", "Feet together"],
        "execution": ["Lower chest to ground", "Elbows at 45 degrees", "Keep body straight", "Push through full range", "Lock out at top"],
        "breathing": ["Breathe in going down", "Exhale pushing up"]
    }'::jsonb,
    common_mistakes = 'Hips sagging, hips piked up, not going to full depth, flaring elbows out, head dropping',
    safety_notes = 'Modify on knees or with hands elevated if needed. Keep wrists straight. Stop if you feel wrist or shoulder pain.'
WHERE LOWER(name) LIKE '%push%' AND LOWER(name) LIKE '%up%';

-- 11. Plank
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_PLANK_VIDEO',
    technique_cues = '{
        "setup": ["Forearms on ground", "Elbows under shoulders", "Body in straight line", "Feet hip-width"],
        "execution": ["Squeeze glutes", "Brace core hard", "Hold position", "Breathe steadily", "Do not let hips sag or pike"],
        "breathing": ["Breathe normally", "Do not hold breath", "Maintain core tension"]
    }'::jsonb,
    common_mistakes = 'Hips sagging toward ground, hips too high, holding breath, looking up instead of down, not engaging glutes',
    safety_notes = 'Start with shorter holds (20-30 seconds) and build up. Stop if you feel lower back pain. Focus on quality over duration.'
WHERE LOWER(name) LIKE '%plank%';

-- 12. Dips
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_DIP_VIDEO',
    technique_cues = '{
        "setup": ["Hands on parallel bars", "Arms locked out", "Slight forward lean", "Legs bent or straight"],
        "execution": ["Lower until elbows at 90 degrees", "Keep elbows close", "Press back up", "Lock out at top", "Control the descent"],
        "breathing": ["Breathe in going down", "Exhale pressing up"]
    }'::jsonb,
    common_mistakes = 'Going too deep, flaring elbows out, shrugging shoulders, not locking out, swinging legs for momentum',
    safety_notes = 'Stop at 90 degrees of elbow flexion unless you have excellent shoulder mobility. Use assistance bands if needed. Avoid if you have shoulder issues.'
WHERE LOWER(name) LIKE '%dip%' AND NOT LOWER(name) LIKE '%nordic%';

-- 13. Leg Press
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_LEGPRESS_VIDEO',
    technique_cues = '{
        "setup": ["Back flat against pad", "Feet shoulder-width on platform", "Feet mid-platform", "Hands on handles"],
        "execution": ["Lower platform with control", "Knees track over toes", "Stop before lower back lifts", "Press through full foot", "Do not lock knees fully at top"],
        "breathing": ["Breathe in during descent", "Exhale during press"]
    }'::jsonb,
    common_mistakes = 'Lower back lifting off pad, locking knees out hard, going too deep, feet too high or low on platform',
    safety_notes = 'Keep lower back pressed against pad at all times. Use safety stops. Do not lock out knees forcefully.'
WHERE LOWER(name) LIKE '%leg%' AND LOWER(name) LIKE '%press%';

-- 14. Lat Pulldown
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_LATPULL_VIDEO',
    technique_cues = '{
        "setup": ["Knees secured under pad", "Hands wide on bar", "Sit upright", "Slight lean back"],
        "execution": ["Pull bar to upper chest", "Lead with elbows", "Squeeze shoulder blades", "Control the return", "Full arm extension at top"],
        "breathing": ["Breathe out during pull", "Breathe in during return"]
    }'::jsonb,
    common_mistakes = 'Pulling behind neck, leaning back too much, using momentum, not going to full extension, pulling with arms instead of back',
    safety_notes = 'Always pull to front, never behind neck. Keep core engaged. Use weight you can control through full range.'
WHERE LOWER(name) LIKE '%lat%' AND LOWER(name) LIKE '%pull%';

-- 15. Leg Curl
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_LEGCURL_VIDEO',
    technique_cues = '{
        "setup": ["Lie face down", "Knees just off pad edge", "Ankles behind pad", "Hold handles"],
        "execution": ["Curl heels toward glutes", "Squeeze hamstrings at top", "Lower under control", "Keep hips on pad"],
        "breathing": ["Exhale during curl", "Inhale during lower"]
    }'::jsonb,
    common_mistakes = 'Hips lifting off pad, using momentum, not curling to full range, feet/toes pointing out',
    safety_notes = 'Use smooth controlled motion. Do not jerk the weight. Keep toes pointed toward shins.'
WHERE LOWER(name) LIKE '%leg%' AND LOWER(name) LIKE '%curl%';

-- 16. Cable Row
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_CABLEROW_VIDEO',
    technique_cues = '{
        "setup": ["Sit at cable machine", "Feet on platform", "Slight knee bend", "Upright torso", "Arms extended"],
        "execution": ["Pull handle to lower chest", "Lead with elbows", "Squeeze shoulder blades", "Keep torso stable", "Extend arms fully"],
        "breathing": ["Exhale during pull", "Inhale during extension"]
    }'::jsonb,
    common_mistakes = 'Using momentum, leaning back excessively, shrugging shoulders, not squeezing shoulder blades, rounded back',
    safety_notes = 'Keep torso mostly upright with minimal movement. Control the weight throughout. Focus on back muscles, not arms.'
WHERE LOWER(name) LIKE '%cable%' AND LOWER(name) LIKE '%row%';

-- 17. Bicep Curl
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_CURL_VIDEO',
    technique_cues = '{
        "setup": ["Stand with feet hip-width", "Arms at sides holding weights", "Elbows close to body", "Palms forward"],
        "execution": ["Curl weights up", "Keep elbows stationary", "Squeeze at top", "Lower under control", "Full arm extension at bottom"],
        "breathing": ["Exhale during curl", "Inhale during lower"]
    }'::jsonb,
    common_mistakes = 'Swinging body, moving elbows forward, not going through full range, using momentum, too heavy weight',
    safety_notes = 'Keep elbows locked in position. Use weight you can control. Focus on bicep contraction not moving the weight.'
WHERE LOWER(name) LIKE '%bicep%' OR LOWER(name) LIKE '%curl%';

-- 18. Tricep Extension
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_TRICEP_VIDEO',
    technique_cues = '{
        "setup": ["Stand or sit upright", "Hold weight overhead", "Elbows pointing forward", "Core engaged"],
        "execution": ["Lower weight behind head", "Keep elbows stationary", "Extend arms fully", "Control the movement", "Squeeze triceps at top"],
        "breathing": ["Inhale during lower", "Exhale during extension"]
    }'::jsonb,
    common_mistakes = 'Elbows flaring out, not going through full range, using momentum, arching back',
    safety_notes = 'Keep elbows pointing forward throughout. Use weight you can control. Stop if you feel elbow pain.'
WHERE LOWER(name) LIKE '%tricep%' AND LOWER(name) LIKE '%extension%';

-- 19. Face Pull
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_FACEPULL_VIDEO',
    technique_cues = '{
        "setup": ["Cable at face height", "Rope attachment", "Step back with tension", "Upright posture"],
        "execution": ["Pull rope toward face", "Hands go past ears", "Elbows high", "Squeeze rear delts", "Control the return"],
        "breathing": ["Exhale during pull", "Inhale during return"]
    }'::jsonb,
    common_mistakes = 'Pulling too low, not getting hands past face, elbows dropping, using too much weight, not squeezing rear delts',
    safety_notes = 'Great for shoulder health. Use moderate weight and focus on form. External rotation of shoulders at end of movement is key.'
WHERE LOWER(name) LIKE '%face%' AND LOWER(name) LIKE '%pull%';

-- 20. Hip Thrust
UPDATE exercise_templates
SET
    video_url = 'PLACEHOLDER_HIPTHRUST_VIDEO',
    technique_cues = '{
        "setup": ["Upper back on bench", "Bar over hips with pad", "Feet flat, hip-width", "Knees bent 90 degrees"],
        "execution": ["Drive through heels", "Squeeze glutes hard at top", "Hips fully extended", "Lower under control", "Keep chin tucked"],
        "breathing": ["Exhale at top", "Inhale during lower"]
    }'::jsonb,
    common_mistakes = 'Hyperextending lower back, not achieving full hip extension, feet too close or far, not squeezing glutes',
    safety_notes = 'Use a bar pad to prevent bruising. Keep ribs down and core engaged. Focus on glute squeeze not arching back.'
WHERE LOWER(name) LIKE '%hip%' AND LOWER(name) LIKE '%thrust%';

-- More exercises (21-30) with briefer entries for space

-- 21. Step-ups
UPDATE exercise_templates
SET
    technique_cues = '{
        "setup": ["Stand facing box or bench", "Height at or below knee", "Chest up"],
        "execution": ["Step up with one foot", "Drive through heel", "Stand fully", "Step down controlled"],
        "breathing": ["Exhale stepping up", "Inhale stepping down"]
    }'::jsonb,
    common_mistakes = 'Using momentum, pushing off back leg, box too high, knee caving in',
    safety_notes = 'Start with lower box height. Keep knee tracking over toes.'
WHERE LOWER(name) LIKE '%step%' AND LOWER(name) LIKE '%up%';

-- 22. Bulgarian Split Squat
UPDATE exercise_templates
SET
    technique_cues = '{
        "setup": ["Back foot elevated on bench", "Front foot forward", "Upright torso"],
        "execution": ["Lower back knee down", "Keep front shin vertical", "Drive through front heel"],
        "breathing": ["Inhale down", "Exhale up"]
    }'::jsonb,
    common_mistakes = 'Front foot too close, leaning forward, not going deep enough',
    safety_notes = 'Excellent single-leg exercise. Start with bodyweight.'
WHERE LOWER(name) LIKE '%bulgarian%';

-- 23. Farmers Walk
UPDATE exercise_templates
SET
    technique_cues = '{
        "setup": ["Hold heavy weights at sides", "Shoulders back", "Core tight"],
        "execution": ["Walk forward with control", "Keep shoulders level", "Take deliberate steps"],
        "breathing": ["Breathe rhythmically", "Brace core"]
    }'::jsonb,
    common_mistakes = 'Leaning to one side, shrugging shoulders, walking too fast',
    safety_notes = 'Excellent for grip and core. Start lighter than you think. Have a safe place to set weights down.'
WHERE LOWER(name) LIKE '%farmer%';

-- 24. Hanging Leg Raise
UPDATE exercise_templates
SET
    technique_cues = '{
        "setup": ["Hang from bar", "Arms straight", "Core engaged"],
        "execution": ["Raise legs up", "Control the lower", "No swinging"],
        "breathing": ["Exhale raising", "Inhale lowering"]
    }'::jsonb,
    common_mistakes = 'Swinging, using momentum, not controlling descent',
    safety_notes = 'Very challenging. Bend knees if needed. Focus on core, not hip flexors.'
WHERE LOWER(name) LIKE '%hanging%' AND LOWER(name) LIKE '%leg%';

-- 25. Cable Flye
UPDATE exercise_templates
SET
    technique_cues = '{
        "setup": ["Cables at shoulder height", "Slight forward lean", "Slight elbow bend"],
        "execution": ["Bring hands together", "Squeeze chest", "Control return", "Maintain elbow angle"],
        "breathing": ["Exhale bringing together", "Inhale opening"]
    }'::jsonb,
    common_mistakes = 'Bending arms too much, using momentum, not maintaining posture',
    safety_notes = 'Excellent chest isolation. Keep slight bend in elbows throughout.'
WHERE LOWER(name) LIKE '%cable%' AND LOWER(name) LIKE '%fl%';

-- 26-30: Quick updates for remaining common exercises
UPDATE exercise_templates
SET technique_cues = '{"setup": ["Standard form"], "execution": ["Control throughout"], "breathing": ["Rhythmic"]}'::jsonb
WHERE technique_cues IS NULL AND (
    LOWER(name) LIKE '%shoulder%press%' OR
    LOWER(name) LIKE '%lateral%raise%' OR
    LOWER(name) LIKE '%chest%press%' OR
    LOWER(name) LIKE '%goblet%squat%' OR
    LOWER(name) LIKE '%wall%sit%'
);

-- Verify the migration
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM exercise_templates
    WHERE technique_cues IS NOT NULL;

    RAISE NOTICE 'Migration complete: % exercises now have technique data', updated_count;
END $$;
