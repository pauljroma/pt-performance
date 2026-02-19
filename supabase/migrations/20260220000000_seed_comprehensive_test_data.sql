-- ============================================================================
-- COMPREHENSIVE TEST DATA SEED FOR 10 MOCK PATIENTS
-- ============================================================================
-- Date: 2026-02-20
-- Purpose: Seed realistic test data across all major tables for the 10 mock
--          patients created in 20260217200000_seed_10_mock_patients.sql.
--          Uses ON CONFLICT DO NOTHING throughout for idempotency.
--          Uses relative dates (NOW() - INTERVAL) so data stays fresh.
-- ============================================================================

-- ============================================================================
-- SECTION A: AUTH USERS + PATIENT LINKING
-- ============================================================================
-- Create auth.users entries for each mock patient so the user_id FK is satisfied,
-- then link each patient to their auth user.

-- 1. Marcus Rivera
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated',
    'mock-marcus@ptperformance.test', '',
    NOW(), NOW(), NOW(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 2. Alyssa Chen
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated',
    'mock-alyssa@ptperformance.test', '',
    NOW(), NOW(), NOW(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 3. Tyler Brooks
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated',
    'mock-tyler@ptperformance.test', '',
    NOW(), NOW(), NOW(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 4. Emma Fitzgerald
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated',
    'mock-emma@ptperformance.test', '',
    NOW(), NOW(), NOW(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 5. Jordan Williams
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated',
    'mock-jordan@ptperformance.test', '',
    NOW(), NOW(), NOW(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 6. Sophia Nakamura
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated',
    'mock-sophia@ptperformance.test', '',
    NOW(), NOW(), NOW(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 7. Deshawn Patterson
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated',
    'mock-deshawn@ptperformance.test', '',
    NOW(), NOW(), NOW(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 8. Olivia Martinez
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated',
    'mock-olivia@ptperformance.test', '',
    NOW(), NOW(), NOW(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 9. Liam O'Connor
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated',
    'mock-liam@ptperformance.test', '',
    NOW(), NOW(), NOW(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 10. Isabella Rossi
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated',
    'mock-isabella@ptperformance.test', '',
    NOW(), NOW(), NOW(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- Link each patient to their auth user
UPDATE patients SET user_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid AND user_id IS NULL;
UPDATE patients SET user_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid AND user_id IS NULL;
UPDATE patients SET user_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid AND user_id IS NULL;
UPDATE patients SET user_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid AND user_id IS NULL;
UPDATE patients SET user_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid AND user_id IS NULL;
UPDATE patients SET user_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid AND user_id IS NULL;
UPDATE patients SET user_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid AND user_id IS NULL;
UPDATE patients SET user_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid AND user_id IS NULL;
UPDATE patients SET user_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid AND user_id IS NULL;
UPDATE patients SET user_id = 'aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid AND user_id IS NULL;


-- ============================================================================
-- SECTION B: PROGRAMS + PHASES + SESSIONS + SESSION_EXERCISES
-- ============================================================================
-- Create programs for 7 of 10 patients (NOT Emma #4, Sophia #6, Isabella #10).
-- Each program has 2 phases. Each phase has 3 sessions.
-- Sessions get 4-5 exercises linked from exercise_templates by name.

-- Disable audit triggers to allow bulk inserts without user_id issues
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_programs_trigger') THEN
        ALTER TABLE programs DISABLE TRIGGER USER;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_phases_trigger') THEN
        ALTER TABLE phases DISABLE TRIGGER USER;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_sessions_trigger') THEN
        ALTER TABLE sessions DISABLE TRIGGER USER;
    END IF;
END $$;

-- Programs for 7 patients
-- 1. Marcus Rivera - Labrum Rehab Program
INSERT INTO programs (id, patient_id, name, description, start_date, status)
VALUES (
    'bbbbbbbb-0000-0000-0000-000000000001'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
    'Labrum Rehab Program',
    'Post-labrum repair rehabilitation focusing on shoulder stability and gradual return to throwing.',
    (CURRENT_DATE - INTERVAL '42 days')::date,
    'active'
) ON CONFLICT (id) DO NOTHING;

-- 2. Alyssa Chen - ACL Return to Sport
INSERT INTO programs (id, patient_id, name, description, start_date, status)
VALUES (
    'bbbbbbbb-0000-0000-0000-000000000002'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,
    'ACL Return to Sport',
    'Progressive ACL rehabilitation with sport-specific basketball drills.',
    (CURRENT_DATE - INTERVAL '28 days')::date,
    'active'
) ON CONFLICT (id) DO NOTHING;

-- 3. Tyler Brooks - Performance Training
INSERT INTO programs (id, patient_id, name, description, start_date, status)
VALUES (
    'bbbbbbbb-0000-0000-0000-000000000003'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,
    'Speed & Power Development',
    'Off-season performance training for football wide receiver speed and agility.',
    (CURRENT_DATE - INTERVAL '21 days')::date,
    'active'
) ON CONFLICT (id) DO NOTHING;

-- 5. Jordan Williams - Strength Rebuilding
INSERT INTO programs (id, patient_id, name, description, start_date, status)
VALUES (
    'bbbbbbbb-0000-0000-0000-000000000005'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid,
    'Shoulder-Safe Strength Program',
    'Strength training program working around rotator cuff limitations.',
    (CURRENT_DATE - INTERVAL '56 days')::date,
    'active'
) ON CONFLICT (id) DO NOTHING;

-- 7. Deshawn Patterson - Sprint Performance
INSERT INTO programs (id, patient_id, name, description, start_date, status)
VALUES (
    'bbbbbbbb-0000-0000-0000-000000000007'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid,
    'Sprint Performance Block',
    'Track sprint training with quad strain recovery integration.',
    (CURRENT_DATE - INTERVAL '35 days')::date,
    'active'
) ON CONFLICT (id) DO NOTHING;

-- 8. Olivia Martinez - Volleyball Strength
INSERT INTO programs (id, patient_id, name, description, start_date, status)
VALUES (
    'bbbbbbbb-0000-0000-0000-000000000008'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid,
    'Volleyball Strength Foundation',
    'Building lower body strength and jump capacity for volleyball.',
    (CURRENT_DATE - INTERVAL '7 days')::date,
    'active'
) ON CONFLICT (id) DO NOTHING;

-- 9. Liam O''Connor - Hip Rehab
INSERT INTO programs (id, patient_id, name, description, start_date, status)
VALUES (
    'bbbbbbbb-0000-0000-0000-000000000009'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid,
    'Hip Labral Tear Rehab',
    'Post-surgical hip rehabilitation program for return to hockey.',
    (CURRENT_DATE - INTERVAL '49 days')::date,
    'active'
) ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- PHASES (2 per program = 14 phases)
-- UUID pattern: cccccccc-0000-0000-000X-00000000000Y (X=patient, Y=phase)
-- ============================================================================

-- Marcus (patient 1) phases
INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals)
VALUES
    ('cccccccc-0000-0000-0001-000000000001'::uuid, 'bbbbbbbb-0000-0000-0000-000000000001'::uuid, 'Phase 1: Mobility & Activation', 1, 3, 'Restore shoulder ROM and activate stabilizers'),
    ('cccccccc-0000-0000-0001-000000000002'::uuid, 'bbbbbbbb-0000-0000-0000-000000000001'::uuid, 'Phase 2: Strengthening', 2, 3, 'Build shoulder and scapular strength progressively')
ON CONFLICT (id) DO NOTHING;

-- Alyssa (patient 2) phases
INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals)
VALUES
    ('cccccccc-0000-0000-0002-000000000001'::uuid, 'bbbbbbbb-0000-0000-0000-000000000002'::uuid, 'Phase 1: Foundation', 1, 4, 'Rebuild quad strength and knee stability'),
    ('cccccccc-0000-0000-0002-000000000002'::uuid, 'bbbbbbbb-0000-0000-0000-000000000002'::uuid, 'Phase 2: Sport-Specific', 2, 4, 'Introduce agility and basketball movements')
ON CONFLICT (id) DO NOTHING;

-- Tyler (patient 3) phases
INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals)
VALUES
    ('cccccccc-0000-0000-0003-000000000001'::uuid, 'bbbbbbbb-0000-0000-0000-000000000003'::uuid, 'Phase 1: Strength Base', 1, 3, 'Build foundational strength for speed work'),
    ('cccccccc-0000-0000-0003-000000000002'::uuid, 'bbbbbbbb-0000-0000-0000-000000000003'::uuid, 'Phase 2: Power & Speed', 2, 3, 'Convert strength to explosive power')
ON CONFLICT (id) DO NOTHING;

-- Jordan (patient 5) phases
INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals)
VALUES
    ('cccccccc-0000-0000-0005-000000000001'::uuid, 'bbbbbbbb-0000-0000-0000-000000000005'::uuid, 'Phase 1: Rebuild', 1, 4, 'Regain baseline strength with shoulder modifications'),
    ('cccccccc-0000-0000-0005-000000000002'::uuid, 'bbbbbbbb-0000-0000-0000-000000000005'::uuid, 'Phase 2: Progressive Overload', 2, 4, 'Progressively increase loads and volume')
ON CONFLICT (id) DO NOTHING;

-- Deshawn (patient 7) phases
INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals)
VALUES
    ('cccccccc-0000-0000-0007-000000000001'::uuid, 'bbbbbbbb-0000-0000-0000-000000000007'::uuid, 'Phase 1: Recovery & Base', 1, 3, 'Heal quad strain while maintaining fitness'),
    ('cccccccc-0000-0000-0007-000000000002'::uuid, 'bbbbbbbb-0000-0000-0000-000000000007'::uuid, 'Phase 2: Sprint Preparation', 2, 3, 'Return to sprinting with progressive loading')
ON CONFLICT (id) DO NOTHING;

-- Olivia (patient 8) phases
INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals)
VALUES
    ('cccccccc-0000-0000-0008-000000000001'::uuid, 'bbbbbbbb-0000-0000-0000-000000000008'::uuid, 'Phase 1: Movement Quality', 1, 2, 'Learn fundamental movement patterns'),
    ('cccccccc-0000-0000-0008-000000000002'::uuid, 'bbbbbbbb-0000-0000-0000-000000000008'::uuid, 'Phase 2: Strength Building', 2, 3, 'Begin loading movements with proper form')
ON CONFLICT (id) DO NOTHING;

-- Liam (patient 9) phases
INSERT INTO phases (id, program_id, name, sequence, duration_weeks, goals)
VALUES
    ('cccccccc-0000-0000-0009-000000000001'::uuid, 'bbbbbbbb-0000-0000-0000-000000000009'::uuid, 'Phase 1: Post-Op Mobility', 1, 4, 'Restore hip ROM and basic muscle activation'),
    ('cccccccc-0000-0000-0009-000000000002'::uuid, 'bbbbbbbb-0000-0000-0000-000000000009'::uuid, 'Phase 2: Load Tolerance', 2, 4, 'Build hip strength and skating readiness')
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- SESSIONS (3 per phase = 6 per program = 42 sessions total)
-- UUID pattern: dddddddd-0000-0000-0X0Y-00000000000Z
-- X=patient number, Y=phase number, Z=session number
-- ============================================================================

-- Marcus (patient 1) sessions
INSERT INTO sessions (id, phase_id, name, sequence, notes) VALUES
    ('dddddddd-0000-0000-0101-000000000001'::uuid, 'cccccccc-0000-0000-0001-000000000001'::uuid, 'Shoulder Mobility A', 1, 'Focus on external rotation ROM'),
    ('dddddddd-0000-0000-0101-000000000002'::uuid, 'cccccccc-0000-0000-0001-000000000001'::uuid, 'Shoulder Mobility B', 2, 'Scapular activation and stability'),
    ('dddddddd-0000-0000-0101-000000000003'::uuid, 'cccccccc-0000-0000-0001-000000000001'::uuid, 'Shoulder Mobility C', 3, 'Combined mobility and light strength'),
    ('dddddddd-0000-0000-0102-000000000001'::uuid, 'cccccccc-0000-0000-0001-000000000002'::uuid, 'Strength Day A', 1, 'Upper body strengthening'),
    ('dddddddd-0000-0000-0102-000000000002'::uuid, 'cccccccc-0000-0000-0001-000000000002'::uuid, 'Strength Day B', 2, 'Lower body and core'),
    ('dddddddd-0000-0000-0102-000000000003'::uuid, 'cccccccc-0000-0000-0001-000000000002'::uuid, 'Strength Day C', 3, 'Full body integration')
ON CONFLICT (id) DO NOTHING;

-- Alyssa (patient 2) sessions
INSERT INTO sessions (id, phase_id, name, sequence, notes) VALUES
    ('dddddddd-0000-0000-0201-000000000001'::uuid, 'cccccccc-0000-0000-0002-000000000001'::uuid, 'Knee Rehab A', 1, 'Quad strengthening focus'),
    ('dddddddd-0000-0000-0201-000000000002'::uuid, 'cccccccc-0000-0000-0002-000000000001'::uuid, 'Knee Rehab B', 2, 'Hamstring and hip stability'),
    ('dddddddd-0000-0000-0201-000000000003'::uuid, 'cccccccc-0000-0000-0002-000000000001'::uuid, 'Knee Rehab C', 3, 'Balance and proprioception'),
    ('dddddddd-0000-0000-0202-000000000001'::uuid, 'cccccccc-0000-0000-0002-000000000002'::uuid, 'Court Prep A', 1, 'Lateral movement drills'),
    ('dddddddd-0000-0000-0202-000000000002'::uuid, 'cccccccc-0000-0000-0002-000000000002'::uuid, 'Court Prep B', 2, 'Jumping and landing mechanics'),
    ('dddddddd-0000-0000-0202-000000000003'::uuid, 'cccccccc-0000-0000-0002-000000000002'::uuid, 'Court Prep C', 3, 'Full court simulation')
ON CONFLICT (id) DO NOTHING;

-- Tyler (patient 3) sessions
INSERT INTO sessions (id, phase_id, name, sequence, notes) VALUES
    ('dddddddd-0000-0000-0301-000000000001'::uuid, 'cccccccc-0000-0000-0003-000000000001'::uuid, 'Lower Strength A', 1, 'Squat emphasis'),
    ('dddddddd-0000-0000-0301-000000000002'::uuid, 'cccccccc-0000-0000-0003-000000000001'::uuid, 'Upper Strength A', 2, 'Push/pull balance'),
    ('dddddddd-0000-0000-0301-000000000003'::uuid, 'cccccccc-0000-0000-0003-000000000001'::uuid, 'Full Body Power', 3, 'Compound lifts'),
    ('dddddddd-0000-0000-0302-000000000001'::uuid, 'cccccccc-0000-0000-0003-000000000002'::uuid, 'Speed Day A', 1, 'Acceleration drills'),
    ('dddddddd-0000-0000-0302-000000000002'::uuid, 'cccccccc-0000-0000-0003-000000000002'::uuid, 'Power Day A', 2, 'Plyometric focus'),
    ('dddddddd-0000-0000-0302-000000000003'::uuid, 'cccccccc-0000-0000-0003-000000000002'::uuid, 'Speed & Agility', 3, 'Route running drills')
ON CONFLICT (id) DO NOTHING;

-- Jordan (patient 5) sessions
INSERT INTO sessions (id, phase_id, name, sequence, notes) VALUES
    ('dddddddd-0000-0000-0501-000000000001'::uuid, 'cccccccc-0000-0000-0005-000000000001'::uuid, 'Lower Body A', 1, 'Squat and hinge patterns'),
    ('dddddddd-0000-0000-0501-000000000002'::uuid, 'cccccccc-0000-0000-0005-000000000001'::uuid, 'Upper Body Modified', 2, 'Shoulder-safe pressing and pulling'),
    ('dddddddd-0000-0000-0501-000000000003'::uuid, 'cccccccc-0000-0000-0005-000000000001'::uuid, 'Full Body Circuit', 3, 'Metabolic conditioning'),
    ('dddddddd-0000-0000-0502-000000000001'::uuid, 'cccccccc-0000-0000-0005-000000000002'::uuid, 'Strength Day A', 1, 'Progressive overload lower'),
    ('dddddddd-0000-0000-0502-000000000002'::uuid, 'cccccccc-0000-0000-0005-000000000002'::uuid, 'Strength Day B', 2, 'Progressive overload upper'),
    ('dddddddd-0000-0000-0502-000000000003'::uuid, 'cccccccc-0000-0000-0005-000000000002'::uuid, 'Conditioning', 3, 'CrossFit-style workout')
ON CONFLICT (id) DO NOTHING;

-- Deshawn (patient 7) sessions
INSERT INTO sessions (id, phase_id, name, sequence, notes) VALUES
    ('dddddddd-0000-0000-0701-000000000001'::uuid, 'cccccccc-0000-0000-0007-000000000001'::uuid, 'Rehab Session A', 1, 'Quad recovery focus'),
    ('dddddddd-0000-0000-0701-000000000002'::uuid, 'cccccccc-0000-0000-0007-000000000001'::uuid, 'Upper Maintenance', 2, 'Maintain upper body fitness'),
    ('dddddddd-0000-0000-0701-000000000003'::uuid, 'cccccccc-0000-0000-0007-000000000001'::uuid, 'Core & Mobility', 3, 'Core stability and hip mobility'),
    ('dddddddd-0000-0000-0702-000000000001'::uuid, 'cccccccc-0000-0000-0007-000000000002'::uuid, 'Sprint Prep A', 1, 'Progressive running build-up'),
    ('dddddddd-0000-0000-0702-000000000002'::uuid, 'cccccccc-0000-0000-0007-000000000002'::uuid, 'Sprint Prep B', 2, 'Tempo runs and acceleration'),
    ('dddddddd-0000-0000-0702-000000000003'::uuid, 'cccccccc-0000-0000-0007-000000000002'::uuid, 'Sprint Prep C', 3, 'Full sprint mechanics')
ON CONFLICT (id) DO NOTHING;

-- Olivia (patient 8) sessions
INSERT INTO sessions (id, phase_id, name, sequence, notes) VALUES
    ('dddddddd-0000-0000-0801-000000000001'::uuid, 'cccccccc-0000-0000-0008-000000000001'::uuid, 'Movement 101 A', 1, 'Squat and hinge learning'),
    ('dddddddd-0000-0000-0801-000000000002'::uuid, 'cccccccc-0000-0000-0008-000000000001'::uuid, 'Movement 101 B', 2, 'Push, pull, carry patterns'),
    ('dddddddd-0000-0000-0801-000000000003'::uuid, 'cccccccc-0000-0000-0008-000000000001'::uuid, 'Movement 101 C', 3, 'Plyometric introduction'),
    ('dddddddd-0000-0000-0802-000000000001'::uuid, 'cccccccc-0000-0000-0008-000000000002'::uuid, 'Strength A', 1, 'Loaded squat progression'),
    ('dddddddd-0000-0000-0802-000000000002'::uuid, 'cccccccc-0000-0000-0008-000000000002'::uuid, 'Strength B', 2, 'Loaded hinge and pull'),
    ('dddddddd-0000-0000-0802-000000000003'::uuid, 'cccccccc-0000-0000-0008-000000000002'::uuid, 'Strength C', 3, 'Full body strength circuit')
ON CONFLICT (id) DO NOTHING;

-- Liam (patient 9) sessions
INSERT INTO sessions (id, phase_id, name, sequence, notes) VALUES
    ('dddddddd-0000-0000-0901-000000000001'::uuid, 'cccccccc-0000-0000-0009-000000000001'::uuid, 'Hip Mobility A', 1, 'Gentle ROM restoration'),
    ('dddddddd-0000-0000-0901-000000000002'::uuid, 'cccccccc-0000-0000-0009-000000000001'::uuid, 'Hip Mobility B', 2, 'Muscle activation focus'),
    ('dddddddd-0000-0000-0901-000000000003'::uuid, 'cccccccc-0000-0000-0009-000000000001'::uuid, 'Hip Mobility C', 3, 'Combined mobility and light loading'),
    ('dddddddd-0000-0000-0902-000000000001'::uuid, 'cccccccc-0000-0000-0009-000000000002'::uuid, 'Load Tolerance A', 1, 'Bilateral lower body loading'),
    ('dddddddd-0000-0000-0902-000000000002'::uuid, 'cccccccc-0000-0000-0009-000000000002'::uuid, 'Load Tolerance B', 2, 'Single leg progression'),
    ('dddddddd-0000-0000-0902-000000000003'::uuid, 'cccccccc-0000-0000-0009-000000000002'::uuid, 'Load Tolerance C', 3, 'Sport-specific skating prep')
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- SESSION EXERCISES
-- Look up exercise_template IDs by name and insert exercises for each session.
-- We use a DO block to safely look up templates that exist.
-- ============================================================================

DO $$
DECLARE
    v_squat_id uuid;
    v_bench_id uuid;
    v_deadlift_id uuid;
    v_pullup_id uuid;
    v_lunge_id uuid;
    v_plank_id uuid;
    v_band_pull_id uuid;
    v_goblet_id uuid;
    v_rdl_id uuid;
    v_front_plank_id uuid;
BEGIN
    -- Look up exercise templates by name
    SELECT id INTO v_squat_id FROM exercise_templates WHERE name = 'Barbell Squat' LIMIT 1;
    SELECT id INTO v_bench_id FROM exercise_templates WHERE name = 'Bench Press' LIMIT 1;
    -- Try alternate name if Bench Press not found
    IF v_bench_id IS NULL THEN
        SELECT id INTO v_bench_id FROM exercise_templates WHERE name = 'Barbell Bench Press' LIMIT 1;
    END IF;
    SELECT id INTO v_deadlift_id FROM exercise_templates WHERE name = 'Deadlift' LIMIT 1;
    SELECT id INTO v_pullup_id FROM exercise_templates WHERE name = 'Pull-ups' LIMIT 1;
    IF v_pullup_id IS NULL THEN
        SELECT id INTO v_pullup_id FROM exercise_templates WHERE name = 'Pull-Ups' LIMIT 1;
    END IF;
    SELECT id INTO v_lunge_id FROM exercise_templates WHERE name = 'Lunges' LIMIT 1;
    IF v_lunge_id IS NULL THEN
        SELECT id INTO v_lunge_id FROM exercise_templates WHERE name = 'Walking Lunges' LIMIT 1;
    END IF;
    SELECT id INTO v_plank_id FROM exercise_templates WHERE name = 'Plank' LIMIT 1;
    SELECT id INTO v_band_pull_id FROM exercise_templates WHERE name = 'Band Pull-Apart' LIMIT 1;
    SELECT id INTO v_goblet_id FROM exercise_templates WHERE name = 'Goblet Squat' LIMIT 1;
    SELECT id INTO v_rdl_id FROM exercise_templates WHERE name = 'Romanian Deadlift' LIMIT 1;
    IF v_rdl_id IS NULL THEN
        SELECT id INTO v_rdl_id FROM exercise_templates WHERE name = 'Romanian Deadlift (RDL)' LIMIT 1;
    END IF;
    SELECT id INTO v_front_plank_id FROM exercise_templates WHERE name = 'Front Plank' LIMIT 1;

    -- Fall back: use plank for front plank
    IF v_front_plank_id IS NULL THEN
        v_front_plank_id := v_plank_id;
    END IF;

    -- Only insert session_exercises if we have at least some templates
    -- Marcus Phase 1, Session 1: Shoulder Mobility A
    IF v_band_pull_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0101-000000000001'::uuid, v_band_pull_id, 1, 3, '15', 0, 'lbs', 30, 'Light band, focus on scapular squeeze')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_front_plank_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0101-000000000001'::uuid, v_front_plank_id, 2, 3, '30 seconds', 0, 'lbs', 45, 'Keep core braced, do not sag')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_goblet_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0101-000000000001'::uuid, v_goblet_id, 3, 3, '10', 25, 'lbs', 60, 'Control depth, keep elbows inside knees')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_rdl_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0101-000000000001'::uuid, v_rdl_id, 4, 3, '10', 65, 'lbs', 60, 'Hinge at hips, feel hamstring stretch')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Marcus Phase 2, Session 1: Strength Day A
    IF v_bench_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, target_rpe, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0102-000000000001'::uuid, v_bench_id, 1, 4, '8', 135, 'lbs', 7, 120, 'Moderate load, focus on shoulder position')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_pullup_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, target_rpe, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0102-000000000001'::uuid, v_pullup_id, 2, 3, '8-12', 0, 'lbs', 7, 90, 'Full range of motion, controlled descent')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_squat_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, target_rpe, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0102-000000000001'::uuid, v_squat_id, 3, 4, '6', 185, 'lbs', 8, 150, 'Below parallel, brace core')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Alyssa Phase 1, Session 1: Knee Rehab A
    IF v_goblet_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0201-000000000001'::uuid, v_goblet_id, 1, 3, '12', 20, 'lbs', 60, 'Pain-free ROM only, track knee position')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_rdl_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0201-000000000001'::uuid, v_rdl_id, 2, 3, '10', 45, 'lbs', 60, 'Hip hinge emphasis')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_front_plank_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0201-000000000001'::uuid, v_front_plank_id, 3, 3, '45 seconds', 0, 'lbs', 30, 'Core stability for knee support')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Tyler Phase 1, Session 1: Lower Strength A
    IF v_squat_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, target_rpe, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0301-000000000001'::uuid, v_squat_id, 1, 4, '6', 225, 'lbs', 8, 180, 'Heavy squat day')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_rdl_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, target_rpe, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0301-000000000001'::uuid, v_rdl_id, 2, 4, '8', 185, 'lbs', 7, 120, 'Hamstring development')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_lunge_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, target_rpe, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0301-000000000001'::uuid, v_lunge_id, 3, 3, '10 each', 50, 'lbs', 7, 90, 'Walking lunges with dumbbells')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Jordan Phase 1, Session 1: Lower Body A
    IF v_goblet_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, target_rpe, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0501-000000000001'::uuid, v_goblet_id, 1, 3, '12', 35, 'lbs', 6, 60, 'Light squat to rebuild pattern')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_deadlift_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, target_rpe, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0501-000000000001'::uuid, v_deadlift_id, 2, 4, '6', 185, 'lbs', 7, 150, 'Maintain hip hinge strength')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Deshawn Phase 1, Session 1: Rehab Session A
    IF v_goblet_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0701-000000000001'::uuid, v_goblet_id, 1, 3, '10', 30, 'lbs', 60, 'Easy quad loading, no pain')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_front_plank_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0701-000000000001'::uuid, v_front_plank_id, 2, 3, '45 seconds', 0, 'lbs', 30, 'Maintain sprint posture muscles')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_band_pull_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0701-000000000001'::uuid, v_band_pull_id, 3, 3, '15', 0, 'lbs', 30, 'Upper body maintenance')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Olivia Phase 1, Session 1: Movement 101 A
    IF v_goblet_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0801-000000000001'::uuid, v_goblet_id, 1, 3, '10', 15, 'lbs', 60, 'Learn squat pattern')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_rdl_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0801-000000000001'::uuid, v_rdl_id, 2, 3, '10', 25, 'lbs', 60, 'Learn hinge pattern')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_front_plank_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0801-000000000001'::uuid, v_front_plank_id, 3, 3, '20 seconds', 0, 'lbs', 30, 'Building core endurance')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Liam Phase 1, Session 1: Hip Mobility A
    IF v_band_pull_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0901-000000000001'::uuid, v_band_pull_id, 1, 3, '15', 0, 'lbs', 30, 'Upper body warmup while hip heals')
        ON CONFLICT DO NOTHING;
    END IF;
    IF v_front_plank_id IS NOT NULL THEN
        INSERT INTO session_exercises (session_id, exercise_template_id, sequence, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, notes)
        VALUES ('dddddddd-0000-0000-0901-000000000001'::uuid, v_front_plank_id, 2, 3, '30 seconds', 0, 'lbs', 30, 'Core stability for hip recovery')
        ON CONFLICT DO NOTHING;
    END IF;

    RAISE NOTICE 'Session exercises seeded successfully';
