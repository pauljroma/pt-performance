-- Create user_subscriptions table for storing validated App Store subscriptions
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    transaction_id TEXT NOT NULL,
    original_transaction_id TEXT NOT NULL,
    purchase_date TIMESTAMPTZ NOT NULL,
    expires_date TIMESTAMPTZ,
    is_trial BOOLEAN DEFAULT FALSE,
    environment TEXT,  -- 'Sandbox' or 'Production'
    validated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'active',  -- 'active', 'expired', 'cancelled'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT unique_user_subscription UNIQUE (user_id)
);

-- Index for quick lookups
CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX idx_user_subscriptions_expires ON user_subscriptions(expires_date);

-- RLS policies
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can view their own subscription
CREATE POLICY "Users can view own subscription"
    ON user_subscriptions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Only service role can insert/update (via edge function)
CREATE POLICY "Service role can manage subscriptions"
    ON user_subscriptions
    FOR ALL
    USING (auth.role() = 'service_role');

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_user_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_subscriptions_timestamp
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_subscriptions_updated_at();

COMMENT ON TABLE user_subscriptions IS 'Stores validated App Store subscription information';
