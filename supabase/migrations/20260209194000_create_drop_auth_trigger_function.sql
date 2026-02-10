-- ============================================================================
-- CREATE DROP AUTH TRIGGER FUNCTION - Build 471 Fix
-- ============================================================================
-- Creates a function that can be called via RPC to drop the problematic trigger
-- This works because the function is owned by postgres and uses SECURITY DEFINER
-- ============================================================================

-- Create a function to drop the auth trigger
-- This runs as postgres user due to SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.drop_auth_user_triggers()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result jsonb := '{"dropped": [], "errors": []}';
    trigger_name text;
BEGIN
    -- Drop the create_patient trigger
    BEGIN
        DROP TRIGGER IF EXISTS on_auth_user_created_create_patient ON auth.users;
        result := jsonb_set(result, '{dropped}', result->'dropped' || '"on_auth_user_created_create_patient"');
    EXCEPTION WHEN OTHERS THEN
        result := jsonb_set(result, '{errors}', result->'errors' || to_jsonb(SQLERRM));
    END;

    -- Drop the link_patient trigger
    BEGIN
        DROP TRIGGER IF EXISTS on_auth_user_created_link_patient ON auth.users;
        result := jsonb_set(result, '{dropped}', result->'dropped' || '"on_auth_user_created_link_patient"');
    EXCEPTION WHEN OTHERS THEN
        result := jsonb_set(result, '{errors}', result->'errors' || to_jsonb(SQLERRM));
    END;

    RETURN result;
END;
$$;

-- Grant execute to service_role so it can be called via RPC
GRANT EXECUTE ON FUNCTION public.drop_auth_user_triggers() TO service_role;

-- Also grant to postgres for direct calls
ALTER FUNCTION public.drop_auth_user_triggers() OWNER TO postgres;

-- Verification message
DO $$
BEGIN
    RAISE NOTICE '✅ Created drop_auth_user_triggers function';
    RAISE NOTICE 'Call via RPC: POST /rest/v1/rpc/drop_auth_user_triggers';
END $$;
