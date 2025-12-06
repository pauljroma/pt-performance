# RUNBOOK – Performance & Load Testing

## Purpose

Ensure the PT platform performs reliably under realistic and peak loads:
- Multiple patients
- High-frequency logging
- Several therapists monitoring dashboards
- Agent workflows running in the background

---

## 1. Performance Targets (v1)

- P1: API median latency (95th percentile) < 300 ms for core endpoints:
  - `/today-session/{patientId}`
  - `/patient-summary/{patientId}`
  - `/pt-assistant/summary/{patientId}`
- P2: Mobile screen load time:
  - Today Session: < 1.0 second on typical LTE.
  - Therapist dashboard: < 2.0 seconds for 20 patients.
- P3: Agent backend:
  - Plan-change proposal generation < 2 seconds for a single patient.

---

## 2. Core Scenarios

### Scenario S1 – Patient Logging Peak

Simulate:
- 100 patients logging sessions in a one-hour window.
- Each logging:
  - 8–12 exercises
  - 3–4 sets
  - per-set RPE + pain

Expected:
- DB write load is stable.
- No timeouts on log submission.
- Logs appear in analytics within 5 minutes.

---

### Scenario S2 – Therapist Dashboard Load

Simulate:
- 10 therapists each viewing a panel of 20+ patients.
- Each loads dashboard simultaneously.
- 3–5 refreshes in a 5-minute window.

Expected:
- Dashboard loads under 2 seconds.
- No failures on adherence/pain/velocity queries.
- Supabase connection limits not exceeded.

---

### Scenario S3 – Agent Batch Summaries

Simulate:
- PT assistant generating summaries for 50 patients overnight.

Expected:
- All summaries complete within a batch window (e.g., 15–30 minutes).
- No rate-limit issues with DB or Linear.
- Agent logs capture performance metrics.

---

## 3. Tools & Implementation

- Use a simple load generator:
  - k6 / Locust / custom Python script.
- Define scenarios as code:
  - `scenario_patient_logging`
  - `scenario_therapist_dashboard`
  - `scenario_agent_summaries`

---

## 4. Measurements

Collect:

- Latency per endpoint.
- Error rate (%).
- CPU and memory utilization for:
  - agent backend service
  - database (if accessible).

---

## 5. Definition of Done

- All three scenarios scripted and runnable via command (e.g., `make perf-test`).
- Dashboards (even simple text reports) show:
  - median and 95th percentile latencies
  - error rates
- PT app meets or exceeds v1 performance targets.
