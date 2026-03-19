-- Update demo account passwords for Apple App Review compliance
-- Previous password (password123) doesn't meet client validation rules
-- New password: Modus2026! (8+ chars, uppercase, number, special char)

-- Update demo therapist password
UPDATE auth.users
SET encrypted_password = crypt('Modus2026!', gen_salt('bf')),
    updated_at = now()
WHERE email = 'demo-pt@ptperformance.app';

-- Update demo patient password (keep consistent)
UPDATE auth.users
SET encrypted_password = crypt('Modus2026!', gen_salt('bf')),
    updated_at = now()
WHERE email = 'demo-athlete@ptperformance.app';

-- Re-verify therapist linkage (ensure user_id is set)
UPDATE therapists t
SET user_id = au.id
FROM auth.users au
WHERE t.email = au.email
  AND t.email = 'demo-pt@ptperformance.app'
  AND (t.user_id IS NULL OR t.user_id != au.id);

-- Re-verify patient linkage
UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.email = 'demo-athlete@ptperformance.app'
  AND (p.user_id IS NULL OR p.user_id != au.id);

-- Verification
DO $$
DECLARE
  v_therapist_linked BOOLEAN;
  v_patient_linked BOOLEAN;
BEGIN
  SELECT user_id IS NOT NULL INTO v_therapist_linked
  FROM therapists WHERE email = 'demo-pt@ptperformance.app';

  SELECT user_id IS NOT NULL INTO v_patient_linked
  FROM patients WHERE email = 'demo-athlete@ptperformance.app';

  RAISE NOTICE 'Therapist (demo-pt@) linked: %', COALESCE(v_therapist_linked, false);
  RAISE NOTICE 'Patient (demo-athlete@) linked: %', COALESCE(v_patient_linked, false);
  RAISE NOTICE 'New credentials: demo-pt@ptperformance.app / Modus2026!';
END $$;
