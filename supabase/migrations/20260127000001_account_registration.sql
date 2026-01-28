-- Migration: Account Registration & Subscriptions
-- Build 298: Patient self-registration, subscriptions, therapist linking
-- Prerequisite for App Store submission

-- 1. Make therapist_id nullable (patients can register independently)
ALTER TABLE patients ALTER COLUMN therapist_id DROP NOT NULL;

-- 2. Subscriptions table for StoreKit 2 in-app purchases
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

CREATE INDEX IF NOT EXISTS idx_subscriptions_patient_id ON subscriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- 3. Therapist linking codes
CREATE TABLE IF NOT EXISTS linking_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES patients(id) NOT NULL UNIQUE,
    code TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_by UUID REFERENCES therapists(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_linking_codes_code ON linking_codes(code);

-- 4. RLS policies for subscriptions
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients read own subscription"
    ON subscriptions FOR SELECT
    USING (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

CREATE POLICY "Service role manages subscriptions"
    ON subscriptions FOR ALL
    USING (auth.role() = 'service_role');

-- 5. RLS policies for linking codes
ALTER TABLE linking_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients manage own linking codes"
    ON linking_codes FOR ALL
    USING (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

CREATE POLICY "Therapists read linking codes"
    ON linking_codes FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM therapists WHERE user_id = auth.uid()
    ));

-- 6. Grant access to authenticated users
GRANT SELECT ON subscriptions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON linking_codes TO authenticated;
GRANT ALL ON subscriptions TO service_role;
GRANT ALL ON linking_codes TO service_role;
