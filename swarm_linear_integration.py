#!/usr/bin/env python3
"""
Swarm Agent - Linear Compression Integration

Enables swarm agents to post compressed handoffs to Linear automatically.

Features:
- Automatic handoff compression for agent-to-agent communication
- Preload generation for session continuation
- Linear issue tracking integration
- Metrics and monitoring

Author: claude-code-agent
Date: 2025-12-07
Version: 1.0
"""

import asyncio
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

# Add paths
sys.path.insert(0, str(Path(__file__).parent))

from linear_mcp_helper import LinearMCPHelper, add_comment_sync
from linear_compression import get_compression_metrics


class SwarmLinearIntegration:
    """
    Integration layer between swarm agents and Linear with compression.

    Automatically compresses and posts agent handoffs to Linear issues.
    """

    def __init__(self, team_name: str = "Agent-Control-Plane"):
        """
        Initialize swarm-Linear integration.

        Args:
            team_name: Linear team name for issue tracking
        """
        self.team_name = team_name
        self.mcp = LinearMCPHelper()

    async def post_agent_handoff(
        self,
        agent_id: str,
        issue_id: str,
        handoff_data: Dict[str, Any],
        compression_level: str = "balanced"
    ) -> Dict[str, Any]:
        """
        Post agent handoff to Linear with compression.

        Args:
            agent_id: Agent identifier (e.g., "agent1_bbb_coverage")
            issue_id: Linear issue ID for tracking
            handoff_data: Handoff data from agent
            compression_level: Compression level (default: balanced)

        Returns:
            Result from Linear MCP

        Example:
            integration = SwarmLinearIntegration()
            await integration.post_agent_handoff(
                "agent1_bbb_coverage",
                "ACP-200",
                {
                    "status": "complete",
                    "tasks_completed": [...],
                    "files_modified": [...],
                    "metrics": {...}
                }
            )
        """
        # Format handoff as markdown
        handoff_markdown = self._format_handoff(agent_id, handoff_data)

        # Post with compression
        result = await self.mcp.add_comment_compressed(
            issue_id=issue_id,
            comment=handoff_markdown,
            compression_level=compression_level,
            auto_compress=True  # Auto-compress if >10KB
        )

        return result

    async def post_swarm_completion(
        self,
        swarm_name: str,
        issue_id: str,
        agents_results: List[Dict[str, Any]],
        compression_level: str = "aggressive"
    ) -> Dict[str, Any]:
        """
        Post complete swarm results to Linear with aggressive compression.

        Args:
            swarm_name: Swarm identifier
            issue_id: Linear issue ID
            agents_results: List of agent results
            compression_level: Compression level (default: aggressive for large swarms)

        Returns:
            Result from Linear MCP
        """
        # Format swarm completion report
        completion_markdown = self._format_swarm_completion(swarm_name, agents_results)

        # Post with aggressive compression (swarm reports can be 50-100KB)
        result = await self.mcp.add_comment_compressed(
            issue_id=issue_id,
            comment=completion_markdown,
            compression_level=compression_level,
            auto_compress=True
        )

        return result

    async def create_handoff_issue(
        self,
        agent_id: str,
        handoff_data: Dict[str, Any],
        next_agent_id: Optional[str] = None
    ) -> str:
        """
        Create Linear issue for agent handoff tracking.

        Args:
            agent_id: Current agent ID
            handoff_data: Handoff data
            next_agent_id: Next agent ID (if known)

        Returns:
            Linear issue ID

        Note:
            This requires linear_client to create issues.
            For now, returns placeholder. Extend as needed.
        """
        # TODO: Implement issue creation via MCP
        # For now, handoffs go to existing tracking issues
        raise NotImplementedError("Issue creation via MCP not yet implemented")

    def _format_handoff(self, agent_id: str, handoff_data: Dict[str, Any]) -> str:
        """Format agent handoff as markdown."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M UTC")

        md = f"""# 🤖 Agent Handoff: {agent_id}

**Timestamp**: {timestamp}
**Agent**: {agent_id}
**Status**: {handoff_data.get('status', 'unknown')}

---

## 📋 Tasks Completed

