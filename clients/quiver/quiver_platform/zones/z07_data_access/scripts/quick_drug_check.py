#!/usr/bin/env python3
"""Quick drug connectivity check."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    # Quick check: Do Drug→Gene→Protein paths exist?
    print("Checking Drug→Gene→Protein connectivity...")
    result = session.run("""
        MATCH (d:Drug)-[:TARGETS]->(g:Gene)-[:ENCODES]->(p:Protein)
        RETURN count(*) as path_count
    """)
    record = result.single()
    print(f"  Drug→Gene→Protein paths: {record['path_count']:,}")

    # Sample some
    if record['path_count'] > 0:
        result = session.run("""
            MATCH (d:Drug)-[:TARGETS]->(g:Gene)-[:ENCODES]->(p:Protein)
            RETURN d.name as drug, g.symbol as gene, p.name as protein
            LIMIT 5
        """)
        print("\n  Sample paths:")
        for rec in result:
            print(f"    {rec['drug']} → {rec['gene']} → {rec['protein']}")
    else:
        print("  ❌ NO Drug→Gene→Protein paths found!")
        print("  This is the main blocker for mechanistic_explainer")

driver.close()
