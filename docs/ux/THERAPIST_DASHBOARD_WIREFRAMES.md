# THERAPIST DASHBOARD – Wireframe Spec (iPad)

**Purpose:** Describe core layout and information architecture for the therapist dashboard without visuals, so agents and devs can implement consistent UI.

---

## Screen 1 – Patients Overview

### Layout

**Left column (List)**
- Search box: "Search patients…"
- List of patient rows:
  - Name
  - Highlight chip: Active Program name
  - Small tag: RHP, HS, Post-op, etc.
  - Micro-metrics:
    - Adherence %
    - Pain icon (green/yellow/red)
    - Velocity trend arrow (if pitcher)

**Right side (Detail pane)**
- If no patient selected → "Select a patient to view details."
- When selected → loads Screen 2.

---

## Screen 2 – Patient Detail

**Header**
- Name, age, team
- Active program + phase
- Injury summary line (if any)

**Section A – Key Metrics (cards)**
- Readiness Score (0–100)
- Last 7-day adherence
- Last 7-day pain avg
- Last bullpen velocity (if pitcher)

**Section B – Charts**
- Pain trend chart (last 30 days)
- Velocity trend chart (if applicable)

**Section C – Sessions**
- List of last N sessions:
  - Date
  - Type (strength, bullpen, plyo)
  - Completion indicator
  - Pain summary

**Section D – Flags**
- List of active flags with severity:
  - "High pain during bullpen"
  - "Low adherence"
  - "Velocity drop"

---

## Screen 3 – Program Viewer

**Left (hierarchy)**
- Phases list
- On click → Sessions list for that phase

**Right (detail)**
- Session details:
  - Name, day, intensity
  - Exercise list
  - Throwing components (if any)

---

## DoD

- Layout implemented in SwiftUI using these sections.
- All content wired to live data.
- Resizable / scrollable to handle many patients.
- Clean, uncluttered, aligned to DESIGN_TOKENS.md.
