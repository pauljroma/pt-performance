#!/usr/bin/env python3
"""
Wave 1 Performance Benchmarks - Rust Primitives & Tier Router
==============================================================

Validates performance targets for Phase 3 Wave 1 deployment:
- Agent 1 (Rust Primitives): <0.1ms lookups, 10x speedup vs Python
- Agent 2 (Tier Router): <1ms overhead, 30%+ routing to optimal tiers

Benchmark Categories:
1. Rust Primitives (6 benchmarks)
   - Single drug lookup (Rust)
   - Single drug lookup (Python baseline)
   - Cached lookup comparison
   - Bulk lookup (100 drugs)
   - Concurrent queries (10 threads)
   - Fallback performance

2. Tier Router (5 benchmarks)
   - Routing overhead (single query)
   - Average overhead (1,000 queries)
   - Routing percentage validation
   - Tier selection speed
   - Combined Rust + tier router

3. System Integration (4 benchmarks)
   - End-to-end query performance
   - Throughput (queries/second)
   - Memory usage
   - Cache hit rates

Performance Targets:
- Rust Primitives: <0.1ms (Target: 10x faster than Python ~0.5ms)
- Python Baseline: ~0.5ms
- Tier Router Overhead: <1ms
- Routing Percentage: 30%+ to optimal tiers
- Overall Speedup: 10x improvement

Author: Agent 6 - Wave 1 Performance Benchmarking Specialist
Date: 2025-12-06
"""

import os
import sys
import time
import statistics
import json
from pathlib import Path
from typing import Dict, List, Any, Tuple
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, asdict

# Add zones to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "zones"))

# Import the components to benchmark
try:
    from z07_data_access.tier_router import TierRouter, get_tier_router
    TIER_ROUTER_AVAILABLE = True
except ImportError as e:
    print(f"Warning: TierRouter not available: {e}")
    TIER_ROUTER_AVAILABLE = False

# Try to import Rust primitives
try:
    from rust_primitives import RustDatabaseReader
    RUST_AVAILABLE = True
except ImportError:
    print("Note: Rust primitives not available, will benchmark Python fallback only")
    RUST_AVAILABLE = False


@dataclass
class BenchmarkResult:
    """Result from a single benchmark run"""
    name: str
    category: str
    iterations: int
    mean_ms: float
    median_ms: float
    std_dev_ms: float
    min_ms: float
    max_ms: float
    p95_ms: float
    p99_ms: float
    success: bool
    error: str = ""
    metadata: Dict[str, Any] = None

    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        if self.metadata is None:
            result['metadata'] = {}
        return result


