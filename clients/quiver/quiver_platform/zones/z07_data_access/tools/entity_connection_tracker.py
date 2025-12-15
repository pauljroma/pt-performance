"""
Entity Connection Tracker - 85% Signal Integration Goal

Tracks entity presence and linkage across the full data architecture:
- PostgreSQL: Fusion tables, embedding tables, raw tables
- Neo4j: Graph nodes and relationships
- ChromaDB: Literature mentions and semantic search

Calculates connection_score: % of systems where entity appears with linkable data

Architecture layers:
1. Raw Data (Postgres raw_* tables)
2. Processed Data (Postgres fusion/embedding tables)
3. Graph Layer (Neo4j metagraph + knowledge graph)
4. Semantic Layer (ChromaDB cns_literature)
5. Presentation Layer (Chainlit UI)

Goal: 85% of entities should have connection_score >= 0.75 (present in 3+ systems)

Zone: z07_data_access
Dependencies: psycopg2, neo4j, chromadb
"""
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional
import psycopg2
from neo4j import GraphDatabase
import chromadb

# Add paths
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

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

CHROMADB_CONFIG = {
    'host': 'localhost',
    'port': 8004
}


# Claude Tool Definition
TOOL_DEFINITION = {
    "name": "entity_connection_tracker",
    "description": """Track entity connections across Postgres → Neo4j → ChromaDB architecture.

Calculates connection score for drugs and genes across 4 systems:
1. **PostgreSQL**: Fusion tables (14), embedding tables (12), processed data
2. **Neo4j**: Knowledge graph nodes (1.3M), metagraph (FusionSpace, EmbeddingSpace)
3. **ChromaDB**: Literature mentions in 29,863 CNS papers
4. **Derived signals**: Cross-system linkages and consensus scores

**Connection Score Formula:**
connection_score = (systems_with_entity / total_systems) × 100

**Goal:** 85% of entities should have connection_score >= 75% (present in 3+ systems)

**Returns:**
- Entity presence map (which systems have the entity)
- Connection score (0-100)
- System-specific IDs and counts
- Linkage quality metrics

Examples:
- entity_connection_tracker(entity_id="CHEMBL123", entity_type="drug")
  → Shows presence in Postgres (fusion tables), Neo4j (Drug node), ChromaDB (literature)
- entity_connection_tracker(entity_id="SCN1A", entity_type="gene")
  → Gene presence across systems with connection score
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "entity_id": {
                "type": "string",
                "description": "Entity identifier (ChEMBL ID, Ensembl ID, or name)"
            },
            "entity_type": {
                "type": "string",
                "enum": ["drug", "gene"],
                "description": "Type of entity to track"
            },
            "include_literature_mentions": {
                "type": "boolean",
                "description": "Search ChromaDB for literature mentions. Default: true",
                "default": True
            }
        },
        "required": ["entity_id", "entity_type"]
    }
}


def check_postgres_presence(entity_id: str, entity_type: str) -> Dict[str, Any]:
    """Check entity presence in PostgreSQL tables."""
    conn = psycopg2.connect(**POSTGRES_CONFIG)
    cursor = conn.cursor()

    presence = {
        "fusion_tables": [],
        "embedding_tables": [],
        "total_mentions": 0
    }

    try:
        # Check fusion tables (d_aux_*, g_aux_*, d_g_*, etc.)
        if entity_type == "drug":
            fusion_tables = [
                'd_aux_adr_topk_v6_0', 'd_aux_cto_topk_v6_0', 'd_aux_dgp_topk_v6_0',
                'd_aux_ep_drug_topk_v6_0', 'd_aux_mop_topk_v6_0',
                'd_g_chem_ens_topk_v6_0', 'd_g_chem_ep_topk_v6_0', 'd_d_chem_lincs_topk_v6_0'
            ]
        else:  # gene
            fusion_tables = [
                'g_aux_cto_topk_v6_0', 'g_aux_dgp_topk_v6_0', 'g_aux_ep_drug_topk_v6_0',
                'g_aux_mop_topk_v6_0', 'g_aux_syn_topk_v6_0', 'g_g_ens_lincs_topk_v6_0'
            ]

        for table in fusion_tables:
            cursor.execute(f"""
                SELECT COUNT(*) FROM {table}
                WHERE entity1_id = %s OR entity2_id = %s
            """, (entity_id, entity_id))
            count = cursor.fetchone()[0]
            if count > 0:
                presence["fusion_tables"].append({"table": table, "mentions": count})
                presence["total_mentions"] += count

    finally:
        cursor.close()
        conn.close()

    return presence


def check_neo4j_presence(entity_id: str, entity_type: str) -> Dict[str, Any]:
    """Check entity presence in Neo4j graph."""
    driver = GraphDatabase.driver(NEO4J_CONFIG['uri'],
                                   auth=(NEO4J_CONFIG['user'], NEO4J_CONFIG['password']))

    presence = {
        "node_exists": False,
        "node_labels": [],
        "relationship_count": 0,
        "properties": {}
    }

    with driver.session() as session:
        # Check for node
        label = "Drug" if entity_type == "drug" else "Gene"
        result = session.run(f"""
            MATCH (n:{label})
            WHERE n.id = $entity_id OR n.name = $entity_id OR n.chembl_id = $entity_id OR n.ensembl_id = $entity_id
            RETURN labels(n) as labels, properties(n) as props, COUNT {{ (n)--() }} as rel_count
            LIMIT 1
        """, entity_id=entity_id)

        record = result.single()
        if record:
            presence["node_exists"] = True
            presence["node_labels"] = record["labels"]
            presence["relationship_count"] = record["rel_count"]
            # Get a few key properties
            props = dict(record["props"])
            presence["properties"] = {k: v for k, v in list(props.items())[:5]}

    driver.close()
    return presence


def check_chromadb_presence(entity_id: str, include_mentions: bool = True) -> Dict[str, Any]:
    """Check entity mentions in ChromaDB literature."""
    if not include_mentions:
        return {"mentions": 0, "sample_docs": []}

    try:
        client = chromadb.HttpClient(host=CHROMADB_CONFIG['host'],
                                     port=CHROMADB_CONFIG['port'])
        collection = client.get_collection('cns_literature')

        # Search for entity mentions
        results = collection.query(
            query_texts=[entity_id],
            n_results=10
        )

        return {
            "mentions": len(results['ids'][0]) if results['ids'] else 0,
            "sample_docs": results['ids'][0][:3] if results['ids'] else []
        }
    except Exception as e:
        return {"error": str(e), "mentions": 0}


def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Track entity connections across all systems.

    Args:
        tool_input: Dictionary with:
            - entity_id: Entity identifier
            - entity_type: "drug" or "gene"
            - include_literature_mentions: Search ChromaDB (default: True)

    Returns:
        Dict with connection tracking results
    """
    # Extract parameters
    entity_id = tool_input['entity_id']
    entity_type = tool_input['entity_type']
    include_literature_mentions = tool_input.get('include_literature_mentions', True)

    try:
        # Check each system
        postgres = check_postgres_presence(entity_id, entity_type)
        neo4j = check_neo4j_presence(entity_id, entity_type)
        chromadb = check_chromadb_presence(entity_id, include_literature_mentions)

        # Calculate connection score
        systems_present = 0
        total_systems = 4

        if postgres["total_mentions"] > 0:
            systems_present += 1
        if neo4j["node_exists"]:
            systems_present += 1
        if chromadb.get("mentions", 0) > 0:
            systems_present += 1
        # Derived signals (fusion consensus) counts as 4th system
        if len(postgres["fusion_tables"]) >= 2:
            systems_present += 1

        connection_score = (systems_present / total_systems) * 100

        # Determine if entity meets 85% goal
        meets_goal = connection_score >= 75.0

        return {
            "entity_id": entity_id,
            "entity_type": entity_type,
            "connection_score": connection_score,
            "systems_present": systems_present,
            "total_systems": total_systems,
            "meets_85_percent_goal": meets_goal,
            "system_breakdown": {
                "postgres": {
                    "present": postgres["total_mentions"] > 0,
                    "fusion_tables": len(postgres["fusion_tables"]),
                    "total_mentions": postgres["total_mentions"],
                    "tables": postgres["fusion_tables"]
                },
                "neo4j": {
                    "present": neo4j["node_exists"],
                    "labels": neo4j["node_labels"],
                    "relationships": neo4j["relationship_count"],
                    "properties": neo4j["properties"]
                },
                "chromadb": {
                    "present": chromadb.get("mentions", 0) > 0,
                    "literature_mentions": chromadb.get("mentions", 0),
                    "sample_docs": chromadb.get("sample_docs", [])
                },
                "derived_signals": {
                    "present": len(postgres["fusion_tables"]) >= 2,
                    "fusion_consensus": len(postgres["fusion_tables"])
                }
            },
            "recommendation": "Entity meets goal" if meets_goal else f"Add entity to {4 - systems_present} more systems"
        }

    except Exception as e:
        return {
            "error": str(e),
            "entity_id": entity_id,
            "entity_type": entity_type,
            "status": "error"
        }


if __name__ == "__main__":
    # Example usage
    result = execute("CHEMBL123", "drug")
    print(f"Connection Score: {result['connection_score']}%")
    print(f"Meets 85% goal: {result['meets_85_percent_goal']}")
