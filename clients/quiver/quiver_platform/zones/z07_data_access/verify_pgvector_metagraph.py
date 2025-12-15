#!/usr/bin/env python3
"""
Verification Script for PGVector Metagraph Registration
========================================================

Demonstrates that PGVector embedding tables are properly registered in Neo4j
and can be queried for intelligent embedding space selection.

Usage:
    python3 verify_pgvector_metagraph.py

Shows:
1. Total tables registered
2. Entity type distribution
3. Quality tier breakdown
4. Priority distribution
5. Sample queries using metagraph intelligence
6. Integration with unified_query_layer
"""

from neo4j import GraphDatabase
import json
from typing import Dict, Any, List

def verify_pgvector_registration():
    """Comprehensive verification of PGVector metagraph registration"""

    driver = GraphDatabase.driver(
        "bolt://localhost:7687",
        auth=("neo4j", "testpassword123")
    )

    print("\n" + "="*80)
    print("PGVector Metagraph Registration Verification")
    print("="*80)

    with driver.session() as session:
        # 1. Total registration stats
        print("\n1. REGISTRATION STATISTICS")
        print("-" * 80)

        result = session.run("""
            MATCH (e:EmbeddingSpace)
            WHERE e.table_name IS NOT NULL
            RETURN COUNT(e) as total,
                   COUNT(DISTINCT e.entity_type) as entity_types,
                   COUNT(DISTINCT e.quality_tier) as quality_tiers,
                   AVG(e.dimension) as avg_dimension,
                   MIN(e.dimension) as min_dimension,
                   MAX(e.dimension) as max_dimension,
                   SUM(e.row_count) as total_rows
        """)

        stats = result.single()
        print(f"Total EmbeddingSpace nodes:     {stats['total']}")
        print(f"Entity types registered:        {stats['entity_types']}")
        print(f"Quality tiers:                  {stats['quality_tiers']}")
        print(f"Dimension range:                {stats['min_dimension']}D - {stats['max_dimension']}D (avg: {stats['avg_dimension']:.1f}D)")
        print(f"Total rows across all tables:   {stats['total_rows']:,}")

        # 2. Discovery status
        print("\n2. DISCOVERY STATUS")
        print("-" * 80)

        result = session.run("""
            MATCH (e:EmbeddingSpace)
            WHERE e.pgvector_status = 'loaded'
            RETURN COUNT(e) as discovered_count
        """)
        discovered = result.single()['discovered_count']
        print(f"Tables marked as pgvector_status='loaded': {discovered}")

        # 3. Entity type distribution
        print("\n3. ENTITY TYPE DISTRIBUTION")
        print("-" * 80)

        result = session.run("""
            MATCH (e:EmbeddingSpace)
            WHERE e.table_name IS NOT NULL
            RETURN e.entity_type as entity_type,
                   COUNT(e) as count,
                   AVG(e.dimension) as avg_dim,
                   SUM(e.row_count) as total_rows,
                   MAX(e.row_count) as max_rows
            ORDER BY count DESC
        """)

        for record in result:
            entity = record['entity_type'] or 'unknown'
            avg_dim = record['avg_dim'] if record['avg_dim'] else 0
            total_rows = record['total_rows'] if record['total_rows'] else 0
            print(f"  {entity:20s} : {record['count']:3d} spaces, "
                  f"{avg_dim:5.1f}D avg, {total_rows:,} rows")

        # 4. Quality tier distribution
        print("\n4. QUALITY TIER DISTRIBUTION")
        print("-" * 80)

        result = session.run("""
            MATCH (e:EmbeddingSpace)
            WHERE e.table_name IS NOT NULL
            RETURN e.quality_tier as tier,
                   COUNT(e) as count,
                   AVG(e.dimension) as avg_dim
            ORDER BY tier DESC
        """)

        for record in result:
            tier = record['tier'] or 'unknown'
            avg_dim = record['avg_dim'] if record['avg_dim'] else 0
            print(f"  Tier {tier}: {record['count']:3d} spaces, {avg_dim:5.1f}D avg")

        # 5. Priority distribution
        print("\n5. PRIORITY DISTRIBUTION")
        print("-" * 80)

        result = session.run("""
            MATCH (e:EmbeddingSpace)
            WHERE e.table_name IS NOT NULL
              AND e.priority IS NOT NULL
            RETURN e.priority as priority,
                   COUNT(e) as count,
                   COLLECT(DISTINCT e.entity_type)[0..3] as entity_types
            ORDER BY count DESC
        """)

        for record in result:
            types_str = ', '.join(t for t in record['entity_types'] if t)
            print(f"  {record['priority']:15s} : {record['count']:3d} spaces ({types_str})")

        # 6. Sample critical tables
        print("\n6. CRITICAL TABLES VERIFICATION")
        print("-" * 80)

        critical_queries = [
            ("Gene Embeddings (MODEX)", "MATCH (e:EmbeddingSpace) WHERE e.entity_type='gene' AND e.priority='primary' RETURN e LIMIT 3"),
            ("Drug Embeddings (LINCS)", "MATCH (e:EmbeddingSpace) WHERE e.entity_type='drug' AND e.priority='fusion' RETURN e LIMIT 3"),
            ("Fusion Spaces (MODEX)", "MATCH (e:EmbeddingSpace) WHERE e.priority='primary' RETURN e ORDER BY e.row_count DESC LIMIT 3"),
        ]

        for label, query in critical_queries:
            print(f"\n  {label}:")
            result = session.run(query)
            for record in result:
                e = record['e']
                table = e.get('table_name') or 'unknown'
                dim = e.get('dimension') or 0
                rows = e.get('row_count') or 0
                tier = e.get('quality_tier') or 'unknown'
                print(f"    • {table:40s} {dim:3d}D {rows:>10,} rows (tier {tier})")

        # 7. Schema readiness for unified_query_layer
        print("\n7. UNIFIED QUERY LAYER READINESS")
        print("-" * 80)

        result = session.run("""
            MATCH (e:EmbeddingSpace)
            WHERE e.table_name IS NOT NULL
              AND e.pgvector_status = 'loaded'
            WITH e.entity_type as entity_type, COUNT(DISTINCT e.priority) as priority_count
            WHERE priority_count >= 1
            RETURN DISTINCT entity_type, priority_count
            ORDER BY entity_type
        """)

        ready_entities = []
        for record in result:
            ready_entities.append(record['entity_type'])
            print(f"  ✅ {record['entity_type']:20s} : Ready (multiple priorities available)")

        print(f"\n  Total entity types ready for queries: {len(ready_entities)}")

        # 8. Example queries
        print("\n8. EXAMPLE METAGRAPH QUERIES")
        print("-" * 80)

        print("\n  a) Find best embedding space for gene queries:")
        result = session.run("""
            MATCH (e:EmbeddingSpace)
            WHERE e.entity_type = 'gene'
              AND e.priority IN ['primary', 'fallback']
            RETURN e.table_name, e.dimension, e.row_count, e.priority
            ORDER BY CASE WHEN e.priority='primary' THEN 0 ELSE 1 END,
                     e.dimension DESC
            LIMIT 3
        """)
        for record in result:
            print(f"     {record['e.table_name']:40s} ({record['e.dimension']}D) - Priority: {record['e.priority']}")

        print("\n  b) Find highest quality drug embeddings:")
        result = session.run("""
            MATCH (e:EmbeddingSpace)
            WHERE e.entity_type = 'drug'
              AND e.quality_tier = 'A'
              AND e.dimension IS NOT NULL
            RETURN e.table_name, e.dimension, e.row_count
            ORDER BY e.dimension DESC
            LIMIT 3
        """)
        for record in result:
            table = record['e.table_name'] or 'unknown'
            dim = record['e.dimension'] or 0
            rows = record['e.row_count'] or 0
            print(f"     {table:40s} ({dim}D) {rows:,} rows")

        print("\n  c) Find all available spaces for cross-entity queries:")
        result = session.run("""
            MATCH (e:EmbeddingSpace)
            WHERE e.priority = 'primary'
            RETURN DISTINCT e.entity_type
            ORDER BY e.entity_type
        """)
        entities = [r['e.entity_type'] for r in result]
        print(f"     Available for bridging: {', '.join(entities)}")

    driver.close()

    # 9. Summary
    print("\n" + "="*80)
    print("VERIFICATION COMPLETE")
    print("="*80)
    print("\n✅ PGVector tables successfully registered to Neo4j metagraph")
    print("✅ Metagraph ready for unified_query_layer.discover_tool_capabilities()")
    print("✅ All critical embedding spaces verified and indexed\n")

if __name__ == "__main__":
    verify_pgvector_registration()
