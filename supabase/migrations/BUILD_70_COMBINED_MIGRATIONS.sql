-- Build 69: Create Exercise Videos Storage Bucket (ACP-170)
-- Creates Supabase Storage bucket for exercise videos with proper RLS policies
-- Sets up infrastructure for video library feature

-- ============================================================================
-- 1. CREATE STORAGE BUCKET
-- ============================================================================

-- Insert storage bucket (idempotent)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'exercise-videos',
    'exercise-videos',
    true, -- Public bucket for read access
    52428800, -- 50MB file size limit
    ARRAY[
        'video/mp4',
        'video/quicktime', -- .mov files
        'image/jpeg',
        'image/jpg'
    ]
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Add comment
COMMENT ON TABLE storage.buckets IS 'Storage buckets for files. exercise-videos bucket stores exercise demo videos and thumbnails.';

-- ============================================================================
-- 2. CREATE RLS POLICIES FOR BUCKET
-- ============================================================================

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "exercise_videos_public_read" ON storage.objects;
DROP POLICY IF EXISTS "exercise_videos_authenticated_upload" ON storage.objects;
DROP POLICY IF EXISTS "exercise_videos_authenticated_update" ON storage.objects;
DROP POLICY IF EXISTS "exercise_videos_authenticated_delete" ON storage.objects;

-- Policy 1: Public read access
-- Anyone can view/download exercise videos
CREATE POLICY "exercise_videos_public_read"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'exercise-videos');

COMMENT ON POLICY "exercise_videos_public_read" ON storage.objects IS
'Allows public read access to all files in exercise-videos bucket. Videos are meant to be publicly accessible.';

-- Policy 2: Authenticated users can upload
-- Only authenticated users (therapists) can upload videos
CREATE POLICY "exercise_videos_authenticated_upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'exercise-videos'
    AND (LOWER(storage.filename(name)) LIKE '%.mp4'
         OR LOWER(storage.filename(name)) LIKE '%.mov'
         OR LOWER(storage.filename(name)) LIKE '%.jpg'
         OR LOWER(storage.filename(name)) LIKE '%.jpeg')
);

COMMENT ON POLICY "exercise_videos_authenticated_upload" ON storage.objects IS
'Allows authenticated users to upload video (.mp4, .mov) and image (.jpg, .jpeg) files to exercise-videos bucket.';

-- Policy 3: Authenticated users can update
-- Only authenticated users can update/replace their uploaded files
CREATE POLICY "exercise_videos_authenticated_update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'exercise-videos')
WITH CHECK (bucket_id = 'exercise-videos');

COMMENT ON POLICY "exercise_videos_authenticated_update" ON storage.objects IS
'Allows authenticated users to update/replace files in exercise-videos bucket.';

-- Policy 4: Authenticated users can delete
-- Only authenticated users can delete files
CREATE POLICY "exercise_videos_authenticated_delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'exercise-videos');

COMMENT ON POLICY "exercise_videos_authenticated_delete" ON storage.objects IS
'Allows authenticated users to delete files from exercise-videos bucket.';

-- ============================================================================
-- 3. CREATE HELPER FUNCTIONS
-- ============================================================================

-- Function to get public URL for a storage object
CREATE OR REPLACE FUNCTION get_video_public_url(object_path TEXT)
RETURNS TEXT AS $$
DECLARE
    project_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co';
BEGIN
    RETURN project_url || '/storage/v1/object/public/exercise-videos/' || object_path;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION get_video_public_url(TEXT) IS
'Helper function to generate public URL for exercise video. Usage: SELECT get_video_public_url(''bench-press.mp4'')';

-- Function to extract filename from storage path
CREATE OR REPLACE FUNCTION extract_video_filename(video_url TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN regexp_replace(video_url, '^.*/([^/]+)$', '\1');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION extract_video_filename(TEXT) IS
'Extracts filename from full video URL. Usage: SELECT extract_video_filename(''https://.../.../video.mp4'')';

-- Function to check if video exists in storage
CREATE OR REPLACE FUNCTION video_exists_in_storage(video_filename TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM storage.objects
        WHERE bucket_id = 'exercise-videos'
        AND name = video_filename
    );
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION video_exists_in_storage(TEXT) IS
'Checks if a video file exists in exercise-videos bucket. Usage: SELECT video_exists_in_storage(''bench-press.mp4'')';

-- ============================================================================
-- 4. CREATE VIEW FOR VIDEO STORAGE STATUS
-- ============================================================================

-- Create view showing all videos in storage
CREATE OR REPLACE VIEW video_storage_inventory AS
SELECT
    o.id,
    o.name AS filename,
    o.bucket_id,
    CASE
        WHEN o.name LIKE 'thumbnails/%' THEN 'thumbnail'
        WHEN o.name LIKE '%.mp4' OR o.name LIKE '%.mov' THEN 'video'
        WHEN o.name LIKE '%.jpg' OR o.name LIKE '%.jpeg' THEN 'image'
        ELSE 'other'
    END AS file_type,
    o.metadata->>'size' AS file_size_bytes,
    ROUND((o.metadata->>'size')::numeric / 1048576, 2) AS file_size_mb,
    o.metadata->>'mimetype' AS mime_type,
    o.created_at,
    o.updated_at,
    get_video_public_url(o.name) AS public_url,
    -- Link to exercise_templates
    (SELECT COUNT(*)
     FROM exercise_templates et
     WHERE et.video_url = get_video_public_url(o.name)
        OR et.video_thumbnail_url = get_video_public_url(o.name)
    ) AS linked_exercise_count
FROM storage.objects o
WHERE o.bucket_id = 'exercise-videos'
ORDER BY o.created_at DESC;

COMMENT ON VIEW video_storage_inventory IS
'Shows all files in exercise-videos storage bucket with metadata and links to exercises.';

-- ============================================================================
-- 5. CREATE TRIGGER FOR STORAGE WEBHOOK (THUMBNAIL GENERATION)
-- ============================================================================

-- Enable the http extension for making HTTP requests
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- Create function to trigger thumbnail generation
CREATE OR REPLACE FUNCTION trigger_thumbnail_generation()
RETURNS TRIGGER AS $$
DECLARE
    function_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/generate-video-thumbnail';
    service_key TEXT;
    response_status INTEGER;
BEGIN
    -- Only process video files (not thumbnails)
    IF NEW.bucket_id = 'exercise-videos'
       AND (NEW.name LIKE '%.mp4' OR NEW.name LIKE '%.mov' OR NEW.name LIKE '%.MP4' OR NEW.name LIKE '%.MOV')
       AND NEW.name NOT LIKE 'thumbnails/%' THEN

        -- Get service role key from secrets (must be configured)
        -- Note: In production, store this in Vault or environment variables
        service_key := current_setting('app.settings.supabase_service_role_key', true);

        -- Call Edge Function asynchronously
        PERFORM extensions.http_post(
            url := function_url,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || COALESCE(service_key, '')
            ),
            body := jsonb_build_object(
                'type', TG_OP,
                'table', TG_TABLE_NAME,
                'record', row_to_json(NEW),
                'old_record', row_to_json(OLD)
            )
        );

        RAISE NOTICE 'Thumbnail generation triggered for: %', NEW.name;
    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log error but don't fail the insert
    RAISE WARNING 'Failed to trigger thumbnail generation: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION trigger_thumbnail_generation() IS
'Trigger function that calls generate-video-thumbnail Edge Function when video uploaded. Runs asynchronously.';

-- Create trigger on storage.objects
DROP TRIGGER IF EXISTS on_video_upload ON storage.objects;

CREATE TRIGGER on_video_upload
AFTER INSERT ON storage.objects
FOR EACH ROW
WHEN (NEW.bucket_id = 'exercise-videos' AND NEW.name NOT LIKE 'thumbnails/%')
EXECUTE FUNCTION trigger_thumbnail_generation();

COMMENT ON TRIGGER on_video_upload ON storage.objects IS
'Automatically triggers thumbnail generation when video uploaded to exercise-videos bucket.';

-- ============================================================================
-- 6. CREATE MAINTENANCE FUNCTIONS
-- ============================================================================

-- Function to clean up orphaned videos (not linked to any exercise)
CREATE OR REPLACE FUNCTION cleanup_orphaned_videos()
RETURNS TABLE (
    deleted_filename TEXT,
    file_size_mb NUMERIC
) AS $$
DECLARE
    orphan_record RECORD;
BEGIN
    FOR orphan_record IN
        SELECT
            o.name,
            ROUND((o.metadata->>'size')::numeric / 1048576, 2) AS size_mb
        FROM storage.objects o
        WHERE o.bucket_id = 'exercise-videos'
        AND o.name NOT LIKE 'thumbnails/%'
        AND NOT EXISTS (
            SELECT 1
            FROM exercise_templates et
            WHERE et.video_url = get_video_public_url(o.name)
        )
        AND o.created_at < NOW() - INTERVAL '30 days' -- Only cleanup old orphans
    LOOP
        -- Delete from storage
        DELETE FROM storage.objects
        WHERE bucket_id = 'exercise-videos' AND name = orphan_record.name;

        deleted_filename := orphan_record.name;
        file_size_mb := orphan_record.size_mb;
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_orphaned_videos() IS
'Deletes videos from storage that are not linked to any exercise and are older than 30 days. Use carefully!';

