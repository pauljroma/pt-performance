#!/usr/bin/env python3
"""
Linear MCP Server
Provides Linear integration as an MCP server for Claude Code.
"""

import asyncio
import json
import os
from typing import Any, Dict, List

from linear_client import LinearClient

# MCP protocol implementation
class MCPServer:
    def __init__(self):
        self.linear_client = None
        self.api_key = os.getenv("LINEAR_API_KEY")

        if not self.api_key:
            raise RuntimeError("LINEAR_API_KEY environment variable not set")

        self.tools = [
            {
                "name": "linear_get_plan",
                "description": "Get the current project plan from Linear with all issues and status",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "team_name": {
                            "type": "string",
                            "description": "Team name (default: Agent-Control-Plane)",
                            "default": "Agent-Control-Plane"
                        },
                        "project_name": {
                            "type": "string",
                            "description": "Project name (default: MVP 1 — PT App & Agent Pilot)",
                            "default": "MVP 1 — PT App & Agent Pilot"
                        },
                        "format": {
                            "type": "string",
                            "enum": ["json", "markdown"],
                            "description": "Output format (json or markdown)",
                            "default": "markdown"
                        }
                    }
                }
            },
            {
                "name": "linear_list_issues",
                "description": "List all issues in a project with current status",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "team_name": {
                            "type": "string",
                            "description": "Team name",
                            "default": "Agent-Control-Plane"
                        },
                        "project_name": {
                            "type": "string",
                            "description": "Project name",
                            "default": "MVP 1 — PT App & Agent Pilot"
                        }
                    }
                }
            },
            {
                "name": "linear_get_issue",
                "description": "Get detailed information about a specific issue",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "issue_id": {
                            "type": "string",
                            "description": "Linear issue ID"
                        }
                    },
                    "required": ["issue_id"]
                }
            },
            {
                "name": "linear_update_status",
                "description": "Update the status of an issue",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "issue_id": {
                            "type": "string",
                            "description": "Linear issue ID"
                        },
                        "state_id": {
                            "type": "string",
                            "description": "Workflow state ID (get from linear_get_workflow_states)"
                        }
                    },
                    "required": ["issue_id", "state_id"]
                }
            },
            {
                "name": "linear_add_comment",
                "description": "Add a comment to an issue (e.g., progress update, completion note)",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "issue_id": {
                            "type": "string",
                            "description": "Linear issue ID"
                        },
                        "comment": {
                            "type": "string",
                            "description": "Comment text (supports markdown)"
                        }
                    },
                    "required": ["issue_id", "comment"]
                }
            },
            {
                "name": "linear_get_workflow_states",
                "description": "Get available workflow states for a team (for updating issue status)",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "team_name": {
                            "type": "string",
                            "description": "Team name",
                            "default": "Agent-Control-Plane"
                        }
                    }
                }
            }
        ]

    async def handle_tool_call(self, tool_name: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Handle a tool call from Claude."""
        async with LinearClient(self.api_key) as client:
            try:
                if tool_name == "linear_get_plan":
                    team_name = parameters.get("team_name", "Agent-Control-Plane")
                    project_name = parameters.get("project_name", "MVP 1 — PT App & Agent Pilot")
                    format_type = parameters.get("format", "markdown")

                    if format_type == "markdown":
                        result = await client.export_plan_markdown(team_name, project_name)
                        return {"content": [{"type": "text", "text": result}]}
                    else:
                        result = await client.export_project_plan(team_name, project_name)
                        return {"content": [{"type": "text", "text": json.dumps(result, indent=2)}]}

                elif tool_name == "linear_list_issues":
                    team_name = parameters.get("team_name", "Agent-Control-Plane")
                    project_name = parameters.get("project_name", "MVP 1 — PT App & Agent Pilot")

                    team = await client.get_team_by_name(team_name)
                    if not team:
                        return {"content": [{"type": "text", "text": f"Team '{team_name}' not found"}], "isError": True}

                    project = await client.get_project_by_name(team["id"], project_name)
                    if not project:
                        return {"content": [{"type": "text", "text": f"Project '{project_name}' not found"}], "isError": True}

                    issues = await client.get_project_issues(project["id"])

                    result = f"# Issues in {project_name}\n\n"
                    for issue in issues:
                        labels = ", ".join([label['name'] for label in issue['labels']['nodes']])
                        result += f"**{issue['identifier']}** - {issue['title']}\n"
                        result += f"  Status: {issue['state']['name']} | Labels: {labels}\n"
                        result += f"  ID: `{issue['id']}`\n"
                        result += f"  URL: {issue['url']}\n\n"

                    return {"content": [{"type": "text", "text": result}]}

                elif tool_name == "linear_get_issue":
                    issue_id = parameters["issue_id"]
                    issue = await client.get_issue_by_id(issue_id)

                    if not issue:
                        return {"content": [{"type": "text", "text": f"Issue '{issue_id}' not found"}], "isError": True}

                    result = f"# {issue['identifier']}: {issue['title']}\n\n"
                    result += f"**Status:** {issue['state']['name']}\n"
                    result += f"**URL:** {issue['url']}\n\n"

                    if issue.get('description'):
                        result += f"## Description\n{issue['description']}\n\n"

                    labels = [label['name'] for label in issue['labels']['nodes']]
                    if labels:
                        result += f"**Labels:** {', '.join(labels)}\n\n"

                    if issue.get('assignee'):
                        result += f"**Assignee:** {issue['assignee']['name']}\n\n"

                    comments = issue['comments']['nodes']
                    if comments:
                        result += f"## Comments ({len(comments)})\n\n"
                        for comment in comments:
                            result += f"**{comment['user']['name']}** - {comment['createdAt']}\n"
                            result += f"{comment['body']}\n\n"

                    return {"content": [{"type": "text", "text": result}]}

                elif tool_name == "linear_update_status":
                    issue_id = parameters["issue_id"]
                    state_id = parameters["state_id"]

                    issue = await client.update_issue_status(issue_id, state_id)
                    result = f"✅ Updated {issue['identifier']}: {issue['title']}\nNew status: {issue['state']['name']}"
                    return {"content": [{"type": "text", "text": result}]}

                elif tool_name == "linear_add_comment":
                    issue_id = parameters["issue_id"]
                    comment_text = parameters["comment"]

                    comment = await client.add_issue_comment(issue_id, comment_text)
                    result = f"✅ Comment added at {comment['createdAt']}"
                    return {"content": [{"type": "text", "text": result}]}

                elif tool_name == "linear_get_workflow_states":
                    team_name = parameters.get("team_name", "Agent-Control-Plane")

                    team = await client.get_team_by_name(team_name)
                    if not team:
                        return {"content": [{"type": "text", "text": f"Team '{team_name}' not found"}], "isError": True}

                    states = await client.get_workflow_states(team["id"])

                    result = f"# Workflow States for {team_name}\n\n"
                    for state in states:
                        result += f"**{state['name']}** (`{state['type']}`)\n"
                        result += f"  ID: `{state['id']}`\n"
                        if state.get('description'):
                            result += f"  {state['description']}\n"
                        result += "\n"

                    return {"content": [{"type": "text", "text": result}]}

                else:
                    return {"content": [{"type": "text", "text": f"Unknown tool: {tool_name}"}], "isError": True}

            except Exception as e:
                return {"content": [{"type": "text", "text": f"Error: {str(e)}"}], "isError": True}

    def get_server_info(self) -> Dict[str, Any]:
        """Return MCP server info."""
        return {
            "name": "linear-integration",
            "version": "1.0.0",
            "description": "Linear workspace integration for Claude Code",
            "tools": self.tools
        }


async def main():
    """Run MCP server in stdio mode."""
    server = MCPServer()

    # Simple stdio protocol handler
    import sys

    print(json.dumps({"jsonrpc": "2.0", "method": "server/info", "params": server.get_server_info()}), flush=True)

    for line in sys.stdin:
        try:
            request = json.loads(line.strip())

            if request.get("method") == "tools/list":
                response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": {"tools": server.tools}
                }
                print(json.dumps(response), flush=True)

            elif request.get("method") == "tools/call":
                params = request.get("params", {})
                tool_name = params.get("name")
                tool_params = params.get("arguments", {})

                result = await server.handle_tool_call(tool_name, tool_params)

                response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "result": result
                }
                print(json.dumps(response), flush=True)

        except Exception as e:
            error_response = {
                "jsonrpc": "2.0",
                "id": request.get("id") if 'request' in locals() else None,
                "error": {"code": -32603, "message": str(e)}
            }
            print(json.dumps(error_response), flush=True)


if __name__ == "__main__":
    asyncio.run(main())
