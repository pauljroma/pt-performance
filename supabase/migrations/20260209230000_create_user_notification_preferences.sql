-- ============================================================================
-- CREATE USER NOTIFICATION PREFERENCES TABLE
-- ============================================================================
-- Stores user notification settings for check-in reminders, task alerts, etc.
-- ============================================================================

-- Create the table
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,  -- References auth.users(id)
    check_in_reminder_time TIME DEFAULT '08:00:00',
    task_reminders_enabled BOOLEAN DEFAULT true,
    pt_alerts_enabled BOOLEAN DEFAULT true,
    streak_milestones_enabled BOOLEAN DEFAULT true,
    brief_notifications_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Comments
COMMENT ON TABLE user_notification_preferences IS 'User notification preferences for push notifications';
COMMENT ON COLUMN user_notification_preferences.user_id IS 'References the auth.users(id) - user who owns these preferences';
COMMENT ON COLUMN user_notification_preferences.check_in_reminder_time IS 'Daily check-in reminder time (HH:MM:SS format)';
COMMENT ON COLUMN user_notification_preferences.task_reminders_enabled IS 'Whether to send task reminder notifications';
COMMENT ON COLUMN user_notification_preferences.pt_alerts_enabled IS 'Whether to send PT/therapist alert notifications';
COMMENT ON COLUMN user_notification_preferences.streak_milestones_enabled IS 'Whether to send streak milestone notifications';
COMMENT ON COLUMN user_notification_preferences.brief_notifications_enabled IS 'Whether to send daily brief notifications';

-- Index for lookups by user_id
CREATE INDEX IF NOT EXISTS idx_user_notification_preferences_user_id
    ON user_notification_preferences(user_id);

-- Enable RLS
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own preferences
CREATE POLICY "Users can view their own notification preferences"
    ON user_notification_preferences FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notification preferences"
    ON user_notification_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notification preferences"
    ON user_notification_preferences FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notification preferences"
    ON user_notification_preferences FOR DELETE
    USING (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON user_notification_preferences TO authenticated;

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_user_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_user_notification_preferences_updated_at ON user_notification_preferences;
CREATE TRIGGER trigger_update_user_notification_preferences_updated_at
    BEFORE UPDATE ON user_notification_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_user_notification_preferences_updated_at();

-- Success message
DO $$ BEGIN RAISE NOTICE 'Created user_notification_preferences table with RLS policies'; END $$;
