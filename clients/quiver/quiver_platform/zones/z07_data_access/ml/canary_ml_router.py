#!/usr/bin/env python3
"""
Canary ML Router - Gradual Rollout Wrapper

Implements gradual rollout of ML tier routing with A/B testing and fallback.

Features:
- Canary percentage control (default: 5%)
- Fallback to rule-based routing
- Metrics tracking for both ML and rule-based
- A/B testing support
- Safety checks and monitoring

Version: 1.0.0
Date: 2025-12-06
"""

import logging
import random
import time
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from datetime import datetime

logger = logging.getLogger(__name__)


@dataclass
class RoutingDecision:
    """Result of a routing decision"""
    tier: int
    method: str  # "ml" or "rule_based"
    inference_time_ms: float
    confidence: float = 1.0
    fallback_reason: Optional[str] = None


class CanaryMLRouter:
    """
    ML Router with gradual canary rollout.

    Controls what percentage of traffic uses ML routing vs rule-based routing.
    Tracks metrics for both methods to enable A/B testing.

    Usage:
        from zones.z07_data_access.ml.canary_ml_router import get_canary_router

        router = get_canary_router()
        decision = router.route_query(
            query_type="embedding_similarity",
            entity_type="drug",
            entity_count=10,
            complexity_score=0.3,
            data_sources=["pgvector"]
        )

        print(f"Tier: {decision.tier}, Method: {decision.method}")
    """

    def __init__(
        self,
        canary_percentage: float = 5.0,
        enable_ml: bool = True,
        enable_fallback: bool = True
    ):
        """
        Initialize canary router.

        Args:
            canary_percentage: Percentage of traffic to route via ML (0-100)
            enable_ml: Enable ML routing (if False, always use rule-based)
            enable_fallback: Enable fallback to rule-based on ML errors
        """
        self.canary_percentage = canary_percentage
        self.enable_ml = enable_ml
        self.enable_fallback = enable_fallback

        # Lazy load ML router (only when needed)
        self._ml_router = None

        # Stats tracking
        self.stats = {
            'total_requests': 0,
            'ml_requests': 0,
            'rule_based_requests': 0,
            'ml_errors': 0,
            'ml_fallbacks': 0,
            'ml_total_time_ms': 0.0,
            'rule_based_total_time_ms': 0.0
        }

        logger.info(f"Canary ML Router initialized (canary: {canary_percentage}%, ML enabled: {enable_ml})")

    def _get_ml_router(self):
        """Lazy load ML router"""
        if self._ml_router is None and self.enable_ml:
            try:
                from zones.z07_data_access.ml.ml_tier_router import get_ml_router
                self._ml_router = get_ml_router()
                logger.info("ML router loaded successfully")
            except Exception as e:
                logger.error(f"Failed to load ML router: {e}")
                if not self.enable_fallback:
                    raise
        return self._ml_router

    def _should_use_ml(self) -> bool:
        """
        Determine if this request should use ML routing.

        Uses random sampling to achieve canary percentage.

        Returns:
            True if should use ML, False for rule-based
        """
        if not self.enable_ml:
            return False

        # Random canary selection
        return random.random() * 100 < self.canary_percentage

    def _rule_based_routing(
        self,
        query_type: str,
        entity_type: str,
        entity_count: int,
        complexity_score: float,
        data_sources: List[str]
    ) -> int:
        """
        Simple rule-based tier routing (fallback).

        Rules:
        - master_tables → Tier 1
        - pgvector or embedding → Tier 2
        - neo4j or graph → Tier 3
        - parquet or high complexity → Tier 4

        Args:
            query_type: Type of query
            entity_type: Type of entity
            entity_count: Number of entities
            complexity_score: Query complexity
            data_sources: Required data sources

        Returns:
            Tier number (1-4)
        """
        # Rule 1: Master tables (fastest)
        if 'master_tables' in data_sources and complexity_score < 0.3:
            return 1

        # Rule 2: PGVector (fast for similarity)
        if 'pgvector' in data_sources or 'embedding' in data_sources:
            return 2

        # Rule 3: Neo4j (graph queries)
        if 'neo4j' in data_sources or query_type in ['graph_path', 'graph_traversal']:
            return 3

        # Rule 4: Parquet (complex analytics)
        if 'parquet' in data_sources or complexity_score > 0.7:
            return 4

        # Default: Tier 2 (balanced)
        return 2

    def route_query(
        self,
        query_type: str,
        entity_type: str,
        entity_count: int,
        complexity_score: float,
        data_sources: List[str],
        execution_time_ms: Optional[float] = None
    ) -> RoutingDecision:
        """
        Route query to optimal tier using ML or rule-based routing.

        Args:
            query_type: Type of query
            entity_type: Type of entity
            entity_count: Number of entities
            complexity_score: Query complexity (0-1)
            data_sources: Required data sources
            execution_time_ms: Historical execution time (optional)

        Returns:
            RoutingDecision with tier and metadata
        """
        self.stats['total_requests'] += 1

        # Decide: ML or rule-based?
        use_ml = self._should_use_ml()

        if use_ml:
            # Try ML routing
            try:
                ml_router = self._get_ml_router()

                if ml_router is None:
                    raise RuntimeError("ML router not available")

                start_time = time.time()
                tier = ml_router.predict_tier(
                    query_type=query_type,
                    entity_type=entity_type,
                    entity_count=entity_count,
                    complexity_score=complexity_score,
                    data_sources=data_sources,
                    execution_time_ms=execution_time_ms
                )
                inference_time = (time.time() - start_time) * 1000  # ms

                # Success!
                self.stats['ml_requests'] += 1
                self.stats['ml_total_time_ms'] += inference_time

                return RoutingDecision(
                    tier=tier,
                    method='ml',
                    inference_time_ms=inference_time,
                    confidence=1.0
                )

            except Exception as e:
                # ML failed
                self.stats['ml_errors'] += 1
                logger.warning(f"ML routing failed: {e}")

                if not self.enable_fallback:
                    raise

                # Fall back to rule-based
                logger.info("Falling back to rule-based routing")
                self.stats['ml_fallbacks'] += 1
                use_ml = False  # Continue to rule-based below

        # Rule-based routing (either selected or fallback)
        if not use_ml:
            start_time = time.time()
            tier = self._rule_based_routing(
                query_type=query_type,
                entity_type=entity_type,
                entity_count=entity_count,
                complexity_score=complexity_score,
                data_sources=data_sources
            )
            inference_time = (time.time() - start_time) * 1000  # ms

            self.stats['rule_based_requests'] += 1
            self.stats['rule_based_total_time_ms'] += inference_time

            return RoutingDecision(
                tier=tier,
                method='rule_based',
                inference_time_ms=inference_time,
                confidence=0.8,  # Lower confidence for rule-based
                fallback_reason='canary_not_selected' if not use_ml else 'ml_error'
            )

    def get_stats(self) -> Dict[str, Any]:
        """
        Get routing statistics.

        Returns:
            Dictionary with stats
        """
        total = self.stats['total_requests']
        ml_count = self.stats['ml_requests']
        rule_count = self.stats['rule_based_requests']

        avg_ml_time = (
            self.stats['ml_total_time_ms'] / ml_count if ml_count > 0 else 0
        )
        avg_rule_time = (
            self.stats['rule_based_total_time_ms'] / rule_count if rule_count > 0 else 0
        )

        return {
            'total_requests': total,
            'ml_requests': ml_count,
            'ml_percentage': (ml_count / total * 100) if total > 0 else 0,
            'rule_based_requests': rule_count,
            'rule_based_percentage': (rule_count / total * 100) if total > 0 else 0,
            'ml_errors': self.stats['ml_errors'],
            'ml_fallbacks': self.stats['ml_fallbacks'],
            'ml_error_rate': (self.stats['ml_errors'] / ml_count * 100) if ml_count > 0 else 0,
            'avg_ml_inference_ms': avg_ml_time,
            'avg_rule_inference_ms': avg_rule_time,
            'ml_speedup': (avg_rule_time / avg_ml_time) if avg_ml_time > 0 else 0,
            'canary_percentage_target': self.canary_percentage,
            'ml_enabled': self.enable_ml,
            'fallback_enabled': self.enable_fallback
        }

    def update_canary_percentage(self, new_percentage: float):
        """
        Update canary percentage (for gradual rollout).

        Args:
            new_percentage: New percentage (0-100)
        """
        if not 0 <= new_percentage <= 100:
            raise ValueError(f"Canary percentage must be 0-100, got {new_percentage}")

        old_percentage = self.canary_percentage
        self.canary_percentage = new_percentage

        logger.info(f"Canary percentage updated: {old_percentage}% → {new_percentage}%")


