#!/usr/bin/env python3
"""
White Space Opportunity Mapper - Identify Underpatented Areas

Identifies opportunities in:
- Underpatented therapeutic areas
- Gene targets with low patent coverage
- Mechanisms of action with few patents
- Geographic/market gaps
"""

import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Dict, Any, List
from collections import Counter
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DB_URL = "postgresql://postgres:temppass123@localhost:5435/sapphire_database"

TOOL_DEFINITION = {
    "name": "white_space_opportunity_mapper",
    "description": """Identify underpatented therapeutic areas and gene targets for innovation opportunities."""
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """Map white space opportunities."""
    try:
        conn = psycopg2.connect(DB_URL)
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # Get all patents
        cursor.execute("SELECT * FROM patents WHERE is_expired = FALSE")
        active_patents = cursor.fetchall()

        # Analyze gene target coverage
        gene_targets = Counter(p['gene_target'] for p in active_patents if p.get('gene_target'))

        # Analyze indication coverage
        indications = Counter(p['indication'] for p in active_patents if p.get('indication'))

        # Identify white space
        white_space_targets = _identify_white_space_targets(gene_targets)
        white_space_indications = _identify_white_space_indications(indications)
        innovation_opportunities = _generate_innovation_opportunities(active_patents)

        cursor.close()
        conn.close()

        return {
            "success": True,
            "white_space_gene_targets": white_space_targets,
            "white_space_indications": white_space_indications,
            "innovation_opportunities": innovation_opportunities,
            "strategic_recommendations": _generate_recommendations(white_space_targets, white_space_indications)
        }

    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        return {"success": False, "error": str(e)}


def _identify_white_space_targets(gene_targets: Counter) -> List[Dict[str, Any]]:
    """Identify gene targets with low patent coverage."""
    white_space = []

    for target, count in gene_targets.most_common():
        if count <= 2:  # Low coverage = opportunity
            white_space.append({
                "gene_target": target,
                "patent_count": count,
                "opportunity_level": "HIGH" if count == 1 else "MEDIUM",
                "rationale": f"Only {count} active patent(s) - significant white space for innovation"
            })

    return white_space[:20]  # Top 20


def _identify_white_space_indications(indications: Counter) -> List[Dict[str, Any]]:
    """Identify therapeutic areas with low patent coverage."""
    white_space = []

    for indication, count in indications.most_common():
        if count <= 3:  # Low coverage
            white_space.append({
                "indication": indication,
                "patent_count": count,
                "opportunity_level": "HIGH" if count <= 2 else "MEDIUM",
                "rationale": f"Limited patent protection - opportunity for first-mover advantage"
            })

    return white_space[:15]


def _generate_innovation_opportunities(patents: List[Dict]) -> List[Dict[str, Any]]:
    """Generate specific innovation opportunities."""
    opportunities = []

    # Group by therapeutic area
    area_counts = Counter(p.get('indication', 'Unknown') for p in patents)

    # Rare disease opportunities (assuming low counts = rare/orphan)
    for indication, count in area_counts.items():
        if count == 1:
            opportunities.append({
                "type": "Rare Disease Opportunity",
                "indication": indication,
                "description": f"Only 1 patent in {indication} - potential orphan drug opportunity",
                "strategic_value": "HIGH - Orphan drug designation, extended exclusivity"
            })

    return opportunities[:10]


def _generate_recommendations(targets, indications) -> List[str]:
    """Generate strategic recommendations."""
    recommendations = [
        "Focus R&D on underpatented gene targets with clinical validation",
        "Explore partnership opportunities in white space therapeutic areas",
        "Consider orphan drug designation for rare disease targets",
        "Evaluate freedom-to-operate advantage in low-patent-density areas"
    ]

    if targets and len(targets) > 10:
        recommendations.append(f"High white space: {len(targets)} gene targets with ≤2 patents")

    if indications and len(indications) > 5:
        recommendations.append(f"Multiple underpatented indications identified - prioritize by unmet need")

    return recommendations


if __name__ == '__main__':
    import asyncio
    result = asyncio.run(execute({}))
    print(f"Success: {result.get('success')}")
    if result.get('success'):
        print(f"White Space Targets: {len(result.get('white_space_gene_targets', []))}")
        print(f"Innovation Opportunities: {len(result.get('innovation_opportunities', []))}")
