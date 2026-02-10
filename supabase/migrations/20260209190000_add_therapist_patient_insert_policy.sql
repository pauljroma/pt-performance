-- ============================================================================
-- ADD THERAPIST PATIENT INSERT POLICY - Build 471 Fix
-- ============================================================================
-- Problem: Therapists cannot create new patients because there's no INSERT policy
-- Solution: Add RLS policy allowing therapists to insert patients under their care
-- ============================================================================

-- First ensure the columns exist (in case earlier migrations weren't applied)

-- Add injury_type column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'patients' AND column_name = 'injury_type'
    ) THEN
        ALTER TABLE patients ADD COLUMN injury_type TEXT;
        COMMENT ON COLUMN patients.injury_type IS 'Type of injury being treated';
        RAISE NOTICE '✅ Added injury_type column to patients table';
    ELSE
        RAISE NOTICE 'injury_type column already exists';
    END IF;
END $$;

-- Add target_level column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'patients' AND column_name = 'target_level'
    ) THEN
        ALTER TABLE patients ADD COLUMN target_level TEXT DEFAULT 'Recreational';
        COMMENT ON COLUMN patients.target_level IS 'Target athletic level';
        RAISE NOTICE '✅ Added target_level column to patients table';
    ELSE
        RAISE NOTICE 'target_level column already exists';
    END IF;
END $$;

-- Add mode column if it doesn't exist (as text, not enum for flexibility)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'patients' AND column_name = 'mode'
    ) THEN
        -- Add as TEXT to avoid enum issues
        ALTER TABLE patients ADD COLUMN mode TEXT DEFAULT 'strength';
        COMMENT ON COLUMN patients.mode IS 'Patient mode: rehab, strength, or performance';
        RAISE NOTICE '✅ Added mode column to patients table';
    ELSE
        RAISE NOTICE 'mode column already exists';
    END IF;
END $$;

-- ============================================================================
-- RLS POLICY: Allow therapists to insert patients
-- ============================================================================

-- Note: is_therapist function already exists from previous migrations

-- Drop existing policy if exists (to recreate cleanly)
DROP POLICY IF EXISTS "Therapists can insert patients" ON patients;

-- Create policy allowing therapists to insert new patients
-- Therapists can only insert patients where they are set as the therapist_id
CREATE POLICY "Therapists can insert patients"
    ON patients FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Must be a therapist
        is_therapist(auth.uid())
        AND (
            -- Either therapist_id is set to the therapist's ID
            therapist_id::text = auth.uid()::text
            -- Or therapist_id matches the therapist's record ID
            OR therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
        )
    );

-- Also ensure therapists can update patients they manage
DROP POLICY IF EXISTS "Therapists can update their patients" ON patients;

CREATE POLICY "Therapists can update their patients"
    ON patients FOR UPDATE
    TO authenticated
    USING (
        therapist_id::text = auth.uid()::text
        OR therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
    )
    WITH CHECK (
        therapist_id::text = auth.uid()::text
        OR therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
    );

-- Grant insert permission explicitly
GRANT INSERT ON patients TO authenticated;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
DECLARE
    policy_count INTEGER;
    col_count INTEGER;
BEGIN
    -- Check columns exist
    SELECT COUNT(*) INTO col_count
    FROM information_schema.columns
    WHERE table_name = 'patients'
    AND column_name IN ('injury_type', 'target_level', 'mode');

    -- Check policies exist
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'patients'
    AND policyname LIKE 'Therapists can%';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Migration Complete: Therapist Patient Insert';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Columns verified: % of 3', col_count;
    RAISE NOTICE 'Therapist policies: %', policy_count;
    RAISE NOTICE '';
END $$;
