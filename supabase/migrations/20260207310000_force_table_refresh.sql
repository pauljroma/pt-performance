-- Force table refresh by touching grants and adding a comment
-- This should force PostgREST to see the tables

-- Touch the patients table
COMMENT ON TABLE public.patients IS 'Patient records - refreshed 2026-02-07';
REVOKE ALL ON public.patients FROM anon;
REVOKE ALL ON public.patients FROM authenticated;
GRANT SELECT ON public.patients TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.patients TO authenticated;

-- Touch the sessions table
COMMENT ON TABLE public.sessions IS 'Training sessions - refreshed 2026-02-07';
REVOKE ALL ON public.sessions FROM anon;
REVOKE ALL ON public.sessions FROM authenticated;
GRANT SELECT ON public.sessions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sessions TO authenticated;

-- Touch scheduled_sessions
COMMENT ON TABLE public.scheduled_sessions IS 'Scheduled sessions - refreshed 2026-02-07';
REVOKE ALL ON public.scheduled_sessions FROM anon;
REVOKE ALL ON public.scheduled_sessions FROM authenticated;
GRANT SELECT ON public.scheduled_sessions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.scheduled_sessions TO authenticated;

-- Touch program_library
COMMENT ON TABLE public.program_library IS 'Program library - refreshed 2026-02-07';
REVOKE ALL ON public.program_library FROM anon;
REVOKE ALL ON public.program_library FROM authenticated;
GRANT SELECT ON public.program_library TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.program_library TO authenticated;

-- Touch programs
COMMENT ON TABLE public.programs IS 'Programs - refreshed 2026-02-07';
REVOKE ALL ON public.programs FROM anon;
REVOKE ALL ON public.programs FROM authenticated;
GRANT SELECT ON public.programs TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.programs TO authenticated;

-- Touch streak_records
COMMENT ON TABLE public.streak_records IS 'Streak records - refreshed 2026-02-07';
REVOKE ALL ON public.streak_records FROM anon;
REVOKE ALL ON public.streak_records FROM authenticated;
GRANT SELECT ON public.streak_records TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.streak_records TO authenticated;

-- Force reload
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
