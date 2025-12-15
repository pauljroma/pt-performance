"""
Drug Lookalikes Tool - Patent Workaround Detection

ARCHITECTURE DECISION LOG:
v1.0 (current): Pure agentic with atomic tools
  - This tool provides Claude with drug lookalike discovery capabilities
  - Finds compounds with similar therapeutic effects but different structures
  - Supports patent workaround strategy identification
  - Primary source: Neo4j LOOKALIKE relationships
  - Fallback: PCA_v4_7 drug embedding similarity

Pattern: Wraps Neo4j LOOKALIKE queries with embedding similarity fallback
Reference: /Users/expo/Code/expo/scripts/neo4j_import/12_load_drug_lookalike_edges.py
"""
# MIGRATION NOTE (2025-12-04): Updated to use pgvector_embedding_service (pgvector backend)
# Previous version used parquet-based embedding_service


from typing import Dict, Any, List, Optional
from pathlib import Path
import sys
import os
import logging
import numpy as np

# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import harmonize_drug_id, validate_input, validate_tool_input, format_validation_response
    HARMONIZATION_AVAILABLE = True
    VALIDATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
    VALIDATION_AVAILABLE = False

logger = logging.getLogger(__name__)

# Add path for dependencies
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

# MIGRATED to v3.0 (2025-12-05): Master resolution tables (60x faster)
from zones.z07_data_access.drug_name_resolver_v3 import get_drug_name_resolver_v3 as get_drug_name_resolver


# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "drug_lookalikes",
    "description": """Find drug lookalikes (similar compounds) for patent workaround strategies.

A "lookalike" drug is one that has:
- HIGH disease/therapeutic effect similarity (works the same way)
- LOW structural similarity (chemically different)
= PATENT WORKAROUND POTENTIAL (same therapeutic effect, different structure)

This tool identifies alternative compounds that could bypass patent restrictions while
maintaining similar therapeutic effects. Critical for drug rescue, repurposing, and
cost reduction strategies.

Examples:
- "Find lookalikes for Metformin" → Returns structurally different drugs with similar anti-diabetic effects
- "What are patent workaround candidates for Aspirin?" → Returns alternative anti-inflammatory compounds
- "Show me drugs similar to QS0318588" → Supports both QS codes and commercial names

Data Sources:
1. Neo4j LOOKALIKE relationships (if available) - precomputed with patent potential ratings
2. PCA_v4_7 drug embeddings (fallback) - real-time similarity computation

Key metrics:
- similarity_score: 0-1 scale (1 = identical therapeutic effect)
- structural_similarity: 0-1 scale (lower = more structurally different)
- patent_potential: HIGH/MEDIUM rating based on similarity gap
- source: "neo4j_lookalike" or "embedding_similarity"

Use Cases:
- Patent workaround identification
- Drug rescue strategies (find alternatives to failed/expensive drugs)
- Cost reduction (find similar generics)
- Portfolio expansion (identify adjacent therapeutic opportunities)
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "drug": {
                "type": "string",
                "description": "Drug identifier in any format: Drug name, ChEMBL ID (CHEMBL1234), RxNorm ID (1234567), or LINCS ID (BRD-K...)."
            },
            "similarity_threshold": {
                "type": "number",
                "description": "Minimum similarity threshold for lookalikes (0.7-0.99). Default: 0.85. Higher = more similar therapeutic effect.",
                "default": 0.85,
                "minimum": 0.7,
                "maximum": 0.99
            },
            "max_results": {
                "type": "integer",
                "description": "Maximum number of lookalike drugs to return (1-50). Default: 10",
                "default": 10,
                "minimum": 1,
                "maximum": 50
            },
            "include_approved_only": {
                "type": "boolean",
                "description": "Filter to FDA-approved drugs only. Default: False (includes investigational compounds)",
                "default": False
            }
        },
        "required": ["drug"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute drug_lookalikes tool - find similar compounds for patent workaround.

    This tool helps identify alternative drugs with similar therapeutic effects
    but different chemical structures, useful for patent workaround strategies.

    Args:
        tool_input: Dict with keys:
            - drug (str): Drug ID (QS code) or commercial name
            - similarity_threshold (float, optional): Minimum similarity (default: 0.85)
            - max_results (int, optional): Max results to return (default: 10)
            - include_approved_only (bool, optional): Filter to approved drugs (default: False)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - drug (str): Normalized drug identifier used for query
            - drug_input (str): Original input drug name
            - commercial_name (str): Resolved commercial name of query drug
            - lookalikes (List[Dict]): List of lookalike drugs with metadata
            - count (int): Number of lookalikes found
            - data_source (str): Data source used ("neo4j_lookalike" or "embedding_similarity")
            - strategy_note (str): Strategic interpretation of results
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({"drug": "Metformin", "max_results": 5})
        {
            "success": True,
            "drug": "QS0318588",
            "drug_input": "Metformin",
            "commercial_name": "Metformin",
            "lookalikes": [
                {
                    "drug_id": "QS0318600",
                    "commercial_name": "Phenformin",
                    "similarity_score": 0.92,
                    "structural_similarity": 0.35,
                    "patent_potential": "HIGH",
                    "similarity_gap": 0.57,
                    "source": "neo4j_lookalike"
                },
                ...
            ],
            "count": 5,
            "data_source": "neo4j_lookalike",
            "strategy_note": "Found 5 patent workaround candidates. HIGH potential drugs have >0.5 gap..."
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "drug_lookalikes")
        if validation_errors:
            return format_validation_response("drug_lookalikes", validation_errors)

    try:
        # Get parameters with defaults
        drug = tool_input.get("drug", "").strip()

        # STREAM 1: Identifier harmonization
        harmonization_note = None
        drug_normalized = drug

        if HARMONIZATION_AVAILABLE:
            # Try harmonization (handles ChEMBL IDs, RxNorm IDs, LINCS IDs)
            harmonized = harmonize_drug_id(drug)
            if harmonized["success"]:
                # Use ChEMBL ID if available (most tools use ChEMBL)
                if harmonized.get("chembl_id"):
                    drug_chembl_id = harmonized["chembl_id"]
                    harmonization_note = f"Harmonized {harmonized['id_type_detected']} → ChEMBL"
                # Or use the drug name
                if harmonized.get("drug_name"):
                    drug_normalized = harmonized["drug_name"]
        similarity_threshold = tool_input.get("similarity_threshold", 0.85)
        max_results = tool_input.get("max_results", 10)
        include_approved_only = tool_input.get("include_approved_only", False)

        # Validate parameters
        if not drug or not isinstance(drug, str):
            return {
                "success": False,
                "error": "drug parameter must be a non-empty string",
                "hint": "Examples: 'Metformin', 'QS0318588', 'Aspirin'"
            }

        if not (0.7 <= similarity_threshold <= 0.99):
            return {
                "success": False,
                "error": f"similarity_threshold must be between 0.7 and 0.99, got {similarity_threshold}"
            }

        if not (1 <= max_results <= 50):
            return {
                "success": False,
                "error": f"max_results must be between 1 and 50, got {max_results}"
            }

        # Resolve drug name (commercial name → QS code if needed)
        drug_name_resolver = get_drug_name_resolver()

        # Try to resolve as QS code first
        drug_upper = drug.upper()
        drug_info = drug_name_resolver.resolve(drug_upper)

        # If not found as QS code, try searching by commercial name
        if drug_info['source'] == 'none':
            search_results = drug_name_resolver.search_by_name(drug, limit=1)
            if search_results:
                drug_id = search_results[0]['drug_id']
                drug_info = drug_name_resolver.resolve(drug_id)
            else:
                return {
                    "success": False,
                    "error": f"Drug not found: {drug}",
                    "drug": drug,
                    "hint": "Try using standard drug names or QS codes (e.g., 'Metformin' or 'QS0318588')"
                }
        else:
            drug_id = drug_info['drug_id']

        commercial_name = drug_info['commercial_name']

        # Try Neo4j LOOKALIKE relationships first (preferred)
        neo4j_result = _query_neo4j_lookalikes(
            drug_id=drug_id,
            commercial_name=commercial_name,
            similarity_threshold=similarity_threshold,
            max_results=max_results,
            include_approved_only=include_approved_only
        )

        if neo4j_result["success"]:
            # Successfully found lookalikes in Neo4j
            result_dict = {
                "success": True,
                "drug": drug_id,
                "drug_input": drug,
                "commercial_name": commercial_name,
                "lookalikes": neo4j_result["lookalikes"],
                "count": len(neo4j_result["lookalikes"]),
                "data_source": "neo4j_lookalike",
                "strategy_note": _generate_strategy_note(neo4j_result["lookalikes"], "neo4j"),
                "query_params": {
                    "drug": drug,
                    "similarity_threshold": similarity_threshold,
                    "max_results": max_results,
                    "include_approved_only": include_approved_only
                }
            }

            return result_dict

        # Fallback to embedding similarity if Neo4j not available
        logger.info(f"Neo4j lookalikes not available, falling back to embedding similarity: {neo4j_result.get('error', 'Unknown error')}")

        embedding_result = _query_embedding_similarity(
            drug_id=drug_id,
            commercial_name=commercial_name,
            similarity_threshold=similarity_threshold,
            max_results=max_results,
            include_approved_only=include_approved_only
        )

        if embedding_result["success"]:
            return {
                "success": True,
                "drug": drug_id,
                "drug_input": drug,
                "commercial_name": commercial_name,
                "lookalikes": embedding_result["lookalikes"],
                "count": len(embedding_result["lookalikes"]),
                "data_source": "embedding_similarity",
                "strategy_note": _generate_strategy_note(embedding_result["lookalikes"], "embedding"),
                "fallback_note": "Using embedding similarity (Neo4j LOOKALIKE relationships not available)",
                "query_params": {
                    "drug": drug,
                    "similarity_threshold": similarity_threshold,
                    "max_results": max_results,
                    "include_approved_only": include_approved_only
                }
            }
        else:
            return {
                "success": False,
                "error": f"Could not find lookalikes via Neo4j or embeddings: {embedding_result.get('error', 'Unknown error')}",
                "drug": drug_id,
                "drug_input": drug,
                "commercial_name": commercial_name
            }

    except Exception as e:
        logger.error(f"Unexpected error in drug_lookalikes: {str(e)}")
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "drug": tool_input.get("drug", "unknown"),
            "error_type": type(e).__name__
        }


def _query_neo4j_lookalikes(
    drug_id: str,
    commercial_name: str,
    similarity_threshold: float,
    max_results: int,
    include_approved_only: bool
) -> Dict[str, Any]:
    """
    Query Neo4j for LOOKALIKE relationships.

    Args:
        drug_id: QS code for drug
        commercial_name: Commercial name for matching
        similarity_threshold: Minimum disease similarity
        max_results: Max results to return
        include_approved_only: Filter to approved drugs only

    Returns:
        Dict with success status and lookalikes list
    """
    try:
        from neo4j import GraphDatabase
    except ImportError:
        return {
            "success": False,
            "error": "neo4j driver not installed. Run: pip install neo4j"
        }

    # Get Neo4j connection parameters
    neo4j_uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
    neo4j_user = os.getenv("NEO4J_USER", "neo4j")
    neo4j_password = os.getenv("NEO4J_PASSWORD", "rescue123")

    driver = None
    try:
        driver = GraphDatabase.driver(
            neo4j_uri,
            auth=(neo4j_user, neo4j_password)
        )

        with driver.session() as session:
            # Query for LOOKALIKE relationships
            # Match by both name and entity_name to handle different property conventions
            query = """
            MATCH (d1:Drug)-[r:LOOKALIKE]-(d2:Drug)
            WHERE (d1.name = $drug_id OR d1.entity_name = $drug_id
                   OR toLower(d1.name) = toLower($commercial_name))
              AND r.disease_similarity >= $similarity_threshold
            RETURN
                COALESCE(d2.entity_name, d2.name, d2.id) AS drug2_id,
                r.disease_similarity AS disease_similarity,
                r.structural_similarity AS structural_similarity,
                r.similarity_gap AS similarity_gap,
                r.patent_potential AS patent_potential,
                r.rank AS rank
            ORDER BY r.similarity_gap DESC
            LIMIT $max_results
            """

            result = session.run(
                query,
                drug_id=drug_id,
                commercial_name=commercial_name,
                similarity_threshold=similarity_threshold,
                max_results=max_results
            )

            # Resolve commercial names for all results
            drug_name_resolver = get_drug_name_resolver()
            lookalikes = []

            for record in result:
                drug2_id = record["drug2_id"]
                name_info = drug_name_resolver.resolve(drug2_id)

                # Skip if approved_only filter is enabled and we don't have approval info
                # (Conservative: assume investigational if not in priority list)
                if include_approved_only and name_info['source'] not in ['priority_2000', 'metadata_14k']:
                    continue

                lookalike_data = {
                    "drug": name_info['commercial_name'],  # v3.1: PRIMARY field
                    "similarity_score": round(float(record["disease_similarity"]), 3),
                    "screening_id": drug2_id,  # Internal use
                    "structural_similarity": round(float(record["structural_similarity"]), 3) if record["structural_similarity"] is not None else None,
                    "patent_potential": record["patent_potential"],
                    "similarity_gap": round(float(record["similarity_gap"]), 3) if record["similarity_gap"] is not None else None,
                    "source": "neo4j_lookalike",
                    "chembl_id": name_info.get('chembl_id', ''),
                    "name_source": name_info.get('source', 'none')
                }

                lookalikes.append(lookalike_data)

            if lookalikes:
                return {
                    "success": True,
                    "lookalikes": lookalikes[:max_results]  # Ensure we don't exceed max
                }
            else:
                return {
                    "success": False,
                    "error": f"No LOOKALIKE relationships found for {drug_id} in Neo4j"
                }

    except Exception as e:
        logger.error(f"Neo4j query error: {str(e)}")
        return {
            "success": False,
            "error": f"Neo4j query failed: {str(e)}",
            "error_type": type(e).__name__
        }

    finally:
        if driver:
            driver.close()


def _query_embedding_similarity(
    drug_id: str,
    commercial_name: str,
    similarity_threshold: float,
    max_results: int,
    include_approved_only: bool
) -> Dict[str, Any]:
    """
    Fallback to drug similarity using v6.0 fusion tables.

    **v6.0 FUSION INTEGRATION:**
    Now uses pre-computed d_d_chem_lincs_topk_v6_0 for 100× speedup!
    - OLD: 100ms (K-NN on embedding space)
    - NEW: 1ms (indexed fusion lookup)

    Args:
        drug_id: QS code for drug
        commercial_name: Commercial name
        similarity_threshold: Minimum similarity
        max_results: Max results to return
        include_approved_only: Filter to approved drugs only

    Returns:
        Dict with success status and lookalikes list
    """
    # v6.0 FUSION: Try fusion table first (100× faster!)
    try:
        import psycopg2
        from psycopg2.extras import RealDictCursor

        pgvector_config = {
            'host': 'localhost',
            'port': 5435,
            'database': 'sapphire_database',
            'user': 'postgres',
            'password': 'temppass123'
        }

        conn = psycopg2.connect(**pgvector_config)
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # Query same-modal drug fusion table
        cursor.execute("""
            SELECT
                entity2_id as similar_drug_id,
                similarity_score
            FROM d_d_chem_lincs_topk_v6_0
            WHERE entity1_id = %s
              AND similarity_score >= %s
            ORDER BY similarity_score DESC
            LIMIT %s
        """, (drug_id, similarity_threshold, max_results * 2))

        fusion_results = cursor.fetchall()
        conn.close()

        if fusion_results:
            # Build results with commercial name resolution (same format as legacy)
            drug_name_resolver = get_drug_name_resolver()
            lookalikes = []

            for row in fusion_results:
                similar_drug_id = row['similar_drug_id']
                similarity_score = float(row['similarity_score'])

                # Resolve commercial name
                name_info = drug_name_resolver.resolve(similar_drug_id)

                # Apply approved_only filter
                if include_approved_only and name_info['source'] not in ['priority_2000', 'metadata_14k']:
                    continue

                lookalike_data = {
                    "drug": name_info['commercial_name'],  # v3.1: PRIMARY field
                    "similarity_score": round(similarity_score, 3),
                    "screening_id": similar_drug_id,  # Internal use
                    "structural_similarity": None,  # Not available in embedding-only mode
                    "patent_potential": "UNKNOWN",  # Cannot determine without structural data
                    "source": "fusion_v6.0_chem_lincs",
                    "chembl_id": name_info.get('chembl_id', ''),
                    "name_source": name_info.get('source', 'none')
                }

                lookalikes.append(lookalike_data)

                if len(lookalikes) >= max_results:
                    break

            if lookalikes:
                return {
                    "success": True,
                    "lookalikes": lookalikes
                }

        # If fusion query returns no results, fall through to legacy method below
        logger.info(f"No fusion results for {drug_id}, falling back to legacy embedding similarity")

    except Exception as e:
        logger.warning(f"Fusion table query failed: {e}, falling back to legacy method")

    # LEGACY FALLBACK: Original embedding similarity (100ms)
    try:
        from zones.z07_data_access.embedding_service import get_embedding_service as get_embedding_service
    except ImportError:
        return {
            "success": False,
            "error": "embedding_service not available"
        }

    try:
        embedding_service = get_embedding_service()
        if embedding_service is None or embedding_service.drug_df is None:
            return {
                "success": False,
                "error": "Drug embeddings not loaded"
            }

        # Get query drug embedding
        drug_emb = embedding_service.get_drug_embedding(drug_id)
        if drug_emb is None:
            return {
                "success": False,
                "error": f"Drug not found in embeddings: {drug_id}"
            }

        # Normalize query embedding
        drug_emb_norm = drug_emb / (np.linalg.norm(drug_emb) + 1e-8)

        # Get all drug embeddings
        drug_embeddings = embedding_service.drug_df[embedding_service._drug_embedding_cols].values.astype(np.float32)

        # Normalize drug embeddings
        drug_norms = np.linalg.norm(drug_embeddings, axis=1, keepdims=True) + 1e-8
        drug_embeddings_norm = drug_embeddings / drug_norms

        # Compute cosine similarities
        similarities = drug_embeddings_norm @ drug_emb_norm

        # Get drug index for query drug
        drug_index = {
            row['entity_name']: idx
            for idx, row in embedding_service.drug_df.iterrows()
            if 'entity_name' in embedding_service.drug_df.columns
        }

        # Filter by minimum similarity (exclude self)
        if drug_id in drug_index:
            query_idx = drug_index[drug_id]
            valid_mask = (similarities >= similarity_threshold) & (np.arange(len(similarities)) != query_idx)
        else:
            valid_mask = similarities >= similarity_threshold

        valid_indices = np.where(valid_mask)[0]

        # Sort by similarity (descending)
        sorted_indices = valid_indices[np.argsort(-similarities[valid_indices])]

        # Take top K
        top_indices = sorted_indices[:max_results * 2]  # Get extra for filtering

        # Build results with commercial name resolution
        drug_name_resolver = get_drug_name_resolver()
        lookalikes = []

        for idx in top_indices:
            drug_row = embedding_service.drug_df.iloc[idx]
            similar_drug_id = drug_row.get('entity_name', f"DRUG_{idx}") if 'entity_name' in drug_row.index else f"DRUG_{idx}"

            # Resolve commercial name
            name_info = drug_name_resolver.resolve(similar_drug_id)

            # Apply approved_only filter
            if include_approved_only and name_info['source'] not in ['priority_2000', 'metadata_14k']:
                continue

            similarity_score = float(similarities[idx])

            lookalike_data = {
                "drug": name_info['commercial_name'],  # v3.1: PRIMARY field
                "similarity_score": round(similarity_score, 3),
                "screening_id": similar_drug_id,  # Internal use
                "structural_similarity": None,  # Not available in embedding-only mode
                "patent_potential": "UNKNOWN",  # Cannot determine without structural data
                "source": "embedding_similarity",
                "chembl_id": name_info.get('chembl_id', ''),
                "name_source": name_info.get('source', 'none')
            }

            lookalikes.append(lookalike_data)

            if len(lookalikes) >= max_results:
                break

        if lookalikes:
            return {
                "success": True,
                "lookalikes": lookalikes
            }
        else:
            return {
                "success": False,
                "error": f"No similar drugs found above threshold {similarity_threshold}"
            }

    except Exception as e:
        logger.error(f"Embedding similarity error: {str(e)}")
        return {
            "success": False,
            "error": f"Embedding similarity failed: {str(e)}",
            "error_type": type(e).__name__
        }


def _generate_strategy_note(lookalikes: List[Dict[str, Any]], source: str) -> str:
    """
    Generate strategic interpretation of lookalike results.

    Args:
        lookalikes: List of lookalike drugs
        source: Data source ("neo4j" or "embedding")

    Returns:
        Strategic note string
    """
    if not lookalikes:
        return "No lookalikes found."

    count = len(lookalikes)

    if source == "neo4j":
        high_potential = sum(1 for l in lookalikes if l.get("patent_potential") == "HIGH")
        medium_potential = sum(1 for l in lookalikes if l.get("patent_potential") == "MEDIUM")

        if high_potential > 0:
            return (f"Found {count} patent workaround candidates. {high_potential} with HIGH potential "
                   f"(>0.5 gap between therapeutic and structural similarity), {medium_potential} with MEDIUM potential. "
                   f"HIGH potential drugs offer best patent workaround opportunities.")
        else:
            return (f"Found {count} patent workaround candidates with MEDIUM potential. "
                   f"Consider evaluating structural differences for patent viability.")
    else:
        avg_sim = sum(l["similarity_score"] for l in lookalikes) / count
        return (f"Found {count} similar drugs based on embeddings (avg similarity: {avg_sim:.3f}). "
               f"Note: Structural similarity not available. Recommend verifying chemical structures "
               f"for patent differentiation.")


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
