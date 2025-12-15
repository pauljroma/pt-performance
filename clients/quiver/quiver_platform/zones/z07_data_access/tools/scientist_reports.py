#!/usr/bin/env python3
"""
Scientist Reports Tool for Sapphire v3.16

Generates comprehensive disease reports with AI grading, visualizations, and insights.
Powered by the unified report system - all modes use same core engine.

Available Diseases:
- epilepsy: Epilepsy (SCN1A, SCN2A, GABAergic pathways)
- als: Amyotrophic Lateral Sclerosis (SOD1, TDP-43, motor neurons)
- parkinsons: Parkinson's Disease (SNCA, LRRK2, dopamine pathways)
- alzheimers: Alzheimer's Disease (APP, APOE, amyloid beta)
- pain: Chronic Pain (SCN9A, TRPV1, nociception)
- glp1: GLP-1 Therapeutics (GLP1R, incretin pathways)

Features:
- Neo4j knowledge graph queries (genes, drugs, pathways, patterns)
- AI-powered grading system (A+ to D)
- Interactive Plotly visualizations (t-SNE, bar charts, networks)
- Learned patterns from historical discoveries
- Drug-gene embedding relationships

Author: claude-code-agent
Date: 2025-12-01
Version: 1.0
"""

import json
import sys
from pathlib import Path
from typing import Dict, Any, List, Optional

# Add reporting module to path
_file_path = Path(__file__).resolve()
reporting_path = _file_path.parent.parent.parent.parent / "z01_presentation" / "sapphire_reporting"
sys.path.insert(0, str(reporting_path))

# Import harmonization utilities
try:
    from tool_utils import validate_tool_input, format_validation_response
    VALIDATION_AVAILABLE = True
except ImportError:
    VALIDATION_AVAILABLE = False


