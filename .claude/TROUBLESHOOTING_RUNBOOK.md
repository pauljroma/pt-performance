# TROUBLESHOOTING RUNBOOK

## Purpose

Quick reference for common errors encountered across 32 builds. When you see an error → Search this file FIRST → Apply documented solution.

**Rule:** Don't debug from scratch if the error is documented here.

---

## Database & Migration Errors

### "Could not find '[column]' column of '[table]' in the schema cache"

**Cause:** PostgREST schema cache hasn't refreshed after migration applied

**Solution:**
```bash
# Run schema cache refresh script
python3 refresh_schema_cache.py

# If still failing, wait 30-60 seconds and retry
# Schema cache auto-refreshes every 60 seconds
```

**Prevention:** Always run refresh_schema_cache.py after applying migrations

**Reference:** Builds 10-32 (recurring issue)

---

### "Tenant or user not found" (psql connection)

**Cause:** Direct PostgreSQL connection blocked by auth/network

**Solution:** Use Supabase Dashboard SQL Editor instead

```bash
# DON'T: Try to fix psql connection
# DO: Use Dashboard
open https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new
```

**Why:** 31 builds confirmed direct connections don't work in this environment

**Reference:** `.claude/AUTOMATED_MIGRATIONS.md`

---

### "Access token not provided" (supabase CLI)

**Cause:** Supabase CLI requires interactive OAuth login

**Solution:** Use Dashboard SQL Editor (manual application works 100% of time)

```bash
# DON'T: Try to authenticate CLI
# DO: Use Dashboard
open https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new
```

**Why:** OAuth requires browser, can't be automated from CLI

**Reference:** Builds 8-32

---

### "Table already exists"

**Cause:** Migration already applied (good news!)

**Solution:** Skip to verification step

```bash
# Verify table is accessible
python3 apply_migration_direct.py

# Should output: ✅ Table already exists!
```

**Action:** Mark migration as complete, update Linear

---

### "Relation does not exist" (foreign key error)

**Cause:** Referenced table doesn't exist yet (migration order issue)

**Solution:** Check if dependent migration needs to be applied first

```bash
# List all migrations in chronological order
ls -lt supabase/migrations/*.sql

# Apply dependencies first (earlier timestamps)
```

**Prevention:** Migrations should be applied in timestamp order

---

## Swift/iOS Errors

### "Could not decode JSON: keyNotFound([key])"

**Cause:** Swift model expects field that doesn't exist in database/API response

**Solution:** Verify database schema matches Swift model exactly

**Diagnostic Steps:**
```bash
# 1. Check database column names
python3 verify_table_schema.py

# 2. Compare to Swift model
# ios-app/PTPerformance/Models/[ModelName].swift

# 3. Fix mismatch:
# Option A: Add missing column to database
# Option B: Make Swift property optional
```

**Example (Build 15):**
- Database had `session_number` but Swift expected `sessionNumber`
- Fixed by adding alias in view: `session_number as "sessionNumber"`

**Prevention:** Keep database column names matching Swift CodingKeys

---

### "Cannot convert value of type 'X' to expected type 'Y'"

**Cause:** Database type doesn't match Swift type

**Solution:** Check type mapping in database view/query

**Common Mismatches:**
| Database Type | Swift Type | Fix |
|---------------|------------|-----|
| `INT[]` | `[Int]` | Ensure column is truly array type |
| `NUMERIC` | `Double` | Add CAST if needed |
| `TEXT` | `String?` | Make Swift property optional |
| `TIMESTAMPTZ` | `Date` | Use ISO8601 decoder |

**Reference:** Build 10-14 (type mismatches in views)

---

### "RLS policy blocks access" / Empty results when logged in

**Cause:** Row-Level Security policy doesn't match user's auth context

**Diagnostic:**
```sql
-- Check if user is in database
SELECT id, email FROM auth.users WHERE email = 'demo-athlete@ptperformance.app';

-- Check if patient record exists
SELECT id, user_id FROM patients WHERE user_id = '[AUTH_UID_FROM_ABOVE]';

-- Check if linkage is correct
SELECT
    u.email,
    p.id as patient_id,
    p.user_id as patient_user_id
FROM auth.users u
LEFT JOIN patients p ON p.user_id = u.id
WHERE u.email = 'demo-athlete@ptperformance.app';
```

**Solution:** Fix user_id linkage in database

```sql
-- Update patient record to link to auth user
UPDATE patients
SET user_id = (SELECT id FROM auth.users WHERE email = 'demo-athlete@ptperformance.app')
WHERE id = '[PATIENT_ID]';
```

**Prevention:** Always verify auth linkages after creating demo users

**Reference:** Builds 10-12 (RLS linkage issues)

---

## Build & Deployment Errors

### "No signing identity found"

**Cause:** Xcode can't find valid signing certificate

**Solution:**
```bash
# 1. Open Xcode Preferences → Accounts
# 2. Select Apple ID
# 3. Click "Download Manual Profiles"
# 4. Wait for profiles to download
# 5. Retry build
```

