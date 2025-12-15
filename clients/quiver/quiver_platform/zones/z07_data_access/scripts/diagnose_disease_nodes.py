#!/usr/bin/env python3
"""Diagnose Disease node schema and identify NULL names."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("=" * 80)
    print("DISEASE NODE SCHEMA ANALYSIS")
    print("=" * 80)
    print()

    # 1. Count total Disease nodes
    result = session.run("MATCH (d:Disease) RETURN count(d) as total")
    total = result.single()['total']
    print(f"Total Disease nodes: {total:,}")

    # 2. Count Disease nodes with NULL names
    result = session.run("MATCH (d:Disease) WHERE d.name IS NULL RETURN count(d) as null_count")
    null_count = result.single()['null_count']
    print(f"Disease nodes with NULL names: {null_count:,} ({null_count/total*100:.1f}%)")

    # 3. Show sample of Disease nodes with NULL names and their properties
    print("\n" + "=" * 80)
    print("SAMPLE DISEASE NODES WITH NULL NAMES")
    print("=" * 80)
    result = session.run("""
        MATCH (d:Disease)
        WHERE d.name IS NULL
        RETURN d
        LIMIT 5
    """)
    for rec in result:
        disease = rec['d']
        props = dict(disease.items())
        print(f"\nDisease node properties:")
        for key, val in props.items():
            print(f"  {key}: {val}")

    # 4. Check which diseases Rapamycin reaches
    print("\n" + "=" * 80)
    print("DISEASES REACHABLE FROM RAPAMYCIN")
    print("=" * 80)
    result = session.run("""
        MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
              -[:ENCODES]->(prot:Protein)
              -[:IN_PATHWAY]->(pw:Pathway)
              -[:ASSOCIATED_WITH]->(disease:Disease)
        RETURN DISTINCT disease.name as name,
               disease.disease_id as disease_id,
               disease.doid as doid,
               disease.mondo_id as mondo_id,
               disease.disease_name as disease_name,
               keys(disease) as all_properties
        LIMIT 10
    """)

    diseases = list(result)
    if diseases:
        print(f"\nFound {len(diseases)} diseases reachable from Rapamycin:")
        for i, rec in enumerate(diseases, 1):
            print(f"\n  Disease {i}:")
            print(f"    name: {rec['name']}")
            print(f"    disease_id: {rec['disease_id']}")
            print(f"    doid: {rec['doid']}")
            print(f"    mondo_id: {rec['mondo_id']}")
            print(f"    disease_name: {rec['disease_name']}")
            print(f"    All properties: {rec['all_properties']}")
    else:
        print("❌ No diseases found!")

    # 5. Check if "tuberous sclerosis" exists by any property
    print("\n" + "=" * 80)
    print("SEARCHING FOR 'TUBEROUS SCLEROSIS' IN DISEASE NODES")
    print("=" * 80)
    result = session.run("""
        MATCH (d:Disease)
        WHERE toLower(d.name) CONTAINS 'tuberous'
           OR toLower(d.disease_name) CONTAINS 'tuberous'
           OR toLower(d.mondo_id) CONTAINS 'tuberous'
        RETURN d.name as name,
               d.disease_name as disease_name,
               d.disease_id as disease_id,
               d.mondo_id as mondo_id,
               keys(d) as props
        LIMIT 10
    """)

    results = list(result)
    if results:
        print(f"\nFound {len(results)} Disease nodes mentioning 'tuberous':")
        for rec in results:
            print(f"\n  name: {rec['name']}")
            print(f"  disease_name: {rec['disease_name']}")
            print(f"  disease_id: {rec['disease_id']}")
            print(f"  mondo_id: {rec['mondo_id']}")
            print(f"  All properties: {rec['props']}")
    else:
        print("❌ No Disease nodes found with 'tuberous'!")

    # 6. Check all property names used in Disease nodes
    print("\n" + "=" * 80)
    print("ALL PROPERTY NAMES IN DISEASE NODES")
    print("=" * 80)
    result = session.run("""
        MATCH (d:Disease)
        UNWIND keys(d) as key
        RETURN DISTINCT key
        ORDER BY key
    """)
    props = [rec['key'] for rec in result]
    print(f"\nDisease nodes have these properties: {props}")

driver.close()
