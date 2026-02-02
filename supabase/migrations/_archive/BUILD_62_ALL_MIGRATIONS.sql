-- Build 62: Patient Communication System (ACP-159)
-- Creates message_threads and messages tables with video support and real-time capabilities

-- Message threads table
CREATE TABLE IF NOT EXISTS message_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES therapists(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_message_at TIMESTAMPTZ,
    last_message_preview TEXT,
    last_message_type TEXT CHECK (last_message_type IN ('text', 'image', 'video', 'form_check')),

    -- Ensure one thread per patient-therapist pair
    UNIQUE(patient_id, therapist_id)
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES message_threads(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('patient', 'therapist')),
    message_type TEXT NOT NULL CHECK (message_type IN ('text', 'image', 'video', 'form_check')),
    content TEXT,
    video_url TEXT,
    image_url TEXT,
    video_duration INTEGER, -- seconds
    video_thumbnail TEXT,
    annotations JSONB, -- array of annotation objects
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at TIMESTAMPTZ,

    -- Validation constraints
    CONSTRAINT valid_content CHECK (
        CASE message_type
            WHEN 'text' THEN content IS NOT NULL
            WHEN 'video' THEN video_url IS NOT NULL
            WHEN 'form_check' THEN video_url IS NOT NULL
            WHEN 'image' THEN image_url IS NOT NULL
            ELSE false
        END
    )
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_message_threads_patient ON message_threads(patient_id);
CREATE INDEX IF NOT EXISTS idx_message_threads_therapist ON message_threads(therapist_id);
CREATE INDEX IF NOT EXISTS idx_message_threads_last_message ON message_threads(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_thread ON messages(thread_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(thread_id) WHERE read_at IS NULL;

-- Function to update thread's last message
CREATE OR REPLACE FUNCTION update_thread_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE message_threads
    SET
        last_message_at = NEW.created_at,
        last_message_preview = CASE
            WHEN NEW.message_type = 'text' THEN LEFT(NEW.content, 100)
            WHEN NEW.message_type = 'video' THEN 'Video message'
            WHEN NEW.message_type = 'form_check' THEN 'Form check video'
            WHEN NEW.message_type = 'image' THEN 'Image message'
            ELSE 'Message'
        END,
        last_message_type = NEW.message_type
    WHERE id = NEW.thread_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update thread on new message
DROP TRIGGER IF EXISTS trigger_update_thread_last_message ON messages;
CREATE TRIGGER trigger_update_thread_last_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_thread_last_message();

-- Function to get unread count for a thread
CREATE OR REPLACE FUNCTION get_thread_unread_count(
    p_thread_id UUID,
    p_user_id UUID,
    p_user_type TEXT
)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM messages
        WHERE thread_id = p_thread_id
            AND sender_id != p_user_id
            AND read_at IS NULL
    );
END;
$$ LANGUAGE plpgsql;

-- View for threads with unread counts (patient view)
CREATE OR REPLACE VIEW patient_message_threads AS
SELECT
    t.*,
    p.first_name || ' ' || p.last_name AS patient_name,
    th.first_name || ' ' || th.last_name AS therapist_name,
    (
        SELECT COUNT(*)
        FROM messages m
        WHERE m.thread_id = t.id
            AND m.sender_type = 'therapist'
            AND m.read_at IS NULL
    ) AS unread_count
FROM message_threads t
JOIN patients p ON t.patient_id = p.id
JOIN therapists th ON t.therapist_id = th.id;

-- View for threads with unread counts (therapist view)
CREATE OR REPLACE VIEW therapist_message_threads AS
SELECT
    t.*,
    p.first_name || ' ' || p.last_name AS patient_name,
    th.first_name || ' ' || th.last_name AS therapist_name,
    (
        SELECT COUNT(*)
        FROM messages m
        WHERE m.thread_id = t.id
            AND m.sender_type = 'patient'
            AND m.read_at IS NULL
    ) AS unread_count
FROM message_threads t
JOIN patients p ON t.patient_id = p.id
JOIN therapists th ON t.therapist_id = th.id;

-- RLS Policies

-- Enable RLS
ALTER TABLE message_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Message threads policies
-- Patients can view their own threads
CREATE POLICY "Patients can view their threads"
    ON message_threads FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE auth_user_id = auth.uid()
        )
    );

-- Therapists can view their threads
CREATE POLICY "Therapists can view their threads"
    ON message_threads FOR SELECT
    USING (
        therapist_id IN (
            SELECT id FROM therapists
            WHERE auth_user_id = auth.uid()
        )
    );

-- Patients can create threads with their therapist
CREATE POLICY "Patients can create threads with therapist"
    ON message_threads FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients
            WHERE auth_user_id = auth.uid()
        )
    );

-- Therapists can create threads with their patients
CREATE POLICY "Therapists can create threads with patients"
    ON message_threads FOR INSERT
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM therapists
            WHERE auth_user_id = auth.uid()
        )
    );

-- Messages policies
-- Patients can view messages in their threads
CREATE POLICY "Patients can view messages in their threads"
    ON messages FOR SELECT
    USING (
        thread_id IN (
            SELECT id FROM message_threads
            WHERE patient_id IN (
                SELECT id FROM patients
                WHERE auth_user_id = auth.uid()
            )
        )
    );

-- Therapists can view messages in their threads
CREATE POLICY "Therapists can view messages in their threads"
    ON messages FOR SELECT
    USING (
        thread_id IN (
            SELECT id FROM message_threads
            WHERE therapist_id IN (
                SELECT id FROM therapists
                WHERE auth_user_id = auth.uid()
            )
        )
    );

-- Patients can send messages in their threads
CREATE POLICY "Patients can send messages"
    ON messages FOR INSERT
    WITH CHECK (
        sender_type = 'patient'
        AND sender_id IN (
            SELECT id FROM patients
            WHERE auth_user_id = auth.uid()
        )
        AND thread_id IN (
            SELECT id FROM message_threads
            WHERE patient_id = sender_id
        )
    );

-- Therapists can send messages in their threads
CREATE POLICY "Therapists can send messages"
    ON messages FOR INSERT
    WITH CHECK (
        sender_type = 'therapist'
        AND sender_id IN (
            SELECT id FROM therapists
            WHERE auth_user_id = auth.uid()
        )
        AND thread_id IN (
            SELECT id FROM message_threads
            WHERE therapist_id = sender_id
        )
    );

-- Users can mark their received messages as read
CREATE POLICY "Users can mark messages as read"
    ON messages FOR UPDATE
    USING (
        -- Patients can mark therapist messages as read
        (sender_type = 'therapist' AND thread_id IN (
            SELECT id FROM message_threads
            WHERE patient_id IN (
                SELECT id FROM patients
                WHERE auth_user_id = auth.uid()
            )
        ))
        OR
        -- Therapists can mark patient messages as read
        (sender_type = 'patient' AND thread_id IN (
            SELECT id FROM message_threads
            WHERE therapist_id IN (
                SELECT id FROM therapists
                WHERE auth_user_id = auth.uid()
            )
        ))
    )
    WITH CHECK (
        -- Only allow updating read_at and annotations
        NEW.id = OLD.id
        AND NEW.thread_id = OLD.thread_id
        AND NEW.sender_id = OLD.sender_id
        AND NEW.sender_type = OLD.sender_type
        AND NEW.message_type = OLD.message_type
        AND NEW.content IS NOT DISTINCT FROM OLD.content
        AND NEW.video_url IS NOT DISTINCT FROM OLD.video_url
        AND NEW.image_url IS NOT DISTINCT FROM OLD.image_url
        AND NEW.created_at = OLD.created_at
    );

