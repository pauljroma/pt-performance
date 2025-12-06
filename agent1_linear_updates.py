#!/usr/bin/env python3
"""
Agent 1 Linear Integration Script
Handles Linear API updates for Phase 1 Data Layer tasks
"""

import asyncio
import os
import sys
from pathlib import Path

# Add parent directory to path to import linear_client
sys.path.insert(0, str(Path(__file__).parent))

from linear_client import LinearClient


async def main():
    # Get API key from environment
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("ERROR: LINEAR_API_KEY environment variable not set")
        sys.exit(1)

    async with LinearClient(api_key) as client:
        # Get team
        print("Fetching Agent-Control-Plane team...")
        team = await client.get_team_by_name("Agent-Control-Plane")
        if not team:
            print("ERROR: Team 'Agent-Control-Plane' not found")
            sys.exit(1)

        print(f"Team found: {team['name']} (ID: {team['id']})")

        # Get project
        print("\nFetching MVP 1 project...")
        project = await client.get_project_by_name(team["id"], "MVP 1 — PT App & Agent Pilot")
        if not project:
            print("ERROR: Project 'MVP 1 — PT App & Agent Pilot' not found")
            sys.exit(1)

        print(f"Project found: {project['name']} (ID: {project['id']})")

        # Get all issues
        print("\nFetching project issues...")
        issues = await client.get_project_issues(project["id"])

        # Find specific issues
        target_issues = ["ACP-83", "ACP-69", "ACP-79"]
        found_issues = {}

        for issue in issues:
            if issue["identifier"] in target_issues:
                found_issues[issue["identifier"]] = issue
                print(f"\nFound {issue['identifier']}: {issue['title']}")
                print(f"  Current State: {issue['state']['name']}")
                print(f"  URL: {issue['url']}")

        # Check if all issues found
        missing = set(target_issues) - set(found_issues.keys())
        if missing:
            print(f"\nWARNING: Could not find issues: {missing}")

        # Get workflow states
        print("\n\nFetching workflow states...")
        states = await client.get_workflow_states(team["id"])

        state_map = {}
        for state in states:
            state_map[state["name"]] = state["id"]
            print(f"  {state['name']}: {state['id']}")

        # Determine target states
        in_progress_state = None
        done_state = None

        for state_name in ["In Progress", "Started", "In Review"]:
            if state_name in state_map:
                in_progress_state = state_map[state_name]
                break

        for state_name in ["Done", "Completed", "Closed"]:
            if state_name in state_map:
                done_state = state_map[state_name]
                break

        print(f"\n\nTarget States:")
        print(f"  In Progress: {in_progress_state}")
        print(f"  Done: {done_state}")

        # Show found issues summary
        print(f"\n\n{'='*70}")
        print("AGENT 1 PHASE 1 DATA LAYER TASKS")
        print(f"{'='*70}\n")

        for identifier in target_issues:
            if identifier in found_issues:
                issue = found_issues[identifier]
                print(f"{identifier}: {issue['title']}")
                print(f"  ID: {issue['id']}")
                print(f"  State: {issue['state']['name']}")
                print(f"  URL: {issue['url']}")
                print()


if __name__ == "__main__":
    asyncio.run(main())
