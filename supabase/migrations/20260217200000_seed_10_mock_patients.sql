-- 20260217200000_seed_10_mock_patients.sql
-- Seed 10 realistic mock patients for the demo therapist (Sarah Thompson)
-- Therapist ID: 00000000-0000-0000-0000-000000000100
-- These patients span different sports, injury types, levels, and training modes.

-- ============================================================================
-- ENSURE DEMO THERAPIST EXISTS
-- ============================================================================

INSERT INTO therapists (id, first_name, last_name, email, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000100'::uuid,
  'Sarah',
  'Thompson',
  'demo-pt@ptperformance.app',
  '2025-01-01 08:00:00'::timestamptz
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 10 MOCK PATIENTS
-- ============================================================================

INSERT INTO patients (
  id, therapist_id, first_name, last_name, email,
  sport, position, injury_type, target_level, mode,
  created_at
)
VALUES
  -- 1. Marcus Rivera — Baseball, College rehab
  (
    'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'Marcus', 'Rivera',
    'mock-marcus@ptperformance.test',
    'Baseball', 'Shortstop', 'Labrum Repair', 'College', 'rehab',
    NOW() - INTERVAL '45 days'
  ),

  -- 2. Alyssa Chen — Basketball, Professional rehab
  (
    'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'Alyssa', 'Chen',
    'mock-alyssa@ptperformance.test',
    'Basketball', 'Point Guard', 'ACL Reconstruction', 'Professional', 'rehab',
    NOW() - INTERVAL '30 days'
  ),

  -- 3. Tyler Brooks — Football, College performance
  (
    'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'Tyler', 'Brooks',
    'mock-tyler@ptperformance.test',
    'Football', 'Wide Receiver', 'Hamstring Strain', 'College', 'performance',
    NOW() - INTERVAL '21 days'
  ),

  -- 4. Emma Fitzgerald — Soccer, High School rehab
  (
    'aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'Emma', 'Fitzgerald',
    'mock-emma@ptperformance.test',
    'Soccer', 'Midfielder', 'Ankle Sprain', 'High School', 'rehab',
    NOW() - INTERVAL '14 days'
  ),

  -- 5. Jordan Williams — CrossFit, Recreational strength
  (
    'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'Jordan', 'Williams',
    'mock-jordan@ptperformance.test',
    'CrossFit', NULL, 'Rotator Cuff Tendinitis', 'Recreational', 'strength',
    NOW() - INTERVAL '60 days'
  ),

  -- 6. Sophia Nakamura — Swimming, College rehab
  (
    'aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'Sophia', 'Nakamura',
    'mock-sophia@ptperformance.test',
    'Swimming', 'Freestyle/IM', 'Shoulder Impingement', 'College', 'rehab',
    NOW() - INTERVAL '10 days'
  ),

  -- 7. Deshawn Patterson — Track & Field, Semi-Pro performance
  (
    'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'Deshawn', 'Patterson',
    'mock-deshawn@ptperformance.test',
    'Track & Field', 'Sprinter', 'Quad Strain', 'Semi-Pro', 'performance',
    NOW() - INTERVAL '35 days'
  ),

  -- 8. Olivia Martinez — Volleyball, High School strength
  (
    'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'Olivia', 'Martinez',
    'mock-olivia@ptperformance.test',
    'Volleyball', 'Outside Hitter', 'Patellar Tendinitis', 'High School', 'strength',
    NOW() - INTERVAL '7 days'
  ),

  -- 9. Liam O''Connor — Hockey, Professional rehab
  (
    'aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'Liam', 'O''Connor',
    'mock-liam@ptperformance.test',
    'Hockey', 'Center', 'Hip Labral Tear', 'Professional', 'rehab',
    NOW() - INTERVAL '50 days'
  ),

  -- 10. Isabella Rossi — Tennis, Recreational strength
  (
    'aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid,
    '00000000-0000-0000-0000-000000000100'::uuid,
    'Isabella', 'Rossi',
    'mock-isabella@ptperformance.test',
    'Tennis', NULL, 'Tennis Elbow', 'Recreational', 'strength',
    NOW() - INTERVAL '25 days'
  )
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'Mock patients created' AS status,
       COUNT(*) AS count
FROM patients
WHERE therapist_id = '00000000-0000-0000-0000-000000000100'::uuid
  AND email LIKE 'mock-%@ptperformance.test';
