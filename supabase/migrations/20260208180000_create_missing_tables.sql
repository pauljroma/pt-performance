-- ============================================================================
-- Migration: Create Missing Critical Tables
-- Created: 2026-02-08
-- Description: Creates high priority tables that are actively referenced by
--              services but missing from the database schema.
-- ============================================================================

-- ============================================================================
-- 1. SOAP Note Templates
-- Referenced by: SOAPNoteService
-- Purpose: Stores templates for SOAP notes used in clinical documentation
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.soap_note_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT,
    template_content JSONB,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE public.soap_note_templates IS 'Templates for SOAP (Subjective, Objective, Assessment, Plan) clinical notes';
COMMENT ON COLUMN public.soap_note_templates.template_content IS 'JSONB containing template structure with sections for S, O, A, P';
COMMENT ON COLUMN public.soap_note_templates.category IS 'Template category (e.g., initial_eval, follow_up, discharge)';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_soap_note_templates_category ON public.soap_note_templates(category);
CREATE INDEX IF NOT EXISTS idx_soap_note_templates_is_active ON public.soap_note_templates(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_soap_note_templates_created_by ON public.soap_note_templates(created_by);

-- RLS
ALTER TABLE public.soap_note_templates ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view active templates
CREATE POLICY "soap_note_templates_select_active"
    ON public.soap_note_templates
    FOR SELECT
    TO authenticated
    USING (is_active = true);

-- Template creators can manage their own templates
CREATE POLICY "soap_note_templates_creator_all"
    ON public.soap_note_templates
    FOR ALL
    TO authenticated
    USING (created_by = auth.uid())
    WITH CHECK (created_by = auth.uid());

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_soap_note_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_soap_note_templates_updated_at ON public.soap_note_templates;
CREATE TRIGGER trg_soap_note_templates_updated_at
    BEFORE UPDATE ON public.soap_note_templates
    FOR EACH ROW
    EXECUTE FUNCTION public.update_soap_note_templates_updated_at();


-- ============================================================================
-- 2. Patient Achievements
-- Referenced by: AchievementService
-- Purpose: Tracks patient achievements and milestones for gamification
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.patient_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    achievement_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB
);

-- Add comment for documentation
COMMENT ON TABLE public.patient_achievements IS 'Tracks patient achievements and milestones for gamification and motivation';
COMMENT ON COLUMN public.patient_achievements.achievement_type IS 'Type of achievement (e.g., streak, pr, milestone, consistency)';
COMMENT ON COLUMN public.patient_achievements.metadata IS 'Additional data about the achievement (e.g., streak_count, pr_value)';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_patient_achievements_patient_id ON public.patient_achievements(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_achievements_type ON public.patient_achievements(achievement_type);
CREATE INDEX IF NOT EXISTS idx_patient_achievements_earned_at ON public.patient_achievements(earned_at DESC);
CREATE INDEX IF NOT EXISTS idx_patient_achievements_patient_type ON public.patient_achievements(patient_id, achievement_type);

-- RLS
ALTER TABLE public.patient_achievements ENABLE ROW LEVEL SECURITY;

-- Patients can view their own achievements
CREATE POLICY "patient_achievements_patient_select"
    ON public.patient_achievements
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

-- System can insert achievements (via service role or therapist)
CREATE POLICY "patient_achievements_insert"
    ON public.patient_achievements
    FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
        OR
        -- Therapists can award achievements to their patients
        patient_id IN (
            SELECT tp.patient_id
            FROM public.therapist_patients tp
            JOIN public.therapists t ON t.id = tp.therapist_id
            WHERE t.user_id = auth.uid()
        )
    );


-- ============================================================================
-- 3. Data Consents
-- Referenced by: ConsentService
-- Purpose: Tracks patient consent for data usage and privacy compliance
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.data_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    consent_type TEXT NOT NULL,
    granted BOOLEAN NOT NULL,
    granted_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    version TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure logical consistency
    CONSTRAINT chk_consent_dates CHECK (
        (granted = true AND granted_at IS NOT NULL) OR
        (granted = false)
    )
);

