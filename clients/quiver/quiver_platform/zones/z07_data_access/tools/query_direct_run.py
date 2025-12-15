"""
Query Direct Run - Fast Path to Gold Embeddings
================================================

Tier 1 pathway: Zero-overhead similarity search on gold embeddings.
Bypasses all orchestration layers for maximum speed (<100ms).

Author: Pathway Integration
Date: 2025-12-01
Zone: z07_data_access/tools
"""

import psycopg2
from typing import Dict, Any
import time
import os

# Tool definition for Claude
TOOL_DEFINITION = {
    "name": "query_direct_run",
    "description": """FASTEST PATH: Direct similarity search on gold embeddings with zero orchestration overhead.

Use this when:
- Query is simple: "drugs similar to X"
- Entity name is unambiguous
- User wants quick results
- No fusion needed

DO NOT use this when:
- Entity name is ambiguous (e.g., "aspirin" could be multiple ChEMBL IDs)
- Query needs multiple data sources
- Complex multi-step reasoning required

This bypasses intelligence broker, metagraph discovery, and meta layer.
Returns raw embedding similarity results in <100ms.

Performance: Sub-100ms typical query time
Data Sources: Gold embeddings (modex_ep_unified_16d_v6_0, ens_gene_64d_v6_0)
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "entity_name": {
                "type": "string",
                "description": "Exact entity name (drug, gene, protein)"
            },
            "entity_type": {
                "type": "string",
                "enum": ["drug", "gene", "protein"],
                "description": "Type of entity to search"
            },
            "embedding_space": {
                "type": "string",
                "enum": ["gold", "modex_ep", "lincs", "ens_gene"],
                "description": "Embedding space to search (default: gold - highest quality)",
                "default": "gold"
            },
            "k": {
                "type": "integer",
                "description": "Number of neighbors to return (1-50)",
                "default": 20,
                "minimum": 1,
                "maximum": 50
            },
            "min_similarity": {
                "type": "number",
                "description": "Minimum similarity threshold (0.0-1.0)",
                "default": 0.6,
                "minimum": 0.0,
                "maximum": 1.0
            }
        },
        "required": ["entity_name", "entity_type"]
    }
}


async def execute(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Direct execution - bypass all orchestration layers

    Args:
        params: Tool input parameters

    Returns:
        Results with neighbors from gold embeddings
    """
    start_time = time.time()

    entity_name = params["entity_name"]
    entity_type = params["entity_type"]
    space = params.get("embedding_space", "gold")
    k = params.get("k", 20)
    min_similarity = params.get("min_similarity", 0.6)

    # Validate k
    if k < 1 or k > 50:
        return {
            "success": False,
            "error": f"k must be between 1 and 50, got {k}"
        }

    # Map space to table name
    space_map = {
        "gold": {
            "drug": "modex_ep_unified_16d_v6_0",
            "gene": "g_g_1__ens__lincs",  # Fusion: 96D (ENS+LINCS)
            "protein": "g_g_1__ens__lincs"  # Fusion: 96D (ENS+LINCS, use gene space for proteins)
        },
        "modex_ep": {
            "drug": "modex_ep_unified_16d_v6_0",
            "gene": "g_g_1__ens__lincs",  # Fusion: 96D (ENS+LINCS)
            "protein": "g_g_1__ens__lincs"  # Fusion: 96D (ENS+LINCS)
        },
        "lincs": {
            "drug": "lincs_drug_32d_v5_0",
            "gene": "g_g_1__ens__lincs",  # Fusion: 96D (ENS+LINCS)
            "protein": "g_g_1__ens__lincs"  # Fusion: 96D (ENS+LINCS)
        },
        "ens_gene": {
            "drug": "modex_ep_unified_16d_v6_0",  # Fallback to gold for drugs
            "gene": "g_g_1__ens__lincs",  # Fusion: 96D (ENS+LINCS)
            "protein": "g_g_1__ens__lincs"  # Fusion: 96D (ENS+LINCS)
        }
    }

    if space not in space_map:
        return {
            "success": False,
            "error": f"Unknown embedding space: {space}. Use: gold, modex_ep, lincs, ens_gene"
        }

    if entity_type not in space_map[space]:
        return {
            "success": False,
            "error": f"Entity type {entity_type} not available in {space} space"
        }

    table_name = space_map[space][entity_type]

    try:
        # Direct PGVector connection
        conn = psycopg2.connect(
            host=os.getenv("PGVECTOR_HOST", "localhost"),
            port=int(os.getenv("PGVECTOR_PORT", "5435")),
            database=os.getenv("PGVECTOR_DB", "sapphire_database"),
            user=os.getenv("PGVECTOR_USER", "postgres"),
            password=os.getenv("PGVECTOR_PASSWORD", "temppass123")
        )

        cursor = conn.cursor()

        # Get entity embedding (case-insensitive exact match)
        # SCHEMA FIX: Base tables have no 'metadata' column (only id, embedding, version, created_at)
        cursor.execute(f"""
            SELECT id, embedding
            FROM {table_name}
            WHERE LOWER(id) = LOWER(%s)
            LIMIT 1
        """, (entity_name,))

        result = cursor.fetchone()

        if not result:
            # Try fuzzy match
            cursor.execute(f"""
                SELECT id, embedding
                FROM {table_name}
                WHERE LOWER(id) LIKE LOWER(%s)
                LIMIT 1
            """, (f"%{entity_name}%",))

            result = cursor.fetchone()

            if not result:
                cursor.close()
                conn.close()

                latency = (time.time() - start_time) * 1000

                return {
                    "success": False,
                    "found": False,
                    "error": f"Entity '{entity_name}' not found in {space} space ({table_name})",
                    "suggestion": "Try query_atomic_fusion for fuzzy matching across multiple spaces",
                    "pathway": "direct_run",
                    "latency_ms": round(latency, 2)
                }

        # SCHEMA FIX: Only 2 columns returned (id, embedding)
        entity_id, entity_embedding = result

        # Find K nearest neighbors using cosine similarity
        # SCHEMA FIX: No metadata column exists
        cursor.execute(f"""
            SELECT
                id,
                1 - (embedding <=> %s::vector) as similarity
            FROM {table_name}
            WHERE id != %s
              AND 1 - (embedding <=> %s::vector) >= %s
            ORDER BY embedding <=> %s::vector
            LIMIT %s
        """, (entity_embedding, entity_id, entity_embedding, min_similarity, entity_embedding, k))

        neighbors = []
        for row in cursor.fetchall():
            neighbors.append({
                "id": row[0],
                "similarity": round(row[1], 4),
                "metadata": {}  # SCHEMA FIX: No metadata column
            })

        cursor.close()
        conn.close()

        latency = (time.time() - start_time) * 1000

        return {
            "success": True,
            "found": True,
            "pathway": "direct_run",
            "query_entity": entity_name,
            "matched_entity": entity_id,
            "embedding_space": space,
            "table_name": table_name,
            "neighbors": neighbors,
            "neighbor_count": len(neighbors),
            "latency_ms": round(latency, 2),
            "bypassed_orchestration": True,
            "orchestration_overhead_saved": "~200-400ms",
            "metadata": {}  # SCHEMA FIX: No metadata column
        }

    except Exception as e:
        latency = (time.time() - start_time) * 1000

        return {
            "success": False,
            "error": f"Database query failed: {str(e)}",
            "pathway": "direct_run",
            "latency_ms": round(latency, 2)
        }
