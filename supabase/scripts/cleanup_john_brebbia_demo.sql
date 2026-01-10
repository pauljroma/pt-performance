-- ============================================================================
-- CLEANUP SCRIPT: John Brebbia Demo Account
-- ============================================================================
-- Purpose: Clean up all session data and activity for John Brebbia demo account
--          while preserving the patient, therapist, program, and phase structure.
--
-- What this script does:
-- ✅ KEEPS: Patient record, Therapist record, Program, Phases, Sessions (structure)
-- ❌ DELETES: Exercise logs, Pain logs, Bullpen logs, Body comp, AI chats, Messages,
--             Session status, Scheduled sessions, Readiness adjustments, etc.
--
-- Result: Clean demo account ready for fresh demonstration
-- ============================================================================

-- Define the patient ID for John Brebbia
DO $$
DECLARE
  v_patient_id uuid := '00000000-0000-0000-0000-000000000001'::uuid;
  v_therapist_id uuid := '00000000-0000-0000-0000-000000000100'::uuid;
  v_patient_email text := 'demo-athlete@ptperformance.app';
  v_therapist_email text := 'demo-pt@ptperformance.app';

  -- Counters for reporting
  exercise_logs_deleted int;
  pain_logs_deleted int;
  bullpen_logs_deleted int;
  plyo_logs_deleted int;
  body_comp_deleted int;
  session_status_deleted int;
  session_notes_deleted int;
  pain_flags_deleted int;
  scheduled_sessions_deleted int;
  ai_conversations_deleted int;
  messages_deleted int;
  readiness_adjustments_deleted int;
  workout_events_deleted int;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'JOHN BREBBIA DEMO ACCOUNT CLEANUP';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Patient ID: %', v_patient_id;
  RAISE NOTICE 'Patient Email: %', v_patient_email;
  RAISE NOTICE '';

  -- ============================================================================
  -- 1. DELETE EXERCISE LOGS
  -- ============================================================================
  DELETE FROM exercise_logs WHERE patient_id = v_patient_id;
  GET DIAGNOSTICS exercise_logs_deleted = ROW_COUNT;
  RAISE NOTICE '✓ Deleted % exercise logs', exercise_logs_deleted;

  -- ============================================================================
  -- 2. DELETE PAIN LOGS
  -- ============================================================================
  DELETE FROM pain_logs WHERE patient_id = v_patient_id;
  GET DIAGNOSTICS pain_logs_deleted = ROW_COUNT;
  RAISE NOTICE '✓ Deleted % pain logs', pain_logs_deleted;

  -- ============================================================================
  -- 3. DELETE BULLPEN LOGS (THROWING DATA)
  -- ============================================================================
  DELETE FROM bullpen_logs WHERE patient_id = v_patient_id;
  GET DIAGNOSTICS bullpen_logs_deleted = ROW_COUNT;
  RAISE NOTICE '✓ Deleted % bullpen logs', bullpen_logs_deleted;

  -- ============================================================================
  -- 4. DELETE PLYO LOGS (if table exists)
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'plyo_logs') THEN
    DELETE FROM plyo_logs WHERE patient_id = v_patient_id;
    GET DIAGNOSTICS plyo_logs_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % plyo logs', plyo_logs_deleted;
  ELSE
    plyo_logs_deleted := 0;
    RAISE NOTICE '- Plyo logs table does not exist (skipped)';
  END IF;

  -- ============================================================================
  -- 5. DELETE BODY COMPOSITION MEASUREMENTS
  -- ============================================================================
  DELETE FROM body_comp_measurements WHERE patient_id = v_patient_id;
  GET DIAGNOSTICS body_comp_deleted = ROW_COUNT;
  RAISE NOTICE '✓ Deleted % body composition measurements', body_comp_deleted;

  -- ============================================================================
  -- 6. DELETE SESSION STATUS (COMPLETED SESSIONS)
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'session_status') THEN
    DELETE FROM session_status WHERE patient_id = v_patient_id;
    GET DIAGNOSTICS session_status_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % session status records', session_status_deleted;
  ELSE
    session_status_deleted := 0;
    RAISE NOTICE '- Session status table does not exist (skipped)';
  END IF;

  -- ============================================================================
  -- 7. DELETE SESSION NOTES
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'session_notes') THEN
    DELETE FROM session_notes
    WHERE session_id IN (
      SELECT s.id FROM sessions s
      JOIN phases ph ON s.phase_id = ph.id
      JOIN programs pr ON ph.program_id = pr.id
      WHERE pr.patient_id = v_patient_id
    );
    GET DIAGNOSTICS session_notes_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % session notes', session_notes_deleted;
  ELSE
    session_notes_deleted := 0;
    RAISE NOTICE '- Session notes table does not exist (skipped)';
  END IF;

  -- ============================================================================
  -- 8. DELETE PAIN FLAGS
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pain_flags') THEN
    DELETE FROM pain_flags WHERE patient_id = v_patient_id;
    GET DIAGNOSTICS pain_flags_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % pain flags', pain_flags_deleted;
  ELSE
    pain_flags_deleted := 0;
    RAISE NOTICE '- Pain flags table does not exist (skipped)';
  END IF;

  -- ============================================================================
  -- 9. DELETE SCHEDULED SESSIONS
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'scheduled_sessions') THEN
    DELETE FROM scheduled_sessions WHERE patient_id = v_patient_id;
    GET DIAGNOSTICS scheduled_sessions_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % scheduled sessions', scheduled_sessions_deleted;
  ELSE
    scheduled_sessions_deleted := 0;
    RAISE NOTICE '- Scheduled sessions table does not exist (skipped)';
  END IF;

  -- ============================================================================
  -- 10. DELETE AI CONVERSATIONS
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ai_conversations') THEN
    DELETE FROM ai_conversations WHERE patient_id = v_patient_id;
    GET DIAGNOSTICS ai_conversations_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % AI conversations', ai_conversations_deleted;
  ELSE
    ai_conversations_deleted := 0;
    RAISE NOTICE '- AI conversations table does not exist (skipped)';
  END IF;

  -- ============================================================================
  -- 11. DELETE MESSAGES (PATIENT & THERAPIST)
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'messages') THEN
    -- Delete messages where patient is sender or recipient
    DELETE FROM messages
    WHERE sender_id IN (
      SELECT user_id FROM patients WHERE id = v_patient_id
      UNION
      SELECT user_id FROM therapists WHERE id = v_therapist_id
    )
    OR recipient_id IN (
      SELECT user_id FROM patients WHERE id = v_patient_id
      UNION
      SELECT user_id FROM therapists WHERE id = v_therapist_id
    );
    GET DIAGNOSTICS messages_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % messages', messages_deleted;
  ELSE
    messages_deleted := 0;
    RAISE NOTICE '- Messages table does not exist (skipped)';
  END IF;

  -- ============================================================================
  -- 12. DELETE READINESS ADJUSTMENTS
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'readiness_adjustments') THEN
    DELETE FROM readiness_adjustments WHERE patient_id = v_patient_id;
    GET DIAGNOSTICS readiness_adjustments_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % readiness adjustments', readiness_adjustments_deleted;
  ELSE
    readiness_adjustments_deleted := 0;
    RAISE NOTICE '- Readiness adjustments table does not exist (skipped)';
  END IF;

  -- ============================================================================
  -- 13. DELETE WORKOUT EVENTS
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'workout_events') THEN
    DELETE FROM workout_events WHERE patient_id = v_patient_id;
    GET DIAGNOSTICS workout_events_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % workout events', workout_events_deleted;
  ELSE
    workout_events_deleted := 0;
    RAISE NOTICE '- Workout events table does not exist (skipped)';
  END IF;

  -- ============================================================================
  -- 14. DELETE WHOOP DATA (if exists)
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whoop_sleep_data') THEN
    DELETE FROM whoop_sleep_data WHERE patient_id = v_patient_id;
    RAISE NOTICE '✓ Deleted WHOOP sleep data';
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whoop_recovery_data') THEN
    DELETE FROM whoop_recovery_data WHERE patient_id = v_patient_id;
    RAISE NOTICE '✓ Deleted WHOOP recovery data';
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whoop_workout_data') THEN
    DELETE FROM whoop_workout_data WHERE patient_id = v_patient_id;
    RAISE NOTICE '✓ Deleted WHOOP workout data';
  END IF;

  -- ============================================================================
  -- 15. DELETE WORKLOAD FLAGS (if exists)
  -- ============================================================================
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'workload_flags') THEN
    DELETE FROM workload_flags WHERE patient_id = v_patient_id;
    RAISE NOTICE '✓ Deleted workload flags';
  END IF;

  -- ============================================================================
  -- SUMMARY REPORT
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'CLEANUP SUMMARY';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Exercise Logs:         %', exercise_logs_deleted;
  RAISE NOTICE 'Pain Logs:             %', pain_logs_deleted;
  RAISE NOTICE 'Bullpen Logs:          %', bullpen_logs_deleted;
  RAISE NOTICE 'Plyo Logs:             %', plyo_logs_deleted;
  RAISE NOTICE 'Body Comp:             %', body_comp_deleted;
  RAISE NOTICE 'Session Status:        %', session_status_deleted;
  RAISE NOTICE 'Session Notes:         %', session_notes_deleted;
  RAISE NOTICE 'Pain Flags:            %', pain_flags_deleted;
  RAISE NOTICE 'Scheduled Sessions:    %', scheduled_sessions_deleted;
  RAISE NOTICE 'AI Conversations:      %', ai_conversations_deleted;
  RAISE NOTICE 'Messages:              %', messages_deleted;
  RAISE NOTICE 'Readiness Adjustments: %', readiness_adjustments_deleted;
  RAISE NOTICE 'Workout Events:        %', workout_events_deleted;
  RAISE NOTICE '';
  RAISE NOTICE '✅ CLEANUP COMPLETE!';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'PRESERVED DATA (READY FOR DEMO)';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Patient: John Brebbia (demo-athlete@ptperformance.app)';
  RAISE NOTICE 'Therapist: Sarah Thompson (demo-pt@ptperformance.app)';
  RAISE NOTICE 'Program: 8-Week On-Ramp (4 phases, 24 sessions)';
  RAISE NOTICE 'Login: demo-athlete@ptperformance.app / password123';
  RAISE NOTICE '';
  RAISE NOTICE 'The account is now clean and ready for demonstration!';
  RAISE NOTICE '========================================';

END $$;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify cleanup
SELECT 'Patient' as entity, count(*) as count FROM patients WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
UNION ALL
SELECT 'Therapist', count(*) FROM therapists WHERE id = '00000000-0000-0000-0000-000000000100'::uuid
UNION ALL
SELECT 'Programs', count(*) FROM programs WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
UNION ALL
SELECT 'Phases', count(*) FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000200'::uuid
UNION ALL
SELECT 'Sessions', count(*) FROM sessions WHERE phase_id IN (
  SELECT id FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000200'::uuid
)
UNION ALL
SELECT 'Exercise Logs (should be 0)', count(*) FROM exercise_logs WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
UNION ALL
SELECT 'Pain Logs (should be 0)', count(*) FROM pain_logs WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
UNION ALL
SELECT 'Bullpen Logs (should be 0)', count(*) FROM bullpen_logs WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid;
