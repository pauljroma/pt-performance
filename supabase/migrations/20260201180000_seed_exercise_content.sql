-- =============================================================================
-- Seed Exercise Content: Populate why_this_exercise, target_muscles, explanations
-- =============================================================================

-- =============================================================================
-- 1. Update exercise_templates with why_this_exercise and muscle targeting
-- =============================================================================

-- Arm Care Exercises
UPDATE exercise_templates SET
    why_this_exercise = 'Internal rotation strength is crucial for decelerating the arm after throwing. This exercise builds the subscapularis muscle that protects your shoulder during the follow-through phase.',
    target_muscles = ARRAY['subscapularis', 'pectoralis major'],
    secondary_muscles = ARRAY['latissimus dorsi', 'teres major']
WHERE name = 'J-Band Internal Rotation';

UPDATE exercise_templates SET
    why_this_exercise = 'External rotation is the most important movement for throwing athletes. The infraspinatus and teres minor muscles control arm layback and protect against shoulder injuries.',
    target_muscles = ARRAY['infraspinatus', 'teres minor'],
    secondary_muscles = ARRAY['posterior deltoid', 'rhomboids']
WHERE name = 'J-Band External Rotation';

UPDATE exercise_templates SET
    why_this_exercise = 'This exercise isolates external rotation at 90 degrees of abduction - the exact position your arm is in during throwing. Building strength here directly transfers to pitching performance.',
    target_muscles = ARRAY['infraspinatus', 'teres minor'],
    secondary_muscles = ARRAY['posterior deltoid']
WHERE name = '90/90 External Rotation';

UPDATE exercise_templates SET
    why_this_exercise = 'The Y-T-W sequence activates all portions of the lower trapezius and serratus anterior - muscles critical for scapular stability during overhead motion.',
    target_muscles = ARRAY['lower trapezius', 'middle trapezius', 'serratus anterior'],
    secondary_muscles = ARRAY['rhomboids', 'posterior deltoid']
WHERE name = 'Prone Y-T-W';

UPDATE exercise_templates SET
    why_this_exercise = 'Scapular push-ups strengthen the serratus anterior, which is essential for proper scapular upward rotation during throwing.',
    target_muscles = ARRAY['serratus anterior'],
    secondary_muscles = ARRAY['pectoralis minor', 'core']
WHERE name = 'Scap Push-Ups';

UPDATE exercise_templates SET
    why_this_exercise = 'Forearm rotation strength helps control the ball at release and protects the elbow from excessive stress.',
    target_muscles = ARRAY['pronator teres', 'supinator'],
    secondary_muscles = ARRAY['brachioradialis', 'wrist flexors']
WHERE name = 'Forearm Pronation/Supination';

UPDATE exercise_templates SET
    why_this_exercise = 'Wrist strength is essential for ball control and preventing flexor-pronator strains - one of the most common pitcher injuries.',
    target_muscles = ARRAY['wrist flexors', 'wrist extensors'],
    secondary_muscles = ARRAY['finger flexors', 'forearm']
WHERE name = 'Wrist Flexion/Extension';

UPDATE exercise_templates SET
    why_this_exercise = 'Shoulder flexion mobility allows full arm extension during the throwing motion. Restrictions here force compensation elsewhere in the kinetic chain.',
    target_muscles = ARRAY['latissimus dorsi', 'pectoralis major'],
    secondary_muscles = ARRAY['teres major', 'triceps']
WHERE name = 'Shoulder Flexion Stretch';

UPDATE exercise_templates SET
    why_this_exercise = 'Hip mobility directly affects pitching mechanics. Tight hips limit stride length and force the arm to do more work, increasing injury risk.',
    target_muscles = ARRAY['hip internal rotators', 'hip external rotators'],
    secondary_muscles = ARRAY['glutes', 'piriformis']
WHERE name = 'Hip 90/90 Stretch';

-- =============================================================================
-- 2. Populate arm_care_education articles
-- =============================================================================

