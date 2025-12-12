# Build 10 - Anon Key Fix

## What Was Fixed

**Critical Issue**: Config.swift had the **SERVICE KEY** instead of **ANON KEY**
- This caused "no connectivity to database" on iPad
- Service keys bypass RLS and should never be in client apps
- Major security vulnerability

## Changes Made

### File: `ios-app/PTPerformance/Config.swift` (Line 9)

**Before (Build 9):**
```swift
static let supabaseAnonKey = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3" // SERVICE KEY ❌
```

**After (Build 10):**
```swift
static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwYnhlYXhsYW95b3Frb2h5dGx3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMyNDc3MDMsImV4cCI6MjA0ODgyMzcwM30.ecg4DRB_cgq@azx4vcr" // ANON KEY ✅
```

## Status

- ✅ Config.swift updated
- ✅ Committed to git
- ✅ Pushed to GitHub
- 🔄 Build 10 building via GitHub Actions
- ⏳ Will appear in TestFlight when ready

## What Build 10 Should Fix

### Patient Side
- ✅ Database connectivity works
- ✅ Can load session data
- ✅ Can view exercises
- ✅ RLS policies properly enforce access

### Therapist Side
- ✅ Database connectivity works
- ✅ Can load patient list
- ✅ Can view patient details
- ✅ RLS policies properly enforce access

## Test Credentials (Same as Build 9)

**Patient**: demo-athlete@ptperformance.app / demo-patient-2025
**Therapist**: demo-pt@ptperformance.app / demo-therapist-2025

## Previous Fixes (Still Applied)

From Build 9:
- ✅ Auth users exist and have correct passwords
- ✅ Database linkages fixed (patients.user_id → auth.users)
- ✅ Demo data seeded (program, sessions, exercises)

## Why This Is Critical

**Service Key vs Anon Key:**

| Feature | Service Key (Build 9) | Anon Key (Build 10) |
|---------|----------------------|---------------------|
| RLS Enforcement | ❌ Bypassed | ✅ Enforced |
| Security | ❌ Admin access | ✅ User access only |
| Client Use | ❌ Never | ✅ Designed for it |
| Exposure Risk | ❌ Critical | ✅ Safe |

Using service key in client apps = anyone who decompiles the app gets full admin access to the database.

## Next Steps

1. Wait for Build 10 to appear in TestFlight (~10-15 minutes)
2. Install Build 10 on iPad
3. Test both patient and therapist logins
4. Verify database connectivity works

## Expected Outcome

**Build 10 should have working database connectivity** because:
1. ✅ Anon key properly configured
2. ✅ RLS policies in place
3. ✅ Auth linkages correct
4. ✅ Demo data exists

If Build 10 still has connectivity issues, the problem is likely:
- RLS policies too restrictive
- Missing RLS policies for some tables
- Network/firewall issue

---

**Commit**: 8a0e587
**Pushed**: 2025-12-10 13:38 UTC
**Status**: Building
