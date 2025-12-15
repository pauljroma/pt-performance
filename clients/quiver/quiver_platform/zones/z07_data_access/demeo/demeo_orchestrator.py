"""
DeMeo v2.0 - Main Orchestrator

Purpose:
Coordinates drug rescue ranking via tool orchestration, Bayesian fusion,
and metagraph pattern storage.

Features:
- Intent classification (rescue_ranking, mechanism_discovery, etc.)
- Query metagraph for cached LearnedRescuePattern
- Orchestrate 5+ core tools in parallel (vector_antipodal, bbb, adme, etc.)
- Bayesian fusion of tool results
- Store predictions in metagraph as LearnedRescuePattern nodes
- Return explainable rankings with SHAP-style tool contributions

Author: Quiver Platform - DeMeo Team
Created: 2025-12-03
Version: 2.0.0-alpha1
"""

from typing import Dict, List, Optional, Tuple
import asyncio
import numpy as np
from dataclasses import dataclass
from datetime import datetime
import logging

from .bayesian_fusion import (
    fuse_tool_predictions,
    ToolPrediction,
    FusionResult,
    format_fusion_result
)
from .vscore_calculator import compute_disease_signature, DiseaseSignature

logger = logging.getLogger(__name__)


@dataclass
class RescueRanking:
    """Drug rescue ranking result."""
    drug: str
    gene: str
    disease: str
    consensus_score: float
    confidence: float
    confidence_interval: Tuple[float, float]
    tool_contributions: Dict[str, float]
    explanation: str
    pattern_id: Optional[str] = None


# Tool configurations (from DeMeo plan)
CORE_TOOLS = {
    'vector_antipodal': {
        'weight': 0.35,
        'timeout': 5.0,
        'description': 'Core rescue score via antipodal embeddings'
    },
    'bbb_permeability': {
        'weight': 0.20,
        'timeout': 3.0,
        'description': 'CNS access prediction'
    },
    'adme_tox': {
        'weight': 0.15,
        'timeout': 4.0,
        'description': 'Safety assessment (ADME/Tox)'
    },
    'mechanistic_explainer': {
        'weight': 0.15,
        'timeout': 5.0,
        'description': 'Mechanism of action insights'
    },
    'clinical_trials': {
        'weight': 0.10,
        'timeout': 3.0,
        'description': 'Clinical trial evidence lookup'
    },
    'drug_interactions': {
        'weight': 0.05,
        'timeout': 2.0,
        'description': 'Drug-drug interaction contraindications'
    }
}


