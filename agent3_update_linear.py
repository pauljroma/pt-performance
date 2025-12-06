#!/usr/bin/env python3
"""
Agent 3 - Update Linear Issues
Updates Linear issues for Phase 1 Data Layer tasks
"""

import asyncio
import os
import sys
from linear_client import LinearClient


# Issue and State IDs
ISSUES = {
    "ACP-84": {
        "id": "1e32ae02-eb18-46f5-8ccd-e43bd3e1fda9",
        "title": "Seed demo data (therapist, patient, program, sessions)",
    },
    "ACP-67": {
        "id": "5c67804c-0197-42d0-b270-257377b6228d",
        "title": "Seed exercise library in Supabase (50-100 items)",
    },
    "ACP-86": {
        "id": "dd21b83d-5eec-4c50-aa90-23bbe475dab3",
        "title": "Implement data quality tests and validation",
    },
}

IN_PROGRESS_STATE_ID = "36d4e47c-d5bd-4e57-b2e4-46a04835a001"
DONE_STATE_ID = "8a9b8266-b8b2-487a-8286-2ef86385e827"


async def start_issue(client: LinearClient, issue_key: str):
    """Mark issue as In Progress and add start comment"""
    issue = ISSUES[issue_key]

    # Update to In Progress
    print(f"\n{issue_key}: Updating to 'In Progress'...")
    await client.update_issue_status(issue["id"], IN_PROGRESS_STATE_ID)

    # Add comment
    comment = f"🤖 Agent 3 starting work on {issue_key}: {issue['title']}"
    print(f"{issue_key}: Adding comment...")
    await client.add_issue_comment(issue["id"], comment)

    print(f"{issue_key}: ✅ Started")


async def update_progress(client: LinearClient, issue_key: str, message: str):
    """Add progress update comment"""
    issue = ISSUES[issue_key]
    comment = f"⏳ In progress - {message}"
    print(f"\n{issue_key}: Progress update...")
    await client.add_issue_comment(issue["id"], comment)
    print(f"{issue_key}: ✅ Updated")


async def complete_issue(client: LinearClient, issue_key: str, deliverables: str):
    """Mark issue as Done and add completion comment"""
    issue = ISSUES[issue_key]

    # Add completion comment
    comment = f"✅ Work complete.\n\n**Deliverables:**\n{deliverables}"
    print(f"\n{issue_key}: Adding completion comment...")
    await client.add_issue_comment(issue["id"], comment)

    # Update to Done
    print(f"{issue_key}: Updating to 'Done'...")
    await client.update_issue_status(issue["id"], DONE_STATE_ID)

    print(f"{issue_key}: ✅ Completed")


async def main():
    import sys

    if len(sys.argv) < 2:
        print("Usage: python3 agent3_update_linear.py [start-all|start|progress|complete] [issue-key] [message]")
        print("\nCommands:")
        print("  start-all                    - Start all issues")
        print("  start ACP-84                 - Start specific issue")
        print("  progress ACP-84 'message'    - Add progress update")
        print("  complete ACP-84 'delivs'     - Complete issue")
        sys.exit(1)

    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("ERROR: LINEAR_API_KEY not set")
        sys.exit(1)

    command = sys.argv[1]

    async with LinearClient(api_key) as client:
        if command == "start-all":
            for issue_key in ISSUES.keys():
                await start_issue(client, issue_key)

        elif command == "start":
            if len(sys.argv) < 3:
                print("ERROR: Issue key required")
                sys.exit(1)
            issue_key = sys.argv[2]
            await start_issue(client, issue_key)

        elif command == "progress":
            if len(sys.argv) < 4:
                print("ERROR: Issue key and message required")
                sys.exit(1)
            issue_key = sys.argv[2]
            message = sys.argv[3]
            await update_progress(client, issue_key, message)

        elif command == "complete":
            if len(sys.argv) < 4:
                print("ERROR: Issue key and deliverables required")
                sys.exit(1)
            issue_key = sys.argv[2]
            deliverables = sys.argv[3]
            await complete_issue(client, issue_key, deliverables)

        else:
            print(f"ERROR: Unknown command '{command}'")
            sys.exit(1)

    print("\n✅ All Linear updates complete!")


if __name__ == "__main__":
    asyncio.run(main())
