#!/usr/bin/env python3
"""Test the specific directed path: Drug→Gene→Protein→Pathway→Disease."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("Testing DIRECTED path: Drug→Gene→Protein→Pathway→Disease")
    print("=" * 80)

    # Specific directed 4-hop query
    result = session.run("""
        MATCH (drug:Drug {name: 'Rapamycin'})
              -[:TARGETS]->(gene:Gene)
              -[:ENCODES]->(protein:Protein)
              -[:IN_PATHWAY]->(pathway:Pathway)
              -[:ASSOCIATED_WITH]->(disease:Disease {name: 'tuberous sclerosis'})
        RETURN gene.symbol as gene,
               protein.name as protein,
               pathway.name as pathway,
               count(*) as path_count
        LIMIT 10
    """)

    paths = list(result)
    if paths:
        print(f"✅ Found {len(paths)} directed paths!")
        for path in paths:
            print(f"  Rapamycin → {path['gene']} → {path['protein']} → {path['pathway']} → tuberous sclerosis")
    else:
        print("❌ NO directed paths found!")
        print("\nTrying without disease constraint...")

        # Try without disease
        result = session.run("""
            MATCH (drug:Drug {name: 'Rapamycin'})
                  -[:TARGETS]->(gene:Gene)
                  -[:ENCODES]->(protein:Protein)
                  -[:IN_PATHWAY]->(pathway:Pathway)
                  -[:ASSOCIATED_WITH]->(disease:Disease)
            WHERE toLower(disease.name) CONTAINS 'tuberous'
            RETURN gene.symbol as gene,
                   protein.name as protein,
                   pathway.name as pathway,
                   disease.name as disease_name,
                   count(*) as paths
            LIMIT 10
        """)

        paths = list(result)
        if paths:
            print(f"✅ Found {len(paths)} paths with fuzzy disease matching!")
            for path in paths:
                print(f"  Rapamycin → {path['gene']} → {path['protein']} → {path['pathway']} → {path['disease_name']}")
        else:
            print("❌ Still no paths. Checking each hop...")

            # Check hop by hop
            print("\n1. Rapamycin → Gene:")
            result = session.run("""
                MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
                RETURN gene.symbol as gene, count(*) as count
            """)
            genes = list(result)
            if genes:
                print(f"   ✅ {sum(g['count'] for g in genes)} TARGETS edges")
                print(f"   Genes: {[g['gene'] for g in genes[:5]]}")

                # Check if those genes have ENCODES edges
                print("\n2. Gene → Protein:")
                result = session.run("""
                    MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
                          -[:ENCODES]->(protein:Protein)
                    RETURN count(DISTINCT protein) as protein_count
                """)
                rec = result.single()
                print(f"   ✅ {rec['protein_count']} proteins reached via ENCODES")

                # Check if those proteins have IN_PATHWAY edges
                print("\n3. Protein → Pathway:")
                result = session.run("""
                    MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
                          -[:ENCODES]->(protein:Protein)
                          -[:IN_PATHWAY]->(pathway:Pathway)
                    RETURN count(DISTINCT pathway) as pathway_count
                """)
                rec = result.single()
                print(f"   ✅ {rec['pathway_count']} pathways reached via IN_PATHWAY")

                # Check if those pathways have ASSOCIATED_WITH to disease
                print("\n4. Pathway → Disease:")
                result = session.run("""
                    MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
                          -[:ENCODES]->(protein:Protein)
                          -[:IN_PATHWAY]->(pathway:Pathway)
                          -[:ASSOCIATED_WITH]->(disease:Disease)
                    RETURN count(DISTINCT disease) as disease_count
                """)
                rec = result.single()
                print(f"   ✅ {rec['disease_count']} diseases reached via full path")

                # List the diseases
                result = session.run("""
                    MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
                          -[:ENCODES]->(protein:Protein)
                          -[:IN_PATHWAY]->(pathway:Pathway)
                          -[:ASSOCIATED_WITH]->(disease:Disease)
                    RETURN DISTINCT disease.name as disease_name
                    LIMIT 20
                """)
                diseases = [rec['disease_name'] for rec in result]
                print(f"   Diseases reachable: {diseases[:10]}")
            else:
                print("   ❌ No TARGETS edges from Rapamycin!")

driver.close()
