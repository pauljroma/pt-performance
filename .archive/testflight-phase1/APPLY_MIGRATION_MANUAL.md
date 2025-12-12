# Apply RLS Migration - Manual Instructions

**CRITICAL: This fixes Build 8 "data could not be read" error**

## Why Manual Application?

The Supabase CLI requires authentication and project linking, which can be complex. The easiest and most reliable method is to use the Supabase Dashboard SQL Editor directly.

## Step-by-Step Instructions (2 minutes)

### 1. Open Supabase SQL Editor

Click this link or copy to browser:
```
https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
```

### 2. Create New Query

- Click the "+ New Query" button
- This opens a blank SQL editor

### 3. Copy Migration SQL

The migration file is located at:
```
/Users/expo/Code/expo/clients/linear-bootstrap/infra/009_fix_rls_policies.sql
```

Open this file and copy ALL contents (Cmd+A, Cmd+C)

**OR** use this command to print it:
```bash
cat /Users/expo/Code/expo/clients/linear-bootstrap/infra/009_fix_rls_policies.sql
```

### 4. Paste and Run

- Paste the SQL into the Supabase SQL Editor (Cmd+V)
- Click "Run" button (or press Cmd+Enter)
- Wait ~10 seconds for execution

### 5. Verify Success

Scroll to the bottom of the results. You should see:

✅ A table showing policy counts for 13 tables
✅ A list of all patient-facing policies

If you see these, the migration was successful!

## Expected Results

The migration will:
1. Add `user_id` column to `patients` table
2. Create 11 patient-facing RLS policies
3. Create 11 therapist-facing RLS policies
4. Total: 22 new RLS policies

## After Migration: Link Patients to Auth Users

Run this SQL in the same SQL Editor:

```sql
-- Check current status
SELECT
  id,
  first_name,
  last_name,
  email,
  user_id,
  CASE WHEN user_id IS NULL THEN '❌' ELSE '✅' END as linked
FROM patients;

-- Link patients by email
UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.user_id IS NULL
  AND p.email IS NOT NULL;

-- Verify linking
SELECT
  COUNT(*) as total_patients,
  COUNT(user_id) as linked_patients
FROM patients;
```

Expected result: All patients with email addresses should be linked.

## Test the Fix

Run this test query to verify data access works:

```sql
SELECT
  s.name as session,
  se.target_sets,
  se.target_reps,
  et.name as exercise
FROM sessions s
JOIN phases ph ON s.phase_id = ph.id
JOIN programs pr ON ph.program_id = pr.id
JOIN session_exercises se ON se.session_id = s.id
JOIN exercise_templates et ON se.exercise_template_id = et.id
LIMIT 5;
```

If this returns data, the fix is working!

## Troubleshooting

### "Column already exists" error
✅ This is fine - means the column was already added. Continue.

### "Policy already exists" error
✅ This is fine - means the policy was already created. Continue.

### No data returned from test query
- Check if sessions exist: `SELECT COUNT(*) FROM sessions;`
- Check if patients linked: `SELECT * FROM patients WHERE user_id IS NOT NULL;`
- If patients not linked, run the "Link patients" SQL above

## Alternative: Command Line (Advanced)

If you prefer command line and have Supabase CLI configured:

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap

# Login to Supabase
supabase login

# Link to project
supabase link --project-ref rpbxeaxlaoyoqkohytlw

# Copy migration to supabase/migrations if not already there
cp infra/009_fix_rls_policies.sql supabase/migrations/20251209000009_fix_rls_policies.sql

# Push to remote database
supabase db push

# Verify
supabase db remote commit --linked
```

## Next Steps After Migration

1. **Test iOS App Build 8**
   - Open TestFlight
   - Launch PT Performance app
   - Login as patient (demo-athlete@ptperformance.app)
   - Navigate to "Today's Session"
   - Verify data loads without error

2. **Mark Linear Task Complete**
   - Update ACP-107 or relevant Linear task
   - Document that RLS migration was applied

3. **Monitor for Issues**
   - Check app logs for any RLS-related errors
   - Verify all patient data is accessible
   - Verify therapist data access still works

## Success Criteria

✅ Migration SQL executed without errors
✅ `user_id` column added to patients table
✅ 22 RLS policies created
✅ All patients linked to auth.users
✅ Test query returns data
✅ iOS app Build 8 can access patient data

---

**Questions?** See `APPLY_RLS_FIX_NOW.md` or `RLS_FIX_DEPLOYMENT_GUIDE.md` for more details.