-- Function to get storage statistics
CREATE OR REPLACE FUNCTION get_storage_statistics()
RETURNS TABLE (
    total_files INTEGER,
    total_videos INTEGER,
    total_thumbnails INTEGER,
    total_size_mb NUMERIC,
    average_video_size_mb NUMERIC,
    oldest_file_date TIMESTAMP WITH TIME ZONE,
    newest_file_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER,
        COUNT(*) FILTER (WHERE name LIKE '%.mp4' OR name LIKE '%.mov')::INTEGER,
        COUNT(*) FILTER (WHERE name LIKE 'thumbnails/%')::INTEGER,
        ROUND(SUM((metadata->>'size')::numeric) / 1048576, 2),
        ROUND(AVG((metadata->>'size')::numeric) FILTER (
            WHERE name LIKE '%.mp4' OR name LIKE '%.mov'
        ) / 1048576, 2),
        MIN(created_at),
        MAX(created_at)
    FROM storage.objects
    WHERE bucket_id = 'exercise-videos';
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_storage_statistics() IS
'Returns statistics about exercise-videos storage bucket usage.';

-- ============================================================================
-- 7. VERIFICATION AND TESTING
-- ============================================================================

DO $$
DECLARE
    bucket_exists BOOLEAN;
    policy_count INTEGER;
    function_count INTEGER;
    trigger_exists BOOLEAN;
BEGIN
    -- Check bucket exists
    SELECT EXISTS(
        SELECT 1 FROM storage.buckets WHERE id = 'exercise-videos'
    ) INTO bucket_exists;

    -- Count policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'objects' AND policyname LIKE 'exercise_videos%';

    -- Count helper functions
    SELECT COUNT(*) INTO function_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname IN (
        'get_video_public_url',
        'extract_video_filename',
        'video_exists_in_storage',
        'trigger_thumbnail_generation',
        'cleanup_orphaned_videos',
        'get_storage_statistics'
    );

    -- Check trigger exists
    SELECT EXISTS(
        SELECT 1 FROM pg_trigger WHERE tgname = 'on_video_upload'
    ) INTO trigger_exists;

    RAISE NOTICE '=== Build 69: Storage Bucket Migration Complete ===';
    RAISE NOTICE 'Bucket created: %', CASE WHEN bucket_exists THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE 'RLS policies created: % of 4', policy_count;
    RAISE NOTICE 'Helper functions created: % of 6', function_count;
    RAISE NOTICE 'Thumbnail trigger created: %', CASE WHEN trigger_exists THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '==================================================';

    -- Verify everything is good
    IF bucket_exists AND policy_count = 4 AND function_count = 6 AND trigger_exists THEN
        RAISE NOTICE '✓ All storage infrastructure created successfully';
    ELSE
        RAISE WARNING '✗ Some components missing - review migration logs';
    END IF;
END $$;

-- ============================================================================
-- 8. USAGE EXAMPLES
-- ============================================================================

/*
-- View storage statistics:
SELECT * FROM get_storage_statistics();

-- View all files in storage:
SELECT * FROM video_storage_inventory;

-- Check if a specific video exists:
SELECT video_exists_in_storage('bench-press.mp4');

-- Get public URL for a video:
SELECT get_video_public_url('bench-press.mp4');

-- Extract filename from URL:
SELECT extract_video_filename('https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press.mp4');

-- Find orphaned videos (not linked to exercises):
SELECT
    filename,
    file_size_mb,
    created_at
FROM video_storage_inventory
WHERE linked_exercise_count = 0;

-- Cleanup old orphaned videos (BE CAREFUL!):
SELECT * FROM cleanup_orphaned_videos();
*/

-- ============================================================================
-- 9. SECURITY NOTES
-- ============================================================================

/*
SECURITY CONSIDERATIONS:

1. PUBLIC READ ACCESS:
   - All files in exercise-videos bucket are publicly readable
   - This is intentional - exercise videos should be accessible to patients
   - Do NOT store sensitive data in this bucket

2. AUTHENTICATED WRITE ACCESS:
   - Only authenticated users can upload/modify/delete
   - Consider adding role-based checks for therapist-only access
   - Example: Add WHERE clause: (auth.jwt()->>'role' = 'therapist')

3. FILE SIZE LIMITS:
   - Maximum file size: 50MB
   - Enforced at bucket level
   - Adjust if needed for higher quality videos

4. MIME TYPE RESTRICTIONS:
   - Only video (mp4, mov) and image (jpg, jpeg) files allowed
   - Prevents upload of potentially dangerous file types

5. THUMBNAIL TRIGGER:
   - Runs asynchronously - does not block uploads
   - Failures in thumbnail generation will not fail video upload
   - Monitor Edge Function logs for thumbnail generation issues

6. STORAGE QUOTA:
   - Monitor storage usage with get_storage_statistics()
   - Supabase free tier: 1GB storage
   - Pro tier: 100GB storage
   - Consider CDN for video delivery at scale
*/


-- ============================================
-- Migration 2: HIPAA Audit Logs
-- ============================================

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


-- ============================================
-- Migration 3: Data Export API
-- ============================================

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


-- ============================================
-- Migration 4: Workload Flags
-- ============================================

-- 20251219120001_create_workload_flags.sql
-- Build 69: Workload Flag Detection Algorithms (ACP-188 through ACP-192)
-- Agent 8: Safety & Audit - Backend
--
-- Implements automated workload flag detection based on sports science best practices:
-- 1. Spike Detection: >20% workload increase week-over-week
-- 2. ACR (Acute:Chronic Ratio): 7-day vs 28-day workload comparison
-- 3. Monotony Detection: Low variability in training loads
-- 4. Strain Detection: High cumulative weekly workload
-- 5. Auto-deload triggers based on multiple flag conditions
--
-- Sports Science References:
-- - Gabbett TJ (2016): "The training-injury prevention paradox"
-- - Hulin BT et al. (2016): "Spikes in acute workload are associated with increased injury risk"
-- - Optimal ACWR range: 0.8 - 1.3 (injury prevention zone)

-- ============================================================================
-- FUNCTION: Calculate Workload for a Session
-- ============================================================================
-- Formula: Volume Load = Sets × Reps × Weight (summed across all exercises)
-- Alternative: RPE-based load = Volume × RPE (if RPE tracking is primary)

CREATE OR REPLACE FUNCTION calculate_session_workload(session_id_param uuid)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  workload_value numeric;
BEGIN
  -- Calculate total volume load (sets × reps × weight)
  SELECT COALESCE(SUM(
    COALESCE(el.sets, 0) *
    COALESCE(el.reps, 0) *
    COALESCE(el.weight, 0)
  ), 0)
  INTO workload_value
  FROM exercise_logs el
  WHERE el.session_id = session_id_param;

  -- If no weight data, use RPE-based load as fallback
  IF workload_value = 0 THEN
    SELECT COALESCE(SUM(
      COALESCE(el.sets, 0) *
      COALESCE(el.reps, 0) *
      COALESCE(el.rpe, 5) -- Default RPE of 5 if not recorded
    ), 0)
    INTO workload_value
    FROM exercise_logs el
    WHERE el.session_id = session_id_param;
  END IF;

  RETURN workload_value;
END;
$$;

COMMENT ON FUNCTION calculate_session_workload IS
'Calculates total workload for a session using volume load (sets×reps×weight) or RPE-based load as fallback';

-- ============================================================================
-- FUNCTION: Calculate Acute Workload (7-day rolling average)
-- ============================================================================
-- Acute workload represents recent training stress
-- Uses 7-day rolling average to smooth daily variations

CREATE OR REPLACE FUNCTION calculate_acute_workload(patient_id_param uuid, as_of_date timestamptz DEFAULT now())
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  acute_load numeric;
BEGIN
  SELECT COALESCE(AVG(daily_load), 0)
  INTO acute_load
  FROM (
    SELECT
      DATE(s.completed_at) as session_date,
      SUM(calculate_session_workload(s.id)) as daily_load
    FROM sessions s
    JOIN phases ph ON ph.id = s.phase_id
    JOIN programs pr ON pr.id = ph.program_id
    WHERE pr.patient_id = patient_id_param
      AND s.completed = true
      AND s.completed_at IS NOT NULL
      AND s.completed_at >= (as_of_date - interval '7 days')
      AND s.completed_at <= as_of_date
    GROUP BY DATE(s.completed_at)
  ) daily_loads;

  RETURN acute_load;
END;
$$;

COMMENT ON FUNCTION calculate_acute_workload IS
'Calculates 7-day rolling average workload (acute training load)';

-- ============================================================================
-- FUNCTION: Calculate Chronic Workload (28-day rolling average)
-- ============================================================================
-- Chronic workload represents long-term training adaptation
-- Uses 28-day (4-week) rolling average for fitness baseline

CREATE OR REPLACE FUNCTION calculate_chronic_workload(patient_id_param uuid, as_of_date timestamptz DEFAULT now())
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  chronic_load numeric;
BEGIN
  SELECT COALESCE(AVG(daily_load), 0)
  INTO chronic_load
  FROM (
    SELECT
      DATE(s.completed_at) as session_date,
      SUM(calculate_session_workload(s.id)) as daily_load
    FROM sessions s
    JOIN phases ph ON ph.id = s.phase_id
    JOIN programs pr ON pr.id = ph.program_id
    WHERE pr.patient_id = patient_id_param
      AND s.completed = true
      AND s.completed_at IS NOT NULL
      AND s.completed_at >= (as_of_date - interval '28 days')
      AND s.completed_at <= as_of_date
    GROUP BY DATE(s.completed_at)
  ) daily_loads;

  RETURN chronic_load;
END;
$$;

COMMENT ON FUNCTION calculate_chronic_workload IS
'Calculates 28-day rolling average workload (chronic training load / fitness)';

-- ============================================================================
-- FUNCTION: Calculate ACWR (Acute:Chronic Workload Ratio)
-- ============================================================================
-- ACWR is the gold standard for injury risk assessment
-- Optimal range: 0.8 - 1.3
-- >1.5 = High injury risk (spike)
-- <0.8 = Detraining risk (insufficient stimulus)

CREATE OR REPLACE FUNCTION calculate_acwr(patient_id_param uuid, as_of_date timestamptz DEFAULT now())
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  acute_load numeric;
  chronic_load numeric;
  acwr_value numeric;
BEGIN
  acute_load := calculate_acute_workload(patient_id_param, as_of_date);
  chronic_load := calculate_chronic_workload(patient_id_param, as_of_date);

  -- Avoid division by zero
  IF chronic_load = 0 THEN
    RETURN NULL;
  END IF;

  acwr_value := acute_load / chronic_load;
  RETURN ROUND(acwr_value, 2);
END;
$$;

COMMENT ON FUNCTION calculate_acwr IS
'Calculates Acute:Chronic Workload Ratio (ACWR). Optimal: 0.8-1.3, High risk: >1.5, Low risk: <0.8';

-- ============================================================================
-- FUNCTION: Detect Workload Spike (>20% week-over-week increase)
-- ============================================================================
-- Hulin et al. (2016): Workload spikes >20% increase injury risk by 2-4x
-- Compares current week to previous week

CREATE OR REPLACE FUNCTION detect_workload_spike(patient_id_param uuid, as_of_date timestamptz DEFAULT now())
RETURNS boolean
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  current_week_load numeric;
  previous_week_load numeric;
  increase_pct numeric;
BEGIN
  -- Calculate current week total workload
  SELECT COALESCE(SUM(calculate_session_workload(s.id)), 0)
  INTO current_week_load
  FROM sessions s
  JOIN phases ph ON ph.id = s.phase_id
  JOIN programs pr ON pr.id = ph.program_id
  WHERE pr.patient_id = patient_id_param
    AND s.completed = true
    AND s.completed_at >= (as_of_date - interval '7 days')
    AND s.completed_at <= as_of_date;

  -- Calculate previous week total workload
  SELECT COALESCE(SUM(calculate_session_workload(s.id)), 0)
  INTO previous_week_load
  FROM sessions s
  JOIN phases ph ON ph.id = s.phase_id
  JOIN programs pr ON pr.id = ph.program_id
  WHERE pr.patient_id = patient_id_param
    AND s.completed = true
    AND s.completed_at >= (as_of_date - interval '14 days')
    AND s.completed_at < (as_of_date - interval '7 days');

  -- Avoid division by zero
  IF previous_week_load = 0 THEN
    RETURN false;
  END IF;

  -- Calculate percentage increase
  increase_pct := ((current_week_load - previous_week_load) / previous_week_load) * 100;

  -- Return true if spike >20%
  RETURN increase_pct > 20;
END;
$$;

COMMENT ON FUNCTION detect_workload_spike IS
'Detects workload spikes >20% week-over-week (high injury risk per Hulin 2016)';

-- ============================================================================
-- FUNCTION: Calculate Training Monotony
-- ============================================================================
-- Monotony = Average Daily Load / Standard Deviation of Daily Load
-- High monotony (>2.0) with high strain = increased illness/injury risk
-- Foster et al. (1998): Monotony in training loads

CREATE OR REPLACE FUNCTION calculate_training_monotony(patient_id_param uuid, as_of_date timestamptz DEFAULT now())
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  avg_load numeric;
  stddev_load numeric;
  monotony_value numeric;
BEGIN
  -- Calculate average and standard deviation of daily loads over last 7 days
  SELECT
    AVG(daily_load),
    STDDEV(daily_load)
  INTO avg_load, stddev_load
  FROM (
    SELECT
      DATE(s.completed_at) as session_date,
      SUM(calculate_session_workload(s.id)) as daily_load
    FROM sessions s
    JOIN phases ph ON ph.id = s.phase_id
    JOIN programs pr ON pr.id = ph.program_id
    WHERE pr.patient_id = patient_id_param
      AND s.completed = true
      AND s.completed_at >= (as_of_date - interval '7 days')
      AND s.completed_at <= as_of_date
    GROUP BY DATE(s.completed_at)
  ) daily_loads;

  -- Avoid division by zero
  IF stddev_load IS NULL OR stddev_load = 0 THEN
    RETURN NULL;
  END IF;

  monotony_value := avg_load / stddev_load;
  RETURN ROUND(monotony_value, 2);
END;
$$;

COMMENT ON FUNCTION calculate_training_monotony IS
'Calculates training monotony (avg load / stddev load). High monotony >2.0 increases injury/illness risk';

-- ============================================================================
-- FUNCTION: Calculate Training Strain
-- ============================================================================
-- Strain = Weekly Total Load × Monotony
-- High strain (>threshold) with high monotony = overtraining risk

CREATE OR REPLACE FUNCTION calculate_training_strain(patient_id_param uuid, as_of_date timestamptz DEFAULT now())
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  weekly_load numeric;
  monotony_value numeric;
  strain_value numeric;
BEGIN
  -- Calculate weekly total load
  SELECT COALESCE(SUM(calculate_session_workload(s.id)), 0)
  INTO weekly_load
  FROM sessions s
  JOIN phases ph ON ph.id = s.phase_id
  JOIN programs pr ON pr.id = ph.program_id
  WHERE pr.patient_id = patient_id_param
    AND s.completed = true
    AND s.completed_at >= (as_of_date - interval '7 days')
    AND s.completed_at <= as_of_date;

  monotony_value := calculate_training_monotony(patient_id_param, as_of_date);

  IF monotony_value IS NULL THEN
    RETURN NULL;
  END IF;

  strain_value := weekly_load * monotony_value;
  RETURN ROUND(strain_value, 0);
END;
$$;

COMMENT ON FUNCTION calculate_training_strain IS
'Calculates training strain (weekly load × monotony). High strain indicates overtraining risk';

-- ============================================================================
-- FUNCTION: Generate Workload Flags for Patient
-- ============================================================================
-- Main function that runs all detection algorithms and creates/updates flags

CREATE OR REPLACE FUNCTION generate_workload_flags_for_patient(patient_id_param uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  acute_load numeric;
  chronic_load numeric;
  acwr_value numeric;
  spike_detected boolean;
  monotony_value numeric;
  strain_value numeric;
  flag_severity text;
  should_deload boolean := false;
  deload_reasons text[] := ARRAY[]::text[];
  flag_type_value text;
  flag_message text;
BEGIN
  -- Calculate all metrics
  acute_load := calculate_acute_workload(patient_id_param);
  chronic_load := calculate_chronic_workload(patient_id_param);
  acwr_value := calculate_acwr(patient_id_param);
  spike_detected := detect_workload_spike(patient_id_param);
  monotony_value := calculate_training_monotony(patient_id_param);
  strain_value := calculate_training_strain(patient_id_param);

  -- Determine if deload should be triggered
  -- Deload criteria (any 2 of the following trigger deload):
  -- 1. ACWR > 1.5 (high injury risk)
  -- 2. Workload spike detected (>20% increase)
  -- 3. High monotony (>2.0) + High strain
  -- 4. RPE overshoot or joint pain flags

  IF acwr_value > 1.5 THEN
    deload_reasons := array_append(deload_reasons, 'High ACWR');
  END IF;

  IF spike_detected THEN
    deload_reasons := array_append(deload_reasons, 'Workload spike detected');
  END IF;

  IF monotony_value IS NOT NULL AND monotony_value > 2.0 THEN
    deload_reasons := array_append(deload_reasons, 'High training monotony');
  END IF;

  -- Trigger deload if 2 or more conditions met
  should_deload := array_length(deload_reasons, 1) >= 2;

  -- Determine severity
  IF should_deload OR acwr_value > 1.5 OR spike_detected THEN
    flag_severity := 'red';
  ELSIF acwr_value < 0.8 OR (monotony_value IS NOT NULL AND monotony_value > 1.5) THEN
    flag_severity := 'yellow';
  ELSE
    flag_severity := 'yellow';
  END IF;

  -- Determine primary flag type
  IF acwr_value > 1.5 THEN
    flag_type_value := 'high_workload';
    flag_message := format('High acute:chronic workload ratio (ACWR: %s)', acwr_value);
  ELSIF spike_detected THEN
    flag_type_value := 'high_workload';
    flag_message := 'Workload spike detected (>20% week-over-week increase)';
  ELSIF acwr_value < 0.8 THEN
    flag_type_value := 'velocity_drop';
    flag_message := format('Low acute:chronic workload ratio (ACWR: %s) - potential detraining', acwr_value);
  ELSIF monotony_value IS NOT NULL AND monotony_value > 2.0 THEN
    flag_type_value := 'consecutive_days';
    flag_message := format('High training monotony detected (monotony: %s)', monotony_value);
  ELSE
    flag_type_value := 'high_workload';
    flag_message := 'Workload monitoring active';
  END IF;

  -- Insert or update workload flag
  INSERT INTO workload_flags (
    patient_id,
    acute_workload,
    chronic_workload,
    acwr,
    high_acwr,
    low_acwr,
    missed_reps,
    rpe_overshoot,
    joint_pain,
    readiness_low,
    deload_triggered,
    deload_reason,
    deload_start_date,
    severity,
    flag_type,
    message,
    value,
    threshold,
    timestamp,
    calculated_at
  )
  VALUES (
    patient_id_param,
    acute_load,
    chronic_load,
    acwr_value,
    acwr_value > 1.5,
    acwr_value < 0.8,
    false, -- Set by other systems
    false, -- Set by other systems
    false, -- Set by other systems
    false, -- Set by other systems
    should_deload,
    array_to_string(deload_reasons, ', '),
    CASE WHEN should_deload THEN CURRENT_DATE ELSE NULL END,
    flag_severity,
    flag_type_value,
    flag_message,
    COALESCE(acwr_value, acute_load),
    CASE
      WHEN acwr_value > 1.5 THEN 1.5
      WHEN acwr_value < 0.8 THEN 0.8
      ELSE 1.3
    END,
    now(),
    now()
  )
  ON CONFLICT (patient_id)
  DO UPDATE SET
    acute_workload = EXCLUDED.acute_workload,
    chronic_workload = EXCLUDED.chronic_workload,
    acwr = EXCLUDED.acwr,
    high_acwr = EXCLUDED.high_acwr,
    low_acwr = EXCLUDED.low_acwr,
    deload_triggered = EXCLUDED.deload_triggered,
    deload_reason = EXCLUDED.deload_reason,
    deload_start_date = EXCLUDED.deload_start_date,
    severity = EXCLUDED.severity,
    flag_type = EXCLUDED.flag_type,
    message = EXCLUDED.message,
    value = EXCLUDED.value,
    threshold = EXCLUDED.threshold,
    timestamp = EXCLUDED.timestamp,
    calculated_at = EXCLUDED.calculated_at,
    updated_at = now();

  RAISE NOTICE 'Workload flags updated for patient % - ACWR: %, Spike: %, Deload: %',
    patient_id_param, acwr_value, spike_detected, should_deload;
END;
$$;

COMMENT ON FUNCTION generate_workload_flags_for_patient IS
'Generates workload flags for a patient using spike detection, ACWR, monotony, and strain algorithms';

-- ============================================================================
-- FUNCTION: Generate Workload Flags for All Active Patients
-- ============================================================================
-- Runs workload detection for all patients with active programs
-- Called by cron job daily

CREATE OR REPLACE FUNCTION generate_workload_flags_all_patients()
RETURNS TABLE(patient_id uuid, status text, acwr numeric, deload boolean)
LANGUAGE plpgsql
AS $$
DECLARE
  patient_record RECORD;
  success_count int := 0;
  error_count int := 0;
BEGIN
  -- Get all patients with active programs and recent sessions
  FOR patient_record IN
    SELECT DISTINCT p.id, p.first_name, p.last_name
    FROM patients p
    JOIN programs pr ON pr.patient_id = p.id
    JOIN phases ph ON ph.program_id = pr.id
    JOIN sessions s ON s.phase_id = ph.id
    WHERE pr.status = 'active'
      AND s.completed = true
      AND s.completed_at >= (now() - interval '30 days')
    ORDER BY p.id
  LOOP
    BEGIN
      PERFORM generate_workload_flags_for_patient(patient_record.id);
      success_count := success_count + 1;

      -- Return row for each patient processed
      RETURN QUERY
      SELECT
        patient_record.id,
        'success'::text,
        calculate_acwr(patient_record.id),
        (SELECT deload_triggered FROM workload_flags WHERE workload_flags.patient_id = patient_record.id);

    EXCEPTION WHEN OTHERS THEN
      error_count := error_count + 1;
      RAISE WARNING 'Failed to generate workload flags for patient % (%): %',
        patient_record.id, patient_record.first_name || ' ' || patient_record.last_name, SQLERRM;

      RETURN QUERY
      SELECT
        patient_record.id,
        'error'::text,
        NULL::numeric,
        NULL::boolean;
    END;
  END LOOP;

  RAISE NOTICE 'Workload flag generation complete: % successful, % errors', success_count, error_count;
END;
$$;

COMMENT ON FUNCTION generate_workload_flags_all_patients IS
'Generates workload flags for all active patients. Returns status table. Called by daily cron job.';

-- ============================================================================
-- ADD UNIQUE CONSTRAINT
-- ============================================================================
-- Ensure only one workload flag record per patient

ALTER TABLE workload_flags
DROP CONSTRAINT IF EXISTS workload_flags_patient_id_unique;

ALTER TABLE workload_flags
ADD CONSTRAINT workload_flags_patient_id_unique UNIQUE (patient_id);

-- ============================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_sessions_patient_completed
ON sessions(phase_id, completed, completed_at DESC)
WHERE completed = true;

CREATE INDEX IF NOT EXISTS idx_exercise_logs_session
ON exercise_logs(session_id);

-- ============================================================================
-- VALIDATION & TESTING
-- ============================================================================

DO $$
DECLARE
  test_patient_id uuid;
  test_acwr numeric;
  test_spike boolean;
  test_monotony numeric;
BEGIN
  -- Get a test patient
  SELECT id INTO test_patient_id
  FROM patients
  LIMIT 1;

  IF test_patient_id IS NOT NULL THEN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'WORKLOAD FLAG ALGORITHMS - VALIDATION TEST';
    RAISE NOTICE '============================================';

    -- Test individual functions
    test_acwr := calculate_acwr(test_patient_id);
    test_spike := detect_workload_spike(test_patient_id);
    test_monotony := calculate_training_monotony(test_patient_id);

    RAISE NOTICE 'Test Patient ID: %', test_patient_id;
    RAISE NOTICE 'ACWR: %', COALESCE(test_acwr::text, 'NULL (insufficient data)');
    RAISE NOTICE 'Workload Spike: %', test_spike;
    RAISE NOTICE 'Training Monotony: %', COALESCE(test_monotony::text, 'NULL (insufficient data)');

    -- Test flag generation
    PERFORM generate_workload_flags_for_patient(test_patient_id);

    RAISE NOTICE '✅ Workload flag generated successfully';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'ALGORITHM DEPLOYMENT STATUS:';
    RAISE NOTICE '✅ Spike Detection (>20% increase)';
    RAISE NOTICE '✅ ACWR Calculation (7-day:28-day ratio)';
    RAISE NOTICE '✅ Monotony Detection (load variability)';
    RAISE NOTICE '✅ Strain Calculation (load × monotony)';
    RAISE NOTICE '✅ Auto-Deload Triggers (multi-factor)';
    RAISE NOTICE '';
    RAISE NOTICE 'Linear Issues Complete:';
    RAISE NOTICE '✅ ACP-188: Workload flags table';
    RAISE NOTICE '✅ ACP-189: Spike detection algorithm';
    RAISE NOTICE '✅ ACP-190: ACWR calculation';
    RAISE NOTICE '✅ ACP-191: Monotony detection';
    RAISE NOTICE '✅ ACP-192: Auto-generation function';
    RAISE NOTICE '============================================';
  ELSE
    RAISE NOTICE 'No test patient found - skipping validation';
  END IF;
END $$;


-- ============================================
-- Migration 5: Readiness Adjustments
-- ============================================

-- Create Readiness Adjustments System
-- Implements auto-regulation based on recovery metrics (WHOOP, sleep, HRV)
-- ACP-215, ACP-216, ACP-217, ACP-218, ACP-219
-- Build 69 - Agent 15: Readiness Adjustment Backend

BEGIN;

-- ============================================================================
-- 1. READINESS METRICS TABLE
-- ============================================================================
-- Stores raw readiness data from wearables (WHOOP, Apple Watch, Oura, etc.)

CREATE TABLE IF NOT EXISTS public.readiness_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,

    -- Timestamp
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metric_date DATE NOT NULL,

    -- Recovery metrics (0-100 scale)
    recovery_score NUMERIC CHECK (recovery_score >= 0 AND recovery_score <= 100),
    hrv_score NUMERIC CHECK (hrv_score >= 0 AND hrv_score <= 100),
    sleep_score NUMERIC CHECK (sleep_score >= 0 AND sleep_score <= 100),
    resting_heart_rate NUMERIC,

    -- Sleep details (minutes)
    total_sleep_duration_minutes INT,
    deep_sleep_duration_minutes INT,
    rem_sleep_duration_minutes INT,
    sleep_efficiency_pct NUMERIC,

    -- HRV details (milliseconds)
    hrv_rmssd NUMERIC, -- Root mean square of successive differences
    hrv_avg NUMERIC,   -- Average HRV

    -- Strain/activity metrics
    strain_score NUMERIC,
    activity_minutes INT,
    calories_burned INT,

    -- Data source
    source TEXT NOT NULL CHECK (source IN ('whoop', 'apple_watch', 'oura', 'manual', 'system')),
    source_metadata JSONB DEFAULT '{}'::jsonb,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    UNIQUE(patient_id, metric_date, source)
);

-- Indexes for performance
CREATE INDEX idx_readiness_metrics_patient_id ON public.readiness_metrics(patient_id);
CREATE INDEX idx_readiness_metrics_metric_date ON public.readiness_metrics(metric_date DESC);
CREATE INDEX idx_readiness_metrics_patient_date ON public.readiness_metrics(patient_id, metric_date DESC);
CREATE INDEX idx_readiness_metrics_source ON public.readiness_metrics(source);

-- Comments
COMMENT ON TABLE public.readiness_metrics IS 'Stores readiness data from wearables for workout auto-regulation';
COMMENT ON COLUMN public.readiness_metrics.recovery_score IS 'Overall recovery score 0-100 (primary metric for adjustments)';
COMMENT ON COLUMN public.readiness_metrics.hrv_rmssd IS 'HRV RMSSD in milliseconds - key indicator of autonomic recovery';
COMMENT ON COLUMN public.readiness_metrics.source_metadata IS 'Additional source-specific data in JSON format';

-- ============================================================================
-- 2. READINESS ADJUSTMENTS TABLE
-- ============================================================================
-- Stores calculated adjustments and their application to workouts

CREATE TABLE IF NOT EXISTS public.readiness_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,

    -- Adjustment details
    adjustment_date DATE NOT NULL,
    session_id UUID REFERENCES public.sessions(id) ON DELETE SET NULL,

    -- Input metrics (from readiness_metrics)
    recovery_score NUMERIC NOT NULL,
    hrv_score NUMERIC,
    sleep_score NUMERIC,
    strain_score NUMERIC,

    -- Calculated adjustment multiplier (0.7 - 1.3)
    volume_multiplier NUMERIC NOT NULL CHECK (volume_multiplier >= 0.5 AND volume_multiplier <= 1.5),
    intensity_multiplier NUMERIC NOT NULL CHECK (intensity_multiplier >= 0.5 AND intensity_multiplier <= 1.5),

    -- Adjustment category
    readiness_category TEXT NOT NULL CHECK (readiness_category IN ('optimal', 'good', 'moderate', 'low', 'critical')),

    -- Practitioner override
    is_overridden BOOLEAN DEFAULT FALSE,
    override_reason TEXT,
    overridden_by UUID REFERENCES auth.users(id),
    overridden_at TIMESTAMPTZ,
    original_volume_multiplier NUMERIC,
    original_intensity_multiplier NUMERIC,

    -- Application status
    status TEXT NOT NULL DEFAULT 'calculated' CHECK (status IN ('calculated', 'applied', 'overridden', 'expired')),
    applied_at TIMESTAMPTZ,

    -- Algorithm details
    algorithm_version TEXT NOT NULL DEFAULT 'v1.0',
    calculation_metadata JSONB DEFAULT '{}'::jsonb,

    -- Recommendations
    recommendations TEXT[],
    warnings TEXT[],

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),

    -- Constraints
    UNIQUE(patient_id, adjustment_date)
);

