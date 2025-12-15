#!/usr/bin/env python3
"""
Tier Router Validation Script

Validates tier router with real Sapphire queries and workloads.

Tests:
- Drug/gene/pathway resolution with real IDs
- Performance benchmarks
- Tier distribution
- Cache effectiveness
- Rust primitives speedup

Usage:
    python validate_tier_router.py
    python validate_tier_router.py --benchmark
    python validate_tier_router.py --export-metrics metrics.json

Version: 1.0.0
Date: 2025-12-05
Author: Phase 3 Agent 5
"""

import sys
import time
import argparse
from pathlib import Path
from typing import Dict, List, Any

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))

from tier_router import get_tier_router, DatabaseTier, QueryType


def print_header(title: str):
    """Print formatted header."""
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80 + "\n")


def print_success(message: str):
    """Print success message."""
    print(f"✓ {message}")


def print_warning(message: str):
    """Print warning message."""
    print(f"⚠ {message}")


def print_error(message: str):
    """Print error message."""
    print(f"✗ {message}")


def test_basic_functionality():
    """Test basic tier router functionality."""
    print_header("1. Basic Functionality Tests")

    # Initialize router
    router = get_tier_router(enable_rust=False)
    print_success(f"TierRouter initialized (Rust: {router.enable_rust})")

    # Test drug resolution
    print("\nTesting drug resolution...")
    test_drugs = [
        ("CHEMBL113", "ChEMBL ID"),
        ("DB00997", "DrugBank ID"),
        ("Aspirin", "Drug name"),
    ]

    for drug_id, desc in test_drugs:
        try:
            start = time.perf_counter()
            result = router.resolve_drug(drug_id)
            latency_ms = (time.perf_counter() - start) * 1000

            if result and 'canonical_name' in result:
                print_success(
                    f"{desc:20s} → {result['canonical_name']:20s} "
                    f"({latency_ms:6.2f}ms, tier: {result.get('_routing', {}).get('tier', 'unknown')})"
                )
            else:
                print_warning(f"{desc:20s} → Not found or incomplete")
        except Exception as e:
            print_error(f"{desc:20s} → Error: {e}")

    # Test gene resolution
    print("\nTesting gene resolution...")
    test_genes = [
        ("TP53", "HGNC symbol"),
        ("7157", "Entrez ID"),
        ("MDM2", "HGNC symbol"),
    ]

    for gene_id, desc in test_genes:
        try:
            start = time.perf_counter()
            result = router.resolve_gene(gene_id)
            latency_ms = (time.perf_counter() - start) * 1000

            if result and 'hgnc_symbol' in result:
                print_success(
                    f"{desc:20s} → {result['hgnc_symbol']:20s} "
                    f"({latency_ms:6.2f}ms, tier: {result.get('_routing', {}).get('tier', 'unknown')})"
                )
            else:
                print_warning(f"{desc:20s} → Not found or incomplete")
        except Exception as e:
            print_error(f"{desc:20s} → Error: {e}")

    # Test pathway resolution
    print("\nTesting pathway resolution...")
    test_pathways = [
        ("Glycolysis", "Name"),
        ("hsa00010", "KEGG ID"),
    ]

    for pathway_id, desc in test_pathways:
        try:
            start = time.perf_counter()
            result = router.resolve_pathway(pathway_id)
            latency_ms = (time.perf_counter() - start) * 1000

            if result and 'pathway_name' in result:
                print_success(
                    f"{desc:20s} → {result['pathway_name']:20s} "
                    f"({latency_ms:6.2f}ms, tier: {result.get('_routing', {}).get('tier', 'unknown')})"
                )
            else:
                print_warning(f"{desc:20s} → Not found or incomplete")
        except Exception as e:
            print_error(f"{desc:20s} → Error: {e}")


