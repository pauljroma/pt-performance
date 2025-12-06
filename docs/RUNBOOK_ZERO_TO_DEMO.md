# Zero-to-First-Demo Checklist
_A complete step-by-step of everything required to get the PT App demo running end-to-end._

---

# 0. Preconditions

- Linear workspace configured with:
  - Agent-Control-Plane team
  - Project: MVP 1 — PT App & Agent Pilot
  - zone-* labels
  - Rule automations active
- Claude MCP ↔ Linear integration tested
- Supabase project created

---

# 1. Backend Setup (Supabase)

### Task 1.1 — Apply Schema

```bash
supabase db push
```

### Task 1.2 — Seed Demo Patient
Insert:
- 1 therapist
- 1 patient (Brebbia profile)
- 1 program → 1 phase → 3 sessions
- 8–12 exercises total

### Task 1.3 — Seed Analytics Data
- Body Comp values
- Bullpen (velocity + command)
- Plyo logs
- Pain logs

### Task 1.4 — Verify Views

```sql
select * from vw_patient_adherence;
select * from vw_pain_trend;
```

---

# 2. Mobile App Setup

### Task 2.1 — Build App Skeleton
Open `PTPerformance.xcodeproj` →
- Build + run on simulator
- Confirm AuthView → PatientTabView → HistoryView

### Task 2.2 — Supabase Auth
Add:
- login
- logout
- retrieve user role

### Task 2.3 — Today Session View
- Pull session via `/today-session/{id}`
- Render exercises
- Add logging UI

### Task 2.4 — History View
- Show pain trend
- Show adherence
- Show past sessions

---

# 3. Agent Backend Setup

### Task 3.1 — Start Service

```bash
node src/server.js
```

### Task 3.2 — Test Endpoints

```
/health
/patient-summary/{id}
/pt-assistant/summary/{id}
```

### Task 3.3 — Plan Change Request
Simulate:

```bash
POST /pt-assistant/plan-change-proposal/{id}
```

### Task 3.4 — Verify Linear Issue Created
- Should land in zone-4b
- Status = In Review

---

# 4. Dashboard Setup

### Task 4.1 — Therapist Dashboard (iPad)
- Patient List
- Patient Detail
- Pain + velocity charts

### Task 4.2 — Flags
- Show current flags
- Show risk indicators

---

# 5. Demo Flow

### Step 1 — Patient logs session
Show:
- Logging
- Immediate DB update

### Step 2 — Therapist dashboard updates
- Adherence
- Pain
- Velocity

### Step 3 — PT Assistant summary
- AI-safe explanation
- Suggested options

### Step 4 — Plan Change Request (zone-4b)
- Therapist approves in Linear

### Step 5 — Program updates shown
- New load/volume/intensity

---

# DEFINITION OF "DEMO SUCCESSFUL"

- App runs on iPad + iPhone
- Backend returns real data
- Analytics correct for seeded patient
- PT assistant generates safe, governed output
- Linear approvals visible in real time
