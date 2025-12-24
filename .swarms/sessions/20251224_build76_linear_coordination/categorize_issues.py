#!/usr/bin/env python3
"""Categorize Linear issues by repository"""

import json
from pathlib import Path

# Load Linear issues
with open('linear_issues.json') as f:
    data = json.load(f)

# Categorize by repo based on labels and content
linear_bootstrap_issues = []
ios_issues = []
quiver_issues = []
uncategorized = []

for issue in data:
    title_lower = issue['title'].lower()
    labels = [label.get('name', '') for label in issue.get('labels', {}).get('nodes', [])]

    # Categorize based on labels and title keywords
    if 'ios' in labels or 'build' in title_lower or 'testflight' in title_lower:
        ios_issues.append(issue)
    elif 'backend' in labels or 'quiver' in labels or 'sapphire' in labels or 'whoop' in title_lower or 'wearable' in title_lower:
        quiver_issues.append(issue)
    elif 'content' in labels or 'article' in title_lower or 'breathing' in title_lower or 'mental' in title_lower:
        linear_bootstrap_issues.append(issue)
    else:
        uncategorized.append(issue)

# Build categorization
categorization = {
    "linear-bootstrap": {
        "count": len(linear_bootstrap_issues),
        "issues": [{"id": i['identifier'], "title": i['title'], "state": i['state']['name'], "priority": i.get('priority', 0)} for i in linear_bootstrap_issues]
    },
    "ios-app": {
        "count": len(ios_issues),
        "issues": [{"id": i['identifier'], "title": i['title'], "state": i['state']['name'], "priority": i.get('priority', 0)} for i in ios_issues]
    },
    "quiver": {
        "count": len(quiver_issues),
        "issues": [{"id": i['identifier'], "title": i['title'], "state": i['state']['name'], "priority": i.get('priority', 0)} for i in quiver_issues]
    },
    "uncategorized": {
        "count": len(uncategorized),
        "issues": [{"id": i['identifier'], "title": i['title'], "state": i['state']['name'], "priority": i.get('priority', 0)} for i in uncategorized]
    }
}

# Save categorization
with open('work_distribution.json', 'w') as f:
    json.dump(categorization, f, indent=2)

# Print summary
print("📊 Linear Issues Categorization:")
print("=" * 60)
print(f"Linear-Bootstrap: {categorization['linear-bootstrap']['count']} issues")
print(f"iOS App:          {categorization['ios-app']['count']} issues")
print(f"Quiver/Sapphire:  {categorization['quiver']['count']} issues")
print(f"Uncategorized:    {categorization['uncategorized']['count']} issues")
print(f"\nTotal: {len(data)} issues")
print(f"\n✅ Saved to: work_distribution.json")

# Show Build 76 candidates (P1 issues in Todo/Backlog)
print("\n🎯 Build 76 Candidates (P1 Priority):")
print("=" * 60)
build_76_candidates = [i for i in data if i.get('priority', 99) == 1 and i['state']['name'] in ['Todo', 'Backlog']]
for issue in sorted(build_76_candidates, key=lambda x: x['identifier'])[:10]:
    print(f"{issue['identifier']}: {issue['title'][:55]}")

print(f"\n📝 Found {len(build_76_candidates)} P1 candidates for Build 76")
