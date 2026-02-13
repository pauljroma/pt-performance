-- ============================================================================
-- CREATE DEMO USER IN AUTH.USERS
-- ============================================================================
-- Problem: Demo patient can't have user_id set due to FK constraint
-- Solution: Create the demo user in auth.users so FK is satisfied
-- This allows all existing code to work without special demo mode handling
-- ============================================================================

-- ============================================================================
-- STEP 1: Insert demo patient user into auth.users
-- ============================================================================

INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
)
VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'demo.patient@modus.app',
    '',  -- Empty password - demo mode bypasses auth entirely
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STEP 2: Insert demo therapist user into auth.users
-- ============================================================================

INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
)
VALUES (
    '00000000-0000-0000-0000-000000000100'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'demo.therapist@modus.app',
    '',  -- Empty password - demo mode bypasses auth
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STEP 3: Update demo patient's user_id to link to auth user
-- ============================================================================

UPDATE patients
SET user_id = '00000000-0000-0000-0000-000000000001'::uuid
WHERE id = '00000000-0000-0000-0000-000000000001'::uuid;

-- ============================================================================
-- STEP 4: Update demo therapist's user_id if therapists table exists
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'therapists') THEN
        EXECUTE 'UPDATE therapists SET user_id = ''00000000-0000-0000-0000-000000000100''::uuid WHERE id = ''00000000-0000-0000-0000-000000000100''::uuid';
    END IF;
END $$;

-- ============================================================================
-- STEP 5: Force schema reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    patient_user_id UUID;
    auth_user_exists BOOLEAN;
BEGIN
    -- Check if auth user exists
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = '00000000-0000-0000-0000-000000000001'::uuid) INTO auth_user_exists;

    -- Check patient's user_id
    SELECT user_id INTO patient_user_id
    FROM patients
    WHERE id = '00000000-0000-0000-0000-000000000001'::uuid;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Demo Auth User Created';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Auth user exists: %', auth_user_exists;
    RAISE NOTICE 'Patient user_id: %', patient_user_id;
    RAISE NOTICE '';
    RAISE NOTICE 'Demo patient now has:';
    RAISE NOTICE '  - id = 00000000-0000-0000-0000-000000000001';
    RAISE NOTICE '  - user_id = 00000000-0000-0000-0000-000000000001';
    RAISE NOTICE '  - Linked to auth.users';
    RAISE NOTICE '';
    RAISE NOTICE 'All existing code will work without modification!';
    RAISE NOTICE '============================================';
END $$;
