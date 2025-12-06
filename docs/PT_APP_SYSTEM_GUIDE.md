# PT App – System Guide for AI Agents

## 1. Workflow Summary

Agents follow this sequence:

1. Sync the Linear plan.
2. Select tasks appropriate for their zone.
3. Retrieve context from `/docs`.
4. Update files or backend code.
5. Push changes (local or branch).
6. Update Linear issue:
   - Comment summary
   - Status update
7. For plan changes:
   - Create Plan Change Request (zone-4b)
   - Move to In Review
   - Notify Slack

---

## 2. Zones Cheat Sheet

- **zone-7 / zone-8:** Database, schema, Postgres logic
- **zone-12:** iOS app, frontend, SwiftUI
- **zone-3c:** PT assistant backend
- **zone-4a:** Control-plane logic
- **zone-4b:** Approval flows
- **zone-10b:** Quality & testing
- **zone-13:** Monitoring

Agents must never operate outside declared zones.

---

## 3. CLI + MCP Commands

- `linear_get_plan` → load tasks
- `/sync-linear` → sync bidirectionally
- `python3 linear_client.py export-md` → export issues
- Claude tool: "linear_update_issue" → update status/comment

---

## 4. Definitions of Done By Area

### 4.1 Supabase Tasks
- Schema validated against Supabase.
- SQL migration created.
- Demo data seeded.

### 4.2 iOS Tasks
- Compiles in Xcode.
- Navigation works.
- Supabase auth linked.

### 4.3 Backend Tasks
- Endpoints respond locally.
- Linear integration tested with mock issue.

### 4.4 Approval Tasks
- In Review state correctly set.
- Slack notification works.

---

## 5. Safety Rules
- No unapproved plan modifications.
- No clinical recommendations.
- Pain-driven logic follows thresholds.
- All tasks must reference a Linear issue.
