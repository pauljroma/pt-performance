-- Fix therapist and patient auth linkage

-- 1. Link therapist to auth.users
UPDATE therapists t
SET user_id = au.id
FROM auth.users au
WHERE t.email = au.email
  AND t.user_id IS NULL
  AND t.email = 'demo-pt@ptperformance.app';

-- 2. Link patient to auth.users (should already be done, but ensure)
UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.user_id IS NULL
  AND p.email = 'demo-athlete@ptperformance.app';

-- 3. Link patient to therapist (should already be done, but ensure)
UPDATE patients p
SET therapist_id = t.id
FROM therapists t
WHERE p.email = 'demo-athlete@ptperformance.app'
  AND t.email = 'demo-pt@ptperformance.app'
  AND (p.therapist_id IS NULL OR p.therapist_id != t.id);

-- 4. Verification query
DO $$
DECLARE
  therapist_linked BOOLEAN;
  patient_linked BOOLEAN;
  patient_has_therapist BOOLEAN;
BEGIN
  SELECT user_id IS NOT NULL INTO therapist_linked
  FROM therapists WHERE email = 'demo-pt@ptperformance.app';

  SELECT user_id IS NOT NULL INTO patient_linked
  FROM patients WHERE email = 'demo-athlete@ptperformance.app';

  SELECT therapist_id IS NOT NULL INTO patient_has_therapist
  FROM patients WHERE email = 'demo-athlete@ptperformance.app';

  RAISE NOTICE 'Therapist linked to auth: %', therapist_linked;
  RAISE NOTICE 'Patient linked to auth: %', patient_linked;
  RAISE NOTICE 'Patient has therapist: %', patient_has_therapist;
END $$;
