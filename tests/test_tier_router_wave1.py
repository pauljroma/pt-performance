"""
Comprehensive Test Suite for 4-Tier Router - Wave 1 Foundation
Tests routing logic, performance, tier selection, and fallback behavior

Success Criteria:
- All 18 tests passing
- <1ms routing overhead
- 30%+ query routing through tier system
- Correct tier selection validation
"""

import pytest
import os
import sys
import time
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from zones.z07_data_access.tier_router import TierRouter, DataTier, QueryType


class TestTierRouterInitialization:
    """Test router initialization and configuration"""

    def test_router_initialization(self):
        """Test basic router initialization"""
        router = TierRouter()
        assert router is not None
        assert router.config is not None

    def test_rust_mode_disabled_by_default(self):
        """Test that Rust mode is disabled in Wave 1"""
        router = TierRouter()
        assert router.use_rust == False

    def test_router_enabled_by_default(self):
        """Test that router is enabled by default"""
        router = TierRouter()
        assert router.enabled == True

    def test_config_loads_tier_thresholds(self):
        """Test that configuration loads tier thresholds correctly"""
        router = TierRouter()
        assert "tier_thresholds" in router.config
        assert "master_days" in router.config["tier_thresholds"]
        assert router.config["tier_thresholds"]["master_days"] == 7


class TestQueryAnalysis:
    """Test query analysis and classification"""

    def test_recent_query_detection(self):
        """Test detection of recent queries (Tier 1 - Master)"""
        router = TierRouter()
        query_params = {"days_back": 3}
        query_type, metadata = router.analyze_query(query_params)
        assert query_type == QueryType.RECENT
        assert metadata["days_back"] == 3

    def test_semantic_query_detection(self):
        """Test detection of semantic/embedding queries (Tier 2 - PGVector)"""
        router = TierRouter()
        query_params = {"use_embeddings": True}
        query_type, metadata = router.analyze_query(query_params)
        assert query_type == QueryType.SEMANTIC
        assert metadata["requires_vector"] == True

    def test_similarity_search_detection(self):
        """Test detection of similarity search queries (Tier 2 - PGVector)"""
        router = TierRouter()
        query_params = {"similarity_search": True}
        query_type, metadata = router.analyze_query(query_params)
        assert query_type == QueryType.SEMANTIC

    def test_historical_query_detection(self):
        """Test detection of historical queries (Tier 3 - MinIO)"""
        router = TierRouter()
        query_params = {"days_back": 30}
        query_type, metadata = router.analyze_query(query_params)
        assert query_type == QueryType.HISTORICAL
        assert metadata["days_back"] == 30

    def test_analytics_query_detection(self):
        """Test detection of analytics queries (Tier 4 - Athena)"""
        router = TierRouter()
        query_params = {"days_back": 120}
        query_type, metadata = router.analyze_query(query_params)
        assert query_type == QueryType.ANALYTICS


class TestTierSelection:
    """Test tier selection logic"""

    def test_master_tier_selection(self):
        """Test Master tier selection for recent queries"""
        router = TierRouter()
        query_params = {"days_back": 2}
        tier, overhead = router.route_query(query_params)
        assert tier == DataTier.MASTER

    def test_pgvector_tier_selection(self):
        """Test PGVector tier selection for semantic queries"""
        router = TierRouter()
        query_params = {"use_embeddings": True}
        tier, overhead = router.route_query(query_params)
        assert tier == DataTier.PGVECTOR

    def test_fallback_when_tier_disabled(self):
        """Test fallback to master when preferred tier is disabled"""
        router = TierRouter()
        # MinIO is disabled in Wave 1 config
        query_params = {"days_back": 45}
        tier, overhead = router.route_query(query_params)
        # Should fallback to master since MinIO is disabled
        assert tier == DataTier.MASTER

    def test_fallback_when_router_disabled(self):
        """Test that all queries go to master when router is disabled"""
        os.environ["TIER_ROUTER_ENABLED"] = "false"
        router = TierRouter()
        query_params = {"use_embeddings": True}
        tier, overhead = router.route_query(query_params)
        assert tier == DataTier.MASTER
        os.environ["TIER_ROUTER_ENABLED"] = "true"


