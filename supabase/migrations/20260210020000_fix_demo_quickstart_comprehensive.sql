-- ============================================================================
-- FIX DEMO PATIENT QUICKSTART PROGRESSION
-- ============================================================================
-- Problem: Demo patient stuck on quickstart because:
--   1. No scheduled_sessions for today
--   2. RPC get_today_enrolled_session only granted to 'authenticated', not 'anon'
--   3. program_enrollments table has no anon policies
--
-- Solution:
--   1. Add scheduled_session for today pointing to demo session
--   2. Grant RPC execute to anon role
--   3. Add anon policies to program_enrollments
-- ============================================================================

-- ============================================================================
-- STEP 1: Add scheduled_session for today for demo patient
-- ============================================================================

-- Delete any existing scheduled sessions for today (to avoid duplicates)
DELETE FROM scheduled_sessions
WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
  AND scheduled_date = CURRENT_DATE;

-- Insert scheduled session for today
INSERT INTO scheduled_sessions (
    id,
    patient_id,
    session_id,
    scheduled_date,
    scheduled_time,
    status,
    reminder_sent,
    notes,
    created_at,
    updated_at
)
VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000401'::uuid,
    CURRENT_DATE,
    '09:00:00',
    'scheduled',
    false,
    'Demo workout - Foundation Phase Session 1',
    NOW(),
    NOW()
);

-- ============================================================================
-- STEP 2: Grant RPC execute to anon role
-- ============================================================================

-- Grant execute on enrollment RPCs to anon (for demo mode)
GRANT EXECUTE ON FUNCTION get_enrolled_program_sessions(UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_today_enrolled_session(UUID) TO anon;

-- ============================================================================
-- STEP 3: Add anon policies to program_enrollments
-- ============================================================================

-- Check if program_enrollments exists and add policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'program_enrollments' AND table_schema = 'public') THEN
        -- Drop existing anon policies if any
        EXECUTE 'DROP POLICY IF EXISTS "program_enrollments_anon_read" ON program_enrollments';

        -- Create SELECT policy for anon
        EXECUTE 'CREATE POLICY "program_enrollments_anon_read" ON program_enrollments FOR SELECT TO anon USING (true)';

        -- Grant SELECT to anon
        EXECUTE 'GRANT SELECT ON program_enrollments TO anon';

        RAISE NOTICE 'Added anon policies to program_enrollments';
    END IF;
END $$;

-- ============================================================================
-- STEP 4: Ensure program_library has anon access
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'program_library' AND table_schema = 'public') THEN
        -- Drop existing anon policies if any
        EXECUTE 'DROP POLICY IF EXISTS "program_library_anon_read" ON program_library';

        -- Create SELECT policy for anon
        EXECUTE 'CREATE POLICY "program_library_anon_read" ON program_library FOR SELECT TO anon USING (true)';

        -- Grant SELECT to anon
        EXECUTE 'GRANT SELECT ON program_library TO anon';

        RAISE NOTICE 'Added anon policies to program_library';
    END IF;
END $$;

-- ============================================================================
-- STEP 5: Add future scheduled sessions (next 7 days)
-- ============================================================================

-- Add workouts for the next week so demo user can see upcoming schedule
INSERT INTO scheduled_sessions (
    id,
    patient_id,
    session_id,
    scheduled_date,
    scheduled_time,
    status,
    reminder_sent,
    notes,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000401'::uuid,
    CURRENT_DATE + (day_offset || ' days')::interval,
    (CASE WHEN day_offset % 2 = 0 THEN '09:00:00' ELSE '10:00:00' END)::time,
    'scheduled',
    false,
    'Demo workout - Foundation Phase',
    NOW(),
    NOW()
FROM generate_series(1, 6) AS day_offset
WHERE day_offset NOT IN (3, 6) -- Skip day 3 and 6 for rest days
ON CONFLICT DO NOTHING;

-- ============================================================================
-- STEP 6: Force schema reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    scheduled_count INT;
    today_session TEXT;
BEGIN
    -- Count scheduled sessions for demo patient
    SELECT COUNT(*) INTO scheduled_count
    FROM scheduled_sessions
    WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
      AND status = 'scheduled';

    -- Get today's session name
    SELECT s.name INTO today_session
    FROM scheduled_sessions ss
    JOIN sessions s ON s.id = ss.session_id
    WHERE ss.patient_id = '00000000-0000-0000-0000-000000000001'::uuid
      AND ss.scheduled_date = CURRENT_DATE
    LIMIT 1;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Demo QuickStart Fix Complete';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Scheduled sessions for demo patient: %', scheduled_count;
    RAISE NOTICE 'Today''s session: %', COALESCE(today_session, 'None');
    RAISE NOTICE '';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '  - Added scheduled_session for today';
    RAISE NOTICE '  - Added scheduled_sessions for next 7 days';
    RAISE NOTICE '  - Granted RPC execute to anon role';
    RAISE NOTICE '  - Added anon policies to program_enrollments';
    RAISE NOTICE '  - Added anon policies to program_library';
    RAISE NOTICE '============================================';
END $$;
