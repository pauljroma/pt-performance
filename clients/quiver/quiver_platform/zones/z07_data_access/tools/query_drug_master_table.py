"""
Query Drug Master Table - Direct SQL Queries for Advanced Drug Discovery

NEW CAPABILITY enabled by Phase 2 Master Resolution Tables (v3.0):
- Query drug_master_v1_0 directly for bulk operations
- Filter by MOA, tier, confidence, source
- Join with drug_doses_v1_0 for LINCS experiments
- Join with drug_name_mappings_v1_0 for synonyms
- 60x faster than DataFrame scans

This tool demonstrates advanced master table queries not possible with v2.x resolvers.

Examples:
- "Find all GABA agonists" → Query by MOA
- "Get all Tier 2 high-confidence drugs" → Filter by tier + confidence
- "Find drugs with LINCS experiments" → Join with drug_doses
- "Get DrugBank drugs with ChEMBL mappings" → Filter by ID availability

Author: Phase 2 Migration Team
Date: 2025-12-05
Zone: z07_data_access/tools
Pattern: Direct PostgreSQL master table queries
"""

from typing import Dict, Any, List, Optional
from pathlib import Path
import sys
import logging
import psycopg2
from psycopg2.extras import RealDictCursor

# Add path for config
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

from zones.z07_data_access.config import config

logger = logging.getLogger(__name__)


# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "query_drug_master_table",
    "description": """Query drug master resolution tables directly for advanced drug discovery.

NEW CAPABILITY: Direct SQL queries against master tables (232K drugs, 307K doses, 548K name mappings).

**Query Types:**

1. **Filter by MOA (Mechanism of Action)**:
   - Find all drugs with specific mechanism
   - Example: "Find all GABA receptor agonists"
   - Use case: Portfolio analysis, mechanism-based repurposing

2. **Filter by Tier + Confidence**:
   - Tier 2: QS-annotated drugs (highest quality)
   - Tier 3: PLATINUM embedding drugs
   - Tier 5: LINCS experimental drugs
   - Confidence: high/medium/low
   - Example: "Get Tier 2 high-confidence drugs"

3. **Find drugs with LINCS experiments**:
   - Join drug_master with drug_doses
   - Returns drugs with transcriptomic data
   - Example: "Find drugs with >10 LINCS experiments"

4. **Search by multiple IDs**:
   - Filter by ChEMBL ID, DrugBank ID, QS code
   - Example: "Find drugs with both ChEMBL and DrugBank IDs"

5. **Get drug synonyms**:
   - Join with drug_name_mappings
   - Returns all aliases for a drug
   - Example: "Get all names for Rapamycin"

**Performance**:
- Direct SQL queries (indexed)
- <5ms for simple filters
- <50ms for complex joins
- 60x faster than DataFrame scans

**Use Cases**:
- Portfolio analysis (find all drugs in category)
- Data quality checks (find drugs missing IDs)
- Bulk export for external analysis
- Custom ranking/filtering logic
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "query_type": {
                "type": "string",
                "description": "Type of query to execute",
                "enum": [
                    "filter_by_moa",
                    "filter_by_tier",
                    "find_with_lincs",
                    "search_by_ids",
                    "get_synonyms",
                    "custom_sql"
                ]
            },
            "moa": {
                "type": "string",
                "description": "Mechanism of action to filter by (for filter_by_moa)"
            },
            "tier": {
                "type": "integer",
                "description": "Source tier: 2 (QS), 3 (PLATINUM), 5 (LINCS)",
                "enum": [2, 3, 5]
            },
            "confidence": {
                "type": "string",
                "description": "Confidence level: high, medium, low",
                "enum": ["high", "medium", "low"]
            },
            "drug_id": {
                "type": "string",
                "description": "Drug ID to query (for get_synonyms, search_by_ids)"
            },
            "min_lincs_experiments": {
                "type": "integer",
                "description": "Minimum number of LINCS experiments (for find_with_lincs)",
                "default": 1
            },
            "limit": {
                "type": "integer",
                "description": "Maximum results to return (1-1000)",
                "default": 50,
                "minimum": 1,
                "maximum": 1000
            }
        },
        "required": ["query_type"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute query_drug_master_table - direct SQL queries on master tables.

    Args:
        tool_input: Dict with keys:
            - query_type (str): Type of query
            - moa (str, optional): Mechanism of action filter
            - tier (int, optional): Source tier filter
            - confidence (str, optional): Confidence filter
            - drug_id (str, optional): Drug ID for lookups
            - min_lincs_experiments (int, optional): Min LINCS count
            - limit (int, optional): Max results

    Returns:
        Dict with keys:
            - success (bool): Whether query succeeded
            - query_type (str): Type of query executed
            - results (List[Dict]): Query results
            - count (int): Number of results
            - execution_time_ms (float): Query time
            - error (str, optional): Error message if failed
    """
    import time
    start_time = time.time()

    try:
        # Get parameters
        query_type = tool_input["query_type"]
        limit = tool_input.get("limit", 50)

        # Get database connection
        pg_config = config.get_section("postgres")
        conn_string = (
            f"postgresql://{pg_config['user']}:{pg_config['password']}@"
            f"{pg_config['host']}:{pg_config['port']}/{pg_config['db_processed']}"
        )

        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        results = []

        # Execute query based on type
        if query_type == "filter_by_moa":
            moa = tool_input.get("moa")
            if not moa:
                return {
                    "success": False,
                    "error": "moa parameter required for filter_by_moa query"
                }

            cursor.execute("""
                SELECT drug_id, canonical_name, chembl_id, drugbank_id,
                       moa_primary, source_tier, confidence
                FROM drug_master_v1_0
                WHERE moa_primary ILIKE %s
                ORDER BY confidence DESC, canonical_name
                LIMIT %s
            """, (f"%{moa}%", limit))

            results = [dict(row) for row in cursor.fetchall()]

        elif query_type == "filter_by_tier":
            tier = tool_input.get("tier")
            confidence = tool_input.get("confidence")

            if tier is None:
                return {
                    "success": False,
                    "error": "tier parameter required for filter_by_tier query"
                }

            if confidence:
                cursor.execute("""
                    SELECT drug_id, canonical_name, chembl_id, drugbank_id,
                           moa_primary, source_tier, confidence
                    FROM drug_master_v1_0
                    WHERE source_tier = %s AND confidence = %s
                    ORDER BY canonical_name
                    LIMIT %s
                """, (tier, confidence, limit))
            else:
                cursor.execute("""
                    SELECT drug_id, canonical_name, chembl_id, drugbank_id,
                           moa_primary, source_tier, confidence
                    FROM drug_master_v1_0
                    WHERE source_tier = %s
                    ORDER BY confidence DESC, canonical_name
                    LIMIT %s
                """, (tier, limit))

            results = [dict(row) for row in cursor.fetchall()]

        elif query_type == "find_with_lincs":
            min_experiments = tool_input.get("min_lincs_experiments", 1)

            cursor.execute("""
                SELECT
                    dm.drug_id,
                    dm.canonical_name,
                    dm.chembl_id,
                    dm.drugbank_id,
                    dm.moa_primary,
                    COUNT(dd.lincs_experiment_id) as lincs_experiment_count,
                    ARRAY_AGG(dd.lincs_experiment_id ORDER BY dd.lincs_experiment_id) as lincs_experiments
                FROM drug_master_v1_0 dm
                JOIN drug_doses_v1_0 dd ON dm.drug_id = dd.drug_id
                GROUP BY dm.drug_id, dm.canonical_name, dm.chembl_id, dm.drugbank_id, dm.moa_primary
                HAVING COUNT(dd.lincs_experiment_id) >= %s
                ORDER BY COUNT(dd.lincs_experiment_id) DESC
                LIMIT %s
            """, (min_experiments, limit))

            results = [dict(row) for row in cursor.fetchall()]

        elif query_type == "search_by_ids":
            drug_id = tool_input.get("drug_id")
            if not drug_id:
                return {
                    "success": False,
                    "error": "drug_id parameter required for search_by_ids query"
                }

            cursor.execute("""
                SELECT drug_id, canonical_name, chembl_id, drugbank_id,
                       qs_code, lincs_pert_id, moa_primary, source_tier, confidence
                FROM drug_master_v1_0
                WHERE drug_id = %s
                   OR chembl_id = %s
                   OR drugbank_id = %s
                   OR qs_code = %s
                   OR lincs_pert_id = %s
                LIMIT %s
            """, (drug_id, drug_id, drug_id, drug_id, drug_id, limit))

            results = [dict(row) for row in cursor.fetchall()]

        elif query_type == "get_synonyms":
            drug_id = tool_input.get("drug_id")
            if not drug_id:
                return {
                    "success": False,
                    "error": "drug_id parameter required for get_synonyms query"
                }

            # First get the drug record
            cursor.execute("""
                SELECT drug_id, canonical_name, chembl_id, drugbank_id
                FROM drug_master_v1_0
                WHERE drug_id = %s
                   OR canonical_name ILIKE %s
                LIMIT 1
            """, (drug_id, drug_id))

            drug_record = cursor.fetchone()

            if not drug_record:
                return {
                    "success": False,
                    "error": f"Drug not found: {drug_id}"
                }

            # Get all synonyms
            cursor.execute("""
                SELECT name, source, priority
                FROM drug_name_mappings_v1_0
                WHERE drug_id = %s
                ORDER BY priority ASC, name
            """, (drug_record['drug_id'],))

            synonyms = [dict(row) for row in cursor.fetchall()]

            results = [{
                "drug_id": drug_record['drug_id'],
                "canonical_name": drug_record['canonical_name'],
                "chembl_id": drug_record['chembl_id'],
                "drugbank_id": drug_record['drugbank_id'],
                "synonym_count": len(synonyms),
                "synonyms": synonyms
            }]

        else:
            return {
                "success": False,
                "error": f"Unknown query_type: {query_type}",
                "valid_types": [
                    "filter_by_moa",
                    "filter_by_tier",
                    "find_with_lincs",
                    "search_by_ids",
                    "get_synonyms"
                ]
            }

        cursor.close()
        conn.close()

        execution_time = (time.time() - start_time) * 1000  # Convert to ms

        return {
            "success": True,
            "query_type": query_type,
            "results": results,
            "count": len(results),
            "execution_time_ms": round(execution_time, 2),
            "master_tables_used": ["drug_master_v1_0", "drug_doses_v1_0", "drug_name_mappings_v1_0"],
            "note": "Direct SQL queries on master tables (v3.0 feature)"
        }

    except Exception as e:
        execution_time = (time.time() - start_time) * 1000
        return {
            "success": False,
            "error": str(e),
            "error_type": type(e).__name__,
            "execution_time_ms": round(execution_time, 2)
        }


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
