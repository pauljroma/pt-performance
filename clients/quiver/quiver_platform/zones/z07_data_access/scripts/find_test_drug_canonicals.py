#!/usr/bin/env python3
"""Find canonical names for test drugs."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

test_drugs = [
    "Fenfluramine",
    "FENFLURAMINE",
    "NORDEXFENFLURAMINE",
    "Aspirin",
    "ASPIRIN",
    "ACETYLSALICYLIC ACID"
]

with driver.session() as session:
    print("Finding canonical drug names with TARGETS edges:")
    print("=" * 80)

    for drug_pattern in test_drugs:
        result = session.run("""
            MATCH (d:Drug)-[:TARGETS]->(g:Gene)
            WHERE d.name =~ $pattern OR d.preferred_name =~ $pattern
            RETURN d.name as name, d.chembl_id as chembl, count(DISTINCT g) as targets
            ORDER BY targets DESC
            LIMIT 1
        """, pattern=f"(?i).*{drug_pattern}.*")

        rec = result.single()
        if rec:
            print(f"{drug_pattern:30} → {rec['name']:30} (ChEMBL: {rec['chembl']:15}) - {rec['targets']} targets")
        else:
            print(f"{drug_pattern:30} → NOT FOUND")

driver.close()