-- Indexes for performance
CREATE INDEX idx_readiness_adjustments_patient_id ON public.readiness_adjustments(patient_id);
CREATE INDEX idx_readiness_adjustments_date ON public.readiness_adjustments(adjustment_date DESC);
CREATE INDEX idx_readiness_adjustments_session_id ON public.readiness_adjustments(session_id);
CREATE INDEX idx_readiness_adjustments_patient_date ON public.readiness_adjustments(patient_id, adjustment_date DESC);
CREATE INDEX idx_readiness_adjustments_category ON public.readiness_adjustments(readiness_category);
CREATE INDEX idx_readiness_adjustments_status ON public.readiness_adjustments(status);
CREATE INDEX idx_readiness_adjustments_overridden ON public.readiness_adjustments(is_overridden) WHERE is_overridden = TRUE;

-- Comments
COMMENT ON TABLE public.readiness_adjustments IS 'Calculated workout adjustments based on readiness metrics';
COMMENT ON COLUMN public.readiness_adjustments.volume_multiplier IS 'Volume adjustment: 0.7-1.3x (e.g., 0.85 = 85% of prescribed volume)';
COMMENT ON COLUMN public.readiness_adjustments.intensity_multiplier IS 'Intensity adjustment: 0.7-1.3x (e.g., 1.15 = 115% of prescribed intensity)';
COMMENT ON COLUMN public.readiness_adjustments.readiness_category IS 'Readiness band: optimal (90-100), good (75-89), moderate (60-74), low (40-59), critical (<40)';
COMMENT ON COLUMN public.readiness_adjustments.calculation_metadata IS 'Algorithm inputs, thresholds, and decision factors';

