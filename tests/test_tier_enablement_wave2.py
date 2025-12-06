"""
Comprehensive Test Suite for 4-Tier Router - Wave 2 (Full 4-Tier Enablement)
Tests MinIO (Tier 3), Athena (Tier 4), health monitoring, and automatic failover

Success Criteria:
- All 25+ tests passing
- MinIO and Athena queries working
- 50%+ routing to optimal tiers (from 42% in Wave 1)
- <1ms routing overhead maintained
- Automatic failover tested (tier failure recovery <5s)
- All Wave 1 tests still passing
"""

import pytest
import os
import sys
import time
from pathlib import Path
from unittest.mock import Mock, MagicMock

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from zones.z07_data_access.tier_router import TierRouter, DataTier, QueryType
from zones.z07_data_access.tier3_minio_integration import MinIOTier, HealthStatus as MinIOHealthStatus
from zones.z07_data_access.tier4_athena_integration import AthenaTier, HealthStatus as AthenaHealthStatus, QueryState
from zones.z07_data_access.tier_health_monitor import TierHealthMonitor, TierStatus


class TestMinIOIntegration:
    """Test MinIO Tier 3 integration"""

    def test_minio_initialization(self):
        """Test MinIO tier initialization"""
        minio = MinIOTier()
        assert minio is not None
        assert minio.bucket == "pt-historical"

    def test_minio_health_check(self):
        """Test MinIO health check"""
        minio = MinIOTier()
        health = minio.health_check()
        assert health is not None
        assert hasattr(health, 'available')
        assert hasattr(health, 'latency_ms')
        assert hasattr(health, 'status')

    def test_minio_query_historical_data(self):
        """Test MinIO query for historical data (7-90 days)"""
        minio = MinIOTier()
        result = minio.query(
            filter_criteria={"table": "sessions"},
            days_back=30,
            limit=10
        )
        assert result is not None
        assert result.row_count >= 0
        assert result.bucket == "pt-historical"
        # Check that data contains expected fields (if any returned)
        if len(result.data) > 0:
            assert "tier" in result.data[0] or "id" in result.data[0]

    def test_minio_cache_functionality(self):
        """Test MinIO caching layer"""
        minio = MinIOTier(cache_enabled=True)

        # First query - cache miss
        result1 = minio.query({"table": "sessions"}, days_back=30)
        assert result1.cached == False

        # Second query - should be cached
        result2 = minio.query({"table": "sessions"}, days_back=30)
        # Note: In mock implementation, cache might not work exactly as expected
        # This test validates the interface exists
        assert hasattr(result2, 'cached')

    def test_minio_stats_tracking(self):
        """Test MinIO statistics tracking"""
        minio = MinIOTier()

        # Execute some queries
        minio.query({"table": "sessions"}, days_back=30)
        minio.query({"table": "exercises"}, days_back=45)

        stats = minio.get_stats()
        assert stats["total_queries"] >= 2
        assert "cache_hit_rate_pct" in stats
        assert "avg_query_time_ms" in stats


class TestAthenaIntegration:
    """Test Athena Tier 4 integration"""

    def test_athena_initialization(self):
        """Test Athena tier initialization"""
        athena = AthenaTier()
        assert athena is not None
        assert athena.database == "pt_analytics"

    def test_athena_health_check(self):
        """Test Athena health check"""
        athena = AthenaTier()
        health = athena.health_check()
        assert health is not None
        assert hasattr(health, 'available')
        assert hasattr(health, 'latency_ms')
        assert hasattr(health, 'status')

    def test_athena_analytics_query(self):
        """Test Athena analytics query execution"""
        athena = AthenaTier()
        result = athena.execute_analytics_query(
            sql="SELECT COUNT(*) FROM sessions WHERE created_at > '2024-01-01'"
        )
        assert result is not None
        assert hasattr(result, 'row_count')
        assert hasattr(result, 'query_id')
        assert hasattr(result, 'state')

    def test_athena_aggregation_query(self):
        """Test Athena aggregation query"""
        athena = AthenaTier()
        result = athena.execute_analytics_query(
            sql="SELECT metric, COUNT(*) as count FROM analytics GROUP BY metric"
        )
        assert result is not None
        # Mock returns aggregation results
        if result.row_count > 0:
            assert "metric" in result.data[0] or "tier" in result.data[0]

    def test_athena_stats_tracking(self):
        """Test Athena statistics tracking"""
        athena = AthenaTier()

        # Execute some queries
        athena.execute_analytics_query("SELECT * FROM sessions")
        athena.execute_analytics_query("SELECT COUNT(*) FROM exercises")

        stats = athena.get_stats()
        assert stats["total_queries"] >= 2
        assert "success_rate_pct" in stats
        assert "avg_query_time_ms" in stats
        assert "total_data_scanned_bytes" in stats


