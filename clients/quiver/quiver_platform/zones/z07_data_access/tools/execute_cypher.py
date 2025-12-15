"""
Execute Cypher Tool - Custom Neo4j Queries

ARCHITECTURE DECISION LOG:
v3.0 (current): Pure agentic with atomic tools
  - Allows Claude to write and execute custom Cypher queries
  - Provides access to full Neo4j capabilities beyond pre-built tools
  - Includes safety limits (max results, timeout)
  - Read-only queries for safety

Pattern: Wraps Neo4j graph provider with safety constraints
Reference: Week 1 graph tools for patterns
"""

from typing import Dict, Any, List
from pathlib import Path
import sys

# Add path for services
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))



# Import validation utilities (Stream 1.2: Validation Framework)
try:
    from tool_utils import validate_tool_input, format_validation_response
    VALIDATION_AVAILABLE = True
except ImportError:
    VALIDATION_AVAILABLE = False

# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "execute_cypher",
    "description": """Execute custom Cypher queries against the Neo4j knowledge graph.

Allows Claude to write and run custom Cypher queries for complex graph operations
beyond the capabilities of pre-built tools.

Safety features:
- Read-only queries (MATCH, RETURN, WHERE, WITH, etc.)
- Write operations (CREATE, DELETE, SET) are blocked
- Max 1000 results returned
- Query timeout: 30 seconds

Use cases:
- Complex multi-hop graph traversals
- Custom aggregations and statistics
- Pattern matching beyond pre-built tools
- Schema exploration

Examples:
- "MATCH (g:Gene)-[:TARGETS]->(d:Drug) RETURN g.name, d.name LIMIT 10"
- "MATCH (g:Gene {name: 'TSC2'})-[r]->(n) RETURN type(r), labels(n), count(*) as count"
- "MATCH path = (a:Gene)-[*1..3]-(b:Disease) WHERE a.name = 'BRCA1' RETURN path LIMIT 5"

Graph schema:
- 1.3M nodes (Gene, Drug, Disease, Pathway, Protein, etc.)
- 9.5M relationships (TARGETS, TREATS, INTERACTS_WITH, ASSOCIATED_WITH, etc.)
- Properties: name, id, symbol, description, score, etc.
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Cypher query to execute (read-only). Must start with MATCH, RETURN, or WITH"
            },
            "parameters": {
                "type": "object",
                "description": "Query parameters for parameterized queries (optional). Example: {'gene_name': 'TSC2'}",
                "default": {}
            },
            "limit": {
                "type": "integer",
                "description": "Maximum number of results to return (1-1000). Default: 100",
                "default": 100,
                "minimum": 1,
                "maximum": 1000
            }
        },
        "required": ["query"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute execute_cypher tool - run custom Cypher queries.

    Args:
        tool_input: Dict with keys:
            - query (str): Cypher query (read-only)
            - parameters (dict, optional): Query parameters (default: {})
            - limit (int, optional): Max results (default: 100)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - query (str): Original query
            - results (List[Dict]): Query results
            - count (int): Number of results returned
            - latency (str): Query execution time
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({
        ...     "query": "MATCH (g:Gene {name: $name})-[r]->(n) RETURN type(r), labels(n), count(*) as count",
        ...     "parameters": {"name": "TSC2"}
        ... })
        {
            "success": True,
            "query": "MATCH (g:Gene {name: $name})...",
            "results": [
                {"type(r)": "INTERACTS_WITH", "labels(n)": ["Protein"], "count": 45},
                {"type(r)": "ASSOCIATED_WITH", "labels(n)": ["Disease"], "count": 12}
            ],
            "count": 2
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "execute_cypher")
        if validation_errors:
            return format_validation_response("execute_cypher", validation_errors)

    try:
        # Get parameters with defaults
        query = tool_input["query"]
        parameters = tool_input.get("parameters", {})
        limit = tool_input.get("limit", 100)

        # Validate parameters
        if not query or not isinstance(query, str):
            return {
                "success": False,
                "error": "Query parameter must be a non-empty string",
                "hint": "Example: MATCH (g:Gene) RETURN g.name LIMIT 10"
            }

        if not (1 <= limit <= 1000):
            return {
                "success": False,
                "error": f"Limit must be between 1 and 1000, got {limit}"
            }

        # Safety check: ensure read-only query
        query_upper = query.strip().upper()
        write_keywords = ["CREATE", "DELETE", "REMOVE", "SET", "MERGE", "DROP", "DETACH"]

        for keyword in write_keywords:
            if keyword in query_upper:
                return {
                    "success": False,
                    "error": f"Write operation '{keyword}' not allowed. Only read-only queries are permitted.",
                    "allowed_operations": ["MATCH", "RETURN", "WHERE", "WITH", "ORDER BY", "LIMIT", "SKIP"],
                    "blocked_operations": write_keywords
                }

        # Ensure query has MATCH, RETURN, or WITH
        if not any(kw in query_upper for kw in ["MATCH", "RETURN", "WITH", "CALL"]):
            return {
                "success": False,
                "error": "Query must contain MATCH, RETURN, WITH, or CALL",
                "hint": "Example: MATCH (g:Gene) RETURN g.name LIMIT 10"
            }

        # Import Neo4j driver
        try:
            from neo4j import GraphDatabase
        except ImportError:
            return {
                "success": False,
                "error": "neo4j driver not installed. Run: pip install neo4j"
            }

        # Get Neo4j connection details
        import os
        neo4j_uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
        neo4j_user = os.getenv("NEO4J_USER", "neo4j")
        neo4j_password = os.getenv("NEO4J_PASSWORD", "testpassword123")

        # Add LIMIT if not present (safety)
        if "LIMIT" not in query_upper:
            query = f"{query.rstrip(';')} LIMIT {limit}"

        # Execute query
        import time
        start_time = time.time()

        try:
            driver = GraphDatabase.driver(
                neo4j_uri,
                auth=(neo4j_user, neo4j_password)
            )

            with driver.session() as session:
                result = session.run(query, parameters or {})
                results = [dict(record) for record in result]

            driver.close()
        except Exception as e:
            return {
                "success": False,
                "error": f"Cypher query failed: {str(e)}",
                "query": query,
                "parameters": parameters,
                "hint": "Check query syntax and parameter names"
            }

        end_time = time.time()
        latency_ms = int((end_time - start_time) * 1000)

        # Enforce limit on results
        formatted_results = results[:limit] if results else []

        return {
            "success": True,
            "query": query,
            "parameters": parameters,
            "results": formatted_results,
            "count": len(formatted_results),
            "latency": f"{latency_ms}ms",
            "query_params": {
                "limit": limit
            }
        }

    except Exception as e:
        # Unexpected error
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "query": tool_input.get("query", "unknown"),
            "error_type": type(e).__name__
        }


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