-- Add comment for documentation
COMMENT ON TABLE public.data_consents IS 'Tracks patient consent for data usage, privacy compliance (GDPR, HIPAA)';
COMMENT ON COLUMN public.data_consents.consent_type IS 'Type of consent (e.g., data_processing, marketing, research, third_party_sharing)';
COMMENT ON COLUMN public.data_consents.version IS 'Version of the consent terms the patient agreed to';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_data_consents_patient_id ON public.data_consents(patient_id);
CREATE INDEX IF NOT EXISTS idx_data_consents_type ON public.data_consents(consent_type);
CREATE INDEX IF NOT EXISTS idx_data_consents_patient_type ON public.data_consents(patient_id, consent_type);
CREATE INDEX IF NOT EXISTS idx_data_consents_granted ON public.data_consents(granted) WHERE granted = true;

-- RLS
ALTER TABLE public.data_consents ENABLE ROW LEVEL SECURITY;

-- Patients can view their own consent records
CREATE POLICY "data_consents_patient_select"
    ON public.data_consents
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

-- Patients can manage their own consents
CREATE POLICY "data_consents_patient_insert"
    ON public.data_consents
    FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "data_consents_patient_update"
    ON public.data_consents
    FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );


-- ============================================================================
-- 4. Consent Audit Log
-- Referenced by: ConsentService
-- Purpose: Immutable audit trail for all consent changes (compliance requirement)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.consent_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    consent_type TEXT,
    old_value JSONB,
    new_value JSONB,
    performed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    performed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE public.consent_audit_log IS 'Immutable audit trail for consent changes - required for GDPR/HIPAA compliance';
COMMENT ON COLUMN public.consent_audit_log.action IS 'Action performed (grant, revoke, update, view)';
COMMENT ON COLUMN public.consent_audit_log.old_value IS 'Previous consent state before change';
COMMENT ON COLUMN public.consent_audit_log.new_value IS 'New consent state after change';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_consent_audit_log_patient_id ON public.consent_audit_log(patient_id);
CREATE INDEX IF NOT EXISTS idx_consent_audit_log_performed_at ON public.consent_audit_log(performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_consent_audit_log_action ON public.consent_audit_log(action);
CREATE INDEX IF NOT EXISTS idx_consent_audit_log_consent_type ON public.consent_audit_log(consent_type);

-- RLS
ALTER TABLE public.consent_audit_log ENABLE ROW LEVEL SECURITY;

-- Patients can view their own audit logs
CREATE POLICY "consent_audit_log_patient_select"
    ON public.consent_audit_log
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

-- Only system can insert audit logs (append-only, no updates/deletes)
CREATE POLICY "consent_audit_log_insert"
    ON public.consent_audit_log
    FOR INSERT
    TO authenticated
    WITH CHECK (performed_by = auth.uid());


-- ============================================================================
-- 5. Failed Login Attempts
-- Referenced by: SecurityMonitor
-- Purpose: Tracks failed login attempts for security monitoring and lockout
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.failed_login_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ip_address TEXT,
    user_agent TEXT,
    attempted_at TIMESTAMPTZ DEFAULT NOW(),
    reason TEXT
);

-- Add comment for documentation
COMMENT ON TABLE public.failed_login_attempts IS 'Tracks failed login attempts for security monitoring, rate limiting, and account lockout';
COMMENT ON COLUMN public.failed_login_attempts.reason IS 'Reason for failure (invalid_password, account_locked, mfa_failed, etc.)';
COMMENT ON COLUMN public.failed_login_attempts.ip_address IS 'IP address of the login attempt (for geo-blocking and analysis)';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_failed_login_attempts_user_id ON public.failed_login_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_failed_login_attempts_attempted_at ON public.failed_login_attempts(attempted_at DESC);
CREATE INDEX IF NOT EXISTS idx_failed_login_attempts_ip_address ON public.failed_login_attempts(ip_address);
-- Composite index for checking recent attempts per user
CREATE INDEX IF NOT EXISTS idx_failed_login_attempts_user_recent ON public.failed_login_attempts(user_id, attempted_at DESC);

-- RLS
ALTER TABLE public.failed_login_attempts ENABLE ROW LEVEL SECURITY;

