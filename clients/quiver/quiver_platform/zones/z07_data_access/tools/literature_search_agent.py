"""
Literature Search Agent Tool - Deep Citation Analysis

ARCHITECTURE DECISION LOG:
v1.0: Agent-based literature search with citation depth analysis
  - Integrates with Literature Search Agent service (port 8101)
  - Provides deep citation network traversal
  - Supports hybrid search (semantic + keyword)
  - Multi-hop citation chain discovery

Pattern: Service integration tool for agent-based search
Reference: semantic_search.py for tool structure
"""

import asyncio
import os
from typing import Any

import httpx


# Import validation utilities (Stream 1.2: Validation Framework)
try:
    from tool_utils import validate_tool_input, format_validation_response
    VALIDATION_AVAILABLE = True
except ImportError:
    VALIDATION_AVAILABLE = False

# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "literature_search_agent",
    "description": """Advanced literature search with citation network analysis.

Uses the Literature Search Agent service for deep citation analysis and multi-hop
literature discovery. Goes beyond simple semantic search by analyzing citation
networks and research lineage.

**When to use this vs semantic_search:**
- Use this for: Deep research, citation chains, finding research lineage
- Use semantic_search for: Quick lookups, broad topic searches

**Capabilities:**
- Citation network traversal (follow citations up to N hops)
- Hybrid search (semantic similarity + keyword matching)
- Citation depth analysis (find foundational papers)
- Research lineage discovery (trace idea evolution)

**Examples:**
- "Find papers that cite KCNQ2 modulators research with 2-hop depth"
- "What are the foundational papers on TSC2-mTOR pathway?"
- "Trace the evolution of gene therapy for epilepsy"
- "Find recent papers citing Dravet syndrome treatments"

**Key features:**
- search_type: 'hybrid' (default), 'semantic', or 'keyword'
- citation_depth: How many citation hops (1-3, default: 2)
- top_k: Number of results (default: 20)
- filters: Filter by year, journal, authors, etc.

**Performance:**
- Latency: 1-5s (depends on citation depth)
- Quality: Higher precision than basic semantic search
- Coverage: 29,863 CNS papers + citation network

**Data source:** Literature Search Agent v1.0 (ChromaDB + citation graph)
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Research query. Examples: 'KCNQ2 modulators', 'TSC2 pathway inhibitors', 'epilepsy gene therapy'",
            },
            "search_type": {
                "type": "string",
                "description": "Search mode: 'hybrid' (semantic+keyword, default), 'semantic' (meaning-based), 'keyword' (exact matches)",
                "enum": ["hybrid", "semantic", "keyword"],
                "default": "hybrid",
            },
            "citation_depth": {
                "type": "integer",
                "description": "Citation network depth (1-3 hops). Higher = find foundational papers. Default: 2",
                "minimum": 1,
                "maximum": 3,
                "default": 2,
            },
            "top_k": {
                "type": "integer",
                "description": "Number of papers to return (1-50). Default: 20",
                "minimum": 1,
                "maximum": 50,
                "default": 20,
            },
            "filters": {
                "type": "object",
                "description": "Optional filters: {year_min: 2020, year_max: 2024, journal: 'Nature', authors: ['Smith']}",
                "properties": {
                    "year_min": {"type": "integer"},
                    "year_max": {"type": "integer"},
                    "journal": {"type": "string"},
                    "authors": {"type": "array", "items": {"type": "string"}},
                },
            },
        },
        "required": ["query"],
    },
}


async def execute(params: dict[str, Any]) -> dict[str, Any]:
    """
    Execute literature search with citation analysis.

    Args:
        params: {query, search_type?, citation_depth?, top_k?, filters?}

    Returns:
        {
            success: bool,
            results: [{paper_id, title, abstract, authors, year, journal, doi, pmid,
                      citation_score, relevance_score, citation_chain}],
            count: int,
            query_time_ms: float,
            agent: str
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(params, TOOL_DEFINITION["input_schema"], "literature_search_agent")
        if validation_errors:
            return format_validation_response("literature_search_agent", validation_errors)

    query = params.get("query")
    search_type = params.get("search_type", "hybrid")
    citation_depth = params.get("citation_depth", 2)
    top_k = params.get("top_k", 20)
    filters = params.get("filters")

    if not query:
        return {"success": False, "error": "Query parameter required"}

    # Literature Search Agent endpoint
    agent_url = os.getenv("LITERATURE_SEARCH_AGENT_URL", "http://localhost:8101")

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{agent_url}/search",
                json={
                    "query": query,
                    "search_type": search_type,
                    "citation_depth": citation_depth,
                    "top_k": top_k,
                    "filters": filters,
                },
            )

            if response.status_code == 200:
                data = response.json()
                return {
                    "success": True,
                    "results": data.get("results", []),
                    "count": len(data.get("results", [])),
                    "query_time_ms": data.get("query_time_ms", 0),
                    "search_type": search_type,
                    "citation_depth": citation_depth,
                    "agent": "literature_search_agent_v1.0",
                    "query": query,
                }
            else:
                return {
                    "success": False,
                    "error": f"Agent returned status {response.status_code}: {response.text}",
                }

    except httpx.TimeoutException:
        return {
            "success": False,
            "error": "Literature Search Agent timeout (>30s). Try reducing citation_depth or top_k.",
        }
    except httpx.ConnectError:
        return {
            "success": False,
            "error": f"Cannot connect to Literature Search Agent at {agent_url}. Is the service running?",
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {e!s}"}


# Synchronous wrapper for compatibility
def execute_sync(params: dict[str, Any]) -> dict[str, Any]:
    """Synchronous wrapper for execute()."""
    return asyncio.run(execute(params))
