#!/usr/bin/env python3
"""
Competitive Landscape Dashboard - Market Intelligence & Portfolio Analysis

Provides competitive intelligence across:
- Company patent portfolios
- Therapeutic area market share
- Patent type strategies
- Technology trends
"""

import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Dict, Any, List
from collections import defaultdict
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DB_URL = "postgresql://postgres:temppass123@localhost:5435/sapphire_database"

TOOL_DEFINITION = {
    "name": "competitive_landscape_dashboard",
    "description": """Analyze competitive patent landscape across companies and therapeutic areas."""
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """Generate competitive landscape dashboard."""
    try:
        conn = psycopg2.connect(DB_URL)
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # Company portfolios
        cursor.execute("""
            SELECT assignee, COUNT(*) as total_patents,
                   SUM(CASE WHEN is_expired = FALSE THEN 1 ELSE 0 END) as active_patents,
                   SUM(CASE WHEN patent_type = 'composition' THEN 1 ELSE 0 END) as composition_patents
            FROM patents
            GROUP BY assignee
            ORDER BY total_patents DESC
            LIMIT 15
        """)
        company_portfolios = cursor.fetchall()

        # Therapeutic area distribution
        cursor.execute("""
            SELECT indication, COUNT(*) as patent_count
            FROM patents
            WHERE is_expired = FALSE
            GROUP BY indication
            ORDER BY patent_count DESC
            LIMIT 10
        """)
        therapeutic_areas = cursor.fetchall()

        # Patent type distribution
        cursor.execute("""
            SELECT patent_type, COUNT(*) as count,
                   ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM patents), 1) as percentage
            FROM patents
            GROUP BY patent_type
            ORDER BY count DESC
        """)
        patent_types = cursor.fetchall()

        cursor.close()
        conn.close()

        return {
            "success": True,
            "company_portfolios": [dict(r) for r in company_portfolios],
            "therapeutic_areas": [dict(r) for r in therapeutic_areas],
            "patent_type_distribution": [dict(r) for r in patent_types],
            "market_insights": _generate_market_insights(company_portfolios, therapeutic_areas)
        }

    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        return {"success": False, "error": str(e)}


def _generate_market_insights(companies, areas) -> Dict[str, Any]:
    """Generate strategic market insights."""
    if not companies:
        return {}

    top_company = companies[0]
    total_portfolios = len(companies)

    return {
        "market_leader": top_company['assignee'],
        "leader_portfolio_size": top_company['total_patents'],
        "market_concentration": "HIGH" if top_company['total_patents'] > 10 else "MODERATE",
        "total_active_players": total_portfolios,
        "key_insight": f"{top_company['assignee']} leads with {top_company['total_patents']} patents"
    }


if __name__ == '__main__':
    import asyncio
    result = asyncio.run(execute({}))
    print(f"Success: {result.get('success')}")
    if result.get('success'):
        print(f"Top Company: {result['market_insights']['market_leader']}")
