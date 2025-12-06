# PT App – High-Level Architecture

## 1. Components

1. **iOS/iPadOS Client (SwiftUI)**
   - Therapist mode (iPad-optimized).
   - Patient mode (iPhone-optimized).
   - Auth via Supabase.
   - Screens:
     - Login / onboarding.
     - Therapist dashboard: patients, programs, recent flags.
     - Program editor: phases → sessions → exercises.
     - Patient session view: "Today's session" with logging UI.
     - History & trends (basic charts).

2. **Supabase Backend (Postgres + Auth + Storage)**
   - Postgres schema for:
     - therapists, patients
     - programs, phases, sessions
     - exercise_templates, session_exercises
     - exercise_logs, pain_logs
     - assessments, notes
   - Row-level security (patients only see own data; therapists see their panel).
   - Basic SQL views for:
     - adherence metrics
     - pain trends
     - recent session summaries.

3. **Agent Service Backend**
   - Node or Python service.
   - Connects to:
     - Supabase (read/write).
     - Linear (GraphQL API).
   - Responsibilities:
     - PT Assistant (query program & results and answer "PT-style" within guardrails).
     - Plan change proposals → create "Plan Change Request" issues in Linear.
     - Slack/WhatsApp approval webhooks.

4. **Agent Control Plane**
   - **Linear**:
     - Team: Agent-Control-Plane.
     - Project: MVP 1 — PT App & Agent Pilot.
     - Zone labels: zone-3a/3b/3c/4a/4b/7/8/10b/12/13.
     - Templates: Agent Task, Plan Change Request.
   - **Slack**:
     - Channel for "PT-Agent-Approvals".
     - Messages when zone-4b issues go In Review.

---

## 2. Key Flows

### 2.1 Daily Patient Flow

1. Patient opens app → authenticates via Supabase.
2. App fetches "today's session":
   - Active program + relevant session for date/phase.
3. Patient logs:
   - Sets/reps/load per exercise.
   - Pain (0–10) and optional notes.
4. Data written to `exercise_logs` and `pain_logs`.

### 2.2 Therapist Review Flow

1. Therapist opens iPad app.
2. Sees:
   - Completion % per patient.
   - Pain trend and flags.
3. Can drill into a patient:
   - Program structure.
   - Last N sessions.
   - Notes & assessments.

### 2.3 PT Assistant & Plan Change Flow (later phase)

1. PT or patient asks question via app or chat.
2. Agent service:
   - Reads program and recent logs from Supabase.
   - If simple advice → respond.
   - If plan change needed:
     - Drafts proposal.
     - Creates "Plan Change Request" in Linear with zone-4b.
3. Slack notifies PT:
   - Approve / modify / reject.
4. On approval, agent service updates Supabase program/sessions.

---

## 3. Minimal v1 Surface

- No background jobs initially; everything triggered by user interaction.
- Single Supabase project; staging vs production via schemas or separate instances.
- Versioned schema via SQL migrations checked into Git.
