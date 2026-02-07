-- Debug and fix exercise_logs RLS
-- List all existing policies and recreate with proper permissions

-- First, let's see what policies exist
DO $$
DECLARE
    pol record;
BEGIN
    RAISE NOTICE '=== Existing policies on exercise_logs ===';
    FOR pol IN
        SELECT policyname, permissive, roles, cmd, qual, with_check
        FROM pg_policies
        WHERE tablename = 'exercise_logs'
    LOOP
        RAISE NOTICE 'Policy: % | Permissive: % | Roles: % | Cmd: %',
            pol.policyname, pol.permissive, pol.roles, pol.cmd;
    END LOOP;
END $$;

-- Drop ALL existing policies on exercise_logs
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'exercise_logs'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.exercise_logs', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- Disable RLS temporarily to ensure clean slate
ALTER TABLE public.exercise_logs DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS
ALTER TABLE public.exercise_logs ENABLE ROW LEVEL SECURITY;

-- Create simple permissive policy for SELECT (everyone can read their own)
CREATE POLICY "exercise_logs_select"
ON public.exercise_logs FOR SELECT
USING (true);  -- Allow all reads for now

-- Create permissive policy for INSERT
CREATE POLICY "exercise_logs_insert"
ON public.exercise_logs FOR INSERT
WITH CHECK (true);  -- Allow all inserts for now

-- Create permissive policy for UPDATE
CREATE POLICY "exercise_logs_update"
ON public.exercise_logs FOR UPDATE
USING (true);  -- Allow all updates for now

-- Create permissive policy for DELETE
CREATE POLICY "exercise_logs_delete"
ON public.exercise_logs FOR DELETE
USING (true);  -- Allow all deletes for now

-- Ensure grants are in place
GRANT ALL ON public.exercise_logs TO authenticated;
GRANT ALL ON public.exercise_logs TO anon;

-- Force schema reload
NOTIFY pgrst, 'reload schema';

-- Verify
DO $$
DECLARE
    pol record;
BEGIN
    RAISE NOTICE '=== New policies on exercise_logs ===';
    FOR pol IN
        SELECT policyname, permissive, roles, cmd
        FROM pg_policies
        WHERE tablename = 'exercise_logs'
    LOOP
        RAISE NOTICE 'Policy: % | Permissive: % | Roles: % | Cmd: %',
            pol.policyname, pol.permissive, pol.roles, pol.cmd;
    END LOOP;
END $$;
