#!/usr/bin/env python3
"""
Agent 2 - Linear Issue Update Script
Updates Linear issues for Phase 1 Data Layer tasks
"""

import asyncio
import os
import sys
from linear_client import LinearClient


async def main():
    # Get API key from environment
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ Error: LINEAR_API_KEY environment variable not set")
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

        # Get all issues to find our target issues
        issues = await client.get_project_issues(project["id"])

        # Find our specific issues
        issue_map = {}
        for issue in issues:
            if issue['identifier'] in ['ACP-85', 'ACP-64', 'ACP-70']:
                issue_map[issue['identifier']] = issue
                print(f"\n📌 Found {issue['identifier']}: {issue['title']}")
                print(f"   Current state: {issue['state']['name']}")
                print(f"   ID: {issue['id']}")

        # Get workflow states
        states = await client.get_workflow_states(team["id"])
        state_map = {state['name']: state['id'] for state in states}

        print(f"\n📋 Available states: {list(state_map.keys())}")

        # Determine the state to use for "In Progress" and "Done"
        in_progress_state = state_map.get('In Progress') or state_map.get('Started')
        done_state = state_map.get('Done') or state_map.get('Completed')

        if not in_progress_state or not done_state:
            print(f"❌ Could not find required states. Available: {list(state_map.keys())}")
            sys.exit(1)

        # Update ACP-85 to In Progress
        if 'ACP-85' in issue_map:
            print(f"\n🔄 Updating ACP-85 to In Progress...")
            await client.update_issue_status(issue_map['ACP-85']['id'], in_progress_state)
            await client.add_issue_comment(
                issue_map['ACP-85']['id'],
                "🤖 Agent 2 starting work on creating analytics views (vw_patient_adherence, vw_pain_trend, vw_throwing_workload)"
            )
            print("✅ ACP-85 updated")

        # Update ACP-64 to In Progress
        if 'ACP-64' in issue_map:
            print(f"\n🔄 Updating ACP-64 to In Progress...")
            await client.update_issue_status(issue_map['ACP-64']['id'], in_progress_state)
            await client.add_issue_comment(
                issue_map['ACP-64']['id'],
                "🤖 Agent 2 starting work on implementing throwing workload views (vw_throwing_workload, vw_onramp_progress)"
            )
            print("✅ ACP-64 updated")

        # Update ACP-70 to In Progress
        if 'ACP-70' in issue_map:
            print(f"\n🔄 Updating ACP-70 to In Progress...")
            await client.update_issue_status(issue_map['ACP-70']['id'], in_progress_state)
            await client.add_issue_comment(
                issue_map['ACP-70']['id'],
                "🤖 Agent 2 starting work on creating data quality view (vw_data_quality_issues)"
            )
            print("✅ ACP-70 updated")

        print("\n✅ All issues updated to In Progress with start comments")


if __name__ == "__main__":
    asyncio.run(main())
