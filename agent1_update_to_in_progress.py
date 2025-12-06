#!/usr/bin/env python3
"""
Agent 1: Update Linear issues to In Progress
"""

import asyncio
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from linear_client import LinearClient


# Issue IDs from previous query
ISSUES = {
    "ACP-83": {
        "id": "74aab92a-b1b1-445f-992e-c9862284587f",
        "title": "Validate and apply Supabase schema from SQL files"
    },
    "ACP-69": {
        "id": "e9196c94-47fa-4a91-afbc-d22ef3c7fe35",
        "title": "Add CHECK constraints for pain/RPE/velocity in schema"
    },
    "ACP-79": {
        "id": "47b15c33-b842-42d1-8001-8ddf4ae2f74b",
        "title": "Build Protocol Schema (tables: protocol_templates, protocol_phases, protocol_constraints)"
    }
}

IN_PROGRESS_STATE_ID = "36d4e47c-d5bd-4e57-b2e4-46a04835a001"


async def main():
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("ERROR: LINEAR_API_KEY environment variable not set")
        sys.exit(1)

    async with LinearClient(api_key) as client:
        print("Starting Agent 1 Phase 1 Data Layer Tasks...\n")

        for identifier, issue_data in ISSUES.items():
            issue_id = issue_data["id"]
            title = issue_data["title"]

            print(f"\n{'='*70}")
            print(f"{identifier}: {title}")
            print(f"{'='*70}")

            # Update to In Progress
            print(f"\nMoving to In Progress state...")
            try:
                await client.update_issue_status(issue_id, IN_PROGRESS_STATE_ID)
                print(f"  Status updated to: In Progress")
            except Exception as e:
                print(f"  ERROR updating status: {e}")
                continue

            # Add initial comment
            comment_text = f"Agent 1 starting work on {identifier}: {title}\n\nSchema files ready:\n- 001_init_supabase.sql (base tables)\n- 002_epic_enhancements.sql (epic A-H enhancements)\n- 003_agent1_constraints_and_protocols.sql (CHECK constraints + protocol schema)\n\nBeginning deployment to Supabase..."

            print(f"\nAdding initial comment...")
            try:
                await client.add_issue_comment(issue_id, comment_text)
                print(f"  Comment added successfully")
            except Exception as e:
                print(f"  ERROR adding comment: {e}")

        print(f"\n\n{'='*70}")
        print("All issues updated to In Progress!")
        print(f"{'='*70}\n")


if __name__ == "__main__":
    asyncio.run(main())