"""

        # Add completed tasks
        tasks = handoff_data.get('tasks_completed', [])
        if tasks:
            for task in tasks:
                md += f"- ✅ {task}\n"
        else:
            md += "*No tasks listed*\n"

        md += "\n---\n\n## 📁 Files Modified\n\n"

        # Add modified files
        files = handoff_data.get('files_modified', [])
        if files:
            for file in files:
                md += f"- `{file}`\n"
        else:
            md += "*No files modified*\n"

        md += "\n---\n\n## 📊 Metrics\n\n"

        # Add metrics
        metrics = handoff_data.get('metrics', {})
        if metrics:
            md += "```json\n"
            md += json.dumps(metrics, indent=2)
            md += "\n```\n"
        else:
            md += "*No metrics available*\n"

        md += "\n---\n\n## 📝 Notes\n\n"

        # Add notes
        notes = handoff_data.get('notes', '')
        if notes:
            md += notes
        else:
            md += "*No additional notes*"

        md += "\n\n---\n\n"
        md += f"*Handoff posted via Linear MCP with compression* 🚀\n"

        return md

    def _format_swarm_completion(
        self,
        swarm_name: str,
        agents_results: List[Dict[str, Any]]
    ) -> str:
        """Format swarm completion report as markdown."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M UTC")

        md = f"""# 🎯 Swarm Completion: {swarm_name}

**Timestamp**: {timestamp}
**Swarm**: {swarm_name}
**Agents**: {len(agents_results)}
**Status**: ✅ **COMPLETE**

---

## 📊 Swarm Summary

"""

        # Count completed/failed agents
        completed = sum(1 for r in agents_results if r.get('status') == 'complete')
        failed = len(agents_results) - completed

        md += f"- **Total Agents**: {len(agents_results)}\n"
        md += f"- **Completed**: {completed} ✅\n"
        md += f"- **Failed**: {failed} ❌\n"
        md += "\n---\n\n## 🤖 Agent Results\n\n"

        # Add each agent's results
        for i, result in enumerate(agents_results, 1):
            agent_id = result.get('agent_id', f'agent{i}')
            status = result.get('status', 'unknown')
            status_emoji = "✅" if status == "complete" else "❌"

            md += f"### {i}. {agent_id} {status_emoji}\n\n"
            md += f"**Status**: {status}\n"

            # Tasks completed
            tasks = result.get('tasks_completed', [])
            if tasks:
                md += f"**Tasks**: {len(tasks)} completed\n"
                for task in tasks[:5]:  # Show first 5
                    md += f"  - {task}\n"
                if len(tasks) > 5:
                    md += f"  - *...and {len(tasks) - 5} more*\n"

            # Files modified
            files = result.get('files_modified', [])
            if files:
                md += f"**Files**: {len(files)} modified\n"

            # Deliverables
            deliverables = result.get('deliverables', [])
            if deliverables:
                md += f"**Deliverables**: {', '.join(deliverables)}\n"

            md += "\n"

        md += "---\n\n## 📈 Compression Metrics\n\n"

        # Add compression metrics
        comp_metrics = get_compression_metrics()
        md += "```json\n"
        md += json.dumps(comp_metrics, indent=2)
        md += "\n```\n"

        md += "\n---\n\n"
        md += f"*Swarm completion posted via Linear MCP with aggressive compression* 🚀\n"

        return md


# ============================================================================
# Synchronous Convenience Functions
# ============================================================================

def post_agent_handoff_sync(
    agent_id: str,
    issue_id: str,
    handoff_data: Dict[str, Any],
    compression_level: str = "balanced"
) -> Dict[str, Any]:
    """
    Synchronous wrapper for posting agent handoff.

    Example:
        post_agent_handoff_sync(
            "agent1_bbb_coverage",
            "ACP-200",
            {
                "status": "complete",
                "tasks_completed": ["Fix BBB coverage", "Run tests"],
                "files_modified": ["fix_bbb.py"],
                "metrics": {"test_pass_rate": 0.95}
            }
        )
    """
    integration = SwarmLinearIntegration()
    return asyncio.run(integration.post_agent_handoff(
        agent_id,
        issue_id,
        handoff_data,
        compression_level
    ))


