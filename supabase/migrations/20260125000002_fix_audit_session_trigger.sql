-- ============================================================================
-- FIX AUDIT SESSION TRIGGER - program_id ERROR
-- ============================================================================
-- BUILD 278: Fix "Record 'new' has no field for program_id" error
--
-- Issue: The audit_session_changes() trigger function tries to access
-- NEW.program_id, but the sessions table has phase_id, not program_id.
-- Need to join through phases table to get the program_id.
-- ============================================================================

-- Drop and recreate the trigger function with correct column reference
CREATE OR REPLACE FUNCTION public.audit_session_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_patient_id UUID;
    v_phase_id UUID;
BEGIN
    -- Get phase_id from the session record (sessions has phase_id, not program_id)
    v_phase_id := COALESCE(NEW.phase_id, OLD.phase_id);

    -- Get patient_id by joining through phases -> programs
    IF v_phase_id IS NOT NULL THEN
        SELECT pr.patient_id INTO v_patient_id
        FROM public.phases ph
        INNER JOIN public.programs pr ON pr.id = ph.program_id
        WHERE ph.id = v_phase_id;
    END IF;

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

-- Re-enable the trigger if it was disabled
ALTER TABLE sessions ENABLE TRIGGER audit_session_changes_trigger;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'BUILD 278: AUDIT SESSION TRIGGER FIXED';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'FIXED:';
  RAISE NOTICE '  - Changed NEW.program_id → NEW.phase_id';
  RAISE NOTICE '  - Added join through phases table to get program_id';
  RAISE NOTICE '  - Re-enabled audit_session_changes_trigger';
  RAISE NOTICE '';
  RAISE NOTICE 'Now patients can complete prescribed sessions!';
  RAISE NOTICE '========================================================================';
END $$;
