# Build 32 - Migration Required for Exercise Logging

## Status: ⚠️ Action Required

**Build:** 32
**Status:** Uploaded to TestFlight ✅
**Blocking Issue:** `exercise_logs` table doesn't exist in database
**Solution:** Apply migration (1-minute manual step required)

---

## What Works in Build 32

✅ **UI Fixed** - Exercise rows now visible (proper contrast)
✅ **Comprehensive Logging** - Full diagnostics for exercise log submission
✅ **Error Identified** - Clear error message: "Could not find the 'actual_sets' column of 'exercise_logs' in the schema cache"

## What's Missing

❌ **Database Table** - `exercise_logs` table doesn't exist yet
📋 **Migration Created** - Ready to apply at `supabase/migrations/20251212000001_create_exercise_logs_table.sql`

---

## 🎯 Action Required: Apply Migration

### Option 1: Supabase Dashboard (Recommended - 1 minute)

1. **Go to SQL Editor:**
   https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new

2. **Copy Migration SQL:**
   Located at: `supabase/migrations/20251212000001_create_exercise_logs_table.sql`

3. **Paste and Run** in SQL Editor

4. **Verify:** Table `exercise_logs` should appear in Table Editor

### Option 2: Command Line (if network allows)

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/supabase
supabase db push --linked --include-all --yes
```

*(Note: Currently blocked by IPv6 network routing issue)*

---

## What the Migration Creates

### Table: `exercise_logs`

**Columns:**
- `id` (UUID, primary key)
- `session_exercise_id` (UUID, FK to session_exercises)
- `patient_id` (UUID, FK to patients)
- `logged_at` (timestamp with timezone)
- `actual_sets` (integer, >0)
- `actual_reps` (integer array - reps per set)
- `actual_load` (numeric 6,2 - weight used)
- `load_unit` (text - 'lbs' or 'kg')
- `rpe` (integer 0-10 - Rating of Perceived Exertion)
- `pain_score` (integer 0-10 - Pain level)
- `notes` (text, optional)
- `completed` (boolean, default true)
- `created_at`, `updated_at` (timestamps)

**Indexes:** (for fast queries)
- `idx_exercise_logs_patient_id`
- `idx_exercise_logs_session_exercise_id`
- `idx_exercise_logs_logged_at`
- `idx_exercise_logs_patient_logged_at` (composite)

**RLS Policies:**
- Patients can only see/create/update their own logs
- Therapists can view logs for their patients
- Proper auth checks using `auth.uid()`

---

## After Migration: Testing Build 32

Once migration applied, test the following:

### Test Flow:
1. **Login** as demo patient (`demo-athlete@ptperformance.app` / `demo-patient-2025`)
2. **Navigate** to "Today's Session"
3. **Select** first exercise (should show 10 exercises)
4. **Tap** "Log This Exercise"
5. **Fill in:**
   - Sets: 3
   - Reps per set: 10, 10, 10
   - Load: 135 lbs
   - RPE: 8
   - Pain: 5
6. **Submit** exercise
7. **Check Debug Logs** (🐜 button):
   - Should see: "✅ Exercise log created successfully with ID: [uuid]"
   - Should NOT see: "Could not find the 'actual_sets' column"

### Expected Success Logs:

```
🔍 📝 Starting exercise log submission...
🔍   Session Exercise ID: 6259d4b7-5ebd-4fa7-afa0-ff313e0112d7
🔍   Patient ID: 00000000-0000-0000-0000-000000000001
🔍   Sets: 3, Reps: [10, 10, 10]
🔍   Load: 135.0 lbs, RPE: 8, Pain: 5
🔍 📝 Inserting into exercise_logs table...
✅ Insert successful - response size: 456 bytes
📝 Response JSON: {"id":"[uuid]","session_exercise_id":"...","actual_sets":3,...}
✅ Exercise log created successfully with ID: [uuid]
```

---

## Next Steps After Migration

### Immediate (Build 32):
- [x] Fix UI styling
- [x] Add comprehensive logging
- [x] Create migration file
- [ ] **Apply migration** ⬅️ YOU ARE HERE
- [ ] Test exercise logging end-to-end
- [ ] Verify data persists correctly

### Phase 1.2 (Build 33+):
- [ ] Session completion flow
- [ ] Session summary screen
- [ ] Calculate session metrics (volume, avg pain, avg RPE)
- [ ] Mark session as completed

### Phase 1.3 (Build 34+):
- [ ] Session history view
- [ ] Show last 30 days of completed sessions
- [ ] Drill into session to see exercise logs

---

## Files Changed in Build 32

1. **TodaySessionView.swift** - Fixed exercise row background color
2. **ExerciseLogService.swift** - Added comprehensive diagnostic logging
3. **Migration Created:** `supabase/migrations/20251212000001_create_exercise_logs_table.sql`

---

## Why Migration Couldn't Be Applied Automatically

**Network Issue:** IPv6 routing blocked connection to Supabase database
**Error:** `No route to host` when connecting to `db.rpbxeaxlaoyoqkohytlw.supabase.co:5432`

**Attempted Methods:**
- ❌ `supabase db push` - No access token / network blocked
- ❌ `psql` direct connection - IPv6 routing issue
- ❌ Python `psycopg2` - Same network block
- ❌ Supabase REST API - Doesn't support DDL execution

**Solution:** Manual apply via Supabase Dashboard (1-minute task)

---

## Migration File Location

```
/Users/expo/Code/expo/clients/linear-bootstrap/supabase/migrations/20251212000001_create_exercise_logs_table.sql
```

**Contents:** 97 lines of SQL including table creation, indexes, RLS policies, and grants

---

## Post-Migration Verification

Run this SQL to confirm table exists:

```sql
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'exercise_logs'
ORDER BY ordinal_position;
```

Expected: 14 rows (all columns listed above)

---

## Support

If migration fails or issues occur:
1. Check Supabase logs in dashboard
2. Review error message
3. Verify RLS policies don't conflict with existing policies
4. Check that `session_exercises` and `patients` tables exist (they should)

---

**Status:** Ready for migration ✅
**Blocker:** Manual apply required (1 minute)
**Next:** Test Build 32 exercise logging after migration applied
