#!/usr/bin/env python3
"""Check what edges SCN1A has."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("SCN1A outgoing relationships:")
    print("=" * 80)

    result = session.run("""
        MATCH (g:Gene {symbol: "SCN1A"})-[r]->(target)
        RETURN type(r) as rel_type, labels(target)[0] as target_type,
               coalesce(target.name, target.symbol, 'unknown') as target_name,
               count(*) as count
        ORDER BY count DESC
        LIMIT 20
    """)

    for rec in result:
        print(f"  SCN1A -[{rec['rel_type']}]-> {rec['target_type']}:{rec['target_name']} (x{rec['count']})")

    # Specifically check for Disease relationships
    print("\n" + "=" * 80)
    print("SCN1A → Disease relationships:")
    result = session.run("""
        MATCH (g:Gene {symbol: "SCN1A"})-[r]->(d:Disease)
        RETURN type(r) as rel_type, d.name as disease_name
        LIMIT 10
    """)

    diseases = list(result)
    if diseases:
        for rec in diseases:
            print(f"  SCN1A -[{rec['rel_type']}]-> {rec['disease_name']}")
    else:
        print("  ❌ SCN1A has NO direct edges to Disease nodes!")

driver.close()
