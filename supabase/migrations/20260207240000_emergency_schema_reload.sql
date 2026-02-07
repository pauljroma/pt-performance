-- Emergency schema cache reload
-- This forces PostgREST to reload all table/function definitions

-- Reload schema cache
NOTIFY pgrst, 'reload schema';

-- Also notify config reload for good measure
NOTIFY pgrst, 'reload config';
