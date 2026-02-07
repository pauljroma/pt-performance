-- Check available schemas and PostgREST config
DO $$
DECLARE
    schema_rec record;
BEGIN
    RAISE NOTICE '=== Available schemas ===';
    FOR schema_rec IN SELECT schema_name FROM information_schema.schemata ORDER BY schema_name
    LOOP
        RAISE NOTICE 'Schema: %', schema_rec.schema_name;
    END LOOP;

    RAISE NOTICE '=== Checking pgrst config ===';
    -- Check if there's a pgrst schema
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'pgrst') THEN
        RAISE NOTICE 'pgrst schema exists';
    ELSE
        RAISE NOTICE 'pgrst schema does not exist';
    END IF;

    -- Check if there's an api schema
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'api') THEN
        RAISE NOTICE 'api schema exists';
    ELSE
        RAISE NOTICE 'api schema does not exist - PostgREST should use public';
    END IF;
END $$;
