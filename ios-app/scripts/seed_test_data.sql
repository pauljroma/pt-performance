-- Test Data Seeding Script for PTPerformance
-- Build 69 - Agent 17: Testing
-- This script creates comprehensive test data for unit and E2E testing

-- Clean up existing test data (optional - uncomment if needed)
-- DELETE FROM exercise_logs WHERE patient_id IN (SELECT id FROM patients WHERE email LIKE '%test%');
-- DELETE FROM session_exercises WHERE session_id IN (SELECT id FROM sessions WHERE phase_id IN (SELECT id FROM phases WHERE program_id IN (SELECT id FROM programs WHERE name LIKE '%Test%')));
-- DELETE FROM sessions WHERE phase_id IN (SELECT id FROM phases WHERE program_id IN (SELECT id FROM programs WHERE name LIKE '%Test%')));
-- DELETE FROM phases WHERE program_id IN (SELECT id FROM programs WHERE name LIKE '%Test%');
-- DELETE FROM programs WHERE name LIKE '%Test%';
-- DELETE FROM patients WHERE email LIKE '%test%';
-- DELETE FROM therapists WHERE email LIKE '%test%';

-- ================================================================
-- TEST THERAPISTS
-- ================================================================

INSERT INTO therapists (id, auth_user_id, first_name, last_name, email, created_at)
VALUES
    ('11111111-1111-1111-1111-111111111111', NULL, 'Test', 'Therapist', 'test-therapist@ptperformance.app', NOW()),
    ('22222222-2222-2222-2222-222222222222', NULL, 'Jane', 'Smith', 'test-therapist-2@ptperformance.app', NOW())
ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- TEST PATIENTS
-- ================================================================

INSERT INTO patients (id, auth_user_id, therapist_id, first_name, last_name, email, sport, position, created_at)
VALUES
    ('33333333-3333-3333-3333-333333333333', NULL, '11111111-1111-1111-1111-111111111111',
     'Test', 'Patient', 'test-patient@ptperformance.app', 'Basketball', 'Forward', NOW()),
    ('44444444-4444-4444-4444-444444444444', NULL, '11111111-1111-1111-1111-111111111111',
     'Another', 'TestPatient', 'test-patient-2@ptperformance.app', 'Baseball', 'Pitcher', NOW()),
    ('55555555-5555-5555-5555-555555555555', NULL, '22222222-2222-2222-2222-222222222222',
     'Third', 'TestPatient', 'test-patient-3@ptperformance.app', 'Football', 'Quarterback', NOW())
ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- TEST EXERCISE TEMPLATES
-- ================================================================

INSERT INTO exercise_templates (id, name, category, body_region, description, created_at)
VALUES
    ('ex-00000001-0000-0000-0000-000000000001', 'Test Squat', 'Strength', 'Lower Body', 'Basic squat exercise for testing', NOW()),
    ('ex-00000002-0000-0000-0000-000000000002', 'Test Bench Press', 'Strength', 'Upper Body', 'Basic bench press for testing', NOW()),
    ('ex-00000003-0000-0000-0000-000000000003', 'Test Deadlift', 'Strength', 'Lower Body', 'Basic deadlift for testing', NOW()),
    ('ex-00000004-0000-0000-0000-000000000004', 'Test Pull-up', 'Strength', 'Upper Body', 'Basic pull-up for testing', NOW()),
    ('ex-00000005-0000-0000-0000-000000000005', 'Test Lunge', 'Strength', 'Lower Body', 'Basic lunge for testing', NOW())
ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- TEST PROGRAMS
-- ================================================================

