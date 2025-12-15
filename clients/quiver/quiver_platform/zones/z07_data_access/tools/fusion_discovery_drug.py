"""
Fusion Discovery Tool - Drug Multi-Modal Fusion Query

Enables discovery of drug associations across all auxiliary fusion spaces:
- d_aux_adr: Drug → Adverse Drug Reactions
- d_aux_cto: Drug → Cell Types
- d_aux_dgp: Drug → Disease-Gene-Protein
- d_aux_ep_drug: Drug → Electrophysiology
- d_aux_mop: Drug → Mechanism of Phenotype

Architecture:
- Queries 14 fusion tables in PostgreSQL (port 5435)
- Leverages existing FusionQueryEngine from sapphire_fusion_queries_v6_0.py
- Returns consensus rankings across fusion types
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
        sapphire_drug_gene_discovery
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
    "name": "fusion_discovery_drug",
    "description": """Discover drug associations across 5 auxiliary fusion spaces using multi-modal similarity.

Queries 5 drug auxiliary fusion tables (d_aux_*) to find related entities:
1. **d_aux_adr**: Adverse drug reactions and safety signals
2. **d_aux_cto**: Cell type specificity and tissue targeting
3. **d_aux_dgp**: Disease-gene-protein mechanisms
4. **d_aux_ep_drug**: Electrophysiology and ion channel effects
5. **d_aux_mop**: Mechanism of phenotype associations

**Data:** 3,561,500 fusion pairs across 5 tables (14,246 drugs × 50 top-K matches)

**Use cases:**
- Safety assessment: "What ADRs are similar to Drug X?"
- Tissue targeting: "What cell types does Drug X affect?"
- Mechanism discovery: "What phenotype mechanisms relate to Drug X?"
- EP profiling: "What ion channel effects does Drug X have?"

**Returns:** Consensus ranking across all fusion types with similarity scores

Examples:
- fusion_discovery_drug(drug_id="CHEMBL123", fusion_types=["adr", "mop"], top_k=10)
  → Top 10 entities from ADR and MOP fusions
- fusion_discovery_drug(drug_id="Aspirin", fusion_types=["all"], top_k=5)
  → Top 5 from all 5 fusion types with consensus ranking
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "drug_id": {
                "type": "string",
                "description": "Drug identifier (ChEMBL ID or drug name). Examples: 'CHEMBL123', 'Aspirin', 'Levetiracetam'"
            },
            "fusion_types": {
                "type": "array",
                "items": {"type": "string", "enum": ["adr", "cto", "dgp", "ep_drug", "mop", "all"]},
                "description": "Which fusion types to query. Use 'all' for consensus across all 5. Default: ['all']",
                "default": ["all"]
            },
            "top_k": {
                "type": "integer",
                "description": "Number of results per fusion type (1-50). Default: 10",
                "default": 10,
                "minimum": 1,
                "maximum": 50
            },
            "consensus_ranking": {
                "type": "boolean",
                "description": "Return consensus ranking across fusion types (aggregated scores). Default: true",
                "default": True
            }
        },
        "required": ["drug_id"]
    }
}


def execute(
    drug_id: str,
    fusion_types: List[str] = ["all"],
    top_k: int = 10,
    consensus_ranking: bool = True
) -> Dict[str, Any]:
    """
    Execute drug fusion discovery query.

    Args:
        drug_id: Drug identifier (ChEMBL ID or name)
        fusion_types: List of fusion types or ["all"]
        top_k: Number of results per fusion type
        consensus_ranking: Whether to return consensus ranking

    Returns:
        Dict with fusion discoveries and consensus ranking
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
            fusion_types = ["adr", "cto", "dgp", "ep_drug", "mop"]

        # Use existing sapphire_drug_gene_discovery function (REUSE)
        if consensus_ranking:
            results = sapphire_drug_gene_discovery(drug_id, top_k=top_k)
        else:
            # Query individual fusion types
            engine = FusionQueryEngine()
            try:
                results = {
                    "drug_id": drug_id,
                    "fusion_discoveries": {}
                }

                for fusion_type in fusion_types:
                    if fusion_type in ["adr", "cto", "dgp", "ep_drug", "mop"]:
                        fusion_results = engine.find_similar_genes_for_drug(
                            drug_id, fusion_type, top_k
                        )
                        results["fusion_discoveries"][fusion_type] = fusion_results
            finally:
                engine.close()

        # Add metadata
        results["metadata"] = {
            "fusion_types_queried": fusion_types,
            "top_k": top_k,
            "consensus_ranking": consensus_ranking,
            "total_fusion_tables": 5,
            "total_fusion_pairs": 3561500,
            "architecture": "PostgreSQL v6.0 fusion tables"
        }

        return results

    except Exception as e:
        return {
            "error": str(e),
            "drug_id": drug_id,
            "status": "error"
        }


if __name__ == "__main__":
    # Example usage
    result = execute("CHEMBL123", fusion_types=["adr", "mop"], top_k=5)
    print(result)
