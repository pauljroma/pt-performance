#!/usr/bin/env python3
"""
Phase 3 - Mobile App Frontend - Update Linear Issues
Updates Linear issues for all 18 Phase 3 mobile app tasks
"""

import asyncio
import os
import sys
from linear_client import LinearClient


# Phase 3 Mobile App Issues (18 total)
PHASE3_ISSUES = {
    # Patient App (6 issues)
    "ACP-92": {
        "id": None,  # Will fetch from Linear
        "title": "Integrate Supabase Swift SDK and auth flow",
        "group": "patient_app"
    },
    "ACP-93": {
        "id": None,
        "title": "Build Today Session screen with real data",
        "group": "patient_app"
    },
    "ACP-94": {
        "id": None,
        "title": "Implement exercise logging UI with submission",
        "group": "patient_app"
    },
    "ACP-95": {
        "id": None,
        "title": "Create History view with pain/adherence charts",
        "group": "patient_app"
    },
    "ACP-78": {
        "id": None,
        "title": "Implement basic pain/adherence charts in History tab",
        "group": "patient_app"
    },
    "ACP-76": {
        "id": None,
        "title": "Wire Today Session to Supabase today-session endpoint",
        "group": "patient_app"
    },

    # Therapist App (5 issues)
    "ACP-96": {
        "id": None,
        "title": "Build therapist patient list view",
        "group": "therapist_app"
    },
    "ACP-97": {
        "id": None,
        "title": "Create patient detail screen with charts and flags",
        "group": "therapist_app"
    },
    "ACP-98": {
        "id": None,
        "title": "Implement program viewer (phases → sessions → exercises)",
        "group": "therapist_app"
    },
    "ACP-99": {
        "id": None,
        "title": "Add patient notes and assessment interface",
        "group": "therapist_app"
    },
    "ACP-68": {
        "id": None,
        "title": "Build search/filter API for therapists",
        "group": "therapist_app"
    },

    # Integration & Testing (7 issues)
    "ACP-73": {
        "id": None,
        "title": "Implement agent_logs table + writing from backend",
        "group": "integration"
    },
    "ACP-71": {
        "id": None,
        "title": "Add unit tests for 1RM / strength target functions",
        "group": "integration"
    },
    "ACP-63": {
        "id": None,
        "title": "Model 8-week on-ramp as program → phases → sessions",
        "group": "integration"
    },
    "ACP-62": {
        "id": None,
        "title": "Normalize bullpen tracker into bullpen_logs",
        "group": "integration"
    },
    "ACP-59": {
        "id": None,
        "title": "Add rm_estimate to exercise_logs and backfill logic",
        "group": "integration"
    },
    "ACP-58": {
        "id": None,
        "title": "Implement 1RM computation utils from XLS formulas",
        "group": "integration"
    },
    "ACP-57": {
        "id": None,
        "title": "Final MVP Review & Sign-off",
        "group": "integration"
    },
}

IN_PROGRESS_STATE_ID = "36d4e47c-d5bd-4e57-b2e4-46a04835a001"
DONE_STATE_ID = "8a9b8266-b8b2-487a-8286-2ef86385e827"


async def fetch_issue_ids(client: LinearClient):
    """Fetch issue IDs from Linear by identifier (ACP-XX)"""
    print("Fetching issue IDs from Linear...")

    # Use the same project ID as check_linear_status.py
    project_id = "d86e35fb091b"

    # Fetch all issues for the project
    issues = await client.get_project_issues(project_id)

    if not issues:
        print("❌ No issues found in project")
        return False

    # Map issue identifiers to IDs
    found_count = 0
    for issue in issues:
        identifier = issue["identifier"]
        if identifier in PHASE3_ISSUES:
            PHASE3_ISSUES[identifier]["id"] = issue["id"]
            found_count += 1
            print(f"  ✓ {identifier}: {issue['title'][:50]}...")

    print(f"\nFound {found_count}/{len(PHASE3_ISSUES)} Phase 3 issues")
    return found_count == len(PHASE3_ISSUES)


