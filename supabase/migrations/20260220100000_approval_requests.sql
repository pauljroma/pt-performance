-- Therapist Approval Gates
-- Human-in-the-loop pattern for AI-generated workout modifications
--
-- AI features that recommend workout modifications (intensity increases,
-- exercise substitutions, program changes, return-to-activity decisions)
-- now require explicit therapist approval before being applied.
-- Low-severity changes can be auto-approved based on configuration.

BEGIN;

-- ============================================================================
-- 1. Approval requests table
-- ============================================================================

CREATE TABLE IF NOT EXISTS approval_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    therapist_id UUID REFERENCES therapists(id), -- therapist who should approve
    request_type TEXT NOT NULL CHECK (request_type IN (
        'workout_modification', 'intensity_increase', 'exercise_substitution',
        'program_change', 'return_to_activity'
    )),
    severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired', 'auto_approved')),

    -- What's being requested
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    suggested_change JSONB NOT NULL, -- The AI-generated modification details
    ai_rationale TEXT, -- Why the AI suggested this
    ai_confidence DECIMAL(3,2) CHECK (ai_confidence BETWEEN 0 AND 1),

    -- Therapist response
    therapist_notes TEXT,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES auth.users(id),

    -- Auto-approval rules
    auto_approve_if_low_severity BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '72 hours'),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 2. Indexes
-- ============================================================================

CREATE INDEX idx_approval_requests_patient ON approval_requests(patient_id);
CREATE INDEX idx_approval_requests_therapist ON approval_requests(therapist_id);
CREATE INDEX idx_approval_requests_status ON approval_requests(status) WHERE status = 'pending';
CREATE INDEX idx_approval_requests_severity ON approval_requests(severity);
CREATE INDEX idx_approval_requests_created_at ON approval_requests(created_at DESC);

-- ============================================================================
-- 3. RLS policies
-- ============================================================================

ALTER TABLE approval_requests ENABLE ROW LEVEL SECURITY;

-- Patients can see their own approval requests
CREATE POLICY "patients_view_own_approvals" ON approval_requests
    FOR SELECT USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
        -- Demo patient bypass
        OR patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- Therapists can view and manage approvals for their patients
CREATE POLICY "therapists_manage_approvals" ON approval_requests
    FOR ALL USING (
        therapist_id IN (
            SELECT id FROM therapists WHERE user_id = auth.uid()
        )
        OR is_therapist()
    );

-- Service role can do everything (for edge functions)
CREATE POLICY "service_role_full_access" ON approval_requests
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- 4. Auto-approve low severity requests trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION auto_approve_low_severity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.severity = 'low' AND NEW.auto_approve_if_low_severity = true THEN
        NEW.status := 'auto_approved';
        NEW.reviewed_at := NOW();
        NEW.therapist_notes := 'Auto-approved: low severity change within safe parameters';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_approve_low_severity
    BEFORE INSERT ON approval_requests
    FOR EACH ROW
    EXECUTE FUNCTION auto_approve_low_severity();

-- ============================================================================
-- 5. Expire old pending requests
-- ============================================================================

CREATE OR REPLACE FUNCTION expire_old_approval_requests()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE approval_requests
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending' AND expires_at < NOW();
END;
$$;

-- ============================================================================
-- 6. Updated_at trigger (reuses existing update_updated_at_column function)
-- ============================================================================

CREATE TRIGGER set_approval_requests_updated_at
    BEFORE UPDATE ON approval_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. Force schema cache reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

COMMIT;