TOOL_DEFINITION = {
    "name": "generate_scientist_report",
    "description": """Generate comprehensive scientist report with interactive visualizations and AI grading.

    This tool generates detailed disease analysis reports that include:
    - Knowledge graph statistics (genes, drugs, pathways, relationships)
    - AI-powered quality grading (A+ to D based on data coverage)
    - Interactive Plotly visualizations (t-SNE embeddings, bar charts, network graphs)
    - Learned patterns from historical discoveries
    - Drug-gene embedding relationships
    - Pathway enrichment analysis

    Available diseases:
    - epilepsy: Epilepsy (focus on SCN1A, SCN2A, KCNQ2, GABAergic pathways)
    - als: ALS (SOD1, TDP-43, C9orf72, motor neuron pathways)
    - parkinsons: Parkinson's (SNCA, LRRK2, PARK7, dopamine pathways)
    - alzheimers: Alzheimer's (APP, APOE, PSEN1, amyloid/tau pathways)
    - pain: Chronic Pain (SCN9A, TRPV1, OPRM1, nociceptive pathways)
    - glp1: GLP-1 Therapeutics (GLP1R, DPP4, incretin pathways)

    Use Cases:
    - Quick disease landscape assessment
    - Identify data gaps for specific conditions
    - Explore drug-gene relationships
    - Review learned patterns from past discoveries
    - Generate presentation-ready visualizations

    Reports are served via HTTP at: http://localhost:8082/scientist/[disease].html
    """,
    "input_schema": {
        "type": "object",
        "properties": {
            "disease": {
                "type": "string",
                "enum": ["epilepsy", "als", "parkinsons", "alzheimers", "pain", "glp1"],
                "description": (
                    "Disease to generate report for:\n"
                    "- epilepsy: Epilepsy/seizure disorders\n"
                    "- als: Amyotrophic Lateral Sclerosis\n"
                    "- parkinsons: Parkinson's Disease\n"
                    "- alzheimers: Alzheimer's Disease\n"
                    "- pain: Chronic Pain conditions\n"
                    "- glp1: GLP-1 receptor therapeutics"
                )
            },
            "focus_areas": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Optional focus areas: drugs, genes, pathways, patterns, embeddings"
            }
        },
        "required": ["disease"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """Execute scientist report generation."""
    # Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "generate_scientist_report")
        if validation_errors:
            return format_validation_response("generate_scientist_report", validation_errors)

    try:
        disease = tool_input["disease"]
        focus_areas = tool_input.get("focus_areas", None)

        # Import unified report API
        try:
            from unified_report_api import generate_report_via_mcp
        except ImportError as e:
            return {
                "success": False,
                "error": f"Failed to import unified report API: {str(e)}",
                "hint": "Ensure unified_report_api.py is in sapphire_reporting directory"
            }

        # Generate report using unified system
        result = generate_report_via_mcp(disease=disease, focus_areas=focus_areas)

        if not result.get("success"):
            return {
                "success": False,
                "error": result.get("error", "Report generation failed"),
                "disease": disease
            }

        # Format response for Chainlit
        disease_name = result.get("disease_name", disease.title())
        stats = result.get("statistics", {})
        grade = result.get("grade", "?")
        url = result.get("url", "")

        response = {
            "success": True,
            "message": f"✅ **Scientist Report Generated: {disease_name}**\n\n",
            "disease": disease,
            "disease_name": disease_name,
            "grade": grade,
            "url": url,
            "statistics": stats
        }

        # Add formatted summary
        summary_parts = [
            f"**Quick Summary:**",
            f"- **Disease**: {disease_name}",
            f"- **Overall Grade**: {grade}",
            f"- **Genes Analyzed**: {stats.get('genes', 0)}",
            f"- **Drugs Found**: {stats.get('drugs', 0)}",
            f"- **Pathways**: {stats.get('pathways', 0)}",
            f"- **Learned Patterns**: {stats.get('learned_patterns', 0)}",
            f"",
            f"**View Full Report:**",
            f"🌐 {url}",
            f"",
            f"**Data Coverage:**"
        ]

        # Add grading breakdown if available
        if "grading_breakdown" in result:
            breakdown = result["grading_breakdown"]
            summary_parts.append(f"- Genes: {breakdown.get('gene_score', 0):.0f}/25 points")
            summary_parts.append(f"- Proteins: {breakdown.get('protein_score', 0):.0f}/15 points")
            summary_parts.append(f"- Drugs: {breakdown.get('drug_score', 0):.0f}/25 points")
            summary_parts.append(f"- Pathways: {breakdown.get('pathway_score', 0):.0f}/15 points")
            summary_parts.append(f"- Relationships: {breakdown.get('relationship_score', 0):.0f}/20 points")

        response["formatted_summary"] = "\n".join(summary_parts)

        return response

    except Exception as e:
        import traceback
        return {
            "success": False,
            "error": f"Scientist report generation failed: {str(e)}",
            "traceback": traceback.format_exc(),
            "disease": tool_input.get("disease", "unknown")
        }


# Batch generation tool
BATCH_TOOL_DEFINITION = {
    "name": "generate_all_scientist_reports",
    "description": """Generate scientist reports for ALL diseases in batch mode.

    This tool generates comprehensive reports for all 6 diseases:
    - Epilepsy
    - ALS
    - Parkinson's Disease
    - Alzheimer's Disease
    - Chronic Pain
    - GLP-1 Therapeutics

    Use this for:
    - Initial system setup (populate all reports)
    - Weekly batch updates
    - Comparative disease analysis
    - Dashboard population

    All reports are saved to: http://localhost:8082/scientist/
    Index page: http://localhost:8082/scientist/index.html
    """,
    "input_schema": {
        "type": "object",
        "properties": {
            "force_regenerate": {
                "type": "boolean",
                "default": False,
                "description": "Force regeneration even if reports exist"
            }
        },
        "required": []
    }
}


async def execute_batch(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """Execute batch scientist report generation for all diseases."""
    try:
        force = tool_input.get("force_regenerate", False)

        # Import unified report API
        try:
            from unified_report_api import generate_reports_batch
        except ImportError as e:
            return {
                "success": False,
                "error": f"Failed to import unified report API: {str(e)}"
            }

        # Generate all reports using batch mode
        result = generate_reports_batch(
            diseases=["epilepsy", "als", "parkinsons", "alzheimers", "pain", "glp1"],
            force=force
        )

        if not result.get("success"):
            return {
                "success": False,
                "error": result.get("error", "Batch generation failed")
            }

        # Format response
        reports = result.get("reports", [])
        index_url = result.get("index_url", "")

        summary_parts = [
            f"✅ **All Scientist Reports Generated**\n",
            f"**Reports Created**: {len(reports)}/6",
            f"",
            f"**Individual Reports:**"
        ]

        for report in reports:
            disease = report.get("disease", "unknown")
            grade = report.get("grade", "?")
            url = report.get("url", "")
            summary_parts.append(f"- {disease.title()}: Grade {grade} → {url}")

        summary_parts.extend([
            f"",
            f"**Dashboard:**",
            f"🌐 {index_url}"
        ])

        return {
            "success": True,
            "message": "\n".join(summary_parts),
            "reports_generated": len(reports),
            "reports": reports,
            "index_url": index_url
        }

    except Exception as e:
        import traceback
        return {
            "success": False,
            "error": f"Batch report generation failed: {str(e)}",
            "traceback": traceback.format_exc()
        }


# Export for tool registration
__all__ = ["TOOL_DEFINITION", "execute", "BATCH_TOOL_DEFINITION", "execute_batch"]
