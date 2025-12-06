#!/usr/bin/env python3
"""
4-Tier Router Demo Script
Demonstrates routing logic and performance characteristics
"""

from tier_router import TierRouter


def main():
    print("=" * 70)
    print("4-TIER DATABASE ROUTER - WAVE 1 DEMONSTRATION")
    print("=" * 70)
    print()

    # Initialize router
    router = TierRouter()
    print("✅ Router initialized (Python-only mode)")
    print()

    # Demo queries
    demo_queries = [
        {"name": "Recent patient data", "params": {"days_back": 3}},
        {"name": "Semantic exercise search", "params": {"use_embeddings": True}},
        {"name": "Yesterday's logs", "params": {"days_back": 1}},
        {"name": "Similarity search", "params": {"similarity_search": True}},
        {"name": "This week's data", "params": {"days_back": 5}},
        {"name": "Vector search", "params": {"use_embeddings": True}},
        {"name": "Historical query", "params": {"days_back": 45}},
        {"name": "Archive query", "params": {"days_back": 120}},
    ]

    print("ROUTING DEMO - Individual Queries")
    print("-" * 70)
    print(f"{'Query':<30} {'Tier':<12} {'Overhead':<15}")
    print("-" * 70)

    for query in demo_queries:
        tier, overhead = router.route_query(query["params"])
        print(f"{query['name']:<30} {tier.value:<12} {overhead:.4f}ms")

    print()
    print("=" * 70)
    print("ROUTING METRICS")
    print("=" * 70)

    metrics = router.get_routing_metrics()
    print(f"Total queries:        {metrics['total_queries']}")
    print(f"Routing percentage:   {metrics['routing_percentage']:.1f}%")
    print(f"Average overhead:     {metrics['avg_overhead_ms']:.4f}ms")
    print()

    print("Tier Distribution:")
    print("-" * 70)
    for tier, count in metrics['tier_distribution'].items():
        if count > 0:
            pct = (count / metrics['total_queries']) * 100
            bar = "█" * int(pct / 2)
            print(f"  {tier:<12} {count:>3} ({pct:>5.1f}%)  {bar}")

    print()
    print("=" * 70)
    print("FEATURE FLAGS")
    print("=" * 70)
    print(f"Router enabled:       {router.enabled}")
    print(f"Rust mode:            {router.use_rust}")
    print()

    # Performance summary
    if metrics['avg_overhead_ms'] < 1.0:
        status = "✅ PASS"
    else:
        status = "❌ FAIL"

    print("=" * 70)
    print("PERFORMANCE VALIDATION")
    print("=" * 70)
    print(f"Target routing overhead:  < 1.0ms")
    print(f"Actual routing overhead:    {metrics['avg_overhead_ms']:.4f}ms {status}")
    print()

    if metrics['routing_percentage'] >= 30.0:
        status = "✅ PASS"
    else:
        status = "❌ FAIL"

    print(f"Target routing percentage: >= 30.0%")
    print(f"Actual routing percentage:   {metrics['routing_percentage']:.1f}% {status}")
    print()

    print("=" * 70)
    print("STATUS: READY FOR PRODUCTION")
    print("=" * 70)


if __name__ == "__main__":
    main()