END $$;

-- Re-enable triggers
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_programs_trigger') THEN
        ALTER TABLE programs ENABLE TRIGGER USER;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_phases_trigger') THEN
        ALTER TABLE phases ENABLE TRIGGER USER;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_sessions_trigger') THEN
        ALTER TABLE sessions ENABLE TRIGGER USER;
    END IF;
END $$;


-- ============================================================================
-- SECTION C: SESSION STATUS + EXERCISE LOGS
-- ============================================================================
-- Create session_status entries for completed/missed sessions.
-- Then create exercise_logs for completed sessions (referencing session_exercises).
-- Due to the XOR constraint on exercise_logs, we must link to real session_exercise_ids.

DO $$
DECLARE
    v_session RECORD;
    v_se RECORD;
    v_completed boolean;
    v_sched_date date;
    v_patient_ids uuid[] := ARRAY[
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid
    ];
    v_pid uuid;
    v_session_num int;
    v_set_num int;
    v_reps int;
    v_load numeric;
    v_rpe numeric;
BEGIN
    -- For each patient with programs, mark Phase 1 sessions as mostly completed
    FOREACH v_pid IN ARRAY v_patient_ids LOOP
        v_session_num := 0;
        FOR v_session IN
            SELECT s.id AS session_id, s.name
            FROM sessions s
            JOIN phases ph ON s.phase_id = ph.id
            JOIN programs p ON ph.program_id = p.id
            WHERE p.patient_id = v_pid
            ORDER BY ph.sequence, s.sequence
        LOOP
            v_session_num := v_session_num + 1;
            v_sched_date := CURRENT_DATE - (30 - v_session_num * 3);

            -- 80% completion rate: sessions 1-5 completed, session 6 missed
            IF v_session_num <= 4 THEN
                v_completed := true;
            ELSIF v_session_num = 5 THEN
                v_completed := true;
            ELSE
                v_completed := false;
            END IF;

            INSERT INTO session_status (patient_id, session_id, scheduled_date, status, completed_at, notes)
            VALUES (
                v_pid,
                v_session.session_id,
                v_sched_date,
                CASE WHEN v_completed THEN 'completed' ELSE 'missed' END,
                CASE WHEN v_completed THEN v_sched_date::timestamptz + INTERVAL '14 hours' ELSE NULL END,
                CASE WHEN v_completed THEN 'Completed on schedule' ELSE 'Missed - scheduling conflict' END
            )
            ON CONFLICT (patient_id, session_id, scheduled_date) DO NOTHING;

            -- Create exercise_logs for completed sessions
            IF v_completed THEN
                FOR v_se IN
                    SELECT se.id AS se_id, se.prescribed_load, se.prescribed_sets, se.prescribed_reps
                    FROM session_exercises se
                    WHERE se.session_id = v_session.session_id
                    ORDER BY se.sequence
                LOOP
                    -- Generate 3 sets per exercise
                    FOR v_set_num IN 1..3 LOOP
                        v_load := COALESCE(v_se.prescribed_load, 100) * (0.9 + random() * 0.2);
                        v_reps := GREATEST(1, CASE
                            WHEN v_se.prescribed_reps ~ '^\d+$' THEN v_se.prescribed_reps::int
                            ELSE 10
                        END + floor(random() * 3 - 1)::int);
                        v_rpe := LEAST(10, GREATEST(5, 6.5 + random() * 2.5));

                        INSERT INTO exercise_logs (
                            patient_id, session_id, session_exercise_id,
                            performed_at, set_number, actual_sets, actual_reps, actual_load,
                            load_unit, rpe, is_pr, notes
                        )
                        VALUES (
                            v_pid,
                            v_session.session_id,
                            v_se.se_id,
                            v_sched_date::timestamptz + INTERVAL '14 hours' + (v_set_num * INTERVAL '3 minutes'),
                            v_set_num,
                            3,
                            ARRAY[v_reps],
                            ROUND(v_load, 1),
                            'lbs',
                            ROUND(v_rpe::numeric, 1),
                            (v_set_num = 1 AND v_session_num = 4 AND random() < 0.3),
                            NULL
                        )
                        ON CONFLICT DO NOTHING;
                    END LOOP;
                END LOOP;
            END IF;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'Session status and exercise logs seeded';
