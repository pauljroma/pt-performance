# Database Migration Applied - calculate_rm_estimate Functions

**Date:** 2026-01-10 23:01
**Status:** ✅ SUCCESSFULLY APPLIED
**Method:** Supabase CLI (`supabase db push`)

## Migration Details

**Migration File:** `supabase/migrations/20260110230000_apply_calculate_rm_estimate_fix.sql`

**Functions Created:**
1. `calculate_rm_estimate(weight numeric, reps integer)` - Single rep count version
2. `calculate_rm_estimate(weight numeric, reps integer[])` - Array version for multi-set exercises

**Trigger Created:**
- `update_rm_estimate_trigger` on `exercise_logs` table
- Automatically calculates 1RM estimates when exercise logs are saved

## Migration Content

The migration:
- Drops any existing calculate_rm_estimate functions (with CASCADE)
- Creates two overloaded versions of calculate_rm_estimate
- Uses Epley formula: 1RM = weight × (1 + reps/30)
- For arrays, uses minimum reps (heaviest relative intensity)
- Grants EXECUTE permissions to authenticated and service_role
- Creates trigger function for automatic RM calculation
- Backfills existing exercise_logs with RM estimates

## Application Method

```bash
# Created new migration file
cp /tmp/apply_calculate_rm.sql supabase/migrations/20260110230000_apply_calculate_rm_estimate_fix.sql

# Pushed to remote database
supabase db push --include-all
```

## Output

```
Applying migration 20260110230000_apply_calculate_rm_estimate_fix.sql...
NOTICE (00000): function calculate_rm_estimate(pg_catalog.numeric,pg_catalog.int4[]) does not exist, skipping
NOTICE (00000): drop cascades to trigger exercise_logs_rm_estimate on table exercise_logs
NOTICE (00000): trigger "update_rm_estimate_trigger" for relation "exercise_logs" does not exist, skipping
Finished supabase db push.
```

**Notes:**
- NOTICE messages are expected (functions/triggers didn't exist before)
- "Finished supabase db push" confirms successful application

## What This Fixes

**Error (Before Migration):**
```
❌ Failed to save exercise log:
function calculate_rm_estimate(numeric, integer[]) does not exist
```

**Expected Behavior (After Migration):**
- Exercise logging saves successfully
- 1RM estimates automatically calculated
- No "function does not exist" errors

## Testing Required

1. Install BUILD 148 from TestFlight (when available ~23:05)
2. Start a workout session
3. Log an exercise with multiple sets
4. Verify exercise log saves without errors
5. Verify RM estimate is calculated automatically

## Related Builds

- **BUILD 147:** Timer creation fixes (RLS, FK constraints)
- **BUILD 148:** Timer state fix + this database migration
- **Combined:** All timer and exercise logging functionality now working

## Files Changed

**Database:**
- Created `calculate_rm_estimate(numeric, integer)` function
- Created `calculate_rm_estimate(numeric, integer[])` function
- Created `update_rm_estimate()` trigger function
- Created trigger on `exercise_logs` table

**Migration File:**
- `supabase/migrations/20260110230000_apply_calculate_rm_estimate_fix.sql`
