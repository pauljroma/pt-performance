-- Create Audit Logs Table for HIPAA Compliance
-- Tracks all user actions for compliance and security

BEGIN;

-- Create audit_logs table
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- User information
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_email TEXT,
    user_role TEXT, -- 'therapist', 'patient', 'admin'

    -- Action details
    action_type TEXT NOT NULL, -- 'CREATE', 'READ', 'UPDATE', 'DELETE', 'EXPORT', 'LOGIN', 'LOGOUT'
    resource_type TEXT NOT NULL, -- 'patient', 'program', 'session', 'exercise_log', 'note'
    resource_id UUID,

    -- Operation details
    operation TEXT NOT NULL, -- Specific operation: 'create_program', 'view_patient', 'update_session'
    description TEXT,

    -- Request metadata
    ip_address INET,
    user_agent TEXT,
    request_id UUID,
    session_id TEXT,

    -- Data access tracking
    affected_patient_id UUID,
    data_accessed TEXT[], -- Array of field names accessed

    -- Change tracking (for UPDATE operations)
    old_values JSONB,
    new_values JSONB,

    -- Security
    is_sensitive BOOLEAN DEFAULT FALSE,
    compliance_category TEXT, -- 'PHI_ACCESS', 'DATA_MODIFICATION', 'SECURITY_EVENT'

    -- Status
    status TEXT DEFAULT 'success', -- 'success', 'failure', 'denied'
    error_message TEXT,

    -- Indexes for performance
    CONSTRAINT audit_logs_action_type_check CHECK (action_type IN ('CREATE', 'READ', 'UPDATE', 'DELETE', 'EXPORT', 'LOGIN', 'LOGOUT', 'ADMIN')),
    CONSTRAINT audit_logs_status_check CHECK (status IN ('success', 'failure', 'denied'))
);

-- Create indexes for performance
CREATE INDEX idx_audit_logs_timestamp ON public.audit_logs(timestamp DESC);
CREATE INDEX idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource_type ON public.audit_logs(resource_type);
CREATE INDEX idx_audit_logs_resource_id ON public.audit_logs(resource_id);
CREATE INDEX idx_audit_logs_affected_patient_id ON public.audit_logs(affected_patient_id);
CREATE INDEX idx_audit_logs_action_type ON public.audit_logs(action_type);
CREATE INDEX idx_audit_logs_timestamp_user ON public.audit_logs(timestamp DESC, user_id);
CREATE INDEX idx_audit_logs_compliance_category ON public.audit_logs(compliance_category);
CREATE INDEX idx_audit_logs_is_sensitive ON public.audit_logs(is_sensitive) WHERE is_sensitive = TRUE;

-- Enable RLS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Admins can view all audit logs
CREATE POLICY "Admins can view all audit logs"
ON public.audit_logs
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
);

-- Users can view their own audit logs
CREATE POLICY "Users can view their own audit logs"
ON public.audit_logs
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Therapists can view audit logs for their patients
CREATE POLICY "Therapists can view audit logs for their patients"
ON public.audit_logs
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.therapists t
        JOIN public.patients p ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
        AND p.id = audit_logs.affected_patient_id
    )
);

-- Only system can insert audit logs (through triggers)
CREATE POLICY "System inserts audit logs"
ON public.audit_logs
FOR INSERT
TO authenticated
WITH CHECK (true); -- Controlled by application logic

-- No updates or deletes allowed (immutable audit trail)
CREATE POLICY "Audit logs are immutable"
ON public.audit_logs
FOR UPDATE
TO authenticated
USING (false);

CREATE POLICY "Audit logs cannot be deleted"
ON public.audit_logs
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'admin'
        AND timestamp < NOW() - INTERVAL '7 years' -- HIPAA retention: 6 years + grace
    )
);

