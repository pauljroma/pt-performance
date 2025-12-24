#!/usr/bin/env python3
"""Verify Build 44 issues by identifier."""

import os
import json
import requests

LINEAR_API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
LINEAR_API_URL = "https://api.linear.app/graphql"

def query_linear(query, variables=None):
    """Execute a GraphQL query against Linear API."""
    headers = {
        "Content-Type": "application/json",
        "Authorization": LINEAR_API_KEY
    }
    payload = {"query": query}
    if variables:
        payload["variables"] = variables

    response = requests.post(
        LINEAR_API_URL,
        headers=headers,
        json=payload
    )
    return response.json()

# Query for specific issues YUK-22 through YUK-26
issue_ids = ["YUK-22", "YUK-23", "YUK-24", "YUK-25", "YUK-26"]

print("Verifying Build 44 issues by identifier...\n")
print("="*80)

all_verified = True
for issue_id in issue_ids:
    query = """
    query GetIssue($id: String!) {
      issue(id: $id) {
        id
        identifier
        title
        state {
          name
          type
        }
        labels {
          nodes {
            name
          }
        }
        url
        description
        createdAt
      }
    }
    """

    result = query_linear(query, {"id": issue_id})

    if "errors" in result or not result.get("data", {}).get("issue"):
        print(f"\n❌ {issue_id}: NOT FOUND")
        all_verified = False
        continue

    issue = result["data"]["issue"]
    labels = [label["name"] for label in issue["labels"]["nodes"]]

    print(f"\n✅ {issue['identifier']}: {issue['title'][:60]}...")
    print(f"   State: {issue['state']['name']} ({issue['state']['type']})")
    print(f"   Labels: {', '.join(labels)}")
    print(f"   URL: {issue['url']}")

    # Verify it's in Done state
    if issue['state']['type'] != 'completed':
        print(f"   ⚠️  WARNING: Not in completed state!")
        all_verified = False

    # Verify build-44 label
    if 'build-44' not in labels:
        print(f"   ⚠️  WARNING: Missing build-44 label!")
        all_verified = False

print("\n" + "="*80)

if all_verified:
    print(f"\n✅ SUCCESS: All 5 Build 44 issues verified and properly configured!")
    print(f"✅ All issues are in 'Done' state")
    print(f"✅ All issues have build-44 label")
    print(f"\nIssues created:")
    for issue_id in issue_ids:
        print(f"  - {issue_id}")
else:
    print(f"\n⚠️  Some issues had warnings or were not found")

print(f"\nTestFlight Build 44 Delivery UUID: 5839e3c3-dfaf-4bd6-b25a-bfe72ab46dcf")