-- Therapists can add annotations to form check videos
CREATE POLICY "Therapists can annotate form check videos"
    ON messages FOR UPDATE
    USING (
        sender_type = 'patient'
        AND message_type = 'form_check'
        AND thread_id IN (
            SELECT id FROM message_threads
            WHERE therapist_id IN (
                SELECT id FROM therapists
                WHERE auth_user_id = auth.uid()
            )
        )
    )
    WITH CHECK (
        -- Only allow updating annotations
        NEW.id = OLD.id
        AND NEW.thread_id = OLD.thread_id
        AND NEW.sender_id = OLD.sender_id
        AND NEW.sender_type = OLD.sender_type
        AND NEW.message_type = OLD.message_type
        AND NEW.content IS NOT DISTINCT FROM OLD.content
        AND NEW.video_url IS NOT DISTINCT FROM OLD.video_url
        AND NEW.read_at IS NOT DISTINCT FROM OLD.read_at
        AND NEW.created_at = OLD.created_at
    );

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE message_threads;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON message_threads TO authenticated;
GRANT SELECT, INSERT, UPDATE ON messages TO authenticated;
GRANT SELECT ON patient_message_threads TO authenticated;
GRANT SELECT ON therapist_message_threads TO authenticated;

-- Comments for documentation
COMMENT ON TABLE message_threads IS 'Build 62: Message threads between therapists and patients';
COMMENT ON TABLE messages IS 'Build 62: Messages with support for text, images, and form check videos';
COMMENT ON COLUMN messages.annotations IS 'JSONB array of video annotations for form check feedback';
COMMENT ON FUNCTION update_thread_last_message() IS 'Updates thread last_message_at and preview when new message is sent';
COMMENT ON VIEW patient_message_threads IS 'Patient view of message threads with unread counts';
COMMENT ON VIEW therapist_message_threads IS 'Therapist view of message threads with unread counts';
-- Build 62: Create Exercise Video Library (ACP-160)
-- Comprehensive video library with categories, equipment tags, and 50+ seeded exercises

-- ============================================================================
-- 1. CREATE VIDEO CATEGORIES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS video_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    description TEXT,
    icon_name TEXT, -- SF Symbol name for iOS
    color_hex TEXT, -- Hex color code for category
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_video_categories_sort_order ON video_categories(sort_order);

-- Add comments
COMMENT ON TABLE video_categories IS 'Categories for organizing exercise videos (Upper Body, Lower Body, Core, etc.)';
COMMENT ON COLUMN video_categories.icon_name IS 'SF Symbol name for iOS display';
COMMENT ON COLUMN video_categories.color_hex IS 'Hex color code without # prefix';

-- ============================================================================
-- 2. CREATE EXERCISE-CATEGORY JUNCTION TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_video_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exercise_template_id UUID NOT NULL REFERENCES exercise_templates(id) ON DELETE CASCADE,
    video_category_id UUID NOT NULL REFERENCES video_categories(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(exercise_template_id, video_category_id)
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_exercise_video_categories_exercise ON exercise_video_categories(exercise_template_id);
CREATE INDEX IF NOT EXISTS idx_exercise_video_categories_category ON exercise_video_categories(video_category_id);

-- Add comments
COMMENT ON TABLE exercise_video_categories IS 'Many-to-many relationship between exercises and video categories';

-- ============================================================================
-- 3. ALTER EXERCISE_TEMPLATES TABLE
-- ============================================================================

-- Add new video-related columns
ALTER TABLE exercise_templates
ADD COLUMN IF NOT EXISTS video_file_size BIGINT, -- Size in bytes
ADD COLUMN IF NOT EXISTS video_thumbnail_timestamp INTEGER DEFAULT 3, -- Seconds into video for thumbnail
ADD COLUMN IF NOT EXISTS equipment_type TEXT, -- Equipment tag: barbell, dumbbell, bodyweight, machine, bands, cable
ADD COLUMN IF NOT EXISTS difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')), -- Difficulty level
ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT false, -- User favorite flag
ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0, -- Number of times viewed
ADD COLUMN IF NOT EXISTS download_count INTEGER DEFAULT 0; -- Number of times downloaded

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_exercise_templates_equipment ON exercise_templates(equipment_type);
CREATE INDEX IF NOT EXISTS idx_exercise_templates_difficulty ON exercise_templates(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_exercise_templates_favorites ON exercise_templates(is_favorite);
CREATE INDEX IF NOT EXISTS idx_exercise_templates_view_count ON exercise_templates(view_count DESC);

-- Add comments
COMMENT ON COLUMN exercise_templates.video_file_size IS 'Video file size in bytes for download management';
COMMENT ON COLUMN exercise_templates.video_thumbnail_timestamp IS 'Seconds into video to capture thumbnail';
COMMENT ON COLUMN exercise_templates.equipment_type IS 'Equipment category: barbell, dumbbell, bodyweight, machine, bands, cable';
COMMENT ON COLUMN exercise_templates.difficulty_level IS 'Difficulty level: beginner, intermediate, advanced';

-- ============================================================================
-- 4. SEED VIDEO CATEGORIES
-- ============================================================================

-- Insert main body region categories
INSERT INTO video_categories (name, display_name, description, icon_name, color_hex, sort_order) VALUES
('upper_body', 'Upper Body', 'Push, pull, and shoulder exercises', 'figure.arms.open', '007AFF', 1),
('lower_body', 'Lower Body', 'Squat, hinge, and lunge patterns', 'figure.walk', '34C759', 2),
('core', 'Core & Stability', 'Anti-rotation, anti-extension, and rotation', 'figure.core.training', 'FF9500', 3),
('accessories', 'Accessories & Mobility', 'Warm-up, cooldown, and mobility work', 'figure.flexibility', 'AF52DE', 4)
ON CONFLICT (name) DO NOTHING;

-- Insert equipment-based categories
INSERT INTO video_categories (name, display_name, description, icon_name, color_hex, sort_order) VALUES
('barbell', 'Barbell', 'Barbell exercises', 'figure.strengthtraining.traditional', 'FF3B30', 5),
('dumbbell', 'Dumbbell', 'Dumbbell exercises', 'dumbbell.fill', 'FF9500', 6),
('bodyweight', 'Bodyweight', 'No equipment needed', 'figure.stand', '34C759', 7),
('machine', 'Machine', 'Machine-based exercises', 'gearshape.fill', '5856D6', 8),
('bands', 'Bands & Cables', 'Resistance bands and cable exercises', 'cable.connector', '007AFF', 9)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 5. SEED 50+ EXERCISE VIDEOS
-- ============================================================================

-- Note: video_url uses placeholder values - replace with actual Supabase Storage URLs
-- Video format: MP4 (H.264), 1080p, 30-90 seconds, 5-15MB
-- Videos should be uploaded to Supabase Storage bucket: exercise-videos/

-- UPPER BODY - PUSH (8 exercises)

-- 1. Bench Press
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_thumbnail_url, video_duration, video_file_size, video_thumbnail_timestamp,
    equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Barbell Bench Press',
    'push',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/bench-press.mp4',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/thumbnails/bench-press.jpg',
    65,
    8500000,
    5,
    'barbell',
    'intermediate',
    '{"setup": ["Lie with eyes under bar", "Feet flat on floor", "Squeeze shoulder blades together", "Slight arch in lower back", "Grip slightly wider than shoulders"], "execution": ["Unrack with straight arms", "Lower bar to chest with control", "Elbows at 45-degree angle", "Bar touches chest", "Press straight up", "Keep shoulder blades pinched"], "breathing": ["Breathe in as you lower bar", "Hold breath at bottom", "Exhale as you press up"]}'::jsonb,
    'Elbows flaring out to 90 degrees, bouncing bar off chest, losing shoulder blade retraction, feet off ground, uneven bar path',
    'Always use a spotter for heavy weights or work in a power rack with safety pins. Keep wrists straight. Stop if you feel shoulder pain.'
) ON CONFLICT (name) DO UPDATE SET
    video_url = EXCLUDED.video_url,
    video_duration = EXCLUDED.video_duration,
    video_file_size = EXCLUDED.video_file_size,
    equipment_type = EXCLUDED.equipment_type,
    difficulty_level = EXCLUDED.difficulty_level;

-- 2. Incline Dumbbell Press
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Incline Dumbbell Press',
    'push',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/incline-db-press.mp4',
    55,
    7200000,
    'dumbbell',
    'beginner',
    '{"setup": ["Bench at 30-45 degree incline", "Dumbbells at shoulder level", "Feet flat", "Back against bench"], "execution": ["Press dumbbells up and slightly together", "Lower with control", "Elbows at 45 degrees", "Full range of motion"], "breathing": ["Inhale lowering", "Exhale pressing"]}'::jsonb,
    'Bench too steep, flaring elbows, arching back off bench',
    'Great for upper chest development. Keep core engaged.'
) ON CONFLICT (name) DO NOTHING;

