# RLS Policy Fix - Deployment Guide

**Date:** 2025-12-09
**Issue:** Build 8 fails with "data could not be read because it doesn't exist"
**Root Cause:** Missing RLS policies blocking patient data access
**Migration File:** `infra/009_fix_rls_policies.sql` & `supabase/migrations/20251209000009_fix_rls_policies.sql`

---

## Quick Status

- ✅ Migration file created: `infra/009_fix_rls_policies.sql`
- ✅ Migration copied to: `supabase/migrations/20251209000009_fix_rls_policies.sql`
- ⏳ Awaiting deployment to Supabase database
- ⏳ Awaiting verification testing

---

## Deployment Options

### Option 1: Supabase CLI (Requires Login)

**Step 1: Login to Supabase**
```bash
supabase login
```

This will open your browser to authenticate. After authentication:

**Step 2: Link to Project**
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap
supabase link --project-ref rpbxeaxlaoyoqkohytlw --password "rcq!vyd6qtb_HCP5mzt"
```

**Step 3: Deploy Migration**
```bash
supabase db push
```

This will automatically deploy the new migration file: `supabase/migrations/20251209000009_fix_rls_policies.sql`

---

### Option 2: Supabase Dashboard (Manual - RECOMMENDED IF CLI FAILS)

**Step 1: Access SQL Editor**
1. Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw
2. Click "SQL Editor" in left sidebar
3. Click "+ New Query"

**Step 2: Copy Migration SQL**
Copy the entire contents of `/Users/expo/Code/expo/clients/linear-bootstrap/infra/009_fix_rls_policies.sql` into the SQL editor.

**Step 3: Execute Migration**
1. Click "Run" button (or press Cmd+Enter)
2. Wait for execution to complete
3. Verify no errors in output

**Expected Output:**
- ALTER TABLE (adds user_id column)
- CREATE INDEX (adds user_id index)
- CREATE POLICY (22 times - for all the new policies)
- SELECT query results showing policy counts

---

### Option 3: Direct Database Connection (Advanced)

If you have database credentials, you can use `psql`:

```bash
# Set connection string
export DATABASE_URL="postgres://postgres.rpbxeaxlaoyoqkohytlw:[PASSWORD]@aws-0-us-west-1.pooler.supabase.com:6543/postgres"

# Apply migration
psql $DATABASE_URL < infra/009_fix_rls_policies.sql
```

---

## What This Migration Does

### 1. Fixes Missing user_id Column (CRITICAL)
```sql
ALTER TABLE patients ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_patients_user_id ON patients(user_id);
```

**Why:** The existing RLS policies reference `patients.user_id` but the column doesn't exist!

### 2. Adds 11 Patient SELECT Policies
Adds RLS policies for patients to read their own data from:
- ✅ phases
- ✅ sessions
- ✅ session_exercises
- ✅ exercise_logs
- ✅ pain_logs
- ✅ bullpen_logs
- ✅ plyo_logs
- ✅ session_notes
- ✅ body_comp_measurements
- ✅ session_status
- ✅ pain_flags

### 3. Adds 11 Therapist SELECT Policies
Mirrors the patient policies so therapists can read their patients' data.

### 4. Includes Verification Queries
The migration ends with two SELECT queries that show:
- Policy count per table
- List of all patient-facing policies

---

## Verification Steps

### 1. Verify Column Addition

Run this query in Supabase SQL Editor:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'patients'
  AND column_name = 'user_id';
```

**Expected Result:**
| column_name | data_type | is_nullable |
|-------------|-----------|-------------|
| user_id     | uuid      | YES         |

---

### 2. Verify Policy Counts

Run this query:

```sql
SELECT
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'patients', 'programs', 'phases', 'sessions', 'session_exercises',
    'exercise_logs', 'pain_logs', 'bullpen_logs', 'plyo_logs',
    'session_notes', 'body_comp_measurements', 'session_status', 'pain_flags'
  )
GROUP BY tablename
ORDER BY tablename;
```

**Expected Result:**
| tablename               | policy_count |
|-------------------------|--------------|
| body_comp_measurements  | 2            |
| bullpen_logs            | 2            |
| exercise_logs           | 2            |
| pain_flags              | 2            |
| pain_logs               | 2            |
| patients                | 2            |
| phases                  | 2            |
| plyo_logs               | 2            |
| programs                | 2            |
| session_exercises       | 2            |
| session_notes           | 2            |
| session_status          | 2            |
| sessions                | 2            |

Each table should have 2 policies: one for patients, one for therapists.

---

### 3. Verify Specific Patient Policies

Run this query:

```sql
SELECT
  tablename,
  policyname
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname LIKE 'patients_%'
ORDER BY tablename, policyname;
```

**Expected Result:** Should show 13 policies named `patients_see_own_*`

---

### 4. Test Patient Data Access

**CRITICAL TEST:** This query simulates what the iOS app does.

```sql
-- First, find a test patient user_id
SELECT id, user_id, first_name, last_name, email
FROM patients
LIMIT 5;

-- Then test the full query chain (replace USER_ID_HERE with actual user_id from above)
-- Run this as an authenticated patient user, or adjust WHERE clause for testing
SELECT
  s.id as session_id,
  s.name as session_name,
  s.target_date,
  se.id as session_exercise_id,
  se.target_sets,
  se.target_reps,
  et.name as exercise_name
FROM sessions s
JOIN phases ph ON s.phase_id = ph.id
JOIN programs pr ON ph.program_id = pr.id
JOIN session_exercises se ON se.session_id = s.id
JOIN exercise_templates et ON se.exercise_template_id = et.id
WHERE pr.patient_id = (
  SELECT id FROM patients WHERE user_id = 'USER_ID_HERE'::uuid
)
LIMIT 10;
```

