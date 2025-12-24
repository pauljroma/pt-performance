#!/usr/bin/env python3
"""List recent issues from Yukon team."""

import os
import json
import requests
from datetime import datetime, timedelta

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

# Query for recent issues in Yukon team
query = """
query {
  team(id: "a3f75dcc-2bee-4d47-b8f5-5ffdcbc69f8b") {
    name
    key
    issues(first: 30, orderBy: createdAt) {
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
        updatedAt
      }
    }
  }
}
"""

print("Querying recent issues from Yukon team...\n")
result = query_linear(query)

if "errors" in result:
    print("❌ Error querying Linear:")
    print(json.dumps(result["errors"], indent=2))
    exit(1)

team = result["data"]["team"]
issues = team["issues"]["nodes"]

print(f"Team: {team['name']} ({team['key']})")
print(f"Found {len(issues)} issues\n")
print("="*80)

# Filter for recently created issues (last hour)
now = datetime.now()
recent_cutoff = now - timedelta(hours=1)

recent_issues = []
for issue in issues:
    created_at = datetime.fromisoformat(issue["createdAt"].replace("Z", "+00:00"))
    if created_at.replace(tzinfo=None) > recent_cutoff:
        recent_issues.append(issue)

if recent_issues:
    print(f"\n✅ Recently created issues (last hour): {len(recent_issues)}\n")
    for issue in recent_issues:
        labels = [label["name"] for label in issue["labels"]["nodes"]]
        print(f"  {issue['identifier']}: {issue['title'][:60]}...")
        print(f"    State: {issue['state']['name']}")
        print(f"    Labels: {', '.join(labels)}")
        print(f"    URL: {issue['url']}")
        print(f"    Created: {issue['createdAt']}")
        print()
else:
    print("\n❌ No recently created issues found in the last hour")

# Show all issues for debugging
print("\n" + "="*80)
print(f"All {len(issues)} issues in Yukon team (most recent first):\n")
for i, issue in enumerate(reversed(issues[-10:]), 1):  # Last 10 issues
    labels = [label["name"] for label in issue["labels"]["nodes"]]
    print(f"{i}. {issue['identifier']}: {issue['title'][:50]}...")
    print(f"   State: {issue['state']['name']}, Labels: {', '.join(labels[:3])}")
    print()
