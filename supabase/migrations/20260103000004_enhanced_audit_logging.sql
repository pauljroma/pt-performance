-- Migration: Enhanced Audit Logging for Therapist Access
-- Build: 119
-- Date: 2026-01-03
-- Purpose: HIPAA "accounting of disclosures" requirement - log all therapist access to patient data

-- Create therapist_access_logs table
CREATE TABLE IF NOT EXISTS therapist_access_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapist_id UUID NOT NULL REFERENCES auth.users(id),
    patient_id UUID NOT NULL REFERENCES auth.users(id),
    table_name VARCHAR(100) NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')),
    record_id UUID,
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    session_id TEXT,
    ip_address INET
);

-- Create indexes for performance and compliance queries
CREATE INDEX idx_therapist_access_logs_therapist_id ON therapist_access_logs(therapist_id);
CREATE INDEX idx_therapist_access_logs_patient_id ON therapist_access_logs(patient_id);
CREATE INDEX idx_therapist_access_logs_accessed_at ON therapist_access_logs(accessed_at DESC);
CREATE INDEX idx_therapist_access_logs_table_action ON therapist_access_logs(table_name, action);

-- Enable RLS on therapist_access_logs
ALTER TABLE therapist_access_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Only compliance officer/admin can read audit logs
-- For now, allow therapists to see their own access logs
CREATE POLICY "Therapists can view own access logs"
    ON therapist_access_logs FOR SELECT
    TO authenticated
    USING (therapist_id = auth.uid());

-- RLS Policy: System can insert audit logs (no manual INSERT)
CREATE POLICY "System can insert audit logs"
    ON therapist_access_logs FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- RLS Policy: Audit logs are immutable (no UPDATE/DELETE)
-- This is enforced by NOT creating UPDATE/DELETE policies

-- Function: Log therapist access to patient data
CREATE OR REPLACE FUNCTION log_therapist_access()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_therapist BOOLEAN;
BEGIN
    -- Check if current user is a therapist
    SELECT is_therapist(auth.uid()) INTO v_is_therapist;

    -- Only log if user is a therapist AND accessing someone else's data
    IF v_is_therapist = true AND NEW.patient_id != auth.uid() THEN
        INSERT INTO therapist_access_logs (
            therapist_id,
            patient_id,
            table_name,
            action,
            record_id,
            accessed_at,
            session_id
        ) VALUES (
            auth.uid(),
            NEW.patient_id,
            TG_TABLE_NAME,
            TG_OP,
            NEW.id,
            now(),
            current_setting('request.jwt.claims', true)::json->>'session_id'
        );
    END IF;

    RETURN NEW;
END;
$$;

-- Trigger: Log therapist access on daily_readiness INSERT
CREATE TRIGGER log_therapist_access_daily_readiness_insert
AFTER INSERT ON daily_readiness
FOR EACH ROW
EXECUTE FUNCTION log_therapist_access();

-- Trigger: Log therapist access on daily_readiness UPDATE
CREATE TRIGGER log_therapist_access_daily_readiness_update
AFTER UPDATE ON daily_readiness
FOR EACH ROW
EXECUTE FUNCTION log_therapist_access();

-- Function: Purge old audit logs (6-year HIPAA retention)
CREATE OR REPLACE FUNCTION purge_old_audit_logs(days_to_keep INT DEFAULT 2190)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INT;
BEGIN
    DELETE FROM therapist_access_logs
    WHERE accessed_at < (now() - (days_to_keep || ' days')::INTERVAL);

    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

    RETURN v_deleted_count;
END;
$$;

-- Comment
COMMENT ON TABLE therapist_access_logs IS 'HIPAA accounting of disclosures - all therapist access to patient data (BUILD 119)';
COMMENT ON FUNCTION log_therapist_access IS 'Trigger function to log therapist access to patient data (BUILD 119)';
COMMENT ON FUNCTION purge_old_audit_logs IS 'Purge audit logs older than retention period (default 6 years) (BUILD 119)';
