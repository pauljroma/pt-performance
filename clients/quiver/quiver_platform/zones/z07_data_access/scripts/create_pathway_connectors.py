#!/usr/bin/env python3
"""
Create Pathway Connector Edges

Bridges the gap between existing Gene→Pathway edges and what mechanistic_explainer needs:
1. Create Protein→Pathway edges (via Gene→Pathway + Gene→Protein mapping)
2. Create Pathway→Disease edges (via Gene→Disease + Gene→Pathway aggregation)

This enables mechanistic discovery without re-loading Reactome data.
"""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")


def create_protein_pathway_edges(driver):
    """Create Protein → Pathway edges via Gene."""
    print("\n" + "=" * 80)
    print("CREATING PROTEIN → PATHWAY EDGES")
    print("=" * 80)
    print("Creating Protein→Pathway edges via Gene→Protein→Pathway...")

    with driver.session() as session:
        query = """
        // Find Gene→Pathway edges, then link Protein→Pathway
        MATCH (g:Gene)-[gp:PARTICIPATES_IN|INFERRED_PARTICIPATES_IN]->(pw:Pathway)
        MATCH (prot:Protein)
        WHERE prot.symbol = g.symbol OR prot.gene_id = g.gene_id

        MERGE (prot)-[r:IN_PATHWAY]->(pw)
        ON CREATE SET
            r.via_gene = g.symbol,
            r.source = 'inferred_from_gene',
            r.created_at = datetime()

        RETURN count(DISTINCT r) as edge_count
        """

        print("Running Neo4j query...")
        result = session.run(query)
        record = result.single()
        count = record["edge_count"] if record else 0

        print(f"✅ Created {count:,} Protein→Pathway edges")
        return count


def create_pathway_disease_edges(driver):
    """Create Pathway → Disease edges via Gene aggregation."""
    print("\n" + "=" * 80)
    print("CREATING PATHWAY → DISEASE EDGES")
    print("=" * 80)
    print("Aggregating Gene→Disease + Gene→Pathway to infer Pathway→Disease...")

    with driver.session() as session:
        query = """
        // Find genes that link pathways to diseases
        MATCH (g:Gene)-[gp:PARTICIPATES_IN|INFERRED_PARTICIPATES_IN]->(pw:Pathway)
        MATCH (g)-[gd:ASSOCIATED_WITH]->(d:Disease)

        // Create pathway-disease edge
        // Aggregate score = max gene-disease score
        // Track gene count supporting the association
        WITH pw, d, max(gd.score) as max_score, count(DISTINCT g) as gene_count
        WHERE gene_count >= 2  // Require at least 2 genes for pathway-disease link

        MERGE (pw)-[r:ASSOCIATED_WITH]->(d)
        ON CREATE SET
            r.score = max_score,
            r.gene_count = gene_count,
            r.source = 'inferred_from_genes',
            r.created_at = datetime()
        ON MATCH SET
            r.gene_count = gene_count,
            r.score = CASE WHEN max_score > r.score THEN max_score ELSE r.score END

        RETURN count(r) as edge_count
        """

        print("Running Neo4j query...")
        result = session.run(query)
        record = result.single()
        count = record["edge_count"] if record else 0

        print(f"✅ Created {count:,} Pathway→Disease edges (min 2 genes per pathway-disease)")
        return count


def verify_edges(driver):
    """Verify connector edges."""
    print("\n" + "=" * 80)
    print("VERIFICATION")
    print("=" * 80)

    with driver.session() as session:
        checks = [
            ("Protein→Pathway (IN_PATHWAY)", "MATCH (:Protein)-[r:IN_PATHWAY]->(:Pathway) RETURN count(r) as count"),
            ("Pathway→Disease (ASSOCIATED_WITH)", "MATCH (:Pathway)-[r:ASSOCIATED_WITH]->(:Disease) RETURN count(r) as count"),
            ("Gene→Pathway (baseline)", "MATCH (:Gene)-[r:PARTICIPATES_IN]->(:Pathway) RETURN count(r) as count"),
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


def test_mechanistic_path(driver):
    """Test if a full mechanistic path now exists."""
    print("\n" + "=" * 80)
    print("TESTING MECHANISTIC PATH")
    print("=" * 80)

    print("Testing: Drug → Protein → Pathway → Disease path...\n")

    with driver.session() as session:
        query = """
        // Find a complete mechanistic path
        MATCH (drug:Drug)-[:TARGETS|TARGETS_DETAILED]->(prot:Protein)
              -[:IN_PATHWAY]->(pw:Pathway)
              -[:ASSOCIATED_WITH]->(d:Disease)
        RETURN drug.name as drug, prot.name as protein, pw.name as pathway, d.name as disease
        LIMIT 5
        """

        try:
            result = session.run(query)
            records = list(result)

            if len(records) > 0:
                print(f"✅ Found {len(records)} complete mechanistic paths!\n")
                for i, record in enumerate(records, 1):
                    print(f"{i}. {record['drug']} → {record['protein']} → {record['pathway']} → {record['disease']}")
                print("\n✅ Mechanistic discovery should now work!")
            else:
                print("⚠️  No complete mechanistic paths found.")
                print("   Check that Drug→Protein edges exist in Neo4j")

        except Exception as e:
            print(f"❌ Test failed: {e}")

    print()


def main():
    """Main execution."""
    print("\n" + "=" * 80)
    print("PATHWAY CONNECTOR CREATOR")
    print("=" * 80)
    print()

    # Connect
    print(f"Connecting to Neo4j at {NEO4J_URI}...")
    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
    driver.verify_connectivity()
    print("✅ Connected\n")

    try:
        # Create connector edges
        protein_pathway_count = create_protein_pathway_edges(driver)
        pathway_disease_count = create_pathway_disease_edges(driver)

        # Verify
        verify_edges(driver)

        # Test mechanistic path
        test_mechanistic_path(driver)

        # Summary
        print("=" * 80)
        print("SUMMARY")
        print("=" * 80)
        print(f"Protein→Pathway edges created: {protein_pathway_count:,}")
        print(f"Pathway→Disease edges created: {pathway_disease_count:,}")

        if protein_pathway_count > 0 and pathway_disease_count > 0:
            print("\n✅ SUCCESS! Mechanistic discovery should now work.")
        else:
            print("\n⚠️  PARTIAL: Some edges missing.")

        print()
        return 0

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1

    finally:
        driver.close()


if __name__ == "__main__":
    import sys
    sys.exit(main())
