"""
4-Tier Database Router with ML Support - Wave 2 Agent 11
Routes queries across Master, PGVector, MinIO, and Athena tiers

This is the ML-enhanced version. To use:
1. Train an MLTierSelector model
2. Create router with: router = TierRouterML(ml_selector=selector)
3. Set USE_ML_ROUTING=true

Architecture:
- Tier 1 (Master): Recent data (<7 days), high-frequency queries
- Tier 2 (PGVector): Semantic search, embeddings, similarity queries
- Tier 3 (MinIO): Historical data (7-90 days), bulk queries
- Tier 4 (Athena): Archive (>90 days), analytics queries
"""

import os
import time
import yaml
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, Optional, Tuple

# Import shared enums from tier_router
from .tier_router import DataTier, QueryType


class TierRouterML:
    """4-tier database routing engine with ML support"""

    def __init__(
        self,
        config_path: Optional[str] = None,
        health_monitor: Optional[Any] = None,
        ml_selector: Optional[Any] = None
    ):
        """
        Initialize router with ML support

        Args:
            config_path: Path to configuration file
            health_monitor: Optional health monitor for failover
            ml_selector: Optional MLTierSelector for ML-based routing
        """
        self.use_rust = os.getenv("TIER_ROUTER_USE_RUST", "false").lower() == "true"
        self.enabled = os.getenv("TIER_ROUTER_ENABLED", "true").lower() == "true"
        self.use_ml_routing = os.getenv("USE_ML_ROUTING", "false").lower() == "true"

        # Load configuration
        if config_path is None:
            config_path = Path(__file__).parent / "tier_router_config.yaml"

        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)

        # Integrations
        self.health_monitor = health_monitor
        self.ml_selector = ml_selector

        self.routing_stats = {
            "total_queries": 0,
            "tier_counts": {tier.value: 0 for tier in DataTier},
            "total_overhead_ms": 0.0,
            "failover_count": 0,
            "ml_predictions": 0,
            "ml_fallbacks": 0
        }

    def analyze_query(self, query_params: Dict[str, Any]) -> Tuple[QueryType, Dict[str, Any]]:
        """Analyze query parameters to determine query type"""
        metadata = {}

        if query_params.get("use_embeddings") or query_params.get("similarity_search"):
            return QueryType.SEMANTIC, {"requires_vector": True}

        days_back = query_params.get("days_back", 0)
        if days_back <= self.config["tier_thresholds"]["master_days"]:
            return QueryType.RECENT, {"days_back": days_back}
        elif days_back <= self.config["tier_thresholds"]["minio_days"]:
            return QueryType.HISTORICAL, {"days_back": days_back}
        else:
            return QueryType.ANALYTICS, {"days_back": days_back}

    def route_query(self, query_params: Dict[str, Any]) -> Tuple[DataTier, float]:
        """Route query to appropriate tier"""
        start_time = time.perf_counter()

        if not self.enabled:
            tier = DataTier.MASTER
        else:
            query_type, metadata = self.analyze_query(query_params)
            tier = self._select_tier(query_type, metadata, query_params)

        overhead_ms = (time.perf_counter() - start_time) * 1000

        self.routing_stats["total_queries"] += 1
        self.routing_stats["tier_counts"][tier.value] += 1
        self.routing_stats["total_overhead_ms"] += overhead_ms

        return tier, overhead_ms

    def _select_tier(
        self,
        query_type: QueryType,
        metadata: Dict[str, Any],
        query_params: Optional[Dict[str, Any]] = None
    ) -> DataTier:
        """Select tier using ML or static routing"""
        # Try ML routing first
        if self.use_ml_routing and self.ml_selector and query_params:
            try:
                prediction = self.ml_selector.predict(query_params)
                self.routing_stats["ml_predictions"] += 1

                if not prediction.fallback_to_static:
                    # Convert ML DataTier to router DataTier by value
                    ml_tier_value = prediction.tier.value
                    router_tier = DataTier(ml_tier_value)

                    tier_config = self.config["routing_rules"].get(router_tier.value, {})
                    if tier_config.get("enabled", False):
                        if self.health_monitor:
                            if self.health_monitor.is_tier_available(router_tier.value):
                                return router_tier
                        else:
                            return router_tier

                self.routing_stats["ml_fallbacks"] += 1
            except Exception:
                self.routing_stats["ml_fallbacks"] += 1

        # Static routing fallback
        routing_rules = self.config["routing_rules"]

        tier_map = {
            QueryType.RECENT: DataTier.MASTER,
            QueryType.SEMANTIC: DataTier.PGVECTOR,
            QueryType.HISTORICAL: DataTier.MINIO,
            QueryType.ANALYTICS: DataTier.ATHENA
        }

        preferred_tier = tier_map.get(query_type, DataTier.MASTER)

        tier_config = routing_rules.get(preferred_tier.value, {})
        if not tier_config.get("enabled", False):
            return DataTier(self.config["fallback_tier"])

        if self.health_monitor:
            if not self.health_monitor.is_tier_available(preferred_tier.value):
                self.routing_stats["failover_count"] += 1
                return DataTier.MASTER

        return preferred_tier

    def get_routing_metrics(self) -> Dict[str, Any]:
        """Get routing statistics"""
        total = self.routing_stats["total_queries"]
        if total == 0:
            return {
                "total_queries": 0,
                "routing_percentage": 0.0,
                "avg_overhead_ms": 0.0,
                "tier_distribution": {},
                "ml_predictions": 0,
                "ml_fallbacks": 0
            }

        non_master = sum(
            count for tier, count in self.routing_stats["tier_counts"].items()
            if tier != DataTier.MASTER.value
        )
        routing_percentage = (non_master / total) * 100
        avg_overhead = self.routing_stats["total_overhead_ms"] / total

        tier_distribution_pct = {
            tier: (count / total) * 100
            for tier, count in self.routing_stats["tier_counts"].items()
        }

        ml_predictions = self.routing_stats.get("ml_predictions", 0)
        ml_usage_pct = (ml_predictions / total) * 100 if total > 0 else 0.0

        return {
            "total_queries": total,
            "routing_percentage": routing_percentage,
            "avg_overhead_ms": avg_overhead,
            "tier_distribution": self.routing_stats["tier_counts"].copy(),
            "tier_distribution_pct": tier_distribution_pct,
            "failover_count": self.routing_stats.get("failover_count", 0),
            "ml_predictions": ml_predictions,
            "ml_fallbacks": self.routing_stats.get("ml_fallbacks", 0),
            "ml_usage_pct": ml_usage_pct
        }