async def start_issue(client: LinearClient, issue_key: str):
    """Mark issue as In Progress and add start comment"""
    issue = PHASE3_ISSUES[issue_key]

    if not issue["id"]:
        print(f"❌ {issue_key}: No issue ID found, skipping")
        return

    # Update to In Progress
    print(f"\n{issue_key}: Updating to 'In Progress'...")
    await client.update_issue_status(issue["id"], IN_PROGRESS_STATE_ID)

    # Add comment
    comment = f"🤖 Phase 3 Mobile App work starting on {issue_key}: {issue['title']}\n\nGroup: {issue['group']}"
    print(f"{issue_key}: Adding comment...")
    await client.add_issue_comment(issue["id"], comment)

    print(f"{issue_key}: ✅ Started")


async def update_progress(client: LinearClient, issue_key: str, message: str):
    """Add progress update comment"""
    issue = PHASE3_ISSUES[issue_key]

    if not issue["id"]:
        return

    comment = f"📝 Progress update: {message}"
    print(f"{issue_key}: {message}")
    await client.add_issue_comment(issue["id"], comment)


async def complete_issue(client: LinearClient, issue_key: str, summary: str):
    """Mark issue as Done and add completion comment"""
    issue = PHASE3_ISSUES[issue_key]

    if not issue["id"]:
        print(f"❌ {issue_key}: No issue ID found, skipping")
        return

    # Add completion comment
    comment = f"✅ **COMPLETE**: {issue['title']}\n\n{summary}\n\n---\n🤖 Phase 3 Mobile App - Issue completed"
    print(f"\n{issue_key}: Adding completion comment...")
    await client.add_issue_comment(issue["id"], comment)

    # Update to Done
    print(f"{issue_key}: Updating to 'Done'...")
    await client.update_issue_status(issue["id"], DONE_STATE_ID)

    print(f"{issue_key}: ✅ Complete")


async def main():
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ LINEAR_API_KEY environment variable not set")
        sys.exit(1)

    async with LinearClient(api_key) as client:
        # Fetch issue IDs
        if not await fetch_issue_ids(client):
            print("\n⚠️  Warning: Not all issues found. Continuing with available issues...")

        # Example usage:
        if len(sys.argv) > 1:
            command = sys.argv[1]

            if command == "start-all":
                print("\n🚀 Starting all Phase 3 issues...")
                for issue_key in PHASE3_ISSUES.keys():
                    await start_issue(client, issue_key)

            elif command.startswith("start-"):
                group = command.replace("start-", "")
                print(f"\n🚀 Starting {group} issues...")
                for issue_key, issue in PHASE3_ISSUES.items():
                    if issue["group"] == group:
                        await start_issue(client, issue_key)

            elif command.startswith("complete-"):
                issue_key = command.replace("complete-", "").upper()
                if issue_key in PHASE3_ISSUES:
                    await complete_issue(client, issue_key, "Implementation complete. See completion report for details.")
                else:
                    print(f"❌ Unknown issue: {issue_key}")

            else:
                print(f"❌ Unknown command: {command}")
                print("\nUsage:")
                print("  python3 phase3_linear_update.py start-all")
                print("  python3 phase3_linear_update.py start-patient_app")
                print("  python3 phase3_linear_update.py start-therapist_app")
                print("  python3 phase3_linear_update.py start-integration")
                print("  python3 phase3_linear_update.py complete-ACP-92")
        else:
            print("\nPhase 3 Linear Update Script")
            print("=" * 60)
            print("\nIssue Groups:")
            print("  patient_app: 6 issues (ACP-92, 93, 94, 95, 78, 76)")
            print("  therapist_app: 5 issues (ACP-96, 97, 98, 99, 68)")
            print("  integration: 7 issues (ACP-73, 71, 63, 62, 59, 58, 57)")
            print("\nUsage:")
            print("  python3 phase3_linear_update.py start-all")
            print("  python3 phase3_linear_update.py start-patient_app")
            print("  python3 phase3_linear_update.py start-therapist_app")
            print("  python3 phase3_linear_update.py start-integration")
            print("  python3 phase3_linear_update.py complete-ACP-92")


if __name__ == "__main__":
    asyncio.run(main())