END $$;


-- ============================================================================
-- SECTION D: DAILY READINESS (30 days, all 10 patients)
-- ============================================================================
-- The auto_calculate_readiness_trigger computes readiness_score automatically.
-- We do NOT include readiness_score in the INSERT.

DO $$
DECLARE
    v_day int;
    v_date date;
    v_sleep numeric(3,1);
    v_soreness int;
    v_energy int;
    v_stress int;
    v_variation numeric;
BEGIN
    FOR v_day IN 0..29 LOOP
        v_date := CURRENT_DATE - v_day;

        -- Use sin() for smooth variation + small random noise
        v_variation := sin(v_day * 0.5);

        -- Marcus: trending up (healing well)
        v_sleep := LEAST(10.0, GREATEST(4.0, 7.0 + (v_day::numeric / 30.0) * 1.5 + (random() - 0.5)))::numeric(3,1);
        v_soreness := GREATEST(1, LEAST(10, (4 - v_day / 10 + floor(random() * 2))::int));
        v_energy := GREATEST(1, LEAST(10, (6 + v_day / 10 + floor(random() * 2))::int));
        v_stress := GREATEST(1, LEAST(10, (4 - v_day / 15 + floor(random() * 2))::int));

        INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level)
        VALUES ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, v_date, v_sleep, v_soreness, v_energy, v_stress)
        ON CONFLICT (patient_id, date) DO NOTHING;

        -- Alyssa: stable high (pro discipline)
        v_sleep := LEAST(10.0, GREATEST(4.0, 7.5 + (random() * 1.0)))::numeric(3,1);
        v_soreness := GREATEST(1, LEAST(10, (3 + floor(random() * 2))::int));
        v_energy := GREATEST(1, LEAST(10, (7 + floor(random() * 2))::int));
        v_stress := GREATEST(1, LEAST(10, (2 + floor(random() * 2))::int));

        INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level)
        VALUES ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, v_date, v_sleep, v_soreness, v_energy, v_stress)
        ON CONFLICT (patient_id, date) DO NOTHING;

        -- Tyler: variable (college lifestyle - bad sleep some nights)
        v_sleep := LEAST(10.0, GREATEST(4.0, 6.0 + sin(v_day * 0.7) * 1.5 + (random() - 0.5)))::numeric(3,1);
        v_soreness := GREATEST(1, LEAST(10, (5 + floor(sin(v_day * 0.4) * 2 + random() * 2))::int));
        v_energy := GREATEST(1, LEAST(10, (5 + floor(sin(v_day * 0.6) * 2 + random() * 2))::int));
        v_stress := GREATEST(1, LEAST(10, (5 + floor(sin(v_day * 0.3) * 2 + random() * 2))::int));

        INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level)
        VALUES ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, v_date, v_sleep, v_soreness, v_energy, v_stress)
        ON CONFLICT (patient_id, date) DO NOTHING;

        -- Emma: trending up fast (young, quick healing)
        v_sleep := LEAST(10.0, GREATEST(4.0, 6.5 + (v_day::numeric / 20.0) * 1.5 + (random() - 0.5)))::numeric(3,1);
        v_soreness := GREATEST(1, LEAST(10, (5 - v_day / 7 + floor(random() * 2))::int));
        v_energy := GREATEST(1, LEAST(10, (5 + v_day / 8 + floor(random() * 2))::int));
        v_stress := GREATEST(1, LEAST(10, (5 - v_day / 10 + floor(random() * 2))::int));

        INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level)
        VALUES ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, v_date, v_sleep, v_soreness, v_energy, v_stress)
        ON CONFLICT (patient_id, date) DO NOTHING;

        -- Jordan: inconsistent (all over the place)
        v_sleep := LEAST(10.0, GREATEST(4.0, 5.5 + sin(v_day * 1.2) * 2.0 + (random() - 0.5)))::numeric(3,1);
        v_soreness := GREATEST(1, LEAST(10, (5 + floor(sin(v_day * 0.8) * 3 + random() * 2))::int));
        v_energy := GREATEST(1, LEAST(10, (4 + floor(sin(v_day * 0.9) * 3 + random() * 2))::int));
        v_stress := GREATEST(1, LEAST(10, (6 + floor(sin(v_day * 0.5) * 2 + random() * 2))::int));

        INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level)
        VALUES ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, v_date, v_sleep, v_soreness, v_energy, v_stress)
        ON CONFLICT (patient_id, date) DO NOTHING;

        -- Sophia: stable moderate
        v_sleep := LEAST(10.0, GREATEST(4.0, 6.8 + (random() * 0.8)))::numeric(3,1);
        v_soreness := GREATEST(1, LEAST(10, (4 + floor(random() * 2))::int));
        v_energy := GREATEST(1, LEAST(10, (6 + floor(random() * 2))::int));
        v_stress := GREATEST(1, LEAST(10, (4 + floor(random() * 2))::int));

        INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level)
        VALUES ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, v_date, v_sleep, v_soreness, v_energy, v_stress)
        ON CONFLICT (patient_id, date) DO NOTHING;

        -- Deshawn: stable high (elite discipline)
        v_sleep := LEAST(10.0, GREATEST(4.0, 7.8 + (random() * 0.6)))::numeric(3,1);
        v_soreness := GREATEST(1, LEAST(10, (2 + floor(random() * 2))::int));
        v_energy := GREATEST(1, LEAST(10, (8 + floor(random() * 2))::int));
        v_stress := GREATEST(1, LEAST(10, (2 + floor(random() * 2))::int));

        INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level)
        VALUES ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, v_date, v_sleep, v_soreness, v_energy, v_stress)
        ON CONFLICT (patient_id, date) DO NOTHING;

        -- Olivia: low/adjusting (new to training)
        v_sleep := LEAST(10.0, GREATEST(4.0, 5.8 + (random() * 1.0)))::numeric(3,1);
        v_soreness := GREATEST(1, LEAST(10, (6 + floor(random() * 2))::int));
        v_energy := GREATEST(1, LEAST(10, (5 + floor(random() * 2))::int));
        v_stress := GREATEST(1, LEAST(10, (6 + floor(random() * 2))::int));

        INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level)
        VALUES ('aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid, v_date, v_sleep, v_soreness, v_energy, v_stress)
        ON CONFLICT (patient_id, date) DO NOTHING;

        -- Liam: trending DOWN (fatigue accumulating)
        v_sleep := LEAST(10.0, GREATEST(4.0, 7.0 - (v_day::numeric / 20.0) * 1.5 + (random() - 0.5)))::numeric(3,1);
        v_soreness := GREATEST(1, LEAST(10, (4 + v_day / 8 + floor(random() * 2))::int));
        v_energy := GREATEST(1, LEAST(10, (7 - v_day / 8 + floor(random() * 2))::int));
        v_stress := GREATEST(1, LEAST(10, (4 + v_day / 10 + floor(random() * 2))::int));

        INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level)
        VALUES ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, v_date, v_sleep, v_soreness, v_energy, v_stress)
        ON CONFLICT (patient_id, date) DO NOTHING;

        -- Isabella: variable (recreational)
        v_sleep := LEAST(10.0, GREATEST(4.0, 6.5 + sin(v_day * 0.6) * 1.2 + (random() - 0.5)))::numeric(3,1);
        v_soreness := GREATEST(1, LEAST(10, (4 + floor(sin(v_day * 0.5) * 2 + random() * 2))::int));
        v_energy := GREATEST(1, LEAST(10, (5 + floor(sin(v_day * 0.7) * 2 + random() * 2))::int));
        v_stress := GREATEST(1, LEAST(10, (4 + floor(sin(v_day * 0.4) * 2 + random() * 2))::int));

        INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level)
        VALUES ('aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid, v_date, v_sleep, v_soreness, v_energy, v_stress)
        ON CONFLICT (patient_id, date) DO NOTHING;
    END LOOP;

    RAISE NOTICE 'Daily readiness data seeded for 30 days x 10 patients';
END $$;


-- ============================================================================
-- SECTION E: NUTRITION GOALS + LOGS
-- ============================================================================
-- Create one active nutrition_goal per patient (8 patients).
-- Then generate 14 days of nutrition logs with realistic meal distributions.

-- Nutrition Goals (using the actual schema columns from nutrition_goals table)
INSERT INTO nutrition_goals (patient_id, daily_calories, daily_protein_grams, daily_carbs_grams, daily_fats_grams, active, notes)
VALUES
    -- Marcus: 2800 cal, bulking for baseball
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, 2800, 180.0, 320.0, 90.0, true, 'Labrum recovery nutrition - high protein for tissue repair'),
    -- Alyssa: 2400 cal, lean muscle maintenance
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 2400, 160.0, 260.0, 80.0, true, 'ACL recovery - support muscle rebuilding around knee'),
    -- Tyler: 3200 cal, football bulk
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, 3200, 200.0, 380.0, 100.0, true, 'Off-season mass building for WR position'),
    -- Jordan: 2600 cal, functional fitness
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, 2600, 170.0, 290.0, 85.0, true, 'CrossFit-style nutrition with shoulder recovery focus'),
    -- Deshawn: 2800 cal, sprint performance
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, 2800, 175.0, 340.0, 80.0, true, 'Sprinter nutrition - high carb for explosiveness'),
    -- Olivia: 2000 cal, growing athlete
    ('aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid, 2000, 120.0, 240.0, 65.0, true, 'HS athlete fuel - balanced growth nutrition'),
    -- Liam: 3000 cal, hockey performance
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, 3000, 190.0, 340.0, 95.0, true, 'Pro hockey nutrition - high demands despite rehab'),
    -- Isabella: 2200 cal, recreational fitness
    ('aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid, 2200, 130.0, 260.0, 75.0, true, 'Tennis recovery - anti-inflammatory emphasis')
ON CONFLICT DO NOTHING;


-- Nutrition Logs: 14 days x 3-4 meals per patient
DO $$
DECLARE
    v_day int;
    v_date date;
    v_logged_at timestamptz;
    v_cals int;
    v_prot numeric;
    v_carbs numeric;
    v_fats numeric;
    v_variation numeric;
    -- Patient calorie targets for distribution
    v_patient_ids uuid[] := ARRAY[
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid
    ];
    v_daily_cals int[] := ARRAY[2800, 2400, 3200, 2600, 2800, 2000, 3000, 2200];
    v_daily_prot numeric[] := ARRAY[180, 160, 200, 170, 175, 120, 190, 130];
    v_daily_carbs numeric[] := ARRAY[320, 260, 380, 290, 340, 240, 340, 260];
    v_daily_fats numeric[] := ARRAY[90, 80, 100, 85, 80, 65, 95, 75];
    v_pid uuid;
    v_idx int;
BEGIN
    FOR v_day IN 0..13 LOOP
        v_date := CURRENT_DATE - v_day;

        FOR v_idx IN 1..8 LOOP
            v_pid := v_patient_ids[v_idx];

            -- BREAKFAST (~25% of daily target with +/-15% variation)
            v_variation := 0.85 + random() * 0.30;
            v_cals := (v_daily_cals[v_idx] * 0.25 * v_variation)::int;
            v_prot := ROUND((v_daily_prot[v_idx] * 0.25 * v_variation)::numeric, 1);
            v_carbs := ROUND((v_daily_carbs[v_idx] * 0.25 * v_variation)::numeric, 1);
            v_fats := ROUND((v_daily_fats[v_idx] * 0.25 * v_variation)::numeric, 1);
            v_logged_at := v_date::timestamptz + INTERVAL '7 hours' + (random() * INTERVAL '1 hour');

            INSERT INTO nutrition_logs (patient_id, log_date, logged_at, meal_type, description, calories, protein_grams, carbs_grams, fats_grams, notes)
            VALUES (v_pid, v_date, v_logged_at, 'breakfast', 'Breakfast meal', v_cals, v_prot, v_carbs, v_fats, NULL)
            ON CONFLICT DO NOTHING;

            -- LUNCH (~30% of daily target)
            v_variation := 0.85 + random() * 0.30;
            v_cals := (v_daily_cals[v_idx] * 0.30 * v_variation)::int;
            v_prot := ROUND((v_daily_prot[v_idx] * 0.30 * v_variation)::numeric, 1);
            v_carbs := ROUND((v_daily_carbs[v_idx] * 0.30 * v_variation)::numeric, 1);
            v_fats := ROUND((v_daily_fats[v_idx] * 0.30 * v_variation)::numeric, 1);
            v_logged_at := v_date::timestamptz + INTERVAL '12 hours' + (random() * INTERVAL '1 hour');

            INSERT INTO nutrition_logs (patient_id, log_date, logged_at, meal_type, description, calories, protein_grams, carbs_grams, fats_grams, notes)
            VALUES (v_pid, v_date, v_logged_at, 'lunch', 'Lunch meal', v_cals, v_prot, v_carbs, v_fats, NULL)
            ON CONFLICT DO NOTHING;

            -- DINNER (~35% of daily target)
            v_variation := 0.85 + random() * 0.30;
            v_cals := (v_daily_cals[v_idx] * 0.35 * v_variation)::int;
            v_prot := ROUND((v_daily_prot[v_idx] * 0.35 * v_variation)::numeric, 1);
            v_carbs := ROUND((v_daily_carbs[v_idx] * 0.35 * v_variation)::numeric, 1);
            v_fats := ROUND((v_daily_fats[v_idx] * 0.35 * v_variation)::numeric, 1);
            v_logged_at := v_date::timestamptz + INTERVAL '18 hours' + (random() * INTERVAL '1 hour');

            INSERT INTO nutrition_logs (patient_id, log_date, logged_at, meal_type, description, calories, protein_grams, carbs_grams, fats_grams, notes)
            VALUES (v_pid, v_date, v_logged_at, 'dinner', 'Dinner meal', v_cals, v_prot, v_carbs, v_fats, NULL)
            ON CONFLICT DO NOTHING;

            -- SNACK (~10% of daily target, only on ~60% of days)
            IF random() < 0.6 THEN
                v_variation := 0.85 + random() * 0.30;
                v_cals := (v_daily_cals[v_idx] * 0.10 * v_variation)::int;
                v_prot := ROUND((v_daily_prot[v_idx] * 0.10 * v_variation)::numeric, 1);
                v_carbs := ROUND((v_daily_carbs[v_idx] * 0.10 * v_variation)::numeric, 1);
                v_fats := ROUND((v_daily_fats[v_idx] * 0.10 * v_variation)::numeric, 1);
                v_logged_at := v_date::timestamptz + INTERVAL '15 hours' + (random() * INTERVAL '2 hours');

                INSERT INTO nutrition_logs (patient_id, log_date, logged_at, meal_type, description, calories, protein_grams, carbs_grams, fats_grams, notes)
                VALUES (v_pid, v_date, v_logged_at, 'snack', 'Afternoon snack', v_cals, v_prot, v_carbs, v_fats, NULL)
                ON CONFLICT DO NOTHING;
            END IF;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'Nutrition logs seeded for 14 days x 8 patients';
END $$;


-- ============================================================================
-- SECTION F: BODY COMPOSITIONS
-- ============================================================================
-- Monthly measurements for each patient showing realistic trends.
-- 2-6 measurements per patient spanning the last 5 months.

INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, lean_mass_lb, notes)
VALUES
    -- Marcus Rivera (190 lbs, healing, maintaining weight)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, (NOW() - INTERVAL '120 days')::date, 192.0, 14.2, 148.0, 'Pre-surgery baseline'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, (NOW() - INTERVAL '90 days')::date,  189.5, 14.8, 145.0, 'Post-surgery 1 month'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, (NOW() - INTERVAL '60 days')::date,  190.0, 14.0, 147.0, 'Regaining muscle'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, (NOW() - INTERVAL '30 days')::date,  191.5, 13.5, 149.0, 'Good progress'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, (NOW() - INTERVAL '3 days')::date,   192.0, 13.0, 150.5, 'Nearly back to baseline'),

    -- Alyssa Chen (145 lbs, pro athlete, consistent)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, (NOW() - INTERVAL '90 days')::date,  146.0, 18.5, 107.0, 'ACL rehab start'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, (NOW() - INTERVAL '60 days')::date,  145.0, 18.0, 107.5, 'Slight quad atrophy on surgical side'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, (NOW() - INTERVAL '30 days')::date,  146.5, 17.5, 109.0, 'Quad rebuilding nicely'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, (NOW() - INTERVAL '5 days')::date,   147.0, 17.0, 110.0, 'Strong improvement'),

    -- Tyler Brooks (205 lbs, college football, gaining muscle)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, (NOW() - INTERVAL '90 days')::date,  200.0, 16.0, 150.0, 'Start of off-season'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, (NOW() - INTERVAL '60 days')::date,  203.0, 15.5, 153.0, 'Adding lean mass'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, (NOW() - INTERVAL '30 days')::date,  205.0, 15.0, 156.0, 'On track for season'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, (NOW() - INTERVAL '7 days')::date,   207.0, 14.8, 158.0, 'Excellent body comp changes'),

    -- Emma Fitzgerald (130 lbs, HS soccer, growing)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, (NOW() - INTERVAL '60 days')::date,  128.0, 22.0, 90.0, 'Initial assessment'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, (NOW() - INTERVAL '14 days')::date,  130.0, 21.5, 92.0, 'Healthy growth'),

    -- Jordan Williams (185 lbs, CrossFit, recomposition)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, (NOW() - INTERVAL '150 days')::date, 188.0, 18.0, 138.0, 'Before shoulder injury'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, (NOW() - INTERVAL '90 days')::date,  185.0, 19.0, 134.0, 'Lost some muscle during rest'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, (NOW() - INTERVAL '60 days')::date,  184.0, 18.5, 135.0, 'Starting to recover'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, (NOW() - INTERVAL '30 days')::date,  185.0, 17.8, 137.0, 'Good recomp progress'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, (NOW() - INTERVAL '5 days')::date,   186.0, 17.0, 139.0, 'Approaching pre-injury levels'),

    -- Sophia Nakamura (140 lbs, college swimmer, lean)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, (NOW() - INTERVAL '30 days')::date,  139.0, 20.0, 100.0, 'Swimmer build assessment'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, (NOW() - INTERVAL '7 days')::date,   140.0, 19.5, 101.5, 'Maintaining well'),

    -- Deshawn Patterson (175 lbs, track sprinter, very lean)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, (NOW() - INTERVAL '120 days')::date, 176.0, 8.5, 145.0, 'Pre-quad strain'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, (NOW() - INTERVAL '90 days')::date,  174.0, 9.0, 142.0, 'Lost some leg mass'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, (NOW() - INTERVAL '60 days')::date,  175.0, 8.8, 143.5, 'Rebuilding'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, (NOW() - INTERVAL '30 days')::date,  176.5, 8.2, 146.0, 'Almost recovered'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, (NOW() - INTERVAL '5 days')::date,   177.0, 8.0, 147.0, 'Sprint-ready composition'),

    -- Olivia Martinez (150 lbs, HS volleyball, developing)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid, (NOW() - INTERVAL '14 days')::date,  149.0, 24.0, 102.0, 'Initial assessment'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid, (NOW() - INTERVAL '3 days')::date,   150.0, 23.5, 103.5, 'Early progress'),

    -- Liam O''Connor (200 lbs, pro hockey, declining slightly due to fatigue)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, (NOW() - INTERVAL '150 days')::date, 202.0, 13.0, 158.0, 'Pre-surgery'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, (NOW() - INTERVAL '120 days')::date, 198.0, 14.0, 153.0, 'Post-surgery 1 month'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, (NOW() - INTERVAL '90 days')::date,  199.0, 13.5, 155.0, 'Slow recovery'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, (NOW() - INTERVAL '60 days')::date,  200.0, 13.8, 155.0, 'Plateauing, fatigue issue'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, (NOW() - INTERVAL '30 days')::date,  199.5, 14.2, 154.0, 'Need to address fatigue'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, (NOW() - INTERVAL '5 days')::date,   199.0, 14.5, 153.0, 'Declining trend'),

    -- Isabella Rossi (135 lbs, recreational tennis)
    ('aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid, (NOW() - INTERVAL '60 days')::date,  136.0, 23.0, 94.0, 'Starting point'),
    ('aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid, (NOW() - INTERVAL '30 days')::date,  135.5, 22.5, 95.0, 'Slight improvement'),
    ('aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid, (NOW() - INTERVAL '7 days')::date,   135.0, 22.0, 96.0, 'Steady recomposition')
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SECTION G: PAIN LOGS
-- ============================================================================
-- Pain logs for 5 rehab patients: Marcus, Alyssa, Emma, Sophia, Liam.
-- One per week for 4-6 weeks, showing downward trends (except Sophia fluctuates).
-- session_id is NULL since we may not have valid session references for all.

INSERT INTO pain_logs (patient_id, session_id, logged_at, pain_rest, pain_during, pain_after, notes)
VALUES
    -- Marcus: steady downward trend (labrum repair healing well)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, NULL, NOW() - INTERVAL '42 days', 4, 6, 7, 'Early rehab, significant discomfort during overhead'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, NULL, NOW() - INTERVAL '35 days', 3, 5, 6, 'Improving but still sore after sessions'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, NULL, NOW() - INTERVAL '28 days', 2, 4, 5, 'Much better, less pain at rest'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, NULL, NOW() - INTERVAL '21 days', 2, 3, 4, 'Good progress, manageable pain during exercises'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, NULL, NOW() - INTERVAL '14 days', 1, 2, 3, 'Minimal resting pain, tolerable during activity'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, NULL, NOW() - INTERVAL '7 days',  1, 2, 2, 'Near pain-free at rest, slight discomfort at end range'),

    -- Alyssa: rapid improvement (pro athlete, disciplined rehab)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, NULL, NOW() - INTERVAL '28 days', 3, 5, 6, 'ACL rehab starting, knee swelling still present'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, NULL, NOW() - INTERVAL '21 days', 2, 4, 4, 'Swelling down, pain manageable'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, NULL, NOW() - INTERVAL '14 days', 1, 3, 3, 'Good quad activation, minimal pain'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, NULL, NOW() - INTERVAL '7 days',  1, 2, 2, 'Ready for sport-specific phase'),

    -- Emma: fast improvement (young, ankle sprain)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, NULL, NOW() - INTERVAL '14 days', 3, 5, 5, 'Ankle still tender, using brace'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, NULL, NOW() - INTERVAL '10 days', 2, 3, 4, 'Much better, walking without limp'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, NULL, NOW() - INTERVAL '7 days',  1, 2, 3, 'Light jogging pain-free'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, NULL, NOW() - INTERVAL '3 days',  1, 1, 2, 'Almost fully recovered'),

    -- Sophia: fluctuating (shoulder impingement, not consistently improving)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, NULL, NOW() - INTERVAL '28 days', 3, 5, 5, 'Shoulder catching during freestyle stroke'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, NULL, NOW() - INTERVAL '21 days', 2, 4, 4, 'Better after rest weekend'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, NULL, NOW() - INTERVAL '14 days', 3, 5, 6, 'Flare-up after increased training volume'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, NULL, NOW() - INTERVAL '7 days',  2, 4, 5, 'Slightly better but still inconsistent'),

    -- Liam: slow improvement then regression (hip labral tear, fatigue accumulating)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, NULL, NOW() - INTERVAL '42 days', 5, 7, 8, 'Post-surgical, significant hip pain'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, NULL, NOW() - INTERVAL '35 days', 4, 6, 7, 'Gradual improvement'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, NULL, NOW() - INTERVAL '28 days', 3, 5, 6, 'Progressing well'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, NULL, NOW() - INTERVAL '21 days', 3, 4, 5, 'Plateau in improvement'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, NULL, NOW() - INTERVAL '14 days', 3, 5, 6, 'Regression - pushed too hard on skating drills'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, NULL, NOW() - INTERVAL '7 days',  4, 5, 6, 'Still elevated, need to manage load')
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SECTION H: STREAKS
-- ============================================================================
-- Disable the streak trigger before bulk inserting to avoid cascading calculations.

