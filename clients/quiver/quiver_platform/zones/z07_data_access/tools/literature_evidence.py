"""
Literature Evidence Tool - Multi-Query Aggregation and Evidence Chains

ARCHITECTURE DECISION LOG:
v1.0: Literature API integration for advanced evidence discovery
  - Integrates with Literature API service (port 8765)
  - Multi-query aggregation (union/intersection)
  - Evidence chain reasoning (multi-hop claim verification)
  - Advanced literature synthesis

Pattern: Service integration tool for evidence-based reasoning
Reference: literature_search_agent.py for tool structure
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
    "name": "literature_evidence",
    "description": """Advanced literature evidence discovery with multi-query aggregation and evidence chains.

Uses the Literature API for sophisticated evidence-based reasoning across the
literature corpus (29,863 CNS papers).

**Two modes:**

1. **Multi-Query Aggregation** (mode='aggregate'):
   Combine multiple related queries to build comprehensive evidence
   - Union: Combine all unique results (broader coverage)
   - Intersection: Only papers matching all queries (higher precision)

   Example use case: "Find papers about SCN1A that mention both epilepsy AND drug treatments"
   - queries: ["SCN1A mutations", "epilepsy treatments", "sodium channel blockers"]
   - aggregation: "intersection"

2. **Evidence Chain Reasoning** (mode='evidence_chain'):
   Multi-hop reasoning to verify or discover causal chains
   - Traces logical connections through literature
   - Builds evidence chains (A→B→C)
   - Confidence scoring at each hop

   Example use case: "Verify if there's evidence that drug X affects gene Y"
   - claim: "Aspirin modulates SCN1A expression"
   - max_hops: 3 (e.g., Aspirin→COX-2→Inflammation→SCN1A)

**Examples:**

Aggregation:
- "Combine papers about TSC2, mTOR pathway, and epilepsy (intersection)"
- "Find all papers mentioning KCNQ2 OR KCNQ3 (union)"
- "Papers about drug combinations for tuberous sclerosis (union)"

Evidence chains:
- "Find evidence chain linking rapamycin to TSC2 rescue"
- "Trace connection between ketogenic diet and KCNQ2"
- "Verify if valproic acid affects SCN1A expression"

**Performance:**
- Aggregation: 1-3s (depends on # queries)
- Evidence chain: 2-8s (depends on hops and complexity)
- Quality: High precision with confidence scoring

**Data source:** Literature API v1.0 (29,863 CNS papers)
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "mode": {
                "type": "string",
                "description": "Operation mode: 'aggregate' (multi-query) or 'evidence_chain' (multi-hop reasoning)",
                "enum": ["aggregate", "evidence_chain"],
            },
            "queries": {
                "type": "array",
                "description": "[aggregate mode] List of queries to combine (1-10 queries)",
                "items": {"type": "string"},
                "minItems": 1,
                "maxItems": 10,
            },
            "aggregation": {
                "type": "string",
                "description": "[aggregate mode] How to combine: 'union' (all results) or 'intersection' (common results)",
                "enum": ["union", "intersection"],
                "default": "union",
            },
            "claim": {
                "type": "string",
                "description": "[evidence_chain mode] Claim to verify or discover evidence for",
            },
            "max_hops": {
                "type": "integer",
                "description": "[evidence_chain mode] Maximum chain length (1-5 hops). Default: 3",
                "minimum": 1,
                "maximum": 5,
                "default": 3,
            },
            "confidence_threshold": {
                "type": "number",
                "description": "[evidence_chain mode] Minimum confidence per hop (0-1). Default: 0.6",
                "minimum": 0.0,
                "maximum": 1.0,
                "default": 0.6,
            },
            "limit": {
                "type": "integer",
                "description": "[aggregate mode] Max results (1-200). Default: 50",
                "minimum": 1,
                "maximum": 200,
                "default": 50,
            },
        },
        "required": ["mode"],
    },
}


