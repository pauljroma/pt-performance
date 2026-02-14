"""
Performance Benchmark Template

Compares Python vs Cython vs Rust implementations to verify speedup.

Usage:
    python benchmark.py

Requirements:
    pip install numpy pandas tabulate matplotlib
"""

import time
import numpy as np
import pandas as pd
from typing import Callable, Dict, List, Optional
from tabulate import tabulate
import sys

# Import implementations
# Uncomment the ones you have:

# import fast_ops_python as py_impl  # Pure Python
# import fast_ops_cython as cy_impl  # Cython
# import fast_ops_rust as rs_impl    # Rust


class Benchmarker:
    """Benchmark different implementations."""

    def __init__(self, n_runs: int = 10, warmup_runs: int = 2):
        self.n_runs = n_runs
        self.warmup_runs = warmup_runs
        self.results = []

    def benchmark_function(
        self,
        func: Callable,
        args: tuple,
        kwargs: dict,
        name: str
    ) -> Dict[str, float]:
        """
        Benchmark a single function.

        Args:
            func: Function to benchmark
            args: Positional arguments
            kwargs: Keyword arguments
            name: Name for reporting

        Returns:
            Dict with timing statistics
        """
        # Warmup runs (not counted)
        for _ in range(self.warmup_runs):
            try:
                _ = func(*args, **kwargs)
            except Exception as e:
                return {
                    'name': name,
                    'error': str(e),
                    'mean': float('inf'),
                    'std': 0,
                    'min': float('inf'),
                    'max': float('inf'),
                }

        # Actual benchmark runs
        times = []
        for _ in range(self.n_runs):
            start = time.perf_counter()
            result = func(*args, **kwargs)
            elapsed = time.perf_counter() - start
            times.append(elapsed)

        return {
            'name': name,
            'mean': np.mean(times),
            'std': np.std(times),
            'min': np.min(times),
            'max': np.max(times),
            'result': result,  # Store for verification
        }

    def add_result(self, result: Dict):
        """Add benchmark result."""
        self.results.append(result)

    def compare(self, baseline_name: str = None) -> pd.DataFrame:
        """
        Compare results and calculate speedups.

        Args:
            baseline_name: Name of baseline implementation (usually Python)

        Returns:
            DataFrame with comparison
        """
        df = pd.DataFrame(self.results)

        # Calculate speedup relative to baseline
        if baseline_name and baseline_name in df['name'].values:
            baseline_time = df[df['name'] == baseline_name]['mean'].iloc[0]
            df['speedup'] = baseline_time / df['mean']
        else:
            # Use slowest as baseline
            baseline_time = df['mean'].max()
            df['speedup'] = baseline_time / df['mean']

        # Sort by speed (fastest first)
        df = df.sort_values('mean')

        return df

    def print_report(self, baseline_name: str = None):
        """Print formatted benchmark report."""
        df = self.compare(baseline_name)

        print("\n" + "=" * 80)
        print("PERFORMANCE BENCHMARK REPORT")
        print("=" * 80)

        # Summary table
        table_data = []
        for _, row in df.iterrows():
            if 'error' in row and row['error']:
                table_data.append([
                    row['name'],
                    'ERROR',
                    row['error'],
                    '-',
                ])
            else:
                table_data.append([
                    row['name'],
                    f"{row['mean']:.6f}s",
                    f"±{row['std']:.6f}s",
                    f"{row['speedup']:.1f}x",
                ])

        print("\n")
        print(tabulate(
            table_data,
            headers=['Implementation', 'Mean Time', 'Std Dev', 'Speedup'],
            tablefmt='grid'
        ))

        # Detailed statistics
        print("\n" + "-" * 80)
        print("DETAILED STATISTICS")
        print("-" * 80)

        for _, row in df.iterrows():
            if 'error' not in row or not row['error']:
                print(f"\n{row['name']}:")
                print(f"  Mean:    {row['mean']:.6f}s")
                print(f"  Std Dev: {row['std']:.6f}s")
                print(f"  Min:     {row['min']:.6f}s")
                print(f"  Max:     {row['max']:.6f}s")
                print(f"  Speedup: {row['speedup']:.1f}x")

        # Speedup analysis
        print("\n" + "-" * 80)
        print("SPEEDUP ANALYSIS")
        print("-" * 80)

        fastest = df.iloc[0]
        slowest = df.iloc[-1]

        print(f"\nFastest: {fastest['name']} ({fastest['mean']:.6f}s)")
        print(f"Slowest: {slowest['name']} ({slowest['mean']:.6f}s)")
        print(f"Overall speedup: {slowest['mean'] / fastest['mean']:.1f}x")

        # Recommendations
        print("\n" + "-" * 80)
        print("RECOMMENDATIONS")
        print("-" * 80)

        if len(df) >= 2:
            second_fastest = df.iloc[1]
            speedup_diff = second_fastest['mean'] / fastest['mean']

            print(f"\nFastest implementation: {fastest['name']}")

            if speedup_diff < 1.5:
                print(f"⚠️  Only {speedup_diff:.1f}x faster than {second_fastest['name']}")
                print("   Consider complexity vs benefit tradeoff")
            elif speedup_diff < 5:
                print(f"✅ {speedup_diff:.1f}x faster than {second_fastest['name']}")
                print("   Good speedup, worth the complexity")
            else:
                print(f"🚀 {speedup_diff:.1f}x faster than {second_fastest['name']}")
                print("   Excellent speedup, definitely worth it!")

        print("\n" + "=" * 80)

    def verify_correctness(self, tolerance: float = 1e-6) -> bool:
        """
        Verify all implementations produce same result.

        Args:
            tolerance: Tolerance for floating-point comparison

        Returns:
            True if all results match
        """
        if len(self.results) < 2:
            return True

        baseline_result = self.results[0]['result']

        for result in self.results[1:]:
            if not np.allclose(result['result'], baseline_result, atol=tolerance):
                print(f"❌ Result mismatch: {result['name']}")
                print(f"   Expected: {baseline_result}")
                print(f"   Got: {result['result']}")
                return False

        print("✅ All implementations produce identical results")
        return True


