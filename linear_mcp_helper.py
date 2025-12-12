#!/usr/bin/env python3
"""
Linear MCP Helper - Easy compression for existing scripts

Provides simple wrapper functions for Linear MCP server with automatic compression.
Use this in place of direct GraphQL API calls to enable compression.

Author: claude-code-agent
Date: 2025-12-07
Version: 1.0
"""

import asyncio
import os
from typing import Optional, Dict, Any
from mcp_server import MCPServer


class LinearMCPHelper:
    """
    Helper class for using Linear MCP with compression.

    Simplifies migration from direct GraphQL API calls to compressed MCP calls.
    """

    def __init__(self):
        """Initialize MCP server."""
        self.server = MCPServer()

    async def add_comment_compressed(
        self,
        issue_id: str,
        comment: str,
        compression_level: str = "balanced",
        auto_compress: bool = True
    ) -> Dict[str, Any]:
        """
        Add comment to Linear issue with automatic compression for large content.

        Args:
            issue_id: Linear issue ID (e.g., "ACP-123")
            comment: Comment text (supports markdown)
            compression_level: fast/balanced/aggressive (default: balanced)
            auto_compress: Auto-enable compression for content >10KB (default: True)

        Returns:
            Result dict from MCP server

        Example:
            helper = LinearMCPHelper()
            await helper.add_comment_compressed(
                "ACP-123",
                large_handoff_report
            )
        """
        # Auto-detect if compression should be used
        compress = auto_compress and len(comment) > 10240  # >10KB

        result = await self.server.handle_tool_call("linear_add_comment", {
            "issue_id": issue_id,
            "comment": comment,
            "compress": compress,
            "compression_level": compression_level
        })

        return result

    async def get_plan_compressed(
        self,
        team_name: str = "Agent-Control-Plane",
        project_name: str = "MVP 1 — PT App & Agent Pilot",
        format_type: str = "markdown",
        compression_level: str = "fast"
    ) -> str:
        """
        Get project plan with compression.

        Args:
            team_name: Linear team name
            project_name: Linear project name
            format_type: json or markdown
            compression_level: fast/balanced/aggressive

        Returns:
            Compressed plan text
        """
        result = await self.server.handle_tool_call("linear_get_plan", {
            "team_name": team_name,
            "project_name": project_name,
            "format": format_type,
            "compress": True,
            "compression_level": compression_level
        })

        return result["content"][0]["text"]

    async def get_issue_compressed(
        self,
        issue_id: str,
        compression_level: str = "fast"
    ) -> str:
        """
        Get issue details with compression.

        Args:
            issue_id: Linear issue ID
            compression_level: fast/balanced/aggressive

        Returns:
            Compressed issue text
        """
        result = await self.server.handle_tool_call("linear_get_issue", {
            "issue_id": issue_id,
            "compress": True,
            "compression_level": compression_level
        })

        return result["content"][0]["text"]


# ============================================================================
# Synchronous Wrapper Functions (for easy migration)
# ============================================================================

def add_comment_sync(
    issue_id: str,
    comment: str,
    compression_level: str = "balanced",
    auto_compress: bool = True
) -> Dict[str, Any]:
    """
    Synchronous wrapper for add_comment_compressed.

    Use this as drop-in replacement for direct GraphQL calls.

    Example:
        # Old code:
        # response = requests.post(LINEAR_API_URL, json={...})

        # New code:
        from linear_mcp_helper import add_comment_sync
        result = add_comment_sync("ACP-123", large_comment)
        print(result["content"][0]["text"])
    """
    helper = LinearMCPHelper()
    return asyncio.run(helper.add_comment_compressed(
        issue_id,
        comment,
        compression_level,
        auto_compress
    ))


def get_plan_sync(
    team_name: str = "Agent-Control-Plane",
    project_name: str = "MVP 1 — PT App & Agent Pilot",
    format_type: str = "markdown",
    compression_level: str = "fast"
) -> str:
    """
    Synchronous wrapper for get_plan_compressed.

    Example:
        from linear_mcp_helper import get_plan_sync
        plan = get_plan_sync("My Team", "My Project")
        print(plan)
    """
    helper = LinearMCPHelper()
    return asyncio.run(helper.get_plan_compressed(
        team_name,
        project_name,
        format_type,
        compression_level
    ))


def get_issue_sync(
    issue_id: str,
    compression_level: str = "fast"
) -> str:
    """
    Synchronous wrapper for get_issue_compressed.

    Example:
        from linear_mcp_helper import get_issue_sync
        issue = get_issue_sync("ACP-123")
        print(issue)
    """
    helper = LinearMCPHelper()
    return asyncio.run(helper.get_issue_compressed(
        issue_id,
        compression_level
    ))


# ============================================================================
# Quick Test
# ============================================================================

if __name__ == "__main__":
    """Test the helper functions."""
    import sys

    # Check environment
    if not os.getenv("LINEAR_API_KEY"):
        print("❌ LINEAR_API_KEY not set")
        sys.exit(1)

    print("=" * 70)
    print("Linear MCP Helper - Test")
    print("=" * 70)

    # Test with small comment (no compression)
    print("\n1. Testing small comment (no auto-compression)...")
    result = add_comment_sync(
        "TEST-123",
        "Small test comment from MCP helper"
    )
    print(f"✅ Result: {result['content'][0]['text']}")

    # Test with large comment (auto-compression)
    print("\n2. Testing large comment (auto-compression)...")
    large_comment = "# Large Test Comment\n\n" + ("This is test content. " * 1000)
    result = add_comment_sync(
        "TEST-123",
        large_comment
    )
    print(f"✅ Result: {result['content'][0]['text']}")

    print("\n" + "=" * 70)
    print("Tests complete! ✅")
    print("=" * 70)
