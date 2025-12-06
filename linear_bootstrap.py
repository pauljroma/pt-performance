#!/usr/bin/env python3
"""
Linear Bootstrap Script
Creates team, labels, project, and initial issues in Linear using GraphQL API.
"""

import asyncio
import os
import sys
from typing import Dict, List, Optional

import aiohttp


LINEAR_API_URL = "https://api.linear.app/graphql"


class LinearBootstrap:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.headers = {
            "Authorization": api_key,
            "Content-Type": "application/json",
        }
        self.session: Optional[aiohttp.ClientSession] = None

    async def __aenter__(self):
        self.session = aiohttp.ClientSession(headers=self.headers)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()

    async def query(self, query: str, variables: Optional[Dict] = None) -> Dict:
        """Execute a GraphQL query."""
        if not self.session:
            raise RuntimeError("Session not initialized. Use async context manager.")

        payload = {"query": query}
        if variables:
            payload["variables"] = variables

        async with self.session.post(LINEAR_API_URL, json=payload) as response:
            if response.status != 200:
                text = await response.text()
                raise Exception(f"GraphQL request failed: {response.status} - {text}")

            result = await response.json()
            if "errors" in result:
                raise Exception(f"GraphQL errors: {result['errors']}")

            return result.get("data", {})

    async def get_or_create_team(self, team_name: str) -> Dict:
        """Get existing team or create if it doesn't exist."""
        # Query for existing team
        query = """
        query Teams {
            teams {
                nodes {
                    id
                    name
                    key
                }
            }
        }
        """

        data = await self.query(query)
        teams = data.get("teams", {}).get("nodes", [])

        for team in teams:
            if team["name"] == team_name:
                print(f"✓ Team '{team_name}' already exists (ID: {team['id']}, Key: {team['key']})")
                return team

        # Create team if it doesn't exist
        mutation = """
        mutation CreateTeam($name: String!, $key: String!) {
            teamCreate(input: {name: $name, key: $key}) {
                success
                team {
                    id
                    name
                    key
                }
            }
        }
        """

        variables = {
            "name": team_name,
            "key": "ACP"  # Team key for Agent-Control-Plane
        }

        data = await self.query(mutation, variables)
        team = data["teamCreate"]["team"]
        print(f"✓ Created team '{team_name}' (ID: {team['id']}, Key: {team['key']})")
        return team

    async def get_or_create_label(self, team_id: str, label_name: str) -> Dict:
        """Get existing label or create if it doesn't exist."""
        # Query for existing labels
        query = """
        query Labels($teamId: String!) {
            team(id: $teamId) {
                labels {
                    nodes {
                        id
                        name
                    }
                }
            }
        }
        """

        data = await self.query(query, {"teamId": team_id})
        labels = data.get("team", {}).get("labels", {}).get("nodes", [])

        for label in labels:
            if label["name"] == label_name:
                print(f"  ✓ Label '{label_name}' already exists (ID: {label['id']})")
                return label

        # Create label if it doesn't exist
        mutation = """
        mutation CreateLabel($teamId: String!, $name: String!) {
            issueLabelCreate(input: {teamId: $teamId, name: $name}) {
                success
                issueLabel {
                    id
                    name
                }
            }
        }
        """

        variables = {
            "teamId": team_id,
            "name": label_name
        }

        data = await self.query(mutation, variables)
        label = data["issueLabelCreate"]["issueLabel"]
        print(f"  ✓ Created label '{label_name}' (ID: {label['id']})")
        return label

    async def get_or_create_project(self, team_id: str, project_name: str) -> Dict:
        """Get existing project or create if it doesn't exist."""
        # Query for existing projects
        query = """
        query Projects($teamId: String!) {
            team(id: $teamId) {
                projects {
                    nodes {
                        id
                        name
                        url
                    }
                }
            }
        }
        """

        data = await self.query(query, {"teamId": team_id})
        projects = data.get("team", {}).get("projects", {}).get("nodes", [])

        for project in projects:
            if project["name"] == project_name:
                print(f"✓ Project '{project_name}' already exists")
                print(f"  ID: {project['id']}")
                print(f"  URL: {project['url']}")
                return project

        # Create project if it doesn't exist
        mutation = """
        mutation CreateProject($teamIds: [String!]!, $name: String!) {
            projectCreate(input: {teamIds: $teamIds, name: $name}) {
                success
                project {
                    id
                    name
                    url
                }
            }
        }
        """

        variables = {
            "teamIds": [team_id],
            "name": project_name
        }

        data = await self.query(mutation, variables)
        project = data["projectCreate"]["project"]
        print(f"✓ Created project '{project_name}'")
        print(f"  ID: {project['id']}")
        print(f"  URL: {project['url']}")
        return project

    async def get_or_create_issue(
        self,
        team_id: str,
        project_id: str,
        title: str,
        label_ids: List[str]
    ) -> Dict:
        """Get existing issue or create if it doesn't exist."""
        # Query for existing issues in the project
        query = """
        query ProjectIssues($projectId: String!) {
            project(id: $projectId) {
                issues {
                    nodes {
                        id
                        title
                        url
                    }
                }
            }
        }
        """

        data = await self.query(query, {"projectId": project_id})
        issues = data.get("project", {}).get("issues", {}).get("nodes", [])

        for issue in issues:
            if issue["title"] == title:
                print(f"  ✓ Issue '{title}' already exists")
                print(f"    ID: {issue['id']}")
                print(f"    URL: {issue['url']}")
                return issue

        # Create issue if it doesn't exist
        mutation = """
        mutation CreateIssue($teamId: String!, $projectId: String!, $title: String!, $labelIds: [String!]!) {
            issueCreate(input: {teamId: $teamId, projectId: $projectId, title: $title, labelIds: $labelIds}) {
                success
                issue {
                    id
                    title
                    url
                    identifier
                }
            }
        }
        """

        variables = {
            "teamId": team_id,
            "projectId": project_id,
            "title": title,
            "labelIds": label_ids
        }

        data = await self.query(mutation, variables)
        issue = data["issueCreate"]["issue"]
        print(f"  ✓ Created issue '{title}'")
        print(f"    ID: {issue['id']}")
        print(f"    Identifier: {issue['identifier']}")
        print(f"    URL: {issue['url']}")
        return issue


