# URGENT: Schema Fixes Required for Build 44

**Date:** 2025-12-14
**Priority:** 🔴 HIGH - App is experiencing errors
**Status:** Migration created, needs manual application

---

## Issues Found

Build 44 is experiencing 3 database schema errors:

### 1. Missing `severity` Column ❌
```
Error: column workload_flags.severity does not exist
Location: PatientListViewModel when loading workload flags
```

### 2. Null `phase_number` Values ❌
```
Error: Cannot get value of type Int -- found null value instead
Location: ProgramViewModel when decoding phases for Winter Lift program
```

### 3. Null `target_level` Values ❌
```
Error: Cannot get value of type String -- found null value instead
Location: TherapistProgramsView when loading programs list
```

---

## Solution

### Migration File Created
**File:** `supabase/migrations/20251214150000_fix_schema_issues.sql`

### Quick Fix (Run in Supabase SQL Editor)

**Go to:** https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new

**Copy and paste this SQL:**

```sql
-- Fix Schema Issues for Build 44
-- Fixes: Missing severity column, null phase_number, null target_level

-- 1. Add severity column to workload_flags table
ALTER TABLE workload_flags
ADD COLUMN IF NOT EXISTS severity TEXT DEFAULT 'medium';

-- Add check constraint for valid severity values
ALTER TABLE workload_flags
ADD CONSTRAINT severity_valid_values
CHECK (severity IN ('low', 'medium', 'high'));

-- Update existing workload flags to have severity
UPDATE workload_flags
SET severity = 'medium'
WHERE severity IS NULL;

-- Make severity NOT NULL
ALTER TABLE workload_flags
ALTER COLUMN severity SET NOT NULL;

-- 2. Update existing programs with null target_level
UPDATE programs
SET target_level = 'Intermediate'
WHERE target_level IS NULL;

-- Make target_level NOT NULL with default
ALTER TABLE programs
ALTER COLUMN target_level SET DEFAULT 'Intermediate';

-- 3. Update existing phases with null phase_number
UPDATE phases
SET phase_number = sequence
WHERE phase_number IS NULL;

-- Make phase_number NOT NULL with default
ALTER TABLE phases
ALTER COLUMN phase_number SET DEFAULT 1;

-- Verify fixes
SELECT
  'workload_flags' as table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'workload_flags' AND column_name = 'severity'
UNION ALL
SELECT
  'programs' as table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'programs' AND column_name = 'target_level'
UNION ALL
SELECT
  'phases' as table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'phases' AND column_name = 'phase_number';
```

**Click "RUN"**

---

## Expected Results

After running the migration:

```
workload_flags.severity: text NOT NULL (default: 'medium')
programs.target_level: text NOT NULL (default: 'Intermediate')
phases.phase_number: integer NOT NULL (default: 1)
```

---

## Verification

After applying the migration, restart the iOS app and verify:

1. ✅ No "column workload_flags.severity does not exist" errors
2. ✅ No "Cannot get value of type Int" errors when loading programs
3. ✅ No "Cannot get value of type String" errors in programs list
4. ✅ All 3 patients load successfully
5. ✅ Winter Lift program loads with all phases

---

## Impact

**Before Fix:**
- ❌ Workload flags fail to load
- ❌ Winter Lift program fails to load (Nic Roma's program)
- ❌ Programs list fails to load
- ❌ Partial app functionality

**After Fix:**
- ✅ All workload flags load successfully
- ✅ All programs load with proper target levels
- ✅ All phases load with proper phase numbers
- ✅ Full app functionality restored

---

## Root Cause

The `workload_flags` table was created in migration `20251213120001_create_workload_flags_table.sql` but the `severity` column was not included. The iOS models expect this column to exist.

Programs created before the `target_level` field was made required still have NULL values.

Phases created with only `sequence` field don't have `phase_number` set.

---

## After Applying Migration

Mark the migration as applied:

```bash
cd /Users/expo/Code/expo
touch supabase/migrations/20251214150000_fix_schema_issues.sql.applied
git add supabase/migrations/20251214150000_fix_schema_issues.sql*
git commit -m "fix(schema): Add severity column and fix null values

- Add severity column to workload_flags (fixes flag loading)
- Fix null target_level in programs (fixes programs list)
- Fix null phase_number in phases (fixes Winter Lift program)

Migration: 20251214150000_fix_schema_issues.sql
Build: 44 hotfix"
```

---

## Timeline

**Created:** 2025-12-14 08:04 PST
**Urgency:** Apply within 1 hour (before TestFlight testing)
**Estimated Time:** 2 minutes to apply + 30 seconds to verify

---

## Status

- [x] Migration file created
- [x] SQL executed in Supabase
- [x] Migration marked as applied
- [ ] App tested and verified
- [ ] Changes committed to Git

---

**Migration Applied:** 2025-12-14 08:07 PST via Python script
**Next Action:** Test Build 44 on device to verify all errors resolved

**SQL Editor URL:** https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new
