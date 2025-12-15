"""
Real Sapphire Tool Adapters for DeMeo v3.0

Converts Sapphire tool outputs to ToolPrediction format for Bayesian fusion.
Connects 6 existing Sapphire tools to DeMeo's drug rescue ranking system.

Tools integrated:
1. BBB Permeability - Blood-brain barrier penetration prediction
2. ADME/Tox - Safety and toxicity assessment
3. Clinical Trial Intelligence - Evidence from clinical trials
4. Drug Interactions - Interaction risk scoring
5. Mechanistic Explainer - Mechanism of action analysis
6. Vector Antipodal - Embedding-based antipodal search

Author: DeMeo v3.0 Integration Team
Date: 2025-12-03
Zone: z07_data_access/demeo
"""

from typing import Dict, Any
import logging
import asyncio

from clients.quiver.quiver_platform.zones.z07_data_access.demeo.bayesian_fusion import ToolPrediction

# Import existing Sapphire tools
from clients.quiver.quiver_platform.zones.z07_data_access.tools.bbb_permeability import (
    execute as bbb_execute
)
from clients.quiver.quiver_platform.zones.z07_data_access.tools.adme_tox_predictor import (
    execute as adme_execute
)
from clients.quiver.quiver_platform.zones.z07_data_access.tools.clinical_trial_intelligence import (
    execute as clinical_execute
)
from clients.quiver.quiver_platform.zones.z07_data_access.tools.drug_interactions import (
    execute as interactions_execute
)
from clients.quiver.quiver_platform.zones.z07_data_access.tools.mechanistic_explainer import (
    execute as mech_execute
)
from clients.quiver.quiver_platform.zones.z07_data_access.tools.vector_antipodal import (
    execute as antipodal_execute
)
from clients.quiver.quiver_platform.zones.z07_data_access.tools.transcriptomic_rescue import (
    execute as transcriptomic_execute
)
from clients.quiver.quiver_platform.zones.z07_data_access.tools.target_validation_scorer import (
    execute as target_validation_execute
)
from clients.quiver.quiver_platform.zones.z07_data_access.tools.literature_evidence import (
    execute as literature_execute
)
from clients.quiver.quiver_platform.zones.z07_data_access.tools.rescue_combinations import (
    execute as combinations_execute
)

logger = logging.getLogger(__name__)


async def get_bbb_prediction(drug: str) -> ToolPrediction:
    """
    Get BBB permeability prediction for a drug.

    Args:
        drug: Drug name

    Returns:
        ToolPrediction with BBB probability score and confidence
    """
    try:
        result = await bbb_execute({"drug_name": drug})

        # BBB tool returns "found" instead of "success"
        if result.get("found"):
            # Use correct field name: "bbb_permeability_probability"
            score = result.get("bbb_permeability_probability", 0.5)

            # Convert string confidence to float
            confidence_str = result.get("confidence", "medium")
            confidence_map = {"high": 0.90, "medium": 0.75, "low": 0.50}
            confidence = confidence_map.get(confidence_str, 0.75)

            return ToolPrediction(score=float(score), confidence=float(confidence))
    except Exception as e:
        logger.warning(f"BBB prediction failed for {drug}: {e}")

    # Fallback to neutral prediction
    return ToolPrediction(score=0.5, confidence=0.50)


async def get_adme_prediction(drug: str) -> ToolPrediction:
    """
    Get ADME/Tox safety prediction for a drug.

    Args:
        drug: Drug name

    Returns:
        ToolPrediction with safety score and confidence
    """
    try:
        result = await adme_execute({"drug": drug})
        if result.get("success"):
            # Use correct field name: "overall_safety_score"
            score = result.get("overall_safety_score", 0.5)

            # Calculate confidence from risk classification
            risk_class = result.get("risk_classification", "moderate")
            confidence_map = {"low": 0.90, "moderate": 0.75, "high": 0.60}
            confidence = confidence_map.get(risk_class, 0.75)

            return ToolPrediction(score=float(score), confidence=float(confidence))
    except Exception as e:
        logger.warning(f"ADME prediction failed for {drug}: {e}")

    # Fallback
    return ToolPrediction(score=0.5, confidence=0.50)


