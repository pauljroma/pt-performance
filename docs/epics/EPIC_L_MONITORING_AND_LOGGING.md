# EPIC L – Monitoring & Logging

## L.1 Purpose

Provide minimal but meaningful observability for:
- Backend services
- PT assistant calls
- Plan change flows
- Agent operations

---

## L.2 Logging Requirements

Each agent-service endpoint must log:
- timestamp
- endpoint
- patient_id (if applicable)
- linear_issue_id (if applicable)
- success/failure
- error details

For v1, logs can be:
- JSON lines in a file
- or a simple Supabase table `agent_logs`

---

## L.3 Metrics (v1)

Simple counters:
- number of plan change requests created per week
- number of approvals vs rejects
- number of PT assistant summaries requested
- number of high pain flags

Later: export to a real metrics system; v1 can live as SQL views or CSV exports.

---

## L.4 Tasks (zone-13)

- "Implement simple agent_logs table + writing from backend." (zone-7, zone-13)
- "Add logging to /patient-summary and /pt-assistant routes." (zone-3c, zone-13)
- "Create weekly monitoring report template in docs." (zone-13)
