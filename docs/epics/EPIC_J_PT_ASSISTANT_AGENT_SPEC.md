# EPIC J – PT Assistant Agent Specification

## J.1 Purpose

Create a constrained PT-style assistant that:
- Reads programs and logs
- Describes progress to therapist or athlete
- Flags risk and suggests plan changes
- NEVER gives diagnosis or prescriptive medical advice

---

## J.2 Inputs

- Supabase:
  - patient profile
  - active program and phase
  - last N sessions, exercise_logs, pain_logs
  - bullpen_logs (if applicable)
- Linear:
  - current tasks for that patient/program
  - open plan-change requests (zone-4b)

---

## J.3 Allowed Behaviors

PT assistant may:
- Explain progress trends (pain, adherence, workload).
- Suggest **types** of changes (e.g., "reduce intensity", "add rest day").
- Draft structured plan change proposals.

PT assistant MUST:
- Create a Plan Change Request issue in Linear for any structural program change.
- Use `EPIC_G` rules for pain interpretation.
- Use throwing rules from `EPIC_C` when relevant.

PT assistant may NOT:
- Provide diagnoses.
- Recommend medications.
- Overrule PT or physician.

---

## J.4 Plan Change Request Format

When proposing changes, the agent constructs:
- summary: short title
- patient_id
- current_phase / session
- change_type:
  - reduce_volume
  - reduce_intensity
  - adjust_frequency
  - alter_exercise
  - modify_throwing_ladder
- rationale: based on pain/workload/velocity
- impact_level: Low/Medium/High

These are stored in Linear "Plan Change Request" issues with zone-4b.

---

## J.5 API / Endpoint Requirements

Backend (zone-3c, zone-12):
- `/pt-assistant/summary/{patientId}`:
  - high-level textual summary for PT
- `/pt-assistant/plan-change-proposal/{patientId}`:
  - POST with trigger context (e.g. "high pain", "velocity drop")
  - returns a structured proposal + Linear issue ID (if created)

---

## J.6 Agent Behaviors per Role

- **Therapist-facing mode**:
  - More technical
  - References metrics and epics
- **Patient-facing mode**:
  - Simple language
  - More encouragement, less detail

Config stored in `docs/PT_ASSISTANT_PERSONAS.md` (to be created later).