-- Users can view their own failed login attempts
CREATE POLICY "failed_login_attempts_user_select"
    ON public.failed_login_attempts
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Only service role should insert (handled at application level)
-- No insert policy for regular authenticated users


-- ============================================================================
-- 6. Evidence Citations
-- Referenced by: CitationService
-- Purpose: Stores evidence-based citations for exercise recommendations
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.evidence_citations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID,
    source_type TEXT NOT NULL,
    source_url TEXT,
    title TEXT NOT NULL,
    authors TEXT[],
    publication_date DATE,
    doi TEXT,
    citation_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE public.evidence_citations IS 'Evidence-based citations supporting exercise and treatment recommendations';
COMMENT ON COLUMN public.evidence_citations.claim_id IS 'Reference to the claim/recommendation this citation supports';
COMMENT ON COLUMN public.evidence_citations.source_type IS 'Type of source (journal_article, textbook, guideline, meta_analysis)';
COMMENT ON COLUMN public.evidence_citations.doi IS 'Digital Object Identifier for academic papers';
COMMENT ON COLUMN public.evidence_citations.authors IS 'Array of author names';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_evidence_citations_claim_id ON public.evidence_citations(claim_id);
CREATE INDEX IF NOT EXISTS idx_evidence_citations_source_type ON public.evidence_citations(source_type);
CREATE INDEX IF NOT EXISTS idx_evidence_citations_doi ON public.evidence_citations(doi) WHERE doi IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_evidence_citations_publication_date ON public.evidence_citations(publication_date DESC);

-- GIN index for searching authors array
CREATE INDEX IF NOT EXISTS idx_evidence_citations_authors ON public.evidence_citations USING GIN(authors);

-- RLS
ALTER TABLE public.evidence_citations ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view citations (public knowledge base)
CREATE POLICY "evidence_citations_select"
    ON public.evidence_citations
    FOR SELECT
    TO authenticated
    USING (true);

-- Only therapists/admins can add citations
CREATE POLICY "evidence_citations_therapist_insert"
    ON public.evidence_citations
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );


-- ============================================================================
-- VERIFICATION BLOCK
-- ============================================================================

DO $$
DECLARE
    v_table_count INTEGER := 0;
    v_missing_tables TEXT[] := ARRAY[]::TEXT[];
    v_expected_tables TEXT[] := ARRAY[
        'soap_note_templates',
        'patient_achievements',
        'data_consents',
        'consent_audit_log',
        'failed_login_attempts',
        'evidence_citations'
    ];
    v_table_name TEXT;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Verifying table creation...';
    RAISE NOTICE '============================================';

    FOREACH v_table_name IN ARRAY v_expected_tables
    LOOP
        IF EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name = v_table_name
        ) THEN
            v_table_count := v_table_count + 1;
            RAISE NOTICE 'OK: Table % exists', v_table_name;
        ELSE
            v_missing_tables := array_append(v_missing_tables, v_table_name);
            RAISE WARNING 'MISSING: Table % was not created', v_table_name;
        END IF;
    END LOOP;

    RAISE NOTICE '--------------------------------------------';
    RAISE NOTICE 'Tables created: %/%', v_table_count, array_length(v_expected_tables, 1);

    IF array_length(v_missing_tables, 1) > 0 THEN
        RAISE EXCEPTION 'Migration failed - missing tables: %', v_missing_tables;
    END IF;

    -- Verify RLS is enabled
    RAISE NOTICE '--------------------------------------------';
    RAISE NOTICE 'Verifying RLS policies...';

    FOR v_table_name IN
        SELECT tablename FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename = ANY(v_expected_tables)
    LOOP
        IF EXISTS (
            SELECT 1 FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public'
            AND c.relname = v_table_name
            AND c.relrowsecurity = true
        ) THEN
            RAISE NOTICE 'OK: RLS enabled on %', v_table_name;
        ELSE
            RAISE WARNING 'WARNING: RLS not enabled on %', v_table_name;
        END IF;
    END LOOP;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'Migration completed successfully!';
    RAISE NOTICE '============================================';
END $$;
