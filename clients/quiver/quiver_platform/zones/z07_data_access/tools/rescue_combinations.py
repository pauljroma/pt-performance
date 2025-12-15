"""
Rescue Combinations Tool - Comprehensive Drug Rescue Discovery
===============================================================

COMPOSITE TOOL: Orchestrates multiple drug discovery strategies for comprehensive rescue analysis.

Architecture:
- Calls vector_antipodal for primary rescue candidates
- Calls drug_interactions for DDI warnings (Neo4j)
- Calls drug_lookalikes for patent alternatives
- Calls drug_combinations_synergy for synergistic pairs
- Aggregates results into unified recommendation report

Workflow:
1. Get top rescue candidates (vector_antipodal)
2. For each candidate:
   - Check DDI warnings (drug_interactions)
   - Find lookalike alternatives (drug_lookalikes)
3. Find synergistic combinations (drug_combinations_synergy)
4. Generate prioritized recommendations integrating all factors

Pattern: Composite tool calling atomic tools
Version: 1.0.0
Date: 2025-11-27
Author: claude-code-agent
"""

from typing import Dict, Any, List, Optional
from pathlib import Path
import sys
import asyncio

# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import harmonize_drug_id, validate_input, validate_tool_input, format_validation_response
    HARMONIZATION_AVAILABLE = True
    VALIDATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
    VALIDATION_AVAILABLE = False

# Add path for imports
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

# Import atomic tools
from zones.z07_data_access.tools import vector_antipodal
from zones.z07_data_access.tools import drug_interactions
from zones.z07_data_access.tools import drug_lookalikes
from zones.z07_data_access.tools import drug_combinations_synergy


# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "rescue_combinations",
    "description": """Comprehensive drug rescue discovery using multiple strategies (v6.0 FUSION-ENHANCED).

**v6.0 PERFORMANCE BOOST:** Now benefits from fusion table acceleration in underlying tools!
- drug_interactions: +27× faster with fusion-based predictions
- drug_lookalikes: +100× faster with pre-computed similarities

Orchestrates 4 complementary discovery methods:
1. Rescue Candidates - Antipodal embedding similarity (vector_antipodal)
2. DDI Warnings - Drug-drug interaction safety checks (Neo4j)
3. Lookalike Alternatives - Structural/target similarity for patent workarounds
4. Synergistic Combinations - Drugs with complementary mechanisms

Returns unified report with:
- Top rescue candidates ranked by score
- Safety warnings (DDI contraindications)
- Patent-free alternatives (lookalikes)
- Synergistic combination opportunities
- Prioritized recommendations integrating all factors

Example:
- "Comprehensive rescue for TSC2" → Returns rescue drugs + interactions + lookalikes + synergies
- "Find drug combinations for KCNQ2" → Multi-strategy analysis with safety + efficacy

Use cases:
- Drug repurposing with safety analysis
- Finding patent-free alternatives
- Identifying combination therapy opportunities
- Comprehensive rescue discovery workflow

Commercial names included for all drugs.
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "gene": {
                "type": "string",
                "description": "Target gene for rescue discovery. Examples: TSC2, SCN1A, KCNQ2, BRCA1"
            },
            "include_interactions": {
                "type": "boolean",
                "description": "Check drug-drug interactions (DDI) for top candidates. Default: true",
                "default": True
            },
            "include_lookalikes": {
                "type": "boolean",
                "description": "Find structural/target lookalikes for patent alternatives. Default: true",
                "default": True
            },
            "include_synergies": {
                "type": "boolean",
                "description": "Find synergistic drug combinations. Default: true",
                "default": True
            },
            "top_k": {
                "type": "integer",
                "description": "Number of rescue candidates to analyze (1-20). Default: 5",
                "default": 5,
                "minimum": 1,
                "maximum": 20
            },
            "min_rescue_score": {
                "type": "number",
                "description": "Minimum rescue score threshold (0-1). Default: 0.6",
                "default": 0.6,
                "minimum": 0.0,
                "maximum": 1.0
            }
        },
        "required": ["gene"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute rescue_combinations tool - comprehensive drug rescue discovery.

    Orchestrates multiple strategies:
    1. Vector antipodal rescue scoring
    2. Drug-drug interaction warnings
    3. Structural/target lookalike alternatives
    4. Synergistic combination discovery

    Args:
        tool_input: Dict with keys:
            - gene (str): Target gene symbol
            - include_interactions (bool, optional): Check DDI (default: True)
            - include_lookalikes (bool, optional): Find lookalikes (default: True)
            - include_synergies (bool, optional): Find synergies (default: True)
            - top_k (int, optional): Number of candidates (default: 5, max: 20)
            - min_rescue_score (float, optional): Min score threshold (default: 0.6)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - gene (str): Gene analyzed
            - rescue_candidates (List[Dict]): Top rescue drugs from vector_antipodal
            - interaction_warnings (List[Dict]): DDI contraindications
            - lookalike_alternatives (List[Dict]): Patent-free alternatives
            - synergistic_combinations (List[Dict]): Complementary drug pairs
            - recommendations (List[Dict]): Prioritized unified recommendations
            - summary (Dict): Aggregate statistics
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({"gene": "TSC2", "top_k": 5})
        {
            "success": True,
            "gene": "TSC2",
            "rescue_candidates": [
                {
                    "drug_id": "QS0318588_10uM",
                    "commercial_name": "Rapamycin",
                    "rescue_score": 0.726,
                    "tier": 4
                },
                ...
            ],
            "interaction_warnings": [
                {
                    "drug_pair": ["Rapamycin", "Tacrolimus"],
                    "severity": "major",
                    "interaction_type": "shared_target",
                    "description": "Both inhibit mTOR - additive immunosuppression"
                },
                ...
            ],
            "lookalike_alternatives": [
                {
                    "original_drug": "Rapamycin",
                    "lookalikes": [
                        {
                            "drug": "Temsirolimus",
                            "similarity_score": 0.89,
                            "shared_targets": 3,
                            "patent_status": "generic_available"
                        },
                        ...
                    ]
                },
                ...
            ],
            "synergistic_combinations": [
                {
                    "drug1_commercial_name": "Rapamycin",
                    "drug2_commercial_name": "Metformin",
                    "synergy_score": 0.82,
                    "interaction_type": "synergistic",
                    "complementarity": 0.75
                },
                ...
            ],
            "recommendations": [
                {
                    "rank": 1,
                    "drug": "Rapamycin",
                    "commercial_name": "Rapamycin",
                    "rescue_score": 0.726,
                    "safety_flag": "monitor",
                    "has_lookalikes": True,
                    "synergy_count": 2,
                    "recommendation": "Strong rescue candidate with lookalike alternatives and synergy potential"
                },
                ...
            ],
            "summary": {
                "total_candidates": 5,
                "major_interactions": 2,
                "lookalike_options": 12,
                "synergistic_pairs": 8,
                "safe_candidates": 3
            }
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "rescue_combinations")
        if validation_errors:
            return format_validation_response("rescue_combinations", validation_errors)

    try:
        # Extract parameters with defaults
        gene = tool_input["gene"]
        include_interactions = tool_input.get("include_interactions", True)
        include_lookalikes = tool_input.get("include_lookalikes", True)
        include_synergies = tool_input.get("include_synergies", True)
        top_k = tool_input.get("top_k", 5)
        min_rescue_score = tool_input.get("min_rescue_score", 0.6)

        # Validate parameters
        if not gene or not isinstance(gene, str):
            return {
                "success": False,
                "error": "Gene parameter must be a non-empty string",
                "hint": "Examples: TSC2, SCN1A, KCNQ2, BRCA1"
            }

        if not (1 <= top_k <= 20):
            return {
                "success": False,
                "error": f"top_k must be between 1 and 20, got {top_k}"
            }

        if not (0.0 <= min_rescue_score <= 1.0):
            return {
                "success": False,
                "error": f"min_rescue_score must be between 0.0 and 1.0, got {min_rescue_score}"
            }

        # Initialize result structure
        result = {
            "success": True,
            "gene": gene,
            "rescue_candidates": [],
            "interaction_warnings": [],
            "lookalike_alternatives": [],
            "synergistic_combinations": [],
            "recommendations": [],
            "summary": {},
            "execution_log": []
        }

        # =================================================================
        # STEP 1: Get top rescue candidates (vector_antipodal)
        # =================================================================
        result["execution_log"].append("Fetching rescue candidates via vector_antipodal...")

        antipodal_result = await vector_antipodal.execute({
            "gene": gene,
            "top_k": top_k,
            "min_score": min_rescue_score
        })

        if not antipodal_result.get("success"):
            return {
                "success": False,
                "error": f"Failed to get rescue candidates: {antipodal_result.get('error', 'unknown')}",
                "gene": gene,
                "antipodal_result": antipodal_result
            }

        result["rescue_candidates"] = antipodal_result.get("rescue_candidates", [])
        result["gene"] = antipodal_result.get("gene", gene)  # Use normalized gene name
        result["execution_log"].append(f"Found {len(result['rescue_candidates'])} rescue candidates")

        if not result["rescue_candidates"]:
            result_dict = {
                "success": True,
                "gene": result["gene"],
                "rescue_candidates": [],
                "message": f"No rescue candidates found for {result['gene']} above threshold {min_rescue_score}",
                "hint": "Try lowering min_rescue_score or check gene symbol spelling"
            }

            return result_dict

        # Extract drug commercial names for further analysis
        candidate_drugs = [
            {
                "drug": c.get("drug", c.get("commercial_name", "Unknown")),
                "screening_id": c.get("screening_id", c.get("drug_id", ""))
            }
            for c in result["rescue_candidates"]
        ]

        # =================================================================
        # STEP 2: Check drug-drug interactions (DDI)
        # =================================================================
        if include_interactions and len(candidate_drugs) > 1:
            result["execution_log"].append("Checking drug-drug interactions...")

            try:
                # Check pairwise interactions for all candidates
                interactions_all = []

                for i, drug_a in enumerate(candidate_drugs):
                    # Query interactions for this drug
                    ddi_result = await drug_interactions.execute({
                        "drug": drug_a["drug"],
                        "max_results": 100  # Get all to filter to our candidates
                    })

                    if ddi_result.get("success"):
                        # Filter to interactions with other candidates
                        candidate_names = {d.get("commercial_name", d.get("drug", "Unknown")) for d in candidate_drugs}
                        for interaction in ddi_result.get("interactions", []):
                            interaction_name = interaction.get("commercial_name", interaction.get("drug", "Unknown"))
                            if interaction_name in candidate_names:
                                # Avoid duplicates (A-B and B-A)
                                drug_a_name = drug_a.get("commercial_name", drug_a.get("drug", "Unknown"))
                                pair = tuple(sorted([drug_a_name, interaction_name]))
                                if not any(
                                    tuple(sorted(w["drug_pair"])) == pair
                                    for w in interactions_all
                                ):
                                    interactions_all.append({
                                        "drug_pair": [drug_a_name, interaction_name],
                                        "drug_ids": [drug_a.get("drug_id", drug_a.get("screening_id", "")), interaction.get("drug_id", interaction.get("screening_id", ""))],
                                        "severity": interaction["severity"],
                                        "interaction_type": interaction["interaction_type"],
                                        "description": interaction["description"],
                                        "confidence_score": interaction.get("confidence_score", 0.0),
                                        "shared_targets": interaction.get("shared_targets", [])
                                    })

                result["interaction_warnings"] = interactions_all
                result["execution_log"].append(f"Found {len(interactions_all)} interaction warnings")

            except Exception as e:
                result["execution_log"].append(f"DDI check failed: {str(e)}")
                result["interaction_warnings"] = []

        # =================================================================
        # STEP 3: Find lookalike alternatives
        # =================================================================
        if include_lookalikes and candidate_drugs:
            result["execution_log"].append("Finding lookalike alternatives...")

            try:
                lookalike_groups = []

                for drug in candidate_drugs:
                    drug_name = drug.get("commercial_name", drug.get("drug", "Unknown"))
                    lookalike_result = await drug_lookalikes.execute({
                        "drug": drug_name,
                        "similarity_threshold": 0.8,  # High similarity for good alternatives
                        "max_results": 5  # Top 5 lookalikes per drug
                    })

                    if lookalike_result.get("success") and lookalike_result.get("lookalikes"):
                        lookalike_groups.append({
                            "original_drug": drug_name,
                            "original_drug_id": drug.get("drug_id", drug.get("screening_id", "")),
                            "lookalikes": lookalike_result["lookalikes"]
                        })

                result["lookalike_alternatives"] = lookalike_groups
                total_lookalikes = sum(len(g["lookalikes"]) for g in lookalike_groups)
                result["execution_log"].append(f"Found {total_lookalikes} lookalike alternatives")

            except Exception as e:
                result["execution_log"].append(f"Lookalike search failed: {str(e)}")
                result["lookalike_alternatives"] = []

        # =================================================================
        # STEP 4: Find synergistic combinations
        # =================================================================
        if include_synergies and len(candidate_drugs) >= 2:
            result["execution_log"].append("Identifying synergistic combinations...")

            try:
                synergies = []

                # For each rescue candidate, find synergistic partners among other candidates
                for i, drug in enumerate(candidate_drugs[:min(3, len(candidate_drugs))]):  # Limit to top 3 to avoid explosion
                    synergy_result = await drug_combinations_synergy.execute({
                        "drug1": drug.get("drug", "Unknown"),
                        "target_gene": result["gene"],
                        "top_k": 10,
                        "min_synergy_score": 0.6
                    })

                    if synergy_result.get("success") and synergy_result.get("combinations"):
                        # Filter to combinations with other rescue candidates
                        candidate_names = {d.get("drug", "Unknown") for d in candidate_drugs}
                        for combo in synergy_result["combinations"]:
                            # Only include if both drugs are in our candidate list
                            if combo["drug2_commercial_name"] in candidate_names:
                                # Avoid duplicates
                                pair = tuple(sorted([combo["drug1_commercial_name"], combo["drug2_commercial_name"]]))
                                if not any(
                                    tuple(sorted([s["drug1_commercial_name"], s["drug2_commercial_name"]])) == pair
                                    for s in synergies
                                ):
                                    synergies.append(combo)

                result["synergistic_combinations"] = synergies
                result["execution_log"].append(f"Found {len(synergies)} synergistic pairs")

            except Exception as e:
                result["execution_log"].append(f"Synergy analysis failed: {str(e)}")
                result["synergistic_combinations"] = []

        # =================================================================
        # STEP 5: Generate prioritized recommendations
        # =================================================================
        result["execution_log"].append("Generating prioritized recommendations...")

        recommendations = _generate_recommendations(
            rescue_candidates=result["rescue_candidates"],
            interactions=result["interaction_warnings"],
            lookalikes=result["lookalike_alternatives"],
            synergies=result["synergistic_combinations"]
        )
        result["recommendations"] = recommendations

        # =================================================================
        # STEP 6: Generate summary statistics
        # =================================================================
        result["summary"] = _generate_summary(result)
        result["execution_log"].append("Comprehensive rescue analysis complete")

        return result

    except Exception as e:
        return {
            "success": False,
            "error": f"Unexpected error in rescue_combinations: {str(e)}",
            "gene": tool_input.get("gene", "unknown"),
            "error_type": type(e).__name__
        }


# =============================================================================
# Helper Functions: Recommendation Generation
# =============================================================================

def _generate_recommendations(
    rescue_candidates: List[Dict],
    interactions: List[Dict],
    lookalikes: List[Dict],
    synergies: List[Dict]
) -> List[Dict]:
    """
    Generate prioritized recommendations integrating all factors.

    Scoring:
    - Base: rescue_score (0-1)
    - Penalty: major DDI interactions (-0.3), moderate (-0.15), minor (-0.05)
    - Bonus: has lookalikes (+0.1)
    - Bonus: synergistic combinations (+0.05 per synergy, max +0.2)

    Args:
        rescue_candidates: List of rescue drugs
        interactions: List of DDI warnings
        lookalikes: List of lookalike groups
        synergies: List of synergistic pairs

    Returns:
        Sorted list of recommendations with integrated scoring
    """
    # Build interaction lookup by commercial name
    interaction_map = {}  # commercial_name -> list of interactions
    for interaction in interactions:
        for drug_name in interaction["drug_pair"]:
            if drug_name not in interaction_map:
                interaction_map[drug_name] = []
            interaction_map[drug_name].append(interaction)

    # Build lookalike lookup by commercial name
    lookalike_map = {}  # commercial_name -> count
    for group in lookalikes:
        lookalike_map[group["original_drug"]] = len(group["lookalikes"])

    # Build synergy lookup by commercial name
    synergy_map = {}  # commercial_name -> count
    for synergy in synergies:
        for drug_name in [synergy["drug1_commercial_name"], synergy["drug2_commercial_name"]]:
            synergy_map[drug_name] = synergy_map.get(drug_name, 0) + 1

    # Generate recommendations
    recommendations = []

    for candidate in rescue_candidates:
        drug_id = candidate.get("drug_id", candidate.get("screening_id", ""))
        commercial_name = candidate.get("commercial_name", candidate.get("drug", "Unknown"))
        rescue_score = candidate.get("rescue_score", 0.0)

        # Calculate integrated score
        score = rescue_score

        # Apply DDI penalties
        safety_flag = "safe"
        if commercial_name in interaction_map:
            drug_interactions_list = interaction_map[commercial_name]
            major_count = sum(1 for i in drug_interactions_list if i["severity"] == "major")
            moderate_count = sum(1 for i in drug_interactions_list if i["severity"] == "moderate")
            minor_count = sum(1 for i in drug_interactions_list if i["severity"] == "minor")

            score -= major_count * 0.3
            score -= moderate_count * 0.15
            score -= minor_count * 0.05

            if major_count > 0:
                safety_flag = "contraindicated"
            elif moderate_count > 0:
                safety_flag = "monitor"
            else:
                safety_flag = "minor_interactions"

        # Apply lookalike bonus
        has_lookalikes = commercial_name in lookalike_map
        if has_lookalikes:
            score += 0.1

        # Apply synergy bonus
        synergy_count = synergy_map.get(commercial_name, 0)
        score += min(synergy_count * 0.05, 0.2)

        # Clamp score to [0, 1]
        score = max(0.0, min(1.0, score))

        # Generate recommendation text
        recommendation_parts = []
        if rescue_score >= 0.8:
            recommendation_parts.append("Excellent rescue candidate")
        elif rescue_score >= 0.7:
            recommendation_parts.append("Strong rescue candidate")
        elif rescue_score >= 0.6:
            recommendation_parts.append("Good rescue candidate")
        else:
            recommendation_parts.append("Moderate rescue candidate")

        if safety_flag == "contraindicated":
            recommendation_parts.append("CONTRAINDICATED - major DDI warnings")
        elif safety_flag == "monitor":
            recommendation_parts.append("requires monitoring (DDI)")
        elif safety_flag == "minor_interactions":
            recommendation_parts.append("minor interactions noted")

        if has_lookalikes:
            recommendation_parts.append(f"has {lookalike_map[commercial_name]} lookalike alternatives")

        if synergy_count > 0:
            recommendation_parts.append(f"{synergy_count} synergistic combinations")

        recommendations.append({
            "drug": commercial_name,  # v3.1: PRIMARY field - use for display
            "rescue_score": rescue_score,
            "integrated_score": round(score, 3),
            "safety_flag": safety_flag,
            "has_lookalikes": has_lookalikes,
            "lookalike_count": lookalike_map.get(commercial_name, 0),
            "synergy_count": synergy_count,
            "tier": candidate.get("tier", 0),
            "screening_id": drug_id,  # QS ID for traceability (internal)
            "recommendation": "; ".join(recommendation_parts)
        })

    # Sort by integrated score
    recommendations.sort(key=lambda x: x["integrated_score"], reverse=True)

    # Add rank
    for rank, rec in enumerate(recommendations, start=1):
        rec["rank"] = rank

    return recommendations


def _generate_summary(result: Dict) -> Dict:
    """Generate summary statistics."""
    return {
        "total_candidates": len(result["rescue_candidates"]),
        "major_interactions": sum(
            1 for i in result["interaction_warnings"] if i["severity"] == "major"
        ),
        "moderate_interactions": sum(
            1 for i in result["interaction_warnings"] if i["severity"] == "moderate"
        ),
        "total_interactions": len(result["interaction_warnings"]),
        "lookalike_options": sum(
            len(g["lookalikes"]) for g in result["lookalike_alternatives"]
        ),
        "drugs_with_lookalikes": len(result["lookalike_alternatives"]),
        "synergistic_pairs": len(result["synergistic_combinations"]),
        "safe_candidates": sum(
            1 for r in result["recommendations"] if r["safety_flag"] == "safe"
        ),
        "top_recommendation": result["recommendations"][0]["drug"] if result["recommendations"] else None,
        "top_integrated_score": result["recommendations"][0]["integrated_score"] if result["recommendations"] else 0.0
    }


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
