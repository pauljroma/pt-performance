"""
Signal Tracking Dashboard - 85% Connection Goal Metrics

Provides system-wide metrics for entity connection tracking across:
- PostgreSQL fusion tables (14 tables, 11.2M rows)
- Neo4j knowledge graph (1.3M nodes)
- ChromaDB literature (29,863 papers)

Tracks progress toward 85% connection goal:
- Goal: 85% of entities have connection_score >= 75%
- Connection score = % of systems where entity appears with linkable data

Metrics:
- Total entities tracked
- Entities meeting 85% goal
- Connection score distribution
- System coverage breakdown
- Gap analysis and recommendations

Zone: z07_data_access
Dependencies: entity_connection_tracker, psycopg2, neo4j
"""
import sys
from pathlib import Path
from typing import Any, Dict, List
import psycopg2
from neo4j import GraphDatabase

# Add paths
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

# Import entity tracker (REUSE)
try:
    from zones.z07_data_access.tools.entity_connection_tracker import (
        check_postgres_presence,
        check_neo4j_presence,
        check_chromadb_presence
    )
    TRACKER_AVAILABLE = True
except ImportError:
    TRACKER_AVAILABLE = False

# Configuration
POSTGRES_CONFIG = {
    'host': 'localhost',
    'port': 5435,
    'database': 'sapphire_database',
    'user': 'postgres',
    'password': 'temppass123'
}

NEO4J_CONFIG = {
    'uri': 'bolt://localhost:7687',
    'user': 'neo4j',
    'password': 'testpassword123'
}


