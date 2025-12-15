"""
Query Drug Electrophysiology Similarity - Atomic Fusion Table Wrapper

Queries d_aux_ep_drug_topk_v6_0 fusion table for drugs with similar electrophysiology profiles.

Purpose:
- Ion channel profiling: Find drugs affecting similar ion channels
- CNS drug discovery: Identify drugs with similar neurophysiology effects
- Safety screening: Drugs with similar cardiac EP risks (hERG, QT prolongation)

Architecture:
- Direct query to pre-computed d_aux_ep_drug_topk_v6_0 fusion table (1-5ms)
- Returns top-K drugs ranked by EP similarity (0.0-1.0)

Data: 712,300 pre-computed pairs (14,246 drugs × 50 neighbors)
Note: Currently used by bbb_permeability - now standalone atomic access!

Author: Swarm Agent 004 - Atomic Fusion Wrappers v1
Created: 2025-12-04
Zone: z07_data_access/tools
Version: v1.0
"""

from typing import Dict, Any
import os
import time
import psycopg2

TOOL_DEFINITION = {
    "name": "query_drug_ep_similarity",
    "description": """Find drugs with similar electrophysiology (EP) profiles using pre-computed fusion table.

**Performance:** 1-5ms queries using d_aux_ep_drug_topk_v6_0 fusion table

**Use Cases:**
- Ion channel profiling: "What drugs affect similar Na+ channels to lamotrigine?"
- CNS drug discovery: "Find drugs with similar neuronal excitability effects"
- Cardiac safety: "Drugs with similar hERG/QT prolongation risks"
- Epilepsy therapy: "Drugs affecting similar ion channel combinations"

**Similarity Score:**
- 1.0 = Identical EP profile
- 0.9+ = Highly similar ion channel effects
- 0.7-0.9 = Moderately similar EP mechanisms
- <0.7 = Low EP overlap

**Data:** 712,300 pre-computed pairs (14,246 drugs × 50 top neighbors)

**Examples:**
- query_drug_ep_similarity(drug_id="lamotrigine", top_k=10) → Na+ channel blockers
- query_drug_ep_similarity(drug_id="retigabine", top_k=20) → KCNQ openers

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
    """Execute EP similarity query"""
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
            FROM d_aux_ep_drug_topk_v6_0
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
                "ep_similarity": round(float(row[1]), 4)
            }
            for row in results
        ]

        return {
            "success": True,
            "query_drug": drug_id,
            "similar_drugs": similar_drugs,
            "count": len(similar_drugs),
            "fusion_table": "d_aux_ep_drug_topk_v6_0",
            "query_time_ms": round((time.time() - start_time) * 1000, 2),
            "source": "fusion_v6.0",
            "note": "Now atomic - previously buried in bbb_permeability tool"
        }

    except Exception as e:
        return {"success": False, "error": str(e), "drug_id": drug_id}
