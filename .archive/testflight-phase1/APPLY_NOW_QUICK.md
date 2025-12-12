# 🚀 Apply RLS Migration NOW - Quick Reference

**Fixes Build 8 "data could not be read" error**

---

## ⚡ 2-Minute Process

### 1. Open SQL Editor
```
https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
```

### 2. Click "+ New Query"

### 3. Copy Migration SQL

**Location:** `/Users/expo/Code/expo/clients/linear-bootstrap/infra/009_fix_rls_policies.sql`

**View Command:**
```bash
cat /Users/expo/Code/expo/clients/linear-bootstrap/infra/009_fix_rls_policies.sql
```

### 4. Paste & Run

- Paste into editor
- Click "Run" button
- Wait 10 seconds

### 5. Link Patients (Run This Next)

```sql
UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.user_id IS NULL;

SELECT COUNT(*) as total, COUNT(user_id) as linked FROM patients;
```

### 6. Test Query (Verify It Works)

```sql
SELECT s.name, se.target_sets, et.name as exercise
FROM sessions s
JOIN phases ph ON s.phase_id = ph.id
JOIN programs pr ON ph.program_id = pr.id
JOIN session_exercises se ON se.session_id = s.id
JOIN exercise_templates et ON se.exercise_template_id = et.id
LIMIT 5;
```

**Expected:** Returns 5 rows ✅

---

## 📱 Test Build 8

1. Open TestFlight
2. Launch PT Performance
3. Login: demo-athlete@ptperformance.app
4. Go to "Today's Session"
5. **Verify:** Data loads (no error)

---

## ✅ Success Checklist

- [ ] Migration SQL executed
- [ ] Patients linked (UPDATE ran)
- [ ] Test query returns data
- [ ] iOS app shows session data
- [ ] No "doesn't exist" error

---

## 📚 Full Documentation

- Detailed: `APPLY_MIGRATION_MANUAL.md`
- Report: `RLS_MIGRATION_EXECUTION_REPORT.md`
- Original: `APPLY_RLS_FIX_NOW.md`

---

**Dashboard:** https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql

**Takes 2 minutes. Do it now! 🎯**
