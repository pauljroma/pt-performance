#!/usr/bin/env python3
"""Test the exact query mechanistic_explainer uses."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

# Use exact normalized names from tool
drug_name = "Rapamycin"
disease_name = "tuberous sclerosis"
max_depth = 4

with driver.session() as session:
    print(f"Testing mechanistic_explainer query:")
    print(f"  Drug: {drug_name}")
    print(f"  Disease: {disease_name}")
    print(f"  Max depth: {max_depth}")
    print("=" * 80)

    # Exact query from mechanistic_explainer.py line 521
    query = f"""
    MATCH p = (drug:Drug {{name: $drug_name}})-[*1..{max_depth}]-(disease:Disease {{name: $disease_name}})
    WHERE ALL(r IN relationships(p) WHERE
        type(r) IN [
            'INHIBITS', 'ACTIVATES', 'BINDS_TO', 'MODULATES', 'TARGETS',
            'PART_OF_PATHWAY', 'REGULATES_PATHWAY', 'DYSREGULATED_IN',
            'ASSOCIATED_WITH', 'CAUSAL_FOR', 'TREATS', 'INDICATED_FOR',
            'INTERACTS_WITH', 'PHOSPHORYLATES', 'BINDS_TO',
            'UPREGULATED_IN', 'DOWNREGULATED_IN',
            'ENCODES', 'IN_PATHWAY', 'PARTICIPATES_IN', 'IMPLICATED_IN'
        ]
    )
    RETURN p,
           length(p) as path_length,
           [node in nodes(p) | labels(node)[0] + ':' + coalesce(node.name, node.symbol, 'unknown')] as path_nodes
    LIMIT 5
    """

    result = session.run(query, drug_name=drug_name, disease_name=disease_name)
    paths = list(result)

    if paths:
        print(f"✅ Found {len(paths)} paths!")
        for i, rec in enumerate(paths, 1):
            print(f"\n  Path {i} (length {rec['path_length']}):")
            print(f"    {' → '.join(rec['path_nodes'])}")
    else:
        print("❌ NO PATHS FOUND!")
        print("\nDebugging:")

        # Check if nodes exist with exact names
        result = session.run("""
            MATCH (d:Drug {name: $drug})
            RETURN count(d) as count
        """, drug=drug_name)
        drug_count = result.single()['count']
        print(f"  Drug '{drug_name}' exists: {drug_count > 0} ({drug_count} nodes)")

        result = session.run("""
            MATCH (d:Disease {name: $disease})
            RETURN count(d) as count
        """, disease=disease_name)
        disease_count = result.single()['count']
        print(f"  Disease '{disease_name}' exists: {disease_count > 0} ({disease_count} nodes)")

        if drug_count == 0:
            # Check what the actual drug name is
            result = session.run("""
                MATCH (d:Drug)
                WHERE toLower(d.name) CONTAINS toLower($pattern)
                RETURN d.name as name
                LIMIT 5
            """, pattern="rapamycin")
            print(f"\n  Similar drug names:")
            for rec in result:
                print(f"    - {rec['name']}")

        if disease_count == 0:
            # Check what the actual disease name is
            result = session.run("""
                MATCH (d:Disease)
                WHERE toLower(d.name) CONTAINS toLower($pattern)
                RETURN d.name as name
                LIMIT 5
            """, pattern="tuberous")
            print(f"\n  Similar disease names:")
            for rec in result:
                print(f"    - {rec['name']}")

driver.close()
