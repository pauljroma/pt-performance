#!/usr/bin/env python3
"""Import Linear issues from CSV file"""

import os
import csv
import requests
import time

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"
ACP_TODO_STATE_ID = "6806266a-71d7-41d2-8fab-b8b84651ea37"

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

# Priority mapping
PRIORITY_MAP = {
    "Critical": 1,  # Urgent
    "High": 2,      # High
    "Medium": 3,    # Medium
    "Low": 4        # Low
}

def create_issue(title, description, priority=3, labels=None):
    """Create a Linear issue"""
    mutation = """
    mutation CreateIssue($input: IssueCreateInput!) {
        issueCreate(input: $input) {
            success
            issue {
                id
                identifier
                title
                url
            }
        }
    }
    """

    issue_input = {
        "teamId": ACP_TEAM_ID,
        "title": title,
        "description": description,
        "priority": priority,
        "stateId": ACP_TODO_STATE_ID
    }

    # Add labels if provided (labels must be pre-created or omitted for now)
    # Linear API requires label IDs, not names
    # We'll skip labels for now to avoid complexity

    response = requests.post(
        GRAPHQL_URL,
        json={
            "query": mutation,
            "variables": {"input": issue_input}
        },
        headers=headers
    )

    if response.status_code == 200:
        try:
            data = response.json()
            if data and data.get("data", {}).get("issueCreate", {}).get("success"):
                issue = data["data"]["issueCreate"]["issue"]
                return issue
            else:
                print(f"    Error: {data}")
                return None
        except Exception as e:
            print(f"    Error parsing response: {e}")
            print(f"    Response: {response.text}")
            return None
    else:
        print(f"    HTTP {response.status_code}: {response.text}")
        return None

def format_issue_description(row):
    """Format CSV row into Linear issue description"""
    parts = []

    if row.get("Initiative"):
        parts.append(f"**Initiative:** {row['Initiative']}")

    if row.get("Epic"):
        parts.append(f"**Epic:** {row['Epic']}")

    if row.get("Estimate"):
        parts.append(f"**Estimate:** {row['Estimate']} hours")

    if row.get("Labels"):
        parts.append(f"**Labels:** {row['Labels']}")

    if row.get("Assignee"):
        parts.append(f"**Assignee:** {row['Assignee']}")

    return "\n".join(parts)

def main():
    csv_file = "../../linear_issues_builds_63_66.csv"

    print("="*80)
    print("Import Linear Issues from CSV")
    print("="*80)
    print(f"Team: ACP (Agent-Control-Plane)")
    print(f"Team ID: {ACP_TEAM_ID}")
    print(f"Default State: Todo")
    print(f"CSV File: {csv_file}")
    print("="*80)
    print()

    # Read CSV
    issues_to_create = []
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            issues_to_create.append(row)

    print(f"Found {len(issues_to_create)} issues to create\n")

    # Confirm
    response = input("Proceed with creating issues? (yes/no): ")
    if response.lower() != "yes":
        print("Aborted.")
        return

    print()
    print("Creating issues...")
    print("-" * 80)

    created_issues = []
    failed_issues = []

    for i, row in enumerate(issues_to_create, 1):
        title = row["Issue"]
        description = format_issue_description(row)
        priority = PRIORITY_MAP.get(row.get("Priority", "Medium"), 3)

        print(f"{i}/{len(issues_to_create)}: {title}")

        issue = create_issue(title, description, priority)

        if issue:
            print(f"  ✅ Created: {issue['identifier']}")
            print(f"     URL: {issue['url']}")
            created_issues.append({
                "identifier": issue['identifier'],
                "title": title,
                "url": issue['url']
            })
        else:
            print(f"  ❌ Failed to create issue")
            failed_issues.append(title)

        # Rate limiting: pause between requests
        if i < len(issues_to_create):
            time.sleep(0.5)  # 500ms between requests

        print()

    print("="*80)
    print("Import Complete")
    print("="*80)
    print()
    print(f"✅ Successfully created: {len(created_issues)} issues")
    print(f"❌ Failed to create: {len(failed_issues)} issues")
    print()

    if created_issues:
        print("Created Issues:")
        for issue in created_issues:
            print(f"  • {issue['identifier']}: {issue['title']}")
            print(f"    {issue['url']}")

    if failed_issues:
        print()
        print("Failed Issues:")
        for title in failed_issues:
            print(f"  • {title}")

    print()
    print(f"Total: {len(created_issues)}/{len(issues_to_create)} issues created")

if __name__ == "__main__":
    main()