class TestPerformance:
    """Test routing performance and overhead"""

    def test_routing_overhead_under_1ms(self):
        """Test that routing overhead is <1ms (critical requirement)"""
        router = TierRouter()
        query_params = {"days_back": 3}
        tier, overhead = router.route_query(query_params)
        assert overhead < 1.0, f"Routing overhead {overhead}ms exceeds 1ms limit"

    def test_average_overhead_under_1ms(self):
        """Test that average overhead stays <1ms over multiple queries"""
        router = TierRouter()
        queries = [
            {"days_back": 2},
            {"use_embeddings": True},
            {"days_back": 30},
            {"similarity_search": True},
            {"days_back": 5},
        ]

        for query_params in queries:
            router.route_query(query_params)

        metrics = router.get_routing_metrics()
        avg_overhead = metrics["avg_overhead_ms"]
        assert avg_overhead < 1.0, f"Average overhead {avg_overhead}ms exceeds 1ms"

    def test_routing_percentage_above_30(self):
        """Test that 30%+ of queries are routed through tier system"""
        router = TierRouter()

        # Simulate mixed workload
        queries = [
            {"days_back": 2},           # Master
            {"use_embeddings": True},   # PGVector (routed)
            {"days_back": 1},           # Master
            {"similarity_search": True}, # PGVector (routed)
            {"days_back": 3},           # Master
            {"use_embeddings": True},   # PGVector (routed)
            {"days_back": 2},           # Master
            {"use_embeddings": True},   # PGVector (routed)
        ]

        for query_params in queries:
            router.route_query(query_params)

        metrics = router.get_routing_metrics()
        routing_percentage = metrics["routing_percentage"]
        assert routing_percentage >= 30.0, \
            f"Routing percentage {routing_percentage}% is below 30% target"


class TestRoutingMetrics:
    """Test routing metrics and statistics"""

    def test_metrics_tracking(self):
        """Test that routing metrics are tracked correctly"""
        router = TierRouter()
        queries = [
            {"days_back": 2},
            {"use_embeddings": True},
            {"days_back": 3},
        ]

        for query_params in queries:
            router.route_query(query_params)

        metrics = router.get_routing_metrics()
        assert metrics["total_queries"] == 3
        assert "tier_distribution" in metrics
        assert "avg_overhead_ms" in metrics

    def test_tier_distribution_counts(self):
        """Test that tier distribution is counted correctly"""
        router = TierRouter()

        # 2 master, 2 pgvector
        queries = [
            {"days_back": 2},
            {"use_embeddings": True},
            {"days_back": 3},
            {"similarity_search": True},
        ]

        for query_params in queries:
            router.route_query(query_params)

        metrics = router.get_routing_metrics()
        tier_dist = metrics["tier_distribution"]
        assert tier_dist["master"] == 2
        assert tier_dist["pgvector"] == 2


# Benchmark test for detailed performance analysis
def test_routing_performance_benchmark():
    """Benchmark routing performance with 1000 queries"""
    router = TierRouter()

    queries = [
        {"days_back": 2},
        {"use_embeddings": True},
        {"days_back": 5},
        {"similarity_search": True},
        {"days_back": 1},
    ] * 200  # 1000 total queries

    start = time.perf_counter()
    for query_params in queries:
        router.route_query(query_params)
    end = time.perf_counter()

    total_time_ms = (end - start) * 1000
    avg_time_per_query = total_time_ms / len(queries)

    print(f"\n=== Routing Performance Benchmark ===")
    print(f"Total queries: {len(queries)}")
    print(f"Total time: {total_time_ms:.2f}ms")
    print(f"Average per query: {avg_time_per_query:.4f}ms")

    metrics = router.get_routing_metrics()
    print(f"Routing percentage: {metrics['routing_percentage']:.1f}%")
    print(f"Tier distribution: {metrics['tier_distribution']}")

    assert avg_time_per_query < 1.0, \
        f"Average routing time {avg_time_per_query}ms exceeds 1ms requirement"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