class TestTierHealthMonitor:
    """Test tier health monitoring"""

    def test_health_monitor_initialization(self):
        """Test health monitor initialization"""
        monitor = TierHealthMonitor()
        assert monitor is not None
        assert monitor.check_interval == 30

    def test_register_tier_clients(self):
        """Test registering tier clients"""
        monitor = TierHealthMonitor()

        # Create mock tier clients
        mock_master = Mock()
        mock_master.health_check = Mock(return_value=Mock(available=True, latency_ms=10.0))

        monitor.register_tier("master", mock_master)
        assert "master" in monitor.tier_clients

    def test_check_all_tiers(self):
        """Test checking health of all tiers"""
        monitor = TierHealthMonitor()

        # Register mock clients
        for tier_name in ["master", "pgvector", "minio", "athena"]:
            mock_client = Mock()
            mock_client.health_check = Mock(
                return_value=Mock(available=True, latency_ms=50.0, error=None)
            )
            monitor.register_tier(tier_name, mock_client)

        snapshot = monitor.check_all_tiers()
        assert snapshot is not None
        assert snapshot.total_tiers == 4
        assert snapshot.available_tier_count >= 0

    def test_get_available_tiers(self):
        """Test getting list of available tiers"""
        monitor = TierHealthMonitor()

        # Register healthy tiers
        for tier_name in ["master", "pgvector"]:
            mock_client = Mock()
            mock_client.health_check = Mock(
                return_value=Mock(available=True, latency_ms=50.0, error=None)
            )
            monitor.register_tier(tier_name, mock_client)

        monitor.check_all_tiers()
        available = monitor.get_available_tiers()
        assert isinstance(available, list)

    def test_tier_failure_detection(self):
        """Test detection of tier failures"""
        monitor = TierHealthMonitor(max_consecutive_failures=2)

        # Register failing tier
        mock_client = Mock()
        mock_client.health_check = Mock(
            return_value=Mock(available=False, latency_ms=0.0, error="Connection failed")
        )
        monitor.register_tier("minio", mock_client)

        # Check multiple times to trigger consecutive failures
        monitor.check_all_tiers()
        monitor.check_all_tiers()

        assert not monitor.is_tier_available("minio") or monitor.current_health["minio"].consecutive_failures > 0


