#!/usr/bin/env python3
"""Test if Rapamycin→TSC path exists."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("=" * 80)
    print("RAPAMYCIN → TUBEROUS SCLEROSIS PATH CHECK")
    print("=" * 80)
    print()

    # Step 1: Find how Rapamycin is stored
    print("1. Finding Rapamycin in database:")
    result = session.run("""
        MATCH (d:Drug)
        WHERE d.name =~ '(?i).*rapamycin.*' OR d.preferred_name =~ '(?i).*rapamycin.*'
            OR d.synonyms =~ '(?i).*rapamycin.*'
        RETURN d.name as name, d.preferred_name as pref, d.chembl_id as chembl
        LIMIT 5
    """)
    drugs = list(result)
    if drugs:
        print(f"   Found {len(drugs)} Rapamycin matches:")
        for drug in drugs:
            print(f"      Name: {drug['name']}, Preferred: {drug['pref']}, ChEMBL: {drug['chembl']}")
    else:
        print("   ❌ Rapamycin NOT FOUND!")

    # Step 2: Find how Tuberous Sclerosis is stored
    print("\n2. Finding Tuberous Sclerosis in database:")
    result = session.run("""
        MATCH (d:Disease)
        WHERE d.name =~ '(?i).*tuberous.*' OR d.preferred_name =~ '(?i).*tuberous.*'
        RETURN d.name as name, d.preferred_name as pref
        LIMIT 5
    """)
    diseases = list(result)
    if diseases:
        print(f"   Found {len(diseases)} Tuberous Sclerosis matches:")
        for disease in diseases:
            print(f"      Name: {disease['name']}, Preferred: {disease['pref']}")
    else:
        print("   ❌ Tuberous Sclerosis NOT FOUND!")

    # Step 3: Try to find path
    if drugs and diseases:
        drug_name = drugs[0]['name']
        disease_name = diseases[0]['name']

        print(f"\n3. Searching for paths from '{drug_name}' to '{disease_name}':")
        result = session.run("""
            MATCH (drug:Drug)-[:TARGETS]->(g:Gene)-[:ENCODES]->(p:Protein)
                  -[:IN_PATHWAY]->(pw:Pathway)-[:ASSOCIATED_WITH]->(dis:Disease)
            WHERE drug.name = $drug_name
              AND dis.name = $disease_name
            RETURN g.symbol as gene, p.name as protein, pw.name as pathway
            LIMIT 5
        """, drug_name=drug_name, disease_name=disease_name)

        paths = list(result)
        if paths:
            print(f"   ✅ Found {len(paths)} paths!")
            for path in paths:
                print(f"      {drug_name} → {path['gene']} → {path['protein']} → {path['pathway']} → {disease_name}")
        else:
            print(f"   ❌ NO PATHS found from {drug_name} to {disease_name}")

            # Debug: Check what genes Rapamycin targets
            print(f"\n   Debugging: What genes does {drug_name} target?")
            result = session.run("""
                MATCH (drug:Drug)-[:TARGETS]->(g:Gene)
                WHERE drug.name = $drug_name
                RETURN g.symbol as gene
                LIMIT 10
            """, drug_name=drug_name)
            genes = list(result)
            if genes:
                print(f"      Targets {len(genes)} genes:")
                for gene in genes[:5]:
                    print(f"         - {gene['gene']}")

                # Check if those genes have ENCODES edges
                gene_symbols = [g['gene'] for g in genes[:5]]
                print(f"\n   Do these genes have ENCODES edges?")
                for symbol in gene_symbols:
                    result = session.run("""
                        MATCH (g:Gene)-[:ENCODES]->(p:Protein)
                        WHERE g.symbol = $symbol
                        RETURN count(*) as count
                    """, symbol=symbol)
                    rec = result.single()
                    print(f"      {symbol}: {rec['count']} ENCODES edges")
            else:
                print(f"      ❌ {drug_name} targets NO genes!")

driver.close()
