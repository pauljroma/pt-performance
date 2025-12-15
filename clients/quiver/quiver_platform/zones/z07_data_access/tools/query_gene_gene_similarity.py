"""
Query Gene-Gene Similarity - Atomic Fusion Table Wrapper

Queries g_g_ens_lincs_topk_v6_0 fusion table for similar genes via ENS × LINCS fusion.

Purpose:
- Gene similarity baseline: Find functionally similar genes
- Rare disease gene discovery: Identify candidate genes for undiagnosed patients
- Pathway analysis: Genes in similar biological pathways

Architecture:
- Direct query to pre-computed g_g_ens_lincs_topk_v6_0 fusion table (1-5ms)
- Returns top-K genes ranked by ENS × LINCS similarity (0.0-1.0)

Data: 918,400 pre-computed pairs (18,368 genes × 50 neighbors)
Note: Different from g_g_1__ens__lincs (96D fusion) - this is topk_v6_0 optimized table

Author: Swarm Agent 014 - Atomic Fusion Wrappers v1
Created: 2025-12-04
Zone: z07_data_access/tools
Version: v1.0
"""

from typing import Dict, Any
import os
import time
import psycopg2

TOOL_DEFINITION = {
    "name": "query_gene_gene_similarity",
    "description": """Find similar genes using ENS × LINCS fusion table.

**Performance:** 1-5ms queries using g_g_ens_lincs_topk_v6_0 fusion table

**Use Cases:**
- Gene similarity baseline: "What genes are functionally similar to SCN1A?"
- Rare disease discovery: "Find candidate genes for Dravet-like patients without SCN1A mutation"
- Pathway analysis: "Genes in similar biological pathways to TSC2"
- Drug repurposing: "If drug works for SCN1A, try these similar genes"

**Similarity Score:**
- 1.0 = Identical gene
- 0.9+ = Highly similar (functional homologs)
- 0.7-0.9 = Moderately similar (pathway overlap)
- <0.7 = Low similarity

**Data:** 918,400 pre-computed pairs (18,368 genes × 50 top neighbors)

**Note:** This uses g_g_ens_lincs_topk_v6_0 (optimized fusion table), different from
g_g_1__ens__lincs (96D combined embedding). Both are valid, this is faster for top-K queries.

**Examples:**
- query_gene_gene_similarity(gene="SCN1A", top_k=10) → SCN2A, SCN3A, SCN9A (Na+ channels)
- query_gene_gene_similarity(gene="TSC2", top_k=20) → TSC1, mTOR pathway genes
- query_gene_gene_similarity(gene="STXBP1", top_k=15) → DEE-associated genes

Performance: ~1-5ms per query""",
    "input_schema": {
        "type": "object",
        "properties": {
            "gene": {
                "type": "string",
                "description": "Gene symbol (case-insensitive). Examples: 'SCN1A', 'TSC2', 'KCNQ2'"
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
                "description": "Minimum similarity threshold (0.0-1.0). Default: 0.0 (no filtering)",
                "default": 0.0,
                "minimum": 0.0,
                "maximum": 1.0
            }
        },
        "required": ["gene"]
    }
}


async def execute(params: Dict[str, Any]) -> Dict[str, Any]:
    """Execute gene-gene similarity query"""
    start_time = time.time()

    gene = params.get("gene", "").strip().upper()
    top_k = params.get("top_k", 10)
    min_similarity = params.get("min_similarity", 0.0)  # Changed from 0.7 to 0.0 to fix TSC2 issue

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
            FROM g_g_ens_lincs_topk_v6_0
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
                "similarity_score": round(float(row[1]), 4)
            }
            for row in results
        ]

        return {
            "success": True,
            "query_gene": gene,
            "similar_genes": similar_genes,
            "count": len(similar_genes),
            "fusion_table": "g_g_ens_lincs_topk_v6_0",
            "query_time_ms": round((time.time() - start_time) * 1000, 2),
            "source": "fusion_v6.0",
            "note": "Atomic wrapper for topk_v6_0 fusion table (optimized for speed)"
        }

    except Exception as e:
        return {"success": False, "error": str(e), "gene": gene}
