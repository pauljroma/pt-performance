# EPIC K – Data Quality & Testing Strategy

## K.1 Purpose

Ensure:
- Clinical and training data is consistent and trustworthy.
- RAG and ML use clean inputs.
- Agents don't propagate corrupt or incomplete data.

---

## K.2 Data Quality Dimensions

- Completeness: key fields not null (patient_id, dates, program/phase/session IDs).
- Validity: pain scores 0–10 only, RPE 0–10, velocities within realistic bounds.
- Consistency: foreign keys intact; logs align with sessions; no orphaned logs.
- Timeliness: session logs aligned with dates; no future dates by mistake.

---

## K.3 Technical Mechanisms

### K.3.1 Constraints

In Supabase:
- CHECK constraints for pain, RPE, command, velocity.
- Foreign keys with ON DELETE behavior.

### K.3.2 Data Quality Scripts (zone-10b)

Scripts to:
- Find invalid records.
- Summarize missingness.
- Report sessions with logs but no program.

These can be:
- SQL views (e.g., `vw_data_quality_issues`)
- Python/Node scripts for more complex analysis.

---

## K.4 Testing Strategy

### K.4.1 Unit Tests

For:
- 1RM computation utils.
- Pain rule engine.
- Throwing workload computations.

### K.4.2 Integration Tests

- Backend endpoints:
  - `/today-session/{patientId}`
  - `/patient-summary/{patientId}`
  - `/pt-assistant/...`

### K.4.3 Prompt / Agent Tests

Per `AGENT_GOVERNANCE`:
- Check that PT Assistant:
  - never returns clinical diagnosis.
  - always creates Plan Change Requests for structural changes.
  - respects pain and workload thresholds.

---

## K.5 Tasks (zones: 10b, 7, 3c)

- "Add CHECK constraints for pain/RPE/velocity in schema." (zone-7, zone-10b)
- "Create vw_data_quality_issues view." (zone-7, zone-10b)
- "Add unit tests for 1RM / strength target functions." (zone-10b)
- "Add PT assistant behavior tests (prompt harness)." (zone-3c, zone-10b)
