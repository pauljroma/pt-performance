# ✅ RLS Migration - Complete Package

**Date:** 2025-12-09
**Task:** Fix Build 8 "data could not be read" error
**Status:** Ready for Manual Application

---

## 🎯 What You Need to Do

**Apply the RLS migration via Supabase Dashboard (2 minutes)**

### Quick Start

1. **Open this link:**
   ```
   https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
   ```

2. **Or run this command to open automatically:**
   ```bash
   ./open_sql_editor.sh
   ```

3. **Follow the guide:**
   - See: `APPLY_NOW_QUICK.md` (one-page quick reference)

---

## 📦 Files Created for You

### Main Migration File
- **`infra/009_fix_rls_policies.sql`** - The migration SQL (ready to apply)

### Quick Reference Guides
1. **`APPLY_NOW_QUICK.md`** ⭐ START HERE - One-page quick reference
2. **`APPLY_MIGRATION_MANUAL.md`** - Detailed step-by-step instructions
3. **`RLS_MIGRATION_INSTRUCTIONS.txt`** - Complete instructions with SQL included

### Verification Tools
4. **`verify_rls_migration.sql`** - Complete test suite to verify migration worked
5. **`open_sql_editor.sh`** - Opens Supabase Dashboard in browser

### Documentation
6. **`RLS_MIGRATION_EXECUTION_REPORT.md`** - Full technical report of what was attempted
7. **`RLS_MIGRATION_COMPLETE.md`** - This file (summary)

### Helper Scripts (Attempted Automation)
8. `apply_rls_migration.py` - Python script (requires psycopg2)
9. `apply_rls_via_api.py` - REST API approach (not supported)
10. `apply_rls_direct.sh` - Shell script (requires psql)
11. `apply_migration_final.py` - Helper with instructions
12. `check_db_schema.py` - Database schema checker

---

## 🚀 Recommended Workflow

### Step 1: Apply Migration (2 min)
```bash
# Option A: Open browser automatically
./open_sql_editor.sh

# Option B: Manual
# 1. Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
# 2. Click "+ New Query"
# 3. Copy contents of: infra/009_fix_rls_policies.sql
# 4. Paste and click "Run"
```

### Step 2: Link Patients (30 sec)
Run this SQL in the same editor:
```sql
UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.user_id IS NULL;

SELECT COUNT(*) as total, COUNT(user_id) as linked FROM patients;
```

### Step 3: Verify (1 min)
Copy and run: `verify_rls_migration.sql`

Or just run this quick test:
```sql
SELECT s.name, se.target_sets, et.name as exercise
FROM sessions s
JOIN phases ph ON s.phase_id = ph.id
JOIN programs pr ON ph.program_id = pr.id
JOIN session_exercises se ON se.session_id = s.id
JOIN exercise_templates et ON se.exercise_template_id = et.id
LIMIT 5;
```

Expected: Returns 5 rows ✅

### Step 4: Test iOS App (2 min)
1. Open TestFlight
2. Launch PT Performance (Build 8)
3. Login: demo-athlete@ptperformance.app
4. Go to "Today's Session"
5. Verify: Data loads without "doesn't exist" error

---

## 📊 What This Migration Does

### Schema Changes
- Adds `user_id` column to `patients` table
- Links patients to Supabase auth.users
- Creates unique index on user_id

### RLS Policies (22 total)

#### Patient Policies (11)
Allows patients to see their own:
- Program phases and sessions
- Session exercises
- Exercise logs
- Pain logs
- Bullpen logs
- Plyo logs
- Session notes
- Body composition data
- Session status
- Pain flags

#### Therapist Policies (11)
Allows therapists to see their patients':
- Same 11 data types as above
- Based on therapist_id relationship

---

## ✅ Success Criteria

After applying migration, you should have:

- [x] Migration SQL executed without critical errors
- [x] `user_id` column exists in patients table
- [x] 11 patient-facing RLS policies created
- [x] 11 therapist-facing RLS policies created
- [x] Patients linked to auth.users (user_id populated)
- [x] Test query returns session/exercise data
- [x] iOS app Build 8 can access patient data

---

## 🔍 Verification Checklist

Run these queries to verify everything worked:

