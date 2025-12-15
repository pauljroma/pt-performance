#!/usr/bin/env python3
"""
Session Analytics & Reporting Tool for Sapphire v3

Enables scientists to query conversation history and generate reports:
- What questions did I ask about gene X?
- Which tools did I use most frequently?
- What drugs were discovered in the last week?
- Generate usage summary reports

Author: claude-code-agent
Date: 2025-11-28
Version: 1.0
"""

import json
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from collections import Counter, defaultdict

# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import validate_tool_input, format_validation_response
    VALIDATION_AVAILABLE = True
except ImportError:
    VALIDATION_AVAILABLE = False


TOOL_DEFINITION = {
    "name": "session_analytics",
    "description": """Query conversation history and generate analytics reports.

    This tool analyzes your Sapphire conversation history (stored as JSON files) to answer questions like:
    - "What did I ask about TSC2 last week?"
    - "Which tools have I used most frequently?"
    - "What drugs did I discover in recent sessions?"
    - "Show me my usage patterns over the last month"
    - "Generate a summary report of my research activity"

    Use Cases:
    - Review past discoveries
    - Track research progress
    - Identify most-used tools and queries
    - Generate weekly/monthly summary reports
    - Find specific conversations about genes/drugs
    """,
    "input_schema": {
        "type": "object",
        "properties": {
            "query_type": {
                "type": "string",
                "enum": [
                    "search_conversations",
                    "tool_usage_stats",
                    "discovered_entities",
                    "recent_activity",
                    "weekly_report",
                    "monthly_report"
                ],
                "description": (
                    "Type of analytics query:\n"
                    "- search_conversations: Find conversations about specific topics\n"
                    "- tool_usage_stats: Tool usage frequency and patterns\n"
                    "- discovered_entities: Genes/drugs discovered across sessions\n"
                    "- recent_activity: Activity in last N days\n"
                    "- weekly_report: Comprehensive weekly summary\n"
                    "- monthly_report: Comprehensive monthly summary"
                )
            },
            "search_term": {
                "type": "string",
                "description": "Search term for conversations (gene name, drug name, keyword)"
            },
            "days_back": {
                "type": "integer",
                "default": 7,
                "description": "Number of days to look back (for recent_activity, weekly_report)"
            },
            "limit": {
                "type": "integer",
                "default": 20,
                "description": "Maximum number of results to return"
            }
        },
        "required": ["query_type"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """Execute session analytics query."""
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "session_analytics")
        if validation_errors:
            return format_validation_response("session_analytics", validation_errors)

    try:
        query_type = tool_input["query_type"]
        search_term = tool_input.get("search_term", "")
        days_back = tool_input.get("days_back", 7)
        limit = tool_input.get("limit", 20)

        # Load all session files
        sessions = load_all_sessions(days_back=days_back if query_type in ["recent_activity", "weekly_report"] else None)

        if not sessions:
            return {
                "success": True,
                "message": "No conversation sessions found",
                "sessions_analyzed": 0
            }

        # Route to appropriate analytics function
        if query_type == "search_conversations":
            result = search_conversations(sessions, search_term, limit)
        elif query_type == "tool_usage_stats":
            result = tool_usage_stats(sessions)
        elif query_type == "discovered_entities":
            result = discovered_entities(sessions, limit)
        elif query_type == "recent_activity":
            result = recent_activity(sessions, days_back)
        elif query_type == "weekly_report":
            result = generate_report(sessions, "week")
        elif query_type == "monthly_report":
            result = generate_report(sessions, "month")
        else:
            return {
                "success": False,
                "error": f"Unknown query_type: {query_type}"
            }

        result["success"] = True
        result["sessions_analyzed"] = len(sessions)
        return result

    except Exception as e:
        import traceback
        return {
            "success": False,
            "error": f"Session analytics failed: {str(e)}",
            "traceback": traceback.format_exc()
        }


def load_all_sessions(days_back: Optional[int] = None) -> List[Dict[str, Any]]:
    """Load all session JSON files, optionally filtered by date."""
    sessions = []
    session_dir = Path(__file__).parent.parent.parent.parent.parent.parent.parent / "data" / "sessions"

    if not session_dir.exists():
        return []

    # Calculate cutoff date if filtering
    cutoff_date = None
    if days_back is not None:
        cutoff_date = datetime.now() - timedelta(days=days_back)

    for session_file in session_dir.glob("session_*.json"):
        try:
            with open(session_file, 'r') as f:
                session = json.load(f)

            # Filter by date if specified
            if cutoff_date:
                session_start = datetime.fromisoformat(session.get("session_start", ""))
                if session_start < cutoff_date:
                    continue

            sessions.append(session)
        except Exception as e:
            print(f"⚠️  Failed to load {session_file}: {e}")

    # Sort by session_start (newest first)
    sessions.sort(key=lambda s: s.get("session_start", ""), reverse=True)
    return sessions


def search_conversations(sessions: List[Dict], search_term: str, limit: int) -> Dict[str, Any]:
    """Search conversations for specific terms."""
    matches = []

    for session in sessions:
        session_id = session.get("session_id", "unknown")
        session_start = session.get("session_start", "")
        conversation = session.get("conversation_history", [])

        for i, message in enumerate(conversation):
            if search_term.lower() in message.get("content", "").lower():
                matches.append({
                    "session_id": session_id[:8] + "...",
                    "session_date": session_start[:10],
                    "role": message.get("role"),
                    "content_preview": message.get("content", "")[:200],
                    "full_content": message.get("content", "")
                })

                if len(matches) >= limit:
                    break

        if len(matches) >= limit:
            break

    return {
        "query": search_term,
        "matches_found": len(matches),
        "matches": matches[:limit]
    }


def tool_usage_stats(sessions: List[Dict]) -> Dict[str, Any]:
    """Analyze tool usage patterns across sessions."""
    tool_counter = Counter()
    tool_success = defaultdict(lambda: {"success": 0, "failed": 0})
    tool_times = defaultdict(list)

    for session in sessions:
        for tool_call in session.get("tool_calls", []):
            tool_name = tool_call.get("tool", "unknown")
            tool_counter[tool_name] += 1

            # Track success/failure
            if tool_call.get("result", {}).get("success"):
                tool_success[tool_name]["success"] += 1
            else:
                tool_success[tool_name]["failed"] += 1

    # Build stats
    tool_stats = []
    for tool_name, count in tool_counter.most_common():
        stats = tool_success[tool_name]
        success_rate = stats["success"] / (stats["success"] + stats["failed"]) * 100 if (stats["success"] + stats["failed"]) > 0 else 0

        tool_stats.append({
            "tool": tool_name,
            "usage_count": count,
            "success_count": stats["success"],
            "failed_count": stats["failed"],
            "success_rate": round(success_rate, 1)
        })

    return {
        "total_tool_calls": sum(tool_counter.values()),
        "unique_tools_used": len(tool_counter),
        "tool_stats": tool_stats
    }


def discovered_entities(sessions: List[Dict], limit: int) -> Dict[str, Any]:
    """Extract genes and drugs mentioned across sessions."""
    genes = Counter()
    drugs = Counter()

    for session in sessions:
        for tool_call in session.get("tool_calls", []):
            tool_input = tool_call.get("input", {})
            result = tool_call.get("result", {})

            # Extract entity from input
            entity = tool_input.get("entity") or tool_input.get("anchor_entity")
            entity_type = tool_input.get("entity_type")

            if entity and entity_type == "gene":
                genes[entity] += 1
            elif entity and entity_type == "drug":
                drugs[entity] += 1

            # Extract discovered entities from provenance_discovery results
            if tool_call.get("tool") == "provenance_discovery" and result.get("success"):
                discoveries = result.get("discoveries", {})
                for category in ["ep_measurements", "transcript_validated", "extended_discovery"]:
                    for item in discoveries.get(category, []):
                        drug_name = item.get("entity")
                        if drug_name:
                            drugs[drug_name] += 1

    return {
        "genes": {
            "total_unique": len(genes),
            "most_queried": [{"gene": g, "count": c} for g, c in genes.most_common(limit)]
        },
        "drugs": {
            "total_unique": len(drugs),
            "most_discovered": [{"drug": d, "count": c} for d, c in drugs.most_common(limit)]
        }
    }


def recent_activity(sessions: List[Dict], days_back: int) -> Dict[str, Any]:
    """Summarize recent activity."""
    total_queries = sum(s.get("query_count", 0) for s in sessions)

    # Count queries per day
    daily_activity = defaultdict(int)
    for session in sessions:
        session_date = session.get("session_start", "")[:10]
        daily_activity[session_date] += session.get("query_count", 0)

    return {
        "period": f"Last {days_back} days",
        "sessions": len(sessions),
        "total_queries": total_queries,
        "avg_queries_per_session": round(total_queries / len(sessions), 1) if sessions else 0,
        "daily_activity": dict(sorted(daily_activity.items(), reverse=True))
    }


def generate_report(sessions: List[Dict], period: str) -> Dict[str, Any]:
    """Generate comprehensive weekly or monthly report."""
    days_back = 7 if period == "week" else 30

    # Get all analytics
    activity = recent_activity(sessions, days_back)
    tools = tool_usage_stats(sessions)
    entities = discovered_entities(sessions, limit=10)

    # Extract key insights
    top_tool = tools["tool_stats"][0] if tools["tool_stats"] else None
    top_gene = entities["genes"]["most_queried"][0] if entities["genes"]["most_queried"] else None
    top_drug = entities["drugs"]["most_discovered"][0] if entities["drugs"]["most_discovered"] else None

    return {
        "report_type": f"{period}ly_summary",
        "period": f"Last {days_back} days",
        "generated_at": datetime.now().isoformat(),

        "activity_summary": activity,
        "tool_usage": tools,
        "entity_discoveries": entities,

        "key_insights": {
            "most_used_tool": top_tool["tool"] if top_tool else None,
            "most_queried_gene": top_gene["gene"] if top_gene else None,
            "most_discovered_drug": top_drug["drug"] if top_drug else None,
            "total_unique_genes": entities["genes"]["total_unique"],
            "total_unique_drugs": entities["drugs"]["total_unique"]
        }
    }


# Export for tool registration
__all__ = ["TOOL_DEFINITION", "execute"]
