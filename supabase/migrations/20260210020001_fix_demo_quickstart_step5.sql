-- Fix: Apply remaining step 5 from quickstart fix (with proper time casting)

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
WHERE day_offset NOT IN (3, 6)
ON CONFLICT DO NOTHING;

-- Force schema reload
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- Verification
DO $$
DECLARE
    scheduled_count INT;
    today_session TEXT;
BEGIN
    SELECT COUNT(*) INTO scheduled_count
    FROM scheduled_sessions
    WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
      AND status = 'scheduled'
      AND scheduled_date >= CURRENT_DATE;

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
    RAISE NOTICE 'Upcoming scheduled sessions: %', scheduled_count;
    RAISE NOTICE 'Today''s session: %', COALESCE(today_session, 'None');
    RAISE NOTICE '============================================';
END $$;
