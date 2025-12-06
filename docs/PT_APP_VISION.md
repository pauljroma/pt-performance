# PT App – Vision & Scope

## 1. Purpose

Build a mobile-first platform for Physical Therapists and high-performance coaches to:
- Design and manage complex, multi-phase rehab and performance programs.
- Capture high-quality patient/athlete data during each session.
- Monitor progress and risk over time.
- Support remote care and hybrid models.

Goal: **Be more clinically-aware and adaptable than Bridge/Volt** for PT + throwing athletes.

---

## 2. Primary Users

### Therapist / Coach
- Designs programs (phases, sessions, exercises).
- Adjusts plans based on pain, performance, and constraints.
- Reviews adherence and risk.
- Needs fast charting + decision support.

### Patient / Athlete
- Sees "what to do today" clearly.
- Logs work quickly (sets/reps/load, pain, RPE).
- Captures notes and optionally video.
- Gets guidance on when to push vs hold.

---

## 3. Core Outcomes (for v1)

1. **Single PT & single athlete loop**
   - PT can create a 4–8 week program.
   - Athlete logs work on iPhone.
   - PT reviews completion and pain trends on iPad.

2. **Clinically-informed logging**
   - Pain scale (0–10) per exercise or session.
   - Key ROM/functional metrics where relevant.
   - Flags when pain ↑ while load ↑ too fast.

3. **Simple, reliable sync**
   - Data stored in Supabase (Postgres).
   - Same account accessible from iPhone and iPad.
   - Offline-tolerant for short outages, sync when online.

---

## 4. Non-Goals (for v1)

- No billing/payments.
- No marketplace of PTs.
- No complex insurance workflows.
- No deep analytics dashboard yet (beyond basic charts).
- No full EHR; this is **adjacent**, not a replacement.

---

## 5. Differentiators

- Programs model **phases, constraints, and tissue capacity**, not just workouts.
- Tight link between **PT notes, plan, and logged data**.
- Clear support for **throwing athletes** and **return-to-throw protocols**.
- Designed from day one to be **agent-driven**:
  - Plans and changes live in Linear.
  - Agents generate code, schema, and content.
  - PT assistant agent helps interpret progress (later phase).

---

## 6. Tech Guardrails (v1)

- Mobile: **SwiftUI**, single universal app (iPhone + iPad).
- Backend: **Supabase (Postgres + Auth + Storage)**.
- Agent service: small Node/Python backend for PT assistant + approvals.
- Control plane: **Linear + Slack** for tasks and approvals.