async def execute_rescue_ranking(
    gene: str,
    disease: str,
    top_k: int = 20,
    unified_query_layer=None,
    neo4j_client=None,
    use_cache: bool = True
) -> Dict:
    """
    Execute drug rescue ranking for a gene-disease pair.

    Workflow:
    1. Check metagraph for existing LearnedRescuePattern (if use_cache=True)
    2. If none exist, orchestrate tools in parallel
    3. Fuse results via Bayesian fusion
    4. Store as LearnedRescuePattern in metagraph
    5. Return ranked drugs with explainability

    Args:
        gene: Target gene symbol (e.g., "SCN1A")
        disease: Disease name (e.g., "Dravet Syndrome")
        top_k: Number of top drugs to return (default 20)
        unified_query_layer: UnifiedQueryLayer instance
        neo4j_client: Neo4jClient instance
        use_cache: Query metagraph for cached patterns (default True)

    Returns:
        Dict with:
        - ranked_drugs: List[RescueRanking]
        - disease_signature: DiseaseSignature
        - metadata: execution metadata

    Example:
        >>> result = await execute_rescue_ranking("SCN1A", "Dravet Syndrome")
        >>> result['ranked_drugs'][0].drug
        'Fenfluramine'
        >>> result['ranked_drugs'][0].consensus_score
        0.87
    """
    logger.info(f"🧬 DeMeo v2.0 Rescue Ranking: {gene} → {disease}")

    # Step 1: Check metagraph for cached patterns
    cached_patterns = []
    if use_cache and neo4j_client:
        cached_patterns = await query_metagraph_for_patterns(
            gene=gene,
            disease=disease,
            neo4j_client=neo4j_client,
            top_k=top_k
        )

    if cached_patterns:
        logger.info(f"  ✓ Found {len(cached_patterns)} cached patterns in metagraph")
        # Convert cached patterns to RescueRanking objects
        ranked_drugs = [_pattern_to_ranking(p) for p in cached_patterns]
        return {
            'ranked_drugs': ranked_drugs,
            'disease_signature': None,
            'metadata': {
                'source': 'metagraph_cache',
                'n_patterns': len(cached_patterns),
                'execution_time_ms': 0
            }
        }

    # Step 2: No cache hit - generate new predictions
    logger.info("  ⚙️  No cache hit, generating new predictions...")

    start_time = datetime.utcnow()

    # Compute disease signature
    logger.info("  📊 Computing disease signature...")
    disease_signature = compute_disease_signature(
        gene=gene,
        disease=disease,
        cycle=0,
        unified_query_layer=unified_query_layer,
        neo4j_client=neo4j_client
    )

    # Get candidate drugs (placeholder - would query from database)
    candidate_drugs = _get_candidate_drugs(gene, unified_query_layer)
    logger.info(f"  💊 Evaluating {len(candidate_drugs)} candidate drugs...")

    # Step 3: Orchestrate tools for each drug
    ranked_drugs = []
    for drug in candidate_drugs[:top_k * 2]:  # Evaluate 2x top_k for filtering
        try:
            tool_results = await orchestrate_tools(
                drug=drug,
                gene=gene,
                disease=disease,
                unified_query_layer=unified_query_layer
            )

            # Bayesian fusion
            fusion_result = fuse_tool_predictions(
                tool_results=tool_results,
                weights={k: v['weight'] for k, v in CORE_TOOLS.items()}
            )

            # Create ranking
            ranking = RescueRanking(
                drug=drug,
                gene=gene,
                disease=disease,
                consensus_score=fusion_result.consensus_score,
                confidence=fusion_result.confidence,
                confidence_interval=fusion_result.confidence_interval,
                tool_contributions=fusion_result.tool_contributions,
                explanation=format_fusion_result(fusion_result, drug, gene)
            )

            ranked_drugs.append(ranking)

        except Exception as e:
            logger.warning(f"  ✗ Failed to rank {drug}: {e}")
            continue

    # Sort by consensus score
    ranked_drugs = sorted(ranked_drugs, key=lambda x: x.consensus_score, reverse=True)
    ranked_drugs = ranked_drugs[:top_k]

    # Step 4: Store patterns in metagraph
    if neo4j_client:
        for ranking in ranked_drugs:
            pattern_id = await store_learned_pattern(
                ranking=ranking,
                cycle=0,
                neo4j_client=neo4j_client
            )
            ranking.pattern_id = pattern_id

    execution_time_ms = (datetime.utcnow() - start_time).total_seconds() * 1000

    logger.info(f"  ✅ Rescue ranking complete: {len(ranked_drugs)} drugs ranked in {execution_time_ms:.0f}ms")

    return {
        'ranked_drugs': ranked_drugs,
        'disease_signature': disease_signature,
        'metadata': {
            'source': 'fresh_prediction',
            'n_candidates_evaluated': len(candidate_drugs),
            'n_drugs_ranked': len(ranked_drugs),
            'execution_time_ms': execution_time_ms
        }
    }


