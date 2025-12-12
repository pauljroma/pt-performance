# RLS Fix Deployment Checklist

**Issue:** Build 8 fails with "data could not be read because it doesn't exist"
**Fix:** Add missing RLS policies and user_id column
**Date:** 2025-12-09

---

## Pre-Deployment Checklist

- [x] Root cause analysis completed (`RLS_POLICY_ANALYSIS.md`)
- [x] Migration file created (`infra/009_fix_rls_policies.sql`)
- [x] Migration copied to Supabase directory (`supabase/migrations/20251209000009_fix_rls_policies.sql`)
- [x] Verification script created (`test_rls_fix.sql`)
- [x] Patient linking script created (`link_patients_to_auth.sql`)
- [x] Deployment guide created (`RLS_FIX_DEPLOYMENT_GUIDE.md`)
- [x] Quick start guide created (`APPLY_RLS_FIX_NOW.md`)
- [x] Automated deploy script created (`apply_rls_fix.sh`)
- [x] Results document created (`RLS_FIX_RESULTS.md`)
- [x] All files verified and ready

---

## Deployment Checklist

### Step 1: Apply Migration
- [ ] Open Supabase Dashboard: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw
- [ ] Navigate to SQL Editor
- [ ] Copy SQL from `infra/009_fix_rls_policies.sql`
- [ ] Paste and run in SQL Editor
- [ ] Verify no critical errors (ignore "already exists" warnings)
- [ ] Confirm completion message appears

**Time:** ~1 minute

---

### Step 2: Run Verification Tests
- [ ] Open `test_rls_fix.sql` in editor
- [ ] Copy and paste into Supabase SQL Editor
- [ ] Run all tests
- [ ] Verify results:
  - [ ] Test 1: user_id column exists (1 row)
  - [ ] Test 2: user_id index exists (1 row)
  - [ ] Test 3: 13 tables each have 2 policies
  - [ ] Test 4: 13 patient policies listed
  - [ ] Test 5: 13+ therapist policies listed
  - [ ] Test 6: All tables have RLS enabled
  - [ ] Test 7: Patient records shown
  - [ ] Test 8: Auth users shown
  - [ ] Test 9: Sample data returns (or empty if no sessions)
  - [ ] Test 10: All 13 tables show "COMPLETE" status

**Time:** ~2 minutes

---

### Step 3: Link Patients to Auth Users
- [ ] Open `link_patients_to_auth.sql` in editor
- [ ] Run Step 1 queries to check current status
- [ ] Note how many patients need linking
- [ ] Run Step 2 (dry run) to preview updates
- [ ] Uncomment and run Step 3 to perform actual linking
- [ ] Run Step 5 to verify all patients are linked
- [ ] Confirm all patients have user_id set

**Time:** ~1 minute

---

### Step 4: Test Database Queries
- [ ] Run this test query in SQL Editor:
  ```sql
  SELECT
    s.name as session,
    se.target_sets,
    et.name as exercise
  FROM sessions s
  JOIN phases ph ON s.phase_id = ph.id
  JOIN programs pr ON ph.program_id = pr.id
  JOIN session_exercises se ON se.session_id = s.id
  JOIN exercise_templates et ON se.exercise_template_id = et.id
  LIMIT 5;
  ```
- [ ] Verify query returns data (not empty)
- [ ] Verify no RLS permission errors

**Time:** ~30 seconds

---

### Step 5: Test iOS App
- [ ] Open TestFlight on iOS device
- [ ] Launch PT Performance app (Build 8)
- [ ] Login as patient user
- [ ] Navigate to "Today's Session"
- [ ] Verify session data loads successfully
- [ ] Verify exercises are visible
- [ ] Verify no "data could not be read" errors
- [ ] Test navigation to other screens
- [ ] Verify all data displays correctly

**Time:** ~3 minutes

---

## Post-Deployment Checklist

### Documentation
- [ ] Update `RLS_FIX_RESULTS.md` with actual deployment results
- [ ] Document any issues encountered
- [ ] Note final verification test results
- [ ] Record timestamp of successful deployment

### Monitoring
- [ ] Check Supabase logs for RLS errors (should be none)
- [ ] Monitor app analytics for data loading errors
- [ ] Track patient login success rate
- [ ] Watch for any new "doesn't exist" errors

