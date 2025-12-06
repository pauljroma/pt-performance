# RUNBOOK – Day-in-the-Life Scenarios (System Acceptance)

**Purpose:** Define real-world daily flows for:
- Patients
- Physical Therapists
- AI Agents
- The overall PT platform

These act as acceptance criteria, integration tests, and agent operation scenarios.

---

# 1. DAY IN THE LIFE – PATIENT (iPhone)

## Scenario P1 – Opening the App
1. Patient unlocks phone and opens PTPerformance.
2. Home shows:
   - Today's session (title + 1-line summary)
   - Time estimate
   - "Start Session" button

**Acceptance:**
- < 1 second load.
- No empty screens.
- If rest day → "Today is a recovery day".

---

## Scenario P2 – Logging the Session
1. Patient taps "Start Session".
2. Exercises load in order with:
   - sets/reps/load target
   - pain slider per set
   - cue notes (if any)

3. Patient completes:
   - Trap Bar DL: logs 3 sets, pain 2/10
   - Shoulder ER: pain 4/10
   - Plyo wall drills: pain 3/10

4. Patient taps Complete → summary view.

**Acceptance:**
- Logs stored in `exercise_logs`.
- Pain stored in `pain_logs`.
- Session shows in History immediately.
- If pain > 5 → system triggers risk flag.

---

## Scenario P3 – History View
1. Patient taps History tab.
2. Sees:
   - last sessions
   - pain trend chart
   - adherence % calculated

**Acceptance:**
- Data matches DB.
- Charts render instantly.

---

# 2. DAY IN THE LIFE – THERAPIST (iPad)

## Scenario T1 – Reviewing Morning Dashboard
1. Therapist sits down, opens app on iPad.
2. Dashboard loads list of patients with:
   - Profile photo/name
   - Readiness Score
   - Pain indicator color
   - Adherence %
   - Velocity trend arrow (if pitcher)

**Acceptance:**
- All metrics computed correctly.
- No crashes even with 20+ patients.

---

## Scenario T2 – Reviewing Brebbia (elite pitcher)
1. Therapist taps Brebbia.
2. Detail screen loads with:
   - Phase: "On-Ramp Week 3"
   - Pain trend: small chart
   - Velocity trend: chart (FB/SL)
   - Bullpen summary: hit-spot%
   - Flags: "Velocity drop last 3 days"

**Acceptance:**
- Velocity chart matches XLS data shape.
- Flag computed accurately from DB.
- Links tie to correct sessions.

---

## Scenario T3 – Taking Action (Plan Change)
Brebbia pain = 6 for 2 sessions → velocity drop > 3 mph.

1. Therapist opens AI PT Assistant summary.
2. PT Assistant outputs:
   - "Pain trending upward."
   - "Velocity declining 4 mph average."
   - "Suggested: reduce intensity next bullpen session."

3. Therapist taps "Create Plan Change Request".
4. Linear issue created with zone-4b.

**Acceptance:**
- Agent uses correct template.
- Issue enters "In Review".
- Slack or WhatsApp notifies PT.

---

# 3. DAY IN THE LIFE – AGENT (Backend)

## Scenario A1 – Start of Work Session
1. Agent triggers `/sync-linear`.
2. Finds next task in zone-7 (Supabase).
3. Reads Objective, Scope, DoD.
4. Opens schema file from repo.
5. Executes task.
6. Updates Linear issue:
   - comment summary
   - status to In Review

**Acceptance:**
- Agent honors zone rules.
- Agent writes accurate summary.

---

## Scenario A2 – Plan Change Trigger
1. Agent sees pain_during = 7 for Brebbia.
2. Checks velocity drop.
3. Creates Plan Change Request issue:
   - summary: "High pain and velocity decline"
   - zone-4b
   - severity = high

**Acceptance:**
- PT approval required.
- No automatic program edits without human sign-off.

---

## Scenario A3 – Data Quality Alert
When agent sees:
- Invalid pain score (11)
- Or missing session_id
- Or orphan exercise log

Agent moves issue to Blocked, adds comment, and creates a zone-10b cleanup issue.

**Acceptance:**
- DQ issues route correctly.
- Agent does NOT bypass tests.

---

# 4. SYSTEM ACCEPTANCE CRITERIA

A full end-to-end day is considered "Valid" when:

- Patient logs session → DB updates instantly.
- Therapist sees accurate data (pain, adherence, velocity).
- AI flags risks correctly.
- AI proposes safe plan changes.
- Linear governs workflow.
- Slack/WhatsApp approvals work.
- Program adjustments update DB post-approval.
