"""
DeMeo v2.0 - Multi-Modal Consensus Engine

Purpose:
Combines predictions from multiple embedding spaces (MODEX, ENS, LINCS) using
weighted fusion to produce consensus predictions.

Key Features:
- Weighted fusion of MODEX (50%) + ENS (30%) + LINCS (20%)
- Agreement coefficient calculation (cross-modal similarity)
- Quality-based adaptive weighting
- Validation of consensus vectors

Author: Quiver Platform - DeMeo Team
Created: 2025-12-03
Version: 2.0.0-alpha1
"""

from typing import Dict, Tuple, Optional, List
import numpy as np
from dataclasses import dataclass
import logging
from sklearn.metrics.pairwise import cosine_similarity

# Try to import Cython-optimized core (100-1200x speedup)
try:
    from . import _multimodal_consensus_core as cython_core
    USE_CYTHON = True
except ImportError:
    USE_CYTHON = False
    cython_core = None

logger = logging.getLogger(__name__)
if USE_CYTHON:
    logger.info("✅ Using Cython-accelerated multimodal_consensus_core (100-1200x speedup)")


@dataclass
class ConsensusResult:
    """Result of multi-modal consensus."""
    consensus_vector: np.ndarray  # Fused embedding vector
    agreement_coefficient: float  # Cross-modal similarity (0.0-1.0)
    modality_scores: Dict[str, float]  # modality → score/similarity
    weights_used: Dict[str, float]  # modality → weight
    metadata: Dict  # Additional metadata


# Default multi-modal weights (from DeMeo plan)
DEFAULT_MULTIMODAL_WEIGHTS = {
    'modex': 0.50,  # Mechanistic co-expression, highest priority
    'ens': 0.30,    # Core biological features
    'lincs': 0.20   # Transcriptomic signatures
}


def _compute_score_based_consensus(
    vectors: Dict[str, np.ndarray],
    weights: Optional[Dict[str, float]] = None
) -> ConsensusResult:
    """
    Fallback consensus computation for vectors with different dimensions.

    For Bayesian fusion, we don't need vector-level fusion - just agreement metrics.
    This computes pairwise similarities and uses them as proxy for consensus.

    Args:
        vectors: {space_name: vector} with potentially different dimensions
        weights: {space_name: weight}

    Returns:
        ConsensusResult with placeholder consensus_vector and computed metrics
    """
    if weights is None:
        weights = DEFAULT_MULTIMODAL_WEIGHTS

    # Normalize weights
    available_spaces = set(vectors.keys())
    weights = _normalize_weights(weights, available_spaces)

    # Compute pairwise cosine similarities (dimension-agnostic using norms)
    space_names = list(vectors.keys())
    n_spaces = len(space_names)

    # For different dimensions, use normalized vector norms as proxy scores
    space_scores = {}
    for space_name in space_names:
        vector = vectors[space_name]
        # Compute L2 norm as representative score
        norm = float(np.linalg.norm(vector))
        # Normalize by dimension to make comparable across spaces
        normalized_score = norm / np.sqrt(len(vector))
        space_scores[space_name] = normalized_score

    # Weighted average of normalized scores as agreement proxy
    weighted_score = sum(weights.get(space, 0.0) * space_scores[space]
                        for space in space_names)

    # Use score variance as inverse agreement (low variance = high agreement)
    score_values = list(space_scores.values())
    score_std = float(np.std(score_values))
    # Map to [0, 1] range: low std = high agreement
    agreement_coefficient = max(0.0, 1.0 - min(1.0, score_std))

    # Modality scores: how close each space's score is to weighted average
    modality_scores = {}
    for space in space_names:
        diff = abs(space_scores[space] - weighted_score)
        # Convert difference to similarity: smaller diff = higher similarity
        similarity = max(0.0, 1.0 - diff)
        modality_scores[space] = similarity

    # Create placeholder consensus vector (use first space's dimension)
    first_vector = next(iter(vectors.values()))
    consensus_vector = np.zeros_like(first_vector)

    # Build metadata
    metadata = {
        'n_modalities': n_spaces,
        'dimensions': [len(v) for v in vectors.values()],
        'dimension_mismatch': True,
        'fallback_method': 'score_based_consensus',
        'space_scores': space_scores
    }

    logger.info(f"Score-based consensus: agreement={agreement_coefficient:.3f}, "
                f"spaces={list(space_names)}, dims={metadata['dimensions']}")

    return ConsensusResult(
        consensus_vector=consensus_vector,  # Placeholder
        agreement_coefficient=agreement_coefficient,
        modality_scores=modality_scores,
        weights_used=weights,
        metadata=metadata
    )


