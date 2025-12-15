"""
Query Drug-Gene Similarity - Atomic Fusion Table Wrapper

Queries d_g_chem_ens_topk_v6_0 fusion table for drug-gene targeting relationships via chemistry × ENS embeddings.

Purpose:
- Drug targeting: Find which genes a drug is likely to affect
- Target validation: Validate drug-gene interactions
- Drug repurposing: Identify new gene targets for existing drugs

Architecture:
- Direct query to pre-computed d_g_chem_ens_topk_v6_0 fusion table (1-5ms)
- Returns top-K genes ranked by drug-gene similarity (0.0-1.0)

Data: 712,300 pre-computed pairs (14,246 drugs × 50 top gene targets)
Note: Currently used by target_validation_scorer, drug_repurposing_ranker - now atomic!

Author: Swarm Agent 011 - Atomic Fusion Wrappers v1
Created: 2025-12-04
Zone: z07_data_access/tools
Version: v1.0
"""

from typing import Dict, Any
import os
import time
import psycopg2

TOOL_DEFINITION = {
    "name": "query_drug_gene_similarity",
    "description": """Find genes targeted by a drug using chemistry × ENS fusion table.

**VERY HIGH VALUE:** Drug targeting - discover which genes a drug affects!

**Performance:** 1-5ms queries using d_g_chem_ens_topk_v6_0 fusion table

**Use Cases:**
- Drug targeting: "What genes does aspirin target?"
- Target validation: "Validate that valproate affects SCN1A"
- Drug repurposing: "Find new gene targets for metformin"
- Mechanism discovery: "What genes does this experimental compound affect?"

**Similarity Score:**
- 1.0 = Perfect drug-gene match (direct target)
- 0.9+ = Highly likely gene target
- 0.7-0.9 = Moderate drug-gene interaction
- <0.7 = Low targeting likelihood

**Data:** 712,300 pre-computed pairs (14,246 drugs × 50 top gene targets)

**Examples:**
- query_drug_gene_similarity(drug_id="valproate", top_k=10) → SCN1A, KCNQ, etc.
- query_drug_gene_similarity(drug_id="rapamycin", top_k=20) → mTOR pathway genes

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
                "description": "Number of gene targets to return (1-50). Default: 10",
                "default": 10,
                "minimum": 1,
                "maximum": 50
            },
            "min_similarity": {
                "type": "number",
                "description": "Minimum targeting score (0.0-1.0). Default: 0.7",
                "default": 0.7,
                "minimum": 0.0,
                "maximum": 1.0
            }
        },
        "required": ["drug_id"]
    }
}


async def execute(params: Dict[str, Any]) -> Dict[str, Any]:
    """Execute drug-gene targeting query"""
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
            FROM d_g_chem_ens_topk_v6_0
            WHERE entity1_id = %s AND similarity_score >= %s
            ORDER BY similarity_score DESC
            LIMIT %s
        """, (drug_id, min_similarity, top_k))

        results = cursor.fetchall()
        cursor.close()
        conn.close()

        gene_targets = [
            {
                "gene": row[0],
                "targeting_score": round(float(row[1]), 4)
            }
            for row in results
        ]

        return {
            "success": True,
            "query_drug": drug_id,
            "gene_targets": gene_targets,
            "count": len(gene_targets),
            "fusion_table": "d_g_chem_ens_topk_v6_0",
            "query_time_ms": round((time.time() - start_time) * 1000, 2),
            "source": "fusion_v6.0",
            "note": "Now atomic - previously buried in target_validation_scorer, drug_repurposing_ranker"
        }

    except Exception as e:
        return {"success": False, "error": str(e), "drug_id": drug_id}
