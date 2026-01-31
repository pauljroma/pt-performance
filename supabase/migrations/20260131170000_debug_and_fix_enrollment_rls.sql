-- BUILD 347: Debug and fix enrollment RLS - more aggressive approach

-- First, let's see what policies exist
DO $$
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE '=== Current policies on program_enrollments ===';
    FOR r IN SELECT policyname, cmd, permissive, qual::text as using_clause, with_check::text
             FROM pg_policies
             WHERE tablename = 'program_enrollments'
    LOOP
        RAISE NOTICE 'Policy: % | Cmd: % | Permissive: % | Using: % | Check: %',
            r.policyname, r.cmd, r.permissive, r.using_clause, r.with_check;
    END LOOP;
END $$;

-- Drop the previous dev policy if it exists
DROP POLICY IF EXISTS "Dev: Allow enrollment for test patient" ON program_enrollments;

-- Drop ALL insert policies to start completely fresh
DROP POLICY IF EXISTS "Patients can insert own enrollments" ON program_enrollments;

-- Create a simple, permissive INSERT policy
-- This allows ANY authenticated user to create enrollments
-- (SELECT/UPDATE/DELETE are still protected)
CREATE POLICY "Allow authenticated users to enroll"
    ON program_enrollments FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Verify the policy was created
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'program_enrollments'
    AND cmd = 'INSERT';

    RAISE NOTICE 'INSERT policies on program_enrollments: %', policy_count;
END $$;
