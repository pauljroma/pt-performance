-- Create a simple test view to verify API access
-- This will help diagnose if PostgREST can see anything

-- Create a simple test function
CREATE OR REPLACE FUNCTION public.api_health_check()
RETURNS TABLE(status text, checked_at timestamptz)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT 'healthy'::text, now();
$$;

GRANT EXECUTE ON FUNCTION public.api_health_check() TO anon;
GRANT EXECUTE ON FUNCTION public.api_health_check() TO authenticated;

-- Create a simple view
CREATE OR REPLACE VIEW public.api_test AS
SELECT 'API is working' as message, now() as checked_at;

GRANT SELECT ON public.api_test TO anon;
GRANT SELECT ON public.api_test TO authenticated;

-- Notify reload
NOTIFY pgrst, 'reload schema';
