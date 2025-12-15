#!/usr/bin/env python3
"""Check EFO ID mapping to find which EFO corresponds to tuberous sclerosis."""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("=" * 80)
    print("CHECKING EFO_0000174 (Disease reachable from Rapamycin)")
    print("=" * 80)

    # Look up EFO_0000174 in external resources
    # Common EFO IDs for tuberous sclerosis: EFO_0002926
    # Let's check what diseases reference this EFO

    result = session.run("""
        MATCH (d:Disease)
        WHERE d.efo_id = 'EFO_0000174'
           OR d.xrefs CONTAINS 'EFO:0000174'
        RETURN d.name as name,
               d.efo_id as efo_id,
               d.mondo_id as mondo_id,
               d.xrefs as xrefs,
               keys(d) as props
    """)

    print("\nDisease with EFO_0000174:")
    for rec in result:
        print(f"  name: {rec['name']}")
        print(f"  efo_id: {rec['efo_id']}")
        print(f"  mondo_id: {rec['mondo_id']}")
        print(f"  xrefs: {rec['xrefs']}")
        print(f"  props: {rec['props']}")

    # Check if tuberous sclerosis nodes have EFO cross-references
    print("\n" + "=" * 80)
    print("TUBEROUS SCLEROSIS DISEASE NODES - XREFS")
    print("=" * 80)

    result = session.run("""
        MATCH (d:Disease)
        WHERE toLower(d.name) CONTAINS 'tuberous'
        RETURN d.name as name,
               d.mondo_id as mondo_id,
               d.xrefs as xrefs
        ORDER BY d.name
    """)

    for rec in result:
        print(f"\n{rec['name']}")
        print(f"  MONDO: {rec['mondo_id']}")
        print(f"  XREFs: {rec['xrefs']}")

    # Strategy: Link EFO-only Disease nodes to proper Disease nodes via shared identifiers
    print("\n" + "=" * 80)
    print("SOLUTION STRATEGY")
    print("=" * 80)
    print("""
We have two sets of Disease nodes:
1. OpenTargets nodes: Only efo_id, no name (7 nodes)
2. Full nodes: name, mondo_id, xrefs (26,630 nodes)

The Pathway→Disease edges point to #1 but queries need #2.

Solution: Create SAME_AS edges between matching disease nodes,
then update queries to follow SAME_AS to find named diseases.

OR: Re-point Pathway→Disease edges from EFO nodes to named nodes.
    """)

driver.close()
