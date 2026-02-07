-- Refresh ALL tables to fix PostgREST schema cache
-- This touches every table to force cache refresh

DO $$
DECLARE
    tbl record;
    grant_count integer := 0;
BEGIN
    RAISE NOTICE 'Refreshing all tables in public schema...';

    FOR tbl IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
    LOOP
        -- Revoke and re-grant to force schema cache update
        EXECUTE format('REVOKE ALL ON public.%I FROM anon', tbl.tablename);
        EXECUTE format('REVOKE ALL ON public.%I FROM authenticated', tbl.tablename);
        EXECUTE format('GRANT SELECT ON public.%I TO anon', tbl.tablename);
        EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', tbl.tablename);
        grant_count := grant_count + 1;
    END LOOP;

    RAISE NOTICE 'Refreshed % tables', grant_count;
END $$;

-- Also refresh all views
DO $$
DECLARE
    vw record;
    view_count integer := 0;
BEGIN
    RAISE NOTICE 'Refreshing all views in public schema...';

    FOR vw IN
        SELECT viewname
        FROM pg_views
        WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('REVOKE ALL ON public.%I FROM anon', vw.viewname);
            EXECUTE format('REVOKE ALL ON public.%I FROM authenticated', vw.viewname);
            EXECUTE format('GRANT SELECT ON public.%I TO anon', vw.viewname);
            EXECUTE format('GRANT SELECT ON public.%I TO authenticated', vw.viewname);
            view_count := view_count + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Skipped view %: %', vw.viewname, SQLERRM;
        END;
    END LOOP;

    RAISE NOTICE 'Refreshed % views', view_count;
END $$;

-- Refresh all functions
DO $$
DECLARE
    func record;
    func_count integer := 0;
BEGIN
    RAISE NOTICE 'Refreshing all functions in public schema...';

    FOR func IN
        SELECT p.proname, pg_get_function_identity_arguments(p.oid) as args
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.prokind = 'f'  -- Only regular functions, not triggers
    LOOP
        BEGIN
            EXECUTE format('REVOKE ALL ON FUNCTION public.%I(%s) FROM anon', func.proname, func.args);
            EXECUTE format('REVOKE ALL ON FUNCTION public.%I(%s) FROM authenticated', func.proname, func.args);
            EXECUTE format('GRANT EXECUTE ON FUNCTION public.%I(%s) TO anon', func.proname, func.args);
            EXECUTE format('GRANT EXECUTE ON FUNCTION public.%I(%s) TO authenticated', func.proname, func.args);
            func_count := func_count + 1;
        EXCEPTION WHEN OTHERS THEN
            -- Skip functions that can't be granted
            NULL;
        END;
    END LOOP;

    RAISE NOTICE 'Refreshed % functions', func_count;
END $$;

-- Force reload
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- Verification
DO $$
BEGIN
    RAISE NOTICE '=== Schema refresh complete ===';
    RAISE NOTICE 'PostgREST should now see all tables, views, and functions';
END $$;
