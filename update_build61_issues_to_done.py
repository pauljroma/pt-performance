#!/usr/bin/env python3
"""
Update Build 61 Linear issues to Done status.
Marks ACP-154 through ACP-158 as completed.
"""

import os
import sys
from linear_client import LinearClient

def main():
    # Initialize Linear client
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ ERROR: LINEAR_API_KEY environment variable not set")
        sys.exit(1)

    client = LinearClient(api_key)

    # Build 61 issues
    issues = [
        {"id": "ACP-154", "title": "Build 61 Agent 1: Onboarding Flow"},
        {"id": "ACP-155", "title": "Build 61 Agent 2: In-App Help System"},
        {"id": "ACP-156", "title": "Build 61 Agent 3: Exercise Technique Guides"},
        {"id": "ACP-157", "title": "Build 61 Agent 4: Form Validation & Accessibility"},
        {"id": "ACP-158", "title": "Build 61 Agent 5: Coordination & Deployment"},
    ]

    # Get "Done" state ID
    done_state = client.get_workflow_state("Done")
    if not done_state:
        print("❌ ERROR: Could not find 'Done' workflow state")
        sys.exit(1)

    print("🔄 Updating Build 61 Linear issues to Done...\n")

    success_count = 0
    for issue_info in issues:
        issue_id = issue_info["id"]
        issue_title = issue_info["title"]

        try:
            # Update issue to Done
            result = client.update_issue(issue_id, state_id=done_state["id"])
            if result:
                print(f"✅ {issue_id}: {issue_title}")
                success_count += 1
            else:
                print(f"⚠️  {issue_id}: Could not update (may not exist)")
        except Exception as e:
            print(f"❌ {issue_id}: Error - {str(e)}")

    print(f"\n{'='*60}")
    print(f"BUILD 61 LINEAR UPDATE COMPLETE")
    print(f"{'='*60}")
    print(f"Successfully updated: {success_count}/{len(issues)} issues")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()
