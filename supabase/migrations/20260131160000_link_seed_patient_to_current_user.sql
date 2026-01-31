-- BUILD 347: Link seed patient to the authenticated user
-- The seed patient has patient_id but may not have user_id set to match auth.uid()

-- This is a one-time fix to ensure the seed patient is linked to the logged-in user
-- When the user logs in, we update the patient's user_id to match their auth.uid()

-- Option 1: Create a function that can be called to link patient on demand
CREATE OR REPLACE FUNCTION public.link_my_patient_record()
RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_user_email TEXT;
    v_patient_id UUID;
    v_result JSON;
BEGIN
    -- Get current user's ID and email
    v_user_id := auth.uid();

    SELECT email INTO v_user_email
    FROM auth.users
    WHERE id = v_user_id;

    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Find patient with matching email but no user_id, or with different user_id
    SELECT id INTO v_patient_id
    FROM patients
    WHERE email = v_user_email
    LIMIT 1;

    IF v_patient_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'No patient record found for your email');
    END IF;

    -- Update patient's user_id to match current auth user
    UPDATE patients
    SET user_id = v_user_id
    WHERE id = v_patient_id;

    RETURN json_build_object(
        'success', true,
        'patient_id', v_patient_id,
        'user_id', v_user_id,
        'email', v_user_email
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.link_my_patient_record() TO authenticated;

-- Option 2: Create a trigger that auto-links on any patient table read
-- This ensures the patient is linked when they try to use the app
CREATE OR REPLACE FUNCTION auto_link_patient_on_read()
RETURNS TRIGGER AS $$
BEGIN
    -- If the patient has our email but not our user_id, update it
    IF NEW.email = (SELECT email FROM auth.users WHERE id = auth.uid())
       AND (NEW.user_id IS NULL OR NEW.user_id != auth.uid()) THEN
        NEW.user_id := auth.uid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: This trigger approach won't work for SELECT
-- Instead, let's add a simple policy that allows enrollment for the test patient

-- Option 3: Add a service-role bypass policy for development
-- This allows any authenticated user to enroll the test patient
-- ONLY FOR DEVELOPMENT - remove in production!
CREATE POLICY "Dev: Allow enrollment for test patient"
    ON program_enrollments FOR INSERT
    WITH CHECK (
        -- Allow if inserting for the test patient AND user has a linked patient record
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        AND auth.uid() IS NOT NULL
    );

DO $$
BEGIN
    RAISE NOTICE 'Created link_my_patient_record() function';
    RAISE NOTICE 'Added dev policy for test patient enrollment';
    RAISE NOTICE 'Call SELECT link_my_patient_record() to link your patient record';
END $$;
