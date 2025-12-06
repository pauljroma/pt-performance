# Linear Mapping Guide – From Docs to Issues

## Goals

Provide a clear mapping so an LLM agent can:
- Read docs in `/docs` and `/docs/epics`
- Create / update Linear issues correctly
- Attach the right zones, priorities, and definitions of done

---

## Teams & Project

- Team: `Agent-Control-Plane`
- Project: `MVP 1 — PT App & Agent Pilot`

All issues in this scope should live here.

---

## Zones and Typical Work

- zone-7: Schema, SQL, Supabase
- zone-8: Storage / migrations
- zone-10b: Tests / quality / data checks
- zone-12: SwiftUI iOS app + general development
- zone-3c: PT agent backend / AI runtime
- zone-4b: Plan Change Requests / approvals
- zone-13: Monitoring / logging
- zone-3a/3b: Planning / context (rarely for individual issues)

---

## Priority Defaults

- High:
  - Initial schema
  - Today Session flow
  - PT agent backend skeleton
  - Anything needed for first end-to-end demo
- Medium:
  - Analytics views
  - Strength targets
  - Dashboard polish
- Low:
  - Nice-to-have refinements
  - Advanced metrics

---

## Issue Fields

Each issue should have:

- **Title**: short, action-oriented, e.g. "Implement pain rule engine for PT assistant"
- **Objective**: 1–3 sentences
- **Scope (Allowed Changes)**: files / areas agents can touch
- **Definition of Done**: concrete acceptance criteria
- **Impact**: optional (Low/Medium/High)
- **Zone labels**: 1–2 zone-* labels

---

## Example Mapping

- `EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md` → issues:
  - "Implement 1RM utilities" → zone-7, zone-10b, High
  - "Add rm_estimate to exercise_logs" → zone-7, zone-8, High
  - "Add therapist strength target UI" → zone-12, Medium

- `EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md` → issues:
  - "Normalize bullpen tracker to bullpen_logs" → zone-7, zone-8, High
  - "Create vw_throwing_workload" → zone-7, zone-10b, Medium
  - "Implement throwing workload flags and Plan Change Requests" → zone-3c, zone-4b, High

---

## Instructions to Agents

1. Read the epics and specs.
2. For each major bullet under "Tasks" or "Agent Tasks":
   - Create a Linear issue under `MVP 1 — PT App & Agent Pilot`.
   - Apply zone labels as specified.
   - Use the "Agent Task" template when possible.
3. Keep all changes within these issues.
4. Never create unzoned issues.
