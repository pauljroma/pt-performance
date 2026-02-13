-- ============================================================================
-- FIX PATIENTS TABLE ANON WRITE ACCESS
-- ============================================================================
-- Problem: "permission denied for patient tables" when saving mode in demo
-- Root cause: anon role only has SELECT, not INSERT/UPDATE on patients
-- Solution: Add INSERT/UPDATE policies for anon role (demo patient only)
-- ============================================================================

-- ============================================================================
-- STEP 1: Add UPDATE policy for anon on patients (demo patient only)
-- ============================================================================

DROP POLICY IF EXISTS "patients_anon_update" ON patients;
CREATE POLICY "patients_anon_update"
    ON patients FOR UPDATE
    TO anon
    USING (id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (id = '00000000-0000-0000-0000-000000000001'::uuid);

-- ============================================================================
-- STEP 2: Add INSERT policy for anon on patients (restricted)
-- ============================================================================

DROP POLICY IF EXISTS "patients_anon_insert" ON patients;
CREATE POLICY "patients_anon_insert"
    ON patients FOR INSERT
    TO anon
    WITH CHECK (id = '00000000-0000-0000-0000-000000000001'::uuid);

-- ============================================================================
-- STEP 3: Grant permissions
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON patients TO anon;

-- ============================================================================
-- STEP 4: Force schema reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    policy_count INT;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'patients'
      AND policyname LIKE '%anon%';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Patients Anon Write Access Fix Complete';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Anon policies on patients table: %', policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Demo patient can now:';
    RAISE NOTICE '  - SELECT (read patient data)';
    RAISE NOTICE '  - UPDATE (save mode changes)';
    RAISE NOTICE '  - INSERT (if needed)';
    RAISE NOTICE '============================================';
END $$;