async def main():
    # Get API key from environment
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ Error: LINEAR_API_KEY environment variable not set")
        sys.exit(1)

    print("🚀 Linear Bootstrap Script")
    print("=" * 60)

    async with LinearBootstrap(api_key) as linear:
        # 1. Ensure team exists
        print("\n1️⃣  Ensuring team exists...")
        team = await linear.get_or_create_team("Agent-Control-Plane")
        team_id = team["id"]

        # 2. Create labels
        print("\n2️⃣  Creating labels...")
        label_names = [
            "zone-3a", "zone-3b", "zone-3c", "zone-4a", "zone-4b",
            "zone-7", "zone-8", "zone-10b", "zone-12", "zone-13"
        ]

        labels = {}
        for label_name in label_names:
            label = await linear.get_or_create_label(team_id, label_name)
            labels[label_name] = label

        # 3. Create project
        print("\n3️⃣  Creating project...")
        project = await linear.get_or_create_project(
            team_id,
            "MVP 1 — PT App & Agent Pilot"
        )
        project_id = project["id"]

        # 4. Create issues
        print("\n4️⃣  Creating issues...")
        issues_config = [
            {
                "title": "Define Supabase Schema for PT App",
                "labels": ["zone-7", "zone-8"]
            },
            {
                "title": "Scaffold iOS SwiftUI App Structure",
                "labels": ["zone-12"]
            },
            {
                "title": "Create PT Agent Service Backend Skeleton",
                "labels": ["zone-3c", "zone-12"]
            }
        ]

        for issue_config in issues_config:
            label_ids = [labels[label_name]["id"] for label_name in issue_config["labels"]]
            await linear.get_or_create_issue(
                team_id,
                project_id,
                issue_config["title"],
                label_ids
            )

    print("\n" + "=" * 60)
    print("✅ Bootstrap complete!")


if __name__ == "__main__":
    asyncio.run(main())
