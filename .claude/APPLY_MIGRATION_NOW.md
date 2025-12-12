# Apply Build 32 Migration - REQUIRED

## Status: ❌ Migration NOT Applied

**Error in iOS App:**
```
Could not find the 'actual_sets' column of 'exercise_logs' in the schema cache
```

**Root Cause:** The `exercise_logs` table does not exist in the database yet.

## ✅ Solution: Apply Migration via Supabase Dashboard (1 minute)

### Step 1: Open SQL Editor
https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new

### Step 2: Copy Migration SQL

The SQL is in: `supabase/migrations/20251212000001_create_exercise_logs_table.sql`

Or run in terminal:
```bash
cat supabase/migrations/20251212000001_create_exercise_logs_table.sql | pbcopy
```

### Step 3: Paste and Run in Dashboard
1. Paste the SQL into the SQL Editor
2. Click "RUN" button
3. Wait for "Success" message
4. Verify table appears in Table Editor

### Step 4: Verify

Check that table exists:
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'exercise_logs'
ORDER BY ordinal_position;
```

Expected: 14 rows (all columns from migration)

### Step 5: Test Build 32 on iPad

After applying migration:
1. Open Build 32 on iPad
2. Login as demo patient
3. Navigate to "Today's Session"
4. Log an exercise
5. Verify: Success message in debug logs
6. Verify: Data appears in Supabase Table Editor

## Why This Method?

All automated approaches fail due to network/auth restrictions:
- ❌ `supabase db push` - No access token
- ❌ `psql` connection - Connection pooler auth fails
- ❌ REST API RPC - No exec function available
- ❌ Python psycopg2 - Same connection issues

✅ **Supabase Dashboard** - Always works, web-based, 100% success rate over 31 builds

## After Migration Applied

Update this file to:
```markdown
## Status: ✅ Migration Applied

Applied: 2025-12-12
Method: Supabase Dashboard SQL Editor
Verified: exercise_logs table exists with 14 columns
Build 32 Status: Ready for testing
```

Then test exercise logging end-to-end on iPad.

---

**Next:** Once confirmed working, proceed to Build 33 (Session Completion)
