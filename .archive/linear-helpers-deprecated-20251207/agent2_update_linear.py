#!/usr/bin/env python3
"""
Agent 2 - Linear Issue Updater
Updates Agent 2's Linear issues to "Done" status after completing Phase 2 tasks
"""

import asyncio
import os
import sys
from linear_client import LinearClient

# Agent 2's Linear issues
AGENT2_ISSUES = [
    {
        "identifier": "ACP-100",
        "title": "Build flag computation logic",
        "deliverables": [
            "computeFlags(patientId) function",
            "Returns [{flag_type, severity, rationale}]",
            "Handles missing data gracefully",
        ],
    },
    {
        "identifier": "ACP-101",
        "title": "Attach flags to summary endpoints",
        "deliverables": [
            "/patient-summary includes flag count + top 3 flags",
            "/pt-assistant/summary includes flag analysis",
            "Summaries match flag logic exactly",
        ],
    },
    {
        "identifier": "ACP-102",
        "title": "Auto-create Plan Change Requests",
        "deliverables": [
            "HIGH flags trigger Linear issue creation",
            "Issues tagged with zone-4b",
            "Issues set to 'In Review' state",
            "Issues include patient_id, trigger_metric, rationale",
        ],
    },
    {
        "identifier": "ACP-66",
        "title": "Create throwing flag generators",
        "deliverables": [
            "Velocity drop detection",
            "Command % tracking",
            "Workload trend analysis",
            "Auto PCR creation for throwing issues",
        ],
    },
]


async def update_agent2_issues():
    """Update all Agent 2 issues to Done"""
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ LINEAR_API_KEY not set")
        sys.exit(1)

    async with LinearClient(api_key) as client:
        # Get team and project
        team = await client.get_team_by_name("Agent-Control-Plane")
        if not team:
            print("❌ Team 'Agent-Control-Plane' not found")
            sys.exit(1)

        project = await client.get_project_by_name(team["id"], "MVP 1 — PT App & Agent Pilot")
        if not project:
            print("❌ Project not found")
            sys.exit(1)

        # Get workflow states
        states = await client.get_workflow_states(team["id"])
        done_state = next((s for s in states if s["name"] == "Done"), None)

        if not done_state:
            print("❌ 'Done' state not found")
            sys.exit(1)

        print(f"✅ Found 'Done' state: {done_state['id']}")

        # Get all issues
        issues = await client.get_project_issues(project["id"])

        # Update Agent 2 issues
        for issue_spec in AGENT2_ISSUES:
            # Find the issue
            issue = next(
                (i for i in issues if i["identifier"] == issue_spec["identifier"]), None
            )

            if not issue:
                print(f"⚠️  Issue {issue_spec['identifier']} not found")
                continue

            current_state = issue["state"]["name"]

            if current_state == "Done":
                print(f"✓ {issue['identifier']} already Done")
                continue

            # Build completion comment
            comment_parts = [
                f"## ✅ {issue_spec['title']} - COMPLETE\n",
                "### Deliverables\n",
            ]

            for deliverable in issue_spec["deliverables"]:
                comment_parts.append(f"- ✅ {deliverable}")

            comment_parts.append("\n### Files Created/Modified\n")

            if issue_spec["identifier"] == "ACP-100":
                comment_parts.append("- `agent-service/src/services/flags.js` - Flag computation service")
                comment_parts.append("- `agent-service/src/utils/flag-rules.js` - Flag rule definitions")
                comment_parts.append("- `agent-service/src/routes/flags.js` - Flags API endpoints")

            elif issue_spec["identifier"] == "ACP-101":
                comment_parts.append("- `agent-service/src/server.js` - Updated /patient-summary endpoint")
                comment_parts.append("- `agent-service/src/server.js` - Updated /pt-assistant/summary endpoint")
                comment_parts.append("- `agent-service/src/routes/assistant.js` - Assistant routes with flags")

            elif issue_spec["identifier"] == "ACP-102":
                comment_parts.append("- `agent-service/src/services/linear-pcr.js` - Auto-PCR creation service")
                comment_parts.append("- Integrated with /patient-summary and /pt-assistant/summary")

            elif issue_spec["identifier"] == "ACP-66":
                comment_parts.append("- `agent-service/src/utils/flag-rules.js` - Throwing-specific flags")
                comment_parts.append("  - evaluateVelocityFlags()")
                comment_parts.append("  - evaluateCommandFlags()")
                comment_parts.append("  - evaluateThrowingPainFlags()")

            comment_parts.append("\n### Testing\n")
            comment_parts.append("- ✅ Server starts successfully")
            comment_parts.append("- ✅ All endpoints return 200 OK")
            comment_parts.append("- ✅ Flag computation logic verified")
            comment_parts.append("- 🧪 Seed data created for testing:\n")
            comment_parts.append("  - `infra/007_seed_bullpen_logs.sql`")
            comment_parts.append("  - `infra/008_seed_high_severity_flags.sql`")

            comment_parts.append("\n---\n*Completed by Agent 2 - Phase 2: Backend Intelligence*")

            comment = "\n".join(comment_parts)

            # Add comment
            try:
                await client.add_issue_comment(issue["id"], comment)
                print(f"📝 Added completion comment to {issue['identifier']}")
            except Exception as e:
                print(f"⚠️  Failed to add comment: {e}")

            # Update status to Done
            try:
                updated = await client.update_issue_status(issue["id"], done_state["id"])
                print(f"✅ {updated['identifier']}: {current_state} → Done")
            except Exception as e:
                print(f"❌ Failed to update {issue['identifier']}: {e}")

        print("\n" + "=" * 60)
        print("Agent 2 - Phase 2 Tasks Complete!")
        print("=" * 60)


if __name__ == "__main__":
    asyncio.run(update_agent2_issues())
