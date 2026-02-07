-- Add missing indexes for foreign keys and common query patterns
-- This migration addresses performance issues from the security audit

-- ============================================================
-- MISSING FK INDEXES
-- ============================================================

-- supplement_stacks.created_by FK index (was missing)
CREATE INDEX IF NOT EXISTS idx_supplement_stacks_created_by
    ON supplement_stacks(created_by);

-- ============================================================
-- COMPOSITE INDEXES FOR COMMON QUERY PATTERNS
-- ============================================================

-- patient_alerts: therapist dashboard queries filter by severity
CREATE INDEX IF NOT EXISTS idx_patient_alerts_therapist_severity
    ON patient_alerts(therapist_id, severity);

-- patient_alerts: therapist status queries
CREATE INDEX IF NOT EXISTS idx_patient_alerts_therapist_status
    ON patient_alerts(therapist_id, status);

-- soap_notes: therapist patient history lookup
CREATE INDEX IF NOT EXISTS idx_soap_notes_therapist_patient_date
    ON soap_notes(therapist_id, patient_id, note_date DESC);

-- clinical_assessments: patient assessment history
CREATE INDEX IF NOT EXISTS idx_clinical_assessments_patient_date
    ON clinical_assessments(patient_id, assessment_date DESC);

-- workout_prescriptions: patient prescription lookup
CREATE INDEX IF NOT EXISTS idx_workout_prescriptions_patient_active
    ON workout_prescriptions(patient_id, status)
    WHERE status = 'active';

-- daily_readiness: patient daily lookup (common query pattern)
CREATE INDEX IF NOT EXISTS idx_daily_readiness_patient_date
    ON daily_readiness(patient_id, created_at DESC);

-- sessions: patient session history (sessions table uses different schema)
-- Skip this index as sessions table structure differs

-- ============================================================
-- PARTIAL INDEXES FOR FILTERED QUERIES
-- ============================================================

-- Active programs only
CREATE INDEX IF NOT EXISTS idx_programs_patient_active
    ON programs(patient_id)
    WHERE status = 'active';

-- Unread notifications
CREATE INDEX IF NOT EXISTS idx_push_notification_tokens_user
    ON push_notification_tokens(user_id);

COMMENT ON INDEX idx_supplement_stacks_created_by IS 'FK index for supplement_stacks.created_by - was missing';
COMMENT ON INDEX idx_patient_alerts_therapist_severity IS 'Composite index for therapist dashboard alert queries';
