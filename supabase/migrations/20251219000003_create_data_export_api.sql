-- Data Export API for HIPAA Patient Data Portability
-- Allows patients to export all their data

BEGIN;

-- Create data export requests table
CREATE TABLE IF NOT EXISTS public.data_export_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    requested_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Export parameters
    export_format TEXT NOT NULL DEFAULT 'json', -- 'json', 'csv', 'pdf'
    include_sessions BOOLEAN DEFAULT TRUE,
    include_exercises BOOLEAN DEFAULT TRUE,
    include_notes BOOLEAN DEFAULT TRUE,
    include_readiness BOOLEAN DEFAULT TRUE,
    include_analytics BOOLEAN DEFAULT TRUE,
    date_range_start DATE,
    date_range_end DATE,

    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    completed_at TIMESTAMPTZ,
    error_message TEXT,

    -- Export result
    export_url TEXT, -- Signed URL to download export
    export_size_bytes BIGINT,
    expires_at TIMESTAMPTZ,

    -- Audit
    ip_address INET,
    user_agent TEXT,

    CONSTRAINT data_export_requests_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    CONSTRAINT data_export_requests_format_check CHECK (export_format IN ('json', 'csv', 'pdf'))
);

-- Create indexes
CREATE INDEX idx_data_export_requests_patient_id ON public.data_export_requests(patient_id);
CREATE INDEX idx_data_export_requests_requested_by ON public.data_export_requests(requested_by);
CREATE INDEX idx_data_export_requests_status ON public.data_export_requests(status);
CREATE INDEX idx_data_export_requests_requested_at ON public.data_export_requests(requested_at DESC);

-- Enable RLS
ALTER TABLE public.data_export_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Patients can request export of their own data
CREATE POLICY "Patients can request their own data export"
ON public.data_export_requests
FOR INSERT
TO authenticated
WITH CHECK (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- Patients can view their own export requests
CREATE POLICY "Patients can view their own export requests"
ON public.data_export_requests
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- Therapists can view export requests for their patients
CREATE POLICY "Therapists can view export requests for their patients"
ON public.data_export_requests
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT p.id FROM public.patients p
        JOIN public.therapists t ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
    )
);

-- Function to export patient data as JSON
CREATE OR REPLACE FUNCTION public.export_patient_data(
    p_patient_id UUID,
    p_include_sessions BOOLEAN DEFAULT TRUE,
    p_include_exercises BOOLEAN DEFAULT TRUE,
    p_include_notes BOOLEAN DEFAULT TRUE,
    p_include_readiness BOOLEAN DEFAULT TRUE,
    p_include_analytics BOOLEAN DEFAULT TRUE,
    p_date_range_start DATE DEFAULT NULL,
    p_date_range_end DATE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_export_data JSONB;
    v_patient_data JSONB;
    v_programs_data JSONB;
    v_sessions_data JSONB;
    v_exercises_data JSONB;
    v_notes_data JSONB;
    v_readiness_data JSONB;
BEGIN
    -- Verify access
    IF NOT (
        -- Patient accessing their own data
        EXISTS (SELECT 1 FROM public.patients WHERE id = p_patient_id AND user_id = auth.uid())
        OR
        -- Therapist accessing their patient's data
        EXISTS (
            SELECT 1 FROM public.patients p
            JOIN public.therapists t ON p.therapist_id = t.id
            WHERE p.id = p_patient_id AND t.user_id = auth.uid()
        )
    ) THEN
        RAISE EXCEPTION 'Insufficient permissions to export this patient data';
    END IF;

    -- Get patient info
    SELECT jsonb_build_object(
        'id', id,
        'first_name', first_name,
        'last_name', last_name,
        'email', email,
        'date_of_birth', date_of_birth,
        'phone', phone,
        'created_at', created_at
    )
    INTO v_patient_data
    FROM public.patients
    WHERE id = p_patient_id;

    -- Get programs
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'name', name,
            'description', description,
            'start_date', start_date,
            'end_date', end_date,
            'status', status,
            'created_at', created_at
        )
    )
    INTO v_programs_data
    FROM public.programs
    WHERE patient_id = p_patient_id
    AND (p_date_range_start IS NULL OR start_date >= p_date_range_start)
    AND (p_date_range_end IS NULL OR start_date <= p_date_range_end);

    -- Get sessions (if requested)
    IF p_include_sessions THEN
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', s.id,
                'program_id', s.program_id,
                'session_number', s.session_number,
                'scheduled_date', s.scheduled_date,
                'status', s.status,
                'created_at', s.created_at
            )
        )
        INTO v_sessions_data
        FROM public.sessions s
        JOIN public.programs p ON s.program_id = p.id
        WHERE p.patient_id = p_patient_id
        AND (p_date_range_start IS NULL OR s.scheduled_date >= p_date_range_start)
        AND (p_date_range_end IS NULL OR s.scheduled_date <= p_date_range_end);
    END IF;

    -- Get exercise logs (if requested)
    IF p_include_exercises THEN
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', el.id,
                'session_id', el.session_id,
                'exercise_id', el.exercise_id,
                'exercise_name', e.name,
                'sets', el.sets,
                'reps', el.reps,
                'weight', el.weight,
                'rpe', el.rpe,
                'notes', el.notes,
                'created_at', el.created_at
            )
        )
        INTO v_exercises_data
        FROM public.exercise_logs el
        JOIN public.sessions s ON el.session_id = s.id
        JOIN public.programs p ON s.program_id = p.id
        JOIN public.exercises e ON el.exercise_id = e.id
        WHERE p.patient_id = p_patient_id
        AND (p_date_range_start IS NULL OR el.created_at::date >= p_date_range_start)
        AND (p_date_range_end IS NULL OR el.created_at::date <= p_date_range_end);
    END IF;

    -- Get notes (if requested)
    IF p_include_notes THEN
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', n.id,
                'session_id', n.session_id,
                'note_text', n.note_text,
                'created_at', n.created_at
            )
        )
        INTO v_notes_data
        FROM public.session_notes n
        JOIN public.sessions s ON n.session_id = s.id
        JOIN public.programs p ON s.program_id = p.id
        WHERE p.patient_id = p_patient_id
        AND (p_date_range_start IS NULL OR n.created_at::date >= p_date_range_start)
        AND (p_date_range_end IS NULL OR n.created_at::date <= p_date_range_end);
    END IF;

    -- Get readiness data (if requested)
    IF p_include_readiness THEN
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', id,
                'date', date,
                'sleep_quality', sleep_quality,
                'muscle_soreness', muscle_soreness,
                'stress_level', stress_level,
                'energy_level', energy_level,
                'readiness_score', readiness_score,
                'created_at', created_at
            )
        )
        INTO v_readiness_data
        FROM public.daily_readiness
        WHERE patient_id = p_patient_id
        AND (p_date_range_start IS NULL OR date >= p_date_range_start)
        AND (p_date_range_end IS NULL OR date <= p_date_range_end);
    END IF;

    -- Build complete export
    v_export_data := jsonb_build_object(
        'export_metadata', jsonb_build_object(
            'exported_at', NOW(),
            'exported_by', auth.uid(),
            'date_range_start', p_date_range_start,
            'date_range_end', p_date_range_end
        ),
        'patient', v_patient_data,
        'programs', COALESCE(v_programs_data, '[]'::jsonb),
        'sessions', COALESCE(v_sessions_data, '[]'::jsonb),
        'exercise_logs', COALESCE(v_exercises_data, '[]'::jsonb),
        'notes', COALESCE(v_notes_data, '[]'::jsonb),
        'daily_readiness', COALESCE(v_readiness_data, '[]'::jsonb)
    );

    -- Log the export for audit purposes
    PERFORM public.log_audit_event(
        'EXPORT',
        'patient_data',
        p_patient_id,
        'export_patient_data',
        'Patient data exported',
        p_patient_id,
        NULL,
        NULL,
        TRUE,
        'PHI_ACCESS'
    );

    RETURN v_export_data;
