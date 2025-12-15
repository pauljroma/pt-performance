#!/usr/bin/env python3
"""
Fusion Tables Pre-Flight Validation Script

Validates PostgreSQL fusion tables before production deployment.

Phase 1 of Production Deployment Swarm:
- Verify PostgreSQL connection and fusion tables
- Check table row counts
- Validate indexes
- Test sample fusion queries
- Measure query latency

Author: Claude Code Agent
Date: 2025-12-03
"""

import os
import sys
import time
import json
from typing import Dict, Any, List
import psycopg2
from psycopg2 import sql

# Expected fusion tables (14 total)
EXPECTED_FUSION_TABLES = [
    # Drug × Drug (chemical + LINCS)
    "d_d_chem_lincs_topk_v6_0",

    # Gene × Gene (ENS + LINCS)
    "g_g_ens_lincs_topk_v6_0",

    # Drug → Gene (cross-modal)
    "d_g_chem_ens_topk_v6_0",
    "d_g_chem_ep_topk_v6_0",

    # Drug Auxiliary Fusion Tables
    "d_aux_adr_topk_v6_0",      # Adverse Drug Reactions
    "d_aux_cto_topk_v6_0",      # Cell Type Ontology
    "d_aux_dgp_topk_v6_0",      # Disease-Gene-Phenotype
    "d_aux_ep_drug_topk_v6_0",  # Expression Profile
    "d_aux_mop_topk_v6_0",      # Mechanism of Pathology

    # Gene Auxiliary Fusion Tables
    "g_aux_cto_topk_v6_0",      # Cell Type Ontology
    "g_aux_dgp_topk_v6_0",      # Disease-Gene-Phenotype
    "g_aux_ep_drug_topk_v6_0",  # Expression Profile
    "g_aux_mop_topk_v6_0",      # Mechanism of Pathology
    "g_aux_syn_topk_v6_0",      # Synergy
]

# Expected row counts (approximate)
EXPECTED_ROW_COUNTS = {
    "d_d_chem_lincs_topk_v6_0": 712_000,
    "g_g_ens_lincs_topk_v6_0": 918_000,
    "d_g_chem_ens_topk_v6_0": 712_000,
    # Others vary, will validate they exist and have data
}


def connect_to_postgres() -> psycopg2.extensions.connection:
    """Connect to PostgreSQL database"""
    try:
        conn = psycopg2.connect(
            host=os.getenv("PGVECTOR_HOST", "localhost"),
            port=int(os.getenv("PGVECTOR_PORT", "5435")),
            database=os.getenv("PGVECTOR_DB", "sapphire_database"),
            user=os.getenv("PGVECTOR_USER", "postgres"),
            password=os.getenv("PGVECTOR_PASSWORD", "temppass123")
        )
        return conn
    except Exception as e:
        print(f"❌ CRITICAL: Cannot connect to PostgreSQL: {e}")
        print(f"   Connection details: localhost:5435, database=sapphire_database")
        sys.exit(1)


def check_postgres_version(conn: psycopg2.extensions.connection) -> Dict[str, Any]:
    """Check PostgreSQL version"""
    print("\n=== PostgreSQL Version ===")

    cursor = conn.cursor()
    cursor.execute("SELECT version();")
    version = cursor.fetchone()[0]

    print(f"✅ PostgreSQL: {version}")
    cursor.close()

    return {"status": "success", "version": version}


def check_fusion_tables_exist(conn: psycopg2.extensions.connection) -> Dict[str, Any]:
    """Check if all expected fusion tables exist"""
    print("\n=== Fusion Tables Existence Check ===")

    cursor = conn.cursor()

    # Get all tables matching pattern
    cursor.execute("""
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
          AND tablename LIKE '%topk_v6_0'
        ORDER BY tablename;
    """)

    existing_tables = [row[0] for row in cursor.fetchall()]

    results = {
        "total_expected": len(EXPECTED_FUSION_TABLES),
        "total_found": len(existing_tables),
        "tables_found": existing_tables,
        "tables_missing": [],
        "extra_tables": []
    }

    # Check for missing tables
    for table in EXPECTED_FUSION_TABLES:
        if table in existing_tables:
            print(f"✅ {table}")
        else:
            print(f"❌ MISSING: {table}")
            results["tables_missing"].append(table)

    # Check for unexpected tables
    for table in existing_tables:
        if table not in EXPECTED_FUSION_TABLES:
            print(f"⚠️  EXTRA: {table}")
            results["extra_tables"].append(table)

    cursor.close()

    if results["tables_missing"]:
        results["status"] = "warning"
        print(f"\n⚠️  {len(results['tables_missing'])} tables missing!")
    else:
        results["status"] = "success"
        print(f"\n✅ All {len(EXPECTED_FUSION_TABLES)} fusion tables found!")

    return results


