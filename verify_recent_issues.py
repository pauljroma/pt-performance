#!/usr/bin/env python3
"""Verify recently created Linear issues"""

import os
import requests

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

def query_linear(query, variables=None):
    """Execute a GraphQL query"""
    response = requests.post(
        GRAPHQL_URL,
        json={"query": query, "variables": variables or {}},
        headers=headers
    )

    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error {response.status_code}: {response.text}")
        return None

# Query for recent issues
issues_query = """
query($teamId: String!) {
  team(id: $teamId) {
    issues(first: 100, orderBy: createdAt) {
      nodes {
        identifier
        title
        createdAt
        state {
          name
        }
        priority
      }
    }
  }
}
"""

print("="*80)
print("Recently Created Issues in ACP Team")
print("="*80)
print()

result = query_linear(issues_query, {"teamId": ACP_TEAM_ID})

if result and result.get("data"):
    issues = result["data"]["team"]["issues"]["nodes"]

    # Filter to ACP-164 and above (recently created)
    recent_issues = [i for i in issues if int(i["identifier"].split("-")[1]) >= 164]

    print(f"Found {len(recent_issues)} recently created issues (ACP-164 and above)")
    print()

    # Group by prefix
    by_category = {}
    for issue in recent_issues:
        # Extract category from title like [iOS], [Backend], etc.
        title = issue["title"]
        if title.startswith("["):
            category = title.split("]")[0][1:]
        else:
            category = "Other"

        if category not in by_category:
            by_category[category] = []

        by_category[category].append(issue)

    # Display by category
    for category, issues_list in sorted(by_category.items()):
        print(f"{category} ({len(issues_list)} issues):")
        for issue in issues_list[:5]:  # Show first 5
            print(f"  • {issue['identifier']}: {issue['title'][:60]}...")
        if len(issues_list) > 5:
            print(f"    ... and {len(issues_list) - 5} more")
        print()

    # Summary by build
    build_63_issues = [i for i in recent_issues if "build-63" in str(i) or "Video" in i["title"] or "video" in i["title"]]
    build_64_issues = [i for i in recent_issues if "build-64" in str(i) or "Workload" in i["title"] or "flag" in i["title"].lower()]
    build_65_issues = [i for i in recent_issues if "build-65" in str(i) or "Scheduled" in i["title"] or "calendar" in i["title"].lower()]
    build_66_issues = [i for i in recent_issues if "build-66" in str(i) or "Readiness" in i["title"] or "adjustment" in i["title"].lower()]
    infra_issues = [i for i in recent_issues if any(x in i["title"] for x in ["[Test]", "[DevOps]", "[Compliance]", "[Performance]"])]

    print("-" * 80)
    print("Summary by Build:")
    print(f"  Build 63 (Video Intelligence): ~{len(build_63_issues)} issues")
    print(f"  Build 64 (Safety & Audit): ~{len(build_64_issues)} issues")
    print(f"  Build 65 (Scheduled Sessions): ~{len(build_65_issues)} issues")
    print(f"  Build 66 (Readiness Adjustment): ~{len(build_66_issues)} issues")
    print(f"  Infrastructure: ~{len(infra_issues)} issues")
    print(f"  Total: {len(recent_issues)} issues")

else:
    print("Failed to query issues")