# Singleton instance
_canary_router_instance: Optional[CanaryMLRouter] = None


def get_canary_router(
    canary_percentage: Optional[float] = None,
    enable_ml: Optional[bool] = None,
    enable_fallback: Optional[bool] = None
) -> CanaryMLRouter:
    """
    Get singleton canary router instance.

    Args:
        canary_percentage: Override default canary percentage
        enable_ml: Override ML enabled flag
        enable_fallback: Override fallback enabled flag

    Returns:
        CanaryMLRouter instance
    """
    global _canary_router_instance

    # Get from environment if not specified
    if canary_percentage is None:
        import os
        canary_percentage = float(os.getenv('TIER_ROUTER_ML_CANARY_PERCENTAGE', '5.0'))

    if enable_ml is None:
        import os
        enable_ml = os.getenv('TIER_ROUTER_ML_ENABLED', 'true').lower() == 'true'

    if enable_fallback is None:
        import os
        enable_fallback = os.getenv('TIER_ROUTER_FALLBACK_ENABLED', 'true').lower() == 'true'

    if _canary_router_instance is None:
        _canary_router_instance = CanaryMLRouter(
            canary_percentage=canary_percentage,
            enable_ml=enable_ml,
            enable_fallback=enable_fallback
        )

    return _canary_router_instance