async def get_clinical_prediction(gene: str, drug: str) -> ToolPrediction:
    """
    Get clinical trial evidence prediction for gene-drug pair.

    Args:
        gene: Gene symbol
        drug: Drug name

    Returns:
        ToolPrediction with evidence score and confidence
    """
    try:
        # Search for trials mentioning both gene and drug
        query = f"{gene} {drug}"
        result = await clinical_execute({"query": query, "max_results": 10})

        if result.get("success"):
            # Calculate score based on number and quality of trials found
            trials_found = result.get("total_trials_found", 0)
            trials_returned = result.get("trials_returned", 0)
            trials = result.get("trials", [])

            # Score: normalize trial count (0-10 trials → 0.3-0.9 score)
            if trials_found > 0:
                # More trials = higher evidence
                score = min(0.3 + (trials_found / 10.0) * 0.6, 0.95)

                # Boost for phase 2/3 trials
                phase_boost = sum(1 for t in trials if t.get("phase") in ["PHASE2", "PHASE3"]) * 0.05
                score = min(score + phase_boost, 0.95)

                confidence = min(0.60 + (trials_returned / 10.0) * 0.30, 0.90)
            else:
                score = 0.3  # Low score if no trials found
                confidence = 0.50

            return ToolPrediction(score=float(score), confidence=float(confidence))
    except Exception as e:
        logger.warning(f"Clinical prediction failed for {gene}/{drug}: {e}")

    # Fallback
    return ToolPrediction(score=0.5, confidence=0.50)


async def get_interactions_prediction(drug: str) -> ToolPrediction:
    """
    Get drug interactions risk prediction (inverted to score).

    Args:
        drug: Drug name

    Returns:
        ToolPrediction with interaction safety score (1 - risk) and confidence
    """
    try:
        result = await interactions_execute({"drug": drug, "max_results": 20})
        if result.get("success"):
            # Calculate risk from interaction counts and severity
            known_interactions = result.get("known_interactions", [])
            predicted_interactions = result.get("predicted_interactions", [])

            # Count by severity
            major_count = sum(1 for i in known_interactions if i.get("severity") == "major")
            moderate_count = sum(1 for i in known_interactions if i.get("severity") == "moderate")
            minor_count = sum(1 for i in known_interactions if i.get("severity") == "minor")

            # Calculate risk score (0 = no risk, 1 = high risk)
            risk_score = min(
                (major_count * 0.15) + (moderate_count * 0.08) + (minor_count * 0.03),
                1.0
            )

            # Invert: low risk = high score
            score = 1.0 - risk_score

            # Confidence based on number of interactions assessed
            total_interactions = len(known_interactions) + len(predicted_interactions)
            confidence = min(0.60 + (total_interactions / 50.0) * 0.30, 0.90)

            return ToolPrediction(score=float(score), confidence=float(confidence))
    except Exception as e:
        logger.warning(f"Interactions prediction failed for {drug}: {e}")

    # Fallback
    return ToolPrediction(score=0.5, confidence=0.50)


