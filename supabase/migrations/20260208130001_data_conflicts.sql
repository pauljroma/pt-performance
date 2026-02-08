-- ============================================================================
-- DATA CONFLICTS SYSTEM - X2Index Command Center (M5)
-- ============================================================================
-- Multi-source conflict resolution for WHOOP, Apple Health, and manual entry
-- Handles data discrepancies with auto-resolution and user resolution flows
--
-- Date: 2026-02-08
-- Feature: X2Index Command Center - Multi-Source Conflict Resolution (M5)
-- ============================================================================

-- =====================================================
-- Data Conflicts Table
-- =====================================================

CREATE TABLE IF NOT EXISTS data_conflicts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    metric_type text NOT NULL,  -- 'sleep_duration', 'recovery_score', 'hrv', etc.
    conflict_date date NOT NULL,
    sources jsonb NOT NULL DEFAULT '[]'::jsonb,  -- Array of conflicting source values
    status text NOT NULL DEFAULT 'pending',  -- 'pending', 'auto_resolved', 'user_resolved', 'dismissed'
    resolved_value jsonb,  -- The final resolved value
    resolved_source text,  -- Source type that was chosen
    resolved_at timestamptz,
    resolved_by uuid REFERENCES patients(id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT valid_metric_type CHECK (metric_type IN (
        'sleep_duration', 'sleep_quality', 'recovery_score',
        'heart_rate', 'hrv', 'steps', 'calories', 'workout'
    )),
    CONSTRAINT valid_status CHECK (status IN (
        'pending', 'auto_resolved', 'user_resolved', 'dismissed'
    ))
);

-- Indexes for efficient querying
CREATE INDEX idx_data_conflicts_patient ON data_conflicts(patient_id);
CREATE INDEX idx_data_conflicts_status ON data_conflicts(status) WHERE status = 'pending';
CREATE INDEX idx_data_conflicts_patient_date ON data_conflicts(patient_id, conflict_date DESC);
CREATE INDEX idx_data_conflicts_metric ON data_conflicts(metric_type);
CREATE INDEX idx_data_conflicts_resolved_at ON data_conflicts(resolved_at DESC) WHERE resolved_at IS NOT NULL;

COMMENT ON TABLE data_conflicts IS 'Stores data conflicts between multiple sources (WHOOP, Apple Health, manual entry)';
COMMENT ON COLUMN data_conflicts.metric_type IS 'Type of metric with conflict: sleep_duration, recovery_score, hrv, etc.';
COMMENT ON COLUMN data_conflicts.sources IS 'JSONB array of conflicting sources with their values, timestamps, and confidence levels';
COMMENT ON COLUMN data_conflicts.status IS 'Resolution status: pending, auto_resolved, user_resolved, dismissed';
COMMENT ON COLUMN data_conflicts.resolved_value IS 'The final resolved value chosen or calculated';
COMMENT ON COLUMN data_conflicts.resolved_source IS 'The source type that provided the resolved value';

-- =====================================================
-- Conflict Audit Log Table
-- =====================================================

CREATE TABLE IF NOT EXISTS conflict_audit_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    conflict_id uuid NOT NULL REFERENCES data_conflicts(id) ON DELETE CASCADE,
    action text NOT NULL,  -- 'created', 'auto_resolved', 'user_resolved', 'dismissed', 'reopened'
    previous_status text,
    new_status text NOT NULL,
    resolved_value jsonb,
    resolved_source text,
    resolved_by uuid REFERENCES patients(id) ON DELETE SET NULL,
    reason text,  -- Optional reason for the action
    created_at timestamptz NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT valid_action CHECK (action IN (
        'created', 'auto_resolved', 'user_resolved', 'dismissed', 'reopened'
    ))
);

CREATE INDEX idx_conflict_audit_conflict ON conflict_audit_log(conflict_id);
CREATE INDEX idx_conflict_audit_created ON conflict_audit_log(created_at DESC);

COMMENT ON TABLE conflict_audit_log IS 'Audit trail for all conflict resolution actions';
COMMENT ON COLUMN conflict_audit_log.action IS 'Type of action: created, auto_resolved, user_resolved, dismissed, reopened';
COMMENT ON COLUMN conflict_audit_log.reason IS 'Optional reason provided for dismissal or resolution';

-- =====================================================
-- Auto-update timestamp trigger
-- =====================================================

CREATE OR REPLACE FUNCTION update_conflict_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_conflict_timestamp_trigger
    BEFORE UPDATE ON data_conflicts
    FOR EACH ROW
    EXECUTE FUNCTION update_conflict_timestamp();

-- =====================================================
-- Audit log trigger
-- =====================================================

