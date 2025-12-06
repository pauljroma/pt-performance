"""
4-Tier Database Router - Wave 1 Foundation (Python-only mode)
Routes queries across Master, PGVector, MinIO, and Athena tiers

Architecture:
- Tier 1 (Master): Recent data (<7 days), high-frequency queries
- Tier 2 (PGVector): Semantic search, embeddings, similarity queries
- Tier 3 (MinIO): Historical data (7-90 days), bulk queries
- Tier 4 (Athena): Archive (>90 days), analytics queries

Wave 1: Python SQL implementation only (TIER_ROUTER_USE_RUST=false)
Wave 2: Rust primitives integration for hot path optimization
"""

import os
import time
import yaml
from datetime import datetime, timedelta
from enum import Enum
from pathlib import Path
from typing import Dict, Any, Optional, Tuple


class DataTier(Enum):
    """Database tier enumeration"""
    MASTER = "master"
    PGVECTOR = "pgvector"
    MINIO = "minio"
    ATHENA = "athena"


class QueryType(Enum):
    """Query type classification"""
    RECENT = "recent"
    SEMANTIC = "semantic"
    HISTORICAL = "historical"
    ANALYTICS = "analytics"


class TierRouter:
    """4-tier database routing engine"""

    def __init__(self, config_path: Optional[str] = None):
        """Initialize router with configuration"""
        self.use_rust = os.getenv("TIER_ROUTER_USE_RUST", "false").lower() == "true"
        self.enabled = os.getenv("TIER_ROUTER_ENABLED", "true").lower() == "true"

        # Load configuration
        if config_path is None:
            config_path = Path(__file__).parent / "tier_router_config.yaml"

        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)

        self.routing_stats = {
            "total_queries": 0,
            "tier_counts": {tier.value: 0 for tier in DataTier},
            "total_overhead_ms": 0.0
        }

    def analyze_query(self, query_params: Dict[str, Any]) -> Tuple[QueryType, Dict[str, Any]]:
        """
        Analyze query parameters to determine query type and routing metadata

        Args:
            query_params: Dict with keys like 'days_back', 'use_embeddings', 'table', etc.

        Returns:
            Tuple of (QueryType, metadata dict)
        """
        metadata = {}

        # Check for semantic search indicators
        if query_params.get("use_embeddings") or query_params.get("similarity_search"):
            return QueryType.SEMANTIC, {"requires_vector": True}

        # Check temporal bounds
        days_back = query_params.get("days_back", 0)
        if days_back <= self.config["tier_thresholds"]["master_days"]:
            return QueryType.RECENT, {"days_back": days_back}
        elif days_back <= self.config["tier_thresholds"]["minio_days"]:
            return QueryType.HISTORICAL, {"days_back": days_back}
        else:
            return QueryType.ANALYTICS, {"days_back": days_back}

    def route_query(self, query_params: Dict[str, Any]) -> Tuple[DataTier, float]:
        """
        Route query to appropriate tier based on analysis

        Args:
            query_params: Query parameters for analysis

        Returns:
            Tuple of (selected tier, routing overhead in ms)
        """
        start_time = time.perf_counter()

        # Feature flag check
        if not self.enabled:
            tier = DataTier.MASTER
        else:
            query_type, metadata = self.analyze_query(query_params)
            tier = self._select_tier(query_type, metadata)

        # Calculate overhead
        overhead_ms = (time.perf_counter() - start_time) * 1000

        # Update stats
        self.routing_stats["total_queries"] += 1
        self.routing_stats["tier_counts"][tier.value] += 1
        self.routing_stats["total_overhead_ms"] += overhead_ms

        return tier, overhead_ms

    def _select_tier(self, query_type: QueryType, metadata: Dict[str, Any]) -> DataTier:
        """Select tier based on query type and metadata"""
        routing_rules = self.config["routing_rules"]

        # Direct query type to tier mapping
        tier_map = {
            QueryType.RECENT: DataTier.MASTER,
            QueryType.SEMANTIC: DataTier.PGVECTOR,
            QueryType.HISTORICAL: DataTier.MINIO,
            QueryType.ANALYTICS: DataTier.ATHENA
        }

        preferred_tier = tier_map.get(query_type, DataTier.MASTER)

        # Check if preferred tier is enabled
        tier_config = routing_rules.get(preferred_tier.value, {})
        if not tier_config.get("enabled", False):
            # Fallback to master if tier disabled
            return DataTier(self.config["fallback_tier"])

        return preferred_tier

    def get_routing_metrics(self) -> Dict[str, Any]:
        """Get routing statistics and performance metrics"""
        total = self.routing_stats["total_queries"]
        if total == 0:
            return {
                "total_queries": 0,
                "routing_percentage": 0.0,
                "avg_overhead_ms": 0.0,
                "tier_distribution": {}
            }

        # Calculate routed percentage (anything not going to master)
        non_master = sum(
            count for tier, count in self.routing_stats["tier_counts"].items()
            if tier != DataTier.MASTER.value
        )
        routing_percentage = (non_master / total) * 100

        avg_overhead = self.routing_stats["total_overhead_ms"] / total

        return {
            "total_queries": total,
            "routing_percentage": routing_percentage,
            "avg_overhead_ms": avg_overhead,
            "tier_distribution": self.routing_stats["tier_counts"].copy()
        }