async def get_mechanistic_prediction(gene: str, drug: str) -> ToolPrediction:
    """
    Get mechanistic explanation score for gene-drug pair.

    Args:
        gene: Gene symbol
        drug: Drug name

    Returns:
        ToolPrediction with mechanism score and confidence
    """
    try:
        # Note: mechanistic explainer requires disease parameter
        # For rescue, we infer disease from gene
        result = await mech_execute({
            "gene": gene,
            "drug": drug,
            "disease": "genetic disorder",  # Generic disease for gene-based queries
            "include_rescue": True
        })

        if result.get("success"):
            # Score based on mechanism and rescue prediction counts
            mechanism_count = result.get("mechanism_count", 0)
            rescue_count = result.get("rescue_count", 0)

            # Calculate score from mechanism quality
            mechanisms = result.get("mechanisms", [])
            rescue_preds = result.get("rescue_predictions", [])

            if mechanism_count > 0 or rescue_count > 0:
                # Average confidence from all mechanisms
                all_confidences = [m.get("confidence", 0.5) for m in mechanisms]
                all_confidences.extend([r.get("confidence", 0.5) for r in rescue_preds])

                score = sum(all_confidences) / len(all_confidences) if all_confidences else 0.5

                # Boost score for multiple mechanisms
                count_boost = min((mechanism_count + rescue_count) * 0.05, 0.20)
                score = min(score + count_boost, 0.95)
            else:
                score = 0.4  # Low score if no mechanisms found

            # Use tool's confidence if available
            confidence = result.get("confidence", 0.70)

            return ToolPrediction(score=float(score), confidence=float(confidence))
    except Exception as e:
        logger.warning(f"Mechanistic prediction failed for {gene}/{drug}: {e}")

    # Fallback
    return ToolPrediction(score=0.5, confidence=0.50)


async def get_antipodal_prediction(gene: str, drug: str) -> ToolPrediction:
    """
    Get vector antipodal prediction for gene-drug pair.

    Args:
        gene: Gene symbol
        drug: Drug name

    Returns:
        ToolPrediction with antipodal score and confidence
    """
    try:
        result = await antipodal_execute({
            "gene": gene,
            "top_k": 50,
            "min_rescue_score": 0.5  # Lower threshold to find more candidates
        })

        if result.get("success"):
            # Find the specific drug in rescue candidates
            rescue_candidates = result.get("rescue_candidates", [])

            # Look for matching drug in candidates
            drug_match = None
            for candidate in rescue_candidates:
                candidate_name = candidate.get("drug_name", "").lower()
                if drug.lower() in candidate_name or candidate_name in drug.lower():
                    drug_match = candidate
                    break

            if drug_match:
                # Use the rescue score as prediction score
                score = drug_match.get("rescue_score", 0.5)

                # Confidence based on rank (top results = higher confidence)
                rank = rescue_candidates.index(drug_match) + 1
                confidence = max(0.60, 0.95 - (rank / 50.0) * 0.35)
            else:
                # Drug not in top candidates - low score
                score = 0.35
                confidence = 0.50

            return ToolPrediction(score=float(score), confidence=float(confidence))
    except Exception as e:
        logger.warning(f"Antipodal prediction failed for {gene}/{drug}: {e}")

    # Fallback
    return ToolPrediction(score=0.5, confidence=0.50)


async def get_transcriptomic_prediction(gene: str, drug: str) -> ToolPrediction:
    """
    Get transcriptomic rescue prediction for gene-drug pair.

    Uses LINCS L1000 data to find drugs that reverse disease gene expression.

    Args:
        gene: Gene symbol
        drug: Drug name

    Returns:
        ToolPrediction with rescue score and confidence
    """
    try:
        result = await transcriptomic_execute({
            "gene": gene,
            "top_n": 50,
            "similarity_threshold": 0.6,  # Lower threshold to find more candidates
            "include_validation": True
        })

        if result.get("success"):
            candidates = result.get("candidates", [])

            # Find the specific drug in candidates
            drug_match = None
            for candidate in candidates:
                candidate_name = candidate.get("drug_name", "").lower()
                if drug.lower() in candidate_name or candidate_name in drug.lower():
                    drug_match = candidate
                    break

            if drug_match:
                # Use rescue score as prediction score
                rescue_score = drug_match.get("rescue_score", 0.5)

                # Confidence based on transcript count and similarity
                transcript_count = drug_match.get("total_transcripts", 0)
                avg_similarity = drug_match.get("avg_similarity", 0.5)

                # More transcripts + higher similarity = higher confidence
                confidence = min(
                    0.60 + (transcript_count / 100.0) * 0.25 + (avg_similarity * 0.15),
                    0.95
                )

                return ToolPrediction(score=float(rescue_score), confidence=float(confidence))
            else:
                # Drug not in top candidates - low score
                return ToolPrediction(score=0.35, confidence=0.45)

    except Exception as e:
        logger.warning(f"Transcriptomic prediction failed for {gene}/{drug}: {e}")

    # Fallback
    return ToolPrediction(score=0.5, confidence=0.40)


