#!/usr/bin/env python3
"""
Linear Stale Issues Cleanup Script

Marks old build issues (Build 74-96) as Done/Cancelled.
We're now at Build 358, so these are very stale.

Usage:
    export LINEAR_API_KEY="lin_api_xxx"
    python3 scripts/linear_cleanup_stale_issues.py

Or run with --dry-run to preview changes.
"""

import os
import sys
import json
import time

try:
    import requests
except ImportError:
    print("ERROR: requests library not installed")
    print("Install with: pip3 install requests")
    sys.exit(1)

LINEAR_API_KEY = os.getenv('LINEAR_API_KEY')
LINEAR_API_URL = 'https://api.linear.app/graphql'

# Issues to clean up (from Build 358 analysis)
STALE_ISSUES = {
    # In Progress issues from Build 74 (Dec 2025)
    "ACP-502": "Mark as Done - Build 74 issues resolved in later builds",
    "ACP-503": "Mark as Done - Help articles fixed in Build 111+",
    "ACP-505": "Mark as Done - Timer UI fixed in later builds",
    "ACP-506": "Mark as Done - Debug logging working in current build",
    # In Progress from Build 93
    "ACP-529": "Mark as Done - Feature restoration completed through Build 358",
    # Todo issues from old builds
    "ACP-471": "Cancel - Build 88 superseded",
    "ACP-478": "Cancel - Build 89 superseded",
    "ACP-491": "Cancel - Build 90 superseded",
    "ACP-532": "Cancel - Build 96 superseded, MVP features in Build 358",
}


def get_headers():
    return {
        'Authorization': LINEAR_API_KEY,
        'Content-Type': 'application/json'
    }


def get_team_states():
    """Get workflow states for the team"""
    query = """
    query {
        teams {
            nodes {
                id
                name
                key
                states {
                    nodes {
                        id
                        name
                        type
                    }
                }
            }
        }
    }
    """
    response = requests.post(LINEAR_API_URL, json={'query': query}, headers=get_headers())
    data = response.json()

    for team in data.get('data', {}).get('teams', {}).get('nodes', []):
        if team['key'] == 'ACP':
            return team['id'], team['states']['nodes']

    return None, []


def get_issue_by_identifier(identifier):
    """Get issue details by identifier (e.g., ACP-502)"""
    query = """
    query($identifier: String!) {
        issue(id: $identifier) {
            id
            identifier
            title
            state {
                id
                name
            }
        }
    }
    """
    # Try with identifier filter instead
    query = """
    query {
        issues(filter: { identifier: { eq: "%s" } }) {
            nodes {
                id
                identifier
                title
                state {
                    id
                    name
                }
            }
        }
    }
    """ % identifier

    response = requests.post(LINEAR_API_URL, json={'query': query}, headers=get_headers())
    data = response.json()
    nodes = data.get('data', {}).get('issues', {}).get('nodes', [])
    return nodes[0] if nodes else None


def update_issue_state(issue_id, state_id, comment):
    """Update issue state and add comment"""
    # Update state
    mutation = """
    mutation($issueId: String!, $stateId: String!) {
        issueUpdate(id: $issueId, input: { stateId: $stateId }) {
            success
            issue {
                id
                identifier
                state {
                    name
                }
            }
        }
    }
    """
    variables = {'issueId': issue_id, 'stateId': state_id}
    response = requests.post(LINEAR_API_URL, json={'query': mutation, 'variables': variables}, headers=get_headers())
    result = response.json()

    # Add comment
    comment_mutation = """
    mutation($issueId: String!, $body: String!) {
        commentCreate(input: { issueId: $issueId, body: $body }) {
            success
        }
    }
    """
    comment_body = f"🤖 Auto-cleanup: {comment}\n\nCleaned up as part of Build 358 Linear workspace maintenance."
    requests.post(LINEAR_API_URL, json={
        'query': comment_mutation,
        'variables': {'issueId': issue_id, 'body': comment_body}
    }, headers=get_headers())

    return result


def main():
    dry_run = '--dry-run' in sys.argv

    if not LINEAR_API_KEY:
        print("❌ LINEAR_API_KEY environment variable not set")
        print("\nTo run this script:")
        print("  1. Get your API key from: https://linear.app/settings/api")
        print("  2. export LINEAR_API_KEY='lin_api_xxx'")
        print("  3. python3 scripts/linear_cleanup_stale_issues.py")
        print("\n=== ISSUES TO CLEAN UP ===\n")
        for identifier, reason in STALE_ISSUES.items():
            print(f"  [{identifier}] {reason}")
        print(f"\nTotal: {len(STALE_ISSUES)} stale issues")
        return

    print("=== Linear Stale Issues Cleanup ===\n")

    if dry_run:
        print("🔍 DRY RUN MODE - No changes will be made\n")

    # Get team and states
    team_id, states = get_team_states()
    if not team_id:
        print("❌ Could not find ACP team")
        return

    # Find Done and Cancelled state IDs
    done_state_id = None
    cancelled_state_id = None
    for state in states:
        if state['name'] == 'Done':
            done_state_id = state['id']
        elif state['name'] in ['Cancelled', 'Canceled']:
            cancelled_state_id = state['id']

    print(f"Team ID: {team_id}")
    print(f"Done state: {done_state_id}")
    print(f"Cancelled state: {cancelled_state_id}\n")

    # Process each issue
    success_count = 0
    for identifier, reason in STALE_ISSUES.items():
        print(f"Processing {identifier}...")

        issue = get_issue_by_identifier(identifier)
        if not issue:
            print(f"  ⚠️ Issue not found: {identifier}")
            continue

        current_state = issue['state']['name']
        target_state_id = done_state_id if "Done" in reason else cancelled_state_id
        target_state_name = "Done" if "Done" in reason else "Cancelled"

        if current_state in ['Done', 'Cancelled', 'Canceled']:
            print(f"  ✓ Already {current_state}: {issue['title'][:50]}")
            continue

        print(f"  → {current_state} → {target_state_name}: {issue['title'][:50]}")

        if not dry_run:
            result = update_issue_state(issue['id'], target_state_id, reason)
            if result.get('data', {}).get('issueUpdate', {}).get('success'):
                print(f"  ✅ Updated successfully")
                success_count += 1
            else:
                print(f"  ❌ Update failed: {result}")
            time.sleep(0.5)  # Rate limiting
        else:
            success_count += 1

    print(f"\n=== Summary ===")
    print(f"{'Would update' if dry_run else 'Updated'}: {success_count}/{len(STALE_ISSUES)} issues")

    if dry_run:
        print("\nTo execute, run without --dry-run flag")


if __name__ == '__main__':
    main()
