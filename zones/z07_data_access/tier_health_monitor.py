"""
Tier Health Monitor - Multi-tier availability and failover management

Monitors health of all 4 database tiers and provides automatic failover logic

Features:
- Health checks for all tiers (Master, PGVector, MinIO, Athena)
- Heartbeat monitoring (configurable interval)
- Latency tracking per tier
- Automatic failover logic
- Health status dashboard integration
- Historical health metrics

Architecture:
- Periodic health checks (default: 30s)
- Circuit breaker pattern for failing tiers
- Graceful degradation on tier failure
- Health metrics aggregation
"""

import time
import threading
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, field
from enum import Enum
from collections import deque


class TierStatus(Enum):
    """Tier health status"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNAVAILABLE = "unavailable"
    UNKNOWN = "unknown"


@dataclass
class TierHealth:
    """Health status for a single tier"""
    tier_name: str
    status: TierStatus
    available: bool
    latency_ms: float
    last_check: datetime
    error: Optional[str] = None
    consecutive_failures: int = 0


@dataclass
class HealthSnapshot:
    """Point-in-time health snapshot of all tiers"""
    timestamp: datetime
    tiers: Dict[str, TierHealth]
    overall_health: TierStatus
    available_tier_count: int
    total_tiers: int


class TierHealthMonitor:
    """
    Monitor health of all database tiers

    Provides health checks, failover logic, and availability metrics
    """

    def __init__(
        self,
        check_interval_seconds: int = 30,
        latency_threshold_healthy_ms: float = 100.0,
        latency_threshold_degraded_ms: float = 500.0,
        max_consecutive_failures: int = 3,
        history_size: int = 100
    ):
        """
        Initialize health monitor

        Args:
            check_interval_seconds: How often to check tier health
            latency_threshold_healthy_ms: Latency threshold for healthy status
            latency_threshold_degraded_ms: Latency threshold for degraded status
            max_consecutive_failures: Failures before marking unavailable
            history_size: Number of health snapshots to retain
        """
        self.check_interval = check_interval_seconds
        self.latency_healthy = latency_threshold_healthy_ms
        self.latency_degraded = latency_threshold_degraded_ms
        self.max_failures = max_consecutive_failures

        # Tier clients (will be injected)
        self.tier_clients: Dict[str, Any] = {}

        # Health state
        self.current_health: Dict[str, TierHealth] = {
            "master": TierHealth("master", TierStatus.UNKNOWN, False, 0.0, datetime.now()),
            "pgvector": TierHealth("pgvector", TierStatus.UNKNOWN, False, 0.0, datetime.now()),
            "minio": TierHealth("minio", TierStatus.UNKNOWN, False, 0.0, datetime.now()),
            "athena": TierHealth("athena", TierStatus.UNKNOWN, False, 0.0, datetime.now())
        }

        # Health history
        self.history: deque = deque(maxlen=history_size)

        # Background monitoring
        self.monitoring_enabled = False
        self.monitor_thread: Optional[threading.Thread] = None

        # Statistics
        self.stats = {
            "total_checks": 0,
            "total_failures": 0,
            "total_recoveries": 0,
            "uptime_checks": {tier: 0 for tier in self.current_health.keys()},
            "downtime_checks": {tier: 0 for tier in self.current_health.keys()}
        }

    def register_tier(self, tier_name: str, tier_client: Any):
        """
        Register a tier client for health monitoring

        Args:
            tier_name: Name of tier (master, pgvector, minio, athena)
            tier_client: Client object with health_check() method
        """
        self.tier_clients[tier_name] = tier_client

    def check_all_tiers(self) -> HealthSnapshot:
        """
        Check health of all registered tiers

        Returns:
            HealthSnapshot with current health status
        """
        self.stats["total_checks"] += 1
        snapshot_time = datetime.now()
        tier_health_results = {}

        for tier_name, tier_client in self.tier_clients.items():
            health = self._check_tier_health(tier_name, tier_client)
            tier_health_results[tier_name] = health

            # Update current health
            self.current_health[tier_name] = health

            # Update stats
            if health.available:
                self.stats["uptime_checks"][tier_name] += 1
            else:
                self.stats["downtime_checks"][tier_name] += 1

        # Determine overall health
        available_count = sum(1 for h in tier_health_results.values() if h.available)
        total_count = len(tier_health_results)

        if available_count == total_count:
            overall_status = TierStatus.HEALTHY
        elif available_count >= total_count // 2:
            overall_status = TierStatus.DEGRADED
        else:
            overall_status = TierStatus.UNAVAILABLE

        snapshot = HealthSnapshot(
            timestamp=snapshot_time,
            tiers=tier_health_results,
            overall_health=overall_status,
            available_tier_count=available_count,
            total_tiers=total_count
        )

        # Add to history
        self.history.append(snapshot)

        return snapshot

    def _check_tier_health(self, tier_name: str, tier_client: Any) -> TierHealth:
        """
        Check health of a single tier

        Args:
            tier_name: Name of tier
            tier_client: Client with health_check() method

        Returns:
            TierHealth status
        """
        try:
            # Call tier's health check method
            if hasattr(tier_client, 'health_check'):
                health_result = tier_client.health_check()

                # Parse health result
                available = getattr(health_result, 'available', False)
                latency_ms = getattr(health_result, 'latency_ms', 0.0)
                error = getattr(health_result, 'error', None)

                # Determine status based on latency
                if not available:
                    status = TierStatus.UNAVAILABLE
                elif latency_ms < self.latency_healthy:
                    status = TierStatus.HEALTHY
                elif latency_ms < self.latency_degraded:
                    status = TierStatus.DEGRADED
                else:
                    status = TierStatus.UNAVAILABLE

                # Track consecutive failures
                current_health = self.current_health.get(tier_name)
                if available:
                    consecutive_failures = 0
                    if current_health and not current_health.available:
                        self.stats["total_recoveries"] += 1
                else:
                    consecutive_failures = (current_health.consecutive_failures + 1
                                          if current_health else 1)
                    if consecutive_failures == 1:
                        self.stats["total_failures"] += 1

                return TierHealth(
                    tier_name=tier_name,
                    status=status,
                    available=available,
                    latency_ms=latency_ms,
                    last_check=datetime.now(),
                    error=error,
                    consecutive_failures=consecutive_failures
                )

            else:
                # Client doesn't support health checks - assume healthy
                return TierHealth(
                    tier_name=tier_name,
                    status=TierStatus.HEALTHY,
                    available=True,
                    latency_ms=0.0,
                    last_check=datetime.now()
                )

        except Exception as e:
            current_health = self.current_health.get(tier_name)
            consecutive_failures = (current_health.consecutive_failures + 1
                                  if current_health else 1)

            if consecutive_failures == 1:
                self.stats["total_failures"] += 1

            return TierHealth(
                tier_name=tier_name,
                status=TierStatus.UNAVAILABLE,
                available=False,
                latency_ms=0.0,
                last_check=datetime.now(),
                error=str(e),
                consecutive_failures=consecutive_failures
            )

    def get_available_tiers(self) -> List[str]:
        """
        Get list of currently available tiers

        Used by router for failover decisions

        Returns:
            List of tier names that are available
        """
        available = []
        for tier_name, health in self.current_health.items():
            if health.available and health.consecutive_failures < self.max_failures:
                available.append(tier_name)
        return available

    def is_tier_available(self, tier_name: str) -> bool:
        """
        Check if a specific tier is available

        Args:
            tier_name: Name of tier to check

        Returns:
            True if tier is available, False otherwise
        """
        if tier_name not in self.current_health:
            return False

        health = self.current_health[tier_name]
        return health.available and health.consecutive_failures < self.max_failures

    def get_tier_latency(self, tier_name: str) -> float:
        """
        Get current latency for a tier

        Args:
            tier_name: Name of tier

        Returns:
            Latency in milliseconds (0.0 if unavailable)
        """
        if tier_name not in self.current_health:
            return 0.0

        return self.current_health[tier_name].latency_ms

    def get_best_available_tier(
        self,
        preferred_tiers: List[str]
    ) -> Optional[str]:
        """
        Get best available tier from a preference list

        Args:
            preferred_tiers: List of tiers in order of preference

        Returns:
            Name of best available tier, or None if none available
        """
        for tier_name in preferred_tiers:
            if self.is_tier_available(tier_name):
                return tier_name
        return None

    def start_monitoring(self):
        """Start background health monitoring"""
        if self.monitoring_enabled:
            return

        self.monitoring_enabled = True
        self.monitor_thread = threading.Thread(
            target=self._monitoring_loop,
            daemon=True
        )
        self.monitor_thread.start()

    def stop_monitoring(self):
        """Stop background health monitoring"""
        self.monitoring_enabled = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)

    def _monitoring_loop(self):
        """Background monitoring loop"""
        while self.monitoring_enabled:
            try:
                self.check_all_tiers()
            except Exception as e:
                print(f"Error in health monitoring loop: {e}")

            time.sleep(self.check_interval)

    def get_health_summary(self) -> Dict[str, Any]:
        """
        Get summary of current health status

        Returns:
            Dictionary with health metrics and status
        """
        available_tiers = self.get_available_tiers()
        snapshot = self.check_all_tiers()

        return {
            "overall_status": snapshot.overall_health.value,
            "available_tiers": available_tiers,
            "available_count": len(available_tiers),
            "total_tiers": len(self.current_health),
            "tier_health": {
                name: {
                    "status": health.status.value,
                    "available": health.available,
                    "latency_ms": health.latency_ms,
                    "consecutive_failures": health.consecutive_failures,
                    "last_check": health.last_check.isoformat()
                }
                for name, health in self.current_health.items()
            },
            "last_check": snapshot.timestamp.isoformat()
        }

    def get_stats(self) -> Dict[str, Any]:
        """Get health monitoring statistics"""
        total_checks = self.stats["total_checks"]
        if total_checks == 0:
            return {
                "total_checks": 0,
                "total_failures": 0,
                "total_recoveries": 0,
                "uptime_percentage": {}
            }

        uptime_pct = {}
        for tier, uptime_checks in self.stats["uptime_checks"].items():
            downtime_checks = self.stats["downtime_checks"][tier]
            total_tier_checks = uptime_checks + downtime_checks
            if total_tier_checks > 0:
                uptime_pct[tier] = (uptime_checks / total_tier_checks) * 100
            else:
                uptime_pct[tier] = 0.0

        return {
            "total_checks": total_checks,
            "total_failures": self.stats["total_failures"],
            "total_recoveries": self.stats["total_recoveries"],
            "uptime_percentage": uptime_pct,
            "history_size": len(self.history)
        }

    def get_health_history(
        self,
        minutes_back: int = 10
    ) -> List[HealthSnapshot]:
        """
        Get health history for the last N minutes

        Args:
            minutes_back: How many minutes of history to return

        Returns:
            List of HealthSnapshot objects
        """
        cutoff_time = datetime.now() - timedelta(minutes=minutes_back)
        return [
            snapshot for snapshot in self.history
            if snapshot.timestamp >= cutoff_time
        ]
