#!/usr/bin/env python3
"""Check if COX-1 (PTGS1) is in any pathways."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    # Check Gene nodes for COX-1/PTGS1
    result = session.run("""
        MATCH (g:Gene)
        WHERE toLower(g.symbol) IN ['cox1', 'ptgs1', 'cox-1', 'cyclooxygenase-1']
           OR toLower(g.name) CONTAINS 'cyclooxygenase'
        RETURN g.symbol as symbol, g.name as name, labels(g) as labels
        LIMIT 10
    """)
    print("Gene nodes for COX-1/PTGS1:")
    genes_found = list(result)
    for record in genes_found:
        print(f"  - {record['symbol']}: {record['name']}")

    if genes_found:
        # Check if those genes are in pathways
        result = session.run("""
            MATCH (g:Gene)-[r:PARTICIPATES_IN|INFERRED_PARTICIPATES_IN]->(pw:Pathway)
            WHERE toLower(g.symbol) IN ['cox1', 'ptgs1', 'cox-1', 'cyclooxygenase-1']
               OR toLower(g.name) CONTAINS 'cyclooxygenase'
            RETURN g.symbol as gene, type(r) as rel, pw.name as pathway
            LIMIT 10
        """)
        print("\nGene→Pathway edges for COX-1/PTGS1:")
        pathway_edges = list(result)
        for record in pathway_edges:
            print(f"  - {record['gene']} -{record['rel']}-> {record['pathway']}")

        if not pathway_edges:
            print("  ❌ COX-1/PTGS1 not found in any pathways!")
    else:
        print("  ❌ No COX-1/PTGS1 gene nodes found!")

    # Check Protein nodes
    result = session.run("""
        MATCH (p:Protein)
        WHERE toLower(p.symbol) IN ['cox1', 'ptgs1', 'cox-1']
           OR toLower(p.name) CONTAINS 'cyclooxygenase'
        RETURN p.symbol as symbol, p.name as name
        LIMIT 10
    """)
    print("\nProtein nodes for COX-1/PTGS1:")
    for record in result:
        print(f"  - {record['symbol']}: {record['name']}")

driver.close()
