-- Check all views with SECURITY DEFINER
SELECT
  schemaname,
  viewname,
  viewowner,
  definition
FROM pg_views
WHERE schemaname = 'public'
  AND definition ILIKE '%SECURITY DEFINER%';

-- Check all functions with SECURITY DEFINER
SELECT
  n.nspname as schema,
  p.proname as function_name,
  pg_get_functiondef(p.oid) as definition
FROM pg_proc p
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND pg_get_functiondef(p.oid) ILIKE '%SECURITY DEFINER%';
