#!/usr/bin/env python3
"""
Linear Issue Status Update Tool

Updates issue status in Linear.

Usage:
    python3 scripts/linear/update_status.py ISSUE_ID "Done"
    python3 scripts/linear/update_status.py PT-123 "In Progress"
    python3 scripts/linear/update_status.py PT-123 "Done" --comment "Completed testing"

Features:
- Update issue status by identifier
- Add status update comment
- Bulk status updates from file
- List available states
"""

import os
import sys
import json
import argparse
from typing import Dict, List, Optional

try:
    import requests
except ImportError:
    print("❌ requests library required")
    print("Install with: pip install requests")
    sys.exit(1)


class LinearClient:
    """Simple Linear API client"""

    API_URL = "https://api.linear.app/graphql"

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.headers = {
            "Authorization": api_key,
            "Content-Type": "application/json",
        }

    def query(self, query: str, variables: Optional[Dict] = None) -> Dict:
        """Execute GraphQL query"""
        payload = {"query": query}
        if variables:
            payload["variables"] = variables

        response = requests.post(
            self.API_URL, json=payload, headers=self.headers, timeout=30
        )
        response.raise_for_status()

        data = response.json()
        if "errors" in data:
            raise Exception(f"GraphQL errors: {data['errors']}")

        return data["data"]

    def get_issue_by_identifier(self, identifier: str) -> Optional[Dict]:
        """Get issue by identifier (e.g., PT-123)"""
        query = """
        query Issue($identifier: String!) {
          issue(id: $identifier) {
            id
            identifier
            title
            state {
              id
              name
              type
            }
            team {
              id
              name
            }
          }
        }
        """

        try:
            data = self.query(query, {"identifier": identifier})
            return data.get("issue")
        except Exception:
            # Try searching by identifier
            search_query = """
            query Issues($filter: IssueFilter) {
              issues(filter: $filter, first: 1) {
                nodes {
                  id
                  identifier
                  title
                  state {
                    id
                    name
                    type
                  }
                  team {
                    id
                    name
                  }
                }
              }
            }
            """

            data = self.query(
                search_query, {"filter": {"number": {"eq": int(identifier.split("-")[1])}}}
            )
            issues = data["issues"]["nodes"]
            return issues[0] if issues else None

    def get_workflow_states(self, team_id: str) -> List[Dict]:
        """Get available workflow states for a team"""
        query = """
        query Team($teamId: String!) {
          team(id: $teamId) {
            states {
              nodes {
                id
                name
                type
                description
              }
            }
          }
        }
        """

        data = self.query(query, {"teamId": team_id})
        return data["team"]["states"]["nodes"]

    def update_issue_state(self, issue_id: str, state_id: str) -> bool:
        """Update issue state"""
        mutation = """
        mutation IssueUpdate($id: String!, $stateId: String!) {
          issueUpdate(id: $id, input: { stateId: $stateId }) {
            success
            issue {
              id
              identifier
              title
              state {
                name
              }
            }
          }
        }
        """

        data = self.query(mutation, {"id": issue_id, "stateId": state_id})
        result = data["issueUpdate"]

        if result["success"]:
            issue = result["issue"]
            print(
                f"✅ Updated {issue['identifier']}: {issue['title']} → {issue['state']['name']}"
            )
            return True
        else:
            print(f"❌ Failed to update issue")
            return False

    def add_comment(self, issue_id: str, body: str) -> bool:
        """Add comment to issue"""
        mutation = """
        mutation CommentCreate($issueId: String!, $body: String!) {
          commentCreate(input: { issueId: $issueId, body: $body }) {
            success
            comment {
              id
              body
            }
          }
        }
        """

        data = self.query(mutation, {"issueId": issue_id, "body": body})
        result = data["commentCreate"]

        if result["success"]:
            print(f"✅ Added comment to issue")
            return True
        else:
            print(f"❌ Failed to add comment")
            return False


def find_state_by_name(states: List[Dict], name: str) -> Optional[Dict]:
    """Find state by name (case-insensitive)"""
    name_lower = name.lower()
    for state in states:
        if state["name"].lower() == name_lower:
            return state
    return None


