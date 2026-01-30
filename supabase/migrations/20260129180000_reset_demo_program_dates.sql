-- Reset demo patient data for current date testing
-- Demo patient: John Brebbia (00000000-0000-0000-0000-000000000001)

-- Step 1: Update program dates to span today
UPDATE programs
SET
  start_date = CURRENT_DATE - INTERVAL '7 days',
  end_date = CURRENT_DATE + INTERVAL '8 weeks',
  status = 'active'
WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Step 2: Update phases to align with current dates
UPDATE phases
SET
  start_date = CURRENT_DATE - INTERVAL '7 days' + ((sequence - 1) * INTERVAL '2 weeks'),
  end_date = CURRENT_DATE - INTERVAL '7 days' + (sequence * INTERVAL '2 weeks')
WHERE program_id IN (
  SELECT id FROM programs WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
);

-- Step 3: Remove any existing scheduled session for demo patient for today
DELETE FROM scheduled_sessions
WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
AND scheduled_date = CURRENT_DATE;

-- Step 4: Schedule first session (Week 1 - Session 1) for today
INSERT INTO scheduled_sessions (
  patient_id,
  session_id,
  scheduled_date,
  scheduled_time,
  status
)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '00000000-0000-0000-0000-000000000401'::uuid,  -- Week 1 - Session 1
  CURRENT_DATE,
  '09:00:00'::time,
  'scheduled'
)
ON CONFLICT (patient_id, session_id, scheduled_date) DO UPDATE
SET status = 'scheduled', scheduled_time = '09:00:00'::time;
