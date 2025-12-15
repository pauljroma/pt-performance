#!/usr/bin/env python3
"""
Debug Drug→Protein Connectivity Issues

Investigates why mechanistic_explainer fails to find Drug→Disease paths
despite having Gene→Protein, Protein→Pathway, Pathway→Disease edges.
"""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")


def debug_drug_paths():
    """Investigate drug connectivity step by step."""

    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

    # Test drugs from failing tests
    test_drugs = ["Rapamycin", "ASPIRIN", "Fenfluramine", "NORDEXFENFLURAMINE"]
    test_diseases = ["Tuberous Sclerosis", "tuberous sclerosis", "Dravet Syndrome", "Dravet syndrome"]

    print("=" * 80)
    print("DRUG CONNECTIVITY DEBUG")
    print("=" * 80)
    print()

    with driver.session() as session:

        # Step 1: Check if drug nodes exist
        print("STEP 1: Drug Node Existence")
        print("-" * 80)
        for drug in test_drugs:
            result = session.run(
                """
                MATCH (d:Drug)
                WHERE d.name = $drug OR d.preferred_name = $drug
                RETURN d.name as name, d.preferred_name as pref, labels(d) as labels,
                       keys(d) as properties
                LIMIT 1
                """,
                drug=drug
            )
            record = result.single()
            if record:
                print(f"  ✓ Found: {drug}")
                print(f"    Name: {record['name']}, Preferred: {record['pref']}")
                print(f"    Labels: {record['labels']}")
                print(f"    Properties: {record['properties'][:5]}...")
            else:
                print(f"  ✗ NOT FOUND: {drug}")
        print()

        # Step 2: Check Drug→Gene edges
        print("STEP 2: Drug→Gene Relationships")
        print("-" * 80)
        for drug in test_drugs:
            result = session.run(
                """
                MATCH (d:Drug)-[r]->(g:Gene)
                WHERE d.name = $drug OR d.preferred_name = $drug
                RETURN type(r) as rel_type, g.symbol as gene, count(*) as count
                LIMIT 5
                """,
                drug=drug
            )
            records = list(result.values())
            if records:
                print(f"  ✓ {drug} has {len(records)} gene relationships:")
                for rel_type, gene, count in records[:3]:
                    print(f"    {drug} -[{rel_type}]-> {gene}")
            else:
                print(f"  ✗ {drug} has NO gene relationships")
        print()

        # Step 3: Check Gene→Protein edges (we created these!)
        print("STEP 3: Gene→Protein ENCODES Edges (Sample)")
        print("-" * 80)
        result = session.run(
            """
            MATCH (g:Gene)-[e:ENCODES]->(p:Protein)
            RETURN g.symbol as gene, p.name as protein, count(*) as count
            LIMIT 5
            """
        )
        records = list(result.values())
        print(f"  Total Gene→Protein edges sampled: {len(records)}")
        for gene, protein, count in records[:3]:
            print(f"    {gene} -[ENCODES]-> {protein}")
        print()

        # Step 4: Check Protein→Pathway edges
        print("STEP 4: Protein→Pathway Edges (Sample)")
        print("-" * 80)
        result = session.run(
            """
            MATCH (p:Protein)-[r:PARTICIPATES_IN]->(pw:Pathway)
            RETURN p.name as protein, pw.name as pathway
            LIMIT 5
            """
        )
        records = list(result.values())
        print(f"  Total Protein→Pathway edges sampled: {len(records)}")
        for protein, pathway in records[:3]:
            print(f"    {protein} -[PARTICIPATES_IN]-> {pathway}")
        print()

        # Step 5: Check Pathway→Disease edges
        print("STEP 5: Pathway→Disease Edges (Sample)")
        print("-" * 80)
        result = session.run(
            """
            MATCH (pw:Pathway)-[r:ASSOCIATED_WITH]->(d:Disease)
            RETURN pw.name as pathway, d.name as disease
            LIMIT 5
            """
        )
        records = list(result.values())
        print(f"  Total Pathway→Disease edges sampled: {len(records)}")
        for pathway, disease in records[:3]:
            print(f"    {pathway} -[ASSOCIATED_WITH]-> {disease}")
        print()

        # Step 6: Try full path for Rapamycin → TSC
        print("STEP 6: Full Path Analysis - Rapamycin → Tuberous Sclerosis")
        print("-" * 80)
        result = session.run(
            """
            MATCH path = (drug:Drug)-[*1..5]->(disease:Disease)
            WHERE (drug.name = 'Rapamycin' OR drug.preferred_name = 'Rapamycin')
              AND (disease.name =~ '(?i).*tuberous.*' OR disease.preferred_name =~ '(?i).*tuberous.*')
            RETURN
                [node in nodes(path) | labels(node)[0] + ':' + coalesce(node.name, node.symbol, node.preferred_name, 'unknown')] as path_nodes,
                [rel in relationships(path) | type(rel)] as path_rels,
                length(path) as path_length
            LIMIT 3
            """
        )
        records = list(result.values())
        if records:
            print(f"  ✓ Found {len(records)} paths:")
            for path_nodes, path_rels, path_length in records:
                print(f"    Length {path_length}: {' → '.join(path_nodes)}")
                print(f"    Edges: {' → '.join(path_rels)}")
        else:
            print(f"  ✗ NO PATHS FOUND from Rapamycin to Tuberous Sclerosis")

            # Try to find what Rapamycin connects to
            print("\n  Debugging: What does Rapamycin connect to?")
            result = session.run(
                """
                MATCH (drug:Drug)-[r]->(target)
                WHERE drug.name = 'Rapamycin' OR drug.preferred_name = 'Rapamycin'
                RETURN type(r) as rel_type, labels(target)[0] as target_type,
                       coalesce(target.name, target.symbol, 'unknown') as target_name,
                       count(*) as count
                ORDER BY count DESC
                LIMIT 10
                """
            )
            records = list(result.values())
            for rel_type, target_type, target_name, count in records:
                print(f"    Rapamycin -[{rel_type}]-> {target_type}:{target_name} (x{count})")
        print()

        # Step 7: Check if Genes have both Drug and Protein connections
        print("STEP 7: Genes with BOTH Drug and Protein connections")
        print("-" * 80)
        result = session.run(
            """
            MATCH (d:Drug)-[:TARGETS]->(g:Gene)-[:ENCODES]->(p:Protein)
            RETURN g.symbol as gene,
                   count(DISTINCT d) as drug_count,
                   count(DISTINCT p) as protein_count
            LIMIT 10
            """
        )
        records = list(result.values())
        if records:
            print(f"  ✓ Found {len(records)} genes with both Drug and Protein connections:")
            for gene, drug_count, protein_count in records[:5]:
                print(f"    {gene}: {drug_count} drugs → gene → {protein_count} proteins")
        else:
            print(f"  ✗ NO GENES with both Drug→Gene and Gene→Protein edges")
            print("  → This is likely the disconnect!")
        print()

    driver.close()

    print("=" * 80)
    print("DIAGNOSIS COMPLETE")
    print("=" * 80)


if __name__ == "__main__":
    debug_drug_paths()
