#!/usr/bin/env python3
"""
Fix Protein→Pathway Links

Problem: Proteins from Gene-[:ENCODES]->Protein don't have IN_PATHWAY edges
Root cause: Property mismatch when creating IN_PATHWAY edges

Solution: Re-create IN_PATHWAY edges using the ACTUAL Protein nodes from ENCODES
"""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("=" * 80)
    print("FIXING PROTEIN→PATHWAY EDGES")
    print("=" * 80)
    print()

    # Strategy: For each Gene→Protein→Pathway path via Gene,
    # create Protein→Pathway edge using the ACTUAL Protein node from ENCODES

    query = """
    // Find Gene→Protein ENCODES edges and Gene→Pathway edges
    // Then link Protein→Pathway directly
    MATCH (gene:Gene)-[:ENCODES]->(prot:Protein)
    MATCH (gene)-[:PARTICIPATES_IN|INFERRED_PARTICIPATES_IN]->(pw:Pathway)

    MERGE (prot)-[r:IN_PATHWAY]->(pw)
    ON CREATE SET
        r.via_gene = gene.symbol,
        r.source = 'inferred_from_gene_encodes',
        r.created_at = datetime()

    RETURN count(DISTINCT r) as edges_created
    """

    print("Creating Protein→Pathway edges via Gene ENCODES...")
    print("Query: Gene-[:ENCODES]->Protein, Gene-[:PARTICIPATES_IN]->Pathway")
    print("       => Protein-[:IN_PATHWAY]->Pathway")
    print()

    result = session.run(query)
    record = result.single()
    count = record['edges_created'] if record else 0

    print(f"✅ Created {count:,} Protein→Pathway IN_PATHWAY edges")
    print()

    # Verify: Check if Rapamycin's proteins now have pathways
    print("=" * 80)
    print("VERIFICATION: Rapamycin → Proteins → Pathways")
    print("=" * 80)

    result = session.run("""
        MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
              -[:ENCODES]->(prot:Protein)
              -[:IN_PATHWAY]->(pw:Pathway)
        RETURN count(DISTINCT pw) as pathway_count
    """)
    rec = result.single()
    pathway_count = rec['pathway_count']

    if pathway_count > 0:
        print(f"✅ SUCCESS! Rapamycin reaches {pathway_count} pathways via targets")

        # Show sample paths
        result = session.run("""
            MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
                  -[:ENCODES]->(prot:Protein)
                  -[:IN_PATHWAY]->(pw:Pathway)
            RETURN gene.symbol as gene, prot.name as protein, pw.name as pathway
            LIMIT 5
        """)
        print("\nSample paths:")
        for rec in result:
            print(f"  Rapamycin → {rec['gene']} → {rec['protein']} → {rec['pathway']}")
    else:
        print("❌ FAILED: Rapamycin still doesn't reach pathways")

driver.close()
