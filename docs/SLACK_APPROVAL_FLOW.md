# Slack Approval Flow – PT Plan Changes

## Goal

Allow PT to approve or reject plan changes from phone, without opening Linear.

---

## Steps

1. Agent service creates a Plan Change Request issue in Linear (zone-4b, status = In Review).
2. Agent service posts a message to Slack channel `#pt-agent-approvals`:
   - Patient
   - Proposed change
   - Reason/context
   - Impact
   - Linear issue link
   - Buttons: ✅ Approve, ❌ Reject

3. PT taps a button:
   - Slack sends an interactive webhook back to agent service.
   - On **Approve**:
     - Agent service updates Linear issue status to "Approved" (or Done).
     - Applies change to Supabase program/session.
   - On **Reject**:
     - Agent service updates status to "Rejected".
     - Adds comment with PT's response.

4. All state changes remain visible in Linear.

---

## Implementation Notes

- Use Slack App with:
  - Incoming Webhook (for sending messages).
  - Interactivity (for buttons).
- Agent service exposes `/slack/interactions` endpoint.

Claude can now write the actual Slack integration code.
