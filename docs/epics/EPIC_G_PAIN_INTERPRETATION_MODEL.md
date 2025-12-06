# EPIC G – Pain Interpretation Model

## Purpose

Normalize pain logs from:
- exercise_logs
- pain_logs
- bullpen_logs

so agents and PTs can interpret them consistently.

---

## Requirements

### G1. Pain Zones
Pain type:
- Rest
- During movement
- After movement
- Throwing-specific pain

### G2. Rule-Based Interpretation

If pain > 5:
- immediate flag

If pain 3–5 for >2 consecutive sessions:
- propose plan change

If pain decreases in spite of higher load:
- mark as "positive adaptation"

### G3. Throwing Pain

If bullpen pain > 4:
- restrict intensity next session

If bullpen pain > 6:
- auto-create Plan Change Request with context:
  - pitch type
  - velocity
  - workload trend

### G4. Backend Logic

Create `/pain-summary/{patientId}`:
- recent pain values
- trends (7-day, 14-day)
- rule-based flags

### G5. Agent Tasks

- Implement pain rule engine.
- Add flags to therapist dashboard.
- Connect flags to zone-4b flow.
