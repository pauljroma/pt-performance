# PT App – MVP 1 Plan (for Linear)

> This file is designed for an LLM agent (Claude) to read and translate into Linear issues
> under the project "MVP 1 — PT App & Agent Pilot" in the Agent-Control-Plane team.
> Each task should become a Linear issue with the indicated zone labels and priority.

---

## Workstream A – Data & Supabase (Zones: zone-7, zone-8)

**Goal:** Solid, clean data model and basic views for PT programs and logs.

### A1. Design Logical Data Model  (zone-7, High)
- Define entities: Therapist, Patient, Program, Phase, Session, ExerciseTemplate, SessionExercise, ExerciseLog, PainLog, Assessment, Note.
- Document relationships and key fields in `docs/SCHEMA.md`.

### A2. Implement Supabase Schema  (zone-7, zone-8, High)
- Translate logical model into Postgres tables.
- Create `infra/supabase_schema.sql` with CREATE TABLE statements.
- Apply migrations to Supabase dev project.

### A3. Seed Demo Patient & Program  (zone-7, zone-8, Medium)
- Insert one therapist and one patient (John Brebbia-style profile).
- Seed a 4-week On-Ramp program with 3 sessions per week.
- Ensure data visible via Supabase dashboard.

### A4. Basic Views for Adherence & Pain  (zone-7, zone-8, Medium)
- Create SQL views:
  - `vw_patient_adherence` (sessions completed vs scheduled).
  - `vw_pain_trend` (pain over time per patient).
- Document columns and usage in `docs/ANALYTICS.md`.

---

## Workstream B – Mobile Client (SwiftUI) (Zone: zone-12)

**Goal:** Universal SwiftUI app with patient + therapist flows wired to Supabase.

### B1. Create SwiftUI App Skeleton  (zone-12, High)
- New Xcode project `PTPerformance`.
- Set up navigation structure:
  - Auth flow.
  - Patient tab.
  - Therapist tab.
- Integrate Supabase SDK for auth.

### B2. Patient "Today's Session" Screen  (zone-12, High)
- Fetch today's session + exercises for logged-in patient.
- Render exercises with sets/reps/load and pain sliders.
- Local state for edit before submit.

### B3. Submit Session Log  (zone-12, Medium)
- POST exercise and pain logs to Supabase.
- Handle success/error states.
- Show simple completion confirmation.

### B4. Therapist Dashboard (v1)  (zone-12, Medium)
- List assigned patients.
- For each:
  - Last session date.
  - Adherence % (from view).
  - Simple pain indicator.

---

## Workstream C – PT Agent Backend (Zones: zone-3c, zone-12)

**Goal:** Minimal backend service that can query Supabase and talk to Linear.

### C1. Backend Skeleton  (zone-3c, zone-12, High)
- Node or Python service (choose one and document).
- Basic health endpoint.
- Config via env: Supabase URL/key, Linear API key.

### C2. Supabase Query Endpoints  (zone-3c, zone-12, Medium)
- Endpoint: `/patient-summary/{patientId}`:
  - Program info.
  - Last N sessions.
  - Pain trend.
- Endpoint: `/today-session/{patientId}`:
  - Data used by PT assistant or future chat.

### C3. Linear Integration Layer  (zone-3c, zone-12, High)
- Functions to:
  - Create issues in Agent-Control-Plane.
  - Add comments and update status.
- Use existing MCP/Linear client where possible.

### C4. Plan Change Request Creator  (zone-3c, zone-4b, High)
- Function that:
  - Takes a structured plan-change proposal.
  - Creates a "Plan Change Request" issue in Linear with zone-4b.
  - Optionally posts to Slack channel.

---

## Workstream D – Governance & Observability (Zones: zone-4a, zone-4b, zone-10b, zone-13)

**Goal:** Keep agents safe and transparent.

### D1. Label & Status Conventions  (zone-4a, Low)
- Document how to use:
  - zone-* labels.
  - Statuses (Todo, In Progress, In Review, Done, Blocked).
- Add to `docs/AGENT_GOVERNANCE.md`.

### D2. Approval Flow Definition  (zone-4b, Medium)
- Define when plan changes require:
  - PT approval only.
  - PT + medical oversight (placeholder).
- Document triggers for zone-4b usage.

### D3. Basic Logging & Metrics  (zone-13, Medium)
- Log agent-service calls:
  - Which Linear issue.
  - Which patient.
  - Success/failure.
- Simple stats in a markdown or dashboard for iteration.

---

## Instructions to Claude

1. Read `PT_APP_VISION.md`, `PT_APP_ARCHITECTURE.md`, and this `PT_APP_PLAN.md`.
2. For each task above:
   - Create or update matching Linear issues under project "MVP 1 — PT App & Agent Pilot".
   - Apply correct zone labels.
   - Set priority (High/Medium/Low) as indicated.
3. Keep Linear as the single source of truth for task state.
4. Before executing code changes, always:
   - Re-sync from Linear.
   - Pick tasks from appropriate zones.
   - Update Linear with comments and status as work progresses.
