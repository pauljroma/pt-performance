# Linear Reality Check - 2025-12-12
**Current Build:** 35 (deployed to TestFlight)
**Linear Project Status:** 50/50 issues marked "Done" (100%)
**Actual Completion:** ~85% (gaps identified below)

---

## ✅ Actually Complete (Verified in Codebase)

### iOS Patient App
- **ACP-92**: Supabase Swift SDK integrated ✅
  - File: `Services/SupabaseClient.swift`
  - Auth flow working

- **ACP-93**: Today Session screen ✅
  - File: `TodaySessionView.swift`
  - Loads real data from backend

- **ACP-94**: Exercise logging UI ✅
  - File: `Views/Patient/ExerciseLogView.swift`
  - Submits to Supabase via `ExerciseLogService.swift`

- **ACP-95**: History view with charts ✅
  - File: `Views/Patient/HistoryView.swift`
  - Pain/adherence charts implemented

### iOS Therapist Dashboard
- **ACP-96**: Patient list view ✅
  - File: `TherapistDashboardView.swift`
  - Shows patients with adherence, flags

- **ACP-97**: Patient detail screen ✅
  - File: `Views/Therapist/PatientDetailView.swift`
  - Charts and flags displayed

- **ACP-98**: Program viewer ✅
  - File: `Views/Therapist/ProgramViewerView.swift`
  - Phases → Sessions → Exercises hierarchy

- **ACP-99**: Notes interface ✅
  - File: `Views/Therapist/NotesView.swift`
  - Therapist can add/view notes

### Build 35 Addition (NOT in Linear)
- **Programs Tab (List Only)** ✅
  - File: `TherapistProgramsView.swift`
  - Shows all programs from database
  - Navigation to program viewer
  - **NEW - Not tracked in Linear!**

---

## ⚠️ Partially Complete (Marked Done but Has TODOs)

### Program Management
- **ACP-80**: Program Builder Integration
  - Status: Linear says "Done" but has TODOs
  - File: `ViewModels/ProgramBuilderViewModel.swift:111`
  - TODO: `// TODO: Implement Supabase save`
  - **Reality:** UI skeleton exists, database save NOT implemented

- **Program Editor**
  - File: `ViewModels/ProgramEditorViewModel.swift`
  - Line 46: `// TODO: Load from Supabase`
  - Line 57: `// TODO: Implement Supabase query`
  - Line 109: `// TODO: Save to Supabase`
  - **Reality:** ViewModel exists, all CRUD operations are stubs

### Patient Filtering
- **ACP-96** (Patient List)
  - File: `ViewModels/PatientListViewModel.swift:134`
  - TODO: `// TODO: Join with patients table to filter by therapist`
  - **Reality:** Shows all patients, not filtered by therapist

---

## ❌ Not Started (No Code Found)

### Backend Services
- **Agent Backend**: No agent-service directory found in iOS app
- **PT Assistant Endpoints**: No implementation found
- **Plan Change Requests**: No automation found

### Database
- **Migrations**: Several .sql.applied files suggest migrations were run manually
  - Migration automation incomplete

---

## 📊 Actual Completion Breakdown

| Category | Linear Status | Reality | Gap |
|----------|--------------|---------|-----|
| iOS Patient App | 100% Done | 95% Complete | Exercise log edge cases |
| iOS Therapist Dashboard | 100% Done | 90% Complete | Program creation missing |
| Program Management | 100% Done | 40% Complete | **MAJOR GAP** - No create/edit |
| Backend Services | 100% Done | Unknown | Not in iOS repo |
| Database | 100% Done | 95% Complete | Some TODOs in views |

**Overall Assessment:** 85% actually complete

---

## 🔍 Key Discrepancies

### 1. Program Builder (ACP-80)
**Linear:** ✅ Done
**Reality:** ⚠️ Skeleton only - cannot create programs
**Fix Needed:** Implement save logic in `ProgramBuilderViewModel.swift`

### 2. Program Editor
**Linear:** No specific issue
**Reality:** ⚠️ ViewModel exists but all methods are TODO stubs
**Fix Needed:** Implement load/query/save methods

### 3. Therapist Patient Filtering (ACP-96)
**Linear:** ✅ Done
**Reality:** ⚠️ Shows ALL patients, not filtered by therapist
**Fix Needed:** Implement therapist filtering

### 4. Build 35 Programs Tab
**Linear:** ❌ No issue exists
**Reality:** ✅ Fully implemented and deployed!
**Fix Needed:** Create Linear issue retrospectively

---

## 📋 Recommended Linear Updates

### Issues to Reopen
1. **ACP-80** - Program Builder Integration
   - Change status: Done → In Progress
   - Add comment: "UI skeleton complete, database save pending"

### Issues to Create
1. **Program Creator - Database Save**
   - Implement ProgramBuilderViewModel.createProgram()
   - Save to Supabase programs table
   - Estimated: 2-3 hours

2. **Program Editor - CRUD Operations**
   - Implement load/query/save in ProgramEditorViewModel
   - Estimated: 4-6 hours

3. **Therapist Patient Filtering**
   - Filter patients by therapist_id
   - Update PatientListViewModel query
   - Estimated: 1-2 hours

4. **Programs Tab Implementation** (Retroactive)
   - Document Build 35 completion
   - Mark as Done immediately

---

## 🎯 Current State Summary

**What Works:**
- Patient can log in, view sessions, log exercises
- Therapist can view patients, see details, view programs, add notes
- Programs can be VIEWED (Build 35)
- Exercise logging saves to database
- Charts display pain/adherence trends

**What Doesn't Work:**
- Cannot CREATE new programs (UI exists, save missing)
- Cannot EDIT existing programs (all stubs)
- Patient list shows ALL patients (not filtered by therapist)
- No backend agent service (unclear if it should be in iOS repo)

**Deployment Status:**
- Build 35 deployed to TestFlight ✅
- Contains Programs Tab (not in Linear)
- All builds functional for viewing/logging
- Creation/editing features incomplete

---

## 📌 Next Actions

1. ✅ **Review Complete** - This document
2. ⏭️ **Update Linear** - Reopen ACP-80, create 3 new issues
3. ⏭️ **Implement Missing Features** - Program create/edit, filtering

---

**Prepared By:** Claude Code
**Date:** 2025-12-12
**Purpose:** Reconcile Linear project status with actual codebase state
**Recommendation:** Update Linear to reflect reality, then complete remaining features
