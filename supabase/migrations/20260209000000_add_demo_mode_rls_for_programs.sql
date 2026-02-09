-- BUILD 468: Add RLS policies for demo mode program creation
-- Demo mode uses hardcoded UUIDs without Supabase Auth, so auth.uid() returns NULL
-- These policies allow demo users to manage programs

-- Demo therapist UUID
-- 00000000-0000-0000-0000-000000000100 = Sarah Thompson (Demo Therapist)

-- ============================================================================
-- 1. Drop existing restrictive policies and recreate with demo support
-- ============================================================================

-- Drop the existing therapist policies that only check auth.uid()
DROP POLICY IF EXISTS "Therapists can create programs" ON programs;
DROP POLICY IF EXISTS "Therapists can update programs" ON programs;
DROP POLICY IF EXISTS "Therapists can delete programs" ON programs;
DROP POLICY IF EXISTS "Anyone can view system programs" ON programs;

-- ============================================================================
-- 2. Create new policies with demo mode support
-- ============================================================================

-- Therapists can create programs (including demo therapist)
CREATE POLICY "Therapists can create programs"
    ON programs FOR INSERT
    WITH CHECK (
        -- Real authenticated therapists
        auth.uid() IN (SELECT user_id FROM therapists WHERE user_id IS NOT NULL)
        -- Demo mode: allow when auth.uid() is null (demo uses hardcoded UUIDs without Supabase Auth)
        OR auth.uid() IS NULL
        -- System templates (patient_id IS NULL)
        OR patient_id IS NULL
    );

-- Therapists can update programs (including demo therapist)
CREATE POLICY "Therapists can update programs"
    ON programs FOR UPDATE
    USING (
        -- Real authenticated therapists
        auth.uid() IN (SELECT user_id FROM therapists WHERE user_id IS NOT NULL)
        -- Demo mode: allow when auth.uid() is null
        OR auth.uid() IS NULL
        -- System templates are editable
        OR patient_id IS NULL
    );

-- Therapists can delete programs (including demo therapist)
CREATE POLICY "Therapists can delete programs"
    ON programs FOR DELETE
    USING (
        -- Real authenticated therapists
        auth.uid() IN (SELECT user_id FROM therapists WHERE user_id IS NOT NULL)
        -- Demo mode: allow when auth.uid() is null
        OR auth.uid() IS NULL
    );

-- Anyone can view system programs (for program library browsing)
CREATE POLICY "Anyone can view system programs"
    ON programs FOR SELECT
    USING (
        -- System templates are public
        patient_id IS NULL
        -- Patients can view their own programs
        OR patient_id = auth.uid()
        -- Real authenticated therapists can view all
        OR auth.uid() IN (SELECT user_id FROM therapists WHERE user_id IS NOT NULL)
        -- Demo users can view all programs
        OR auth.uid() IS NULL
    );

-- ============================================================================
-- 3. Similar updates for program_library table
-- ============================================================================

DROP POLICY IF EXISTS "Therapists can publish to library" ON program_library;
DROP POLICY IF EXISTS "Therapists can update library items" ON program_library;
DROP POLICY IF EXISTS "Therapists can delete library items" ON program_library;

-- Therapists can publish programs to the library (including demo)
CREATE POLICY "Therapists can publish to library"
    ON program_library FOR INSERT
    WITH CHECK (
        auth.uid() IN (SELECT user_id FROM therapists WHERE user_id IS NOT NULL)
        -- Demo mode: allow when auth.uid() is null
        OR auth.uid() IS NULL
    );

-- Therapists can update library entries (including demo)
CREATE POLICY "Therapists can update library items"
    ON program_library FOR UPDATE
    USING (
        auth.uid() IN (SELECT user_id FROM therapists WHERE user_id IS NOT NULL)
        OR auth.uid() IS NULL
    );

-- Therapists can delete library entries (including demo)
CREATE POLICY "Therapists can delete library items"
    ON program_library FOR DELETE
    USING (
        auth.uid() IN (SELECT user_id FROM therapists WHERE user_id IS NOT NULL)
        OR auth.uid() IS NULL
    );

-- ============================================================================
-- 4. Comments
-- ============================================================================

COMMENT ON POLICY "Therapists can create programs" ON programs IS
    'Allow therapists (authenticated or demo mode) to create programs';
COMMENT ON POLICY "Therapists can update programs" ON programs IS
    'Allow therapists (authenticated or demo mode) to update programs';
COMMENT ON POLICY "Therapists can delete programs" ON programs IS
    'Allow therapists (authenticated or demo mode) to delete programs';
COMMENT ON POLICY "Anyone can view system programs" ON programs IS
    'Allow viewing system templates and own programs; demo users can view all';

-- ============================================================================
-- 5. Add demo mode support for conflict_resolution_log (uses users table)
-- ============================================================================

-- Check if users table exists and add policy
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        -- Drop existing policies if any
        DROP POLICY IF EXISTS "Users can view own record" ON users;
        DROP POLICY IF EXISTS "Demo users can read users" ON users;

        -- Allow authenticated users to view their own record
        CREATE POLICY "Users can view own record"
            ON users FOR SELECT
            USING (
                id = auth.uid()
                -- Demo mode: allow reads
                OR auth.uid() IS NULL
            );
    END IF;
END $$;

-- ============================================================================
-- 6. Add demo mode support for phases table
-- ============================================================================

DROP POLICY IF EXISTS "Therapists can manage phases" ON phases;
DROP POLICY IF EXISTS "Anyone can view phases" ON phases;

-- Therapists (including demo) can manage phases
CREATE POLICY "Therapists can manage phases"
    ON phases FOR ALL
    USING (
        -- System templates
        program_id IN (SELECT id FROM programs WHERE patient_id IS NULL)
        -- Authenticated therapists
        OR auth.uid() IN (SELECT user_id FROM therapists WHERE user_id IS NOT NULL)
        -- Demo mode
        OR auth.uid() IS NULL
    );

-- Anyone can view phases for system programs
CREATE POLICY "Anyone can view phases"
    ON phases FOR SELECT
    USING (
        program_id IN (SELECT id FROM programs WHERE patient_id IS NULL)
        OR auth.uid() IN (SELECT user_id FROM therapists WHERE user_id IS NOT NULL)
        OR program_id IN (SELECT id FROM programs WHERE patient_id = auth.uid())
        -- Demo mode
        OR auth.uid() IS NULL
    );

-- ============================================================================
-- 7. Add demo mode support for program_workout_assignments table
-- ============================================================================

DROP POLICY IF EXISTS "Therapists can manage workout assignments" ON program_workout_assignments;

-- Therapists (including demo) can manage workout assignments
CREATE POLICY "Therapists can manage workout assignments"
    ON program_workout_assignments FOR ALL
    USING (
        -- System templates
        program_id IN (SELECT id FROM programs WHERE patient_id IS NULL)
        -- Authenticated therapists
        OR auth.uid() IN (SELECT user_id FROM therapists WHERE user_id IS NOT NULL)
        -- Demo mode
        OR auth.uid() IS NULL
    );
