#!/usr/bin/env python3
"""
Inspect existing pathway edges in Neo4j.

Checks what relationships pathways currently have.
"""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("Pathway properties sample:")
    result = session.run("MATCH (p:Pathway) RETURN p LIMIT 3")
    for record in result:
        pathway = record["p"]
        print(f"  {pathway}")
        print()

    print("\nRelationship types involving Pathways:")
    result = session.run("""
        MATCH (p:Pathway)-[r]-()
        RETURN type(r) as rel_type, count(*) as count
        ORDER BY count DESC
    """)
    for record in result:
        print(f"  {record['rel_type']}: {record['count']:,}")

    print("\nSample pathway relationships:")
    result = session.run("""
        MATCH (p:Pathway)-[r]-(other)
        RETURN p.name as pathway_name, type(r) as rel_type, labels(other)[0] as other_label, other.name as other_name
        LIMIT 10
    """)
    for record in result:
        print(f"  {record['pathway_name']} -{record['rel_type']}-> {record['other_label']}: {record['other_name']}")

driver.close()
