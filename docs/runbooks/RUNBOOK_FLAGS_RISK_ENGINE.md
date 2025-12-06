# RUNBOOK – Risk Engine (Pain, Velocity, Workload)
Zones: zone-7, zone-10b, zone-3c, zone-4b
Goal: Identify when athlete/PT flow requires intervention

---

## 1. Preparation

### Inputs
- Pain logs
- Bullpen logs
- Exercise logs
- `EPIC_G` and `EPIC_C`

---

## 2. Flag Types

### Pain-Based Flags
- Pain > 5 → immediate flag
- Pain 3–5 for 2+ sessions → flag
- Pain increasing > 2 points session-over-session → flag

### Velocity Flags
- Drop > 3 mph in 1–2 sessions → flag
- Drop > 5 mph → plan change needed

### Command Flags (pitching)
- Hit-spot% decline > 20% over 3 sessions → flag

### Adherence Flags
- Adherence < 60% over 7 days

---

## 3. Steps

### Step A — Build Flag Computation Logic
Implement function:

`computeFlags(patientId) → list of {flag_type, severity, rationale}`

Pull:
- pain trend
- bullpen logs
- session adherence

**DoD:**
- Function handles missing data gracefully

---

### Step B — Attach Flags to Summary Endpoints
Modify:
- `/patient-summary`
- `/pt-assistant/summary`

Include:
- flag count
- top 3 highest severity flags

**DoD:**
- Summaries match flag logic exactly

---

### Step C — Auto-create Plan Change Requests
If severity = HIGH:
- Create Linear issue:
  - zone-4b
  - status: In Review
- Include:
  - patient_id
  - trigger_metric
  - last sessions
  - rationale

**DoD:**
- Claude sees flagged issue in Linear

---

## 4. Final Outputs
- Flag computation engine
- Auto-generated plan change requests
- Integration with PT assistant endpoints
