# AGENT GOVERNANCE – Rules of Engagement for All AI Agents

This document defines the rules every agent must follow when interacting with:
- Linear (source of truth)
- Supabase (patient data)
- SwiftUI client code
- PT program logic
- Plan change requests

---

## 1. Core Principles

### 1.1 Linear Is the Source of Truth
Agents MUST:
- Read the current plan from Linear before acting.
- Update issues with progress comments.
- Never close issues without completion criteria.
- Never modify plan structures outside of Linear.

### 1.2 Zones Drive Behavior
Each task must have a zone label:

- **zone-3a** Cognitive planning
- **zone-3b** Context retrieval / RAG
- **zone-3c** AI runtime & agent backend
- **zone-4a** Control & orchestration
- **zone-4b** Approval flow (PT sign-off)
- **zone-7** Data management
- **zone-8** Persistent storage (Supabase)
- **zone-10b** Quality (tests, validation, queries)
- **zone-12** Development (app, backend)
- **zone-13** Monitoring

Agents must:
- Assign themselves the correct zones.
- Not work outside assigned zones.

### 1.3 Approval Workflow (zone-4b)
Any change to:
- A patient's program
- Session structure
- Therapist-facing logic
- Pain thresholds
- Return-to-throw flow

MUST create a **Plan Change Request** issue using the template and move to **In Review**.

Only the PT or Paul may approve.

---

## 2. Behavioral Rules for Agents

### 2.1 Before Coding
Agents must:
1. Sync Linear (`/sync-linear` or equivalent).
2. Read issue objective + scope.
3. Confirm zone labels and constraints.
4. Retrieve context from `/docs`.

### 2.2 While Coding
- Follow SwiftUI, SQL, and backend guidelines.
- Use minimal dependencies.
- Never modify database without a migration.
- Link commits to Linear issues.

### 2.3 After Coding
Agents must:
- Update Linear issue with comment summarizing changes.
- Attach code block of final diff (if available).
- Move issue to "In Review".
- Notify approval channel if zone-4b.

---

## 3. PT Clinical Safety Rules

Agents MUST:
- Never give medical advice.
- Never override a therapist decision.
- Never automatically increase intensity if pain is trending up.
- Never shorten taper or return-to-throw phases.
- Always propose changes via a **Plan Change Request**.

---

## 4. Logging & Observability (zone-13)

Agents must log:
- Issue ID
- Zone
- Command type (read, write, propose-change)
- Timestamp
- Error or success state

Logs stored in `logs/agent_log.md` for v1.
