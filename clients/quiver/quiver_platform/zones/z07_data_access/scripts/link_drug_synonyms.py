#!/usr/bin/env python3
"""
Link Drug Synonyms - Copy TARGETS edges from canonical drugs to synonyms

Problem: "Rapamycin" exists as a Drug node but has no TARGETS edges.
         "SIROLIMUS" (CHEMBL413) is the canonical name with TARGETS edges.

Solution: Copy TARGETS edges from SIROLIMUS → Rapamycin for all synonyms.
"""

import os
from neo4j import GraphDatabase

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "rescue123")

# Known drug synonym mappings
DRUG_SYNONYMS = {
    "Rapamycin": "SIROLIMUS",
    "Fenfluramine": "FENFLURAMINE", # Check if needs different canonical name
    "Aspirin": "ASPIRIN"  # Check canonical name
}


def link_drug_targets(driver, synonym_name, canonical_name):
    """Copy TARGETS edges from canonical drug to synonym."""

    with driver.session() as session:
        # First check if synonym exists
        result = session.run("""
            MATCH (d:Drug {name: $synonym})
            RETURN d.name as name
        """, synonym=synonym_name)

        if not result.single():
            print(f"  ⚠️  Synonym '{synonym_name}' not found in database")
            return 0

        # Check if canonical exists and has TARGETS
        result = session.run("""
            MATCH (d:Drug {name: $canonical})-[:TARGETS]->(g:Gene)
            RETURN count(g) as target_count
        """, canonical=canonical_name)

        record = result.single()
        if not record or record['target_count'] == 0:
            print(f"  ⚠️  Canonical '{canonical_name}' has no TARGETS edges")
            return 0

        target_count = record['target_count']

        # Copy TARGETS edges
        query = """
        MATCH (canonical:Drug {name: $canonical})-[r:TARGETS]->(g:Gene)
        MATCH (synonym:Drug {name: $synonym})
        MERGE (synonym)-[r2:TARGETS]->(g)
        ON CREATE SET
            r2.source = 'copied_from_' + canonical.name,
            r2.created_at = datetime()
        RETURN count(r2) as edges_created
        """

        result = session.run(query, canonical=canonical_name, synonym=synonym_name)
        record = result.single()
        edges_created = record['edges_created'] if record else 0

        print(f"  ✅ Copied {edges_created} TARGETS edges from '{canonical_name}' to '{synonym_name}'")
        return edges_created


def main():
    """Link all drug synonyms."""

    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

    print("=" * 80)
    print("DRUG SYNONYM LINKING")
    print("=" * 80)
    print()

    total_edges = 0

    for synonym, canonical in DRUG_SYNONYMS.items():
        print(f"Processing: {synonym} ↔ {canonical}")
        edges = link_drug_targets(driver, synonym, canonical)
        total_edges += edges

    print()
    print("=" * 80)
    print(f"TOTAL: Copied {total_edges} TARGETS edges")
    print("=" * 80)

    driver.close()


if __name__ == "__main__":
    main()
