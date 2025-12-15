#!/usr/bin/env python3
"""
Fusion Tools Baseline Performance Benchmark

Measures baseline performance for all 9 fusion-integrated tools in LEGACY mode
(with fusion disabled) to establish pre-deployment performance metrics.

Phase 2 of Production Deployment Swarm:
- Benchmark each tool with fusion disabled
- Run sample queries (10 per tool)
- Measure latency (avg, p95, p99)
- Document baseline for comparison

Author: Claude Code Agent
Date: 2025-12-03
"""

import os
import sys
import time
import json
import asyncio
from typing import Dict, Any, List
import statistics

# Temporarily disable fusion for baseline measurement
os.environ["FUSION_TABLES_ENABLED"] = "false"

# Import all 9 fusion-integrated tools
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bbb_permeability
import drug_repurposing_ranker
import demeo_drug_rescue
import drug_lookalikes
import target_validation_scorer
import drug_interactions
import rescue_combinations
import drug_combinations_synergy
import vector_neighbors


# Test queries for each tool
TOOL_TESTS = {
    "bbb_permeability": {
        "tool": bbb_permeability,
        "queries": [
            {"drug_id": "DB00997"},  # Doxorubicin
            {"drug_id": "DB01174"},  # Phenobarbital
            {"drug_id": "DB00334"},  # Olanzapine
        ]
    },
    "drug_repurposing_ranker": {
        "tool": drug_repurposing_ranker,
        "queries": [
            {"disease": "epilepsy", "top_k": 20},
            {"disease": "alzheimer", "top_k": 20},
            {"disease": "parkinson", "top_k": 20},
        ]
    },
    "demeo_drug_rescue": {
        "tool": demeo_drug_rescue,
        "queries": [
            {"gene": "TSC2", "top_k": 20},
            {"gene": "SCN1A", "top_k": 20},
            {"gene": "KCNQ2", "top_k": 20},
        ]
    },
    "drug_lookalikes": {
        "tool": drug_lookalikes,
        "queries": [
            {"drug_id": "DB00997", "top_k": 20},
            {"drug_id": "DB01174", "top_k": 20},
            {"drug_id": "DB00334", "top_k": 20},
        ]
    },
    "target_validation_scorer": {
        "tool": target_validation_scorer,
        "queries": [
            {"gene": "TSC2", "disease": "epilepsy"},
            {"gene": "SCN1A", "disease": "epilepsy"},
            {"gene": "KCNQ2", "disease": "epilepsy"},
        ]
    },
    "drug_interactions": {
        "tool": drug_interactions,
        "queries": [
            {"drug1": "DB00997", "drug2": "DB01174"},
            {"drug1": "DB00334", "drug2": "DB00997"},
            {"drug1": "DB01174", "drug2": "DB00334"},
        ]
    },
    "rescue_combinations": {
        "tool": rescue_combinations,
        "queries": [
            {"gene": "TSC2", "top_k": 10},
            {"gene": "SCN1A", "top_k": 10},
            {"gene": "KCNQ2", "top_k": 10},
        ]
    },
    "drug_combinations_synergy": {
        "tool": drug_combinations_synergy,
        "queries": [
            {"drug_id": "DB00997", "top_k": 10},
            {"drug_id": "DB01174", "top_k": 10},
            {"drug_id": "DB00334", "top_k": 10},
        ]
    },
    "vector_neighbors": {
        "tool": vector_neighbors,
        "queries": [
            {"gene": "TSC2", "top_k": 20},
            {"gene": "SCN1A", "top_k": 20},
            {"gene": "KCNQ2", "top_k": 20},
        ]
    }
}


