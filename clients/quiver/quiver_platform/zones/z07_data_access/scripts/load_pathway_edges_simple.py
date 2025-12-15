#!/usr/bin/env python3
"""
Simple Pathway Edge Loader for Stream 2 Testing

Loads critical pathway edges to Neo4j to enable mechanistic discovery:
1. Protein → Pathway (PARTICIPATES_IN / IN_PATHWAY)
2. Pathway → Disease (ASSOCIATED_WITH)
3. Gene → Pathway (via Protein)

Simplified version without Zone 10c dependencies.

Usage:
    python load_pathway_edges_simple.py
"""

import os
import sys
from pathlib import Path
from typing import List, Dict, Tuple

try:
    from neo4j import GraphDatabase
    import psycopg
except ImportError:
    print("❌ Missing dependencies. Install with:")
    print("   pip install neo4j psycopg[binary]")
    sys.exit(1)


# Configuration from environment
NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")
PG_URL = os.getenv("DATABASE_URL", "postgresql://postgres:expo_secure_pg_2025@localhost:5433/rescue")

BATCH_SIZE = 500


def load_protein_pathway_edges(driver, pg_conn):
    """Load Protein → Pathway edges from Reactome."""
    print("\n" + "=" * 80)
    print("LOADING PROTEIN → PATHWAY EDGES")
    print("=" * 80)

    # Query Reactome data from PostgreSQL
    print("📊 Querying Reactome protein-pathway associations from PostgreSQL...")

    try:
        with pg_conn.cursor() as cur:
            query = """
            SELECT DISTINCT
                e.uniprot_id,
                p.stable_id as pathway_id,
                p.display_name as pathway_name
            FROM reactome.physical_entity e
            JOIN reactome.physical_entity_2_pathway ep ON e.db_id = ep.physical_entity_id
            JOIN reactome.pathway p ON ep.pathway_id = p.db_id
            WHERE e.uniprot_id IS NOT NULL
              AND p.stable_id IS NOT NULL
              AND p.species_id = 48887  -- Homo sapiens
            LIMIT 50000
            """
            cur.execute(query)
            rows = cur.fetchall()
            print(f"Found {len(rows)} protein-pathway associations")

    except Exception as e:
        print(f"❌ PostgreSQL query failed: {e}")
        print("⚠️  Reactome data may not be loaded in PostgreSQL")
        return 0

    if len(rows) == 0:
        print("⚠️  No Reactome data found. Skip for now.")
        return 0

    # Load to Neo4j in batches
    print(f"📥 Loading to Neo4j in batches of {BATCH_SIZE}...")

    created = 0
    with driver.session() as session:
        for i in range(0, len(rows), BATCH_SIZE):
            batch = rows[i:i+BATCH_SIZE]

            query = """
            UNWIND $batch AS row
            MATCH (p:Protein {uniprot_id: row.uniprot_id})
            MERGE (pw:Pathway {reactome_id: row.pathway_id})
            ON CREATE SET
                pw.name = row.pathway_name,
                pw.source = 'Reactome',
                pw.loaded_at = datetime()
            MERGE (p)-[r:PARTICIPATES_IN]->(pw)
            ON CREATE SET r.source = 'Reactome'
            RETURN count(r) as created_count
            """

            batch_data = [
                {
                    "uniprot_id": row[0],
                    "pathway_id": row[1],
                    "pathway_name": row[2]
                }
                for row in batch
            ]

            try:
                result = session.run(query, batch=batch_data)
                record = result.single()
                batch_created = record["created_count"] if record else 0
                created += batch_created
                print(f"  Batch {i//BATCH_SIZE + 1}: {batch_created} edges created")
            except Exception as e:
                print(f"  ❌ Batch {i//BATCH_SIZE + 1} failed: {e}")

    print(f"\n✅ Created {created} Protein→Pathway edges")
    return created


def load_pathway_disease_edges(driver):
    """
    Infer Pathway → Disease edges from existing Gene → Disease associations.

    Logic: If Gene G is associated with Disease D, and Gene G participates in Pathway P,
    then Pathway P is implicated in Disease D.
    """
    print("\n" + "=" * 80)
    print("CREATING PATHWAY → DISEASE EDGES (INFERRED)")
    print("=" * 80)

    print("🧮 Inferring pathway-disease associations from gene-disease + gene-pathway...")

    with driver.session() as session:
        query = """
        // Find pathways implicated in diseases via genes
        MATCH (g:Gene)-[gd:ASSOCIATED_WITH]->(d:Disease)
        MATCH (prot:Protein {symbol: g.symbol})-[:PARTICIPATES_IN]->(pw:Pathway)

        // Create pathway-disease edge with aggregated score
        MERGE (pw)-[r:IMPLICATED_IN]->(d)
        ON CREATE SET
            r.score = gd.score,
            r.evidence = 'inferred_from_gene_disease',
            r.gene_count = 1,
            r.created_at = datetime()
        ON MATCH SET
            r.gene_count = r.gene_count + 1,
            r.score = CASE
                WHEN gd.score > r.score THEN gd.score
                ELSE r.score
            END

        RETURN count(DISTINCT r) as pathway_disease_count
        """

        try:
            result = session.run(query)
            record = result.single()
            count = record["pathway_disease_count"] if record else 0
            print(f"✅ Created/updated {count} Pathway→Disease edges")
            return count
        except Exception as e:
            print(f"❌ Failed to create pathway-disease edges: {e}")
            return 0


