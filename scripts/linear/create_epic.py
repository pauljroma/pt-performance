#!/usr/bin/env python3
"""
Linear Epic Creation Tool

Creates epics (projects) in Linear from JSON specifications.

Usage:
    python3 scripts/linear/create_epic.py epic_spec.json
    python3 scripts/linear/create_epic.py --interactive

Features:
- Create epics from JSON specification
- Interactive epic creation
- Bulk epic creation
- Dry-run mode for validation
"""

import os
import sys
import json
import argparse
from pathlib import Path
from typing import Dict, Optional
from datetime import datetime, timedelta

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

    def get_teams(self):
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

    def create_project(
        self,
        name: str,
        description: str,
        team_ids: list,
        target_date: Optional[str] = None,
        lead_id: Optional[str] = None,
        state: str = "planned",
    ) -> Dict:
        """Create a project (epic) in Linear"""

        mutation = """
        mutation ProjectCreate($input: ProjectCreateInput!) {
          projectCreate(input: $input) {
            success
            project {
              id
              name
              url
              targetDate
              state
              teams {
                nodes {
                  name
                }
              }
            }
          }
        }
        """

        variables = {
            "input": {
                "name": name,
                "description": description,
                "teamIds": team_ids,
                "state": state,
            }
        }

        if target_date:
            variables["input"]["targetDate"] = target_date

        if lead_id:
            variables["input"]["leadId"] = lead_id

        data = self.query(mutation, variables)
        return data["projectCreate"]

    def create_issue(
        self,
        title: str,
        description: str,
        team_id: str,
        project_id: Optional[str] = None,
        assignee_id: Optional[str] = None,
        priority: int = 3,
        estimate: Optional[int] = None,
    ) -> Dict:
        """Create an issue in Linear"""

        mutation = """
        mutation IssueCreate($input: IssueCreateInput!) {
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

        variables = {
            "input": {
                "title": title,
                "description": description,
                "teamId": team_id,
                "priority": priority,
            }
        }

        if project_id:
            variables["input"]["projectId"] = project_id

        if assignee_id:
            variables["input"]["assigneeId"] = assignee_id

        if estimate:
            variables["input"]["estimate"] = estimate

        data = self.query(mutation, variables)
        return data["issueCreate"]


def load_epic_spec(spec_path: Path) -> Dict:
    """Load epic specification from JSON file"""
    with open(spec_path, "r", encoding="utf-8") as f:
        return json.load(f)


def create_epic_from_spec(client: LinearClient, spec: Dict, dry_run: bool = False):
    """Create epic from specification"""

    print("=" * 60)
    print("EPIC SPECIFICATION")
    print("=" * 60)

    print(f"\n📦 Name: {spec['name']}")
    print(f"📝 Description: {spec.get('description', 'N/A')[:100]}...")
    print(f"🎯 Target Date: {spec.get('target_date', 'N/A')}")
    print(f"👥 Teams: {', '.join(spec.get('team_ids', []))}")

    if "issues" in spec:
        print(f"📋 Issues to create: {len(spec['issues'])}")

    print("\n" + "=" * 60)

    if dry_run:
        print("\n🔍 DRY RUN - No changes will be made")
        return

    # Confirm
    response = input("\nCreate this epic? (y/N) ")
    if response.lower() != "y":
        print("❌ Aborted")
        return

    # Create project
    print("\n🚀 Creating project...")

    result = client.create_project(
        name=spec["name"],
        description=spec.get("description", ""),
        team_ids=spec.get("team_ids", []),
        target_date=spec.get("target_date"),
        lead_id=spec.get("lead_id"),
        state=spec.get("state", "planned"),
    )

    if not result["success"]:
        print("❌ Failed to create project")
        return

    project = result["project"]
    project_id = project["id"]

    print(f"✅ Created project: {project['name']}")
    print(f"   ID: {project_id}")
    print(f"   URL: {project['url']}")

    # Create issues if specified
    if "issues" in spec and spec["issues"]:
        print(f"\n📋 Creating {len(spec['issues'])} issues...")

        for idx, issue_spec in enumerate(spec["issues"], 1):
            print(f"\n  [{idx}/{len(spec['issues'])}] {issue_spec['title']}")

            issue_result = client.create_issue(
                title=issue_spec["title"],
                description=issue_spec.get("description", ""),
                team_id=spec["team_ids"][0],  # Use first team
                project_id=project_id,
                assignee_id=issue_spec.get("assignee_id"),
                priority=issue_spec.get("priority", 3),
                estimate=issue_spec.get("estimate"),
            )

            if issue_result["success"]:
                issue = issue_result["issue"]
                print(f"    ✅ {issue['identifier']}: {issue['title']}")
            else:
                print(f"    ❌ Failed to create issue")

    print("\n" + "=" * 60)
    print("✅ Epic creation complete!")
    print("=" * 60)


def interactive_epic_creation(client: LinearClient):
    """Create epic interactively"""

    print("=" * 60)
    print("INTERACTIVE EPIC CREATION")
    print("=" * 60)

    # Get teams
    print("\n🔍 Fetching teams...")
    teams = client.get_teams()

    print("\nAvailable teams:")
    for idx, team in enumerate(teams, 1):
        print(f"  {idx}. {team['name']} ({team['key']}) - {team['id']}")

    # Get input
    print("\n" + "=" * 60)

    name = input("Epic name: ")
    description = input("Description: ")

    # Select team
    team_idx = int(input(f"Team (1-{len(teams)}): ")) - 1
    team_id = teams[team_idx]["id"]

    # Target date (optional)
    target_date_input = input("Target date (YYYY-MM-DD, or Enter to skip): ")
    target_date = target_date_input if target_date_input else None

    # Confirm
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Name: {name}")
    print(f"Description: {description}")
    print(f"Team: {teams[team_idx]['name']}")
    print(f"Target Date: {target_date or 'N/A'}")
    print("=" * 60)

    response = input("\nCreate this epic? (y/N) ")
    if response.lower() != "y":
        print("❌ Aborted")
        return

    # Create
    print("\n🚀 Creating project...")

    result = client.create_project(
        name=name,
        description=description,
        team_ids=[team_id],
        target_date=target_date,
        state="planned",
    )

    if result["success"]:
        project = result["project"]
        print(f"\n✅ Created project: {project['name']}")
        print(f"   ID: {project['id']}")
        print(f"   URL: {project['url']}")
    else:
        print("\n❌ Failed to create project")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Create epics in Linear")
    parser.add_argument("spec_file", nargs="?", help="Epic specification JSON file")
    parser.add_argument(
        "--interactive", "-i", action="store_true", help="Interactive epic creation"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Validate spec without creating"
    )

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

    # Interactive mode
    if args.interactive:
        interactive_epic_creation(client)
        return

    # Spec file mode
    if not args.spec_file:
        print("❌ Spec file or --interactive required")
        parser.print_help()
        sys.exit(1)

    spec_path = Path(args.spec_file)
    if not spec_path.exists():
        print(f"❌ Spec file not found: {spec_path}")
        sys.exit(1)

    # Load and create
    spec = load_epic_spec(spec_path)
    create_epic_from_spec(client, spec, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