**Expected Result:** Returns session data (not empty!)

---

## After Deployment - Update Demo Data

**IMPORTANT:** The `user_id` column is new, so existing patient records need to be linked to auth users.

### Check Current Patient Records

```sql
SELECT id, first_name, last_name, email, user_id
FROM patients
ORDER BY created_at DESC
LIMIT 10;
```

### Link Patient Records to Auth Users

If you have test patients, link them:

```sql
-- Example: Link patient to auth user by email
UPDATE patients
SET user_id = (SELECT id FROM auth.users WHERE email = 'patient@example.com')
WHERE email = 'patient@example.com'
  AND user_id IS NULL;
```

Or for your demo patient:

```sql
-- Update Adam Mitchell's patient record
UPDATE patients
SET user_id = (SELECT id FROM auth.users WHERE email = 'adam@demo.com')
WHERE email = 'adam@demo.com'
  AND user_id IS NULL;
```

---

## Rollback Plan (If Needed)

If the migration causes issues, you can rollback:

```sql
-- Remove policies
DROP POLICY IF EXISTS patients_see_own_phases ON phases;
DROP POLICY IF EXISTS therapists_see_patient_phases ON phases;
DROP POLICY IF EXISTS patients_see_own_sessions ON sessions;
DROP POLICY IF EXISTS therapists_see_patient_sessions ON sessions;
DROP POLICY IF EXISTS patients_see_own_session_exercises ON session_exercises;
DROP POLICY IF EXISTS therapists_see_patient_session_exercises ON session_exercises;
DROP POLICY IF EXISTS patients_see_own_exercise_logs ON exercise_logs;
DROP POLICY IF EXISTS therapists_see_patient_exercise_logs ON exercise_logs;
DROP POLICY IF EXISTS patients_see_own_pain_logs ON pain_logs;
DROP POLICY IF EXISTS therapists_see_patient_pain_logs ON pain_logs;
DROP POLICY IF EXISTS patients_see_own_bullpen_logs ON bullpen_logs;
DROP POLICY IF EXISTS therapists_see_patient_bullpen_logs ON bullpen_logs;
DROP POLICY IF EXISTS patients_see_own_plyo_logs ON plyo_logs;
DROP POLICY IF EXISTS therapists_see_patient_plyo_logs ON plyo_logs;
DROP POLICY IF EXISTS patients_see_own_session_notes ON session_notes;
DROP POLICY IF EXISTS therapists_see_patient_session_notes ON session_notes;
DROP POLICY IF EXISTS patients_see_own_body_comp ON body_comp_measurements;
DROP POLICY IF EXISTS therapists_see_patient_body_comp ON body_comp_measurements;
DROP POLICY IF EXISTS patients_see_own_session_status ON session_status;
DROP POLICY IF EXISTS therapists_see_patient_session_status ON session_status;
DROP POLICY IF EXISTS patients_see_own_pain_flags ON pain_flags;
DROP POLICY IF EXISTS therapists_see_patient_pain_flags ON pain_flags;

-- Remove column (CAREFUL - this deletes data!)
ALTER TABLE patients DROP COLUMN IF EXISTS user_id;
DROP INDEX IF EXISTS idx_patients_user_id;
```

**NOTE:** Only rollback if absolutely necessary. The `user_id` column removal will lose the linkage data!

---

## Next Steps After Deployment

1. ✅ Verify migration applied (run verification queries above)
2. ✅ Update patient records to link `user_id` to auth users
3. ✅ Test iOS app login and data retrieval
4. ✅ Create build 9 with same code (RLS is backend fix)
5. ✅ Deploy to TestFlight
6. ✅ Test on real device
7. ✅ Update Linear task status

---

## Troubleshooting

### "Policy already exists" error
This is OK! It means the policy was already created. The migration uses `CREATE POLICY` without `IF NOT EXISTS`, so if you run it twice, you'll see this error. Just ignore it.

### "Column already exists" error
This is OK! The migration uses `IF NOT EXISTS` for the column addition, so this shouldn't happen. But if it does, it's safe.

### "No rows returned" from test query
This could mean:
1. The patient has no sessions created yet
2. The patient's `user_id` is not set correctly
3. The patient user is not authenticated correctly

Check:
```sql
-- Verify patient exists and has user_id
SELECT * FROM patients WHERE email = 'your-patient-email@example.com';

-- Verify sessions exist
SELECT COUNT(*) FROM sessions;

-- Verify programs exist
SELECT COUNT(*) FROM programs;
```

---

## Project Information

- **Supabase Project:** rpbxeaxlaoyoqkohytlw
- **Dashboard:** https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw
- **Migration File:** `infra/009_fix_rls_policies.sql`
- **Analysis Doc:** `RLS_POLICY_ANALYSIS.md`

---

**Status:** Ready for deployment
**Risk Level:** Low (additive changes only, no data deletion)
**Estimated Duration:** 2-3 minutes to apply, 5 minutes to verify
**Requires Downtime:** No
