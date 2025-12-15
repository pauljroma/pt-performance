"""
DrugNameResolver Performance Benchmark
Compares v2.1 (DataFrame) vs v2.1-FAST (dict) implementations

Expected results:
- v2.1: ~1-2 sec for 1000 drugs (cold cache)
- v2.1-FAST: ~200-400ms for 1000 drugs (cold cache)  → 3-5x faster
"""

import time
from typing import List

# Test drugs (mix of QS codes, BRD codes, drug names)
TEST_DRUGS = [
    "QS0318588", "QS0318589", "QS0318590",  # QS codes
    "BRD-K00765816", "BRD-K76908866", "BRD-K80348542",  # BRD codes
    "Caffeine", "Aspirin", "Ibuprofen",  # Drug names
    "CHEMBL113", "CHEMBL25", "CHEMBL521",  # CHEMBL IDs
] * 100  # 1200 lookups total

def benchmark_resolver(resolver_class, name: str, test_drugs: List[str]):
    """Benchmark a resolver implementation."""
    print(f"\n{'='*60}")
    print(f"Benchmarking: {name}")
    print(f"{'='*60}")

    # Initialize
    start_init = time.time()
    resolver = resolver_class(enable_neo4j_fallback=False)
    init_time = time.time() - start_init
    print(f"✅ Initialization: {init_time:.3f}s")

    # Warm up (1 call to initialize cache)
    _ = resolver.resolve(test_drugs[0])

    # Benchmark: cold cache (unique drugs)
    unique_drugs = list(set(test_drugs))
    start = time.time()
    for drug_id in unique_drugs:
        _ = resolver.resolve(drug_id)
    cold_time = time.time() - start
    cold_per_drug = (cold_time / len(unique_drugs)) * 1000  # ms
    print(f"✅ Cold cache ({len(unique_drugs)} unique drugs): {cold_time:.3f}s ({cold_per_drug:.2f}ms/drug)")

    # Benchmark: warm cache (repeated lookups)
    start = time.time()
    for drug_id in test_drugs:
        _ = resolver.resolve(drug_id)
    warm_time = time.time() - start
    warm_per_drug = (warm_time / len(test_drugs)) * 1000  # ms
    print(f"✅ Warm cache ({len(test_drugs)} total lookups): {warm_time:.3f}s ({warm_per_drug:.3f}ms/drug)")

    # Cache stats
    stats = resolver.get_stats()
    print(f"✅ Cache hit rate: {stats.get('cache_resolve_hit_rate', 0)*100:.1f}%")
    print(f"✅ Version: {stats.get('version', 'N/A')}")

    return {
        'name': name,
        'init_time': init_time,
        'cold_time': cold_time,
        'cold_per_drug_ms': cold_per_drug,
        'warm_time': warm_time,
        'warm_per_drug_ms': warm_per_drug,
        'cache_hit_rate': stats.get('cache_resolve_hit_rate', 0)
    }


def main():
    print("\n" + "="*60)
    print("DrugNameResolver Performance Benchmark")
    print("="*60)
    print(f"Test: {len(TEST_DRUGS)} total lookups ({len(set(TEST_DRUGS))} unique drugs)")

    # Import both versions
    from drug_name_resolver import DrugNameResolverV21
    from drug_name_resolver_fast import DrugNameResolverV21Fast

    # Benchmark v2.1 (DataFrame)
    results_v21 = benchmark_resolver(DrugNameResolverV21, "v2.1 (DataFrame)", TEST_DRUGS)

    # Benchmark v2.1-FAST (dict)
    results_fast = benchmark_resolver(DrugNameResolverV21Fast, "v2.1-FAST (dict)", TEST_DRUGS)

    # Compare results
    print(f"\n{'='*60}")
    print("PERFORMANCE COMPARISON")
    print(f"{'='*60}")

    speedup_cold = results_v21['cold_time'] / results_fast['cold_time']
    speedup_warm = results_v21['warm_time'] / results_fast['warm_time']

    print(f"\n🚀 COLD CACHE SPEEDUP: {speedup_cold:.2f}x")
    print(f"   v2.1:      {results_v21['cold_per_drug_ms']:.2f} ms/drug")
    print(f"   v2.1-FAST: {results_fast['cold_per_drug_ms']:.2f} ms/drug")

    print(f"\n🚀 WARM CACHE SPEEDUP: {speedup_warm:.2f}x")
    print(f"   v2.1:      {results_v21['warm_per_drug_ms']:.3f} ms/drug")
    print(f"   v2.1-FAST: {results_fast['warm_per_drug_ms']:.3f} ms/drug")

    print(f"\n{'='*60}")
    if speedup_cold >= 3.0:
        print("✅ SUCCESS: Achieved 3-5x speedup target!")
    elif speedup_cold >= 2.0:
        print("⚠️  PARTIAL: 2-3x speedup (good, but below 3-5x target)")
    else:
        print("❌ FAILED: Did not achieve 2x speedup")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
