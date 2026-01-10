-- Create an RPC function to fix RLS policies
CREATE OR REPLACE FUNCTION fix_content_rls_policies()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER -- Run with elevated permissions
AS $$
BEGIN
    -- Drop existing policies
    EXECUTE 'DROP POLICY IF EXISTS "Allow public read access to published content" ON public.content_items';
    EXECUTE 'DROP POLICY IF EXISTS "Allow authenticated read access to content" ON public.content_items';

    -- Enable RLS
    ALTER TABLE public.content_items ENABLE ROW LEVEL SECURITY;

    -- Create policy for published content
    EXECUTE 'CREATE POLICY "Allow public read access to published content" ON public.content_items FOR SELECT USING (is_published = true)';

    -- Content types policies
    ALTER TABLE public.content_types ENABLE ROW LEVEL SECURITY;
    EXECUTE 'DROP POLICY IF EXISTS "Allow public read access to content_types" ON public.content_types';
    EXECUTE 'CREATE POLICY "Allow public read access to content_types" ON public.content_types FOR SELECT USING (true)';

    RETURN 'RLS policies applied successfully';
END;
$$;
