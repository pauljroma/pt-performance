-- BUILD 366: Fix RLS using plpgsql SECURITY DEFINER function
-- Previous sql function may not work correctly with SECURITY DEFINER

-- Step 1: Drop ALL existing policies on daily_readiness
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Step 2: Drop old function if exists
DROP FUNCTION IF EXISTS check_patient_ownership(UUID);
DROP FUNCTION IF EXISTS auth_owns_patient(UUID);

-- Step 3: Create plpgsql SECURITY DEFINER function
-- plpgsql handles SECURITY DEFINER more reliably than sql language
CREATE OR REPLACE FUNCTION check_patient_ownership(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_auth_uid UUID;
    v_exists BOOLEAN;
BEGIN
    -- Get auth.uid()
    v_auth_uid := auth.uid();

    -- If not authenticated, deny
    IF v_auth_uid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Check if patient belongs to this user
    SELECT EXISTS (
        SELECT 1 FROM patients
        WHERE id = p_patient_id
        AND user_id = v_auth_uid
    ) INTO v_exists;

    RETURN COALESCE(v_exists, FALSE);
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION check_patient_ownership(UUID) TO authenticated;

-- Step 4: Enable RLS
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Step 5: Create policy using the function
CREATE POLICY "users_manage_own_patient_readiness"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (check_patient_ownership(patient_id))
    WITH CHECK (check_patient_ownership(patient_id));

-- Step 6: Ensure grants
GRANT SELECT, INSERT, UPDATE, DELETE ON daily_readiness TO authenticated;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - RLS via plpgsql SECURITY DEFINER check_patient_ownership()';
