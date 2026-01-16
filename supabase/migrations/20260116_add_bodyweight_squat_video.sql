-- Add video and technique data for Bodyweight Squat
-- Build 187 - Adding exercise details for AI substitutions

UPDATE exercise_templates
SET
    video_url = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    video_thumbnail_url = 'https://via.placeholder.com/640x360/28A745/FFFFFF?text=Bodyweight+Squat',
    video_duration = 60,
    technique_cues = '{
        "setup": [
            "Stand with feet shoulder-width apart",
            "Toes pointed slightly outward (15-30 degrees)",
            "Arms extended in front for balance or hands on hips",
            "Engage core and keep chest up",
            "Weight distributed evenly across feet"
        ],
        "execution": [
            "Initiate movement by pushing hips back",
            "Bend knees and lower until thighs are parallel to ground",
            "Keep knees tracking over toes",
            "Maintain neutral spine throughout",
            "Drive through heels to return to standing"
        ],
        "breathing": [
            "Inhale as you lower down",
            "Exhale as you push back up",
            "Maintain steady breathing rhythm"
        ]
    }'::jsonb,
    form_cues = '[
        {"cue": "Keep chest up and proud", "timestamp": 5},
        {"cue": "Push knees out over toes", "timestamp": 10},
        {"cue": "Go as deep as mobility allows", "timestamp": 15},
        {"cue": "Drive through heels to stand", "timestamp": 20}
    ]'::jsonb,
    common_mistakes = 'Knees caving inward. Heels lifting off ground. Rounding lower back. Not going deep enough. Leaning too far forward. Rushing the movement.',
    safety_notes = 'Start with partial range of motion if needed. Hold onto a sturdy object for balance if required. Stop if you feel knee or back pain. Progress depth gradually as mobility improves.'
WHERE id = '00000000-0000-0000-0000-000000000013';

-- Also add data for Hip Hinge (another common bodyweight substitution)
UPDATE exercise_templates
SET
    video_url = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    video_thumbnail_url = 'https://via.placeholder.com/640x360/FFC107/000000?text=Hip+Hinge',
    video_duration = 45,
    technique_cues = '{
        "setup": [
            "Stand with feet hip-width apart",
            "Slight bend in knees (soft knees)",
            "Hands on hips or arms crossed over chest",
            "Engage core muscles",
            "Maintain neutral spine"
        ],
        "execution": [
            "Push hips straight back like closing a car door",
            "Keep back flat as torso lowers",
            "Lower until you feel hamstring stretch",
            "Squeeze glutes to return to standing",
            "Keep weight in heels throughout"
        ],
        "breathing": [
            "Inhale as you hinge forward",
            "Exhale as you return to standing"
        ]
    }'::jsonb,
    form_cues = '[
        {"cue": "Push hips BACK, not down", "timestamp": 5},
        {"cue": "Keep back flat - no rounding", "timestamp": 10},
        {"cue": "Feel the stretch in hamstrings", "timestamp": 15}
    ]'::jsonb,
    common_mistakes = 'Rounding the lower back. Bending knees too much (turning it into a squat). Not pushing hips back far enough. Looking up and hyperextending neck.',
    safety_notes = 'Master this movement before progressing to deadlifts. Keep movements slow and controlled. Stop if you feel lower back strain.'
WHERE id = '00000000-0000-0000-0000-0000000000fe';

-- Add data for Prone Y Raise
UPDATE exercise_templates
SET
    video_url = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    video_thumbnail_url = 'https://via.placeholder.com/640x360/17A2B8/FFFFFF?text=Prone+Y+Raise',
    video_duration = 40,
    technique_cues = '{
        "setup": [
            "Lie face down on floor or bench",
            "Arms extended overhead in Y position",
            "Thumbs pointing up toward ceiling",
            "Forehead resting on floor or looking slightly forward",
            "Legs straight and relaxed"
        ],
        "execution": [
            "Squeeze shoulder blades together and down",
            "Lift arms off ground keeping Y shape",
            "Hold at top for 1-2 seconds",
            "Lower with control",
            "Keep neck in neutral position"
        ],
        "breathing": [
            "Exhale as you lift arms",
            "Inhale as you lower"
        ]
    }'::jsonb,
    form_cues = '[
        {"cue": "Thumbs up toward ceiling", "timestamp": 5},
        {"cue": "Squeeze shoulder blades together", "timestamp": 8},
        {"cue": "Keep neck relaxed", "timestamp": 12}
    ]'::jsonb,
    common_mistakes = 'Using momentum to lift arms. Shrugging shoulders toward ears. Lifting head and straining neck. Not squeezing shoulder blades.',
    safety_notes = 'Start with small range of motion. Focus on muscle activation over height. Great for shoulder health and posture.'
WHERE id = '00000000-0000-0000-0000-000000000b01';

-- Add data for Pike Push-Up
UPDATE exercise_templates
SET
    video_url = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    video_thumbnail_url = 'https://via.placeholder.com/640x360/DC3545/FFFFFF?text=Pike+Push-Up',
    video_duration = 50,
    technique_cues = '{
        "setup": [
            "Start in downward dog position",
            "Hands shoulder-width apart",
            "Hips pushed high toward ceiling",
            "Head between arms looking at feet",
            "Feet hip-width apart"
        ],
        "execution": [
            "Bend elbows and lower head toward ground",
            "Keep hips high throughout movement",
            "Touch head lightly to ground if possible",
            "Push through hands to return to start",
            "Keep core engaged throughout"
        ],
        "breathing": [
            "Inhale as you lower",
            "Exhale as you push up"
        ]
    }'::jsonb,
    form_cues = '[
        {"cue": "Keep hips high - dont let them drop", "timestamp": 5},
        {"cue": "Elbows point back, not out", "timestamp": 10},
        {"cue": "Head goes FORWARD of hands", "timestamp": 15}
    ]'::jsonb,
    common_mistakes = 'Letting hips drop (turns into regular push-up). Elbows flaring out wide. Not going deep enough. Rushing the movement.',
    safety_notes = 'Great progression toward handstand push-ups. Elevate hands on blocks to reduce difficulty. Stop if you feel shoulder impingement.'
WHERE id = '00000000-0000-0000-0000-0000000000ff';
