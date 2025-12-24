#!/usr/bin/env python3
"""Get workflow states for ACP team"""

import os
import requests

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

query = """
query GetWorkflowStates {
    team(id: "%s") {
        states {
            nodes {
                id
                name
                type
                position
            }
        }
    }
}
""" % ACP_TEAM_ID

response = requests.post(
    GRAPHQL_URL,
    json={
        "query": query
    },
    headers=headers
)

if response.status_code == 200:
    data = response.json()
    states = data.get("data", {}).get("team", {}).get("states", {}).get("nodes", [])

    print("="*80)
    print("ACP Team Workflow States")
    print("="*80)
    print()

    for state in sorted(states, key=lambda s: s.get("position", 0)):
        print(f"{state['name']:<20} | ID: {state['id']}")
        print(f"  Type: {state['type']:<15} Position: {state['position']}")
        print()
else:
    print(f"Error: {response.status_code}")
    print(response.text)