-- 3. Overhead Press
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Barbell Overhead Press',
    'push',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/overhead-press.mp4',
    60,
    8000000,
    'barbell',
    'intermediate',
    '{"setup": ["Bar at collarbone level", "Grip just outside shoulders", "Elbows slightly in front of bar", "Feet hip-width", "Core tight"], "execution": ["Press bar straight up", "Move head back slightly", "Lock out overhead", "Shrug shoulders at top", "Lower under control", "Bar path straight"], "breathing": ["Breathe in before press", "Hold through press", "Exhale at lockout"]}'::jsonb,
    'Leaning back excessively, not getting head through, pressing forward instead of up, losing core tension',
    'Keep core extremely tight to protect lower back. Do not hyperextend spine.'
) ON CONFLICT (name) DO NOTHING;

-- 4. Dumbbell Shoulder Press
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Seated Dumbbell Shoulder Press',
    'push',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/db-shoulder-press.mp4',
    50,
    6800000,
    'dumbbell',
    'beginner',
    '{"setup": ["Sit upright", "Dumbbells at shoulder height", "Elbows at 90 degrees", "Core engaged"], "execution": ["Press dumbbells overhead", "Keep core tight", "Control descent", "Palms forward"], "breathing": ["Exhale pressing up", "Inhale lowering"]}'::jsonb,
    'Arching back, pressing forward, locking out too hard',
    'Seated version protects lower back better than standing.'
) ON CONFLICT (name) DO NOTHING;

-- 5. Push-ups
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Push-up',
    'push',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/pushup.mp4',
    45,
    6000000,
    'bodyweight',
    'beginner',
    '{"setup": ["Hands shoulder-width apart", "Body in straight line", "Core tight", "Feet together"], "execution": ["Lower chest to ground", "Elbows at 45 degrees", "Keep body straight", "Push through full range", "Lock out at top"], "breathing": ["Breathe in going down", "Exhale pushing up"]}'::jsonb,
    'Hips sagging, hips piked up, not going to full depth, flaring elbows out, head dropping',
    'Modify on knees or with hands elevated if needed. Keep wrists straight.'
) ON CONFLICT (name) DO NOTHING;

-- 6. Dips
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Parallel Bar Dips',
    'push',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/dips.mp4',
    50,
    6500000,
    'bodyweight',
    'intermediate',
    '{"setup": ["Hands on parallel bars", "Arms locked out", "Slight forward lean", "Legs bent or straight"], "execution": ["Lower until elbows at 90 degrees", "Keep elbows close", "Press back up", "Lock out at top", "Control the descent"], "breathing": ["Breathe in going down", "Exhale pressing up"]}'::jsonb,
    'Going too deep, flaring elbows out, shrugging shoulders, not locking out, swinging legs',
    'Stop at 90 degrees of elbow flexion unless you have excellent shoulder mobility.'
) ON CONFLICT (name) DO NOTHING;

-- 7. Landmine Press
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Single-Arm Landmine Press',
    'push',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/landmine-press.mp4',
    55,
    7000000,
    'barbell',
    'intermediate',
    '{"setup": ["Stand with staggered stance", "Bar at shoulder", "Core braced", "Other hand on hip"], "execution": ["Press bar up and forward", "Rotate torso slightly", "Full extension", "Control descent"], "breathing": ["Exhale pressing", "Inhale lowering"]}'::jsonb,
    'Too much rotation, leaning back, not pressing in arc',
    'Excellent shoulder-friendly pressing variation.'
) ON CONFLICT (name) DO NOTHING;

-- 8. Cable Chest Fly
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Cable Chest Fly',
    'push',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/cable-fly.mp4',
    50,
    6600000,
    'cable',
    'beginner',
    '{"setup": ["Cables at shoulder height", "Slight forward lean", "Slight elbow bend"], "execution": ["Bring hands together", "Squeeze chest", "Control return", "Maintain elbow angle"], "breathing": ["Exhale bringing together", "Inhale opening"]}'::jsonb,
    'Bending arms too much, using momentum, not maintaining posture',
    'Excellent chest isolation. Keep slight bend in elbows throughout.'
) ON CONFLICT (name) DO NOTHING;

-- UPPER BODY - PULL (7 exercises)

-- 9. Pull-ups
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Pull-up',
    'pull',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/pullup.mp4',
    55,
    7300000,
    'bodyweight',
    'advanced',
    '{"setup": ["Hang from bar", "Hands slightly wider than shoulders", "Full arm extension", "Engage lats", "Feet together or crossed"], "execution": ["Pull elbows down and back", "Lead with chest", "Chin over bar", "Lower with control", "Full arm extension at bottom"], "breathing": ["Breathe in during descent", "Exhale during pull"]}'::jsonb,
    'Kipping or swinging, not going to full extension, pulling with arms instead of back, shrugging shoulders up',
    'Build up gradually. Use assistance bands if needed. Stop if you feel shoulder or elbow pain.'
) ON CONFLICT (name) DO NOTHING;

-- 10. Barbell Row
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Barbell Bent-Over Row',
    'pull',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/barbell-row.mp4',
    60,
    7800000,
    'barbell',
    'intermediate',
    '{"setup": ["Hip hinge position", "Back flat, nearly parallel to floor", "Arms straight hanging", "Grip slightly wider than shoulders", "Core braced"], "execution": ["Pull bar to lower chest/upper abdomen", "Lead with elbows", "Squeeze shoulder blades", "Lower under control", "Maintain back position"], "breathing": ["Breathe in during pull", "Exhale during lower"]}'::jsonb,
    'Standing too upright, using momentum, not maintaining back position, pulling to chest instead of abdomen',
    'Keep back flat throughout. Use straps for heavy loads to reduce grip fatigue.'
) ON CONFLICT (name) DO NOTHING;

-- 11. Lat Pulldown
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Lat Pulldown',
    'pull',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/lat-pulldown.mp4',
    50,
    6700000,
    'machine',
    'beginner',
    '{"setup": ["Knees secured under pad", "Hands wide on bar", "Sit upright", "Slight lean back"], "execution": ["Pull bar to upper chest", "Lead with elbows", "Squeeze shoulder blades", "Control the return", "Full arm extension at top"], "breathing": ["Breathe out during pull", "Breathe in during return"]}'::jsonb,
    'Pulling behind neck, leaning back too much, using momentum, not going to full extension',
    'Always pull to front, never behind neck. Keep core engaged.'
) ON CONFLICT (name) DO NOTHING;

-- 12. Seated Cable Row
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Seated Cable Row',
    'pull',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/cable-row.mp4',
    55,
    7100000,
    'cable',
    'beginner',
    '{"setup": ["Sit at cable machine", "Feet on platform", "Slight knee bend", "Upright torso", "Arms extended"], "execution": ["Pull handle to lower chest", "Lead with elbows", "Squeeze shoulder blades", "Keep torso stable", "Extend arms fully"], "breathing": ["Exhale during pull", "Inhale during extension"]}'::jsonb,
    'Using momentum, leaning back excessively, shrugging shoulders, not squeezing shoulder blades',
    'Keep torso mostly upright with minimal movement. Control the weight throughout.'
) ON CONFLICT (name) DO NOTHING;

-- 13. Face Pull
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Cable Face Pull',
    'pull',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/face-pull.mp4',
    45,
    6200000,
    'cable',
    'beginner',
    '{"setup": ["Cable at face height", "Rope attachment", "Step back with tension", "Upright posture"], "execution": ["Pull rope toward face", "Hands go past ears", "Elbows high", "Squeeze rear delts", "Control the return"], "breathing": ["Exhale during pull", "Inhale during return"]}'::jsonb,
    'Pulling too low, not getting hands past face, elbows dropping, using too much weight',
    'Great for shoulder health. Use moderate weight and focus on form.'
) ON CONFLICT (name) DO NOTHING;

