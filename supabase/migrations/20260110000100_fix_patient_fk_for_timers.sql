-- Fix patient foreign key issue for workout_timers
-- Issue: Auth users don't have corresponding entries in patients table

-- First, check if patients table exists and show its structure
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename = 'patients'
    ) THEN
        RAISE NOTICE 'patients table exists';
    ELSE
        RAISE NOTICE 'patients table DOES NOT exist - this is the problem!';
    END IF;
END $$;

-- Show all tables that reference patients
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND ccu.table_name = 'patients';

-- If patients table doesn't exist, we need to either:
-- 1. Create it
-- 2. Or change workout_timers to reference auth.users directly

-- For now, let's create a basic patients table that mirrors auth.users
CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create trigger to auto-create patient record when user signs up
CREATE OR REPLACE FUNCTION create_patient_on_signup()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO patients (id, first_name, last_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'Unknown')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created_create_patient ON auth.users;
CREATE TRIGGER on_auth_user_created_create_patient
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_patient_on_signup();

-- Backfill: Insert existing auth users into patients table with default values
INSERT INTO patients (id, first_name, last_name)
SELECT
    id,
    COALESCE(raw_user_meta_data->>'first_name', 'User'),
    COALESCE(raw_user_meta_data->>'last_name', 'Unknown')
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- Show how many patients were created
SELECT
    (SELECT COUNT(*) FROM auth.users) as total_auth_users,
    (SELECT COUNT(*) FROM patients) as total_patients,
    (SELECT COUNT(*) FROM auth.users WHERE id NOT IN (SELECT id FROM patients)) as missing_patients;

-- Enable RLS on patients table
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies
CREATE POLICY "Users can view their own patient record"
    ON patients FOR SELECT
    TO authenticated
    USING (id = auth.uid());

CREATE POLICY "Users can update their own patient record"
    ON patients FOR UPDATE
    TO authenticated
    USING (id = auth.uid());
