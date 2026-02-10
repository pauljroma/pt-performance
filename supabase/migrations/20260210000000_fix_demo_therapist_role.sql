-- ============================================================================
-- FIX DEMO THERAPIST ROLE
-- ============================================================================
-- Problem: Demo therapist cannot create patients or programs because is_therapist()
-- returns false - the demo therapist has no entry in user_roles table
-- Solution: Add therapist role for demo therapist and ensure therapists table has user_id
-- ============================================================================

-- Demo therapist UUID (from therapists table, not auth.users)
-- The demo therapist record ID: 00000000-0000-0000-0000-000000000100

-- ============================================================================
-- 1. Find or create the demo therapist's auth user_id
-- ============================================================================

-- First, check if there's a user_id in the therapists table for the demo therapist
DO $$
DECLARE
    demo_therapist_user_id UUID;
    demo_therapist_id UUID := '00000000-0000-0000-0000-000000000100'::uuid;
BEGIN
    -- Get the user_id from therapists table
    SELECT user_id INTO demo_therapist_user_id
    FROM therapists
    WHERE id = demo_therapist_id;

    IF demo_therapist_user_id IS NOT NULL THEN
        -- User ID exists, add therapist role
        INSERT INTO user_roles (user_id, role_name, assigned_at)
        VALUES (demo_therapist_user_id, 'therapist', NOW())
        ON CONFLICT (user_id, role_name) DO NOTHING;

        RAISE NOTICE 'Added therapist role for demo therapist user_id: %', demo_therapist_user_id;
    ELSE
        RAISE NOTICE 'Demo therapist has no user_id set in therapists table';
    END IF;
END $$;

-- ============================================================================
-- 2. Update RLS policies to also check therapists table directly
-- ============================================================================

-- Update is_therapist function to check both user_roles AND therapists table
-- Must use CREATE OR REPLACE with same parameter name to preserve dependent policies
CREATE OR REPLACE FUNCTION is_therapist(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM user_roles ur
        WHERE ur.user_id = is_therapist.user_id
        AND ur.role_name = 'therapist'
    )
    OR EXISTS (
        SELECT 1
        FROM therapists t
        WHERE t.user_id = is_therapist.user_id
    );
$$;

-- ============================================================================
-- 3. Fix patients INSERT policy to handle demo mode
-- ============================================================================

-- Drop and recreate the therapist insert policy with demo mode support
DROP POLICY IF EXISTS "Therapists can insert patients" ON patients;

CREATE POLICY "Therapists can insert patients"
    ON patients FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Must be a therapist (checks both user_roles and therapists table)
        is_therapist(auth.uid())
        AND (
            -- therapist_id matches auth.uid() directly
            therapist_id::text = auth.uid()::text
            -- Or therapist_id matches the therapist's record ID
            OR therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        )
    );

-- ============================================================================
-- 4. Ensure demo mode RLS works for all therapist actions
-- ============================================================================

-- Note: therapist_notes table may not exist yet, skip if not present
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'therapist_notes') THEN
        -- Add demo-friendly policies for therapist_notes (used in patient setup)
        DROP POLICY IF EXISTS "Therapists can insert notes" ON therapist_notes;

        CREATE POLICY "Therapists can insert notes"
            ON therapist_notes FOR INSERT
            TO authenticated
            WITH CHECK (
                is_therapist(auth.uid())
                AND therapist_id::text = auth.uid()::text
            );

        -- Grant insert permission
        GRANT INSERT ON therapist_notes TO authenticated;
        RAISE NOTICE 'Added therapist_notes insert policy';
    ELSE
        RAISE NOTICE 'therapist_notes table does not exist, skipping policy';
    END IF;
END $$;

-- ============================================================================
-- 5. Verification
-- ============================================================================
DO $$
DECLARE
    therapist_role_count INTEGER;
    is_therapist_result BOOLEAN;
BEGIN
    -- Count therapist roles
    SELECT COUNT(*) INTO therapist_role_count
    FROM user_roles
    WHERE role_name = 'therapist';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Demo Therapist Role Fix Complete';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Total therapist roles in user_roles: %', therapist_role_count;
    RAISE NOTICE 'is_therapist function updated to check therapists table';
    RAISE NOTICE '';
END $$;
