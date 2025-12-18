#!/usr/bin/env python3.11
"""
Documentation Control MCP Server

Prevents documentation sprawl by enforcing NO_MARKDOWN_FILES policy.
Blocks README/HANDOFF/PLAN files outside allowed locations.

This server implements the anti-sprawl policy requested by the user:
"stop garbage Readme, plans, .md, handoff being put all over the workspace"

Author: claude-code-agent
Date: 2025-12-03
Version: 1.0
"""

import json
import asyncio
from pathlib import Path
from typing import List, Dict, Optional
import fnmatch

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent


class DocumentationControlMCP:
    """MCP server for documentation sprawl prevention."""

    def __init__(self):
        self.app = Server("documentation-control")

        # Load policy configuration
        self.config_path = Path(__file__).parent / "ALLOWED_DOCUMENTATION.json"
        self.config = self._load_config()

        # Metrics
        self.metrics = {
            'checks_performed': 0,
            'violations_blocked': 0,
            'documents_registered': 0,
            'documents_archived': 0
        }

        self._register_handlers()

    def _load_config(self) -> dict:
        """Load documentation policy configuration."""
        try:
            with open(self.config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            # Return default config
            return {
                "allowed_locations": {
                    ".outcomes/": {"purpose": "Outcomes"},
                    ".swarms/": {"purpose": "Swarms"},
                    "docs/": {"purpose": "Official docs"}
                },
                "blocked_patterns": {},
                "whitelist": {},
                "registered_documents": []
            }

    def _save_config(self):
        """Save configuration changes."""
        with open(self.config_path, 'w') as f:
            json.dump(self.config, f, indent=2)

    def _register_handlers(self):
        """Register MCP handlers."""

        @self.app.list_tools()
        async def list_tools() -> list[Tool]:
            return [
                Tool(
                    name="check_documentation_allowed",
                    description="Check if creating a documentation file is allowed (CALL BEFORE CREATING .md FILES)",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "filename": {
                                "type": "string",
                                "description": "Documentation filename (e.g., 'README.md', 'HANDOFF.md')"
                            },
                            "location": {
                                "type": "string",
                                "description": "Intended location path (e.g., '.outcomes/', 'workspace_root/')"
                            }
                        },
                        "required": ["filename", "location"]
                    }
                ),
                Tool(
                    name="register_documentation",
                    description="Register a newly created documentation file",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "filename": {
                                "type": "string",
                                "description": "Documentation filename"
                            },
                            "location": {
                                "type": "string",
                                "description": "File location"
                            },
                            "purpose": {
                                "type": "string",
                                "description": "Purpose of this document"
                            }
                        },
                        "required": ["filename", "location", "purpose"]
                    }
                ),
                Tool(
                    name="list_documentation",
                    description="List registered documentation files by type",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "doc_type": {
                                "type": "string",
                                "description": "Filter by type (README, HANDOFF, GUIDE, etc.)",
                                "default": None
                            }
                        }
                    }
                ),
                Tool(
                    name="archive_documentation",
                    description="Archive outdated documentation file",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "filename": {
                                "type": "string",
                                "description": "Filename to archive"
                            },
                            "location": {
                                "type": "string",
                                "description": "Current location"
                            },
                            "reason": {
                                "type": "string",
                                "description": "Reason for archiving"
                            }
                        },
                        "required": ["filename", "location", "reason"]
                    }
                )
            ]

        @self.app.call_tool()
        async def call_tool(name: str, arguments: dict) -> list[TextContent]:
            try:
                if name == "check_documentation_allowed":
                    return await self._check_allowed(arguments)
                elif name == "register_documentation":
                    return await self._register_doc(arguments)
                elif name == "list_documentation":
                    return await self._list_docs(arguments)
                elif name == "archive_documentation":
                    return await self._archive_doc(arguments)
                else:
                    return [TextContent(type="text", text=f"❌ Unknown tool: {name}")]
            except Exception as e:
                return [TextContent(type="text", text=f"❌ Error: {str(e)}")]

    # ========================================================================
    # TOOL IMPLEMENTATIONS
    # ========================================================================

    async def _check_allowed(self, args: dict) -> list[TextContent]:
        """Check if documentation creation is allowed."""
        filename = args.get("filename", "")
        location = args.get("location", "")

        self.metrics['checks_performed'] += 1

        # Normalize location
        location = location.rstrip('/')
        if not location or location == '.':
            location = 'workspace_root'

        full_path = f"{location}/{filename}"

        # Check if whitelisted
        if self._is_whitelisted(full_path):
            return [TextContent(
                type="text",
                text=f"✅ **ALLOWED**: '{filename}' in '{location}'\n\n"
                     f"**Reason**: Whitelisted location\n\n"
                     f"You may create this file."
            )]

        # Check if location is allowed
        if not self._is_location_allowed(location):
            self.metrics['violations_blocked'] += 1

            # Find suggested location
            suggested_location = self._suggest_location(filename)

            return [TextContent(
                type="text",
                text=f"❌ **BLOCKED**: '{filename}' not allowed in '{location}'\n\n"
                     f"**Reason**: Documentation sprawl prevention\n\n"
                     f"**Policy**: NO_MARKDOWN_FILES outside designated areas\n\n"
                     f"**Suggested Location**: {suggested_location}\n\n"
                     f"**Allowed Locations**:\n"
                     + self._format_allowed_locations()
            )]

        # Check blocked patterns
        violation = self._check_blocked_patterns(filename, location)
        if violation:
            self.metrics['violations_blocked'] += 1
            return [TextContent(
                type="text",
                text=f"❌ **BLOCKED**: '{filename}' matches blocked pattern\n\n"
                     f"**Pattern**: {violation['pattern']}\n"
                     f"**Reason**: {violation['reason']}\n\n"
                     f"**Redirect To**: {violation['redirect_to']}\n\n"
                     f"**Examples of allowed files**:\n"
                     + self._format_pattern_examples(violation['redirect_to'])
            )]

        # Allowed
        return [TextContent(
            type="text",
            text=f"✅ **ALLOWED**: '{filename}' in '{location}'\n\n"
                 f"**Location Purpose**: {self._get_location_purpose(location)}\n\n"
                 f"Remember to register this document after creation using `register_documentation`."
        )]

    async def _register_doc(self, args: dict) -> list[TextContent]:
        """Register a documentation file."""
        filename = args.get("filename", "")
        location = args.get("location", "")
        purpose = args.get("purpose", "")

        # Check if already registered
        for doc in self.config.get('registered_documents', []):
            if doc['filename'] == filename and doc['location'] == location:
                return [TextContent(
                    type="text",
                    text=f"⚠️  '{filename}' already registered at '{location}'"
                )]

        # Register
        if 'registered_documents' not in self.config:
            self.config['registered_documents'] = []

        self.config['registered_documents'].append({
            'filename': filename,
            'location': location,
            'purpose': purpose,
            'status': 'active',
            'registered_at': '2025-12-03T06:00:00Z'
        })

        self._save_config()
        self.metrics['documents_registered'] += 1

        return [TextContent(
            type="text",
            text=f"✅ Registered '{filename}' at '{location}'\n\n"
                 f"**Purpose**: {purpose}\n"
                 f"**Status**: Active\n\n"
                 f"Total registered documents: {len(self.config['registered_documents'])}"
        )]

    async def _list_docs(self, args: dict) -> list[TextContent]:
        """List registered documentation."""
        doc_type = args.get("doc_type")

        docs = self.config.get('registered_documents', [])

        # Filter by type if specified
        if doc_type:
            docs = [d for d in docs if doc_type.upper() in d['filename'].upper()]

        if not docs:
            return [TextContent(
                type="text",
                text=f"No documentation files registered"
                     + (f" for type '{doc_type}'" if doc_type else "")
            )]

        # Format output
        output = f"# Registered Documentation"
        if doc_type:
            output += f" (Type: {doc_type})"
        output += f"\n\n**Total**: {len(docs)}\n\n"

        # Group by location
        by_location = {}
        for doc in docs:
            loc = doc['location']
            if loc not in by_location:
                by_location[loc] = []
            by_location[loc].append(doc)

        for location, location_docs in sorted(by_location.items()):
            output += f"## {location}\n"
            for doc in location_docs:
                output += f"- **{doc['filename']}**"
                if doc.get('purpose'):
                    output += f" - {doc['purpose']}"
                if doc.get('status') != 'active':
                    output += f" ({doc['status']})"
                output += "\n"
            output += "\n"

        return [TextContent(type="text", text=output)]

    async def _archive_doc(self, args: dict) -> list[TextContent]:
        """Archive a documentation file."""
        filename = args.get("filename", "")
        location = args.get("location", "")
        reason = args.get("reason", "")

        # Find document
        docs = self.config.get('registered_documents', [])
        found = False

        for doc in docs:
            if doc['filename'] == filename and doc['location'] == location:
                doc['status'] = 'archived'
                doc['archived_reason'] = reason
                doc['archived_at'] = '2025-12-03T06:00:00Z'
                found = True
                break

        if not found:
            return [TextContent(
                type="text",
                text=f"❌ Document '{filename}' at '{location}' not found in registry"
            )]

        self._save_config()
        self.metrics['documents_archived'] += 1

        return [TextContent(
            type="text",
            text=f"✅ Archived '{filename}' at '{location}'\n\n"
                 f"**Reason**: {reason}\n\n"
                 f"The document is now marked as archived in the registry."
        )]

    # ========================================================================
    # VALIDATION HELPERS
    # ========================================================================

    def _is_whitelisted(self, path: str) -> bool:
        """Check if path is whitelisted."""
        whitelist = self.config.get('whitelist', {})

        # Check project root files
        if '/' not in path or path.startswith('workspace_root/'):
            filename = path.split('/')[-1]
            root_files = whitelist.get('project_root', {}).get('allowed_files', [])
            if filename in root_files:
                return True

        # Check pattern matches
        for category, config in whitelist.items():
            patterns = config.get('allowed_patterns', [])
            for pattern in patterns:
                if fnmatch.fnmatch(path, pattern):
                    return True

        return False

    def _is_location_allowed(self, location: str) -> bool:
        """Check if location is in allowed list."""
        if location == 'workspace_root':
            return False  # Workspace root not allowed (except whitelisted files)

        allowed_locations = self.config.get('allowed_locations', {})

        for allowed_loc in allowed_locations.keys():
            if location.startswith(allowed_loc.rstrip('/')):
                return True

        return False

    def _check_blocked_patterns(self, filename: str, location: str) -> Optional[Dict]:
        """Check if file matches blocked pattern."""
        blocked = self.config.get('blocked_patterns', {})
        full_path = f"{location}/{filename}"

        for pattern_name, pattern_config in blocked.items():
            pattern = pattern_config['pattern']

            # Check if matches pattern
            if fnmatch.fnmatch(full_path, pattern) or fnmatch.fnmatch(filename, pattern):
                # Check exceptions
                exceptions = pattern_config.get('exceptions', [])
                is_exception = any(fnmatch.fnmatch(full_path, exc) for exc in exceptions)

                if not is_exception:
                    return pattern_config

        return None

    def _suggest_location(self, filename: str) -> str:
        """Suggest appropriate location for filename."""
        filename_upper = filename.upper()

        if 'HANDOFF' in filename_upper:
            return ".handoffs/"
        elif 'PLAN' in filename_upper or 'SWARM' in filename_upper:
            return ".swarms/"
        elif 'OUTCOME' in filename_upper or 'RESULT' in filename_upper:
            return ".outcomes/"
        elif 'GUIDE' in filename_upper or 'TUTORIAL' in filename_upper:
            return "docs/"
        elif 'README' in filename_upper:
            return "docs/ (or project root if main README)"
        else:
            return "docs/ (for general documentation)"

    def _format_allowed_locations(self) -> str:
        """Format allowed locations for display."""
        locations = self.config.get('allowed_locations', {})
        output = ""

        for loc, config in sorted(locations.items()):
            output += f"- **{loc}**: {config.get('purpose', 'N/A')}\n"

        return output

    def _format_pattern_examples(self, location: str) -> str:
        """Format example filenames for a location."""
        examples = {
            ".outcomes/": [
                ".outcomes/my_task_outcome_20251203.json",
                ".outcomes/my_task_summary.md"
            ],
            ".swarms/": [
                ".swarms/my_swarm_plan_v1.yaml",
                ".swarms/my_swarm_manifest.md"
            ],
            ".handoffs/": [
                ".handoffs/HANDOFF-20251203-session.json",
                ".handoffs/HANDOFF-project-complete.md"
            ],
            "docs/": [
                "docs/guides/my_guide.md",
                "docs/api/my_api_reference.md"
            ]
        }

        location_examples = examples.get(location, [])
        if not location_examples:
            return f"{location}your_document.md"

        return "\n".join(f"  - {ex}" for ex in location_examples)

    def _get_location_purpose(self, location: str) -> str:
        """Get purpose description for a location."""
        locations = self.config.get('allowed_locations', {})

        for loc, config in locations.items():
            if location.startswith(loc.rstrip('/')):
                return config.get('purpose', 'Unknown')

        return "Unknown"

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
    """Run documentation control MCP server."""
    server = DocumentationControlMCP()
    await server.run()


if __name__ == "__main__":
    asyncio.run(main())
