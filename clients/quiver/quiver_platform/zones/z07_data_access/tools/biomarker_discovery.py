"""
Biomarker Discovery Tool - AI-Powered Biomarker Identification

ARCHITECTURE DECISION LOG:
v1.0: Agent-based biomarker discovery from literature
  - Integrates with Biomarker Discovery Agent service (port 8100)
  - Identifies diagnostic, prognostic, and predictive biomarkers
  - Tissue-specific biomarker analysis
  - Literature-driven discovery

Pattern: Service integration tool for biomarker discovery
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
    "name": "biomarker_discovery",
    "description": """Discover biomarkers for diseases using AI-powered literature analysis.

Uses the Biomarker Discovery Agent to identify diagnostic, prognostic, and predictive
biomarkers from the literature corpus (29,863 CNS papers).

**Biomarker Types:**
- diagnostic: Biomarkers for disease detection/diagnosis
- prognostic: Biomarkers predicting disease progression
- predictive: Biomarkers predicting treatment response
- monitoring: Biomarkers for disease monitoring

**Use cases:**
- Find diagnostic biomarkers for epilepsy
- Identify prognostic markers for TSC
- Discover predictive biomarkers for drug response
- Find tissue-specific biomarkers

**Examples:**
- "Find diagnostic biomarkers for tuberous sclerosis"
- "What are prognostic biomarkers for epilepsy in brain tissue?"
- "Identify blood biomarkers for KCNQ2 channelopathy"
- "Find CSF biomarkers for neurodevelopmental disorders"

**Key features:**
- biomarker_type: Type of biomarker (default: 'diagnostic')
- tissue: Tissue context (e.g., 'brain', 'blood', 'csf', optional)
- top_k: Number of biomarkers to return (default: 20)

**Output includes:**
- Biomarker name and type
- Disease association
- Tissue specificity
- Evidence strength (from literature)
- Supporting papers (PMIDs)
- Clinical validation status

**Performance:**
- Latency: 2-8s (depends on complexity)
- Quality: Evidence-based from peer-reviewed literature
- Coverage: 29,863 CNS papers

**Data source:** Biomarker Discovery Agent v1.0 (ChromaDB + NLP)
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "disease": {
                "type": "string",
                "description": "Disease or condition name. Examples: 'tuberous sclerosis', 'epilepsy', 'KCNQ2 channelopathy', 'Dravet syndrome'",
            },
            "biomarker_type": {
                "type": "string",
                "description": "Type of biomarker: 'diagnostic' (default), 'prognostic', 'predictive', 'monitoring'",
                "enum": ["diagnostic", "prognostic", "predictive", "monitoring"],
                "default": "diagnostic",
            },
            "tissue": {
                "type": "string",
                "description": "Tissue context (optional). Examples: 'brain', 'blood', 'csf', 'serum', 'plasma', 'urine'",
            },
            "top_k": {
                "type": "integer",
                "description": "Number of biomarkers to return (1-50). Default: 20",
                "minimum": 1,
                "maximum": 50,
                "default": 20,
            },
        },
        "required": ["disease"],
    },
}


async def execute(params: dict[str, Any]) -> dict[str, Any]:
    """
    Execute biomarker discovery for a disease.

    Args:
        params: {disease, biomarker_type?, tissue?, top_k?}

    Returns:
        {
            success: bool,
            biomarkers: [{name, type, disease, tissue, evidence_score,
                         supporting_papers, validation_status, description}],
            count: int,
            query_time_ms: float,
            agent: str
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(params, TOOL_DEFINITION["input_schema"], "biomarker_discovery")
        if validation_errors:
            return format_validation_response("biomarker_discovery", validation_errors)

    disease = params.get("disease")
    biomarker_type = params.get("biomarker_type", "diagnostic")
    tissue = params.get("tissue")
    top_k = params.get("top_k", 20)

    if not disease:
        return {"success": False, "error": "Disease parameter required"}

    # Biomarker Discovery Agent endpoint
    agent_url = os.getenv("BIOMARKER_DISCOVERY_AGENT_URL", "http://localhost:8100")

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{agent_url}/discover",
                json={
                    "disease": disease,
                    "biomarker_type": biomarker_type,
                    "tissue": tissue,
                    "top_k": top_k,
                },
            )

            if response.status_code == 200:
                data = response.json()
                return {
                    "success": True,
                    "biomarkers": data.get("biomarkers", []),
                    "count": len(data.get("biomarkers", [])),
                    "query_time_ms": data.get("query_time_ms", 0),
                    "biomarker_type": biomarker_type,
                    "disease": disease,
                    "tissue": tissue,
                    "agent": "biomarker_discovery_agent_v1.0",
                }
            else:
                return {
                    "success": False,
                    "error": f"Agent returned status {response.status_code}: {response.text}",
                }

    except httpx.TimeoutException:
        return {
            "success": False,
            "error": "Biomarker Discovery Agent timeout (>30s). Try reducing top_k.",
        }
    except httpx.ConnectError:
        return {
            "success": False,
            "error": f"Cannot connect to Biomarker Discovery Agent at {agent_url}. Is the service running?",
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {e!s}"}


# Synchronous wrapper for compatibility
def execute_sync(params: dict[str, Any]) -> dict[str, Any]:
    """Synchronous wrapper for execute()."""
    return asyncio.run(execute(params))
