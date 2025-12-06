# RUNBOOK – PT Agent Backend
Zones: zone-3c, zone-12
Goal: Provide intelligent summaries, plan-change proposals, Linear integration

---

## 1. Preparation

### Inputs
- `agent-service/` scaffold
- `EPIC_J_PT_ASSISTANT_AGENT_SPEC`
- `EPIC_G_PAIN_INTERPRETATION_MODEL`
- `EPIC_C_THROWING_ONRAMP_PLYO_MODEL`

### Tools
- Node or Python environment
- Postman / cURL
- Claude agent

---

## 2. Steps

### Step A — Backend Skeleton
Implement:
- `/health`
- Fresh project structure
- Env config for SUPABASE_URL & LINEAR_API_KEY

**DoD:**
- Service starts
- Health endpoint green

---

### Step B — Supabase Query Endpoints
Implement:

**`GET /patient-summary/{id}`**
Returns:
- patient profile
- recent session logs
- pain trend
- bullpen metrics

**`GET /today-session/{id}`**
Returns:
- exercises for today
- phase/session metadata

**DoD:**
- Responses match seeded data
- No 500-level errors

---

### Step C — PT Assistant Summaries
Implement:

**`GET /pt-assistant/summary/{id}`**
Generates:
- pain trend summary
- adherence summary
- strength signals
- velocity signals (if pitcher)

**DoD:**
- Text is accurate, concise, safe

---

### Step D — Plan Change Requests
Implement:

**`POST /pt-assistant/plan-change-proposal/{id}`**
1. Evaluate conditions:
   - pain > 5
   - velocity drop
   - poor adherence
2. Create Linear issue:
   - zone-4b
   - In Review
3. Return issue ID + summary.

**DoD:**
- Linear issue created successfully
- Slack integration triggered (later phase)

---

## 3. Final Outputs
- Working PT agent backend
- Automatic plan change proposals
- Verified Linear integration
