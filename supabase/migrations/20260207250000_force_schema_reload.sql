-- Force PostgREST schema cache reload
-- This migration re-grants permissions to trigger a full schema refresh

-- Revoke and re-grant on a core table to force schema reload
REVOKE SELECT ON public.patients FROM anon;
GRANT SELECT ON public.patients TO anon;

REVOKE SELECT ON public.patients FROM authenticated;
GRANT SELECT ON public.patients TO authenticated;

-- Also touch sessions table
REVOKE SELECT ON public.sessions FROM anon;
GRANT SELECT ON public.sessions TO anon;

REVOKE SELECT ON public.sessions FROM authenticated;
GRANT SELECT ON public.sessions TO authenticated;

-- Force the reload signal
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- Verify tables are accessible
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
LIMIT 5;