INSERT INTO programs (id, patient_id, therapist_id, name, description, target_level, duration_weeks, start_date, status, created_at, updated_at)
VALUES
    ('prog-0000001-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111',
     'Test Program 1', 'Comprehensive test program for E2E testing', 'Intermediate', 8, NOW() - INTERVAL '4 weeks', 'active', NOW(), NOW()),
    ('prog-0000002-0000-0000-0000-000000000002', '44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111',
     'Test Program 2', 'Advanced test program', 'Advanced', 12, NOW() - INTERVAL '2 weeks', 'active', NOW(), NOW()),
    ('prog-0000003-0000-0000-0000-000000000003', '55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222',
     'Test Program 3', 'Beginner test program', 'Beginner', 6, NOW() - INTERVAL '1 week', 'active', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- TEST PHASES
-- ================================================================

INSERT INTO phases (id, program_id, phase_number, name, duration_weeks, goals, created_at)
VALUES
    -- Program 1 phases
    ('phase-000001-0000-0000-0000-000000000001', 'prog-0000001-0000-0000-0000-000000000001', 1,
     'Foundation Phase', 4, 'Build base strength and conditioning', NOW()),
    ('phase-000002-0000-0000-0000-000000000002', 'prog-0000001-0000-0000-0000-000000000001', 2,
     'Strength Phase', 4, 'Increase maximal strength', NOW()),

    -- Program 2 phases
    ('phase-000003-0000-0000-0000-000000000003', 'prog-0000002-0000-0000-0000-000000000002', 1,
     'Hypertrophy Phase', 6, 'Build muscle mass', NOW()),
    ('phase-000004-0000-0000-0000-000000000004', 'prog-0000002-0000-0000-0000-000000000002', 2,
     'Power Phase', 6, 'Develop explosive power', NOW()),

    -- Program 3 phases
    ('phase-000005-0000-0000-0000-000000000005', 'prog-0000003-0000-0000-0000-000000000003', 1,
     'Introduction Phase', 3, 'Learn proper form and technique', NOW()),
    ('phase-000006-0000-0000-0000-000000000006', 'prog-0000003-0000-0000-0000-000000000003', 2,
     'Progression Phase', 3, 'Begin progressive overload', NOW())
ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- TEST SESSIONS
-- ================================================================

INSERT INTO sessions (id, phase_id, session_number, name, weekday, notes, created_at)
VALUES
    -- Program 1, Phase 1 sessions
    ('sess-00001-0000-0000-0000-000000000001', 'phase-000001-0000-0000-0000-000000000001', 1, 'Lower Body 1', 1, 'Focus on squat form', NOW()),
    ('sess-00002-0000-0000-0000-000000000002', 'phase-000001-0000-0000-0000-000000000001', 2, 'Upper Body 1', 3, 'Focus on bench press', NOW()),
    ('sess-00003-0000-0000-0000-000000000003', 'phase-000001-0000-0000-0000-000000000001', 3, 'Lower Body 2', 5, 'Focus on deadlift', NOW()),

    -- Program 1, Phase 2 sessions
    ('sess-00004-0000-0000-0000-000000000004', 'phase-000002-0000-0000-0000-000000000002', 4, 'Strength Lower 1', 1, 'Heavy squats', NOW()),
    ('sess-00005-0000-0000-0000-000000000005', 'phase-000002-0000-0000-0000-000000000002', 5, 'Strength Upper 1', 3, 'Heavy bench', NOW()),

    -- Program 2 sessions
    ('sess-00006-0000-0000-0000-000000000006', 'phase-000003-0000-0000-0000-000000000003', 1, 'Hypertrophy Day 1', 1, 'High volume', NOW()),
    ('sess-00007-0000-0000-0000-000000000007', 'phase-000003-0000-0000-0000-000000000003', 2, 'Hypertrophy Day 2', 3, 'High volume', NOW()),

    -- Program 3 sessions
    ('sess-00008-0000-0000-0000-000000000008', 'phase-000005-0000-0000-0000-000000000005', 1, 'Beginner Day 1', 1, 'Learn basics', NOW()),
    ('sess-00009-0000-0000-0000-000000000009', 'phase-000005-0000-0000-0000-000000000005', 2, 'Beginner Day 2', 4, 'Practice form', NOW())
ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- TEST SESSION EXERCISES
-- ================================================================

INSERT INTO session_exercises (id, session_id, exercise_template_id, prescribed_sets, prescribed_reps, prescribed_load, load_unit, rest_period_seconds, sequence, notes)
VALUES
    -- Session 1 exercises (Lower Body 1)
    ('sexer-0001-0000-0000-0000-000000000001', 'sess-00001-0000-0000-0000-000000000001', 'ex-00000001-0000-0000-0000-000000000001', 3, '10', 135.0, 'lbs', 90, 1, 'Focus on depth'),
    ('sexer-0002-0000-0000-0000-000000000002', 'sess-00001-0000-0000-0000-000000000001', 'ex-00000005-0000-0000-0000-000000000005', 3, '12', 95.0, 'lbs', 60, 2, 'Control descent'),

    -- Session 2 exercises (Upper Body 1)
    ('sexer-0003-0000-0000-0000-000000000003', 'sess-00002-0000-0000-0000-000000000002', 'ex-00000002-0000-0000-0000-000000000002', 3, '10', 185.0, 'lbs', 120, 1, 'Full range of motion'),
    ('sexer-0004-0000-0000-0000-000000000004', 'sess-00002-0000-0000-0000-000000000002', 'ex-00000004-0000-0000-0000-000000000004', 3, '8', NULL, 'bodyweight', 90, 2, 'Strict form'),

    -- Session 3 exercises (Lower Body 2)
    ('sexer-0005-0000-0000-0000-000000000005', 'sess-00003-0000-0000-0000-000000000003', 'ex-00000003-0000-0000-0000-000000000003', 3, '8', 225.0, 'lbs', 180, 1, 'Neutral spine'),
    ('sexer-0006-0000-0000-0000-000000000006', 'sess-00003-0000-0000-0000-000000000003', 'ex-00000001-0000-0000-0000-000000000001', 3, '15', 95.0, 'lbs', 60, 2, 'High rep work'),

    -- Session 4 exercises (Strength Lower 1)
    ('sexer-0007-0000-0000-0000-000000000007', 'sess-00004-0000-0000-0000-000000000004', 'ex-00000001-0000-0000-0000-000000000001', 5, '5', 225.0, 'lbs', 240, 1, 'Max effort'),

    -- Session 5 exercises (Strength Upper 1)
    ('sexer-0008-0000-0000-0000-000000000008', 'sess-00005-0000-0000-0000-000000000005', 'ex-00000002-0000-0000-0000-000000000002', 5, '5', 225.0, 'lbs', 240, 1, 'Max effort')
ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- TEST EXERCISE LOGS (Historical Data)
-- ================================================================

INSERT INTO exercise_logs (id, patient_id, session_exercise_id, logged_at, actual_sets, actual_reps, actual_load, load_unit, rpe, pain_score, notes, created_at)
VALUES
    -- Week 1 logs for Test Patient 1
    ('log-000001-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 'sexer-0001-0000-0000-0000-000000000001',
     NOW() - INTERVAL '28 days', 3, ARRAY[10, 10, 10], 135.0, 'lbs', 7, 2, 'Felt good', NOW() - INTERVAL '28 days'),
    ('log-000002-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333', 'sexer-0002-0000-0000-0000-000000000002',
     NOW() - INTERVAL '28 days', 3, ARRAY[12, 12, 11], 95.0, 'lbs', 6, 2, 'Good pump', NOW() - INTERVAL '28 days'),

    -- Week 2 logs
    ('log-000003-0000-0000-0000-000000000003', '33333333-3333-3333-3333-333333333333', 'sexer-0001-0000-0000-0000-000000000001',
     NOW() - INTERVAL '21 days', 3, ARRAY[10, 10, 10], 140.0, 'lbs', 7, 2, 'Progressive overload', NOW() - INTERVAL '21 days'),
    ('log-000004-0000-0000-0000-000000000004', '33333333-3333-3333-3333-333333333333', 'sexer-0003-0000-0000-0000-000000000003',
     NOW() - INTERVAL '21 days', 3, ARRAY[10, 10, 9], 185.0, 'lbs', 8, 3, 'Challenging', NOW() - INTERVAL '21 days'),

    -- Week 3 logs
    ('log-000005-0000-0000-0000-000000000005', '33333333-3333-3333-3333-333333333333', 'sexer-0001-0000-0000-0000-000000000001',
     NOW() - INTERVAL '14 days', 3, ARRAY[10, 10, 10], 145.0, 'lbs', 7, 1, 'Feeling strong', NOW() - INTERVAL '14 days'),
    ('log-000006-0000-0000-0000-000000000006', '33333333-3333-3333-3333-333333333333', 'sexer-0005-0000-0000-0000-000000000005',
     NOW() - INTERVAL '14 days', 3, ARRAY[8, 8, 7], 225.0, 'lbs', 8, 2, 'Deadlift PR', NOW() - INTERVAL '14 days'),

    -- Week 4 logs (current week)
    ('log-000007-0000-0000-0000-000000000007', '33333333-3333-3333-3333-333333333333', 'sexer-0007-0000-0000-0000-000000000007',
     NOW() - INTERVAL '7 days', 5, ARRAY[5, 5, 5, 5, 5], 225.0, 'lbs', 9, 2, 'Heavy day', NOW() - INTERVAL '7 days'),
    ('log-000008-0000-0000-0000-000000000008', '33333333-3333-3333-3333-333333333333', 'sexer-0008-0000-0000-0000-000000000008',
     NOW() - INTERVAL '7 days', 5, ARRAY[5, 5, 5, 4, 4], 225.0, 'lbs', 9, 3, 'Tough sets', NOW() - INTERVAL '7 days'),

    -- Recent logs for Test Patient 2
    ('log-000009-0000-0000-0000-000000000009', '44444444-4444-4444-4444-444444444444', 'sexer-0001-0000-0000-0000-000000000001',
     NOW() - INTERVAL '3 days', 3, ARRAY[10, 10, 10], 155.0, 'lbs', 7, 2, 'Good session', NOW() - INTERVAL '3 days'),
    ('log-000010-0000-0000-0000-000000000010', '44444444-4444-4444-4444-444444444444', 'sexer-0003-0000-0000-0000-000000000003',
     NOW() - INTERVAL '3 days', 3, ARRAY[10, 10, 9], 205.0, 'lbs', 8, 2, 'Strong bench', NOW() - INTERVAL '3 days')
ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- TEST DAILY READINESS SCORES
-- ================================================================

INSERT INTO daily_readiness (id, patient_id, date, sleep_quality, muscle_soreness, stress_level, energy_level, injury_status, readiness_score, created_at)
VALUES
    -- Last 14 days for Test Patient 1
    ('read-00001-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '13 days', 8, 4, 3, 8, NULL, 78, NOW() - INTERVAL '13 days'),
    ('read-00002-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '12 days', 7, 5, 4, 7, NULL, 70, NOW() - INTERVAL '12 days'),
    ('read-00003-0000-0000-0000-000000000003', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '11 days', 9, 3, 2, 9, NULL, 88, NOW() - INTERVAL '11 days'),
    ('read-00004-0000-0000-0000-000000000004', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '10 days', 8, 4, 3, 8, NULL, 78, NOW() - INTERVAL '10 days'),
    ('read-00005-0000-0000-0000-000000000005', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '9 days', 7, 6, 5, 6, NULL, 60, NOW() - INTERVAL '9 days'),
    ('read-00006-0000-0000-0000-000000000006', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '8 days', 8, 4, 3, 8, NULL, 78, NOW() - INTERVAL '8 days'),
    ('read-00007-0000-0000-0000-000000000007', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '7 days', 9, 3, 2, 9, NULL, 88, NOW() - INTERVAL '7 days'),
    ('read-00008-0000-0000-0000-000000000008', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '6 days', 8, 5, 4, 7, NULL, 70, NOW() - INTERVAL '6 days'),
    ('read-00009-0000-0000-0000-000000000009', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '5 days', 7, 6, 5, 7, NULL, 65, NOW() - INTERVAL '5 days'),
    ('read-00010-0000-0000-0000-000000000010', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '4 days', 8, 4, 3, 8, NULL, 78, NOW() - INTERVAL '4 days'),
    ('read-00011-0000-0000-0000-000000000011', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '3 days', 9, 3, 2, 9, NULL, 88, NOW() - INTERVAL '3 days'),
    ('read-00012-0000-0000-0000-000000000012', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '2 days', 8, 4, 3, 8, NULL, 78, NOW() - INTERVAL '2 days'),
    ('read-00013-0000-0000-0000-000000000013', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE - INTERVAL '1 day', 7, 5, 4, 7, NULL, 70, NOW() - INTERVAL '1 day'),
    ('read-00014-0000-0000-0000-000000000014', '33333333-3333-3333-3333-333333333333',
     CURRENT_DATE, 8, 4, 3, 8, NULL, 78, NOW())
ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- TEST SCHEDULED SESSIONS
-- ================================================================

INSERT INTO scheduled_sessions (id, program_id, patient_id, session_id, scheduled_date, status, completed_at, created_at, updated_at)
VALUES
    -- Past completed sessions
    ('sched-0001-0000-0000-0000-000000000001', 'prog-0000001-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333',
     'sess-00001-0000-0000-0000-000000000001', CURRENT_DATE - INTERVAL '28 days', 'completed', NOW() - INTERVAL '28 days', NOW(), NOW()),
    ('sched-0002-0000-0000-0000-000000000002', 'prog-0000001-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333',
     'sess-00002-0000-0000-0000-000000000002', CURRENT_DATE - INTERVAL '26 days', 'completed', NOW() - INTERVAL '26 days', NOW(), NOW()),
    ('sched-0003-0000-0000-0000-000000000003', 'prog-0000001-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333',
     'sess-00003-0000-0000-0000-000000000003', CURRENT_DATE - INTERVAL '24 days', 'completed', NOW() - INTERVAL '24 days', NOW(), NOW()),

    -- Upcoming scheduled sessions
    ('sched-0004-0000-0000-0000-000000000004', 'prog-0000001-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333',
     'sess-00004-0000-0000-0000-000000000004', CURRENT_DATE, 'scheduled', NULL, NOW(), NOW()),
    ('sched-0005-0000-0000-0000-000000000005', 'prog-0000001-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333',
     'sess-00005-0000-0000-0000-000000000005', CURRENT_DATE + INTERVAL '2 days', 'scheduled', NULL, NOW(), NOW()),
    ('sched-0006-0000-0000-0000-000000000006', 'prog-0000001-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333',
     'sess-00001-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '4 days', 'scheduled', NULL, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

-- Count test data created
SELECT 'Therapists' as entity, COUNT(*) as count FROM therapists WHERE email LIKE '%test%'
UNION ALL
SELECT 'Patients', COUNT(*) FROM patients WHERE email LIKE '%test%'
UNION ALL
SELECT 'Programs', COUNT(*) FROM programs WHERE name LIKE '%Test%'
UNION ALL
SELECT 'Phases', COUNT(*) FROM phases WHERE program_id IN (SELECT id FROM programs WHERE name LIKE '%Test%')
UNION ALL
SELECT 'Sessions', COUNT(*) FROM sessions WHERE phase_id IN (SELECT id FROM phases WHERE program_id IN (SELECT id FROM programs WHERE name LIKE '%Test%'))
UNION ALL
SELECT 'Session Exercises', COUNT(*) FROM session_exercises WHERE session_id IN (SELECT id FROM sessions WHERE phase_id IN (SELECT id FROM phases WHERE program_id IN (SELECT id FROM programs WHERE name LIKE '%Test%')))
UNION ALL
SELECT 'Exercise Logs', COUNT(*) FROM exercise_logs WHERE patient_id IN (SELECT id FROM patients WHERE email LIKE '%test%')
UNION ALL
SELECT 'Daily Readiness', COUNT(*) FROM daily_readiness WHERE patient_id IN (SELECT id FROM patients WHERE email LIKE '%test%')
UNION ALL
SELECT 'Scheduled Sessions', COUNT(*) FROM scheduled_sessions WHERE patient_id IN (SELECT id FROM patients WHERE email LIKE '%test%');

-- ================================================================
-- END OF SCRIPT
-- ================================================================