### Communication
- [ ] Update Linear task status
- [ ] Notify team that RLS fix is deployed
- [ ] Share test results
- [ ] Schedule follow-up testing

---

## Success Criteria

Migration is successful when ALL of these are true:

- [x] Migration file created (281 lines)
- [ ] Migration applied to database (no errors)
- [ ] Column `patients.user_id` exists
- [ ] Index `idx_patients_user_id` exists
- [ ] 22 new RLS policies created (11 patient + 11 therapist)
- [ ] All verification tests pass
- [ ] All patient records linked to auth.users
- [ ] Test query returns data
- [ ] iOS app loads patient data successfully
- [ ] No RLS permission errors in logs

---

## Rollback Criteria

Rollback if ANY of these occur:

- [ ] Migration causes database errors
- [ ] Existing functionality breaks
- [ ] Performance degrades significantly
- [ ] Data integrity issues discovered
- [ ] Critical security vulnerability introduced

**Rollback procedure:** See `RLS_FIX_DEPLOYMENT_GUIDE.md` section "Rollback Plan"

---

## Issue Resolution Timeline

| Status | Action | Expected Duration | Actual Duration |
|--------|--------|-------------------|-----------------|
| ✅ Complete | Analysis | 30 min | [ACTUAL] |
| ✅ Complete | Migration creation | 10 min | [ACTUAL] |
| ✅ Complete | Documentation | 20 min | [ACTUAL] |
| ⏳ Pending | Deploy migration | 1 min | [PENDING] |
| ⏳ Pending | Verify migration | 2 min | [PENDING] |
| ⏳ Pending | Link patients | 1 min | [PENDING] |
| ⏳ Pending | Test iOS app | 3 min | [PENDING] |
| **Total** | **End-to-end** | **~1 hour** | **[PENDING]** |

---

## Files Created (All Ready)

| File | Size | Purpose | Status |
|------|------|---------|--------|
| `infra/009_fix_rls_policies.sql` | 7.9 KB | Main migration | ✅ Ready |
| `supabase/migrations/20251209000009_fix_rls_policies.sql` | 7.9 KB | Supabase migration | ✅ Ready |
| `RLS_POLICY_ANALYSIS.md` | 23 KB | Root cause analysis | ✅ Complete |
| `RLS_FIX_DEPLOYMENT_GUIDE.md` | 10 KB | Deployment guide | ✅ Complete |
| `RLS_FIX_RESULTS.md` | 13 KB | Results & verification | ✅ Complete |
| `APPLY_RLS_FIX_NOW.md` | 3.4 KB | Quick start | ✅ Complete |
| `test_rls_fix.sql` | 7.6 KB | Verification tests | ✅ Ready |
| `link_patients_to_auth.sql` | 5.4 KB | Patient linking | ✅ Ready |
| `apply_rls_fix.sh` | 3.4 KB | Deploy script | ✅ Executable |
| `RLS_FIX_CHECKLIST.md` | This file | Deployment checklist | ✅ Complete |

---

## Next Actions

**Immediate (Now):**
1. [ ] Apply migration using `APPLY_RLS_FIX_NOW.md` guide
2. [ ] Run verification tests
3. [ ] Link patients to auth users
4. [ ] Test iOS app

**Follow-up (Within 24 hours):**
1. [ ] Monitor for issues
2. [ ] Update Linear tasks
3. [ ] Document final results
4. [ ] Plan Build 9 if needed

**Future (This week):**
1. [ ] Add automated RLS policy tests
2. [ ] Improve patient onboarding to set user_id
3. [ ] Document RLS pattern for future tables
4. [ ] Consider RLS policy generator

---

## Contact & Support

- **Supabase Dashboard:** https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw
- **Migration Files:** `/Users/expo/Code/expo/clients/linear-bootstrap/infra/`
- **Documentation:** All RLS_FIX_*.md files in project root
- **Support:** See Supabase docs for RLS troubleshooting

---

## Final Notes

- This fix is **critical** for Build 8 to work
- Migration is **low risk** (additive only)
- Expected completion time: **~7 minutes**
- No app downtime required
- Backend-only fix (no app rebuild needed)

**Ready to deploy?** Start with `APPLY_RLS_FIX_NOW.md`! 🚀

---

**Created:** 2025-12-09
**Status:** Ready for Deployment
**Risk Level:** Low
**Priority:** Critical
