"""
Graph Properties Tool - Neo4j Node Metadata Access

ARCHITECTURE DECISION LOG:
v1.0 (current): Pure agentic with atomic tools
  - This tool provides Claude with Neo4j node metadata access
  - Handles multi-strategy node discovery (exact → case-insensitive → partial)
  - Returns all node properties with complete metadata
  - Calculates in-degree, out-degree, and total degree counts
  - Returns node label, properties dict, and relationship statistics

Pattern: Wraps Neo4j direct session queries for node introspection
Reference: /Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z07_data_access/tools/graph_neighbors.py
"""

from typing import Dict, Any, Optional
from pathlib import Path
import sys
import os
import logging

logger = logging.getLogger(__name__)

# Add path for Neo4j driver
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
    "name": "graph_properties",
    "description": """Access complete node metadata from Neo4j graph database.

Retrieves all properties of a node including labels, attributes, and relationship statistics
(in-degree, out-degree, total connections).

Supports multi-strategy node discovery:
- Exact matching on name, symbol, or id fields
- Case-insensitive matching
- Partial/fuzzy matching as fallback

Examples:
- "What are the properties of BRCA1 gene?" → Returns all BRCA1 node properties
- "Get metadata for Aspirin drug" → Returns all Aspirin node properties
- "Show node properties for Epilepsy disease" → Returns all Epilepsy node properties
- "What connections does protein TP53 have?" → Returns TP53 properties and degree counts

Key features:
- Case-insensitive node name matching
- Complete property retrieval (all node attributes)
- Relationship statistics (incoming/outgoing edge counts)
- Node label identification
- Multi-strategy discovery (exact → case-insensitive → partial)
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "node_name": {
                "type": "string",
                "description": "Name or symbol of the node (e.g., 'BRCA1', 'Aspirin', 'Epilepsy'). Case-insensitive."
            },
            "include_degree": {
                "type": "boolean",
                "description": "Calculate and return in-degree, out-degree, and total degree counts (default: true)",
                "default": True
            }
        },
        "required": ["node_name"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute graph_properties tool - retrieve node metadata from Neo4j.

    This is a thin wrapper around Neo4j Cypher queries for node introspection.
    Handles case-insensitive node matching and formats results for Claude.

    Args:
        tool_input: Dict with keys:
            - node_name (str): Node name (case-insensitive)
            - include_degree (bool, optional): Calculate edge counts (default: true)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - node_name (str): Normalized node name
            - node_label (str): Primary label of the node
            - properties (Dict[str, Any]): All node properties
            - degree (Dict, optional): Contains in_degree, out_degree, total_degree
            - data_source (str): Data provenance
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({
        ...     "node_name": "BRCA1",
        ...     "include_degree": True
        ... })
        {
            "success": True,
            "node_name": "BRCA1",
            "node_label": "Gene",
            "properties": {
                "name": "BRCA1",
                "symbol": "BRCA1",
                "id": "ENSG00000012048",
                "chromosome": "17",
                "description": "Breast cancer type 1 susceptibility protein"
            },
            "degree": {
                "in_degree": 12,
                "out_degree": 45,
                "total_degree": 57
            },
            "data_source": "Neo4j graph database"
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "graph_properties")
        if validation_errors:
            return format_validation_response("graph_properties", validation_errors)

    try:
        # Get parameters with defaults
        node_name = tool_input.get("node_name", "").strip()
        include_degree = tool_input.get("include_degree", True)

        # Validate parameters
        if not node_name or not isinstance(node_name, str):
            return {
                "success": False,
                "error": "node_name parameter must be a non-empty string",
                "hint": "Examples: BRCA1, Aspirin, Epilepsy, TP53"
            }

        # Get Neo4j driver
        try:
            from neo4j import GraphDatabase
        except ImportError:
            return {
                "success": False,
                "error": "neo4j driver not installed. Run: pip install neo4j"
            }

        # Get connection parameters
        neo4j_uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
        neo4j_user = os.getenv("NEO4J_USER", "neo4j")
        neo4j_password = os.getenv("NEO4J_PASSWORD", "rescue123")

        # Create driver and execute query
        driver = None
        try:
            driver = GraphDatabase.driver(
                neo4j_uri,
                auth=(neo4j_user, neo4j_password)
            )

            with driver.session() as session:
                # Query 1: Find node with exact matching (fastest)
                find_node_query_exact = """
                MATCH (n)
                WHERE (toLower(n.name) = toLower($node_name)
                   OR toLower(n.symbol) = toLower($node_name)
                   OR toLower(n.id) = toLower($node_name))
                RETURN n, labels(n) AS node_labels
                LIMIT 1
                """

                result = session.run(find_node_query_exact, node_name=node_name)
                record = result.single()

                # Fallback 2: Case-insensitive partial match
                if not record:
                    find_node_query_partial = """
                    MATCH (n)
                    WHERE (toLower(n.name) CONTAINS toLower($node_name)
                       OR toLower(n.symbol) CONTAINS toLower($node_name))
                    RETURN n, labels(n) AS node_labels
                    LIMIT 1
                    """

                    result = session.run(find_node_query_partial, node_name=node_name)
                    record = result.single()

                    if not record:
                        return {
                            "success": False,
                            "error": f"Node not found: {node_name}",
                            "node_name": node_name,
                            "hint": "Check spelling or try using standard symbols/identifiers"
                        }

                node = record["n"]
                node_labels = record["node_labels"]
                node_label = node_labels[0] if node_labels else "Unknown"

                # Get normalized node name
                normalized_name = node.get("name") or node.get("symbol") or node.get("id") or node_name

                # Extract all properties
                properties_dict = dict(node.items())

                # Remove None values from properties
                properties_dict = {k: v for k, v in properties_dict.items() if v is not None}

                # Build result
                result_dict = {
                    "success": True,
                    "node_name": normalized_name,
                    "node_label": node_label,
                    "properties": properties_dict,
                    "data_source": "Neo4j graph database",
                    "query_params": {
                        "node_name": node_name
                    }
                }

                # Query 2: Calculate degree if requested
                if include_degree:
                    degree_query = """
                    MATCH (n)
                    WHERE (toLower(n.name) = toLower($node_name)
                       OR toLower(n.symbol) = toLower($node_name)
                       OR toLower(n.id) = toLower($node_name))
                    RETURN
                        COUNT { (n)-->() } AS out_degree,
                        COUNT { (n)<--() } AS in_degree
                    LIMIT 1
                    """

                    degree_result = session.run(degree_query, node_name=normalized_name)
                    degree_record = degree_result.single()

                    if degree_record:
                        in_degree = degree_record["in_degree"] or 0
                        out_degree = degree_record["out_degree"] or 0
                        total_degree = in_degree + out_degree

                        result_dict["degree"] = {
                            "in_degree": in_degree,
                            "out_degree": out_degree,
                            "total_degree": total_degree
                        }

                return result_dict

        except Exception as e:
            logger.error(f"Neo4j query error: {str(e)}")
            return {
                "success": False,
                "error": f"Neo4j query failed: {str(e)}",
                "node_name": node_name,
                "error_type": type(e).__name__
            }

        finally:
            if driver:
                driver.close()

    except Exception as e:
        logger.error(f"Unexpected error in graph_properties: {str(e)}")
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "node_name": tool_input.get("node_name", "unknown"),
            "error_type": type(e).__name__
        }


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
