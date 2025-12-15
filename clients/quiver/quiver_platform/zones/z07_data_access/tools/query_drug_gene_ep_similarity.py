"""
Query Drug-Gene EP Similarity - Atomic Fusion Table Wrapper

Queries d_g_chem_ep_topk_v6_0 fusion table for drug-gene targeting via chemistry × EP embeddings.

Purpose:
- EP-specific drug targeting: Find genes affected by drug via ion channel mechanisms
- Electrophysiology profiling: Drugs targeting specific EP genes
- CNS drug discovery: Ion channel-specific drug-gene interactions

Architecture:
- Direct query to pre-computed d_g_chem_ep_topk_v6_0 fusion table (1-5ms)
- Returns top-K genes ranked by EP-specific drug-gene similarity (0.0-1.0)

Data: 712,300 pre-computed pairs (14,246 drugs × 50 top EP gene targets)
Status: Previously UNUSED - EP-specific drug targeting now exposed!

Author: Swarm Agent 012 - Atomic Fusion Wrappers v1
Created: 2025-12-04
Zone: z07_data_access/tools
Version: v1.0
"""

from typing import Dict, Any
import os
import time
import psycopg2

TOOL_DEFINITION = {
    "name": "query_drug_gene_ep_similarity",
    "description": """Find genes targeted by a drug via electrophysiology mechanisms using fusion table.

**HIGH VALUE:** Previously UNUSED - EP-specific drug-gene targeting!

**Performance:** 1-5ms queries using d_g_chem_ep_topk_v6_0 fusion table

**Use Cases:**
- Ion channel targeting: "What Na+ channel genes does lamotrigine affect?"
- CNS drug discovery: "Find KCNQ genes targeted by this compound"
- Epilepsy therapy: "What seizure-related genes does valproate target via EP?"
- Cardiac safety: "What hERG-related genes does this drug affect?"

**Similarity Score:**
- 1.0 = Perfect EP-based drug-gene match
- 0.9+ = Highly likely EP gene target
- 0.7-0.9 = Moderate EP-mediated interaction
- <0.7 = Low EP targeting

**Data:** 712,300 pre-computed pairs (14,246 drugs × 50 top EP gene targets)

**Examples:**
- query_drug_gene_ep_similarity(drug_id="lamotrigine", top_k=10) → SCN1A, SCN2A (Na+ channels)
- query_drug_gene_ep_similarity(drug_id="retigabine", top_k=20) → KCNQ2, KCNQ3 (K+ channels)

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
                "description": "Number of EP gene targets to return (1-50). Default: 10",
                "default": 10,
                "minimum": 1,
                "maximum": 50
            },
            "min_similarity": {
                "type": "number",
                "description": "Minimum EP targeting score (0.0-1.0). Default: 0.7",
                "default": 0.7,
                "minimum": 0.0,
                "maximum": 1.0
            }
        },
        "required": ["drug_id"]
    }
}


async def execute(params: Dict[str, Any]) -> Dict[str, Any]:
    """Execute EP-specific drug-gene targeting query"""
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
            FROM d_g_chem_ep_topk_v6_0
            WHERE entity1_id = %s AND similarity_score >= %s
            ORDER BY similarity_score DESC
            LIMIT %s
        """, (drug_id, min_similarity, top_k))

        results = cursor.fetchall()
        cursor.close()
        conn.close()

        ep_gene_targets = [
            {
                "gene": row[0],
                "ep_targeting_score": round(float(row[1]), 4)
            }
            for row in results
        ]

        return {
            "success": True,
            "query_drug": drug_id,
            "ep_gene_targets": ep_gene_targets,
            "count": len(ep_gene_targets),
            "fusion_table": "d_g_chem_ep_topk_v6_0",
            "query_time_ms": round((time.time() - start_time) * 1000, 2),
            "source": "fusion_v6.0",
            "note": "⭐ Previously UNUSED - EP-specific drug-gene targeting!"
        }

    except Exception as e:
        return {"success": False, "error": str(e), "drug_id": drug_id}
