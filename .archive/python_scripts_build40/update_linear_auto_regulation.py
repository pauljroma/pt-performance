#!/usr/bin/env python3
"""Update Linear issues ACP-120 through ACP-132 to Done status"""

from dotenv import load_dotenv
import os
import requests
import json

load_dotenv()
api_key = os.getenv('LINEAR_API_KEY')
done_state_id = '8a9b8266-b8b2-487a-8286-2ef86385e827'  # Agent-Control-Plane team Done state

# Issue IDs from previous query
issues = [
    {'id': 'fbfe0c3c-7900-4254-865b-d4bd34b95e89', 'identifier': 'ACP-121'},
    {'id': '8009c75c-71b8-4848-acd1-7a2b8f7828ca', 'identifier': 'ACP-122'},
    {'id': '8ae32796-3633-47d5-9abb-ba9f0a880b06', 'identifier': 'ACP-123'},
    {'id': '39e31e22-90e2-4524-86a0-f6aa92a07092', 'identifier': 'ACP-124'},
    {'id': 'be728ade-d4cf-45a2-b6e4-fb4374df6d1b', 'identifier': 'ACP-125'},
    {'id': '347d019a-6c36-4568-9758-a47e938ec515', 'identifier': 'ACP-126'},
    {'id': '5515279f-ba68-4c11-8e99-ad98acdadb66', 'identifier': 'ACP-127'},
    {'id': 'a7fed97d-c91c-423e-9af3-0939990ebb88', 'identifier': 'ACP-128'},
    {'id': '66837d2d-5df7-437a-9e32-b36f25365c58', 'identifier': 'ACP-129'},
    {'id': 'ba1c2d6d-2482-4cda-9f97-e8a04f1c6940', 'identifier': 'ACP-130'},
    {'id': '187816de-559a-4eb7-9289-0222b03a9652', 'identifier': 'ACP-131'},
]

# Also find ACP-120 and ACP-132
query_missing = '''
query {
  issues(filter: { number: { in: [120, 132] } }) {
    nodes {
      id
      identifier
      title
    }
  }
}
'''

response = requests.post(
    'https://api.linear.app/graphql',
    headers={'Authorization': api_key, 'Content-Type': 'application/json'},
    json={'query': query_missing}
)

missing_issues = response.json()['data']['issues']['nodes']
for issue in missing_issues:
    issues.append({'id': issue['id'], 'identifier': issue['identifier']})

print(f"Found {len(issues)} issues to update")

# Update each issue to Done
success_count = 0
for issue in issues:
    mutation = f'''
    mutation {{
      issueUpdate(
        id: "{issue['id']}"
        input: {{ stateId: "{done_state_id}" }}
      ) {{
        success
        issue {{
          identifier
          state {{ name }}
        }}
      }}
    }}
    '''

    response = requests.post(
        'https://api.linear.app/graphql',
        headers={'Authorization': api_key, 'Content-Type': 'application/json'},
        json={'query': mutation}
    )

    result = response.json()
    if result and result.get('data', {}).get('issueUpdate', {}).get('success'):
        print(f"✅ {issue['identifier']} updated to Done")
        success_count += 1
    else:
        print(f"❌ {issue['identifier']} failed: {result}")

print(f"\n✅ Updated {success_count}/{len(issues)} auto-regulation issues to Done status")
