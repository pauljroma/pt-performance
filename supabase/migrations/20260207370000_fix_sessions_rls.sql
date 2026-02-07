-- Fix sessions table RLS for demo user

-- Drop all existing policies
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'sessions'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.sessions', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- Reset RLS
ALTER TABLE public.sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

-- Create simple permissive policies
CREATE POLICY "sessions_select" ON public.sessions FOR SELECT USING (true);
CREATE POLICY "sessions_insert" ON public.sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "sessions_update" ON public.sessions FOR UPDATE USING (true);
CREATE POLICY "sessions_delete" ON public.sessions FOR DELETE USING (true);

-- Ensure grants
GRANT ALL ON public.sessions TO authenticated;
GRANT ALL ON public.sessions TO anon;

-- Also fix session_exercises while we're at it
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'session_exercises'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.session_exercises', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.session_exercises DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "session_exercises_select" ON public.session_exercises FOR SELECT USING (true);
CREATE POLICY "session_exercises_insert" ON public.session_exercises FOR INSERT WITH CHECK (true);
CREATE POLICY "session_exercises_update" ON public.session_exercises FOR UPDATE USING (true);
CREATE POLICY "session_exercises_delete" ON public.session_exercises FOR DELETE USING (true);

GRANT ALL ON public.session_exercises TO authenticated;
GRANT ALL ON public.session_exercises TO anon;

-- Fix scheduled_sessions too
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname FROM pg_policies WHERE tablename = 'scheduled_sessions'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.scheduled_sessions', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.scheduled_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "scheduled_sessions_select" ON public.scheduled_sessions FOR SELECT USING (true);
CREATE POLICY "scheduled_sessions_insert" ON public.scheduled_sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "scheduled_sessions_update" ON public.scheduled_sessions FOR UPDATE USING (true);
CREATE POLICY "scheduled_sessions_delete" ON public.scheduled_sessions FOR DELETE USING (true);

GRANT ALL ON public.scheduled_sessions TO authenticated;
GRANT ALL ON public.scheduled_sessions TO anon;

NOTIFY pgrst, 'reload schema';
