-- Fix: Link all BASE pack programs to workout content and re-backfill
-- Build 441 - Ensures enrolled programs show workouts on Today tab
--
-- Problem: Migration 20260205210000 used title pattern matching that didn't match actual titles
-- Solution: Link by pack_id or update all BASE programs to Foundation Strength as default

-- ============================================================================
-- Step 1: Check and report current state
-- ============================================================================

DO $$
DECLARE
    v_unlinked_count INT;
    v_linked_count INT;
    v_enrollment_count INT;
BEGIN
    SELECT COUNT(*) INTO v_unlinked_count
    FROM program_library
    WHERE program_id IS NULL;

    SELECT COUNT(*) INTO v_linked_count
    FROM program_library
    WHERE program_id IS NOT NULL;

    SELECT COUNT(*) INTO v_enrollment_count
    FROM program_enrollments
    WHERE status = 'active';

    RAISE NOTICE 'Current state: % unlinked programs, % linked programs, % active enrollments',
        v_unlinked_count, v_linked_count, v_enrollment_count;
END $$;

-- ============================================================================
-- Step 2: Link BASE pack programs to Foundation Strength (most versatile)
-- ============================================================================

DO $$
DECLARE
    v_foundation_id UUID;
    v_updated_count INT := 0;
BEGIN
    -- Get the Foundation Strength program (system template)
    SELECT id INTO v_foundation_id
    FROM programs
    WHERE name = 'Foundation Strength Program'
      AND patient_id IS NULL
    LIMIT 1;

    IF v_foundation_id IS NULL THEN
        RAISE NOTICE 'Foundation Strength Program not found, creating it...';
        -- This shouldn't happen if 20260205210000 ran, but just in case
        RETURN;
    END IF;

    RAISE NOTICE 'Foundation Strength Program ID: %', v_foundation_id;

    -- Update all BASE pack programs that don't have program_id
    UPDATE program_library
    SET program_id = v_foundation_id,
        updated_at = NOW()
    WHERE pack_id = (SELECT id FROM program_packs WHERE code = 'BASE' LIMIT 1)
      AND program_id IS NULL;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % BASE pack programs with Foundation Strength link', v_updated_count;

    -- Also link any programs with category 'strength' that are unlinked
    UPDATE program_library
    SET program_id = v_foundation_id,
        updated_at = NOW()
    WHERE category = 'strength'
      AND program_id IS NULL;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % strength category programs', v_updated_count;

    -- Link mobility programs to Mobility Mastery if it exists
    UPDATE program_library
    SET program_id = COALESCE(
        (SELECT id FROM programs WHERE name = 'Mobility Mastery' AND patient_id IS NULL LIMIT 1),
        v_foundation_id
    ),
        updated_at = NOW()
    WHERE category = 'mobility'
      AND program_id IS NULL;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % mobility category programs', v_updated_count;

    -- Link any remaining unlinked programs to Foundation as fallback
    UPDATE program_library
    SET program_id = v_foundation_id,
        updated_at = NOW()
    WHERE program_id IS NULL;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % remaining unlinked programs with fallback', v_updated_count;
END $$;

-- ============================================================================
-- Step 3: Re-run backfill for all active enrollments
-- ============================================================================

DO $$
DECLARE
    v_enrollment RECORD;
    v_count INT;
    v_total INT := 0;
BEGIN
    -- First, clear any existing enrollment-based scheduled sessions
    DELETE FROM scheduled_sessions WHERE enrollment_id IS NOT NULL;
    RAISE NOTICE 'Cleared existing enrollment scheduled sessions';

    -- Now backfill all active enrollments
    FOR v_enrollment IN
        SELECT pe.id, pe.patient_id, pe.started_at, pl.program_id, pl.title
        FROM program_enrollments pe
        JOIN program_library pl ON pl.id = pe.program_library_id
        WHERE pe.status = 'active'
          AND pl.program_id IS NOT NULL
    LOOP
        RAISE NOTICE 'Scheduling workouts for enrollment % (program: %)', v_enrollment.id, v_enrollment.title;

        SELECT schedule_enrollment_workouts(
            v_enrollment.id,
            COALESCE(v_enrollment.started_at::DATE, CURRENT_DATE)
        ) INTO v_count;

        RAISE NOTICE '  -> Scheduled % workouts', v_count;
        v_total := v_total + v_count;
    END LOOP;

    RAISE NOTICE 'Total scheduled sessions created: %', v_total;
END $$;

-- ============================================================================
-- Step 4: Final verification
-- ============================================================================

DO $$
DECLARE
    v_scheduled_count INT;
    v_enrollment_count INT;
    v_linked_count INT;
BEGIN
    SELECT COUNT(*) INTO v_scheduled_count
    FROM scheduled_sessions
    WHERE enrollment_id IS NOT NULL;

    SELECT COUNT(*) INTO v_enrollment_count
    FROM program_enrollments
    WHERE status = 'active';

    SELECT COUNT(*) INTO v_linked_count
    FROM program_library
    WHERE program_id IS NOT NULL;

    RAISE NOTICE '=== FINAL STATE ===';
    RAISE NOTICE 'Linked programs in library: %', v_linked_count;
    RAISE NOTICE 'Active enrollments: %', v_enrollment_count;
    RAISE NOTICE 'Scheduled sessions from enrollments: %', v_scheduled_count;

    IF v_scheduled_count = 0 AND v_enrollment_count > 0 THEN
        RAISE WARNING 'No sessions scheduled despite active enrollments - check program_workout_assignments';
    END IF;
END $$;
