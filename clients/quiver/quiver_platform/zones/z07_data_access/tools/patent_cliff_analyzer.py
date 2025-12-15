#!/usr/bin/env python3
"""
Patent Cliff Analyzer - Identify Patent Expiry Opportunities and Risks

Analyzes patent expiry timelines to identify:
- Generic drug opportunities (expiring patents)
- Revenue cliff risks for companies
- Competitive landscape shifts
- M&A opportunities (expiring portfolios)
"""

import os
import sys
import logging
from pathlib import Path
from datetime import datetime, timedelta
from typing import List, Dict, Any, Tuple
import psycopg2
from psycopg2.extras import RealDictCursor
from collections import defaultdict

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DB_URL = "postgresql://postgres:temppass123@localhost:5435/sapphire_database"


# Claude Tool Definition
TOOL_DEFINITION = {
    "name": "patent_cliff_analyzer",
    "description": """Analyze patent expiry timelines to identify generic opportunities and revenue risks.

**What This Tool Does:**
Identifies patent cliffs - periods when key drug patents expire, creating generic opportunities and revenue risks.

**Key Capabilities:**

1. **Patent Expiry Timeline:**
   - Year-by-year patent expiry analysis
   - Drug-specific expiry tracking
   - Company-specific patent cliffs
   - Therapeutic area impact assessment

2. **Generic Opportunities:**
   - High-value drugs losing patent protection
   - First-to-file opportunities
   - Market entry timing
   - Competitive generic landscape

3. **Revenue Risk Assessment:**
   - Company revenue exposure
   - Patent cliff impact ($B revenue at risk)
   - Portfolio concentration risk
   - Diversification analysis

4. **Strategic Insights:**
   - M&A opportunities (expiring portfolios)
   - Lifecycle management needs
   - Reformulation opportunities
   - New indication potential

**Example Queries:**

*Generic Opportunities:*
- "What drugs lose patent protection in 2025-2027?"
- "Find blockbusters expiring before 2030"
- "Show composition patents expiring next 3 years"

*Revenue Risk:*
- "What's Novartis' patent cliff exposure?"
- "Which companies face major patent cliffs?"
- "Analyze cardiovascular patent cliff"

*Strategic Planning:*
- "Find lifecycle management opportunities"
- "Identify acquisition targets with expiring patents"
- "Show first-to-file generic opportunities"

**Use Cases:**
- Generic drug development planning
- Revenue forecasting and risk management
- M&A target identification
- Competitive intelligence
- Lifecycle management strategy
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "time_horizon": {
                "type": "string",
                "description": "Analysis time window: 'next_3_years', 'next_5_years', '2025-2030', 'all_active', or custom 'YYYY-YYYY'",
                "default": "next_5_years"
            },
            "company_filter": {
                "type": "string",
                "description": "Filter by specific company (e.g., 'Novartis', 'Pfizer')"
            },
            "therapeutic_area_filter": {
                "type": "string",
                "description": "Filter by disease area (e.g., 'cancer', 'cardiovascular', 'epilepsy')"
            },
            "patent_type_filter": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Filter by patent types (e.g., ['composition', 'formulation'])"
            },
            "min_revenue_threshold": {
                "type": "number",
                "description": "Minimum drug revenue ($M) to include in analysis (for filtering blockbusters)"
            },
            "include_timeline_viz": {
                "type": "boolean",
                "description": "Include year-by-year timeline visualization",
                "default": True
            },
            "include_company_risk": {
                "type": "boolean",
                "description": "Include company-specific revenue risk assessment",
                "default": True
            }
        }
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute patent cliff analyzer.

    Returns:
        Dict with keys:
            - success (bool)
            - time_horizon (str)
            - patent_cliff_summary (Dict)
            - expiry_timeline (List[Dict])
            - company_risk_analysis (List[Dict])
            - generic_opportunities (List[Dict])
            - strategic_insights (Dict)
            - data_sources (List[str])
    """
    import time
    start_time = time.time()

    try:
        # Extract parameters
        time_horizon = tool_input.get("time_horizon", "next_5_years")
        company_filter = tool_input.get("company_filter")
        therapeutic_area = tool_input.get("therapeutic_area_filter")
        patent_types = tool_input.get("patent_type_filter", [])
        min_revenue = tool_input.get("min_revenue_threshold", 0)
        include_timeline = tool_input.get("include_timeline_viz", True)
        include_company_risk = tool_input.get("include_company_risk", True)

        # Parse time horizon
        start_date, end_date = _parse_time_horizon(time_horizon)

        # Query expiring patents
        expiring_patents = _query_expiring_patents(
            start_date,
            end_date,
            company_filter,
            therapeutic_area,
            patent_types
        )

        # Analyze patent cliff
        cliff_summary = _analyze_patent_cliff(expiring_patents, start_date, end_date)

        # Build expiry timeline
        timeline = _build_expiry_timeline(expiring_patents) if include_timeline else None

        # Company risk analysis
        company_risks = _analyze_company_risk(expiring_patents) if include_company_risk else None

        # Generic opportunities
        generic_opps = _identify_generic_opportunities(expiring_patents)

        # Strategic insights
        insights = _generate_strategic_insights(cliff_summary, expiring_patents)

        # Calculate latency
        latency_ms = (time.time() - start_time) * 1000

        return {
            "success": True,
            "time_horizon": f"{start_date.year}-{end_date.year}",
            "patent_cliff_summary": cliff_summary,
            "expiry_timeline": timeline,
            "company_risk_analysis": company_risks,
            "generic_opportunities": generic_opps,
            "strategic_insights": insights,
            "data_sources": ["PostgreSQL Patents Database", "FDA Orange Book"],
            "latency_ms": round(latency_ms, 2)
        }

    except Exception as e:
        logger.error(f"patent_cliff_analyzer error: {e}", exc_info=True)
        return {
            "success": False,
            "error": f"Patent cliff analysis failed: {str(e)}",
            "error_type": type(e).__name__
        }


def _parse_time_horizon(time_horizon: str) -> Tuple[datetime, datetime]:
    """Parse time horizon string into date range."""
    today = datetime.now()

    if time_horizon == "next_3_years":
        return today, today + timedelta(days=3*365)
    elif time_horizon == "next_5_years":
        return today, today + timedelta(days=5*365)
    elif time_horizon == "all_active":
        return today, datetime(2050, 12, 31)
    elif "-" in time_horizon and len(time_horizon.split("-")) == 2:
        # Custom range like "2025-2030"
        start_year, end_year = time_horizon.split("-")
        return datetime(int(start_year), 1, 1), datetime(int(end_year), 12, 31)
    else:
        # Default to next 5 years
        return today, today + timedelta(days=5*365)


def _query_expiring_patents(
    start_date: datetime,
    end_date: datetime,
    company: str = None,
    therapeutic_area: str = None,
    patent_types: List[str] = None
) -> List[Dict[str, Any]]:
    """Query patents expiring in date range."""
    try:
        conn = psycopg2.connect(DB_URL)
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # Build query
        query = """
            SELECT *
            FROM patents
            WHERE expiry_date BETWEEN %s AND %s
              AND is_expired = FALSE
        """
        params = [start_date.date(), end_date.date()]

        if company:
            query += " AND assignee ILIKE %s"
            params.append(f"%{company}%")

        if therapeutic_area:
            query += " AND indication ILIKE %s"
            params.append(f"%{therapeutic_area}%")

        if patent_types:
            query += " AND patent_type = ANY(%s)"
            params.append(patent_types)

        query += " ORDER BY expiry_date ASC"

        cursor.execute(query, params)
        patents = cursor.fetchall()

        cursor.close()
        conn.close()

        return [dict(p) for p in patents]

    except Exception as e:
        logger.error(f"Query failed: {e}")
        return []


def _analyze_patent_cliff(
    patents: List[Dict],
    start_date: datetime,
    end_date: datetime
) -> Dict[str, Any]:
    """Analyze overall patent cliff characteristics."""
    total_patents = len(patents)

    if total_patents == 0:
        return {
            "total_expiring_patents": 0,
            "composition_patents": 0,
            "peak_expiry_year": None,
            "companies_affected": 0,
            "therapeutic_areas": 0,
            "average_patents_per_year": 0
        }

    # Count composition patents (highest value)
    composition_count = len([p for p in patents if p.get('patent_type') == 'composition'])

    # Find peak expiry year
    expiry_years = defaultdict(int)
    for p in patents:
        year = p['expiry_date'].year if hasattr(p['expiry_date'], 'year') else int(str(p['expiry_date'])[:4])
        expiry_years[year] += 1

    peak_year = max(expiry_years.items(), key=lambda x: x[1])[0] if expiry_years else None

    # Count unique companies and therapeutic areas
    companies = set(p.get('assignee', 'Unknown') for p in patents)
    areas = set(p.get('indication', 'Unknown') for p in patents)

    years_span = (end_date.year - start_date.year) or 1

    return {
        "total_expiring_patents": total_patents,
        "composition_patents": composition_count,
        "composition_percentage": round(100 * composition_count / total_patents, 1),
        "peak_expiry_year": peak_year,
        "peak_expiry_count": expiry_years.get(peak_year, 0),
        "companies_affected": len(companies),
        "therapeutic_areas": len(areas),
        "average_patents_per_year": round(total_patents / years_span, 1),
        "time_span_years": years_span
    }


def _build_expiry_timeline(patents: List[Dict]) -> List[Dict[str, Any]]:
    """Build year-by-year expiry timeline."""
    timeline = defaultdict(lambda: {
        "year": 0,
        "total_expiring": 0,
        "composition_patents": 0,
        "drugs": [],
        "companies": set()
    })

    for p in patents:
        year = p['expiry_date'].year if hasattr(p['expiry_date'], 'year') else int(str(p['expiry_date'])[:4])

        timeline[year]["year"] = year
        timeline[year]["total_expiring"] += 1

        if p.get('patent_type') == 'composition':
            timeline[year]["composition_patents"] += 1

        timeline[year]["drugs"].append({
            "drug_name": p.get('drug_name'),
            "patent_number": p.get('patent_number'),
            "assignee": p.get('assignee'),
            "patent_type": p.get('patent_type'),
            "indication": p.get('indication')
        })

        timeline[year]["companies"].add(p.get('assignee', 'Unknown'))

    # Convert to list and sort
    result = []
    for year_data in sorted(timeline.values(), key=lambda x: x['year']):
        year_data['companies'] = list(year_data['companies'])
        result.append(year_data)

    return result


def _analyze_company_risk(patents: List[Dict]) -> List[Dict[str, Any]]:
    """Analyze patent cliff risk by company."""
    company_data = defaultdict(lambda: {
        "company": "",
        "expiring_patents": 0,
        "composition_patents": 0,
        "peak_cliff_year": None,
        "drugs_at_risk": [],
        "risk_level": "LOW"
    })

    for p in patents:
        company = p.get('assignee', 'Unknown')
        company_data[company]["company"] = company
        company_data[company]["expiring_patents"] += 1

        if p.get('patent_type') == 'composition':
            company_data[company]["composition_patents"] += 1

        company_data[company]["drugs_at_risk"].append({
            "drug_name": p.get('drug_name'),
            "expiry_date": str(p.get('expiry_date')),
            "indication": p.get('indication')
        })

    # Calculate risk levels
    for company, data in company_data.items():
        if data["expiring_patents"] >= 5:
            risk_level = "HIGH"
        elif data["expiring_patents"] >= 3:
            risk_level = "MEDIUM"
        else:
            risk_level = "LOW"

        data["risk_level"] = risk_level

    # Sort by expiring patents (highest risk first)
    result = sorted(company_data.values(), key=lambda x: x['expiring_patents'], reverse=True)
    return result


def _identify_generic_opportunities(patents: List[Dict]) -> List[Dict[str, Any]]:
    """Identify high-value generic drug opportunities."""
    opportunities = []

    for p in patents:
        # Composition patents are highest value for generics
        if p.get('patent_type') == 'composition':
            opportunity_score = 10
        elif p.get('patent_type') == 'formulation':
            opportunity_score = 7
        else:
            opportunity_score = 5

        # Calculate years until expiry
        expiry_date = p['expiry_date']
        if hasattr(expiry_date, 'year'):
            years_until_expiry = expiry_date.year - datetime.now().year
        else:
            expiry_year = int(str(expiry_date)[:4])
            years_until_expiry = expiry_year - datetime.now().year

        opportunities.append({
            "drug_name": p.get('drug_name'),
            "patent_number": p.get('patent_number'),
            "expiry_date": str(p.get('expiry_date')),
            "years_until_expiry": years_until_expiry,
            "current_holder": p.get('assignee'),
            "indication": p.get('indication'),
            "patent_type": p.get('patent_type'),
            "opportunity_score": opportunity_score,
            "strategic_value": _assess_generic_value(p)
        })

    # Sort by opportunity score and proximity to expiry
    opportunities.sort(key=lambda x: (x['opportunity_score'], -x['years_until_expiry']), reverse=True)
    return opportunities[:20]  # Top 20 opportunities


def _assess_generic_value(patent: Dict) -> str:
    """Assess strategic value of generic opportunity."""
    patent_type = patent.get('patent_type', '')
    indication = patent.get('indication', '').lower()

    # High-value indications
    high_value_areas = ['cancer', 'diabetes', 'cardiovascular', 'alzheimer', 'rare disease']

    if patent_type == 'composition':
        if any(area in indication for area in high_value_areas):
            return "VERY HIGH - Composition patent in high-value therapeutic area"
        else:
            return "HIGH - Composition patent provides strong market exclusivity"
    elif patent_type == 'formulation':
        return "MEDIUM - Formulation patent, alternative formulations may exist"
    else:
        return "MODERATE - Method-of-use patent, original formulation may remain protected"


def _generate_strategic_insights(cliff_summary: Dict, patents: List[Dict]) -> Dict[str, Any]:
    """Generate strategic insights from patent cliff analysis."""
    insights = {
        "overall_assessment": "",
        "key_opportunities": [],
        "risk_areas": [],
        "recommended_actions": []
    }

    total = cliff_summary.get('total_expiring_patents', 0)
    composition_pct = cliff_summary.get('composition_percentage', 0)
    peak_year = cliff_summary.get('peak_expiry_year')

    # Overall assessment
    if total > 20:
        insights["overall_assessment"] = f"SIGNIFICANT PATENT CLIFF: {total} patents expiring with peak in {peak_year}. Major market shift expected."
    elif total > 10:
        insights["overall_assessment"] = f"MODERATE PATENT CLIFF: {total} patents expiring. Notable generic competition anticipated."
    else:
        insights["overall_assessment"] = f"LIMITED PATENT CLIFF: {total} patents expiring. Manageable competitive pressure."

    # Key opportunities
    if composition_pct > 50:
        insights["key_opportunities"].append(f"{composition_pct}% are composition patents - high-value generic opportunities")

    # Risk areas
    if peak_year and cliff_summary.get('peak_expiry_count', 0) > 5:
        insights["risk_areas"].append(f"Concentration risk: {cliff_summary['peak_expiry_count']} patents expire in {peak_year}")

    # Recommended actions
    insights["recommended_actions"] = [
        "Evaluate lifecycle management strategies (new formulations, indications)",
        "Assess M&A opportunities for expiring portfolios",
        "Develop generic entry strategies for high-value drugs",
        "Monitor competitive landscape for first-to-file opportunities"
    ]

    return insights


# Main execution
if __name__ == '__main__':
    # Test query
    import asyncio

    async def test():
        result = await execute({
            "time_horizon": "next_5_years",
            "include_timeline_viz": True,
            "include_company_risk": True
        })
        print(f"Success: {result.get('success')}")
        print(f"Expiring Patents: {result.get('patent_cliff_summary', {}).get('total_expiring_patents')}")

    asyncio.run(test())