async def orchestrate_tools(
    drug: str,
    gene: str,
    disease: str,
    unified_query_layer=None
) -> Dict[str, ToolPrediction]:
    """
    Orchestrate 5+ tools in parallel with timeout handling.

    Args:
        drug: Drug name
        gene: Gene symbol
        disease: Disease name
        unified_query_layer: UnifiedQueryLayer instance

    Returns:
        Dict[tool_name, ToolPrediction]

    Example:
        >>> tool_results = await orchestrate_tools("Fenfluramine", "SCN1A", "Dravet")
        >>> tool_results['vector_antipodal'].score
        0.85
    """
    tool_results = {}

    # Create tasks for parallel execution
    tasks = {}
    for tool_name, config in CORE_TOOLS.items():
        task = _execute_tool_with_timeout(
            tool_name=tool_name,
            drug=drug,
            gene=gene,
            disease=disease,
            timeout=config['timeout'],
            unified_query_layer=unified_query_layer
        )
        tasks[tool_name] = task

    # Execute in parallel
    results = await asyncio.gather(*tasks.values(), return_exceptions=True)

    # Collect results
    for tool_name, result in zip(tasks.keys(), results):
        if isinstance(result, Exception):
            logger.warning(f"    ✗ {tool_name}: {result}")
        else:
            tool_results[tool_name] = result
            logger.debug(f"    ✓ {tool_name}: score={result.score:.2f}")

    return tool_results


async def _execute_tool_with_timeout(
    tool_name: str,
    drug: str,
    gene: str,
    disease: str,
    timeout: float,
    unified_query_layer=None
) -> ToolPrediction:
    """Execute a single tool with timeout."""
    try:
        result = await asyncio.wait_for(
            _execute_tool(tool_name, drug, gene, disease, unified_query_layer),
            timeout=timeout
        )
        return result
    except asyncio.TimeoutError:
        raise TimeoutError(f"{tool_name} timed out after {timeout}s")


async def _execute_tool(
    tool_name: str,
    drug: str,
    gene: str,
    disease: str,
    unified_query_layer=None
) -> ToolPrediction:
    """
    Execute a single tool (placeholder implementation).

    In production, this would call actual tool implementations:
    - vector_antipodal: Antipodal similarity scoring
    - bbb_permeability: BBB penetration prediction
    - adme_tox: ADME/Tox safety assessment
    - mechanistic_explainer: MOA description
    - clinical_trials: FDA/trial database lookup
    - drug_interactions: Contraindication checking

    For now, returns mock predictions.
    """
    await asyncio.sleep(0.1)  # Simulate tool latency

    # Mock predictions (replace with actual tool calls)
    mock_scores = {
        'vector_antipodal': 0.85,
        'bbb_permeability': 0.91,
        'adme_tox': 0.78,
        'mechanistic_explainer': 0.72,
        'clinical_trials': 0.95,
        'drug_interactions': 0.88
    }

    score = mock_scores.get(tool_name, 0.70)
    confidence = 0.85

    return ToolPrediction(
        score=score,
        confidence=confidence,
        metadata={'drug': drug, 'gene': gene, 'disease': disease}
    )


async def query_metagraph_for_patterns(
    gene: str,
    disease: str,
    neo4j_client,
    top_k: int = 20,
    min_confidence: float = 0.70
) -> List[Dict]:
    """
    Query metagraph for existing LearnedRescuePattern.

    Args:
        gene: Gene symbol
        disease: Disease name
        neo4j_client: Neo4jClient instance
        top_k: Number of patterns to return
        min_confidence: Minimum confidence threshold

    Returns:
        List of pattern dicts
    """
    if neo4j_client is None:
        return []

    cypher = """
    MATCH (p:LearnedRescuePattern {gene: $gene, disease: $disease})
    WHERE p.confidence >= $min_confidence
    RETURN p
    ORDER BY p.confidence DESC
    LIMIT $top_k
    """

    params = {
        'gene': gene,
        'disease': disease,
        'min_confidence': min_confidence,
        'top_k': top_k
    }

    try:
        # result = neo4j_client.execute_query(cypher, params)
        # return result
        # Placeholder for now
        logger.info(f"Would query metagraph for {gene}/{disease} patterns")
        return []  # No cache hit for testing
    except Exception as e:
        logger.error(f"Failed to query metagraph: {e}")
        return []


