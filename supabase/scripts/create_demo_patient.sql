-- Create demo therapist and patient for AI chat testing
-- Run this to populate the empty patients table

-- 1. Create demo therapist
INSERT INTO therapists (id, first_name, last_name, email, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000100'::uuid,
  'Sarah',
  'Thompson',
  'demo-pt@ptperformance.app',
  '2025-01-01 08:00:00'::timestamptz
)
ON CONFLICT (email) DO NOTHING;

-- 2. Create demo patient (John Brebbia)
INSERT INTO patients (
  id,
  therapist_id,
  first_name,
  last_name,
  email,
  date_of_birth,
  sport,
  position,
  dominant_hand,
  height_in,
  weight_lb,
  medical_history,
  medications,
  goals,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'John',
  'Brebbia',
  'demo-athlete@ptperformance.app',
  '1990-05-27'::date,
  'Baseball',
  'Pitcher (Right-handed)',
  'Right',
  73,
  195,
  '{
    "injuries": [
      {
        "year": 2025,
        "body_region": "elbow",
        "diagnosis": "Grade 1 tricep strain",
        "notes": "Minor strain during spring training, conservative rehab protocol"
      }
    ],
    "surgeries": [],
    "chronic_conditions": []
  }'::jsonb,
  '{
    "current": [],
    "allergies": []
  }'::jsonb,
  'Return to full throwing capacity by June 2025. Regain 94-96 mph fastball velocity. Improve shoulder stability and reduce injury risk.',
  '2025-01-01 08:30:00'::timestamptz
)
ON CONFLICT (email) DO NOTHING;

-- 3. Verify
SELECT id, first_name, last_name, email FROM patients;
