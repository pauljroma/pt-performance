"""
Available Spaces Tool - List Embedding Spaces

ARCHITECTURE DECISION LOG:
v4.0 (current): PostgreSQL pgvector + Neo4j Graph only
  - pgvector: Scalable vector search with HNSW indexes
    * gene_embeddings: 18,368 genes × 64D
  - Neo4j: Graph-based rescue prediction and similarity edges
    * PREDICTS_RESCUE_MODEX_16D: 49K rescue predictions (Drug→Gene)
    * SIMILAR_* relationships: Various similarity types
  - NO file-based storage (literature embeddings only later)
  - Helps Claude understand what data is available

v3.1: Multi-storage (Files + Neo4j + pgvector)
v3.0: File-based only with EmbeddingService

Pattern: Enumerates available vector spaces across storage backends
Reference: Production Sapphire architecture
"""

from typing import Dict, Any, List
import os


# Import validation utilities (Stream 1.2: Validation Framework)
try:
    from tool_utils import validate_tool_input, format_validation_response
    VALIDATION_AVAILABLE = True
except ImportError:
    VALIDATION_AVAILABLE = False

# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "available_spaces",
    "description": """List available embedding spaces from PostgreSQL pgvector and Neo4j graph.

Returns information about all embedding spaces in the production system:
- **pgvector spaces**: Direct vector similarity search with HNSW indexes
- **Neo4j relationships**: Graph-based rescue predictions and similarities

**Storage Backends:**

1. PostgreSQL pgvector:
   - gene_embeddings: 18,368 genes × 64D
   - Supports: k-NN search, cosine similarity, HNSW indexes
   - Latency: <10ms for similarity queries

2. Neo4j Graph:
   - PREDICTS_RESCUE_MODEX_16D: 49K rescue edges (Drug→Gene)
     * 955 genes with rescue predictions
     * Top-100 rescue candidates per gene
     * 16D MODEX embedding space
     * Properties: rescue_score, raw_similarity, rank
   - SIMILAR_* relationships: Various similarity types
     * Gene-Gene: SIMILAR_ENS, SIMILAR_MODEX, SIMILAR_EP_GENE
     * Drug-Drug: SIMILAR_CHEMBL, SIMILAR_QNVS, SIMILAR_STRUCTURAL
     * Cross-space: SIMILAR_CROSS_SPACE, SIMILAR_CROSS_SPACE_EP
   - Latency: <50ms for graph traversals

**Use Cases:**
- Drug rescue prediction: Use MODEX_16D space (Neo4j)
- Gene similarity: Use pgvector gene_embeddings or Neo4j SIMILAR_* edges
- Drug similarity: Use Neo4j SIMILAR_* edges
- Literature search: Coming later (separate system)

Examples:
- "What embedding spaces are available?" → Lists pgvector + Neo4j spaces
- "Show me gene embedding spaces" → Returns gene_embeddings (pgvector)
- "What rescue prediction spaces exist?" → Returns MODEX_16D (Neo4j)
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "storage_backend": {
                "type": "string",
                "description": "Filter by storage: 'pgvector', 'neo4j', or 'all'. Default: 'all'",
                "enum": ["pgvector", "neo4j", "all"],
                "default": "all"
            }
        },
        "required": []
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute available_spaces tool - list embedding spaces from pgvector and Neo4j.

    Args:
        tool_input: Dict with keys:
            - storage_backend (str, optional): 'pgvector', 'neo4j', or 'all' (default: 'all')

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - pgvector_spaces (List[Dict]): pgvector embedding tables
            - neo4j_spaces (List[Dict]): Neo4j embedding relationships
            - total_spaces (int): Total number of spaces
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({"storage_backend": "all"})
        {
            "success": True,
            "pgvector_spaces": [
                {
                    "name": "gene_embeddings",
                    "entity_type": "Gene",
                    "dimensions": 64,
                    "entity_count": 18368,
                    "operations": ["k-NN search", "cosine similarity"],
                    "latency": "<10ms"
                }
            ],
            "neo4j_spaces": [
                {
                    "name": "MODEX_16D",
                    "relationship_type": "PREDICTS_RESCUE_MODEX_16D",
                    "entity_type": "Drug→Gene",
                    "edge_count": 49195,
                    "dimensions": 16,
                    "description": "Drug rescue predictions using 16D MODEX",
                    "operations": ["rescue_prediction", "antipodal_search"],
                    "latency": "<50ms"
                }
            ],
            "total_spaces": 2
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "available_spaces")
        if validation_errors:
            return format_validation_response("available_spaces", validation_errors)

    try:
        import psycopg2
        from neo4j import GraphDatabase

        # Get parameters with defaults
        backend_filter = tool_input.get("storage_backend", "all")

        valid_backends = ["pgvector", "neo4j", "all"]
        if backend_filter not in valid_backends:
            return {
                "success": False,
                "error": f"Invalid storage_backend: {backend_filter}",
                "valid_backends": valid_backends
            }

        pgvector_spaces = []
        neo4j_spaces = []

        # === pgvector Spaces ===
        if backend_filter in ["pgvector", "all"]:
            try:
                conn = psycopg2.connect(
                    host=os.getenv('POSTGRES_HOST', 'localhost'),
                    port=os.getenv('POSTGRES_PORT', '5432'),
                    database=os.getenv('POSTGRES_DB', 'quiver_data'),
                    user=os.getenv('POSTGRES_USER', 'expo'),
                    password=os.getenv('POSTGRES_PASSWORD', '')
                )
                cur = conn.cursor()

                # Get embedding tables
                cur.execute("""
                    SELECT DISTINCT table_name
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND column_name = 'embedding'
                      AND data_type = 'USER-DEFINED'
                    ORDER BY table_name
                """)

                for (table,) in cur.fetchall():
                    # Get count
                    cur.execute(f'SELECT COUNT(*) FROM {table}')
                    count = cur.fetchone()[0]

                    # Get dimensions
                    cur.execute(f'''
                        SELECT vector_dims(embedding) as dims
                        FROM {table}
                        WHERE embedding IS NOT NULL
                        LIMIT 1
                    ''')
                    result = cur.fetchone()
                    dims = result[0] if result else 0

                    # Skip empty tables
                    if count == 0 or dims == 0:
                        continue

                    # Determine entity type from table name
                    entity_type = "Unknown"
                    if "gene" in table.lower():
                        entity_type = "Gene"
                    elif "drug" in table.lower():
                        entity_type = "Drug"
                    elif "clinical" in table.lower():
                        entity_type = "ClinicalTrial"
                    elif "pubmed" in table.lower() or "preprint" in table.lower():
                        entity_type = "Literature"

                    pgvector_spaces.append({
                        "name": table,
                        "entity_type": entity_type,
                        "dimensions": dims,
                        "entity_count": count,
                        "operations": ["k-NN search", "cosine similarity", "HNSW index"],
                        "storage_backend": "PostgreSQL pgvector",
                        "latency": "<10ms"
                    })

                cur.close()
                conn.close()

            except Exception as e:
                pgvector_spaces.append({
                    "error": f"Failed to query pgvector: {str(e)}"
                })

        # === Neo4j Spaces ===
        if backend_filter in ["neo4j", "all"]:
            try:
                uri = os.getenv('NEO4J_URI', 'bolt://localhost:7687')
                user = os.getenv('NEO4J_USER', 'neo4j')
                password = os.getenv('NEO4J_PASSWORD', '')
                database = os.getenv('NEO4J_DATABASE', 'neo4j')

                driver = GraphDatabase.driver(uri, auth=(user, password))

                with driver.session(database=database) as session:
                    # Focus on rescue prediction relationships
                    result = session.run('''
                        CALL db.relationshipTypes() YIELD relationshipType
                        WHERE relationshipType CONTAINS 'RESCUE'
                           OR relationshipType CONTAINS 'MODEX'
                        RETURN relationshipType
                        ORDER BY relationshipType
                    ''')

                    for rec in result:
                        rel_type = rec['relationshipType']

                        # Count edges
                        count_result = session.run(f'''
                            MATCH ()-[r:{rel_type}]->()
                            RETURN count(r) as edge_count
                        ''').single()

                        edge_count = count_result['edge_count']

                        # Sample to understand structure
                        sample = session.run(f'''
                            MATCH (a)-[r:{rel_type}]->(b)
                            RETURN labels(a)[0] as from_label,
                                   labels(b)[0] as to_label,
                                   keys(r) as properties
                            LIMIT 1
                        ''').single()

                        if sample:
                            from_l = sample['from_label']
                            to_l = sample['to_label']
                            props = sample['properties']

                            # Extract dimensions from properties if available
                            dims = 16 if "MODEX_16D" in rel_type else "N/A"

                            # Determine operations
                            operations = ["graph_traversal"]
                            if "RESCUE" in rel_type:
                                operations.extend(["rescue_prediction", "antipodal_search"])
                            if "SIMILAR" in rel_type:
                                operations.append("similarity_search")

                            neo4j_spaces.append({
                                "name": rel_type.replace("PREDICTS_RESCUE_", "").replace("SIMILAR_", ""),
                                "relationship_type": rel_type,
                                "entity_type": f"{from_l}→{to_l}",
                                "edge_count": edge_count,
                                "dimensions": dims,
                                "properties": props,
                                "operations": operations,
                                "storage_backend": "Neo4j Graph",
                                "latency": "<50ms"
                            })

                driver.close()

            except Exception as e:
                neo4j_spaces.append({
                    "error": f"Failed to query Neo4j: {str(e)}"
                })

        return {
            "success": True,
            "pgvector_spaces": pgvector_spaces,
            "neo4j_spaces": neo4j_spaces,
            "total_spaces": len(pgvector_spaces) + len(neo4j_spaces),
            "storage_summary": {
                "pgvector": f"{len(pgvector_spaces)} vector tables",
                "neo4j": f"{len(neo4j_spaces)} embedding relationships"
            },
            "query_params": {
                "storage_backend": backend_filter
            }
        }

    except Exception as e:
        # Unexpected error
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "error_type": type(e).__name__
        }


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
