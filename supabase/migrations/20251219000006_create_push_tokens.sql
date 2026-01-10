-- 20251219000005_create_push_tokens.sql
-- Create push notification tokens table for APNs device management
-- Build 69 - Agent 9: Safety - Notifications & QA
--
-- Stores device tokens for push notifications via APNs
-- Supports multi-device per user and token lifecycle management

-- ============================================================================
-- CREATE PUSH_NOTIFICATION_TOKENS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.push_notification_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Device Token Info
  device_token text NOT NULL UNIQUE,
  platform text NOT NULL CHECK (platform IN ('ios', 'android')),

  -- Device Metadata
  device_name text,
  device_model text,
  os_version text,
  app_version text,

  -- Status
  is_active boolean DEFAULT true,

  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  last_used_at timestamptz DEFAULT now(),

  -- Constraints
  CONSTRAINT valid_platform CHECK (platform IN ('ios', 'android'))
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index for user lookups
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id
  ON public.push_notification_tokens(user_id)
  WHERE is_active = true;

-- Index for token lookups
CREATE INDEX IF NOT EXISTS idx_push_tokens_device_token
  ON public.push_notification_tokens(device_token)
  WHERE is_active = true;

-- Index for platform filtering
CREATE INDEX IF NOT EXISTS idx_push_tokens_platform
  ON public.push_notification_tokens(platform)
  WHERE is_active = true;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.push_notification_tokens ENABLE ROW LEVEL SECURITY;

-- Users can view their own device tokens
CREATE POLICY "Users can view own device tokens"
  ON public.push_notification_tokens
  FOR SELECT
  USING (user_id = auth.uid());

-- Users can insert their own device tokens
CREATE POLICY "Users can insert own device tokens"
  ON public.push_notification_tokens
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can update their own device tokens
CREATE POLICY "Users can update own device tokens"
  ON public.push_notification_tokens
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own device tokens
CREATE POLICY "Users can delete own device tokens"
  ON public.push_notification_tokens
  FOR DELETE
  USING (user_id = auth.uid());

-- Service role can manage all tokens (for Edge Functions)
CREATE POLICY "Service can manage all tokens"
  ON public.push_notification_tokens
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_push_token_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on row update
DROP TRIGGER IF EXISTS trigger_update_push_token_updated_at ON public.push_notification_tokens;
CREATE TRIGGER trigger_update_push_token_updated_at
  BEFORE UPDATE ON public.push_notification_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_push_token_updated_at();

-- Function to clean up inactive tokens (older than 90 days)
CREATE OR REPLACE FUNCTION cleanup_inactive_push_tokens()
RETURNS integer AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.push_notification_tokens
  WHERE is_active = false
    AND updated_at < now() - interval '90 days';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- NOTIFICATION LOGS TABLE
-- ============================================================================

-- Track notification delivery for debugging and analytics
CREATE TABLE IF NOT EXISTS public.notification_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_token_id uuid REFERENCES public.push_notification_tokens(id) ON DELETE SET NULL,

  -- Notification Details
  notification_type text NOT NULL,
  title text,
  body text,
  payload jsonb,

  -- Delivery Status
  status text NOT NULL CHECK (status IN ('sent', 'delivered', 'failed', 'pending')),
  error_message text,
  apns_response jsonb,

  -- Timestamps
  created_at timestamptz DEFAULT now(),
  delivered_at timestamptz,

  -- Constraints
  CONSTRAINT valid_status CHECK (status IN ('sent', 'delivered', 'failed', 'pending'))
);

-- Indexes for notification logs
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id
  ON public.notification_logs(user_id);

CREATE INDEX IF NOT EXISTS idx_notification_logs_status
  ON public.notification_logs(status);

CREATE INDEX IF NOT EXISTS idx_notification_logs_created_at
  ON public.notification_logs(created_at DESC);

-- RLS for notification logs
ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;

-- Users can view their own notification logs
CREATE POLICY "Users can view own notification logs"
  ON public.notification_logs
  FOR SELECT
  USING (user_id = auth.uid());

-- Service can insert notification logs
CREATE POLICY "Service can insert notification logs"
  ON public.notification_logs
  FOR INSERT
  WITH CHECK (true);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.push_notification_tokens IS 'Stores APNs device tokens for push notifications (Build 69)';
COMMENT ON COLUMN public.push_notification_tokens.device_token IS 'APNs device token (hex string)';
COMMENT ON COLUMN public.push_notification_tokens.platform IS 'Platform: ios or android';
COMMENT ON COLUMN public.push_notification_tokens.is_active IS 'Whether this token is currently active';

COMMENT ON TABLE public.notification_logs IS 'Tracks push notification delivery status (Build 69)';
COMMENT ON COLUMN public.notification_logs.status IS 'Delivery status: sent, delivered, failed, or pending';

-- ============================================================================
-- VALIDATION
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'PUSH NOTIFICATION TABLES CREATED';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ push_notification_tokens table created';
  RAISE NOTICE '✅ notification_logs table created';
  RAISE NOTICE '✅ RLS policies enabled';
  RAISE NOTICE '✅ Indexes created';
  RAISE NOTICE '✅ Cleanup function created';
  RAISE NOTICE '============================================';
END $$;