def update_issue_status(
    client: LinearClient,
    identifier: str,
    state_name: str,
    comment: Optional[str] = None,
):
    """Update issue status by identifier"""

    print("=" * 60)
    print("UPDATING ISSUE STATUS")
    print("=" * 60)

    # Get issue
    print(f"\n🔍 Fetching issue {identifier}...")
    issue = client.get_issue_by_identifier(identifier)

    if not issue:
        print(f"❌ Issue not found: {identifier}")
        sys.exit(1)

    print(f"✅ Found: {issue['identifier']} - {issue['title']}")
    print(f"   Current state: {issue['state']['name']}")

    # Get available states
    print(f"\n🔍 Fetching workflow states...")
    states = client.get_workflow_states(issue["team"]["id"])

    # Find target state
    target_state = find_state_by_name(states, state_name)

    if not target_state:
        print(f"\n❌ State not found: {state_name}")
        print(f"\nAvailable states for {issue['team']['name']}:")
        for state in states:
            print(f"  - {state['name']} ({state['type']})")
        sys.exit(1)

    print(f"✅ Target state: {target_state['name']}")

    # Confirm
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Issue: {issue['identifier']} - {issue['title']}")
    print(f"Current: {issue['state']['name']}")
    print(f"Target: {target_state['name']}")
    if comment:
        print(f"Comment: {comment}")
    print("=" * 60)

    response = input("\nUpdate status? (y/N) ")
    if response.lower() != "y":
        print("❌ Aborted")
        return

    # Update state
    print("\n🚀 Updating status...")
    success = client.update_issue_state(issue["id"], target_state["id"])

    if not success:
        sys.exit(1)

    # Add comment if provided
    if comment:
        print("\n💬 Adding comment...")
        client.add_comment(issue["id"], comment)

    print("\n✅ Update complete!")


def list_states(client: LinearClient, team_id: Optional[str] = None):
    """List available workflow states"""

    print("=" * 60)
    print("WORKFLOW STATES")
    print("=" * 60)

    if not team_id:
        # Get teams first
        query = """
        query {
          teams {
            nodes {
              id
              name
              key
            }
          }
        }
        """

        data = client.query(query)
        teams = data["teams"]["nodes"]

        print("\nSelect team:")
        for idx, team in enumerate(teams, 1):
            print(f"  {idx}. {team['name']} ({team['key']})")

        team_idx = int(input("\nTeam (1-{}): ".format(len(teams)))) - 1
        team_id = teams[team_idx]["id"]

    # Get states
    states = client.get_workflow_states(team_id)

    print("\n" + "=" * 60)
    print("Available states:")
    print("=" * 60)

    for state in states:
        print(f"\n{state['name']} ({state['type']})")
        if state.get("description"):
            print(f"  {state['description']}")

    print("\n" + "=" * 60)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Update issue status in Linear")
    parser.add_argument("identifier", nargs="?", help="Issue identifier (e.g., PT-123)")
    parser.add_argument("state", nargs="?", help="Target state (e.g., 'Done')")
    parser.add_argument("--comment", "-c", help="Add comment with status update")
    parser.add_argument(
        "--list-states", "-l", action="store_true", help="List available states"
    )
    parser.add_argument("--team", help="Team ID (for --list-states)")

    args = parser.parse_args()

    # Load API key from environment
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ LINEAR_API_KEY environment variable required")
        print("")
        print("Add to .env:")
        print("  LINEAR_API_KEY=lin_api_XXXXXXXXXXXXXXXXXXXX")
        print("")
        sys.exit(1)

    # Create client
    client = LinearClient(api_key)

    # List states mode
    if args.list_states:
        list_states(client, args.team)
        return

    # Update mode
    if not args.identifier or not args.state:
        print("❌ Issue identifier and state required")
        parser.print_help()
        sys.exit(1)

    update_issue_status(client, args.identifier, args.state, args.comment)


if __name__ == "__main__":
    main()
