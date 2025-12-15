#!/usr/bin/env python3
"""
# MIGRATION NOTE (2025-12-04): Updated drug embedding table
# Context: Drug properties (drug-only)
# Previous: modex_ep_unified_16d_v6_0 (drug-gene UNIFIED, wrong for drug-only ops)
# Current: drug_chemical_v6_0_256d (drug-only, correct)

Drug Properties Detail Tool - Query PGVector + Neo4j for comprehensive drug data

Provides deep dive into drug properties combining:
- PGVector metadata (drug_chemical_v6_0_256d or drug_chemical_v6_0_256d)
- Neo4j drug node properties (pharmacology, indications, etc.)
- ChEMBL molecular properties (from rescue database)

Architecture:
1. Query PGVector for drug metadata (embeddings + metadata)
2. Enrich with Neo4j drug node properties
3. Merge both sources for comprehensive profile

Author: claude-code-agent
Date: 2025-12-01
Version: 3.1 (PGVector + Neo4j)
"""

from typing import Dict, Any, Optional, List
import sys
import os
import time
import psycopg2
from pathlib import Path

# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import validate_tool_input, format_validation_response, harmonize_drug_id, validate_input
    HARMONIZATION_AVAILABLE = True
    VALIDATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
    VALIDATION_AVAILABLE = False

# Add parent directory to path for imports
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

from zones.z07_data_access.postgres_connection import query_postgres
# MIGRATED to v3.0 (2025-12-05): Master resolution tables (60x faster)
from zones.z07_data_access.drug_name_resolver_v3 import get_drug_name_resolver_v3 as get_drug_name_resolver_v21


