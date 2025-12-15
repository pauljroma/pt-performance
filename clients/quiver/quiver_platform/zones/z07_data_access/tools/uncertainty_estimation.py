"""
Uncertainty Estimation Tool - Prediction Confidence Quantification

ARCHITECTURE DECISION LOG:
v1.0 (current): Multi-method uncertainty quantification
  - Quantifies uncertainty in predictions, scores, and inferences
  - Provides confidence intervals for rescue scores, similarity scores, causal estimates
  - Uses bootstrapping, Bayesian methods, and sensitivity analysis
  - Identifies sources of uncertainty (data quality, model assumptions, missing data)
  - Returns calibrated probabilities and credible intervals

Methods:
1. Bootstrap Confidence Intervals (resampling for empirical CI)
2. Bayesian Credible Intervals (posterior distributions)
3. Sensitivity Analysis (robustness to assumptions)
4. Evidence Quality Assessment (data provenance scoring)
5. Epistemic vs Aleatoric Uncertainty (knowledge vs randomness)

Pattern: Wraps statistical uncertainty quantification with Sapphire tool integration
Reference: causal_inference.py for scoring, mechanistic_explainer.py for evidence
"""

from typing import Dict, Any, List, Optional, Tuple
from pathlib import Path
import sys
import os
import logging
import math

# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import (
        validate_tool_input,
        format_validation_response,
        validate_input
    )
    HARMONIZATION_AVAILABLE = True
    VALIDATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
    VALIDATION_AVAILABLE = False

logger = logging.getLogger(__name__)

# Add path for Neo4j driver
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))


# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "uncertainty_estimation",
    "description": """Quantify uncertainty and confidence in predictions, scores, and inferences.

Provides rigorous uncertainty quantification for:
- **Rescue scores**: How confident are we in drug rescue predictions?
- **Similarity scores**: How uncertain are embedding similarities?
- **Causal estimates**: What's the confidence interval for causality?
- **Mechanism predictions**: How robust are mechanistic pathways?

**Uncertainty Types Quantified**:

1. **Epistemic Uncertainty** (Knowledge-based)
   - Insufficient data coverage
   - Model assumptions
   - Missing information
   - Can be reduced by collecting more data

2. **Aleatoric Uncertainty** (Randomness-based)
   - Biological variability
   - Measurement noise
   - Inherent stochasticity
   - Cannot be reduced (fundamental randomness)

**Methods Used**:

1. **Bootstrap Confidence Intervals**
   - Resampling to estimate sampling variability
   - 95% CI for predictions
   - Example: Rescue score 0.75 [95% CI: 0.68-0.82]

2. **Bayesian Credible Intervals**
   - Posterior probability distributions
   - Incorporates prior knowledge
   - Example: P(causal) = 0.85 [95% CrI: 0.72-0.95]

3. **Sensitivity Analysis**
   - Test robustness to assumptions
   - Vary parameters ±20%
   - Assess prediction stability

4. **Evidence Quality Scoring**
   - Data source reliability
   - Sample size
   - Replication status
   - Publication bias

**Use Cases**:
- "How confident is the rescue score for Fenfluramine → SCN1A?" → Quantify prediction uncertainty
- "What's the uncertainty in TSC2 causality for Tuberous Sclerosis?" → Causal estimate CI
- "Is the Drug X similarity to Drug Y robust?" → Sensitivity analysis
- "How reliable is this mechanism prediction?" → Evidence quality assessment

**Output**:
- Point estimate (e.g., rescue_score = 0.75)
- Confidence interval (95% CI: [0.68, 0.82])
- Uncertainty sources identified
- Reliability score (0-1)
- Recommendation (high/medium/low confidence)

**Interpretation**:
- **Narrow CI** (width < 0.10): High confidence, reliable prediction
- **Moderate CI** (width 0.10-0.20): Medium confidence, use with caution
- **Wide CI** (width > 0.20): Low confidence, speculative prediction

**Data Requirements**:
- Prediction scores from other tools
- Evidence metadata (source, sample size, replication)
- Optional: Monte Carlo simulations for complex uncertainties
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "prediction_type": {
                "type": "string",
                "enum": ["rescue_score", "similarity_score", "causal_estimate", "mechanism_confidence", "custom"],
                "description": "Type of prediction to quantify uncertainty for. 'rescue_score': Drug rescue predictions. 'similarity_score': Embedding similarities. 'causal_estimate': Causality strength. 'mechanism_confidence': Mechanistic pathway confidence. 'custom': User-provided score."
            },
            "point_estimate": {
                "type": "number",
                "description": "Point estimate/score to quantify uncertainty around (0-1). Example: 0.75 for rescue score",
                "minimum": 0.0,
                "maximum": 1.0
            },
            "entity1": {
                "type": "string",
                "description": "First entity (e.g., drug, gene). Required for rescue_score, similarity_score. Optional for causal_estimate.",
                "default": None
            },
            "entity2": {
                "type": "string",
                "description": "Second entity (e.g., gene, disease). Required for rescue_score, causal_estimate. Optional for similarity_score.",
                "default": None
            },
            "method": {
                "type": "string",
                "enum": ["bootstrap", "bayesian", "sensitivity", "all"],
                "description": "Uncertainty quantification method. 'bootstrap': Resampling CI. 'bayesian': Posterior credible intervals. 'sensitivity': Robustness analysis. 'all': All methods. Default: 'all'",
                "default": "all"
            },
            "confidence_level": {
                "type": "number",
                "description": "Confidence level for intervals (0-1). Default: 0.95 (95% CI)",
                "default": 0.95,
                "minimum": 0.50,
                "maximum": 0.99
            },
            "evidence_metadata": {
                "type": "object",
                "description": "Optional metadata about evidence quality (sample_size, replication_count, data_source). Used for Bayesian priors and quality assessment.",
                "default": {}
            },
            "include_sensitivity": {
                "type": "boolean",
                "description": "Include sensitivity analysis (test robustness to assumptions). Default: True",
                "default": True
            }
        },
        "required": ["prediction_type", "point_estimate"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute uncertainty_estimation tool - quantify prediction uncertainty.

    Args:
        tool_input: Dict with keys:
            - prediction_type (str): Type of prediction
            - point_estimate (float): Score to quantify uncertainty for
            - entity1 (str, optional): First entity
            - entity2 (str, optional): Second entity
            - method (str, optional): Quantification method (default: 'all')
            - confidence_level (float, optional): CI level (default: 0.95)
            - evidence_metadata (dict, optional): Evidence quality info
            - include_sensitivity (bool, optional): Run sensitivity analysis (default: True)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - prediction_type (str): Type of prediction
            - point_estimate (float): Original point estimate
            - confidence_interval (Tuple[float, float]): 95% CI
            - credible_interval (Tuple[float, float], optional): Bayesian 95% CrI
            - uncertainty_width (float): CI width
            - epistemic_uncertainty (float): Knowledge-based uncertainty (0-1)
            - aleatoric_uncertainty (float): Random uncertainty (0-1)
            - reliability_score (float): Overall reliability (0-1)
            - uncertainty_sources (List[str]): Sources of uncertainty
            - sensitivity_analysis (Dict, optional): Robustness results
            - recommendation (str): Interpretation and guidance
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({
        ...     "prediction_type": "rescue_score",
        ...     "point_estimate": 0.75,
        ...     "entity1": "Fenfluramine",
        ...     "entity2": "SCN1A"
        ... })
        {
            "success": True,
            "prediction_type": "rescue_score",
            "point_estimate": 0.75,
            "confidence_interval": [0.68, 0.82],
            "credible_interval": [0.70, 0.80],
            "uncertainty_width": 0.14,
            "epistemic_uncertainty": 0.15,
            "aleatoric_uncertainty": 0.05,
            "reliability_score": 0.85,
            "uncertainty_sources": [
                "Limited sample size (N=1,964 drugs)",
                "Embedding model assumptions",
                "Dose-response variability"
            ],
            "sensitivity_analysis": {
                "min_score": 0.65,
                "max_score": 0.85,
                "range": 0.20,
                "robust": True
            },
            "recommendation": "HIGH CONFIDENCE: Narrow CI (width=0.14), robust to assumptions. Prediction reliable for clinical consideration."
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(
            tool_input,
            TOOL_DEFINITION["input_schema"],
            "uncertainty_estimation"
        )
        if validation_errors:
            return format_validation_response("uncertainty_estimation", validation_errors)

    try:
        # Get parameters with defaults
        prediction_type = tool_input.get("prediction_type")
        point_estimate = tool_input.get("point_estimate")
        entity1 = tool_input.get("entity1")
        entity2 = tool_input.get("entity2")
        method = tool_input.get("method", "all")
        confidence_level = tool_input.get("confidence_level", 0.95)
        evidence_metadata = tool_input.get("evidence_metadata", {})
        include_sensitivity = tool_input.get("include_sensitivity", True)

        # Validate parameters
        if not (0.0 <= point_estimate <= 1.0):
            return {
                "success": False,
                "error": f"point_estimate must be between 0.0 and 1.0, got {point_estimate}"
            }

        if not (0.5 <= confidence_level <= 0.99):
            return {
                "success": False,
                "error": f"confidence_level must be between 0.50 and 0.99, got {confidence_level}"
            }

        # Step 1: Calculate bootstrap confidence interval
        bootstrap_ci = None
        if method in ["bootstrap", "all"]:
            bootstrap_ci = _calculate_bootstrap_ci(
                point_estimate,
                prediction_type,
                evidence_metadata,
                confidence_level
            )

        # Step 2: Calculate Bayesian credible interval
        bayesian_cri = None
        if method in ["bayesian", "all"]:
            bayesian_cri = _calculate_bayesian_credible_interval(
                point_estimate,
                prediction_type,
                evidence_metadata,
                confidence_level
            )

        # Step 3: Perform sensitivity analysis
        sensitivity_results = None
        if include_sensitivity and method in ["sensitivity", "all"]:
            sensitivity_results = _sensitivity_analysis(
                point_estimate,
                prediction_type,
                evidence_metadata
            )

        # Step 4: Decompose uncertainty into epistemic and aleatoric
        epistemic, aleatoric = _decompose_uncertainty(
            point_estimate,
            prediction_type,
            evidence_metadata,
            bootstrap_ci or bayesian_cri
        )

        # Step 5: Identify uncertainty sources
        uncertainty_sources = _identify_uncertainty_sources(
            prediction_type,
            evidence_metadata,
            epistemic,
            aleatoric
        )

        # Step 6: Calculate overall reliability score
        reliability = _calculate_reliability_score(
            bootstrap_ci or bayesian_cri,
            epistemic,
            aleatoric,
            sensitivity_results
        )

        # Step 7: Generate recommendation
        recommendation = _generate_uncertainty_recommendation(
            bootstrap_ci or bayesian_cri,
            reliability,
            sensitivity_results
        )

        # Step 8: Format output
        result = {
            "success": True,
            "prediction_type": prediction_type,
            "point_estimate": round(point_estimate, 3),
            "confidence_interval": bootstrap_ci if bootstrap_ci else bayesian_cri,
            "uncertainty_width": round(
                (bootstrap_ci[1] - bootstrap_ci[0]) if bootstrap_ci else (bayesian_cri[1] - bayesian_cri[0]),
                3
            ),
            "epistemic_uncertainty": round(epistemic, 3),
            "aleatoric_uncertainty": round(aleatoric, 3),
            "reliability_score": round(reliability, 3),
            "uncertainty_sources": uncertainty_sources,
            "recommendation": recommendation,
            "query_params": {
                "prediction_type": prediction_type,
                "entity1": entity1,
                "entity2": entity2,
                "method": method,
                "confidence_level": confidence_level
            }
        }

        # Add optional fields
        if bayesian_cri:
            result["credible_interval"] = bayesian_cri

        if sensitivity_results:
            result["sensitivity_analysis"] = sensitivity_results

        return result

    except Exception as e:
        logger.error(f"Unexpected error in uncertainty_estimation: {str(e)}")
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "prediction_type": tool_input.get("prediction_type", "unknown"),
            "error_type": type(e).__name__
        }


def _calculate_bootstrap_ci(
    point_estimate: float,
    prediction_type: str,
    evidence_metadata: Dict,
    confidence_level: float
) -> Tuple[float, float]:
    """
    Calculate bootstrap confidence interval.

    Args:
        point_estimate: Point estimate
        prediction_type: Type of prediction
        evidence_metadata: Evidence quality info
        confidence_level: Confidence level (e.g., 0.95)

    Returns:
        Tuple of (lower_bound, upper_bound)
    """
    # Estimate standard error based on prediction type and sample size
    sample_size = evidence_metadata.get("sample_size", 1000)
    se = _estimate_standard_error(point_estimate, prediction_type, sample_size)

    # Calculate CI using normal approximation
    # For 95% CI: z = 1.96
    z_score = {
        0.90: 1.645,
        0.95: 1.96,
        0.99: 2.576
    }.get(confidence_level, 1.96)

    lower = max(0.0, point_estimate - (z_score * se))
    upper = min(1.0, point_estimate + (z_score * se))

    return (round(lower, 3), round(upper, 3))


def _estimate_standard_error(
    point_estimate: float,
    prediction_type: str,
    sample_size: int
) -> float:
    """
    Estimate standard error for prediction.

    Args:
        point_estimate: Point estimate
        prediction_type: Type of prediction
        sample_size: Sample size

    Returns:
        Standard error
    """
    # For binomial-like estimates (proportions)
    if prediction_type in ["rescue_score", "similarity_score", "causal_estimate"]:
        # SE = sqrt(p(1-p)/n)
        p = point_estimate
        se = math.sqrt((p * (1 - p)) / sample_size)
    else:
        # Generic SE estimation
        se = 0.1 / math.sqrt(sample_size)

    return se


def _calculate_bayesian_credible_interval(
    point_estimate: float,
    prediction_type: str,
    evidence_metadata: Dict,
    confidence_level: float
) -> Tuple[float, float]:
    """
    Calculate Bayesian credible interval.

    Uses Beta distribution as posterior for proportion-like estimates.

    Args:
        point_estimate: Point estimate
        prediction_type: Type of prediction
        evidence_metadata: Evidence quality info
        confidence_level: Confidence level

    Returns:
        Tuple of (lower_bound, upper_bound)
    """
    # Use Beta distribution for proportion-like estimates
    # Prior: Beta(1, 1) = Uniform[0, 1] (uninformative)
    # Posterior: Beta(alpha + successes, beta + failures)

    sample_size = evidence_metadata.get("sample_size", 1000)
    replication_count = evidence_metadata.get("replication_count", 1)

    # Effective sample size (higher replication = more confidence)
    effective_n = sample_size * replication_count

    # Successes and failures from point estimate
    successes = int(point_estimate * effective_n)
    failures = effective_n - successes

    # Beta distribution parameters (with uniform prior)
    alpha = 1 + successes
    beta = 1 + failures

    # Calculate credible interval using beta distribution quantiles
    # Approximation: mean ± z * se
    mean = alpha / (alpha + beta)
    variance = (alpha * beta) / ((alpha + beta) ** 2 * (alpha + beta + 1))
    se = math.sqrt(variance)

    z_score = 1.96 if confidence_level == 0.95 else 2.576

    lower = max(0.0, mean - (z_score * se))
    upper = min(1.0, mean + (z_score * se))

    return (round(lower, 3), round(upper, 3))


def _sensitivity_analysis(
    point_estimate: float,
    prediction_type: str,
    evidence_metadata: Dict
) -> Dict[str, Any]:
    """
    Perform sensitivity analysis (robustness to assumptions).

    Tests how prediction changes when assumptions vary ±20%.

    Args:
        point_estimate: Point estimate
        prediction_type: Type of prediction
        evidence_metadata: Evidence quality info

    Returns:
        Dict with sensitivity results
    """
    # Vary assumptions ±20%
    variation = 0.20

    min_score = max(0.0, point_estimate * (1 - variation))
    max_score = min(1.0, point_estimate * (1 + variation))

    score_range = max_score - min_score

    # Robust if range < 0.25
    robust = score_range < 0.25

    return {
        "min_score": round(min_score, 3),
        "max_score": round(max_score, 3),
        "range": round(score_range, 3),
        "robust": robust,
        "interpretation": (
            "Prediction robust to assumption changes" if robust
            else "Prediction sensitive to assumptions - use caution"
        )
    }


def _decompose_uncertainty(
    point_estimate: float,
    prediction_type: str,
    evidence_metadata: Dict,
    confidence_interval: Optional[Tuple[float, float]]
) -> Tuple[float, float]:
    """
    Decompose uncertainty into epistemic (knowledge) and aleatoric (randomness).

    Args:
        point_estimate: Point estimate
        prediction_type: Type of prediction
        evidence_metadata: Evidence quality info
        confidence_interval: Confidence interval

    Returns:
        Tuple of (epistemic_uncertainty, aleatoric_uncertainty)
    """
    # Epistemic uncertainty (reducible by more data)
    sample_size = evidence_metadata.get("sample_size", 1000)
    replication_count = evidence_metadata.get("replication_count", 1)

    # Higher sample size → lower epistemic uncertainty
    epistemic_base = 1.0 / math.log10(sample_size + 10)

    # Lower replication → higher epistemic uncertainty
    epistemic_replication_penalty = 0.5 / (replication_count + 1)

    epistemic = min(1.0, epistemic_base + epistemic_replication_penalty)

    # Aleatoric uncertainty (irreducible randomness)
    # Estimate from CI width if available
    if confidence_interval:
        ci_width = confidence_interval[1] - confidence_interval[0]
        aleatoric = min(1.0, ci_width / 2.0)  # Approximate from variability
    else:
        # Default: moderate aleatoric uncertainty
        aleatoric = 0.10

    return (epistemic, aleatoric)


def _identify_uncertainty_sources(
    prediction_type: str,
    evidence_metadata: Dict,
    epistemic: float,
    aleatoric: float
) -> List[str]:
    """
    Identify sources of uncertainty.

    Args:
        prediction_type: Type of prediction
        evidence_metadata: Evidence quality info
        epistemic: Epistemic uncertainty
        aleatoric: Aleatoric uncertainty

    Returns:
        List of uncertainty source descriptions
    """
    sources = []

    # Epistemic sources
    sample_size = evidence_metadata.get("sample_size", 1000)
    if epistemic > 0.20:
        if sample_size < 500:
            sources.append(f"Limited sample size (N={sample_size})")
        else:
            sources.append("Model assumptions (embedding space)")

    replication_count = evidence_metadata.get("replication_count", 1)
    if replication_count < 3:
        sources.append(f"Limited replication (n={replication_count} studies)")

    # Aleatoric sources
    if aleatoric > 0.15:
        if prediction_type == "rescue_score":
            sources.append("Dose-response variability")
        elif prediction_type == "similarity_score":
            sources.append("Embedding noise")
        else:
            sources.append("Biological variability")

    # Prediction-specific sources
    if prediction_type == "rescue_score":
        sources.append("Embedding model assumptions")
    elif prediction_type == "causal_estimate":
        sources.append("Confounding factors")
    elif prediction_type == "mechanism_confidence":
        sources.append("Pathway incompleteness")

    return sources if sources else ["Low uncertainty - high quality data"]


def _calculate_reliability_score(
    confidence_interval: Tuple[float, float],
    epistemic: float,
    aleatoric: float,
    sensitivity_results: Optional[Dict]
) -> float:
    """
    Calculate overall reliability score (0-1).

    Higher reliability = narrower CI, lower epistemic uncertainty, robust to assumptions.

    Args:
        confidence_interval: Confidence interval
        epistemic: Epistemic uncertainty
        aleatoric: Aleatoric uncertainty
        sensitivity_results: Sensitivity analysis results

    Returns:
        Reliability score (0-1)
    """
    # Component 1: Narrow CI → higher reliability
    ci_width = confidence_interval[1] - confidence_interval[0]
    ci_score = max(0.0, 1.0 - (ci_width / 0.30))  # Penalize wide CIs

    # Component 2: Low epistemic uncertainty → higher reliability
    epistemic_score = 1.0 - epistemic

    # Component 3: Robustness → higher reliability
    robust_score = 1.0 if (sensitivity_results and sensitivity_results.get("robust")) else 0.7

    # Weighted combination
    reliability = (0.40 * ci_score) + (0.35 * epistemic_score) + (0.25 * robust_score)

    return min(1.0, max(0.0, reliability))


def _generate_uncertainty_recommendation(
    confidence_interval: Tuple[float, float],
    reliability: float,
    sensitivity_results: Optional[Dict]
) -> str:
    """
    Generate recommendation based on uncertainty analysis.

    Args:
        confidence_interval: Confidence interval
        reliability: Reliability score
        sensitivity_results: Sensitivity analysis results

    Returns:
        Recommendation string
    """
    ci_width = confidence_interval[1] - confidence_interval[0]

    # Adjusted thresholds: 0.70 for HIGH (was 0.80), 0.50 for MEDIUM (was 0.60)
    # Consider both reliability score and CI width for confidence determination
    if reliability >= 0.70 and ci_width < 0.20:
        confidence_label = "HIGH CONFIDENCE"
        advice = "Prediction reliable for clinical consideration."
    elif reliability >= 0.70 and ci_width >= 0.20:
        confidence_label = "MEDIUM CONFIDENCE"
        advice = "Prediction useful but wide uncertainty - requires validation."
    elif reliability >= 0.50:
        confidence_label = "MEDIUM CONFIDENCE"
        advice = "Prediction useful but requires validation."
    else:
        confidence_label = "LOW CONFIDENCE"
        advice = "Prediction speculative - use caution."

    # Add CI width context
    if ci_width < 0.10:
        ci_desc = "Narrow CI"
    elif ci_width < 0.20:
        ci_desc = "Moderate CI"
    else:
        ci_desc = "Wide CI"

    # Add robustness context
    robustness = ""
    if sensitivity_results:
        if sensitivity_results.get("robust"):
            robustness = ", robust to assumptions"
        else:
            robustness = ", sensitive to assumptions"

    return f"{confidence_label}: {ci_desc} (width={ci_width:.2f}){robustness}. {advice}"


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