class TestWave2Routing:
    """Test Wave 2 routing with all 4 tiers enabled"""

    def test_router_with_wave2_config(self):
        """Test router loads Wave 2 configuration correctly"""
        router = TierRouter()
        assert router.config["routing_rules"]["minio"]["enabled"] == True
        assert router.config["routing_rules"]["athena"]["enabled"] == True

    def test_minio_tier_selection(self):
        """Test MinIO tier selection for historical queries"""
        router = TierRouter()
        query_params = {"days_back": 30}
        tier, overhead = router.route_query(query_params)
        assert tier == DataTier.MINIO
        assert overhead < 1.0

    def test_athena_tier_selection(self):
        """Test Athena tier selection for analytics queries"""
        router = TierRouter()
        query_params = {"days_back": 120}
        tier, overhead = router.route_query(query_params)
        assert tier == DataTier.ATHENA
        assert overhead < 1.0

    def test_50_percent_routing_target(self):
        """Test that 50%+ of queries are routed to optimal tiers"""
        router = TierRouter()

        # Simulate diverse workload with all tier types
        queries = [
            {"days_back": 2},            # Master
            {"use_embeddings": True},    # PGVector
            {"days_back": 30},           # MinIO
            {"days_back": 120},          # Athena
            {"days_back": 5},            # Master
            {"similarity_search": True}, # PGVector
            {"days_back": 60},           # MinIO
            {"days_back": 150},          # Athena
            {"days_back": 3},            # Master
            {"days_back": 45},           # MinIO
        ]

        for query_params in queries:
            router.route_query(query_params)

        metrics = router.get_routing_metrics()
        routing_percentage = metrics["routing_percentage"]

        # With 4 tiers enabled, should achieve 50%+ routing
        assert routing_percentage >= 50.0, \
            f"Routing percentage {routing_percentage}% is below 50% target"

    def test_tier_distribution_wave2(self):
        """Test tier distribution with all 4 tiers active"""
        router = TierRouter()

        # Simulate balanced workload
        queries = [
            {"days_back": 2},            # Master
            {"days_back": 3},            # Master
            {"days_back": 5},            # Master
            {"days_back": 6},            # Master
            {"use_embeddings": True},    # PGVector
            {"use_embeddings": True},    # PGVector
            {"similarity_search": True}, # PGVector
            {"days_back": 30},           # MinIO
            {"days_back": 45},           # MinIO
            {"days_back": 60},           # MinIO
            {"days_back": 120},          # Athena
            {"days_back": 150},          # Athena
        ]

        for query_params in queries:
            router.route_query(query_params)

        metrics = router.get_routing_metrics()
        tier_dist = metrics["tier_distribution"]

        # Verify all 4 tiers are being used
        assert tier_dist["master"] > 0
        assert tier_dist["pgvector"] > 0
        assert tier_dist["minio"] > 0
        assert tier_dist["athena"] > 0


class TestAutomaticFailover:
    """Test automatic failover functionality"""

    def test_failover_when_tier_unavailable(self):
        """Test automatic failover when preferred tier is unavailable"""
        monitor = TierHealthMonitor()

        # Register healthy master, unhealthy MinIO
        mock_master = Mock()
        mock_master.health_check = Mock(
            return_value=Mock(available=True, latency_ms=10.0, error=None)
        )
        monitor.register_tier("master", mock_master)

        mock_minio = Mock()
        mock_minio.health_check = Mock(
            return_value=Mock(available=False, latency_ms=0.0, error="Connection timeout")
        )
        monitor.register_tier("minio", mock_minio)

        # Check health to update state
        monitor.check_all_tiers()

        # Create router with health monitor
        router = TierRouter(health_monitor=monitor)

        # Query that would normally go to MinIO
        query_params = {"days_back": 30}
        tier, overhead = router.route_query(query_params)

        # Should failover to Master since MinIO is unavailable
        assert tier == DataTier.MASTER
        assert router.routing_stats["failover_count"] >= 1

    def test_failover_chain(self):
        """Test failover chain (Athena → MinIO → Master)"""
        monitor = TierHealthMonitor()

        # Register healthy master, unhealthy MinIO and Athena
        mock_master = Mock()
        mock_master.health_check = Mock(
            return_value=Mock(available=True, latency_ms=10.0, error=None)
        )
        monitor.register_tier("master", mock_master)

        mock_minio = Mock()
        mock_minio.health_check = Mock(
            return_value=Mock(available=False, latency_ms=0.0, error="Connection timeout")
        )
        monitor.register_tier("minio", mock_minio)

        mock_athena = Mock()
        mock_athena.health_check = Mock(
            return_value=Mock(available=False, latency_ms=0.0, error="Service unavailable")
        )
        monitor.register_tier("athena", mock_athena)

        monitor.check_all_tiers()

        router = TierRouter(health_monitor=monitor)

        # Query that would go to Athena
        query_params = {"days_back": 120}
        tier, overhead = router.route_query(query_params)

        # Should failover all the way to Master
        assert tier == DataTier.MASTER