async def benchmark_tool(tool_name: str, tool_config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Benchmark a single tool with multiple queries

    Args:
        tool_name: Name of the tool
        tool_config: Tool configuration with queries

    Returns:
        Benchmark results
    """
    print(f"\n=== Benchmarking: {tool_name} ===")

    tool = tool_config["tool"]
    queries = tool_config["queries"]

    latencies = []
    successful_queries = 0
    failed_queries = 0

    for i, query_params in enumerate(queries, 1):
        try:
            start_time = time.time()

            # Execute tool query
            result = await tool.execute(query_params)

            latency_ms = (time.time() - start_time) * 1000
            latencies.append(latency_ms)

            if result.get("success", False):
                successful_queries += 1
                print(f"  Query {i}/{len(queries)}: {latency_ms:.2f}ms ✅")
            else:
                failed_queries += 1
                print(f"  Query {i}/{len(queries)}: {latency_ms:.2f}ms ❌ {result.get('error', 'Unknown error')}")

        except Exception as e:
            failed_queries += 1
            print(f"  Query {i}/{len(queries)}: EXCEPTION ❌ {e}")

    # Calculate statistics
    if latencies:
        avg_latency = statistics.mean(latencies)
        p50_latency = statistics.median(latencies)
        p95_latency = statistics.quantiles(latencies, n=20)[18] if len(latencies) >= 20 else max(latencies)
        p99_latency = statistics.quantiles(latencies, n=100)[98] if len(latencies) >= 100 else max(latencies)
        min_latency = min(latencies)
        max_latency = max(latencies)
    else:
        avg_latency = p50_latency = p95_latency = p99_latency = min_latency = max_latency = 0

    results = {
        "tool_name": tool_name,
        "total_queries": len(queries),
        "successful_queries": successful_queries,
        "failed_queries": failed_queries,
        "latency_ms": {
            "avg": round(avg_latency, 2),
            "p50": round(p50_latency, 2),
            "p95": round(p95_latency, 2),
            "p99": round(p99_latency, 2),
            "min": round(min_latency, 2),
            "max": round(max_latency, 2)
        },
        "fusion_enabled": False,
        "mode": "legacy"
    }

    print(f"  Avg latency: {avg_latency:.2f}ms | P95: {p95_latency:.2f}ms | P99: {p99_latency:.2f}ms")

    return results


async def main():
    """Main baseline benchmark routine"""
    print("=" * 80)
    print("FUSION TOOLS BASELINE PERFORMANCE BENCHMARK")
    print("Production Deployment - Phase 2")
    print("Mode: LEGACY (Fusion DISABLED)")
    print("=" * 80)

    start_time = time.time()

    # Verify fusion is disabled
    fusion_enabled = os.getenv("FUSION_TABLES_ENABLED", "false").lower() == "true"
    if fusion_enabled:
        print("❌ ERROR: Fusion is still enabled! Set FUSION_TABLES_ENABLED=false")
        sys.exit(1)

    print("✅ Fusion disabled - measuring legacy performance baseline\n")

    # Benchmark all tools
    all_results = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "mode": "legacy",
        "fusion_enabled": False,
        "tools": []
    }

    for tool_name, tool_config in TOOL_TESTS.items():
        try:
            result = await benchmark_tool(tool_name, tool_config)
            all_results["tools"].append(result)
        except Exception as e:
            print(f"❌ Failed to benchmark {tool_name}: {e}")
            all_results["tools"].append({
                "tool_name": tool_name,
                "error": str(e),
                "mode": "legacy"
            })

    # Calculate overall statistics
    total_queries = sum(t.get("total_queries", 0) for t in all_results["tools"])
    successful_queries = sum(t.get("successful_queries", 0) for t in all_results["tools"])
    failed_queries = sum(t.get("failed_queries", 0) for t in all_results["tools"])

    avg_latencies = [t.get("latency_ms", {}).get("avg", 0) for t in all_results["tools"] if "latency_ms" in t]
    overall_avg_latency = statistics.mean(avg_latencies) if avg_latencies else 0

    all_results["summary"] = {
        "total_tools": len(TOOL_TESTS),
        "total_queries": total_queries,
        "successful_queries": successful_queries,
        "failed_queries": failed_queries,
        "success_rate_pct": round(successful_queries / total_queries * 100, 1) if total_queries > 0 else 0,
        "overall_avg_latency_ms": round(overall_avg_latency, 2)
    }

    # Calculate total benchmark time
    total_time = time.time() - start_time
    all_results["total_benchmark_time_seconds"] = round(total_time, 2)

    # Print summary
    print("\n" + "=" * 80)
    print("BASELINE BENCHMARK SUMMARY")
    print("=" * 80)
    print(f"Total tools: {len(TOOL_TESTS)}")
    print(f"Total queries: {total_queries}")
    print(f"Successful: {successful_queries} ({all_results['summary']['success_rate_pct']}%)")
    print(f"Failed: {failed_queries}")
    print(f"Overall avg latency: {overall_avg_latency:.2f}ms (LEGACY MODE)")
    print(f"\nTotal benchmark time: {total_time:.2f}s")

    # Save results
    output_file = "fusion_baseline_performance.json"
    with open(output_file, "w") as f:
        json.dump(all_results, f, indent=2)

    print(f"\n📄 Baseline results saved to: {output_file}")

    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
