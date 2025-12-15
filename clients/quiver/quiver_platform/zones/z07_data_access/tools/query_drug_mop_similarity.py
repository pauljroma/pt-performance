"""
Query Drug Mechanism-of-Phenotype Similarity - Atomic Fusion Table Wrapper

Queries d_aux_mop_topk_v6_0 fusion table for drugs with similar mechanism-of-phenotype associations.

Purpose:
- Phenotype-based drug discovery: Find drugs causing similar observable effects
- Reverse pharmacology: Work backwards from phenotype to mechanism
- Polypharmacology: Drugs affecting multiple phenotype mechanisms similarly

Architecture:
- Direct query to pre-computed d_aux_mop_topk_v6_0 fusion table (1-5ms)
- Returns top-K drugs ranked by MOP similarity (0.0-1.0)

Data: 712,300 pre-computed pairs (14,246 drugs × 50 neighbors)
Status: Previously UNUSED - now exposed for discovery!

Author: Swarm Agent 005 - Atomic Fusion Wrappers v1
Created: 2025-12-04
Zone: z07_data_access/tools
Version: v1.0
"""

from typing import Dict, Any
import os
import time
import psycopg2

TOOL_DEFINITION = {
    "name": "query_drug_mop_similarity",
    "description": """Find drugs with similar mechanism-of-phenotype associations using pre-computed fusion table.

**HIGH VALUE:** Previously UNUSED table - enables phenotype-driven drug discovery!

**Performance:** 1-5ms queries using d_aux_mop_topk_v6_0 fusion table

**Use Cases:**
- Phenotype-based discovery: "What drugs cause similar sedation phenotypes to benzodiazepines?"
- Reverse pharmacology: "Find drugs with similar anti-inflammatory phenotypes"
- Side effect prediction: "Drugs with similar weight gain phenotype mechanisms"
- Polypharmacology: "Drugs affecting multiple phenotypes similarly"

**Similarity Score:**
- 1.0 = Identical phenotype mechanisms
- 0.9+ = Highly similar observable effects
- 0.7-0.9 = Moderately similar phenotypes
- <0.7 = Low phenotype overlap

**Data:** 712,300 pre-computed pairs (14,246 drugs × 50 top neighbors)

**Examples:**
- query_drug_mop_similarity(drug_id="chlorpromazine", top_k=10) → Antipsychotic phenotypes
- query_drug_mop_similarity(drug_id="aspirin", top_k=20) → Anti-inflammatory phenotypes

Performance: ~1-5ms per query""",
    "input_schema": {
        "type": "object",
        "properties": {
            "drug_id": {
                "type": "string",
                "description": "Drug identifier (ChEMBL ID or drug name)"
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
    """Execute MOP similarity query"""
    start_time = time.time()

    drug_id = params.get("drug_id", "").strip()
    top_k = params.get("top_k", 10)
    min_similarity = params.get("min_similarity", 0.7)

    if not drug_id:
        return {"success": False, "error": "drug_id parameter required"}

    try:
        conn = psycopg2.connect(
            host=os.getenv("PGVECTOR_HOST", "localhost"),
            port=int(os.getenv("PGVECTOR_PORT", "5435")),
            database=os.getenv("PGVECTOR_DB", "sapphire_database"),
            user=os.getenv("PGVECTOR_USER", "postgres"),
            password=os.getenv("PGVECTOR_PASSWORD", "temppass123")
        )

        cursor = conn.cursor()

        cursor.execute("""
            SELECT entity2_id, similarity_score
            FROM d_aux_mop_topk_v6_0
            WHERE entity1_id = %s AND similarity_score >= %s
            ORDER BY similarity_score DESC
            LIMIT %s
        """, (drug_id, min_similarity, top_k))

        results = cursor.fetchall()
        cursor.close()
        conn.close()

        similar_drugs = [
            {
                "drug_id": row[0],
                "mop_similarity": round(float(row[1]), 4)
            }
            for row in results
        ]

        return {
            "success": True,
            "query_drug": drug_id,
            "similar_drugs": similar_drugs,
            "count": len(similar_drugs),
            "fusion_table": "d_aux_mop_topk_v6_0",
            "query_time_ms": round((time.time() - start_time) * 1000, 2),
            "source": "fusion_v6.0",
            "note": "Previously UNUSED table - phenotype discovery value!"
        }

    except Exception as e:
        return {"success": False, "error": str(e), "drug_id": drug_id}
