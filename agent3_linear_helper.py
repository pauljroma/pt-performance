#!/usr/bin/env python3
"""
Agent 3 - Linear Helper
Manages Linear issue updates for Phase 1 Data Layer tasks
"""

import asyncio
import os
import sys
from linear_client import LinearClient


PROJECT_ID = "d86e35fb091b"
TEAM_NAME = "Agent-Control-Plane"
PROJECT_NAME = "MVP 1 — PT App & Agent Pilot"

# Issue identifiers
ISSUE_IDS = {
    "ACP-84": None,  # Seed demo data (John Brebbia)
    "ACP-67": None,  # Seed exercise library
    "ACP-86": None,  # Data quality tests
}


async def get_issue_by_identifier(client: LinearClient, team_id: str, identifier: str):
    """Get issue by identifier (e.g., ACP-84)"""
    query = """
    query Issues($teamId: String!) {
        team(id: $teamId) {
            issues {
                nodes {
                    id
                    identifier
                    title
                    description
                    state {
                        id
                        name
                        type
                    }
                    url
                }
            }
        }
    }
    """

    data = await client.query(query, {"teamId": team_id})
    issues = data.get("team", {}).get("issues", {}).get("nodes", [])

    for issue in issues:
        if issue["identifier"] == identifier:
            return issue
    return None


async def main():
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("ERROR: LINEAR_API_KEY not set")
        sys.exit(1)

    async with LinearClient(api_key) as client:
        # Get team
        team = await client.get_team_by_name(TEAM_NAME)
        if not team:
            print(f"ERROR: Team '{TEAM_NAME}' not found")
            sys.exit(1)

        print(f"Team: {team['name']} ({team['key']})")
        print(f"Team ID: {team['id']}\n")

        # Get workflow states
        states = await client.get_workflow_states(team["id"])
        print("Workflow States:")
        for state in states:
            print(f"  - {state['name']} ({state['type']}) ID: {state['id']}")
        print()

        # Find "In Progress" and "Done" states
        in_progress_state = next((s for s in states if s['name'] == 'In Progress'), None)
        done_state = next((s for s in states if s['name'] == 'Done'), None)

        if not in_progress_state or not done_state:
            print("ERROR: Could not find 'In Progress' or 'Done' states")
            sys.exit(1)

        print(f"In Progress State ID: {in_progress_state['id']}")
        print(f"Done State ID: {done_state['id']}\n")

        # Get issues
        print("Fetching issues...")
        for identifier in ISSUE_IDS.keys():
            issue = await get_issue_by_identifier(client, team["id"], identifier)
            if issue:
                ISSUE_IDS[identifier] = issue["id"]
                print(f"\n{identifier}: {issue['title']}")
                print(f"  ID: {issue['id']}")
                print(f"  State: {issue['state']['name']}")
                print(f"  URL: {issue['url']}")
                if issue.get('description'):
                    desc_preview = issue['description'][:150].replace('\n', ' ')
                    print(f"  Description: {desc_preview}...")
            else:
                print(f"\n{identifier}: NOT FOUND")

        # Save IDs for later use
        print("\n\n=== Issue IDs (copy these) ===")
        for identifier, issue_id in ISSUE_IDS.items():
            if issue_id:
                print(f"{identifier}: {issue_id}")

        print("\n\n=== State IDs (copy these) ===")
        print(f"IN_PROGRESS_STATE_ID = '{in_progress_state['id']}'")
        print(f"DONE_STATE_ID = '{done_state['id']}'")


if __name__ == "__main__":
    asyncio.run(main())
