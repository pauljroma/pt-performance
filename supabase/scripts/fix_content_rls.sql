-- Fix RLS policies for content_items table
-- Allow public read access to published articles

BEGIN;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow public read access to published content" ON public.content_items;
DROP POLICY IF EXISTS "Allow authenticated read access to content" ON public.content_items;

-- Enable RLS on content_items
ALTER TABLE public.content_items ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read published content
CREATE POLICY "Allow public read access to published content"
ON public.content_items
FOR SELECT
USING (is_published = true);

-- Same for content_types
ALTER TABLE public.content_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to content_types" ON public.content_types;

CREATE POLICY "Allow public read access to content_types"
ON public.content_types
FOR SELECT
USING (true);

-- Allow public read access to user_progress for their own records
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own progress" ON public.user_progress;
DROP POLICY IF EXISTS "Users can insert their own progress" ON public.user_progress;
DROP POLICY IF EXISTS "Users can update their own progress" ON public.user_progress;

CREATE POLICY "Users can read their own progress"
ON public.user_progress
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress"
ON public.user_progress
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress"
ON public.user_progress
FOR UPDATE
USING (auth.uid() = user_id);

-- Allow public read/write access to content_interactions for analytics
ALTER TABLE public.content_interactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public to track content interactions" ON public.content_interactions;

CREATE POLICY "Allow public to track content interactions"
ON public.content_interactions
FOR INSERT
WITH CHECK (true);

COMMIT;