async def store_learned_pattern(
    ranking: RescueRanking,
    cycle: int,
    neo4j_client
) -> str:
    """
    Store LearnedRescuePattern in Neo4j metagraph.

    Args:
        ranking: RescueRanking object
        cycle: Active learning cycle
        neo4j_client: Neo4jClient instance

    Returns:
        pattern_id
    """
    pattern_id = f"rescue_{ranking.gene}_{ranking.disease.replace(' ', '_')}_{ranking.drug}_cycle{cycle}"

    if neo4j_client is None:
        logger.warning("No Neo4jClient, skipping pattern storage")
        return pattern_id

    cypher = """
    CREATE (p:LearnedRescuePattern {
        pattern_id: $pattern_id,
        gene: $gene,
        disease: $disease,
        drug: $drug,
        consensus_score: $consensus_score,
        confidence: $confidence,
        tool_contributions: $tool_contributions,
        cycle: $cycle,
        validation_status: 'predicted',
        discovered_at: datetime(),
        last_updated: datetime()
    })
    RETURN p.pattern_id as pattern_id
    """

    params = {
        'pattern_id': pattern_id,
        'gene': ranking.gene,
        'disease': ranking.disease,
        'drug': ranking.drug,
        'consensus_score': ranking.consensus_score,
        'confidence': ranking.confidence,
        'tool_contributions': ranking.tool_contributions,
        'cycle': cycle
    }

    try:
        # result = neo4j_client.execute_query(cypher, params)
        logger.info(f"Would store pattern: {pattern_id}")
        return pattern_id
    except Exception as e:
        logger.error(f"Failed to store pattern: {e}")
        raise


def _get_candidate_drugs(gene: str, unified_query_layer) -> List[str]:
    """
    Get candidate drugs for rescue ranking.

    In production, would query from:
    - PGVector top-K similarity
    - Neo4j graph neighbors
    - Literature-mentioned drugs

    For now, returns mock drugs.
    """
    # Mock drug list
    mock_drugs = [
        "Stiripentol", "Fenfluramine", "Cannabidiol", "Valproate",
        "Clobazam", "Levetiracetam", "Topiramate", "Bromide",
        "Everolimus", "Sirolimus", "Riluzole", "Fenofibrate",
        "Verteporfin", "Halofuginone", "Bromocriptine", "Moxidectin",
        "Zonisamide", "Perampanel", "Lacosamide", "Brivaracetam"
    ]
    return mock_drugs


def _pattern_to_ranking(pattern: Dict) -> RescueRanking:
    """Convert cached pattern dict to RescueRanking object."""
    return RescueRanking(
        drug=pattern.get('drug', 'Unknown'),
        gene=pattern.get('gene', ''),
        disease=pattern.get('disease', ''),
        consensus_score=pattern.get('consensus_score', 0.0),
        confidence=pattern.get('confidence', 0.0),
        confidence_interval=(0.0, 0.0),  # Not stored in pattern
        tool_contributions=pattern.get('tool_contributions', {}),
        explanation="",
        pattern_id=pattern.get('pattern_id')
    )


# ============================================================================
# Utility Functions
# ============================================================================

def format_rescue_rankings(rankings: List[RescueRanking], top_n: int = 10) -> str:
    """Format top N rescue rankings as human-readable output."""
    output = f"\n🏆 Top {top_n} Drug Rescue Candidates:\n\n"

    for i, ranking in enumerate(rankings[:top_n], 1):
        ci_lower, ci_upper = ranking.confidence_interval
        output += f"{i}. {ranking.drug}\n"
        output += f"   Score: {ranking.consensus_score:.3f} [CI: {ci_lower:.2f}-{ci_upper:.2f}]\n"
        output += f"   Confidence: {ranking.confidence:.2f}\n"

        # Top 3 tool contributions
        sorted_tools = sorted(
            ranking.tool_contributions.items(),
            key=lambda x: x[1],
            reverse=True
        )[:3]
        output += f"   Top Tools: {', '.join(f'{t}({c:.2f})' for t, c in sorted_tools)}\n\n"

    return output