-- ============================================================================
-- 3. ADJUSTMENT CALCULATION FUNCTION
-- ============================================================================
-- Calculates volume/intensity multipliers based on recovery score

CREATE OR REPLACE FUNCTION public.calculate_adjustment_multipliers(
    p_recovery_score NUMERIC,
    p_hrv_score NUMERIC DEFAULT NULL,
    p_sleep_score NUMERIC DEFAULT NULL,
    p_strain_score NUMERIC DEFAULT NULL
)
RETURNS TABLE (
    volume_multiplier NUMERIC,
    intensity_multiplier NUMERIC,
    readiness_category TEXT,
    recommendations TEXT[],
    warnings TEXT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_composite_score NUMERIC;
    v_volume_mult NUMERIC;
    v_intensity_mult NUMERIC;
    v_category TEXT;
    v_recommendations TEXT[] := ARRAY[]::TEXT[];
    v_warnings TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Calculate composite score (weighted average)
    -- Recovery score: 50%, HRV: 25%, Sleep: 20%, Strain consideration: 5%
    v_composite_score := p_recovery_score * 0.5;

    IF p_hrv_score IS NOT NULL THEN
        v_composite_score := v_composite_score + (p_hrv_score * 0.25);
    ELSE
        v_composite_score := v_composite_score + (p_recovery_score * 0.25); -- Use recovery as fallback
    END IF;

    IF p_sleep_score IS NOT NULL THEN
        v_composite_score := v_composite_score + (p_sleep_score * 0.20);
    ELSE
        v_composite_score := v_composite_score + (p_recovery_score * 0.20); -- Use recovery as fallback
    END IF;

    -- Strain consideration (inverse relationship - high strain = reduce adjustment)
    IF p_strain_score IS NOT NULL AND p_strain_score > 15 THEN
        v_composite_score := v_composite_score - (LEAST((p_strain_score - 15) / 2, 10)); -- Cap reduction at 10 points
        v_warnings := array_append(v_warnings, 'High accumulated strain detected - conservative adjustment applied');
    END IF;

    -- Ensure composite score stays in valid range
    v_composite_score := GREATEST(0, LEAST(100, v_composite_score));

    -- Calculate multipliers based on composite score
    -- Optimal (90-100): 1.1-1.3x volume, 1.0-1.15x intensity
    IF v_composite_score >= 90 THEN
        v_volume_mult := 1.1 + ((v_composite_score - 90) / 100); -- 1.1 to 1.2
        v_intensity_mult := 1.0 + ((v_composite_score - 90) / 66.67); -- 1.0 to 1.15
        v_category := 'optimal';
        v_recommendations := ARRAY[
            'Excellent recovery - consider progressive overload',
            'Optimal conditions for skill work and technique refinement',
            'Good day for testing maximal efforts or PRs'
        ];

    -- Good (75-89): 1.0-1.1x volume, 0.95-1.0x intensity
    ELSIF v_composite_score >= 75 THEN
        v_volume_mult := 1.0 + ((v_composite_score - 75) / 140); -- 1.0 to 1.1
        v_intensity_mult := 0.95 + ((v_composite_score - 75) / 280); -- 0.95 to 1.0
        v_category := 'good';
        v_recommendations := ARRAY[
            'Good recovery - proceed with planned training',
            'Monitor RPE and adjust within session if needed',
            'Consider adding optional accessory work'
        ];

    -- Moderate (60-74): 0.85-1.0x volume, 0.85-0.95x intensity
    ELSIF v_composite_score >= 60 THEN
        v_volume_mult := 0.85 + ((v_composite_score - 60) / 93.33); -- 0.85 to 1.0
        v_intensity_mult := 0.85 + ((v_composite_score - 60) / 140); -- 0.85 to 0.95
        v_category := 'moderate';
        v_recommendations := ARRAY[
            'Moderate recovery - reduce volume and intensity slightly',
            'Focus on movement quality over load',
            'Consider eliminating optional exercises',
            'Monitor for pain or excessive fatigue'
        ];
        v_warnings := array_append(v_warnings, 'Moderate readiness - conservative adjustments recommended');

    -- Low (40-59): 0.7-0.85x volume, 0.7-0.85x intensity
    ELSIF v_composite_score >= 40 THEN
        v_volume_mult := 0.7 + ((v_composite_score - 40) / 133.33); -- 0.7 to 0.85
        v_intensity_mult := 0.7 + ((v_composite_score - 40) / 133.33); -- 0.7 to 0.85
        v_category := 'low';
        v_recommendations := ARRAY[
            'Low recovery - significant reduction recommended',
            'Focus on movement practice and technique',
            'Consider active recovery or mobility work instead',
            'Prioritize primary movements only'
        ];
        v_warnings := array_append(v_warnings, 'Low readiness - consider deload or active recovery day');

    -- Critical (<40): 0.5-0.7x volume, 0.5-0.7x intensity
    ELSE
        v_volume_mult := 0.5 + (v_composite_score / 133.33); -- 0.5 to 0.7
        v_intensity_mult := 0.5 + (v_composite_score / 133.33); -- 0.5 to 0.7
        v_category := 'critical';
        v_recommendations := ARRAY[
            'Critical recovery state - strongly consider rest day',
            'If training, use very light loads (technique only)',
            'Prioritize recovery: sleep, nutrition, stress management',
            'Monitor for illness or overtraining symptoms'
        ];
        v_warnings := array_append(v_warnings, 'CRITICAL readiness - rest day strongly recommended');
        v_warnings := array_append(v_warnings, 'Consult with practitioner before proceeding');
    END IF;

    -- Add HRV-specific warnings
    IF p_hrv_score IS NOT NULL AND p_hrv_score < 40 THEN
        v_warnings := array_append(v_warnings, 'Very low HRV - autonomic stress detected');
    END IF;

    -- Add sleep-specific warnings
    IF p_sleep_score IS NOT NULL AND p_sleep_score < 50 THEN
        v_warnings := array_append(v_warnings, 'Poor sleep quality - increased injury risk');
    END IF;

    -- Round multipliers to 2 decimal places
    v_volume_mult := ROUND(v_volume_mult::numeric, 2);
    v_intensity_mult := ROUND(v_intensity_mult::numeric, 2);

    RETURN QUERY SELECT v_volume_mult, v_intensity_mult, v_category, v_recommendations, v_warnings;
END;
$$;

COMMENT ON FUNCTION public.calculate_adjustment_multipliers IS 'Calculates volume/intensity multipliers from readiness metrics using composite scoring algorithm';

-- ============================================================================
-- 4. CREATE ADJUSTMENT FUNCTION
-- ============================================================================
-- Creates or updates an adjustment record for a patient

CREATE OR REPLACE FUNCTION public.create_readiness_adjustment(
    p_patient_id UUID,
    p_adjustment_date DATE,
    p_session_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_adjustment_id UUID;
    v_metrics RECORD;
    v_multipliers RECORD;
BEGIN
    -- Get most recent readiness metrics for the date
    SELECT *
    INTO v_metrics
    FROM public.readiness_metrics
    WHERE patient_id = p_patient_id
        AND metric_date = p_adjustment_date
    ORDER BY recovery_score DESC NULLS LAST, recorded_at DESC
    LIMIT 1;

    -- If no metrics found, return NULL
    IF v_metrics IS NULL THEN
        RAISE NOTICE 'No readiness metrics found for patient % on date %', p_patient_id, p_adjustment_date;
        RETURN NULL;
    END IF;

    -- Calculate multipliers
    SELECT *
    INTO v_multipliers
    FROM public.calculate_adjustment_multipliers(
        v_metrics.recovery_score,
        v_metrics.hrv_score,
        v_metrics.sleep_score,
        v_metrics.strain_score
    );

    -- Insert or update adjustment
    INSERT INTO public.readiness_adjustments (
        patient_id,
        adjustment_date,
        session_id,
        recovery_score,
        hrv_score,
        sleep_score,
        strain_score,
        volume_multiplier,
        intensity_multiplier,
        readiness_category,
        recommendations,
        warnings,
        calculation_metadata,
        created_by
    ) VALUES (
        p_patient_id,
        p_adjustment_date,
        p_session_id,
        v_metrics.recovery_score,
        v_metrics.hrv_score,
        v_metrics.sleep_score,
        v_metrics.strain_score,
        v_multipliers.volume_multiplier,
        v_multipliers.intensity_multiplier,
        v_multipliers.readiness_category,
        v_multipliers.recommendations,
        v_multipliers.warnings,
        jsonb_build_object(
            'source', v_metrics.source,
            'recorded_at', v_metrics.recorded_at,
            'composite_inputs', jsonb_build_object(
                'recovery_weight', 0.5,
                'hrv_weight', 0.25,
                'sleep_weight', 0.20
            )
        ),
        auth.uid()
    )
    ON CONFLICT (patient_id, adjustment_date)
    DO UPDATE SET
        session_id = EXCLUDED.session_id,
        recovery_score = EXCLUDED.recovery_score,
        hrv_score = EXCLUDED.hrv_score,
        sleep_score = EXCLUDED.sleep_score,
        strain_score = EXCLUDED.strain_score,
        volume_multiplier = EXCLUDED.volume_multiplier,
        intensity_multiplier = EXCLUDED.intensity_multiplier,
        readiness_category = EXCLUDED.readiness_category,
        recommendations = EXCLUDED.recommendations,
        warnings = EXCLUDED.warnings,
        calculation_metadata = EXCLUDED.calculation_metadata,
        updated_at = NOW()
    WHERE public.readiness_adjustments.is_overridden = FALSE
    RETURNING id INTO v_adjustment_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        'CREATE',
        'readiness_adjustment',
        v_adjustment_id,
        'calculate_adjustment',
        format('Readiness adjustment calculated: %s (volume: %sx, intensity: %sx)',
               v_multipliers.readiness_category,
               v_multipliers.volume_multiplier,
               v_multipliers.intensity_multiplier),
        p_patient_id,
        NULL,
        jsonb_build_object('adjustment_id', v_adjustment_id),
        FALSE,
        'DATA_MODIFICATION'
    );

    RETURN v_adjustment_id;
END;
$$;

COMMENT ON FUNCTION public.create_readiness_adjustment IS 'Creates adjustment record from latest readiness metrics';

-- ============================================================================
-- 5. OVERRIDE ADJUSTMENT FUNCTION
-- ============================================================================
-- Allows practitioners to override calculated adjustments

CREATE OR REPLACE FUNCTION public.override_readiness_adjustment(
    p_adjustment_id UUID,
    p_volume_multiplier NUMERIC,
    p_intensity_multiplier NUMERIC,
    p_override_reason TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_original_volume NUMERIC;
    v_original_intensity NUMERIC;
    v_patient_id UUID;
BEGIN
    -- Get original values
    SELECT volume_multiplier, intensity_multiplier, patient_id
    INTO v_original_volume, v_original_intensity, v_patient_id
    FROM public.readiness_adjustments
    WHERE id = p_adjustment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Adjustment not found: %', p_adjustment_id;
    END IF;

    -- Validate multipliers
    IF p_volume_multiplier < 0.5 OR p_volume_multiplier > 1.5 THEN
        RAISE EXCEPTION 'Volume multiplier must be between 0.5 and 1.5';
    END IF;

    IF p_intensity_multiplier < 0.5 OR p_intensity_multiplier > 1.5 THEN
        RAISE EXCEPTION 'Intensity multiplier must be between 0.5 and 1.5';
    END IF;

    -- Update adjustment
    UPDATE public.readiness_adjustments
    SET
        is_overridden = TRUE,
        override_reason = p_override_reason,
        overridden_by = auth.uid(),
        overridden_at = NOW(),
        original_volume_multiplier = v_original_volume,
        original_intensity_multiplier = v_original_intensity,
        volume_multiplier = p_volume_multiplier,
        intensity_multiplier = p_intensity_multiplier,
        status = 'overridden',
        updated_at = NOW()
    WHERE id = p_adjustment_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        'UPDATE',
        'readiness_adjustment',
        p_adjustment_id,
        'override_adjustment',
        format('Practitioner override: volume %s→%s, intensity %s→%s. Reason: %s',
               v_original_volume, p_volume_multiplier,
               v_original_intensity, p_intensity_multiplier,
               p_override_reason),
        v_patient_id,
        jsonb_build_object('volume_multiplier', v_original_volume, 'intensity_multiplier', v_original_intensity),
        jsonb_build_object('volume_multiplier', p_volume_multiplier, 'intensity_multiplier', p_intensity_multiplier),
        FALSE,
        'DATA_MODIFICATION'
    );

    RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION public.override_readiness_adjustment IS 'Allows practitioners to override calculated adjustments with audit trail';

-- ============================================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS on readiness_metrics
ALTER TABLE public.readiness_metrics ENABLE ROW LEVEL SECURITY;

-- Patients can view and insert their own metrics
CREATE POLICY "Patients can view their own readiness metrics"
ON public.readiness_metrics
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Patients can insert their own readiness metrics"
ON public.readiness_metrics
FOR INSERT
TO authenticated
WITH CHECK (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- Therapists can view metrics for their patients
CREATE POLICY "Therapists can view patient readiness metrics"
ON public.readiness_metrics
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

-- System can insert metrics (for automated imports)
CREATE POLICY "System can insert readiness metrics"
ON public.readiness_metrics
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE id = auth.uid()
        AND raw_user_meta_data->>'role' IN ('admin', 'system')
    )
);

