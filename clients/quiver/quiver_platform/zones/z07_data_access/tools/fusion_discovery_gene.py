"""
Fusion Discovery Tool - Gene Multi-Modal Fusion Query

Enables discovery of gene associations across all auxiliary fusion spaces:
- g_aux_cto: Gene → Cell Types
- g_aux_dgp: Gene → Disease-Gene-Protein
- g_aux_ep_drug: Gene → Electrophysiology Drug
- g_aux_mop: Gene → Mechanism of Phenotype
- g_aux_syn: Gene → Syndromes

Architecture:
- Queries 14 fusion tables in PostgreSQL (port 5435)
- Leverages existing FusionQueryEngine from sapphire_fusion_queries_v6_0.py
- Returns cross-modal discoveries
- Integration with Sapphire v3.17 tools

Zone: z07_data_access
Dependencies: FusionQueryEngine, PostgreSQL v6.0 fusion tables
"""
import sys
from pathlib import Path
from typing import Any, Dict, List

# Add paths (go up 7 levels: file -> tools -> z07 -> zones -> quiver_platform -> quiver -> clients -> expo)
project_root = Path(__file__).parent.parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

# Add fusion implementation path
fusion_impl_path = project_root / "clients" / "quiver" / "L6_CNS_Foundation_v1_0" / "implementation"
sys.path.insert(0, str(fusion_impl_path))

# Import existing FusionQueryEngine (REUSE)
try:
    from sapphire_fusion_queries_v6_0 import (
        FusionQueryEngine,
        sapphire_gene_auxiliary_discovery
    )
    FUSION_ENGINE_AVAILABLE = True
except ImportError as e:
    FUSION_ENGINE_AVAILABLE = False
    IMPORT_ERROR = str(e)
except Exception as e:
    FUSION_ENGINE_AVAILABLE = False
    IMPORT_ERROR = f"Unexpected error: {str(e)}"


# Claude Tool Definition
TOOL_DEFINITION = {
    "name": "fusion_discovery_gene",
    "description": """Discover gene associations across 5 auxiliary fusion spaces using multi-modal similarity.

Queries 5 gene auxiliary fusion tables (g_aux_*) to find related entities:
1. **g_aux_cto**: Cell type expression and tissue specificity
2. **g_aux_dgp**: Disease-gene-protein associations
3. **g_aux_ep_drug**: Electrophysiology drug similarities
4. **g_aux_mop**: Mechanism of phenotype links
5. **g_aux_syn**: Syndrome genetics and rare disease genes

**Data:** 4,592,000 fusion pairs across 5 tables (18,368 genes × 50 top-K matches)

**Use cases:**
- Tissue expression: "What cell types express Gene X?"
- Disease association: "What disease-gene-protein links involve Gene X?"
- Drug targeting: "What EP drugs relate to Gene X?"
- Syndrome genetics: "What syndromes associate with Gene X?"

**Returns:** Cross-modal discoveries with similarity scores

Examples:
- fusion_discovery_gene(gene_id="ENSG00000123", fusion_types=["cto", "syn"], top_k=10)
  → Top 10 from cell type and syndrome fusions
- fusion_discovery_gene(gene_id="SCN1A", fusion_types=["all"], top_k=5)
  → Top 5 from all 5 fusion types
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "gene_id": {
                "type": "string",
                "description": "Gene identifier (Ensembl ID or gene symbol). Examples: 'ENSG00000123456', 'SCN1A', 'KCNQ2'"
            },
            "fusion_types": {
                "type": "array",
                "items": {"type": "string", "enum": ["cto", "dgp", "ep_drug", "mop", "syn", "all"]},
                "description": "Which fusion types to query. Use 'all' for all 5. Default: ['all']",
                "default": ["all"]
            },
            "top_k": {
                "type": "integer",
                "description": "Number of results per fusion type (1-50). Default: 10",
                "default": 10,
                "minimum": 1,
                "maximum": 50
            }
        },
        "required": ["gene_id"]
    }
}


def execute(
    gene_id: str,
    fusion_types: List[str] = ["all"],
    top_k: int = 10
) -> Dict[str, Any]:
    """
    Execute gene fusion discovery query.

    Args:
        gene_id: Gene identifier (Ensembl ID or symbol)
        fusion_types: List of fusion types or ["all"]
        top_k: Number of results per fusion type

    Returns:
        Dict with fusion discoveries
    """
    if not FUSION_ENGINE_AVAILABLE:
        error_msg = IMPORT_ERROR if 'IMPORT_ERROR' in globals() else "Unknown import error"
        return {
            "error": "FusionQueryEngine not available",
            "message": f"Cannot import sapphire_fusion_queries_v6_0.py: {error_msg}",
            "status": "unavailable"
        }

    try:
        # Normalize fusion types
        if "all" in fusion_types:
            fusion_types = ["cto", "dgp", "ep_drug", "mop", "syn"]

        # Use existing sapphire_gene_auxiliary_discovery function (REUSE)
        results = sapphire_gene_auxiliary_discovery(gene_id, top_k=top_k)

        # Filter to requested fusion types if not "all"
        if fusion_types != ["cto", "dgp", "ep_drug", "mop", "syn"]:
            if "fusion_discoveries" in results:
                results["fusion_discoveries"] = {
                    k: v for k, v in results["fusion_discoveries"].items()
                    if k in fusion_types
                }

        # Add metadata
        results["metadata"] = {
            "fusion_types_queried": fusion_types,
            "top_k": top_k,
            "total_fusion_tables": 5,
            "total_fusion_pairs": 4592000,
            "architecture": "PostgreSQL v6.0 fusion tables"
        }

        return results

    except Exception as e:
        return {
            "error": str(e),
            "gene_id": gene_id,
            "status": "error"
        }


if __name__ == "__main__":
    # Example usage
    result = execute("SCN1A", fusion_types=["cto", "syn"], top_k=5)
    print(result)
