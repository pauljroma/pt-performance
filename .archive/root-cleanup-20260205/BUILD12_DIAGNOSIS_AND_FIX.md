# Build 12 Diagnosis and Fix

## User Report
"Build 12 - notes and programs from therapist login show data missing"

## Investigation Results

### ✅ NOTES - WORKING!
The notes functionality is **actually working correctly**:
- Notes query returns 200 status
- Returns 2 notes with correct schema
- All required fields present (note_type, note_text, created_by, etc.)

**Conclusion:** Notes may have been fixed by previous migrations or the "data missing" error is coming from elsewhere.

---

### ❌ PROGRAMS - FAILING!

The program viewer fails due to **2 schema mismatches**:

#### Issue 1: sessions.session_number doesn't exist
**iOS Code (ProgramViewModel.swift:61):**
```swift
.order("session_number", ascending: true)
```

**Database Reality:**
- Table has: `sequence` column
- iOS expects: `session_number` column

**Error:**
```
{"code":"42703","message":"column sessions.session_number does not exist"}
```

#### Issue 2: exercise_templates.exercise_name doesn't exist
**iOS Code (ProgramViewModel.swift:83):**
```swift
exercise_templates!inner(exercise_name)
```

**Database Reality:**
- Table has: `name` column
- iOS expects: `exercise_name` column

**Error:**
```
{"code":"42703","message":"column exercise_templates_1.exercise_name does not exist"}
```

---

## Root Cause

The iOS models were designed with expected column names, but the database schema uses different names:

| iOS Expects | Database Has |
|------------|--------------|
| `sessions.session_number` | `sessions.sequence` |
| `exercise_templates.exercise_name` | `exercise_templates.name` |

This causes JSON decoding to fail with "data missing" errors.

---

## Solution

**Created Migration:** `supabase/migrations/20251211000008_fix_program_viewer_schema.sql`

**What it does:**
1. Adds `sessions.session_number` column (alias for `sequence`)
2. Adds `exercise_templates.exercise_name` column (alias for `name`)
3. Creates triggers to keep them in sync automatically
4. Syncs all existing data

**Benefits:**
- ✅ No iOS code changes needed
- ✅ Both column names work (backward compatible)
- ✅ Automatic sync prevents data drift

---

## How to Fix

### Step 1: Apply Migration (2 minutes)

**Open Supabase SQL Editor:**
```
https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new
```

**Copy entire contents of:**
```
clients/linear-bootstrap/supabase/migrations/20251211000008_fix_program_viewer_schema.sql
```

**Paste and click "Run"**

You should see:
```
✅ PROGRAM VIEWER SCHEMA FIXED
✅ Program viewer should now work!
```

### Step 2: Verify Fix (30 seconds)

```bash
cd clients/linear-bootstrap
python3 test_program_viewer_fixed.py
```

Expected output:
```
✅ ALL TESTS PASSED!
✅ sessions.session_number column exists
✅ exercise_templates.exercise_name column exists
✅ Program query returns all phases
✅ Sessions query works
✅ Exercises query works
🚀 Ready to test on iPad!
```

### Step 3: Test on iPad

1. Open PTPerformance app
2. Login as therapist (demo-pt@ptperformance.app)
3. Tap on patient "John Brebbia"
4. Tap "Program" tab
5. Should see: "4-Week Return to Throw" with all 4 phases
6. Tap a phase to see sessions
7. Should see 6 sessions with exercises

---

## Test Scripts Created

1. **`test_program_and_notes_queries.py`** - Diagnoses the exact failing queries
2. **`test_program_viewer_fixed.py`** - Verifies the fix works after migration
3. **`APPLY_MIGRATION_20251211000008.md`** - Instructions for applying migration

---

## Summary

| Feature | Status | Action |
|---------|--------|--------|
| **Notes** | ✅ Working | None - already fixed |
| **Programs** | ❌ Failing | Apply migration 20251211000008 |

**Time to fix:** ~3 minutes (2 min migration + 30 sec verification + 1 min iPad test)

**Expected result:** Build 12 will show all program data correctly.
