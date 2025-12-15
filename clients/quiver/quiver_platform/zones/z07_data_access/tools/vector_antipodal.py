"""
Vector Antipodal Tool - Drug Rescue via PGVector Antipodal Similarity

CORRECT ARCHITECTURE:
1. Query PGVector (sapphire_database) for gene embedding
2. Invert embedding (multiply by -1) to get antipodal vector
3. Query PGVector for drugs similar to antipodal vector
4. Optionally enrich with Neo4j graph relationships

Author: Fixed for PGVector + Neo4j architecture
Date: 2025-12-01
Zone: z07_data_access/tools
"""

from typing import Dict, Any, List
import os
import time
import psycopg2
from neo4j import GraphDatabase
import sys
from pathlib import Path

# Add path for drug_name_resolver
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

# MIGRATED to v3.0 (2025-12-05): Master resolution tables (60x faster)
from clients.quiver.quiver_platform.zones.z07_data_access.drug_name_resolver_v3 import get_drug_name_resolver_v3 as get_drug_name_resolver

# Tool definition for Claude
TOOL_DEFINITION = {
    "name": "vector_antipodal",
    "description": """Find drug rescue candidates using antipodal (opposite) embedding similarity from PGVector.

**Architecture:**
1. Gets gene embedding from PGVector (sapphire_database)
2. Inverts embedding to find opposite direction
3. Searches PGVector for drugs similar to inverted embedding
4. Returns rescue candidates ranked by antipodal similarity

**Embedding Space:**
- modex_ep_unified_16d_v6_0: 16D MODEX unified space (BOTH genes AND drugs)
  - Contains 18,368 genes + 14,246 drugs (32,614 total entities)
  - Mechanism-of-action based embeddings
  - Required for antipodal drug-gene matching

**Rescue Score:**
- 1.0 = Perfect antipodal (drug opposite to gene dysfunction)
- 0.0 = Same direction (not a rescue candidate)

Examples:
- "What drugs rescue TSC2?" → Find antipodal drugs to TSC2
- "Rescue candidates for SCN1A" → Find opposite drugs
- "Find drugs opposite to KCNQ2" → Antipodal search

Performance: ~200ms for PGVector query
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "gene": {
                "type": "string",
                "description": "Gene symbol (case-insensitive). Examples: TSC2, SCN1A, KCNQ2"
            },
            "embedding_space": {
                "type": "string",
                "enum": ["modex", "auto"],
                "description": "Embedding space: 'modex' (16D unified drug+gene space), 'auto' (default: modex). Note: Only 'modex' supports antipodal matching.",
                "default": "auto"
            },
            "top_k": {
                "type": "integer",
                "description": "Number of rescue candidates to return (1-100)",
                "default": 20,
                "minimum": 1,
                "maximum": 100
            },
            "min_rescue_score": {
                "type": "number",
                "description": "Minimum antipodal score threshold (0.0-1.0). Score of 0.7 = cosine similarity -0.7 (strong opposite direction). Higher = more antipodal.",
                "default": 0.7,
                "minimum": 0.0,
                "maximum": 1.0
            },
            "enrich_with_neo4j": {
                "type": "boolean",
                "description": "Add Neo4j graph relationships for enrichment",
                "default": True
            }
        },
        "required": ["gene"]
    }
}


async def execute(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute antipodal rescue search using PGVector + Neo4j

    Args:
        params: Tool parameters

    Returns:
        Rescue candidates with scores
    """
    start_time = time.time()

    gene = params.get("gene", "").strip().upper()
    embedding_space = params.get("embedding_space", "auto")
    top_k = params.get("top_k", 20)
    min_rescue_score = params.get("min_rescue_score", 0.7)  # Changed from 0.5 to 0.7 for stronger antipodal
    enrich_with_neo4j = params.get("enrich_with_neo4j", True)

    if not gene:
        return {
            "success": False,
            "error": "Gene parameter required",
            "hint": "Examples: TSC2, SCN1A, KCNQ2"
        }

    # Auto-select embedding space
    if embedding_space == "auto":
        embedding_space = "modex"

    # Map to PGVector table name - UNIFIED TABLE for drug-gene antipodal
    # modex_ep_unified_16d_v6_0 contains BOTH genes AND drugs (32,614 entries)
    # This is the ONLY valid table for antipodal matching (need both entities in same space)
    unified_table = "modex_ep_unified_16d_v6_0"
    dimensions = 16

    if embedding_space not in ["modex", "auto"]:
        return {
            "success": False,
            "error": f"Invalid embedding_space: {embedding_space}. Only 'modex' supported for antipodal matching.",
            "valid_options": ["modex", "auto"],
            "reason": "Antipodal matching requires unified drug+gene embedding space"
        }

    try:
        # Connect to PGVector
        conn = psycopg2.connect(
            host=os.getenv("PGVECTOR_HOST", "localhost"),
            port=int(os.getenv("PGVECTOR_PORT", "5435")),
            database=os.getenv("PGVECTOR_DB", "sapphire_database"),
            user=os.getenv("PGVECTOR_USER", "postgres"),
            password=os.getenv("PGVECTOR_PASSWORD", "temppass123")
        )

        cursor = conn.cursor()

        # Step 1: Get gene embedding from PGVector unified table (case-insensitive)
        cursor.execute(f"""
            SELECT id, embedding
            FROM {unified_table}
            WHERE UPPER(id) = %s
            LIMIT 1
        """, (gene,))

        gene_result = cursor.fetchone()

        if not gene_result:
            # Try fuzzy match
            cursor.execute(f"""
                SELECT id, embedding
                FROM {unified_table}
                WHERE UPPER(id) LIKE %s
                LIMIT 1
            """, (f"%{gene}%",))

            gene_result = cursor.fetchone()

        if not gene_result:
            cursor.close()
            conn.close()

            return {
                "success": False,
                "error": f"Gene '{gene}' not found in PGVector table {unified_table}",
                "hint": "Check gene symbol spelling. Try: TSC2, SCN1A, KCNQ2",
                "embedding_space_used": embedding_space,
                "table_searched": unified_table
            }

        gene_id, gene_embedding = gene_result

        # Step 2: Find antipodal drugs from SAME unified table (opposite embeddings for rescue)
        #
        # Antipodal scoring:
        # - Cosine distance operator (<=>): distance = 1 - cosine_similarity
        # - For antipodal (opposite): cosine_similarity should be negative (close to -1)
        # - Distance ~2.0 means cosine_similarity ~-1.0 (perfect antipodal)
        # - Antipodal score = distance - 1 (gives 0.0 to 1.0 range)
        #
        # Example: distance=1.96 → cosine_sim=-0.96 → antipodal_score=0.96 ✅
        #
        # Filter to drugs only (exclude genes)
        # Drug pattern: 7-digit ID with dosage (e.g., "0211429_10uM" or "0211429_1.11uM")
        # This matches ONLY drugs, not genes like "FAM71E2" or "SYNGAP1"
        cursor.execute(f"""
            SELECT
                id,
                (embedding <=> %s::vector) as cosine_distance,
                (embedding <=> %s::vector) - 1.0 as antipodal_score,
                1 - (embedding <=> %s::vector) as cosine_similarity
            FROM {unified_table}
            WHERE id != %s
              AND (embedding <=> %s::vector) - 1.0 >= %s
              AND id ~ '^[0-9]{{7}}_'
            ORDER BY (embedding <=> %s::vector) DESC
            LIMIT %s
        """, (gene_embedding, gene_embedding, gene_embedding, gene_id, gene_embedding, min_rescue_score, gene_embedding, top_k))

        # Initialize drug name resolver for QS ID → commercial name mapping
        drug_name_resolver = get_drug_name_resolver()

        rescue_candidates = []
        for row in cursor.fetchall():
            drug_id, cosine_distance, antipodal_score, cosine_similarity = row

            # Parse dosage from EP drug IDs (format: "0211429_10uM")
            dosage_info = None
            clean_drug_id = drug_id
            if "_" in drug_id and ("uM" in drug_id or "nM" in drug_id or "mM" in drug_id):
                parts = drug_id.rsplit("_", 1)
                if len(parts) == 2:
                    clean_drug_id = parts[0]  # e.g., "0211429"
                    dosage_info = parts[1]    # e.g., "10uM"

            # Resolve drug commercial name using z07 resolver
            # Add QS prefix if not present (database stores IDs without prefix)
            lookup_id = clean_drug_id if clean_drug_id.startswith('QS') else f'QS{clean_drug_id}'
            name_info = drug_name_resolver.resolve(lookup_id)

            candidate = {
                "drug_id": clean_drug_id,  # QS ID for traceability
                "commercial_name": name_info.get('commercial_name', clean_drug_id),  # Resolved name
                "chembl_id": name_info.get('chembl_id', ''),
                "name_source": name_info.get('source', 'unknown'),
                "rescue_score": round(antipodal_score, 4),  # 0.0-1.0, higher = more antipodal
                "cosine_distance": round(cosine_distance, 4),  # PGVector <=> operator
                "cosine_similarity": round(cosine_similarity, 4),  # Should be negative for rescue
                "embedding_space": embedding_space
            }

            # Add dosage if available (EP embeddings)
            if dosage_info:
                candidate["dosage"] = dosage_info
                candidate["full_id"] = drug_id  # Keep original ID with dosage

            rescue_candidates.append(candidate)

        cursor.close()
        conn.close()

        # Step 4: Enrich with Neo4j if requested
        if enrich_with_neo4j and rescue_candidates:
            rescue_candidates = await _enrich_with_neo4j(
                gene_id,
                rescue_candidates
            )

        latency = (time.time() - start_time) * 1000

        return {
            "success": True,
            "gene": gene_id,
            "rescue_candidates": rescue_candidates,
            "candidate_count": len(rescue_candidates),
            "embedding_space": embedding_space,
            "pgvector_table": unified_table,
            "architecture": "unified_drug_gene_table",
            "dimensions": dimensions,
            "latency_ms": round(latency, 2),
            "data_sources": [f"PGVector Unified ({unified_table})", "Neo4j (enrichment)" if enrich_with_neo4j else f"PGVector Unified ({unified_table})"]
        }

    except Exception as e:
        latency = (time.time() - start_time) * 1000

        return {
            "success": False,
            "error": f"Antipodal search failed: {str(e)}",
            "gene": gene,
            "embedding_space": embedding_space,
            "latency_ms": round(latency, 2)
        }


async def _enrich_with_neo4j(gene_symbol: str, rescue_candidates: List[Dict]) -> List[Dict]:
    """
    Enrich rescue candidates with Neo4j graph relationships

    Args:
        gene_symbol: Gene being rescued
        rescue_candidates: List of drug candidates from PGVector

    Returns:
        Enriched candidates with graph data
    """
    try:
        uri = os.getenv('NEO4J_URI', 'bolt://localhost:7687')
        user = os.getenv('NEO4J_USER', 'neo4j')
        password = os.getenv('NEO4J_PASSWORD', 'testpassword123')
        database = os.getenv('NEO4J_DATABASE', 'neo4j')

        driver = GraphDatabase.driver(uri, auth=(user, password))

        with driver.session(database=database) as session:
            for candidate in rescue_candidates:
                drug_id = candidate["drug_id"]

                # Check if drug-gene relationship exists in graph
                result = session.run("""
                    MATCH (d:Drug)-[r]-(g:Gene {symbol: $gene})
                    WHERE d.id = $drug_id OR d.name = $drug_id OR d.chembl_id = $drug_id
                    RETURN type(r) as rel_type, properties(r) as rel_props
                    LIMIT 5
                """, gene=gene_symbol, drug_id=drug_id)

                relationships = []
                for record in result:
                    relationships.append({
                        "type": record["rel_type"],
                        "properties": dict(record["rel_props"]) if record["rel_props"] else {}
                    })

                if relationships:
                    candidate["neo4j_relationships"] = relationships
                    candidate["graph_validated"] = True
                else:
                    candidate["graph_validated"] = False

        driver.close()

    except Exception as e:
        # Don't fail the whole query if Neo4j enrichment fails
        print(f"⚠️  Neo4j enrichment failed: {e}")

    return rescue_candidates
