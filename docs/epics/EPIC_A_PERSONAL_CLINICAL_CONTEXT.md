# EPIC A – Personal & Clinical Context (Brebbia Profile)

## A.1 Purpose

Model the **real-world clinical + personal context** of a high-level pitcher (e.g., John Brebbia) so that:

- Programs are **patient-specific**, not generic templates.
- PTs see meaningful context at a glance (injuries, surgeries, meds, goals).
- Agents can reason safely about **plan changes** (zone-4b) using this context.

Source: `Personal` sheet in XLS.

---

## A.2 Data Model Requirements

### A.2.1 Patient Identity

From `Personal` tab:

- Name
- DOB
- Age
- Sport
- Position
- Email

**Mapped to `patients` table:**

- `first_name`, `last_name`
- `date_of_birth`
- `sport`, `position`
- `email`
- (Age derived in UI, not stored)

### A.2.2 Clinical History

The XLS stores rich narrative text like:

- "Brief Medical History"
- "Injuries: 2025 – right tricep strain (grade 1)…"
- "Medications: in-season daily diclofenac sodium…"

**Mapped to:**

- `patients.medical_history` (JSON)
  - injuries (array of {year, body_region, diagnosis, notes})
  - surgeries (array)
  - chronic_conditions (array)
- `patients.medications` (JSON)
  - name, dose, schedule, seasonality

**Acceptance criteria:**

- Agents must preserve **semantic structure** (injuries vs meds) when ingesting narrative text.
- UI surfaces "headline risks" (e.g., current injury, key meds) on therapist dashboard.

---

## A.3 Program Context Fields

The XLS implies:

- Long-term performance goals (e.g., maintain MLB-level performance).
- Short-term rehab goals (e.g., return from grade 1 tricep strain).
- Role context (right-handed relief pitcher; bullpen usage patterns).

**Mapped to:**

- `programs.name` (e.g., "2025 In-Season Maintenance", "2025 Tricep Rehab")
- `programs.description` (free-text description of rehab/performance goal)
- Optional `programs.metadata` (JSON) with:
  - target_level (e.g., MLB, college)
  - role (starter, reliever)
  - return_to_throw_target_date

---

## A.4 UX Requirements (Therapist)

### A.4.1 Patient Summary Panel (Therapist Dashboard)

For Brebbia-like patient, therapist must see:

- ID: Name, age, team, role
- Active program(s) with high-level status:
  - weeks completed / remaining
  - adherence %
  - pain trend headline
- Clinical flags:
  - active injury
  - meds that impact load (e.g., NSAIDs)

**Definition of Done:**

- Single API call or view (`/patient-summary/{id}`) returns all of the above.
- Therapist iPad dashboard shows this in 1–2 taps.

---

## A.5 Agent Rules

Agents in **zone-3c / zone-4b** MUST:

- Use clinical context only to **inform flags and plan-change proposals**, not to give medical advice.
- Include patient context summary in any Plan Change Request:
  - current injury
  - current program
  - recent pain trend
- Never suggest higher workloads if current injury is acute and pain trend is not stable / improving.

---
