#!/usr/bin/env python3
"""
Add Neo4j Indexes for Query Performance

Creates indexes on frequently queried properties to speed up:
- Fuzzy matching queries (Drug.name, Gene.name, Disease.name)
- Exact ID lookups (Drug.chembl_id, Gene.symbol, Disease.mondo_id)
- Relationship queries (edge traversals)

Expected performance improvement: 10-100x faster queries

Usage:
    python add_neo4j_indexes.py
"""

import sys
import os
from pathlib import Path
from typing import List, Tuple

try:
    from neo4j import GraphDatabase
except ImportError:
    print("❌ Error: neo4j package not installed")
    print("Install with: pip install neo4j")
    sys.exit(1)


# Index definitions: (label, property, index_type)
INDEXES_TO_CREATE = [
    # Drug indexes
    ("Drug", "name", "text"),
    ("Drug", "chembl_id", "btree"),
    ("Drug", "drugbank_id", "btree"),

    # Gene indexes
    ("Gene", "name", "text"),
    ("Gene", "symbol", "btree"),
    ("Gene", "ensembl_id", "btree"),
    ("Gene", "ncbi_gene_id", "btree"),

    # Disease indexes
    ("Disease", "name", "text"),
    ("Disease", "mondo_id", "btree"),
    ("Disease", "doid", "btree"),

    # Protein indexes
    ("Protein", "name", "text"),
    ("Protein", "uniprot_id", "btree"),

    # Pathway indexes
    ("Pathway", "name", "text"),
    ("Pathway", "reactome_id", "btree"),
    ("Pathway", "kegg_id", "btree"),

    # Phenotype indexes
    ("Phenotype", "name", "text"),
    ("Phenotype", "hpo_id", "btree"),
]


def create_indexes(driver):
    """Create all indexes in Neo4j."""

    print("=" * 80)
    print("NEO4J INDEX CREATION")
    print("=" * 80)
    print()

    created = 0
    skipped = 0
    errors = 0

    with driver.session() as session:
        # First, list existing indexes
        print("📋 Checking existing indexes...")
        try:
            existing_indexes = session.run("SHOW INDEXES").data()
            print(f"Found {len(existing_indexes)} existing indexes")
            print()
        except Exception as e:
            print(f"⚠️  Could not list existing indexes: {e}")
            existing_indexes = []

        # Create each index
        for label, property_name, index_type in INDEXES_TO_CREATE:
            index_name = f"idx_{label.lower()}_{property_name.lower()}"

            print(f"Creating {index_name}...", end=" ")

            try:
                if index_type == "text":
                    # Text index for fuzzy matching (CONTAINS queries)
                    query = f"""
                    CREATE TEXT INDEX {index_name} IF NOT EXISTS
                    FOR (n:{label})
                    ON (n.{property_name})
                    """
                else:
                    # B-tree index for exact lookups
                    query = f"""
                    CREATE INDEX {index_name} IF NOT EXISTS
                    FOR (n:{label})
                    ON (n.{property_name})
                    """

                session.run(query)
                print("✅ CREATED")
                created += 1

            except Exception as e:
                if "already exists" in str(e).lower() or "equivalent" in str(e).lower():
                    print("⏭️  ALREADY EXISTS")
                    skipped += 1
                else:
                    print(f"❌ ERROR: {e}")
                    errors += 1

        print()
        print("=" * 80)
        print("SUMMARY")
        print("=" * 80)
        print(f"✅ Created:  {created}")
        print(f"⏭️  Skipped:  {skipped}")
        print(f"❌ Errors:   {errors}")
        print(f"📊 Total:    {created + skipped + errors}")
        print()

        # List final indexes
        print("=" * 80)
        print("FINAL INDEX LIST")
        print("=" * 80)
        try:
            final_indexes = session.run("SHOW INDEXES").data()
            for idx in final_indexes:
                name = idx.get("name", "N/A")
                labels = idx.get("labelsOrTypes", [])
                properties = idx.get("properties", [])
                idx_type = idx.get("type", "N/A")
                state = idx.get("state", "N/A")

                label_str = labels[0] if labels else "?"
                prop_str = properties[0] if properties else "?"

                status_icon = "✅" if state == "ONLINE" else "🔄" if state == "POPULATING" else "❌"
                print(f"{status_icon} {name}: {label_str}.{prop_str} ({idx_type})")
        except Exception as e:
            print(f"⚠️  Could not list final indexes: {e}")

        print()


def main():
    """Main execution."""
    print()
    print("🔧 Neo4j Index Creation Tool")
    print()

    # Get Neo4j connection details from environment
    neo4j_uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
    neo4j_user = os.getenv("NEO4J_USER", "neo4j")
    neo4j_password = os.getenv("NEO4J_PASSWORD", "rescue123")
    neo4j_database = os.getenv("NEO4J_DATABASE", "neo4j")

    print(f"Connecting to Neo4j at {neo4j_uri}...")
    print(f"Database: {neo4j_database}")
    print()

    # Connect to Neo4j
    try:
        driver = GraphDatabase.driver(neo4j_uri, auth=(neo4j_user, neo4j_password))
        driver.verify_connectivity()
        print("✅ Connected to Neo4j")
        print()
    except Exception as e:
        print(f"❌ Could not connect to Neo4j: {e}")
        print("Check connection settings in .env file")
        return 1

    try:
        # Create indexes
        create_indexes(driver)

        print("=" * 80)
        print("✅ INDEX CREATION COMPLETE")
        print("=" * 80)
        print()
        print("💡 Performance tips:")
        print("   - Text indexes enable fast CONTAINS queries")
        print("   - B-tree indexes enable fast exact matches")
        print("   - Indexes are used automatically by Neo4j query planner")
        print("   - Monitor index usage with: SHOW INDEXES")
        print()

        return 0

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1

    finally:
        driver.close()


if __name__ == "__main__":
    sys.exit(main())