**If still failing:** Check Apple Developer portal for expired certificates

---

### "Provisioning profile expired"

**Cause:** App provisioning profile needs renewal

**Solution:**
1. Go to: https://developer.apple.com/account/resources/profiles
2. Find "PT Performance" profile
3. Click "Edit"
4. Save (regenerates with new expiration)
5. Download and double-click to install
6. Retry build

**Prevention:** Renew profiles before they expire (check quarterly)

---

### "Build already exists with this version"

**Cause:** Trying to upload build with same version/build number as previous

**Solution:**
```bash
# Increment build number in Config.swift
# Change: static let buildNumber = "32"
# To: static let buildNumber = "33"
```

**Prevention:** Always increment build number before creating new build

**Reference:** `.claude/BUILD_RUNBOOK.md`

---

## Network & API Errors

### "IPv6 routing blocked" / "No route to host"

**Cause:** Direct network connections to Supabase pooler blocked

**Solution:** Use REST API or Dashboard instead of direct connections

```bash
# DON'T: psql, pg_dump, pg_restore
# DO: REST API, Dashboard SQL Editor, Supabase Studio
```

**Why:** Network environment blocks direct PostgreSQL ports

---

### "API rate limit exceeded"

**Cause:** Too many requests to Supabase API

**Solution:** Add delay between requests or batch operations

```python
import time

# Add delay between requests
time.sleep(0.5)  # 500ms delay
```

**Prevention:** Use batch operations when possible

---

## Linear Integration Errors

### "Linear API: Unauthorized"

**Cause:** API key expired or invalid

**Solution:** User needs to regenerate Linear API key

**User Action Required:**
1. Go to: https://linear.app/settings/api
2. Create new API key
3. Update environment variable or script

**Note:** Claude can't fix this - user must provide valid key

---

### "Issue not found" / "Project not found"

**Cause:** Wrong issue ID or project doesn't exist

**Solution:** Verify issue ID in Linear

```bash
# Linear URL pattern:
# https://linear.app/team-name/issue/ISSUE-ID
# Example: https://linear.app/agent-control-plane/issue/ACP-107
```

**Current Project:** MVP 1 — PT App & Agent Pilot
**Current Issues:** ACP-100 series

---

## Git Errors

### "pre-commit hook failed"

**Cause:** Git hook detected files outside allowed workspace

**Solution:** Remove files outside `/Users/expo/Code/expo/clients/linear-bootstrap`

```bash
# Check what files are staged
git status

# If files are in wrong directory, unstage them
git reset HEAD path/to/wrong/file

# Only commit files in linear-bootstrap directory
```

**Prevention:** Always work in `/Users/expo/Code/expo/clients/linear-bootstrap`

---

## Error Diagnostic Workflow

When encountering ANY error:

### Step 1: Search This Runbook
```bash
# Search for error message
grep -i "error text" .claude/TROUBLESHOOTING_RUNBOOK.md
```

### Step 2: Check Recent Outcomes
```bash
# Look for similar issues in recent sessions
ls -lt .outcomes/*.md | head -5
grep -i "error text" .outcomes/*.md
```

### Step 3: Check Archived Solutions
```bash
# Search archive for historical solutions
grep -ri "error text" .archive/
```

### Step 4: If Genuinely New Error

**Document it:**
1. Add to this runbook under appropriate section
2. Include: Cause, Solution, Prevention
3. Reference build number where it occurred

**Don't:**
- Debug from scratch if error might be documented
- Recreate solutions that already exist
- Skip documentation (helps future builds)

---

## Quick Reference: Most Common Errors

| Error | File/Location | Quick Fix |
|-------|---------------|-----------|
| Schema cache | Database | `python3 refresh_schema_cache.py` |
| RLS blocks access | Database | Check auth.uid() linkage |
| Swift decoder | iOS | Verify column names match |
| Tenant not found | psql | Use Dashboard instead |
| Access token | Supabase CLI | Use Dashboard instead |

---

## When to Ask User vs Auto-Fix

### Auto-Fix (Don't Ask)

✅ Schema cache refresh (run script)
✅ Migration verification (run existing scripts)
✅ Documentation updates (known pattern)
✅ Adding .applied marker to migrations

### Ask User (Don't Assume)

❓ Incrementing build number (user decides)
❓ Creating new migration SQL (user provides requirements)
❓ Changing RLS policies (security implications)
❓ Deleting data (destructive action)
❓ Publishing build to production (requires approval)

---

## Maintenance

### After Each Build

If new error encountered:
1. Document in this runbook
2. Include build number reference
3. Add to relevant section

### Monthly Review

Check if:
- Solutions still valid (environment may change)
- New patterns emerged (consolidate similar errors)
- Outdated solutions (remove if no longer applicable)

---

**Last Updated:** Build 32 (2025-12-12)
**Total Errors Documented:** 20+
**Builds Covered:** 1-32
**Time Saved:** ~3-5 minutes per error (vs debugging from scratch)