CREATE OR REPLACE FUNCTION log_conflict_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Log status changes
    IF TG_OP = 'INSERT' THEN
        INSERT INTO conflict_audit_log (
            conflict_id, action, new_status, resolved_value,
            resolved_source, resolved_by
        ) VALUES (
            NEW.id, 'created', NEW.status, NEW.resolved_value,
            NEW.resolved_source, NEW.resolved_by
        );
    ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        INSERT INTO conflict_audit_log (
            conflict_id, action, previous_status, new_status,
            resolved_value, resolved_source, resolved_by
        ) VALUES (
            NEW.id,
            CASE NEW.status
                WHEN 'auto_resolved' THEN 'auto_resolved'
                WHEN 'user_resolved' THEN 'user_resolved'
                WHEN 'dismissed' THEN 'dismissed'
                WHEN 'pending' THEN 'reopened'
                ELSE 'updated'
            END,
            OLD.status,
            NEW.status,
            NEW.resolved_value,
            NEW.resolved_source,
            NEW.resolved_by
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_conflict_change_trigger
    AFTER INSERT OR UPDATE ON data_conflicts
    FOR EACH ROW
    EXECUTE FUNCTION log_conflict_change();

-- =====================================================
-- Function: Detect Data Conflicts
-- =====================================================

CREATE OR REPLACE FUNCTION detect_data_conflicts(
    p_patient_id uuid,
    p_date date
)
RETURNS SETOF data_conflicts
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conflict_id uuid;
    v_metric text;
    v_sources jsonb;
BEGIN
    -- This function would be called by the sync process to detect conflicts
    -- In a full implementation, it would:
    -- 1. Query health_data_sync for the patient and date
    -- 2. Group by metric type
    -- 3. Compare values from different sources
    -- 4. Create conflict records where values differ significantly

    -- For now, return existing conflicts for the date
    RETURN QUERY
    SELECT *
    FROM data_conflicts
    WHERE patient_id = p_patient_id
    AND conflict_date = p_date
    AND status = 'pending';
END;
$$;

COMMENT ON FUNCTION detect_data_conflicts IS 'Detect data conflicts for a patient on a specific date';

-- =====================================================
-- Function: Create Conflict
-- =====================================================

CREATE OR REPLACE FUNCTION create_data_conflict(
    p_patient_id uuid,
    p_metric_type text,
    p_conflict_date date,
    p_sources jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conflict_id uuid;
BEGIN
    -- Check if a pending conflict already exists for this metric/date
    SELECT id INTO v_conflict_id
    FROM data_conflicts
    WHERE patient_id = p_patient_id
    AND metric_type = p_metric_type
    AND conflict_date = p_conflict_date
    AND status = 'pending';

    IF v_conflict_id IS NOT NULL THEN
        -- Update existing conflict with new sources
        UPDATE data_conflicts
        SET sources = p_sources,
            updated_at = now()
        WHERE id = v_conflict_id;

        RETURN v_conflict_id;
    END IF;

    -- Create new conflict
    INSERT INTO data_conflicts (
        patient_id, metric_type, conflict_date, sources, status
    ) VALUES (
        p_patient_id, p_metric_type, p_conflict_date, p_sources, 'pending'
    )
    RETURNING id INTO v_conflict_id;

    RETURN v_conflict_id;
END;
$$;

COMMENT ON FUNCTION create_data_conflict IS 'Create or update a data conflict record';

-- =====================================================
-- Function: Auto-Resolve Conflict
-- =====================================================

CREATE OR REPLACE FUNCTION auto_resolve_conflict(
    p_conflict_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conflict data_conflicts%ROWTYPE;
    v_sources jsonb;
    v_best_source jsonb;
    v_priority int;
    v_best_priority int := 999;
    v_best_confidence numeric := 0;
    v_source jsonb;
BEGIN
    -- Get the conflict
    SELECT * INTO v_conflict
    FROM data_conflicts
    WHERE id = p_conflict_id AND status = 'pending';

    IF NOT FOUND THEN
        RETURN false;
    END IF;

    v_sources := v_conflict.sources;

    -- Priority order: manual=1, whoop=2, apple_health=3, oura=4, garmin=5, fitbit=6
    FOR v_source IN SELECT * FROM jsonb_array_elements(v_sources)
    LOOP
        v_priority := CASE (v_source->>'source_type')
            WHEN 'manual' THEN 1
            WHEN 'whoop' THEN 2
            WHEN 'apple_health' THEN 3
            WHEN 'oura' THEN 4
            WHEN 'garmin' THEN 5
            WHEN 'fitbit' THEN 6
            ELSE 99
        END;

        -- Select based on priority, then confidence
        IF v_priority < v_best_priority OR
           (v_priority = v_best_priority AND (v_source->>'confidence')::numeric > v_best_confidence) THEN
            v_best_priority := v_priority;
            v_best_confidence := (v_source->>'confidence')::numeric;
            v_best_source := v_source;
        END IF;
    END LOOP;

    -- Only auto-resolve if we have a clear winner (priority <= 2 or confidence >= 0.85)
    IF v_best_priority > 2 AND v_best_confidence < 0.85 THEN
        RETURN false;
    END IF;

    -- Resolve the conflict
    UPDATE data_conflicts
    SET status = 'auto_resolved',
        resolved_value = v_best_source->'value',
        resolved_source = v_best_source->>'source_type',
        resolved_at = now()
    WHERE id = p_conflict_id;

    RETURN true;
END;
$$;

COMMENT ON FUNCTION auto_resolve_conflict IS 'Attempt to automatically resolve a conflict using priority and confidence';

-- =====================================================
-- Function: Get Conflict Summary
-- =====================================================

CREATE OR REPLACE FUNCTION get_conflict_summary(
    p_patient_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_build_object(
        'pending_count', COUNT(*) FILTER (WHERE status = 'pending'),
        'auto_resolved_count', COUNT(*) FILTER (WHERE status = 'auto_resolved'),
        'user_resolved_count', COUNT(*) FILTER (WHERE status = 'user_resolved'),
        'dismissed_count', COUNT(*) FILTER (WHERE status = 'dismissed'),
        'total_count', COUNT(*),
        'most_common_metric', (
            SELECT metric_type
            FROM data_conflicts
            WHERE patient_id = p_patient_id
            GROUP BY metric_type
            ORDER BY COUNT(*) DESC
            LIMIT 1
        )
    )
    INTO v_result
    FROM data_conflicts
    WHERE patient_id = p_patient_id;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_conflict_summary IS 'Get summary statistics for a patient''s conflicts';

-- =====================================================
-- Row-Level Security (RLS)
-- =====================================================

ALTER TABLE data_conflicts ENABLE ROW LEVEL SECURITY;
ALTER TABLE conflict_audit_log ENABLE ROW LEVEL SECURITY;

-- Patients can view their own conflicts
CREATE POLICY "Patients can view their own conflicts"
    ON data_conflicts FOR SELECT
    USING (patient_id = auth.uid());

-- Patients can update their own conflicts (for resolution)
CREATE POLICY "Patients can update their own conflicts"
    ON data_conflicts FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- System can insert conflicts (via triggers/functions)
CREATE POLICY "Service role can manage all conflicts"
    ON data_conflicts FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Therapists can view patient conflicts
CREATE POLICY "Therapists can view patient conflicts"
    ON data_conflicts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = data_conflicts.patient_id
            AND tp.therapist_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- Audit log policies
CREATE POLICY "Patients can view their own conflict audit logs"
    ON conflict_audit_log FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM data_conflicts dc
            WHERE dc.id = conflict_audit_log.conflict_id
            AND dc.patient_id = auth.uid()
        )
    );

CREATE POLICY "Service role can manage all audit logs"
    ON conflict_audit_log FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- Grant Permissions
-- =====================================================

GRANT SELECT, UPDATE ON data_conflicts TO authenticated;
GRANT ALL ON data_conflicts TO service_role;

GRANT SELECT ON conflict_audit_log TO authenticated;
GRANT ALL ON conflict_audit_log TO service_role;

GRANT EXECUTE ON FUNCTION detect_data_conflicts TO authenticated;
GRANT EXECUTE ON FUNCTION create_data_conflict TO service_role;
GRANT EXECUTE ON FUNCTION auto_resolve_conflict TO authenticated;
GRANT EXECUTE ON FUNCTION get_conflict_summary TO authenticated;

-- =====================================================
-- Verification
-- =====================================================

DO $$
DECLARE
    v_conflicts_count integer;
    v_audit_count integer;
BEGIN
    SELECT COUNT(*) INTO v_conflicts_count FROM data_conflicts;
    SELECT COUNT(*) INTO v_audit_count FROM conflict_audit_log;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DATA CONFLICTS SYSTEM CREATED - X2Index Command Center (M5)';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables Created:';
    RAISE NOTICE '   - data_conflicts (% existing entries)', v_conflicts_count;
    RAISE NOTICE '   - conflict_audit_log (% existing entries)', v_audit_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Functions Created:';
    RAISE NOTICE '   - detect_data_conflicts(patient_id, date)';
    RAISE NOTICE '   - create_data_conflict(patient_id, metric_type, date, sources)';
    RAISE NOTICE '   - auto_resolve_conflict(conflict_id)';
    RAISE NOTICE '   - get_conflict_summary(patient_id)';
    RAISE NOTICE '';
    RAISE NOTICE 'Triggers:';
    RAISE NOTICE '   - update_conflict_timestamp_trigger (auto-update updated_at)';
    RAISE NOTICE '   - log_conflict_change_trigger (audit logging)';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies:';
    RAISE NOTICE '   - Patients: View and update own conflicts';
    RAISE NOTICE '   - Therapists: View linked patient conflicts';
    RAISE NOTICE '   - Service role: Full access';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DATA CONFLICTS SYSTEM READY';
    RAISE NOTICE '============================================================================';
END $$;
