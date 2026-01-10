-- Add RLS policies for help_articles table
-- Allows public read access to published articles

BEGIN;

-- Enable RLS on help_articles table
ALTER TABLE public.help_articles ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public read access to published articles
CREATE POLICY "Public read access to published help articles"
ON public.help_articles
FOR SELECT
USING (is_published = true);

-- Policy: Allow authenticated users to increment view counts
-- (via increment_article_view function which is SECURITY DEFINER)

-- Enable RLS on article_interactions table
ALTER TABLE public.article_interactions ENABLE ROW LEVEL SECURITY;

-- Policy: Allow users to insert their own interactions
CREATE POLICY "Users can insert their own article interactions"
ON public.article_interactions
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Policy: Allow users to view their own interactions
CREATE POLICY "Users can view their own article interactions"
ON public.article_interactions
FOR SELECT
TO authenticated
USING (auth.uid() = user_id OR user_id IS NULL);

-- Enable RLS on article_references table
ALTER TABLE public.article_references ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public read access to references for published articles
CREATE POLICY "Public read access to article references"
ON public.article_references
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.help_articles
        WHERE help_articles.id = article_references.article_id
        AND help_articles.is_published = true
    )
);

COMMIT;
