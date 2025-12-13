#!/usr/bin/env python3
"""
Linear Client - Full CRUD operations for Linear workspace
Provides read/write access to Linear projects, issues, and comments.
"""

import asyncio
import json
import os
import sys
from datetime import datetime
from typing import Dict, List, Optional

import aiohttp


LINEAR_API_URL = "https://api.linear.app/graphql"


class LinearClient:
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

    # ==================== READ OPERATIONS ====================

    async def get_team_by_name(self, team_name: str) -> Optional[Dict]:
        """Get team by name."""
        query = """
        query Teams {
            teams {
                nodes {
                    id
                    name
                    key
                    description
                }
            }
        }
        """

        data = await self.query(query)
        teams = data.get("teams", {}).get("nodes", [])

        for team in teams:
            if team["name"] == team_name:
                return team
        return None

    async def get_project_by_name(self, team_id: str, project_name: str) -> Optional[Dict]:
        """Get project by name within a team."""
        query = """
        query Projects($teamId: String!) {
            team(id: $teamId) {
                projects {
                    nodes {
                        id
                        name
                        description
                        url
                        state
                        progress
                        startDate
                        targetDate
                    }
                }
            }
        }
        """

        data = await self.query(query, {"teamId": team_id})
        projects = data.get("team", {}).get("projects", {}).get("nodes", [])

        for project in projects:
            if project["name"] == project_name:
                return project
        return None

    async def get_project_issues(self, project_id: str) -> List[Dict]:
        """Get all issues in a project with full details."""
        query = """
        query ProjectIssues($projectId: String!) {
            project(id: $projectId) {
                issues {
                    nodes {
                        id
                        identifier
                        title
                        description
                        priority
                        estimate
                        url
                        createdAt
                        updatedAt
                        state {
                            id
                            name
                            type
                        }
                        assignee {
                            id
                            name
                            email
                        }
                        labels {
                            nodes {
                                id
                                name
                                color
                            }
                        }
                        comments {
                            nodes {
                                id
                                body
                                createdAt
                                user {
                                    name
                                }
                            }
                        }
                    }
                }
            }
        }
        """

        data = await self.query(query, {"projectId": project_id})
        return data.get("project", {}).get("issues", {}).get("nodes", [])

    async def get_issue_by_id(self, issue_id: str) -> Optional[Dict]:
        """Get issue details by ID."""
        query = """
        query Issue($issueId: String!) {
            issue(id: $issueId) {
                id
                identifier
                title
                description
                priority
                estimate
                url
                createdAt
                updatedAt
                state {
                    id
                    name
                    type
                }
                assignee {
                    id
                    name
                    email
                }
                labels {
                    nodes {
                        id
                        name
                        color
                    }
                }
                comments {
                    nodes {
                        id
                        body
                        createdAt
                        user {
                            name
                        }
                    }
                }
            }
        }
        """

        data = await self.query(query, {"issueId": issue_id})
        return data.get("issue")

    async def get_workflow_states(self, team_id: str) -> List[Dict]:
        """Get all workflow states for a team."""
        query = """
        query WorkflowStates($teamId: String!) {
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

        data = await self.query(query, {"teamId": team_id})
        return data.get("team", {}).get("states", {}).get("nodes", [])

    # ==================== WRITE OPERATIONS ====================

    async def update_issue_status(self, issue_id: str, state_id: str) -> Dict:
        """Update issue status/state."""
        mutation = """
        mutation UpdateIssue($issueId: String!, $stateId: String!) {
            issueUpdate(id: $issueId, input: {stateId: $stateId}) {
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

        data = await self.query(mutation, {"issueId": issue_id, "stateId": state_id})
        return data["issueUpdate"]["issue"]

    async def add_issue_comment(self, issue_id: str, comment: str) -> Dict:
        """Add a comment to an issue."""
        mutation = """
        mutation CreateComment($issueId: String!, $body: String!) {
            commentCreate(input: {issueId: $issueId, body: $body}) {
                success
                comment {
                    id
                    body
                    createdAt
                }
            }
        }
        """

        data = await self.query(mutation, {"issueId": issue_id, "body": comment})
        return data["commentCreate"]["comment"]

    async def update_issue_description(self, issue_id: str, description: str) -> Dict:
        """Update issue description."""
        mutation = """
        mutation UpdateIssue($issueId: String!, $description: String!) {
            issueUpdate(id: $issueId, input: {description: $description}) {
                success
                issue {
                    id
                    identifier
                    description
                }
            }
        }
        """

        data = await self.query(mutation, {"issueId": issue_id, "description": description})
        return data["issueUpdate"]["issue"]

    async def create_issue(self, team_id: str, title: str, description: str = "",
                          labels: List[str] = None, priority: int = 0,
                          project_id: str = None, parent_id: str = None,
                          estimate: int = None) -> Dict:
        """Create a new issue in a team."""
        mutation = """
        mutation CreateIssue($teamId: String!, $title: String!, $description: String, $labelIds: [String!], $priority: Int, $projectId: String, $parentId: String, $estimate: Int) {
            issueCreate(input: {teamId: $teamId, title: $title, description: $description, labelIds: $labelIds, priority: $priority, projectId: $projectId, parentId: $parentId, estimate: $estimate}) {
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
            "teamId": team_id,
            "title": title,
            "description": description,
            "labelIds": labels or [],
            "priority": priority,
            "projectId": project_id,
            "parentId": parent_id,
            "estimate": estimate
        }

        data = await self.query(mutation, variables)
        return data["issueCreate"]["issue"]

    # ==================== PLAN EXPORT ====================

    async def export_project_plan(self, team_name: str, project_name: str) -> Dict:
        """Export complete project plan as structured data."""
        # Get team
        team = await self.get_team_by_name(team_name)
        if not team:
            raise Exception(f"Team '{team_name}' not found")

        # Get project
        project = await self.get_project_by_name(team["id"], project_name)
        if not project:
            raise Exception(f"Project '{project_name}' not found")

        # Get issues
        issues = await self.get_project_issues(project["id"])

        # Get workflow states
        workflow_states = await self.get_workflow_states(team["id"])

        return {
            "team": team,
            "project": project,
            "issues": issues,
            "workflow_states": workflow_states,
            "exported_at": datetime.utcnow().isoformat(),
        }

    async def export_plan_markdown(self, team_name: str, project_name: str) -> str:
        """Export project plan as formatted markdown."""
        plan = await self.export_project_plan(team_name, project_name)

        md = []
        md.append(f"# {plan['project']['name']}\n")
        md.append(f"**Team:** {plan['team']['name']} ({plan['team']['key']})\n")
        md.append(f"**Project URL:** {plan['project']['url']}\n")

        if plan['project'].get('description'):
            md.append(f"\n## Description\n{plan['project']['description']}\n")

        md.append(f"\n**Progress:** {plan['project'].get('progress', 0):.1f}%\n")

        if plan['project'].get('startDate'):
            md.append(f"**Start Date:** {plan['project']['startDate']}\n")
        if plan['project'].get('targetDate'):
            md.append(f"**Target Date:** {plan['project']['targetDate']}\n")

        md.append(f"\n## Issues ({len(plan['issues'])} total)\n")

        # Group issues by state
        issues_by_state = {}
        for issue in plan['issues']:
            state_name = issue['state']['name']
            if state_name not in issues_by_state:
                issues_by_state[state_name] = []
            issues_by_state[state_name].append(issue)

        for state_name, issues in issues_by_state.items():
            md.append(f"\n### {state_name} ({len(issues)})\n")
            for issue in issues:
                labels = ", ".join([label['name'] for label in issue['labels']['nodes']])
                md.append(f"- **[{issue['identifier']}]({issue['url']})** {issue['title']}")
                if labels:
                    md.append(f" `{labels}`")
                md.append("\n")

                if issue.get('description'):
                    # Indent description
                    desc_lines = issue['description'].split('\n')
                    for line in desc_lines:
                        md.append(f"  {line}\n")

                if issue.get('assignee'):
                    md.append(f"  *Assigned to: {issue['assignee']['name']}*\n")

                # Show recent comments
                comments = issue['comments']['nodes']
                if comments:
                    md.append(f"  💬 {len(comments)} comment(s)\n")

        md.append(f"\n---\n*Exported: {plan['exported_at']}*\n")

        return "".join(md)


async def main():
    import argparse

    parser = argparse.ArgumentParser(description="Linear Client - Query and manage Linear workspace")
    parser.add_argument("command", choices=["export-json", "export-md", "list-issues", "update-status", "add-comment", "create-issue"])
    parser.add_argument("--team", default="Agent-Control-Plane", help="Team name")
    parser.add_argument("--project", default="MVP 1 — PT App & Agent Pilot", help="Project name")
    parser.add_argument("--issue-id", help="Issue ID for update/comment operations")
    parser.add_argument("--state-id", help="State ID for status update")
    parser.add_argument("--comment", help="Comment text")
    parser.add_argument("--output", help="Output file path (optional)")
    parser.add_argument("--title", help="Issue title for create-issue")
    parser.add_argument("--description", help="Issue description for create-issue")
    parser.add_argument("--priority", type=int, default=0, help="Priority (0=none, 1=urgent, 2=high, 3=medium, 4=low)")

    args = parser.parse_args()

    # Get API key from environment
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ Error: LINEAR_API_KEY environment variable not set")
        sys.exit(1)

    async with LinearClient(api_key) as client:
        if args.command == "export-json":
            plan = await client.export_project_plan(args.team, args.project)
            output = json.dumps(plan, indent=2)

            if args.output:
                with open(args.output, "w") as f:
                    f.write(output)
                print(f"✅ Plan exported to {args.output}")
            else:
                print(output)

        elif args.command == "export-md":
            md = await client.export_plan_markdown(args.team, args.project)

            if args.output:
                with open(args.output, "w") as f:
                    f.write(md)
                print(f"✅ Plan exported to {args.output}")
            else:
                print(md)

        elif args.command == "list-issues":
            team = await client.get_team_by_name(args.team)
            if not team:
                print(f"❌ Team '{args.team}' not found")
                sys.exit(1)

            project = await client.get_project_by_name(team["id"], args.project)
            if not project:
                print(f"❌ Project '{args.project}' not found")
                sys.exit(1)

            issues = await client.get_project_issues(project["id"])

            print(f"\n📋 Issues in {args.project}\n")
            for issue in issues:
                labels = ", ".join([label['name'] for label in issue['labels']['nodes']])
                print(f"  [{issue['identifier']}] {issue['title']}")
                print(f"  State: {issue['state']['name']} | Labels: {labels}")
                print(f"  URL: {issue['url']}\n")

        elif args.command == "update-status":
            if not args.issue_id or not args.state_id:
                print("❌ --issue-id and --state-id required for update-status")
                sys.exit(1)

            issue = await client.update_issue_status(args.issue_id, args.state_id)
            print(f"✅ Updated {issue['identifier']}: {issue['title']}")
            print(f"   New state: {issue['state']['name']}")

        elif args.command == "add-comment":
            if not args.issue_id or not args.comment:
                print("❌ --issue-id and --comment required for add-comment")
                sys.exit(1)

            comment = await client.add_issue_comment(args.issue_id, args.comment)
            print(f"✅ Comment added at {comment['createdAt']}")

        elif args.command == "create-issue":
            if not args.title:
                print("❌ --title required for create-issue")
                sys.exit(1)

            # Get team
            team = await client.get_team_by_name(args.team)
            if not team:
                print(f"❌ Team '{args.team}' not found")
                sys.exit(1)

            issue = await client.create_issue(
                team_id=team["id"],
                title=args.title,
                description=args.description or "",
                priority=args.priority
            )
            print(f"✅ Issue created: {issue['identifier']}")
            print(f"   Title: {issue['title']}")
            print(f"   URL: {issue['url']}")


if __name__ == "__main__":
    asyncio.run(main())
