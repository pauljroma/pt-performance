# New Linear Issues Specification
**Date:** 2025-12-12
**Purpose:** Track remaining TODOs discovered in Build 35 reality check
**Project:** MVP 1 — PT App & Agent Pilot

---

## Issue 1: Program Creator - Database Save Implementation

**Title:** Implement Program Creator database save (ProgramBuilderViewModel)

**Description:**
Complete the Program Builder implementation by adding database save functionality.

**Current State:**
- UI skeleton exists ✅
- ProgramBuilderViewModel exists ✅
- createProgram() method is a TODO stub ❌

**File:** `ViewModels/ProgramBuilderViewModel.swift:111`

**TODO Code:**
```swift
// TODO: Implement Supabase save
/*
do {
    let programData: [String: Any] = [
        "name": programName,
        "protocol_id": selectedProtocol?.id.uuidString,
        "patient_id": patientId?.uuidString,
        "created_at": Date().ISO8601Format()
    ]

    let response = try await supabase
        .from("programs")
        .insert(programData)
        .execute()

    // Save phases...
} catch {
    print("Error creating program: \(error)")
}
*/
```

**Acceptance Criteria:**
- [ ] createProgram() saves to Supabase programs table
- [ ] Phases are saved to phases table
- [ ] Foreign keys are valid
- [ ] Error handling for save failures
- [ ] Success confirmation to user
- [ ] Navigation back to programs list

**Estimated Time:** 2-3 hours

**Priority:** High

**Labels:** `zone-12`, `zone-7`, `build-36`

**Dependencies:** None - Build 35 UI is ready

---

## Issue 2: Program Editor - CRUD Operations

**Title:** Implement Program Editor load/query/save operations

**Description:**
Complete the Program Editor implementation by implementing all CRUD operations currently marked as TODO.

**Current State:**
- ProgramEditorViewModel exists ✅
- All methods are TODO stubs ❌

**Files & TODOs:**
1. `ViewModels/ProgramEditorViewModel.swift:46`
   - `// TODO: Load from Supabase`

2. `ViewModels/ProgramEditorViewModel.swift:57`
   - `// TODO: Implement Supabase query`

3. `ViewModels/ProgramEditorViewModel.swift:109`
   - `// TODO: Save to Supabase`

**Required Methods:**
1. **loadProgram(programId: String)**
   - Fetch program from Supabase
   - Load associated phases
   - Populate ViewModel state

2. **queryExercises(filters: [String: Any])**
   - Query exercise templates
   - Filter by category/body region
   - Return paginated results

3. **saveProgram()**
   - Update program in Supabase
   - Update phases
   - Handle validation errors

**Acceptance Criteria:**
- [ ] Can load existing program into editor
- [ ] Can query and filter exercises
- [ ] Can save modifications to program
- [ ] Validation before save
- [ ] Error handling for each operation
- [ ] Loading states in UI

**Estimated Time:** 4-6 hours

**Priority:** High

**Labels:** `zone-12`, `zone-7`, `build-36`

**Dependencies:** None

---

## Issue 3: Therapist Patient Filtering

**Title:** Filter patient list by therapist_id (not show all patients)

**Description:**
Currently the therapist dashboard shows ALL patients in the database. It should only show patients assigned to the logged-in therapist.

**Current State:**
- Patient list loads ✅
- Shows ALL patients (no filtering) ❌

**File:** `ViewModels/PatientListViewModel.swift:134`

**TODO Code:**
```swift
// TODO: Join with patients table to filter by therapist
```

**Current Query:**
```swift
func loadPatients(therapistId: String? = nil) async {
    let response = try await supabase.client
        .from("patients")
        .select()
        .execute()
    // Returns ALL patients
}
```

**Required Query:**
```swift
func loadPatients(therapistId: String) async {
    let response = try await supabase.client
        .from("patients")
        .select()
        .eq("therapist_id", value: therapistId)
        .execute()
    // Returns only therapist's patients
}
```

**Acceptance Criteria:**
- [ ] Patient list filtered by therapist_id
- [ ] Uses therapist ID from auth session
- [ ] Empty state if therapist has no patients
- [ ] No crashes if therapist_id is nil
- [ ] Update patient model if therapist_id field missing

**Estimated Time:** 1-2 hours

**Priority:** Medium

**Labels:** `zone-12`, `zone-7`, `build-36`

**Dependencies:** Verify `patients` table has `therapist_id` column

---

## Issue 4: Programs Tab Implementation (Retroactive - Build 35)

**Title:** ✅ Programs Tab - View All Programs (Completed in Build 35)

**Description:**
Document the Programs Tab implementation completed in Build 35.

**Implemented Features:**
- Fetch all programs from Supabase ✅
- Display program cards with patient info ✅
- Show program name, duration, target level ✅
- Clickable cards open ProgramViewerView ✅
- Pull-to-refresh support ✅
- Loading states and error handling ✅
- Empty state when no programs exist ✅

**Files Created:**
- `TherapistProgramsView.swift` (196 lines)
- Added `ProgramsListViewModel` class
- Added `ProgramListCard` component
- Added `ProgramListItem` model

**Database Query:**
```sql
SELECT
    id,
    patient_id,
    name,
    target_level,
    duration_weeks,
    created_at,
    patients!inner(first_name, last_name)
FROM programs
ORDER BY created_at DESC
```

**Completion:**
- Implemented: 2025-12-12
- Deployed: Build 35 to TestFlight
- Status: ✅ Complete

**Priority:** N/A (Already done)

**Labels:** `zone-12`, `zone-7`, `build-35`, `completed`

**Note:** This issue should be created and immediately marked as Done for tracking purposes.

---

## Issue 5: Program Builder UI Integration

**Title:** Add "Create Program" button to Programs Tab

**Description:**
The Programs Tab currently shows existing programs. Add a "Create Program" button that navigates to the Program Builder.

**Current State:**
- Programs Tab displays list ✅
- No create button ❌
- ProgramBuilderView exists (not integrated)

**Required Changes:**
1. Add "+" button to Programs Tab toolbar
2. Navigate to ProgramBuilderView on tap
3. Wire up ProgramBuilderViewModel
4. Return to Programs Tab after create
5. Refresh list to show new program

**Acceptance Criteria:**
- [ ] "+" button in navigation bar
- [ ] Tapping opens Program Builder
- [ ] Can select protocol/template
- [ ] Can add phases
- [ ] Save button creates program (requires Issue #1)
- [ ] Success confirmation
- [ ] List refreshes automatically

**Estimated Time:** 2 hours

**Priority:** Medium

**Labels:** `zone-12`, `build-36`

**Dependencies:** Issue #1 (database save must be implemented first)

---

## Summary

**Total New Issues:** 5
- 3 implementation issues (6-11 hours total)
- 1 retroactive documentation issue
- 1 UI integration issue

**Priority Breakdown:**
- High: 2 issues (Program Creator, Program Editor)
- Medium: 2 issues (Patient Filtering, UI Integration)
- Done: 1 issue (Programs Tab - retroactive)

**Recommended Implementation Order:**
1. Issue #1: Program Creator save (enables creation workflow)
2. Issue #5: Add Create button (completes user flow)
3. Issue #3: Patient Filtering (fixes data leak)
4. Issue #2: Program Editor (advanced feature)
5. Issue #4: Create retroactive issue for documentation

**Build 36 Scope:**
If we complete Issues #1, #3, and #5, Build 36 will have:
- Full program creation workflow
- Proper patient filtering by therapist
- Complete programs management

---

**Next Step:** Create these issues in Linear manually or implement create_issue() method in linear_client.py