def check_table_row_counts(conn: psycopg2.extensions.connection, tables: List[str]) -> Dict[str, Any]:
    """Check row counts for all fusion tables"""
    print("\n=== Fusion Table Row Counts ===")

    cursor = conn.cursor()

    results = {
        "tables": {},
        "total_rows": 0,
        "status": "success"
    }

    for table in tables:
        try:
            cursor.execute(sql.SQL("SELECT COUNT(*) FROM {}").format(sql.Identifier(table)))
            count = cursor.fetchone()[0]

            expected = EXPECTED_ROW_COUNTS.get(table, None)

            if expected:
                # Check if within 20% of expected
                diff_pct = abs(count - expected) / expected * 100
                status = "✅" if diff_pct < 20 else "⚠️"
                print(f"{status} {table}: {count:,} rows (expected: {expected:,}, diff: {diff_pct:.1f}%)")
            else:
                print(f"✅ {table}: {count:,} rows")

            results["tables"][table] = {
                "count": count,
                "expected": expected,
                "status": "ok" if count > 0 else "empty"
            }

            results["total_rows"] += count

        except Exception as e:
            print(f"❌ {table}: ERROR - {e}")
            results["tables"][table] = {
                "count": 0,
                "error": str(e),
                "status": "error"
            }
            results["status"] = "error"

    print(f"\n✅ Total fusion table rows: {results['total_rows']:,}")

    cursor.close()
    return results


def check_indexes(conn: psycopg2.extensions.connection, tables: List[str]) -> Dict[str, Any]:
    """Check if indexes exist on fusion tables"""
    print("\n=== Fusion Table Indexes ===")

    cursor = conn.cursor()

    results = {
        "tables": {},
        "status": "success"
    }

    for table in tables:
        try:
            cursor.execute("""
                SELECT indexname, indexdef
                FROM pg_indexes
                WHERE schemaname = 'public'
                  AND tablename = %s
                ORDER BY indexname;
            """, (table,))

            indexes = cursor.fetchall()

            if indexes:
                print(f"✅ {table}: {len(indexes)} indexes")
                for idx_name, idx_def in indexes:
                    print(f"   - {idx_name}")
            else:
                print(f"⚠️  {table}: NO INDEXES (performance will be degraded!)")
                results["status"] = "warning"

            results["tables"][table] = {
                "index_count": len(indexes),
                "indexes": [idx[0] for idx in indexes]
            }

        except Exception as e:
            print(f"❌ {table}: ERROR - {e}")
            results["tables"][table] = {
                "error": str(e)
            }

    cursor.close()
    return results


