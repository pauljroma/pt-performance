-- Check what's in the api schema
DO $$
DECLARE
    tbl record;
    func record;
BEGIN
    RAISE NOTICE '=== Tables in api schema ===';
    FOR tbl IN SELECT table_name FROM information_schema.tables WHERE table_schema = 'api'
    LOOP
        RAISE NOTICE 'Table: api.%', tbl.table_name;
    END LOOP;

    RAISE NOTICE '=== Tables in public schema (first 20) ===';
    FOR tbl IN SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' LIMIT 20
    LOOP
        RAISE NOTICE 'Table: public.%', tbl.table_name;
    END LOOP;

    RAISE NOTICE '=== Views in api schema ===';
    FOR tbl IN SELECT table_name FROM information_schema.views WHERE table_schema = 'api'
    LOOP
        RAISE NOTICE 'View: api.%', tbl.table_name;
    END LOOP;
END $$;

-- Grant api schema access to roles
GRANT USAGE ON SCHEMA api TO anon;
GRANT USAGE ON SCHEMA api TO authenticated;
GRANT USAGE ON SCHEMA api TO authenticator;