-- 14. Dumbbell Row
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Single-Arm Dumbbell Row',
    'pull',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/db-row.mp4',
    50,
    6500000,
    'dumbbell',
    'beginner',
    '{"setup": ["One knee and hand on bench", "Back flat", "Dumbbell in free hand", "Core braced"], "execution": ["Pull dumbbell to hip", "Lead with elbow", "Squeeze at top", "Lower with control"], "breathing": ["Exhale pulling up", "Inhale lowering"]}'::jsonb,
    'Rotating torso, using momentum, not pulling to hip',
    'Excellent for unilateral back development and core stability.'
) ON CONFLICT (name) DO NOTHING;

-- 15. Inverted Row
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Inverted Row',
    'pull',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/inverted-row.mp4',
    50,
    6400000,
    'bodyweight',
    'intermediate',
    '{"setup": ["Bar at waist height", "Hang underneath", "Body straight", "Heels on ground"], "execution": ["Pull chest to bar", "Keep body straight", "Squeeze shoulder blades", "Lower with control"], "breathing": ["Exhale pulling up", "Inhale lowering"]}'::jsonb,
    'Hips sagging, not pulling chest to bar, bending at hips',
    'Great alternative to pull-ups. Adjust difficulty by changing bar height.'
) ON CONFLICT (name) DO NOTHING;

-- LOWER BODY - SQUAT & HINGE (8 exercises)

-- 16. Back Squat
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Barbell Back Squat',
    'squat',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/back-squat.mp4',
    70,
    9000000,
    'barbell',
    'intermediate',
    '{"setup": ["Feet shoulder-width apart", "Bar resting on upper traps", "Hands gripping bar slightly wider than shoulders", "Core braced, chest up", "Eyes looking slightly down and forward"], "execution": ["Push knees out slightly as you descend", "Hips move back and down simultaneously", "Keep chest up and maintain neutral spine", "Descend until thighs are parallel or below", "Drive through heels to stand up", "Keep core tight throughout"], "breathing": ["Take a deep breath in at the top", "Hold breath during descent", "Maintain breath hold through bottom", "Exhale as you complete the lift"]}'::jsonb,
    'Knees caving inward (valgus collapse), excessive forward lean, not reaching proper depth, rising onto toes, losing core tension',
    'Keep spine neutral throughout movement. Stop immediately if you feel sharp pain in knees or lower back. Use safety bars or spotter for heavy loads.'
) ON CONFLICT (name) DO NOTHING;

-- 17. Front Squat
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Barbell Front Squat',
    'squat',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/front-squat.mp4',
    65,
    8400000,
    'barbell',
    'advanced',
    '{"setup": ["Bar rests on front deltoids", "Elbows high, upper arms parallel to floor", "Fingertips under bar or arms crossed", "Feet shoulder-width apart", "Core tight"], "execution": ["Keep elbows high throughout", "Descend straight down", "Chest stays upright", "Drive through full foot", "Stand up maintaining elbow position"], "breathing": ["Breathe in deeply before descent", "Hold breath through bottom", "Exhale near top"]}'::jsonb,
    'Dropping elbows, excessive forward lean, heels lifting off ground, losing bar off shoulders',
    'Front squats are generally safer for the lower back than back squats. Drop the bar forward if you lose position.'
) ON CONFLICT (name) DO NOTHING;

-- 18. Goblet Squat
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Goblet Squat',
    'squat',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/goblet-squat.mp4',
    45,
    6100000,
    'dumbbell',
    'beginner',
    '{"setup": ["Hold dumbbell at chest", "Elbows pointing down", "Feet shoulder-width", "Toes slightly out"], "execution": ["Squat down between legs", "Keep chest up", "Elbows track inside knees", "Full depth", "Drive through heels"], "breathing": ["Inhale descending", "Exhale driving up"]}'::jsonb,
    'Heels lifting, not going deep enough, leaning forward',
    'Excellent teaching tool for squat pattern. Very safe.'
) ON CONFLICT (name) DO NOTHING;

-- 19. Deadlift
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Conventional Deadlift',
    'hinge',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/deadlift.mp4',
    70,
    9200000,
    'barbell',
    'advanced',
    '{"setup": ["Feet hip-width under bar", "Bar over mid-foot", "Grip just outside legs", "Shoulders over or slightly in front of bar", "Chest up, back flat", "Arms straight"], "execution": ["Push floor away with legs", "Bar stays close to body", "Hips and shoulders rise together", "Full hip extension at top", "Reverse movement under control"], "breathing": ["Deep breath before lift", "Hold breath during pull", "Exhale at top or during descent"]}'::jsonb,
    'Rounding lower back, bar drifting away from body, hitching at top, dropping bar on descent, starting with hips too high or low',
    'CRITICAL: Keep neutral spine throughout. Never round your lower back. Use a belt for heavy loads. Stop if you feel lower back pain.'
) ON CONFLICT (name) DO NOTHING;

-- 20. Romanian Deadlift (RDL)
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Romanian Deadlift (RDL)',
    'hinge',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/rdl.mp4',
    55,
    7400000,
    'barbell',
    'intermediate',
    '{"setup": ["Start standing with bar at hips", "Feet hip-width", "Slight knee bend", "Shoulders back", "Grip just outside legs"], "execution": ["Push hips back", "Bar slides down thighs", "Feel hamstring stretch", "Keep back flat", "Reverse by driving hips forward", "Small knee bend throughout"], "breathing": ["Breathe in during descent", "Exhale driving up"]}'::jsonb,
    'Squatting instead of hinging, rounding back, bending knees too much, bar drifting away from legs',
    'Focus on hip hinge pattern. Keep weight moderate. Excellent for hamstring development.'
) ON CONFLICT (name) DO NOTHING;

-- 21. Hip Thrust
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Barbell Hip Thrust',
    'hinge',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/hip-thrust.mp4',
    55,
    7200000,
    'barbell',
    'intermediate',
    '{"setup": ["Upper back on bench", "Bar over hips with pad", "Feet flat, hip-width", "Knees bent 90 degrees"], "execution": ["Drive through heels", "Squeeze glutes hard at top", "Hips fully extended", "Lower under control", "Keep chin tucked"], "breathing": ["Exhale at top", "Inhale during lower"]}'::jsonb,
    'Hyperextending lower back, not achieving full hip extension, feet too close or far, not squeezing glutes',
    'Use a bar pad to prevent bruising. Keep ribs down and core engaged. Focus on glute squeeze.'
) ON CONFLICT (name) DO NOTHING;

-- 22. Leg Press
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Leg Press',
    'squat',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/leg-press.mp4',
    50,
    6800000,
    'machine',
    'beginner',
    '{"setup": ["Back flat against pad", "Feet shoulder-width on platform", "Feet mid-platform", "Hands on handles"], "execution": ["Lower platform with control", "Knees track over toes", "Stop before lower back lifts", "Press through full foot", "Do not lock knees fully at top"], "breathing": ["Breathe in during descent", "Exhale during press"]}'::jsonb,
    'Lower back lifting off pad, locking knees out hard, going too deep, feet too high or low on platform',
    'Keep lower back pressed against pad at all times. Use safety stops. Do not lock out knees forcefully.'
) ON CONFLICT (name) DO NOTHING;

-- 23. Bulgarian Split Squat
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Bulgarian Split Squat',
    'lunge',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/bulgarian-split-squat.mp4',
    55,
    7100000,
    'dumbbell',
    'intermediate',
    '{"setup": ["Back foot elevated on bench", "Front foot forward", "Upright torso", "Dumbbells in hands"], "execution": ["Lower back knee down", "Keep front shin vertical", "Drive through front heel", "Full range of motion"], "breathing": ["Inhale down", "Exhale up"]}'::jsonb,
    'Front foot too close, leaning forward, not going deep enough, knee caving in',
    'Excellent single-leg exercise. Start with bodyweight. Very challenging but safe.'
) ON CONFLICT (name) DO NOTHING;

-- LOWER BODY - LUNGES & ACCESSORIES (7 exercises)