```sql
-- 1. Check user_id column exists
SELECT column_name FROM information_schema.columns
WHERE table_name = 'patients' AND column_name = 'user_id';
-- Expected: 1 row

-- 2. Count patient policies
SELECT COUNT(*) FROM pg_policies WHERE policyname LIKE 'patients_%';
-- Expected: 11

-- 3. Count therapist policies
SELECT COUNT(*) FROM pg_policies WHERE policyname LIKE 'therapists_%';
-- Expected: 11

-- 4. Check patients linked
SELECT COUNT(*) as total, COUNT(user_id) as linked FROM patients;
-- Expected: Both numbers should be equal (or close)

-- 5. Test data access
SELECT COUNT(*) FROM sessions s
JOIN phases ph ON s.phase_id = ph.id
JOIN programs pr ON ph.program_id = pr.id;
-- Expected: > 0
```

---

## 🛠️ Troubleshooting

### Common Errors (These are OK!)

**"relation already exists"**
✅ Column/index already added - this is fine, continue

**"policy already exists"**
✅ Policy already created - this is fine, continue

### Real Issues

**"relation does not exist"**
❌ Database schema not initialized
**Fix:** Need to apply base migrations first (001-008)

**Test query returns 0 rows**
❌ No seed data in database
**Fix:** Run seed data migrations (003_seed_demo_data.sql, etc.)

**Patients not linked (user_id is NULL)**
❌ Email mismatch or auth users not created
**Fix:** Check auth.users table and verify emails match

---

## 📁 File Locations Summary

All files are in: `/Users/expo/Code/expo/clients/linear-bootstrap/`

```
linear-bootstrap/
├── infra/
│   └── 009_fix_rls_policies.sql          ← Main migration file
├── APPLY_NOW_QUICK.md                    ← ⭐ Quick reference
├── APPLY_MIGRATION_MANUAL.md             ← Detailed instructions
├── RLS_MIGRATION_INSTRUCTIONS.txt        ← Full instructions
├── verify_rls_migration.sql              ← Verification queries
├── open_sql_editor.sh                    ← Browser opener
├── RLS_MIGRATION_EXECUTION_REPORT.md     ← Technical report
└── RLS_MIGRATION_COMPLETE.md             ← This file
```

---

## 🎓 What We Learned

### Why Automated Application Failed

1. **Direct PostgreSQL:** Supabase blocks port 5432 (security)
2. **REST API:** Doesn't support raw SQL execution
3. **CLI:** Requires interactive login (not available in automation)
4. **psql:** Not installed on this system

### Why Manual is Best

1. **Official method** - Supabase Dashboard is the recommended way
2. **Fast** - Only takes 2 minutes
3. **Reliable** - Immediate feedback and error messages
4. **Secure** - No credential passing required
5. **Verifiable** - Results shown immediately

---

## 🎯 Next Actions

### Immediate (Required)
1. ✅ Apply migration via Dashboard (2 min)
2. ✅ Link patients (30 sec)
3. ✅ Verify with test query (30 sec)
4. ✅ Test iOS app Build 8 (2 min)

### Follow-up (Recommended)
1. Update Linear task (ACP-107 or relevant)
2. Document completion
3. Monitor app for errors
4. Add RLS policy monitoring

### Future Improvements
1. Install psql for future migrations
2. Set up Supabase CLI authentication
3. Create CI/CD pipeline for migrations
4. Add automated RLS testing

---

## 📞 Support

### Documentation Files
- Quick start: `APPLY_NOW_QUICK.md`
- Detailed guide: `APPLY_MIGRATION_MANUAL.md`
- Technical report: `RLS_MIGRATION_EXECUTION_REPORT.md`
- Original guide: `APPLY_RLS_FIX_NOW.md`

### Useful Commands
```bash
# Open SQL Editor in browser
./open_sql_editor.sh

# View migration SQL
cat infra/009_fix_rls_policies.sql

# View verification queries
cat verify_rls_migration.sql
```

### Supabase Dashboard
- Project: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw
- SQL Editor: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
- Table Editor: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/editor

---

## 🎉 Summary

Everything is ready for you to apply the RLS migration and fix Build 8's data access issue. The process is straightforward and will take about 5 minutes total.

**Start here:** `APPLY_NOW_QUICK.md` or run `./open_sql_editor.sh`

**Good luck!** 🚀

---

**Generated:** 2025-12-09
**Status:** Ready for Application
**Priority:** High (blocks Build 8)
**Estimated Time:** 5 minutes
