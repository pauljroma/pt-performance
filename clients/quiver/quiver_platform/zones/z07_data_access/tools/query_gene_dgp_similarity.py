"""
Query Gene Disease-Gene-Protein Similarity - Atomic Fusion Table Wrapper

Queries g_aux_dgp_topk_v6_0 fusion table for genes involved in similar disease-gene-protein networks.

Purpose:
- Disease pathway mapping: Find genes in similar molecular disease pathways
- Rare disease gene discovery: Identify candidate genes for undiagnosed diseases
- Therapeutic target validation: Genes in similar druggable networks

Architecture:
- Direct query to pre-computed g_aux_dgp_topk_v6_0 fusion table (1-5ms)
- Returns top-K genes ranked by DGP network similarity (0.0-1.0)

Data: 918,400 pre-computed pairs (18,368 genes × 50 neighbors)
Note: Currently used by demeo_drug_rescue - now standalone atomic access!

Author: Swarm Agent 007 - Atomic Fusion Wrappers v1
Created: 2025-12-04
Zone: z07_data_access/tools
Version: v1.0
"""

from typing import Dict, Any
import os
import time
import psycopg2

TOOL_DEFINITION = {
    "name": "query_gene_dgp_similarity",
    "description": """Find genes in similar disease-gene-protein (DGP) networks using pre-computed fusion table.

**Performance:** 1-5ms queries using g_aux_dgp_topk_v6_0 fusion table

**Use Cases:**
- Disease pathway mapping: "What genes share TSC2's mTOR pathway role?"
- Rare disease discovery: "Find candidate genes for Dravet-like syndromes"
- Target validation: "Genes in similar druggable disease networks"
- Comorbidity analysis: "Genes shared across related disease pathways"

**Similarity Score (0.0-1.0):**
- 1.0 = Identical DGP network role
- 0.9+ = Highly similar disease pathways
- 0.7-0.9 = Moderately similar gene-protein networks
- <0.7 = Low pathway overlap

**Default threshold: 0.7** (moderate similarity filter)

**Interpreting Results:**
- 0 results at 0.7 threshold = Gene has unique functional role with low pathway overlap (scientifically meaningful!)
- To explore weak overlaps, lower min_similarity to 0.2-0.5
- Example: SCN1A (sodium channel) returns 0 results at 0.7 - this indicates functional uniqueness, not missing data

**Data:** 918,400 pre-computed pairs (18,368 genes × 50 top neighbors)

**Examples:**
- query_gene_dgp_similarity(gene="TSC2", top_k=10) → mTOR pathway genes (strong overlap)
- query_gene_dgp_similarity(gene="SCN1A", top_k=20, min_similarity=0.2) → Weak pathway overlaps

Performance: ~1-5ms per query""",
    "input_schema": {
        "type": "object",
        "properties": {
            "gene": {
                "type": "string",
                "description": "Gene symbol (case-insensitive)"
            },
            "top_k": {
                "type": "integer",
                "description": "Number of similar genes to return (1-50). Default: 10",
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
        "required": ["gene"]
    }
}


async def execute(params: Dict[str, Any]) -> Dict[str, Any]:
    """Execute gene DGP similarity query"""
    start_time = time.time()

    gene = params.get("gene", "").strip().upper()
    top_k = params.get("top_k", 10)
    min_similarity = params.get("min_similarity", 0.7)

    if not gene:
        return {"success": False, "error": "gene parameter required"}

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
            FROM g_aux_dgp_topk_v6_0
            WHERE entity1_id = %s AND similarity_score >= %s
            ORDER BY similarity_score DESC
            LIMIT %s
        """, (gene, min_similarity, top_k))

        results = cursor.fetchall()
        cursor.close()
        conn.close()

        similar_genes = [
            {
                "gene": row[0],
                "dgp_similarity": round(float(row[1]), 4)
            }
            for row in results
        ]

        return {
            "success": True,
            "query_gene": gene,
            "similar_genes": similar_genes,
            "count": len(similar_genes),
            "fusion_table": "g_aux_dgp_topk_v6_0",
            "query_time_ms": round((time.time() - start_time) * 1000, 2),
            "source": "fusion_v6.0",
            "note": "Now atomic - previously buried in demeo_drug_rescue"
        }

    except Exception as e:
        return {"success": False, "error": str(e), "gene": gene}
