"""
Graph Subgraph Tool - N-Hop Subgraph Extraction from Neo4j

ARCHITECTURE DECISION LOG:
v1.0 (current): Pure agentic with atomic tools
  - This tool provides Claude with Neo4j subgraph extraction capabilities
  - Handles variable-length path traversal (1-3 hops from center node)
  - Returns both nodes and edges for complete subgraph reconstruction
  - Supports filtering by node types and relationship types
  - Limits results to prevent graph explosion (default 100 nodes, max 500)
  - Uses multi-strategy node discovery similar to graph_neighbors

Pattern: Wraps Neo4j Cypher variable-length path queries
Reference: /Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z08_persist/providers/neo4j_graph_provider.py:231-284
"""

from typing import Dict, Any, List, Optional, Set, Tuple
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
    "name": "graph_subgraph",
    "description": """Extract N-hop subgraphs from Neo4j around a central node.

Discovers all connected nodes and edges within N hops (1-3) from a center node,
with optional filtering by node labels and relationship types.

Returns complete subgraph structure (nodes, edges, statistics) for visualization
and analysis.

Relationship types supported:
- TARGETS: Drug → Gene/Protein (drug targets)
- TREATS: Drug → Disease (drug treats disease)
- INTERACTS_WITH: Protein ↔ Protein (protein-protein interactions)
- IN_PATHWAY: Gene/Protein → Pathway (genes in pathways)
- ASSOCIATED_WITH: Disease → Pathway (disease-pathway associations)
- IMPLICATED_IN: Disease → Pathway (disease pathways)
- HAS_DRUG_INTERACTION: Drug ↔ Drug (drug-drug interactions)

Examples:
- "Show me the 2-hop neighborhood of BRCA1" → Returns all nodes 1-2 hops from BRCA1
- "Extract a subgraph around TP53 limiting to genes and proteins" → Filters by node type
- "What's the drug interaction subgraph around Aspirin?" → Drug-drug interactions
- "Get all pathways connected to diabetes in 1 hop" → Disease → Pathway relationships

Key features:
- Case-insensitive node name matching
- Variable-length path patterns (1-3 hops)
- Node type filtering (optional)
- Relationship type filtering (optional)
- Result limiting to prevent explosion (default 100 nodes, max 500)
- Returns edges with relationship metadata
- Includes subgraph statistics (node types, relationship types, density)
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "center_node": {
                "type": "string",
                "description": "Name or symbol of the central node (e.g., 'BRCA1', 'Aspirin', 'Epilepsy'). Case-insensitive."
            },
            "hops": {
                "type": "integer",
                "description": "Number of hops to traverse (1-3). Default: 1. Higher values explore larger neighborhoods.",
                "default": 1,
                "minimum": 1,
                "maximum": 3
            },
            "node_types": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Filter subgraph to specific node labels (optional). Examples: ['Gene', 'Protein', 'Pathway', 'Disease', 'Drug']. If empty, includes all node types.",
                "default": []
            },
            "relationship_types": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Filter edges to specific relationship types (optional). Examples: ['TARGETS', 'INTERACTS_WITH', 'IN_PATHWAY']. If empty, includes all relationships.",
                "default": []
            },
            "max_nodes": {
                "type": "integer",
                "description": "Maximum total nodes to return (10-500). Default: 100",
                "default": 100,
                "minimum": 10,
                "maximum": 500
            }
        },
        "required": ["center_node"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute graph_subgraph tool - extract N-hop subgraph from Neo4j.

    This is a thin wrapper around Neo4j Cypher variable-length path queries.
    Handles case-insensitive node matching and formats subgraph for Claude.

    Args:
        tool_input: Dict with keys:
            - center_node (str): Central node name (case-insensitive)
            - hops (int, optional): Number of hops (default: 1)
            - node_types (list, optional): Filter by node labels
            - relationship_types (list, optional): Filter by relationship types
            - max_nodes (int, optional): Limit total nodes (default: 100)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - center_node (str): Normalized central node name
            - center_node_type (str): Label of center node
            - nodes (List[Dict]): Subgraph nodes with properties
            - edges (List[Dict]): Subgraph edges with relationship info
            - node_count (int): Total nodes in subgraph
            - edge_count (int): Total edges in subgraph
            - statistics (Dict): Subgraph analysis (types, density, etc.)
            - data_source (str): Data provenance
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({
        ...     "center_node": "BRCA1",
        ...     "hops": 2,
        ...     "node_types": ["Gene", "Protein"],
        ...     "max_nodes": 50
        ... })
        {
            "success": True,
            "center_node": "BRCA1",
            "center_node_type": "Gene",
            "nodes": [
                {
                    "id": "BRCA1",
                    "name": "BRCA1",
                    "node_type": "Gene",
                    "properties": {"symbol": "BRCA1", "position": "..."},
                    "distance_from_center": 0
                },
                {
                    "id": "TP53",
                    "name": "TP53",
                    "node_type": "Gene",
                    "properties": {...},
                    "distance_from_center": 1
                },
                ...
            ],
            "edges": [
                {
                    "source": "BRCA1",
                    "target": "TP53",
                    "relationship_type": "INTERACTS_WITH",
                    "properties": {"confidence": 0.95},
                    "hop_distance": 1
                },
                ...
            ],
            "node_count": 25,
            "edge_count": 38,
            "statistics": {
                "node_types": {"Gene": 15, "Protein": 10},
                "relationship_types": {"INTERACTS_WITH": 25, "IN_PATHWAY": 13},
                "max_degree": 8,
                "avg_degree": 3.04,
                "density": 0.12
            },
            "data_source": "Neo4j graph database",
            "query_params": {...}
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "graph_subgraph")
        if validation_errors:
            return format_validation_response("graph_subgraph", validation_errors)

    try:
        # Get parameters with defaults
        center_node = tool_input.get("center_node", "").strip()
        hops = tool_input.get("hops", 1)
        node_types = tool_input.get("node_types", [])
        relationship_types = tool_input.get("relationship_types", [])
        max_nodes = tool_input.get("max_nodes", 100)

        # Validate parameters
        if not center_node or not isinstance(center_node, str):
            return {
                "success": False,
                "error": "center_node parameter must be a non-empty string",
                "hint": "Examples: BRCA1, Aspirin, Epilepsy, TP53"
            }

        if not (1 <= hops <= 3):
            return {
                "success": False,
                "error": f"hops must be between 1 and 3, got {hops}"
            }

        if not (10 <= max_nodes <= 500):
            return {
                "success": False,
                "error": f"max_nodes must be between 10 and 500, got {max_nodes}"
            }

        # Normalize inputs
        relationship_types = [rt.upper() for rt in relationship_types if isinstance(rt, str)]
        node_types = [nt.capitalize() for nt in node_types if isinstance(nt, str)]

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
                # Query 1: Find the central node and determine its type
                find_node_query = """
                MATCH (n)
                WHERE (toLower(n.name) = toLower($node_name)
                   OR toLower(n.symbol) = toLower($node_name)
                   OR toLower(n.id) = toLower($node_name))
                RETURN n, labels(n) AS node_labels
                LIMIT 1
                """

                result = session.run(find_node_query, node_name=center_node)
                record = result.single()

                if not record:
                    # Try partial match as fallback
                    find_node_query_partial = """
                    MATCH (n)
                    WHERE (toLower(n.name) CONTAINS toLower($node_name)
                       OR toLower(n.symbol) CONTAINS toLower($node_name))
                    RETURN n, labels(n) AS node_labels
                    LIMIT 1
                    """

                    result = session.run(find_node_query_partial, node_name=center_node)
                    record = result.single()

                    if not record:
                        return {
                            "success": False,
                            "error": f"Node not found: {center_node}",
                            "center_node": center_node,
                            "hint": "Check spelling or try using standard symbols/identifiers"
                        }

                center = record["n"]
                center_node_type_list = record["node_labels"]
                center_node_type = center_node_type_list[0] if center_node_type_list else "Unknown"

                # Get normalized center node name
                normalized_center = center.get("name") or center.get("symbol") or center.get("id") or center_node

                # Query 2: Extract N-hop subgraph
                subgraph_data = _extract_subgraph(
                    session,
                    normalized_center,
                    hops,
                    node_types,
                    relationship_types,
                    max_nodes
                )

                if not subgraph_data:
                    return {
                        "success": False,
                        "error": "Failed to extract subgraph",
                        "center_node": normalized_center,
                        "hops": hops
                    }

                # Calculate subgraph statistics
                statistics = _compute_subgraph_statistics(
                    subgraph_data["nodes"],
                    subgraph_data["edges"]
                )

                result_dict = {
                    "success": True,
                    "center_node": normalized_center,
                    "center_node_type": center_node_type,
                    "nodes": subgraph_data["nodes"],
                    "edges": subgraph_data["edges"],
                    "node_count": len(subgraph_data["nodes"]),
                    "edge_count": len(subgraph_data["edges"]),
                    "statistics": statistics,
                    "data_source": "Neo4j graph database",
                    "query_params": {
                        "center_node": center_node,
                        "hops": hops,
                        "node_types": node_types if node_types else "all",
                        "relationship_types": relationship_types if relationship_types else "all",
                        "max_nodes": max_nodes
                    }
                }

                return result_dict

        except Exception as e:
            logger.error(f"Neo4j query error: {str(e)}")
            return {
                "success": False,
                "error": f"Neo4j query failed: {str(e)}",
                "center_node": center_node,
                "error_type": type(e).__name__
            }

        finally:
            if driver:
                driver.close()

    except Exception as e:
        logger.error(f"Unexpected error in graph_subgraph: {str(e)}")
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "center_node": tool_input.get("center_node", "unknown"),
            "error_type": type(e).__name__
        }


def _extract_subgraph(
    session,
    center_node: str,
    hops: int,
    node_types: List[str],
    relationship_types: List[str],
    max_nodes: int
) -> Optional[Dict[str, Any]]:
    """
    Extract N-hop subgraph using variable-length path patterns.

    Args:
        session: Neo4j session
        center_node: Name of central node
        hops: Number of hops to traverse (1-3)
        node_types: Filter by node labels (empty = all)
        relationship_types: Filter by relationship types (empty = all)
        max_nodes: Maximum total nodes to return

    Returns:
        Dict with 'nodes' and 'edges' lists, or None on error
    """
    try:
        nodes_dict: Dict[str, Dict[str, Any]] = {}
        edges_list: List[Dict[str, Any]] = []

        # Query all paths up to N hops from center node
        # This finds all nodes reachable within N hops and all edges between them
        paths_query = f"""
        MATCH (center)-[rel*0..{hops}]-(connected)
        WHERE (toLower(center.name) = toLower($center_node)
           OR toLower(center.symbol) = toLower($center_node)
           OR toLower(center.id) = toLower($center_node))
        WITH DISTINCT center, connected, rel
        RETURN center, connected, rel, size(rel) as hop_distance
        LIMIT $max_nodes
        """

        result = session.run(
            paths_query,
            center_node=center_node,
            max_nodes=max_nodes * 2  # Allow querying more to get good coverage
        )

        # Collect all nodes
        node_distances: Dict[str, int] = {}
        for record in result:
            center_node_obj = record["center"]
            connected_node = record["connected"]
            hops_found = record["hop_distance"]

            # Add center node (distance 0)
            center_id = center_node_obj.get("name") or center_node_obj.get("symbol") or center_node_obj.get("id")
            if center_id and center_id not in node_distances:
                node_distances[center_id] = 0

            # Add connected node
            connected_id = connected_node.get("name") or connected_node.get("symbol") or connected_node.get("id")
            if connected_id and (connected_id not in node_distances or node_distances[connected_id] > hops_found):
                node_distances[connected_id] = hops_found

        # Limit to max_nodes
        if len(node_distances) > max_nodes:
            # Keep center node + closest nodes by hop distance
            sorted_nodes = sorted(node_distances.items(), key=lambda x: (x[1], x[0]))
            node_distances = dict(sorted_nodes[:max_nodes])

        # Now query details for each node and relationships between them
        if not node_distances:
            return {"nodes": [], "edges": []}

        # Query node details for all nodes in our subgraph
        node_names = list(node_distances.keys())
        nodes_query = """
        MATCH (n)
        WHERE (toLower(n.name) IN $names
           OR toLower(n.symbol) IN $names
           OR toLower(n.id) IN $names)
        RETURN
            COALESCE(n.name, n.symbol, n.id) AS node_id,
            COALESCE(n.name, n.symbol, n.id) AS name,
            labels(n) AS node_labels,
            properties(n) AS properties
        """

        result = session.run(
            nodes_query,
            names=[n.lower() if isinstance(n, str) else str(n).lower() for n in node_names]
        )

        for record in result:
            node_id = record["node_id"]
            node_labels = record["node_labels"]
            node_type = node_labels[0] if node_labels else "Unknown"

            # Check node type filter
            if node_types and node_type not in node_types:
                continue

            # Add node to result
            nodes_dict[node_id] = {
                "id": node_id,
                "name": record["name"],
                "node_type": node_type,
                "properties": record["properties"] or {},
                "distance_from_center": node_distances.get(node_id, hops)
            }

        # Query edges between nodes in subgraph
        edges_query = """
        MATCH (n1)-[rel]-(n2)
        WHERE (COALESCE(n1.name, n1.symbol, n1.id) IN $node_ids
           OR COALESCE(n1.name, n1.symbol, n1.id) IN $node_ids)
        AND (COALESCE(n2.name, n2.symbol, n2.id) IN $node_ids
           OR COALESCE(n2.name, n2.symbol, n2.id) IN $node_ids)
        RETURN
            COALESCE(n1.name, n1.symbol, n1.id) AS source,
            COALESCE(n2.name, n2.symbol, n2.id) AS target,
            type(rel) AS relationship_type,
            properties(rel) AS rel_properties
        """

        node_ids = list(nodes_dict.keys())
        if node_ids:
            result = session.run(
                edges_query,
                node_ids=node_ids
            )

            seen_edges: Set[Tuple[str, str, str]] = set()

            for record in result:
                source = record["source"]
                target = record["target"]
                rel_type = record["relationship_type"]

                # Check relationship type filter
                if relationship_types and rel_type not in relationship_types:
                    continue

                # Avoid duplicate edges (directed relationships recorded once)
                edge_key = (source, target, rel_type)
                if edge_key in seen_edges:
                    continue
                seen_edges.add(edge_key)

                # Calculate hop distance as the sum of source and target distances
                hop_dist = (node_distances.get(source, 0) + node_distances.get(target, 0)) // 2

                # Build properties dict, filtering out None values
                rel_props = record.get("rel_properties") or {}
                rel_properties = {k: v for k, v in rel_props.items() if v is not None}

                edges_list.append({
                    "source": source,
                    "target": target,
                    "relationship_type": rel_type,
                    "properties": rel_properties if rel_properties else {},
                    "hop_distance": hop_dist
                })

        return {
            "nodes": list(nodes_dict.values()),
            "edges": edges_list
        }

    except Exception as e:
        logger.error(f"Error in _extract_subgraph: {str(e)}")
        return None


def _compute_subgraph_statistics(
    nodes: List[Dict[str, Any]],
    edges: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """
    Compute statistics about the extracted subgraph.

    Args:
        nodes: List of nodes in subgraph
        edges: List of edges in subgraph

    Returns:
        Dict with subgraph statistics
    """
    # Count node types
    node_types: Dict[str, int] = {}
    for node in nodes:
        node_type = node.get("node_type", "Unknown")
        node_types[node_type] = node_types.get(node_type, 0) + 1

    # Count relationship types
    rel_types: Dict[str, int] = {}
    for edge in edges:
        rel_type = edge.get("relationship_type", "Unknown")
        rel_types[rel_type] = rel_types.get(rel_type, 0) + 1

    # Calculate degree statistics
    degree_map: Dict[str, int] = {}
    for edge in edges:
        source = edge.get("source")
        target = edge.get("target")
        if source:
            degree_map[source] = degree_map.get(source, 0) + 1
        if target:
            degree_map[target] = degree_map.get(target, 0) + 1

    max_degree = max(degree_map.values()) if degree_map else 0
    avg_degree = sum(degree_map.values()) / len(degree_map) if degree_map else 0

    # Calculate density
    num_nodes = len(nodes)
    num_edges = len(edges)
    max_edges = (num_nodes * (num_nodes - 1)) / 2 if num_nodes > 1 else 0
    density = num_edges / max_edges if max_edges > 0 else 0

    return {
        "node_types": node_types,
        "node_type_count": len(node_types),
        "relationship_types": rel_types,
        "relationship_type_count": len(rel_types),
        "max_degree": max_degree,
        "avg_degree": round(avg_degree, 2),
        "density": round(density, 4),
        "total_nodes": num_nodes,
        "total_edges": num_edges
    }


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