def post_swarm_completion_sync(
    swarm_name: str,
    issue_id: str,
    agents_results: List[Dict[str, Any]],
    compression_level: str = "aggressive"
) -> Dict[str, Any]:
    """
    Synchronous wrapper for posting swarm completion.

    Example:
        post_swarm_completion_sync(
            "production_testing_comprehensive",
            "ACP-201",
            [
                {"agent_id": "agent1", "status": "complete", ...},
                {"agent_id": "agent2", "status": "complete", ...}
            ]
        )
    """
    integration = SwarmLinearIntegration()
    return asyncio.run(integration.post_swarm_completion(
        swarm_name,
        issue_id,
        agents_results,
        compression_level
    ))


# ============================================================================
# Demo/Test
# ============================================================================

def demo_agent_handoff():
    """Demonstrate agent handoff posting."""
    print("=" * 70)
    print("Demo: Agent Handoff with Compression")
    print("=" * 70)

    # Sample agent handoff data
    handoff_data = {
        "status": "complete",
        "tasks_completed": [
            "Analyzed BBB coverage gap (0% → 80%)",
            "Fixed chemical_v6_0 embeddings",
            "Generated fusion table entries",
            "Ran test_bbb_common_drugs.py",
            "Achieved 95% test pass rate"
        ],
        "files_modified": [
            "scripts/fix_bbb_coverage_v6.py",
            "tests/test_bbb_common_drugs.py"
        ],
        "metrics": {
            "bbb_coverage_before": 0.0,
            "bbb_coverage_after": 0.95,
            "test_pass_rate": 0.95,
            "drugs_processed": 23
        },
        "notes": "Successfully fixed BBB coverage for all common drugs. Test suite passing."
    }

    try:
        result = post_agent_handoff_sync(
            agent_id="agent1_bbb_coverage",
            issue_id=os.getenv("LINEAR_ISSUE_ID", "TEST-123"),
            handoff_data=handoff_data,
            compression_level="balanced"
        )

        print("\n✅ Handoff posted successfully!")
        print(result["content"][0]["text"])

    except Exception as e:
        print(f"\n❌ Error: {e}")


def demo_swarm_completion():
    """Demonstrate swarm completion posting."""
    print("=" * 70)
    print("Demo: Swarm Completion with Compression")
    print("=" * 70)

    # Sample swarm results
    agents_results = [
        {
            "agent_id": "agent1_bbb_coverage",
            "status": "complete",
            "tasks_completed": ["Fix BBB coverage", "Run tests"],
            "files_modified": ["fix_bbb.py"],
            "deliverables": ["BBB_COVERAGE_FIX_REPORT.md"]
        },
        {
            "agent_id": "agent2_integration_tests",
            "status": "complete",
            "tasks_completed": ["Create test suite", "Run integration tests"],
            "files_modified": ["test_integration.py"],
            "deliverables": ["INTEGRATION_TEST_REPORT.md"]
        },
        {
            "agent_id": "agent3_performance",
            "status": "complete",
            "tasks_completed": ["Benchmark performance", "Optimize queries"],
            "files_modified": ["performance_optimizations.py"],
            "deliverables": ["PERFORMANCE_REPORT.md"]
        }
    ]

    try:
        result = post_swarm_completion_sync(
            swarm_name="production_testing_comprehensive",
            issue_id=os.getenv("LINEAR_ISSUE_ID", "TEST-123"),
            agents_results=agents_results,
            compression_level="aggressive"
        )

        print("\n✅ Swarm completion posted successfully!")
        print(result["content"][0]["text"])

    except Exception as e:
        print(f"\n❌ Error: {e}")


if __name__ == "__main__":
    """Run demos if executed directly."""

    # Check environment
    if not os.getenv("LINEAR_API_KEY"):
        print("❌ LINEAR_API_KEY not set")
        print("   Set it with: export LINEAR_API_KEY='your_key_here'")
        sys.exit(1)

    # Run demos
    demo_agent_handoff()
    print("\n")
    demo_swarm_completion()

    print("\n" + "=" * 70)
    print("Demos complete! ✅")
    print("=" * 70)
