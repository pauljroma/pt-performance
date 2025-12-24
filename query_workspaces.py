#!/usr/bin/env python3
"""Query Linear API to find all workspaces and teams"""

import os
import requests
import json

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")

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

# Query for organization and teams
org_query = """
query {
  organization {
    id
    name
    urlKey
    teams {
      nodes {
        id
        key
        name
        description
      }
    }
  }
}
"""

print("="*80)
print("Linear Workspaces and Teams")
print("="*80)
print()

result = query_linear(org_query)

if result and result.get("data"):
    org = result["data"]["organization"]
    print(f"Organization: {org['name']}")
    print(f"  URL Key: {org['urlKey']}")
    print(f"  ID: {org['id']}")
    print()
    print("Teams:")
    print("-" * 80)

    for team in org["teams"]["nodes"]:
        print(f"  {team['key']}: {team['name']}")
        print(f"    ID: {team['id']}")
        if team.get("description"):
            print(f"    Description: {team['description']}")
        print()
else:
    print("Failed to query organization")
    print(json.dumps(result, indent=2))

# Query for workflow states
states_query = """
query {
  workflowStates {
    nodes {
      id
      name
      type
      team {
        key
        name
      }
    }
  }
}
"""

print("="*80)
print("Workflow States by Team")
print("="*80)
print()

states_result = query_linear(states_query)

if states_result and states_result.get("data"):
    states = states_result["data"]["workflowStates"]["nodes"]

    # Group by team
    by_team = {}
    for state in states:
        team_key = state["team"]["key"]
        if team_key not in by_team:
            by_team[team_key] = {
                "name": state["team"]["name"],
                "states": []
            }
        by_team[team_key]["states"].append({
            "id": state["id"],
            "name": state["name"],
            "type": state["type"]
        })

    for team_key, team_data in sorted(by_team.items()):
        print(f"{team_key}: {team_data['name']}")
        for state in team_data["states"]:
            print(f"  • {state['name']} ({state['type']}) - ID: {state['id']}")
        print()
else:
    print("Failed to query workflow states")
