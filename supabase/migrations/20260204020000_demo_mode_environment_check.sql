-- ============================================================================
-- Demo Mode Environment Check
-- Only allows demo patient access when DEMO_MODE is enabled
-- For production: set demo_mode_enabled = false
-- ============================================================================

-- Create app_settings table if not exists
CREATE TABLE IF NOT EXISTS app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert demo_mode setting (default: true for development)
INSERT INTO app_settings (key, value, description)
VALUES (
    'demo_mode_enabled',
    'true',
    'When true, allows unauthenticated access to demo patient data. SET TO FALSE IN PRODUCTION!'
)
ON CONFLICT (key) DO NOTHING;

-- Create function to check if demo mode is enabled
CREATE OR REPLACE FUNCTION is_demo_mode_enabled()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT COALESCE(
        (SELECT value::boolean FROM app_settings WHERE key = 'demo_mode_enabled'),
        false
    );
$$;

-- Grant execute to authenticated and anon roles
GRANT EXECUTE ON FUNCTION is_demo_mode_enabled() TO authenticated, anon;

-- Allow public read access to app_settings (non-sensitive config)
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read app settings" ON app_settings FOR SELECT USING (true);

-- ============================================================================
-- Update demo patient policies to check demo mode
-- ============================================================================

-- Drop the unconditional demo policies
DROP POLICY IF EXISTS "Demo patient view lab results" ON lab_results;
DROP POLICY IF EXISTS "Demo patient insert lab results" ON lab_results;
DROP POLICY IF EXISTS "Demo patient update lab results" ON lab_results;
DROP POLICY IF EXISTS "Demo patient delete lab results" ON lab_results;
DROP POLICY IF EXISTS "Demo patient view biomarker values" ON biomarker_values;
DROP POLICY IF EXISTS "Demo patient insert biomarker values" ON biomarker_values;

-- Recreate with demo mode check
CREATE POLICY "Demo patient view lab results" ON lab_results
    FOR SELECT USING (
        is_demo_mode_enabled()
        AND patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

CREATE POLICY "Demo patient insert lab results" ON lab_results
    FOR INSERT WITH CHECK (
        is_demo_mode_enabled()
        AND patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

CREATE POLICY "Demo patient update lab results" ON lab_results
    FOR UPDATE USING (
        is_demo_mode_enabled()
        AND patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    ) WITH CHECK (
        is_demo_mode_enabled()
        AND patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

CREATE POLICY "Demo patient delete lab results" ON lab_results
    FOR DELETE USING (
        is_demo_mode_enabled()
        AND patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

CREATE POLICY "Demo patient view biomarker values" ON biomarker_values
    FOR SELECT USING (
        is_demo_mode_enabled()
        AND EXISTS (
            SELECT 1 FROM lab_results lr
            WHERE lr.id = biomarker_values.lab_result_id
            AND lr.patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        )
    );

CREATE POLICY "Demo patient insert biomarker values" ON biomarker_values
    FOR INSERT WITH CHECK (
        is_demo_mode_enabled()
        AND EXISTS (
            SELECT 1 FROM lab_results lr
            WHERE lr.id = biomarker_values.lab_result_id
            AND lr.patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        )
    );

-- ============================================================================
-- Production deployment instructions:
--
-- To disable demo mode for production, run:
--   UPDATE app_settings SET value = 'false' WHERE key = 'demo_mode_enabled';
--
-- This will immediately block all unauthenticated demo patient access
-- while keeping the policies in place for development environments.
-- ============================================================================

COMMENT ON TABLE app_settings IS 'Application configuration settings. demo_mode_enabled controls unauthenticated demo access.';