def create_gene_pathway_shortcut(driver):
    """
    Create Gene → Pathway shortcut edges (via Protein).

    Helps with queries that start from Gene instead of Protein.
    """
    print("\n" + "=" * 80)
    print("CREATING GENE → PATHWAY SHORTCUTS")
    print("=" * 80)

    print("🔗 Creating Gene→Pathway edges via Protein...")

    with driver.session() as session:
        query = """
        // Create Gene → Pathway edges via Protein
        MATCH (g:Gene)-[:ENCODES]->(prot:Protein)-[:PARTICIPATES_IN]->(pw:Pathway)
        MERGE (g)-[r:IN_PATHWAY]->(pw)
        ON CREATE SET
            r.via = 'protein',
            r.created_at = datetime()
        RETURN count(DISTINCT r) as gene_pathway_count
        """

        try:
            result = session.run(query)
            record = result.single()
            count = record["gene_pathway_count"] if record else 0
            print(f"✅ Created {count} Gene→Pathway shortcut edges")
            return count
        except Exception as e:
            print(f"❌ Failed to create gene-pathway shortcuts: {e}")
            return 0


def verify_pathway_connectivity(driver):
    """Verify pathway edges are loaded."""
    print("\n" + "=" * 80)
    print("VERIFICATION")
    print("=" * 80)

    with driver.session() as session:
        checks = [
            ("Pathway nodes", "MATCH (p:Pathway) RETURN count(p) as count"),
            ("Protein→Pathway edges", "MATCH (:Protein)-[r:PARTICIPATES_IN]->(:Pathway) RETURN count(r) as count"),
            ("Gene→Pathway edges", "MATCH (:Gene)-[r:IN_PATHWAY]->(:Pathway) RETURN count(r) as count"),
            ("Pathway→Disease edges", "MATCH (:Pathway)-[r:IMPLICATED_IN]->(:Disease) RETURN count(r) as count"),
        ]

        print()
        for label, query in checks:
            try:
                result = session.run(query)
                record = result.single()
                count = record["count"] if record else 0
                status = "✅" if count > 0 else "⚠️"
                print(f"{status} {label}: {count:,}")
            except Exception as e:
                print(f"❌ {label}: Error - {e}")

    print()


def main():
    """Main execution."""
    print("\n" + "=" * 80)
    print("PATHWAY EDGE LOADER - Stream 2 Support")
    print("=" * 80)
    print()

    # Connect to Neo4j
    print(f"Connecting to Neo4j at {NEO4J_URI}...")
    try:
        neo4j_driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
        neo4j_driver.verify_connectivity()
        print("✅ Neo4j connected")
    except Exception as e:
        print(f"❌ Neo4j connection failed: {e}")
        return 1

    # Connect to PostgreSQL
    print(f"Connecting to PostgreSQL...")
    try:
        pg_conn = psycopg.connect(PG_URL)
        print("✅ PostgreSQL connected")
    except Exception as e:
        print(f"❌ PostgreSQL connection failed: {e}")
        print("⚠️  Will skip Reactome data loading from PostgreSQL")
        pg_conn = None

    try:
        # Load pathway edges
        if pg_conn:
            protein_pathway_count = load_protein_pathway_edges(neo4j_driver, pg_conn)
        else:
            protein_pathway_count = 0
            print("\n⚠️  Skipping Protein→Pathway loading (no PostgreSQL)")

        pathway_disease_count = load_pathway_disease_edges(neo4j_driver)
        gene_pathway_count = create_gene_pathway_shortcut(neo4j_driver)

        # Verify
        verify_pathway_connectivity(neo4j_driver)

        # Summary
        print("=" * 80)
        print("SUMMARY")
        print("=" * 80)
        print(f"Protein→Pathway edges: {protein_pathway_count:,}")
        print(f"Pathway→Disease edges: {pathway_disease_count:,}")
        print(f"Gene→Pathway edges: {gene_pathway_count:,}")
        print()

        if protein_pathway_count + pathway_disease_count + gene_pathway_count > 0:
            print("✅ Pathway edges loaded successfully!")
            print("   Mechanistic explainer should now be able to discover pathways.")
        else:
            print("⚠️  No pathway edges loaded.")
            print("   Check that:")
            print("   - Reactome data is loaded in PostgreSQL")
            print("   - Gene-Disease associations exist in Neo4j")
            print("   - Protein-Gene edges (ENCODES) exist in Neo4j")

        print()
        return 0

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1

    finally:
        neo4j_driver.close()
        if pg_conn:
            pg_conn.close()


if __name__ == "__main__":
    sys.exit(main())
