#!/usr/bin/env python3
"""
Create Gene → Protein (ENCODES) Edges

Creates the missing link in the mechanistic discovery chain:
Drug → Gene → Protein → Pathway → Disease

Matches Genes to Proteins by:
1. Gene.symbol = Protein.symbol
2. Gene.ensembl_id = Protein.ensembl_id
3. Gene.uniprot_id = Protein.uniprot_id

Expected: ~20,000 edges (one per protein-coding gene)
"""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")


def create_gene_protein_edges(driver):
    """Create Gene → Protein ENCODES edges."""
    print("\n" + "=" * 80)
    print("CREATING GENE → PROTEIN (ENCODES) EDGES")
    print("=" * 80)
    print()

    with driver.session() as session:
        # Method 1: Match by symbol
        print("Method 1: Matching by symbol...")
        query1 = """
        MATCH (g:Gene), (p:Protein)
        WHERE g.symbol IS NOT NULL
          AND p.symbol IS NOT NULL
          AND g.symbol = p.symbol
        MERGE (g)-[r:ENCODES]->(p)
        ON CREATE SET
            r.match_method = 'symbol',
            r.created_at = datetime()
        RETURN count(DISTINCT r) as edge_count
        """
        result = session.run(query1)
        record = result.single()
        count1 = record["edge_count"] if record else 0
        print(f"  ✅ Created {count1:,} edges via symbol matching")

        # Method 2: Match by Ensembl ID
        print("\nMethod 2: Matching by Ensembl ID...")
        query2 = """
        MATCH (g:Gene), (p:Protein)
        WHERE g.ensembl_id IS NOT NULL
          AND p.ensembl_id IS NOT NULL
          AND g.ensembl_id = p.ensembl_id
        MERGE (g)-[r:ENCODES]->(p)
        ON CREATE SET
            r.match_method = 'ensembl_id',
            r.created_at = datetime()
        ON MATCH SET
            r.match_method = r.match_method + ',ensembl_id'
        RETURN count(DISTINCT r) as edge_count
        """
        result = session.run(query2)
        record = result.single()
        count2 = record["edge_count"] if record else 0
        print(f"  ✅ Created {count2:,} edges via Ensembl ID matching")

        # Method 3: Match by UniProt ID (if Gene has it)
        print("\nMethod 3: Matching by UniProt ID...")
        query3 = """
        MATCH (g:Gene), (p:Protein)
        WHERE g.uniprot_id IS NOT NULL
          AND p.uniprot_id IS NOT NULL
          AND g.uniprot_id = p.uniprot_id
        MERGE (g)-[r:ENCODES]->(p)
        ON CREATE SET
            r.match_method = 'uniprot_id',
            r.created_at = datetime()
        ON MATCH SET
            r.match_method = r.match_method + ',uniprot_id'
        RETURN count(DISTINCT r) as edge_count
        """
        result = session.run(query3)
        record = result.single()
        count3 = record["edge_count"] if record else 0
        print(f"  ✅ Created {count3:,} edges via UniProt ID matching")

        # Total unique edges
        print("\nCounting total unique ENCODES edges...")
        query_total = """
        MATCH (g:Gene)-[r:ENCODES]->(p:Protein)
        RETURN count(r) as total_count
        """
        result = session.run(query_total)
        record = result.single()
        total = record["total_count"] if record else 0

        print(f"\n✅ Total Gene→Protein (ENCODES) edges: {total:,}")
        return total


def verify_mechanistic_path(driver):
    """Verify that the full mechanistic path now exists."""
    print("\n" + "=" * 80)
    print("VERIFICATION: Testing Full Mechanistic Path")
    print("=" * 80)
    print()

    with driver.session() as session:
        # Test the full path
        print("Testing: Drug → Gene → Protein → Pathway → Disease...\n")
        query = """
        MATCH (drug:Drug)-[:TARGETS]->(gene:Gene)
              -[:ENCODES]->(prot:Protein)
              -[:IN_PATHWAY]->(pw:Pathway)
              -[:ASSOCIATED_WITH]->(d:Disease)
        RETURN drug.name as drug, gene.symbol as gene, prot.name as protein,
               pw.name as pathway, d.name as disease
        LIMIT 10
        """

        result = session.run(query)
        records = list(result)

        if len(records) > 0:
            print(f"✅ SUCCESS! Found {len(records)} complete mechanistic paths:\n")
            for i, record in enumerate(records, 1):
                print(f"{i}. {record['drug']} → {record['gene']} → {record['protein']}")
                print(f"   → {record['pathway']} → {record['disease']}")
                print()
            print("🎉 Mechanistic discovery should now work!")
        else:
            print("⚠️  No complete paths found yet.")
            print("   Debugging...")

            # Debug: Check each step
            checks = [
                ("Drug→Gene", "MATCH (d:Drug)-[:TARGETS]->(g:Gene) RETURN count(DISTINCT d) as drugs, count(*) as edges"),
                ("Gene→Protein", "MATCH (g:Gene)-[:ENCODES]->(p:Protein) RETURN count(DISTINCT g) as genes, count(*) as edges"),
                ("Protein→Pathway", "MATCH (p:Protein)-[:IN_PATHWAY]->(pw:Pathway) RETURN count(DISTINCT p) as proteins, count(*) as edges"),
                ("Pathway→Disease", "MATCH (pw:Pathway)-[:ASSOCIATED_WITH]->(d:Disease) RETURN count(DISTINCT pw) as pathways, count(*) as edges"),
            ]

            print("\n  Step-by-step check:")
            for label, query in checks:
                result = session.run(query)
                record = result.single()
                if record:
                    print(f"    {label}: {dict(record)}")


def main():
    """Main execution."""
    print("\n" + "=" * 80)
    print("GENE → PROTEIN EDGE CREATOR")
    print("Critical Link for Mechanistic Discovery")
    print("=" * 80)

    # Connect to Neo4j
    print(f"\nConnecting to Neo4j at {NEO4J_URI}...")
    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
    driver.verify_connectivity()
    print("✅ Connected\n")

    try:
        # Create edges
        total_edges = create_gene_protein_edges(driver)

        # Verify mechanistic path
        verify_mechanistic_path(driver)

        # Summary
        print("=" * 80)
        print("SUMMARY")
        print("=" * 80)
        print(f"Gene→Protein (ENCODES) edges created: {total_edges:,}")

        if total_edges > 10000:
            print("\n✅ SUCCESS! Should enable mechanistic discovery.")
            print("   Expected improvement: +10-15% test pass rate")
        elif total_edges > 1000:
            print("\n🟡 PARTIAL: Some edges created.")
            print("   May improve mechanistic discovery partially.")
        else:
            print("\n⚠️  WARNING: Very few edges created.")
            print("   Check that Gene and Protein nodes have matching identifiers.")

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
