#!/usr/bin/env python3
"""Check if PTGS1 pathways link to cardiovascular disease."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    # Check if Arachidonic acid pathway is linked to any disease
    result = session.run("""
        MATCH (pw:Pathway)-[:ASSOCIATED_WITH|IMPLICATED_IN]->(d:Disease)
        WHERE toLower(pw.name) CONTAINS 'arachidonic'
           OR toLower(pw.name) CONTAINS 'prostaglandin'
           OR toLower(pw.name) CONTAINS 'cox'
        RETURN pw.name as pathway, d.name as disease
        LIMIT 20
    """)
    print("Arachidonic/Prostaglandin/COX pathways → Diseases:")
    count = 0
    for record in result:
        print(f"  - {record['pathway']} → {record['disease']}")
        count += 1

    if count == 0:
        print("  ❌ No disease associations found for these pathways!")

    # Check what the actual disease name is in Neo4j
    result = session.run("""
        MATCH (d:Disease)
        WHERE toLower(d.name) CONTAINS 'cardiovascular'
           OR toLower(d.name) CONTAINS 'atherosclerotic'
           OR toLower(d.name) CONTAINS 'heart'
        RETURN d.name as disease
        LIMIT 20
    """)
    print("\nCardiovascular/Atherosclerotic diseases in Neo4j:")
    for record in result:
        print(f"  - {record['disease']}")

    # Try the full ASPIRIN path with any cardiovascular disease
    result = session.run("""
        MATCH p=(drug:Drug {name: 'ASPIRIN'})-[:TARGETS]->(g:Gene {symbol: 'PTGS1'})
              -[:ENCODES]->(prot:Protein)
              -[:IN_PATHWAY]->(pw:Pathway)
              -[:ASSOCIATED_WITH|IMPLICATED_IN]->(d:Disease)
        WHERE toLower(d.name) CONTAINS 'cardiovascular'
           OR toLower(d.name) CONTAINS 'atherosclerotic'
        RETURN g.symbol as gene, pw.name as pathway, d.name as disease
        LIMIT 10
    """)
    print("\nFull ASPIRIN → PTGS1 → Protein → Pathway → Cardiovascular Disease:")
    paths = list(result)
    for record in paths:
        print(f"  - {record['gene']} → {record['pathway']} → {record['disease']}")

    if not paths:
        print("  ❌ No complete paths found to cardiovascular disease!")

driver.close()