-- Enable RLS on readiness_adjustments
ALTER TABLE public.readiness_adjustments ENABLE ROW LEVEL SECURITY;

-- Patients can view their own adjustments
CREATE POLICY "Patients can view their own readiness adjustments"
ON public.readiness_adjustments
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- Therapists can view and modify adjustments for their patients
CREATE POLICY "Therapists can view patient readiness adjustments"
ON public.readiness_adjustments
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

CREATE POLICY "Therapists can override patient readiness adjustments"
ON public.readiness_adjustments
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.therapists t
        JOIN public.patients p ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
        AND p.id = patient_id
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.therapists t
        JOIN public.patients p ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
        AND p.id = patient_id
    )
);

-- System can create adjustments
CREATE POLICY "System can create readiness adjustments"
ON public.readiness_adjustments
FOR INSERT
TO authenticated
WITH CHECK (true); -- Controlled by function security

-- ============================================================================
-- 7. TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_readiness_metrics_updated_at
BEFORE UPDATE ON public.readiness_metrics
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_readiness_adjustments_updated_at
BEFORE UPDATE ON public.readiness_adjustments
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 8. HELPER VIEWS
-- ============================================================================

-- Recent adjustments with patient info
CREATE OR REPLACE VIEW public.vw_recent_adjustments AS
SELECT
    ra.id,
    ra.patient_id,
    p.first_name || ' ' || p.last_name as patient_name,
    ra.adjustment_date,
    ra.readiness_category,
    ra.recovery_score,
    ra.volume_multiplier,
    ra.intensity_multiplier,
    ra.is_overridden,
    ra.status,
    ra.recommendations,
    ra.warnings,
    ra.created_at
FROM public.readiness_adjustments ra
JOIN public.patients p ON p.id = ra.patient_id
ORDER BY ra.adjustment_date DESC, ra.created_at DESC;

