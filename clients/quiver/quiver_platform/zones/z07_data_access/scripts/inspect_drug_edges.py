#!/usr/bin/env python3
"""Inspect drug edges in Neo4j."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("Drug relationship types:")
    result = session.run("""
        MATCH (d:Drug)-[r]->(other)
        RETURN type(r) as rel_type, labels(other)[0] as target_label, count(*) as count
        ORDER BY count DESC
        LIMIT 10
    """)
    for record in result:
        print(f"  {record['rel_type']} → {record['target_label']}: {record['count']:,}")

    print("\nSample drug→protein edges:")
    result = session.run("""
        MATCH (d:Drug)-[r]->(p:Protein)
        RETURN d.name as drug, type(r) as rel_type, p.name as protein
        LIMIT 5
    """)
    for record in result:
        print(f"  {record['drug']} -{record['rel_type']}-> {record['protein']}")

driver.close()