class Wave1Benchmarks:
    """Comprehensive benchmark suite for Wave 1 deployment"""

    def __init__(self):
        """Initialize benchmark suite"""
        self.results: List[BenchmarkResult] = []
        self.db_url = os.environ.get(
            "DATABASE_URL",
            "postgresql://postgres:temppass123@localhost:5435/sapphire_database"
        )

        # Initialize components if available
        self.rust_reader = None
        self.tier_router = None

        if RUST_AVAILABLE:
            try:
                self.rust_reader = RustDatabaseReader(self.db_url, pool_size=10)
                print("✓ Rust primitives initialized")
            except Exception as e:
                print(f"✗ Rust initialization failed: {e}")

        if TIER_ROUTER_AVAILABLE:
            try:
                self.tier_router = get_tier_router(enable_rust=RUST_AVAILABLE)
                print("✓ TierRouter initialized")
            except Exception as e:
                print(f"✗ TierRouter initialization failed: {e}")

    def _run_benchmark(
        self,
        name: str,
        category: str,
        func: callable,
        iterations: int = 100,
        warmup: int = 10
    ) -> BenchmarkResult:
        """
        Run a benchmark with warmup and collect statistics.

        Args:
            name: Benchmark name
            category: Category (rust_primitives, tier_router, system)
            func: Function to benchmark (should return success boolean)
            iterations: Number of iterations
            warmup: Number of warmup iterations

        Returns:
            BenchmarkResult with timing statistics
        """
        print(f"\n  Running: {name} ({iterations} iterations)...", end=" ")

        # Warmup
        for _ in range(warmup):
            try:
                func()
            except Exception:
                pass

        # Actual benchmark
        timings = []
        successes = 0
        errors = []

        for i in range(iterations):
            start = time.perf_counter()
            try:
                success = func()
                if success:
                    successes += 1
            except Exception as e:
                errors.append(str(e))

            end = time.perf_counter()
            timings.append((end - start) * 1000)  # Convert to ms

        # Calculate statistics
        if timings:
            mean_ms = statistics.mean(timings)
            median_ms = statistics.median(timings)
            std_dev_ms = statistics.stdev(timings) if len(timings) > 1 else 0
            min_ms = min(timings)
            max_ms = max(timings)
            sorted_timings = sorted(timings)
            p95_ms = sorted_timings[int(len(sorted_timings) * 0.95)]
            p99_ms = sorted_timings[int(len(sorted_timings) * 0.99)]
        else:
            mean_ms = median_ms = std_dev_ms = min_ms = max_ms = p95_ms = p99_ms = 0

        success = (successes / iterations) >= 0.95  # 95% success rate
        error = "; ".join(set(errors[:3])) if errors else ""

        result = BenchmarkResult(
            name=name,
            category=category,
            iterations=iterations,
            mean_ms=mean_ms,
            median_ms=median_ms,
            std_dev_ms=std_dev_ms,
            min_ms=min_ms,
            max_ms=max_ms,
            p95_ms=p95_ms,
            p99_ms=p99_ms,
            success=success,
            error=error,
            metadata={
                'success_rate': successes / iterations,
                'error_count': len(errors)
            }
        )

        status = "✓" if success else "✗"
        print(f"{status} {mean_ms:.3f}ms (median: {median_ms:.3f}ms)")

        self.results.append(result)
        return result

    # =========================================================================
    # Category 1: Rust Primitives Benchmarks (6 benchmarks)
    # =========================================================================

    def benchmark_rust_single_lookup(self) -> BenchmarkResult:
        """Benchmark 1: Single drug lookup using Rust primitives"""
        if not self.rust_reader:
            return self._create_skip_result(
                "Rust Single Lookup",
                "rust_primitives",
                "Rust primitives not available"
            )

        def test():
            try:
                result = self.rust_reader.resolve_drug("CHEMBL113")
                return result is not None
            except Exception:
                return False

        return self._run_benchmark(
            "Rust Single Lookup",
            "rust_primitives",
            test,
            iterations=1000
        )

    def benchmark_python_single_lookup(self) -> BenchmarkResult:
        """Benchmark 2: Single drug lookup using Python SQL (baseline)"""
        if not self.tier_router:
            return self._create_skip_result(
                "Python Single Lookup (Baseline)",
                "rust_primitives",
                "TierRouter not available"
            )

        def test():
            try:
                # Force Python mode
                result = self.tier_router.resolve_drug("CHEMBL113", use_rust=False)
                return result is not None
            except Exception:
                return False

        return self._run_benchmark(
            "Python Single Lookup (Baseline)",
            "rust_primitives",
            test,
            iterations=1000
        )

    def benchmark_cached_lookup(self) -> BenchmarkResult:
        """Benchmark 3: Cached lookup comparison"""
        if not self.tier_router:
            return self._create_skip_result(
                "Cached Lookup",
                "rust_primitives",
                "TierRouter not available"
            )

        # Prime cache
        try:
            self.tier_router.resolve_drug("CHEMBL113")
        except Exception:
            pass

        def test():
            try:
                result = self.tier_router.resolve_drug("CHEMBL113")
                return result is not None
            except Exception:
                return False

        return self._run_benchmark(
            "Cached Lookup",
            "rust_primitives",
            test,
            iterations=10000
        )

    def benchmark_bulk_lookup(self) -> BenchmarkResult:
        """Benchmark 4: Bulk lookup (100 drugs)"""
        if not self.tier_router:
            return self._create_skip_result(
                "Bulk Lookup (100 drugs)",
                "rust_primitives",
                "TierRouter not available"
            )

        drug_ids = [f"CHEMBL{i}" for i in range(100, 200)]

        def test():
            try:
                results = [self.tier_router.resolve_drug(drug_id) for drug_id in drug_ids]
                return len(results) == 100
            except Exception:
                return False

        return self._run_benchmark(
            "Bulk Lookup (100 drugs)",
            "rust_primitives",
            test,
            iterations=10
        )

    def benchmark_concurrent_queries(self) -> BenchmarkResult:
        """Benchmark 5: Concurrent queries (10 threads)"""
        if not self.tier_router:
            return self._create_skip_result(
                "Concurrent Queries (10 threads)",
                "rust_primitives",
                "TierRouter not available"
            )

        drug_ids = [f"CHEMBL{i}" for i in range(100, 110)]

        def test():
            try:
                with ThreadPoolExecutor(max_workers=10) as executor:
                    futures = [
                        executor.submit(self.tier_router.resolve_drug, drug_id)
                        for drug_id in drug_ids
                    ]
                    results = [f.result() for f in as_completed(futures)]
                    return len(results) == 10
            except Exception:
                return False

        return self._run_benchmark(
            "Concurrent Queries (10 threads)",
            "rust_primitives",
            test,
            iterations=100
        )

    def benchmark_fallback_performance(self) -> BenchmarkResult:
        """Benchmark 6: Rust fallback to Python performance"""
        if not self.tier_router:
            return self._create_skip_result(
                "Fallback Performance",
                "rust_primitives",
                "TierRouter not available"
            )

        def test():
            try:
                # Try a lookup that might fail in Rust and fallback to Python
                result = self.tier_router.resolve_drug("INVALID_DRUG_12345")
                return True  # Success if it doesn't crash
            except Exception:
                return False

        return self._run_benchmark(
            "Fallback Performance",
            "rust_primitives",
            test,
            iterations=100
        )

    # =========================================================================
    # Category 2: Tier Router Benchmarks (5 benchmarks)
    # =========================================================================

    def benchmark_routing_overhead_single(self) -> BenchmarkResult:
        """Benchmark 7: Routing overhead for single query"""
        if not self.tier_router:
            return self._create_skip_result(
                "Routing Overhead (Single Query)",
                "tier_router",
                "TierRouter not available"
            )

        from z07_data_access.tier_router import QueryType

        def test():
            try:
                routing = self.tier_router.route_query(QueryType.NAME_RESOLUTION)
                return routing is not None
            except Exception:
                return False

        return self._run_benchmark(
            "Routing Overhead (Single Query)",
            "tier_router",
            test,
            iterations=10000
        )

    def benchmark_routing_overhead_average(self) -> BenchmarkResult:
        """Benchmark 8: Average routing overhead across 1,000 queries"""
        if not self.tier_router:
            return self._create_skip_result(
                "Routing Overhead (1,000 queries)",
                "tier_router",
                "TierRouter not available"
            )

        from z07_data_access.tier_router import QueryType
        query_types = [
            QueryType.NAME_RESOLUTION,
            QueryType.ID_MAPPING,
            QueryType.METADATA_LOOKUP,
            QueryType.EMBEDDING_SIMILARITY,
            QueryType.VECTOR_NEIGHBORS
        ]

        def test():
            try:
                for i in range(200):  # 200 * 5 = 1,000 total
                    query_type = query_types[i % len(query_types)]
                    self.tier_router.route_query(query_type)
                return True
            except Exception:
                return False

        return self._run_benchmark(
            "Routing Overhead (1,000 queries)",
            "tier_router",
            test,
            iterations=10
        )

    def benchmark_routing_percentage(self) -> BenchmarkResult:
        """Benchmark 9: Validate routing percentage to optimal tiers"""
        if not self.tier_router:
            return self._create_skip_result(
                "Routing Percentage Validation",
                "tier_router",
                "TierRouter not available"
            )

        # Simulate diverse queries
        queries = [
            ("CHEMBL113", "drug"),
            ("TP53", "gene"),
            ("REACTOME:R-HSA-1428517", "pathway"),
        ] * 10

        def test():
            try:
                for entity_id, entity_type in queries:
                    if entity_type == "drug":
                        self.tier_router.resolve_drug(entity_id)
                    elif entity_type == "gene":
                        self.tier_router.resolve_gene(entity_id)
                    elif entity_type == "pathway":
                        self.tier_router.resolve_pathway(entity_id)
                return True
            except Exception:
                return False

        return self._run_benchmark(
            "Routing Percentage Validation",
            "tier_router",
            test,
            iterations=10
        )

    def benchmark_tier_selection_speed(self) -> BenchmarkResult:
        """Benchmark 10: Tier selection speed"""
        if not self.tier_router:
            return self._create_skip_result(
                "Tier Selection Speed",
                "tier_router",
                "TierRouter not available"
            )

        from z07_data_access.tier_router import QueryType

        def test():
            try:
                # Test all query types
                for query_type in QueryType:
                    self.tier_router.route_query(query_type)
                return True
            except Exception:
                return False

        return self._run_benchmark(
            "Tier Selection Speed",
            "tier_router",
            test,
            iterations=1000
        )

    def benchmark_combined_rust_router(self) -> BenchmarkResult:
        """Benchmark 11: Combined Rust + Tier Router performance"""
        if not self.tier_router:
            return self._create_skip_result(
                "Combined Rust + Router",
                "tier_router",
                "TierRouter not available"
            )

        def test():
            try:
                # End-to-end: route + resolve
                result = self.tier_router.resolve_drug("CHEMBL113")
                return result is not None
            except Exception:
                return False

        return self._run_benchmark(
            "Combined Rust + Router",
            "tier_router",
            test,
            iterations=1000
        )

    # =========================================================================
    # Category 3: System Integration Benchmarks (4 benchmarks)
    # =========================================================================

    def benchmark_end_to_end_query(self) -> BenchmarkResult:
        """Benchmark 12: End-to-end query performance"""
        if not self.tier_router:
            return self._create_skip_result(
                "End-to-End Query",
                "system",
                "TierRouter not available"
            )

        def test():
            try:
                # Simulate real-world query: resolve drug, get metadata
                drug = self.tier_router.resolve_drug("CHEMBL113")
                gene = self.tier_router.resolve_gene("TP53")
                return drug is not None and gene is not None
            except Exception:
                return False

        return self._run_benchmark(
            "End-to-End Query",
            "system",
            test,
            iterations=500
        )

    def benchmark_throughput(self) -> BenchmarkResult:
        """Benchmark 13: Throughput (queries/second)"""
        if not self.tier_router:
            return self._create_skip_result(
                "Throughput (queries/sec)",
                "system",
                "TierRouter not available"
            )

        def test():
            try:
                start = time.perf_counter()
                for i in range(100):
                    self.tier_router.resolve_drug(f"CHEMBL{100 + (i % 50)}")
                elapsed = time.perf_counter() - start
                qps = 100 / elapsed
                return qps > 100  # Target: >100 qps
            except Exception:
                return False

        return self._run_benchmark(
            "Throughput (queries/sec)",
            "system",
            test,
            iterations=10
        )

    def benchmark_memory_usage(self) -> BenchmarkResult:
        """Benchmark 14: Memory usage efficiency"""
        if not self.tier_router:
            return self._create_skip_result(
                "Memory Usage",
                "system",
                "TierRouter not available"
            )

        import psutil
        import os as os_module

        process = psutil.Process(os_module.getpid())

        def test():
            try:
                mem_before = process.memory_info().rss / 1024 / 1024  # MB

                # Perform 1000 queries
                for i in range(1000):
                    self.tier_router.resolve_drug(f"CHEMBL{100 + (i % 100)}")

                mem_after = process.memory_info().rss / 1024 / 1024  # MB
                mem_increase = mem_after - mem_before

                # Memory increase should be minimal (<10MB for 1000 queries)
                return mem_increase < 10
            except Exception:
                return False

        return self._run_benchmark(
            "Memory Usage",
            "system",
            test,
            iterations=5
        )

    def benchmark_cache_hit_rate(self) -> BenchmarkResult:
        """Benchmark 15: Cache hit rate efficiency"""
        if not self.tier_router:
            return self._create_skip_result(
                "Cache Hit Rate",
                "system",
                "TierRouter not available"
            )

        def test():
            try:
                # Clear cache
                self.tier_router.clear_cache()

                # Prime cache with 50 unique queries
                for i in range(50):
                    self.tier_router.resolve_drug(f"CHEMBL{100 + i}")

                # Repeat queries (should hit cache)
                for i in range(50):
                    self.tier_router.resolve_drug(f"CHEMBL{100 + i}")

                # Check cache stats
                stats = self.tier_router.get_stats()
                cache_info = stats.get('cache_info', {}).get('resolve_drug', {})
                hits = cache_info.get('hits', 0)

                # Should have high cache hit rate
                return hits > 40  # At least 80% hit rate
            except Exception:
                return False

        return self._run_benchmark(
            "Cache Hit Rate",
            "system",
            test,
            iterations=10
        )

    def _create_skip_result(self, name: str, category: str, reason: str) -> BenchmarkResult:
        """Create a skipped benchmark result"""
        result = BenchmarkResult(
            name=name,
            category=category,
            iterations=0,
            mean_ms=0,
            median_ms=0,
            std_dev_ms=0,
            min_ms=0,
            max_ms=0,
            p95_ms=0,
            p99_ms=0,
            success=False,
            error=f"SKIPPED: {reason}",
            metadata={'skipped': True, 'reason': reason}
        )
        print(f"\n  ⊘ Skipped: {name} ({reason})")
        self.results.append(result)
        return result

    # =========================================================================
    # Main Benchmark Runner
    # =========================================================================

    def run_all_benchmarks(self) -> Dict[str, Any]:
        """
        Run all benchmarks and return results.

        Returns:
            Dict with benchmark results and analysis
        """
        print("\n" + "=" * 80)
        print("Wave 1 Performance Benchmarks - Rust Primitives & Tier Router")
        print("=" * 80)

        print("\n" + "-" * 80)
        print("Category 1: Rust Primitives (6 benchmarks)")
        print("-" * 80)
        self.benchmark_rust_single_lookup()
        self.benchmark_python_single_lookup()
        self.benchmark_cached_lookup()
        self.benchmark_bulk_lookup()
        self.benchmark_concurrent_queries()
        self.benchmark_fallback_performance()

        print("\n" + "-" * 80)
        print("Category 2: Tier Router (5 benchmarks)")
        print("-" * 80)
        self.benchmark_routing_overhead_single()
        self.benchmark_routing_overhead_average()
        self.benchmark_routing_percentage()
        self.benchmark_tier_selection_speed()
        self.benchmark_combined_rust_router()

        print("\n" + "-" * 80)
        print("Category 3: System Integration (4 benchmarks)")
        print("-" * 80)
        self.benchmark_end_to_end_query()
        self.benchmark_throughput()
        self.benchmark_memory_usage()
        self.benchmark_cache_hit_rate()

        # Analyze results
        analysis = self._analyze_results()

        print("\n" + "=" * 80)
        print("Benchmark Summary")
        print("=" * 80)
        print(f"\nTotal Benchmarks: {len(self.results)}")
        print(f"Successful: {analysis['successful_count']}")
        print(f"Failed: {analysis['failed_count']}")
        print(f"Skipped: {analysis['skipped_count']}")

        return {
            'results': [r.to_dict() for r in self.results],
            'analysis': analysis,
            'targets_met': self._validate_targets(analysis)
        }

    def _analyze_results(self) -> Dict[str, Any]:
        """Analyze benchmark results and calculate metrics"""
        total = len(self.results)
        successful = sum(1 for r in self.results if r.success)
        failed = sum(1 for r in self.results if not r.success and not r.metadata.get('skipped', False))
        skipped = sum(1 for r in self.results if r.metadata.get('skipped', False))

        # Calculate speedup (Rust vs Python)
        rust_result = next((r for r in self.results if r.name == "Rust Single Lookup"), None)
        python_result = next((r for r in self.results if r.name == "Python Single Lookup (Baseline)"), None)

        speedup = None
        if rust_result and python_result and rust_result.mean_ms > 0 and python_result.mean_ms > 0:
            speedup = python_result.mean_ms / rust_result.mean_ms

        # Calculate average routing overhead
        routing_results = [r for r in self.results if r.category == "tier_router"]
        avg_routing_overhead = statistics.mean([r.mean_ms for r in routing_results]) if routing_results else None

        return {
            'total_benchmarks': total,
            'successful_count': successful,
            'failed_count': failed,
            'skipped_count': skipped,
            'success_rate': successful / total if total > 0 else 0,
            'rust_speedup': speedup,
            'avg_routing_overhead_ms': avg_routing_overhead,
            'rust_available': RUST_AVAILABLE,
            'tier_router_available': TIER_ROUTER_AVAILABLE
        }

    def _validate_targets(self, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """Validate performance targets"""
        targets_met = {}

        # Target 1: Rust <0.1ms
        rust_result = next((r for r in self.results if r.name == "Rust Single Lookup"), None)
        if rust_result:
            targets_met['rust_sub_0_1ms'] = rust_result.mean_ms < 0.1

        # Target 2: 10x speedup
        if analysis['rust_speedup']:
            targets_met['10x_speedup'] = analysis['rust_speedup'] >= 10.0

        # Target 3: <1ms routing overhead
        if analysis['avg_routing_overhead_ms']:
            targets_met['routing_sub_1ms'] = analysis['avg_routing_overhead_ms'] < 1.0

        # Target 4: 30%+ routing to optimal tiers
        # (Would need to check tier_router stats)
        if self.tier_router:
            stats = self.tier_router.get_stats()
            tier_dist = stats.get('tier_distribution_percent', {})
            routing_pct = sum(pct for tier, pct in tier_dist.items() if tier != 'master_tables')
            targets_met['30pct_routing'] = routing_pct >= 30.0

        return targets_met

    def export_results(self, filepath: str):
        """Export results to JSON file"""
        analysis = self._analyze_results()
        data = {
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
            'results': [r.to_dict() for r in self.results],
            'analysis': analysis,
            'targets_met': self._validate_targets(analysis)
        }

        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"\n✓ Results exported to: {filepath}")


def main():
    """Main entry point"""
    benchmarks = Wave1Benchmarks()
    results = benchmarks.run_all_benchmarks()

    # Export results
    output_dir = Path(__file__).parent.parent.parent / ".outcomes"
    output_dir.mkdir(exist_ok=True)
    output_file = output_dir / "wave1_benchmark_results.json"
    benchmarks.export_results(str(output_file))

    return results


if __name__ == "__main__":
    main()
