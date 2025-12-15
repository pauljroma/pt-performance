"""
Graph Neighbors Tool - Neo4j Relationship Traversal + PGVector Embedding Enrichment

ARCHITECTURE DECISION LOG:
v1.0: Pure agentic with atomic tools (Neo4j only)
v2.0 (current): Neo4j PRIMARY + PGVector enrichment
  - Neo4j graph traversal remains FIRST (relationship structure is authoritative)
  - PGVector enrichment adds embedding similarity scores for semantic insight
  - Handles multi-relationship traversal (TARGETS, TREATS, INTERACTS_WITH, IN_PATHWAY, etc.)
  - Returns neighbor nodes with relationship metadata + embedding similarity
  - Supports filtering by relationship type and node labels
  - Limits results to prevent graph explosion (default 20 neighbors)

Pattern: Neo4j query → PGVector enrichment (optional)
Reference: vector_antipodal.py:_enrich_with_neo4j(), vector_neighbors.py
Date: 2025-12-01
"""
# MIGRATION NOTE (2025-12-04): Updated drug embedding table
# Context: Drug neighbor enrichment (drug-only)
# Previous: modex_ep_unified_16d_v6_0 (drug-gene UNIFIED, wrong for drug-only ops)
# Current: drug_chemical_v6_0_256d (drug-only, correct)


from typing import Dict, Any, List, Optional
from pathlib import Path
import sys
import os
import logging
import time
import psycopg2

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

# MIGRATED to v3.0 (2025-12-05): Master resolution tables (60x faster)
from clients.quiver.quiver_platform.zones.z07_data_access.drug_name_resolver_v3 import get_drug_name_resolver_v3 as get_drug_name_resolver


# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "graph_neighbors",
    "description": """Traverse Neo4j relationships to find neighboring nodes connected to a starting node.

**Neo4j Graph Traversal + PGVector Embedding Enrichment**

Supports multi-relationship discovery across Drug, Gene, Protein, Pathway, and Disease nodes
with optional embedding similarity enrichment from PGVector.

Relationship types supported:
- TARGETS: Drug → Gene/Protein (drug targets)
- TREATS: Drug → Disease (drug treats disease)
- INTERACTS_WITH: Protein ↔ Protein (protein-protein interactions)
- IN_PATHWAY: Gene/Protein → Pathway (genes in pathways)
- ASSOCIATED_WITH: Disease → Pathway (disease-pathway associations)
- IMPLICATED_IN: Disease → Pathway (disease pathways)
- HAS_DRUG_INTERACTION: Drug ↔ Drug (drug-drug interactions)

Examples:
- "What proteins does drug X target?" → Returns all TARGETS relationships
- "Which pathways contain gene Y?" → Returns all IN_PATHWAY relationships
- "What genes interact with protein Z?" → Returns INTERACTS_WITH neighbors with similarity
- "Which drugs treat disease W?" → Returns TREATS relationships with embeddings

Key features:
- Neo4j FIRST: Graph traversal provides authoritative relationship structure
- PGVector enrichment: Optional embedding similarity scores for semantic insights
- Case-insensitive node name matching
- Relationship type filtering (optional)
- Node label filtering (optional)
- Limited results to prevent graph explosion (default 20, max 100)
- Returns relationship properties, node attributes, and embedding similarity scores
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "node_name": {
                "type": "string",
                "description": "Name or symbol of the starting node (e.g., 'BRCA1', 'Aspirin', 'Epilepsy'). Case-insensitive."
            },
            "relationship_types": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Filter by specific relationship types (optional). Examples: ['TARGETS', 'INTERACTS_WITH', 'IN_PATHWAY']. If empty, returns all relationships.",
                "default": []
            },
            "node_labels": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Filter neighbors by node labels (optional). Examples: ['Gene', 'Protein', 'Pathway', 'Disease', 'Drug']. If empty, returns all node types.",
                "default": []
            },
            "max_neighbors": {
                "type": "integer",
                "description": "Maximum number of neighbors to return (1-100). Default: 20",
                "default": 20,
                "minimum": 1,
                "maximum": 100
            },
            "direction": {
                "type": "string",
                "enum": ["both", "outgoing", "incoming"],
                "description": "Relationship direction. 'both'=bidirectional, 'outgoing'=from node, 'incoming'=to node. Default: 'both'",
                "default": "both"
            },
            "enrich_with_embeddings": {
                "type": "boolean",
                "description": "Enrich neighbors with PGVector embedding similarity scores (optional, default: True)",
                "default": True
            },
            "embedding_space": {
                "type": "string",
                "enum": ["modex", "ens", "lincs", "auto"],
                "description": "Embedding space for enrichment: 'modex' (16D), 'ens' (7D), 'lincs' (32D), 'auto' (default)",
                "default": "auto"
            }
        },
        "required": ["node_name"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute graph_neighbors tool - traverse Neo4j relationships with PGVector enrichment.

    **Architecture v2.0:**
    1. Query Neo4j for graph neighbors (PRIMARY DATA SOURCE)
    2. Optionally enrich each neighbor with PGVector embedding similarity scores

    Handles case-insensitive node matching and formats results for Claude.

    Args:
        tool_input: Dict with keys:
            - node_name (str): Starting node name (case-insensitive)
            - relationship_types (list, optional): Filter by relationship types
            - node_labels (list, optional): Filter neighbors by node labels
            - max_neighbors (int, optional): Limit results (default: 20)
            - direction (str, optional): Relationship direction (default: 'both')
            - enrich_with_embeddings (bool, optional): Add PGVector similarity (default: True)
            - embedding_space (str, optional): Embedding space (default: 'auto' -> 'modex')

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - node_name (str): Normalized starting node name
            - node_type (str): Label of starting node
            - neighbors (List[Dict]): Neighboring nodes with relationship info + embedding similarity
            - count (int): Number of neighbors found
            - relationship_types_found (List[str]): Relationship types in results
            - data_sources (List[str]): Data provenance (Neo4j + PGVector if enriched)
            - enrichment_status (str): "complete", "partial", or "skipped"
            - error (str, optional): Error message if failed

    Example with enrichment:
        >>> await execute({
        ...     "node_name": "BRCA1",
        ...     "relationship_types": ["INTERACTS_WITH"],
        ...     "enrich_with_embeddings": True,
        ...     "embedding_space": "modex",
        ...     "max_neighbors": 10
        ... })
        {
            "success": True,
            "node_name": "BRCA1",
            "node_type": "Gene",
            "neighbors": [
                {
                    "name": "TP53",
                    "node_type": "Gene",
                    "relationship_type": "INTERACTS_WITH",
                    "properties": {"confidence": 0.95},
                    "direction": "outgoing",
                    "embedding_similarity": 0.8245,
                    "embedding_space": "modex"
                },
                ...
            ],
            "count": 5,
            "relationship_types_found": ["INTERACTS_WITH"],
            "data_sources": ["Neo4j graph database", "PGVector (sapphire_database)"],
            "enrichment_status": "complete"
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "graph_neighbors")
        if validation_errors:
            return format_validation_response("graph_neighbors", validation_errors)

    try:
        # Get parameters with defaults
        node_name = tool_input.get("node_name", "").strip()
        relationship_types = tool_input.get("relationship_types", [])
        node_labels = tool_input.get("node_labels", [])
        max_neighbors = tool_input.get("max_neighbors", 20)
        direction = tool_input.get("direction", "both")
        enrich_with_embeddings = tool_input.get("enrich_with_embeddings", True)
        embedding_space = tool_input.get("embedding_space", "auto")

        # Validate parameters
        if not node_name or not isinstance(node_name, str):
            return {
                "success": False,
                "error": "node_name parameter must be a non-empty string",
                "hint": "Examples: BRCA1, Aspirin, Epilepsy, TP53"
            }

        if not (1 <= max_neighbors <= 100):
            return {
                "success": False,
                "error": f"max_neighbors must be between 1 and 100, got {max_neighbors}"
            }

        if direction not in ["both", "outgoing", "incoming"]:
            return {
                "success": False,
                "error": f"direction must be 'both', 'outgoing', or 'incoming', got {direction}"
            }

        # Normalize inputs
        relationship_types = [rt.upper() for rt in relationship_types if isinstance(rt, str)]
        node_labels = [nl.capitalize() for nl in node_labels if isinstance(nl, str)]

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
                # Query 1: Find the starting node and determine its type
                find_node_query = """
                MATCH (n)
                WHERE (toLower(n.name) = toLower($node_name)
                   OR toLower(n.symbol) = toLower($node_name)
                   OR toLower(n.id) = toLower($node_name))
                RETURN n, labels(n) AS node_labels
                LIMIT 1
                """

                result = session.run(find_node_query, node_name=node_name)
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
                node_type_list = record["node_labels"]
                starting_node_type = node_type_list[0] if node_type_list else "Unknown"

                # Get normalized node name
                normalized_name = node.get("name") or node.get("symbol") or node.get("id") or node_name

                # Query 2: Find neighbors based on direction and filters
                neighbors_data = []
                relationship_types_found = set()

                if direction in ["both", "outgoing"]:
                    neighbors_data.extend(
                        _query_neighbors(
                            session,
                            normalized_name,
                            relationship_types,
                            node_labels,
                            max_neighbors,
                            direction="outgoing"
                        )
                    )

                if direction in ["both", "incoming"]:
                    neighbors_data.extend(
                        _query_neighbors(
                            session,
                            normalized_name,
                            relationship_types,
                            node_labels,
                            max_neighbors,
                            direction="incoming"
                        )
                    )

                # Remove duplicates while preserving order
                seen = set()
                unique_neighbors = []
                for neighbor in neighbors_data:
                    key = (neighbor["name"], neighbor["relationship_type"], neighbor["direction"])
                    if key not in seen:
                        seen.add(key)
                        unique_neighbors.append(neighbor)
                        relationship_types_found.add(neighbor["relationship_type"])

                # Limit to max_neighbors
                unique_neighbors = unique_neighbors[:max_neighbors]

                # Enrich with PGVector embeddings if requested and neighbors exist
                enrichment_status = "skipped"
                data_sources = ["Neo4j graph database"]

                if enrich_with_embeddings and unique_neighbors:
                    try:
                        unique_neighbors, enrichment_status = await _enrich_with_pgvector(
                            normalized_name,
                            unique_neighbors,
                            starting_node_type,
                            embedding_space
                        )
                        data_sources.append("PGVector (sapphire_database)")
                    except Exception as e:
                        logger.warning(f"PGVector enrichment failed (continuing with Neo4j results): {str(e)}")
                        enrichment_status = "partial"

                result_dict = {
                    "success": True,
                    "node_name": normalized_name,
                    "node_type": starting_node_type,
                    "neighbors": unique_neighbors,
                    "count": len(unique_neighbors),
                    "relationship_types_found": sorted(list(relationship_types_found)),
                    "data_sources": data_sources,
                    "enrichment_status": enrichment_status,
                    "query_params": {
                        "node_name": node_name,
                        "relationship_types": relationship_types if relationship_types else "all",
                        "node_labels": node_labels if node_labels else "all",
                        "max_neighbors": max_neighbors,
                        "direction": direction,
                        "enrich_with_embeddings": enrich_with_embeddings,
                        "embedding_space": embedding_space if enrich_with_embeddings else "n/a"
                    }
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
        logger.error(f"Unexpected error in graph_neighbors: {str(e)}")
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "node_name": tool_input.get("node_name", "unknown"),
            "error_type": type(e).__name__
        }


def _query_neighbors(
    session,
    node_name: str,
    relationship_types: List[str],
    node_labels: List[str],
    max_neighbors: int,
    direction: str = "outgoing"
) -> List[Dict[str, Any]]:
    """
    Helper function to query neighbors in a specific direction.

    Args:
        session: Neo4j session
        node_name: Name of starting node
        relationship_types: Filter by relationship types (empty = all)
        node_labels: Filter neighbors by node labels (empty = all)
        max_neighbors: Maximum results to return
        direction: 'outgoing' or 'incoming'

    Returns:
        List of neighbor dicts with relationship metadata
    """
    neighbors = []

    try:
        # Build relationship pattern
        if direction == "outgoing":
            pattern = "(start)-[rel]->(neighbor)"
            relationship_arrow = "->"
        else:  # incoming
            pattern = "(neighbor)-[rel]->(start)"
            relationship_arrow = "<-"

        # Build WHERE clause for relationships
        if relationship_types:
            rel_filter = " OR ".join([f"type(rel) = '{rt}'" for rt in relationship_types])
            rel_where = f"AND ({rel_filter})"
        else:
            rel_where = ""

        # Build WHERE clause for neighbor node labels
        if node_labels:
            label_filter = " OR ".join([f"'{label}' IN labels(neighbor)" for label in node_labels])
            label_where = f"AND ({label_filter})"
        else:
            label_where = ""

        # Build the query
        query = f"""
        MATCH {pattern}
        WHERE (toLower(start.name) = toLower($node_name)
           OR toLower(start.symbol) = toLower($node_name)
           OR toLower(start.id) = toLower($node_name))
        {rel_where}
        {label_where}
        RETURN
            COALESCE(neighbor.name, neighbor.symbol, neighbor.id) AS name,
            labels(neighbor) AS neighbor_labels,
            type(rel) AS relationship_type,
            properties(rel) AS rel_properties,
            $direction AS direction
        LIMIT $limit
        """

        result = session.run(
            query,
            node_name=node_name,
            direction=direction,
            limit=max_neighbors
        )

        # Sapphire v3.1: Initialize drug name resolver for commercial name resolution
        drug_name_resolver = get_drug_name_resolver()

        for record in result:
            neighbor_labels = record["neighbor_labels"]
            neighbor_type = neighbor_labels[0] if neighbor_labels else "Unknown"

            # Build properties dict, filtering out None values
            rel_props = record.get("rel_properties") or {}
            rel_properties = {k: v for k, v in rel_props.items() if v is not None}

            neighbor_data = {
                "node_type": neighbor_type,
                "relationship_type": record["relationship_type"],
                "properties": rel_properties if rel_properties else {},
                "direction": record["direction"]
            }

            # Sapphire v3.1: For drugs, resolve commercial name as PRIMARY DISPLAY
            if neighbor_type == "Drug":
                drug_id = record["name"]
                name_info = drug_name_resolver.resolve(drug_id)
                neighbor_data["drug_id"] = drug_id  # QS ID for traceability
                neighbor_data["commercial_name"] = name_info['commercial_name']  # v3.1: PRIMARY DISPLAY
                neighbor_data["name"] = name_info['commercial_name']  # Also set 'name' for backward compatibility
                neighbor_data["chembl_id"] = name_info.get('chembl_id', '')
                neighbor_data["name_source"] = name_info.get('source', 'none')
            else:
                # For non-drugs, keep simple name
                neighbor_data["name"] = record["name"]

            neighbors.append(neighbor_data)

    except Exception as e:
        logger.error(f"Error in _query_neighbors: {str(e)}")
        # Return empty list on error - caller will still get results from other direction

    return neighbors


async def _enrich_with_pgvector(
    start_node_name: str,
    neighbors: List[Dict[str, Any]],
    start_node_type: str,
    embedding_space: str = "auto"
) -> tuple:
    """
    Enrich neighbors with PGVector embedding similarity scores.

    Architecture: Neo4j query provides structure (FIRST), PGVector provides semantic richness.

    Args:
        start_node_name: Name of starting node (for context)
        neighbors: List of neighbors from Neo4j
        start_node_type: Type of starting node (Gene, Protein, Drug, etc.)
        embedding_space: Embedding space ('modex', 'ens', 'lincs', 'auto')

    Returns:
        Tuple of:
            - enriched_neighbors: List with embedding similarity added
            - enrichment_status: "complete", "partial", or "skipped"
    """
    try:
        # Auto-select embedding space
        if embedding_space == "auto":
            embedding_space = "modex"

        # Map to PGVector table names based on node type
        # Genes have dedicated embedding tables
        if start_node_type == "Gene":
            if embedding_space == "modex":
                table_name = "g_g_1__ens__lincs"  # Fusion: 96D (ENS+LINCS)
                dimensions = 256
            elif embedding_space == "ens":
                table_name = "g_g_1__ens__lincs"  # Fusion: 96D (ENS+LINCS)
                dimensions = 7
            elif embedding_space == "lincs":
                table_name = "g_g_1__ens__lincs"  # Fusion: 96D (ENS+LINCS)
                dimensions = 32
            else:
                # Skip enrichment for invalid space
                logger.warning(f"Invalid embedding_space: {embedding_space}")
                return neighbors, "skipped"
        else:
            # For non-genes (Protein, Drug, Disease), only modex available
            if embedding_space in ["modex", "auto"]:
                # Map to appropriate embedding table
                if start_node_type == "Protein":
                    table_name = "g_g_1__ens__lincs"  # Fusion: 96D (ENS+LINCS)  # Use gene embeddings
                    dimensions = 256
                elif start_node_type == "Drug":
                    table_name = "drug_chemical_v6_0_256d"
                    dimensions = 256
                else:
                    # Skip enrichment for unsupported node types
                    logger.warning(f"Enrichment not available for node type: {start_node_type}")
                    return neighbors, "skipped"
            else:
                # Only modex available for non-genes
                logger.warning(f"Embedding space '{embedding_space}' not available for {start_node_type}")
                return neighbors, "skipped"

        # Connect to PGVector
        conn = psycopg2.connect(
            host=os.getenv("PGVECTOR_HOST", "localhost"),
            port=int(os.getenv("PGVECTOR_PORT", "5435")),
            database=os.getenv("PGVECTOR_DB", "sapphire_database"),
            user=os.getenv("PGVECTOR_USER", "postgres"),
            password=os.getenv("PGVECTOR_PASSWORD", "temppass123")
        )

        cursor = conn.cursor()

        # Get starting node embedding
        cursor.execute(f"""
            SELECT id, embedding
            FROM {table_name}
            WHERE UPPER(id) = %s
            LIMIT 1
        """, (start_node_name.upper(),))

        start_result = cursor.fetchone()

        if not start_result:
            cursor.close()
            conn.close()
            logger.warning(f"Starting node {start_node_name} not found in embedding table {table_name}")
            return neighbors, "partial"

        start_id, start_embedding = start_result

        # Enrich each neighbor with embedding similarity
        enriched_neighbors = []
        enriched_count = 0

        for neighbor in neighbors:
            neighbor_name = neighbor.get("name", "")

            try:
                # Query PGVector for neighbor embedding and compute similarity
                cursor.execute(f"""
                    SELECT
                        id,
                        1 - (embedding <=> %s::vector) as similarity
                    FROM {table_name}
                    WHERE UPPER(id) = %s
                    LIMIT 1
                """, (start_embedding, neighbor_name.upper()))

                neighbor_result = cursor.fetchone()

                if neighbor_result:
                    neighbor_id, similarity = neighbor_result
                    neighbor["embedding_similarity"] = round(similarity, 4)
                    neighbor["embedding_space"] = embedding_space
                    neighbor["pgvector_enriched"] = True
                    enriched_count += 1
                else:
                    # Neighbor not found in embedding space - mark as attempted but unsuccessful
                    neighbor["embedding_similarity"] = None
                    neighbor["embedding_space"] = embedding_space
                    neighbor["pgvector_enriched"] = False

            except Exception as e:
                logger.warning(f"Failed to enrich neighbor {neighbor_name}: {str(e)}")
                neighbor["embedding_similarity"] = None
                neighbor["pgvector_enriched"] = False

            enriched_neighbors.append(neighbor)

        cursor.close()
        conn.close()

        # Determine enrichment status
        if enriched_count == len(neighbors):
            enrichment_status = "complete"
        elif enriched_count > 0:
            enrichment_status = "partial"
        else:
            enrichment_status = "skipped"

        logger.info(f"PGVector enrichment: {enriched_count}/{len(neighbors)} neighbors enriched ({embedding_space})")

        return enriched_neighbors, enrichment_status

    except psycopg2.Error as e:
        logger.error(f"PGVector connection error: {str(e)}")
        return neighbors, "partial"

    except Exception as e:
        logger.error(f"PGVector enrichment error: {str(e)}")
        return neighbors, "partial"


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