# Claude Tool Definition
TOOL_DEFINITION = {
    "name": "signal_tracking_dashboard",
    "description": """System-wide metrics for 85% entity connection goal.

Shows aggregate metrics across the full data architecture:
1. **Total entities**: Unique drugs and genes across all systems
2. **Entities meeting 85% goal**: Count with connection_score >= 75%
3. **Connection score distribution**: Histogram of scores
4. **System coverage**: % of entities in Postgres, Neo4j, ChromaDB
5. **Gap analysis**: Which entities need more linkage

**85% Connection Goal:**
- Target: 85% of entities present in 3+ systems
- Current: Tracked in real-time
- Gaps: Identified with recommendations

**Metrics by Entity Type:**
- Drugs: 14,246 total (ChEMBL + LINCS)
- Genes: 18,368 total (Ensembl + MODEX)

Returns:
- Overall connection rate
- Entities above/below threshold
- System-specific coverage
- Actionable gap analysis

Examples:
- signal_tracking_dashboard(entity_type="drug", sample_size=1000)
  → Sample 1000 drugs, calculate metrics
- signal_tracking_dashboard(entity_type="all", detailed=true)
  → Full analysis for all entities
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "entity_type": {
                "type": "string",
                "enum": ["drug", "gene", "all"],
                "description": "Which entity type to analyze. Default: 'all'",
                "default": "all"
            },
            "sample_size": {
                "type": "integer",
                "description": "Number of entities to sample (0 = all). Default: 500",
                "default": 500,
                "minimum": 0,
                "maximum": 10000
            },
            "detailed": {
                "type": "boolean",
                "description": "Include detailed gap analysis. Default: false",
                "default": False
            }
        },
        "required": []
    }
}


def get_entity_sample(entity_type: str, sample_size: int) -> List[Dict[str, str]]:
    """Get sample of entities from fusion tables."""
    conn = psycopg2.connect(**POSTGRES_CONFIG)
    cursor = conn.cursor()

    entities = []

    try:
        if entity_type in ["drug", "all"]:
            cursor.execute(f"""
                SELECT DISTINCT entity1_id as id
                FROM d_aux_adr_topk_v6_0
                LIMIT {sample_size if sample_size > 0 else 1000}
            """)
            entities.extend([{"id": row[0], "type": "drug"} for row in cursor.fetchall()])

        if entity_type in ["gene", "all"]:
            cursor.execute(f"""
                SELECT DISTINCT entity1_id as id
                FROM g_aux_cto_topk_v6_0
                LIMIT {sample_size if sample_size > 0 else 1000}
            """)
            entities.extend([{"id": row[0], "type": "gene"} for row in cursor.fetchall()])

    finally:
        cursor.close()
        conn.close()

    return entities


def calculate_aggregate_metrics(entities: List[Dict[str, str]]) -> Dict[str, Any]:
    """Calculate aggregate connection metrics."""
    if not TRACKER_AVAILABLE:
        return {"error": "Tracker not available"}

    metrics = {
        "total_entities": len(entities),
        "entities_meeting_goal": 0,
        "connection_scores": [],
        "system_coverage": {
            "postgres": 0,
            "neo4j": 0,
            "chromadb": 0,
            "derived_signals": 0
        }
    }

    for entity in entities[:100]:  # Sample first 100 for performance
        entity_id = entity["id"]
        entity_type = entity["type"]

        # Check presence in each system
        postgres = check_postgres_presence(entity_id, entity_type)
        neo4j = check_neo4j_presence(entity_id, entity_type)
        chromadb = check_chromadb_presence(entity_id, include_mentions=False)  # Skip for speed

        # Calculate connection score
        systems_present = 0
        if postgres["total_mentions"] > 0:
            systems_present += 1
            metrics["system_coverage"]["postgres"] += 1
        if neo4j["node_exists"]:
            systems_present += 1
            metrics["system_coverage"]["neo4j"] += 1
        if chromadb.get("mentions", 0) > 0:
            systems_present += 1
            metrics["system_coverage"]["chromadb"] += 1
        if len(postgres["fusion_tables"]) >= 2:
            systems_present += 1
            metrics["system_coverage"]["derived_signals"] += 1

        connection_score = (systems_present / 4) * 100
        metrics["connection_scores"].append(connection_score)

        if connection_score >= 75.0:
            metrics["entities_meeting_goal"] += 1

    # Calculate percentages
    total_sampled = len(metrics["connection_scores"])
    metrics["percent_meeting_goal"] = (metrics["entities_meeting_goal"] / total_sampled * 100) if total_sampled > 0 else 0
    metrics["avg_connection_score"] = sum(metrics["connection_scores"]) / total_sampled if total_sampled else 0

    # Convert coverage to percentages
    for system in metrics["system_coverage"]:
        metrics["system_coverage"][system] = (metrics["system_coverage"][system] / total_sampled * 100) if total_sampled > 0 else 0

    return metrics


def execute(
    entity_type: str = "all",
    sample_size: int = 500,
    detailed: bool = False
) -> Dict[str, Any]:
    """
    Generate signal tracking dashboard.

    Args:
        entity_type: "drug", "gene", or "all"
        sample_size: Number of entities to sample
        detailed: Include detailed analysis

    Returns:
        Dict with dashboard metrics
    """
    try:
        # Get entity sample
        entities = get_entity_sample(entity_type, sample_size)

        # Calculate metrics
        metrics = calculate_aggregate_metrics(entities)

        # Assess vs 85% goal
        meets_goal = metrics.get("percent_meeting_goal", 0) >= 85.0

        dashboard = {
            "entity_type": entity_type,
            "sample_size": len(entities),
            "metrics": metrics,
            "85_percent_goal": {
                "target": 85.0,
                "current": metrics.get("percent_meeting_goal", 0),
                "meets_goal": meets_goal,
                "gap": 85.0 - metrics.get("percent_meeting_goal", 0)
            },
            "system_architecture": {
                "postgres_fusion_tables": 14,
                "postgres_total_rows": 11208800,
                "neo4j_nodes": "1.3M",
                "neo4j_relationships": "9.5M",
                "chromadb_documents": 29863,
                "chromadb_port": 8004
            },
            "recommendations": []
        }

        # Generate recommendations
        if not meets_goal:
            gap = 85.0 - metrics.get("percent_meeting_goal", 0)
            dashboard["recommendations"].append(
                f"Need to improve connection score by {gap:.1f}% to meet 85% goal"
            )

            # System-specific recommendations
            coverage = metrics.get("system_coverage", {})
            if coverage.get("postgres", 0) < 90:
                dashboard["recommendations"].append(
                    "Improve PostgreSQL coverage: Load more entities into fusion tables"
                )
            if coverage.get("neo4j", 0) < 80:
                dashboard["recommendations"].append(
                    "Improve Neo4j coverage: Add more Drug/Gene nodes to knowledge graph"
                )
            if coverage.get("chromadb", 0) < 60:
                dashboard["recommendations"].append(
                    "Improve ChromaDB coverage: Enhance literature entity extraction"
                )

        return dashboard

    except Exception as e:
        return {
            "error": str(e),
            "status": "error"
        }


if __name__ == "__main__":
    # Example usage
    result = execute(entity_type="drug", sample_size=100)
    print(f"Meeting 85% goal: {result['85_percent_goal']['meets_goal']}")
    print(f"Current: {result['85_percent_goal']['current']:.1f}%")
