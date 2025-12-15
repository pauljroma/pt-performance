#!/usr/bin/env python3
"""Debug mechanistic path."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    # Check if ASPIRIN drug exists
    result = session.run("MATCH (d:Drug {name: 'ASPIRIN'}) RETURN d.name as name")
    record = result.single()
    print(f"1. ASPIRIN drug exists: {record['name'] if record else 'NOT FOUND'}")

    # Check if cardiovascular disease exists
    result = session.run("""
        MATCH (d:Disease)
        WHERE toLower(d.name) CONTAINS 'cardiovascular'
        RETURN d.name as name
        LIMIT 5
    """)
    print("\n2. Cardiovascular diseases:")
    for record in result:
        print(f"   - {record['name']}")

    # Check ASPIRIN targets
    result = session.run("""
        MATCH (d:Drug {name: 'ASPIRIN'})-[:TARGETS]->(g:Gene)
        RETURN g.symbol as gene
        LIMIT 5
    """)
    print("\n3. ASPIRIN targets (genes):")
    for record in result:
        print(f"   - {record['gene']}")

    # Check if those genes encode proteins
    result = session.run("""
        MATCH (d:Drug {name: 'ASPIRIN'})-[:TARGETS]->(g:Gene)-[:ENCODES]->(p:Protein)
        RETURN g.symbol as gene, p.name as protein
        LIMIT 5
    """)
    print("\n4. ASPIRIN → Gene → Protein:")
    for record in result:
        print(f"   - {record['gene']} → {record['protein']}")

    # Check if those proteins are in pathways
    result = session.run("""
        MATCH (d:Drug {name: 'ASPIRIN'})-[:TARGETS]->(g:Gene)-[:ENCODES]->(p:Protein)-[:IN_PATHWAY]->(pw:Pathway)
        RETURN g.symbol as gene, p.name as protein, pw.name as pathway
        LIMIT 5
    """)
    print("\n5. ASPIRIN → Gene → Protein → Pathway:")
    for record in result:
        print(f"   - {record['gene']} → {record['protein']} → {record['pathway']}")

    # Check if those pathways associate with diseases
    result = session.run("""
        MATCH (d:Drug {name: 'ASPIRIN'})-[:TARGETS]->(g:Gene)-[:ENCODES]->(p:Protein)
              -[:IN_PATHWAY]->(pw:Pathway)-[:ASSOCIATED_WITH]->(dis:Disease)
        RETURN g.symbol as gene, pw.name as pathway, dis.name as disease
        LIMIT 10
    """)
    print("\n6. Full ASPIRIN → Gene → Protein → Pathway → Disease:")
    count = 0
    for record in result:
        print(f"   - {record['gene']} → {record['pathway']} → {record['disease']}")
        count += 1
    print(f"\n   Total paths found: {count}")

driver.close()
