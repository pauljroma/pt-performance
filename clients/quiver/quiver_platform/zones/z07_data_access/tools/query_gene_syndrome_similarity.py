"""
Query Gene Syndrome Similarity - Atomic Fusion Table Wrapper

Queries g_aux_syn_topk_v6_0 fusion table for genes associated with similar syndromes.

Purpose:
- Rare disease gene discovery: Find genes causing similar rare syndromes
- Syndrome classification: Group genes by clinical syndrome similarity
- Diagnostic support: Candidate genes for undiagnosed syndrome patients

Architecture:
- Direct query to pre-computed g_aux_syn_topk_v6_0 fusion table (1-5ms)
- Returns top-K genes ranked by syndrome similarity (0.0-1.0)

Data: 918,400 pre-computed pairs (18,368 genes × 50 neighbors)
Note: Currently used by demeo_drug_rescue - HIGH VALUE for rare disease queries!

Author: Swarm Agent 010 - Atomic Fusion Wrappers v1
Created: 2025-12-04
Zone: z07_data_access/tools
Version: v1.0
"""

from typing import Dict, Any
import os
import time
import psycopg2

TOOL_DEFINITION = {
    "name": "query_gene_syndrome_similarity",
    "description": """Find genes associated with similar syndromes using pre-computed fusion table.

**VERY HIGH VALUE:** Rare disease discovery - find genes causing Dravet-like, Angelman-like syndromes!

**Performance:** 1-5ms queries using g_aux_syn_topk_v6_0 fusion table

**Use Cases:**
- Rare disease discovery: "What genes cause Dravet-like syndromes similar to SCN1A?"
- Syndrome classification: "Genes associated with Tuberous Sclerosis-like syndromes"
- Diagnostic support: "Find candidate genes for patient with Angelman-like phenotype"
- Comorbidity analysis: "Genes causing epilepsy + autism syndromes"

**Similarity Score:**
- 1.0 = Identical syndrome associations
- 0.9+ = Highly similar clinical syndromes
- 0.7-0.9 = Moderately similar syndrome features
- <0.7 = Low syndrome overlap

**Data:** 918,400 pre-computed pairs (18,368 genes × 50 top neighbors)

**Examples:**
- query_gene_syndrome_similarity(gene="SCN1A", top_k=10) → Dravet-like syndrome genes
- query_gene_syndrome_similarity(gene="TSC2", top_k=20) → Tuberous sclerosis-like genes
- query_gene_syndrome_similarity(gene="STXBP1", top_k=15) → DEE-like syndrome genes

Performance: ~1-5ms per query""",
    "input_schema": {
        "type": "object",
        "properties": {
            "gene": {
                "type": "string",
                "description": "Gene symbol (case-insensitive). Examples: 'SCN1A', 'TSC2', 'STXBP1'"
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
    """Execute gene syndrome similarity query"""
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
            FROM g_aux_syn_topk_v6_0
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
                "syndrome_similarity": round(float(row[1]), 4)
            }
            for row in results
        ]

        return {
            "success": True,
            "query_gene": gene,
            "similar_genes": similar_genes,
            "count": len(similar_genes),
            "fusion_table": "g_aux_syn_topk_v6_0",
            "query_time_ms": round((time.time() - start_time) * 1000, 2),
            "source": "fusion_v6.0",
            "note": "⭐ HIGH VALUE - rare disease syndrome discovery!"
        }

    except Exception as e:
        return {"success": False, "error": str(e), "gene": gene}
