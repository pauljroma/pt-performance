# RUNBOOK – Therapist Dashboard (iPad)
Zones: zone-12, zone-3c, zone-7
Goal: Provide comprehensive patient monitoring for therapists

---

## 1. Preparation

Inputs:
- `EPIC_H_THERAPIST_DASHBOARD`
- Supabase schema
- Flag engine outputs

---

## 2. Steps

### Step A — Patient List
Query:
- name
- adherence %
- last session date
- pain indicator
- flags

UI:
- Table view in SwiftUI
- Color-coded pain and flags

**DoD:**
- Correct summary for seeded patient

---

### Step B — Patient Detail Screen
Sections:
- Header (name, program, phase)
- Charts (pain trend, velocity if pitcher)
- Session history
- Flags

**DoD:**
- Interacts smoothly
- Data loads correctly
- No crashes

---

### Step C — Program Viewer
Render:
- Phase list
- Sessions inside phase
- Exercises inside session

**DoD:**
- Matches DB state
- SwiftUI navigation clean

---

### Step D — Patient Notes & Assessments
Implement:
- Add therapist note
- View historical notes
- Tag notes to sessions

**DoD:**
- Notes save to `session_notes`
- Display chronologically

---

## 3. Final Outputs
- Complete therapist dashboard
- Patient monitoring interface
- Note-taking capability
- Flag visualization
