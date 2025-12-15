#!/usr/bin/env python3
"""Test if LIMIT 20 vs LIMIT 5 makes a difference."""

import os
from neo4j import GraphDatabase
import time

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

drug_name = "Rapamycin"
disease_name = "tuberous sclerosis"
max_depth = 4

query_template = """
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
WITH p, length(p) as path_length
ORDER BY path_length ASC
LIMIT {limit}
RETURN p, path_length
"""

with driver.session() as session:
    for limit in [5, 20]:
        print(f"\n{'='*80}")
        print(f"Testing with LIMIT {limit}")
        print('='*80)

        query = query_template.format(max_depth=max_depth, limit=limit)

        start = time.time()
        result = session.run(query, drug_name=drug_name, disease_name=disease_name)
        paths = list(result)
        elapsed = time.time() - start

        print(f"⏱️  Query completed in {elapsed:.2f}s")
        print(f"   Found {len(paths)} paths")

driver.close()