ALTER TABLE streak_history DISABLE TRIGGER trg_update_streak_on_activity;

-- Streak Records (workout type for all 10 patients)
INSERT INTO streak_records (patient_id, streak_type, current_streak, longest_streak, last_activity_date, streak_start_date)
VALUES
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, 'workout', 12, 15, CURRENT_DATE, CURRENT_DATE - 11),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 'workout', 18, 22, CURRENT_DATE, CURRENT_DATE - 17),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, 'workout', 3,  8,  CURRENT_DATE, CURRENT_DATE - 2),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, 'workout', 7,  7,  CURRENT_DATE, CURRENT_DATE - 6),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, 'workout', 1,  12, CURRENT_DATE, CURRENT_DATE),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, 'workout', 5,  10, CURRENT_DATE, CURRENT_DATE - 4),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, 'workout', 21, 21, CURRENT_DATE, CURRENT_DATE - 20),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid, 'workout', 4,  4,  CURRENT_DATE, CURRENT_DATE - 3),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, 'workout', 8,  14, CURRENT_DATE, CURRENT_DATE - 7),
    ('aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid, 'workout', 2,  6,  CURRENT_DATE, CURRENT_DATE - 1)
ON CONFLICT (patient_id, streak_type) DO NOTHING;


-- Streak History: daily activity entries for the last 30 days
DO $$
DECLARE
    v_day int;
    v_date date;
    v_patient_ids uuid[] := ARRAY[
        'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid,
        'aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid
    ];
    -- Compliance rates: how often each patient works out (probability per day)
    v_compliance numeric[] := ARRAY[0.75, 0.85, 0.50, 0.65, 0.40, 0.60, 0.90, 0.55, 0.70, 0.45];
    v_pid uuid;
    v_idx int;
    v_workout boolean;
    v_arm_care boolean;
BEGIN
    FOR v_day IN 0..29 LOOP
        v_date := CURRENT_DATE - v_day;

        FOR v_idx IN 1..10 LOOP
            v_pid := v_patient_ids[v_idx];
            v_workout := random() < v_compliance[v_idx];
            v_arm_care := random() < (v_compliance[v_idx] * 0.5); -- Arm care is less consistent

            -- Only insert if at least one activity was done
            IF v_workout OR v_arm_care THEN
                INSERT INTO streak_history (patient_id, activity_date, workout_completed, arm_care_completed, notes)
                VALUES (v_pid, v_date, v_workout, v_arm_care, NULL)
                ON CONFLICT (patient_id, activity_date) DO NOTHING;
            END IF;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'Streak history seeded for 30 days x 10 patients';
END $$;

-- Re-enable the streak trigger
ALTER TABLE streak_history ENABLE TRIGGER trg_update_streak_on_activity;


-- ============================================================================
-- SECTION I: PATIENT GOALS
-- ============================================================================
-- 2 goals per patient. Mix of active and completed.

INSERT INTO patient_goals (patient_id, title, description, category, target_value, current_value, unit, target_date, status)
VALUES
    -- Marcus Rivera
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, 'Full Shoulder ROM', 'Achieve full external rotation range of motion post-labrum repair', 'rehabilitation', 180, 155, 'degrees', CURRENT_DATE + 30, 'active'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, 'Pain-Free Throwing', 'Complete 30 throws at 60% effort with zero pain', 'pain_reduction', 0, 1.5, 'pain score', CURRENT_DATE + 45, 'active'),

    -- Alyssa Chen
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 'Single Leg Squat Symmetry', 'Achieve 90% symmetry index on single leg squat', 'rehabilitation', 90, 78, 'percent', CURRENT_DATE + 60, 'active'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 'Vertical Jump Recovery', 'Return to pre-injury vertical jump of 28 inches', 'strength', 28, 22, 'inches', CURRENT_DATE + 90, 'active'),

    -- Tyler Brooks
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, '40-Yard Dash Time', 'Hit 4.45 second 40-yard dash for combine prep', 'endurance', 4.45, 4.55, 'seconds', CURRENT_DATE + 60, 'active'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, 'Squat 1RM Goal', 'Reach 315 lb back squat 1RM', 'strength', 315, 285, 'lbs', CURRENT_DATE + 45, 'active'),

    -- Emma Fitzgerald
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, 'Return to Soccer Practice', 'Clear for full soccer practice without ankle brace', 'rehabilitation', 1, 0, 'cleared', CURRENT_DATE + 14, 'active'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, 'Pain-Free Running', 'Run 2 miles continuously with no ankle pain', 'pain_reduction', 0, 1, 'pain score', CURRENT_DATE + 7, 'completed'),

    -- Jordan Williams
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, 'Overhead Press Recovery', 'Achieve pain-free overhead pressing at 95 lbs', 'rehabilitation', 95, 65, 'lbs', CURRENT_DATE + 45, 'active'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, 'Body Fat Goal', 'Reduce body fat to 15% while maintaining muscle', 'body_composition', 15, 17, 'percent', CURRENT_DATE + 90, 'active'),

    -- Sophia Nakamura
    ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, 'Pain-Free Freestyle', 'Swim 200m freestyle with no shoulder impingement pain', 'pain_reduction', 0, 3, 'pain score', CURRENT_DATE + 30, 'active'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, 'Scapular Stability', 'Hold Y-raise for 30 seconds with proper form', 'strength', 30, 18, 'seconds', CURRENT_DATE + 21, 'active'),

    -- Deshawn Patterson
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, 'Return to Full Sprint', 'Complete 100m sprint at 95% effort with no quad pain', 'rehabilitation', 95, 85, 'percent effort', CURRENT_DATE + 14, 'active'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, 'Hamstring-Quad Ratio', 'Achieve 0.65 H:Q ratio for injury prevention', 'strength', 0.65, 0.58, 'ratio', CURRENT_DATE + 30, 'active'),

    -- Olivia Martinez
    ('aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid, 'Bodyweight Squat Form', 'Complete 20 consecutive bodyweight squats with perfect form', 'strength', 20, 12, 'reps', CURRENT_DATE + 14, 'active'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid, 'Reduce Knee Pain', 'Patellar tendon pain below 2/10 during jumping', 'pain_reduction', 2, 5, 'pain score', CURRENT_DATE + 30, 'active'),

    -- Liam O''Connor
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, 'Hip Flexion ROM', 'Achieve 120 degrees hip flexion on surgical side', 'rehabilitation', 120, 95, 'degrees', CURRENT_DATE + 45, 'active'),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, 'Skating Readiness', 'Complete 20-minute continuous skating session', 'endurance', 20, 8, 'minutes', CURRENT_DATE + 60, 'active'),

    -- Isabella Rossi
    ('aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid, 'Tennis Elbow Pain Reduction', 'Reduce forehand pain to 1/10 or less', 'pain_reduction', 1, 4, 'pain score', CURRENT_DATE + 30, 'active'),
    ('aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid, 'Grip Strength Recovery', 'Achieve 35 kg grip strength on affected side', 'strength', 35, 25, 'kg', CURRENT_DATE + 45, 'active')
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SECTION J: PATIENT ACHIEVEMENTS
-- ============================================================================
-- Range from 1 to 7+ per patient. Mix of achievement types.

INSERT INTO patient_achievements (patient_id, achievement_type, title, description, earned_at, metadata)
VALUES
    -- Marcus Rivera (5 achievements)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, 'streak', 'Week Warrior', 'Completed 7 consecutive workout days', NOW() - INTERVAL '20 days', '{"streak_count": 7}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, 'milestone', 'First Session Complete', 'Completed first rehab session', NOW() - INTERVAL '42 days', '{"session_name": "Shoulder Mobility A"}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, 'consistency', 'Readiness Tracker', 'Logged daily readiness 14 days in a row', NOW() - INTERVAL '15 days', '{"days": 14}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, 'pr', 'Bench Press PR', 'New bench press personal record: 155 lbs', NOW() - INTERVAL '5 days', '{"exercise": "Bench Press", "weight_lbs": 155, "reps": 5}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid, 'milestone', 'Phase 1 Complete', 'Completed Phase 1: Mobility & Activation', NOW() - INTERVAL '21 days', '{"phase_name": "Mobility & Activation"}'::jsonb),

    -- Alyssa Chen (7 achievements - pro discipline)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 'streak', '2-Week Streak', 'Completed 14 consecutive workout days', NOW() - INTERVAL '10 days', '{"streak_count": 14}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 'streak', '3-Week Streak', 'Completed 21 consecutive workout days', NOW() - INTERVAL '3 days', '{"streak_count": 21}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 'milestone', 'First Session Complete', 'Completed first ACL rehab session', NOW() - INTERVAL '28 days', '{"session_name": "Knee Rehab A"}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 'consistency', 'Nutrition Star', 'Logged all meals for 7 consecutive days', NOW() - INTERVAL '12 days', '{"days": 7}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 'consistency', 'Readiness Tracker', 'Logged daily readiness 21 days in a row', NOW() - INTERVAL '5 days', '{"days": 21}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 'milestone', 'Phase 1 Complete', 'Completed Phase 1: Foundation', NOW() - INTERVAL '14 days', '{"phase_name": "Foundation"}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid, 'pr', 'Goblet Squat PR', 'New goblet squat PR: 45 lbs x 12', NOW() - INTERVAL '7 days', '{"exercise": "Goblet Squat", "weight_lbs": 45, "reps": 12}'::jsonb),

    -- Tyler Brooks (3 achievements)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, 'milestone', 'First Session Complete', 'Completed first performance session', NOW() - INTERVAL '21 days', '{"session_name": "Lower Strength A"}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, 'pr', 'Squat PR', 'New squat personal record: 285 lbs', NOW() - INTERVAL '8 days', '{"exercise": "Barbell Squat", "weight_lbs": 285, "reps": 3}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid, 'streak', '5-Day Streak', 'Completed 5 consecutive workout days', NOW() - INTERVAL '12 days', '{"streak_count": 5}'::jsonb),

    -- Emma Fitzgerald (2 achievements)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, 'milestone', 'First Jog', 'First pain-free jogging session post-sprain', NOW() - INTERVAL '5 days', '{"distance_miles": 0.5}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid, 'streak', 'Week Warrior', 'Completed 7 consecutive workout days', NOW() - INTERVAL '3 days', '{"streak_count": 7}'::jsonb),

    -- Jordan Williams (4 achievements)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, 'milestone', 'First Session Complete', 'Started shoulder-safe program', NOW() - INTERVAL '56 days', '{"session_name": "Lower Body A"}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, 'pr', 'Deadlift PR', 'New deadlift personal record: 225 lbs', NOW() - INTERVAL '20 days', '{"exercise": "Deadlift", "weight_lbs": 225, "reps": 5}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, 'streak', '10-Day Streak', 'Completed 10 consecutive workout days', NOW() - INTERVAL '15 days', '{"streak_count": 10}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid, 'consistency', 'Body Comp Tracker', 'Logged body composition 5 times', NOW() - INTERVAL '5 days', '{"count": 5}'::jsonb),

    -- Sophia Nakamura (1 achievement)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid, 'milestone', 'Started Rehab', 'Began shoulder impingement rehabilitation', NOW() - INTERVAL '10 days', '{"program": "Shoulder Rehab"}'::jsonb),

    -- Deshawn Patterson (6 achievements - disciplined athlete)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, 'streak', '2-Week Streak', 'Completed 14 consecutive workout days', NOW() - INTERVAL '20 days', '{"streak_count": 14}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, 'streak', '3-Week Streak', 'Completed 21 consecutive workout days', NOW() - INTERVAL '1 day', '{"streak_count": 21}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, 'milestone', 'First Session Complete', 'Completed first sprint rehab session', NOW() - INTERVAL '35 days', '{"session_name": "Rehab Session A"}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, 'milestone', 'Phase 1 Complete', 'Completed Phase 1: Recovery & Base', NOW() - INTERVAL '14 days', '{"phase_name": "Recovery & Base"}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, 'consistency', 'Readiness Tracker', 'Logged daily readiness 28 days in a row', NOW() - INTERVAL '2 days', '{"days": 28}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid, 'consistency', 'Nutrition Star', 'Logged all meals for 14 consecutive days', NOW() - INTERVAL '3 days', '{"days": 14}'::jsonb),

    -- Olivia Martinez (2 achievements)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid, 'milestone', 'First Training Session', 'Completed first strength training session ever', NOW() - INTERVAL '7 days', '{"session_name": "Movement 101 A"}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid, 'streak', '3-Day Streak', 'Completed 3 consecutive workout days', NOW() - INTERVAL '2 days', '{"streak_count": 3}'::jsonb),

    -- Liam O''Connor (4 achievements)
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, 'milestone', 'First Session Complete', 'Completed first hip rehab session', NOW() - INTERVAL '49 days', '{"session_name": "Hip Mobility A"}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, 'streak', 'Week Warrior', 'Completed 7 consecutive workout days', NOW() - INTERVAL '30 days', '{"streak_count": 7}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, 'streak', '2-Week Streak', 'Completed 14 consecutive workout days', NOW() - INTERVAL '18 days', '{"streak_count": 14}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid, 'milestone', 'Phase 1 Complete', 'Completed Phase 1: Post-Op Mobility', NOW() - INTERVAL '20 days', '{"phase_name": "Post-Op Mobility"}'::jsonb),

    -- Isabella Rossi (2 achievements)
    ('aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid, 'milestone', 'Started Program', 'Began tennis elbow rehabilitation', NOW() - INTERVAL '25 days', '{"program": "Tennis Elbow Rehab"}'::jsonb),
    ('aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid, 'consistency', 'Readiness Tracker', 'Logged daily readiness 7 days in a row', NOW() - INTERVAL '10 days', '{"days": 7}'::jsonb)
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SECTION K: VERIFICATION
-- ============================================================================

SELECT 'Test data seeding complete' AS status;

SELECT p.first_name, p.last_name,
    (SELECT COUNT(*) FROM daily_readiness dr WHERE dr.patient_id = p.id) AS readiness_days,
    (SELECT COUNT(*) FROM nutrition_logs nl WHERE nl.patient_id = p.id) AS nutrition_logs,
    (SELECT COUNT(*) FROM body_comp_measurements bc WHERE bc.patient_id = p.id) AS body_comp_entries,
    (SELECT COUNT(*) FROM patient_goals pg WHERE pg.patient_id = p.id) AS goals,
    (SELECT COUNT(*) FROM patient_achievements pa WHERE pa.patient_id = p.id) AS achievements,
    (SELECT current_streak FROM streak_records sr WHERE sr.patient_id = p.id AND sr.streak_type = 'workout') AS current_streak
FROM patients p
WHERE p.id IN (
    'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000002'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000003'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000004'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000006'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000007'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000008'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000009'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-00000000000a'::uuid
)
ORDER BY p.first_name;

-- Force PostgREST schema reload
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