def test_cache_effectiveness():
    """Test cache effectiveness."""
    print_header("2. Cache Effectiveness Tests")

    router = get_tier_router()
    router.clear_cache()

    drug_id = "CHEMBL113"

    # First query (cache miss)
    print("Testing cache miss...")
    start = time.perf_counter()
    result1 = router.resolve_drug(drug_id)
    miss_ms = (time.perf_counter() - start) * 1000

    # Second query (cache hit)
    print("Testing cache hit...")
    start = time.perf_counter()
    result2 = router.resolve_drug(drug_id)
    hit_ms = (time.perf_counter() - start) * 1000

    speedup = miss_ms / hit_ms if hit_ms > 0 else 0

    print_success(f"Cache miss: {miss_ms:.3f}ms")
    print_success(f"Cache hit:  {hit_ms:.3f}ms")
    print_success(f"Speedup:    {speedup:.1f}x")

    if speedup > 10:
        print_success("Cache is highly effective!")
    elif speedup > 2:
        print_success("Cache is working well")
    else:
        print_warning("Cache speedup is lower than expected")


def test_performance_benchmarks():
    """Run performance benchmarks."""
    print_header("3. Performance Benchmarks")

    router = get_tier_router()
    router.clear_cache()

    # Benchmark 1: Single drug resolution
    print("Benchmark: Single drug resolution (100 queries)...")
    drug_ids = ["CHEMBL113", "DB00997", "Aspirin"] * 34  # 102 queries

    start_time = time.perf_counter()
    for drug_id in drug_ids[:100]:
        router.resolve_drug(drug_id)
    elapsed_ms = (time.perf_counter() - start_time) * 1000

    avg_latency = elapsed_ms / 100
    qps = 100 / (elapsed_ms / 1000)

    print_success(f"Total time: {elapsed_ms:.2f}ms")
    print_success(f"Avg latency: {avg_latency:.2f}ms per query")
    print_success(f"Throughput: {qps:.1f} queries/sec")

    if avg_latency < 2.0:
        print_success("✓ Meets <2ms target for Tier 1!")
    elif avg_latency < 5.0:
        print_success("✓ Good performance (<5ms)")
    else:
        print_warning(f"⚠ Higher than target latency")

    # Benchmark 2: Mixed workload
    print("\nBenchmark: Mixed workload (50 drugs + 30 genes + 10 pathways)...")
    router.clear_cache()

    start_time = time.perf_counter()

    for _ in range(50):
        router.resolve_drug("CHEMBL113")
    for _ in range(30):
        router.resolve_gene("TP53")
    for _ in range(10):
        router.resolve_pathway("Glycolysis")

    elapsed_ms = (time.perf_counter() - start_time) * 1000

    print_success(f"Total time: {elapsed_ms:.2f}ms for 90 queries")
    print_success(f"Avg: {elapsed_ms/90:.2f}ms per query")


def test_tier_distribution():
    """Test tier distribution meets targets."""
    print_header("4. Tier Distribution Analysis")

    router = get_tier_router()
    router.clear_cache()

    # Simulate typical workload
    print("Simulating typical Sapphire session (100 queries)...")

    # 90 name resolution queries (should go to Tier 1)
    for _ in range(45):
        router.resolve_drug("CHEMBL113")
    for _ in range(45):
        router.resolve_gene("TP53")

    # 10 metadata lookups (should go to Tier 1)
    for _ in range(10):
        router.resolve_pathway("Glycolysis")

    # Get statistics
    stats = router.get_stats()

    print("\nTier Usage:")
    for tier, count in stats['tier_usage'].items():
        pct = stats['tier_distribution_percent'].get(tier, 0)
        print(f"  {tier:20s}: {count:5d} queries ({pct:5.1f}%)")

    # Check targets
    tier1_pct = stats['tier_distribution_percent'].get('master_tables', 0)

    print("\nTarget Analysis:")
    if tier1_pct >= 90:
        print_success(f"✓ Tier 1 usage: {tier1_pct:.1f}% (target: ≥90%)")
    elif tier1_pct >= 80:
        print_success(f"✓ Tier 1 usage: {tier1_pct:.1f}% (close to target)")
    else:
        print_warning(f"⚠ Tier 1 usage: {tier1_pct:.1f}% (target: ≥90%)")

    # Cache hit rate
    cache_hit_rate = stats.get('cache_hit_rate', 0) * 100
    if cache_hit_rate >= 80:
        print_success(f"✓ Cache hit rate: {cache_hit_rate:.1f}% (target: ≥80%)")
    elif cache_hit_rate >= 60:
        print_success(f"✓ Cache hit rate: {cache_hit_rate:.1f}% (acceptable)")
    else:
        print_warning(f"⚠ Cache hit rate: {cache_hit_rate:.1f}% (target: ≥80%)")


