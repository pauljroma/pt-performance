-- Create patient record for auth user first
INSERT INTO patients (id, email, first_name, last_name, therapist_id, created_at)
VALUES (
  'bc9d4832-f338-47d6-b5bb-92b118991ded',
  'john.brebbia@demo.com',  -- Use different email to avoid conflict
  'John',
  'Brebbia',
  '00000000-0000-0000-0000-000000000100',
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  first_name = 'John',
  last_name = 'Brebbia';

-- Copy body comp data to auth user
INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, lean_mass_lb)
SELECT 
  'bc9d4832-f338-47d6-b5bb-92b118991ded'::uuid,
  measured_at,
  weight_lb,
  body_fat_pct,
  lean_mass_lb
FROM body_comp_measurements
WHERE patient_id = '00000000-0000-0000-0000-000000000001'
  AND measured_at >= '2025-10-06'
ON CONFLICT DO NOTHING;
