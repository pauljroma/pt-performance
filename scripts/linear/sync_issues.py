#!/usr/bin/env python3
"""
Linear Issues Sync Tool

Syncs issues from Linear API to local tracking.

Usage:
    python3 scripts/linear/sync_issues.py
    python3 scripts/linear/sync_issues.py --team TEAM_ID
    python3 scripts/linear/sync_issues.py --state "In Progress"
    python3 scripts/linear/sync_issues.py --project "Project Name"

Features:
- Fetch issues from Linear API
- Filter by team, state, project
- Export to JSON/CSV
- Update local tracking
"""

import os
import sys
import json
import argparse
from pathlib import Path
from typing import List, Dict, Optional
from datetime import datetime

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

    def get_issues(
        self,
        team_id: Optional[str] = None,
        state: Optional[str] = None,
        project_name: Optional[str] = None,
        limit: int = 50,
    ) -> List[Dict]:
        """Fetch issues from Linear"""

        # Build filter
        filter_parts = []
        if team_id:
            filter_parts.append(f'team: {{ id: {{ eq: "{team_id}" }} }}')
        if state:
            filter_parts.append(f'state: {{ name: {{ eq: "{state}" }} }}')
        if project_name:
            filter_parts.append(f'project: {{ name: {{ eq: "{project_name}" }} }}')

        filter_str = ", ".join(filter_parts) if filter_parts else ""
        filter_clause = f"filter: {{ {filter_str} }}" if filter_str else ""

        query = f"""
        query {{
          issues(first: {limit}, {filter_clause}) {{
            nodes {{
              id
              identifier
              title
              description
              priority
              estimate
              createdAt
              updatedAt
              completedAt
              state {{
                name
                type
              }}
              assignee {{
                name
                email
              }}
              team {{
                id
                name
              }}
              project {{
                name
                targetDate
              }}
              labels {{
                nodes {{
                  name
                  color
                }}
              }}
              url
            }}
          }}
        }}
        """

        data = self.query(query)
        return data["issues"]["nodes"]

    def get_teams(self) -> List[Dict]:
        """Fetch teams"""
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

        data = self.query(query)
        return data["teams"]["nodes"]


def export_to_json(issues: List[Dict], output_path: Path):
    """Export issues to JSON"""
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(issues, f, indent=2, default=str)

    print(f"✅ Exported {len(issues)} issues to {output_path}")


def export_to_csv(issues: List[Dict], output_path: Path):
    """Export issues to CSV"""
    import csv

    if not issues:
        print("⚠️  No issues to export")
        return

    # Flatten issue structure for CSV
    rows = []
    for issue in issues:
        row = {
            "id": issue["id"],
            "identifier": issue["identifier"],
            "title": issue["title"],
            "state": issue["state"]["name"],
            "priority": issue.get("priority", ""),
            "estimate": issue.get("estimate", ""),
            "assignee": issue["assignee"]["name"] if issue.get("assignee") else "",
            "team": issue["team"]["name"] if issue.get("team") else "",
            "project": issue["project"]["name"] if issue.get("project") else "",
            "created": issue["createdAt"],
            "updated": issue["updatedAt"],
            "url": issue["url"],
        }
        rows.append(row)

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)

    print(f"✅ Exported {len(issues)} issues to {output_path}")


def print_summary(issues: List[Dict]):
    """Print issue summary"""
    print("\n" + "=" * 60)
    print("SYNC SUMMARY")
    print("=" * 60)

    print(f"\n📊 Total issues: {len(issues)}")

    # Group by state
    by_state = {}
    for issue in issues:
        state = issue["state"]["name"]
        by_state[state] = by_state.get(state, 0) + 1

    print("\n📋 By state:")
    for state, count in sorted(by_state.items()):
        print(f"  {state}: {count}")

    # Group by team
    by_team = {}
    for issue in issues:
        team = issue["team"]["name"] if issue.get("team") else "No team"
        by_team[team] = by_team.get(team, 0) + 1

    print("\n👥 By team:")
    for team, count in sorted(by_team.items()):
        print(f"  {team}: {count}")

    # Group by project
    by_project = {}
    for issue in issues:
        project = issue["project"]["name"] if issue.get("project") else "No project"
        by_project[project] = by_project.get(project, 0) + 1

    print("\n📦 By project:")
    for project, count in sorted(by_project.items()):
        print(f"  {project}: {count}")

    print("\n" + "=" * 60)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Sync issues from Linear API")
    parser.add_argument("--team", help="Filter by team ID")
    parser.add_argument("--state", help="Filter by state (e.g., 'In Progress')")
    parser.add_argument("--project", help="Filter by project name")
    parser.add_argument("--limit", type=int, default=50, help="Max issues to fetch")
    parser.add_argument(
        "--output",
        default="linear_issues.json",
        help="Output file path (default: linear_issues.json)",
    )
    parser.add_argument(
        "--format",
        choices=["json", "csv"],
        default="json",
        help="Output format (default: json)",
    )
    parser.add_argument("--list-teams", action="store_true", help="List all teams")

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

    # List teams if requested
    if args.list_teams:
        print("🔍 Fetching teams...")
        teams = client.get_teams()

        print("\n" + "=" * 60)
        print("TEAMS")
        print("=" * 60)

        for team in teams:
            print(f"\n{team['name']} ({team['key']})")
            print(f"  ID: {team['id']}")

        print("\n" + "=" * 60)
        sys.exit(0)

    # Fetch issues
    print("🔍 Fetching issues from Linear...")
    print(f"   Filters: team={args.team}, state={args.state}, project={args.project}")
    print("")

    issues = client.get_issues(
        team_id=args.team, state=args.state, project_name=args.project, limit=args.limit
    )

    if not issues:
        print("⚠️  No issues found")
        sys.exit(0)

    # Print summary
    print_summary(issues)

    # Export
    output_path = Path(args.output)
    print(f"\n💾 Exporting to {output_path}...")

    if args.format == "json":
        export_to_json(issues, output_path)
    else:
        export_to_csv(issues, output_path)

    print("\n✅ Sync complete!")


if __name__ == "__main__":
    main()
