#!/usr/bin/env python3
"""Check what "Estrogen receptor alpha" is labeled as."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    result = session.run("""
        MATCH (n)
        WHERE n.name =~ '(?i).*estrogen receptor alpha.*' OR n.symbol = 'ESR1'
        RETURN labels(n) as labels, n.name as name, n.symbol as symbol
        LIMIT 5
    """)

    print("Nodes matching 'Estrogen receptor alpha' or ESR1:")
    for record in result:
        print(f"  Labels: {record['labels']}")
        print(f"  Name: {record['name']}")
        print(f"  Symbol: {record['symbol']}")
        print()

    # Check if Drug→TARGETS goes to Protein or Gene
    result = session.run("""
        MATCH (d:Drug {name: 'DANAZOL'})-[r:TARGETS]->(target)
        RETURN labels(target) as labels, target.name as name
        LIMIT 1
    """)

    record = result.single()
    if record:
        print(f"DANAZOL -TARGETS-> node:")
        print(f"  Labels: {record['labels']}")
        print(f"  Name: {record['name']}")

driver.close()