if __name__ == "__main__":
    # Test the canary router
    logging.basicConfig(level=logging.INFO)

    print("=" * 80)
    print("Canary ML Router - Test")
    print("=" * 80)

    # Initialize with 20% canary (for testing)
    router = CanaryMLRouter(canary_percentage=20.0, enable_ml=True, enable_fallback=True)

    # Test cases
    test_queries = [
        {
            "query_type": "metadata_lookup",
            "entity_type": "drug",
            "entity_count": 1,
            "complexity_score": 0.1,
            "data_sources": ["master_tables"],
            "desc": "Simple lookup"
        },
        {
            "query_type": "embedding_similarity",
            "entity_type": "gene",
            "entity_count": 50,
            "complexity_score": 0.5,
            "data_sources": ["pgvector"],
            "desc": "Vector search"
        },
        {
            "query_type": "graph_path",
            "entity_type": "pathway",
            "entity_count": 10,
            "complexity_score": 0.7,
            "data_sources": ["neo4j"],
            "desc": "Graph query"
        }
    ]

    # Run 100 queries to test canary distribution
    print(f"\nRunning 100 test queries (20% canary)...")

    for _ in range(100):
        query = random.choice(test_queries)
        desc = query.pop('desc', '')
        decision = router.route_query(**query)

    # Get stats
    stats = router.get_stats()

    print(f"\nResults:")
    print(f"  Total Requests: {stats['total_requests']}")
    print(f"  ML Requests: {stats['ml_requests']} ({stats['ml_percentage']:.1f}%)")
    print(f"  Rule-Based: {stats['rule_based_requests']} ({stats['rule_based_percentage']:.1f}%)")
    print(f"  ML Errors: {stats['ml_errors']}")
    print(f"  ML Fallbacks: {stats['ml_fallbacks']}")
    print(f"  Avg ML Inference: {stats['avg_ml_inference_ms']:.3f}ms")
    print(f"  Avg Rule Inference: {stats['avg_rule_inference_ms']:.3f}ms")
    if stats['ml_speedup'] > 0:
        print(f"  ML Speedup: {stats['ml_speedup']:.1f}x faster")

    print("\n" + "=" * 80)
    print("✅ Canary router test complete!")
    print("=" * 80)