# ============================================================================
# EXAMPLE BENCHMARKS
# ============================================================================

def benchmark_array_processing():
    """Benchmark array processing functions."""
    print("\n" + "=" * 80)
    print("BENCHMARK: Array Processing (1M elements)")
    print("=" * 80)

    # Generate test data
    data = np.random.randn(1_000_000)

    benchmarker = Benchmarker(n_runs=10, warmup_runs=2)

    # Benchmark Python implementation
    def python_impl(data):
        """Pure Python implementation."""
        result = 0.0
        for value in data:
            result += value * value + 2 * value + 1
        return result

    benchmarker.add_result(
        benchmarker.benchmark_function(
            python_impl,
            args=(data,),
            kwargs={},
            name="Python"
        )
    )

    # Benchmark Cython implementation (if available)
    try:
        import fast_ops_cython
        benchmarker.add_result(
            benchmarker.benchmark_function(
                fast_ops_cython.process_data_fast,
                args=(data,),
                kwargs={},
                name="Cython"
            )
        )
    except ImportError:
        print("⚠️  Cython implementation not available")

    # Benchmark Rust implementation (if available)
    try:
        import fast_ops_rust
        benchmarker.add_result(
            benchmarker.benchmark_function(
                fast_ops_rust.process_parallel,
                args=(data.tolist(),),
                kwargs={},
                name="Rust (parallel)"
            )
        )
    except ImportError:
        print("⚠️  Rust implementation not available")

    # Print report
    benchmarker.print_report(baseline_name="Python")

    # Verify correctness
    benchmarker.verify_correctness()


def benchmark_filter_transform():
    """Benchmark filter + transform operations."""
    print("\n" + "=" * 80)
    print("BENCHMARK: Filter + Transform (1M elements)")
    print("=" * 80)

    data = np.random.randn(1_000_000)
    threshold = 0.0

    benchmarker = Benchmarker(n_runs=10)

    # Python implementation
    def python_impl(data, threshold):
        return [x * 2.0 for x in data if x > threshold]

    benchmarker.add_result(
        benchmarker.benchmark_function(
            python_impl,
            args=(data.tolist(), threshold),
            kwargs={},
            name="Python (list comp)"
        )
    )

    # NumPy implementation
    def numpy_impl(data, threshold):
        return data[data > threshold] * 2.0

    benchmarker.add_result(
        benchmarker.benchmark_function(
            numpy_impl,
            args=(data, threshold),
            kwargs={},
            name="NumPy"
        )
    )

    # Rust implementation (if available)
    try:
        import fast_ops_rust
        benchmarker.add_result(
            benchmarker.benchmark_function(
                fast_ops_rust.filter_transform,
                args=(data.tolist(), threshold),
                kwargs={},
                name="Rust (parallel)"
            )
        )
    except ImportError:
        print("⚠️  Rust implementation not available")

    benchmarker.print_report(baseline_name="Python (list comp)")


def benchmark_json_parsing():
    """Benchmark JSON parsing."""
    print("\n" + "=" * 80)
    print("BENCHMARK: JSON Parsing (1MB)")
    print("=" * 80)

    import json

    # Generate test JSON
    test_data = {f"key_{i}": {"value": i, "data": [i] * 10} for i in range(10000)}
    json_str = json.dumps(test_data)

    print(f"JSON size: {len(json_str) / 1024:.1f} KB")

    benchmarker = Benchmarker(n_runs=10)

    # Python json module
    def python_json(s):
        return json.loads(s)

    benchmarker.add_result(
        benchmarker.benchmark_function(
            python_json,
            args=(json_str,),
            kwargs={},
            name="Python (json)"
        )
    )

    # Rust implementation (if available)
    try:
        import fast_ops_rust
        benchmarker.add_result(
            benchmarker.benchmark_function(
                fast_ops_rust.parse_json_fast,
                args=(json_str,),
                kwargs={},
                name="Rust (serde_json)"
            )
        )
    except ImportError:
        print("⚠️  Rust implementation not available")

    benchmarker.print_report(baseline_name="Python (json)")


# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    print("\n")
    print("╔" + "=" * 78 + "╗")
    print("║" + " " * 20 + "POLYGLOT PERFORMANCE BENCHMARK" + " " * 28 + "║")
    print("╚" + "=" * 78 + "╝")

    # Run all benchmarks
    benchmark_array_processing()
    benchmark_filter_transform()
    benchmark_json_parsing()

    print("\n" + "=" * 80)
    print("BENCHMARK COMPLETE")
    print("=" * 80)
    print("\nNext steps:")
    print("1. Review speedup numbers")
    print("2. Check if speedup justifies complexity")
    print("3. Profile to identify remaining bottlenecks")
    print("4. Consider: Is this the right optimization level for your use case?")
    print("\nGuidelines:")
    print("  - <5x speedup: Consider if complexity is worth it")
    print("  - 5-50x speedup: Usually worth it for hot paths")
    print("  - >50x speedup: Excellent, definitely use optimized version")
    print("\n")