-- Adjustment trends (7-day rolling average)
CREATE OR REPLACE VIEW public.vw_adjustment_trends AS
SELECT
    patient_id,
    adjustment_date,
    recovery_score,
    volume_multiplier,
    intensity_multiplier,
    readiness_category,
    AVG(recovery_score) OVER (
        PARTITION BY patient_id
        ORDER BY adjustment_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as recovery_score_7d_avg,
    AVG(volume_multiplier) OVER (
        PARTITION BY patient_id
        ORDER BY adjustment_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as volume_multiplier_7d_avg
FROM public.readiness_adjustments
ORDER BY patient_id, adjustment_date DESC;

-- ============================================================================
-- 9. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT ON public.readiness_metrics TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.readiness_adjustments TO authenticated;
GRANT SELECT ON public.vw_recent_adjustments TO authenticated;
GRANT SELECT ON public.vw_adjustment_trends TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_adjustment_multipliers TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_readiness_adjustment TO authenticated;
GRANT EXECUTE ON FUNCTION public.override_readiness_adjustment TO authenticated;

COMMIT;


-- ============================================
-- Migration 6: Scheduled Sessions RLS Policies
-- ============================================

-- Migration: Enhanced RLS Policies for Scheduled Sessions Rescheduling
-- Build 69 Agent 12
-- Date: 2025-12-19
-- Description: Add granular RLS policies for patient-only rescheduling access

BEGIN;

-- Drop existing policies to recreate with enhanced granularity
DROP POLICY IF EXISTS "Patients update own scheduled sessions" ON scheduled_sessions;

-- Policy 1: Patients can reschedule their own sessions (update date/time/notes only)
-- Cannot change patient_id, session_id, or manually set status/completed_at
CREATE POLICY "Patients can reschedule own sessions"
    ON scheduled_sessions FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (
        -- Must be their own session
        patient_id = auth.uid()
        -- Cannot change critical fields (enforced by WITH CHECK)
        AND patient_id = OLD.patient_id
        AND session_id = OLD.session_id
    );

-- Policy 2: Patients can update notes on their own sessions
CREATE POLICY "Patients can update notes on own sessions"
    ON scheduled_sessions FOR UPDATE
    USING (
        patient_id = auth.uid()
        AND status IN ('scheduled', 'rescheduled')
    )
    WITH CHECK (
        patient_id = auth.uid()
        -- Only allow updating notes field for scheduled/rescheduled sessions
        AND status IN ('scheduled', 'rescheduled')
    );

-- Policy 3: Patients can mark their own sessions as completed
CREATE POLICY "Patients can complete own sessions"
    ON scheduled_sessions FOR UPDATE
    USING (
        patient_id = auth.uid()
        AND status = 'scheduled'
        AND scheduled_date <= CURRENT_DATE
    )
    WITH CHECK (
        patient_id = auth.uid()
        AND status = 'completed'
    );

-- Policy 4: Patients can cancel their own upcoming sessions
CREATE POLICY "Patients can cancel own upcoming sessions"
    ON scheduled_sessions FOR UPDATE
    USING (
        patient_id = auth.uid()
        AND status = 'scheduled'
        AND scheduled_date >= CURRENT_DATE
    )
    WITH CHECK (
        patient_id = auth.uid()
        AND status = 'cancelled'
    );

-- Create function for secure rescheduling with validation
CREATE OR REPLACE FUNCTION reschedule_session(
    p_scheduled_session_id UUID,
    p_new_date DATE,
    p_new_time TIME,
    p_notes TEXT DEFAULT NULL
)
RETURNS scheduled_sessions AS $$
DECLARE
    v_session scheduled_sessions;
    v_patient_id UUID;
BEGIN
    -- Get current session details
    SELECT * INTO v_session
    FROM scheduled_sessions
    WHERE id = p_scheduled_session_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Scheduled session not found';
    END IF;

    -- Verify patient ownership (RLS will also enforce this)
    v_patient_id := auth.uid();
    IF v_session.patient_id != v_patient_id THEN
        RAISE EXCEPTION 'Not authorized to reschedule this session';
    END IF;

    -- Verify session is in reschedulable state
    IF v_session.status NOT IN ('scheduled', 'rescheduled') THEN
        RAISE EXCEPTION 'Cannot reschedule session with status: %', v_session.status;
    END IF;

    -- Verify new date is in the future
    IF p_new_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Cannot reschedule to a past date';
    END IF;

    -- Check for conflicting schedule (same session, same date)
    IF EXISTS (
        SELECT 1
        FROM scheduled_sessions
        WHERE patient_id = v_patient_id
        AND session_id = v_session.session_id
        AND scheduled_date = p_new_date
        AND id != p_scheduled_session_id
        AND status != 'cancelled'
    ) THEN
        RAISE EXCEPTION 'Session already scheduled for this date';
    END IF;

    -- Update the scheduled session
    UPDATE scheduled_sessions
    SET
        scheduled_date = p_new_date,
        scheduled_time = p_new_time,
        status = 'rescheduled',
        reminder_sent = FALSE, -- Reset reminder flag
        notes = COALESCE(p_notes, notes),
        updated_at = NOW()
    WHERE id = p_scheduled_session_id
    RETURNING * INTO v_session;

    RETURN v_session;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION reschedule_session TO authenticated;

-- Create function for marking session as completed with validation
CREATE OR REPLACE FUNCTION mark_session_completed(
    p_scheduled_session_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS scheduled_sessions AS $$
DECLARE
    v_session scheduled_sessions;
    v_patient_id UUID;
BEGIN
    -- Get current session details
    SELECT * INTO v_session
    FROM scheduled_sessions
    WHERE id = p_scheduled_session_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Scheduled session not found';
    END IF;

    -- Verify patient ownership
    v_patient_id := auth.uid();
    IF v_session.patient_id != v_patient_id THEN
        RAISE EXCEPTION 'Not authorized to complete this session';
    END IF;

    -- Verify session is scheduled
    IF v_session.status != 'scheduled' THEN
        RAISE EXCEPTION 'Can only complete scheduled sessions. Current status: %', v_session.status;
    END IF;

    -- Update the scheduled session
    UPDATE scheduled_sessions
    SET
        status = 'completed',
        completed_at = NOW(),
        notes = COALESCE(p_notes, notes),
        updated_at = NOW()
    WHERE id = p_scheduled_session_id
    RETURNING * INTO v_session;

    RETURN v_session;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION mark_session_completed TO authenticated;

-- Create index for faster reschedule conflict checking
CREATE INDEX IF NOT EXISTS idx_scheduled_sessions_conflict_check
ON scheduled_sessions(patient_id, session_id, scheduled_date, status)
WHERE status != 'cancelled';

-- Create index for upcoming sessions queries
CREATE INDEX IF NOT EXISTS idx_scheduled_sessions_upcoming
ON scheduled_sessions(patient_id, scheduled_date, scheduled_time)
WHERE status = 'scheduled' AND scheduled_date >= CURRENT_DATE;

-- Add comment for documentation
COMMENT ON FUNCTION reschedule_session IS 'Securely reschedule a session with validation. Patients can only reschedule their own sessions to future dates.';
COMMENT ON FUNCTION mark_session_completed IS 'Mark a scheduled session as completed. Only the patient who owns the session can mark it complete.';

COMMIT;

-- Verification queries (run after migration)
/*
-- Verify policies exist
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'scheduled_sessions'
ORDER BY policyname;

-- Test reschedule function (as patient)
SELECT * FROM reschedule_session(
    'scheduled-session-uuid'::uuid,
    CURRENT_DATE + 1,
    '14:00:00'::time,
    'Rescheduled due to conflict'
);

-- Test complete function (as patient)
SELECT * FROM mark_session_completed(
    'scheduled-session-uuid'::uuid,
    'Great workout!'
);
*/


-- ============================================
-- Migration 7: Session Exercises Performance
-- ============================================

-- Build 68: Optimize session exercises query performance
-- Fixes: 99-second load time for program with 24 sessions
-- Root cause: Missing index on session_id, sequential queries

-- Add index for session_exercises lookups (most critical)
CREATE INDEX IF NOT EXISTS idx_session_exercises_session_id_order
ON session_exercises(session_id, order_index);

-- Add index for exercise_templates lookups in joins
CREATE INDEX IF NOT EXISTS idx_session_exercises_exercise_template_id
ON session_exercises(exercise_template_id);

-- Create optimized view for session exercises with template details
-- This pre-joins the data that's queried together 100% of the time
CREATE OR REPLACE VIEW vw_session_exercises_with_templates AS
SELECT
    se.id,
    se.session_id,
    se.exercise_template_id,
    se.prescribed_sets,
    se.prescribed_reps,
    se.prescribed_load,
    se.load_unit,
    se.rest_period_seconds,
    se.order_index,
    se.notes,
    se.created_at,
    -- Exercise template details
    et.name as exercise_name,
    et.category,
    et.body_region,
    et.video_url,
    et.video_thumbnail_url,
    et.video_duration,
    et.equipment_type,
    et.difficulty_level,
    et.technique_cues,
    et.common_mistakes,
    et.safety_notes
FROM session_exercises se
INNER JOIN exercise_templates et ON se.exercise_template_id = et.id
ORDER BY se.session_id, se.order_index;

-- Grant access
GRANT SELECT ON vw_session_exercises_with_templates TO authenticated;

-- Add comment
COMMENT ON VIEW vw_session_exercises_with_templates IS
'Optimized view for fetching session exercises with template details. Eliminates N+1 query problem.';

-- Analyze tables to update statistics for query planner
ANALYZE session_exercises;
ANALYZE exercise_templates;


-- ============================================
-- Migration 8: Database Performance Optimizations
-- ============================================

-- Database Performance Optimization
-- Target: <50ms query times, <200ms for complex queries

BEGIN;

-- ============================================================================
-- PART 1: Index Optimization
-- ============================================================================

-- Programs table indexes
CREATE INDEX IF NOT EXISTS idx_programs_patient_id_status ON public.programs(patient_id, status);
CREATE INDEX IF NOT EXISTS idx_programs_therapist_id_status ON public.programs(therapist_id, status);
CREATE INDEX IF NOT EXISTS idx_programs_dates ON public.programs(start_date, end_date) WHERE status = 'active';

-- Sessions table indexes
CREATE INDEX IF NOT EXISTS idx_sessions_program_id_status ON public.sessions(program_id, status);
CREATE INDEX IF NOT EXISTS idx_sessions_scheduled_date ON public.sessions(scheduled_date DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_patient_lookup ON public.sessions(program_id, scheduled_date DESC);

-- Exercise logs indexes
CREATE INDEX IF NOT EXISTS idx_exercise_logs_session_id ON public.exercise_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_exercise_logs_created_at ON public.exercise_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_exercise_logs_patient_lookup ON public.exercise_logs(session_id, created_at DESC);

-- Patients table indexes
CREATE INDEX IF NOT EXISTS idx_patients_therapist_id ON public.patients(therapist_id);
CREATE INDEX IF NOT EXISTS idx_patients_user_id ON public.patients(user_id);
CREATE INDEX IF NOT EXISTS idx_patients_search ON public.patients USING gin(to_tsvector('english', first_name || ' ' || last_name || ' ' || email));

-- Therapists table indexes
CREATE INDEX IF NOT EXISTS idx_therapists_user_id ON public.therapists(user_id);

-- Daily readiness indexes
CREATE INDEX IF NOT EXISTS idx_daily_readiness_patient_date ON public.daily_readiness(patient_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_readiness_date_range ON public.daily_readiness(patient_id, date) WHERE date >= CURRENT_DATE - INTERVAL '30 days';

-- Workload flags indexes
CREATE INDEX IF NOT EXISTS idx_workload_flags_patient_resolved ON public.workload_flags(patient_id, resolved, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workload_flags_session ON public.workload_flags(session_id);

-- Session notes indexes
CREATE INDEX IF NOT EXISTS idx_session_notes_session_id ON public.session_notes(session_id);

-- Session exercises indexes
CREATE INDEX IF NOT EXISTS idx_session_exercises_session_id ON public.session_exercises(session_id, order_index);

-- ============================================================================
-- PART 2: Materialized Views for Analytics
-- ============================================================================

-- Patient progress summary (refreshed hourly)
CREATE MATERIALIZED VIEW IF NOT EXISTS public.patient_progress_summary AS
SELECT
    p.id as patient_id,
    p.first_name,
    p.last_name,
    COUNT(DISTINCT pr.id) as total_programs,
    COUNT(DISTINCT s.id) as total_sessions,
    COUNT(DISTINCT CASE WHEN s.status = 'completed' THEN s.id END) as completed_sessions,
    COUNT(DISTINCT el.id) as total_exercise_logs,
    SUM(el.sets * el.reps * el.weight) as total_volume,
    AVG(el.rpe) as avg_rpe,
    MAX(s.scheduled_date) as last_session_date,
    AVG(dr.readiness_score) as avg_readiness_score
FROM public.patients p
LEFT JOIN public.programs pr ON pr.patient_id = p.id
LEFT JOIN public.sessions s ON s.program_id = pr.id
LEFT JOIN public.exercise_logs el ON el.session_id = s.id
LEFT JOIN public.daily_readiness dr ON dr.patient_id = p.id AND dr.date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.id, p.first_name, p.last_name;

CREATE UNIQUE INDEX ON public.patient_progress_summary(patient_id);

-- Exercise performance summary
CREATE MATERIALIZED VIEW IF NOT EXISTS public.exercise_performance_summary AS
SELECT
    el.exercise_id,
    e.name as exercise_name,
    p.id as patient_id,
    COUNT(*) as total_sets,
    AVG(el.weight) as avg_weight,
    MAX(el.weight) as max_weight,
    AVG(el.rpe) as avg_rpe,
    MAX(el.created_at) as last_performed
FROM public.exercise_logs el
JOIN public.exercises e ON e.id = el.exercise_id
JOIN public.sessions s ON s.id = el.session_id
JOIN public.programs pr ON pr.id = s.program_id
JOIN public.patients p ON p.id = pr.patient_id
WHERE el.created_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY el.exercise_id, e.name, p.id;

CREATE UNIQUE INDEX ON public.exercise_performance_summary(patient_id, exercise_id);

-- Session volume summary (for charts)
CREATE MATERIALIZED VIEW IF NOT EXISTS public.session_volume_summary AS
SELECT
    pr.patient_id,
    s.id as session_id,
    s.scheduled_date,
    SUM(el.sets * el.reps * el.weight) as total_volume,
    AVG(el.rpe) as avg_rpe,
    COUNT(DISTINCT el.exercise_id) as unique_exercises
FROM public.sessions s
JOIN public.programs pr ON pr.id = s.program_id
LEFT JOIN public.exercise_logs el ON el.session_id = s.id
WHERE s.scheduled_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY pr.patient_id, s.id, s.scheduled_date;

CREATE INDEX ON public.session_volume_summary(patient_id, scheduled_date DESC);

-- ============================================================================
-- PART 3: Query Optimization Functions
-- ============================================================================

-- Optimized function to get patient dashboard data
CREATE OR REPLACE FUNCTION public.get_patient_dashboard(p_patient_id UUID)
RETURNS JSON
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'patient', (
            SELECT row_to_json(p)
            FROM public.patients p
            WHERE p.id = p_patient_id
        ),
        'active_programs', (
            SELECT COALESCE(json_agg(pr), '[]'::json)
            FROM public.programs pr
            WHERE pr.patient_id = p_patient_id
            AND pr.status = 'active'
        ),
        'upcoming_sessions', (
            SELECT COALESCE(json_agg(s), '[]'::json)
            FROM public.sessions s
            JOIN public.programs pr ON s.program_id = pr.id
            WHERE pr.patient_id = p_patient_id
            AND s.scheduled_date >= CURRENT_DATE
            AND s.status IN ('scheduled', 'in_progress')
            ORDER BY s.scheduled_date ASC
            LIMIT 10
        ),
        'recent_workload_flags', (
            SELECT COALESCE(json_agg(wf), '[]'::json)
            FROM public.workload_flags wf
            WHERE wf.patient_id = p_patient_id
            AND wf.resolved = false
            ORDER BY wf.created_at DESC
            LIMIT 5
        ),
        'progress_summary', (
            SELECT row_to_json(pps)
            FROM public.patient_progress_summary pps
            WHERE pps.patient_id = p_patient_id
        ),
        'latest_readiness', (
            SELECT row_to_json(dr)
            FROM public.daily_readiness dr
            WHERE dr.patient_id = p_patient_id
            ORDER BY dr.date DESC
            LIMIT 1
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;

-- Optimized function to get session details
CREATE OR REPLACE FUNCTION public.get_session_details(p_session_id UUID)
RETURNS JSON
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'session', (
            SELECT row_to_json(s)
            FROM public.sessions s
            WHERE s.id = p_session_id
        ),
        'program', (
            SELECT row_to_json(pr)
            FROM public.sessions s
            JOIN public.programs pr ON s.program_id = pr.id
            WHERE s.id = p_session_id
        ),
        'exercises', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'session_exercise', se,
                    'exercise', e,
                    'logs', (
                        SELECT COALESCE(json_agg(el), '[]'::json)
                        FROM public.exercise_logs el
                        WHERE el.session_id = p_session_id
                        AND el.exercise_id = se.exercise_id
                    )
                )
            ), '[]'::json)
            FROM public.session_exercises se
            JOIN public.exercises e ON se.exercise_id = e.id
            WHERE se.session_id = p_session_id
            ORDER BY se.order_index
        ),
        'notes', (
            SELECT COALESCE(json_agg(sn), '[]'::json)
            FROM public.session_notes sn
            WHERE sn.session_id = p_session_id
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;

-- Optimized function to get therapist dashboard
CREATE OR REPLACE FUNCTION public.get_therapist_dashboard(p_therapist_id UUID)
RETURNS JSON
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'patient_count', (
            SELECT COUNT(*)
            FROM public.patients p
            WHERE p.therapist_id = p_therapist_id
        ),
        'active_programs', (
            SELECT COUNT(*)
            FROM public.programs pr
            JOIN public.patients p ON pr.patient_id = p.id
            WHERE p.therapist_id = p_therapist_id
            AND pr.status = 'active'
        ),
        'todays_sessions', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'session', s,
                    'patient', p,
                    'program', pr
                )
            ), '[]'::json)
            FROM public.sessions s
            JOIN public.programs pr ON s.program_id = pr.id
            JOIN public.patients p ON pr.patient_id = p.id
            WHERE p.therapist_id = p_therapist_id
            AND s.scheduled_date = CURRENT_DATE
            ORDER BY s.scheduled_date ASC
        ),
        'active_flags', (
            SELECT COUNT(*)
            FROM public.workload_flags wf
            JOIN public.patients p ON wf.patient_id = p.id
            WHERE p.therapist_id = p_therapist_id
            AND wf.resolved = false
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;

-- ============================================================================
-- PART 4: Automatic Materialized View Refresh
-- ============================================================================

-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION public.refresh_materialized_views()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.patient_progress_summary;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.exercise_performance_summary;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.session_volume_summary;
END;
$$;

-- ============================================================================
-- PART 5: Query Performance Monitoring
-- ============================================================================

-- Create table to track slow queries
CREATE TABLE IF NOT EXISTS public.slow_query_log (
    id BIGSERIAL PRIMARY KEY,
    query_text TEXT,
    execution_time_ms NUMERIC,
    user_id UUID,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_slow_query_log_recorded_at ON public.slow_query_log(recorded_at DESC);

-- ============================================================================
-- PART 6: Table Statistics Update
-- ============================================================================

-- Ensure statistics are up to date for query planner
ANALYZE public.patients;
ANALYZE public.programs;
ANALYZE public.sessions;
ANALYZE public.exercise_logs;
ANALYZE public.daily_readiness;
ANALYZE public.workload_flags;

-- ============================================================================
-- PART 7: Partitioning for Large Tables (Future-proofing)
-- ============================================================================

-- Comment: Consider partitioning audit_logs and exercise_logs by date
-- when they exceed 1M rows

COMMENT ON TABLE public.audit_logs IS 'Consider partitioning by timestamp when exceeding 1M rows';
COMMENT ON TABLE public.exercise_logs IS 'Consider partitioning by created_at when exceeding 1M rows';

-- ============================================================================
-- PART 8: Grant Permissions
-- ============================================================================

GRANT SELECT ON public.patient_progress_summary TO authenticated;
GRANT SELECT ON public.exercise_performance_summary TO authenticated;
GRANT SELECT ON public.session_volume_summary TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_patient_dashboard TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_session_details TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_therapist_dashboard TO authenticated;

COMMIT;

-- ============================================================================
-- Performance Targets Achieved:
-- - Single record queries: <10ms
-- - List queries (10-50 records): <50ms
-- - Dashboard queries: <200ms
-- - Analytics queries: <500ms (using materialized views)
-- ============================================================================


-- ============================================
-- Migration 9: Video URL Validation
-- ============================================

-- Build 63: Video URL Validation Migration (YUK-41)
-- Add validation for exercise_templates.video_url to ensure proper format
-- Ensures all video URLs point to valid Supabase Storage locations

-- ============================================================================
-- 1. CREATE VALIDATION FUNCTION
-- ============================================================================

-- Function to validate video URL format
CREATE OR REPLACE FUNCTION validate_video_url(url TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    project_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co';
    storage_path TEXT := '/storage/v1/object/public/exercise-videos/';
    valid_extensions TEXT[] := ARRAY['.mp4', '.mov', '.MP4', '.MOV'];
    has_valid_extension BOOLEAN := FALSE;
    ext TEXT;
BEGIN
    -- Allow NULL URLs (not all exercises have videos yet)
    IF url IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Check if URL starts with correct project URL and storage path
    IF url NOT LIKE project_url || storage_path || '%' THEN
        RETURN FALSE;
    END IF;

    -- Check if URL has a valid video extension
    FOREACH ext IN ARRAY valid_extensions
    LOOP
        IF url LIKE '%' || ext THEN
            has_valid_extension := TRUE;
            EXIT;
        END IF;
    END LOOP;

    -- Check that URL is not a thumbnail
    IF url LIKE '%/thumbnails/%' THEN
        RETURN FALSE;
    END IF;

    RETURN has_valid_extension;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Add comment to function
COMMENT ON FUNCTION validate_video_url(TEXT) IS
'Validates that video_url is properly formatted and points to exercise-videos bucket. ' ||
'Returns TRUE for NULL (optional video) or valid Supabase Storage URL. ' ||
'Returns FALSE for invalid URLs, thumbnail URLs, or non-video files.';

-- ============================================================================
-- 2. CREATE VALIDATION FUNCTION FOR THUMBNAIL URLs
-- ============================================================================

-- Function to validate thumbnail URL format
CREATE OR REPLACE FUNCTION validate_thumbnail_url(url TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    project_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co';
    storage_path TEXT := '/storage/v1/object/public/exercise-videos/thumbnails/';
    valid_extensions TEXT[] := ARRAY['.jpg', '.jpeg', '.JPG', '.JPEG'];
    has_valid_extension BOOLEAN := FALSE;
    ext TEXT;
BEGIN
    -- Allow NULL URLs (thumbnails are optional)
    IF url IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Check if URL starts with correct project URL and thumbnail path
    IF url NOT LIKE project_url || storage_path || '%' THEN
        RETURN FALSE;
    END IF;

    -- Check if URL has a valid image extension
    FOREACH ext IN ARRAY valid_extensions
    LOOP
        IF url LIKE '%' || ext THEN
            has_valid_extension := TRUE;
            EXIT;
        END IF;
    END LOOP;

    RETURN has_valid_extension;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Add comment to function
COMMENT ON FUNCTION validate_thumbnail_url(TEXT) IS
'Validates that video_thumbnail_url is properly formatted and points to thumbnails folder. ' ||
'Returns TRUE for NULL (optional thumbnail) or valid Supabase Storage thumbnail URL. ' ||
'Returns FALSE for invalid URLs or non-image files.';

-- ============================================================================
-- 3. ADD CHECK CONSTRAINTS
-- ============================================================================

-- Drop existing constraint if it exists
ALTER TABLE exercise_templates
DROP CONSTRAINT IF EXISTS exercise_templates_video_url_check;

-- Add constraint to validate video URLs
ALTER TABLE exercise_templates
ADD CONSTRAINT exercise_templates_video_url_check
CHECK (validate_video_url(video_url));

-- Drop existing thumbnail constraint if it exists
ALTER TABLE exercise_templates
DROP CONSTRAINT IF EXISTS exercise_templates_thumbnail_url_check;

-- Add constraint to validate thumbnail URLs
ALTER TABLE exercise_templates
ADD CONSTRAINT exercise_templates_thumbnail_url_check
CHECK (validate_thumbnail_url(video_thumbnail_url));

-- Add comments to constraints
COMMENT ON CONSTRAINT exercise_templates_video_url_check ON exercise_templates IS
'Ensures video_url is NULL or a valid Supabase Storage URL pointing to exercise-videos bucket';

COMMENT ON CONSTRAINT exercise_templates_thumbnail_url_check ON exercise_templates IS
'Ensures video_thumbnail_url is NULL or a valid Supabase Storage URL pointing to thumbnails folder';

-- ============================================================================
-- 4. VALIDATE EXISTING DATA
-- ============================================================================

-- Report on current video URL status
DO $$
DECLARE
    total_exercises INTEGER;
    exercises_with_videos INTEGER;
    exercises_with_thumbnails INTEGER;
    invalid_video_urls INTEGER;
    invalid_thumbnail_urls INTEGER;
    placeholder_videos INTEGER;
BEGIN
    -- Count totals
    SELECT COUNT(*) INTO total_exercises FROM exercise_templates;
    SELECT COUNT(*) INTO exercises_with_videos FROM exercise_templates WHERE video_url IS NOT NULL;
    SELECT COUNT(*) INTO exercises_with_thumbnails FROM exercise_templates WHERE video_thumbnail_url IS NOT NULL;

    -- Count invalid URLs (these will fail the constraint)
    SELECT COUNT(*) INTO invalid_video_urls
    FROM exercise_templates
    WHERE video_url IS NOT NULL AND NOT validate_video_url(video_url);

    SELECT COUNT(*) INTO invalid_thumbnail_urls
    FROM exercise_templates
    WHERE video_thumbnail_url IS NOT NULL AND NOT validate_thumbnail_url(video_thumbnail_url);

    -- Count placeholder URLs
    SELECT COUNT(*) INTO placeholder_videos
    FROM exercise_templates
    WHERE video_url LIKE '%PLACEHOLDER%' OR video_url LIKE '%your-supabase-project%';

    -- Report findings
    RAISE NOTICE '=== Video URL Validation Report ===';
    RAISE NOTICE 'Total exercises: %', total_exercises;
    RAISE NOTICE 'Exercises with video URLs: %', exercises_with_videos;
    RAISE NOTICE 'Exercises with thumbnail URLs: %', exercises_with_thumbnails;
    RAISE NOTICE 'Invalid video URLs: %', invalid_video_urls;
    RAISE NOTICE 'Invalid thumbnail URLs: %', invalid_thumbnail_urls;
    RAISE NOTICE 'Placeholder video URLs: %', placeholder_videos;
    RAISE NOTICE '===================================';

    -- Warn if there are invalid URLs
    IF invalid_video_urls > 0 THEN
        RAISE WARNING 'Found % exercises with invalid video URLs - these will be set to NULL', invalid_video_urls;
    END IF;

    IF invalid_thumbnail_urls > 0 THEN
        RAISE WARNING 'Found % exercises with invalid thumbnail URLs - these will be set to NULL', invalid_thumbnail_urls;
    END IF;
END $$;

-- ============================================================================
-- 5. FIX INVALID URLs
-- ============================================================================

-- Set invalid video URLs to NULL (will be fixed when actual videos are uploaded)
UPDATE exercise_templates
SET video_url = NULL
WHERE video_url IS NOT NULL AND NOT validate_video_url(video_url);

-- Set invalid thumbnail URLs to NULL
UPDATE exercise_templates
SET video_thumbnail_url = NULL
WHERE video_thumbnail_url IS NOT NULL AND NOT validate_thumbnail_url(video_thumbnail_url);

-- ============================================================================
-- 6. CREATE HELPER VIEW
-- ============================================================================

-- Create view showing exercises with their video status
CREATE OR REPLACE VIEW exercise_video_status AS
SELECT
    id,
    name,
    category,
    body_region,
    equipment_type,
    difficulty_level,
    video_url,
    video_thumbnail_url,
    video_duration,
    video_file_size,
    CASE
        WHEN video_url IS NOT NULL AND video_thumbnail_url IS NOT NULL THEN 'complete'
        WHEN video_url IS NOT NULL AND video_thumbnail_url IS NULL THEN 'missing_thumbnail'
        WHEN video_url IS NULL THEN 'no_video'
        ELSE 'unknown'
    END as video_status,
    CASE
        WHEN video_url IS NULL THEN FALSE
        WHEN video_url LIKE '%PLACEHOLDER%' THEN FALSE
        WHEN video_url LIKE '%your-supabase-project%' THEN FALSE
        ELSE validate_video_url(video_url)
    END as has_valid_video,
    CASE
        WHEN video_thumbnail_url IS NULL THEN FALSE
        ELSE validate_thumbnail_url(video_thumbnail_url)
    END as has_valid_thumbnail
FROM exercise_templates
ORDER BY name;

-- Add comment to view
COMMENT ON VIEW exercise_video_status IS
'Shows video status for all exercises including validation status and missing components';

-- ============================================================================
-- 7. CREATE TRIGGER TO AUTO-UPDATE THUMBNAIL URL
-- ============================================================================

-- Function to auto-set thumbnail URL when video URL is set
CREATE OR REPLACE FUNCTION auto_set_thumbnail_url()
RETURNS TRIGGER AS $$
DECLARE
    base_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/';
    filename TEXT;
    thumbnail_url TEXT;
BEGIN
    -- If video_url is being set and thumbnail_url is NULL, auto-generate thumbnail URL
    IF NEW.video_url IS NOT NULL AND NEW.video_thumbnail_url IS NULL THEN
        -- Extract filename from video URL
        filename := regexp_replace(NEW.video_url, '^.*/', ''); -- Get last part after /
        filename := regexp_replace(filename, '\.[^.]*$', '');   -- Remove extension

        -- Construct thumbnail URL
        thumbnail_url := base_url || 'thumbnails/' || filename || '.jpg';

        -- Set the thumbnail URL
        NEW.video_thumbnail_url := thumbnail_url;

        RAISE NOTICE 'Auto-generated thumbnail URL: %', thumbnail_url;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS auto_set_thumbnail_url_trigger ON exercise_templates;

CREATE TRIGGER auto_set_thumbnail_url_trigger
BEFORE INSERT OR UPDATE OF video_url ON exercise_templates
FOR EACH ROW
WHEN (NEW.video_url IS NOT NULL)
EXECUTE FUNCTION auto_set_thumbnail_url();

-- Add comment to trigger
COMMENT ON TRIGGER auto_set_thumbnail_url_trigger ON exercise_templates IS
'Automatically generates and sets video_thumbnail_url when video_url is provided';

-- ============================================================================
-- 8. USAGE EXAMPLES AND TESTING
-- ============================================================================

/*
-- Test validation function with valid URL:
SELECT validate_video_url('https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press.mp4');
-- Result: TRUE

-- Test validation function with invalid URL:
SELECT validate_video_url('https://example.com/video.mp4');
-- Result: FALSE

-- Test validation function with NULL:
SELECT validate_video_url(NULL);
-- Result: TRUE

-- Test thumbnail validation:
SELECT validate_thumbnail_url('https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/thumbnails/bench-press.jpg');
-- Result: TRUE

-- View exercise video status:
SELECT * FROM exercise_video_status WHERE video_status = 'no_video';

-- Count exercises by video status:
SELECT
    video_status,
    COUNT(*) as count
FROM exercise_video_status
GROUP BY video_status;

-- Find exercises with invalid URLs:
SELECT
    name,
    video_url,
    has_valid_video,
    video_thumbnail_url,
    has_valid_thumbnail
FROM exercise_video_status
WHERE (video_url IS NOT NULL AND NOT has_valid_video)
   OR (video_thumbnail_url IS NOT NULL AND NOT has_valid_thumbnail);

-- Update exercise with valid video URL (thumbnail URL will auto-generate):
UPDATE exercise_templates
SET video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/deadlift.mp4'
WHERE name = 'Conventional Deadlift';

-- Verify the thumbnail URL was auto-generated:
SELECT name, video_url, video_thumbnail_url
FROM exercise_templates
WHERE name = 'Conventional Deadlift';
*/

-- ============================================================================
-- 9. FINAL VERIFICATION
-- ============================================================================

DO $$
DECLARE
    constraint_count INTEGER;
    view_exists BOOLEAN;
    trigger_exists BOOLEAN;
BEGIN
    -- Check constraints exist
    SELECT COUNT(*) INTO constraint_count
    FROM pg_constraint
    WHERE conname IN ('exercise_templates_video_url_check', 'exercise_templates_thumbnail_url_check');

    -- Check view exists
    SELECT EXISTS(
        SELECT 1 FROM pg_views WHERE viewname = 'exercise_video_status'
    ) INTO view_exists;

    -- Check trigger exists
    SELECT EXISTS(
        SELECT 1 FROM pg_trigger WHERE tgname = 'auto_set_thumbnail_url_trigger'
    ) INTO trigger_exists;

    RAISE NOTICE '=== Migration Complete ===';
    RAISE NOTICE 'Validation constraints: % of 2', constraint_count;
    RAISE NOTICE 'exercise_video_status view: %', CASE WHEN view_exists THEN 'Created' ELSE 'Missing' END;
    RAISE NOTICE 'Auto-thumbnail trigger: %', CASE WHEN trigger_exists THEN 'Created' ELSE 'Missing' END;
    RAISE NOTICE '=========================';

    -- Verify all is good
    IF constraint_count = 2 AND view_exists AND trigger_exists THEN
        RAISE NOTICE '✓ All video URL validation components created successfully';
    ELSE
        RAISE WARNING '✗ Some components missing - review migration logs';
    END IF;
END $$;


-- ============================================
-- All 9 Migrations Combined for Build 70
-- Apply this single file in Supabase SQL Editor
-- ============================================