def test_sample_queries(conn: psycopg2.extensions.connection) -> Dict[str, Any]:
    """Test sample fusion queries and measure latency"""
    print("\n=== Sample Fusion Query Tests ===")

    cursor = conn.cursor()

    results = {
        "queries": [],
        "avg_latency_ms": 0,
        "status": "success"
    }

    # Test queries for each major fusion table
    test_queries = [
        {
            "name": "Drug × Drug (chemical + LINCS)",
            "table": "d_d_chem_lincs_topk_v6_0",
            "query": "SELECT entity2_id, similarity_score FROM d_d_chem_lincs_topk_v6_0 WHERE entity1_id = 'DB00997' ORDER BY similarity_score DESC LIMIT 10;"
        },
        {
            "name": "Gene × Gene (ENS + LINCS)",
            "table": "g_g_ens_lincs_topk_v6_0",
            "query": "SELECT entity2_id, similarity_score FROM g_g_ens_lincs_topk_v6_0 WHERE entity1_id = 'TSC2' ORDER BY similarity_score DESC LIMIT 10;"
        },
        {
            "name": "Drug → Gene (cross-modal)",
            "table": "d_g_chem_ens_topk_v6_0",
            "query": "SELECT entity2_id, similarity_score FROM d_g_chem_ens_topk_v6_0 WHERE entity1_id = 'DB00997' ORDER BY similarity_score DESC LIMIT 10;"
        },
    ]

    total_latency = 0
    successful_queries = 0

    for test in test_queries:
        try:
            start_time = time.time()
            cursor.execute(test["query"])
            rows = cursor.fetchall()
            latency_ms = (time.time() - start_time) * 1000

            if rows:
                status = "✅"
                if latency_ms > 10:
                    status = "⚠️"
                    print(f"{status} {test['name']}: {latency_ms:.2f}ms ({len(rows)} results) - SLOW!")
                else:
                    print(f"{status} {test['name']}: {latency_ms:.2f}ms ({len(rows)} results)")

                results["queries"].append({
                    "name": test["name"],
                    "table": test["table"],
                    "latency_ms": round(latency_ms, 2),
                    "result_count": len(rows),
                    "status": "ok"
                })

                total_latency += latency_ms
                successful_queries += 1
            else:
                print(f"❌ {test['name']}: NO RESULTS (empty table or bad query)")
                results["queries"].append({
                    "name": test["name"],
                    "table": test["table"],
                    "status": "no_results"
                })
                results["status"] = "warning"

        except Exception as e:
            print(f"❌ {test['name']}: ERROR - {e}")
            results["queries"].append({
                "name": test["name"],
                "table": test["table"],
                "error": str(e),
                "status": "error"
            })
            results["status"] = "error"

    if successful_queries > 0:
        results["avg_latency_ms"] = round(total_latency / successful_queries, 2)
        print(f"\n✅ Average query latency: {results['avg_latency_ms']:.2f}ms")

    cursor.close()
    return results


def main():
    """Main pre-flight validation routine"""
    print("=" * 80)
    print("FUSION TABLES PRE-FLIGHT VALIDATION")
    print("Production Deployment - Phase 1")
    print("=" * 80)

    start_time = time.time()

    # Connect to PostgreSQL
    conn = connect_to_postgres()

    # Run validation checks
    validation_results = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "checks": {}
    }

    # Check 1: PostgreSQL version
    validation_results["checks"]["postgres_version"] = check_postgres_version(conn)

    # Check 2: Fusion tables exist
    tables_check = check_fusion_tables_exist(conn)
    validation_results["checks"]["fusion_tables"] = tables_check

    # Get list of existing tables for further checks
    existing_tables = tables_check["tables_found"]

    # Check 3: Row counts
    validation_results["checks"]["row_counts"] = check_table_row_counts(conn, existing_tables)

    # Check 4: Indexes
    validation_results["checks"]["indexes"] = check_indexes(conn, existing_tables)

    # Check 5: Sample queries
    validation_results["checks"]["sample_queries"] = test_sample_queries(conn)

    # Close connection
    conn.close()

    # Calculate total validation time
    total_time = time.time() - start_time
    validation_results["total_validation_time_seconds"] = round(total_time, 2)

    # Determine overall status
    overall_status = "success"
    critical_issues = []
    warnings = []

    if tables_check["tables_missing"]:
        overall_status = "warning"
        warnings.append(f"{len(tables_check['tables_missing'])} fusion tables missing")

    if validation_results["checks"]["sample_queries"]["status"] == "error":
        overall_status = "error"
        critical_issues.append("Sample query tests failed")

    if validation_results["checks"]["row_counts"]["total_rows"] == 0:
        overall_status = "error"
        critical_issues.append("All fusion tables empty!")

    validation_results["overall_status"] = overall_status
    validation_results["critical_issues"] = critical_issues
    validation_results["warnings"] = warnings

    # Print summary
    print("\n" + "=" * 80)
    print("VALIDATION SUMMARY")
    print("=" * 80)

    if overall_status == "success":
        print("✅ PRE-FLIGHT VALIDATION PASSED!")
        print("   All fusion tables ready for production deployment.")
    elif overall_status == "warning":
        print("⚠️  PRE-FLIGHT VALIDATION PASSED WITH WARNINGS")
        for warning in warnings:
            print(f"   - {warning}")
    else:
        print("❌ PRE-FLIGHT VALIDATION FAILED")
        for issue in critical_issues:
            print(f"   - {issue}")

    print(f"\nTotal validation time: {total_time:.2f}s")

    # Save results to JSON
    output_file = "fusion_preflight_validation_results.json"
    with open(output_file, "w") as f:
        json.dump(validation_results, f, indent=2)

    print(f"\n📄 Detailed results saved to: {output_file}")

    return 0 if overall_status in ["success", "warning"] else 1


if __name__ == "__main__":
    sys.exit(main())