INSERT INTO arm_care_education (category, title, slug, summary, content, key_points, is_featured, sort_order)
VALUES
    ('anatomy', 'Understanding the Rotator Cuff', 'rotator-cuff-anatomy',
     'The four muscles that protect and move your throwing shoulder.',
     E'# The Rotator Cuff: Your Shoulder''s Foundation\n\nThe rotator cuff is a group of four muscles that surround the shoulder joint:\n\n## The Four Muscles\n\n### 1. Supraspinatus\nLocated on top of the shoulder blade, this muscle initiates arm elevation.\n\n### 2. Infraspinatus\nThe primary external rotator, located on the back of the shoulder blade.\n\n### 3. Teres Minor\nWorks with infraspinatus for external rotation.\n\n### 4. Subscapularis\nControls internal rotation and deceleration.\n\n## Why This Matters\n\nDuring a pitch, your arm rotates at over 7,000 degrees per second. The rotator cuff muscles must accelerate, stabilize, and decelerate the arm.',
     ARRAY['Four muscles: supraspinatus, infraspinatus, teres minor, subscapularis', 'Work together to stabilize and move the shoulder', 'Critical for throwing arm health'],
     true, 1),

    ('injury_prevention', 'The Throwers Ten: Essential Arm Care', 'throwers-ten-program',
     'A research-backed exercise protocol for preventing throwing injuries.',
     E'# The Throwers Ten Program\n\nDeveloped by Dr. Kevin Wilk and Dr. James Andrews, the Throwers Ten is the gold standard for arm care.\n\n## Key Exercises\n\n1. External Rotation at 0 and 90 degrees\n2. Internal Rotation at 0 and 90 degrees\n3. Shoulder Abduction to 90 degrees\n4. Scaption (Scapular Plane Elevation)\n5. Prone Horizontal Abduction\n6. Serratus Punches\n\n## When to Do It\n\n- Pre-season: 3x per week\n- In-season: 2x per week on non-throwing days',
     ARRAY['Research-backed injury prevention', 'Developed by leading sports medicine experts', 'Targets all critical throwing muscles'],
     true, 2),

    ('recovery', 'Post-Throwing Recovery Protocol', 'post-throwing-recovery',
     'What to do in the hours after pitching to optimize recovery.',
     E'# Recovery After Throwing\n\n## Immediately After (0-30 minutes)\n\n### Cool Down\n- Light jogging or bike for 5-10 minutes\n- Keeps blood flowing to flush metabolic waste\n\n### Gentle Stretching\n- Sleeper stretch: 30 seconds x 3\n- Cross-body stretch: 30 seconds x 3\n\n## 2-6 Hours After\n\n### Nutrition\n- Protein within 2 hours (20-30g)\n- Hydration: replace 150% of fluid lost\n\n## Next Day\n\n- Light throwing (catch play)\n- Full arm care routine at moderate intensity',
     ARRAY['Cool down immediately after throwing', 'Prioritize nutrition and hydration', 'Light movement promotes recovery'],
     true, 3),

    ('technique', 'Understanding Arm Slot and Injury Risk', 'arm-slot-injury-risk',
     'How your natural arm slot affects injury patterns and prevention strategies.',
     E'# Arm Slot and Injury Prevention\n\nYour arm slot influences which injuries you are most susceptible to.\n\n## High 3/4 to Overhand\n\n### Common Injuries\n- Superior labrum tears (SLAP)\n- Supraspinatus impingement\n\n### Prevention Focus\n- Thoracic spine mobility\n- Scapular upward rotation strength\n\n## Low 3/4 to Sidearm\n\n### Common Injuries\n- UCL tears (Tommy John)\n- Flexor-pronator strains\n\n### Prevention Focus\n- Wrist and forearm strengthening\n- Hip and core stability\n\n## Key Takeaway\n\nDont change your natural arm slot. Build the specific strength your arm slot demands.',
     ARRAY['Arm slot affects injury patterns', 'High slots stress the shoulder more', 'Low slots stress the elbow more'],
     false, 4),

    ('programming', 'Building Your Off-Season Arm Care Plan', 'offseason-arm-care-plan',
     'A 12-week framework for rebuilding arm strength before spring training.',
     E'# Off-Season Arm Care Blueprint\n\n## Phase 1: Foundation (Weeks 1-4)\n\n- Restore full range of motion\n- Arm care 4x per week\n- No throwing first 2 weeks\n\n## Phase 2: Strength (Weeks 5-8)\n\n- Build rotator cuff strength\n- Progress long toss distance weekly\n- Add weighted ball work (light)\n\n## Phase 3: Power (Weeks 9-12)\n\n- Convert strength to throwing power\n- Arm care 3x per week (maintenance)\n- Bullpen progression begins',
     ARRAY['Foundation before intensity', 'Progress throwing distance gradually', 'Power phase prepares for competition'],
     true, 5)

ON CONFLICT (slug) DO UPDATE SET
    summary = EXCLUDED.summary,
    content = EXCLUDED.content,
    key_points = EXCLUDED.key_points,
    is_featured = EXCLUDED.is_featured;

-- =============================================================================
-- 3. Verification
-- =============================================================================

DO $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count FROM exercise_templates WHERE why_this_exercise IS NOT NULL;
    RAISE NOTICE 'Exercise templates with why_this_exercise: %', v_count;

    SELECT COUNT(*) INTO v_count FROM arm_care_education;
    RAISE NOTICE 'Arm care education articles: %', v_count;
END $$;
