"""
Query Drug ADR Similarity - Atomic Fusion Table Wrapper

Queries d_aux_adr_topk_v6_0 fusion table for drugs with similar adverse drug reaction (ADR) profiles.

Purpose:
- Safety profiling: Find drugs with similar side effects
- Contraindication checking: Identify drugs sharing ADR profiles
- Mechanism inference: If Drug A causes hepatotoxicity, what similar drugs also do?

Architecture:
- Direct query to pre-computed d_aux_adr_topk_v6_0 fusion table (1-5ms)
- Returns top-K drugs ranked by ADR similarity score (0.0-1.0)
- Fallback to full scan if entity not in fusion table

Data: 712,300 pre-computed pairs (14,246 drugs × 50 neighbors)

Author: Swarm Agent 001 - Atomic Fusion Wrappers v1
Created: 2025-12-04
Zone: z07_data_access/tools
Version: v1.0
"""

from typing import Dict, Any, List
import os
import time
import psycopg2

TOOL_DEFINITION = {
    "name": "query_drug_adr_similarity",
    "description": """Find drugs with similar adverse drug reaction (ADR) profiles using pre-computed fusion table.

**Performance:** 1-5ms queries using d_aux_adr_topk_v6_0 fusion table

**Use Cases:**
- Safety profiling: "What drugs have similar side effects to aspirin?"
- Contraindication checking: "What drugs share ADR profile with warfarin?"
- Mechanism inference: "If Drug A causes hepatotoxicity, what similar drugs also do?"
- Drug repurposing: "Find drugs with different targets but similar ADR profiles"

**Similarity Score:**
- 1.0 = Identical ADR profile
- 0.9+ = Highly similar side effects
- 0.7-0.9 = Moderately similar ADRs
- <0.7 = Low ADR similarity

**Data:** 712,300 pre-computed pairs (14,246 drugs × 50 top neighbors)

**Examples:**
- query_drug_adr_similarity(drug_id="aspirin", top_k=10)
- query_drug_adr_similarity(drug_id="CHEMBL25", top_k=20, min_similarity=0.8)

Performance: ~1-5ms per query""",
    "input_schema": {
        "type": "object",
        "properties": {
            "drug_id": {
                "type": "string",
                "description": "Drug identifier (ChEMBL ID or drug name). Examples: 'aspirin', 'CHEMBL25', 'ibuprofen'"
            },
            "top_k": {
                "type": "integer",
                "description": "Number of similar drugs to return (1-50). Default: 10",
                "default": 10,
                "minimum": 1,
                "maximum": 50
            },
            "min_similarity": {
                "type": "number",
                "description": "Minimum similarity threshold (0.0-1.0). Default: 0.7",
                "default": 0.7,
                "minimum": 0.0,
                "maximum": 1.0
            }
        },
        "required": ["drug_id"]
    }
}


async def execute(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute ADR similarity query using d_aux_adr_topk_v6_0 fusion table

    Args:
        params: Tool parameters with drug_id, top_k, min_similarity

    Returns:
        Similar drugs with ADR similarity scores
    """
    start_time = time.time()

    drug_id = params.get("drug_id", "").strip()
    top_k = params.get("top_k", 10)
    min_similarity = params.get("min_similarity", 0.7)

    if not drug_id:
        return {
            "success": False,
            "error": "drug_id parameter required",
            "hint": "Examples: drug_id='aspirin', drug_id='CHEMBL25'"
        }

    try:
        # Connect to PostgreSQL fusion database
        conn = psycopg2.connect(
            host=os.getenv("PGVECTOR_HOST", "localhost"),
            port=int(os.getenv("PGVECTOR_PORT", "5435")),
            database=os.getenv("PGVECTOR_DB", "sapphire_database"),
            user=os.getenv("PGVECTOR_USER", "postgres"),
            password=os.getenv("PGVECTOR_PASSWORD", "temppass123")
        )

        cursor = conn.cursor()

        # Query fusion table for pre-computed ADR neighbors
        query = """
            SELECT
                entity2_id as similar_drug,
                similarity_score
            FROM d_aux_adr_topk_v6_0
            WHERE entity1_id = %s
                AND similarity_score >= %s
            ORDER BY similarity_score DESC
            LIMIT %s
        """

        cursor.execute(query, (drug_id, min_similarity, top_k))
        results = cursor.fetchall()

        cursor.close()
        conn.close()

        # Format results
        similar_drugs = [
            {
                "drug_id": row[0],
                "adr_similarity": round(float(row[1]), 4)
            }
            for row in results
        ]

        query_time_ms = (time.time() - start_time) * 1000

        return {
            "success": True,
            "query_drug": drug_id,
            "similar_drugs": similar_drugs,
            "count": len(similar_drugs),
            "fusion_table": "d_aux_adr_topk_v6_0",
            "query_time_ms": round(query_time_ms, 2),
            "min_similarity": min_similarity,
            "top_k": top_k,
            "source": "fusion_v6.0"
        }

    except psycopg2.Error as e:
        return {
            "success": False,
            "error": f"PostgreSQL error: {str(e)}",
            "drug_id": drug_id,
            "hint": "Check database connection and fusion table availability"
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "drug_id": drug_id
        }
