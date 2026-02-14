-- Create Wearable Connections Table
-- ACP-472: Multi-Wearable Integration Architecture
-- Tracks connected wearable devices per patient with OAuth credentials,
-- sync configuration, and primary device designation.
--
-- Supports: WHOOP, Oura, Apple Watch, Garmin
-- Migrates existing WHOOP credentials from patients table.

BEGIN;

-- ============================================================================
-- 1. WEARABLE CONNECTIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.wearable_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,

    -- Device identification
    wearable_type TEXT NOT NULL CHECK (wearable_type IN ('whoop', 'oura', 'apple_watch', 'garmin')),
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,

    -- Connection timestamps
    connected_at TIMESTAMPTZ DEFAULT NOW(),
    last_sync_at TIMESTAMPTZ,

    -- OAuth tokens stored as JSONB. Disk-level encryption via Supabase.
    -- For column-level encryption, consider pgcrypto or Supabase Vault.
    credentials JSONB,

    -- Device name, firmware version, model, etc.
    device_metadata JSONB,

    -- Sync configuration with sensible defaults
    sync_config JSONB DEFAULT '{"auto_sync": true, "sync_interval_minutes": 60}'::jsonb,

    -- Audit timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 2. INDEXES
-- ============================================================================

-- Only one primary wearable per patient (among active connections)
CREATE UNIQUE INDEX IF NOT EXISTS idx_wearable_primary
    ON public.wearable_connections (patient_id)
    WHERE is_primary = TRUE AND is_active = TRUE;

-- One active connection per wearable type per patient
CREATE UNIQUE INDEX IF NOT EXISTS idx_wearable_unique_type
    ON public.wearable_connections (patient_id, wearable_type)
    WHERE is_active = TRUE;

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_wearable_connections_patient_id
    ON public.wearable_connections (patient_id);
CREATE INDEX IF NOT EXISTS idx_wearable_connections_type
    ON public.wearable_connections (wearable_type);
CREATE INDEX IF NOT EXISTS idx_wearable_connections_last_sync
    ON public.wearable_connections (last_sync_at DESC)
    WHERE is_active = TRUE;

-- ============================================================================
-- 3. COMMENTS
-- ============================================================================

COMMENT ON TABLE public.wearable_connections IS
    'Tracks connected wearable devices (WHOOP, Oura, Apple Watch, Garmin) per patient';
COMMENT ON COLUMN public.wearable_connections.is_primary IS
    'Designates the primary wearable used for readiness/recovery data';
COMMENT ON COLUMN public.wearable_connections.credentials IS
    'JSONB containing OAuth tokens: {"access_token", "refresh_token", "expires_at"}. Disk-level encryption via Supabase; for column-level encryption, consider pgcrypto or Supabase Vault.';
COMMENT ON COLUMN public.wearable_connections.device_metadata IS
    'Device-specific metadata: {"device_name", "firmware_version", "model", "serial_number"}';
COMMENT ON COLUMN public.wearable_connections.sync_config IS
    'Sync preferences: {"auto_sync": bool, "sync_interval_minutes": int, "metrics_enabled": [...]}';

-- ============================================================================
-- 4. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.wearable_connections ENABLE ROW LEVEL SECURITY;

-- Patients can view their own connections
CREATE POLICY "Patients can view own wearable connections"
    ON public.wearable_connections
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

-- Patients can insert their own connections
CREATE POLICY "Patients can create own wearable connections"
    ON public.wearable_connections
    FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

-- Patients can update their own connections
CREATE POLICY "Patients can update own wearable connections"
    ON public.wearable_connections
    FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

-- Patients can delete their own connections
CREATE POLICY "Patients can delete own wearable connections"
    ON public.wearable_connections
    FOR DELETE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients WHERE user_id = auth.uid()
        )
    );

-- Therapists can view their patients' connections (read-only)
CREATE POLICY "Therapists can view patient wearable connections"
    ON public.wearable_connections
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.therapists t
            JOIN public.patients p ON p.therapist_id = t.id
            WHERE t.user_id = auth.uid()
            AND p.id = patient_id
        )
    );

-- ============================================================================
-- 5. UPDATED_AT TRIGGER
-- ============================================================================

-- Depends on: update_updated_at_column() from 20260104220000_build138_complete_schema.sql
CREATE TRIGGER update_wearable_connections_updated_at
    BEFORE UPDATE ON public.wearable_connections
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 6. MIGRATE EXISTING WHOOP CREDENTIALS
-- ============================================================================
-- Move WHOOP credentials from the patients table into wearable_connections.
-- Sets WHOOP as primary for patients who already had it connected.

INSERT INTO public.wearable_connections (
    patient_id,
    wearable_type,
    is_primary,
    is_active,
    credentials,
    connected_at
)
SELECT
    id,
    'whoop',
    TRUE,
    TRUE,
    whoop_credentials,
    COALESCE(updated_at, NOW())
FROM public.patients
WHERE whoop_credentials IS NOT NULL
ON CONFLICT (patient_id, wearable_type) WHERE is_active = TRUE
DO UPDATE SET credentials = EXCLUDED.credentials, is_primary = TRUE;

-- ============================================================================
-- 7. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.wearable_connections TO authenticated;

COMMIT;
