#!/usr/bin/env python3
"""
Get detailed list of all backlog issues from Linear
"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()
LINEAR_API_KEY = os.getenv('LINEAR_API_KEY')

if not LINEAR_API_KEY:
    print("❌ LINEAR_API_KEY not found in .env")
    exit(1)

LINEAR_API = "https://api.linear.app/graphql"
HEADERS = {
    "Authorization": LINEAR_API_KEY,
    "Content-Type": "application/json"
}

def get_backlog_issues():
    """Get all backlog issues with full details"""
    query = """
    query Issues {
        issues(filter: { state: { type: { eq: "backlog" } } }) {
            nodes {
                id
                identifier
                title
                description
                priority
                estimate
                labels {
                    nodes {
                        name
                    }
                }
                assignee {
                    name
                }
                createdAt
            }
        }
    }
    """

    response = requests.post(
        LINEAR_API,
        headers=HEADERS,
        json={"query": query}
    )

    if response.status_code == 200:
        result = response.json()
        return result['data']['issues']['nodes']
    return []

def main():
    print("\n" + "="*80)
    print("📋 BACKLOG ISSUES - DETAILED VIEW")
    print("="*80 + "\n")

    issues = get_backlog_issues()

    if not issues:
        print("✅ No backlog issues found! All done!")
        return

    print(f"Found {len(issues)} backlog issues:\n")

    for i, issue in enumerate(issues, 1):
        print(f"{i}. {issue['identifier']}: {issue['title']}")

        if issue.get('description'):
            # Truncate description
            desc = issue['description'][:200]
            if len(issue['description']) > 200:
                desc += "..."
            print(f"   Description: {desc}")

        labels = [label['name'] for label in issue.get('labels', {}).get('nodes', [])]
        if labels:
            print(f"   Labels: {', '.join(labels)}")

        if issue.get('priority'):
            print(f"   Priority: {issue['priority']}")

        if issue.get('estimate'):
            print(f"   Estimate: {issue['estimate']} points")

        print()

    print("="*80)
    print(f"Total: {len(issues)} issues in backlog")
    print("="*80)

if __name__ == "__main__":
    main()
