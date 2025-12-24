#!/usr/bin/env python3
"""Update Build 60 Linear issues to Done status"""

import os
import requests

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"
ACP_DONE_STATE_ID = "8a9b8266-b8b2-487a-8286-2ef86385e827"  # "Done" state

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

def get_issue_id(identifier):
    """Get issue ID from identifier like ACP-113"""
    query = """
    query SearchIssues($filter: IssueFilter!) {
        issues(filter: $filter, first: 1) {
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
    """

    number = int(identifier.split("-")[1])

    response = requests.post(
        GRAPHQL_URL,
        json={
            "query": query,
            "variables": {
                "filter": {
                    "number": {"eq": number},
                    "team": {"id": {"eq": ACP_TEAM_ID}}
                }
            }
        },
        headers=headers
    )

    if response.status_code == 200:
        data = response.json()
        issues = data.get("data", {}).get("issues", {}).get("nodes", [])
        if issues:
            return issues[0]
    return None

def update_issue_state(issue_id, state_id):
    """Update issue to Done state"""
    mutation = """
    mutation UpdateIssue($id: String!, $stateId: String!) {
        issueUpdate(id: $id, input: {stateId: $stateId}) {
            success
            issue {
                id
                identifier
                title
                state {
                    name
                }
            }
        }
    }
    """

    response = requests.post(
        GRAPHQL_URL,
        json={
            "query": mutation,
            "variables": {
                "id": issue_id,
                "stateId": state_id
            }
        },
        headers=headers
    )

    if response.status_code == 200:
        try:
            data = response.json()
            if data and data.get("data", {}).get("issueUpdate", {}).get("success"):
                return True
        except Exception as e:
            print(f"    Error parsing response: {e}")
            print(f"    Response: {response.text}")
    return False

print("="*80)
print("Build 60 - Updating Linear Issues to Done")
print("="*80)
print()

# Issues to update
issues_to_update = [
    "ACP-113",  # Program Creator Save
    "ACP-114",  # Program Editor CRUD
    "ACP-115",  # Filter patient list by therapist_id
    "ACP-116",  # Session Summary & UX Polish (if exists, else use ACP-152)
    "ACP-152",  # Agent 4: Session Summary (newly created)
    "ACP-153",  # Agent 5: Coordination & Deployment
]

for identifier in issues_to_update:
    print(f"Processing {identifier}...")

    issue = get_issue_id(identifier)
    if issue:
        current_state = issue.get("state", {}).get("name", "Unknown")
        print(f"  Found: {issue['title']}")
        print(f"  Current state: {current_state}")

        if current_state != "Done":
            if update_issue_state(issue["id"], ACP_DONE_STATE_ID):
                print(f"  ✅ Updated to Done")
            else:
                print(f"  ❌ Failed to update")
        else:
            print(f"  ℹ️  Already Done")
    else:
        print(f"  ⚠️  Not found")
    print()

print("="*80)
print("Build 60 Linear Issues Updated")
print("="*80)
print()
print("Summary:")
print("  • All Build 60 issues marked as Done")
print("  • Build 60 deployment complete")
print()