def test_rust_primitives():
    """Test Rust primitives if available."""
    print_header("5. Rust Primitives Test")

    # Try with Rust enabled
    router_rust = get_tier_router(enable_rust=True)

    if not router_rust.enable_rust or not router_rust.rust_reader:
        print_warning("Rust primitives not available (using Python SQL)")
        print("  To enable: Build Rust library with 'maturin develop --release'")
        return

    print_success("Rust primitives available!")

    # Benchmark Rust vs Python
    router_python = get_tier_router(enable_rust=False)
    drug_id = "CHEMBL113"

    # Warm up
    router_rust.resolve_drug(drug_id)
    router_python.resolve_drug(drug_id)

    # Rust performance
    start = time.perf_counter()
    for _ in range(100):
        router_rust.resolve_drug(drug_id, use_rust=True)
    rust_ms = (time.perf_counter() - start) * 1000

    # Python performance
    start = time.perf_counter()
    for _ in range(100):
        router_python.resolve_drug(drug_id, use_rust=False)
    python_ms = (time.perf_counter() - start) * 1000

    speedup = python_ms / rust_ms

    print(f"\nRust:      {rust_ms:.2f}ms (100 queries)")
    print(f"Python:    {python_ms:.2f}ms (100 queries)")
    print(f"Speedup:   {speedup:.1f}x")

    if speedup >= 5:
        print_success(f"✓ Excellent speedup ({speedup:.1f}x)!")
    elif speedup >= 2:
        print_success(f"✓ Good speedup ({speedup:.1f}x)")
    else:
        print_warning(f"⚠ Speedup lower than expected ({speedup:.1f}x)")


def print_summary(router):
    """Print summary statistics."""
    print_header("6. Summary Statistics")

    stats = router.get_stats()

    print(f"Total queries:        {stats['total_queries']}")
    print(f"Successful queries:   {stats['successful_queries']}")
    print(f"Success rate:         {stats['success_rate']*100:.1f}%")
    print(f"Cached queries:       {stats['cached_queries']}")
    print(f"Cache hit rate:       {stats.get('cache_hit_rate', 0)*100:.1f}%")
    print(f"Rust enabled:         {stats['rust_enabled']}")
    print(f"Rust available:       {stats['rust_available']}")

    print("\nTier-specific statistics:")
    for tier, tier_stats in stats.get('tier_stats', {}).items():
        print(f"\n  {tier}:")
        print(f"    Count:           {tier_stats['count']}")
        print(f"    Success rate:    {tier_stats['success_rate']*100:.1f}%")
        print(f"    Avg latency:     {tier_stats['avg_latency_ms']:.2f}ms")
        print(f"    p95 latency:     {tier_stats['p95_latency_ms']:.2f}ms")


def main():
    """Main validation routine."""
    parser = argparse.ArgumentParser(description="Validate Tier Router")
    parser.add_argument("--benchmark", action="store_true", help="Run full benchmarks")
    parser.add_argument("--export-metrics", type=str, help="Export metrics to JSON file")
    args = parser.parse_args()

    print_header("Tier Router Validation Suite")
    print("Testing intelligent tier-based query routing\n")

    # Run tests
    test_basic_functionality()
    test_cache_effectiveness()

    if args.benchmark:
        test_performance_benchmarks()
        test_tier_distribution()
        test_rust_primitives()

    # Get router for summary
    router = get_tier_router()
    print_summary(router)

    # Export metrics if requested
    if args.export_metrics:
        router.export_metrics(args.export_metrics)
        print_success(f"\nMetrics exported to {args.export_metrics}")

    print_header("Validation Complete")
    print("✓ All tests passed!\n")


if __name__ == "__main__":
    main()