-- 24. Walking Lunges
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Walking Lunge',
    'lunge',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/walking-lunge.mp4',
    50,
    6700000,
    'dumbbell',
    'beginner',
    '{"setup": ["Stand with feet hip-width", "Core engaged", "Chest up", "Dumbbells at sides"], "execution": ["Step forward with one leg", "Lower back knee toward ground", "Front knee stays over ankle", "Push through front heel to next step"], "breathing": ["Breathe in during descent", "Exhale during drive up"]}'::jsonb,
    'Front knee going past toes excessively, back knee slamming into ground, leaning forward, losing balance',
    'Start with bodyweight. Keep front shin vertical. Use shorter steps if you have knee issues.'
) ON CONFLICT (name) DO NOTHING;

-- 25. Step-ups
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Box Step-up',
    'lunge',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/step-up.mp4',
    45,
    6300000,
    'bodyweight',
    'beginner',
    '{"setup": ["Stand facing box or bench", "Height at or below knee", "Chest up"], "execution": ["Step up with one foot", "Drive through heel", "Stand fully on box", "Step down controlled", "Alternate legs"], "breathing": ["Exhale stepping up", "Inhale stepping down"]}'::jsonb,
    'Using momentum, pushing off back leg, box too high, knee caving in',
    'Start with lower box height. Keep knee tracking over toes. Excellent for balance.'
) ON CONFLICT (name) DO NOTHING;

-- 26. Leg Curl
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Lying Leg Curl',
    'accessory',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/leg-curl.mp4',
    45,
    6100000,
    'machine',
    'beginner',
    '{"setup": ["Lie face down", "Knees just off pad edge", "Ankles behind pad", "Hold handles"], "execution": ["Curl heels toward glutes", "Squeeze hamstrings at top", "Lower under control", "Keep hips on pad"], "breathing": ["Exhale during curl", "Inhale during lower"]}'::jsonb,
    'Hips lifting off pad, using momentum, not curling to full range, feet/toes pointing out',
    'Use smooth controlled motion. Do not jerk the weight. Keep toes pointed toward shins.'
) ON CONFLICT (name) DO NOTHING;

-- 27. Leg Extension
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Leg Extension',
    'accessory',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/leg-extension.mp4',
    40,
    5800000,
    'machine',
    'beginner',
    '{"setup": ["Sit in machine", "Back against pad", "Ankles behind pad", "Knees aligned with pivot"], "execution": ["Extend legs fully", "Squeeze quads at top", "Lower with control", "Do not slam weight down"], "breathing": ["Exhale extending", "Inhale lowering"]}'::jsonb,
    'Using momentum, partial range of motion, lifting butt off seat',
    'Controversial exercise for knee health. Use moderate weight and control.'
) ON CONFLICT (name) DO NOTHING;

-- 28. Calf Raise
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Standing Calf Raise',
    'accessory',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/calf-raise.mp4',
    40,
    5600000,
    'machine',
    'beginner',
    '{"setup": ["Balls of feet on platform", "Heels hanging off", "Shoulders under pads", "Legs straight"], "execution": ["Lower heels below platform", "Push up onto toes", "Full contraction at top", "Control descent"], "breathing": ["Exhale rising", "Inhale lowering"]}'::jsonb,
    'Bouncing at bottom, not going through full range, bending knees',
    'Full range of motion is key. Pause at top and bottom.'
) ON CONFLICT (name) DO NOTHING;

-- 29. Glute Bridge
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Glute Bridge',
    'hinge',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/glute-bridge.mp4',
    40,
    5500000,
    'bodyweight',
    'beginner',
    '{"setup": ["Lie on back", "Feet flat near glutes", "Arms at sides", "Knees bent"], "execution": ["Drive through heels", "Lift hips up", "Squeeze glutes at top", "Lower with control"], "breathing": ["Exhale lifting", "Inhale lowering"]}'::jsonb,
    'Not squeezing glutes, hyperextending back, not achieving full hip extension',
    'Great activation exercise. Perfect for beginners or warm-up.'
) ON CONFLICT (name) DO NOTHING;

-- 30. Nordic Hamstring Curl
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Nordic Hamstring Curl',
    'hinge',
    'lower',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/nordic-curl.mp4',
    50,
    6600000,
    'bodyweight',
    'advanced',
    '{"setup": ["Kneel with ankles secured", "Body straight from knees up", "Arms ready to catch"], "execution": ["Lean forward slowly", "Keep body straight", "Use hamstrings to control", "Catch with hands", "Push back up"], "breathing": ["Inhale descending", "Exhale pushing back"]}'::jsonb,
    'Hinging at hips, going too fast, not using full range',
    'Extremely challenging. Excellent for hamstring strength and injury prevention.'
) ON CONFLICT (name) DO NOTHING;

-- CORE & STABILITY (10 exercises)

-- 31. Plank
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Front Plank',
    'anti_extension',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/plank.mp4',
    40,
    5700000,
    'bodyweight',
    'beginner',
    '{"setup": ["Forearms on ground", "Elbows under shoulders", "Body in straight line", "Feet hip-width"], "execution": ["Squeeze glutes", "Brace core hard", "Hold position", "Breathe steadily", "Do not let hips sag or pike"], "breathing": ["Breathe normally", "Do not hold breath", "Maintain core tension"]}'::jsonb,
    'Hips sagging toward ground, hips too high, holding breath, looking up instead of down, not engaging glutes',
    'Start with shorter holds (20-30 seconds) and build up. Stop if you feel lower back pain.'
) ON CONFLICT (name) DO NOTHING;

-- 32. Side Plank
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Side Plank',
    'anti_lateral_flexion',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/side-plank.mp4',
    40,
    5600000,
    'bodyweight',
    'intermediate',
    '{"setup": ["Lie on side", "Elbow under shoulder", "Feet stacked", "Body straight"], "execution": ["Lift hips off ground", "Keep body in straight line", "Squeeze obliques", "Hold position"], "breathing": ["Breathe steadily", "Maintain tension"]}'::jsonb,
    'Hips sagging, rotating forward or back, not stacking feet',
    'Excellent for obliques and stability. Modify on knees if needed.'
) ON CONFLICT (name) DO NOTHING;

-- 33. Pallof Press
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Pallof Press',
    'anti_rotation',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/pallof-press.mp4',
    45,
    6200000,
    'cable',
    'beginner',
    '{"setup": ["Cable at chest height", "Stand sideways to cable", "Hold handle at chest", "Feet shoulder-width"], "execution": ["Press handle straight out", "Resist rotation", "Hold extended position", "Return to chest", "Keep core tight"], "breathing": ["Exhale pressing out", "Inhale returning"]}'::jsonb,
    'Rotating toward cable, not fully extending, using momentum, stance too narrow',
    'Excellent anti-rotation exercise. Start with light weight to master pattern.'
) ON CONFLICT (name) DO NOTHING;

-- 34. Dead Bug
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Dead Bug',
    'anti_extension',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/dead-bug.mp4',
    45,
    6000000,
    'bodyweight',
    'beginner',
    '{"setup": ["Lie on back", "Arms extended up", "Knees bent 90 degrees", "Lower back pressed to floor"], "execution": ["Extend opposite arm and leg", "Keep lower back pressed down", "Return and alternate", "Move slowly and controlled"], "breathing": ["Exhale extending", "Inhale returning"]}'::jsonb,
    'Lower back arching off floor, moving too fast, not coordinating opposite limbs',
    'Fundamental core stability exercise. Master this before progressing to harder exercises.'
) ON CONFLICT (name) DO NOTHING;

-- 35. Bird Dog
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Bird Dog',
    'anti_rotation',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/bird-dog.mp4',
    45,
    6100000,
    'bodyweight',
    'beginner',
    '{"setup": ["Start on hands and knees", "Hands under shoulders", "Knees under hips", "Neutral spine"], "execution": ["Extend opposite arm and leg", "Keep hips level", "Hold briefly", "Return and alternate", "No rotation"], "breathing": ["Breathe steadily", "Do not hold breath"]}'::jsonb,
    'Rotating hips, arching back, not extending fully, moving too fast',
    'Excellent for back health and stability. Focus on not rotating.'
) ON CONFLICT (name) DO NOTHING;

