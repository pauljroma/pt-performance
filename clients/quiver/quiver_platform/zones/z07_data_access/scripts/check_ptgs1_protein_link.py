#!/usr/bin/env python3
"""Check if PTGS1 gene is linked to proteins."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    # Check if PTGS1 gene encodes any protein
    result = session.run("""
        MATCH (g:Gene {symbol: 'PTGS1'})-[r:ENCODES]->(p:Protein)
        RETURN g.symbol as gene, type(r) as rel, p.symbol as protein_symbol, p.name as protein_name
    """)
    print("PTGS1 Gene → Protein (ENCODES) edges:")
    encodes_found = list(result)
    for record in encodes_found:
        print(f"  - {record['gene']} -ENCODES-> Protein(symbol={record['protein_symbol']}, name={record['protein_name']})")

    if not encodes_found:
        print("  ❌ PTGS1 gene not linked to any protein via ENCODES!")

        # Check if we can create the link manually
        print("\nLet's try to find matching proteins...")
        result = session.run("""
            MATCH (g:Gene {symbol: 'PTGS1'})
            MATCH (p:Protein)
            WHERE toLower(p.symbol) IN ['cox1', 'ptgs1']
               OR toLower(p.name) CONTAINS 'cyclooxygenase-1'
               OR toLower(p.name) CONTAINS 'ptgs1'
            RETURN g.symbol as gene, p.symbol as protein_symbol, p.name as protein_name,
                   g.uniprot_id as gene_uniprot, p.uniprot_id as protein_uniprot
            LIMIT 10
        """)
        print("\nPotential matches:")
        for record in result:
            print(f"  Gene: {record['gene']} (UniProt: {record['gene_uniprot']})")
            print(f"  Protein: {record['protein_symbol']} / {record['protein_name']} (UniProt: {record['protein_uniprot']})")
            print()
    else:
        # Check if that protein is in pathways
        result = session.run("""
            MATCH (g:Gene {symbol: 'PTGS1'})-[:ENCODES]->(p:Protein)-[:IN_PATHWAY]->(pw:Pathway)
            RETURN p.symbol as protein, pw.name as pathway
            LIMIT 10
        """)
        print("\nPTGS1 → Protein → Pathway:")
        pathways_found = list(result)
        for record in pathways_found:
            print(f"  - {record['protein']} → {record['pathway']}")

        if not pathways_found:
            print("  ❌ Proteins linked to PTGS1 are NOT in any pathways!")

driver.close()