async def get_target_validation_prediction(gene: str, drug: str) -> ToolPrediction:
    """
    Get target validation prediction for gene.

    Validates target quality across 6 evidence dimensions.
    Higher validation = more likely drug will work for this target.

    Args:
        gene: Gene symbol
        drug: Drug name (not used for target validation, but kept for consistency)

    Returns:
        ToolPrediction with validation score and confidence
    """
    try:
        result = await target_validation_execute({
            "gene": gene,
            "disease": "genetic disorder",  # Generic for rescue context
            "explanation_detail": "score_only"  # Faster
        })

        if result.get("success"):
            validation_score = result.get("validation_score", 0.5)

            # Use validation score as prediction score
            # Higher target validation = more likely ANY drug will work
            score = validation_score

            # Confidence from CI width and recommendation
            ci = result.get("confidence_interval", (0.4, 0.6))
            ci_width = ci[1] - ci[0]

            # Narrow CI = high confidence
            confidence = max(0.60, min(0.95, 0.95 - (ci_width * 2.0)))

            return ToolPrediction(score=float(score), confidence=float(confidence))

    except Exception as e:
        logger.warning(f"Target validation failed for {gene}: {e}")

    # Fallback
    return ToolPrediction(score=0.5, confidence=0.40)


async def get_literature_prediction(gene: str, drug: str) -> ToolPrediction:
    """
    Get literature evidence prediction for gene-drug pair.

    Searches 29,863 CNS papers for supporting evidence.

    Args:
        gene: Gene symbol
        drug: Drug name

    Returns:
        ToolPrediction with evidence score and confidence
    """
    try:
        # Multi-query aggregation for comprehensive evidence
        result = await literature_execute({
            "mode": "aggregate",
            "queries": [
                f"{gene} drug treatment",
                f"{drug} {gene}",
                f"{gene} rescue therapy"
            ],
            "aggregation": "intersection",  # High precision
            "limit": 50
        })

        if result.get("success"):
            papers_found = result.get("papers_found", 0)
            papers = result.get("papers", [])

            # Score based on number and quality of papers
            if papers_found > 0:
                # More papers = stronger evidence (0.3-0.9 range)
                score = min(0.3 + (papers_found / 20.0) * 0.6, 0.95)

                # Boost for high-relevance papers
                high_relevance = sum(1 for p in papers if p.get("relevance_score", 0) > 0.85)
                score = min(score + (high_relevance * 0.05), 0.95)

                confidence = min(0.60 + (papers_found / 30.0) * 0.30, 0.90)
            else:
                score = 0.3  # Low score if no papers
                confidence = 0.50

            return ToolPrediction(score=float(score), confidence=float(confidence))

    except Exception as e:
        logger.warning(f"Literature prediction failed for {gene}/{drug}: {e}")

    # Fallback
    return ToolPrediction(score=0.5, confidence=0.40)


async def get_combination_prediction(gene: str, drug: str) -> ToolPrediction:
    """
    Get rescue combination prediction for gene-drug pair.

    Identifies synergistic drug combinations for enhanced rescue.

    Args:
        gene: Gene symbol
        drug: Drug name (base drug for combination)

    Returns:
        ToolPrediction with synergy score and confidence
    """
    try:
        result = await combinations_execute({
            "gene": gene,
            "base_drug": drug,
            "max_combinations": 20
        })

        if result.get("success"):
            combinations = result.get("combinations", [])

            if combinations:
                # Score based on best synergy score
                best_synergy = max(c.get("synergy_score", 0) for c in combinations)

                # Average confidence from top 3 combinations
                top_3_confidences = sorted(
                    [c.get("confidence", 0.5) for c in combinations],
                    reverse=True
                )[:3]
                confidence = sum(top_3_confidences) / len(top_3_confidences) if top_3_confidences else 0.50

                return ToolPrediction(score=float(best_synergy), confidence=float(confidence))
            else:
                return ToolPrediction(score=0.5, confidence=0.45)

    except Exception as e:
        logger.warning(f"Combination prediction failed for {gene}/{drug}: {e}")

    # Fallback
    return ToolPrediction(score=0.5, confidence=0.40)


