#!/usr/bin/env python3
"""
Get the specific 11 backlog issues
"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()
LINEAR_API_KEY = os.getenv('LINEAR_API_KEY')

LINEAR_API = "https://api.linear.app/graphql"
HEADERS = {
    "Authorization": LINEAR_API_KEY,
    "Content-Type": "application/json"
}

def get_backlog_issues():
    """Get backlog issues"""
    query = """
    query Issues {
        issues(filter: { state: { type: { eq: "backlog" } } }) {
            nodes {
                id
                identifier
                title
                description
                labels {
                    nodes {
                        name
                    }
                }
            }
        }
    }
    """

    response = requests.post(LINEAR_API, headers=HEADERS, json={"query": query})
    if response.status_code == 200:
        return response.json()['data']['issues']['nodes']
    return []

print("\n" + "="*80)
print("📋 REMAINING 11 BACKLOG ISSUES")
print("="*80 + "\n")

issues = get_backlog_issues()

print(f"Total backlog: {len(issues)} issues\n")

# Categorize by phase
phase_2 = []
other = []

for issue in issues:
    labels = [l['name'] for l in issue.get('labels', {}).get('nodes', [])]

    # Check if it's zone-3c or zone-4b (Phase 2: Backend Intelligence)
    if 'zone-3c' in labels or 'zone-4b' in labels:
        phase_2.append(issue)
    else:
        other.append(issue)

print(f"🟢 PHASE 2: Backend Intelligence ({len(phase_2)} issues)")
print("-" * 80)
for issue in phase_2:
    labels = [l['name'] for l in issue.get('labels', {}).get('nodes', [])]
    print(f"{issue['identifier']}: {issue['title']}")
    print(f"  Labels: {', '.join(labels)}")
    if issue.get('description'):
        desc = issue['description'][:150].replace('\n', ' ')
        print(f"  Description: {desc}...")
    print()

print(f"\n🟡 OTHER PHASES ({len(other)} issues)")
print("-" * 80)
for issue in other:
    labels = [l['name'] for l in issue.get('labels', {}).get('nodes', [])]
    print(f"{issue['identifier']}: {issue['title']}")
    print(f"  Labels: {', '.join(labels)}")
    if issue.get('description'):
        desc = issue['description'][:150].replace('\n', ' ')
        print(f"  Description: {desc}...")
    print()

print("="*80)
print(f"Total: {len(issues)} backlog issues")
print("="*80)
