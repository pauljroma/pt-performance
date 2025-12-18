#!/usr/bin/env python3.11
"""
Git Operations MCP Server

Provides structured git operations with safety checks and validation.
Prevents dangerous operations, validates commit messages, enforces branch naming.

Author: claude-code-agent
Date: 2025-12-03
Version: 1.0
"""

import asyncio
import re
import subprocess
from typing import List, Optional
from pathlib import Path

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent


class GitOperationsMCP:
    """MCP server for safe git operations."""

    def __init__(self):
        self.app = Server("git-operations")
        self.metrics = {
            'commits_created': 0,
            'prs_created': 0,
            'branches_created': 0,
            'dangerous_ops_blocked': 0
        }

        # Safety configuration
        self.protected_branches = ['main', 'master', 'production']
        self.required_co_authors = ['Claude <noreply@anthropic.com>']

        self._register_handlers()

    def _register_handlers(self):
        """Register MCP handlers."""

        @self.app.list_tools()
        async def list_tools() -> list[Tool]:
            return [
                Tool(
                    name="create_commit",
                    description="Create a git commit with proper formatting and co-authorship",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "message": {
                                "type": "string",
                                "description": "Commit message (will add Claude co-author)"
                            },
                            "files": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "Files to stage (optional, default: all changes)"
                            },
                            "skip_hooks": {
                                "type": "boolean",
                                "description": "Skip pre-commit hooks (NOT RECOMMENDED)",
                                "default": False
                            }
                        },
                        "required": ["message"]
                    }
                ),
                Tool(
                    name="create_pr",
                    description="Create a pull request with proper format",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "title": {
                                "type": "string",
                                "description": "PR title"
                            },
                            "body": {
                                "type": "string",
                                "description": "PR body (markdown)"
                            },
                            "base": {
                                "type": "string",
                                "description": "Base branch (default: main)",
                                "default": "main"
                            }
                        },
                        "required": ["title", "body"]
                    }
                ),
                Tool(
                    name="create_branch",
                    description="Create a new branch with proper naming",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "name": {
                                "type": "string",
                                "description": "Branch name (kebab-case recommended)"
                            },
                            "from_branch": {
                                "type": "string",
                                "description": "Branch to create from (default: current)",
                                "default": None
                            }
                        },
                        "required": ["name"]
                    }
                ),
                Tool(
                    name="get_status",
                    description="Get current git status",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "include_untracked": {
                                "type": "boolean",
                                "description": "Include untracked files",
                                "default": True
                            }
                        }
                    }
                ),
                Tool(
                    name="get_diff",
                    description="Get git diff for staged or unstaged changes",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "staged": {
                                "type": "boolean",
                                "description": "Show staged changes (default: False = unstaged)",
                                "default": False
                            },
                            "files": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "Specific files to diff (optional)"
                            }
                        }
                    }
                )
            ]

        @self.app.call_tool()
        async def call_tool(name: str, arguments: dict) -> list[TextContent]:
            try:
                if name == "create_commit":
                    return await self._create_commit(arguments)
                elif name == "create_pr":
                    return await self._create_pr(arguments)
                elif name == "create_branch":
                    return await self._create_branch(arguments)
                elif name == "get_status":
                    return await self._get_status(arguments)
                elif name == "get_diff":
                    return await self._get_diff(arguments)
                else:
                    return [TextContent(type="text", text=f"❌ Unknown tool: {name}")]
            except Exception as e:
                return [TextContent(type="text", text=f"❌ Error: {str(e)}")]

    # ========================================================================
    # TOOL IMPLEMENTATIONS
    # ========================================================================

    async def _create_commit(self, args: dict) -> list[TextContent]:
        """Create a commit with proper formatting."""
        message = args.get("message", "")
        files = args.get("files", [])
        skip_hooks = args.get("skip_hooks", False)

        # Validate commit message
        validation_error = self._validate_commit_message(message)
        if validation_error:
            return [TextContent(type="text", text=f"❌ {validation_error}")]

        # Check if we're on a protected branch
        current_branch = self._run_git_command("git branch --show-current")
        if current_branch in self.protected_branches:
            self.metrics['dangerous_ops_blocked'] += 1
            return [TextContent(
                type="text",
                text=f"❌ Cannot commit directly to protected branch '{current_branch}'\n\n"
                     f"Please create a feature branch:\n"
                     f"  git checkout -b feature/your-feature"
            )]

        # Stage files
        if files:
            for file in files:
                try:
                    self._run_git_command(f"git add \"{file}\"")
                except Exception as e:
                    return [TextContent(type="text", text=f"❌ Failed to stage {file}: {str(e)}")]
        else:
            # Stage all changes
            self._run_git_command("git add .")

        # Build commit message with co-author
        full_message = self._format_commit_message(message)

        # Create commit
        try:
            hook_flag = "--no-verify" if skip_hooks else ""
            self._run_git_command(f"git commit {hook_flag} -m \"$(cat <<'EOF'\n{full_message}\nEOF\n)\"")
            self.metrics['commits_created'] += 1

            # Get commit hash
            commit_hash = self._run_git_command("git rev-parse HEAD")

            return [TextContent(
                type="text",
                text=f"✅ Commit created successfully!\n\n"
                     f"**Commit**: {commit_hash[:8]}\n"
                     f"**Branch**: {current_branch}\n"
                     f"**Message**: {message}\n\n"
                     f"🤖 Co-authored by Claude\n\n"
                     f"Next steps:\n"
                     f"- Push to remote: `git push`\n"
                     f"- Create PR: Use `create_pr` tool"
            )]
        except Exception as e:
            return [TextContent(type="text", text=f"❌ Commit failed: {str(e)}")]

    async def _create_pr(self, args: dict) -> list[TextContent]:
        """Create a pull request."""
        title = args.get("title", "")
        body = args.get("body", "")
        base = args.get("base", "main")

        # Check if gh CLI is available
        try:
            self._run_git_command("gh --version")
        except:
            return [TextContent(
                type="text",
                text="❌ GitHub CLI (gh) not installed\n\n"
                     "Install: `brew install gh`\n"
                     "Authenticate: `gh auth login`"
            )]

        # Get current branch
        current_branch = self._run_git_command("git branch --show-current")

        # Check if branch is pushed
        try:
            self._run_git_command(f"git rev-parse origin/{current_branch}")
        except:
            return [TextContent(
                type="text",
                text=f"❌ Branch '{current_branch}' not pushed to remote\n\n"
                     f"Push first: `git push -u origin {current_branch}`"
            )]

        # Format PR body with Claude attribution
        pr_body = body + "\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)"

        # Create PR
        try:
            result = self._run_git_command(
                f"gh pr create --title \"{title}\" --body \"$(cat <<'EOF'\n{pr_body}\nEOF\n)\" --base {base}"
            )
            self.metrics['prs_created'] += 1

            # Extract PR URL from result
            pr_url = result.split('\n')[0] if result else "PR created"

            return [TextContent(
                type="text",
                text=f"✅ Pull request created successfully!\n\n"
                     f"**Title**: {title}\n"
                     f"**Branch**: {current_branch} → {base}\n"
                     f"**URL**: {pr_url}\n\n"
                     f"🤖 Attributed to Claude Code"
            )]
        except Exception as e:
            return [TextContent(type="text", text=f"❌ PR creation failed: {str(e)}")]

    async def _create_branch(self, args: dict) -> list[TextContent]:
        """Create a new branch."""
        name = args.get("name", "")
        from_branch = args.get("from_branch")

        # Validate branch name
        validation_error = self._validate_branch_name(name)
        if validation_error:
            return [TextContent(type="text", text=f"❌ {validation_error}")]

        # Check if branch exists
        try:
            self._run_git_command(f"git rev-parse --verify {name}")
            return [TextContent(type="text", text=f"❌ Branch '{name}' already exists")]
        except:
            pass  # Branch doesn't exist, good

        # Create branch
        try:
            if from_branch:
                self._run_git_command(f"git checkout -b {name} {from_branch}")
            else:
                self._run_git_command(f"git checkout -b {name}")

            self.metrics['branches_created'] += 1

            return [TextContent(
                type="text",
                text=f"✅ Branch '{name}' created successfully!\n\n"
                     f"**Branch**: {name}\n"
                     f"**From**: {from_branch or 'current branch'}\n\n"
                     f"Next steps:\n"
                     f"- Make changes\n"
                     f"- Commit: Use `create_commit` tool\n"
                     f"- Push: `git push -u origin {name}`"
            )]
        except Exception as e:
            return [TextContent(type="text", text=f"❌ Branch creation failed: {str(e)}")]

    async def _get_status(self, args: dict) -> list[TextContent]:
        """Get git status."""
        include_untracked = args.get("include_untracked", True)

        try:
            # Get status
            status = self._run_git_command("git status --porcelain")
            branch = self._run_git_command("git branch --show-current")

            if not status:
                return [TextContent(
                    type="text",
                    text=f"✅ Working tree clean\n\n**Branch**: {branch}"
                )]

            # Parse status
            modified = []
            staged = []
            untracked = []

            for line in status.split('\n'):
                if not line:
                    continue

                status_code = line[:2]
                file_path = line[3:]

                if status_code == "??":
                    if include_untracked:
                        untracked.append(file_path)
                elif status_code[0] != " ":
                    staged.append(file_path)
                else:
                    modified.append(file_path)

            # Format output
            output = f"# Git Status\n\n**Branch**: {branch}\n\n"

            if staged:
                output += "## Staged Changes\n"
                for f in staged[:10]:
                    output += f"- {f}\n"
                if len(staged) > 10:
                    output += f"- ...and {len(staged) - 10} more\n"
                output += "\n"

            if modified:
                output += "## Modified (Unstaged)\n"
                for f in modified[:10]:
                    output += f"- {f}\n"
                if len(modified) > 10:
                    output += f"- ...and {len(modified) - 10} more\n"
                output += "\n"

            if untracked and include_untracked:
                output += "## Untracked Files\n"
                for f in untracked[:10]:
                    output += f"- {f}\n"
                if len(untracked) > 10:
                    output += f"- ...and {len(untracked) - 10} more\n"

            return [TextContent(type="text", text=output)]

        except Exception as e:
            return [TextContent(type="text", text=f"❌ Failed to get status: {str(e)}")]

    async def _get_diff(self, args: dict) -> list[TextContent]:
        """Get git diff."""
        staged = args.get("staged", False)
        files = args.get("files", [])

        try:
            # Build command
            cmd = "git diff"
            if staged:
                cmd += " --cached"

            if files:
                cmd += " -- " + " ".join(f'"{f}"' for f in files)

            # Get diff
            diff = self._run_git_command(cmd)

            if not diff:
                return [TextContent(
                    type="text",
                    text=f"No {'staged' if staged else 'unstaged'} changes"
                )]

            # Truncate if too long
            max_lines = 100
            diff_lines = diff.split('\n')
            if len(diff_lines) > max_lines:
                diff = '\n'.join(diff_lines[:max_lines])
                diff += f"\n\n... (truncated, {len(diff_lines) - max_lines} more lines)"

            output = f"# Git Diff ({'Staged' if staged else 'Unstaged'})\n\n"
            output += f"```diff\n{diff}\n```"

            return [TextContent(type="text", text=output)]

        except Exception as e:
            return [TextContent(type="text", text=f"❌ Failed to get diff: {str(e)}")]

    # ========================================================================
    # VALIDATION HELPERS
    # ========================================================================

    def _validate_commit_message(self, message: str) -> Optional[str]:
        """Validate commit message format."""
        if not message or len(message.strip()) < 3:
            return "Commit message too short (minimum 3 characters)"

        if len(message) > 500:
            return "Commit message too long (maximum 500 characters)"

        # Check for common mistakes
        if message.strip().endswith('.'):
            return "Commit message should not end with a period"

        # Encourage conventional commits
        conventional_prefixes = ['feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore']
        if not any(message.lower().startswith(f"{prefix}:") or message.lower().startswith(f"{prefix}(") for prefix in conventional_prefixes):
            # Warning, not error
            pass

        return None

    def _validate_branch_name(self, name: str) -> Optional[str]:
        """Validate branch name."""
        if not name or len(name) < 3:
            return "Branch name too short (minimum 3 characters)"

        if len(name) > 100:
            return "Branch name too long (maximum 100 characters)"

        # Check format
        if not re.match(r'^[a-z0-9._/-]+$', name):
            return "Branch name must be lowercase alphanumeric with dashes, dots, underscores, or slashes"

        # Check for protected names
        if name in self.protected_branches:
            return f"Cannot create branch with protected name '{name}'"

        return None

    def _format_commit_message(self, message: str) -> str:
        """Format commit message with co-author."""
        formatted = message.strip()

        # Add Claude attribution
        formatted += "\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)"

        # Add co-author
        for author in self.required_co_authors:
            formatted += f"\n\nCo-Authored-By: {author}"

        return formatted

    def _run_git_command(self, command: str) -> str:
        """Run a git command and return output."""
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode != 0:
            raise Exception(result.stderr.strip() or result.stdout.strip())

        return result.stdout.strip()

    # ========================================================================
    # SERVER LIFECYCLE
    # ========================================================================

    async def run(self):
        """Run the MCP server."""
        async with stdio_server() as (read_stream, write_stream):
            await self.app.run(
                read_stream,
                write_stream,
                self.app.create_initialization_options()
            )


# ============================================================================
# MAIN
# ============================================================================

async def main():
    """Run git operations MCP server."""
    server = GitOperationsMCP()
    await server.run()


if __name__ == "__main__":
    asyncio.run(main())
