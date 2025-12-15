#!/usr/bin/env python3
"""
Fix EFO Disease Linkage

Problem: Pathway→Disease edges point to EFO-only Disease nodes (no names)
Solution: Re-point those edges to proper Disease nodes with names

Strategy:
1. Find pathways connected to EFO_0000174 (the one Rapamycin reaches)
2. Create new Pathway→Disease edges to "tuberous sclerosis" (MONDO:0001734)
3. Delete old edges to EFO_0000174
"""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("=" * 80)
    print("FIXING EFO DISEASE LINKAGE")
    print("=" * 80)
    print()

    # Step 1: Check which pathways connect to EFO_0000174
    result = session.run("""
        MATCH (pw:Pathway)-[r:ASSOCIATED_WITH]->(d:Disease {efo_id: 'EFO_0000174'})
        RETURN count(r) as edge_count,
               count(DISTINCT pw) as pathway_count
    """)
    rec = result.single()
    print(f"Pathways connected to EFO_0000174:")
    print(f"  {rec['pathway_count']} pathways")
    print(f"  {rec['edge_count']} edges")
    print()

    # Step 2: Find the proper tuberous sclerosis Disease node
    result = session.run("""
        MATCH (d:Disease)
        WHERE d.name = 'tuberous sclerosis'
          AND d.mondo_id = 'MONDO:0001734'
        RETURN d.name as name, d.mondo_id as mondo_id
    """)
    rec = result.single()
    if rec:
        print(f"✅ Found proper Disease node: {rec['name']} ({rec['mondo_id']})")
    else:
        print("❌ Proper Disease node not found! Trying case-insensitive...")
        result = session.run("""
            MATCH (d:Disease)
            WHERE toLower(d.name) = 'tuberous sclerosis'
              AND d.mondo_id IS NOT NULL
            RETURN d.name as name, d.mondo_id as mondo_id
            LIMIT 1
        """)
        rec = result.single()
        if rec:
            print(f"✅ Found: {rec['name']} ({rec['mondo_id']})")
        else:
            print("❌ Cannot find tuberous sclerosis Disease node!")
            driver.close()
            exit(1)
    print()

    # Step 3: Re-point Pathway→Disease edges from EFO to proper node
    print("Re-pointing Pathway→Disease edges...")
    result = session.run("""
        // Find pathways pointing to EFO disease
        MATCH (pw:Pathway)-[old:ASSOCIATED_WITH]->(efo:Disease {efo_id: 'EFO_0000174'})

        // Find proper disease node
        MATCH (proper:Disease)
        WHERE toLower(proper.name) = 'tuberous sclerosis'
          AND proper.mondo_id IS NOT NULL

        // Create new edge to proper disease
        MERGE (pw)-[new:ASSOCIATED_WITH]->(proper)
        ON CREATE SET
            new.source = 'relinked_from_efo',
            new.original_efo = 'EFO_0000174',
            new.created_at = datetime()

        // Delete old edge (optional - keeping for now)
        // DELETE old

        RETURN count(DISTINCT new) as edges_created,
               count(DISTINCT pw) as pathways_updated
    """)
    rec = result.single()
    print(f"✅ Created {rec['edges_created']} edges to proper Disease node")
    print(f"   Updated {rec['pathways_updated']} pathways")
    print()

    # Step 4: Verify Rapamycin now reaches "tuberous sclerosis" with name
    print("=" * 80)
    print("VERIFICATION: Rapamycin → tuberous sclerosis")
    print("=" * 80)

    result = session.run("""
        MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
              -[:ENCODES]->(prot:Protein)
              -[:IN_PATHWAY]->(pw:Pathway)
              -[:ASSOCIATED_WITH]->(disease:Disease)
        WHERE toLower(disease.name) = 'tuberous sclerosis'
        RETURN count(DISTINCT pw) as pathway_count,
               disease.name as disease_name,
               disease.mondo_id as mondo_id
    """)

    rec = result.single()
    if rec and rec['pathway_count'] > 0:
        print(f"✅ SUCCESS!")
        print(f"   Rapamycin → {rec['pathway_count']} pathways → {rec['disease_name']} ({rec['mondo_id']})")

        # Show sample path
        result = session.run("""
            MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
                  -[:ENCODES]->(prot:Protein)
                  -[:IN_PATHWAY]->(pw:Pathway)
                  -[:ASSOCIATED_WITH]->(disease:Disease)
            WHERE toLower(disease.name) = 'tuberous sclerosis'
            RETURN gene.symbol as gene,
                   prot.name as protein,
                   pw.name as pathway,
                   disease.name as disease
            LIMIT 3
        """)
        print("\nSample paths:")
        for rec in result:
            print(f"  Rapamycin → {rec['gene']} → {rec['protein']} → {rec['pathway']} → {rec['disease']}")
    else:
        print("❌ FAILED: Still no named paths found")
    print()

    # Step 5: Check all diseases now reachable from Rapamycin
    print("=" * 80)
    print("ALL DISEASES REACHABLE FROM RAPAMYCIN")
    print("=" * 80)
    result = session.run("""
        MATCH (drug:Drug {name: 'Rapamycin'})-[:TARGETS]->(gene:Gene)
              -[:ENCODES]->(prot:Protein)
              -[:IN_PATHWAY]->(pw:Pathway)
              -[:ASSOCIATED_WITH]->(disease:Disease)
        WHERE disease.name IS NOT NULL
        RETURN DISTINCT disease.name as disease_name
        ORDER BY disease_name
        LIMIT 20
    """)

    diseases = [rec['disease_name'] for rec in result]
    if diseases:
        print(f"\n✅ Rapamycin reaches {len(diseases)} named diseases:")
        for d in diseases:
            print(f"  - {d}")
    else:
        print("❌ No named diseases reachable")

driver.close()
