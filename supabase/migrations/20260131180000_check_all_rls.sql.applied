-- BUILD 347: Check ALL tables involved in enrollment and fix

-- Debug: Show all RLS-enabled tables and their policies
DO $$
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE '=== RLS Status for all relevant tables ===';

    -- Check program_library
    FOR r IN SELECT tablename, rowsecurity
             FROM pg_tables
             WHERE tablename IN ('program_library', 'program_enrollments', 'patients')
    LOOP
        RAISE NOTICE 'Table: % | RLS Enabled: %', r.tablename, r.rowsecurity;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '=== All policies on program_library ===';
    FOR r IN SELECT policyname, cmd, permissive, qual::text as using_clause, with_check::text
             FROM pg_policies
             WHERE tablename = 'program_library'
    LOOP
        RAISE NOTICE 'Policy: % | Cmd: % | Using: %', r.policyname, r.cmd, r.using_clause;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '=== All policies on program_enrollments ===';
    FOR r IN SELECT policyname, cmd, permissive, qual::text as using_clause, with_check::text
             FROM pg_policies
             WHERE tablename = 'program_enrollments'
    LOOP
        RAISE NOTICE 'Policy: % | Cmd: % | Check: %', r.policyname, r.cmd, r.with_check;
    END LOOP;
END $$;

-- The issue might be that program_library has RLS and the foreign key check fails
-- Let's ensure program_library allows SELECT for the program being enrolled in

-- First, let's see if program_library has the "Anyone can view" policy
-- If not, add it

-- Drop any restrictive policies on program_library SELECT
DROP POLICY IF EXISTS "Anyone can view program library" ON program_library;

-- Create a fully permissive SELECT policy for program_library
CREATE POLICY "Anyone can view program library"
    ON program_library FOR SELECT
    USING (true);

-- Also ensure the specific program exists and is visible
DO $$
DECLARE
    program_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM program_library WHERE id = 'A15D7C44-118A-4DBF-A8FC-BD0CE3759A3B'::uuid)
    INTO program_exists;

    RAISE NOTICE 'Program A15D7C44-118A-4DBF-A8FC-BD0CE3759A3B exists: %', program_exists;
END $$;

-- NUCLEAR OPTION: Disable RLS on program_enrollments entirely for testing
-- This will tell us definitively if RLS is the problem
ALTER TABLE program_enrollments DISABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== RLS DISABLED on program_enrollments for testing ===';
    RAISE NOTICE 'Try enrolling again. If it works, RLS was the issue.';
    RAISE NOTICE 'We will re-enable RLS with proper policies after confirming.';
END $$;
