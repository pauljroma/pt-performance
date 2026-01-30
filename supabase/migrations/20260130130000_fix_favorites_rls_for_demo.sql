-- BUILD 326: Fix Favorites RLS for Demo Mode
-- Purpose: Allow demo users (anon) to add/remove favorite templates
-- Issue: RLS policy only allowed authenticated users

-- ============================================================================
-- 1. ADD ANON RLS POLICIES FOR PATIENT_FAVORITE_TEMPLATES
-- ============================================================================

-- Allow anon to read favorites (for demo mode)
DROP POLICY IF EXISTS "patient_favorite_templates_anon_read" ON patient_favorite_templates;
CREATE POLICY "patient_favorite_templates_anon_read"
ON patient_favorite_templates
FOR SELECT
TO anon
USING (true);

-- Allow anon to insert favorites (for demo mode)
DROP POLICY IF EXISTS "patient_favorite_templates_anon_insert" ON patient_favorite_templates;
CREATE POLICY "patient_favorite_templates_anon_insert"
ON patient_favorite_templates
FOR INSERT
TO anon
WITH CHECK (true);

-- Allow anon to delete favorites (for demo mode)
DROP POLICY IF EXISTS "patient_favorite_templates_anon_delete" ON patient_favorite_templates;
CREATE POLICY "patient_favorite_templates_anon_delete"
ON patient_favorite_templates
FOR DELETE
TO anon
USING (true);

-- Grant permissions to anon role
GRANT SELECT, INSERT, DELETE ON patient_favorite_templates TO anon;

-- ============================================================================
-- 2. ALSO FIX PATIENT_WORKOUT_TEMPLATES FOR DEMO MODE
-- ============================================================================

-- Allow anon to read patient templates
DROP POLICY IF EXISTS "patient_workout_templates_anon_read" ON patient_workout_templates;
CREATE POLICY "patient_workout_templates_anon_read"
ON patient_workout_templates
FOR SELECT
TO anon
USING (true);

-- Allow anon to insert patient templates
DROP POLICY IF EXISTS "patient_workout_templates_anon_insert" ON patient_workout_templates;
CREATE POLICY "patient_workout_templates_anon_insert"
ON patient_workout_templates
FOR INSERT
TO anon
WITH CHECK (true);

-- Allow anon to update patient templates
DROP POLICY IF EXISTS "patient_workout_templates_anon_update" ON patient_workout_templates;
CREATE POLICY "patient_workout_templates_anon_update"
ON patient_workout_templates
FOR UPDATE
TO anon
USING (true);

-- Allow anon to delete patient templates
DROP POLICY IF EXISTS "patient_workout_templates_anon_delete" ON patient_workout_templates;
CREATE POLICY "patient_workout_templates_anon_delete"
ON patient_workout_templates
FOR DELETE
TO anon
USING (true);

-- Grant permissions to anon role
GRANT SELECT, INSERT, UPDATE, DELETE ON patient_workout_templates TO anon;

-- ============================================================================
-- 3. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    fav_policy_count INT;
    pt_policy_count INT;
BEGIN
    -- Count anon policies for favorites
    SELECT COUNT(*) INTO fav_policy_count
    FROM pg_policies
    WHERE tablename = 'patient_favorite_templates'
    AND policyname LIKE '%anon%';

    -- Count anon policies for patient templates
    SELECT COUNT(*) INTO pt_policy_count
    FROM pg_policies
    WHERE tablename = 'patient_workout_templates'
    AND policyname LIKE '%anon%';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'BUILD 326: Demo Mode RLS Policies Added';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'patient_favorite_templates anon policies: %', fav_policy_count;
    RAISE NOTICE 'patient_workout_templates anon policies: %', pt_policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Demo users can now:';
    RAISE NOTICE '  - Add/remove favorite templates';
    RAISE NOTICE '  - Create/edit/delete custom templates';
    RAISE NOTICE '============================================';
END $$;
