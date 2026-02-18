-- 20260218000000_create_app_feedback_table.sql
-- ACP-979: Create app_feedback table for in-app review feedback collection
-- Low-rating feedback (1-3 stars) from AppStoreReviewPromptView is stored here
-- instead of routing to the App Store.

CREATE TABLE IF NOT EXISTS app_feedback (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id text NOT NULL,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  feedback text,
  app_version text,
  build_number text,
  timestamp timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- RLS: anyone authenticated can insert feedback, only service role can read
ALTER TABLE app_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own feedback"
  ON app_feedback FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Service role can read feedback"
  ON app_feedback FOR SELECT
  USING (auth.role() = 'service_role');
