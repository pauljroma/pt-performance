#!/usr/bin/env python3.11
"""
Component Registry MCP Server

Provides Model Context Protocol interface for component registry.
Claude can query directly without Bash tool.

Author: claude-code-agent
Date: 2025-12-02
Version: 1.0
"""

import asyncio
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

# Add migrations directory to path so we can import component_registry_resilient
MIGRATIONS_DIR = Path(__file__).parent.resolve()
if str(MIGRATIONS_DIR) not in sys.path:
    sys.path.insert(0, str(MIGRATIONS_DIR))

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# Import the resilient registry
from component_registry_resilient import ResilientComponentRegistry


# Initialize MCP server
app = Server("component-registry")
registry = ResilientComponentRegistry()


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools."""
    return [
        Tool(
            name="search_components",
            description="Search component registry for reusable components",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search term (searches component_id and component_name)",
                    },
                    "component_type": {
                        "type": "string",
                        "description": "Filter by type (service, agent, data_source, pipeline, etc.)",
                    },
                    "zone": {
                        "type": "string",
                        "description": "Filter by zone (z00_foundation, z08_data_access, etc.)",
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum results to return (default: 20)",
                        "default": 20,
                    },
                },
            },
        ),
        Tool(
            name="get_component",
            description="Get detailed information about a specific component",
            inputSchema={
                "type": "object",
                "properties": {
                    "component_id": {
                        "type": "string",
                        "description": "Component ID (e.g., 'neo4j-client-v1.0')",
                    },
                },
                "required": ["component_id"],
            },
        ),
        Tool(
            name="get_registry_stats",
            description="Get component registry statistics (total count, breakdown by type/zone)",
            inputSchema={
                "type": "object",
                "properties": {},
            },
        ),
        Tool(
            name="check_component_exists",
            description="Check if a component with similar name/functionality already exists (REUSE-FIRST principle)",
            inputSchema={
                "type": "object",
                "properties": {
                    "component_name": {
                        "type": "string",
                        "description": "Name or description of component you want to create",
                    },
                },
                "required": ["component_name"],
            },
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Handle tool calls."""

    if name == "search_components":
        # Search components
        query = arguments.get("query")
        component_type = arguments.get("component_type")
        zone = arguments.get("zone")
        limit = arguments.get("limit", 20)

        results = await registry.search(
            query=query,
            component_type=component_type,
            zone=zone,
        )

        # Limit results
        results = results[:limit]

        if not results:
            return [
                TextContent(
                    type="text",
                    text=f"No components found matching criteria.\n\nSearched:\n- Query: {query or 'any'}\n- Type: {component_type or 'any'}\n- Zone: {zone or 'any'}",
                )
            ]

        # Format results
        output = f"Found {len(results)} component(s):\n\n"
        for comp in results:
            output += f"**{comp.get('component_id')}**\n"
            output += f"  - Type: {comp.get('component_type')}\n"
            if comp.get('zone'):
                output += f"  - Zone: {comp.get('zone')}\n"
            if comp.get('file_path') and comp.get('file_path') != 'unknown':
                output += f"  - Location: {comp.get('file_path')}\n"
            if comp.get('module_path'):
                output += f"  - Import: `from {comp.get('module_path')} import ...`\n"
            output += "\n"

        return [TextContent(type="text", text=output)]

    elif name == "get_component":
        # Get specific component
        component_id = arguments.get("component_id")

        if not component_id:
            return [TextContent(type="text", text="Error: component_id is required")]

        # Search for exact match
        results = await registry.search(query=component_id)

        # Find exact match
        component = None
        for comp in results:
            if comp.get("component_id") == component_id:
                component = comp
                break

        if not component:
            return [
                TextContent(
                    type="text",
                    text=f"Component '{component_id}' not found.\n\nDid you mean one of these?\n"
                    + "\n".join([f"  - {c.get('component_id')}" for c in results[:5]]),
                )
            ]

        # Format component details
        output = f"# {component.get('component_name', component_id)}\n\n"
        output += f"**ID**: {component.get('component_id')}\n"
        output += f"**Type**: {component.get('component_type')}\n"
        output += f"**Version**: {component.get('version')}\n"
        output += f"**Lane**: {component.get('lane')}\n\n"

        if component.get('zone'):
            output += f"**Zone**: {component.get('zone')}\n"

        if component.get('file_path') and component.get('file_path') != 'unknown':
            output += f"**Location**: `{component.get('file_path')}`\n\n"

        if component.get('module_path'):
            output += f"**Import**:\n```python\nfrom {component.get('module_path')} import ...\n```\n\n"

        # Add metadata
        if component.get('deployment_status'):
            output += f"**Deployment Status**: {component.get('deployment_status')}\n"

        if component.get('test_coverage') is not None:
            coverage = component.get('test_coverage')
            if isinstance(coverage, float):
                output += f"**Test Coverage**: {coverage * 100:.0f}%\n"

        return [TextContent(type="text", text=output)]

    elif name == "get_registry_stats":
        # Get statistics
        stats = await registry.get_statistics()

        output = "# Component Registry Statistics\n\n"
        output += f"**Registry Mode**: {stats.get('mode', 'unknown')}\n"
        output += f"**Total Components**: {stats.get('total_components', 0)}\n\n"

        if stats.get('by_type'):
            output += "## By Type\n"
            for type_name, count in sorted(
                stats.get('by_type', {}).items(), key=lambda x: x[1], reverse=True
            ):
                output += f"- {type_name}: {count}\n"
            output += "\n"

        if stats.get('by_zone'):
            output += "## By Zone\n"
            for zone_name, count in sorted(
                stats.get('by_zone', {}).items(), key=lambda x: x[1], reverse=True
            )[:10]:  # Top 10 zones
                output += f"- {zone_name}: {count}\n"
            output += "\n"

        if stats.get('status') == 'degraded':
            output += "\n⚠️  **Note**: Using cached data (PostgreSQL unavailable)\n"

        return [TextContent(type="text", text=output)]

    elif name == "check_component_exists":
        # Check if similar component exists (REUSE-FIRST)
        component_name = arguments.get("component_name", "")

        # Extract keywords from component name
        keywords = component_name.lower().split()

        # Search for each keyword
        all_results = []
        for keyword in keywords:
            if len(keyword) > 3:  # Skip short words
                results = await registry.search(query=keyword)
                all_results.extend(results)

        # Deduplicate
        seen = set()
        unique_results = []
        for comp in all_results:
            comp_id = comp.get('component_id')
            if comp_id not in seen:
                seen.add(comp_id)
                unique_results.append(comp)

        if not unique_results:
            return [
                TextContent(
                    type="text",
                    text=f"✅ No similar components found for '{component_name}'.\n\nYou may proceed with creating this component.\n\nRemember to:\n- Create as library/service (not script)\n- Add to appropriate zone\n- Register in component registry after creation",
                )
            ]

        # Found similar components - potential reuse
        output = f"⚠️  **REUSE CHECK**: Found {len(unique_results)} potentially similar component(s) for '{component_name}':\n\n"

        for i, comp in enumerate(unique_results[:10], 1):  # Top 10
            output += f"{i}. **{comp.get('component_id')}**\n"
            output += f"   - Type: {comp.get('component_type')}\n"
            if comp.get('file_path') and comp.get('file_path') != 'unknown':
                output += f"   - Location: {comp.get('file_path')}\n"
            output += "\n"

        output += "\n**Action Required**:\n"
        output += "1. Review these existing components\n"
        output += "2. Check if any can be reused (≥70% similarity)\n"
        output += "3. If reusable → use existing component\n"
        output += "4. If not reusable → document why and create new component\n"

        return [TextContent(type="text", text=output)]

    else:
        return [TextContent(type="text", text=f"Unknown tool: {name}")]


async def main():
    """Run MCP server."""
    # Initialize registry
    await registry.initialize()

    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