TOOL_DEFINITION = {
    "name": "drug_properties_detail",
    "description": """Query comprehensive drug properties from PGVector + Neo4j + ChEMBL.

    This tool provides deep scientific details about drugs combining multiple sources:

    **PGVector Sources:**
    - Drug embeddings (39D EP or 16D MODEX spaces)
    - Embedding metadata (dimensionality, norms)
    - Drug ID standardization

    **Neo4j Graph Properties:**
    - Pharmacological properties (mechanism of action)
    - Indications and therapeutic uses
    - Drug-target interactions
    - Pathway associations
    - Clinical data (trial status, approvals)

    **ChEMBL Molecular Data:**
    - Molecular weight, LogP, PSA
    - H-bond donors/acceptors
    - Structure (SMILES, InChI)
    - Rotatable bonds, aromatic rings

    Use this when you need complete drug characterization from all available sources.

    Example queries:
    - "Show me detailed properties for Rapamycin"
    - "What mTOR inhibitors are approved?"
    - "Give me targets for anti-epilepsy drugs"
    """,
    "input_schema": {
        "type": "object",
        "properties": {
            "drug_name": {
                "type": "string",
                "description": "Drug identifier: name, ChEMBL ID (CHEMBL1234), RxNorm, LINCS ID (BRD-K), or Quiver ID"
            },
            "include_pgvector": {
                "type": "boolean",
                "description": "Include PGVector embeddings metadata (default: true)",
                "default": True
            },
            "include_neo4j": {
                "type": "boolean",
                "description": "Include Neo4j graph properties (default: true)",
                "default": True
            },
            "include_chembl": {
                "type": "boolean",
                "description": "Include ChEMBL molecular properties (default: true)",
                "default": True
            }
        },
        "required": ["drug_name"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute drug properties lookup from PGVector + Neo4j + ChEMBL.

    Architecture:
    1. Query PGVector for drug metadata (embeddings)
    2. Query Neo4j for graph properties
    3. Query ChEMBL for molecular properties
    4. Merge all sources
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "drug_properties_detail")
        if validation_errors:
            return format_validation_response("drug_properties_detail", validation_errors)

    start_time = time.time()

    try:
        drug_name = tool_input["drug_name"]
        include_pgvector = tool_input.get("include_pgvector", True)
        include_neo4j = tool_input.get("include_neo4j", True)
        include_chembl = tool_input.get("include_chembl", True)

        # Normalize drug name
        drug_normalized = drug_name.strip()

        # STEP 1: Resolve drug name to QS ID / ChEMBL ID using drug_name_resolver
        resolver = get_drug_name_resolver_v21()
        drug_info = resolver.resolve(drug_normalized)

        qs_id = drug_info.get('drug_id', drug_normalized)
        chembl_id = drug_info.get('chembl_id', '')
        commercial_name = drug_info.get('commercial_name', drug_normalized)

        result = {
            "success": True,
            "drug_name": drug_name,
            "normalized_name": drug_normalized,
            "qs_id": qs_id,
            "chembl_id": chembl_id,
            "commercial_name": commercial_name,
            "resolver_source": drug_info.get('source', 'none'),
            "data_sources": [],
            "metadata": {}
        }

        # STREAM 1: PGVector drug metadata
        pgvector_data = {}
        if include_pgvector:
            # Try with QS ID first, then ChEMBL ID, then commercial name
            pgvector_data = await query_pgvector_drug_metadata(qs_id, chembl_id, commercial_name)
            if pgvector_data.get("found"):
                result["data_sources"].append("PGVector")
                # Store PGVector data (embeddings metadata, drug ID, dosages)
                result["metadata"]["pgvector"] = pgvector_data

        # STREAM 2: Neo4j enrichment
        neo4j_data = {}
        if include_neo4j:
            neo4j_data = await query_neo4j_drug_properties(drug_normalized)
            if neo4j_data.get("found"):
                result["data_sources"].append("Neo4j")
                # Store Neo4j properties (targets, indications, MOA)
                result["metadata"]["neo4j"] = neo4j_data

        # STREAM 3: ChEMBL molecular properties
        chembl_data = {}
        if include_chembl:
            chembl_data = await get_molecular_properties(drug_normalized)
            if chembl_data.get("found"):
                result["data_sources"].append("ChEMBL")
                # Store ChEMBL properties (molecular weight, structure, etc.)
                result["metadata"]["chembl"] = chembl_data

        # Check if we found any data
        if not result["data_sources"]:
            result["success"] = False
            result["error"] = f"No data found for drug '{drug_name}' in any source (PGVector, Neo4j, ChEMBL)"
            result["hint"] = "Try alternative drug name or check spelling"
            return result

        # STREAM 4: Merge all sources into unified metadata
        result["metadata"]["unified"] = merge_drug_metadata(pgvector_data, neo4j_data, chembl_data)

        result["query_time_ms"] = round((time.time() - start_time) * 1000, 2)

        return result

    except Exception as e:
        import traceback
        return {
            "success": False,
            "error": f"Drug properties query failed: {str(e)}",
            "traceback": traceback.format_exc(),
            "hint": "Database connectivity issue. Check PGVector, Neo4j, and PostgreSQL connections."
        }


async def query_pgvector_drug_metadata(qs_id: str, chembl_id: str, commercial_name: str) -> Dict[str, Any]:
    """
    Query PGVector for drug metadata from embedding tables.

    Architecture Pattern (from vector_antipodal.py):
    1. Try drug_chemical_v6_0_256d (39D EP space - primary, has dosages)
    2. Fallback to drug_chemical_v6_0_256d (16D MODEX space)
    3. Extract dosage from EP drug IDs (format: "DrugName_X.XX uM")
    4. Return embedding metadata, normalized drug ID, and all dosages
    """
    import logging
    logger = logging.getLogger(__name__)

    try:
        logger.info(f"PGVector search: qs_id='{qs_id}', chembl_id='{chembl_id}', commercial_name='{commercial_name}'")
        # Connect to PGVector
        conn = psycopg2.connect(
            host=os.getenv("PGVECTOR_HOST", "localhost"),
            port=int(os.getenv("PGVECTOR_PORT", "5435")),
            database=os.getenv("PGVECTOR_DB", "sapphire_database"),
            user=os.getenv("PGVECTOR_USER", "postgres"),
            password=os.getenv("PGVECTOR_PASSWORD", "temppass123")
        )

        cursor = conn.cursor()

        # Try DRUG_CHEMICAL_V6_0_256D first (primary: 256D chemical fingerprints)
        # Search by QS ID, ChEMBL ID, or commercial name
        # SCHEMA FIX: Base tables have no 'metadata' column (only id, embedding, version, created_at)
        search_terms = [qs_id.upper(), chembl_id.upper() if chembl_id else '', commercial_name.upper()]

        cursor.execute("""
            SELECT id, embedding
            FROM drug_chemical_v6_0_256d
            WHERE UPPER(id) = %s
               OR UPPER(id) = %s
               OR UPPER(id) = %s
               OR UPPER(id) LIKE %s
               OR UPPER(id) LIKE %s
            LIMIT 10
        """, (search_terms[0], search_terms[1], search_terms[2],
              f"%{search_terms[0]}%", f"%{search_terms[2]}%"))

        results = cursor.fetchall()
        embedding_space = "DRUG_CHEMICAL_256D_v6_0"
        logger.info(f"DRUG_CHEMICAL_256D results: {len(results)} rows found")

        # Fallback to MODEX_EP_UNIFIED_16D if not found
        if not results:
            cursor.execute("""
                SELECT id, embedding
                FROM drug_chemical_v6_0_256d
                WHERE UPPER(id) = %s
                   OR UPPER(id) = %s
                   OR UPPER(id) = %s
                   OR UPPER(id) LIKE %s
                   OR UPPER(id) LIKE %s
                LIMIT 10
            """, (search_terms[0], search_terms[1], search_terms[2],
                  f"%{search_terms[0]}%", f"%{search_terms[2]}%"))

            results = cursor.fetchall()
            embedding_space = "MODEX_EP_UNIFIED_16D_v6_0"

        cursor.close()
        conn.close()

        if results:
            # Extract dosages from all matching EP drug IDs
            # SCHEMA FIX: Only 2 columns returned (id, embedding), no metadata
            dosages = []
            drug_ids = []
            primary_drug_id = results[0][0]
            primary_embedding = results[0][1]

            for row in results:
                drug_id_full = row[0]
                drug_ids.append(drug_id_full)

                # Parse dosage from EP drug IDs (format: "DrugName_X.XX uM")
                if "_" in drug_id_full and any(unit in drug_id_full for unit in ['uM', 'nM', 'mM', 'µM']):
                    parts = drug_id_full.rsplit('_', 1)
                    if len(parts) == 2:
                        dosage = parts[1]  # e.g., "0.123 uM"
                        if dosage not in dosages:
                            dosages.append(dosage)

            # Calculate embedding norm (embedding might be string or list)
            embedding_norm = None
            if primary_embedding:
                try:
                    if isinstance(primary_embedding, str):
                        # Parse string representation: "[0.123, 0.456, ...]"
                        import json
                        primary_embedding = json.loads(primary_embedding.replace("'", '"'))
                    embedding_norm = float(sum(x**2 for x in primary_embedding) ** 0.5)
                except:
                    # Skip norm calculation if parsing fails
                    pass

            return {
                "found": True,
                "drug_id": primary_drug_id,
                "all_drug_ids": drug_ids,
                "embedding_space": embedding_space,
                "embedding_dimension": 256 if "256D" in embedding_space else 16,
                "embedding_norm": embedding_norm,
                "metadata": {},  # SCHEMA FIX: No metadata column exists
                "dosages": dosages,
                "dosage_count": len(dosages),
                "source": "PGVector"
            }
        else:
            logger.warning(f"No results found in EP_39D or MODEX_16D for: qs_id='{qs_id}', chembl_id='{chembl_id}', commercial_name='{commercial_name}'")
            return {"found": False}

    except Exception as e:
        logger.error(f"PGVector query error: {str(e)}", exc_info=True)
        return {"found": False, "error": str(e)}


async def query_neo4j_drug_properties(drug_name: str) -> Dict[str, Any]:
    """
    Query Neo4j for drug node properties and relationships.

    Returns:
    - Drug properties (name, synonyms, etc.)
    - Targets (proteins/genes the drug interacts with)
    - Indications (diseases the drug treats)
    - Mechanism of action
    - Relationships metadata

    Pattern: Direct Neo4j driver following entity_metadata.py approach
    """
    try:
        from neo4j import GraphDatabase

        # Get Neo4j connection parameters from environment
        neo4j_uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
        neo4j_user = os.getenv("NEO4J_USER", "neo4j")
        neo4j_password = os.getenv("NEO4J_PASSWORD", "rescue123")

        driver = GraphDatabase.driver(neo4j_uri, auth=(neo4j_user, neo4j_password))

        try:
            with driver.session() as session:
                # Query 1: Find drug node and its properties
                cypher_query = """
                MATCH (d:Drug)
                WHERE d.id = $drug_id OR d.name = $drug_id OR d.symbol = $drug_id
                      OR UPPER(d.id) = $drug_id_upper OR UPPER(d.name) = $drug_id_upper
                RETURN d, labels(d) as labels
                LIMIT 1
                """

                result = session.run(
                    cypher_query,
                    {"drug_id": drug_name, "drug_id_upper": drug_name.upper()}
                ).data()

                if not result:
                    driver.close()
                    return {"found": False}

                drug_node = result[0]['d']
                drug_properties = dict(drug_node)

                # Query 2: Get drug targets
                targets_query = """
                MATCH (d:Drug)-[r:TARGETS]->(p:Protein)
                WHERE d.id = $drug_id OR UPPER(d.id) = $drug_id_upper
                RETURN p.id as target_id, p.name as target_name, type(r) as rel_type, r.score as score
                LIMIT 50
                """

                targets_result = session.run(
                    targets_query,
                    {"drug_id": drug_name, "drug_id_upper": drug_name.upper()}
                ).data()

                targets = []
                if targets_result:
                    for row in targets_result:
                        targets.append({
                            "target_id": row.get("target_id"),
                            "target_name": row.get("target_name"),
                            "relationship": row.get("rel_type"),
                            "score": row.get("score")
                        })

                # Query 3: Get drug indications (diseases)
                indications_query = """
                MATCH (d:Drug)-[r:INDICATED_FOR]->(dis:Disease)
                WHERE d.id = $drug_id OR UPPER(d.id) = $drug_id_upper
                RETURN dis.id as disease_id, dis.name as disease_name, r.evidence as evidence
                LIMIT 20
                """

                indications_result = session.run(
                    indications_query,
                    {"drug_id": drug_name, "drug_id_upper": drug_name.upper()}
                ).data()

                indications = []
                if indications_result:
                    for row in indications_result:
                        indications.append({
                            "disease_id": row.get("disease_id"),
                            "disease_name": row.get("disease_name"),
                            "evidence": row.get("evidence")
                        })

                # Query 4: Get drug degree (relationship count)
                degree_query = """
                MATCH (d:Drug)-[r]-(n)
                WHERE d.id = $drug_id OR UPPER(d.id) = $drug_id_upper
                RETURN type(r) as rel_type, count(*) as count
                """

                degree_result = session.run(
                    degree_query,
                    {"drug_id": drug_name, "drug_id_upper": drug_name.upper()}
                ).data()

                relationships = {}
                total_degree = 0
                if degree_result:
                    for row in degree_result:
                        rel_type = row['rel_type']
                        count = row['count']
                        relationships[rel_type] = count
                        total_degree += count

                result = {
                    "found": True,
                    "drug_id": drug_properties.get("id"),
                    "drug_name": drug_properties.get("name"),
                    "properties": drug_properties,
                    "targets": targets,
                    "target_count": len(targets),
                    "indications": indications,
                    "indication_count": len(indications),
                    "graph": {
                        "degree": total_degree,
                        "relationships": relationships
                    },
                    "source": "Neo4j"
                }

        finally:
            driver.close()

        return result

    except Exception as e:
        return {"found": False, "error": str(e)}


async def get_molecular_properties(drug_name: str) -> Dict[str, Any]:
    """Query molecular properties from ChEMBL PostgreSQL database."""
    try:
        query = """
        SELECT
            md.pref_name,
            md.chembl_id,
            cs.canonical_smiles,
            cs.standard_inchi,
            cp.mw_freebase as molecular_weight,
            cp.alogp,
            cp.hba as h_bond_acceptors,
            cp.hbd as h_bond_donors,
            cp.psa as polar_surface_area,
            cp.rtb as rotatable_bonds,
            cp.aromatic_rings,
            cp.heavy_atoms,
            md.max_phase as development_phase
        FROM molecule_dictionary md
        LEFT JOIN compound_structures cs ON md.molregno = cs.molregno
        LEFT JOIN compound_properties cp ON md.molregno = cp.molregno
        WHERE LOWER(md.pref_name) = LOWER($1)
           OR LOWER(md.pref_name) LIKE LOWER($1 || '%')
        LIMIT 1
        """

        result = await query_postgres(query, [drug_name], database="rescue")

        if result:
            row = result[0]
            return {
                "found": True,
                "chembl_id": row.get("chembl_id"),
                "preferred_name": row.get("pref_name"),
                "molecular_weight": row.get("molecular_weight"),
                "alogp": row.get("alogp"),
                "h_bond_acceptors": row.get("h_bond_acceptors"),
                "h_bond_donors": row.get("h_bond_donors"),
                "polar_surface_area": row.get("polar_surface_area"),
                "rotatable_bonds": row.get("rotatable_bonds"),
                "aromatic_rings": row.get("aromatic_rings"),
                "heavy_atoms": row.get("heavy_atoms"),
                "development_phase": row.get("development_phase"),
                "smiles": row.get("canonical_smiles"),
                "inchi": row.get("standard_inchi")[:100] + "..." if row.get("standard_inchi") else None,
                "source": "ChEMBL"
            }
        else:
            return {"found": False}

    except Exception as e:
        return {"found": False, "error": str(e)}


def merge_drug_metadata(
    pgvector_data: Dict[str, Any],
    neo4j_data: Dict[str, Any],
    chembl_data: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Merge drug metadata from all sources (PGVector, Neo4j, ChEMBL).

    Pattern:
    - PGVector: Embeddings and standardized drug ID
    - Neo4j: Pharmacology, targets, indications, graph relationships
    - ChEMBL: Molecular properties, structure, development phase

    Returns unified metadata with all information integrated.
    """
    unified = {
        "primary_id": None,
        "embedding": {},
        "pharmacology": {},
        "molecular": {},
        "clinical": {}
    }

    # STREAM 1: Get primary ID (prefer Neo4j > PGVector)
    if neo4j_data.get("found"):
        unified["primary_id"] = neo4j_data.get("drug_id") or neo4j_data.get("drug_name")
    elif pgvector_data.get("found"):
        unified["primary_id"] = pgvector_data.get("drug_id")

    # STREAM 2: Embedding metadata with dosages
    if pgvector_data.get("found"):
        unified["embedding"] = {
            "space": pgvector_data.get("embedding_space"),
            "dimensions": pgvector_data.get("embedding_dimension"),
            "norm": pgvector_data.get("embedding_norm"),
            "metadata": pgvector_data.get("metadata", {}),
            "dosages": pgvector_data.get("dosages", []),
            "dosage_count": pgvector_data.get("dosage_count", 0),
            "all_drug_ids": pgvector_data.get("all_drug_ids", [])
        }

    # STREAM 3: Pharmacology (Neo4j)
    if neo4j_data.get("found"):
        unified["pharmacology"] = {
            "targets": neo4j_data.get("targets", []),
            "target_count": neo4j_data.get("target_count", 0),
            "indications": neo4j_data.get("indications", []),
            "indication_count": neo4j_data.get("indication_count", 0),
            "graph_degree": neo4j_data.get("graph", {}).get("degree", 0),
            "relationships": neo4j_data.get("graph", {}).get("relationships", {})
        }
        # Add Neo4j properties if available
        if neo4j_data.get("properties"):
            unified["neo4j_properties"] = neo4j_data["properties"]

    # STREAM 4: Molecular properties (ChEMBL)
    if chembl_data.get("found"):
        unified["molecular"] = {
            "chembl_id": chembl_data.get("chembl_id"),
            "preferred_name": chembl_data.get("preferred_name"),
            "molecular_weight": chembl_data.get("molecular_weight"),
            "lipophilicity_alogp": chembl_data.get("alogp"),
            "h_bond_acceptors": chembl_data.get("h_bond_acceptors"),
            "h_bond_donors": chembl_data.get("h_bond_donors"),
            "polar_surface_area": chembl_data.get("polar_surface_area"),
            "rotatable_bonds": chembl_data.get("rotatable_bonds"),
            "aromatic_rings": chembl_data.get("aromatic_rings"),
            "heavy_atoms": chembl_data.get("heavy_atoms"),
            "smiles": chembl_data.get("smiles"),
            "inchi": chembl_data.get("inchi")
        }
        unified["clinical"] = {
            "development_phase": chembl_data.get("development_phase")
        }

    return unified


# Export for tool registration
__all__ = ["TOOL_DEFINITION", "execute"]