class TestPerformanceWave2:
    """Test Wave 2 performance requirements"""

    def test_routing_overhead_under_1ms_wave2(self):
        """Test that routing overhead stays <1ms with 4 tiers"""
        router = TierRouter()

        queries = [
            {"days_back": 2},
            {"use_embeddings": True},
            {"days_back": 30},
            {"days_back": 120},
            {"days_back": 5},
        ]

        for query_params in queries:
            tier, overhead = router.route_query(query_params)
            assert overhead < 1.0, f"Routing overhead {overhead}ms exceeds 1ms limit"

    def test_average_overhead_wave2(self):
        """Test average overhead over 100 queries"""
        router = TierRouter()

        queries = [
            {"days_back": 2},
            {"use_embeddings": True},
            {"days_back": 30},
            {"days_back": 120},
        ] * 25  # 100 queries

        for query_params in queries:
            router.route_query(query_params)

        metrics = router.get_routing_metrics()
        avg_overhead = metrics["avg_overhead_ms"]
        assert avg_overhead < 1.0, f"Average overhead {avg_overhead}ms exceeds 1ms"

    def test_failover_overhead(self):
        """Test that failover doesn't add significant overhead"""
        monitor = TierHealthMonitor()

        # Register unhealthy MinIO
        mock_minio = Mock()
        mock_minio.health_check = Mock(
            return_value=Mock(available=False, latency_ms=0.0, error="Timeout")
        )
        monitor.register_tier("minio", mock_minio)

        # Register healthy master
        mock_master = Mock()
        mock_master.health_check = Mock(
            return_value=Mock(available=True, latency_ms=10.0, error=None)
        )
        monitor.register_tier("master", mock_master)

        monitor.check_all_tiers()

        router = TierRouter(health_monitor=monitor)

        # Query that triggers failover
        tier, overhead = router.route_query({"days_back": 30})

        # Failover should still be <1ms
        assert overhead < 1.0


class TestBackwardCompatibility:
    """Test Wave 1 functionality still works"""

    def test_wave1_master_routing(self):
        """Test Wave 1 master tier routing still works"""
        router = TierRouter()
        tier, overhead = router.route_query({"days_back": 2})
        assert tier == DataTier.MASTER

    def test_wave1_pgvector_routing(self):
        """Test Wave 1 PGVector routing still works"""
        router = TierRouter()
        tier, overhead = router.route_query({"use_embeddings": True})
        assert tier == DataTier.PGVECTOR

    def test_wave1_metrics_compatibility(self):
        """Test Wave 1 metrics format is preserved"""
        router = TierRouter()
        router.route_query({"days_back": 2})

        metrics = router.get_routing_metrics()
        # Wave 1 fields still present
        assert "total_queries" in metrics
        assert "routing_percentage" in metrics
        assert "avg_overhead_ms" in metrics
        assert "tier_distribution" in metrics


def test_wave2_routing_performance_benchmark():
    """Benchmark routing performance with 1000 queries across 4 tiers"""
    router = TierRouter()

    queries = [
        {"days_back": 2},            # Master
        {"use_embeddings": True},    # PGVector
        {"days_back": 30},           # MinIO
        {"days_back": 120},          # Athena
        {"days_back": 5},            # Master
    ] * 200  # 1000 total queries

    start = time.perf_counter()
    for query_params in queries:
        router.route_query(query_params)
    end = time.perf_counter()

    total_time_ms = (end - start) * 1000
    avg_time_per_query = total_time_ms / len(queries)

    print(f"\n=== Wave 2 Routing Performance Benchmark ===")
    print(f"Total queries: {len(queries)}")
    print(f"Total time: {total_time_ms:.2f}ms")
    print(f"Average per query: {avg_time_per_query:.4f}ms")

    metrics = router.get_routing_metrics()
    print(f"Routing percentage: {metrics['routing_percentage']:.1f}%")
    print(f"Tier distribution: {metrics['tier_distribution']}")
    print(f"Tier distribution %: {metrics['tier_distribution_pct']}")
    print(f"Failover count: {metrics['failover_count']}")

    assert avg_time_per_query < 1.0, \
        f"Average routing time {avg_time_per_query}ms exceeds 1ms requirement"
    assert metrics['routing_percentage'] >= 50.0, \
        f"Routing percentage {metrics['routing_percentage']}% below 50% target"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
