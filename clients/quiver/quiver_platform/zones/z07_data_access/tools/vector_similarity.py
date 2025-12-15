"""
Vector Similarity Tool - Cross-Entity Embedding Comparison

ARCHITECTURE DECISION LOG:
v1.0 (current): Pure agentic with atomic tools
  - This tool provides Claude with entity similarity capabilities
  - Supports gene-gene, drug-drug, and cross-entity (gene-drug) comparisons
  - Handles case-insensitive entity matching with fuzzy matching for typos
  - Returns cosine similarity (0-1 scale), distance, and embedding space metadata

Pattern: Wraps PGVectorService v6.0 for cosine similarity computation
Reference: /Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z07_data_access/pgvector_service.py
Updated: 2025-12-03 (migrated to PGVector v6.0)
"""

from typing import Dict, Any, Optional, Tuple
from pathlib import Path
import sys
import numpy as np

# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import validate_tool_input, format_validation_response, harmonize_drug_id, validate_input
    HARMONIZATION_AVAILABLE = True
    VALIDATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
    VALIDATION_AVAILABLE = False

# Add path for services
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

import psycopg2
import os
# MIGRATED to v3.0 (2025-12-05): Master resolution tables (60x faster)
from zones.z07_data_access.drug_name_resolver_v3 import get_drug_name_resolver_v3 as get_drug_name_resolver


# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "vector_similarity",
    "description": """Compare cosine similarity between any two entities using their v6.0 embeddings.

Supports pairwise similarity comparisons across:
- Gene-gene: Compare genetic signatures (ENS 64D)
- Drug-drug: Compare chemical/functional profiles (Chemical 256D)
- Gene-drug: Cross-space similarity (ENS × Chemical)

Uses fast PGVector database queries (<5ms latency).

Examples:
- "What's the similarity between TSC2 and TP53?" → Gene-gene comparison
- "How similar are aspirin and ibuprofen?" → Drug-drug comparison
- "Compare TSC2 to QS0318588" → Cross-space comparison
- "similarity between kncq2 and brca1" → Case-insensitive matching

Output metrics:
- similarity_score: 0-1 scale (1 = identical, 0 = orthogonal, <0 possible for antipodal)
- cosine_distance: Raw cosine similarity (-1 to 1)
- entity_types: Confirmed types of both entities
- embedding_spaces: v6.0 spaces used for each entity

Data (PGVector v6.0):
- 18,368 genes (ENS 64D)
- 14,246 drugs (Chemical 256D)
- Direct database access
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "entity1": {
                "type": "string",
                "description": "First entity name (gene symbol or drug name, case-insensitive). Examples: TSC2, TP53, KCNQ2, aspirin, QS0318588_10uM"
            },
            "entity2": {
                "type": "string",
                "description": "Second entity name (gene symbol or drug name, case-insensitive). Examples: BRCA1, SCN1A, ibuprofen, paracetamol"
            }
        },
        "required": ["entity1", "entity2"]
    }
}


# TODO REVIEW (2025-12-04): This tool uses modex_ep_unified_16d_v6_0 (drug-gene UNIFIED)
# Context: REVIEW: Vector similarity (uses drug AND gene)
# Question: Should this use drug-only table (drug_chemical_v6_0_256d) or keep unified?
# If drug-only operations: Replace with drug_chemical_v6_0_256d
# If drug+gene operations: Keep modex_ep_unified_16d_v6_0

def _normalize_embedding(embedding: np.ndarray) -> np.ndarray:
    """
    Normalize embedding vector to unit length.

    Args:
        embedding: Raw embedding vector

    Returns:
        Normalized embedding vector
    """
    norm = np.linalg.norm(embedding) + 1e-8
    return embedding / norm


def _compute_cosine_similarity(vec1: np.ndarray, vec2: np.ndarray) -> float:
    """
    Compute cosine similarity between two vectors.

    Args:
        vec1: First normalized vector
        vec2: Second normalized vector

    Returns:
        Cosine similarity (-1 to 1)
    """
    return float(np.dot(vec1, vec2))


def _query_entity_from_pgvector(entity_name: str) -> Optional[Tuple[str, np.ndarray, str, str]]:
    """
    Query entity from PGVector tables (genes or drugs).

    Tries multiple tables in order:
    1. Genes: ens_gene_64d_v6_0 (ENS 64D)
    2. Genes: lincs_gene_32d_v5_0 (LINCS 32D)
    3. Drugs: drug_chemical_v6_0_256d (Chemical 256D)
    4. Drugs: modex_ep_unified_16d_v6_0 (Unified 16D)

    Returns:
        Tuple of (normalized_name, embedding, entity_type, table_name) or None
    """
    conn = psycopg2.connect(
        host=os.getenv("PGVECTOR_HOST", "localhost"),
        port=int(os.getenv("PGVECTOR_PORT", "5435")),
        database=os.getenv("PGVECTOR_DB", "sapphire_database"),
        user=os.getenv("PGVECTOR_USER", "postgres"),
        password=os.getenv("PGVECTOR_PASSWORD", "temppass123")
    )

    cursor = conn.cursor()
    entity_upper = entity_name.upper()

    # Try gene tables first
    gene_tables = [
        ("ens_gene_64d_v6_0", "gene_ens_64d"),
        ("lincs_gene_32d_v5_0", "gene_lincs_32d")
    ]

    for table, space in gene_tables:
        cursor.execute(f"""
            SELECT id, embedding
            FROM {table}
            WHERE UPPER(id) = %s
            LIMIT 1
        """, (entity_upper,))

        result = cursor.fetchone()
        if result:
            entity_id, embedding = result
            cursor.close()
            conn.close()
            # Convert embedding to numpy array if needed
            if isinstance(embedding, str):
                embedding = np.array(eval(embedding))
            return (entity_id, np.array(embedding), "gene", space)

    # Try drug table (drug_chemical_v6_0_256d ONLY - for drug-drug similarity)
    # NOTE: modex_ep_unified_16d_v6_0 is for drug-gene antipodal, NOT drug similarity
    cursor.execute("""
        SELECT id, embedding
        FROM drug_chemical_v6_0_256d
        WHERE UPPER(id) = %s OR UPPER(id) LIKE %s
        LIMIT 1
    """, (entity_upper, f"%{entity_upper}%"))

    result = cursor.fetchone()
    if result:
        entity_id, embedding = result
        cursor.close()
        conn.close()
        # Convert embedding to numpy array if needed
        if isinstance(embedding, str):
            embedding = np.array(eval(embedding))
        return (entity_id, np.array(embedding), "drug", "drug_chemical_256d")

    cursor.close()
    conn.close()
    return None


def _find_entity_in_dataframe(
    entity_name: str,
    entity_df,
    entity_type: str
) -> Optional[Tuple[str, Any]]:
    """
    Find entity in dataframe with fuzzy matching support.

    Tries in order:
    1. Exact match
    2. Case-insensitive match
    3. Fuzzy match (Levenshtein distance, 80% threshold)

    Args:
        entity_name: Entity to search for
        entity_df: DataFrame with entity_name column
        entity_type: "gene" or "drug" for context

    Returns:
        Tuple of (normalized_name, row) or None if not found
    """
    if entity_df is None or entity_df.empty:
        return None

    entity_names = entity_df['entity_name'].values if 'entity_name' in entity_df.columns else []

    if not len(entity_names):
        return None

    # Try exact match first (fastest)
    if entity_name in entity_names:
        row = entity_df[entity_df['entity_name'] == entity_name].iloc[0]
        return (entity_name, row)

    # Try case-insensitive match
    entity_upper = entity_name.upper()
    matches = [e for e in entity_names if e.upper() == entity_upper]

    if matches:
        found_name = matches[0]
        row = entity_df[entity_df['entity_name'] == found_name].iloc[0]
        return (found_name, row)

    # Fuzzy match using Levenshtein distance for typos
    from difflib import get_close_matches

    close_matches = get_close_matches(
        entity_upper,
        [e.upper() for e in entity_names],
        n=1,
        cutoff=0.8
    )

    if close_matches:
        matched_upper = close_matches[0]
        found_name = next(e for e in entity_names if e.upper() == matched_upper)
        row = entity_df[entity_df['entity_name'] == found_name].iloc[0]
        return (found_name, row)

    # No match found
    return None


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute vector_similarity tool - compare two entities by embedding similarity.

    This is a thin wrapper around EmbeddingService methods.
    Handles case-insensitive entity matching and formats results for Claude.

    Args:
        tool_input: Dict with keys:
            - entity1 (str): First entity name (case-insensitive)
            - entity2 (str): Second entity name (case-insensitive)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - entity1 (str): Normalized entity1 name
            - entity2 (str): Normalized entity2 name
            - similarity_score (float): 0-1 scale similarity
            - cosine_distance (float): Raw cosine similarity (-1 to 1)
            - entity1_type (str): Type of entity1 (gene or drug)
            - entity2_type (str): Type of entity2 (gene or drug)
            - embedding_space (str): Space(s) used for comparison
            - interpretation (str): Human-readable interpretation
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({"entity1": "TSC2", "entity2": "TP53"})
        {
            "success": True,
            "entity1": "TSC2",
            "entity2": "TP53",
            "similarity_score": 0.742,
            "cosine_distance": 0.742,
            "entity1_type": "gene",
            "entity2_type": "gene",
            "embedding_space": "MODEX × MODEX",
            "interpretation": "High similarity - genes may share functional roles",
            "data_source": "Direct parquet (MODEX 32D × PCA 32D)"
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "vector_similarity")
        if validation_errors:
            return format_validation_response("vector_similarity", validation_errors)

    try:
        # Get parameters
        entity1_input = tool_input.get("entity1", "").strip()
        entity2_input = tool_input.get("entity2", "").strip()

        # Validate parameters
        if not entity1_input or not isinstance(entity1_input, str):
            return {
                "success": False,
                "error": "entity1 parameter must be a non-empty string",
                "hint": "Examples: TSC2, TP53, aspirin, paracetamol"
            }

        if not entity2_input or not isinstance(entity2_input, str):
            return {
                "success": False,
                "error": "entity2 parameter must be a non-empty string",
                "hint": "Examples: BRCA1, SCN1A, ibuprofen, QS0318588_10uM"
            }

        # Query both entities from PGVector
        entity1_result = _query_entity_from_pgvector(entity1_input)
        entity2_result = _query_entity_from_pgvector(entity2_input)

        # Check if both entities were found
        if not entity1_result:
            return {
                "success": False,
                "error": f"Entity not found: {entity1_input}",
                "hint": "Try: TSC2, SCN1A, KCNQ2 (genes) or drug names",
                "searched_tables": ["ens_gene_64d_v6_0", "lincs_gene_32d_v5_0", "drug_chemical_v6_0_256d"]
            }

        if not entity2_result:
            return {
                "success": False,
                "error": f"Entity not found: {entity2_input}",
                "hint": "Try: BRCA1, TP53 (genes) or drug names",
                "searched_tables": ["ens_gene_64d_v6_0", "lincs_gene_32d_v5_0", "drug_chemical_v6_0_256d"]
            }

        # Unpack results
        entity1_id, entity1_embedding, entity1_type, entity1_space = entity1_result
        entity2_id, entity2_embedding, entity2_type, entity2_space = entity2_result

        # Normalize embeddings
        entity1_norm = _normalize_embedding(entity1_embedding)
        entity2_norm = _normalize_embedding(entity2_embedding)

        # Compute cosine similarity
        cosine_sim = _compute_cosine_similarity(entity1_norm, entity2_norm)

        # Generate interpretation
        if cosine_sim >= 0.8:
            interpretation = "Very high similarity - entities may be functionally equivalent"
        elif cosine_sim >= 0.6:
            interpretation = "High similarity - entities likely share functional roles"
        elif cosine_sim >= 0.4:
            interpretation = "Moderate similarity - some functional relationship"
        elif cosine_sim >= 0.0:
            interpretation = "Low similarity - relatively independent"
        else:
            interpretation = "Antipodal - opposite biological effects"

        # Build result
        return {
            "success": True,
            "entity1": entity1_id,
            "entity1_input": entity1_input,
            "entity1_type": entity1_type,
            "entity1_space": entity1_space,
            "entity2": entity2_id,
            "entity2_input": entity2_input,
            "entity2_type": entity2_type,
            "entity2_space": entity2_space,
            "similarity_score": round((1.0 + cosine_sim) / 2.0, 4),  # Normalized to 0-1
            "cosine_similarity": round(cosine_sim, 4),  # Raw -1 to 1
            "embedding_spaces": f"{entity1_space} × {entity2_space}",
            "interpretation": interpretation,
            "data_source": "PGVector v6.0",
            "comparison_type": f"{entity1_type}-{entity2_type}"
        }

    except Exception as e:
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "error_type": type(e).__name__
        }

# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