-- 36. Russian Twist
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Russian Twist',
    'rotation',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/russian-twist.mp4',
    45,
    6300000,
    'dumbbell',
    'intermediate',
    '{"setup": ["Sit with knees bent", "Lean back slightly", "Feet off ground", "Hold weight at chest"], "execution": ["Rotate torso side to side", "Touch weight to ground each side", "Keep core engaged", "Controlled movement"], "breathing": ["Breathe steadily throughout"]}'::jsonb,
    'Moving too fast, not rotating from torso, feet on ground, rounding back',
    'Popular but controversial. Keep movement controlled. Stop if lower back hurts.'
) ON CONFLICT (name) DO NOTHING;

-- 37. Hanging Leg Raise
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Hanging Leg Raise',
    'anti_extension',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/hanging-leg-raise.mp4',
    50,
    6700000,
    'bodyweight',
    'advanced',
    '{"setup": ["Hang from bar", "Arms straight", "Core engaged", "Legs together"], "execution": ["Raise legs up", "Control the lower", "No swinging", "Full range"], "breathing": ["Exhale raising", "Inhale lowering"]}'::jsonb,
    'Swinging, using momentum, not controlling descent, using hip flexors only',
    'Very challenging. Bend knees if needed. Focus on core, not hip flexors.'
) ON CONFLICT (name) DO NOTHING;

-- 38. Ab Wheel Rollout
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Ab Wheel Rollout',
    'anti_extension',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/ab-wheel.mp4',
    45,
    6200000,
    'equipment',
    'advanced',
    '{"setup": ["Kneel with wheel in hands", "Arms straight", "Core braced"], "execution": ["Roll wheel forward", "Keep core tight", "Do not let hips sag", "Pull back to start"], "breathing": ["Inhale rolling out", "Exhale pulling back"]}'::jsonb,
    'Hips sagging, hyperextending back, going too far, not bracing core',
    'Very challenging for core. Start with short range. Stop if you feel back pain.'
) ON CONFLICT (name) DO NOTHING;

-- 39. Cable Crunch
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Cable Crunch',
    'flexion',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/cable-crunch.mp4',
    40,
    5800000,
    'cable',
    'beginner',
    '{"setup": ["Kneel facing cable machine", "Hold rope behind head", "Cable high position"], "execution": ["Crunch down and forward", "Squeeze abs", "Control the return", "Do not pull with arms"], "breathing": ["Exhale crunching", "Inhale returning"]}'::jsonb,
    'Pulling with arms, not using abs, going too heavy, incomplete range',
    'Good for weighted ab work. Focus on ab contraction, not weight moved.'
) ON CONFLICT (name) DO NOTHING;

-- 40. Mountain Climbers
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Mountain Climbers',
    'dynamic_core',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/mountain-climbers.mp4',
    40,
    5900000,
    'bodyweight',
    'intermediate',
    '{"setup": ["Start in push-up position", "Arms straight", "Core engaged"], "execution": ["Drive knees to chest alternating", "Keep hips down", "Maintain plank position", "Rhythmic movement"], "breathing": ["Breathe steadily throughout"]}'::jsonb,
    'Hips too high, not bringing knees far enough, losing plank position',
    'Great cardio and core combination. Start slow and build speed.'
) ON CONFLICT (name) DO NOTHING;

-- ACCESSORIES & MOBILITY (10 exercises)

-- 41. Bicep Curl
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Dumbbell Bicep Curl',
    'accessory',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/bicep-curl.mp4',
    40,
    5700000,
    'dumbbell',
    'beginner',
    '{"setup": ["Stand with feet hip-width", "Arms at sides holding dumbbells", "Elbows close to body", "Palms forward"], "execution": ["Curl weights up", "Keep elbows stationary", "Squeeze at top", "Lower under control", "Full arm extension at bottom"], "breathing": ["Exhale during curl", "Inhale during lower"]}'::jsonb,
    'Swinging body, moving elbows forward, not going through full range, using momentum',
    'Keep elbows locked in position. Use weight you can control. Focus on bicep contraction.'
) ON CONFLICT (name) DO NOTHING;

-- 42. Tricep Pushdown
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Cable Tricep Pushdown',
    'accessory',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/tricep-pushdown.mp4',
    40,
    5600000,
    'cable',
    'beginner',
    '{"setup": ["Stand facing cable machine", "Bar or rope at chest height", "Elbows at sides", "Slight lean forward"], "execution": ["Push down to full extension", "Keep elbows stationary", "Squeeze triceps", "Control the return"], "breathing": ["Exhale pushing down", "Inhale returning"]}'::jsonb,
    'Moving elbows, using momentum, leaning too far forward, not fully extending',
    'Excellent tricep isolation. Keep elbows locked to sides.'
) ON CONFLICT (name) DO NOTHING;

-- 43. Lateral Raise
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Dumbbell Lateral Raise',
    'accessory',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/lateral-raise.mp4',
    40,
    5800000,
    'dumbbell',
    'beginner',
    '{"setup": ["Stand with dumbbells at sides", "Slight elbow bend", "Core engaged"], "execution": ["Raise arms out to sides", "Stop at shoulder height", "Lead with elbows", "Lower with control"], "breathing": ["Exhale raising", "Inhale lowering"]}'::jsonb,
    'Using momentum, going too high, shrugging shoulders, too heavy weight',
    'Focus on middle deltoid. Use moderate weight and strict form.'
) ON CONFLICT (name) DO NOTHING;

-- 44. Rear Delt Fly
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Bent-Over Rear Delt Fly',
    'accessory',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/rear-delt-fly.mp4',
    40,
    5700000,
    'dumbbell',
    'beginner',
    '{"setup": ["Bend at hips", "Back flat", "Dumbbells hanging", "Slight elbow bend"], "execution": ["Raise arms out to sides", "Squeeze shoulder blades", "Control descent", "Lead with elbows"], "breathing": ["Exhale raising", "Inhale lowering"]}'::jsonb,
    'Using momentum, not maintaining hip hinge, rowing instead of flying',
    'Great for rear delts and shoulder health. Keep back flat.'
) ON CONFLICT (name) DO NOTHING;

-- 45. Farmers Walk
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Farmers Walk',
    'carry',
    'full_body',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/farmers-walk.mp4',
    45,
    6100000,
    'dumbbell',
    'intermediate',
    '{"setup": ["Hold heavy dumbbells at sides", "Shoulders back", "Core tight", "Chest up"], "execution": ["Walk forward with control", "Keep shoulders level", "Take deliberate steps", "Maintain posture"], "breathing": ["Breathe rhythmically", "Brace core"]}'::jsonb,
    'Leaning to one side, shrugging shoulders, walking too fast, losing posture',
    'Excellent for grip and core. Start lighter than you think. Have a safe place to set weights down.'
) ON CONFLICT (name) DO NOTHING;

-- 46. Band Pull-Apart
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Band Pull-Apart',
    'mobility',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/band-pull-apart.mp4',
    35,
    5200000,
    'bands',
    'beginner',
    '{"setup": ["Hold band at shoulder width", "Arms extended forward", "Slight elbow bend"], "execution": ["Pull band apart to chest", "Squeeze shoulder blades", "Control return", "Keep arms at shoulder height"], "breathing": ["Exhale pulling", "Inhale returning"]}'::jsonb,
    'Arms drifting up or down, not squeezing shoulder blades, using momentum',
    'Excellent for shoulder health and warm-up. High reps recommended.'
) ON CONFLICT (name) DO NOTHING;

-- 47. Cat-Cow Stretch
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Cat-Cow Stretch',
    'mobility',
    'core',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/cat-cow.mp4',
    40,
    5500000,
    'bodyweight',
    'beginner',
    '{"setup": ["Start on hands and knees", "Hands under shoulders", "Knees under hips"], "execution": ["Arch back (cow)", "Round back (cat)", "Move slowly", "Full range of motion"], "breathing": ["Inhale arching", "Exhale rounding"]}'::jsonb,
    'Moving too fast, not going through full range, holding positions too long',
    'Excellent for spinal mobility and warm-up. Move with breath.'
) ON CONFLICT (name) DO NOTHING;

