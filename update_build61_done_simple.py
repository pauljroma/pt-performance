#!/usr/bin/env python3
"""Update Build 61 Linear issues to Done"""

import os
import requests

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

def get_done_state_id():
    """Get the Done state ID for ACP team"""
    query = """
    query {
        team(id: "5296cff8-9c53-4cb3-9df3-ccb83601805e") {
            states {
                nodes {
                    id
                    name
                }
            }
        }
    }
    """
    response = requests.post(GRAPHQL_URL, json={"query": query}, headers=headers)
    if response.status_code == 200:
        data = response.json()
        states = data.get("data", {}).get("team", {}).get("states", {}).get("nodes", [])
        for state in states:
            if state["name"].lower() == "done":
                return state["id"]
    return None

def update_issue_to_done(issue_identifier, done_state_id):
    """Update an issue to Done state"""
    mutation = """
    mutation UpdateIssue($id: String!, $stateId: String!) {
        issueUpdate(id: $id, input: {stateId: $stateId}) {
            success
            issue {
                identifier
                title
                state {
                    name
                }
            }
        }
    }
    """

    # First, get the issue ID from identifier
    get_issue_query = """
    query GetIssue($identifier: String!) {
        issue(id: $identifier) {
            id
            identifier
            title
        }
    }
    """

    response = requests.post(
        GRAPHQL_URL,
        json={"query": get_issue_query, "variables": {"identifier": issue_identifier}},
        headers=headers
    )

    if response.status_code == 200:
        data = response.json()
        issue_data = data.get("data", {}).get("issue")
        if issue_data:
            issue_id = issue_data["id"]

            # Now update the issue
            response = requests.post(
                GRAPHQL_URL,
                json={
                    "query": mutation,
                    "variables": {"id": issue_id, "stateId": done_state_id}
                },
                headers=headers
            )

            if response.status_code == 200:
                data = response.json()
                if data.get("data", {}).get("issueUpdate", {}).get("success"):
                    return True
    return False

print("="*80)
print("Build 61 - Updating Linear Issues to Done")
print("="*80)
print()

# Get Done state ID
print("Getting Done state ID...")
done_state_id = get_done_state_id()
if not done_state_id:
    print("❌ Could not find Done state")
    exit(1)
print(f"✅ Done state ID: {done_state_id}")
print()

# Build 61 issues
issues = [
    "ACP-154",  # Build 61 Agent 1: Onboarding Flow
    "ACP-155",  # Build 61 Agent 2: In-App Help System
    "ACP-156",  # Build 61 Agent 3: Exercise Technique Guides
    "ACP-157",  # Build 61 Agent 4: Form Validation & Accessibility
    "ACP-158",  # Build 61 Agent 5: Coordination & Deployment
]

success_count = 0
for issue_id in issues:
    print(f"Updating {issue_id}...", end=" ")
    if update_issue_to_done(issue_id, done_state_id):
        print("✅")
        success_count += 1
    else:
        print("❌")

print()
print("="*80)
print(f"Complete: {success_count}/{len(issues)} issues updated to Done")
print("="*80)
