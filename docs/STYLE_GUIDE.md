# PT Platform – Style & Naming Guide

This style guide keeps everything coherent across:
- Linear (plans, issues, zones)
- Docs (specs, epics, runbooks)
- Code (Swift, SQL, backend)
- UX (what the product feels like)

Use this for humans AND agents.

---

## 1. Naming Conventions

### 1.1 Projects / Epics (Linear)

**Pattern:**
`[MVP or Theme] — [Short, Outcome-Oriented Name]`

Examples:
- `MVP 1 — PT App & Agent Pilot`
- `EPIC — Throwing & On-Ramp Model`
- `EPIC — Strength & S&C Model`

Avoid:
- Vague: "Backend work", "Random stuff"
- Overly clever names without context

---

### 1.2 Issues (Linear)

**Pattern:**
`[Verb] [Object] [Context]`

Examples:
- `Define Supabase Schema for PT App`
- `Implement Today Session Screen (Patient)`
- `Create PT Agent Plan-Change Endpoint`
- `Add Pain Rule Engine Tests`

Avoid:
- "Do data"
- "Build backend"
- "More UI"

**Titles are human-readable, Objective field is the detailed intent.**

---

### 1.3 Files & Folders

**Docs:**

- `/docs/` → top-level specs
- `/docs/epics/` → epic-specific detail
- `/docs/runbooks/` → step-by-step execution guides
- `/docs/system/` → governance, mapping, architecture

**Naming:**

- `PT_APP_VISION.md`
- `EPIC_A_PERSONAL_CLINICAL_CONTEXT.md`
- `RUNBOOK_DATA_SUPABASE.md`
- `AGENT_GOVERNANCE.md`
- `LINEAR_MAPPING_GUIDE.md`

Use:
- `UPPER_SNAKE` for high-level specs/runbooks.
- `EPIC_X_*` to cluster related epics.

---

## 2. Writing Style for Docs

### 2.1 Tone

- Clear, direct, professional.
- Short sentences.
- Avoid fluff and marketing language.
- Prefer bullet points when possible.

**Example (GOOD):**
> "Agents must check Linear before coding. If the zone label is missing, stop and fix the issue."

**Example (AVOID):**
> "In order to ensure maximum synergy, agents should probably try their best to check Linear…"

---

### 2.2 Structure

For major docs (vision, epics, specs, runbooks):

**Order:**
1. Purpose
2. Scope / Boundaries
3. Inputs / Dependencies
4. Requirements (grouped)
5. Agent Tasks or Implementation Steps
6. Definition of Done

Use `##` and `###` headings, not deeper than `####` unless absolutely necessary.

---

### 2.3 Definitions of Done (DoD)

Always include **concrete** DoD for any task or runbook step:

- What must be true in the DB?
- What must be visible in UI?
- What must pass (tests / behaviors)?
- What must be updated in Linear?

**Pattern:**

```markdown
**Definition of Done (DoD):**
- Condition 1
- Condition 2
- Condition 3
```

---

## 3. Linear Usage Style

### 3.1 Labels
- Zones: zone-7, zone-8, zone-12, etc.
- Approval / risk: zone-4b
- Optional: add needs-approval or throwing, S&C, mobile as thematic labels.

Every issue must have:
- At least one zone-* label.
- Clear Objective and Scope fields filled.

### 3.2 Statuses

Recommended flow:
- Backlog → idea / not ready
- Todo → ready to be picked up
- In Progress → actively being worked
- In Review → waiting for approval / QA
- Done → completed
- Blocked → needs input or fix

Agents:
- Move Todo → In Progress → In Review → Done as they work.
- NEVER move directly from Todo → Done.

---

## 4. UX / UI Style (App)

### 4.1 Visual Feel
- Clean, simple, athletic-clinical hybrid.
- Think: "pro training facility x modern health app".

Colors (high-level):
- Primary: Deep blue or navy (trust, clinical).
- Accent: A single highlight color (e.g., teal or green) for progress & success.
- Alerts: Red/amber for flags and pain warnings.
- Background: Light / neutral, avoid heavy color blocks.

Let Claude propose an exact palette later; keep this guide conceptual.

---

### 4.2 Layout Principles
- iPhone (patient): one main action per screen.
  - Home → "Start Session"
  - Session → log quickly, minimal scrolling.
- iPad (therapist): master-detail layouts.
  - Left panel: patients / programs.
  - Right panel: detail & charts.

Spacing:
- Generous padding (12–24 pts).
- Avoid tight, dense tables for patients; use cards or grouped lists.

---

### 4.3 Interaction Principles
- Primary actions on the right or bottom.
- Destructive actions (e.g., delete) should:
  - Require confirmation.
  - Be visually distinct (red).

Text:
- Use human language:
  - "Today's session"
  - "How did it feel?"
- Avoid jargon on patient-side screens.

Charts:
- Use sparklines or simple line charts.
- Do not overload with filters in v1.

---

## 5. Code Style (High-Level)

### 5.1 Swift / SwiftUI
- File-per-view pattern for main screens.
- Keep views small and composable.
- Use ViewModel structs/classes for non-trivial logic.
- Prefer @StateObject / @ObservedObject for app state.
- No massive God views; keep business logic out of SwiftUI bodies when possible.

Naming:
- TodaySessionView, PatientHistoryView, TherapistDashboardView.

---

### 5.2 Backend (Node/Python)
- Consistent function names:
  - getPatientSummary
  - getTodaySession
  - createPlanChangeRequest
- Error handling:
  - Return structured JSON { error: "code", message: "...", details: {} }
- One file per concern when it grows:
  - supabaseClient, linearClient, ptAssistantService, etc.

---

### 5.3 SQL / Schema
- Lowercase with underscores:
  - patients, exercise_logs, body_comp_measurements
- Primary keys: id (UUID)
- Foreign keys:
  - patient_id, therapist_id, session_id, etc.
- Views: prefix with vw_:
  - vw_patient_adherence, vw_pain_trend.

---

## 6. Agent Prompting Style

When writing prompts or instructions for Claude/agents:
- Be explicit about:
  - Which doc(s) to use
  - Which zone to operate in
  - Which Linear issue ID to work against
- Always mention:
  - "Update Linear with a progress comment and status when done."

Pattern (for prompts):

```
"Using PT_APP_PLAN.md and RUNBOOK_DATA_SUPABASE.md, work on issue ACP-7 (zone-7, zone-8).
Implement Step A only.
When finished, summarize the change in a Linear comment and move status to In Progress (if still working) or In Review (if done)."
```

---

## 7. Documentation Hygiene
- Keep docs evergreen: if something changes materially, update the doc or add a short "Revision history" at the top.
- No raw secrets (API keys, tokens) in docs.
- If a doc is draft-level, mark clearly at the top:
  - > STATUS: DRAFT
- If a doc is authoritative, mark:
  - > STATUS: SOURCE OF TRUTH

---

## 8. "Looks Good" Checklist

Before you consider a thing "done and polished," check:
- Names are consistent with this guide.
- Issue titles are clear and action verbs lead.
- Each spec/epic has:
  - Purpose
  - Requirements
  - Tasks
  - DoD
- UI screenshots (later) or diagrams, where helpful, are:
  - Legible
  - Labeled
  - Free of clutter

This checklist is for humans AND agents.

---
