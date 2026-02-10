-- ============================================================================
-- CREATE/UPDATE LINKING CODES TABLE
-- ============================================================================
-- Stores temporary linking codes for therapist-patient connections
-- ============================================================================

-- Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS linking_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL UNIQUE REFERENCES patients(id) ON DELETE CASCADE,
    code VARCHAR(8) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'linking_codes' AND column_name = 'used_at') THEN
        ALTER TABLE linking_codes ADD COLUMN used_at TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'linking_codes' AND column_name = 'updated_at') THEN
        ALTER TABLE linking_codes ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'linking_codes' AND column_name = 'created_at') THEN
        ALTER TABLE linking_codes ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- Comments
COMMENT ON TABLE linking_codes IS 'Temporary codes for linking therapists to patients';
COMMENT ON COLUMN linking_codes.patient_id IS 'The patient who generated this code';
COMMENT ON COLUMN linking_codes.code IS '8-character alphanumeric linking code';
COMMENT ON COLUMN linking_codes.expires_at IS 'When this code expires (typically 24 hours)';
COMMENT ON COLUMN linking_codes.used_by IS 'Therapist user_id who claimed this code';
COMMENT ON COLUMN linking_codes.used_at IS 'When the code was used';

-- Index for code lookups
CREATE INDEX IF NOT EXISTS idx_linking_codes_code ON linking_codes(code);
CREATE INDEX IF NOT EXISTS idx_linking_codes_expires_at ON linking_codes(expires_at);

-- Enable RLS
ALTER TABLE linking_codes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Patients can view own linking codes" ON linking_codes;
DROP POLICY IF EXISTS "Patients can insert own linking codes" ON linking_codes;
DROP POLICY IF EXISTS "Patients can update own linking codes" ON linking_codes;
DROP POLICY IF EXISTS "Patients can delete own linking codes" ON linking_codes;
DROP POLICY IF EXISTS "Therapists can view valid codes" ON linking_codes;
DROP POLICY IF EXISTS "Therapists can claim unused codes" ON linking_codes;

-- RLS Policies

-- Patients can view and manage their own linking codes
CREATE POLICY "Patients can view own linking codes"
    ON linking_codes FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Patients can insert own linking codes"
    ON linking_codes FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Patients can update own linking codes"
    ON linking_codes FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Patients can delete own linking codes"
    ON linking_codes FOR DELETE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Therapists can view and claim unused codes (for linking)
CREATE POLICY "Therapists can view valid codes"
    ON linking_codes FOR SELECT
    USING (
        used_by IS NULL AND expires_at > NOW()
    );

CREATE POLICY "Therapists can claim unused codes"
    ON linking_codes FOR UPDATE
    USING (
        used_by IS NULL AND expires_at > NOW()
    )
    WITH CHECK (
        used_by = auth.uid()
    );

-- Grant permissions
GRANT ALL ON linking_codes TO authenticated;

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_linking_codes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_linking_codes_updated_at ON linking_codes;
CREATE TRIGGER trigger_update_linking_codes_updated_at
    BEFORE UPDATE ON linking_codes
    FOR EACH ROW
    EXECUTE FUNCTION update_linking_codes_updated_at();

-- Success message
DO $$ BEGIN RAISE NOTICE 'Created/updated linking_codes table with RLS policies'; END $$;
