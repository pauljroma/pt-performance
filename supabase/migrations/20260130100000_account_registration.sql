-- Migration: Account Registration & Subscriptions
-- Build 298: Patient self-registration, subscriptions, therapist linking
-- Timestamp: 20260130100000

-- Make therapist_id nullable (patients can register independently)
ALTER TABLE patients ALTER COLUMN therapist_id DROP NOT NULL;

-- Subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES patients(id) NOT NULL,
    product_id TEXT NOT NULL,
    original_transaction_id TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    expires_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ DEFAULT now(),
    environment TEXT DEFAULT 'production',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Therapist linking codes
CREATE TABLE IF NOT EXISTS linking_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES patients(id) NOT NULL UNIQUE,
    code TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_by UUID REFERENCES therapists(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS policies
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE linking_codes ENABLE ROW LEVEL SECURITY;

-- Subscriptions policies: patients can read their own subscription
CREATE POLICY "patients_read_own_subscription"
    ON subscriptions FOR SELECT
    USING (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

-- Allow service role full access to subscriptions
CREATE POLICY "service_role_manages_subscriptions"
    ON subscriptions FOR ALL
    USING (auth.role() = 'service_role');

-- Allow anon access for demo mode (read-only)
CREATE POLICY "anon_read_subscriptions_demo"
    ON subscriptions FOR SELECT
    TO anon
    USING (true);

-- Linking codes policies: patients manage their own codes
CREATE POLICY "patients_manage_own_linking_codes"
    ON linking_codes FOR ALL
    USING (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

-- Therapists can read linking codes to validate them
CREATE POLICY "therapists_read_linking_codes"
    ON linking_codes FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM therapists WHERE user_id = auth.uid()
    ));

-- Allow anon access for demo mode (read-only)
CREATE POLICY "anon_read_linking_codes_demo"
    ON linking_codes FOR SELECT
    TO anon
    USING (true);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_subscriptions_patient_id ON subscriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_original_transaction_id ON subscriptions(original_transaction_id);
CREATE INDEX IF NOT EXISTS idx_linking_codes_code ON linking_codes(code);
CREATE INDEX IF NOT EXISTS idx_linking_codes_expires_at ON linking_codes(expires_at);

-- Grant access to authenticated users
GRANT SELECT ON subscriptions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON linking_codes TO authenticated;
GRANT ALL ON subscriptions TO service_role;
GRANT ALL ON linking_codes TO service_role;

-- Grant anon access for demo mode
GRANT SELECT ON subscriptions TO anon;
GRANT SELECT ON linking_codes TO anon;
