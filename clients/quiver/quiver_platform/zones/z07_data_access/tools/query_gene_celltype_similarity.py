"""
Query Gene Cell Type Similarity - Atomic Fusion Table Wrapper

Queries g_aux_cto_topk_v6_0 fusion table for genes with similar cell-type expression profiles.

Purpose:
- Cell-type specific gene expression: Find genes expressed in similar cell populations
- Tissue targeting: Identify genes for cell-type specific therapies
- Development biology: Genes with similar cell lineage patterns

Architecture:
- Direct query to pre-computed g_aux_cto_topk_v6_0 fusion table (1-5ms)
- Returns top-K genes ranked by cell-type similarity (0.0-1.0)

Data: 918,400 pre-computed pairs (18,368 genes × 50 neighbors)
Note: Currently used by demeo_drug_rescue - now standalone atomic access!

Author: Swarm Agent 006 - Atomic Fusion Wrappers v1
Created: 2025-12-04
Zone: z07_data_access/tools
Version: v1.0
"""

from typing import Dict, Any
import os
import time
import psycopg2

TOOL_DEFINITION = {
    "name": "query_gene_celltype_similarity",
    "description": """Find genes with similar cell-type expression profiles using pre-computed fusion table.

**Performance:** 1-5ms queries using g_aux_cto_topk_v6_0 fusion table

**Use Cases:**
- Cell-type specific expression: "What genes have similar neuron-specific expression to SCN1A?"
- Tissue targeting: "Find genes expressed in glioblastoma-like cell types"
- Development: "Genes with similar embryonic cell-type patterns"
- CNS specificity: "Genes co-expressed in similar brain regions"

**Similarity Score:**
- 1.0 = Identical cell-type expression
- 0.9+ = Highly similar tissue specificity
- 0.7-0.9 = Moderately similar cell populations
- <0.7 = Low cell-type overlap

**Data:** 918,400 pre-computed pairs (18,368 genes × 50 top neighbors)

**Examples:**
- query_gene_celltype_similarity(gene="SCN1A", top_k=10) → Neuron-specific genes
- query_gene_celltype_similarity(gene="TSC2", top_k=20) → mTOR pathway cell types

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
    """Execute gene cell-type similarity query"""
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
            FROM g_aux_cto_topk_v6_0
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
                "celltype_similarity": round(float(row[1]), 4)
            }
            for row in results
        ]

        return {
            "success": True,
            "query_gene": gene,
            "similar_genes": similar_genes,
            "count": len(similar_genes),
            "fusion_table": "g_aux_cto_topk_v6_0",
            "query_time_ms": round((time.time() - start_time) * 1000, 2),
            "source": "fusion_v6.0",
            "note": "Now atomic - previously buried in demeo_drug_rescue"
        }

    except Exception as e:
        return {"success": False, "error": str(e), "gene": gene}
