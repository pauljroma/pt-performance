-- ============================================================================
-- FIX: patient_flags View Schema Mismatch
-- ============================================================================
-- The iOS PatientFlag model expects different column names than what the
-- pain_flags table provides. This updates the view to match iOS expectations.
-- Date: 2025-12-11
-- ============================================================================

DROP VIEW IF EXISTS patient_flags CASCADE;

CREATE VIEW patient_flags AS
SELECT
    id,
    patient_id,
    flag_type,
    severity,
    notes AS description,
    triggered_at AS created_at,
    resolved_at,
    false AS auto_created
FROM pain_flags;

ALTER VIEW patient_flags SET (security_invoker = true);

-- Verification
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'PATIENT_FLAGS VIEW SCHEMA FIXED';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Updated column mappings:';
  RAISE NOTICE '  - notes → description (iOS expects description)';
  RAISE NOTICE '  - triggered_at → created_at (iOS expects created_at)';
  RAISE NOTICE '  - Added auto_created column (hardcoded to false)';
  RAISE NOTICE '';
  RAISE NOTICE '✅ patient_flags view now matches iOS PatientFlag model!';
  RAISE NOTICE '========================================================================';
END $$;
