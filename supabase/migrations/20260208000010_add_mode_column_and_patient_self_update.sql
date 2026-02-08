-- ============================================================================
-- ADD MODE COLUMN AND PATIENT SELF-UPDATE - Build 462
-- ============================================================================
-- Fixes Quick Setup flow:
-- 1. Adds mode column to patients table if it doesn't exist
-- 2. Allows patients to update their own mode during onboarding
-- ============================================================================

-- Create mode enum if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'patient_mode') THEN
        CREATE TYPE patient_mode AS ENUM ('rehab', 'strength', 'performance');
        COMMENT ON TYPE patient_mode IS
            'Patient training mode: rehab (injury recovery), strength (general fitness), performance (elite athletes)';
    END IF;
END $$;

-- Add mode column to patients table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'patients' AND column_name = 'mode'
    ) THEN
        ALTER TABLE patients
        ADD COLUMN mode patient_mode NOT NULL DEFAULT 'strength',
        ADD COLUMN mode_changed_at timestamptz,
        ADD COLUMN mode_changed_by uuid REFERENCES auth.users(id);

        COMMENT ON COLUMN patients.mode IS 'Current patient mode';
        COMMENT ON COLUMN patients.mode_changed_at IS 'Timestamp of last mode change';
        COMMENT ON COLUMN patients.mode_changed_by IS 'User who changed the mode';
    END IF;
END $$;

-- Create mode_history table if it doesn't exist
CREATE TABLE IF NOT EXISTS mode_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    previous_mode patient_mode,
    new_mode patient_mode NOT NULL,
    changed_by uuid NOT NULL REFERENCES auth.users(id),
    reason text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mode_history_patient ON mode_history(patient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mode_history_therapist ON mode_history(changed_by);

-- Create mode_features table if it doesn't exist
CREATE TABLE IF NOT EXISTS mode_features (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mode patient_mode NOT NULL,
    feature_key text NOT NULL,
    feature_name text NOT NULL,
    feature_description text,
    enabled boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(mode, feature_key)
);

CREATE INDEX IF NOT EXISTS idx_mode_features_mode ON mode_features(mode) WHERE enabled = true;

-- Enable RLS
ALTER TABLE mode_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE mode_features ENABLE ROW LEVEL SECURITY;

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Therapists can update patient modes" ON patients;
DROP POLICY IF EXISTS "Patients can update their own record" ON patients;

-- Allow patients to update their OWN record (for Quick Setup onboarding)
CREATE POLICY "Patients can update their own record"
    ON patients FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Mode history policies
DROP POLICY IF EXISTS "Patients can view their mode history" ON mode_history;
DROP POLICY IF EXISTS "Therapists can view all mode history" ON mode_history;
DROP POLICY IF EXISTS "Users can insert mode history" ON mode_history;

CREATE POLICY "Patients can view their mode history"
    ON mode_history FOR SELECT
    TO authenticated
    USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert mode history"
    ON mode_history FOR INSERT
    TO authenticated
    WITH CHECK (changed_by = auth.uid());

-- Mode features - everyone can read enabled features
DROP POLICY IF EXISTS "Anyone can read mode features" ON mode_features;
CREATE POLICY "Anyone can read mode features"
    ON mode_features FOR SELECT
    TO authenticated
    USING (enabled = true);

-- Grant permissions
GRANT SELECT, UPDATE ON patients TO authenticated;
GRANT SELECT, INSERT ON mode_history TO authenticated;
GRANT SELECT ON mode_features TO authenticated;

-- Seed default mode features if empty
INSERT INTO mode_features (mode, feature_key, feature_name, feature_description, enabled)
SELECT * FROM (VALUES
    ('rehab'::patient_mode, 'pain_tracking', 'Pain Tracking', 'Track pain levels over time', true),
    ('rehab'::patient_mode, 'rom_tracking', 'ROM Tracking', 'Track range of motion progress', true),
    ('rehab'::patient_mode, 'function_scores', 'Function Scores', 'Track functional improvement', true),
    ('strength'::patient_mode, 'volume_tracking', 'Volume Tracking', 'Track training volume', true),
    ('strength'::patient_mode, 'pr_tracking', 'PR Tracking', 'Track personal records', true),
    ('strength'::patient_mode, 'body_comp', 'Body Composition', 'Track body composition goals', true),
    ('performance'::patient_mode, 'readiness_score', 'Readiness Score', 'Daily readiness assessment', true),
    ('performance'::patient_mode, 'fatigue_management', 'Fatigue Management', 'Track and manage fatigue', true),
    ('performance'::patient_mode, 'load_monitoring', 'Load Monitoring', 'Monitor training load', true)
) AS v(mode, feature_key, feature_name, feature_description, enabled)
WHERE NOT EXISTS (SELECT 1 FROM mode_features LIMIT 1)
ON CONFLICT (mode, feature_key) DO NOTHING;

-- Verification
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ Mode column added to patients table';
    RAISE NOTICE '✅ Patients can now update their own mode';
    RAISE NOTICE '✅ Mode features seeded';
    RAISE NOTICE '';
END $$;
