#!/usr/bin/env python3
"""
Get the 11 remaining backlog issues with full details
"""
import os
import requests
from dotenv import load_dotenv

load_dotenv()

LINEAR_API_KEY = os.getenv('LINEAR_API_KEY')
LINEAR_PROJECT_ID = os.getenv('LINEAR_PROJECT_ID', 'b88d8e4e-f47e-4b06-bb13-4c4a2d8f9e5e')

headers = {
    'Authorization': LINEAR_API_KEY,
    'Content-Type': 'application/json'
}

def get_all_issues():
    """Get all project issues with state"""
    query = """
    query($projectId: String!) {
      project(id: $projectId) {
        issues(first: 100) {
          nodes {
            id
            identifier
            title
            description
            state {
              name
              type
            }
            labels(first: 10) {
              nodes {
                name
              }
            }
          }
        }
      }
    }
    """

    response = requests.post(
        'https://api.linear.app/graphql',
        headers=headers,
        json={'query': query, 'variables': {'projectId': LINEAR_PROJECT_ID}}
    )

    if response.status_code != 200:
        print(f"Error: {response.status_code}")
        print(response.text)
        return []

    data = response.json()
    if 'errors' in data:
        print("GraphQL Errors:", data['errors'])
        return []

    return data['data']['project']['issues']['nodes']

def main():
    issues = get_all_issues()

    # Filter to backlog only
    backlog_issues = [i for i in issues if i['state']['name'] == 'Backlog']
    done_issues = [i for i in issues if i['state']['name'] == 'Done']

    print("="*80)
    print(f"📊 TOTAL ISSUES: {len(issues)}")
    print(f"✅ Done: {len(done_issues)}")
    print(f"📝 Backlog: {len(backlog_issues)}")
    print("="*80)
    print()

    print("="*80)
    print("🔵 BACKLOG ISSUES (11 remaining)")
    print("="*80)

    for issue in sorted(backlog_issues, key=lambda x: x['identifier']):
        labels = [l['name'] for l in issue['labels']['nodes']]
        label_str = ', '.join(labels) if labels else 'no labels'

        print(f"\n{issue['identifier']}: {issue['title']}")
        print(f"  Labels: {label_str}")
        if issue.get('description'):
            desc = issue['description'][:150].replace('\n', ' ')
            print(f"  Description: {desc}...")

    print("\n" + "="*80)

if __name__ == '__main__':
    main()