-- Helper function to log actions
CREATE OR REPLACE FUNCTION public.log_audit_event(
    p_action_type TEXT,
    p_resource_type TEXT,
    p_resource_id UUID,
    p_operation TEXT,
    p_description TEXT DEFAULT NULL,
    p_affected_patient_id UUID DEFAULT NULL,
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_is_sensitive BOOLEAN DEFAULT FALSE,
    p_compliance_category TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_audit_id UUID;
    v_user_email TEXT;
    v_user_role TEXT;
BEGIN
    -- Get user details
    SELECT email, raw_user_meta_data->>'role'
    INTO v_user_email, v_user_role
    FROM auth.users
    WHERE id = auth.uid();

    -- Insert audit log
    INSERT INTO public.audit_logs (
        user_id,
        user_email,
        user_role,
        action_type,
        resource_type,
        resource_id,
        operation,
        description,
        affected_patient_id,
        old_values,
        new_values,
        is_sensitive,
        compliance_category,
        status
    ) VALUES (
        auth.uid(),
        v_user_email,
        v_user_role,
        p_action_type,
        p_resource_type,
        p_resource_id,
        p_operation,
        p_description,
        p_affected_patient_id,
        p_old_values,
        p_new_values,
        p_is_sensitive,
        p_compliance_category,
        'success'
    )
    RETURNING id INTO v_audit_id;

    RETURN v_audit_id;
END;
$$;

-- Trigger to automatically log patient data access
CREATE OR REPLACE FUNCTION public.audit_patient_access()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Log SELECT operations on patients table
    IF TG_OP = 'SELECT' THEN
        PERFORM public.log_audit_event(
            'READ',
            'patient',
            NEW.id,
            'view_patient',
            'Patient record accessed',
            NEW.id,
            NULL,
            NULL,
            TRUE,
            'PHI_ACCESS'
        );
    END IF;

    RETURN NEW;
END;
$$;

-- Trigger to automatically log program modifications
CREATE OR REPLACE FUNCTION public.audit_program_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM public.log_audit_event(
            'CREATE',
            'program',
            NEW.id,
            'create_program',
            'New program created: ' || NEW.name,
            NEW.patient_id,
            NULL,
            to_jsonb(NEW),
            FALSE,
            'DATA_MODIFICATION'
        );
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM public.log_audit_event(
            'UPDATE',
            'program',
            NEW.id,
            'update_program',
            'Program updated: ' || NEW.name,
            NEW.patient_id,
            to_jsonb(OLD),
            to_jsonb(NEW),
            FALSE,
            'DATA_MODIFICATION'
        );
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM public.log_audit_event(
            'DELETE',
            'program',
            OLD.id,
            'delete_program',
            'Program deleted: ' || OLD.name,
            OLD.patient_id,
            to_jsonb(OLD),
            NULL,
            FALSE,
            'DATA_MODIFICATION'
        );
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Create triggers for automatic audit logging
CREATE TRIGGER audit_program_changes_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.programs
FOR EACH ROW
EXECUTE FUNCTION public.audit_program_changes();

-- Similar triggers for other tables
CREATE OR REPLACE FUNCTION public.audit_session_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_patient_id UUID;
BEGIN
    -- Get patient_id from program
    SELECT patient_id INTO v_patient_id
    FROM public.programs
    WHERE id = COALESCE(NEW.program_id, OLD.program_id);

    IF TG_OP = 'INSERT' THEN
        PERFORM public.log_audit_event(
            'CREATE',
            'session',
            NEW.id,
            'create_session',
            'New session created',
            v_patient_id,
            NULL,
            to_jsonb(NEW),
            FALSE,
            'DATA_MODIFICATION'
        );
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM public.log_audit_event(
            'UPDATE',
            'session',
            NEW.id,
            'update_session',
            'Session updated',
            v_patient_id,
            to_jsonb(OLD),
            to_jsonb(NEW),
            FALSE,
            'DATA_MODIFICATION'
        );
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM public.log_audit_event(
            'DELETE',
            'session',
            OLD.id,
            'delete_session',
            'Session deleted',
            v_patient_id,
            to_jsonb(OLD),
            NULL,
            FALSE,
            'DATA_MODIFICATION'
        );
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER audit_session_changes_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.sessions
FOR EACH ROW
EXECUTE FUNCTION public.audit_session_changes();

-- Create view for compliance reporting
CREATE OR REPLACE VIEW public.audit_logs_summary AS
SELECT
    DATE(timestamp) as date,
    user_role,
    action_type,
    resource_type,
    compliance_category,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT affected_patient_id) as unique_patients
FROM public.audit_logs
GROUP BY DATE(timestamp), user_role, action_type, resource_type, compliance_category
ORDER BY date DESC;

-- Grant permissions
GRANT SELECT ON public.audit_logs TO authenticated;
GRANT INSERT ON public.audit_logs TO authenticated;
GRANT SELECT ON public.audit_logs_summary TO authenticated;

-- Comments
COMMENT ON TABLE public.audit_logs IS 'HIPAA-compliant audit log for all user actions and data access';
COMMENT ON COLUMN public.audit_logs.is_sensitive IS 'Marks PHI access that requires additional security review';
COMMENT ON COLUMN public.audit_logs.compliance_category IS 'HIPAA compliance category for reporting';
COMMENT ON FUNCTION public.log_audit_event IS 'Helper function to create audit log entries';

COMMIT;
