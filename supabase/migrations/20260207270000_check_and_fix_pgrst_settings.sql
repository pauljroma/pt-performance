-- Check and fix PostgREST settings
-- This ensures the authenticator role has proper access

-- Check current settings (will show in migration output)
DO $$
BEGIN
    RAISE NOTICE 'Checking PostgREST configuration...';

    -- Check if authenticator role exists
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticator') THEN
        RAISE NOTICE 'authenticator role exists';
    ELSE
        RAISE NOTICE 'authenticator role MISSING!';
    END IF;

    -- Check if anon role exists
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        RAISE NOTICE 'anon role exists';
    ELSE
        RAISE NOTICE 'anon role MISSING!';
    END IF;

    -- Check if authenticated role exists
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        RAISE NOTICE 'authenticated role exists';
    ELSE
        RAISE NOTICE 'authenticated role MISSING!';
    END IF;
END $$;

-- Ensure authenticator can switch to anon/authenticated
GRANT anon TO authenticator;
GRANT authenticated TO authenticator;

-- Ensure proper schema access
GRANT USAGE ON SCHEMA public TO authenticator;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant access to all existing tables
DO $$
DECLARE
    tbl record;
BEGIN
    FOR tbl IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', tbl.tablename);
        EXECUTE format('GRANT SELECT ON public.%I TO anon', tbl.tablename);
    END LOOP;
    RAISE NOTICE 'Granted table permissions';
END $$;

-- Grant access to all existing functions
DO $$
DECLARE
    func record;
BEGIN
    FOR func IN
        SELECT p.proname, pg_get_function_identity_arguments(p.oid) as args
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
    LOOP
        BEGIN
            EXECUTE format('GRANT EXECUTE ON FUNCTION public.%I(%s) TO authenticated', func.proname, func.args);
            EXECUTE format('GRANT EXECUTE ON FUNCTION public.%I(%s) TO anon', func.proname, func.args);
        EXCEPTION WHEN OTHERS THEN
            -- Skip functions that can't be granted (e.g., triggers)
            NULL;
        END;
    END LOOP;
    RAISE NOTICE 'Granted function permissions';
END $$;

-- Force cache reload
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
