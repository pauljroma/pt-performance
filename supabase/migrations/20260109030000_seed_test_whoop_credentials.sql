-- Seed WHOOP credentials for test patient
-- BUILD 138 - Test Infrastructure

-- Update test patient with mock WHOOP credentials
UPDATE patients
SET whoop_credentials = jsonb_build_object(
    'access_token', 'mock_access_token_for_testing',
    'refresh_token', 'mock_refresh_token_for_testing',
    'expires_at', (NOW() + INTERVAL '1 year')::TEXT,
    'athlete_id', 'mock_athlete_12345'
)
WHERE id = '00000000-0000-0000-0000-000000000001';

-- Verify the update
DO $$
DECLARE
    creds_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO creds_count
    FROM patients
    WHERE id = '00000000-0000-0000-0000-000000000001'
      AND whoop_credentials IS NOT NULL;

    IF creds_count = 0 THEN
        RAISE EXCEPTION 'Failed to seed WHOOP credentials for test patient';
    END IF;

    RAISE NOTICE 'WHOOP credentials seeded successfully for test patient';
END $$;
