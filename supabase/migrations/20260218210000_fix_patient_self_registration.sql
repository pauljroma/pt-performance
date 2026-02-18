-- Build 537: Fix patient self-registration for standalone users
--
-- Problem: The patients_auth_insert RLS policy only allows therapists to insert.
-- Regular users who sign up cannot create their own patient record, which blocks
-- mode selection, goal saving, and the entire quick setup flow.
--
-- Also: The auth trigger that auto-created patient records on signup was dropped
-- in migration 20260209194000. Re-enable it and backfill missing records.

BEGIN;

-- ============================================================================
-- 1. Fix INSERT policy: Allow users to create their own patient record
-- ============================================================================

-- Drop the restrictive policy (was applied in our earlier fix migration too)
DROP POLICY IF EXISTS "patients_auth_insert" ON patients;

-- New policy: therapists can insert any patient, users can insert their own record
CREATE POLICY "patients_auth_insert"
    ON patients FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Users can create their own patient record (user_id matches auth.uid)
        user_id::text = auth.uid()::text
        -- Therapists can create patient records for others
        OR is_therapist()
        -- Demo patient
        OR id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- ============================================================================
-- 2. Also fix the SELECT/UPDATE policies to not hit auth.users
--    (our earlier migration 20260218200000 already did this, but the INSERT
--     policy that was recreated there still had the old restriction)
-- ============================================================================

-- Already handled in 20260218200000 - no action needed

-- ============================================================================
-- 3. Re-create auto-patient trigger for new signups
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_patient_on_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO patients (
        id,
        user_id,
        email,
        first_name,
        last_name,
        mode,
        sport,
        created_at
    ) VALUES (
        gen_random_uuid(),
        NEW.id,
        COALESCE(NEW.email, ''),
        COALESCE(NEW.raw_user_meta_data->>'first_name', split_part(COALESCE(NEW.email, 'User'), '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'User'),
        'strength',
        'General Fitness',
        NOW()
    )
    ON CONFLICT DO NOTHING;

    RETURN NEW;
END;
$$;

-- Re-enable the trigger
DROP TRIGGER IF EXISTS on_auth_user_created_create_patient ON auth.users;
CREATE TRIGGER on_auth_user_created_create_patient
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.create_patient_on_signup();

-- ============================================================================
-- 4. Backfill: Create patient records for existing auth users who don't have one
-- ============================================================================

INSERT INTO patients (id, user_id, email, first_name, last_name, mode, sport, created_at)
SELECT
    gen_random_uuid(),
    u.id,
    COALESCE(u.email, ''),
    COALESCE(u.raw_user_meta_data->>'first_name', split_part(COALESCE(u.email, 'User'), '@', 1)),
    COALESCE(u.raw_user_meta_data->>'last_name', 'User'),
    'strength',
    'General Fitness',
    NOW()
FROM auth.users u
WHERE NOT EXISTS (
    SELECT 1 FROM patients p
    WHERE p.user_id::text = u.id::text
       OR p.email = u.email
)
AND u.id != '00000000-0000-0000-0000-000000000001'::uuid  -- Skip demo patient
AND u.id != '00000000-0000-0000-0000-000000000100'::uuid; -- Skip demo therapist

-- ============================================================================
-- 5. Force schema cache reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

COMMIT;
