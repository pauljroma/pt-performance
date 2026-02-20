-- ============================================================================
-- SEED DAILY TEST SESSIONS FOR E2E TESTS
-- ============================================================================
-- Date: 2026-02-20
-- Purpose: Ensure test patients have a scheduled_sessions row for CURRENT_DATE
--          so that the Today Hub displays workout content and readiness check-in
--          prompts. Without this, 8 WorkoutExecution tests and 7 ReadinessCheckIn
--          tests skip because the TodaySessionViewModel sees no session.
--
-- Key insight: TodaySessionViewModel.fetchFromSupabase() first queries
--   SELECT session_id FROM scheduled_sessions
--   WHERE patient_id = X AND scheduled_date = CURRENT_DATE AND status = 'scheduled'
-- If no row exists, the Today Hub shows noSessionView (no ReadinessStatusCard).
--
-- Uses CURRENT_DATE so sessions are always "today" regardless of when migration runs.
-- Uses ON CONFLICT DO NOTHING for idempotency (CLAUDE.md requirement).
-- ============================================================================

-- ============================================================================
-- STEP 1: Clean up any stale scheduled_sessions for these patients for today
-- (in case a previous run left completed/cancelled rows that would conflict)
-- ============================================================================

-- Delete any non-scheduled sessions for today so we can insert fresh ones
DELETE FROM scheduled_sessions
WHERE patient_id IN (
    'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,  -- Marcus Rivera
    'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid    -- Jordan Williams
)
AND scheduled_date = CURRENT_DATE
AND status != 'scheduled';

-- ============================================================================
-- STEP 2: Insert scheduled_sessions for today
-- ============================================================================

-- Marcus Rivera (rehab mode) - used by ReadinessCheckIn tests
-- References session "Shoulder Mobility A" from comprehensive seed data
-- This session already has exercises (band pull-apart, front plank, goblet squat, RDL)
INSERT INTO scheduled_sessions (
    id,
    patient_id,
    session_id,
    scheduled_date,
    scheduled_time,
    status,
    notes,
    created_at,
    updated_at
) VALUES (
    'eeeeeeee-0000-0000-0000-000000000001'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,
    'dddddddd-0000-0000-0101-000000000001'::uuid,  -- Shoulder Mobility A (Phase 1, Session 1)
    CURRENT_DATE,
    '09:00:00'::time,
    'scheduled',
    'Daily rehab session - Shoulder Mobility A (E2E test seed)',
    NOW(),
    NOW()
)
ON CONFLICT DO NOTHING;

-- Jordan Williams (strength mode) - used by WorkoutExecution tests
-- References session "Lower Body A" from comprehensive seed data
-- This session already has exercises (goblet squat, deadlift)
INSERT INTO scheduled_sessions (
    id,
    patient_id,
    session_id,
    scheduled_date,
    scheduled_time,
    status,
    notes,
    created_at,
    updated_at
) VALUES (
    'eeeeeeee-0000-0000-0000-000000000005'::uuid,
    'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid,
    'dddddddd-0000-0000-0501-000000000001'::uuid,  -- Lower Body A (Phase 1, Session 1)
    CURRENT_DATE,
    '10:00:00'::time,
    'scheduled',
    'Daily strength session - Lower Body A (E2E test seed)',
    NOW(),
    NOW()
)
ON CONFLICT DO NOTHING;


-- ============================================================================
-- STEP 3: Delete any existing daily readiness entries for today
-- so the "Check In Now" button appears in ReadinessStatusCard
-- ============================================================================

DELETE FROM daily_readiness
WHERE patient_id IN (
    'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid,  -- Marcus Rivera
    'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid    -- Jordan Williams
)
AND date = CURRENT_DATE;


-- ============================================================================
-- STEP 4: Ensure the referenced sessions are NOT marked as completed
-- (reset if a previous test run marked them complete)
-- ============================================================================

UPDATE sessions
SET completed = false,
    completed_at = NULL,
    started_at = NULL,
    total_volume = NULL,
    avg_rpe = NULL,
    avg_pain = NULL,
    duration_minutes = NULL
WHERE id IN (
    'dddddddd-0000-0000-0101-000000000001'::uuid,  -- Marcus: Shoulder Mobility A
    'dddddddd-0000-0000-0501-000000000001'::uuid    -- Jordan: Lower Body A
)
AND completed = true;


-- ============================================================================
-- STEP 5: Verification
-- ============================================================================

DO $$
DECLARE
    v_marcus_session_count int;
    v_jordan_session_count int;
    v_marcus_exercise_count int;
    v_jordan_exercise_count int;
    v_marcus_readiness_count int;
    v_jordan_readiness_count int;
BEGIN
    -- Verify scheduled sessions exist for today
    SELECT COUNT(*) INTO v_marcus_session_count
    FROM scheduled_sessions
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid
      AND scheduled_date = CURRENT_DATE
      AND status = 'scheduled';

    SELECT COUNT(*) INTO v_jordan_session_count
    FROM scheduled_sessions
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid
      AND scheduled_date = CURRENT_DATE
      AND status = 'scheduled';

    -- Verify exercises exist for the sessions
    SELECT COUNT(*) INTO v_marcus_exercise_count
    FROM session_exercises
    WHERE session_id = 'dddddddd-0000-0000-0101-000000000001'::uuid;

    SELECT COUNT(*) INTO v_jordan_exercise_count
    FROM session_exercises
    WHERE session_id = 'dddddddd-0000-0000-0501-000000000001'::uuid;

    -- Verify no daily readiness exists for today (so check-in prompt shows)
    SELECT COUNT(*) INTO v_marcus_readiness_count
    FROM daily_readiness
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid
      AND date = CURRENT_DATE;

    SELECT COUNT(*) INTO v_jordan_readiness_count
    FROM daily_readiness
    WHERE patient_id = 'aaaaaaaa-bbbb-cccc-dddd-000000000005'::uuid
      AND date = CURRENT_DATE;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'DAILY TEST SESSIONS SEED VERIFICATION';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Marcus Rivera (rehab):';
    RAISE NOTICE '  Scheduled sessions today: % (expected: >= 1)', v_marcus_session_count;
    RAISE NOTICE '  Exercises in session:     % (expected: >= 2)', v_marcus_exercise_count;
    RAISE NOTICE '  Readiness entries today:  % (expected: 0)', v_marcus_readiness_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Jordan Williams (strength):';
    RAISE NOTICE '  Scheduled sessions today: % (expected: >= 1)', v_jordan_session_count;
    RAISE NOTICE '  Exercises in session:     % (expected: >= 2)', v_jordan_exercise_count;
    RAISE NOTICE '  Readiness entries today:  % (expected: 0)', v_jordan_readiness_count;
    RAISE NOTICE '============================================';

    -- Assert minimum expectations
    IF v_marcus_session_count < 1 THEN
        RAISE WARNING 'Marcus has no scheduled session for today!';
    END IF;
    IF v_jordan_session_count < 1 THEN
        RAISE WARNING 'Jordan has no scheduled session for today!';
    END IF;
    IF v_marcus_exercise_count < 1 THEN
        RAISE WARNING 'Marcus session has no exercises - WorkoutExecution tests will fail!';
    END IF;
    IF v_jordan_exercise_count < 1 THEN
        RAISE WARNING 'Jordan session has no exercises - WorkoutExecution tests will fail!';
    END IF;
END $$;
