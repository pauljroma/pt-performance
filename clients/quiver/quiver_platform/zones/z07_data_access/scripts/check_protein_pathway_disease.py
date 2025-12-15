#!/usr/bin/env python3
"""Check Protein→Pathway→Disease connectivity."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("=" * 80)
    print("PROTEIN→PATHWAY→DISEASE CONNECTIVITY CHECK")
    print("=" * 80)
    print()

    # Check 1: Protein→Pathway edges
    print("1. Protein→Pathway edges:")
    result = session.run("""
        MATCH (p:Protein)-[r]->(pw:Pathway)
        RETURN type(r) as rel_type, count(*) as count
    """)
    for rec in result:
        print(f"   {rec['rel_type']}: {rec['count']:,} edges")

    # Check 2: Pathway→Disease edges
    print("\n2. Pathway→Disease edges:")
    result = session.run("""
        MATCH (pw:Pathway)-[r]->(d:Disease)
        RETURN type(r) as rel_type, count(*) as count
    """)
    for rec in result:
        print(f"   {rec['rel_type']}: {rec['count']:,} edges")

    # Check 3: Full Drug→Protein→Pathway path
    print("\n3. Drug→Gene→Protein→Pathway paths:")
    result = session.run("""
        MATCH (d:Drug)-[:TARGETS]->(g:Gene)-[:ENCODES]->(p:Protein)-[]->(pw:Pathway)
        RETURN count(*) as count
    """)
    record = result.single()
    count = record['count']
    print(f"   Total: {count:,} paths")

    if count == 0:
        print("   ❌ BLOCKER: Proteins don't connect to Pathways!")

        # Debug: Check what edge types connect Proteins
        print("\n   Debugging: What DO Proteins connect to?")
        result = session.run("""
            MATCH (p:Protein)-[r]->(target)
            RETURN labels(target)[0] as target_type, type(r) as rel_type, count(*) as count
            ORDER BY count DESC
            LIMIT 10
        """)
        for rec in result:
            print(f"      Protein -[{rec['rel_type']}]-> {rec['target_type']}: {rec['count']:,}")

    # Check 4: Full Drug→Disease path
    print("\n4. Complete Drug→Gene→Protein→Pathway→Disease paths:")
    result = session.run("""
        MATCH (d:Drug)-[:TARGETS]->(g:Gene)-[:ENCODES]->(p:Protein)
              -[]->(pw:Pathway)-[]->(dis:Disease)
        RETURN count(*) as count
        """
    )
    record = result.single()
    count = record['count']
    print(f"   Total: {count:,} complete paths")

    if count == 0:
        print("   ❌ NO complete Drug→Disease paths via Protein→Pathway!")
    else:
        print(f"   ✅ Found {count:,} complete paths!")

driver.close()