END;
$$;

-- Function to request data export (creates async job)
CREATE OR REPLACE FUNCTION public.request_data_export(
    p_patient_id UUID,
    p_export_format TEXT DEFAULT 'json',
    p_include_sessions BOOLEAN DEFAULT TRUE,
    p_include_exercises BOOLEAN DEFAULT TRUE,
    p_include_notes BOOLEAN DEFAULT TRUE,
    p_include_readiness BOOLEAN DEFAULT TRUE,
    p_include_analytics BOOLEAN DEFAULT TRUE,
    p_date_range_start DATE DEFAULT NULL,
    p_date_range_end DATE DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request_id UUID;
BEGIN
    -- Verify access
    IF NOT (
        EXISTS (SELECT 1 FROM public.patients WHERE id = p_patient_id AND user_id = auth.uid())
    ) THEN
        RAISE EXCEPTION 'Insufficient permissions to export this patient data';
    END IF;

    -- Create export request
    INSERT INTO public.data_export_requests (
        patient_id,
        requested_by,
        export_format,
        include_sessions,
        include_exercises,
        include_notes,
        include_readiness,
        include_analytics,
        date_range_start,
        date_range_end
    ) VALUES (
        p_patient_id,
        auth.uid(),
        p_export_format,
        p_include_sessions,
        p_include_exercises,
        p_include_notes,
        p_include_readiness,
        p_include_analytics,
        p_date_range_start,
        p_date_range_end
    )
    RETURNING id INTO v_request_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        'EXPORT',
        'patient_data',
        p_patient_id,
        'request_data_export',
        'Data export requested',
        p_patient_id,
        NULL,
        NULL,
        TRUE,
        'PHI_ACCESS'
    );

    RETURN v_request_id;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.export_patient_data TO authenticated;
GRANT EXECUTE ON FUNCTION public.request_data_export TO authenticated;
GRANT SELECT, INSERT ON public.data_export_requests TO authenticated;

-- Comments
COMMENT ON TABLE public.data_export_requests IS 'HIPAA-compliant patient data export requests';
COMMENT ON FUNCTION public.export_patient_data IS 'Exports complete patient data in JSON format';
COMMENT ON FUNCTION public.request_data_export IS 'Creates async data export request';

COMMIT;
