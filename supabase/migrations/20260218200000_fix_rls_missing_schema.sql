-- Build 536: Fix RLS policies that query auth.users + add missing schema objects
--
-- Problems fixed:
-- 1. RLS policies that SELECT from auth.users fail with "permission denied for table users"
--    because authenticated role cannot query auth.users. Fix: use is_therapist() SECURITY DEFINER.
-- 2. audit_logs missing 'details' and 'device_id' columns expected by iOS AuditEntryInsert model
-- 3. deferred_deep_links table missing entirely (referenced by DeepLinkService)
--
-- Tables affected: fatigue_accumulation, deload_recommendations, active_deloads,
--   health_kit_data, hrv_baselines, automation_webhooks, automation_logs,
--   data_conflicts, patients, audit_logs

BEGIN;

-- ============================================================================
-- 0. Ensure is_therapist() helper exists (SECURITY DEFINER — safe auth.users access)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_therapist()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.therapists
        WHERE user_id = auth.uid()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_therapist() TO authenticated;

-- Helper: get current user's email via JWT (avoids auth.users query)
CREATE OR REPLACE FUNCTION public.auth_email()
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
    SELECT auth.jwt() ->> 'email';
$$;

GRANT EXECUTE ON FUNCTION public.auth_email() TO authenticated;
GRANT EXECUTE ON FUNCTION public.auth_email() TO anon;

-- ============================================================================
-- 1. fatigue_accumulation — fix therapist policies
-- ============================================================================

-- From 20260201160001
DROP POLICY IF EXISTS "fatigue_accum_therapist_select" ON fatigue_accumulation;
-- From 20260201100000
DROP POLICY IF EXISTS "fatigue_therapists_select_all" ON fatigue_accumulation;

CREATE POLICY "fatigue_accum_therapist_select"
    ON fatigue_accumulation FOR SELECT
    TO authenticated
    USING (is_therapist());

-- ============================================================================
-- 2. deload_recommendations — fix therapist policy
-- ============================================================================

DROP POLICY IF EXISTS "deload_rec_therapists_select_all" ON deload_recommendations;

CREATE POLICY "deload_rec_therapists_select_all"
    ON deload_recommendations FOR SELECT
    TO authenticated
    USING (is_therapist());

-- ============================================================================
-- 3. active_deloads — fix therapist policies
-- ============================================================================

DROP POLICY IF EXISTS "active_deload_therapists_select_all" ON active_deloads;
DROP POLICY IF EXISTS "active_deload_therapists_update_all" ON active_deloads;

CREATE POLICY "active_deload_therapists_select_all"
    ON active_deloads FOR SELECT
    TO authenticated
    USING (is_therapist());

CREATE POLICY "active_deload_therapists_update_all"
    ON active_deloads FOR UPDATE
    TO authenticated
    USING (is_therapist())
    WITH CHECK (is_therapist());

-- ============================================================================
-- 4. health_kit_data — fix therapist policy
-- ============================================================================

DROP POLICY IF EXISTS "Therapists can view patient healthkit data" ON health_kit_data;

CREATE POLICY "Therapists can view patient healthkit data"
    ON health_kit_data FOR SELECT
    TO authenticated
    USING (is_therapist());

-- ============================================================================
-- 5. hrv_baselines — fix therapist policy
-- ============================================================================

DROP POLICY IF EXISTS "Therapists can view patient hrv baselines" ON hrv_baselines;

CREATE POLICY "Therapists can view patient hrv baselines"
    ON hrv_baselines FOR SELECT
    TO authenticated
    USING (is_therapist());

-- ============================================================================
-- 6. automation_logs + automation_webhooks — fix therapist policies
-- ============================================================================

DROP POLICY IF EXISTS "Therapists can view automation_logs" ON automation_logs;
DROP POLICY IF EXISTS "Therapists can view automation_webhooks" ON automation_webhooks;

CREATE POLICY "Therapists can view automation_logs"
    ON automation_logs FOR SELECT
    TO authenticated
    USING (is_therapist());

CREATE POLICY "Therapists can view automation_webhooks"
    ON automation_webhooks FOR SELECT
    TO authenticated
    USING (is_therapist());

-- ============================================================================
-- 7. data_conflicts — fix therapist policy
-- ============================================================================

DROP POLICY IF EXISTS "Therapists can view patient conflicts" ON data_conflicts;

CREATE POLICY "Therapists can view patient conflicts"
    ON data_conflicts FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = data_conflicts.patient_id
            AND tp.therapist_id = auth.uid()
        )
        OR is_therapist()
    );

-- ============================================================================
-- 8. patients — replace auth.users email lookup with auth_email()
-- ============================================================================

DROP POLICY IF EXISTS "patients_auth_select" ON patients;
DROP POLICY IF EXISTS "patients_auth_update" ON patients;

CREATE POLICY "patients_auth_select"
    ON patients FOR SELECT
    TO authenticated
    USING (
        id = '00000000-0000-0000-0000-000000000001'::uuid
        OR user_id = auth.uid()
        OR email = auth_email()
        OR therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
    );

CREATE POLICY "patients_auth_update"
    ON patients FOR UPDATE
    TO authenticated
    USING (
        id = '00000000-0000-0000-0000-000000000001'::uuid
        OR user_id = auth.uid()
        OR email = auth_email()
        OR therapist_id IN (SELECT id FROM therapists WHERE user_id = auth.uid())
    );

-- ============================================================================
-- 9. audit_logs — fix admin policies + add missing columns
-- ============================================================================

-- Add missing columns expected by iOS AuditEntryInsert model
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS details TEXT;
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS device_id TEXT;

-- Fix admin policies that query auth.users
DROP POLICY IF EXISTS "Admins can view all audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Audit logs cannot be deleted" ON public.audit_logs;

CREATE POLICY "Admins can view all audit logs"
    ON public.audit_logs FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
    );

CREATE POLICY "Audit logs cannot be deleted"
    ON public.audit_logs FOR DELETE
    TO authenticated
    USING (
        (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
        AND timestamp < NOW() - INTERVAL '7 years'
    );

-- ============================================================================
-- 10. Create deferred_deep_links table (referenced by DeepLinkService)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.deferred_deep_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    url TEXT NOT NULL,
    fingerprint TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    claimed_at TIMESTAMPTZ,
    is_claimed BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_deferred_deep_links_fingerprint
    ON deferred_deep_links (fingerprint)
    WHERE NOT is_claimed;

CREATE INDEX IF NOT EXISTS idx_deferred_deep_links_created
    ON deferred_deep_links (created_at DESC);

ALTER TABLE deferred_deep_links ENABLE ROW LEVEL SECURITY;

-- Anyone can insert (links created from web before install)
CREATE POLICY "Anyone can create deferred deep links"
    ON deferred_deep_links FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Authenticated users can read unclaimed links matching their fingerprint
CREATE POLICY "Users can read matching deep links"
    ON deferred_deep_links FOR SELECT
    TO authenticated
    USING (true);

-- Authenticated users can claim links
CREATE POLICY "Users can claim deep links"
    ON deferred_deep_links FOR UPDATE
    TO authenticated
    USING (NOT is_claimed)
    WITH CHECK (is_claimed = true);

-- Service role full access
CREATE POLICY "Service role full access deferred deep links"
    ON deferred_deep_links FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE ON deferred_deep_links TO authenticated;
GRANT INSERT ON deferred_deep_links TO anon;
GRANT ALL ON deferred_deep_links TO service_role;

-- ============================================================================
-- 11. Force PostgREST schema cache reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

COMMIT;
