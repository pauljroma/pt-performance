-- BUILD 127: Create timer_presets table for interval timer functionality
-- Stores curated timer configurations (Tabata, EMOM, AMRAP, etc.)

-- Create timer_presets table
CREATE TABLE IF NOT EXISTS timer_presets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    template_json JSONB NOT NULL,
    category TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add helpful comment
COMMENT ON TABLE timer_presets IS 'Curated interval timer configurations';

-- Create index for category filtering
CREATE INDEX IF NOT EXISTS idx_timer_presets_category ON timer_presets(category);

-- Enable RLS
ALTER TABLE timer_presets ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can read timer presets (they're public)
CREATE POLICY "Timer presets are publicly readable"
ON timer_presets FOR SELECT
USING (true);

-- Seed with sample timer presets
INSERT INTO timer_presets (name, description, template_json, category) VALUES
(
    'Classic Tabata',
    'The original Tabata protocol - 4 minutes of high-intensity interval training',
    '{"type": "tabata", "work_seconds": 20, "rest_seconds": 10, "rounds": 8, "cycles": 1, "total_duration": 240, "difficulty": "hard", "equipment": "Bodyweight"}',
    'cardio'
),
(
    'EMOM Strength',
    '10 rounds of strength work with built-in rest',
    '{"type": "emom", "work_seconds": 40, "rest_seconds": 20, "rounds": 10, "cycles": 1, "total_duration": 600, "difficulty": "moderate", "equipment": "Dumbbells"}',
    'strength'
),
(
    '5 Minute AMRAP',
    'As many rounds as possible in 5 minutes',
    '{"type": "amrap", "work_seconds": 300, "rest_seconds": 0, "rounds": 1, "cycles": 1, "total_duration": 300, "difficulty": "hard", "equipment": "Bodyweight"}',
    'cardio'
),
(
    'Warm-up Intervals',
    'Light intervals to prepare for training',
    '{"type": "intervals", "work_seconds": 30, "rest_seconds": 30, "rounds": 5, "cycles": 1, "total_duration": 300, "difficulty": "easy", "equipment": "None"}',
    'warmup'
),
(
    'Recovery Stretching',
    'Guided recovery with timed holds',
    '{"type": "custom", "work_seconds": 45, "rest_seconds": 15, "rounds": 6, "cycles": 1, "total_duration": 360, "difficulty": "easy", "equipment": "Mat"}',
    'recovery'
),
(
    'Advanced HIIT',
    '30-second work, 15-second rest for 12 rounds',
    '{"type": "intervals", "work_seconds": 30, "rest_seconds": 15, "rounds": 12, "cycles": 1, "total_duration": 540, "difficulty": "very_hard", "equipment": "Bodyweight"}',
    'cardio'
),
(
    'Power Intervals',
    '45 seconds of work, 15 seconds of rest for strength building',
    '{"type": "intervals", "work_seconds": 45, "rest_seconds": 15, "rounds": 8, "cycles": 1, "total_duration": 480, "difficulty": "moderate", "equipment": "Weights"}',
    'strength'
),
(
    'Cool Down Timer',
    '5 minutes of gentle movement and stretching',
    '{"type": "custom", "work_seconds": 60, "rest_seconds": 0, "rounds": 5, "cycles": 1, "total_duration": 300, "difficulty": "easy", "equipment": "Mat"}',
    'recovery'
)
ON CONFLICT DO NOTHING;