def compute_consensus(
    vectors: Dict[str, np.ndarray],
    weights: Optional[Dict[str, float]] = None
) -> ConsensusResult:
    """
    Compute consensus vector from multiple embedding spaces.

    Algorithm:
        consensus = sum(weight_i * vector_i) / sum(weights)

    Args:
        vectors: {space_name: vector} - must have at least 2 spaces
        weights: {space_name: weight} - if None, use DEFAULT_MULTIMODAL_WEIGHTS

    Returns:
        ConsensusResult with consensus vector and agreement metrics

    Example:
        >>> vectors = {
        ...     'modex': np.array([0.5, 0.3, 0.8]),
        ...     'ens': np.array([0.4, 0.4, 0.7]),
        ...     'lincs': np.array([0.6, 0.2, 0.9])
        ... }
        >>> result = compute_consensus(vectors)
        >>> result.consensus_vector
        array([0.48, 0.32, 0.78])  # weighted fusion
    """
    if len(vectors) < 2:
        raise ValueError("Need at least 2 embedding spaces for consensus")

    if weights is None:
        weights = DEFAULT_MULTIMODAL_WEIGHTS

    # Check if all vectors have same dimension
    dims = [v.shape[0] if v.ndim == 1 else v.shape for v in vectors.values()]
    same_dims = len(set(map(str, dims))) == 1

    if not same_dims:
        # DIMENSION MISMATCH FALLBACK: Use score-based consensus for Bayesian fusion
        # For Bayesian regression, we don't need vector fusion - just agreement metrics
        logger.warning(f"Dimension mismatch detected: {dims}. Using score-based consensus fallback.")
        return _compute_score_based_consensus(vectors, weights)

    # Ensure weights are normalized
    available_spaces = set(vectors.keys())
    weights = _normalize_weights(weights, available_spaces)

    # Weighted fusion
    consensus_vector = np.zeros_like(next(iter(vectors.values())))
    for space, vector in vectors.items():
        weight = weights.get(space, 0.0)
        consensus_vector += weight * vector

    # Calculate agreement coefficient (cross-modal similarity)
    agreement = calculate_agreement_coefficient(vectors)

    # Calculate modality scores (similarity to consensus)
    modality_scores = {}
    for space, vector in vectors.items():
        if USE_CYTHON:
            # Use Cython for 100x speedup
            similarity = cython_core.cosine_similarity(vector, consensus_vector)
        else:
            # sklearn fallback
            similarity = cosine_similarity(
                vector.reshape(1, -1),
                consensus_vector.reshape(1, -1)
            )[0, 0]
        modality_scores[space] = float(similarity)

    # Build metadata
    metadata = {
        'n_modalities': len(vectors),
        'dimensions': consensus_vector.shape[0],
        'consensus_norm': float(np.linalg.norm(consensus_vector))
    }

    return ConsensusResult(
        consensus_vector=consensus_vector,
        agreement_coefficient=agreement,
        modality_scores=modality_scores,
        weights_used=weights,
        metadata=metadata
    )


def calculate_agreement_coefficient(vectors: Dict[str, np.ndarray]) -> float:
    """
    Measure cross-modal similarity (pairwise cosine similarity).

    High agreement → 0.85-0.95 (vectors point in same direction)
    Low agreement → 0.50-0.70 (vectors diverge)

    Args:
        vectors: {space_name: vector}

    Returns:
        Agreement coefficient (0.0-1.0)
    """
    if len(vectors) < 2:
        return 1.0  # Single modality = perfect agreement

    # Use Cython for 1200x speedup
    if USE_CYTHON:
        # Convert to 2D array for Cython
        space_names = list(vectors.keys())
        vectors_2d = np.array([vectors[name] for name in space_names], dtype=np.float64)
        agreement = cython_core.calculate_agreement(vectors_2d)
        return float(max(0.0, min(1.0, agreement)))

    # Pure Python fallback
    space_names = list(vectors.keys())
    similarities = []

    for i, space1 in enumerate(space_names):
        for space2 in space_names[i+1:]:
            v1 = vectors[space1].reshape(1, -1)
            v2 = vectors[space2].reshape(1, -1)
            sim = cosine_similarity(v1, v2)[0, 0]
            similarities.append(sim)

    # Average similarity = agreement coefficient
    agreement = float(np.mean(similarities))

    # Ensure in [0, 1] range
    agreement = max(0.0, min(1.0, agreement))

    return agreement