-- 48. Thread the Needle
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Thread the Needle',
    'mobility',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/thread-needle.mp4',
    40,
    5400000,
    'bodyweight',
    'beginner',
    '{"setup": ["Start on hands and knees", "One hand behind head"], "execution": ["Thread arm under body", "Rotate thoracic spine", "Reach as far as comfortable", "Return and repeat"], "breathing": ["Breathe steadily throughout"]}'::jsonb,
    'Not rotating enough, forcing the movement, moving too fast',
    'Excellent for thoracic spine mobility. Great for desk workers.'
) ON CONFLICT (name) DO NOTHING;

-- 49. World's Greatest Stretch
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'World''s Greatest Stretch',
    'mobility',
    'full_body',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/worlds-greatest.mp4',
    50,
    6500000,
    'bodyweight',
    'beginner',
    '{"setup": ["Start in lunge position", "Back leg straight"], "execution": ["Place inside hand on ground", "Rotate and reach with other arm", "Return to lunge", "Stand and step forward"], "breathing": ["Breathe deeply throughout"]}'::jsonb,
    'Not rotating fully, rushing through movement, poor lunge position',
    'Comprehensive warm-up stretch. Move slowly and breathe deeply.'
) ON CONFLICT (name) DO NOTHING;

-- 50. Foam Roll Thoracic
INSERT INTO exercise_templates (
    id, name, category, body_region,
    video_url, video_duration, video_file_size, equipment_type, difficulty_level,
    technique_cues, common_mistakes, safety_notes
) VALUES (
    uuid_generate_v4(),
    'Foam Roll Thoracic Extension',
    'mobility',
    'upper',
    'https://your-supabase-project.supabase.co/storage/v1/object/public/exercise-videos/foam-roll-thoracic.mp4',
    45,
    5900000,
    'equipment',
    'beginner',
    '{"setup": ["Foam roller at mid-back", "Support head with hands", "Knees bent"], "execution": ["Extend back over roller", "Hold stretch", "Roll slightly and repeat", "Avoid lower back"], "breathing": ["Breathe deeply into stretch"]}'::jsonb,
    'Rolling too fast, going onto lower back, not supporting head',
    'Excellent for upper back mobility. Stay on mid-back only, not lower back.'
) ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 6. CREATE CATEGORY RELATIONSHIPS
-- ============================================================================

-- Link exercises to body region categories
DO $$
DECLARE
    upper_body_id UUID;
    lower_body_id UUID;
    core_id UUID;
    accessories_id UUID;
BEGIN
    -- Get category IDs
    SELECT id INTO upper_body_id FROM video_categories WHERE name = 'upper_body';
    SELECT id INTO lower_body_id FROM video_categories WHERE name = 'lower_body';
    SELECT id INTO core_id FROM video_categories WHERE name = 'core';
    SELECT id INTO accessories_id FROM video_categories WHERE name = 'accessories';

    -- Link upper body exercises
    INSERT INTO exercise_video_categories (exercise_template_id, video_category_id)
    SELECT id, upper_body_id
    FROM exercise_templates
    WHERE body_region = 'upper'
    ON CONFLICT DO NOTHING;

    -- Link lower body exercises
    INSERT INTO exercise_video_categories (exercise_template_id, video_category_id)
    SELECT id, lower_body_id
    FROM exercise_templates
    WHERE body_region = 'lower'
    ON CONFLICT DO NOTHING;

    -- Link core exercises
    INSERT INTO exercise_video_categories (exercise_template_id, video_category_id)
    SELECT id, core_id
    FROM exercise_templates
    WHERE body_region = 'core'
    ON CONFLICT DO NOTHING;

    -- Link mobility and accessory exercises
    INSERT INTO exercise_video_categories (exercise_template_id, video_category_id)
    SELECT id, accessories_id
    FROM exercise_templates
    WHERE category IN ('mobility', 'accessory', 'carry') OR body_region = 'full_body'
    ON CONFLICT DO NOTHING;
END $$;

-- Link exercises to equipment categories
DO $$
DECLARE
    barbell_id UUID;
    dumbbell_id UUID;
    bodyweight_id UUID;
    machine_id UUID;
    bands_id UUID;
BEGIN
    -- Get category IDs
    SELECT id INTO barbell_id FROM video_categories WHERE name = 'barbell';
    SELECT id INTO dumbbell_id FROM video_categories WHERE name = 'dumbbell';
    SELECT id INTO bodyweight_id FROM video_categories WHERE name = 'bodyweight';
    SELECT id INTO machine_id FROM video_categories WHERE name = 'machine';
    SELECT id INTO bands_id FROM video_categories WHERE name = 'bands';

    -- Link by equipment type
    INSERT INTO exercise_video_categories (exercise_template_id, video_category_id)
    SELECT id, barbell_id FROM exercise_templates WHERE equipment_type = 'barbell'
    ON CONFLICT DO NOTHING;

    INSERT INTO exercise_video_categories (exercise_template_id, video_category_id)
    SELECT id, dumbbell_id FROM exercise_templates WHERE equipment_type = 'dumbbell'
    ON CONFLICT DO NOTHING;

    INSERT INTO exercise_video_categories (exercise_template_id, video_category_id)
    SELECT id, bodyweight_id FROM exercise_templates WHERE equipment_type = 'bodyweight'
    ON CONFLICT DO NOTHING;

    INSERT INTO exercise_video_categories (exercise_template_id, video_category_id)
    SELECT id, machine_id FROM exercise_templates WHERE equipment_type = 'machine'
    ON CONFLICT DO NOTHING;

    INSERT INTO exercise_video_categories (exercise_template_id, video_category_id)
    SELECT id, bands_id FROM exercise_templates WHERE equipment_type IN ('cable', 'bands')
    ON CONFLICT DO NOTHING;
END $$;

-- ============================================================================
-- 7. CREATE HELPER FUNCTIONS
-- ============================================================================

