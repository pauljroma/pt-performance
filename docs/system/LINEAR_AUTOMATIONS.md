# LINEAR AUTOMATIONS – Agent Control Plane (Business Plan)

## Purpose
Define the rules that keep agents on-path inside Linear.

---

## Rule 1 – Zone Required for Any New Issue
**When:** Issue is created
**If:** Issue has NO label starting with `zone-`
**Then:**
- Set status → `Blocked`
- Add comment:
  > "Every issue must have at least one zone-* label (zone-7, zone-12, etc.). Please assign and re-open."

---

## Rule 2 – Plan Change Requests → In Review
**When:** Label `zone-4b` is added to an issue
**Then:**
- Set status → `In Review`

This feeds your **Awaiting Approval** view automatically.

---

## Rule 3 – Done Only Allowed from In Review
**When:** Status changes to `Done`
**If:** Previous status is NOT `In Review`
**Then:**
- Set status → `In Review`
- Add comment:
  > "Issues must pass through In Review before Done."

This forces a review step (you or an agent Validator).

---

## Rule 4 – Auto-Assign Agent Tasks by Zone (Optional)
**When:** Issue created with label `zone-7`
**Then:** Assign to `Data/Infra` agent user (future)

Repeat pattern:
- `zone-12` → Mobile agent user
- `zone-3c` → Backend/Assistant agent user

---

## Rule 5 – Flag High-Risk Clinical Items
**When:** Label `clinical-risk-high` is added
**Then:**
- Set priority → High
- Notify via Slack (future integration)

---

## Definition of Done
- All rules configured under:
  - Team Settings → Workflow → Automations
- Tested by creating sample issues and confirming:
  - Blocked when no zone
  - In Review when zone-4b
  - Done only after review
