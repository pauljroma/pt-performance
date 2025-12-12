# 🚀 Apply RLS Fix NOW - Quick Start

**Critical Fix for Build 8 Data Access Issue**

---

## 🎯 Quick Deploy (2 Minutes)

### Method 1: Supabase Dashboard (EASIEST)

1. **Open Supabase SQL Editor**
   - Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw
   - Click "SQL Editor" in left sidebar
   - Click "+ New Query"

2. **Copy Migration SQL**
   - Open file: `infra/009_fix_rls_policies.sql`
   - Copy ALL contents (Cmd+A, Cmd+C)

3. **Run Migration**
   - Paste into SQL Editor (Cmd+V)
   - Click "Run" or press Cmd+Enter
   - Wait ~10 seconds for completion

4. **Verify Success**
   - Scroll to bottom of results
   - Should see policy count table
   - Should show 13 tables with policies

✅ **Done!** Migration applied.

---

### Method 2: Automated Script

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap
./apply_rls_fix.sh
```

Follow the prompts. If CLI login fails, use Method 1 instead.

---

## 📋 After Migration: Link Patients

**Important:** Existing patients need to be linked to auth users.

1. **Open Supabase SQL Editor**
   - Same URL as above

2. **Check Current Status**
   ```sql
   SELECT
     id,
     first_name,
     last_name,
     email,
     user_id,
     CASE WHEN user_id IS NULL THEN '❌' ELSE '✅' END as linked
   FROM patients;
   ```

3. **Link All Patients by Email**
   ```sql
   UPDATE patients p
   SET user_id = au.id
   FROM auth.users au
   WHERE p.email = au.email
     AND p.user_id IS NULL
     AND p.email IS NOT NULL;
   ```

4. **Verify Linking**
   ```sql
   SELECT COUNT(*) as total, COUNT(user_id) as linked FROM patients;
   ```

---

## ✅ Verify Fix Works

**Test Query** (should return data):

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

If this returns data, the fix is working! 🎉

---

## 🧪 Test iOS App

1. **Open TestFlight**
2. **Launch PT Performance app**
3. **Login as patient**
4. **Navigate to "Today's Session"**
5. **Verify data loads** (not "doesn't exist" error)

---

## 📚 Full Documentation

For detailed information, see:
- `RLS_FIX_RESULTS.md` - Complete results and verification
- `RLS_FIX_DEPLOYMENT_GUIDE.md` - Detailed deployment guide
- `test_rls_fix.sql` - Full verification test suite
- `link_patients_to_auth.sql` - Patient linking details

---

## 🆘 Troubleshooting

**"Policy already exists" error**
- ✅ This is fine! Means policy was created. Continue.

**"Column already exists" error**
- ✅ This is fine! Means column was added. Continue.

**Test query returns no data**
- Check if sessions exist: `SELECT COUNT(*) FROM sessions;`
- Check if patients linked: `SELECT * FROM patients;`
- Run `link_patients_to_auth.sql` to fix

**Still can't access data from iOS app**
- Verify patient's `user_id` matches their auth user
- Check app is using correct Supabase credentials
- Check app is sending correct authentication token

---

## 🎯 Expected Timeline

- ✅ Migration: 30 seconds
- ✅ Link patients: 10 seconds
- ✅ Verify: 1 minute
- ✅ Test iOS: 2 minutes
- **Total: ~4 minutes**

---

**Ready to fix Build 8? Start with Method 1 above! 🚀**
