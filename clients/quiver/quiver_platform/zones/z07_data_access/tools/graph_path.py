"""
Graph Path Tool - Neo4j Shortest Path Discovery

ARCHITECTURE DECISION LOG:
v1.0 (current): Pure agentic with atomic tools
  - This tool provides Claude with Neo4j shortest path capabilities
  - Handles multi-relationship pathfinding between two nodes
  - Returns complete path with nodes and relationships
  - Supports filtering by relationship type and maximum depth
  - Uses Cypher shortestPath() and allShortestPaths() functions
  - Limits depth to prevent expensive queries (default 5, max 10)

Pattern: Wraps Neo4j direct session queries with path discovery
Reference: /Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z08_persist/providers/neo4j_graph_provider.py
"""

from typing import Dict, Any, List, Optional
from pathlib import Path
import sys
import os
import logging

# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import harmonize_gene_id, validate_input, normalize_gene_symbol, validate_tool_input, format_validation_response
    HARMONIZATION_AVAILABLE = True
    VALIDATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
    VALIDATION_AVAILABLE = False

logger = logging.getLogger(__name__)

# Add path for Neo4j driver
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))


# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "graph_path",
    "description": """Find shortest paths between two nodes in the Neo4j graph database.

Discovers connection routes between entities (genes, drugs, proteins, pathways, diseases)
with support for filtering by relationship types and maximum path depth.

Relationship types supported:
- TARGETS: Drug → Gene/Protein (drug targets)
- TREATS: Drug → Disease (drug treats disease)
- INTERACTS_WITH: Protein ↔ Protein (protein-protein interactions)
- IN_PATHWAY: Gene/Protein → Pathway (genes in pathways)
- ASSOCIATED_WITH: Disease → Pathway (disease-pathway associations)
- IMPLICATED_IN: Disease → Pathway (disease pathways)
- HAS_DRUG_INTERACTION: Drug ↔ Drug (drug-drug interactions)

Examples:
- "How are BRCA1 and TP53 connected?" → Returns shortest paths between genes
- "Find paths from drug X to disease Y" → Drug's mechanism to disease
- "What connects gene A to pathway B?" → Multi-hop gene-to-pathway connections
- "Show connections between protein X and protein Y" → Protein interaction paths

Key features:
- Case-insensitive node name matching
- Multi-strategy node discovery (exact, case-insensitive, partial match)
- Relationship type filtering (optional)
- Configurable maximum depth (default 5, max 10)
- Returns all shortest paths or single shortest path
- Complete node and relationship metadata in results
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "source_node": {
                "type": "string",
                "description": "Starting node name or symbol (e.g., 'BRCA1', 'Aspirin', 'Epilepsy'). Case-insensitive."
            },
            "target_node": {
                "type": "string",
                "description": "Ending node name or symbol (e.g., 'TP53', 'Ibuprofen', 'Cancer'). Case-insensitive."
            },
            "max_depth": {
                "type": "integer",
                "description": "Maximum path length/depth (number of relationships). Default: 5, Max: 10",
                "default": 5,
                "minimum": 1,
                "maximum": 10
            },
            "relationship_types": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Filter paths by specific relationship types (optional). Examples: ['TARGETS', 'INTERACTS_WITH', 'IN_PATHWAY']. If empty, uses all relationships.",
                "default": []
            },
            "find_all": {
                "type": "boolean",
                "description": "Find all shortest paths (true) or just one (false). Default: false",
                "default": False
            }
        },
        "required": ["source_node", "target_node"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute graph_path tool - find shortest paths between nodes.

    This is a thin wrapper around Neo4j Cypher shortestPath/allShortestPaths queries.
    Handles case-insensitive node matching and formats results for Claude.

    Args:
        tool_input: Dict with keys:
            - source_node (str): Starting node name (case-insensitive)
            - target_node (str): Ending node name (case-insensitive)
            - max_depth (int, optional): Maximum path length (default: 5)
            - relationship_types (list, optional): Filter by relationship types
            - find_all (bool, optional): Find all shortest paths (default: False)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - source_node (str): Normalized source node name
            - target_node (str): Normalized target node name
            - paths (List[Dict]): List of paths with nodes and relationships
            - path_count (int): Number of paths found
            - path_length (int): Length of shortest path found
            - total_nodes (int): Total unique nodes across all paths
            - total_relationships (int): Total relationships in paths
            - data_source (str): Data provenance
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({
        ...     "source_node": "BRCA1",
        ...     "target_node": "TP53",
        ...     "max_depth": 3
        ... })
        {
            "success": True,
            "source_node": "BRCA1",
            "target_node": "TP53",
            "paths": [
                {
                    "path_index": 1,
                    "length": 2,
                    "nodes": [
                        {"name": "BRCA1", "type": "Gene", "properties": {...}},
                        {"name": "Protein_A", "type": "Protein", "properties": {...}},
                        {"name": "TP53", "type": "Gene", "properties": {...}}
                    ],
                    "relationships": [
                        {
                            "type": "INTERACTS_WITH",
                            "from": "BRCA1",
                            "to": "Protein_A",
                            "properties": {...}
                        },
                        {...}
                    ]
                },
                ...
            ],
            "path_count": 1,
            "path_length": 2,
            "total_nodes": 3,
            "total_relationships": 2,
            "data_source": "Neo4j graph database"
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "graph_path")
        if validation_errors:
            return format_validation_response("graph_path", validation_errors)

    try:
        # Get parameters with defaults
        source_node = tool_input.get("source_node", "").strip()
        target_node = tool_input.get("target_node", "").strip()
        max_depth = tool_input.get("max_depth", 5)
        relationship_types = tool_input.get("relationship_types", [])
        find_all = tool_input.get("find_all", False)

        # Validate parameters
        if not source_node or not isinstance(source_node, str):
            return {
                "success": False,
                "error": "source_node parameter must be a non-empty string",
                "hint": "Examples: BRCA1, Aspirin, Epilepsy, TP53"
            }

        if not target_node or not isinstance(target_node, str):
            return {
                "success": False,
                "error": "target_node parameter must be a non-empty string",
                "hint": "Examples: BRCA1, Aspirin, Epilepsy, TP53"
            }

        if not (1 <= max_depth <= 10):
            return {
                "success": False,
                "error": f"max_depth must be between 1 and 10, got {max_depth}"
            }

        if not isinstance(find_all, bool):
            return {
                "success": False,
                "error": f"find_all must be a boolean, got {type(find_all).__name__}"
            }

        # Normalize inputs
        relationship_types = [rt.upper() for rt in relationship_types if isinstance(rt, str)]

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
                # Step 1: Find source and target nodes with multi-strategy discovery
                source_record = _find_node(session, source_node)
                if not source_record:
                    return {
                        "success": False,
                        "error": f"Source node not found: {source_node}",
                        "source_node": source_node,
                        "hint": "Check spelling or try using standard symbols/identifiers"
                    }

                target_record = _find_node(session, target_node)
                if not target_record:
                    return {
                        "success": False,
                        "error": f"Target node not found: {target_node}",
                        "target_node": target_node,
                        "hint": "Check spelling or try using standard symbols/identifiers"
                    }

                normalized_source = source_record["normalized_name"]
                normalized_target = target_record["normalized_name"]
                source_type = source_record["node_type"]
                target_type = target_record["node_type"]

                # Step 2: Find paths using appropriate Cypher query
                paths_data = _find_paths(
                    session,
                    normalized_source,
                    normalized_target,
                    max_depth,
                    relationship_types,
                    find_all
                )

                if not paths_data:
                    result_dict = {
                        "success": True,
                        "source_node": normalized_source,
                        "source_type": source_type,
                        "target_node": normalized_target,
                        "target_type": target_type,
                        "paths": [],
                        "path_count": 0,
                        "path_length": None,
                        "total_nodes": 0,
                        "total_relationships": 0,
                        "data_source": "Neo4j graph database",
                        "message": f"No paths found between {normalized_source} and {normalized_target} within depth {max_depth}"
                    }

                    return result_dict

                # Step 3: Format paths for Claude
                formatted_paths = []
                path_length = None
                all_nodes = set()
                all_relationships = []

                for path_idx, path_data in enumerate(paths_data, 1):
                    formatted_path = {
                        "path_index": path_idx,
                        "length": path_data["length"],
                        "nodes": path_data["nodes"],
                        "relationships": path_data["relationships"]
                    }
                    formatted_paths.append(formatted_path)

                    if path_length is None:
                        path_length = path_data["length"]

                    # Collect unique nodes
                    for node in path_data["nodes"]:
                        all_nodes.add(node["name"])

                    # Collect relationships
                    all_relationships.extend(path_data["relationships"])

                return {
                    "success": True,
                    "source_node": normalized_source,
                    "source_type": source_type,
                    "target_node": normalized_target,
                    "target_type": target_type,
                    "paths": formatted_paths,
                    "path_count": len(formatted_paths),
                    "path_length": path_length,
                    "total_nodes": len(all_nodes),
                    "total_relationships": len(all_relationships),
                    "data_source": "Neo4j graph database",
                    "query_params": {
                        "source_node": source_node,
                        "target_node": target_node,
                        "max_depth": max_depth,
                        "relationship_types": relationship_types if relationship_types else "all",
                        "find_all": find_all
                    }
                }

        except Exception as e:
            logger.error(f"Neo4j query error: {str(e)}")
            return {
                "success": False,
                "error": f"Neo4j query failed: {str(e)}",
                "source_node": source_node,
                "target_node": target_node,
                "error_type": type(e).__name__
            }

        finally:
            if driver:
                driver.close()

    except Exception as e:
        logger.error(f"Unexpected error in graph_path: {str(e)}")
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "source_node": tool_input.get("source_node", "unknown"),
            "target_node": tool_input.get("target_node", "unknown"),
            "error_type": type(e).__name__
        }


def _find_node(session, node_name: str) -> Optional[Dict[str, Any]]:
    """
    Find a node using multi-strategy discovery (exact, case-insensitive, partial).

    Args:
        session: Neo4j session
        node_name: Name of node to find

    Returns:
        Dict with 'normalized_name' and 'node_type' keys, or None if not found
    """
    try:
        # Strategy 1: Exact match on name, symbol, or id
        query_exact = """
        MATCH (n)
        WHERE (toLower(n.name) = toLower($node_name)
           OR toLower(n.symbol) = toLower($node_name)
           OR toLower(n.id) = toLower($node_name))
        RETURN n, labels(n) AS node_labels
        LIMIT 1
        """

        result = session.run(query_exact, node_name=node_name)
        record = result.single()

        if record:
            node = record["n"]
            node_labels = record["node_labels"]
            return {
                "normalized_name": node.get("name") or node.get("symbol") or node.get("id") or node_name,
                "node_type": node_labels[0] if node_labels else "Unknown"
            }

        # Strategy 2: Partial/contains match
        query_partial = """
        MATCH (n)
        WHERE (toLower(n.name) CONTAINS toLower($node_name)
           OR toLower(n.symbol) CONTAINS toLower($node_name)
           OR toLower(n.id) CONTAINS toLower($node_name))
        RETURN n, labels(n) AS node_labels
        LIMIT 1
        """

        result = session.run(query_partial, node_name=node_name)
        record = result.single()

        if record:
            node = record["n"]
            node_labels = record["node_labels"]
            return {
                "normalized_name": node.get("name") or node.get("symbol") or node.get("id") or node_name,
                "node_type": node_labels[0] if node_labels else "Unknown"
            }

        return None

    except Exception as e:
        logger.error(f"Error in _find_node: {str(e)}")
        return None


def _find_paths(
    session,
    source_name: str,
    target_name: str,
    max_depth: int,
    relationship_types: List[str],
    find_all: bool = False
) -> List[Dict[str, Any]]:
    """
    Find shortest paths between two nodes using Neo4j Cypher.

    Args:
        session: Neo4j session
        source_name: Normalized source node name
        target_name: Normalized target node name
        max_depth: Maximum path depth
        relationship_types: List of relationship types to filter by (empty = all)
        find_all: Whether to find all shortest paths or just one

    Returns:
        List of path dicts with nodes and relationships
    """
    paths = []

    try:
        # Build relationship pattern for filtering
        if relationship_types:
            # If specific relationship types, include them in the pattern
            rel_types_pattern = "|".join(relationship_types)
            path_pattern = f"(source)-[:{rel_types_pattern}*1..{max_depth}]-(target)"
        else:
            # All relationship types
            path_pattern = f"(source)-[*1..{max_depth}]-(target)"

        # Choose between shortestPath (single) or allShortestPaths (all)
        if find_all:
            # Build the full path pattern for allShortestPaths
            if relationship_types:
                rel_types_pattern = "|".join(relationship_types)
                full_path_pattern = f"(source)-[:{rel_types_pattern}*1..{max_depth}]-(target)"
            else:
                full_path_pattern = f"(source)-[*1..{max_depth}]-(target)"

            query = f"""
            MATCH (source), (target)
            WHERE (toLower(source.name) = toLower($source_name)
               OR toLower(source.symbol) = toLower($source_name)
               OR toLower(source.id) = toLower($source_name))
            AND (toLower(target.name) = toLower($target_name)
               OR toLower(target.symbol) = toLower($target_name)
               OR toLower(target.id) = toLower($target_name))
            MATCH p = allShortestPaths({full_path_pattern})
            RETURN p
            LIMIT 100
            """
        else:
            query = f"""
            MATCH p = shortestPath({path_pattern})
            WHERE (toLower(source.name) = toLower($source_name)
               OR toLower(source.symbol) = toLower($source_name)
               OR toLower(source.id) = toLower($source_name))
            AND (toLower(target.name) = toLower($target_name)
               OR toLower(target.symbol) = toLower($target_name)
               OR toLower(target.id) = toLower($target_name))
            RETURN p
            LIMIT 1
            """

        result = session.run(query, source_name=source_name, target_name=target_name)

        for record in result:
            path = record["p"]
            path_data = _extract_path_data(path)
            if path_data:
                paths.append(path_data)

        return paths

    except Exception as e:
        logger.error(f"Error in _find_paths: {str(e)}")
        # Return empty list on error - will return "no paths found" message
        return []


def _extract_path_data(path) -> Optional[Dict[str, Any]]:
    """
    Extract node and relationship information from a Neo4j path.

    Args:
        path: Neo4j Path object

    Returns:
        Dict with 'nodes', 'relationships', and 'length' keys
    """
    try:
        nodes_data = []
        relationships_data = []

        # Extract nodes from path
        for node in path.nodes:
            node_labels = list(node.labels) if hasattr(node, 'labels') else []
            node_type = node_labels[0] if node_labels else "Unknown"

            # Get node properties
            node_properties = dict(node)

            nodes_data.append({
                "name": node.get("name") or node.get("symbol") or node.get("id") or "Unknown",
                "type": node_type,
                "properties": {k: v for k, v in node_properties.items() if v is not None}
            })

        # Extract relationships from path
        for rel in path.relationships:
            rel_type = rel.type if hasattr(rel, 'type') else "UNKNOWN"
            rel_properties = dict(rel)

            # Get start and end node names
            start_node = path.nodes[path.relationships.index(rel)] if path.relationships.index(rel) < len(path.nodes) else None
            end_node = path.nodes[path.relationships.index(rel) + 1] if path.relationships.index(rel) + 1 < len(path.nodes) else None

            start_name = start_node.get("name") or start_node.get("symbol") or start_node.get("id") if start_node else "Unknown"
            end_name = end_node.get("name") or end_node.get("symbol") or end_node.get("id") if end_node else "Unknown"

            relationships_data.append({
                "type": rel_type,
                "from": start_name,
                "to": end_name,
                "properties": {k: v for k, v in rel_properties.items() if v is not None}
            })

        return {
            "nodes": nodes_data,
            "relationships": relationships_data,
            "length": len(path.relationships)
        }

    except Exception as e:
        logger.error(f"Error extracting path data: {str(e)}")
        return None


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
