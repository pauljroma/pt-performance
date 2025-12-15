#!/usr/bin/env python3
"""Test if the rescue prediction query is what's hanging."""

import os
from neo4j import GraphDatabase
import time

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

with driver.session() as session:
    print("=" * 80)
    print("TESTING RESCUE PREDICTION QUERY")
    print("=" * 80)
    print()

    drug_name = "Rapamycin"
    disease_name = "tuberous sclerosis"
    min_confidence = 0.0

    query = """
    MATCH (drug:Drug {name: $drug_name})-[r:PREDICTS_RESCUE_MODEX_16D|PREDICTS_RESCUE_EP]->(g:Gene)-[assoc:CAUSAL_FOR|ASSOCIATED_WITH]->(disease:Disease {name: $disease_name})
    WHERE r.rescue_score >= $min_confidence
    RETURN g.symbol as gene,
           r.rescue_score as rescue_score,
           type(r) as prediction_type
    ORDER BY r.rescue_score DESC
    LIMIT 10
    """

    print(f"Query: Drug={drug_name}, Disease={disease_name}")
    print()

    start = time.time()
    try:
        result = session.run(
            query,
            drug_name=drug_name,
            disease_name=disease_name,
            min_confidence=min_confidence
        )

        results = list(result)
        elapsed = time.time() - start

        print(f"✅ Query completed in {elapsed:.2f}s")
        print(f"   Found {len(results)} rescue predictions")

        for rec in results[:5]:
            print(f"   - {rec['gene']}: {rec['rescue_score']:.3f} ({rec['prediction_type']})")

    except Exception as e:
        elapsed = time.time() - start
        print(f"❌ Query failed after {elapsed:.2f}s")
        print(f"   Error: {e}")

driver.close()