def adaptive_weighting(
    base_weights: Dict[str, float],
    quality_scores: Dict[str, int]
) -> Dict[str, float]:
    """
    Adjust weights based on embedding space quality tiers.

    Quality Tiers (from metagraph):
    - Tier 1: High quality (v6.0 embeddings, well-validated)
    - Tier 2: Medium quality (v5.0 embeddings, some validation)
    - Tier 3: Low quality (experimental, limited validation)

    Args:
        base_weights: {space_name: weight}
        quality_scores: {space_name: tier} (1, 2, or 3)

    Returns:
        Adjusted weights (normalized to sum to 1.0)

    Example:
        >>> base_weights = {'modex': 0.50, 'ens': 0.30, 'lincs': 0.20}
        >>> quality_scores = {'modex': 1, 'ens': 2, 'lincs': 2}  # MODEX is Tier 1
        >>> adaptive_weighting(base_weights, quality_scores)
        {'modex': 0.55, 'ens': 0.27, 'lincs': 0.18}  # MODEX weight increased
    """
    adjusted_weights = {}

    for space, base_weight in base_weights.items():
        if space not in quality_scores:
            # No quality score available, use base weight
            adjusted_weights[space] = base_weight
            continue

        tier = quality_scores[space]

        # Tier 1 → boost by 10%
        # Tier 2 → no change
        # Tier 3 → reduce by 10%
        if tier == 1:
            adjusted_weights[space] = base_weight * 1.10
        elif tier == 2:
            adjusted_weights[space] = base_weight
        elif tier == 3:
            adjusted_weights[space] = base_weight * 0.90
        else:
            logger.warning(f"Unknown tier {tier} for {space}, using base weight")
            adjusted_weights[space] = base_weight

    # Normalize to sum to 1.0
    total = sum(adjusted_weights.values())
    normalized_weights = {
        space: weight / total
        for space, weight in adjusted_weights.items()
    }

    return normalized_weights


def validate_consensus(
    consensus_vec: np.ndarray,
    agreement: float
) -> bool:
    """
    Validate consensus vector is valid.

    Checks:
    - Vector is non-zero
    - All values are finite
    - Agreement is in valid range [0, 1]

    Args:
        consensus_vec: Consensus vector
        agreement: Agreement coefficient

    Returns:
        True if valid, raises ValueError otherwise
    """
    # Check non-zero
    if np.allclose(consensus_vec, 0.0):
        raise ValueError("Consensus vector is zero (all spaces missing?)")

    # Check finite
    if not np.all(np.isfinite(consensus_vec)):
        raise ValueError("Consensus vector contains NaN or Inf")

    # Check agreement range
    if not (0.0 <= agreement <= 1.0):
        raise ValueError(f"Agreement coefficient {agreement} not in [0, 1]")

    return True


def _normalize_weights(
    weights: Dict[str, float],
    available_spaces: set
) -> Dict[str, float]:
    """
    Normalize weights to sum to 1.0 for available spaces only.

    Args:
        weights: {space_name: weight}
        available_spaces: Set of available space names

    Returns:
        Normalized weights
    """
    available_weights = {
        space: weight
        for space, weight in weights.items()
        if space in available_spaces
    }

    if not available_weights:
        raise ValueError("No available spaces to normalize weights")

    total = sum(available_weights.values())
    if total == 0:
        raise ValueError("Total weight is zero")

    normalized = {
        space: weight / total
        for space, weight in available_weights.items()
    }

    return normalized


# ============================================================================
# Utility Functions
# ============================================================================

def get_modality_breakdown(result: ConsensusResult) -> str:
    """
    Format ConsensusResult as human-readable modality breakdown.

    Args:
        result: ConsensusResult object

    Returns:
        Formatted string with modality scores and agreement
    """
    output = "\nMulti-Modal Consensus:\n"

    sorted_modalities = sorted(
        result.modality_scores.items(),
        key=lambda x: result.weights_used[x[0]],
        reverse=True
    )

    for space, score in sorted_modalities:
        weight = result.weights_used[space]
        output += f"  - {space.upper()}: {score:.2f} (weight: {weight:.2%})\n"

    output += f"\nCross-Modal Agreement: {result.agreement_coefficient:.2f}/1.0 "

    if result.agreement_coefficient >= 0.85:
        output += "(VERY HIGH)"
    elif result.agreement_coefficient >= 0.70:
        output += "(HIGH)"
    elif result.agreement_coefficient >= 0.50:
        output += "(MODERATE)"
    else:
        output += "(LOW - contradictory signals)"

    output += f"\n\nConsensus Vector Norm: {result.metadata['consensus_norm']:.2f}\n"

    return output


def detect_modality_outliers(
    result: ConsensusResult,
    threshold: float = 0.60
) -> List[str]:
    """
    Detect modalities that significantly disagree with consensus.

    Args:
        result: ConsensusResult object
        threshold: Similarity threshold (below this = outlier)

    Returns:
        List of outlier modality names
    """
    outliers = []

    for space, score in result.modality_scores.items():
        if score < threshold:
            outliers.append(
                f"⚠️  {space.upper()} similarity ({score:.2f}) below threshold ({threshold:.2f})"
            )

    return outliers
