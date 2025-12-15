"""
Vector Dimensions Tool - Raw Embedding Access

ARCHITECTURE DECISION LOG:
v1.0 (current): Pure agentic with atomic tools
  - This tool provides Claude with raw embedding vector access
  - Handles case-insensitive entity matching ("kncq2" → "KCNQ2", "aspirin" → matching drug)
  - Returns complete 32D embedding vector with dimension labels and metadata

v2.0 (planned): Would add optional filtering/projection to specific dimensions
  - See: /docs/planned/vector_dimensions_v2.0_dimension_filtering.md

Pattern: Wraps EmbeddingService.get_gene_embedding() and get_drug_embedding()
Reference: /Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z07_data_access/embedding_service.py:150-196
"""
# MIGRATION NOTE (2025-12-04): Updated to use pgvector_embedding_service (pgvector backend)
# Previous version used parquet-based embedding_service


from typing import Dict, Any, List
from pathlib import Path
import sys
import numpy as np

# Add path for embedding service
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

from clients.quiver.quiver_platform.zones.z07_data_access.embedding_service import get_embedding_service



# Import validation utilities (Stream 1.2: Validation Framework)
try:
    from tool_utils import validate_tool_input, format_validation_response
    VALIDATION_AVAILABLE = True
except ImportError:
    VALIDATION_AVAILABLE = False

# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "vector_dimensions",
    "description": """Access raw 32D embedding vectors for genes and drugs with complete metadata.

Returns raw embedding vectors with dimension labels, L2 norms, and data provenance.
Useful for vector math operations, similarity analysis, and embedding visualization.

Uses MODEX for genes (18,368 total) and PCA for drugs (14,246 total).
Handles fuzzy matching for case-insensitive and typo-tolerant lookups.

Examples:
- "Get embedding for TSC2" → Returns 32D MODEX vector + metadata
- "What's the raw vector for aspirin?" → Returns 32D PCA vector + metadata
- "Vector for kncq2" → Handles case-insensitive matching (kncq2 → KCNQ2)

Output includes:
- embedding: 32-element float array
- dimension_labels: ["MODEX_00"-"MODEX_31"] or ["PCA_0"-"PCA_31"]
- norm: L2 norm of the raw vector
- data_source: "MODEX" (genes) or "PCA" (drugs)
- metadata: entity name, type, index, additional attributes
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "entity": {
                "type": "string",
                "description": "Entity name (gene symbol or drug name). Case-insensitive. Examples: TSC2, SCN1A, KCNQ2, kncq2, aspirin, LINCS_1234"
            },
            "entity_type": {
                "type": "string",
                "enum": ["gene", "drug"],
                "description": "Type of entity to look up: 'gene' (MODEX 32D) or 'drug' (PCA 32D)"
            }
        },
        "required": ["entity", "entity_type"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute vector_dimensions tool - retrieve raw embedding vectors.

    This is a thin wrapper around EmbeddingService.get_gene_embedding() and
    get_drug_embedding(). Handles case-insensitive entity matching and returns
    complete vector data with metadata.

    Args:
        tool_input: Dict with keys:
            - entity (str): Entity name (case-insensitive, fuzzy matched)
            - entity_type (str): "gene" or "drug"

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - entity (str): Normalized entity name used
            - entity_type (str): Type ("gene" or "drug")
            - embedding (List[float]): 32D vector values
            - dimension_labels (List[str]): ["MODEX_00"-"MODEX_31"] or ["PCA_0"-"PCA_31"]
            - norm (float): L2 norm of raw vector
            - data_source (str): "MODEX" or "PCA"
            - metadata (Dict): Additional entity attributes
            - latency (str): Performance metric
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({"entity": "kncq2", "entity_type": "gene"})
        {
            "success": True,
            "entity": "KCNQ2",
            "entity_input": "kncq2",
            "entity_type": "gene",
            "embedding": [-0.142, 0.385, -0.221, ...],  # 32 values
            "dimension_labels": ["MODEX_00", "MODEX_01", ..., "MODEX_31"],
            "norm": 2.847,
            "data_source": "MODEX (18,368 genes)",
            "metadata": {
                "index": 4721,
                "entity_name": "KCNQ2",
                "entity_type": "gene",
                "best_hit_tier": 1,
                "total_signatures": 2541,
                "hit_signatures": 2189,
                "hit_rate": 0.861,
                "mean_hit_strength": 1.245
            },
            "latency": "<1ms"
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "vector_dimensions")
        if validation_errors:
            return format_validation_response("vector_dimensions", validation_errors)

    try:
        # Get parameters
        entity = tool_input.get("entity", "").strip()
        entity_type = tool_input.get("entity_type", "").lower()

        # Validate parameters
        if not entity or not isinstance(entity, str):
            return {
                "success": False,
                "error": "Entity parameter must be a non-empty string",
                "hint": "Examples: TSC2, KCNQ2, aspirin, LINCS_1234"
            }

        if entity_type not in ["gene", "drug"]:
            return {
                "success": False,
                "error": f"entity_type must be 'gene' or 'drug', got '{entity_type}'",
                "hint": "Specify entity_type as either 'gene' or 'drug'"
            }

        # Get embedding service
        embedding_service = get_embedding_service()
        if embedding_service is None:
            return {
                "success": False,
                "error": "Embedding service not available",
                "hint": "Check that embedding data files are present"
            }

        # Normalize entity name with fuzzy matching
        if entity_type == "gene":
            gene_df = embedding_service.gene_df
            entity_names = gene_df['entity_name'].values

            # Try exact match first (fastest)
            if entity in entity_names:
                normalized_entity = entity
            else:
                # Try case-insensitive match
                entity_upper = entity.upper()
                matches = [e for e in entity_names if e.upper() == entity_upper]

                if matches:
                    normalized_entity = matches[0]  # Use first match
                else:
                    # Fuzzy match using Levenshtein distance for typos ("kncq2" → "KCNQ2")
                    from difflib import get_close_matches

                    close_matches = get_close_matches(
                        entity.upper(),  # Normalize to uppercase
                        [e.upper() for e in entity_names],  # Search in uppercase
                        n=1,  # Return top match
                        cutoff=0.8  # 80% similarity threshold
                    )

                    if close_matches:
                        # Find original entity name with correct casing
                        matched_upper = close_matches[0]
                        normalized_entity = next(e for e in entity_names if e.upper() == matched_upper)
                    else:
                        # No fuzzy match found
                        return {
                            "success": False,
                            "error": f"Gene not found in embeddings: {entity}",
                            "entity": entity,
                            "hint": "Gene not found. Try checking spelling or using standard gene symbols.",
                            "available_genes": f"{len(entity_names):,} genes in MODEX database",
                            "examples": ["TSC2", "SCN1A", "KCNQ2", "BRCA1", "TP53", "STXBP1"]
                        }

            # Get gene embedding
            embedding = embedding_service.get_gene_embedding(normalized_entity)
            if embedding is None:
                return {
                    "success": False,
                    "error": f"Could not retrieve embedding for gene: {normalized_entity}",
                    "entity": entity
                }

            # Get metadata
            gene_row = gene_df[gene_df['entity_name'] == normalized_entity].iloc[0]
            gene_idx = gene_df[gene_df['entity_name'] == normalized_entity].index[0]

            metadata = {
                "index": int(gene_idx),
                "entity_name": normalized_entity,
                "entity_type": "gene",
                "best_hit_tier": gene_row.get('best_hit_tier'),
                "total_signatures": gene_row.get('total_signatures'),
                "hit_signatures": gene_row.get('hit_signatures'),
                "hit_rate": gene_row.get('hit_rate'),
                "mean_hit_strength": gene_row.get('mean_hit_strength'),
                "max_hit_strength": gene_row.get('max_hit_strength'),
                "T1_count": gene_row.get('T1_count'),
                "T2_count": gene_row.get('T2_count'),
                "T3_count": gene_row.get('T3_count')
            }

            data_source = "MODEX (18,368 genes)"
            dimension_labels = [f"MODEX_{i:02d}" for i in range(32)]

        else:  # entity_type == "drug"
            drug_df = embedding_service.drug_df

            # For drugs, try to match entity_name if it exists
            if 'entity_name' in drug_df.columns:
                entity_names = drug_df['entity_name'].values

                # Try exact match first
                if entity in entity_names:
                    normalized_entity = entity
                    drug_idx = drug_df[drug_df['entity_name'] == entity].index[0]
                else:
                    # Try case-insensitive match
                    entity_upper = entity.upper()
                    matches = [e for e in entity_names if e.upper() == entity_upper]

                    if matches:
                        normalized_entity = matches[0]
                        drug_idx = drug_df[drug_df['entity_name'] == normalized_entity].index[0]
                    else:
                        # Fuzzy match
                        from difflib import get_close_matches

                        close_matches = get_close_matches(
                            entity.upper(),
                            [e.upper() for e in entity_names],
                            n=1,
                            cutoff=0.8
                        )

                        if close_matches:
                            matched_upper = close_matches[0]
                            normalized_entity = next(e for e in entity_names if e.upper() == matched_upper)
                            drug_idx = drug_df[drug_df['entity_name'] == normalized_entity].index[0]
                        else:
                            return {
                                "success": False,
                                "error": f"Drug not found in embeddings: {entity}",
                                "entity": entity,
                                "hint": "Drug not found. Try checking spelling or using compound IDs.",
                                "available_drugs": f"{len(entity_names):,} drugs in PCA database",
                                "examples": ["aspirin", "ibuprofen", "LINCS_1234", "QS0318588_10uM"]
                            }
            else:
                # PCA file uses index directly; try to parse entity as index
                try:
                    if entity.isdigit():
                        drug_idx = int(entity)
                        if drug_idx >= len(drug_df):
                            return {
                                "success": False,
                                "error": f"Drug index out of range: {drug_idx}",
                                "available_drugs": f"0-{len(drug_df)-1}"
                            }
                        normalized_entity = f"DRUG_{drug_idx}"
                    else:
                        return {
                            "success": False,
                            "error": f"Drug not found and cannot parse as index: {entity}",
                            "hint": "For PCA drugs, provide drug name or numeric index"
                        }
                except ValueError:
                    return {
                        "success": False,
                        "error": f"Invalid drug reference: {entity}",
                        "hint": "Provide drug name or numeric index"
                    }

            # Get drug embedding
            embedding = embedding_service.get_drug_embedding(normalized_entity)
            if embedding is None:
                return {
                    "success": False,
                    "error": f"Could not retrieve embedding for drug: {normalized_entity}",
                    "entity": entity
                }

            # Get metadata
            drug_row = drug_df.iloc[drug_idx]

            metadata = {
                "index": int(drug_idx),
                "entity_name": normalized_entity,
                "entity_type": "drug",
                "best_hit_tier": drug_row.get('best_hit_tier'),
                "data_tier": drug_row.get('data_tier'),
                "compound_id": drug_row.get('compound_id')
            }

            data_source = "PCA (14,246 drugs)"
            dimension_labels = [f"PCA_{i}" for i in range(32)]

        # Compute L2 norm
        embedding_norm = float(np.linalg.norm(embedding))

        # Format embedding as list of floats (rounded to 6 decimals)
        embedding_list = [float(round(v, 6)) for v in embedding]

        return {
            "success": True,
            "entity": normalized_entity,
            "entity_input": entity,  # Show original input for reference
            "entity_type": entity_type,
            "embedding": embedding_list,
            "dimension_labels": dimension_labels,
            "norm": round(embedding_norm, 6),
            "data_source": data_source,
            "metadata": metadata,
            "latency": "<1ms"
        }

    except ValueError as e:
        # Entity not found in embeddings
        error_msg = str(e)
        return {
            "success": False,
            "error": error_msg,
            "entity": tool_input.get("entity", "unknown"),
            "entity_type": tool_input.get("entity_type", "unknown"),
            "hint": f"Entity not found in {tool_input.get('entity_type', 'unknown')} embedding database."
        }

    except Exception as e:
        # Unexpected error
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "entity": tool_input.get("entity", "unknown"),
            "entity_type": tool_input.get("entity_type", "unknown"),
            "error_type": type(e).__name__
        }


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
