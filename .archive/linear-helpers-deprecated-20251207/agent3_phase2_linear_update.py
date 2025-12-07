#!/usr/bin/env python3
"""
Agent 3 Phase 2 - Linear Issue Updates
Updates ACP-90, ACP-72, ACP-81, ACP-74 to "In Progress" then "Done"
"""

import asyncio
import os
import sys
from linear_client import LinearClient


ISSUE_IDS = {
    "ACP-90": "Implement /plan-change-proposal endpoint",
    "ACP-72": "Add PT assistant behavior tests",
    "ACP-81": "Add protocol validation",
    "ACP-74": "Add logging to endpoints"
}


async def update_agent3_issues():
    """Update all Agent 3 Phase 2 issues to Done"""
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ LINEAR_API_KEY not set")
        sys.exit(1)

    async with LinearClient(api_key) as client:
        # Get team
        team = await client.get_team_by_name("Agent-Control-Plane")
        if not team:
            print("❌ Team not found")
            sys.exit(1)

        print(f"✅ Found team: {team['name']}\n")

        # Get project
        project = await client.get_project_by_name(team["id"], "MVP 1 — PT App & Agent Pilot")
        if not project:
            print("❌ Project not found")
            sys.exit(1)

        print(f"✅ Found project: {project['name']}\n")

        # Get workflow states
        states = await client.get_workflow_states(team["id"])
        done_state = next((s for s in states if s["name"] == "Done"), None)

        if not done_state:
            print("❌ 'Done' state not found")
            sys.exit(1)

        print(f"✅ Found 'Done' state: {done_state['id']}\n")

        # Get project issues
        issues = await client.get_project_issues(project["id"])

        # Find and update Agent 3 issues
        for issue in issues:
            identifier = issue["identifier"]
            if identifier in ISSUE_IDS:
                print(f"\n📋 {identifier}: {issue['title']}")
                print(f"   Current state: {issue['state']['name']}")

                # Update to Done
                if issue['state']['name'] != "Done":
                    await client.update_issue_status(issue["id"], done_state["id"])
                    print(f"   ✅ Updated to: Done")

                    # Add completion comment
                    completion_comment = f"""## ✅ Agent 3 Phase 2 - Task Complete

**Deliverables:**

"""
                    if identifier == "ACP-90":
                        completion_comment += """- POST /pt-assistant/plan-change-proposal/:patientId endpoint implemented
- Creates Linear issues with zone-4b label and "In Review" state
- Returns issue ID and URL
- File: `agent-service/src/routes/pcr.js`
"""
                    elif identifier == "ACP-72":
                        completion_comment += """- Jest test suite created with 20+ test scenarios
- Test coverage for pain detection, velocity drops, adherence tracking
- Protocol validation tests
- Safety validation tests
- Test fixtures with demo patient data
- Files: `agent-service/tests/assistant.test.js`, `agent-service/tests/fixtures/demo-patient-data.json`
"""
                    elif identifier == "ACP-81":
                        completion_comment += """- Protocol validator service implemented
- Queries protocol_constraints table
- Validates suggestions against clinical safety rules
- Blocks unsafe recommendations (critical violations)
- File: `agent-service/src/services/protocol-validator.js`
"""
                    elif identifier == "ACP-74":
                        completion_comment += """- Logging middleware implemented
- Writes to agent_logs table (created in 007_agent_logs_table.sql)
- Logs: timestamp, endpoint, patient_id, response_time, errors
- Error logging with stack traces
- Applied to all endpoints
- File: `agent-service/src/middleware/logging.js`
"""

                    completion_comment += """
**Status:** Complete
**Agent:** Agent 3 (Testing & Observability)
**Phase:** Phase 2 - Backend Intelligence
"""

                    await client.add_issue_comment(issue["id"], completion_comment)
                    print(f"   💬 Added completion comment")
                else:
                    print(f"   ℹ️  Already in Done state")

        print("\n✅ All Agent 3 Phase 2 issues updated!")


if __name__ == "__main__":
    asyncio.run(update_agent3_issues())