async def get_all_tool_predictions(gene: str, drug: str) -> Dict[str, ToolPrediction]:
    """
    Execute all 10 Sapphire tools in parallel and return predictions.

    This is the main orchestrator function that DeMeo uses to get real
    tool predictions for Bayesian fusion.

    Args:
        gene: Gene symbol (e.g., 'SCN1A')
        drug: Drug name (e.g., 'Stiripentol')

    Returns:
        Dict mapping tool name to ToolPrediction with scores and confidences

    Example:
        >>> predictions = await get_all_tool_predictions('SCN1A', 'Stiripentol')
        >>> predictions['bbb_permeability']
        ToolPrediction(score=0.91, confidence=0.88)
    """
    # Execute all 10 tools in parallel for speed
    try:
        results = await asyncio.gather(
            get_antipodal_prediction(gene, drug),
            get_bbb_prediction(drug),
            get_adme_prediction(drug),
            get_mechanistic_prediction(gene, drug),
            get_clinical_prediction(gene, drug),
            get_interactions_prediction(drug),
            get_transcriptomic_prediction(gene, drug),      # Tool #7
            get_target_validation_prediction(gene, drug),   # Tool #8
            get_literature_prediction(gene, drug),          # Tool #9
            get_combination_prediction(gene, drug),         # Tool #10
            return_exceptions=True
        )

        # Map results to tool names (handle exceptions with fallback)
        return {
            "vector_antipodal": results[0] if not isinstance(results[0], Exception) else ToolPrediction(0.5, 0.5),
            "bbb_permeability": results[1] if not isinstance(results[1], Exception) else ToolPrediction(0.5, 0.5),
            "adme_tox": results[2] if not isinstance(results[2], Exception) else ToolPrediction(0.5, 0.5),
            "mechanistic_explainer": results[3] if not isinstance(results[3], Exception) else ToolPrediction(0.5, 0.5),
            "clinical_trials": results[4] if not isinstance(results[4], Exception) else ToolPrediction(0.5, 0.5),
            "drug_interactions": results[5] if not isinstance(results[5], Exception) else ToolPrediction(0.5, 0.5),
            "transcriptomic_rescue": results[6] if not isinstance(results[6], Exception) else ToolPrediction(0.5, 0.5),
            "target_validation": results[7] if not isinstance(results[7], Exception) else ToolPrediction(0.5, 0.5),
            "literature_evidence": results[8] if not isinstance(results[8], Exception) else ToolPrediction(0.5, 0.5),
            "rescue_combinations": results[9] if not isinstance(results[9], Exception) else ToolPrediction(0.5, 0.5)
        }

    except Exception as e:
        logger.error(f"Failed to execute all tools for {gene}/{drug}: {e}")

        # Return all fallback predictions
        return {
            "vector_antipodal": ToolPrediction(0.5, 0.5),
            "bbb_permeability": ToolPrediction(0.5, 0.5),
            "adme_tox": ToolPrediction(0.5, 0.5),
            "mechanistic_explainer": ToolPrediction(0.5, 0.5),
            "clinical_trials": ToolPrediction(0.5, 0.5),
            "drug_interactions": ToolPrediction(0.5, 0.5),
            "transcriptomic_rescue": ToolPrediction(0.5, 0.5),
            "target_validation": ToolPrediction(0.5, 0.5),
            "literature_evidence": ToolPrediction(0.5, 0.5),
            "rescue_combinations": ToolPrediction(0.5, 0.5)
        }