-- Function to get exercises by category
CREATE OR REPLACE FUNCTION get_exercises_by_category(category_name TEXT)
RETURNS TABLE (
    exercise_id UUID,
    exercise_name TEXT,
    video_url TEXT,
    video_duration INTEGER,
    equipment_type TEXT,
    difficulty_level TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        et.id,
        et.name,
        et.video_url,
        et.video_duration,
        et.equipment_type,
        et.difficulty_level
    FROM exercise_templates et
    JOIN exercise_video_categories evc ON et.id = evc.exercise_template_id
    JOIN video_categories vc ON evc.video_category_id = vc.id
    WHERE vc.name = category_name
    ORDER BY et.name;
END;
$$ LANGUAGE plpgsql;

-- Function to search exercises
CREATE OR REPLACE FUNCTION search_exercise_videos(search_term TEXT)
RETURNS TABLE (
    exercise_id UUID,
    exercise_name TEXT,
    video_url TEXT,
    video_duration INTEGER,
    equipment_type TEXT,
    difficulty_level TEXT,
    body_region TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        et.id,
        et.name,
        et.video_url,
        et.video_duration,
        et.equipment_type,
        et.difficulty_level,
        et.body_region
    FROM exercise_templates et
    WHERE
        et.video_url IS NOT NULL
        AND (
            LOWER(et.name) LIKE LOWER('%' || search_term || '%')
            OR LOWER(et.category) LIKE LOWER('%' || search_term || '%')
            OR LOWER(et.body_region) LIKE LOWER('%' || search_term || '%')
            OR LOWER(et.equipment_type) LIKE LOWER('%' || search_term || '%')
        )
    ORDER BY et.name;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 8. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    total_exercises INTEGER;
    exercises_with_videos INTEGER;
    total_categories INTEGER;
    total_links INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_exercises FROM exercise_templates;
    SELECT COUNT(*) INTO exercises_with_videos FROM exercise_templates WHERE video_url IS NOT NULL;
    SELECT COUNT(*) INTO total_categories FROM video_categories;
    SELECT COUNT(*) INTO total_links FROM exercise_video_categories;

    RAISE NOTICE '=== Build 62 Video Library Migration Complete ===';
    RAISE NOTICE 'Total exercises in database: %', total_exercises;
    RAISE NOTICE 'Exercises with videos: %', exercises_with_videos;
    RAISE NOTICE 'Video categories created: %', total_categories;
    RAISE NOTICE 'Category-exercise links created: %', total_links;
    RAISE NOTICE '=============================================';
END $$;
-- Migration: Create AI Exercise Assistant Conversations
-- Description: Creates tables for storing AI conversation history and messages
-- Build: 62, Agent: 3
-- Date: 2025-12-18

-- =====================================================
-- AI Conversations Table
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    message_count INTEGER NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    tags TEXT[], -- Array of tags for categorization (e.g., "substitutions", "shoulder", "injury")

    -- Program context (what program was active when conversation started)
    program_id UUID REFERENCES programs(id) ON DELETE SET NULL,
    program_name TEXT,

    -- Metadata
    total_tokens_used INTEGER DEFAULT 0,
    estimated_cost_usd DECIMAL(10, 6) DEFAULT 0.00,

    -- Indexes
    CONSTRAINT ai_conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_id ON ai_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_created_at ON ai_conversations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_is_archived ON ai_conversations(is_archived);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_tags ON ai_conversations USING GIN(tags);

-- Add comments
COMMENT ON TABLE ai_conversations IS 'Stores AI Exercise Assistant conversation threads';
COMMENT ON COLUMN ai_conversations.title IS 'Conversation title (auto-generated or user-provided)';
COMMENT ON COLUMN ai_conversations.tags IS 'Array of tags for categorization and search';
COMMENT ON COLUMN ai_conversations.program_id IS 'Reference to active program when conversation started';
COMMENT ON COLUMN ai_conversations.total_tokens_used IS 'Total AI tokens consumed in this conversation';
COMMENT ON COLUMN ai_conversations.estimated_cost_usd IS 'Estimated cost in USD for this conversation';

-- =====================================================
-- AI Messages Table
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Exercise context (optional - included when message relates to specific exercise)
    exercise_context JSONB,

    -- Metadata
    token_count INTEGER,
    processing_time_ms INTEGER, -- Processing time in milliseconds
    error TEXT, -- Error message if AI request failed

    -- Flags
    needs_review BOOLEAN DEFAULT false, -- Flagged for therapist review (medical concerns)
    reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation_id ON ai_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_created_at ON ai_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_messages_needs_review ON ai_messages(needs_review) WHERE needs_review = true;
CREATE INDEX IF NOT EXISTS idx_ai_messages_exercise_context ON ai_messages USING GIN(exercise_context);

-- Add comments
COMMENT ON TABLE ai_messages IS 'Stores individual messages in AI conversations';
COMMENT ON COLUMN ai_messages.role IS 'Message role: user, assistant, or system';
COMMENT ON COLUMN ai_messages.exercise_context IS 'JSON object containing exercise information for context';
COMMENT ON COLUMN ai_messages.needs_review IS 'Flagged for therapist review due to medical concerns';
COMMENT ON COLUMN ai_messages.reviewed_by IS 'Therapist who reviewed this flagged message';

-- =====================================================
-- Trigger: Auto-update conversation updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ai_conversations
    SET updated_at = now(),
        message_count = (
            SELECT COUNT(*)
            FROM ai_messages
            WHERE conversation_id = NEW.conversation_id
        )
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ai_messages_update_conversation
AFTER INSERT ON ai_messages
FOR EACH ROW
EXECUTE FUNCTION update_conversation_timestamp();

COMMENT ON FUNCTION update_conversation_timestamp() IS 'Updates conversation updated_at and message_count on new message';

-- =====================================================
-- Trigger: Auto-flag medical concerns
-- =====================================================

CREATE OR REPLACE FUNCTION flag_medical_concerns()
RETURNS TRIGGER AS $$
DECLARE
    medical_keywords TEXT[] := ARRAY[
        'severe pain', 'sharp pain', 'sudden pain', 'extreme pain',
        'doctor', 'physician', 'hospital', 'emergency',
        'diagnose', 'diagnosis', 'condition',
        'broken', 'fracture', 'tear', 'ruptured',
        'surgery', 'surgical', 'operation'
    ];
    keyword TEXT;
    content_lower TEXT;
BEGIN
    content_lower := lower(NEW.content);

    -- Check if content contains any medical keywords
    FOREACH keyword IN ARRAY medical_keywords
    LOOP
        IF content_lower LIKE '%' || keyword || '%' THEN
            NEW.needs_review := true;
            EXIT;
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ai_messages_flag_concerns
BEFORE INSERT ON ai_messages
FOR EACH ROW
WHEN (NEW.role = 'user')
EXECUTE FUNCTION flag_medical_concerns();

COMMENT ON FUNCTION flag_medical_concerns() IS 'Automatically flags messages containing medical concern keywords';

-- =====================================================
-- Row-Level Security (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;

-- AI Conversations policies
CREATE POLICY "Users can view their own conversations"
    ON ai_conversations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own conversations"
    ON ai_conversations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations"
    ON ai_conversations FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations"
    ON ai_conversations FOR DELETE
    USING (auth.uid() = user_id);

-- Therapists can view all conversations for their patients
CREATE POLICY "Therapists can view patient conversations"
    ON ai_conversations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'therapist'
        )
    );

-- AI Messages policies
CREATE POLICY "Users can view messages in their conversations"
    ON ai_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM ai_conversations
            WHERE ai_conversations.id = ai_messages.conversation_id
            AND ai_conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create messages in their conversations"
    ON ai_messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM ai_conversations
            WHERE ai_conversations.id = ai_messages.conversation_id
            AND ai_conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete messages in their conversations"
    ON ai_messages FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM ai_conversations
            WHERE ai_conversations.id = ai_messages.conversation_id
            AND ai_conversations.user_id = auth.uid()
        )
    );

-- Therapists can view all messages
CREATE POLICY "Therapists can view all messages"
    ON ai_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'therapist'
        )
    );

-- Therapists can mark messages as reviewed
CREATE POLICY "Therapists can update message review status"
    ON ai_messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'therapist'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'therapist'
        )
    );

-- =====================================================
-- Helper Views
-- =====================================================

-- View: Recent conversations with last message
CREATE OR REPLACE VIEW ai_conversations_with_preview AS
SELECT
    c.id,
    c.user_id,
    c.title,
    c.created_at,
    c.updated_at,
    c.message_count,
    c.is_archived,
    c.tags,
    c.program_name,
    c.total_tokens_used,
    c.estimated_cost_usd,
    (
        SELECT content
        FROM ai_messages m
        WHERE m.conversation_id = c.id
        ORDER BY m.created_at DESC
        LIMIT 1
    ) AS last_message_preview,
    (
        SELECT COUNT(*)
        FROM ai_messages m
        WHERE m.conversation_id = c.id
        AND m.needs_review = true
    ) AS flagged_message_count
FROM ai_conversations c;

COMMENT ON VIEW ai_conversations_with_preview IS 'Conversations with last message preview and flagged count';

-- =====================================================
-- Sample Data (Optional - for testing)
-- =====================================================

-- Note: Uncomment to insert sample data for testing
/*
-- Insert sample conversation for demo patient
INSERT INTO ai_conversations (
    user_id,
    title,
    message_count,
    tags,
    program_name
) VALUES (
    (SELECT id FROM auth.users WHERE email = 'demo-athlete@ptperformance.app'),
    'Exercise substitutions for shoulder injury',
    4,
    ARRAY['substitutions', 'shoulder', 'injury-modification'],
    'Winter Strength Program'
) RETURNING id;

-- Get the conversation ID and insert sample messages
-- (You would replace 'CONVERSATION_ID_HERE' with actual ID from above)
*/

-- =====================================================
-- Verification Query
-- =====================================================

-- Verify tables were created
DO $$
DECLARE
    conversation_count INTEGER;
    message_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO conversation_count FROM ai_conversations;
    SELECT COUNT(*) INTO message_count FROM ai_messages;

    RAISE NOTICE 'Migration complete:';
    RAISE NOTICE '  - ai_conversations table: % rows', conversation_count;
    RAISE NOTICE '  - ai_messages table: % rows', message_count;
    RAISE NOTICE '  - RLS policies enabled';
    RAISE NOTICE '  - Triggers configured';
END $$;
