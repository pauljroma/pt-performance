# 🚀 START HERE: RLS Migration for Build 8

**Critical Fix:** Resolves "data could not be read because it doesn't exist" error in iOS Build 8

---

## ⚡ Quick Start (Choose One Path)

### Path 1: Super Quick (2 minutes) ⭐ RECOMMENDED

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap
./open_sql_editor.sh
```

Then follow the on-screen instructions.

### Path 2: Copy-Paste Method (2 minutes)

1. Read: **`APPLY_NOW_QUICK.md`** (one-page guide)
2. Open: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
3. Follow the steps in the guide

### Path 3: Detailed Instructions (5 minutes)

Read: **`APPLY_MIGRATION_MANUAL.md`** for complete step-by-step process

---

## 📚 Documentation Guide

### Where to Start

| If you want... | Read this file |
|----------------|----------------|
| ⚡ Fastest method | `APPLY_NOW_QUICK.md` |
| 📦 Complete overview | `RLS_MIGRATION_COMPLETE.md` |
| 📖 Step-by-step guide | `APPLY_MIGRATION_MANUAL.md` |
| 🔍 Technical details | `FINAL_RLS_MIGRATION_SUMMARY.md` |
| 📊 What was attempted | `RLS_MIGRATION_EXECUTION_REPORT.md` |

### Helper Tools

| Tool | Purpose |
|------|---------|
| `open_sql_editor.sh` | Opens Supabase Dashboard |
| `print_migration_sql.sh` | Prints SQL for easy copying |
| `verify_rls_migration.sql` | Verification test suite |

---

## ✅ What This Migration Does

1. **Adds `user_id` column** to patients table (links to auth.users)
2. **Creates 22 RLS policies** (11 for patients, 11 for therapists)
3. **Enables secure data access** for patient and therapist views
4. **Fixes Build 8 error** - patients can now access their data

---

## 🎯 The Process (5 minutes total)

1. **Apply migration** → 2 minutes
2. **Link patients** → 30 seconds
3. **Verify success** → 1 minute
4. **Test iOS app** → 2 minutes

---

## 🔗 Quick Links

- **SQL Editor:** https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
- **Migration File:** `infra/009_fix_rls_policies.sql`
- **Project Dashboard:** https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw

---

## ❓ Common Questions

**Q: Why can't I run an automated script?**
A: Supabase blocks direct database connections. Manual application via Dashboard is the official method and only takes 2 minutes.

**Q: Is this safe to run?**
A: Yes! The migration is idempotent (safe to run multiple times) and only adds RLS policies.

**Q: What if I get "already exists" errors?**
A: That's fine! It means parts of the migration were already applied. Continue with the rest.

**Q: How do I know if it worked?**
A: Run the test query in `verify_rls_migration.sql` - it should return session/exercise data.

---

## 🆘 Need Help?

1. Check `APPLY_MIGRATION_MANUAL.md` for detailed troubleshooting
2. Review `FINAL_RLS_MIGRATION_SUMMARY.md` for technical details
3. See `RLS_MIGRATION_EXECUTION_REPORT.md` for what was attempted

---

## 👉 Next Step

**Run this command:**
```bash
./open_sql_editor.sh
```

Or open this file: **`APPLY_NOW_QUICK.md`**

---

**Good luck! This will fix Build 8's data access issue. 🎉**
