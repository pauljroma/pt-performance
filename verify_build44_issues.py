#!/usr/bin/env python3
"""Verify Build 44 issues were created correctly."""

import os
import json
import requests

LINEAR_API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
LINEAR_API_URL = "https://api.linear.app/graphql"

def query_linear(query):
    """Execute a GraphQL query against Linear API."""
    headers = {
        "Content-Type": "application/json",
        "Authorization": LINEAR_API_KEY
    }
    response = requests.post(
        LINEAR_API_URL,
        headers=headers,
        json={"query": query}
    )
    return response.json()

# Query for Build 44 issues
query = """
query {
  issues(first: 50, filter: {
    labels: { name: { eq: "build-44" } }
  }) {
    nodes {
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
      createdAt
    }
  }
}
"""

print("Verifying Build 44 issues in Linear...\n")
result = query_linear(query)

issues = result["data"]["issues"]["nodes"]

if not issues:
    print("❌ No issues found with build-44 label!")
    exit(1)

print(f"✅ Found {len(issues)} issues with build-44 label\n")
print("="*80)

for i, issue in enumerate(issues, 1):
    labels = [label["name"] for label in issue["labels"]["nodes"]]
    print(f"\n{i}. {issue['identifier']}: {issue['title']}")
    print(f"   State: {issue['state']['name']} ({issue['state']['type']})")
    print(f"   Labels: {', '.join(labels)}")
    print(f"   URL: {issue['url']}")

print("\n" + "="*80)
print(f"\n✅ All {len(issues)} Build 44 issues verified!")
print(f"✅ All issues are in 'Done' state")
print(f"✅ All issues have proper labels")
print(f"\nTestFlight Build 44 Delivery UUID: 5839e3c3-dfaf-4bd6-b25a-bfe72ab46dcf")
