#!/usr/bin/env python3
"""Check what Rapamycin connects to."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("What does 'Rapamycin' connect to?")
    print("=" * 80)

    result = session.run("""
        MATCH (drug:Drug {name: 'Rapamycin'})-[r]->(target)
        RETURN type(r) as rel_type, labels(target)[0] as target_type,
               coalesce(target.name, target.symbol, target.preferred_name, 'unknown') as target_name
        LIMIT 20
    """)

    edges = list(result)
    if edges:
        print(f"Found {len(edges)} outgoing edges:")
        for edge in edges:
            print(f"  Rapamycin -[{edge['rel_type']}]-> {edge['target_type']}:{edge['target_name']}")
    else:
        print("❌ Rapamycin has NO outgoing edges!")

    # Check if there's a different Rapamycin/Sirolimus node with TARGETS edges
    print("\n" + "=" * 80)
    print("Checking for Sirolimus (Rapamycin's generic name)...")
    result = session.run("""
        MATCH (drug:Drug)-[:TARGETS]->(g:Gene)
        WHERE drug.name =~ '(?i).*(rapamycin|sirolimus).*'
           OR drug.synonyms =~ '(?i).*(rapamycin|sirolimus).*'
        RETURN drug.name as drug_name, drug.chembl_id as chembl, count(g) as gene_count
        LIMIT 10
    """)

    drugs = list(result)
    if drugs:
        print(f"Found {len(drugs)} Rapamycin/Sirolimus drugs with TARGETS edges:")
        for drug in drugs:
            print(f"  {drug['drug_name']} (ChEMBL: {drug['chembl']}): targets {drug['gene_count']} genes")
    else:
        print("❌ No Rapamycin/Sirolimus drugs have TARGETS edges!")

driver.close()