async def execute(params: dict[str, Any]) -> dict[str, Any]:
    """
    Execute literature evidence discovery (aggregation or evidence chains).

    Args:
        params: Mode-specific parameters

    Returns:
        Mode-specific response with results, timing, and metadata
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(params, TOOL_DEFINITION["input_schema"], "literature_evidence")
        if validation_errors:
            return format_validation_response("literature_evidence", validation_errors)

    mode = params.get("mode")

    if not mode:
        return {"success": False, "error": "Mode parameter required ('aggregate' or 'evidence_chain')"}

    # Literature API endpoint
    api_url = os.getenv("LITERATURE_API_URL", "http://localhost:8765")

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            if mode == "aggregate":
                return await _execute_aggregate(client, api_url, params)
            elif mode == "evidence_chain":
                return await _execute_evidence_chain(client, api_url, params)
            else:
                return {"success": False, "error": f"Invalid mode: {mode}. Use 'aggregate' or 'evidence_chain'"}

    except httpx.TimeoutException:
        return {
            "success": False,
            "error": f"Literature API timeout (>30s) in {mode} mode. Try reducing complexity.",
        }
    except httpx.ConnectError:
        return {
            "success": False,
            "error": f"Cannot connect to Literature API at {api_url}. Is the service running?",
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error in {mode} mode: {e!s}"}


async def _execute_aggregate(client: httpx.AsyncClient, api_url: str, params: dict[str, Any]) -> dict[str, Any]:
    """Execute multi-query aggregation."""
    queries = params.get("queries")
    aggregation = params.get("aggregation", "union")
    limit = params.get("limit", 50)

    if not queries:
        return {"success": False, "error": "queries parameter required for aggregate mode"}

    if not isinstance(queries, list) or len(queries) < 1:
        return {"success": False, "error": "queries must be a list with 1-10 queries"}

    response = await client.post(
        f"{api_url}/aggregate",
        json={"queries": queries, "aggregation": aggregation, "limit": limit},
    )

    if response.status_code == 200:
        data = response.json()
        return {
            "success": True,
            "mode": "aggregate",
            "results": data.get("results", []),
            "total": data.get("total", 0),
            "queries": data.get("queries", []),
            "aggregation": data.get("aggregation"),
            "per_query_counts": data.get("per_query_counts", {}),
            "query_time_ms": data.get("query_time_ms", 0),
        }
    else:
        return {
            "success": False,
            "error": f"Literature API returned status {response.status_code}: {response.text}",
        }


async def _execute_evidence_chain(client: httpx.AsyncClient, api_url: str, params: dict[str, Any]) -> dict[str, Any]:
    """Execute multi-hop evidence chain reasoning."""
    claim = params.get("claim")
    max_hops = params.get("max_hops", 3)
    confidence_threshold = params.get("confidence_threshold", 0.6)

    if not claim:
        return {"success": False, "error": "claim parameter required for evidence_chain mode"}

    response = await client.post(
        f"{api_url}/evidence_chain",
        json={
            "claim": claim,
            "max_hops": max_hops,
            "confidence_threshold": confidence_threshold,
        },
    )

    if response.status_code == 200:
        data = response.json()
        return {
            "success": True,
            "mode": "evidence_chain",
            "claim": data.get("claim"),
            "evidence_chain": data.get("evidence_chain", []),
            "chain_confidence": data.get("chain_confidence", 0),
            "chain_complete": data.get("chain_complete", False),
            "hops": len(data.get("evidence_chain", [])),
            "query_time_ms": data.get("query_time_ms", 0),
        }
    else:
        return {
            "success": False,
            "error": f"Literature API returned status {response.status_code}: {response.text}",
        }


# Synchronous wrapper for compatibility
def execute_sync(params: dict[str, Any]) -> dict[str, Any]:
    """Synchronous wrapper for execute()."""
    return asyncio.run(execute(params))
